local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameConfig = require("common.GameConfig")


local DaiLiLayer = class("DaiLiLayer", cc.load("mvc").ViewBase)


function DaiLiLayer:onEnter()

end

function DaiLiLayer:onExit()

end

function DaiLiLayer:onCreate(parames)
    cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_TuHaoActivity,os.time())  
    local data = parames[1]

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("DailiZXLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        self:removeFromParent()
    end)

    local Button_copy1 = ccui.Helper:seekWidgetByName(self.root,"Button_copy1")
    Common:addTouchEventListener(Button_copy1,function() 
        UserData.User:copydata("dxxqp668") 
        require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
    end)

    local Button_copy2 = ccui.Helper:seekWidgetByName(self.root,"Button_copy2")
    Common:addTouchEventListener(Button_copy2,function() 
        UserData.User:copydata("dxxqp668") 
        require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
    end)

    local Button_copy3 = ccui.Helper:seekWidgetByName(self.root,"Button_copy3")
    Common:addTouchEventListener(Button_copy3,function() 
        UserData.User:copydata("dxxqp168") 
        require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
    end)

end 

return DaiLiLayer