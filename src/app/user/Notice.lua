local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local Default = require("common.Default")
local HttpUrl = require("common.HttpUrl")
local json = require("json")

local Notice = {
    notice = nil,           --公告
    cycleBroadcast = nil,   --大厅循环广播
    tableBroadcast = {},    --广播
}

function Notice:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS)
    
    cc.Director:getInstance():setNotificationNode(require("app.MyApp"):create():createView("BroadcastLayer"))
    
end

function Notice:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS)
end

function Notice:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIN then
        netInstance = NetMgr:getLoginInstance()
    elseif netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()

    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL  and subCmdID == NetMsgId.SUB_CL_NOTICE_CONFIG then
        --公告
        self.notice = nil
        local data = {}  
        data.dwChannelID = netInstance.cppFunc:readRecvDWORD()                    --渠道ID
        data.wNoticeType = netInstance.cppFunc:readRecvWORD()
        data.szNoticeTitle = netInstance.cppFunc:readRecvString(32)              --文字公告标题
        data.szNoticeInfo = netInstance.cppFunc:readRecvString(512)              --文字公告信息
        data.dwNoticeTime = netInstance.cppFunc:readRecvDWORD()
        if data.dwChannelID ~= 0 and data.dwChannelID ~= CHANNEL_ID then
            return
        end
        self.notice = data
        if data.wNoticeType == 1 then
            self:requestNoticeImageAddress(self.notice)  --请求公告图片
        end
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL  and subCmdID == NetMsgId.SUB_CL_BROADCAST_CONFIG then
        print("广播")
        local data = {}
        data.dwChannelID = netInstance.cppFunc:readRecvDWORD()                  --渠道ID
        data.wType = netInstance.cppFunc:readRecvWORD()                         --广播类型
        data.wRepeatCount = netInstance.cppFunc:readRecvWORD()                  --重复次数
        data.szBroadcastInfo = netInstance.cppFunc:readRecvString(256)          --广播信息
        if data.wType == 0 then
            self.cycleBroadcast = data
        else
            for i = 1, data.wRepeatCount do
                table.insert(self.tableBroadcast,#self.tableBroadcast + 1,data)
            end
        end
        
    else
    
    end

end

function Notice:SUB_CL_LOGON_SUCCESS(event)
	--发送请求公告
    self.notice = nil
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL,NetMsgId.REQ_CL_NOTICE_CONFIG,"d",CHANNEL_ID)
    --请求广播
    self.cycleBroadcast = nil
    self.tableBroadcast = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL,NetMsgId.REQ_CL_BROADCAST_CONFIG,"d",CHANNEL_ID)
end

function Notice:requestNoticeImageAddress(data)
    local isExist =  cc.FileUtils:getInstance():isFileExist(FileDir.dirTemp..data.szNoticeTitle)
    if isExist == true then
        return
    end
    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xmlHttpRequest:setRequestHeader("Content-type","image/jpg")
    xmlHttpRequest:open("GET",data.szNoticeInfo)
    local function onHttpRequestaddr()
        if xmlHttpRequest.status == 200 then
            local response = xmlHttpRequest.response
            local fp = io.open(FileDir.dirTemp..data.szNoticeTitle,"wb+")
            if fp == nil then
                print("请求公告图片创建文件失败!",FileDir.dirTemp..data.szNoticeTitle)
                return
            end
            fp:write(response)
            fp:close()
        else
            print("请求公告图片连接错误!",data.szNoticeInfo)
        end
    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestaddr)
    xmlHttpRequest:send()
end

return Notice