local Common = require("common.Common")
local UserData = require("app.user.UserData")
local GameDesc = require("common.GameDesc")
local StaticData = require("app.static.StaticData")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")

local Recommend = class("Recommend", cc.load("mvc").ViewBase)

function Recommend:onEnter()
	
end

function Recommend:onExit()
	
end

function Recommend:onCleanup()
	
end

function Recommend:onCreate()
	local visibleSize = cc.Director:getInstance():getVisibleSize()
	local csb = cc.CSLoader:createNode("Recommend.csb")
    self:addChild(csb)
    local butn_close = csb:getChildByName('Button_close')
	Common:addTouchEventListener(butn_close, function(sender, event)
		self:removeFromParent()
    end)
    local Text_weixing = csb:getChildByName('Text_weixing')
    Text_weixing:setString(StaticData.Channels[CHANNEL_ID].serviceVX_2)
    -- local Button_copy = ccui.Helper:seekWidgetByName(self.root,"Button_copy")
    local Button_copy = csb:getChildByName('Button_copy')
    Common:addTouchEventListener(Button_copy,function()   
        local btnName = Text_weixing:getString()
        UserData.User:copydata(btnName)
        require("common.MsgBoxLayer"):create(0,nil,"复制成功")
    end)
end

return Recommend

