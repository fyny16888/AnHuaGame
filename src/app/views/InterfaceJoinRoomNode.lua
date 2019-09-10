local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameConfig = require("common.GameConfig")

local InterfaceJoinRoomNode = class("InterfaceJoinRoomNode", cc.load("mvc").ViewBase)

function InterfaceJoinRoomNode:onEnter()
    EventMgr:registListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:registListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED)
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
end

function InterfaceJoinRoomNode:onExit()
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:unregistListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED)
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
end

function InterfaceJoinRoomNode:onCreate(parameter)
    self.roomNumber = parameter[1]
    NetMgr:getGameInstance():closeConnect()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL,NetMsgId.REQ_CL_GAME_SERVER_BY_ID,"d",self.roomNumber)
end

function InterfaceJoinRoomNode:SUB_GR_LOGON_SUCCESS(event)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_JOIN_TABLE,"dd",UserData.User.userID,self.roomNumber)
end

function InterfaceJoinRoomNode:SUB_CL_GAME_SERVER(event)
    local data = event._usedata
    UserData.Game:sendMsgConnectGame(data)
end

function InterfaceJoinRoomNode:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    local data = event._usedata
    UserData.User.externalAdditional = ""
    require("common.MsgBoxLayer"):create(0,nil,"连接游戏服失败！")
end


function InterfaceJoinRoomNode:SUB_CL_GAME_SERVER_ERROR(event)
    local data = event._usedata
    self:removeFromParent() 
    UserData.User.externalAdditional = ""
    require("common.MsgBoxLayer"):create(0,nil,"该房间号不存在！")  
end

function InterfaceJoinRoomNode:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID,data),SCENE_GAME)
end

function InterfaceJoinRoomNode:SUB_GR_JOIN_TABLE_FAILED(event)
    local data = event._usedata
    self:removeFromParent()
    NetMgr:getGameInstance():closeConnect()
    UserData.User.externalAdditional = ""
    if data.wErrorCode == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"您加入的房间已经被解散!")
    elseif data.wErrorCode == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"该房间人数已满!")
    elseif data.wErrorCode == 11 then
        require("common.MsgBoxLayer"):create(0,nil,"最后一局禁止加入!")
    elseif data.wErrorCode == 21 then
        require("common.MsgBoxLayer"):create(0,nil,"您不是该亲友圈不存在!")
    elseif data.wErrorCode == 22 then
        require("common.MsgBoxLayer"):create(0,nil,"您不是该亲友圈成员!")
    elseif data.wErrorCode == 23 then
        require("common.MsgBoxLayer"):create(0,nil,"您不是该亲友圈成员,正在审核中!")
    elseif data.wErrorCode == 24 then
        require("common.MsgBoxLayer"):create(0,nil,"您已被群主禁止娱乐,请联系群主恢复!")
    elseif data.wErrorCode == 25 then
        require("common.MsgBoxLayer"):create(2,nil,"防沉迷配置错误,请联系群主重新设置!")
    elseif data.wErrorCode == 26 then
        require("common.MsgBoxLayer"):create(2,nil,"您的疲劳值不够,请联系群主!")
    elseif data.wErrorCode == 27 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈玩法不存在,请重新刷新亲友圈!")
    else
        require("common.MsgBoxLayer"):create(0,nil,"请升级版本!")
    end
end

return InterfaceJoinRoomNode