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

local ChatLayer = class("ChatLayer", cc.load("mvc").ViewBase)
function ChatLayer:onConfig()
	self.widget = {
		{'button_exp', 'onClickExpress'},
		{'button_send', 'onSendMsg'},
		{'TextField_input'},
		{'tempLatenormal'},
		{'Panel_chat'},
		{'button_send', 'onSend'},
		{'button_exp', 'onShowExp'},
		{'Image_voice',},
		{'button_voice'},
		{'Image_voice_normal'},
		{'Image_voice_cancle'},
		{'Text_voice'},
		{'templateEm'},
		{'club_name'},
		{'club_id'},
		{'Image_chat_1'},
		{'ScrollView_exp'},
		{'Image_input_chat'},
		{'button_speak','onVoice'},
		{'button_input','onInput'},
		{'Button_setting','onSettingCallBack'},
	}
end

function ChatLayer:onEnter()
	EventMgr:registListener(EventType.RET_CLUB_CHAT_MSG, self, self.RET_CLUB_CHAT_MSG)
	EventMgr:registListener(EventType.RET_CLUB_CHAT_RECORD_FINISH, self, self.RET_CLUB_CHAT_RECORD_FINISH)
	EventMgr:registListener(EventType.RET_CLUB_CHAT_RECORD, self, self.RET_CLUB_CHAT_RECORD)
	EventMgr:registListener(EventType.VOICE_SDK_EVENT, self, self.VOICE_SDK_EVENT)
end

function ChatLayer:onExit()
	EventMgr:unregistListener(EventType.RET_CLUB_CHAT_MSG, self, self.RET_CLUB_CHAT_MSG)
	EventMgr:unregistListener(EventType.RET_CLUB_CHAT_RECORD_FINISH, self, self.RET_CLUB_CHAT_RECORD_FINISH)
	EventMgr:unregistListener(EventType.RET_CLUB_CHAT_RECORD, self, self.RET_CLUB_CHAT_RECORD)
	EventMgr:unregistListener(EventType.VOICE_SDK_EVENT, self, self.VOICE_SDK_EVENT)
	self:cancleRecording()
end

function ChatLayer:onCreate(param)
	self.Chat = UserData.Chat
	self.Group = param[2]
	self.viewSize = cc.size(579, 550)
	self.cellSize = cc.size(579, 170) --宽 高
	self.listView = Common:_createList(self.viewSize, handler(self, self._itemUpdateCall), self.cellSize.width, self.cellSize.height, handler(self, self.getDataCount), nil, nil, nil, false)
	self.listView:setPosition(cc.p(6,14))
	self.Panel_chat:addChild(self.listView)
	self.Image_voice:setVisible(false)
	Common:registerNodeEvent(self.button_voice, handler(self, self.voiceListen), false)
	self:initExp()
	self.ScrollView_exp:setVisible(false)
	self.ScrollView_exp:setLocalZOrder(100)
	self.Image_voice:setLocalZOrder(99)
	self.isOS = PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL
	self:createrInput()
	self:resetData()
end

function ChatLayer:updateUI( data )
	self.clubData = data --俱乐部数据
	self:updateTitle()
	self:resetData()
	--添加推送
	self.Chat:addRefreshChatMember(self.clubData.dwClubID);
	self:ReqRecordMsg()
end

function ChatLayer:updateTitle( ... )
	self.club_name:setString(self.clubData.szClubName)
	self.club_id:setString('圈ID：' .. self.clubData.dwClubID)
	Common:requestUserAvatar(self.clubData.dwUserID, self.clubData.szLogoInfo, self.Image_chat_1, 'img')
end

