--
-- Author: Your Name
-- Date: 2019-07-01 19:09:35
--
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local NetMsgId = require("common.NetMsgId")

local QuickStartGameNode = class("QuickStartGameNode", cc.load("mvc").ViewBase)

function QuickStartGameNode:onEnter()
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER_ERROR, self, self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:registListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
end

function QuickStartGameNode:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER_ERROR, self, self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
end

function QuickStartGameNode:onCreate(param)
    NetMgr:getGameInstance():closeConnect()
	local wKindID = param[1]
    UserData.Game:sendMsgGetRoomInfo(wKindID, 3)
end

--获取房间ip地址和端口成功
function QuickStartGameNode:SUB_CL_GAME_SERVER(event)
    local data = event._usedata
    UserData.Game:sendMsgConnectGame(data)           
end

function QuickStartGameNode:SUB_CL_GAME_SERVER_ERROR(event)
    local data = event._usedata
    require("common.MsgBoxLayer"):create(0,nil,"服务器暂未开启！")         
end

function QuickStartGameNode:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    local data = event._usedata
    require("common.MsgBoxLayer"):create(0,nil,"连接游戏服失败！")
end

function QuickStartGameNode:SUB_GR_LOGON_SUCCESS(event)
    local cbLevel = cc.UserDefault:getInstance():getIntegerForKey('quick_game_level', 1)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_MATCH_REDENVELOPE_TABLE,"w",cbLevel)
end

function QuickStartGameNode:SUB_GR_MATCH_TABLE_ING(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID, data),SCENE_GAME)
end

function QuickStartGameNode:SUB_GR_MATCH_TABLE_FAILED(event)
    local data = event._usedata
    if data.wErrorCode == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您在游戏中!")
    elseif data.wErrorCode == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"游戏配置发生错误!")
    elseif data.wErrorCode == 2 then
        require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer"))
        end)
    elseif data.wErrorCode == 3 then
        --require("common.MsgBoxLayer"):create(0,nil,"您的金币已超过上限，请前往更高一级匹配!")
        local cbLevel = cc.UserDefault:getInstance():getIntegerForKey('quick_game_level', 1) + 1
        cc.UserDefault:getInstance():setIntegerForKey('quick_game_level', cbLevel)
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_MATCH_REDENVELOPE_TABLE,"w",cbLevel)
    elseif data.wErrorCode == 4 then
        require("common.MsgBoxLayer"):create(0,nil,"房间已满,稍后再试!")
    else
        require("common.MsgBoxLayer"):create(0,nil,"未知错误,请升级版本!") 
    end
end

function QuickStartGameNode:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID, data),SCENE_GAME)
end

return QuickStartGameNode