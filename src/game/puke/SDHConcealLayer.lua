--[[
*名称:SDHConcealLayer
*描述:三打哈埋底
*作者:admin
*创建日期:2019-06-05 14:41:52
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
local SDHGameCommon 	= require("game.puke.SDHGameCommon")
local Log               = require("common.Log")

local SDHConcealLayer = class("SDHConcealLayer", cc.load("mvc").ViewBase)

function SDHConcealLayer:onConfig()
    self.widget         = {
    	{"AtlasLabel_concealnum"},
    	{"AtlasLabel_selectnum"},
    	{"Panel_card"},
        {"Button_diss", "onDiss"},
    	{"Button_conceal", "onConceal"},
    }
end

function SDHConcealLayer:onEnter()
end

function SDHConcealLayer:onExit()
end

function SDHConcealLayer:onCreate(param)
	local pBuffer = param[1]
	Log.d(pBuffer)
    if SDHGameCommon.tableConfig.tableParameter.b35Down and pBuffer.bLandScore <= 35 then
        self.Button_diss:setTouchEnabled(false)
        self.Button_diss:setColor(cc.c3b(170, 170, 170))
    end
    
	self.AtlasLabel_concealnum:setString(pBuffer.cbConcealCount)
	-- self.Button_diss:setColor(cc.c3b(170, 170, 170))
	-- self.Button_diss:setTouchEnabled(false)
	self:showHandCard(pBuffer)
	self:changeConcealCardColor(pBuffer.cbConcealCard)

    self.beganPos = nil
    local function onTouchBegan(touch , event)
        self:switchCard(touch:getLocation(),"began")
        return true
    end
    local function onTouchMoved(touch , event)
        self:switchCard(touch:getLocation(),"moved")
    end
    local function onTouchEnded(touch , event)
        self:switchCard(touch:getLocation(),"ended")
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,self.Panel_card) 
end

function SDHConcealLayer:onDiss()
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_GIVEUP_GAME,'b', 0)
end

function SDHConcealLayer:onConceal()
	local cardScale = 0.8
    local cardHeight = 231 * cardScale
	local tableSwitchCard = {}
    local tableCardNode = self.Panel_card:getChildren()
	for key, var in pairs(tableCardNode) do
    	if var:getPositionY() > 0 and var:getPositionY() <= 20 then
            table.insert(tableSwitchCard,var.data)
        elseif math.floor(var:getPositionY()) > (cardHeight + 30) then
            table.insert(tableSwitchCard,var.data)
        end
	end

	local concealNum = tonumber(self.AtlasLabel_concealnum:getString())
	if #tableSwitchCard == concealNum then
		--埋底
		NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_BACK_CARD,"bbbbbbbbbb",concealNum,
			tableSwitchCard[1], tableSwitchCard[2], tableSwitchCard[3], tableSwitchCard[4], tableSwitchCard[5], tableSwitchCard[6],
			tableSwitchCard[7], tableSwitchCard[8], tableSwitchCard[9] or 0)
		self:removeFromParent()
	else
    	require("common.MsgBoxLayer"):create(0,nil,'埋底不符合规则')
	end
end

--更新手牌
function SDHConcealLayer:showHandCard(pBuffer)
	self.Panel_card:removeAllChildren()
    local pos = cc.p(self.Panel_card:getPosition())
    local size = self.Panel_card:getContentSize()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local cardScale = 0.8
    local cardWidth = 180 * cardScale    
    local cardHeight = 231 * cardScale
    local stepX = cardWidth * 0.4
    local stepY = cardHeight
    local beganX = 0
    local rowMaxNum = 18
    beganX = (size.width - (rowMaxNum * stepX + cardWidth - 140)) / 2
    
    for i=1,rowMaxNum do
        local data = pBuffer.cbCardData[i]
        local card = SDHGameCommon:getCardNode(data)
        self.Panel_card:addChild(card)
        card:setLocalZOrder(i)
        card:setScale(cardScale)
        card:setAnchorPoint(cc.p(0,0))
        card.data = data
        local pt = cc.p(visibleSize.width-beganX-68-(rowMaxNum-i)*stepX, stepY+30)
        card.pt = pt
        card:setPosition(card.pt)
    end

    local idx = 0
    for i = rowMaxNum+1, pBuffer.cbCardCount do
        idx = idx + 1
        local data = pBuffer.cbCardData[i]
        local card = SDHGameCommon:getCardNode(data)
        self.Panel_card:addChild(card)
        card:setLocalZOrder(i)
        card:setScale(cardScale)
        card:setAnchorPoint(cc.p(0,0))
        card.data = data
        local pt = cc.p(beganX-10 + (idx-1)*stepX, 0)
        card.pt = pt
        card:setPosition(card.pt)
    end
