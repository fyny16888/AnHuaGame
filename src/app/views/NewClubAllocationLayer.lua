--[[
*名称:NewClubAllocationLayer
*描述:设置合伙人成员
*作者:admin
*创建日期:2018-11-20 11:30:52
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

local NewClubAllocationLayer = class("NewClubAllocationLayer", cc.load("mvc").ViewBase)

function NewClubAllocationLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Image_pHead"},
        {"Text_parnterName"},
        {"Text_parnterID"},
        {"TextField_playID"},
        {"Button_find", "onFind"},
        {"ScrollView_1"},
        {"ListView_1"},
        {"Image_item"},
    }
end

function NewClubAllocationLayer:onEnter()
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
end

function NewClubAllocationLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
end

function NewClubAllocationLayer:onCreate(param)
	self.data = param[1]
	self.memberReqState = 0 -- 0 请求中 1-请求结束 2--全部请求结束
    self.curClubIndex = 0
	self:reqNotPartnerMember()
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

    Common:requestUserAvatar(self.data.dwUserID, self.data.szLogoInfo, self.Image_pHead, "img")
    self.Text_parnterName:setString(self.data.szNickName)
    self.Text_parnterID:setString('ID:' .. self.data.dwUserID)
end

function NewClubAllocationLayer:onClose()
    self:removeFromParent()
end

function NewClubAllocationLayer:onFind()
	if not self.ScrollView_1:isVisible() then
		return
	end
	local dwUserID = self.TextField_playID:getString()
	if dwUserID ~= "" then
		UserData.Guild:findClubNotPartnerMember(self.data.dwClubID, tonumber(dwUserID))
	end
end


function NewClubAllocationLayer:reqNotPartnerMember()
 	local startPos = self.curClubIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    UserData.Guild:getClubNotPartnerMember(self.data.dwClubID, startPos, endPos)
end

function NewClubAllocationLayer:scrollEventListen(sender, evenType)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.memberReqState == 1 then
            self.memberReqState = 0
            self:reqNotPartnerMember()
        end
	end
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function NewClubAllocationLayer:addNotParnterMember(data)
	local item = self.Image_item:clone()
    self.ScrollView_1:addChild(item)
    item:setName('notparnter_' .. data.dwUserID)
    self:setCloneItem(item, data)
end

function NewClubAllocationLayer:refreshNotParnterMemPos()
    local inerSize = self.ScrollView_1:getContentSize()
    local arr = self.ScrollView_1:getChildren()
    local scrollH = math.ceil(#arr / 2) * (125 + 10)
    for i,v in ipairs(arr) do
        local row = i % 2
        if row == 0 then
            row = 2
        end
        local col = math.ceil(i / 2)
        local starty = 203
        if scrollH > inerSize.height then
            starty = 203 + scrollH - inerSize.height
        end
        local x = 213 + (row - 1) * 409
        local y = starty - (col - 1) * 135
        v:setPosition(x, y)
    end
    self.ScrollView_1:setInnerContainerSize(cc.size(inerSize.width, scrollH))
end

function NewClubAllocationLayer:setCloneItem(item, data)
	local Image_head     = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name      = self:seekWidgetByNameEx(item, "Text_name")
    local Text_ID    	 = self:seekWidgetByNameEx(item, "Text_ID")
    local Button_setMem  = self:seekWidgetByNameEx(item, "Button_setMem")
    Text_name:setColor(cc.c3b(144, 108, 63))
    Text_ID:setColor(cc.c3b(144, 108, 63))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_ID:setString('ID:' .. data.dwUserID)
  	
  	Button_setMem:setPressedActionEnabled(true)
	local function onEventReset(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			UserData.Guild:reqSettingsClubMember(5, data.dwClubID, data.dwUserID,self.data.dwUserID,"")
			Button_setMem:setTouchEnabled(false)
			Button_setMem:setColor(cc.c3b(170, 170, 170))
			require("common.MsgBoxLayer"):create(0,nil,"设置成员成功")
		end
	end
	Button_setMem:addTouchEventListener(onEventReset)
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
function NewClubAllocationLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    self:addNotParnterMember(data)
end

function NewClubAllocationLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH(event)
	local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.memberReqState = 2
    else
        self.memberReqState = 1
    end
    self.curClubIndex = self.curClubIndex + MEMBER_NUM
    self:refreshNotParnterMemPos()
end

function NewClubAllocationLayer:RET_FIND_CLUB_NOT_PARTNER_MEMBER(event)
	local data = event._usedata
    Log.d(data)

    if data.lRet == 0 then
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

return NewClubAllocationLayer