function ChatLayer:resetData(  )
	self.isShowExp = false
	self.voiceTime = 0
	self.chatData = {}
	self.isFirstReq = true
	self.reqState = 0  --0正在请求中 1，请求结束 2，请求完成
	self.recordData = {}
	self._sendEmojiTime = 0 --时间间隔
	self.endMainID = 0 --最后一个mainid
	self.playItem = nil
	self.isCanClick = true
	self.clickID = nil
	if self.isOS then
		self.TextField_input:setText('')
	else
		self.TextField_input:setString('')
	end
	self.ScrollView_exp:setVisible(false)
	self:setChatState(1)
	self:updateData()
end

--0 说话 1 输入
function ChatLayer:setChatState( chatType ) 
	self.Image_input_chat:setVisible(chatType == 1)
	self.button_speak:setVisible(chatType == 1)
	self.button_voice:setVisible(chatType == 0)
	self.button_input:setVisible(chatType == 0)
end



function ChatLayer:createrInput( ... )

	if self.isOS then
		self.TextField_input = ccui.EditBox:create(cc.size(290.00,51.00), "chat/xitongliaotiandi.png")
		self.TextField_input:setPosition(cc.p(0,0))
		self.TextField_input:setAnchorPoint(cc.p(0,0))
		self.TextField_input:setFontSize(23)
		self.TextField_input:setPlaceHolder("最多输入30个字")
		self.TextField_input:setPlaceholderFontSize(20)
		self.TextField_input:setFontColor(cc.c3b(148, 93, 30))
		self.TextField_input:setMaxLength(30)
		self.TextField_input:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		self.TextField_input:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
		self.TextField_input:registerScriptEditBoxHandler(function(eventname,sender) self:_editboxHandle(eventname,sender) end)
		self.TextField_input:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		self.Image_input_chat:addChild(self.TextField_input)
	else
		self.TextField_input:setVisible(not self.isOS)
	end

end

function ChatLayer:_editboxHandle(eventname,sender)
	if eventname == "began" then
    elseif eventname == "ended" then
		-- 当编辑框失去焦点并且键盘消失的时候被调用
    elseif eventname == "return" then
		-- 当用户点击编辑框的键盘以外的区域，或者键盘的Return按钮被点击时所调用
    elseif eventname == "changed" then
        -- 输入内容改变时调用
        --content = string.trim(content)
    end
end

--更新子节点
function ChatLayer:_itemUpdateCall(index, item)
	if not item then
		item = self.tempLatenormal:clone()
		self:addHongDian(item)
		self:joinGame(item)
		self:shareGame(item)
		item:setPositionX(0)
		item:setPositionY(40)
	end
	item:setName(index + 1)
	
	self:updateChild(item, index)
	if index < 10 then
		if self:isTop() then
			local reqData = self.chatData[1]
			if reqData then
				self.endMainID = reqData.ullSign
				if self.reqState == 1 then
					self.reqState = 0
					self:ReqRecordMsg()
				end
			end
			
		end
	end
	return item
end