end

--改变底牌颜色
function SDHConcealLayer:changeConcealCardColor(cbConcealCard)
	local cardItems = self.Panel_card:getChildren()
	for _,data in ipairs(cbConcealCard) do
		for __,item in ipairs(cardItems) do
			if data == item.data and not item:getChildByName('card_color_flag') then
				local child = ccui.ImageView:create('sdh/ok_ui_sdh_gray_bg.png')
				item:addChild(child)
                child:setName('card_color_flag')
				local size = item:getContentSize()
				child:setPosition(size.width / 2, size.height / 2)
				child:setScale(1.2)
				break
			end
		end
	end
end

function SDHConcealLayer:switchCard(location,touchType)
    local cardScale = 0.8
    local cardWidth = 180 * cardScale    
    local cardHeight = 231 * cardScale
    local stepX = cardWidth * 0.4
    local tableCardNode = self.Panel_card:getChildren()
    local pos = self.Panel_card:convertToNodeSpace(cc.p(location))
    if touchType == "began" then
        self.beganPos = pos
        if cc.rectContainsPoint(self.Panel_card:getBoundingBox(),location) == false then
            return
        end
        local zOrder = 0
        local tempNode = nil
        for key, var in pairs(tableCardNode) do
            local rect = var:getBoundingBox()
            if key ~= #tableCardNode then
                rect = cc.rect(rect.x,rect.y,rect.width,rect.height)
            end
            if cc.rectContainsPoint(rect,self.beganPos) and var:getLocalZOrder() > zOrder then
                tempNode = var
                zOrder = var:getLocalZOrder()
            else
                var:setColor(cc.c3b(255,255,255))
            end
        end
        if tempNode then
            tempNode:setColor(cc.c3b(170,170,170))
        end
    elseif touchType == "moved" then
        if cc.rectContainsPoint(self.Panel_card:getBoundingBox(),location) == false then
            return
        end
        if self.beganPos == nil then 
            self.beganPos = pos
        end 
        local beganX = self.beganPos.x
        local endX = pos.x
        local beganY = self.beganPos.y
        local endY = pos.y
        if endX < beganX then
            endX = self.beganPos.x
            beganX = pos.x
        end

        for key, var in pairs(tableCardNode) do
            local nodeLeftX = cc.p(var:getPosition()).x
            local nodeRightX = nodeLeftX + stepX
            if key == #tableCardNode then
                nodeRightX = nodeLeftX + cardWidth
            end

            local nodeBottomY = cc.p(var:getPosition()).y
            local nodeTopY = nodeBottomY + cardHeight
            if nodeBottomY >= cardHeight then
                nodeBottomY = cardHeight + 30
                nodeTopY = nodeBottomY + cardHeight
            end

            if(beganY >= nodeBottomY and beganY <= nodeTopY) and (endY >= nodeBottomY and endY <= nodeTopY) then
                if (nodeLeftX >= beganX and nodeLeftX <= endX) or (nodeRightX >= beganX and nodeRightX <= endX) then 
                    var:setColor(cc.c3b(170,170,170))
                elseif pos.x >= nodeLeftX and pos.x <= nodeRightX then
                    var:setColor(cc.c3b(170,170,170))
                else
                    var:setColor(cc.c3b(255,255,255))
                end
            else
                var:setColor(cc.c3b(255,255,255))
            end
        end
    else
        for key, var in pairs(tableCardNode) do
            local color = var:getColor()
            if color.r == 170 then
                if var:getPositionY() > 0 and var:getPositionY() <= 20 then
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),0)))
                elseif math.floor(var:getPositionY()) > (cardHeight + 30) then
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),cardHeight + 30)))
                else
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(), var:getPositionY()+20)))
                end
            end
            var:setColor(cc.c3b(255,255,255))
        end

        local tableSwitchCard = {}
        self.AtlasLabel_selectnum:stopAllActions()
        self.AtlasLabel_selectnum:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function() 
    		for key, var in pairs(tableCardNode) do
            	if var:getPositionY() > 0 and var:getPositionY() <= 20 then
	                table.insert(tableSwitchCard,var.data)
	            elseif math.floor(var:getPositionY()) > (cardHeight + 30) then
	                table.insert(tableSwitchCard,var.data)
	            end
        	end
        	self.AtlasLabel_selectnum:setString(#tableSwitchCard)
    	end)))
    end
end

return SDHConcealLayer