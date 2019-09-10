--[[
*名称:SDHSurrenderLayer
*描述:三打哈投降
*作者:admin
*创建日期:2019-06-27 19:33:43
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
local SDHGameCommon 	= require("game.puke.SDHGameCommon") 

local SDHSurrenderLayer = class("SDHSurrenderLayer", cc.load("mvc").ViewBase)

function SDHSurrenderLayer:onConfig()
    self.widget         = {
    	{"Image_frame"},
    	{"Text_title"},
    	{"ListView_surrend"},
    	{"Button_agree", "onAgree"},
    	{"Button_disagree", "onDisagree"},
    	{"Panel_item"},
    }
end

function SDHSurrenderLayer:onEnter()
end

function SDHSurrenderLayer:onExit()
end

function SDHSurrenderLayer:onCreate(param)
	local allTime = 15
	schedule(self, function() 
		allTime = allTime - 1
		if allTime <= 0 then
			allTime = 0
			self:stopAllActions()
		end
		self.Text_title:setString(string.format('庄家发起投降，15秒后将默认为同意(%d)', allTime))
	end, 1)

    local pBuffer = param[1]
	self:refreshUI(pBuffer)
end

function SDHSurrenderLayer:onAgree()
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_GIVEUP_GAME,'b', 1)
	--self:removeFromParent()
end

function SDHSurrenderLayer:onDisagree()
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_GIVEUP_GAME,'b', 2)
	self:removeFromParent()
end

function SDHSurrenderLayer:refreshUI(pBuffer)
	Log.d(pBuffer)
	--庄家投降
	if SDHGameCommon.wBankerUser == SDHGameCommon:getRoleChairID() then
		self.Button_agree:setVisible(false)
		self.Button_disagree:setVisible(false)
	end

	self.ListView_surrend:setContentSize(cc.size(200 * (SDHGameCommon.gameConfig.bPlayerCount-1), 180))
	self.ListView_surrend:removeAllItems()
	for i, var in pairs(SDHGameCommon.player) do
		if var.wChairID ~= SDHGameCommon.wBankerUser then
			local item = self.Panel_item:clone()
			self.ListView_surrend:pushBackCustomItem(item)
			local Image_head = ccui.Helper:seekWidgetByName(item,"Image_head")
			local Text_name = ccui.Helper:seekWidgetByName(item,"Text_name")
			local Image_flag = ccui.Helper:seekWidgetByName(item,"Image_flag")
			Common:requestUserAvatar(var.dwUserID,var.szPto,Image_head,"img")
			local name = Common:getShortName(var.szNickName,8,6)
        	Text_name:setString(name)
        	if pBuffer.bSurrenderUser[var.wChairID+1] ~= 0 then
        		Image_flag:loadTexture('sdh/ok_ui_sdh_vote_agree.png')
        		if var.wChairID == SDHGameCommon:getRoleChairID() then
        			self.Button_agree:setVisible(false)
					self.Button_disagree:setVisible(false)
        		end
        	end
		end
    end
end

return SDHSurrenderLayer