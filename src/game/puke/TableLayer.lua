local StaticData = require("app.static.StaticData")
local GameCommon = require("game.puke.GameCommon") 
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local Bit = require("common.Bit")
local Common = require("common.Common")
local Base64 = require("common.Base64")
local LocationSystem = require("common.LocationSystem")
local Default = require("common.Default")
local UserData = require("app.user.UserData")
local GameLogic = require("game.puke.GameLogic")
local GameDesc = require("common.GameDesc")
local TableLayer = class("TableLayer",function()
    return ccui.Layout:create()
end)

local APPNAME = 'puke'

function TableLayer:create(root)
    local view = TableLayer.new()
    view:onCreate(root)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit() 
        end  
    end  
    view:registerScriptHandler(onEventHandler)
    return view
end

function TableLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:registListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:registListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
            local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
            if uiImage_signal ~= nil then 
                uiImage_signal:setVisible(false) 
            end
        end
    end
    UserData.User:initByLevel()
end

function TableLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:unregistListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)
end

function TableLayer:onCreate(root)
    self.root = root
    self.lastOutCardInfo = {
        bUserCardCount = 0,
        wCurrentUser = 0,
        wOutCardUser = 0,
        bCardData = {},
        time = 0,
        tipsIndex = 0,
        tableCard = {},
    }
    local locationPos = cc.p(0,0)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",1))
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
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,uiPanel_handCard) 
    return true
end

function TableLayer:switchCard(location,touchType)
    local wChairID = GameCommon:getRoleChairID()
    if GameCommon.gameState ~= GameCommon.GameState_Start then
        return
    end
    if GameCommon.player[wChairID].cbCardData == nil then
    	return
    end
    local cardScale = 1
    local cardWidth = 161 * cardScale
    local cardHeight = 231 * cardScale
    local stepX = cardWidth * 0.4
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    local pos = uiPanel_handCard:convertToNodeSpace(cc.p(location))
    if touchType == "began" then
        self.beganPos = pos
        if cc.rectContainsPoint(uiPanel_handCard:getBoundingBox(),location) == false then
            return
        end
        for key, var in pairs(tableCardNode) do
            local rect = var:getBoundingBox()
            if key ~= #tableCardNode then
                rect = cc.rect(rect.x,rect.y,stepX,rect.height)
            end
            if cc.rectContainsPoint(rect,self.beganPos) then
                var:setColor(cc.c3b(170,170,170))
            else
                var:setColor(cc.c3b(255,255,255))
            end
        end
    elseif touchType == "moved" then
        if cc.rectContainsPoint(uiPanel_handCard:getBoundingBox(),location) == false then
            return
        end
        if self.beganPos == nil then 
            self.beganPos = pos
        end 
        local beganX = self.beganPos.x
        local endX = pos.x
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
            if (nodeLeftX >= beganX and nodeLeftX <= endX) or (nodeRightX >= beganX and nodeRightX <= endX) then 
                var:setColor(cc.c3b(170,170,170))
            elseif pos.x >= nodeLeftX and pos.x <= nodeRightX then
                var:setColor(cc.c3b(170,170,170))
            else
                var:setColor(cc.c3b(255,255,255))
            end
        end
    else
        local time =0.1
        local tableSwitchCard = {}
        local tableSwitchCardNode = {}
        for key, var in pairs(tableCardNode) do
            local color = var:getColor()
            if color.r == 170 then
                if var:getPositionY() ~= 0 then
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),0)))
--                    var:setPositionY(0)
                else
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),20)))
--                    var:setPositionY(20)
                    table.insert(tableSwitchCard,#tableSwitchCard+1,var.data)
                    table.insert(tableSwitchCardNode,#tableSwitchCardNode+1,var)
                end
            end
            var:setColor(cc.c3b(255,255,255))
        end
        if #tableSwitchCard >= 0 then
            local tableCard = self:getMaxCardType(tableSwitchCard,#tableSwitchCard)
            if tableCard ~= nil then
                for key, var in pairs(tableSwitchCardNode) do
                    local isFound = false
                    print(var.data)
                    for k, v in pairs(tableCard) do
                    	if v == var.data then
                	        isFound = true
                            var:stopAllActions()
                            var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),20)))
--                            var:setPositionY(20)
                	       break
                    	end
                    end
                    if isFound == false then
                        var:stopAllActions()
                        var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),0)))
--                        var:setPositionY(0)
                    end
                end
            end
        end
    end
end

function TableLayer:doAction(action,pBuffer)
    if action == NetMsgId.SUB_S_GAME_START_PDK then
        if pBuffer.bStartCard > 0 then
            local visibleSize = cc.Director:getInstance():getVisibleSize()
            local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
            local card = GameCommon:getCardNode(pBuffer.bStartCard) 
            uiPanel_tipsCard:addChild(card)          
            card:setScale(1.5)
            card:runAction(cc.Sequence:create(
                cc.ScaleTo:create(0.1,1),
                cc.DelayTime:create(1.0),
                cc.FadeOut:create(0.5),
                cc.RemoveSelf:create()))
            local viewID = GameCommon:getViewIDByChairID(pBuffer.wCurrentUser)
            local uiPanel_tipsCardPosUser = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
            card:setPosition(uiPanel_tipsCardPosUser:getPosition())
        end
        GameCommon:playAnimation(self.root, "我先出",pBuffer.wCurrentUser)
        self:showCountDown(pBuffer.wCurrentUser)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        local uiButton_out = ccui.Helper:seekWidgetByName(self.root,"Button_out")
        uiButton_out:setVisible(false)
    elseif action == NetMsgId.SUB_S_USER_PASS_CARD_PDK then
        GameCommon:playAnimation(self.root, "要不起",pBuffer.wPassUser)
        local wChairID = pBuffer.wPassUser
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",viewID))
        uiPanel_weaveItemArray:removeAllChildren()
        local wChairID = GameCommon:getRoleChairID()
        if self.lastOutCardInfo ~= nil and pBuffer.wCurrentUser == wChairID and self.lastOutCardInfo.wOutCardUser ~= wChairID and GameCommon.tableConfig.nTableType ~= TableType_Playback then
            self.lastOutCardInfo.tableCard = self:getExtractCardType(GameCommon.player[wChairID].cbCardData,GameCommon.player[wChairID].bUserCardCount,self.lastOutCardInfo.bCardData,self.lastOutCardInfo.bUserCardCount)
        end
        if pBuffer.wCurrentUser == wChairID and self.lastOutCardInfo.wOutCardUser ~= wChairID and #self.lastOutCardInfo.tableCard <= 0 then  
            self:showCountDown(pBuffer.wCurrentUser,true)
        else
            self:tryAutoSendCard(pBuffer.wCurrentUser)
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
                             
    elseif action == NetMsgId.SUB_S_WARN_INFO_PDK then
        GameCommon:playAnimation(self.root, "报警",pBuffer.wWarnUser)
        GameCommon.player[pBuffer.wWarnUser].bUserWarn = true
        if GameCommon.gameConfig.bAbandon == 0 then
            local wPlayerCount = GameCommon.gameConfig.bPlayerCount
            local meChairID = GameCommon:getRoleChairID()
            local xiajia = (meChairID+1)%wPlayerCount
            local wChairID = GameCommon:getRoleChairID()
            if pBuffer.wWarnUser == xiajia and self.lastOutCardInfo.wOutCardUser ~= wChairID and GameCommon.tableConfig.nTableType ~= TableType_Playback then
                self.lastOutCardInfo.tableCard = self:getExtractCardType(GameCommon.player[wChairID].cbCardData,GameCommon.player[wChairID].bUserCardCount,pBuffer.bCardData,pBuffer.bUserCardCount)
            end
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.SUB_S_OUT_CARD_PDK then        
        local targetType, targetCardData = self:getCardTypeAndCard(pBuffer.bCardData,pBuffer.bUserCardCount)
        if targetType == GameCommon.CardType_single then
            local value = Bit:_and(pBuffer.bCardData[1],0x0F)
            GameCommon:playAnimation(self.root, value,pBuffer.wOutCardUser)
        elseif targetType == GameCommon.CardType_pair then
            local value = Bit:_and(pBuffer.bCardData[1],0x0F)
            GameCommon:playAnimation(self.root, string.format("对%d",value),pBuffer.wOutCardUser)
        elseif targetType == GameCommon.CardType_straight then
            GameCommon:playAnimation(self.root, "顺子",pBuffer.wOutCardUser)
        elseif targetType == GameCommon.CardType_straightPair then
            GameCommon:playAnimation(self.root, "连对",pBuffer.wOutCardUser)
        elseif targetType == GameCommon.CardType_3Add2 then
            if pBuffer.bUserCardCount == 5 then
                GameCommon:playAnimation(self.root, "三带二",pBuffer.wOutCardUser)
            end
        elseif targetType == GameCommon.CardType_airplane then
            GameCommon:playAnimation(self.root, "飞机",pBuffer.wOutCardUser)
        elseif targetType == GameCommon.CardType_4Add3 then
            if pBuffer.bUserCardCount == 7 then
                GameCommon:playAnimation(self.root, "四带三",pBuffer.wOutCardUser)
            end
        elseif targetType == GameCommon.CardType_bomb then
            GameCommon:playAnimation(self.root, "炸弹",pBuffer.wOutCardUser)
        else
            assert(false,"错误")
            return
        end    
        local wChairID = pBuffer.wOutCardUser
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",viewID))
        uiPanel_weaveItemArray:removeAllChildren()
        local size = uiPanel_weaveItemArray:getContentSize()
        local anchorPoint = uiPanel_weaveItemArray:getAnchorPoint()
        local index = 0
        local time = 0.1
        local cardScale = 0.7
        local cardWidth = 161 * cardScale
        local cardHeight = 231 * cardScale
        local stepX = cardWidth * 0.4
        local stepY = cardHeight
        local beganX = (size.width - ((GameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)) / 2
        if anchorPoint.x == 0 then
            beganX = cardWidth/2
        elseif anchorPoint.x == 1 then
            beganX = size.width + cardWidth/2 - ((pBuffer.bUserCardCount-1) * stepX + cardWidth)
        else
            beganX = (size.width - ((pBuffer.bUserCardCount-1) * stepX + cardWidth)) / 2 + cardWidth/2
        end
        local index = 1
        for key, var in pairs(targetCardData) do
--        for i = 1, pBuffer.bUserCardCount do
--            local var = pBuffer.bCardData[i]
    	    local pos = nil
    	    if pBuffer.notDeleteCard ~= true then
                pos = self:removeHandCard(wChairID,var)
    	    end
            local card = GameCommon:getCardNode(var)
            uiPanel_weaveItemArray:addChild(card)
            if pos == nil then
                card:setScale(cardScale)
                card:setPosition(beganX + (index-1)*stepX, size.height/2)
            else
                card:setPosition(cc.p(card:getParent():convertToNodeSpace(pos)))
                card:setScale(0.9)
                card:runAction(cc.Spawn:create(cc.ScaleTo:create(time,cardScale),cc.MoveTo:create(time,cc.p(beganX + (index-1)*stepX, size.height/2))))
            end
            index = index + 1
        end
        self:showHandCard(wChairID,2) 
        self.lastOutCardInfo = pBuffer
        self.lastOutCardInfo.time = os.time()
        self.lastOutCardInfo.tipsIndex = 0
        self.lastOutCardInfo.tableCard = {}
        local wChairID = GameCommon:getRoleChairID()
        if self.lastOutCardInfo ~= nil and pBuffer.wCurrentUser == wChairID and self.lastOutCardInfo.wOutCardUser ~= wChairID and GameCommon.tableConfig.nTableType ~= TableType_Playback then
            self.lastOutCardInfo.tableCard = self:getExtractCardType(GameCommon.player[wChairID].cbCardData,GameCommon.player[wChairID].bUserCardCount,self.lastOutCardInfo.bCardData,self.lastOutCardInfo.bUserCardCount)
        end
        if pBuffer.wCurrentUser == wChairID and self.lastOutCardInfo.wOutCardUser ~= wChairID and #self.lastOutCardInfo.tableCard <= 0 then  
            self:showCountDown(pBuffer.wCurrentUser,true)
        else
            self:tryAutoSendCard(pBuffer.wCurrentUser)
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
    elseif action == NetMsgId.SUB_S_GAME_END_PDK then
        local wChairID = pBuffer.wWinUser
        self:resetUserCountTimeAni()
        if wChairID == GameCommon:getRoleChairID() then
            GameCommon:playAnimation(self.root, "我赢啦",GameCommon:getRoleChairID())
        else
            GameCommon:playAnimation(self.root, "我输啦",GameCommon:getRoleChairID())
        end
        for i = 0, GameCommon.gameConfig.bPlayerCount-1 do
        	if pBuffer.bUserCardCount[i+1] >= GameCommon.gameConfig.bSpringMinCount then
                GameCommon:playAnimation(self.root, "全关",i)
        	end
        end        
    end
	
end

function TableLayer:showCountDown(wChairID,isHide)     
    self:resetUserCountTimeAni()
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local Panel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    local Panel_countdown = Panel_player:getChildByName("Panel_countdown")
    local uiAtlasLabel_countdownTime = Panel_countdown:getChildByName("AtlasLabel_countdownTime")
    Panel_countdown:setVisible(true)

    uiAtlasLabel_countdownTime:stopAllActions()
    uiAtlasLabel_countdownTime:setString(15)
    local function onEventTime(sender,event)
        local currentTime = tonumber(uiAtlasLabel_countdownTime:getString())
        currentTime = currentTime - 1
        if currentTime < 0 then
            currentTime = 0
            uiAtlasLabel_countdownTime:stopAllActions()
        end
        uiAtlasLabel_countdownTime:setString(tostring(currentTime))
    end
    uiAtlasLabel_countdownTime:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime))))
    
    
    local uiPanel_out = ccui.Helper:seekWidgetByName(self.root,"Panel_out")
    uiPanel_out:setVisible(false)
    local uiImage_outTips = ccui.Helper:seekWidgetByName(self.root,"Image_outTips")
    uiImage_outTips:setVisible(false)
    if wChairID == GameCommon:getRoleChairID() then
        if isHide ~= true and GameCommon.tableConfig.nTableType ~= TableType_Playback then
            uiPanel_out:setVisible(true)
            if GameCommon.gameConfig.bAbandon == 0 then
                local wPlayerCount = GameCommon.gameConfig.bPlayerCount
                local meChairID = GameCommon:getRoleChairID()
                local xiajia = (meChairID+1)%wPlayerCount
                local uiImage_outTips = ccui.Helper:seekWidgetByName(self.root,"Image_outTips")
                uiImage_outTips:setVisible(GameCommon.player[xiajia].bUserWarn)
            end
        end
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",viewID))
        uiPanel_weaveItemArray:removeAllChildren()
    end
    
