cc.exports.SERVER_INFO = {
    ip = "login.paohuzi.qilaigame.com",
    port = 8585,
}
cc.exports.LAYER_SCENE = 0
cc.exports.LAYER_OPERATION = 0x100
cc.exports.LAYER_TIPS = 0x1000
cc.exports.LAYER_GLOBAL = 0x10000
cc.exports.LAYER_RECONNECT = 0x10001

cc.exports.OPEN_TAIJIDUN = true

require("common.LoadingAnimationLayer")
local SceneMgr = require("common.SceneMgr")
local FileMgr = require("common.FileMgr")
local UserData = require("app.user.UserData")
for key, var in pairs(UserData) do
    var:onEnter()
end
local StaticData = require("app.static.StaticData")
local LocationSystem = require("common.LocationSystem")

if voiceEventTracking then
    voiceEventTracking("initSDK",StaticData.Channels[CHANNEL_ID].voiceID)
end

if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    local listenerOnKey = cc.EventListenerKeyboard:create()
    listenerOnKey:registerScriptHandler(function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定要退出游戏？",function() 
            cc.Director:getInstance():endToLua()
        end)
--        local event = cc.EventCustom:new("EVENT_TYPE_PHYSICS_KEY")
--        event._usedata = nil
--        cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
    end,cc.Handler.EVENT_KEYBOARD_RELEASED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listenerOnKey,cc.Director:getInstance():getRunningScene())
end

require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true,true):createView("LoginLayer"),SCENE_LOGIN)