function ChatLayer:updateChild(item, index)
	local data = self.chatData[index + 1]
	local des				= self:seekWidgetByNameEx(item, 'des') --描述时间
	local head				= self:seekWidgetByNameEx(item, 'head') --描述时间
	local Image_chat_di		= self:seekWidgetByNameEx(item, 'Image_chat_di') --描述时间
	local content			= self:seekWidgetByNameEx(item, 'content') --描述时间
	local Image_emoj		= self:seekWidgetByNameEx(item, 'Image_emoj')
	local Image_yuyin		= self:seekWidgetByNameEx(item, 'Image_yuyin')
	local Image_hong_dian 	= self:seekWidgetByNameEx(item, 'Image_hong_dian')
	local chat_time			= self:seekWidgetByNameEx(item, 'chat_time')
	local desText			= self:seekWidgetByNameEx(item, 'desText')
	local Image_system		= self:seekWidgetByNameEx(item,'Image_system')
	local Panel_system_child	= self:seekWidgetByNameEx(item,'Panel_system_child')
	local Panel_join_game	= self:seekWidgetByNameEx(item,'Panel_join_game')

	if data.cbType ~= 4 then
		local name = Common:getShortName(data.szNickName, 7, 7)
		des:setString(name .. os.date(" %m-%d %H:%M:%S", math.floor(data.ullSign /1000)))
		Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, head, 'clip')
	end

	des:setColor(cc.c3b(99, 73, 41))
	content:setColor(cc.c3b(129, 75, 24))
	chat_time:setColor(cc.c3b(129, 75, 24))
	
	Image_yuyin:setVisible(data.cbType == 2)
	Image_chat_di:setVisible(data.cbType ~= 2)
	content:setVisible(data.cbType == 0)
	chat_time:setVisible(data.cbType == 2)
	Image_emoj:setVisible(data.cbType == 1)
	Image_system:setVisible(data.cbType == 4)
	Panel_system_child:setVisible(data.cbType == 4)
	Panel_join_game:setVisible(data.cbType == 3)
	Image_chat_di:setVisible(data.cbType ~= 4)
	head:setVisible(data.cbType ~= 4)
	Image_chat_di:setPositionY(73.44)
	des:setPositionY(93.71)
	if data.cbType == 0 then --文字
		desText:setString(data.szContents)
		content:setString(data.szContents)
		local len = desText:getStringLength()
		local frontSize = desText:getFontSize()
		local size = desText:getContentSize()
		local width = size.width
		local row = math.ceil(width / 425.00)
		if width > 425.00 then
			width = 425.00
		end

		Image_chat_di:setContentSize(cc.size(width + 30, 28 * row + 10))
		if data.dwUserID == UserData.User.userID then
			if width >= 425.00 then
				content:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT) --左对齐
			else
				content:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT) --右对齐
			end
			content:setPositionX(451)
		else
			content:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT) --右对齐
		end
	elseif data.cbType == 1 then --表情
		local path = 'chat/' .. data.cbExpression .. '.png'
		Image_emoj:loadTexture(path)
		Image_chat_di:setContentSize(cc.size(70, 60))
	elseif data.cbType == 2 then --语音
		chat_time:setString(data.szTime .. 's')
		Image_chat_di:setContentSize(cc.size(200,60))
		self:showVoice(item)
	elseif data.cbType == 4 then --大结算
		self:updateRoomInfo(item,data)
	elseif data.cbType == 3 then
		self:updateJoinRoom(item,data)
		Image_chat_di:setContentSize(cc.size(450,100))
		Image_chat_di:setPositionY(93.44)
		des:setPositionY(110)
	end
	Image_hong_dian:setVisible(not data.bHaveRead)
	
	if data.dwUserID == UserData.User.userID then --主角 
		head:setPositionX(527)
		des:setPositionX(480)
		des:setAnchorPoint(cc.p(1, 0.5))
		Image_chat_di:setScaleX(- 1)
		Image_chat_di:setPositionX(334)
		content:setAnchorPoint(cc.p(1, 1))
		Image_emoj:setPositionX(432)
		Image_chat_di:setPositionX(474)
		Image_yuyin:setScaleX(- 1)
		Image_yuyin:setPositionX(425)
		Panel_join_game:setPositionX(31)
		chat_time:setPositionX(270)
		chat_time:setAnchorPoint(cc.p(1, 0.5))
	else
		head:setPositionX(45)
		des:setAnchorPoint(cc.p(0, 0.5))
		des:setPositionX(108)
		Image_chat_di:setScaleX(1)
		Image_chat_di:setPositionX(103)
		content:setAnchorPoint(cc.p(0, 1))
		content:setPositionX(123)
		Image_emoj:setPositionX(145)
		Image_yuyin:setScaleX(1)
		Image_yuyin:setPositionX(148.95)
		Panel_join_game:setPositionX(118.09)
		chat_time:setPositionX(307.00)
		chat_time:setAnchorPoint(cc.p(0, 0.5))
	end
end

local function repeatForver( node, callback, delay,times )
	local delay = cc.DelayTime:create(delay)
	local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
	local rep = cc.RepeatForever:create(sequence)
    node:runAction(rep)
    return sequence
