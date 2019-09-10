local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Bit = require("common.Bit")
local HttpUrl = require("common.HttpUrl")

local AgentLayer = class("AgentLayer", function()
    return cc.Node:create()
end)


function AgentLayer:create(parames)
    local view = AgentLayer.new()
    view:onCreate(parames)
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

function AgentLayer:onEnter()
end

function AgentLayer:onExit()
end

function AgentLayer:onCreate(parames)

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("AgentLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        self:removeFromParent()
    end)  
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_Determine"),function() 
        self:removeFromParent()
    end)  

    -- local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
    -- uiText_contents:setString("")

    for i = 1 ,2 do 
       local item = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_daili%d", i))
       local uiText_wixin = ccui.Helper:seekWidgetByName(item,"Text_wixin")
        Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item,"Button_copy"),function()   
            local btnName =  uiText_wixin:getString()
            UserData.User:copydata(btnName)
            require("common.MsgBoxLayer"):create(0,nil,"已复制到剪切板")
        end) 
    end 
    -- if node ~= nil then
    --     node:addChild(self)
    -- else
        require("common.SceneMgr"):switchTips(self)
    -- end
end


return AgentLayer