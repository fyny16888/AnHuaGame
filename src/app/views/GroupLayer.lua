---=========================================---
--des:聊天室
--time:2018-09-30 10:17:58
--author:fu xing
---=========================================---
local EventMgr			= require("common.EventMgr")
local EventType			= require("common.EventType")
local NetMgr			= require("common.NetMgr")
local NetMsgId			= require("common.NetMsgId")
local StaticData		= require("app.static.StaticData")
local UserData			= require("app.user.UserData")
local Common			= require("common.Common")
local Default			= require("common.Default")
local GameConfig		= require("common.GameConfig")
local Log				= require("common.Log")
local HttpUrl			= require("common.HttpUrl")

local GroupLayer =  class("GroupLayer", cc.load("mvc").ViewBase)

function GroupLayer:onConfig()
    self.widget = {
        {'chatclublist'},
        {'chat_root'},
        {'tempcell'},
        {'group_cell'},
        {'root'},
        --{'Panel_bg','onClickPanle'},
        {'Button_back','onBack'},
    }
end

function GroupLayer:onEnter( )
    EventMgr:registListener(EventType.RET_CLUB_CHAT_GET_UNREAD_MSG, self, self.RET_CLUB_CHAT_GET_UNREAD_MSG)
    EventMgr:registListener(EventType.RET_CLUB_CHAT_MSG, self, self.RET_CLUB_CHAT_MSG)    
end

function GroupLayer:onCreate( param )
    self.Chat = UserData.Chat
    self.clubData = param[1]
    self.childLayer = {}
    self.allCell  = {} --所有节点集合
    self.selectPress = nil
    self.clickID  = nil --当前点击的cell
    self.clickClubID = nil --当前点重的id
    self.oldUI = nil
    self.newUI = nil
    self.isClickFirst = false
    self:addChildLayer('ChatLayer',nil)
    self:addChildLayer('GroupSettingLayer',nil)
    self:addChildLayer('GroupTeam',nil)
    self.rootSize = self.root:getContentSize()
	self.root:setPositionX(- self.rootSize.width / 2 - 5)
    self.root:runAction(cc.Sequence:create(cc.MoveTo:create(0.2, cc.p(0, 0))))
    self.Chat:SendChatUnReadMsg()
end

function GroupLayer:onExit()
    EventMgr:unregistListener(EventType.RET_CLUB_CHAT_GET_UNREAD_MSG, self, self.RET_CLUB_CHAT_GET_UNREAD_MSG)
    EventMgr:unregistListener(EventType.RET_CLUB_CHAT_MSG, self, self.RET_CLUB_CHAT_MSG)
    self.Chat:delClubRefreshMember();
end

function GroupLayer:onBack( ... )
    self:onClickPanle()
end

function GroupLayer:onClickPanle(...)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
	self.root:runAction(cc.Sequence:create(cc.MoveTo:create(0.1, cc.p(- self.rootSize.width-visibleSize.width, 0)), cc.CallFunc:create(function()
		self:removeFromParent()
	end)))
end

function GroupLayer:addChildLayer( name,data )
    local box = require("app.MyApp"):create(data,self):createView(name)
    self.chat_root:addChild(box)
    self.childLayer[name] = box
    box:setVisible(false)
end

function GroupLayer:openChildLayer( name,data)
    local layer = self.childLayer[name]

    if self.oldUI then
        self.oldUI:setVisible(false)
    end

    if name == 'GroupSettingLayer' then
        self.newUI = self.oldUI
    end
    self.oldUI = layer
    layer:setVisible(true)
    if layer.updateUI then
        if not self.clickID or self.clickID ~= data.dwClubID then
            if data then
                layer:updateUI(data)
            end
            self.clickID = data.dwClubID
        end
    end
end

function GroupLayer:backTo( )
    if self.newUI then
        self.newUI:setVisible(true)
    end
    if self.oldUI then
        self.oldUI:setVisible(false)
    end
    self.oldUI = self.newUI
end

local function SetTextProperty( text ,value)
    if text then
        text:setColor(cc.c3b(77, 77, 77))
        text:setString(value)
    end
end

