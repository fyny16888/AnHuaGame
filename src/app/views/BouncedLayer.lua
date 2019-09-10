local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameConfig = require("common.GameConfig")


local BouncedLayer = class("BouncedLayer", cc.load("mvc").ViewBase)


function BouncedLayer:onEnter()

end

function BouncedLayer:onExit()

end

function BouncedLayer:onCreate(parames)
    cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_TuHaoActivity,os.time())  
    local data = parames[1]

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("BouncedLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        self:removeFromParent()
    end)

    local Image_bg = self.root:getChildByName("Image_bg")
    local callback = function()
        require("common.SceneMgr"):switchOperation()
    end
    --Common:playPopupAnim(Image_bg, nil, callback)
end 

return BouncedLayer