local Common = require("common.Common")
local CommonLayer = class("CommonLayer", function()
    return cc.Node:create()
end)

--@param    type: 0文本提示   1确定取消  2确定  3同意拒绝 
--@return   node: 制定加入的父节点


function CommonLayer:create(time,node)
    local view = CommonLayer.new()
    view:onCreate(time,node)
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

function CommonLayer:onEnter()

end

function CommonLayer:onExit()

end

function CommonLayer:onCleanup()

end

function CommonLayer:onCreate(time,node)
    if node ~= nil then
        node:addChild(self)
    else
        require("common.SceneMgr"):switchTips(self)
    end
    if time ~= nil then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(time),cc.RemoveSelf:create()))
    end
    
    local function onTouchBegan(touch,event)
        return true
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,self)
end

return CommonLayer