end

-------------------------------------------------------手牌-----------------------------------------------------
--设置手牌
function TableLayer:setHandCard(wChairID,bUserCardCount,cbCardData)
    GameCommon.player[wChairID].bUserCardCount = bUserCardCount
    GameCommon.player[wChairID].cbCardData = cbCardData
end

--删除手牌
function TableLayer:removeHandCard(wChairID, cbCardData)
    GameCommon.player[wChairID].bUserCardCount = GameCommon.player[wChairID].bUserCardCount - 1
    if GameCommon.player[wChairID].cbCardData == nil then
        return
    end
    for key, var in pairs(GameCommon.player[wChairID].cbCardData) do
    	if var == cbCardData then
    	   table.remove(GameCommon.player[wChairID].cbCardData,key)
    	   break
    	end
    end
    local deleteNode = nil
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    for key, var in pairs(tableCardNode) do
        if deleteNode == nil and var.data == cbCardData then
            deleteNode = var
        end
        var:stopAllActions()
        var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),0)))
--        var:setPositionY(0)
        var:setColor(cc.c3b(255,255,255))
    end
    if deleteNode then
        local pos = cc.p(deleteNode:getParent():convertToWorldSpace(cc.p(deleteNode:getPosition())))
        deleteNode:removeFromParent()
        return pos
    end
end

--更新手牌
function TableLayer:showHandCard(wChairID,effectsType,isShowEndCard)
    if GameCommon.player[wChairID].cbCardData == nil then
        return
    end
    local isCanMove = false
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_handCard = nil
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    if isShowEndCard == true then
        local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,"Panel_weaveItemArray")
        uiPanel_weaveItemArray:setVisible(false)
