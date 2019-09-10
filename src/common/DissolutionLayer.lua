local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")


local DissolutionLayer = class("DissolutionLayer", function()
    return ccui.Layout:create()
end)


function DissolutionLayer:create(player,data)
    local view = DissolutionLayer.new()
    view:onCreate(player,data)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit()
        elseif eventType == "cleanup" then
            view:onCleanup()
        end  
    end
    view:registerScriptHandler(onEventHandler)
    return view
end

function DissolutionLayer:onEnter()
    
end

function DissolutionLayer:onExit()
    
end

function DissolutionLayer:onCleanup()
end

function DissolutionLayer:onCreate(player,data)
    require("common.SceneMgr"):switchTips(self)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("DissolutionLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    --进度动作
    local uiText_countdown = ccui.Helper:seekWidgetByName(self.root,"Text_countdown")
    uiText_countdown:setString(string.format("%d秒后自动解散",data.dwDisbandedTime))
    uiText_countdown:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(function(sender,event) 
           uiText_countdown:setString(string.format("%d秒后自动解散",data.dwDisbandedTime))
            data.dwDisbandedTime = data.dwDisbandedTime - 1
            if data.dwDisbandedTime < 0 then
                data.dwDisbandedTime = 0
            end
        end)
    )))
    
    local uiPanel_btn = ccui.Helper:seekWidgetByName(self.root,"Panel_btn")
    uiPanel_btn:setVisible(false)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_agree"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",true)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_refuse"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE_REPLY,"o",false)
    end)
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    uiPanel_player:retain()
    uiPanel_contents:removeAllChildren()
    for i=1,8 do
        if data.dwUserIDALL[i] ~= 0 then
            local item = uiPanel_player:clone()
            uiPanel_contents:addChild(item)
            local uiImage_state = ccui.Helper:seekWidgetByName(item,"Image_state")
            if data.cbDisbandeState[i] == 1 then
                uiImage_state:loadTexture("game/dismiss/dismiss_agree.png")
            elseif data.cbDisbandeState[i] == 2 then
                uiImage_state:loadTexture("game/dismiss/dismiss_refuse.png")
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.RemoveSelf:create()))
                require("common.MsgBoxLayer"):create(2,nil,string.format("%s拒绝解散房间",data.szNickNameALL[i])) 
                return
            else
                uiImage_state:loadTexture("game/dismiss/dismiss_wait.png")
                if data.dwUserIDALL[i] == UserData.User.userID then
                    uiPanel_btn:setVisible(true)
                end
            end
            local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
            uiText_name:setColor(cc.c3b(132,52,12))
            uiText_name:setString(data.szNickNameALL[i])
            local uiImage_avatar = ccui.Helper:seekWidgetByName(item,"Image_avatar")
            Common:requestUserAvatar(data.dwUserIDALL[i],player[i-1].szPto,uiImage_avatar,"clip")
            local uiImage_clip = ccui.Helper:seekWidgetByName(item,"Image_clip")
        end
    end
    uiPanel_player:release()

    local items = uiPanel_contents:getChildren()
    local size = uiPanel_player:getContentSize()
    local contentSize = uiPanel_contents:getContentSize()
    local interval = contentSize.width/(#items+1)
    for k,v in pairs(items) do
        v:setPosition(interval*k,contentSize.height/2)
    end
end

return DissolutionLayer
    