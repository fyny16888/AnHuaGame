---------------
--   聊天
---------------
local DDZChat = class("DDZChat", cc.load("mvc").ViewBase)
local DDZGameCommon = require("game.puke.DDZGameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local Common = require("common.Common")
local MAXNUM = 20 --最大容量
function DDZChat:onConfig()
	self.widget = {
		{'mask'},
		{'sendClick', 'onSendCall'},
		{'TextField'},
		{'tempdes'},
		{'emTempLate'},
		{'templatelab'},
		{'head_2', 'onClickHead'},
		{'head_1', 'onClickHead'},
		{'page_1'},
		{'page_2'},
		{'templateTextEmoj'},
		{'head_2_child'},
		{'head_1_child'},
		{'Image_Chat'},
	}
	self.pageView = {}
	self.allButton = {}
end

function DDZChat:onEnter()
	EventMgr:registListener('SUB_GR_SEND_CHAT', self, self.SUB_GR_SEND_CHAT)
	EventMgr:registListener('SUB_GF_USER_EXPRESSION', self, self.SUB_GF_USER_EXPRESSION)
end

function DDZChat:onExit()
	EventMgr:unregistListener('SUB_GR_SEND_CHAT', self, self.SUB_GR_SEND_CHAT)
	EventMgr:unregistListener('SUB_GF_USER_EXPRESSION', self, self.SUB_GF_USER_EXPRESSION)
end

function DDZChat:onCreate(params)
	self.tempdes:setVisible(false)
	self.templateTextEmoj:setVisible(false)
	self.usePage = nil
	self:addMaskListen()
	self:initEmSetting()
	self:initChatLab()
	self.page_1:setVisible(false)
	self.page_2:setVisible(false)

	self.isOS = PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL
	self:createrInput()
	if self.isOS then
		self.TextField:setText('')
	else
		self.TextField:setString('')
	end
	self:showPage('head_1')
end

function DDZChat:createrInput( ... )

	if self.isOS then
		self.TextField = ccui.EditBox:create(cc.size(300.00,60.00), "chat/xitongliaotiandi.png")
		self.TextField:setPosition(cc.p(0,0))
		self.TextField:setAnchorPoint(cc.p(0,0))
		self.TextField:setFontSize(23)
		self.TextField:setPlaceHolder("最多输入30个字")
		self.TextField:setPlaceholderFontSize(20)
		self.TextField:setFontColor(cc.c3b(148, 93, 30))
		self.TextField:setMaxLength(30)
		self.TextField:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		self.TextField:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
		self.TextField:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		self.Image_Chat:addChild(self.TextField)
	else
		self.TextField:setVisible(not self.isOS)
	end

end

function DDZChat:initEmSetting(...)
	--50 为了做分页给每页表情赋值一个id
	self:initOneEmjio('page1_Button_1', 'page1_ScrollView_1', 'press_1', 23, 0)
end

--初始化表情 --page1_ScrollView_1
function DDZChat:initOneEmjio(btnName, listName, press, index, start)
	local scrollview = self:seekWidgetByNameEx(self.csb, listName)
	local viewSize = scrollview:getContentSize()
	local anim = require("game.puke.Animation") [index]
	self.emTempLate:setVisible(false)
	local y = self.emTempLate:getSize()
	local count = #anim
	local contentSize = 0
	
	contentSize = math.floor(count / 3) *(y.height) - 30
	
	if contentSize <= viewSize.height then
		contentSize = viewSize.height
	end
	scrollview:setInnerContainerSize(cc.size(viewSize.width, contentSize))
	for i = 1, count do
		local node = self.emTempLate:clone()
		node:setVisible(true)
		local path = anim[i].pngPath
		node:loadTextures(path, path)
		node:setName(i + start)
		node:ignoreContentAdaptWithSize(true)
		local size = node:getSize()
		local row = math.floor((i - 1) / 3) -- 5行
		local colum =(i - 1) % 3  -- 3行
		local posx = 80 +((size.width + 30) * colum)
		local posy = contentSize -(size.height / 2) *(row + 1) - 30 * row
		node:setPosition(posx, posy)
		self:addListener(node, handler(self, self.buttonCall))
		scrollview:addChild(node)
	end
	
	local btn = self:seekWidgetByNameEx(self.csb, btnName)
	if btn then
		self:addListener(btn, handler(self, self.emButtonCall))
	end
end

--初始化 文本 从100开始
function DDZChat:initChatLab(...)
	local chat = require("game.puke.ChatConfig")
	local scrollview = self:seekWidgetByNameEx(self.csb, 'page2_ScrollView')
	local viewSize = scrollview:getContentSize()
	local imgPath = 'puke/face/'
	self.templatelab:setVisible(false)
	local y = self.templatelab:getSize()
	local contentSize = #chat *(y.height + 5)
	scrollview:setInnerContainerSize(cc.size(viewSize.width, contentSize))
	for i = 1, #chat do
		local node = self.templatelab:clone()
		node:setVisible(true)
		node:setTitleText(chat[i].text)
		node:setName(100 + i)
		local size = node:getSize()
		local posy = contentSize + 130 -(size.height +20) * i 
		node:setPosition(40, posy)
		self:addListener(node, handler(self, self.clickExpressLab))
		scrollview:addChild(node)
	end
end


function DDZChat:addMaskListen(...)
	self.mask:setTouchEnabled(true)
	self.mask:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			self:closeView()
		end
	end)