--        for i = 2, 3 do
--            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
--            uiPanel_player:setPositionY(cc.Director:getInstance():getVisibleSize().height*0.79)
--        end
    end
    local pos = cc.p(uiPanel_handCard:getPosition())
    local size = uiPanel_handCard:getContentSize()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local anchorPoint = uiPanel_handCard:getAnchorPoint()
    local index = 0
    local time = 0.05
    local cardScale = 1
    local cardWidth = 180 * cardScale    
    if viewID ~= 1 then
        cardScale = 0.7
        cardWidth = 120 * cardScale 
    end
    local cardHeight = 231 * cardScale
    local stepX = cardWidth * 0.4
    local stepY = cardHeight
    local beganX = 0
    if anchorPoint.x == 0 then
        beganX = 0
    elseif anchorPoint.x == 1 then
        beganX = size.width - ((GameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)
    else
        beganX = (size.width - ((GameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)) / 2
    end
    if effectsType == 2 then
        local tableCardNode = uiPanel_handCard:getChildren()
        for key, var in pairs(tableCardNode) do
            local pt = cc.p(beganX + (key-1)*stepX, 0)
            var.pt = pt
            var:setPositionY(0)
            var:setColor(cc.c3b(255,255,255))
            var:stopAllActions()
            var:runAction(cc.MoveTo:create(time,pt))
        end
        return
    end
    uiPanel_handCard:removeAllChildren()
    for i = 1, GameCommon.player[wChairID].bUserCardCount do
        if GameCommon.tableConfig.tableParameter.b15Or16 == 0 and i == 16 then 
        else
            local data = GameCommon.player[wChairID].cbCardData[i]
            local card = GameCommon:getCardNode(data)

            uiPanel_handCard:addChild(card)
            card:setScale(cardScale)
            card:setAnchorPoint(cc.p(0,0))
            card.data = data
            local pt = cc.p(beganX + (i-1)*stepX, 0)
            if anchorPoint.x == 0 then
                card:setPosition(-cardWidth*2, 0)
            else
                card:setPosition(visibleSize.width + cardWidth*2, 0)
            end
            
            if effectsType == 1 then
                card.pt = pt
                card:stopAllActions()
                card:runAction(cc.Sequence:create(cc.DelayTime:create(1*i*0.03),cc.MoveTo:create(time,pt)))
            else
                card.pt = pt
                card:setPosition(card.pt)
            end
        end
    end
    
end

function TableLayer:initUI()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    require("common.Common"):playEffect("game/pipeidonghua.mp3")
    local wKindID = GameCommon.tableConfig.wKindID
    --背景层
    local uiImage_watermark = ccui.Helper:seekWidgetByName(self.root,"Image_watermark")
    uiImage_watermark:loadTexture(StaticData.Games[wKindID].icon)
    uiImage_watermark:ignoreContentAdaptWithSize(true)
    local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
    uiText_desc:setString("")
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%02d:%02d",date.hour,date.min))
    end),cc.DelayTime:create(1))))
    --卡牌层
    
    --动画层
    self:resetUserCountTimeAni()  

    local uiPanel_out = ccui.Helper:seekWidgetByName(self.root,"Panel_out")
    uiPanel_out:setVisible(false)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_tips"),function() 
        GameCommon.hostedTime = os.time()
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",1))
        local tableCardNode = uiPanel_handCard:getChildren()
        for key, var in pairs(tableCardNode) do
            var:stopAllActions()
            var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),0)))
            --            var:setPositionY(0)
            var:setColor(cc.c3b(255,255,255))
        end
        if self.lastOutCardInfo == nil or self.lastOutCardInfo.tableCard == nil or #self.lastOutCardInfo.tableCard <= 0 then
            return
        end
        self.lastOutCardInfo.tipsIndex = self.lastOutCardInfo.tipsIndex + 1
        if self.lastOutCardInfo.tipsIndex > #self.lastOutCardInfo.tableCard then
            self.lastOutCardInfo.tipsIndex = 1
        end
        for key, var in pairs(self.lastOutCardInfo.tableCard[self.lastOutCardInfo.tipsIndex]) do
            for k, v in pairs(tableCardNode) do
                if v.data == var then
                    v:stopAllActions()
                    v:runAction(cc.MoveTo:create(0.1,cc.p(v:getPositionX(),20)))
                    --                 v:setPositionY(20)
                end
            end
        end
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_outCard"),function() 
        GameCommon.hostedTime = os.time()
        local wChairID = GameCommon:getRoleChairID()
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
        local tableCardNode = uiPanel_handCard:getChildren()
        local tableCardData = {}
        for key, var in pairs(tableCardNode) do
            if var:getPositionY() ~= 0 then
                table.insert(tableCardData,#tableCardData+1, var.data)
            end
        end
        self:sendCard(wChairID,tableCardData)
    end)

    local Button_notoutCard = ccui.Helper:seekWidgetByName(self.root,"Button_notoutCard")
    Button_notoutCard:setVisible(false)
    if GameCommon.tableConfig.tableParameter.bMustOutCard ~= nil and GameCommon.tableConfig.tableParameter.bMustOutCard == 1 then 
        Button_notoutCard:setVisible(true)
    end
    Common:addTouchEventListener(Button_notoutCard,function()
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_PASS_CARD,"")
    end)

    --用户层
    for i = 1, 3 do
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        uiPanel_player:setVisible(false)
        local uiImage_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
        self:setUserHeadCliping(uiImage_avatar)

        uiImage_avatarFrame:setTouchEnabled(true)
        uiImage_avatarFrame:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then
                for key, var in pairs(GameCommon.player) do
                    if GameCommon:getViewIDByChairID(var.wChairID) == i then
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_PLAYER_INFO,"d",var.dwUserID)
                        break
                    end
                end
            end
        end)       
        local uiImage_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        local uiImage_laba = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_laba")
        uiImage_laba:setVisible(false)
        local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
        uiImage_banker:setVisible(false)
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
        uiText_name:setString("")
        local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
        uiText_score:setString("")
        local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
        uiImage_ready:setVisible(false)
        local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_chat")
        uiImage_chat:setVisible(false)
    end
    local Score_piaofen = {
        [1] = {[1] =0 , [2] =1 , [3] =2, [4] =3 },
        [2] = {[1] =0 , [2] =2 , [3] =3, [4] =5 },
        [3] = {[1] =0 , [2] =3 , [3] =5, [4] =8 },
    }

    --飘分
    local uiPanel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
    uiPanel_piaoFen:setVisible(false)
    GameCommon.wPiaoCount = {}
    if GameCommon.tableConfig.tableParameter.bJiaPiao ~= nil and GameCommon.tableConfig.tableParameter.bJiaPiao ~= 0 then 
        local child = {}
        for i=1,4 do
            local child = ccui.Helper:seekWidgetByName(Panel_piaoFen,(i-1))
            print("++++++++++++++++",child,i,Score_piaofen[GameCommon.tableConfig.tableParameter.bJiaPiao][i])
            GameCommon.wPiaoCount[i] = Score_piaofen[GameCommon.tableConfig.tableParameter.bJiaPiao][i]
        end    
    end 

    --UI层
    local uiButton_menu = ccui.Helper:seekWidgetByName(self.root,"Button_menu")
    local uiPanel_function = ccui.Helper:seekWidgetByName(self.root,"Panel_function")
    uiPanel_function:setEnabled(false)
    Common:addTouchEventListener(uiButton_menu,function() 
        uiPanel_function:stopAllActions()
        uiPanel_function:runAction(cc.Sequence:create(cc.MoveTo:create(0.2,cc.p(-99,0)),cc.CallFunc:create(function(sender,event) 
            uiPanel_function:setEnabled(true)
        end)))
        uiButton_menu:stopAllActions()
        uiButton_menu:runAction(cc.ScaleTo:create(0.2,0))
    end)
    uiPanel_function:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            uiPanel_function:stopAllActions()
            uiPanel_function:runAction(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
                uiPanel_function:setEnabled(false)
            end),cc.MoveTo:create(0.2,cc.p(0,0))))
            uiButton_menu:stopAllActions()
            uiButton_menu:runAction(cc.ScaleTo:create(0.2,1))
        end
    end)  
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_skin"),function() 
        local box = require("app.MyApp"):create():createGame('game.puke.KwxPukeColor')
		self:addChild(box) 
        -- local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
        -- UserDefault_Pukepaizhuo = UserDefault_Pukepaizhuo + 1
        -- if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 4 then
        --     UserDefault_Pukepaizhuo = 1
        -- end
        -- cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
        -- uiPanel_bg:removeAllChildren()
        -- uiPanel_bg:addChild(ccui.ImageView:create(string.format("puke/ui/beijing_%d.jpg",UserDefault_Pukepaizhuo)))
    end)
    local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
    if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 4 then
        UserDefault_Pukepaizhuo = 1
        cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
    end
    if UserDefault_Pukepaizhuo ~= 0 then
        uiPanel_bg:removeAllChildren()
        uiPanel_bg:addChild(ccui.ImageView:create(string.format("puke/ui/beijing_%d.jpg",UserDefault_Pukepaizhuo)))
    end
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_font"),function() 
        local UserDefault_PukeCard = nil 
        if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
            UserDefault_PukeCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_PukeCard,0)
        else
            UserDefault_PukeCard = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_PukeCard,1)
        end 
        UserDefault_PukeCard = UserDefault_PukeCard + 1
        if UserDefault_PukeCard < 0 or UserDefault_PukeCard > 1 then
            UserDefault_PukeCard = 0
        end
        cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_PukeCard,UserDefault_PukeCard)
        --牌背
        if GameCommon.gameConfig.bPlayerCount ~= nil then 
            for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
                local wChairID = i
                if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
                    self:showHandCard(wChairID,3)
                end
            end
        end
    end)
    
    local uiPanel_night = ccui.Helper:seekWidgetByName(self.root,"Panel_night")
    local UserDefault_Pukeliangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_Pukeliangdu,0)
    if UserDefault_Pukeliangdu == 0 then
        uiPanel_night:setVisible(false)
    else
        uiPanel_night:setVisible(true)
    end
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_settings"),function() 
        -- local path = self:requireClass('PDKSetting')
		-- local box = require("app.MyApp"):create():createGame(path)
        -- self:addChild(box)
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("SettingsLayer"))
    end)
    local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    uiButton_expression:setPressedActionEnabled(true)
    local function onEventExpression(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local child = self:getChildByName('PDKChat')
			if child and child:getName() == 'PDKChat' then
				child:setVisible(true)
				return true
			end
			local path = self:requireClass('PDKChat')
			local box = require("app.MyApp"):create():createGame(path)
			box:setName('PDKChat')
			self:addChild(box)
        end
    end
    uiButton_expression:addTouchEventListener(onEventExpression)
    local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
    uiButton_ready:setVisible(false)
    Common:addTouchEventListener(uiButton_ready,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_READY,"o",false)
    end) 
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    Common:addTouchEventListener(uiButton_Invitation,function() 
        local currentPlayerCount = 0
        for key, var in pairs(GameCommon.player) do
            currentPlayerCount = currentPlayerCount + 1
        end
        local player = "("
        for key, var in pairs(GameCommon.player) do
            if key == 0 then
                player = player..var.szNickName
            else
                player = player.."、"..var.szNickName
            end
        end
        player = player..")"
        local data = clone(UserData.Share.tableShareParameter[3])
        if data then
            data.dwClubID = GameCommon.tableConfig.dwClubID
            data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[GameCommon.tableConfig.wKindID].name,
                GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wTableNumber,
                GameCommon.gameConfig.bPlayerCount,GameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
            data.szShareContent = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig).." (点击加入游戏)"
            data.szShareUrl = string.format(data.szShareUrl, GameCommon.tableConfig.szGameID)
            if GameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
                data.cbTargetType = Bit:_xor(data.cbTargetType,0x20)
            end
            require("app.MyApp"):create(data, handler(self, self.pleaseOnlinePlayer)):createView("ShareLayer")
        end
        dump(data, 'ShareData:')
    end)
    local uiButton_disbanded = ccui.Helper:seekWidgetByName(self.root,"Button_disbanded")
    Common:addTouchEventListener(uiButton_disbanded,function() 
        require("common.MsgBoxLayer"):create(1,nil,"是否确定解散房间？",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
        end)
    end)
    local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")  --取消按钮
    Common:addTouchEventListener(uiButton_cancel,function() 
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    end)  
    local uiButton_out = ccui.Helper:seekWidgetByName(self.root,"Button_out")
    Common:addTouchEventListener(uiButton_out,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定离开房间?\n房主离开意味着房间被解散",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_LEAVE_TABLE_USER,"")
        end)
    end) 
    
    local uiButton_SignOut = ccui.Helper:seekWidgetByName(self.root,"Button_SignOut")
    Common:addTouchEventListener(uiButton_SignOut,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定返回大厅?",function()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end)
    end) 
    if CHANNEL_ID == 6 or  CHANNEL_ID  == 7  or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
    else
        uiButton_SignOut:setVisible(false)
        -- uiButton_out:setPositionX(visibleSize.width*0.36)       
        -- uiButton_Invitation:setPositionX(visibleSize.width*0.64)  
    end 
    
    local uiButton_position = ccui.Helper:seekWidgetByName(self.root,"Button_position")   -- 定位
    Common:addTouchEventListener(uiButton_position,function() 
        require("common.PositionLayer"):create(GameCommon.tableConfig.wKindID)
       -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createGame("game.puke.KwxLocationLayer"))
       -- require("game.yongzhou.PositionLayer"):create(GameCommon.tableConfig.wKindID)
    end)

    local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
    if GameCommon.tableConfig.wCurrentNumber == 0 and  GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
        if CHANNEL_ID ~= 0 and CHANNEL_ID ~= 1 then
            uiPanel_playerInfoBg:setVisible(false) 
        else 
            uiPanel_playerInfoBg:setVisible(false)
        end
    end
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    Common:addTouchEventListener(uiButton_return,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定返回大厅?",function()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
        end)
    end)
    --结算层
    local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
    uiPanel_end:setVisible(false)
    --灯光层
    local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
    local uiText_des = ccui.Helper:seekWidgetByName(self.root,"Text_des")
    uiText_title:setString(StaticData.Games[GameCommon.tableConfig.wKindID].name)    
    if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
        self:addVoice()
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
        if  StaticData.Hide[CHANNEL_ID].btn10 == 0 then 
            uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position)) 
            uiPanel_playerInfoBg:setVisible(false) 
        end
        uiButton_cancel:setVisible(false)
        if GameCommon.gameState == GameCommon.GameState_Start  then
            local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            uiPanel_ready:setVisible(false)
            if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
                uiButton_Invitation:setVisible(false)
                uiButton_out:setVisible(false)
            else
                uiButton_Invitation:setVisible(true)
                uiButton_out:setVisible(true)
            end

        elseif GameCommon.tableConfig.wCurrentNumber > 0 then
            uiButton_Invitation:setVisible(false)
            uiButton_out:setVisible(false)
            uiButton_SignOut:setVisible(false)
        end
        if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
            uiButton_Invitation:setVisible(false)
            -- uiButton_out:setPositionX(visibleSize.width*0.5)   
        end
        uiText_des:setString(string.format("房间号:%d 局数:%d/%d",GameCommon.tableConfig.wTbaleID, GameCommon.tableConfig.wCurrentNumber, GameCommon.tableConfig.wTableNumber))

        -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/dengdaihaoyou/dengdaihaoyou.ExportJson")
        -- local waitArmature=ccs.Armature:create("dengdaihaoyou")
        -- waitArmature:setPosition(-179.2,150)
        -- if CHANNEL_ID == 6 or  CHANNEL_ID  == 7 or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
        --     waitArmature:setPosition(0,150)
        -- end 
        -- waitArmature:getAnimation():playWithIndex(0)
        -- uiButton_Invitation:addChild(waitArmature)   

    elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then            
        self:addVoice()
        uiPanel_playerInfoBg:setVisible(false)
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        uiButton_out:setVisible(false)
        uiButton_SignOut:setVisible(false)
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_disbanded)) 
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position)) 
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
--        uiPanel_ready:setVisible(false)
        uiButton_voice:setVisible(false)
        uiButton_expression:setVisible(false)
        if GameCommon.tableConfig.cbLevel == 2 then
            uiText_des:setString(string.format("中级场 倍率 %d",GameCommon.tableConfig.wCellScore))
        elseif GameCommon.tableConfig.cbLevel == 3 then
            uiText_des:setString(string.format("高级场 倍率 %d",GameCommon.tableConfig.wCellScore))
        else
            uiText_des:setString(string.format("初级场 倍率 %d",GameCommon.tableConfig.wCellScore))
        end
        self:drawnout()  
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xunzhaoduishou/xunzhaoduishou.ExportJson")
        local waitArmature=ccs.Armature:create("xunzhaoduishou")
        waitArmature:setPosition(0,150)
