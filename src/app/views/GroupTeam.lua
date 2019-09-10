---=========================================---
--des:组局界面
--time:2018-09-30 10:21:26
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

local GroupTeam = class("GroupTeam", cc.load("mvc").ViewBase)

function GroupTeam:onConfig()
    self.widget = {
        {'Button_setting','onClickSetting'},
        {'ListView_group'},
        {'templategroup'},
    }
end

function GroupTeam:onEnter()
    EventMgr:registListener(EventType.RET_CLUB_CHAT_RECORD_ZUJU, self, self.RET_CLUB_CHAT_RECORD_ZUJU)

    EventMgr:registListener(EventType.RET_CLUB_CHAT_RECORD_FINISH, self, self.RET_CLUB_CHAT_RECORD_FINISH)
end

function GroupTeam:onCreate( param )
    self.GroupLayer = param[2]  --group
    self.Chat = UserData.Chat
    self.reqState = 0  --0正在请求中 1，请求结束 2，请求完成
    self.endMainID = nil
    self.teamData = {}
    self.ListView_group:addScrollViewEventListener(handler(self, self.listViewNormalEventListen))
end


function GroupTeam:onExit()
    EventMgr:unregistListener(EventType.RET_CLUB_CHAT_RECORD_ZUJU, self, self.RET_CLUB_CHAT_RECORD_ZUJU)
    EventMgr:unregistListener(EventType.RET_CLUB_CHAT_RECORD_FINISH, self, self.RET_CLUB_CHAT_RECORD_FINISH)
end

function GroupTeam:listViewNormalEventListen(sender, evenType)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
		if self.reqState == 1 then
			self.reqState = 0
            self.Chat:SendRecordMsg(0,self.endMainID)
		end
	end
end

function GroupTeam:resetData( )
    self.endMainID = 0
    self.reqState = 0
    self.teamData = {}
    self.ListView_group:removeAllChildren()
end

function GroupTeam:updateUI( data)
    --请求group
    self:resetData()
    self.Chat:SendRecordMsg(0,self.endMainID)
end

local function SetTextProperty( text ,value)
    if text then
        text:setColor(cc.c3b(77, 77, 77))
        text:setString(value)
    end
end

function GroupTeam:addTeamCell( data )
    local item = self.templategroup:clone()
    item:setName(data.dwTableID)
    self.endMainID = data.ullSign
    local Text_head         = self:seekWidgetByNameEx(item,'Text_head')
    local Text_name         = self:seekWidgetByNameEx(item,'Text_name')
    local Text_group_id     = self:seekWidgetByNameEx(item,'Text_group_id')
    local Text_room_name    = self:seekWidgetByNameEx(item,'Text_room_name')
    local Text_room_num     = self:seekWidgetByNameEx(item,'Text_room_num')
    local Text_game_des     = self:seekWidgetByNameEx(item,'Text_game_des')
    local head_image_clip        = self:seekWidgetByNameEx(item,'head_image_clip')
    local Button_accept     = self:seekWidgetByNameEx(item,'Button_accept')
    local Button_cancle     = self:seekWidgetByNameEx(item,'Button_cancle')
    local name = Common:getShortName(data.szNickName, 7, 7)
    SetTextProperty(Text_head,name .. '  邀请您玩：' .. StaticData.Games[data.wKindID].name)
    SetTextProperty(Text_name,'昵称：' .. name)
    SetTextProperty(Text_group_id,'圈ID：' .. data.dwClubID)
    SetTextProperty(Text_room_name,'房间号：' .. data.dwTableID)
    SetTextProperty(Text_room_num,'局数：' .. data.wGameCount)
    local playwayDes = require("common.GameDesc"):getGameDesc(data.wKindID, data.tableParameter)
    SetTextProperty(Text_game_des,playwayDes)
    self:addEvent(Button_accept,handler(self,self.onAcceptGroup))
    Button_accept:setName(data.dwTableID)
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, head_image_clip, "clip")
    self.ListView_group:pushBackCustomItem(item)
    self.ListView_group:refreshView()
end

function GroupTeam:addEvent(btn, callback )
	btn:setPressedActionEnabled(true)
	btn:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			if callback then
				callback(sender)
			end
		end
	end)
end

--------button callback----
function GroupTeam:onCancleGroup(sender)
    --
end

function GroupTeam:onAcceptGroup(sender)
    local id = sender:getName()
    local data =  self.teamData[tonumber(id)]
    print('-->>',ID)
    dump(data,'fx-------------->>')
    if data then --进入组局
        sender:addChild(require("app.MyApp"):create(data.dwTableID):createView("InterfaceJoinRoomNode"))
    end
end

function GroupTeam:onClickSetting()
    self.GroupLayer:openChildLayer('GroupSettingLayer')
end

--server
function GroupTeam:RET_CLUB_CHAT_RECORD_ZUJU( event )
    local data = event._usedata
    if data.cbType == 3
	or data.cbType == 4 
	or data.cbType == 5 then
		if not StaticData.Games[data.wKindID] then
			return
		end
 	end
    self.teamData[data.dwTableID] = data
    self:addTeamCell(data)
end

function GroupTeam:RET_CLUB_CHAT_RECORD_FINISH(event)
	local data = event._usedata
	if data.isFinish then
		self.reqState = 2 --所有结束
	else
		self.reqState = 1 --本次结束
	end
end

return GroupTeam