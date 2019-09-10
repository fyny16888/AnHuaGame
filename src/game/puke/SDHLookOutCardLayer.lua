--[[
*名称:SDHLookOutCardLayer
*描述:三打哈查看历史出牌
*作者:admin
*创建日期:2019-06-25 16:07:23
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

local SDHLookOutCardLayer = class("SDHLookOutCardLayer", cc.load("mvc").ViewBase)

function SDHLookOutCardLayer:onConfig()
    self.widget         = {
        {"Node_func"},
    	{"Image_frame"},
    	{"ListView_look"},
    	{"Panel_item"},
    }
end

function SDHLookOutCardLayer:onEnter()
end

function SDHLookOutCardLayer:onExit()
end

function SDHLookOutCardLayer:onCreate(param)
	local pBuffer = param[1]
    Log.d(pBuffer)
	local callback = function()
        self:removeFromParent()
    end
    Common:registerScriptMask(self.Node_func, callback)

    for i=1,SDHGameCommon.gameConfig.bPlayerCount do
    	local item = self.Panel_item:clone()
    	self.ListView_look:pushBackCustomItem(item)
    	local Image_head = ccui.Helper:seekWidgetByName(item,"Image_head")
    	local Text_name = ccui.Helper:seekWidgetByName(item,"Text_name")
    	local Image_bank = ccui.Helper:seekWidgetByName(item,"Image_bank")
    	Common:requestUserAvatar(pBuffer.dwUserID[i], pBuffer.szLogoInfo[i], Image_head, "img")
    	Text_name:setString(pBuffer.szNickName[i])
    	if pBuffer.wBankUser == i-1 and pBuffer.bRecordCardCount[i] ~= 0 then
    		Image_bank:setVisible(true)
    	else
    		Image_bank:setVisible(false)
    	end

    	local cardScale = 0.5
	    for j = 1, pBuffer.bRecordCardCount[i] do
	        local data = pBuffer.bRecordCardData[i][j]
	        local card = SDHGameCommon:getCardNode(data)
	        item:addChild(card)
	        card:setScale(cardScale)
	        card:setAnchorPoint(cc.p(0,0))
	        local pt = cc.p(120 + (j-1)*35, 25)
	        card:setPosition(pt)
	    end
    end
end

return SDHLookOutCardLayer