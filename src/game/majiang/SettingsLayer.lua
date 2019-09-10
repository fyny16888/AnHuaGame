local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")

local SettingsLayer = class("SettingsLayer", function()
    return ccui.Layout:create()
end)

function SettingsLayer:create(wKindID)
    local view = SettingsLayer.new()
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

function SettingsLayer:onEnter()

end

function SettingsLayer:onExit()
    
end

function SettingsLayer:onCleanup()
end

function SettingsLayer:onCreate()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("SettingsMaJangLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    require("common.SceneMgr"):switchOperation(self)  
    Common:addTouchEventListener(self.root,function() 
       -- self:removeFromParent()
        self:saveSetting()
        EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE,3)
        require("common.SceneMgr"):switchOperation()
    end,true)

    self.Sound = UserData.Music:getVolumeSound()  --音效 
    self.Music = UserData.Music:getVolumeMusic()  --音乐 
    self.Voice = UserData.Music:getVolumeVoice()  --语音 

    self.isSound = cc.UserDefault:getInstance():getBoolForKey('MJisSound', true) 
    self.isMusic = cc.UserDefault:getInstance():getBoolForKey('MJisMusic', true) 
    self.isVoice = cc.UserDefault:getInstance():getBoolForKey('MJisVoice', true) 

    self.Slider_1 = ccui.Helper:seekWidgetByName(self.root,"Slider_1")
    self.Slider_2 = ccui.Helper:seekWidgetByName(self.root,"Slider_2")
    self.Slider_3 = ccui.Helper:seekWidgetByName(self.root,"Slider_3")

    self.Button_Sound = ccui.Helper:seekWidgetByName(self.root,"Button_Sound")
    self.Button_Music = ccui.Helper:seekWidgetByName(self.root,"Button_Music")
    self.Button_Voice = ccui.Helper:seekWidgetByName(self.root,"Button_Voice")
    Common:addTouchEventListener(self.Button_Sound,function() 
        UserData.Music:saveVolume()
        self:onSoundCall()
    end)
    Common:addTouchEventListener(self.Button_Music,function() 
        UserData.Music:saveVolume()
        self:onMusicCall()
    end)
    Common:addTouchEventListener(self.Button_Voice,function() 
        UserData.Music:saveVolume()
        self:onVoiceCall()
    end)

    local value1 = self:getVoice(0,1,UserData.Music:getVolumeSound()) * 100
	self.Slider_1:setPercent(value1)
	local value2 = self:getVoice(0,1,UserData.Music:getVolumeMusic()) * 100
    self.Slider_2:setPercent(value2)
    local value3 = self:getVoice(0,1,UserData.Music:getVolumeVoice()) * 100
    self.Slider_3:setPercent(value3)
    self:updateSound()
    self:updateMusic()
    self:updateVoice()
    self:registerSliderEvent()

    self.UserDefault_MaJiangCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangCard,0)   --麻将牌类型

    self.Button_card1 = ccui.Helper:seekWidgetByName(self.root,"Button_card1")
    self.Button_card2 = ccui.Helper:seekWidgetByName(self.root,"Button_card2")
    self.Button_card3 = ccui.Helper:seekWidgetByName(self.root,"Button_card3")
    self.Button_card4 = ccui.Helper:seekWidgetByName(self.root,"Button_card4")

    local function CardChange(type)
        self.UserDefault_MaJiangCard = type
        self:updateCard()
    end  
    Common:addTouchEventListener(self.Button_card1,function() CardChange(0)end)
    Common:addTouchEventListener(self.Button_card2,function() CardChange(1)end)
    Common:addTouchEventListener(self.Button_card3,function() CardChange(2)end)
    Common:addTouchEventListener(self.Button_card4,function() CardChange(3)end)

    self:updateCard()

    self.UserDefault_MaJiangCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangCard,0)   --麻将牌类型

    local uiImage_1 = ccui.Helper:seekWidgetByName(self.Button_card1,"Image")
    local uiImage_2 = ccui.Helper:seekWidgetByName(self.Button_card2,"Image")
    local uiImage_3 = ccui.Helper:seekWidgetByName(self.Button_card3,"Image")
    local uiImage_4 = ccui.Helper:seekWidgetByName(self.Button_card4,"Image")
    uiImage_1:setTouchEnabled(true)
    uiImage_2:setTouchEnabled(true)            
    uiImage_3:setTouchEnabled(true)           
    uiImage_4:setTouchEnabled(true)
    local function CardChange(type,sender)
        -- if sender == true then 
        --     Common:palyButton()
        -- end 
        self.UserDefault_MaJiangCard = type
        self:updateCard()
    end  
    Common:addTouchEventListener(self.Button_card1,function() CardChange(0)end)
    Common:addTouchEventListener(self.Button_card2,function() CardChange(1)end)
    Common:addTouchEventListener(self.Button_card3,function() CardChange(2)end)
    Common:addTouchEventListener(self.Button_card4,function() CardChange(3)end)
    uiImage_1:addTouchEventListener(function() CardChange(0,true)end)
    uiImage_2:addTouchEventListener(function() CardChange(1,true)end)
    uiImage_3:addTouchEventListener(function() CardChange(2,true)end)
    uiImage_4:addTouchEventListener(function() CardChange(3,true)end)

    self:updateCard()


    self.UserDefault_MaJiangpaizhuo = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_MaJiangpaizhuo,0)   --麻将牌类型

    self.Button_bg1 = ccui.Helper:seekWidgetByName(self.root,"Button_bg1")
    self.Button_bg2 = ccui.Helper:seekWidgetByName(self.root,"Button_bg2")
    self.Button_bg3 = ccui.Helper:seekWidgetByName(self.root,"Button_bg3")

    local function BGChange(type,sender)
        self.UserDefault_MaJiangpaizhuo = type
        self:updateBG()
    end  
    Common:addTouchEventListener(self.Button_bg1,function() BGChange(0)end)
    Common:addTouchEventListener(self.Button_bg2,function() BGChange(1)end)
    Common:addTouchEventListener(self.Button_bg3,function() BGChange(2)end)

    local Image_1 = ccui.Helper:seekWidgetByName(self.Button_bg1,"Image")
    local Image_2 = ccui.Helper:seekWidgetByName(self.Button_bg2,"Image")
    local Image_3 = ccui.Helper:seekWidgetByName(self.Button_bg3,"Image")
    Image_1:setTouchEnabled(true)
    Image_2:setTouchEnabled(true)            
    Image_3:setTouchEnabled(true)     
    Image_1:addTouchEventListener(function() BGChange(0,true)end)
    Image_2:addTouchEventListener(function() BGChange(1,true)end)
    Image_3:addTouchEventListener(function() BGChange(2,true)end)      


    self:updateBG()

    local uiButton_disbanded = ccui.Helper:seekWidgetByName(self.root,"Button_disbanded")
    Common:addTouchEventListener(uiButton_disbanded,function() 
        require("common.MsgBoxLayer"):create(1,nil,"是否确定解散房间？",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
        end)
    end)

    -- self:initSound() 
