--[[
*名称:PleaseOnlinePlayerLayer
*描述:在线邀请好友
*作者:admin
*创建日期:2018-11-01 10:30:52
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local Default           = require("common.Default")
local GameConfig        = require("common.GameConfig")
local Log               = require("common.Log")
local MEMBER_NUM        = 16

local PleaseOnlinePlayerLayer = class("PleaseOnlinePlayerLayer", cc.load("mvc").ViewBase)

function PleaseOnlinePlayerLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"TextField_playID"},
        {"Button_find", "onFind"},
        {"ScrollView_1"},
        {"ListView_1"},
        {"Image_item"},
    }
    self.recordOnlineInfo = {}
end

function PleaseOnlinePlayerLayer:onEnter()
    EventMgr:registListener(EventType.RET_GET_CLUB_ONLINE_MEMBER,self,self.RET_GET_CLUB_ONLINE_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_ONLINE_MEMBER_FINISH,self,self.RET_GET_CLUB_ONLINE_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_ONLINE_MEMBER,self,self.RET_FIND_CLUB_ONLINE_MEMBER)
end

function PleaseOnlinePlayerLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GET_CLUB_ONLINE_MEMBER,self,self.RET_GET_CLUB_ONLINE_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_ONLINE_MEMBER_FINISH,self,self.RET_GET_CLUB_ONLINE_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_ONLINE_MEMBER,self,self.RET_FIND_CLUB_ONLINE_MEMBER)
end

function PleaseOnlinePlayerLayer:onCreate(param)
	self.dwClubID = param[1]
	self.memberReqState = 0 -- 0 请求中 1-请求结束 2--全部请求结束
    self.curClubIndex = 0
	self:reqOnlineMember()
	self.ScrollView_1:addEventListenerScrollView(handler(self, self.scrollEventListen))

	self.ScrollView_1:setVisible(true)
	self.ListView_1:setVisible(false)
	self.TextField_playID:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
        elseif eventType == ccui.TextFiledEventType.insert_text then
        elseif eventType == ccui.TextFiledEventType.delete_backward then
            self.ScrollView_1:setVisible(true)
			self.ListView_1:setVisible(false)
        end
    end
    self.TextField_playID:addEventListener(textFieldEvent)
end

function PleaseOnlinePlayerLayer:reqOnlineMember()
 	local startPos = self.curClubIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GET_CLUB_ONLINE_MEMBER,"dww",self.dwClubID,startPos,endPos)
end

function PleaseOnlinePlayerLayer:scrollEventListen(sender, evenType)
	print('>>>>>>>>>>',evenType, ccui.ScrollviewEventType.scrollToBottom)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.memberReqState == 1 then
            self.memberReqState = 0
            self:reqOnlineMember()
        end
	end
end


function PleaseOnlinePlayerLayer:onClose()
    self:removeFromParent()
end

function PleaseOnlinePlayerLayer:onFind()
	if not self.ScrollView_1:isVisible() then
		return
	end
	local dwUserID = self.TextField_playID:getString()
	if dwUserID ~= "" then
		NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_FIND_CLUB_ONLINE_MEMBER,"dd",self.dwClubID, tonumber(dwUserID))
	end
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function PleaseOnlinePlayerLayer:addOnlineMember(data)
	if data.cbOnlineStatus == 100 then
		return
	end

	local item = self.Image_item:clone()
    self.ScrollView_1:addChild(item)
    item:setName('online_' .. data.dwUserID)

    local length = #self.ScrollView_1:getChildren()
    local row = length % 2
    if row == 0 then
        row = 2
    end
    local col = math.ceil(length / 2)
    local x = 211 + (row - 1) * 418
    local y = 340 - (col - 1) * 135
    item:setPosition(x, y)

    local inerSize = self.ScrollView_1:getContentSize()
    local scrollH = col * (125 + 10)
    self.ScrollView_1:setInnerContainerSize(cc.size(inerSize.width, scrollH))
    self:setCloneItem(item, data)
end

function PleaseOnlinePlayerLayer:setCloneItem(item, data)
	local Image_head     = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name      = self:seekWidgetByNameEx(item, "Text_name")
    local Text_ID    	 = self:seekWidgetByNameEx(item, "Text_ID")
    local Button_please  = self:seekWidgetByNameEx(item, "Button_please")
    Text_name:setColor(cc.c3b(144, 108, 63))
    Text_ID:setColor(cc.c3b(144, 108, 63))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_ID:setString('ID:' .. data.dwUserID)
  	
  	Button_please:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_INVITE_CLUB_ONLINE_MEMBER,"d",data.dwUserID)
			Button_please:setTouchEnabled(false)
			Button_please:setColor(cc.c3b(170, 170, 170))
			require("common.MsgBoxLayer"):create(0,nil,"邀请发送成功")
		end
	end
	Button_please:addTouchEventListener(onEventReset)
end

function PleaseOnlinePlayerLayer:findPlayerInfoByID(dwUserID)
	for k,v in pairs(self.recordOnlineInfo or {}) do
		if k == dwUserID then
			return v
		end
	end
	return false
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
--获取亲友圈在线成员
function PleaseOnlinePlayerLayer:RET_GET_CLUB_ONLINE_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    self.recordOnlineInfo[data.dwUserID] = data
    self:addOnlineMember(data)
end

function PleaseOnlinePlayerLayer:RET_GET_CLUB_ONLINE_MEMBER_FINISH(event)
	local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.memberReqState = 2
    else
        self.memberReqState = 1
    end
    self.curClubIndex = self.curClubIndex + MEMBER_NUM
end

function PleaseOnlinePlayerLayer:RET_FIND_CLUB_ONLINE_MEMBER(event)
	local data = event._usedata
    Log.d(data)

    if data.lRet == 0 and data.cbOnlineStatus ~= 100 then
    	self.ScrollView_1:setVisible(false)
		self.ListView_1:setVisible(true)
		self.ListView_1:removeAllItems()
		local item = self.Image_item:clone()
		self.ListView_1:pushBackCustomItem(item)
		self:setCloneItem(item, data)
	else
		require("common.MsgBoxLayer"):create(0,nil,"玩家ID不存在")
	end
end

return PleaseOnlinePlayerLayer