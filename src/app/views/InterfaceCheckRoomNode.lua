local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameDesc = require("common.GameDesc")
local GameConfig = require("common.GameConfig")

local InterfaceCheckRoomNode = class("InterfaceCheckRoomNode", cc.load("mvc").ViewBase)

function InterfaceCheckRoomNode:onEnter()
    EventMgr:registListener(EventType.SUB_CL_USER_LOCK_SERVER,self,self.SUB_CL_USER_LOCK_SERVER)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:registListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
end

function InterfaceCheckRoomNode:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_USER_LOCK_SERVER,self,self.SUB_CL_USER_LOCK_SERVER)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
end

function InterfaceCheckRoomNode:onCreate(parameter)
    self.callback     = parameter[1]
    NetMgr:getGameInstance():closeConnect()
    UserData.Game:sendMsgCheckIsPlaying()
    require("common.SceneMgr"):switchTips(self)
end

function InterfaceCheckRoomNode:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID,data),SCENE_GAME)
end

function InterfaceCheckRoomNode:SUB_CL_USER_LOCK_SERVER(event)
    local data = event._usedata
    if data.cbPlaying == 1 then
        UserData.Game:sendMsgConnectGame(data)
    else
        if self.callback then
            self.callback()
        end
        require("common.SceneMgr"):switchTips()
    end
end

function InterfaceCheckRoomNode:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    local data = event._usedata
    self:removeFromParent()
    require("common.MsgBoxLayer"):create(0,nil,"连接游戏失败,请查看您的网络状态！")
end

function InterfaceCheckRoomNode:SUB_GR_LOGON_SUCCESS(event)
    local data = event._usedata
    self:removeFromParent()
    NetMgr:getGameInstance():closeConnect()
end

return InterfaceCheckRoomNode