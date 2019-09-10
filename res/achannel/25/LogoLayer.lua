local LogoLayer = class("LogoLayer",function()
    return ccui.Layout:create()
end)

function LogoLayer:create()
    local view = LogoLayer.new()
    view:onCreate()
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

function LogoLayer:onEnter()

end

function LogoLayer:onExit()

end

function LogoLayer:onCleanup()

end

function LogoLayer:onCreate()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local colorLayer = cc.LayerColor:create(cc.c4b(0,0,0,255))
    self:addChild(colorLayer)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2),cc.CallFunc:create(function(sender,event) 
        local logo = ccui.ImageView:create(string.format("achannel/%d/loginbg.jpg",CHANNEL_ID))
        self:addChild(logo)
        logo:setPosition(visibleSize.width/2,visibleSize.height/2)
        logo:setOpacity(0)
        logo:runAction(cc.Sequence:create(cc.FadeIn:create(0.5),cc.DelayTime:create(1.5),cc.CallFunc:create(function(sender,event) 
            local scene = cc.Director:getInstance():getRunningScene()
            scene:removeAllChildren()
            scene:addChild(require("loading.LoadingLayer"):create())
        end)))
        cc.SimpleAudioEngine:getInstance():playEffect(string.format("achannel/%d/logo.mp3",CHANNEL_ID))
    end)))
end

return LogoLayer

