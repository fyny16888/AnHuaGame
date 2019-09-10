local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local RewardLayer = class("RewardLayer", function()
    return cc.Node:create()
end)

--@param    title: 奖励标题
--@return   node: 制定加入的父节点
--require("common.RewardLayer"):create("充值成功",nil,{{wPropID = 1001,dwPropCount = 1000},{wPropID = 1003,dwPropCount = 10}})



function RewardLayer:create(title,node,...)
    local view = RewardLayer.new()
    view:onCreate(title,node,...)
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

function RewardLayer:onEnter()

end

function RewardLayer:onExit()

end

function RewardLayer:onCleanup()

end

function RewardLayer:onCreate(title,node,...)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RewardLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    require("common.Common"):playEffect("common/sound_reward.mp3")
    self.root:setScale(0)
    self.root:ignoreAnchorPointForPosition(false)
    self.root:setAnchorPoint(cc.p(0.5,0.5))
    self.root:runAction(cc.Sequence:create(cc.EaseBackOut:create(cc.ScaleTo:create(0.3,1))))
    
    local params = {...} 
    local uiListView_reward = ccui.Helper:seekWidgetByName(self.root,"ListView_reward")
    local Image_propbg = ccui.Helper:seekWidgetByName(self.root,"Image_propbg")
    Image_propbg:retain()
    uiListView_reward:removeAllItems()
    for key, var in pairs(params[1]) do
        if StaticData.Items[var.wPropID] ~= nil then
            local item = Image_propbg:clone() 
            local Image_reward = ccui.Helper:seekWidgetByName(item,"Image_reward")
            
            if var.wPropID == 1003 and ( CHANNEL_ID == 20 or CHANNEL_ID == 21 ) then 
                var.wPropID = 1002   --房卡转钻石
            end 
            Image_reward:loadTexture(StaticData.Items[var.wPropID].img)
            uiListView_reward:pushBackCustomItem(item)
            local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
            uiText_name:setString(StaticData.Items[var.wPropID].name)
            uiText_name:setColor(cc.c3b(255 , 255 , 0))           
            local uiText_count = ccui.Helper:seekWidgetByName(item,"Text_count")
            uiText_count:setString(var.dwPropCount)
            
            --self.Particle_bg = cc.ParticleSystemQuad:create("kuosanxing.plist")    
                
            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("common/donghuagongxihuode/donghuagongxihuode.ExportJson")
            self.armaturecj = ccs.Armature:create("donghuagongxihuode")
            self.armaturecj:getAnimation():playWithIndex(0)
            self.armaturecj:setPosition(100,100)
            item:addChild(self.armaturecj,-1)    
        end
    end
    Image_propbg:release()
    
    if node ~= nil then
        node:addChild(self)
    else
        require("common.SceneMgr"):switchTips(self)
    end
    
    local function onTouchBegan(touch , event)
        self.root:setScale(1)
        self.root:runAction(cc.ScaleTo:create(0.2,0))
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2),cc.RemoveSelf:create()))
        return true
    end
    uiListView_reward:refreshView() 
    
    uiListView_reward:setPositionX(cc.Director:getInstance():getVisibleSize().width/2-uiListView_reward:getInnerContainerSize().width/2)--
    uiListView_reward:setDirection(ccui.ScrollViewDir.none)

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,self) 
end

return RewardLayer