end

function ChatLayer:playVoiceAnimation( item ,time)
	item:stopAllActions()
	local index = 1
	local curTime = 0
	local arrys = {}
	for i=1,3 do
		local v = self:seekWidgetByNameEx(item,'Image_v_' .. i)
		table.insert( arrys, v)
		v:setVisible(false)
	end
	repeatForver(item,function ( )
		if curTime > time + 1 then
			self:showVoice(item)
			item:stopAllActions()
		else
			if arrys[index] then
				arrys[index]:setVisible(true)
			end
			index = index + 1
			if index > 4 then
				index = 1
				for i=1,3 do
					arrys[i]:setVisible(false)
				end
			end
		end
		curTime = curTime + 0.3
	end,0.3);

end


function ChatLayer:showVoice(item,isShow)
	item:stopAllActions()
	for i=1,3 do
		local v = self:seekWidgetByNameEx(item,'Image_v_' .. i)
		v:setVisible(isShow or true)
	end
end

local function SetTextProperty( text ,value)
    if text then
        text:setColor(cc.c3b(98, 59, 55))
        text:setString(value)
    end
end

function ChatLayer:updateJoinRoom(item,data)
	local des_room_num 			= self:seekWidgetByNameEx(item,'des_room_num')
	local des_round				= self:seekWidgetByNameEx(item,'des_round')
	local des_playgame			= self:seekWidgetByNameEx(item,'des_playgame')
	local des_game_des			= self:seekWidgetByNameEx(item,'des_game_des')
	SetTextProperty(des_room_num,'房间号:' .. data.dwTableID)
	SetTextProperty(des_round,'局数:' .. data.wGameCount)
	SetTextProperty(des_playgame,'玩法:' .. StaticData.Games[data.wKindID].name)
	SetTextProperty(des_game_des,'即将开始，就差你了，快来吧！')
end

--更新房间信息
function ChatLayer:updateRoomInfo(item,data )
	local Text_room_num 		= self:seekWidgetByNameEx(item,'Text_room_num')
	local Text_time				= self:seekWidgetByNameEx(item,'Text_time')
	local Text_game_name		= self:seekWidgetByNameEx(item,'Text_game_name')
	local Text_game_num			= self:seekWidgetByNameEx(item,'Text_game_num')
	local Text_game_play		= self:seekWidgetByNameEx(item,'Text_game_play')
	local Text_game_player      = self:seekWidgetByNameEx(item,'Text_game_player')
	local ListView_left_player	= self:seekWidgetByNameEx(item,'ListView_left_player')
	local ListView_right_player = self:seekWidgetByNameEx(item,'ListView_right_player')
	local Image_system		    = self:seekWidgetByNameEx(item,'Image_system')
	local Panel_system_child	= self:seekWidgetByNameEx(item,'Panel_system_child')
	local Panel_players  		= self:seekWidgetByNameEx(item,'Panel_players')
	SetTextProperty(Text_room_num,'房间号:' .. data.dwTableID )
	SetTextProperty(Text_time,os.date("%Y.%m.%d %H:%M:%S", math.floor(data.ullSign /1000)))
	local str = ''
	if data.cbPaymentMode == 0 then
		str = '群主'
	elseif data.cbPaymentMode == 1 then
		str = '房主'
	elseif data.cbPaymentMode == 2 then
		str = '大赢家'
	elseif data.cbPaymentMode == 3 then
		str = 'AA制'
	end
	SetTextProperty(Text_game_play,str)
	SetTextProperty(Text_game_name,StaticData.Games[data.wKindID].name)
	SetTextProperty(Text_game_num,data.wCurrentGameCount .. '/' .. data.wGameCount .. '局')
	-- --设置玩家
	-- --556 180  8位 玩家  2.5,-96.22
	-- --556 130  2位 玩家  2.5,-134.33
	-- --556 150  4位 玩家  2.5-119.24
	-- --556 160  6位 玩家  2.5-108.92
	local players = {}
	for i=1,8 do
		if data.dwUserID[i] and data.dwUserID[i] ~= 0 then
			local name = Common:getShortName(data.szNickName[i], 9, 9)
			table.insert( players, {name=name,score=data.lScore[i],id=data.dwUserID[i]} )
		end
	end
	local count = #players
	local info = {}
	if count <= 2 then
		info = {130,-134.33}
	elseif count <= 4 then
		info = {150,-119}
	elseif count <= 6 then
		info = {150,-108}
	elseif count <= 8 then
		info = {160,-96.2}
	end
	Panel_players:removeAllChildren()
	for i=1,count do
		local line = math.floor( (i-1) / 2 ) --多少行
		local row  = (i-1) % 2 --多少列
		local playerText = Text_game_player:clone()
		playerText:setVisible(true)
		local playerData = players[i]
		SetTextProperty(playerText,string.format( "%s:%d  %d",playerData.name,playerData.id,playerData.score))
		Panel_players:addChild(playerText)
		local posy = line * -18
		local posx = row  * 300
		playerText:setPosition(cc.p(posx,posy))
	end

	Image_system:setContentSize(cc.size(556,info[1]))
	Panel_system_child:setPosition(cc.p(2.5,info[2]))
