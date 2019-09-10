---------------
--   解散
---------------
local KwxDisMissTable = class("KwxDisMissTable", cc.load("mvc").ViewBase)
local GameCommon = require("game.majiang.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local NetMsgId = require("common.NetMsgId")
local ASSISTTIME = 180

local dimissState = {
    agree='dismiss_agree',
    apply='dismiss_apply',
    refuse='dismiss_refuse',
    wait='dismiss_wait',
}
function KwxDisMissTable:onConfig()
	self.widget = {
		{'waite_time'},
		{'Button_agree', 'onAgreeCall'},
        {'Button_cancle', 'onCancleCall'},
        {'player_template'},
        {'Image_center'},
        {'Image_state'},
	}
end

function KwxDisMissTable:onEnter()

end

function KwxDisMissTable:onExit()
	if self.schedule then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedule)
		self.schedule = nil
	end
end

function KwxDisMissTable:onCreate(params)
	self.schedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 1, false)
	self.passtime = ASSISTTIME
	self.isDisMiss = false
	self.count = 1
	self:setInfo(params)
end


function KwxDisMissTable:onAgreeCall(...)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", true)
end

function KwxDisMissTable:onCancleCall(...)
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE_REPLY, "o", false)
end

function KwxDisMissTable:update(dt)
	self.passtime = self.passtime - dt
	if not self.isDisMiss then
		if self.passtime <= 0 then
			self.passtime = 0
			self.isDisMiss = true
		end
		self.waite_time:setString(string.format('在%d秒后自动解散', self.passtime))
	end
end

function KwxDisMissTable:setInfo(params)
	local data = params[1]
	
	self.passtime = data.dwDisbandedTime
	self.waite_time:setString(string.format('在%d秒后自动解散', self.passtime))
	self:getCancleName(data)
end


--获取解散人的名
function KwxDisMissTable:getCancleName(data)
    self.Image_center:removeAllChildren();
	local advocateName = ''
	local isOwner = false
	local player = GameCommon.player
	local charid = GameCommon:getRoleChairID()
	local uid = player[charid].dwUserID
	local playerId, name = self:disMissTableInfo(data)
	local isMine = uid == playerId
	self.Button_agree:setVisible(false)
	self.Button_cancle:setVisible(false)
	self.index = 1
	for i = 1, GameCommon.gameConfig.bPlayerCount do
		if data.dwUserIDALL[i] ~= 0 and player then
			if data.cbDisbandeState[i] == 1 then --不可操作
				if playerId ~= data.dwUserIDALL[i] then
					--self:setString(data.szNickNameALL[i], '同意')
					self:updateDimissTable(data.dwUserIDALL[i],dimissState.agree)
				else
					if isMine then
						self:updateDimissTable(data.dwUserIDALL[i],dimissState.apply)
					end
				end
				self:setOperateBtnState(false,data.dwUserIDALL[i]);
			elseif data.cbDisbandeState[i] == 2 then --拒绝
				self:updateDimissTable(data.dwUserIDALL[i],dimissState.refuse)
				self:setOperateBtnState(false,data.dwUserIDALL[i]);
				self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function ( sender,event )
					--self:popUpBox(data.szNickNameALL[i])
				end), cc.RemoveSelf:create()))
			else --还未操作
				if playerId ~= data.dwUserIDALL[i] then
					self:updateDimissTable(data.dwUserIDALL[i],dimissState.wait)
				end
				self:setOperateBtnState(true,data.dwUserIDALL[i]);
			end
		end
	end
	if not isMine then
		self:updateDimissTable(playerId,dimissState.apply)
	end
end

--更新牌桌人物
function KwxDisMissTable:updateDimissTable(uid,state )
    local data = GameCommon:getUserInfoByUserID(uid)
    local player = self.player_template:clone();
    local width = (GameCommon.gameConfig.bPlayerCount-1) * 200 + GameCommon.gameConfig.bPlayerCount * 100
	player:setPosition(cc.p(270-width/2/2 + (self.index-1) * 200,55))
	player:setVisible(true)
	local Image_avatar = self:seekWidgetByNameEx(player,'Image_avatar')
    local Text_name = self:seekWidgetByNameEx(player,'Text_name')
    local Image_state = self:seekWidgetByNameEx(player,'Image_state')
    Image_state:loadTexture(string.format( "majiang/ui/dismiss/%s.png",state ))
	Common:requestUserAvatar(uid,data.szPto,Image_avatar, "clip")
    Text_name:setString(data.szNickName)
    Text_name:setColor(cc.c3b(132,52,12))
    self.index = self.index + 1
    self.Image_center:addChild(player);
end

function KwxDisMissTable:setOperateBtnState(isShow, playerid)
	local player = GameCommon.player
	local charid = GameCommon:getRoleChairID()
	local uid = player[charid].dwUserID
	if uid == playerid then
		self.Button_agree:setVisible(isShow)
		self.Button_cancle:setVisible(isShow)
	end
end

function KwxDisMissTable:disMissTableInfo(data)
	local disPlayerID = nil
	local advocateName = ''
	for i = 1, 3 do
		if data.dwUserIDALL[i] ~= 0 then
			if data.cbDisbandeState[i] == 1 then --已经同意
				if data.wAdvocateDisbandedID == i - 1 then
					disPlayerID = data.dwUserIDALL[i] --谁发起
					advocateName = data.szNickNameALL[i] --谁发起
					break
				end
			end
		end
	end
	return disPlayerID, advocateName
end


return KwxDisMissTable 