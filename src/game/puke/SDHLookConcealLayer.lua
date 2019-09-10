--[[
*名称:SDHLookConcealLayer
*描述:三打哈查看底牌
*作者:admin
*创建日期:2019-06-25 14:33:21
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

local SDHLookConcealLayer = class("SDHLookConcealLayer", cc.load("mvc").ViewBase)

function SDHLookConcealLayer:onConfig()
    self.widget         = {
    	{"Image_bg"},
    	{"Panel_card"},
    	{"AtlasLabel_score"},
    }
end

function SDHLookConcealLayer:onEnter()
end

function SDHLookConcealLayer:onExit()
end

function SDHLookConcealLayer:onCreate()
	local callback = function()
        self:removeFromParent()
    end
    Common:registerScriptMask(self.Image_bg, callback)

	if not SDHGameCommon.cbConcealCard then
		return
	end

	local wConcealScore = SDHGameCommon:GetCardScore(SDHGameCommon.cbConcealCard, SDHGameCommon.cbConcealCount)
    self.AtlasLabel_score:setString(wConcealScore)

    local cardScale = 0.6
    for i = 1, SDHGameCommon.cbConcealCount do
        local data = SDHGameCommon.cbConcealCard[i]
        local card = SDHGameCommon:getCardNode(data)
        self.Panel_card:addChild(card)
        card:setScale(cardScale)
        card:setAnchorPoint(cc.p(0,0))
        local pt = cc.p((i-1)*40, 0)
        card:setPosition(pt)
    end

    if SDHGameCommon.cbConcealCount <=8 then
        self.Panel_card:setPositionX(self.Panel_card:getPositionX() + 20)
    end
end

return SDHLookConcealLayer