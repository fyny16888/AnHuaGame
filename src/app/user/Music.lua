local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local Default = require("common.Default")
local json = require("json")

local Music = { 
    volumeSound = 1,   --音效    0~1 0关 1开
    volumeVoice = 1,   --语音    0~1 0关 1开
    volumeMusic = 0,   --背景音乐    0~1 0关 1开
}

function Music:onEnter()
end 
-- local luaj = nil
-- if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
--     luaj = require("cocos.cocos2d.luaj")
-- end

--音效  语音 音量激活
function Music:storeVolumeValue()
    self.volumeSound = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Sound",1)   --音效    0~1 0关 1开
    self.volumeVoice = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Voice",1)   --语音    0~1 0关 1开
    self.volumeMusic = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Music",1)   --音乐    0~1 0关 1开
    if self.volumeSound == nil or self.volumeSound < 0 or self.volumeSound > 1 then
        self.volumeSound = 1 
    end 
    cc.SimpleAudioEngine:getInstance():setEffectsVolume(self.volumeSound)
    if self.volumeMusic == nil or self.volumeMusic < 0 or self.volumeMusic > 1 then
        self.volumeMusic =1 
    end 
    cc.SimpleAudioEngine:getInstance():setMusicVolume(self.volumeMusic)
    --cc.SimpleAudioEngine:getInstance():setVoiceVolume(self.volumeVoice)   
end 


function Music:setVolumeSound(data)    --设置音效
    if data >=0 and data <= 1 then 
        self.volumeSound = data
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(self.volumeSound)
    end 
end
function Music:setVolumeVoice(data)   --设置语音（接口有问题）
    if data >=0 and data <= 1 then 
        self.volumeVoice = data 
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(self.volumeVoice)
    end 
end
function Music:setVolumeMusic(data)   --设置音乐
    if data >=0 and data <= 1 then 
        self.volumeMusic = data 
        cc.SimpleAudioEngine:getInstance():setMusicVolume(self.volumeMusic)
    end 
end
   
function Music:getVolumeSound() 
    return self.volumeSound    
end

function Music:getVolumeVoice()
    return self.volumeVoice 
end

function Music:getVolumeMusic()
    return self.volumeMusic 
end

function Music:saveVolume()
    cc.UserDefault:getInstance():setFloatForKey("UserDefault_Sound",self.volumeSound)
    cc.UserDefault:getInstance():setFloatForKey("UserDefault_Voice",self.volumeVoice)
    cc.UserDefault:getInstance():setFloatForKey("UserDefault_Music",self.volumeMusic)
end


function Music:saveVolumeSound()
    cc.UserDefault:getInstance():setFloatForKey("UserDefault_Sound",self.volumeSound)
end

function Music:saveVolumeVoice()
    cc.UserDefault:getInstance():setFloatForKey("UserDefault_Voice",self.volumeVoice)
end

function Music:saveVolumeMusic()
    cc.UserDefault:getInstance():setFloatForKey("UserDefault_Music",self.volumeMusic)
end

return Music