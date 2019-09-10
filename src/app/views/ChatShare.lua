local Common = require("common.Common")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local UserData =  require("app.user.UserData")
local ChatShare = class("ChatShare", cc.load("mvc").ViewBase)
local Bit = require("common.Bit")
function ChatShare:onConfig( )
    self.widget = {
        {'Button_close','closeChatShare'},
        {'Panel_contents'}
    }
end

--1 id 2 路径
local  shareConfig = {
    [0]={0,'newshare/newshare_0.png'},
    [1]={4,'newshare/newshare_4.png'},--战绩链接
    [2]={3,'newshare/share3.png'},--聊天室
}

function ChatShare:onCreate( params )
    local shareData = params[1]
    if shareData == nil then
        require("common.MsgBoxLayer"):create(0,nil,"分享配置错误!")
        return
    end
    local posIndex = 1
    for _,v in pairs(shareData.cbTargetType) do
        self:createButton(v,shareData,posIndex)
        posIndex = posIndex + 1
    end
end

function ChatShare:onEnter()
 
end

function ChatShare:onExit()
   
end

function ChatShare:createButton( index,sharedata ,posIndex)
    if not shareConfig[index] then
        return
    end
    local path = shareConfig[index][2]
    local item = ccui.Button:create(path,path,path)  
    Common:addTouchEventListener(item,function ()
        if index == 1
        or index == 0 then--微信好友
            self:onShare(sharedata,shareConfig[1][1])
        elseif index == 2 then
            self:shareLJ(sharedata.szGameID)
        end
    end)
    self.Panel_contents:addChild(item)

    local x = 558.46 - posIndex*240 + 90

    item:setPosition(x,100)
end

--分享
function ChatShare:onShare(shareData, index )
    require("common.LoadingAnimationLayer"):create(0.3)
    local cbTargetType = Bit:_lshift(1,index)
    local data = clone(shareData)
    data.cbTargetType = cbTargetType
    UserData.Share:doShare(data,function(ret)
    end)
end

--连接分享
function ChatShare:shareLJ(szGame)
    local chat = UserData.Chat

    local url = string.format( chat.chatShareData.szChatUrl,szGame) 
    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xmlHttpRequest:setRequestHeader("Content-Type", "application/json; charset=utf-8")
    xmlHttpRequest:open("GET",url)
    local function onHttpRequestCompleted()
        if xmlHttpRequest.status == 200 then
            require("common.MsgBoxLayer"):create(0,nil,"发送成功！")
        else
            require("common.MsgBoxLayer"):create(0,nil,"发送失败！")
        end
    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
    xmlHttpRequest:send()
end

function ChatShare:closeChatShare()
    self:removeFromParent()
end

return ChatShare

