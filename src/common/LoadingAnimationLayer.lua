function cc.exports.closeLoadingAnimationLayer()
    cc.Director:getInstance():getRunningScene():removeChildByTag(LAYER_GLOBAL)
end


local LoadingAnimationLayer = class("common.LoadingAnimationLayer", function()
    return cc.Node:create()
end)


function LoadingAnimationLayer:create(...)
    local view = LoadingAnimationLayer.new()
    view:onCreate(...)
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

function LoadingAnimationLayer:onCreate(...)
    local parameter = {...}
    local time = parameter[1]
    local node = parameter[2]
    local localZOrder = parameter[3]
    local tag = parameter[4]
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    --self:addChild(cc.LayerColor:create(cc.c4b(0,0,0,170)))
        
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("common/jiazaizhongdonghua/jiazaizhongdonghua.ExportJson")
    local armature = ccs.Armature:create("jiazaizhongdonghua")
    armature:setAnchorPoint(cc.p(0.5,0.5))
    armature:setPosition(visibleSize.width/2,visibleSize.height/2)
    armature:getAnimation():playWithIndex(0)
    self:addChild(armature)
    
    if time == nil then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(3) , cc.RemoveSelf:create())) 
    elseif time >= 0 then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(time) , cc.RemoveSelf:create())) 
    else

    end
    
    cc.Director:getInstance():getRunningScene():removeChildByTag(LAYER_GLOBAL)
    if node ~= nil then
        if localZOrder ~= nil and tag ~= nil then 
            node:addChild(self,localZOrder,tag)
        else
            node:addChild(self)
        end
    else
        require("common.SceneMgr"):switchGlobal(self)
    end
    
    local function onTouchBegan(touch , event)
        return true
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,self)
    
end

return LoadingAnimationLayer