end

function SettingsLayer:saveSetting()
	--cc.UserDefault:getInstance():setFloatForKey('CDmusic',self.music)
    cc.UserDefault:getInstance():setBoolForKey('MJisSound', self.isSound) 
    cc.UserDefault:getInstance():setBoolForKey('MJisMusic', self.isMusic) 
    cc.UserDefault:getInstance():setBoolForKey('MJisVoice', self.isVoice) 
    UserData.Music:saveVolume()
	-- cc.UserDefault:getInstance():setBoolForKey('CDisEffMusic',self.isEffMusic)
	-- cc.UserDefault:getInstance():setBoolForKey('CDisFastEat',self.isFastEat)
	-- cc.UserDefault:getInstance():setBoolForKey('CDisOpenTin',self.isOpenTin)
	-- cc.UserDefault:getInstance():setIntegerForKey('CDvolumeSelect',self.volumeSelect)
	-- cc.UserDefault:getInstance():setIntegerForKey('CDspeed',self.speed)
	-- cc.UserDefault:getInstance():setIntegerForKey('CDpaiSize',self.paiSize)
	-- cc.UserDefault:getInstance():setIntegerForKey('CDlineHeight',self.lineHeight)
    -- cc.UserDefault:getInstance():setIntegerForKey('CDzipaiBg',self.bgNum)

    -- if GameCommon:isSelectCDGameType() then
    -- 	cc.UserDefault:getInstance():setIntegerForKey('CDzipaiSelect',self.zipaiSelect)
    -- else
	-- 	cc.UserDefault:getInstance():setIntegerForKey('HYzipaiSelect',self.zipaiSelect)
    -- end
