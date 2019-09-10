local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local json = require("json")
local Default = require("common.Default")
local HttpUrl = require("common.HttpUrl")

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

local Share = {
    className = "com/coco2dx/org/HelperAndroid",
    
    tableShareParameter = {},
    tableCustomerParameter = {},    --客服参数
 }

function Share:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS) 
end

function Share:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS) 
end

function Share:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end

    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.RET_SHARE then
        local data = {}
        data.dwChannelID = netInstance.cppFunc:readRecvDWORD()              --渠道ID
        data.cbTargetID = netInstance.cppFunc:readRecvByte()                --目标ID  0大厅 1公会 2俱乐部 3牌桌 4大结算 5战绩  6小结算 7新牌桌邀请
        data.cbTargetType = netInstance.cppFunc:readRecvByte()              --目标类型  >>0x1微信朋友圈  >>0x2微信好友 >>0x4闲聊  >>0x8聊天室  >>0x10战绩连接
        data.cbShareType = netInstance.cppFunc:readRecvByte()               --分享类型  0文本 1链接 2图片 3自定义图片
        data.szShareTitle = netInstance.cppFunc:readRecvString(128)         --分享标题
        data.szShareContent = netInstance.cppFunc:readRecvString(128)       --分享内容
        data.szShareUrl = netInstance.cppFunc:readRecvString(128)           --分享链接
        data.szShareImg = netInstance.cppFunc:readRecvString(128)           --分享图片
        self.tableShareParameter[data.cbTargetID] = data
    
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_SETTING_CONFIG then
        local data = {}
        data.dwChannelID = netInstance.cppFunc:readRecvDWORD()                   --渠道ID
        data.szSettingInfo = netInstance.cppFunc:readRecvString(256)             --设置信息
        data.szSettingInfo = string.gsub(data.szSettingInfo, "\\n","\n")
        self.tableCustomerParameter = data
        
    else
    
    end
    
end

function Share:SUB_CL_LOGON_SUCCESS(event)
    self.tableShareParameter = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL,NetMsgId.REQ_SHARE,"")
    self.tableCustomerParameter = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL,NetMsgId.REQ_CL_SETTINT_CONFIG,"d",CHANNEL_ID)
end

--分享和邀请
function Share:doShare(data,callback)
    self.shareCallback = callback
    --如果是战绩链接强行改成微信好友
    if data.cbTargetType == 16 then
        data.cbTargetType = 2
        data.cbShareType = 1
    end
    local szParameter = ""
    if data.cbShareType == 1 then
        szParameter = data.szShareUrl
        print("分享连接",data.cbTargetID,data.cbTargetType,data.cbShareType,data.szShareTitle,data.szShareContent,szParameter)
    elseif data.cbShareType == 2 then
        local szShareUrl = string.gsub(data.szShareUrl, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
        szParameter = string.format(HttpUrl.POST_URL_DownShareImg, StaticData.Channels[CHANNEL_ID].ChannelType,CHANNEL_ID,data.cbTargetID, szShareUrl)
        print("分享图片",data.cbTargetID,data.cbTargetType,data.cbShareType,data.szShareTitle,data.szShareContent,szParameter)
    elseif data.cbShareType == 3 then
        szParameter = data.szShareImg
        print("分享本地图片",data.cbTargetID,data.cbTargetType,data.cbShareType,data.szShareTitle,data.szShareContent,szParameter)
    else
        return
    end

    local function doShareSDK()
        if data.cbShareType == 3 then
            data.cbShareType = 2
        end
        if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
            local methodName = "jniDoShare" 
            local args = {tostring(data.cbTargetType),tostring(data.cbShareType),data.szShareTitle,data.szShareContent,szParameter}  
            local sigs = "(Ljava/lang/String;Ljava/lang/String;I)V" 
            luaj.callStaticMethod(self.className ,methodName,args , nil)
        elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
            cus.JniControl:getInstance():doShare(data.cbTargetType,data.cbShareType,data.szShareTitle,data.szShareContent,szParameter)
        end
    end

    local function downloadimage()
        local filename = string.format("downloadshareimage_%d.png",data.cbTargetID)
        local filepath = FileDir.dirTemp..filename
        -- local preAddr = cc.UserDefault:getInstance():getStringForKey(filename,"")  
        -- if preAddr == szParameter and cc.FileUtils:getInstance():isFileExist(filepath) then
        --     szParameter = filepath
        --     doShareSDK()
        --     return
        -- end

        if cc.FileUtils:getInstance():isFileExist(filepath) then
            local texture = cc.TextureCache:getInstance():addImage(filepath)
            if texture then
                cc.TextureCache:getInstance():removeTexture(texture)
            end
        end

        local xmlHttpRequest = cc.XMLHttpRequest:new()
        xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
        xmlHttpRequest:setRequestHeader("Content-type","image/jpg")
        xmlHttpRequest:open("GET",szParameter)
        local function onHttpRequestaddr()
            if xmlHttpRequest.status == 200 then
                local response = xmlHttpRequest.response
                local fp = io.open(filepath,"wb+")
                if fp == nil then
                    if self.shareCallback then
                        self.shareCallback(-1)
                    end
                    return
                end
                fp:write(response)
                fp:close()

                szParameter = filepath
                doShareSDK()
            else
                print("下载图片错误!",szParameter)
                if self.shareCallback then
                    self.shareCallback(-1)
                end
            end
            cc.UserDefault:getInstance():setStringForKey(filename, szParameter)
        end
        xmlHttpRequest:registerScriptHandler(onHttpRequestaddr)
        xmlHttpRequest:send()
    end

    if data.cbShareType == 2 then
        downloadimage()
    else
        doShareSDK()
    end
end

--聊天室回调
function cc.exports.uploadFileResult(data)
    print("uploadFileResult:",data)
end

--分享和邀请回调
function cc.exports.setWeShareResult(data)
    if Share.shareCallback ~= nil then
        local scene = cc.Director:getInstance():getRunningScene()
        scene:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) Share.shareCallback(tonumber(data)) end)))
    end
end

function Share:openURL(webUrl)
    print("网页1：",webUrl)
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
        print("网页2：",webUrl)
        local methodName = "JniOpenWeb" 
        local args = { webUrl }  
        local sigs = "(Ljava/lang/String;)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():openURL(webUrl)
    end
end



return Share