function GroupLayer:addSystemCell( data )
    local cellData = self.allCell[data.dwClubID]
    local item = nil
    if not cellData then
        item = self.group_cell:clone()
        self.allCell[data.dwClubID] = {cell=item,data=data}
        item:setName(data.dwClubID)
        local Image_press       = self:seekWidgetByNameEx(item,'Image_press')
        Image_press:setVisible(false)
        self:addListener(item,handler(self,self.clickCell))
    else
        item = cellData.cell
    end
    local Image_press       = self:seekWidgetByNameEx(item,'Image_press')
    local image_hongdian    = self:seekWidgetByNameEx(item,'image_hongdian')
    local Text_sys      = self:seekWidgetByNameEx(item,'Text_sys')
    SetTextProperty(Text_sys,'系统信息')
    image_hongdian:setVisible(data.isHaveMsg)

    self.chatclublist:insertCustomItem(item,0)
    self.chatclublist:refreshView()
end

function GroupLayer:addGroupCell( data )
    local cellData = self.allCell[data.dwClubID]
    local item = nil
    if not cellData then
        item = self.tempcell:clone()
        self.allCell[data.dwClubID] = {cell=item,data=data}
        item:setName(data.dwClubID)
        local Image_press       = self:seekWidgetByNameEx(item,'Image_press')
        Image_press:setVisible(false)
        self:addListener(item,handler(self,self.clickCell))
    else
        item = cellData.cell
    end
    local Image_press       = self:seekWidgetByNameEx(item,'Image_press')
    local image_hongdian    = self:seekWidgetByNameEx(item,'image_hongdian')
    local Image_player      = self:seekWidgetByNameEx(item,'Image_player')
    local player_name       = self:seekWidgetByNameEx(item,'player_name')
    local player_num        = self:seekWidgetByNameEx(item,'player_num')
    local play_des          = self:seekWidgetByNameEx(item,'play_des')
    SetTextProperty(player_name,'昵称:' .. data.szClubName)
    SetTextProperty(player_num,'人数:' .. data.dwClubPlayerCount)
    SetTextProperty(play_des,'圈ID：'.. data.dwClubID)
    image_hongdian:setVisible(data.isHaveMsg)
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_player, 'img')
    self.chatclublist:pushBackCustomItem(item)
    self.chatclublist:refreshView()
end

function GroupLayer:clickCell( sender )
    local id = sender:getName()
    self:clickGroupByID(id)
end

function GroupLayer:clickGroupByID( id )
    local cellData = self.allCell[tonumber(id)]
    if cellData then
        local data = cellData.data
        local cell = cellData.cell
        local image_hongdian    = self:seekWidgetByNameEx(cell,'image_hongdian')

        image_hongdian:setVisible(false)

        self.clickClubID = id
        local clubData = {}
        if data.dwClubID == 0 then --组局系统消息
            self:openChildLayer('GroupTeam',data)
        else
            self:openChildLayer('ChatLayer',data)
        end
        if self.selectPress then
            self.selectPress:setVisible(false)
        end
        local press = self:seekWidgetByNameEx(cell,'Image_press')
        press:setVisible(true)
        self.selectPress = press
    end
end

function GroupLayer:addListener(btn, callback)
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

--msg 消息返回
function GroupLayer:RET_CLUB_CHAT_GET_UNREAD_MSG( event )
    local data = event._usedata
    if data.dwClubID == 0 then --系统消息
        self:addSystemCell(data)
    else
        self:addGroupCell(data)
    end
    if not self.isClickFirst then
        if self.clubData then
            if self.clubData.dwClubID == data.dwClubID then
                 self:clickGroupByID(data.dwClubID)
                 self.isClickFirst = true
            end
        end
    end
end

------------------------------------server
function GroupLayer:RET_CLUB_CHAT_MSG(event)
    local data = event._usedata
    
    if self.clickClubID  then --刷显示红点
        local num = tonumber(self.clickClubID)
        if num ~= data.dwClubID then
            local item = self.allCell[data.dwClubID]
            if item then
                local image_hongdian    = self:seekWidgetByNameEx(item.cell,'image_hongdian')
                image_hongdian:setVisible(true)
            end
        end
	end
end



return GroupLayer