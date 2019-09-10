local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameConfig = require("common.GameConfig")

local BroadcastLayer = class("BroadcastLayer", cc.load("mvc").ViewBase)

function BroadcastLayer:onEnter()

end

function BroadcastLayer:onExit()

end


function BroadcastLayer:onCreate()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("BroadcastLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    
    local uiPanel_type1 = ccui.Helper:seekWidgetByName(self.root,"Panel_type1")
    local uiPanel_type2 = ccui.Helper:seekWidgetByName(self.root,"Panel_type2")
    local uiPanel_type3 = ccui.Helper:seekWidgetByName(self.root,"Panel_type3")
    
    local items = {uiPanel_type1, uiPanel_type2, uiPanel_type3}
    for key, var in pairs(items) do
        var:setVisible(false)
    end
    
    local function onCheckBroadcast(sender,event)
        self:stopAllActions()
        if #UserData.Notice.tableBroadcast > 0 then 
            local isFound = false
            for key, var in pairs(items) do
            	if var:isVisible() == true then
            	   isFound = true
            	   break
            	end
            end
            if isFound == false then
                local data = UserData.Notice.tableBroadcast[1]
                table.remove(UserData.Notice.tableBroadcast,1)
                
                if items[data.wType] ~= nil then
                    local node = items[data.wType]
                    node:setVisible(true)
                    local uiText_broadcastInfo = ccui.Helper:seekWidgetByName(node,"Text_broadcastInfo")
                    uiText_broadcastInfo:setString(data.szBroadcastInfo)
                    local time = uiText_broadcastInfo:getAutoRenderSize().width - uiText_broadcastInfo:getParent():getContentSize().width
                    uiText_broadcastInfo:setPositionX(0)
                    if time > 0 then
                        uiText_broadcastInfo:runAction(cc.Sequence:create(
                            cc.DelayTime:create(2),
                            cc.MoveTo:create(time/100,cc.p(-time,uiText_broadcastInfo:getPositionY())),
                            cc.DelayTime:create(2),
                            cc.CallFunc:create(function(sender,event) node:setVisible(false) end),
                            cc.DelayTime:create(1),
                            cc.CallFunc:create(onCheckBroadcast)
                        ))
                    else
                        uiText_broadcastInfo:runAction(cc.Sequence:create(
                            cc.DelayTime:create(2),
                            cc.DelayTime:create(2),
                            cc.CallFunc:create(function(sender,event) node:setVisible(false) end),
                            cc.DelayTime:create(1),
                            cc.CallFunc:create(onCheckBroadcast)
                        ))
                    end
                    return
                end
            end
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onCheckBroadcast)))
    end
    onCheckBroadcast()
end

return BroadcastLayer