end

--动态获取节点个数
function ChatLayer:getDataCount()
	return #self.chatData
end

function ChatLayer:shareGame( item )
	local Button_share = self:seekWidgetByNameEx(item, 'Button_share')
	Button_share:setSwallowTouches(false)
	self:addEvent(Button_share, handler(self, function()
		local index = item:getName()
		local data = self.chatData[tonumber(index)]
		if data then
			if data.cbType == 4 then
				self:startShare(data)
			end
		end
	end), true)
end

--分享
function ChatLayer:startShare( shareData )
    local data = clone(UserData.Share.tableShareParameter[4])
    data.dwClubID = shareData.dwClubID
    data.szShareTitle = string.format("战绩分享-房间号:%d,局数:%d/%d",shareData.dwTableID,shareData.wCurrentGameCount,shareData.wGameCount)
    data.szShareContent = ""
    local maxScore = 0
    for i = 1, 8 do
        if shareData.dwUserID[i] ~= nil and shareData.dwUserID[i] ~= 0 and shareData.lScore[i] > maxScore then 
            maxScore = shareData.lScore[i]
        end
    end
    for i = 1, 8 do
        if shareData.dwUserID[i] ~= nil and shareData.dwUserID[i] ~= 0 then
            if data.szShareContent ~= "" then
                data.szShareContent = data.szShareContent.."\n"
            end
            if maxScore ~= 0 and shareData.lScore[i] >= maxScore then
                data.szShareContent = data.szShareContent..string.format("【%s:%d(大赢家)】",shareData.szNickName[i],shareData.lScore[i])
            else
                data.szShareContent = data.szShareContent..string.format("【%s:%d】",shareData.szNickName[i],shareData.lScore[i])
            end
        end
	end
	data.szShareUrl = string.format(data.szShareUrl,shareData.szGameID)
	data.cbTargetType = 0x50
	data.szGameID = shareData.szGameID
	data.isInClub = true;
	require("app.MyApp"):create(data):createView("ShareLayer")
end

function ChatLayer:joinGame( item )
	local Button_joingame = self:seekWidgetByNameEx(item, 'Button_joingame')
	Button_joingame:setSwallowTouches(false)
	self:addEvent(Button_joingame, handler(self, function()
		local index = item:getName()
		local data = self.chatData[tonumber(index)]
		if data then
			if data.cbType == 3 then
				if self.clickID ~= index then
					self.clickID = index
					self.isCanClick = true
				end

				if self.isCanClick then
					performWithDelay(Button_joingame,function ( ... )
						self.isCanClick = true
					end,1)
					self.isCanClick = false
					Button_joingame:addChild(require("app.MyApp"):create(data.dwTableID):createView("InterfaceJoinRoomNode"))
				end
			end
		end
	end), true)