end

function DDZChat:addPanelListen(item, call)
	item:setTouchEnabled(true)
	item:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			if call then
				call(sender)
			end
		end
	end)
end

function DDZChat:closeView(...)
	self:setVisible(false)
end

function DDZChat:onSendCall(...)
	local contents = ''
	if self.isOS then
		contents = self.TextField:getText()
	else
		contents = self.TextField:getString()
	end
	if #contents == 0 then
		return
	end
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	DDZGameCommon:getRoleChairID(), 0, DDZGameCommon:getUserInfo(DDZGameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
	self:setVisible(false)
	self:removeFromParent()
end

function DDZChat:clickExpressLab(sender)
	
	local chat = require("game.puke.ChatConfig")
	local index = sender:getName() or 1
	local chatContent = chat[tonumber(index) - 100]
	local contents = ''
	if chatContent then
		contents = chatContent.text
	end
	self:hidePage(self.page_2)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_USER_SEND_CHAT, "dwbnsdns",
	DDZGameCommon:getRoleChairID(), index, DDZGameCommon:getUserInfo(DDZGameCommon:getRoleChairID()).cbSex, 32, "", string.len(contents), string.len(contents), contents)
	self:removeFromParent()
end

function DDZChat:onClickHead(sender)
	local name = sender:getName()
	
	self:showPage(name)
end

function DDZChat:showPage( hedeName )
	if hedeName == 'head_1' then
		self.page_1:setVisible(true)
		self.page_2:setVisible(false)
		self:setUsetPage(self.page_1)
		self.head_1_child:setVisible(true)
		self.head_2_child:setVisible(false)
	elseif hedeName == 'head_2' then
		self.page_2:setVisible(true)
		self.page_1:setVisible(false)
		self:setUsetPage(self.page_2)
		self.head_1_child:setVisible(false)
		self.head_2_child:setVisible(true)
	end
end

function DDZChat:hidePage(page)
	local isShow = page:isVisible()
	page:setVisible(not isShow)
	self:setUsetPage(page)
end

function DDZChat:setUsetPage(page)
	if self.usePage and self.usePage ~= page then
		self.usePage:setVisible(false)
	end
	self.usePage = page
end

function DDZChat:buttonCall(sender)
	local index = sender:getName()
	self:hidePage(self.page_1)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EXPRESSION, "ww", index, DDZGameCommon:getRoleChairID())
	self:removeFromParent()
end

function DDZChat:emButtonCall(sender)
	local name = sender:getName()
	self:showPage(name)
end


function DDZChat:addListener(btn, callback)
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


function DDZChat:SUB_GR_SEND_CHAT(event)

end

function DDZChat:SUB_GF_USER_EXPRESSION(event)

end

return DDZChat 