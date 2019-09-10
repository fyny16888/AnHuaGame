--[[
*名称:PleaseReciveLayer
*描述:被邀请牌局
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

local PleaseReciveLayer = class("PleaseReciveLayer", cc.load("mvc").ViewBase)

function PleaseReciveLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Text_topName"},
        {"Text_playway"},
        {"Image_head"},
        {"Text_name"},
        {"Text_ID"},
        {'Text_roomid'},
        {"Text_jushu"},
        {"Text_waydes"},
        {"Button_yes", "onYes"},
        {"Button_no", "onNo"},
    }
end

function PleaseReciveLayer:onEnter()
end

function PleaseReciveLayer:onExit()
end

function PleaseReciveLayer:onCreate(param)
	Log.d(param[1])
	local data = param[1]
	self.data = data
	self:initUI(data)
end

function PleaseReciveLayer:onClose()
    self:removeFromParent()
end

function PleaseReciveLayer:onYes()
	local node = require("app.MyApp"):create(self.data.dwTableID):createView("InterfaceJoinRoomNode")
	require("common.SceneMgr"):switchTips(node)
end

function PleaseReciveLayer:onNo()
	self:removeFromParent()
end


------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function PleaseReciveLayer:initUI(data)
	self.Text_topName:setString(data.szNickName)
	self.Text_name:setString(data.szClubName)
	local gamename = StaticData.Games[data.wKindID].name
	self.Text_playway:setString('邀请您玩:' .. gamename)
	Common:requestUserAvatar(data.dwClubID, data.szClubLogoInfo, self.Image_head, "img")
	self.Text_ID:setString('圈ID:' .. data.dwClubID)
	self.Text_roomid:setString('房间号:' .. data.dwTableID)
	self.Text_jushu:setString('局数:' .. data.wGameCount)
	local playwayDes = require("common.GameDesc"):getGameDesc(data.wKindID, data.tableParameter)
	self.Text_waydes:setString(playwayDes)
end

return PleaseReciveLayer