--        waitArmature:setPosition(0,-158)
        waitArmature:getAnimation():playWithIndex(0)
        uiButton_cancel:addChild(waitArmature)
        
    else
        local uiPanel_ui = ccui.Helper:seekWidgetByName(self.root,"Panel_ui")
        uiPanel_ui:setVisible(false)
        uiText_des:setString("牌局回放")
    end
    
    --重启游戏
    local Button_reset = ccui.Helper:seekWidgetByName(self.root,"Button_reset")
    Button_reset:setPressedActionEnabled(true)
    local function onEventReset(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true,true):createView("LoginLayer"),SCENE_LOGIN)
        end
    end
    Button_reset:addTouchEventListener(onEventReset)

    -- @cxx 牌桌查看俱乐部
    local Button_clubTable = ccui.Helper:seekWidgetByName(self.root,"Button_clubTable")
    local Button_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local Button_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    if GameCommon.tableConfig.nTableType == TableType_ClubRoom and GameCommon.tableConfig.nTableType ~= TableType_Playback then
        if GameCommon.gameState == GameCommon.GameState_Start or GameCommon.tableConfig.wCurrentNumber > 0 then
            Button_clubTable:setVisible(false)
            Button_expression:setVisible(true)
            Button_voice:setVisible(true)
        else
            Button_clubTable:setVisible(true)
            Button_expression:setVisible(false)
            Button_voice:setVisible(false)
        end

        Common:addTouchEventListener(Button_clubTable,function()
            local dwClubID = GameCommon.tableConfig.dwClubID
            self:addChild(require("app.MyApp"):create(dwClubID):createView("NewClubFreeTableLayer"))
        end)
    else
        Button_clubTable:setVisible(false)
    end
end

function TableLayer:addClickItem()
    local Panel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
    local child = {}
    for i=1,4 do
        local child = ccui.Helper:seekWidgetByName(Panel_piaoFen,(i-1))
        Common:addTouchEventListener(child,function() 
            local index= child:getName()
            print('--xx',GameCommon.wPiaoCount[i])
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_JIAPIAO,"b",GameCommon.wPiaoCount[i])
        end)
        --table.insert(childs,child)
    end
end


function TableLayer:drawnout()
    local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root,"Image_timedown")
    uiImage_timedown:setVisible(false)
    
    local uiText__timedown = ccui.Helper:seekWidgetByName(self.root,"Text__timedown")
    uiText__timedown:setPosition(uiText__timedown:getParent():getContentSize().width/2,uiText__timedown:getParent():getContentSize().height*0.56)
    uiText__timedown:stopAllActions()
    uiText__timedown:setString("00:00:00")
    local currentTime = 0
    local function onEventTime(sender,event)   
        currentTime = currentTime + 1
        uiText__timedown:setString(string.format("%02d:%02d:%02d",math.floor(currentTime/(60*60)),math.floor(currentTime/60),math.floor(currentTime%60)))
    end
    uiText__timedown:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime)))) 

end 

function TableLayer:updateGameState(state)
    GameCommon.gameState = state 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    if state == GameCommon.GameState_Init then
    elseif state == GameCommon.GameState_Start then
		require("common.SceneMgr"):switchOperation()
        local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
        uiPanel_playerInfoBg:setVisible(false)
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
        uiPanel_ready:setVisible(false)
        if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
            -- --距离报警  
            -- if GameCommon.tableConfig.wCurrentNumber ~= nil and GameCommon.tableConfig.wCurrentNumber == 1 and GameCommon.DistanceAlarm ~= 1  then
            --     if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
            --         GameCommon.DistanceAlarm = 1 
            --         if GameCommon.gameConfig.bPlayerCount ~= 2 then 
            --            require("common.DistanceAlarm"):create(GameCommon)
            --         end                    
            --     end 
            -- end
            for i = 1, 3 do
                local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
                local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
                uiImage_ready:setVisible(false)
            end
        elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
            local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
            uiButton_expression:setVisible(true)
            local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
            uiButton_voice:setVisible(true)
        end         
        local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")  --取消按钮
        uiButton_cancel:setVisible(false)
        local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root,"Image_timedown")
        uiImage_timedown:setVisible(false)
    elseif state == GameCommon.GameState_Over then
        UserData.Game:addGameStatistics(GameCommon.tableConfig.wKindID)
    else
    
    end

    -- @cxx 牌桌查看俱乐部
    local Button_clubTable = ccui.Helper:seekWidgetByName(self.root,"Button_clubTable")
    local Button_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local Button_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    if GameCommon.tableConfig.nTableType == TableType_ClubRoom and GameCommon.tableConfig.nTableType ~= TableType_Playback then
        if GameCommon.gameState == GameCommon.GameState_Start or GameCommon.tableConfig.wCurrentNumber > 0 then
            Button_clubTable:setVisible(false)
            Button_expression:setVisible(true)
            Button_voice:setVisible(true)
        else
            Button_clubTable:setVisible(true)
            Button_expression:setVisible(false)
            Button_voice:setVisible(false)
        end
    end
end

--语音
function TableLayer:addVoice()
    self.tableVoice = {}
    local startVoiceTime = 0
    local maxVoiceTime = 15
    local intervalTimePackage = 0.1
    local fileName = "temp_voice.mp3"
    local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local animVoice = cc.CSLoader:createNode("VoiceNode.csb")
    self:addChild(animVoice,120)
    local root = animVoice:getChildByName("Panel_root")
    local uiPanel_recording = ccui.Helper:seekWidgetByName(root,"Panel_recording")
    local uiPanel_cancel = ccui.Helper:seekWidgetByName(root,"Panel_cancel")
    local uiText_surplus = ccui.Helper:seekWidgetByName(root,"Text_surplus")
    animVoice:setVisible(false)

    --重置状态
    local duration = 0
    local function resetVoice()
        startVoiceTime = 0
        animVoice:stopAllActions()
        animVoice:setVisible(false)
        uiPanel_recording:setVisible(true)

        local uiImage_pro = ccui.Helper:seekWidgetByName(root,"Image_pro")
        uiImage_pro:removeAllChildren()
        local volumeMusic = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Music",1)
        cc.SimpleAudioEngine:getInstance():setMusicVolume(volumeMusic)
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
        uiButton_voice:removeAllChildren()
        local node = require("common.CircleLoadingBar"):create("game/tablenew_23.png")
        node:setColor(cc.c3b(0,0,0))
        uiButton_voice:addChild(node)
        node:setPosition(node:getParent():getContentSize().width/2,node:getParent():getContentSize().height/2)
        node:start(1)
        uiButton_voice:setEnabled(false)
        uiButton_voice:stopAllActions()
        uiButton_voice:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
            uiButton_voice:setEnabled(true)
        end)))
    end

    root:setTouchEnabled(true)
    root:addTouchEventListener(function(sender,event) 
        UserData.Game:cancelVoice()
        resetVoice() 
    end)

    local function onEventSendVoic(event)
        if self.root == nil then
            return
        end
        if cc.PLATFORM_OS_ANDROID == cc.Application:getInstance():getTargetPlatform() then
            if event == nil or string.len(event) <= 0 then
                return
            else
                event = Base64.decode(event)
            end
            local file = io.open(FileDir.dirVoice..fileName,"wb+")
            file:write(event)
            file:close()
        end
        if cc.FileUtils:getInstance():isFileExist(FileDir.dirVoice..fileName) == false then
            print("没有找到录音文件",FileDir.dirVoice..fileName)
            return
        end
        local fp = io.open(FileDir.dirVoice..fileName,"rb")
        local fileData = fp:read("*a")
        fp:close()

        local data = {}
        data.chirID = GameCommon:getRoleChairID()
        data.time = duration
        data.file = string.format("%d_%d.mp3",os.time(),UserData.User.userID)

        local fp = io.open(FileDir.dirVoice..data.file,"wb+")
        fp:write(fileData)
        fp:close()
        table.insert(self.tableVoice,#self.tableVoice + 1,data) 

        cc.FileUtils:getInstance():removeFile(FileDir.dirVoice..fileName)   --windows test

        local fileSize = string.len(fileData)
        local packSize = 1024
        local additional = fileSize%packSize
        if additional > 0 then
            additional = 1
        else
            additional = 0
        end
        local packCount = math.floor(fileSize/packSize) + additional
        local currentPos = 0
        for i = 1 , packCount do
            local periodData = string.sub(fileData,1,packSize)
            fileData = string.sub(fileData,packSize + 1)
            local periodSize = string.len(periodData)
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE,"wwwdddnsnf",GameCommon:getRoleChairID(),packCount,i,data.time,fileSize,periodSize,32,data.file,periodSize,periodData)
        end

    end

    local function onEventVoice(sender,event)
        if event == ccui.TouchEventType.began then
            startVoiceTime = 0
            uiButton_voice:setEnabled(false)
            animVoice:setVisible(true)
            cc.SimpleAudioEngine:getInstance():setMusicVolume(0) 
            cc.SimpleAudioEngine:getInstance():setEffectsVolume(0) 
            uiPanel_recording:setVisible(true)
            startVoiceTime = os.time()
            UserData.Game:startVoice(FileDir.dirVoice..fileName,maxVoiceTime,onEventSendVoic)

            local node = require("common.CircleLoadingBar"):create("common/yuying02.png")
            local uiImage_pro = ccui.Helper:seekWidgetByName(root,"Image_pro")
            uiImage_pro:removeAllChildren()
            uiImage_pro:addChild(node)
            node:setPosition(node:getParent():getContentSize().width/2,node:getParent():getContentSize().height/2)
            node:start(maxVoiceTime)

            local currentTime = 0
            uiText_surplus:stopAllActions()
            uiText_surplus:setString(string.format("还剩%d秒",maxVoiceTime - currentTime))
            uiText_surplus:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
                currentTime = currentTime + 1
                if currentTime > maxVoiceTime then
                    uiText_surplus:stopAllActions()
                    return
                end
                uiText_surplus:setString(string.format("还剩%d秒",maxVoiceTime - currentTime))
            end))))

        elseif event == ccui.TouchEventType.ended then
            if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
                UserData.Game:cancelVoice()
                resetVoice()
                return
            end
            duration = os.time() - startVoiceTime
            resetVoice()
            UserData.Game:overVoice()
            --onEventSendVoic() --windows test
        elseif event == ccui.TouchEventType.canceled then   
            if startVoiceTime == 0 or os.time() - startVoiceTime < 1 then
                resetVoice()
                return
            end
            resetVoice()
            UserData.Game:cancelVoice()
        end
    end
    uiButton_voice:addTouchEventListener(onEventVoice)
    local function onEventPlayVoice(sender,event)
        if #self.tableVoice > 0 then
            local data = self.tableVoice[1]
            table.remove(self.tableVoice,1)
            if data.time > maxVoiceTime then
                data.time = maxVoiceTime
            end
            local viewID = GameCommon:getViewIDByChairID(data.chirID)
            local wanjia = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_laba = ccui.Helper:seekWidgetByName(wanjia,"Image_laba")
            local blinks = math.floor(data.time*2)+1
            uiImage_laba:stopAllActions()
            uiImage_laba:runAction(cc.Sequence:create(
                cc.Show:create(),
                cc.CallFunc:create(function(sender,event) 
                    require("common.Common"):playVoice(FileDir.dirVoice..data.file)
                end),
                cc.Blink:create(data.time,blinks) ,
                cc.Hide:create(),
                cc.DelayTime:create(1),
                cc.CallFunc:create(function(sender,event) 
                    cc.FileUtils:getInstance():removeFile(FileDir.dirVoice..data.file) 
                    onEventPlayVoice()
                end)
            ))

        else
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(onEventPlayVoice)))
        end
    end
    onEventPlayVoice()