end

function ChatLayer:addHongDian(item)
	local Image_chat_di = self:seekWidgetByNameEx(item, 'Image_chat_di')
	Image_chat_di:setSwallowTouches(false)
	Common:addTouchEventListener(Image_chat_di, handler(self, function()
		local index = item:getName()
		local data = self.chatData[tonumber(index)]
		if data then
			if data.cbType == 2 then
				Common:voiceEventTracking('PlayDownload',data.szVoiceSign)
				local hd = self:seekWidgetByNameEx(item, 'Image_hong_dian')
				hd:setVisible(false) --红点隐藏
				self.Chat:SendHeadState(self.clubData.dwClubID, data.ullSign)
				if self.playItem then
					self:showVoice(self.playItem)
				end
				self.playItem = item
				self:playVoiceAnimation(item,data.szTime)
			end
		end
	end), true)
end


function ChatLayer:onInput( ... )
	self:setChatState(1)
end

function ChatLayer:onVoice( ... )
	self:setChatState(0)
end

function ChatLayer:onSend(...)
	local str = ''
	if self.isOS then
		str = self.TextField_input:getText()
	else
		str = self.TextField_input:getString()
	end
	if string.len(str) > 0 then
		self.Chat:SendChatWordMsg(self.clubData.dwClubID, UserData.User.userID, UserData.User.szNickName, UserData.User.szLogoInfo, str)
	else
		local view = require("common.MsgBoxLayer"):create(0, self, "内容为空")
		local pos = cc.p(view:getPosition())
		view:setPosition(cc.p(pos.x - 300,pos.y))
	end
	if self.isOS then
		self.TextField_input:setText('')
	else
		self.TextField_input:setString('')
	end
end

function ChatLayer:updateData(...)
	self.listView:reloadData()
end

function ChatLayer:onShowExp(...)
	self:hideOrShowExp()
end

function ChatLayer:onSettingCallBack( ... )
	self.Group:openChildLayer('GroupSettingLayer')
end

--是否顶部
function ChatLayer:isTop()
	if #self.chatData <= 0 then
		return false
	end
	local curX = self.listView:getContentOffset().y --当前的偏移值
	local offset = -(#self.chatData * self.cellSize.height - self.viewSize.height) --顶部的偏移值
	return curX < offset
end

function ChatLayer:hideOrShowExp()
	self.isShowExp = not self.isShowExp
	self.ScrollView_exp:setVisible(self.isShowExp)
end

--初始化表情
function ChatLayer:initExp(...)
	local viewSize = self.ScrollView_exp:getContentSize()
	for i = 1, 21 do
		local node = self.templateEm:clone()
		node:setVisible(true)
		local path = 'chat/' .. i .. '.png'
		node:loadTextures(path, path)
		--node:ignoreContentAdaptWitOhSize(true)
		node:setName(i)
		local size = node:getSize()
		local row = math.floor((i - 1) / 7) -- 5行
		local colum =(i - 1) % 7  -- 3行
		local posx = 60 +((size.width + 30) * colum)
		local posy =(viewSize.height - 50 -(size.height + 30) * row)
		node:setPosition(posx, posy)
		self:addListener(node, handler(self, self.buttonCall))
		self.ScrollView_exp:addChild(node)
	end
end


function ChatLayer:addListener(btn, callback)
	btn:setPressedActionEnabled(true)
	btn:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			if callback then
				callback(sender)
			end
		end
	end)
end

function ChatLayer:addEvent(btn, callback )
	btn:setPressedActionEnabled(true)
	btn:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			if callback then
				callback(sender)
			end
		end
	end)
end

