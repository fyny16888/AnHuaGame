local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Default = require("common.Default")
local Common = require("common.Common")
local SolemnlyStateLayer = class("SolemnlyStateLayer", function()
    return ccui.Layout:create()
end)

local SolemnlyStateLayer = class("SolemnlyStateLayer", cc.load("mvc").ViewBase)

function SolemnlyStateLayer:onEnter()

end

function SolemnlyStateLayer:onExit()

end

function SolemnlyStateLayer:onCleanup()

end

function SolemnlyStateLayer:onCreate(expressCallback, quickCallback)    
    self:initUI()
end

------------------------------------------------------------------UI--------------------------------------------------------------

function SolemnlyStateLayer:initUI()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("SolemnlyStateLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    


    -- local bgNode = ccui.Helper:seekWidgetByName(self.root,"Panel_nameInfo")
    -- Common:playPopupAnim(bgNode)

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        -- local callback = function()
        --     require("common.SceneMgr"):switchOperation()
        -- end
        -- Common:playExitAnim(bgNode, callback)
        self:removeFromParent()
    end)

    -- Common:addTouchEventListener(self.root,function() 
    --    -- require("common.SceneMgr"):switchOperation()
    --     self:removeFromParent()
    -- end,true)
    

end













return SolemnlyStateLayer  