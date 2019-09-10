---------------
--   设置界面
---------------
local Common = require("common.Common")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local UserData =  require("app.user.UserData")
local PDKSetting = class("PDKSetting", cc.load("mvc").ViewBase)
local Music = require("app.user.UserData").Music
local PDKGameCommon = require("game.puke.PDKGameCommon")
function PDKSetting:onConfig()
	self.widget = {
		{'slider_1'}, --音效
		{'slider_2'}, --音乐
		{'mask','onClose'},
		{'Image_card_bg_1','changeSizeCallFunc'}, --big size
		{'Image_card_bg_2','changeSizeCallFunc'}, -- small size
		{'Image_bg_1','changeBgCallFunc'},
		{'Image_bg_2','changeBgCallFunc'},
		{'Image_bg_3','changeBgCallFunc'},
		{'Image_bg_4','changeBgCallFunc'},
		{'button_voice','changeBtnVoiceCallFunc'},
		{'Image_music','onMusicFunc'},
		{'Image_effect','onEffectFunc'},
		{'Button_dimiss','onDimissCallFunc'},
	}
	self.pageView = {}
end

function PDKSetting:initValue(...)
	self.music			= Music:getVolumeMusic()  --音乐 
	self.effectMusic 	= Music:getVolumeSound()		--音效
	self.size = self:getDefaultValue('PDKSize',1) --1 小 2 大
	self.bgNum = self:getDefaultValue('PDKBgNum',1) --1 2 3 4 依次
	--是否开启音效
	self.isShowVoice = UserData.Music:getVolumeVoice() > 0-- >0显示
end

function PDKSetting:onCreate(params)
	self:initValue()
	self:registerSliderEvent()
	self:updateSetting()
	self:updateMusic()
	self:updateEffectMusic()
end

function PDKSetting:registerSliderEvent( ... )
--音乐
	self.slider_2:setPercent(self.music * 100)
	self.slider_2:addEventListener(function(sender, eventType)
		local epsilon = sender:getPercent() / 100
		Music:setVolumeMusic(epsilon)
		self.music = epsilon
		if self.music > 0 then
			self.isMusic = true
		else
			self.isMusic = false
		end
		self:updateMusic()
	end)
	if self.music > 0 then
		self.isMusic = true
	else
		self.isMusic = false
	end
	self:updateMusic()

	--音效
	self.slider_1:setPercent(self.effectMusic * 100)
	self.slider_1:addEventListener(function(sender, eventType)
		local epsilon = sender:getPercent() / 100
		Music:setVolumeSound(epsilon)
		self.effectMusic = epsilon
		if self.effectMusic > 0 then
			self.isEffMusic = true
		else
			self.isEffMusic = false
		end
		self:updateEffectMusic()
	end)
	if self.effectMusic > 0 then
		self.isEffMusic = true
	else
		self.isEffMusic = false
	end
	self:updateEffectMusic()
end

function PDKSetting:onMusicFunc()
	self.isMusic = not self.isMusic
	if self.isMusic then
		self.music = 100
	else
		self.music = 0
	end
	Music:setVolumeMusic(self.music / 100)
	self.slider_2:setPercent(self.music)
	self:updateMusic()
end

function PDKSetting:onEffectFunc( ... )
	self.isEffMusic = not self.isEffMusic
	if self.isEffMusic then
		self.effectMusic = 100
	else
		self.effectMusic = 0
	end
	Music:setVolumeSound(self.effectMusic / 100)
	self.slider_1:setPercent(self.effectMusic)
	self:updateEffectMusic()
end

function PDKSetting:changeSizeCallFunc(sender)
	local name = sender:getName()
	if name == 'Image_card_bg_1' then
		self.size = 1
	elseif name == 'Image_card_bg_2' then
		self.size = 2
	end
	self:updateHDDH(self.size,'button_card_bg_%d',1,2)
end

function PDKSetting:changeBgCallFunc( sender )
	local name = sender:getName()
	if name == 'Image_bg_1' then
		self.bgNum = 1
	elseif name == 'Image_bg_2' then
		self.bgNum = 2
	elseif name == 'Image_bg_3' then
		self.bgNum = 3
	elseif name == 'Image_bg_4' then
		self.bgNum = 4
	end
	self:updateHDDH(self.bgNum,'button_bg_%d',1,4)
end

function PDKSetting:changeBtnVoiceCallFunc( sender )
	self.isShowVoice = not self.isShowVoice
	self:updateVoice()
end

function PDKSetting:getChangeValue( value )
	if value == 1 then
		value = 2
	else
		value = 1 
	end
	return value
end

function PDKSetting:updateSetting( )
	self:updateSlider()
	self:updateHDDH(self.bgNum,'button_bg_%d',1,4)
	self:updateHDDH(self.size,'button_card_bg_%d',1,2)
	self:updateVoice()
end

function PDKSetting:updateVoice( ... )
	local press = self.button_voice:getChildByName('press')
	press:setVisible(self.isShowVoice)
	print('----------------------------------------------------------',self.isShowVoice)

end

function PDKSetting:updateMusic(  )
	local press = self.Image_music:getChildByName('Image_close')
	press:setVisible(not self.isMusic)
end

function PDKSetting:updateEffectMusic( ... )
	local pressSec = self.Image_effect:getChildByName('Image_close')
	pressSec:setVisible(not self.isEffMusic)
end

function PDKSetting:updateHDDH(showNumb,tempLateStr,smallNum,maxNum )
	for i=smallNum,maxNum do
		local Button_g = self:seekWidgetByNameEx(self.csb,string.format( tempLateStr,i))
		local press = Button_g:getChildByName('press')
		press:setVisible(showNumb == i )
	end
end

function PDKSetting:updateSlider( ... )
	local value = self:getVoice(0,1,Music:getVolumeMusic()) * 100
	self.slider_2:setPercent(value )
	local value1 = self:getVoice(0,1,Music:getVolumeSound()) * 100
	self.slider_1:setPercent(value1)
end

function PDKSetting:onClose(...)
    self:saveSetting()
	self:removeFromParent()
	EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE)
end

function PDKSetting:saveSetting( ... )
	cc.UserDefault:getInstance():setIntegerForKey('PDKSize',self.size)
	cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',self.bgNum)
	if self.isShowVoice then
		UserData.Music:setVolumeVoice(1)
	else
		UserData.Music:setVolumeVoice(0)    
	end
	Music:saveVolume()
end

function PDKSetting:getDefaultValue( key,default )
    return cc.UserDefault:getInstance():getIntegerForKey(key,default)
end

function PDKSetting:getVoice( min,max,cur )
	if cur >= max then
		cur = max
	elseif cur <= min then
		cur = min
	end
	return cur
end

function PDKSetting:onDimissCallFunc(  )
	require("common.MsgBoxLayer"):create(1,nil,"是否确定解散房间？",function()
		NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
	end)
end

--添加slider event
function PDKSetting:addSliderEvent(slider,callBack)
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

return PDKSetting 