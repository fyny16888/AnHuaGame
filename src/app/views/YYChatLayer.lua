---=========================================---
--des:聊天
--time:2018-09-14 11:33:42
--author:fu xing
---=========================================---
local EventMgr			= require("common.EventMgr")
local EventType			= require("common.EventType")
local NetMgr				= require("common.NetMgr")
local NetMsgId			= require("common.NetMsgId")
local StaticData			= require("app.static.StaticData")
local UserData			= require("app.user.UserData")
local Common				= require("common.Common")
local Default			= require("common.Default")
local GameConfig			= require("common.GameConfig")
local Log				= require("common.Log")
local HttpUrl			= require("common.HttpUrl")
local Base64 = require("common.Base64")
local GameCommon = require("game.majiang.GameCommon")  
local YYChatLayer = class("YYChatLayer", cc.load("mvc").ViewBase)
function YYChatLayer:onConfig()
	self.widget = {
		{'Image_voice',},
		{'button_voice'},
		{'Image_voice_normal'},
		{'Image_voice_cancle'},
		{'Text_voice'},
	}
end

function YYChatLayer:onEnter()
    EventMgr:registListener(EventType.VOICE_SDK_EVENT, self, self.VOICE_SDK_EVENT)
end

function YYChatLayer:onExit()
    EventMgr:unregistListener(EventType.VOICE_SDK_EVENT, self, self.VOICE_SDK_EVENT)
	self:cancleRecording()
end

function YYChatLayer:onCreate()
	self.Image_voice:setVisible(false)
	Common:registerNodeEvent(self.button_voice, handler(self, self.voiceListen), false)
    self.Image_voice:setLocalZOrder(99)
	self.voiceTime = 0
	self.curTime = 0
	self._startTime = 0
end

--0 说话 1 输入
function YYChatLayer:setChatState( chatType ) 
	self.button_voice:setVisible(chatType == 0)
end

function YYChatLayer:voiceListen(event)
	if not self.button_voice:isVisible() then
		return
	end
	if event.name == 'end' then
		local rect = cc.rect(0, 0, self.button_voice:getContentSize().width, self.button_voice:getContentSize().height)
		local localPoint = self.button_voice:convertToNodeSpace(cc.p(event.x, event.y))
		local valid = cc.rectContainsPoint(rect, localPoint)
		self.Image_voice:setVisible(false)
		if valid then
			if self.curTime > 0 then --正常结束
				self:stopRecording()
			else
				self:cancleRecording()				
			end
		else
			self:cancleRecording()
		end
		self.button_voice:stopAllActions()
	elseif event.name == 'begin' then
		local rect = cc.rect(0, 0, self.button_voice:getContentSize().width, self.button_voice:getContentSize().height)
		local localPoint = self.button_voice:convertToNodeSpace(cc.p(event.x, event.y))
		local valid = cc.rectContainsPoint(rect, localPoint)
		if valid then
			self:startVoice()
			return valid
		end
		return true
	elseif event.name == 'moved' then
		local rect = cc.rect(0, 0, self.button_voice:getContentSize().width, self.button_voice:getContentSize().height)
		local localPoint = self.button_voice:convertToNodeSpace(cc.p(event.x, event.y))
		local valid = cc.rectContainsPoint(rect, localPoint)
		if valid then
			self:voiceState(1)
		else
			self:voiceState(0)
		end
	end
end

--开始录音
function YYChatLayer:startVoice(...)
	self.Image_voice:setVisible(true)
	self.curTime = 30
	self.Text_voice:setString(self.curTime)
	
	self._startTime = os.time()
	self.voiceTime = 0
	self.button_voice:stopAllActions()
	schedule(self.button_voice, handler(self, function()
		self.curTime = self.curTime - 1
		if self.curTime >= 0 then
			self.Text_voice:setString(self.curTime)
			if self.curTime == 0 then
				self:stopRecording()
			end
		end
	end), 1)
	self:voiceState(1)
	self:startRecording()
end


function YYChatLayer:voiceState(state)
	self.Image_voice_cancle:setVisible(state == 0)
	self.Image_voice_normal:setVisible(state == 1)
end


function YYChatLayer:startRecording()
	Common:voiceEventTracking('StartRecord',1)
	--计时
	print('---开始录音')
end

--取消录音
function YYChatLayer:cancleRecording()

	Common:voiceEventTracking('StopRecord','cancel')

	self.Image_voice:setVisible(false)
end

--上传录音
function YYChatLayer:stopRecording(...)
	
	local timeLen = os.time() - self._startTime
	print('--->>>voiceTime',timeLen)

	if timeLen <= 1.5 then
		self:cancleRecording()
		return
	end
	print('-----------------------------发送语音')
	if timeLen <= 0 then
		timeLen =  1
	end
	self.voiceTime = timeLen
	print('---------------------------------xxxxxx',self.voiceTime)
	Common:voiceEventTracking('StopRecord',1)
end

function YYChatLayer:VOICE_SDK_EVENT(event)
	local data = event._usedata
	print('---->>send VOICE_SDK_EVENT')
	dump(data,'fx---------data----->>')
	--发送语音
	if self.voiceTime <= 1.5 then
		return
	end
	--NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE_YAYA,"wwwdddnsnf",GameCommon:getRoleChairID(),self.voiceTime,1,1,32,data.response,1,0)
	print('-->>>x',self.voiceTime)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE_YAYA,"bwdns",1,GameCommon:getRoleChairID(),self.voiceTime,64,data.response)
	--self.Chat:SendVoice(self.clubData.dwClubID, UserData.User.userID, UserData.User.szNickName, UserData.User.szLogoInfo, data.response, self.voiceTime)
	self.Image_voice:setVisible(false)
end

return YYChatLayer 