end

function SettingsLayer:getVoice( min,max,cur )
	if cur >= max then
		cur = max
	elseif cur <= min then
		cur = min
	end
	return cur
end

function SettingsLayer:registerSliderEvent( ... )
	--音乐
	local callFunc = function ( epsilon )
        self:SoundChange(epsilon)
        print("+++++++++++移动滑条",epsilon)
	end
	self:addSliderEvent(self.Slider_1,callFunc)

	--音效
	local callFunc1 = function ( epsilon )
		self:MusicChange(epsilon)
	end
    self:addSliderEvent(self.Slider_2,callFunc1)
    
    --语音
	local callFunc2 = function ( epsilon )
		self:VoiceChange(epsilon)
	end
	self:addSliderEvent(self.Slider_3,callFunc2)
end


function SettingsLayer:SoundChange( epsilon )
	UserData.Music:setVolumeSound(epsilon)    
    if epsilon <= 0 then 
        self.isSound = false
    else   
        self.isSound = true
    end 
    self:updateSound()
end

function SettingsLayer:MusicChange( epsilon )
	UserData.Music:setVolumeMusic(epsilon)
    if epsilon <= 0 then 
        self.isMusic = false
    else   
        self.isMusic = true       
    end 
    self:updateMusic()
end

function SettingsLayer:VoiceChange( epsilon )
	UserData.Music:setVolumeVoice(epsilon)
    if epsilon <= 0 then 
        self.isVoice = false
    else   
        self.isVoice = true
    end         
    self:updateVoice()
end

--==============================--
--desc: 声音设置
--@return 
--==============================--
function SettingsLayer:onSoundCall()
    print("++++++++++按钮点击1",self.isSound)
    self.isSound = not self.isSound
    print("++++++++++按钮点击2",self.isSound)
	if self.isSound then
		self.Slider_1:setPercent(100)
		self:SoundChange(1)
	else
		self.Slider_1:setPercent(0)
		self:SoundChange(0)
	end
	self:updateSound()
end

function SettingsLayer:onMusicCall()
	self.isMusic = not self.isMusic
	if self.isMusic then
		self.Slider_2:setPercent(100)
		self:MusicChange(1)
	else
		self.Slider_2:setPercent(0)
		self:MusicChange(0)
	end
	self:updateMusic()
end

function SettingsLayer:onVoiceCall()
	self.isVoice = not self.isVoice
	if self.isVoice then
		self.Slider_3:setPercent(100)
		self:VoiceChange(1)
	else
		self.Slider_3:setPercent(0)
		self:VoiceChange(0)
	end
	self:updateVoice()
end


function SettingsLayer:updateSound(...)
    self.Button_Sound:setBright(self.isSound)
end

function SettingsLayer:updateMusic(...)
    self.Button_Music:setBright(self.isMusic)
end

function SettingsLayer:updateVoice(...)
    self.Button_Voice:setBright(self.isVoice)
end