function ChatLayer:buttonCall(sender)
	local index = sender:getName()
	self:hideOrShowExp()
	
	self._sendEmojiTime = self._sendEmojiTime or 0
	
	if os.time() - self._sendEmojiTime <= 3 then
		local view = require("common.MsgBoxLayer"):create(0, self, "说话太快啦！")
		local pos = cc.p(view:getPosition())
		view:setPosition(cc.p(pos.x - 300,pos.y))
	else
		self.Chat:SendChatExp(self.clubData.dwClubID, UserData.User.userID, UserData.User.szNickName, UserData.User.szLogoInfo, tonumber(index))
		self._sendEmojiTime = os.time()
	end
end

function ChatLayer:voiceListen(event)
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
function ChatLayer:startVoice(...)
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


function ChatLayer:voiceState(state)
	self.Image_voice_cancle:setVisible(state == 0)
	self.Image_voice_normal:setVisible(state == 1)
end


function ChatLayer:startRecording()
	Common:voiceEventTracking('StartRecord',1)
	--计时
	print('---开始录音')
end

--取消录音
function ChatLayer:cancleRecording()

	Common:voiceEventTracking('StopRecord','cancel')
	print('---取消录音')
	self.Image_voice:setVisible(false)
end

--上传录音
function ChatLayer:stopRecording(...)
	
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

function ChatLayer:gumpToButton(...)
	local y = self.listView:getContentSize().height
	if y > self.viewSize.height then
		self.listView:setContentOffset(cc.p(0, 0), false)
	end
end

--是否需要跳转底部
function ChatLayer:isCanGoto(offset)
	if math.abs(offset) <(self.cellSize.height * 6) then
		return true
	end
	return false
end

function ChatLayer:ReqRecordMsg(...)
	self.Chat:SendRecordMsg(self.clubData.dwClubID, self.endMainID)
end
------------------------------------server
function ChatLayer:RET_CLUB_CHAT_MSG(event)
	local data = event._usedata
	if data.cbType == 3
	or data.cbType == 4 
	or data.cbType == 5 then
		if not StaticData.Games[data.wKindID] then
			return
		end
 	end
	if self.clubData and data.dwClubID ~= self.clubData.dwClubID then
		return
	end

	self.Chat:sendHasReadMsg(data.dwClubID)

	table.insert(self.chatData, data)
	local offset = self.listView:getContentOffset()
	local oldOffset = offset.y - self.cellSize.height
	local isGoTo = self:isCanGoto(oldOffset)
	self:updateData()
	if data.dwUserID == UserData.User.userID then --自己输入直接跳转
		self:gumpToButton()
	else
		if isGoTo then --跳转
			self:gumpToButton()
		else
			self.listView:setContentOffset(cc.p(offsetx, oldOffset))
		end
	end
end

function ChatLayer:RET_CLUB_CHAT_RECORD_FINISH(event)
	local data = event._usedata
	
	if data.isFinish then
		self.reqState = 2 --所有结束
	else
		self.reqState = 1 --本次结束
	end
	--数据插入
	for i, v in ipairs(self.recordData) do
		table.insert(self.chatData, 1, v)
	end
	
	print('------->>>请求状态', self.reqState)
	self.recordData = {}
	self:updateData() --数据更新
	if self.isFirstReq then
		self.isFirstReq = false
		self:gumpToButton();
	end
end

function ChatLayer:RET_CLUB_CHAT_RECORD(event)
	local data = event._usedata
	if data.cbType == 3
	or data.cbType == 4 
	or data.cbType == 5 then
		if not StaticData.Games[data.wKindID] then
			return
		end
	 end
	if data.dwClubID == self.clubData.dwClubID then
		table.insert(self.recordData, data)
	end
end

function ChatLayer:VOICE_SDK_EVENT(event)
	local data = event._usedata
	print('---->>send VOICE_SDK_EVENT')
	--发送语音
	if self.voiceTime <= 1.5 then
		return
	end
	self.Chat:SendVoice(self.clubData.dwClubID, UserData.User.userID, UserData.User.szNickName, UserData.User.szLogoInfo, data.response, self.voiceTime)
	self.Image_voice:setVisible(false)
end




return ChatLayer 