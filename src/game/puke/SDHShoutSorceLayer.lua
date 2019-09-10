--[[
*名称:SDHShoutSorceLayer
*描述:三打哈叫分
*作者:admin
*创建日期:2019-06-04 11:30:52
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

local SDHShoutSorceLayer = class("SDHShoutSorceLayer", cc.load("mvc").ViewBase)

function SDHShoutSorceLayer:onConfig()
    self.widget         = {
    	{"Panel_frame"},
    	{"Button_item"},
    	{"Text_shoutTips"},
        {"Button_shout", "onShout"},
    	{"Button_noshout", "onNoShout"},
    }
end

function SDHShoutSorceLayer:onEnter()
end

function SDHShoutSorceLayer:onExit()
end

function SDHShoutSorceLayer:onCreate(param)
	self.Button_shout:setTouchEnabled(false)
	self.Button_shout:setColor(cc.c3b(170, 170, 170))
	local pBuffer = param[1]
	local baseSorce = param[2]
	Log.d(pBuffer)
	local text = string.format('提示:如果所有人都不叫分，则第一个人默认叫%d分', baseSorce)
	self.Text_shoutTips:setString(text)
	
	local bCurrentScore = pBuffer.bCurrentScore
	local wUserScore = pBuffer.wUserScore
	local minValue = 255
	for i,v in ipairs(wUserScore) do
		if v < minValue and v ~= 0 then
			minValue = v
		end
	end

	local items = self.Panel_frame:getChildren()
	for i,v in ipairs(items) do
		v:setVisible(false)
	end

	local h = 103
	if baseSorce >= 80 then
		h = 80
		self.Panel_frame:setPositionY(self.Panel_frame:getPositionY() + 15)
	end

	local index = 0
	for i=baseSorce,5,-5 do
		index = index + 1
		local item = items[index]
		if not item then
			item = self.Button_item:clone()
			self.Panel_frame:addChild(item)
		end
		item:setVisible(true)
		item:setTitleText(i)
		if i > bCurrentScore or minValue == i then
			item:setTouchEnabled(false)
			item:setColor(cc.c3b(170, 170, 170))
		else
			item:setTouchEnabled(true)
			item:setColor(cc.c3b(255, 255, 255))
		end

		local col = index % 4
        if col == 0 then
            col = 4
        end
        local row = math.ceil(index / 4)
        local x = 62 + (col - 1) * 143
        local y = 243 - (row - 1) * h
		item:setPosition(x, y)
		-- 叫分
		Common:addTouchEventListener(item,function(sender,event)
        	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_LAND_SCORE,"w",i)
        	self:removeFromParent()
        end)
	end
end

function SDHShoutSorceLayer:onShout()
end

function SDHShoutSorceLayer:onNoShout()
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_LAND_SCORE,"w",255)
	self:removeFromParent()
end

return SDHShoutSorceLayer