function SettingsLayer:updateCard( )
    self.Button_card1:setBright(false)
    self.Button_card2:setBright(false)
    self.Button_card3:setBright(false)
    self.Button_card4:setBright(false)
    if self.UserDefault_MaJiangCard == 0 then
        self.Button_card1:setBright(true)
    elseif  self.UserDefault_MaJiangCard == 1 then
        self.Button_card2:setBright(true)
    elseif  self.UserDefault_MaJiangCard == 2 then
        self.Button_card3:setBright(true)
    elseif  self.UserDefault_MaJiangCard == 3 then
        self.Button_card4:setBright(true)
    end 

    cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_MaJiangCard,self.UserDefault_MaJiangCard)
end

function SettingsLayer:updateBG( )
    self.Button_bg1:setBright(false)
    self.Button_bg2:setBright(false)
    self.Button_bg3:setBright(false)
    if self.UserDefault_MaJiangpaizhuo == 0 then
        self.Button_bg1:setBright(true)
    elseif  self.UserDefault_MaJiangpaizhuo == 1 then
        self.Button_bg2:setBright(true)
    elseif  self.UserDefault_MaJiangpaizhuo == 2 then
        self.Button_bg3:setBright(true)
    end 

    cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_MaJiangpaizhuo,self.UserDefault_MaJiangpaizhuo)
end



function SettingsLayer:initSound()

    --版本信息
    -- local uiText_edition = ccui.Helper:seekWidgetByName(self.root,"Text_edition")
    -- if require("loading.Update").version ~= "" then
    --     local versionInfo = string.format("%s",require("loading.Update").version)
    --     versionInfo ="版本:".. versionInfo
    --     uiText_edition:setString(versionInfo)
    -- end       

    local uiButton_kai_1 = ccui.Helper:seekWidgetByName(self.root,"Button_kai_1")
    local volumeSound = UserData.Music:getVolumeSound()   

    Common:addTouchEventListener(uiButton_kai_1,function() 
        if volumeSound == 1 then
            UserData.Music:setVolumeSound(0) 
            uiButton_kai_1:setBright(false)
            volumeSound = 0
        else
            UserData.Music:setVolumeSound(1) 
            uiButton_kai_1:setBright(true)
            volumeSound = 1 
        end
    end)
    if volumeSound == 1 then
        uiButton_kai_1:setBright(true)
    else
        uiButton_kai_1:setBright(false)
    end
    

    local uiButton_kai_2 = ccui.Helper:seekWidgetByName(self.root,"Button_kai_2")
    local volumeMusic = UserData.Music:getVolumeMusic()   
    Common:addTouchEventListener(uiButton_kai_2,function() 
        if volumeMusic == 1 then
            UserData.Music:setVolumeMusic(0) 
            uiButton_kai_2:setBright(false)
            volumeMusic = 0 
        else
            UserData.Music:setVolumeMusic(1) 
            uiButton_kai_2:setBright(true)
            volumeMusic = 1 
        end
    end)
    if volumeMusic == 1 then
        uiButton_kai_2:setBright(true)
    else
        uiButton_kai_2:setBright(false)
    end

    local uiButton_logout = ccui.Helper:seekWidgetByName(self.root,"Button_logout")
    Common:addTouchEventListener(uiButton_logout,function()    
            UserData.Music:saveVolume()    
            NetMgr:getLogicInstance():closeConnect()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,false):createView("LoginLayer"),SCENE_LOGIN)
            EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
    end)
           
    -- local uiImage_avatar = ccui.Helper:seekWidgetByName(self.root,"Image_avatar")
    -- Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiImage_avatar,"img")
    --  local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")
    -- uiText_name:setString(string.format("%s",UserData.User.szNickName))
    -- local Update = require("loading.Update")    
end

--添加slider event
function SettingsLayer:addSliderEvent(slider,callBack)
	if slider then
		slider:addEventListener(function( sender,eventType )
			local epsilon = sender:getPercent() / 100
			if epsilon >= 0 or epsilon <= 1 then
				if callBack then
					callBack(epsilon)
				end
			end
		end)
	end
end

return SettingsLayer
    