end

function TableLayer:OnUserChatVoice(event)
    if self.tableVoicePackages == nil then
        self.tableVoicePackages = {}
    end
    if self.tableVoicePackages[event.szFileName] == nil then
        self.tableVoicePackages[event.szFileName] = {}
    end
    self.tableVoicePackages[event.szFileName][event.wPackIndex] = event

    --组包
    if event.wPackCount == #self.tableVoicePackages[event.szFileName] then
        local fileData = ""
        for key, var in pairs(self.tableVoicePackages[event.szFileName]) do
            fileData = fileData..var.szPeriodData
        end 
        local data = {}
        data.chirID = self.tableVoicePackages[event.szFileName][1].wChairID
        data.time = self.tableVoicePackages[event.szFileName][1].dwTime
        data.file = self.tableVoicePackages[event.szFileName][1].szFileName
        local fp = io.open(FileDir.dirVoice..data.file,"wb+")
        fp:write(fileData)
        fp:close()
        table.insert(self.tableVoice,#self.tableVoice + 1,data)
        self.tableVoicePackages[event.szFileName] = nil
        print("插入一条语音...",fileData)
    end
end

function TableLayer:showPlayerPosition()   -- 显示玩家距离    
    local wChairID = 0
    for key, var in pairs(GameCommon.player) do
        if var.dwUserID == GameCommon.dwUserID then
            wChairID = var.wChairID
            break
        end
    end
    for wChairID = 1, 4 do
        local uiPanel_players = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_players%d",wChairID))
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
        uiImage_avatar:loadTexture("common/common_dian1.png")
        local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
        uiText_name:setString("") 
        for i = wChairID+1 , 4 do 
            local  uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",wChairID,i)) 
            uiText_location:setString("")       
        end 
    end  
    local viewID = GameCommon:getViewIDByChairID(wChairID) 
    for wChairID = 0, 3 do
        if GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_players = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_players%d",viewID))
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_players,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
            if GameCommon.player[wChairID] ~= nil then 
                uiImage_avatar:loadTexture("common/common_dian2.png")
            end 
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)
            for wTargetChairID = 0, GameCommon.gameConfig.bPlayerCount-1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
                if GameCommon.gameConfig.bPlayerCount == 3 and wTargetChairID == 3 then
                    viewID = 4
                end
                if wTargetChairID ~= wChairID then
                    local uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",viewID,targetViewID))
                    if viewID > targetViewID then
                        uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",targetViewID,viewID))
                    end
                    if uiText_location ~= nil then
                        local distance = uiText_location:getString()
                        if GameCommon.gameConfig.bPlayerCount == 3 and (wChairID == 3 or wTargetChairID == 3) then
                            distance = ""
                        elseif GameCommon.player[wChairID] == nil or GameCommon.player[wTargetChairID] == nil then
                            distance = "等待加入..."
                        elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
                            if distance == "500m" then
                                distance = math.random(1000,300000)
                            end
                        elseif GameCommon.player[wChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",GameCommon.player[wChairID].szNickName)
                        elseif GameCommon.player[wTargetChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",GameCommon.player[wTargetChairID].szNickName)
                        else
                            distance = GameCommon:GetDistance(GameCommon.player[wChairID].location,GameCommon.player[wTargetChairID].location) 
                        end                     
                        if type(distance) == "string" then

                        elseif distance > 1000 then
                            distance = string.format("%dkm",distance/1000)
                        else
                            distance = string.format("%dm",distance)
                        end
                        uiText_location:setString(distance)
                    end
                end
            end
        end
    end
end

function TableLayer:showPlayerInfo(infoTbl)       -- 查看玩家信息
    Common:palyButton()
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(infoTbl, self):createGame("game.puke.PDKPersonInfor"))
    --require("common.PersonalLayer"):create(GameCommon.tableConfig.wKindID,dwUserID,dwShamUserID)
end
function TableLayer:showChat(pBuffer)
    local viewID = GameCommon:getViewIDByChairID(pBuffer.dwUserID, true)
	local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
	local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_chat")
	local uiText_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Text_chat")
	uiText_chat:setString(pBuffer.szChatContent)
	uiImage_chat:setVisible(true)
	uiImage_chat:setScale(0)
	uiImage_chat:stopAllActions()
	uiImage_chat:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1), cc.DelayTime:create(5), cc.Hide:create()))
	local wKindID = GameCommon.tableConfig.wKindID
	local Chat = nil
	local Chat = require("game.puke.ChatConfig")
    local data = Chat[pBuffer.dwSoundID - 100]

	local sound = nil
	if data then
		sound = data.sound
	end
	local soundData = nil
	local soundFile = ''
	if data then
		soundData = sound[1]
		if GameCommon.language ~= 0 then
			local wKindID = GameCommon.tableConfig.wKindID
			if wKindID == 47 or wKindID == 48 or wKindID == 49 or wKindID == 60 then
				soundData = sound[2]
			end
		end
		
		if soundData ~= nil then
			soundFile = soundData[pBuffer.cbSex]
		end
	end
	
	if data ~= nil and soundFile ~= "" then
		require("common.Common"):playEffect(soundFile)
	end
end

function TableLayer:showReward(pBuffer)
    if pBuffer.lRet == 0 then 
        local rewardData = {}
        rewardData.wPropID = 0
        if pBuffer.bType == 0 then 
            rewardData = {{wPropID = 1001,dwPropCount = tonumber(pBuffer.lCount) }}
        else
            rewardData = {{wPropID = 1008,dwPropCount = tonumber(pBuffer.lCount) }}
        end 
        EventMgr:dispatch("RET_GET_MALL_LOG_FINISH",data)
        require("common.RewardLayer"):create("领取成功",nil,rewardData)
    elseif pBuffer.lRet == 1 then 
        local rewardData = {}
        rewardData = {{wPropID = 1001,dwPropCount = tonumber(pBuffer.lCount) }}
        EventMgr:dispatch("RET_GET_MALL_LOG_FINISH",data)
        require("common.RewardLayer"):create("活动结束，自动领取玩豆",nil,rewardData)
    elseif pBuffer.lRet == 2 then 
        require("common.MsgBoxLayer"):create(0,nil,"参数错误")
    elseif pBuffer.lRet == 3 then 
        require("common.MsgBoxLayer"):create(0,nil,"玩家不存在")
    elseif pBuffer.lRet == 4 then 
        require("common.MsgBoxLayer"):create(0,nil,"该游戏不支持领取红包卷")
    end 
end

function TableLayer:showExperssion(pBuffer)
	self:playSpine(pBuffer)
end

function TableLayer:playSpine(pBuffer)
    local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

    local viewID = GameCommon:getViewIDByChairID(pBuffer.wChairID, true)
    local Panel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    local userAnim = ccui.Helper:seekWidgetByName(Panel_player, string.format("Panel_anim_%d", viewID))
    
	local worldPos = cc.p(userAnim:getParent():convertToWorldSpace(cc.p(userAnim:getPosition())))

	local path = ''
	local index = math.floor(pBuffer.wIndex / 50) + 1
	local animIndex
	if index == 1 then --第一页
		animIndex = 23
	elseif index == 2 then --第二页
		animIndex = 24
	end
	local anim
	if animIndex then
		anim = require("game.puke.Animation") [animIndex]
	end
	if anim then
        local id = math.mod(pBuffer.wIndex, 50)


		local data = anim[id]
		if data then
			local skeletonNode = cusNode:getChildByName('pdkskele_' .. pBuffer.wIndex)
			if not skeletonNode then
				skeletonNode = sp.SkeletonAnimation:create(data.animFile .. '.json', data.animFile .. '.atlas')
				cusNode:addChild(skeletonNode)
				skeletonNode:setName('pdkskele_' .. pBuffer.wIndex)
			end
			skeletonNode:setPosition(worldPos)
			skeletonNode:setAnimation(0, data.animName, false)
			skeletonNode:setVisible(true)

			local idx = 1
			skeletonNode:registerSpineEventHandler(function()
				idx = idx + 1
				if idx > 3 then
					-- skeletonNode:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.RemoveSelf:create()))
					skeletonNode:setVisible(false)
				else
					skeletonNode:setAnimation(0, data.animName, false)
				end
			end, sp.EventType.ANIMATION_COMPLETE)
			
			local sound = data.sound
			local soundData = nil
			local soundFile = ''
			if sound then
				
				soundData = sound[GameCommon.language]
				if GameCommon.language ~= 0 then
					local wKindID = GameCommon.tableConfig.wKindID
					if wKindID == 47 or wKindID == 48 or wKindID == 49 or wKindID == 60 then
						soundData = sound[2]
					end
				end
				
				if soundData ~= nil then
					local player = GameCommon.player[pBuffer.wChairID]
					local csbSex = 0
					if player then
						csbSex = player.cbSex
					end
					soundFile = soundData[csbSex]
				end
			end
			
			if soundFile and soundFile ~= "" then
				require("common.Common"):playEffect(soundFile)
			end
		end
	end
end

--提取牌型
function TableLayer:getMaxCardType(bCardData,bUserCardCount)
    local tableCard = self:getExtractCardType(bCardData,bUserCardCount)
    if #tableCard <= 0 then
        return nil
    end
    local max = 0
    for key, var in pairs(tableCard) do
        if max == 0 then
            max = key
        elseif #var > #tableCard[max] then
            max = key
        else
        end
    end
    return tableCard[max]
end

