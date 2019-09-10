--重置上一次的音量设置
local volumeMusic = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Music",1)
cc.SimpleAudioEngine:getInstance():setMusicVolume(volumeMusic)
cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)

--后台控制器
local isEnterBackground = false
function cc.exports.applicationDidEnterBackground()
    if cc.PLATFORM_OS_DEVELOPER ~= PLATFORM_TYPE then
        printInfo("applicationDidEnterBackground:进入后台")
        cc.SimpleAudioEngine:getInstance():setMusicVolume(0)
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(0)
        cc.Director:getInstance():stopAnimation()
        local event = cc.EventCustom:new("EVENT_TYPE_DID_ENTER_BACKGROUND")
        event._usedata = nil
        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end
end

function cc.exports.applicationWillEnterForeground()
    if cc.PLATFORM_OS_DEVELOPER ~= PLATFORM_TYPE then
        printInfo("applicationWillEnterForeground:恢复游戏")
        local volumeMusic = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Music",1)
        cc.SimpleAudioEngine:getInstance():setMusicVolume(volumeMusic)
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
        cc.Director:getInstance():startAnimation()
        cc.Director:getInstance():getRunningScene():runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) 
            local event = cc.EventCustom:new("EVENT_TYPE_WILL_ENTER_FOREGROUND")
            event._usedata = nil
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
        end)))
    end
end

--加载渠道logo
local scene = cc.Scene:create()
cc.Director:getInstance():replaceScene(scene)
local logoLayer = require(string.format("achannel.%d.LogoLayer",CHANNEL_ID)):create()
scene:addChild(logoLayer)