function TableLayer:tryAutoSendCard(wCurrentUser)
    local wChairID = GameCommon:getRoleChairID()
    if wCurrentUser ~= wChairID then
        self:showCountDown(wCurrentUser)
        return
    end
    --如果上次出牌是其他人
    if self.lastOutCardInfo.wOutCardUser ~= wChairID then
        if #self.lastOutCardInfo.tableCard == 1 and #self.lastOutCardInfo.tableCard[1] == GameCommon.player[wChairID].bUserCardCount then
            local tabelCard = {}
            for i = 1, GameCommon.player[wChairID].bUserCardCount do
                table.insert(tabelCard,#tabelCard+1,GameCommon.player[wChairID].cbCardData[i])
            end
            self:sendCard(wChairID,tabelCard)
            self:showCountDown(wCurrentUser,true)
            return
        end
    else
        --如果是自己，尝试甩牌
        local targetType, targetCardData = self:getCardTypeAndCard(GameCommon.player[wChairID].cbCardData,GameCommon.player[wChairID].bUserCardCount)
        if targetType ~= GameCommon.CardType_error then 
            if targetType ~= GameCommon.CardType_bomb then 
                local tableSortCard = self:getSortCard(GameCommon.player[wChairID].cbCardData,GameCommon.player[wChairID].bUserCardCount)
                if #tableSortCard[4] > 0 then
                    self:showCountDown(wCurrentUser)
                    return
                end
            end
            local tabelCard = {}
            for i = 1, GameCommon.player[wChairID].bUserCardCount do
                table.insert(tabelCard,#tabelCard+1,GameCommon.player[wChairID].cbCardData[i])
            end
            self:sendCard(wChairID,tabelCard)
            self:showCountDown(wCurrentUser,true)
            return
        end
    end
    self:showCountDown(wCurrentUser)
end

function TableLayer:sendCard(wChairID,tableCardData)
    local net = NetMgr:getGameInstance()
    if net.connected == false then
        return
    end
    if #tableCardData <= 0 then
        return
    end
    net.cppFunc:beginSendBuf(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OUT_CARD_PDK)
    net.cppFunc:writeSendByte(#tableCardData,0)
    for key, var in pairs(tableCardData) do
        net.cppFunc:writeSendByte(var,0)
    end
    for i = #tableCardData+1, GameCommon.MAX_COUNT do
        net.cppFunc:writeSendByte(0,0)
    end
    net.cppFunc:writeSendWORD(wChairID,0)
    net.cppFunc:endSendBuf()
    net.cppFunc:sendSvrBuf()
end

--连续排序
function TableLayer:getSortCard(bCardData,bUserCardCount)
    local tableSortCard = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    }
    local preValue = nil
    local tableCard = {}
    for key = 1, bUserCardCount do
        local data = bCardData[key]
        local value = Bit:_and(data,0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if preValue == nil or preValue ~= value then
            local num = #tableCard
            if num > 0 then
                table.insert(tableSortCard[num],1,clone(tableCard))
            end
            preValue = value
            tableCard = {}
            table.insert(tableCard,1,data)
        else
            table.insert(tableCard,1,data)
        end
    end
    local num = #tableCard
    if num > 0 and tableSortCard[num] then
        table.insert(tableSortCard[num],1,clone(tableCard))
    end
    return tableSortCard
end

--分析牌型
function TableLayer:getCardTypeAndCard(bCardData,bUserCardCount)
    if bUserCardCount <= 0 then
        return GameCommon.CardType_error
    end
    local tableSortCard = self:getSortCard(bCardData,bUserCardCount)
    if bUserCardCount == 4 and #tableSortCard[4] == 1 then
        --是否为炸弹
        return GameCommon.CardType_bomb, tableSortCard[4][1]
    
    end
    
    if bUserCardCount == 1 and #tableSortCard[1] == 1 then
        --是否为单牌
        return GameCommon.CardType_single, tableSortCard[1][1]
    end
    
    if bUserCardCount == 2 and #tableSortCard[2] == 1 then
        --是否为对子
        return GameCommon.CardType_pair, tableSortCard[2][1]
        
    end
    
    if bUserCardCount >= 5 and bUserCardCount == #tableSortCard[1] then
        --是否为顺子 
        local preValue = nil
        local tableReturnCard = {}
        for key, var in pairs(tableSortCard[1]) do
            local data = var[1]
	        local value = Bit:_and(data,0x0F)
            if value == 1 then
                value = 14
            else
            end
            if preValue == nil or preValue+1 == value then
                table.insert(tableReturnCard,#tableReturnCard+1,data)
                preValue = value
            else
                break
            end
        end
        if #tableReturnCard == bUserCardCount then
            return GameCommon.CardType_straight, tableReturnCard
        end
    end
    
    if bUserCardCount == #tableSortCard[2]*2 then
        --是否为连对 
        local preValue = nil
        local tableReturnCard = {}
        for key, var in pairs(tableSortCard[2]) do
            local data = var[1]
            local value = Bit:_and(data,0x0F)
            if value == 1 then
                value = 14
            else
            end
            if preValue == nil or preValue+1 == value then
                for k, v in pairs(var) do
                    table.insert(tableReturnCard,#tableReturnCard+1,v)
                end
                preValue = value
            else
                break
            end
        end
        if #tableReturnCard == bUserCardCount then
            return GameCommon.CardType_straightPair, tableReturnCard
        end
    end
    
    if GameCommon.gameConfig.b4Add3 and bUserCardCount >= 6 and bUserCardCount <= 7 and #tableSortCard[4] == 1 then
        --是否为四带三
        local tableReturnCard = clone(tableSortCard[4][1])
        tableSortCard[4] = {}
        for key, var in pairs(tableSortCard) do
        	for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
        	end
        end
        if #tableReturnCard == bUserCardCount then
            return GameCommon.CardType_4Add3, tableReturnCard
        end
    end 
       
    --炸弹是否可以拆
    if GameCommon.gameConfig.bBombSeparation == 1 then
        for key, var in pairs(tableSortCard[4]) do
            local data = var[1]
            local value = Bit:_and(data,0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            local table3Same = clone(var)
            local table1Same = {clone(var[4])}
            table.remove(table3Same,#table3Same)
            local isInsert = false
            for k, v in pairs(tableSortCard[3]) do
                local value1 = Bit:_and(v[1],0x0F)
                if value1 == 1 then
                    value1 = 14
                elseif value1 == 2 then
                    value1 = 15
                end
                if value < value1 then
                    table.insert(tableSortCard[3],k,table3Same)
                    isInsert = true
                    break
                end
        	end
        	if isInsert == false then
                table.insert(tableSortCard[3],#tableSortCard[3]+1,table3Same)
        	end
        	
            local isInsert = false
            for k, v in pairs(tableSortCard[1]) do
                local value1 = Bit:_and(data,0x0F)
                if value1 == 1 then
                    value1 = 14
                elseif value1 == 2 then
                    value1 = 15
                end
                if value > value1 then
                    table.insert(tableSortCard[1],k,table1Same)
                    isInsert = true
                    break
                end
            end
            if isInsert == false then
                table.insert(tableSortCard[1],#tableSortCard[1]+1,table1Same)
            end
        end
        tableSortCard[4] = {}
    end
    
    
    if bUserCardCount >= 3 and bUserCardCount <= 5 and #tableSortCard[3] == 1 then
        --是否为三带二
       local tableReturnCard = clone(tableSortCard[3][1])
       tableSortCard[3] = {}
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return GameCommon.CardType_3Add2, tableReturnCard
        end
    end
    
    if #tableSortCard[3] >= 2 and bUserCardCount >= #tableSortCard[3]*3 and bUserCardCount <= #tableSortCard[3]*5 then
       --是否为飞机
       local preValue = nil
        local tableReturnCard = {}
        for key, var in pairs(tableSortCard[3]) do
            local data = var[1]
            local value = Bit:_and(data,0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if preValue == nil or preValue+1 == value then
                for k, v in pairs(var) do
                    table.insert(tableReturnCard,#tableReturnCard+1,v)
                end
                preValue = value
            else
                if #tableReturnCard/3 < 2 then
                    tableReturnCard = {}
                    for k, v in pairs(var) do
                        table.insert(tableReturnCard,#tableReturnCard+1,v)
                    end
                    preValue = value
                else
                    break
                end
            end
        end
        local count = #tableReturnCard/3
        if count >= 2 then
            for key, var in pairs(tableReturnCard) do
                local isFound = false
                for k, v in pairs(tableSortCard[3]) do
                    for iKey, iVar in pairs(v) do
                    	if iVar == var then
                            table.remove(v,iKey)
                            isFound = true
                            break
                    	end
                    end
                    if isFound == true then break end
            	end
            end
            for key, var in pairs(tableSortCard) do
                for k, v in pairs(var) do
                    for ikey, ivar in pairs(v) do
                        table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                        if #tableReturnCard%(count*5) == 0 then break end
                    end
                end
                if #tableReturnCard%(count*5) == 0 then break end
            end
            if #tableReturnCard == bUserCardCount then
                return GameCommon.CardType_airplane, tableReturnCard
            end
        end
    end
    return GameCommon.CardType_error
end

--提取牌型
function TableLayer:getExtractCardType(bCardData,bUserCardCount,bTargetCardData,bTargetUserCardCount)
    local tableCard = {}
    if bUserCardCount <= 0 then
        return tableCard
    end
    local tableSortCard = self:getSortCard(bCardData,bUserCardCount)
    local targetType = nil
    local targetCardData = nil
    if bTargetUserCardCount ~= nil and bTargetUserCardCount > 0 then
        targetType, targetCardData = self:getCardTypeAndCard(bTargetCardData,bTargetUserCardCount)
    end
    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)
    end
    if targetValue == 1 then
        targetValue = 14
    elseif targetValue == 2 then
        targetValue = 15
    end
	if targetType == GameCommon.CardType_single then
        local wPlayerCount = GameCommon.gameConfig.bPlayerCount
        local meChairID = GameCommon:getRoleChairID()
        local xiajia = (meChairID+1)%wPlayerCount
        if GameCommon.gameConfig.bAbandon == 0 and GameCommon.player[xiajia].bUserWarn == true then
            local maxValue = nil
            local maxData = nil
            for key, var in ipairs(tableSortCard) do
                for k, v in pairs(var) do
                    if #v < 4 then
                        local value = Bit:_and(v[1],0x0F)
                        if value == 1 then
                            value = 14
                        elseif value == 2 then
                            value = 15
                        end
                        if value > targetValue and (maxValue == nil or value > maxValue) then
                            maxValue = value
                            maxData = v[1]
                        end
                    end

                end
            end
            if maxValue ~= nil then
                table.insert(tableCard,#tableCard+1,{maxData})
            end
        else
    	   --提取单张
    	   local tableSortCardTemp = clone(tableSortCard)
    	   for key, var in pairs(tableSortCardTemp[1]) do
    	       local value = Bit:_and(var[1],0x0F)
               if value == 1 then
                   value = 14
               elseif value == 2 then
                   value = 15
               end
    	       if value > targetValue then
    	   	       table.insert(tableCard,#tableCard+1,{var[#var]})
    	   	   end
    	   end
    	   for key, var in pairs(tableSortCardTemp[2]) do
    	       local value = Bit:_and(var[1],0x0F)
               if value == 1 then
                   value = 14
               elseif value == 2 then
                   value = 15
               end
               if value > targetValue then
                    table.insert(tableCard,#tableCard+1,{var[#var]})
               end
           end
           for key, var in pairs(tableSortCardTemp[3]) do
               local value = Bit:_and(var[1],0x0F)
               if value == 1 then
                   value = 14
               elseif value == 2 then
                   value = 15
               end
               if value > targetValue then
                   table.insert(tableCard,#tableCard+1,{var[#var]})
               end
           end
       end
	end
	
   if targetType == GameCommon.CardType_pair then
       --提取对子
       local tableSortCardTemp = clone(tableSortCard)
       for key, var in pairs(tableSortCardTemp[2]) do
           local value = Bit:_and(var[1],0x0F)
           if value == 1 then
               value = 14
           elseif value == 2 then
               value = 15
           end
           if value > targetValue then
               table.insert(tableCard,#tableCard+1,var)
           end
       end
       for key, var in pairs(tableSortCardTemp[3]) do
           local value = Bit:_and(var[1],0x0F)
           if value == 1 then
               value = 14
           elseif value == 2 then
               value = 15
           end
           if value > targetValue then
               table.remove(var,1)
               table.insert(tableCard,#tableCard+1,var)
           end
       end
    end
    
    if targetType == nil or targetType == GameCommon.CardType_straight then
       --提取顺子
       --排序
       local tableSortCardTemp = {}
       for key, var in ipairs(tableSortCard) do
       	   for k, v in pairs(var) do
       	       if #v < 4 then
           	       local value = Bit:_and(v[1],0x0F)
                   if value == 1 then
                       value = 14
                   elseif value == 2 then
                       value = 15
                   end
                   tableSortCardTemp[value] = v[#v]
               end
       	       
       	   end
       end
       tableSortCardTemp[15] = nil
       --删除中断
       local targetMinValue = 3
       if targetCardData ~= nil then
            targetMinValue = Bit:_and(targetCardData[1],0x0F)
           if targetMinValue == 1 then
               targetMinValue = 14
           elseif targetMinValue == 2 then
               targetMinValue = 15
           end
           targetMinValue = targetMinValue + 1
       end
       if targetCardData ~= nil then
           for i = targetMinValue , 14 do
                local tableReturnCard = {}
                for j = 0, #targetCardData-1 do
                    if tableSortCardTemp[i+j] ~= nil then
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j])
                    else
                        break
                    end
                end
                if #tableReturnCard == #targetCardData then
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        else
            local tableReturnCard = {}
            for i = 0, 15 do
                if tableSortCardTemp[i] ~= nil then
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i])
                else
                    if #tableReturnCard >= 5 then
                        table.insert(tableCard,#tableCard+1,tableReturnCard)
                    end
                    tableReturnCard = {}
                end
            end
            
        end
    end
    
    if targetType == nil or targetType == GameCommon.CardType_straightPair then
        --提取连对
        --排序
        local tableSortCardTemp = {}
        for key, var in ipairs(tableSortCard) do
            for k, v in pairs(var) do
                if #v >= 2 and #v < 4 then
                    local value = Bit:_and(v[1],0x0F)
                    if value == 1 then
                        value = 14
                    elseif value == 2 then
                        value = 15
                    end
                    tableSortCardTemp[value] = {v[#v-1],v[#v]}
                end

            end
        end
        tableSortCardTemp[15] = nil
        --删除中断
        local targetMinValue = 3
        if targetCardData ~= nil then
            targetMinValue = Bit:_and(targetCardData[1],0x0F)
            if targetMinValue == 1 then
                targetMinValue = 14
            elseif targetMinValue == 2 then
                targetMinValue = 15
            end
            targetMinValue = targetMinValue + 1
        end
        if targetCardData ~= nil then
            for i = targetMinValue , 14 do
                local tableReturnCard = {}
                for j = 0, #targetCardData/2-1 do
                    if tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] >=2 and #tableSortCardTemp[i+j] <= 3 then
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]-1])
                    else
                        break
                    end
                end
                if #tableReturnCard == #targetCardData then
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        else
            local tableReturnCard = {}
            for i = 0, 15 do
                if tableSortCardTemp[i] ~= nil and #tableSortCardTemp[i] >=2 and #tableSortCardTemp[i] <= 3 then
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i][#tableSortCardTemp[i]])
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i][#tableSortCardTemp[i]-1])
                else
                    if #tableReturnCard >= 4 and #tableReturnCard%2 == 0 then
                        table.insert(tableCard,#tableCard+1,tableReturnCard)
                    end
                    tableReturnCard = {}
                end
            end
        end
    end
    
    --提取三带二
    if targetType == nil or targetType == GameCommon.CardType_3Add2 then
        local tableSortCardTemp = clone(tableSortCard)
        for key, var in pairs(tableSortCardTemp[3]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                bTargetUserCardCount = bTargetUserCardCount or bUserCardCount
                --补2个
                if #tableReturnCard%bTargetUserCardCount ~= 0 then
                    for k, v in pairs(tableSortCardTemp[1]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%bTargetUserCardCount == 0 then break end
                    	end
                        if #tableReturnCard%bTargetUserCardCount == 0 then break end
                    end
                end
                if #tableReturnCard%bTargetUserCardCount ~= 0 then
                    for k, v in pairs(tableSortCardTemp[2]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%bTargetUserCardCount == 0 then break end
                        end
                        if #tableReturnCard%bTargetUserCardCount == 0 then break end
                    end
                end
                if #tableReturnCard%bTargetUserCardCount ~= 0 then
                    for k, v in pairs(tableSortCardTemp[3]) do
                        local value1 = Bit:_and(v[1],0x0F)
                        if value1 == 1 then
                            value1 = 14
                        elseif value1 == 2 then
                            value1 = 15
                        end
                        if value ~= value1 then
                            for kKey, vVar in pairs(v) do
                                table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                                if #tableReturnCard%bTargetUserCardCount == 0 then break end
                            end
                            if #tableReturnCard%bTargetUserCardCount == 0 then break end
                        end
                    end
                end
                if targetCardData == nil or (targetCardData ~= nil and (#tableReturnCard == #targetCardData or (#tableReturnCard == bUserCardCount and bUserCardCount >= 3))) then
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        end
    end
    
    --提取四带三
    if GameCommon.gameConfig.b4Add3 == 1 and(targetType == GameCommon.CardType_4Add3) then
        local tableSortCardTemp = clone(tableSortCard)
        for key, var in pairs(tableSortCardTemp[4]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                --补3个
                if #tableReturnCard%7 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[1]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%7 == 0 then break end
                        end
                        if #tableReturnCard%7 == 0 then break end
                    end
                end
                if #tableReturnCard%7 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[2]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%7 == 0 then break end
                        end
                        if #tableReturnCard%7 == 0 then break end
                    end
                end
                if #tableReturnCard%7 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[3]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%7 == 0 then break end
                        end
                        if #tableReturnCard%7 == 0 then break end
                    end
                end
                if targetCardData == nil or (targetCardData ~= nil and #tableReturnCard == #targetCardData) then
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        end
    end
	
    if targetType == nil or targetType == GameCommon.CardType_airplane then
        --提取飞机
        --排序
        local tableSortCardTemp = {}
        for key, var in ipairs(tableSortCard) do
            for k, v in pairs(var) do
                if #v < 4 then
                    local value = Bit:_and(v[1],0x0F)
                    if value == 1 then
                        value = 14
                    elseif value == 2 then
                        value = 15
                    end
                    tableSortCardTemp[value] = clone(v)
                end

            end
        end
        tableSortCardTemp[15] = nil
        --删除中断
        local targetMinValue = 3
        if targetCardData ~= nil then
            targetMinValue = Bit:_and(targetCardData[1],0x0F)
            if targetMinValue == 1 then
                targetMinValue = 14
            elseif targetMinValue == 2 then
                targetMinValue = 15
            end
            targetMinValue = targetMinValue + 1
        end
        if targetCardData ~= nil then
            local count = #targetCardData/5
            for i = targetMinValue , 14 do
                local tableReturnCard = {}
                local table3SameValue = {}
                local isAirplane = true
                for j = 0, count-1 do
                    if tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] == 3 then
                        table3SameValue[i+j] = true
                        for key, var in pairs(tableSortCardTemp[i+j]) do
                            table.insert(tableReturnCard,#tableReturnCard+1,var)
                        end
                    else
                        isAirplane = false
                        break
                    end
                end
                if isAirplane == true then
                    --补齐
                    for key, var in pairs(tableSortCard[1]) do
                        for k, v in pairs(var) do
                            table.insert(tableReturnCard,#tableReturnCard+1,v)
                            if #tableReturnCard%(count*5) == 0 then break end
                        end
                        if #tableReturnCard%(count*5) == 0 then break end
                    end
                    if #tableReturnCard%(count*5) ~= 0 then
                        for key, var in pairs(tableSortCard[2]) do
                            for k, v in pairs(var) do
                                table.insert(tableReturnCard,#tableReturnCard+1,v)
                                if #tableReturnCard%(count*5) == 0 then break end
                            end
                            if #tableReturnCard%(count*5) == 0 then break end
                        end
                    end
                    if #tableReturnCard%(count*5) ~= 0 then
                        for key, var in pairs(tableSortCard[3]) do
                            local value = Bit:_and(var[1],0x0F)
                            if value == 1 then
                                value = 14
                            elseif value == 2 then
                                value = 15
                            end
                            if table3SameValue[value] == nil then
                                for k, v in pairs(var) do
                                    table.insert(tableReturnCard,#tableReturnCard+1,v)
                                    if #tableReturnCard%(count*5) == 0 then break end
                                end
                                if #tableReturnCard%(count*5) == 0 then break end
                            end
                        end
                    end
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        else
            local tableReturnCard = {}
            local table3SameValue = {}
            for i = 0, 15 do
                if tableSortCardTemp[i] ~= nil and #tableSortCardTemp[i] == 3 then
                    table3SameValue[i] = true
                    for key, var in pairs(tableSortCardTemp[i]) do
                        table.insert(tableReturnCard,#tableReturnCard+1,var)
                    end
                else
                    if #tableReturnCard >= 6 then
                        local count = #tableReturnCard/3
                        --补齐
                        if #tableReturnCard%(count*5) ~= 0 then
                            for key, var in pairs(tableSortCard[1]) do
                                for k, v in pairs(var) do
                                    table.insert(tableReturnCard,#tableReturnCard+1,v)
                                    if #tableReturnCard%(count*5) == 0 then break end
                                end
                                if #tableReturnCard%(count*5) == 0 then break end
                            end
                        end
                        if #tableReturnCard%(count*5) ~= 0 then
                            for key, var in pairs(tableSortCard[2]) do
                                for k, v in pairs(var) do
                                    table.insert(tableReturnCard,#tableReturnCard+1,v)
                                    if #tableReturnCard%(count*5) == 0 then break end
                                end
                                if #tableReturnCard%(count*5) == 0 then break end
                            end
                        end
                        if #tableReturnCard%(count*5) ~= 0 then
                            for key, var in pairs(tableSortCard[3]) do
                                local value = Bit:_and(var[1],0x0F)
                                if value == 1 then
                                    value = 14
                                elseif value == 2 then
                                    value = 15
                                end
                                if table3SameValue[value] == nil then
                                    for k, v in pairs(var) do
                                        table.insert(tableReturnCard,#tableReturnCard+1,v)
                                        if #tableReturnCard%(count*5) == 0 then break end
                                    end
                                    if #tableReturnCard%(count*5) == 0 then break end
                                end
                            end
                        end
                        table.insert(tableCard,#tableCard+1,tableReturnCard)
                    end
                    tableReturnCard = {}
                    table3SameValue = {}
                end
            end
        end
    end
    
	--提取炸弹
	if targetType == nil or targetType ~= GameCommon.CardType_bomb then
	   targetValue = 0
	end
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[4]) do
        local value = Bit:_and(var[1],0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if value > targetValue then
            table.insert(tableCard,#tableCard+1,var)
        end
    end
    return tableCard    
end

function TableLayer:EVENT_TYPE_SKIN_CHANGE(event)
    local data = event._usedata
    -- if data ~= 2 then
    --     return
    -- end
    --背景
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
    if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 4 then
        UserDefault_Pukepaizhuo = 1
        cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
    end
    uiPanel_bg:removeAllChildren()
    uiPanel_bg:addChild(ccui.ImageView:create(string.format("puke/ui/beijing_%d.jpg",UserDefault_Pukepaizhuo)))

    --亮度
    local uiPanel_night = ccui.Helper:seekWidgetByName(self.root,"Panel_night")
    local UserDefault_Pukeliangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_Pukeliangdu,0)
    if UserDefault_Pukeliangdu == 0 then
        uiPanel_night:setVisible(false)
    else
        uiPanel_night:setVisible(true)
    end
    --字体
    --牌背
    if GameCommon.gameConfig.bPlayerCount then
        for i = 0 , GameCommon.gameConfig.bPlayerCount-1 do
            local wChairID = i
            if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
                self:showHandCard(wChairID,3)
            end
        end
    end
end

--[
-- @brief  吃不起的牌置灰
-- @param  void
-- @return void
--]
function TableLayer:setUnCardGrey()
    local Panel_handCard1 = ccui.Helper:seekWidgetByName(self.root, "Panel_handCard1")
    local tableCardArr = Panel_handCard1:getChildren()

    if type(self.lastOutCardInfo) ~= 'table' then
        printError('TableLayer:setUnCardGrey data format error')
        return
    end

    local cardInfo = self.lastOutCardInfo.tableCard or {}
    if #cardInfo < 1 then
        return
    end

    for _, node in ipairs(tableCardArr) do
        local isFind = false
        for __, info in ipairs(cardInfo) do
            for ___, data in ipairs(info) do
                if node.data == data then
                    isFind = true
                    break
                end
            end
            if isFind then break end
        end

        if not isFind then
            node:setColor(cc.c3b(170, 170, 170))
        end
    end
end

--[
-- @brief  只有一种吃法自动选择弹出
-- @param  void
-- @return void
--]
function TableLayer:autoSelOnlyType()
    local Panel_handCard1 = ccui.Helper:seekWidgetByName(self.root, "Panel_handCard1")
    local tableCardArr = Panel_handCard1:getChildren()

    if type(self.lastOutCardInfo) ~= 'table' then
        printError('TableLayer:setUnCardGrey data format error')
        return
    end

    local cardInfo = self.lastOutCardInfo.tableCard or {}
    if #cardInfo ~= 1 then
        return
    end

    for _, data in ipairs(cardInfo[1]) do
        for __, node in ipairs(tableCardArr) do
            if node.data == data then
                node:stopAllActions()
                node:runAction(cc.MoveTo:create(0.1,cc.p(node:getPositionX(),20)))
                break
            end
        end
    end
end

function TableLayer:EVENT_TYPE_SIGNAL(event)
    local time = event._usedata
    local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
    local uiText_signal = ccui.Helper:seekWidgetByName(self.root,"Text_signal")
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        if time <= 100 then
            uiImage_signal:loadTexture("common/xinghao4.png")
            uiText_signal:setColor(cc.c3b(140,255,25))
        elseif time <= 200 then
            uiImage_signal:loadTexture("common/xinghao3.png")
            uiText_signal:setColor(cc.c3b(219,255,0))
        elseif time <= 300 then
            uiImage_signal:loadTexture("common/xinghao2.png")
            uiText_signal:setColor(cc.c3b(255,191,0))
        else
            uiImage_signal:loadTexture("common/xinghao1.png")
            uiText_signal:setColor(cc.c3b(255,0,20))
        end
        if time < 0 then
            uiText_signal:setString("")
        else
            uiText_signal:setString(string.format("%dms",time))
        end
    else
        uiImage_signal:setVisible(false)
    end
end

function TableLayer:EVENT_TYPE_ELECTRICITY(event)
    local data = event._usedata
    local uiImage_Electricity = ccui.Helper:seekWidgetByName(self.root,"Image_Electricity")
    local uiLoadingBar_Electricity = ccui.Helper:seekWidgetByName(self.root,"LoadingBar_Electricity")
    if data <= 0.1 then
        uiLoadingBar_Electricity:setColor(cc.c3b(255,0,20))
    elseif data <= 0.2 then
        uiLoadingBar_Electricity:setColor(cc.c3b(255,191,0))
    else
        uiLoadingBar_Electricity:setColor(cc.c3b(140,255,25))
    end
    uiLoadingBar_Electricity:setPercent(data*100)
end

--[
-- @brief  设置用户头像裁剪
-- @param  headNode 用户头像节点
-- @param  headPath 用户头像路径
-- @return void
--]
function TableLayer:setUserHeadCliping(headNode, headPath)
    if not headNode then
        return
    end
    headPath = headPath or "common/hall_avatar.png"
    headNode:loadTexture(headPath)

    -- headNode:setVisible(false)
    -- local headFrameNode = headNode:getParent():getChildByName("Image_avatarFrame")
    -- local clipNode = cc.Sprite:create("common/hall_paohuzi_head.png")
    -- local clip_node = cc.ClippingNode:create(clipNode)
    -- local clip_size = clipNode:getContentSize()
    -- local headNode = cc.Sprite:create(headPath)
    -- local head_size = headNode:getContentSize()
    -- headNode:setScale(clip_size.width / head_size.width, clip_size.height / head_size.height)
    -- clip_node:addChild(headNode)
    -- clip_node:setAlphaThreshold(0)
    -- local size = headFrameNode:getContentSize()
    -- clip_node:setPosition(size.width / 2, size.height / 2)
    -- headFrameNode:addChild(clip_node)
end

--[
-- @brief  重置用户出牌计时动作
-- @param  void
-- @return void
--]
function TableLayer:resetUserCountTimeAni()
    for i = 1, 3 do
        local Panel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        local Panel_countdown = Panel_player:getChildByName("Panel_countdown")
        local AtlasLabel_countdownTime = Panel_countdown:getChildByName("AtlasLabel_countdownTime")
        Panel_countdown:setVisible(false)
        AtlasLabel_countdownTime:stopAllActions()

        -- local aniNode = Panel_countdown:getChildByName('AniTimeCount' .. i)
        -- if not aniNode then
        --     ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/wanjiachupaitishi/wanjiachupaitishi.ExportJson")
        --     local waitArmature = ccs.Armature:create("wanjiachupaitishi")
        --     waitArmature:getAnimation():playWithIndex(0)
        --     Panel_countdown:addChild(waitArmature)
        --     waitArmature:setName('AniTimeCount' .. i)
        -- end
    end
end

--==============================--
--desc:表情互动
--time:2018-08-14 07:40:11
--@wChairID:
--@return 
--==============================--

function TableLayer:getViewWorldPosByChairID(wChairID)
	for key, var in pairs(GameCommon.player) do
		if wChairID == var.wChairID then
			local viewid = GameCommon:getViewIDByChairID(var.wChairID, true)
			local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewid))
			local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
			return uiImage_avatar:getParent():convertToWorldSpace(cc.p(uiImage_avatar:getPosition()))
		end
	end
end

function TableLayer:playSketlAnim(sChairID, eChairID, index,indexEx)

    local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil!')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

	local Animation = require("game.puke.Animation")
	local AnimCnf = Animation[24]
	
	if not AnimCnf[index] then
		return
	end
    
    local skele_key_name = 'hyhudong_' .. index .. indexEx
	local spos = self:getViewWorldPosByChairID(sChairID)
	local epos = self:getViewWorldPosByChairID(eChairID)
	local image = ccui.ImageView:create(AnimCnf[index].imageFile .. '.png')
	self:addChild(image)
	image:setPosition(spos)
	local moveto = cc.MoveTo:create(0.6, cc.p(epos))
	local callfunc = cc.CallFunc:create(function()
		local path = AnimCnf[index].animFile
		local skeletonNode = cusNode:getChildByName(skele_key_name)
		if not skeletonNode then
			skeletonNode = sp.SkeletonAnimation:create(path .. '.json', path .. '.atlas', 1)
			cusNode:addChild(skeletonNode)
			skeletonNode:setName(skele_key_name)
		end
		skeletonNode:setPosition(epos)
		skeletonNode:setAnimation(0, AnimCnf[index].animName, false)
		skeletonNode:setVisible(true)
		image:removeFromParent()

		skeletonNode:registerSpineEventHandler(function(event)
			skeletonNode:setVisible(false)
		end, sp.EventType.ANIMATION_END)
		
		local soundData = AnimCnf[index]
		local soundFile = ''
		if soundData then
			local sound = soundData.sound
			if sound then
				soundFile = sound[0]
			end
		end
		
		if soundFile ~= "" then
			require("common.Common"):playEffect(soundFile)
		end
	end)
	image:runAction(cc.Sequence:create(moveto, callfunc))
end

--表情互动
function TableLayer:playSkelStartToEndPos(sChairID, eChairID, index)
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('PDKOpenUserEffect', true) --是否接受别人的互动
	
	if GameCommon.meChairID == sChairID then --我发出
		if sChairID == eChairID then
			for i, v in pairs(GameCommon.player or {}) do
				if v.wChairID ~= sChairID then
					self:playSketlAnim(sChairID, v.wChairID, index, v.wChairID)
				end
			end
		else
			self:playSketlAnim(sChairID, eChairID, index,0)
		end
	else
		if self.isOpen then
			if sChairID == eChairID then
				for i, v in pairs(GameCommon.player or {}) do
					if v.wChairID ~= sChairID then
						self:playSketlAnim(sChairID, v.wChairID, index, v.wChairID)
					end
				end
			else
				self:playSketlAnim(sChairID, eChairID, index,0)
			end
		end
	end
end

--邀请在线好友
function TableLayer:pleaseOnlinePlayer()
    local dwClubID = GameCommon.tableConfig.dwClubID
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(dwClubID):createView("PleaseOnlinePlayerLayer"))
end

function TableLayer:refreshTableInfo()
    local playerNum = 0
    for k, v in pairs(GameCommon.player or {}) do
        playerNum = playerNum + 1
    end
    local Button_Invitation = ccui.Helper:seekWidgetByName(self.root, "Button_Invitation")
    local Button_ready = ccui.Helper:seekWidgetByName(self.root, "Button_ready")
    if playerNum >= GameCommon.gameConfig.bPlayerCount then
        Button_Invitation:setVisible(false)
        Button_ready:setVisible(true)        
        --距离报警  
        if GameCommon.tableConfig.wCurrentNumber ~= nil and GameCommon.tableConfig.wCurrentNumber == 0 and GameCommon.DistanceAlarm ~= 1  then
            if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
                GameCommon.DistanceAlarm = 1 
                if GameCommon.gameConfig.bPlayerCount ~= 2 then 
                    --require("common.PositionLayer"):create(GameCommon.tableConfig.wKindID)
                    --require("common.DistanceAlarm"):create(GameCommon)
                	local tips = require("common.DistanceTip")
                	tips:checkDis(GameCommon.tableConfig.wKindID)
                end                    
            end 
        end  
    else
        Button_Invitation:setVisible(true)
        Button_ready:setVisible(false)
    end

    local Button_position = ccui.Helper:seekWidgetByName(self.root, "Button_position")
    if GameCommon.gameConfig.bPlayerCount <= 2 and Button_position then
        Button_position:removeFromParent()
    end
end

function TableLayer:requireClass(name)
	local path = string.format("game.%s.%s", APPNAME, name)
	return path
end

return TableLayer