local StaticData = require("app.static.StaticData")
local DDZGameCommon = require("game.puke.DDZGameCommon") 
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
local DDZTableLayer = class("DDZTableLayer",function()
    return ccui.Layout:create()
end)

local APPNAME = 'puke'

function DDZTableLayer:create(root)
    local view = DDZTableLayer.new()
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

function DDZTableLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:registListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:registListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)
    if DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
        if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
            local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
            if uiImage_signal ~= nil then 
                uiImage_signal:setVisible(false) 
            end
        end
    end
    UserData.User:initByLevel()
end

function DDZTableLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:unregistListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)
end

function DDZTableLayer:onCreate(root)
    self.root = root
    self.lastOutCardInfo = {
        bUserCardCount = 0,
        wCurrentUser = 0,
        wOutCardUser = nil,
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

function DDZTableLayer:switchCard(location,touchType)
    local wChairID = DDZGameCommon:getRoleChairID()
    if DDZGameCommon.gameState ~= DDZGameCommon.GameState_Start then
        return
    end
    if DDZGameCommon.player[wChairID].cbCardData == nil then
    	return
    end
    local cardScale = 1
    local cardWidth = 161 * cardScale
    local cardHeight = 231 * cardScale
    local stepX = cardWidth * 0.3
    local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
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

function DDZTableLayer:doAction(action,pBuffer)
    if action == NetMsgId.SUB_S_GAME_START_PDK then
        if pBuffer.bStartCard > 0 then
            local visibleSize = cc.Director:getInstance():getVisibleSize()
            local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
            local card = DDZGameCommon:getCardNode(pBuffer.bStartCard) 
            uiPanel_tipsCard:addChild(card)          
            card:setScale(1.5)
            card:runAction(cc.Sequence:create(
                cc.ScaleTo:create(0.1,1),
                cc.DelayTime:create(1.0),
                cc.FadeOut:create(0.5),
                cc.RemoveSelf:create()))
            local viewID = DDZGameCommon:getViewIDByChairID(pBuffer.wCurrentUser)
            local uiPanel_tipsCardPosUser = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_tipsCardPos%d",viewID))
            card:setPosition(uiPanel_tipsCardPosUser:getPosition())
        end
        -- DDZGameCommon:playAnimation(self.root, "我先出",pBuffer.wCurrentUser)
        --self:showCountDown(pBuffer.wCurrentUser)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        local uiButton_out = ccui.Helper:seekWidgetByName(self.root,"Button_out")
        uiButton_out:setVisible(false)
    elseif action == NetMsgId.SUB_S_USER_PASS_CARD_PDK then
        DDZGameCommon:playAnimation(self.root, "要不起",pBuffer.wPassUser)
        local wChairID = pBuffer.wPassUser
        local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",viewID))
        uiPanel_weaveItemArray:removeAllChildren()
        local wChairID = DDZGameCommon:getRoleChairID()
        if self.lastOutCardInfo ~= nil and pBuffer.wCurrentUser == wChairID and self.lastOutCardInfo.wOutCardUser ~= wChairID and DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
            self.lastOutCardInfo.tableCard = self:getExtractCardType(DDZGameCommon.player[wChairID].cbCardData,DDZGameCommon.player[wChairID].bUserCardCount,self.lastOutCardInfo.bCardData,self.lastOutCardInfo.bUserCardCount)
        end
        if pBuffer.wCurrentUser == wChairID and self.lastOutCardInfo.wOutCardUser ~= wChairID and #self.lastOutCardInfo.tableCard <= 0 then  
            self:showCountDown(pBuffer.wCurrentUser,true)
        else
            self:tryAutoSendCard(pBuffer.wCurrentUser)
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
                             
    elseif action == NetMsgId.SUB_S_WARN_INFO_PDK then
        DDZGameCommon:playAnimation(self.root, "报警",pBuffer.wWarnUser)
        DDZGameCommon.player[pBuffer.wWarnUser].bUserWarn = true
        if DDZGameCommon.gameConfig.bAbandon == 0 then
            local wPlayerCount = DDZGameCommon.gameConfig.bPlayerCount
            local meChairID = DDZGameCommon:getRoleChairID()
            local xiajia = (meChairID+1)%wPlayerCount
            local wChairID = DDZGameCommon:getRoleChairID()
            if pBuffer.wWarnUser == xiajia and self.lastOutCardInfo.wOutCardUser ~= wChairID and DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
                self.lastOutCardInfo.tableCard = self:getExtractCardType(DDZGameCommon.player[wChairID].cbCardData,DDZGameCommon.player[wChairID].bUserCardCount,pBuffer.bCardData,pBuffer.bUserCardCount)
            end
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
    
    elseif action == NetMsgId.SUB_S_OUT_CARD_PDK then     
                      
        local targetType,targetCardData = self:getCardTypeAndCard(pBuffer.bCardData,pBuffer.bUserCardCount)
        --local targetCardData = pBuffer.bCardData

        if targetType == DDZGameCommon.CardType_single then
            local value = Bit:_and(pBuffer.bCardData[1],0x0F)
            if pBuffer.bCardData[1] == 78 then 
                value = 16
            elseif  pBuffer.bCardData[1] == 78 then 
                value = 17
            end 
            DDZGameCommon:playAnimation(self.root, value,pBuffer.wOutCardUser)
        elseif targetType == DDZGameCommon.CardType_pair then
            local value = Bit:_and(pBuffer.bCardData[1],0x0F)
            DDZGameCommon:playAnimation(self.root, string.format("对%d",value),pBuffer.wOutCardUser)
        elseif targetType == DDZGameCommon.CardType_straight then
            DDZGameCommon:playAnimation(self.root, "顺子",pBuffer.wOutCardUser)
        elseif targetType == DDZGameCommon.CardType_straightPair then
            DDZGameCommon:playAnimation(self.root, "连对",pBuffer.wOutCardUser)
        elseif targetType == DDZGameCommon.CardType_three then
            DDZGameCommon:playAnimation(self.root, "三条",pBuffer.wOutCardUser)
        elseif targetType == DDZGameCommon.CardType_3Add1 then
            if pBuffer.bUserCardCount == 4 then
                DDZGameCommon:playAnimation(self.root, "三带一",pBuffer.wOutCardUser)
            end
        elseif targetType == DDZGameCommon.CardType_3Add2 then
            if pBuffer.bUserCardCount == 5 then
                DDZGameCommon:playAnimation(self.root, "三带二",pBuffer.wOutCardUser)
            end
        elseif targetType == DDZGameCommon.CardType_airplane then
            DDZGameCommon:playAnimation(self.root, "飞机",pBuffer.wOutCardUser)
        elseif targetType == DDZGameCommon.CardType_4Add2 then
            if pBuffer.bUserCardCount == 6 then
                DDZGameCommon:playAnimation(self.root, "四带二",pBuffer.wOutCardUser)
            end
        elseif targetType == DDZGameCommon.CardType_4Add3 then
            if pBuffer.bUserCardCount == 7 then
                DDZGameCommon:playAnimation(self.root, "四带三",pBuffer.wOutCardUser)
            end
        elseif targetType == DDZGameCommon.CardType_bomb or  targetType == DDZGameCommon.CardType_ruanbomb or  targetType == DDZGameCommon.CardType_laizibomb or  targetType == DDZGameCommon.CardType_missilebomb then
            DDZGameCommon:playAnimation(self.root, "炸弹",pBuffer.wOutCardUser)
        else
            
            -- assert(false,"错误",targetType)
            -- return
        end    
        local wChairID = pBuffer.wOutCardUser
        local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",viewID))
        uiPanel_weaveItemArray:removeAllChildren()
        local size = uiPanel_weaveItemArray:getContentSize()
        local anchorPoint = uiPanel_weaveItemArray:getAnchorPoint()
        local index = 0
        local time = 0.1
        local cardScale = 0.7
        local cardWidth = 161 * cardScale
        local cardHeight = 231 * cardScale
        local stepX = cardWidth * 0.3
        local stepY = cardHeight
        local beganX = (size.width - ((DDZGameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)) / 2
        if anchorPoint.x == 0 then
            beganX = cardWidth/2
        elseif anchorPoint.x == 1 then
            beganX = size.width + cardWidth/2 - ((pBuffer.bUserCardCount-1) * stepX + cardWidth)
        else
            beganX = (size.width - ((pBuffer.bUserCardCount-1) * stepX + cardWidth)) / 2 + cardWidth/2
        end
        local index = 1
        for key, var in pairs(targetCardData) do
    --    for i = 1, pBuffer.bUserCardCount do
    --        local var = pBuffer.bCardData[i]
            print("牌战绩+++++++++",var)
            local pos = nil
            if var ~= 0 then 
                if pBuffer.notDeleteCard ~= true then
                    pos = self:removeHandCard(wChairID,var)
                end
                local card = DDZGameCommon:getCardNode(var)
                uiPanel_weaveItemArray:addChild(card)
                if wChairID == DDZGameCommon.wDizhuUser then
                    local image = ccui.ImageView:create("puke/table/ok_dizhu.png")
                    card:addChild(image)
                    image:setPosition(120,172)
                end 
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
        end
        self:showHandCard(wChairID,2) 
        self.lastOutCardInfo = pBuffer
        self.lastOutCardInfo.time = os.time()
        self.lastOutCardInfo.tipsIndex = 0
        self.lastOutCardInfo.tableCard = {}
        local wChairID = DDZGameCommon:getRoleChairID()
        if self.lastOutCardInfo ~= nil and pBuffer.wCurrentUser == wChairID and self.lastOutCardInfo.wOutCardUser ~= wChairID and DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
            self.lastOutCardInfo.tableCard = self:getExtractCardType(DDZGameCommon.player[wChairID].cbCardData,DDZGameCommon.player[wChairID].bUserCardCount,self.lastOutCardInfo.bCardData,self.lastOutCardInfo.bUserCardCount)
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
        if wChairID == DDZGameCommon:getRoleChairID() then
            DDZGameCommon:playAnimation(self.root, "我赢啦",DDZGameCommon:getRoleChairID())
        else
            DDZGameCommon:playAnimation(self.root, "我输啦",DDZGameCommon:getRoleChairID())
        end
        -- for i = 0, DDZGameCommon.gameConfig.bPlayerCount-1 do
        -- 	if pBuffer.bUserCardCount[i+1] >=  17  then --DDZGameCommon.gameConfig.bSpringMinCount
        --         DDZGameCommon:playAnimation(self.root, "全关",i)
        -- 	end
        -- end        
    end
	
end

function DDZTableLayer:showCountDown(wChairID,isHide)     
    self:resetUserCountTimeAni()
    local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
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

    local uiPanel_notout = ccui.Helper:seekWidgetByName(self.root,"Panel_notout")
    uiPanel_notout:setVisible(false)

    local uiImage_outTips = ccui.Helper:seekWidgetByName(self.root,"Image_outTips")
    uiImage_outTips:setVisible(false)
    if wChairID == DDZGameCommon:getRoleChairID() then
        uiPanel_notout:setVisible(true)
        local Button_notoutCard = ccui.Helper:seekWidgetByName(self.root,"Button_notoutCard")
        local Button_yaobuqi = ccui.Helper:seekWidgetByName(self.root,"Button_yaobuqi")
        Button_yaobuqi:setVisible(false)

        local Button_tips = ccui.Helper:seekWidgetByName(self.root,"Button_tips")
        local Button_outCard = ccui.Helper:seekWidgetByName(self.root,"Button_outCard")
        
        if isHide ~= true and DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
            uiPanel_out:setVisible(true)            
            if self.lastOutCardInfo.wOutCardUser == nil or self.lastOutCardInfo.wOutCardUser == wChairID  then           
                Button_notoutCard:setVisible(false)
                Button_tips:setPositionX(426.81)
                Button_outCard:setPositionX(755.58)
            else               
                Button_notoutCard:setVisible(true)
                Button_tips:setPositionX(755.58)
                Button_outCard:setPositionX(996.10)
            end 
            if DDZGameCommon.gameConfig.bAbandon == 0 then
                local wPlayerCount = DDZGameCommon.gameConfig.bPlayerCount
                local meChairID = DDZGameCommon:getRoleChairID()
                local xiajia = (meChairID+1)%wPlayerCount
                local uiImage_outTips = ccui.Helper:seekWidgetByName(self.root,"Image_outTips")
                uiImage_outTips:setVisible(DDZGameCommon.player[xiajia].bUserWarn)
            end
        else
            Button_notoutCard:setVisible(false)
            Button_yaobuqi:setVisible(true)           
        end
        local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",viewID))
        uiPanel_weaveItemArray:removeAllChildren()
    end
    local uiPanel_Returntoposition = ccui.Helper:seekWidgetByName(self.root,"Panel_Returntoposition")
    uiPanel_Returntoposition:setEnabled(true)
end

-------------------------------------------------------手牌-----------------------------------------------------
--设置手牌
function DDZTableLayer:setHandCard(wChairID,bUserCardCount,cbCardData)
    DDZGameCommon.player[wChairID].bUserCardCount = bUserCardCount
    DDZGameCommon.player[wChairID].cbCardData = {}
    local k = 0
    for i = 1,21 do 
        if cbCardData[i] ~= 0 then
            k = k + 1
            DDZGameCommon.player[wChairID].cbCardData[k] = cbCardData[i]
        end 
    end 
end

--@ fux
function DDZTableLayer:changeBgLayer()
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
    if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 4 then
        UserDefault_Pukepaizhuo = 1
        cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
    end
    uiPanel_bg:removeAllChildren()
    uiPanel_bg:addChild(ccui.ImageView:create(string.format("puke/ui/beijing_%d.jpg",UserDefault_Pukepaizhuo)))
end

--删除手牌
function DDZTableLayer:removeHandCard(wChairID, cbCardData)
    DDZGameCommon.player[wChairID].bUserCardCount = DDZGameCommon.player[wChairID].bUserCardCount - 1
    if DDZGameCommon.player[wChairID].cbCardData == nil then
        return
    end
    for key, var in pairs(DDZGameCommon.player[wChairID].cbCardData) do
    	if var == cbCardData then
    	   table.remove(DDZGameCommon.player[wChairID].cbCardData,key)
    	   break
    	end
    end
    local deleteNode = nil
    local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
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
function DDZTableLayer:showHandCard(wChairID,effectsType,isShowEndCard)
    if DDZGameCommon.player[wChairID].cbCardData == nil then
        return
    end
    local isCanMove = false
    local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
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
    local stepX = cardWidth * 0.3
    local stepY = cardHeight
    local beganX = 0
    if anchorPoint.x == 0 then
        beganX = 0
    elseif anchorPoint.x == 1 then
        beganX = size.width - ((DDZGameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)
    else
        beganX = (size.width - ((DDZGameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)) / 2
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
    for i = 1, DDZGameCommon.player[wChairID].bUserCardCount do
        if DDZGameCommon.tableConfig.tableParameter~= nil and DDZGameCommon.tableConfig.tableParameter.b15Or16 == 0 and i == 21 then 
        else
            local data = DDZGameCommon.player[wChairID].cbCardData[i]
            if data ~= 0 and data ~= nil then
                local card = DDZGameCommon:getCardNode(data)
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

                local value = Bit:_and(data,0x0F)
                if data == 78 then
                    value = 16
                elseif data == 79 then 
                    value = 17
                end 
                if DDZGameCommon.bLaiZiCard ~= 0 and value == DDZGameCommon.bLaiZiCard then 
                    local laizi = ccui.ImageView:create("puke/table/ok_ui_ddz_card_5.png") 
                    card:addChild(laizi)
                    laizi:setScale(3)  
                    laizi:setPosition(30,100)   
                end 
                if wChairID == DDZGameCommon.wDizhuUser then
                    local image = ccui.ImageView:create("puke/table/ok_dizhu.png")
                    card:addChild(image)
                    image:setPosition(120,172)
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
    
end

function DDZTableLayer:initUI()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    require("common.Common"):playEffect("game/pipeidonghua.mp3")
    local wKindID = DDZGameCommon.tableConfig.wKindID
    --背景层
    local uiImage_watermark = ccui.Helper:seekWidgetByName(self.root,"Image_watermark")
    if DDZGameCommon.tableConfig.tableParameter~= nil then 
        if DDZGameCommon.tableConfig.tableParameter.bPlayWayType == 0 then 
            uiImage_watermark:loadTexture("puke/table/ok_ui_ddz_jd.png")
        elseif DDZGameCommon.tableConfig.tableParameter.bPlayWayType == 1 then 
            uiImage_watermark:loadTexture("puke/table/ok_ui_ddz_hl.png")
        elseif DDZGameCommon.tableConfig.tableParameter.bPlayWayType == 2 then 
            uiImage_watermark:loadTexture("puke/table/ok_ui_ddz_lz.png")
        elseif DDZGameCommon.tableConfig.tableParameter.bPlayWayType == 3 then 
            uiImage_watermark:loadTexture("puke/table/ok_ui_ddz_xx.png")
        end 
    end 
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
    local uiPanel_notout = ccui.Helper:seekWidgetByName(self.root,"Panel_notout")
    uiPanel_notout:setVisible(false)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
   -- ccui.Helper:seekWidgetByName(self.root,"Button_tips"):setVisible(false)
   local Button_tips = ccui.Helper:seekWidgetByName(self.root,"Button_tips")
    Common:addTouchEventListener(Button_tips,function() 
        DDZGameCommon.hostedTime = os.time()
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
    local Button_outCard = ccui.Helper:seekWidgetByName(self.root,"Button_outCard")
    Common:addTouchEventListener(Button_outCard,function() 
        DDZGameCommon.hostedTime = os.time()
        local wChairID = DDZGameCommon:getRoleChairID()
        local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
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


    --   手牌归为
    local uiPanel_Returntoposition = ccui.Helper:seekWidgetByName(self.root,"Panel_Returntoposition")

    Common:addTouchEventListener(uiPanel_Returntoposition,function() 
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",1))
        local tableCardNode = uiPanel_handCard:getChildren()
        for key, var in pairs(tableCardNode) do
            var:stopAllActions()
            var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),0)))
            --            var:setPositionY(0)
            var:setColor(cc.c3b(255,255,255))
        end
    end,true)

    local Button_notoutCard = ccui.Helper:seekWidgetByName(self.root,"Button_notoutCard")
    Button_notoutCard:setVisible(false)
    -- if DDZGameCommon.tableConfig.tableParameter.bMustOutCard ~= nil and DDZGameCommon.tableConfig.tableParameter.bMustOutCard == 1 then 
    -- end
    Common:addTouchEventListener(Button_notoutCard,function()
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_PASS_CARD,"")
    end)

    local Button_yaobuqi = ccui.Helper:seekWidgetByName(self.root,"Button_yaobuqi")
    Button_yaobuqi:setVisible(false)
    -- if DDZGameCommon.tableConfig.tableParameter.bMustOutCard ~= nil and DDZGameCommon.tableConfig.tableParameter.bMustOutCard == 1 then 
    -- end
    Common:addTouchEventListener(Button_yaobuqi,function()
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
                for key, var in pairs(DDZGameCommon.player) do
                    if DDZGameCommon:getViewIDByChairID(var.wChairID) == i then
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
    DDZGameCommon.wPiaoCount = {}
    if DDZGameCommon.tableConfig.tableParameter~=nil and DDZGameCommon.tableConfig.tableParameter.bJiaPiao ~= nil and DDZGameCommon.tableConfig.tableParameter.bJiaPiao ~= 0 then 
        local child = {}
        for i=1,4 do
            local child = ccui.Helper:seekWidgetByName(Panel_piaoFen,(i-1))
            print("++++++++++++++++",child,i,Score_piaofen[DDZGameCommon.tableConfig.tableParameter.bJiaPiao][i])
            DDZGameCommon.wPiaoCount[i] = Score_piaofen[DDZGameCommon.tableConfig.tableParameter.bJiaPiao][i]
        end    
    end 

    --叫地主
    local uiPanel_jiaodizhu = ccui.Helper:seekWidgetByName(self.root,"Panel_jiaodizhu")
    uiPanel_jiaodizhu:setVisible(false)

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"bujiao"),function() --255 不叫
        print("不叫++++++++++++++++++++++++++")
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOUT_BANKER,"b",255)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"jiao"),function() 
        if DDZGameCommon.jiaoOrqiang == 0  then 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOUT_BANKER,"b",1)
        else
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOUT_BANKER,"b",2) 
        end 
    end)

    --抢地主
    local uiPanel_qiangdizhu = ccui.Helper:seekWidgetByName(self.root,"Panel_qiangdizhu")   --255 不抢
    uiPanel_qiangdizhu:setVisible(false)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_buqiang"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOUT_BANKER,"b",255)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_onepoints"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOUT_BANKER,"b",1)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_twopoints"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOUT_BANKER,"b",2)
    end)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_threepoints"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_SHOUT_BANKER,"b",3)
    end)

    -- 底牌
    local uiPanel_dipai = ccui.Helper:seekWidgetByName(self.root,"Panel_dipai")
    uiPanel_dipai:setVisible(false)
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
        if DDZGameCommon.gameConfig.bPlayerCount ~= nil then 
            for i = 0 , DDZGameCommon.gameConfig.bPlayerCount-1 do
                local wChairID = i
                if DDZGameCommon.player ~= nil and DDZGameCommon.player[wChairID] ~= nil then
                    self:showHandCard(wChairID,3)
                end
            end
        end
    end)

    --斗地主抢庄倍数
    local uiText_beishu = ccui.Helper:seekWidgetByName(self.root,"Text_beishu")
    uiText_beishu:setString("1")
    
    local uiPanel_night = ccui.Helper:seekWidgetByName(self.root,"Panel_night")
    local UserDefault_Pukeliangdu = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_Pukeliangdu,0)
    if UserDefault_Pukeliangdu == 0 then
        uiPanel_night:setVisible(false)
    else
        uiPanel_night:setVisible(true)
    end
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_settings"),function() 
        -- local path = self:requireClass('DDZSetting')
		-- local box = require("app.MyApp"):create():createGame(path)
        -- self:addChild(box)
        if DDZGameCommon.tableConfig.nTableType == TableType_GoldRoom or DDZGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then  
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("SettingsLayer"))
        else  
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("SettingsLayer"))
        end
    end)
    local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    uiButton_expression:setPressedActionEnabled(true)
    local function onEventExpression(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local child = self:getChildByName('DDZChat')
			if child and child:getName() == 'DDZChat' then
				child:setVisible(true)
				return true
			end
			local path = self:requireClass('DDZChat')
			local box = require("app.MyApp"):create():createGame(path)
			box:setName('DDZChat')
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
        for key, var in pairs(DDZGameCommon.player) do
            currentPlayerCount = currentPlayerCount + 1
        end
        local player = "("
        for key, var in pairs(DDZGameCommon.player) do
            if key == 0 then
                player = player..var.szNickName
            else
                player = player.."、"..var.szNickName
            end
        end
        player = player..")"
        local data = clone(UserData.Share.tableShareParameter[3])
        if data then
            data.dwClubID = DDZGameCommon.tableConfig.dwClubID
            data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[DDZGameCommon.tableConfig.wKindID].name,
                DDZGameCommon.tableConfig.wTbaleID,DDZGameCommon.tableConfig.wTableNumber,
                DDZGameCommon.gameConfig.bPlayerCount,DDZGameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
            data.szShareContent = GameDesc:getGameDesc(DDZGameCommon.tableConfig.wKindID,DDZGameCommon.gameConfig,DDZGameCommon.tableConfig).." (点击加入游戏)"
            data.szShareUrl = string.format(data.szShareUrl, DDZGameCommon.tableConfig.szGameID)
            if DDZGameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
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
    uiButton_out:setVisible(false)
    Common:addTouchEventListener(uiButton_out,function() 
        require("common.MsgBoxLayer"):create(1,nil,"您确定离开房间?\n房主离开意味着房间被解散",function()
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_LEAVE_TABLE_USER,"")
        end)
    end) 
    
    -- local uiButton_SignOut = ccui.Helper:seekWidgetByName(self.root,"Button_SignOut")
    -- Common:addTouchEventListener(uiButton_SignOut,function() 
    --     require("common.MsgBoxLayer"):create(1,nil,"您确定返回大厅?",function()
    --         require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    --     end)
    -- end) 
    if CHANNEL_ID == 6 or  CHANNEL_ID  == 7  or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
    else
        --uiButton_SignOut:setVisible(false)
        -- uiButton_out:setPositionX(visibleSize.width*0.36)       
        -- uiButton_Invitation:setPositionX(visibleSize.width*0.64)  
    end 
    
    local uiButton_position = ccui.Helper:seekWidgetByName(self.root,"Button_position")   -- 定位
    Common:addTouchEventListener(uiButton_position,function() 
        require("common.PositionLayer"):create(DDZGameCommon.tableConfig.wKindID)
       -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createGame("game.puke.KwxLocationLayer"))
       -- require("game.yongzhou.PositionLayer"):create(DDZGameCommon.tableConfig.wKindID)
    end)

    local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
    if DDZGameCommon.tableConfig.wCurrentNumber == 0 and  DDZGameCommon.tableConfig.nTableType == TableType_FriendRoom or DDZGameCommon.tableConfig.nTableType == TableType_ClubRoom then
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
    uiText_title:setString(StaticData.Games[DDZGameCommon.tableConfig.wKindID].name)    
    if DDZGameCommon.tableConfig.nTableType == TableType_FriendRoom or DDZGameCommon.tableConfig.nTableType == TableType_ClubRoom then
        self:addVoice()
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_top")
        if  StaticData.Hide[CHANNEL_ID].btn10 == 0 then 
            uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position)) 
            uiPanel_playerInfoBg:setVisible(false) 
        end
        uiButton_cancel:setVisible(false)
        if DDZGameCommon.gameState == DDZGameCommon.GameState_Start  then
            local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            uiPanel_ready:setVisible(false)
            if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
                uiButton_Invitation:setVisible(false)
                --uiButton_out:setVisible(false)
            else
                uiButton_Invitation:setVisible(true)
                --uiButton_out:setVisible(true)
            end
        elseif DDZGameCommon.tableConfig.wCurrentNumber > 0 then
            uiButton_Invitation:setVisible(false)
            --:setVisible(false)
            --uiButton_SignOut:setVisible(false)
        elseif DDZGameCommon.tableConfig.wCurrentNumber == 0 then
            --uiButton_out:setVisible(true)
        end
        if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
            uiButton_Invitation:setVisible(false)
            -- uiButton_out:setPositionX(visibleSize.width*0.5)   
        end
        uiText_des:setString(string.format("房间号:%d 局数:%d/%d",DDZGameCommon.tableConfig.wTbaleID, DDZGameCommon.tableConfig.wCurrentNumber, DDZGameCommon.tableConfig.wTableNumber))

        -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/dengdaihaoyou/dengdaihaoyou.ExportJson")
        -- local waitArmature=ccs.Armature:create("dengdaihaoyou")
        -- waitArmature:setPosition(-179.2,150)
        -- if CHANNEL_ID == 6 or  CHANNEL_ID  == 7 or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
        --     waitArmature:setPosition(0,150)
        -- end 
        -- waitArmature:getAnimation():playWithIndex(0)
        -- uiButton_Invitation:addChild(waitArmature)   

    elseif DDZGameCommon.tableConfig.nTableType == TableType_GoldRoom or DDZGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then            
        self:addVoice()
        uiPanel_playerInfoBg:setVisible(false)
        uiButton_ready:setVisible(false)
        uiButton_Invitation:setVisible(false)
        --uiButton_out:setVisible(false)
        --uiButton_SignOut:setVisible(false)
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_top")
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_disbanded)) 
        uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position)) 
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
--        uiPanel_ready:setVisible(false)
        uiButton_voice:setVisible(false)
        uiButton_expression:setVisible(false)
        if DDZGameCommon.tableConfig.cbLevel == 2 then
            uiText_des:setString(string.format("中级场 倍率 %d",DDZGameCommon.tableConfig.wCellScore))
        elseif DDZGameCommon.tableConfig.cbLevel == 3 then
            uiText_des:setString(string.format("高级场 倍率 %d",DDZGameCommon.tableConfig.wCellScore))
        else
            uiText_des:setString(string.format("初级场 倍率 %d",DDZGameCommon.tableConfig.wCellScore))
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

    self:changeBgLayer()

    -- @cxx 牌桌查看俱乐部
    local Button_clubTable = ccui.Helper:seekWidgetByName(self.root,"Button_clubTable")
    local Button_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local Button_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    if DDZGameCommon.tableConfig.nTableType == TableType_ClubRoom and DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
        if DDZGameCommon.gameState == DDZGameCommon.GameState_Start or DDZGameCommon.tableConfig.wCurrentNumber > 0 then
            Button_clubTable:setVisible(false)
            Button_expression:setVisible(true)
            Button_voice:setVisible(true)
        else
            Button_clubTable:setVisible(true)
            Button_expression:setVisible(false)
            Button_voice:setVisible(false)
        end

        Common:addTouchEventListener(Button_clubTable,function()
            local dwClubID = DDZGameCommon.tableConfig.dwClubID
            self:addChild(require("app.MyApp"):create(dwClubID):createView("NewClubFreeTableLayer"))
        end)
    else
        Button_clubTable:setVisible(false)
    end
end


function DDZTableLayer:setTimeCount(data)
    local uiText_beishu = ccui.Helper:seekWidgetByName(self.root,"Text_beishu")
    uiText_beishu:setString(string.format("%d",data))
end 

function DDZTableLayer:addClickItem()
    local Panel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
    local child = {}
    for i=1,4 do
        local child = ccui.Helper:seekWidgetByName(Panel_piaoFen,(i-1))
        Common:addTouchEventListener(child,function() 
            local index= child:getName()
            print('--xx',DDZGameCommon.wPiaoCount[i])
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_JIAPIAO,"b",DDZGameCommon.wPiaoCount[i])
        end)
        --table.insert(childs,child)
    end
end


function DDZTableLayer:drawnout()
    local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root,"Image_timedown")
    uiImage_timedown:setVisible(true)
    
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

function DDZTableLayer:updateGameState(state)
    DDZGameCommon.gameState = state 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    if state == DDZGameCommon.GameState_Init then
    elseif state == DDZGameCommon.GameState_Start then
		require("common.SceneMgr"):switchOperation()
        local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
        uiPanel_playerInfoBg:setVisible(false)
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
        uiPanel_ready:setVisible(false)
        if DDZGameCommon.tableConfig.nTableType == TableType_FriendRoom or DDZGameCommon.tableConfig.nTableType == TableType_ClubRoom then
            -- --距离报警  
            -- if DDZGameCommon.tableConfig.wCurrentNumber ~= nil and DDZGameCommon.tableConfig.wCurrentNumber == 1 and DDZGameCommon.DistanceAlarm ~= 1  then
            --     if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
            --         DDZGameCommon.DistanceAlarm = 1 
            --         if DDZGameCommon.gameConfig.bPlayerCount ~= 2 then 
            --            require("common.DistanceAlarm"):create(DDZGameCommon)
            --         end                    
            --     end 
            -- end
            for i = 1, 3 do
                local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
                local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
                uiImage_ready:setVisible(false)
            end
        elseif DDZGameCommon.tableConfig.nTableType == TableType_GoldRoom or DDZGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
            local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
            uiButton_expression:setVisible(true)
            local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
            uiButton_voice:setVisible(true)
        end         
        local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")  --取消按钮
        uiButton_cancel:setVisible(false)
        local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root,"Image_timedown")
        uiImage_timedown:setVisible(false)
    elseif state == DDZGameCommon.GameState_Over then
        UserData.Game:addGameStatistics(DDZGameCommon.tableConfig.wKindID)
    else
    
    end

    -- @cxx 牌桌查看俱乐部
    local Button_clubTable = ccui.Helper:seekWidgetByName(self.root,"Button_clubTable")
    local Button_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local Button_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    if DDZGameCommon.tableConfig.nTableType == TableType_ClubRoom and DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
        if DDZGameCommon.gameState == DDZGameCommon.GameState_Start or DDZGameCommon.tableConfig.wCurrentNumber > 0 then
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
function DDZTableLayer:addVoice()
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
        data.chirID = DDZGameCommon:getRoleChairID()
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
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE,"wwwdddnsnf",DDZGameCommon:getRoleChairID(),packCount,i,data.time,fileSize,periodSize,32,data.file,periodSize,periodData)
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
            local viewID = DDZGameCommon:getViewIDByChairID(data.chirID)
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

function DDZTableLayer:OnUserChatVoice(event)
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

function DDZTableLayer:showPlayerPosition()   -- 显示玩家距离    
    local wChairID = 0
    for key, var in pairs(DDZGameCommon.player) do
        if var.dwUserID == DDZGameCommon.dwUserID then
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
    local viewID = DDZGameCommon:getViewIDByChairID(wChairID) 
    for wChairID = 0, 3 do
        if DDZGameCommon.player[wChairID] ~= nil then
            local viewID = DDZGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_players = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_players%d",viewID))
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_players,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
            if DDZGameCommon.player[wChairID] ~= nil then 
                uiImage_avatar:loadTexture("common/common_dian2.png")
            end 
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            uiText_name:setString(DDZGameCommon.player[wChairID].szNickName)
            for wTargetChairID = 0, DDZGameCommon.gameConfig.bPlayerCount-1 do
                local targetViewID = DDZGameCommon:getViewIDByChairID(wTargetChairID)
                if DDZGameCommon.gameConfig.bPlayerCount == 3 and wTargetChairID == 3 then
                    viewID = 4
                end
                if wTargetChairID ~= wChairID then
                    local uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",viewID,targetViewID))
                    if viewID > targetViewID then
                        uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",targetViewID,viewID))
                    end
                    if uiText_location ~= nil then
                        local distance = uiText_location:getString()
                        if DDZGameCommon.gameConfig.bPlayerCount == 3 and (wChairID == 3 or wTargetChairID == 3) then
                            distance = ""
                        elseif DDZGameCommon.player[wChairID] == nil or DDZGameCommon.player[wTargetChairID] == nil then
                            distance = "等待加入..."
                        elseif DDZGameCommon.tableConfig.nTableType == TableType_GoldRoom or DDZGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
                            if distance == "500m" then
                                distance = math.random(1000,300000)
                            end
                        elseif DDZGameCommon.player[wChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",DDZGameCommon.player[wChairID].szNickName)
                        elseif DDZGameCommon.player[wTargetChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",DDZGameCommon.player[wTargetChairID].szNickName)
                        else
                            distance = DDZGameCommon:GetDistance(DDZGameCommon.player[wChairID].location,DDZGameCommon.player[wTargetChairID].location) 
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

function DDZTableLayer:showPlayerInfo(infoTbl)       -- 查看玩家信息
    Common:palyButton()
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(infoTbl, self):createGame("game.puke.DDZPersonInfor"))
    --require("common.PersonalLayer"):create(DDZGameCommon.tableConfig.wKindID,dwUserID,dwShamUserID)
end
function DDZTableLayer:showChat(pBuffer)
    local viewID = DDZGameCommon:getViewIDByChairID(pBuffer.dwUserID, true)
	local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
	local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_chat")
	local uiText_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Text_chat")
	uiText_chat:setString(pBuffer.szChatContent)
	uiImage_chat:setVisible(true)
	uiImage_chat:setScale(0)
	uiImage_chat:stopAllActions()
	uiImage_chat:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1), cc.DelayTime:create(5), cc.Hide:create()))
	local wKindID = DDZGameCommon.tableConfig.wKindID
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
		if DDZGameCommon.language ~= 0 then
			local wKindID = DDZGameCommon.tableConfig.wKindID
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

function DDZTableLayer:showReward(pBuffer)
    if pBuffer.lRet == 0 then 
        local rewardData = {}
        rewardData.wPropID = 0
        if pBuffer.bType == 0 then 
            rewardData = {{wPropID = 1001,dwPropCount = tonumber(pBuffer.lCount) }}
           -- rewardData.wPropID = 1001
        else
            rewardData = {{wPropID = 1008,dwPropCount = tonumber(pBuffer.lCount) }}
          --  rewardData.wPropID = 1008
        end 
        EventMgr:dispatch("RET_GET_MALL_LOG_FINISH",data)
        require("common.RewardLayer"):create("领取成功",nil,rewardData)
    elseif pBuffer.lRet == 1 then 
        local rewardData = {}
        rewardData = {{wPropID = 1001,dwPropCount = tonumber(pBuffer.lCount) }}
        --rewardData.dwPropCount = tonumber(pBuffer.lCount)
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

function DDZTableLayer:showExperssion(pBuffer)
	self:playSpine(pBuffer)
end

function DDZTableLayer:playSpine(pBuffer)
    local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

    local viewID = DDZGameCommon:getViewIDByChairID(pBuffer.wChairID, true)
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
				
				soundData = sound[DDZGameCommon.language]
				if DDZGameCommon.language ~= 0 then
					local wKindID = DDZGameCommon.tableConfig.wKindID
					if wKindID == 47 or wKindID == 48 or wKindID == 49 or wKindID == 60 then
						soundData = sound[2]
					end
				end
				
				if soundData ~= nil then
					local player = DDZGameCommon.player[pBuffer.wChairID]
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
function DDZTableLayer:getMaxCardType(bCardData,bUserCardCount)
    local tableCard = self:getExtractCardType(bCardData,bUserCardCount)
    if tableCard == nil or  #tableCard <= 0 then
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

function DDZTableLayer:tryAutoSendCard(wCurrentUser)
    local wChairID = DDZGameCommon:getRoleChairID()
    if wCurrentUser ~= wChairID then
        self:showCountDown(wCurrentUser)
        return
    end
    --如果上次出牌是其他人
    if self.lastOutCardInfo.wOutCardUser ~= wChairID then
        if #self.lastOutCardInfo.tableCard == 1 and #self.lastOutCardInfo.tableCard[1] == DDZGameCommon.player[wChairID].bUserCardCount then
            local tabelCard = {}
            for i = 1, DDZGameCommon.player[wChairID].bUserCardCount do
                table.insert(tabelCard,#tabelCard+1,DDZGameCommon.player[wChairID].cbCardData[i])
            end
            --self:sendCard(wChairID,tabelCard)
            self:showCountDown(wCurrentUser,false)
            return
        end
    else
        --如果是自己，尝试甩牌
        local targetType, targetCardData = self:getCardTypeAndCard(DDZGameCommon.player[wChairID].cbCardData,DDZGameCommon.player[wChairID].bUserCardCount)
       -- local targetCardData = DDZGameCommon.player[wChairID].bCardData
        if targetType ~= DDZGameCommon.CardType_error then 
            if targetType ~= DDZGameCommon.CardType_bomb then 
                local tableSortCard = self:getSortCard(DDZGameCommon.player[wChairID].cbCardData,DDZGameCommon.player[wChairID].bUserCardCount)
                if #tableSortCard[4] > 0 then
                    self:showCountDown(wCurrentUser)
                    return
                end
            end
            local tabelCard = {}
            for i = 1, DDZGameCommon.player[wChairID].bUserCardCount do
                table.insert(tabelCard,#tabelCard+1,DDZGameCommon.player[wChairID].cbCardData[i])
            end
            --self:sendCard(wChairID,tabelCard)     --最后一手甩牌
            self:showCountDown(wCurrentUser,false)
            return
        end
    end
    self:showCountDown(wCurrentUser)
end

function DDZTableLayer:sendCard(wChairID,tableCardData)
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
    for i = #tableCardData+1, DDZGameCommon.MAX_COUNT do
        net.cppFunc:writeSendByte(0,0)
    end
    net.cppFunc:writeSendWORD(wChairID,0)
    net.cppFunc:endSendBuf()
    net.cppFunc:sendSvrBuf()
end

--连续排序
function DDZTableLayer:getSortCard(bCardData,bUserCardCount)
    local tableSortCard = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
        [20] = {},
    }
    local preValue = nil
    local tableCard = {}
    local bLaiZiCard = {}
    local bLaiZiNum = 0
    for key = 1, bUserCardCount do
        local data = bCardData[key]
        if data ~= nil then 
            local value = Bit:_and(data,0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end

            if data == 78 then 
                value = 16
            elseif data == 79 then 
                value = 17
            end

            if DDZGameCommon.bLaiZiCard == value then 
                bLaiZiNum = bLaiZiNum +1    
                table.insert(bLaiZiCard,1,data)    
            else                   
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
        end 
    end
    if bLaiZiNum > 0  then
        table.insert(tableSortCard[20],1,clone(bLaiZiCard))
    end 
    local num = #tableCard
    if num > 0 and tableSortCard[num] then
        table.insert(tableSortCard[num],1,clone(tableCard))
    end
    return tableSortCard
end

--分析牌型
function DDZTableLayer:getCardTypeAndCard(bCardData,bUserCardCount)
    if bUserCardCount <= 0 then
        return DDZGameCommon.CardType_error
    end
    local tableSortCard = self:getSortCard(bCardData,bUserCardCount)
    print("长度+++++++++",#tableSortCard[20])
    local laizinum = 0
    if #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
    if bUserCardCount == 4 and #tableSortCard[4] == 1 then
        --是否为炸弹
        return DDZGameCommon.CardType_bomb, tableSortCard[4][1]
    elseif  bUserCardCount == 4 and  #tableSortCard[3] == 1 and  laizinum == 1 then
        table.insert(tableSortCard[3][1],#tableSortCard[3][1]+1,tableSortCard[20][1][1])
        --是否为炸弹
        return DDZGameCommon.CardType_laizibomb, tableSortCard[3][1]     --, tableSortCard[20][1] 

    elseif  bUserCardCount == 4 and  #tableSortCard[2] == 1 and  laizinum == 2 then
        table.insert(tableSortCard[2][1],#tableSortCard[2][1]+1,tableSortCard[20][1][1])
        table.insert(tableSortCard[2][1],#tableSortCard[2][1]+1,tableSortCard[20][1][2])
        --是否为炸弹
        return DDZGameCommon.CardType_laizibomb, tableSortCard[2][1]     --, tableSortCard[20][1] 

    elseif  bUserCardCount == 4 and  #tableSortCard[1] == 1 and  laizinum == 3 then
        table.insert(tableSortCard[1][1],#tableSortCard[1][1]+1,tableSortCard[20][1][1])
        table.insert(tableSortCard[1][1],#tableSortCard[1][1]+1,tableSortCard[20][1][2])
        table.insert(tableSortCard[1][1],#tableSortCard[1][1]+1,tableSortCard[20][1][3])
        --是否为炸弹
        return DDZGameCommon.CardType_laizibomb, tableSortCard[1][1]     --, tableSortCard[20][1] 
    elseif  bUserCardCount == 2 and  #tableSortCard[1] == 2 and  tableSortCard[1][1][1] == 78  and  tableSortCard[1][2][1] == 79   then
        table.insert(tableSortCard[1][1],#tableSortCard[1][1]+1,tableSortCard[1][2][1])
        return DDZGameCommon.CardType_bomb, tableSortCard[1][1] 
    end
    
    if bUserCardCount == 1 and #tableSortCard[1] == 1 then
        --是否为单牌
        return DDZGameCommon.CardType_single, tableSortCard[1][1]
    end
    
    if bUserCardCount == 2 and #tableSortCard[2] == 1 then
        --是否为对子
        return DDZGameCommon.CardType_pair, tableSortCard[2][1]
    elseif  bUserCardCount == 2 and  #tableSortCard[1] == 1 and  laizinum == 1 then
        table.insert(tableSortCard[1][1],#tableSortCard[1][1]+1,tableSortCard[20][1][1])
        --是否为对子
        return DDZGameCommon.CardType_pair, tableSortCard[1][1] --, tableSortCard[20][1]     
    end


    if #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
    print("扑克+++++++++++++",#tableSortCard[1])
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
            return DDZGameCommon.CardType_straight, tableReturnCard
        end
    elseif bUserCardCount >= 5 and bUserCardCount >= #tableSortCard[1] and (bUserCardCount - #tableSortCard[1]) == laizinum then
        --是否为顺子 
        local preValue = nil
        local a_sub = 1 
        local tableReturnCard = {}
        for key, var in pairs(tableSortCard[1]) do
            local data = var[1]
	        local value = Bit:_and(data,0x0F)
            if value == 1 then
                value = 14
            else
            end
            if preValue == nil or preValue+1 == value then
            else
                local num = value - (preValue+1)                     
                for i = 1, num do
                    if #tableSortCard[20] ~= 0 and tableSortCard[20][1][a_sub] ~= nil then 
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                    a_sub = a_sub + 1
                    else
                        break
                    end 
                end 
                laizinum = laizinum - num
            end
            table.insert(tableReturnCard,#tableReturnCard+1,data)
            preValue = value
            if laizinum < 0 then 
                break
            end 
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_straight, tableReturnCard
        end
    end
    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
    if bUserCardCount == #tableSortCard[2]*2 and bUserCardCount >6 then
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
            return DDZGameCommon.CardType_straightPair, tableReturnCard
        end
    elseif bUserCardCount ==( #tableSortCard[2]*2 + #tableSortCard[1] + laizinum) and laizinum ~= nil  and bUserCardCount >= 6  then       
        --是否为连对 
        local preValue = nil
        local tableReturnCard = {}
        local array_sub = 1
        local singlenum = #tableSortCard[1]      --单牌数

        local numberlies = {}

        for key, var in pairs(tableSortCard[1]) do
            local data= {}
            data.oneprice = var[1]
            data.tweprice = nil
            --data.tweprice = tableSortCard[20][array_sub]
            data.value = Bit:_and(var[1],0x0F)
            if data.value == 1 then
                data.value = 14
            else
            end
            data.type  = 1
            table.insert(numberlies,#numberlies+1,data)
            preValue = value
        end

        for key, var in pairs(tableSortCard[2]) do
            local data= {}
            data.oneprice = var[1]
            data.tweprice = var[2]
            data.value = Bit:_and(var[1],0x0F)
            if data.value == 1 then
                data.value = 14
            else
            end
            -- for k, v in pairs(var) do
            --     table.insert(tableReturnCard,#tableReturnCard+1,v)
            -- end
            data.type  = 2
            table.insert(numberlies,#numberlies+1,data)
            preValue = value
        end

        local bSorted = false
        local cbThreedata = {}
        local cbLast = #numberlies - 1


        for i=1,cbLast do
            for j=i,cbLast do
                print("数值大小",numberlies[j].value ,numberlies[j+1].value)
                if numberlies[j].value > numberlies[j+1].value  then
                    cbThreedata = numberlies[j]
                    numberlies[j] = numberlies[j+1]
                    numberlies[j+1] = cbThreedata  --自己的牌组换位置
                    -- cbThreedata = numberlies[j]
                    -- numberlies[j] = numberlies[j+1]
                    -- numberlies[j+1] = cbThreedata  --复制的牌组换位置
                end
            end
        end

        -- repeat
        --     bSorted = true
        --     for i=1,cbLast do
        --       --如果第一张牌大于第二张牌
        --         if numberlies[i].value > numberlies[i+1].value  then
        --             cbThreedata = numberlies[i]
        --             numberlies[i] = numberlies[i+1]
        --             numberlies[i+1] = cbThreedata  --自己的牌组换位置
        --             cbThreedata = numberlies[i]
        --             numberlies[i] = numberlies[i+1]
        --             numberlies[i+1] = cbThreedata  --复制的牌组换位置
        --             bSorted = false
        --         end
        --     end
        --     cbLast = cbLast - 1
        -- until (bSorted==true)

        --是否为顺子 
        local preValue = nil
        local a_sub = 1 
        for key, var in pairs(numberlies) do
            local value = var.value 
            if preValue == nil or preValue+1 == value then
            else
                local num = value - (preValue+1)                     
                for i = 1, num do
                    if #tableSortCard[20] ~= 0 and # tableSortCard[20][1][a_sub] ~= nil and  tableSortCard[20][1][a_sub+1] ~= nil  then 
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub+1])
                        a_sub = a_sub + 2
                    else
                        break
                    end 
                end 
                laizinum = laizinum - (2*num)
            end
            if var.type == 1 then
                table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                if #tableSortCard[20] ~= 0 and tableSortCard[20][1][a_sub] ~= nil  then 
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                    a_sub = a_sub + 1
                else
                    break
                end 
                laizinum = laizinum - 1
                preValue = value
            elseif var.type == 2 then
                table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                preValue = value
            end 
            if laizinum < 0 then 
                break
            end 
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_straightPair, tableReturnCard
        end

    end
    

    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
    if bUserCardCount >= 5 and bUserCardCount <= 6 and #tableSortCard[4] == 1 then
        --是否为四带二
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
            return DDZGameCommon.CardType_4Add2, tableReturnCard
        end
    elseif bUserCardCount >= 5 and bUserCardCount <= 6 and #tableSortCard[3] >= 1 and  laizinum >= 1 then
        --是否为四带二
        local tableReturnCard = clone(tableSortCard[3][1])
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        tableSortCard[3] = {}
        table.remove(tableSortCard[20][1],1)
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_4Add2, tableReturnCard
        end
    elseif   bUserCardCount >= 5 and bUserCardCount <= 6  and #tableSortCard[2] >= 1 and  laizinum >= 2 then
        --是否为四带二
        local tableReturnCard = {}
        if tableSortCard[2][2] ~= nil then 
            tableReturnCard = clone(tableSortCard[2][2])
            table.remove(tableSortCard[2],2)
        else
            tableReturnCard = clone(tableSortCard[2][1])
            tableSortCard[2] = {}
        end 
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][2])
        table.remove(tableSortCard[20][1],1)
        table.remove(tableSortCard[20][1],1)
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_4Add2, tableReturnCard
        end
    elseif   bUserCardCount >= 5 and bUserCardCount <= 6  and #tableSortCard[1] >= 1 and  laizinum >= 3 then
        --是否为四带二
        local tableReturnCard = {}
        if tableSortCard[1][4] ~= nil then 
            local tableReturnCard = clone(tableSortCard[1][4])
            table.remove(tableSortCard[1],4)
        else
            local tableReturnCard = clone(tableSortCard[1][3])
            table.remove(tableSortCard[1],3)
        end

        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][2])
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][3])
        table.remove(tableSortCard[20][1],1)
        table.remove(tableSortCard[20][1],1)
        table.remove(tableSortCard[20][1],1)
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_4Add2, tableReturnCard
        end
    end 

    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
       
    --炸弹是否可以拆
    if DDZGameCommon.gameConfig.bBombSeparation == 1 then
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
    
    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
    if  bUserCardCount == 5 and #tableSortCard[3] == 1 then
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
            return DDZGameCommon.CardType_3Add2, tableReturnCard
        end
    elseif  bUserCardCount == 5 and #tableSortCard[2] >= 1  and laizinum>= 1 then
        --是否为三带二
        local tableReturnCard = {}
        if tableSortCard[2][2] ~= nil then 
            tableReturnCard = clone(tableSortCard[2][2])
            table.remove(tableSortCard[2],2)
        else
            tableReturnCard = clone(tableSortCard[2][1])
            tableSortCard[2] = {}
        end 
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.remove(tableSortCard[20][1],1)
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_3Add2, tableReturnCard
        end
    elseif  bUserCardCount == 5 and #tableSortCard[1] >= 1 and laizinum ~= nil and laizinum >=  2 then
        --是否为三带二
        local tableReturnCard = {}
        if tableSortCard[1][3] ~= nil then 
            local tableReturnCard = clone(tableSortCard[1][3])
            table.remove(tableSortCard[1],3)
        else
            local tableReturnCard = clone(tableSortCard[1][2])
            table.remove(tableSortCard[1],2)
        end

        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][2])
        table.remove(tableSortCard[20][1],1)
        table.remove(tableSortCard[20][1],1)
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_3Add2, tableReturnCard
        end
    end

    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
    if  bUserCardCount == 4 and #tableSortCard[3] == 1 then
        --是否为三带一
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
            return DDZGameCommon.CardType_3Add1, tableReturnCard
        end
    elseif  bUserCardCount == 4 and #tableSortCard[2] >= 1 and laizinum ~= nil and laizinum >=   1 then
        --是否为三带一
        local tableReturnCard = {}
        if tableSortCard[2][2] ~= nil then 
            tableReturnCard = clone(tableSortCard[2][2])
            table.remove(tableSortCard[2],2)
        else
            tableReturnCard = clone(tableSortCard[2][1])
            tableSortCard[2] = {}
        end 
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.remove(tableSortCard[20][1],1)
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_3Add1, tableReturnCard
        end
    elseif  bUserCardCount == 4 and #tableSortCard[1] >= 1 and laizinum ~= nil and laizinum >=   2 then
        --是否为三带一
        local tableReturnCard = {}
        if tableSortCard[1][3] ~= nil then 
            local tableReturnCard = clone(tableSortCard[1][3])
            table.remove(tableSortCard[1],3)
        else
            local tableReturnCard = clone(tableSortCard[1][2])
            table.remove(tableSortCard[1],2)
        end

        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][2])
        table.remove(tableSortCard[20][1],1)
        table.remove(tableSortCard[20][1],1)
        for key, var in pairs(tableSortCard) do
            for k, v in pairs(var) do
                for ikey, ivar in pairs(v) do
                    table.insert(tableReturnCard,#tableReturnCard+1,ivar)
                end
            end
        end
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_3Add1, tableReturnCard
        end
    end

    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 
    if  bUserCardCount == 3 and #tableSortCard[3] == 1 then
        --是否为三带一
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
            return DDZGameCommon.CardType_3Add1, tableReturnCard
        end
    elseif  bUserCardCount == 3 and #tableSortCard[2] >= 1 and laizinum ~= nil and laizinum >=   1 then
        --是否为三带一
        local tableReturnCard = {}
        if tableSortCard[2][2] ~= nil then 
            tableReturnCard = clone(tableSortCard[2][2])
            table.remove(tableSortCard[2],2)
        else
            tableReturnCard = clone(tableSortCard[2][1])
            tableSortCard[2] = {}
        end 
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.remove(tableSortCard[20][1],1)
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_3Add1, tableReturnCard
        end
    elseif  bUserCardCount == 3 and #tableSortCard[1] >= 1 and laizinum ~= nil and laizinum >=   2 then
        --是否为三带一
        local tableReturnCard = {}
        if tableSortCard[1][3] ~= nil then 
            local tableReturnCard = clone(tableSortCard[1][3])
            table.remove(tableSortCard[1],3)
        else
            local tableReturnCard = clone(tableSortCard[1][2])
            table.remove(tableSortCard[1],2)
        end
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][1])
        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][2])
        table.remove(tableSortCard[20][1],1)
        table.remove(tableSortCard[20][1],1)
        if #tableReturnCard == bUserCardCount then
            return DDZGameCommon.CardType_3Add1, tableReturnCard
        end
    end

    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
        laizinum = #tableSortCard[20][1]
    end 

    local threeCardles = 0

    if bUserCardCount % 3 == 0 then 
        threeCardles = math.floor( bUserCardCount / 3 )
    elseif   bUserCardCount % 4 == 0 then 
        threeCardles = math.floor( bUserCardCount / 4 )
    elseif   bUserCardCount % 5 == 0 then 
        threeCardles = math.floor( bUserCardCount / 5 )
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
                return DDZGameCommon.CardType_airplane, tableReturnCard
            end
        end
    elseif bUserCardCount >= 6 and laizinum ~= nil then --==( #tableSortCard[3]*3 + #tableSortCard[2]*2 + #tableSortCard[1] + #tableSortCard[20][1])then       
        --是否为飞机 
        local preValue = nil
        local tableReturnCard = {}
        local array_sub = 1     
      --  local singlenum = #tableSortCard[1]      --单牌数

        local numberlies = {}

        for key, var in pairs(tableSortCard[1]) do
            local data= {}
            data.oneprice = var[1]
            data.tweprice = nil
            data.threeprice = nil
            data.fourprice = nil
            --data.tweprice = tableSortCard[20][array_sub]
            data.value = Bit:_and(var[1],0x0F)
            if data.value == 1 then
                data.value = 14
            else
            end
            data.type  = 1
            table.insert(numberlies,#numberlies+1,data)
            preValue = value
        end

        for key, var in pairs(tableSortCard[2]) do
            local data= {}
            data.oneprice = var[1]
            data.tweprice = var[2]
            data.threeprice = nil
            data.fourprice = nil
            data.value = Bit:_and(var[1],0x0F)
            if data.value == 1 then
                data.value = 14
            else
            end
            for k, v in pairs(var) do
                table.insert(tableReturnCard,#tableReturnCard+1,v)
            end
            data.type  = 2
            table.insert(numberlies,#numberlies+1,data)
            preValue = value
        end

        
        for key, var in pairs(tableSortCard[3]) do
            local data= {}
            data.oneprice = var[1]
            data.tweprice = var[2]
            data.threeprice = var[3]
            data.fourprice = nil
            data.value = Bit:_and(var[1],0x0F)
            if data.value == 1 then
                data.value = 14
            else
            end
            for k, v in pairs(var) do
                table.insert(tableReturnCard,#tableReturnCard+1,v)
            end
            data.type  = 2
            table.insert(numberlies,#numberlies+1,data)
            preValue = value
        end

        for key, var in pairs(tableSortCard[4]) do
            local data= {}
            data.oneprice = var[1]
            data.tweprice = var[2]
            data.threeprice = var[3]
            data.fourprice = var[4]
            data.value = Bit:_and(var[1],0x0F)
            if data.value == 1 then
                data.value = 14
            else
            end
            for k, v in pairs(var) do
                table.insert(tableReturnCard,#tableReturnCard+1,v)
            end
            data.type  = 2
            table.insert(numberlies,#numberlies+1,data)
            preValue = value
        end

        local bSorted = false
        local  cbThreedata = {}
        local cbLast = #numberlies - 1

        repeat
            bSorted = true
            for i=1,cbLast do
              --如果第一张牌小于第二张牌
                if numberlies[i].value < numberlies[i+1].value  then
                    cbThreedata = numberlies[i]
                    numberlies[i] = numberlies[i+1]
                    numberlies[i+1] = cbThreedata  --自己的牌组换位置
                    cbThreedata = numberlies[i]
                    numberlies[i] = numberlies[i+1]
                    numberlies[i+1] = cbThreedata  --复制的牌组换位置
                    bSorted = false
                end
            end
            cbLast = cbLast - 1
        until (bSorted==true)

        --是否为顺子 
        local preValue = nil
        local a_sub = 1 
        local feijinum = 0
        for key, var in pairs(numberlies) do
            local value = var.value 
            if preValue == nil or preValue-1 == value then
                if var.type == 1 and laizinum ~= nil and laizinum >=  2 then
                    table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                    a_sub = a_sub + 1
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                    a_sub = a_sub + 1
                    laizinum = laizinum - 2
                    preValue = value
                    feijinum = feijinum + 1
                elseif var.type == 2  and laizinum ~= nil and laizinum >=  1 then
                    table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                    table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                    a_sub = a_sub + 1
                    laizinum = laizinum - 1
                    preValue = value
                    feijinum = feijinum + 1
                elseif var.type == 3 then
                    table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                    table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                    table.insert(tableReturnCard,#tableReturnCard+1,var.threeprice)
                    preValue = value 
                    feijinum = feijinum + 1
                elseif var.type == 4 then
                    table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                    table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                    table.insert(tableReturnCard,#tableReturnCard+1,var.threeprice)
                    preValue = value   
                    feijinum = feijinum + 1
                else
                    tableReturnCard = {}
                    if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
                        laizinum = #tableSortCard[20][1]
                    end 
                    a_sub =0
                    preValue = nil
                    feijinum = 0   
                    if var.type == 1 and laizinum ~= nil and laizinum >=  2 then
                        table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                        a_sub = a_sub + 1
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                        a_sub = a_sub + 1
                        laizinum = laizinum - 2
                        preValue = value
                        feijinum = feijinum + 1
                    elseif var.type == 2  and laizinum ~= nil and laizinum >=  1 then
                        table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                        table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                        a_sub = a_sub + 1
                        laizinum = laizinum - 1
                        preValue = value
                        feijinum = feijinum + 1
                    end                 
                end 
                if feijinum == threeCardles then
                    return DDZGameCommon.CardType_straight, tableReturnCard
                end
            else
                if preValue ~= nil then 
                    local num = (preValue-1) - value                     
                    for i = 1, num do
                        if #tableSortCard[20] ~= 0 and tableSortCard[20][1][a_sub] ~= nil and tableSortCard[20][1][a_sub+1] ~= nil and tableSortCard[20][1][a_sub+2] ~= nil then 
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub+1])
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub+2])
                            a_sub = a_sub + 3
                            laizinum = laizinum - 3
                            preValue = preValue - 1
                            feijinum = feijinum + 1
                            if feijinum == threeCardles then
                                return DDZGameCommon.CardType_straight, tableReturnCard
                            end
                        else
                            tableReturnCard = {}
                            if  #tableSortCard[20] ~= 0 and #tableSortCard[20][1] ~= nil  then -- 癞子数
                                laizinum = #tableSortCard[20][1]
                            end 
                            a_sub = 1
                            preValue = nil
                            feijinum = 0  
                            if #tableSortCard[20] ~= 0 and tableSortCard[20][1][a_sub] ~= nil and tableSortCard[20][1][a_sub+1] ~= nil and tableSortCard[20][1][a_sub+2] ~= nil then 
                                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub+1])
                                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub+2])
                                a_sub = a_sub + 3
                                laizinum = laizinum - 3
                                preValue = preValue - 1
                                feijinum = feijinum + 1
                            end 
                            if var.type == 1 and laizinum ~= nil and laizinum >=  2 then
                                table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                                a_sub = a_sub + 1
                                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                                a_sub = a_sub + 1
                                laizinum = laizinum - 2
                                preValue = value
                                feijinum = feijinum + 1
                            elseif var.type == 2  and laizinum ~= nil and laizinum >=  1 then
                                table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                                table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCard[20][1][a_sub])
                                a_sub = a_sub + 1
                                laizinum = laizinum - 1
                                preValue = value
                                feijinum = feijinum + 1
                            elseif var.type == 3 then
                                table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                                table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                                table.insert(tableReturnCard,#tableReturnCard+1,var.threeprice)
                                preValue = value 
                                feijinum = feijinum + 1
                            elseif var.type == 4 then
                                table.insert(tableReturnCard,#tableReturnCard+1,var.oneprice)
                                table.insert(tableReturnCard,#tableReturnCard+1,var.tweprice)
                                table.insert(tableReturnCard,#tableReturnCard+1,var.threeprice)
                                preValue = value   
                                feijinum = feijinum + 1
                            end
                        end 
                    end 
                end 
            end
        end
        -- if #tableReturnCard == bUserCardCount then
        --     return DDZGameCommon.CardType_straight, tableReturnCard
        -- end

    end
    return DDZGameCommon.CardType_error
end

--提取牌型
function DDZTableLayer:getExtractCardType(bCardData,bUserCardCount,bTargetCardData,bTargetUserCardCount)
    local tableCard = {}
    if bUserCardCount <= 0 then
        return tableCard
    end
    local tableSortCard = self:getSortCard(bCardData,bUserCardCount)
    local targetType = nil
    local targetCardData = nil
    if bTargetUserCardCount ~= nil and bTargetUserCardCount > 0 then
        targetType, targetCardData = self:getCardTypeAndCard(bTargetCardData,bTargetUserCardCount)
       -- local targetCardData = bTargetCardData
    end
    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)
        if targetValue == 1 then
            targetValue = 14
        elseif targetValue == 2 then
            targetValue = 15
        end 
        if targetCardData[1] == 78 then
            targetValue = 16
        elseif targetCardData[1] == 79 then
            targetValue = 17
        end 
    end
	if targetType == DDZGameCommon.CardType_single then
        local wPlayerCount = DDZGameCommon.gameConfig.bPlayerCount
        local meChairID = DDZGameCommon:getRoleChairID()
        local xiajia = (meChairID+1)%wPlayerCount
        if DDZGameCommon.gameConfig.bAbandon == 0 and DDZGameCommon.player[xiajia].bUserWarn == true then
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
                        if v[1] == 78 then 
                            value = 16 
                        elseif v[1] == 79 then 
                            value = 17 
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
                if var[1] == 78 then 
                    value = 16 
                elseif var[1] == 79 then 
                    value = 17 
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
                if var[1] == 78 then 
                    value = 16 
                elseif var[1] == 79 then 
                    value = 17 
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
                if var[1] == 78 then 
                    value = 16 
                elseif var[1] == 79 then 
                    value = 17 
                end
                if value > targetValue then
                   table.insert(tableCard,#tableCard+1,{var[#var]})
                end
            end
        end
	end
	
    if targetType == DDZGameCommon.CardType_pair then
       --提取对子
       local tableSortCardTemp = clone(tableSortCard)

       for key, var in pairs(tableSortCardTemp[2]) do
           local value = Bit:_and(var[1],0x0F)
            if value == 1 then
               value = 14
            elseif value == 2 then
               value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
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
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
               table.remove(var,1)
               table.insert(tableCard,#tableCard+1,var)
            end
       end

        for key, var in pairs(tableSortCardTemp[1]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue and #tableSortCardTemp[20]~= 0 and #tableSortCardTemp[20][1] >= 1 then
                table.insert(var,#var+1,tableSortCardTemp[20][1][1])
                table.insert(tableCard,#tableCard+1,var)
            end
        end

        for key, var in pairs(tableSortCardTemp[4]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end 
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                table.remove(var,2)
                table.insert(tableCard,#tableCard+1,var)
            end
        end
    
    end
    
    if targetType == nil or targetType == DDZGameCommon.CardType_straight then
        tableCard = self:LogicShunzhi(tableSortCard,targetCardData,tableCard)
    end
    
    if targetType == nil or targetType == DDZGameCommon.CardType_straightPair then
        tableCard = self:LogicLiandui(tableSortCard,targetCardData,tableCard)      
    end
    
    --提取三带    bUserCardCount
    if targetType == nil or targetType == DDZGameCommon.CardType_three then
        tableCard = self:LogicThree(tableSortCard,targetCardData,tableCard)   
    end
    --提取三带二    bUserCardCount
    if targetType == nil or targetType == DDZGameCommon.CardType_3Add2 then
        tableCard = self:LogicThreeToTwe(tableSortCard,targetCardData,tableCard)   
    end

    --提取三带一
    if targetType == nil or targetType == DDZGameCommon.CardType_3Add1 then
        tableCard = self:LogicThreeToOne(tableSortCard,targetCardData,tableCard)   
    end
    
    -- --提取四带三
    -- if DDZGameCommon.gameConfig.b4Add3 == 1 and(targetType == DDZGameCommon.CardType_4Add3) then
    --     tableCard = self:LogicFour(tableSortCard,targetCardData,tableCard)   
    -- end
	
    if targetType == nil or targetType == DDZGameCommon.CardType_airplane then       
        tableCard = self:LogicThePlane(tableSortCard,targetCardData,tableCard) 
    end
    
	--提取炸弹
	if targetType == nil or targetType ~= DDZGameCommon.CardType_bomb and targetType ~= DDZGameCommon.CardType_laizibomb then
        tableCard = self:LogicFourDone(tableSortCard,targetCardData,tableCard)   
    end

    --癞子炸弹
    if targetType == nil or targetType == DDZGameCommon.CardType_laizibomb then
        tableCard = self:LogicFourlaizi(tableSortCard,targetCardData,tableCard)   
    end

    --提取炸弹
	if targetType == nil or targetType == DDZGameCommon.CardType_bomb then
        tableCard = self:LogicFour(tableSortCard,targetCardData,tableCard)   
    end
    
    --双王为炸弹
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[1]) do
        if var[1] == 78 and tableSortCardTemp[1][key+1] ~= nil and tableSortCardTemp[1][key+1][1] == 79 then
            local  tableReturnCard = {}
            table.insert(tableReturnCard,#tableReturnCard+1,var[1])
            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[1][key+1][1])
            table.insert(tableCard,#tableCard+1,tableReturnCard)
        end 
    end
    return tableCard    
end
----------------------------------------
-----斗地主--提手牌  顺子逻辑判断  ---
function DDZTableLayer:LogicShunzhi(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 
    --    --提取顺子
    --    --排序   
    local tableSortCardTemp = {}
    local laiziCardData = {}    
    laiziCardData = clone(tableSortCard[20])
    for key, var in ipairs(tableSortCard) do
        for k, v in pairs(var) do
            if #v < 4 then
                local value = Bit:_and(v[1],0x0F)
                if value == 1 then
                    value = 14
                elseif value == 2 then
                    value = 15
                end
                if v[1] == 78 then 
                    value = 16 
                elseif v[1] == 79 then 
                    value = 17 
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
        if targetCardData ~= nil and targetCardData[1] == 78 then 
            targetMinValue = 16 
        elseif targetCardData ~= nil and targetCardData[1] == 79 then 
            targetMinValue = 17 
        end
        targetMinValue = targetMinValue + 1
    end
    local tableReturnCard = {}
    if targetCardData ~= nil then
        for i = targetMinValue , 14 do
            tableReturnCard = {}
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
        --有癞子  
        if #tableReturnCard < #targetCardData then 
            for i = targetMinValue , 14 do
                tableReturnCard = {}
                for j = 0, #targetCardData-1 do
                    if i+j <= 14 then 
                        if tableSortCardTemp[i+j] ~= nil  then
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j])
                        else
                            if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                            else
                                laiziCardData = clone(tableSortCard[20])
                                tableReturnCard = {}
                            end
                        end
                        if #tableReturnCard == #targetCardData then
                            table.insert(tableCard,#tableCard+1,tableReturnCard)
                            laiziCardData = clone(tableSortCard[20])
                            tableReturnCard = {}
                        end
                    end
                end             
            end
        end 
    else
        tableReturnCard = {}
        for i = 0, 14 do     
            local shunzhiYesorNo = true      
            if tableSortCardTemp[i] ~= nil then
                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i])
            elseif i == 9 then 
                if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then
                    tableReturnCard = {}
                    table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                    table.remove(laiziCardData[1],1)
                else
                    tableReturnCard = {}
                    return tableCard
                end
            else
                shunzhiYesorNo = false
            end
            if  shunzhiYesorNo == true then 
                for j = i+1, 14 do           
                    if tableSortCardTemp[j] ~= nil then
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[j])
                    else
                        if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then
                            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                            table.remove(laiziCardData[1],1)
                        else
                            laiziCardData = clone(tableSortCard[20])
                            if #tableReturnCard >= 5 then
                                table.insert(tableCard,#tableCard+1,tableReturnCard)
                            end
                            tableReturnCard = {}
                        end
                    end     
                end 
                tableReturnCard = {}
            end             
        end         
     end
    return tableCard
end

-------连队————————————
function DDZTableLayer:LogicLiandui(tableSortCard,targetCardData,tableCard)
    --提取连对
    --排序
    if tableCard == nil then
        tableCard = {}
    end 
    local tableSortCardTemp = {}
    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])
    for key, var in ipairs(tableSortCard) do
        for k, v in pairs(var) do
            if #v == 1 then                     --只有一个的时候   预测有癞子
                local value = Bit:_and(v[1],0x0F)
                if value == 1 then
                    value = 14
                elseif value == 2 then
                    value = 15
                end
                if v[1] == 78 then 
                    value = 16 
                elseif v[1] == 79 then 
                    value = 17 
                end
                tableSortCardTemp[value] = {v[#v]}
            elseif #v >= 2 and #v < 4 then     --有两者
                local value = Bit:_and(v[1],0x0F)
                if value == 1 then
                    value = 14
                elseif value == 2 then
                    value = 15
                end
                if v[1] == 78 then 
                    value = 16 
                elseif v[1] == 79 then 
                    value = 17 
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
        if targetCardData ~= nil and targetCardData[1] == 78 then 
            value = 16 
        elseif targetCardData ~= nil and targetCardData[1] == 79 then 
            value = 17 
        end
        targetMinValue = targetMinValue + 1
    end
    local tableReturnCard = {}
    if targetCardData ~= nil then
        for i = targetMinValue , 14 do
            tableReturnCard = {}
            for j = 0, #targetCardData/2-1 do
                if tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] >=2 and #tableSortCardTemp[i+j] <= 3 then
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])
                    table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]-1])
                else
                    break
                end

                if #tableReturnCard == #targetCardData then
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        end    
        --有癞子  
        if #tableReturnCard < #targetCardData then 
            for i = targetMinValue , 14 do
                tableReturnCard = {}
                for j = 0, #targetCardData/2-1 do
                    if i+j <= 14 then 
                        if tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] >=2 and #tableSortCardTemp[i+j] <= 3 then
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]-1])
                        elseif tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] ==1 then
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])
                            if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                            else
                                laiziCardData = clone(tableSortCard[20])
                                tableReturnCard = {}
                            end
                        else
                            if #laiziCardData~= 0 and #laiziCardData[1] >= 2 then
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                            else
                                laiziCardData = clone(tableSortCard[20])
                                tableReturnCard = {}
                            end
                        end
                        if #tableReturnCard == #targetCardData then
                            table.insert(tableCard,#tableCard+1,tableReturnCard)
                            laiziCardData = clone(tableSortCard[20])
                            tableReturnCard = {}
                        end
                    end
                end
            end
        end        
    else
        tableReturnCard = {}
        for i = 0, 14 do
            local shunzhiYesorNo = true   
            if tableSortCardTemp[i] ~= nil and #tableSortCardTemp[i] >=2 and #tableSortCardTemp[i] <= 3 then
                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i][#tableSortCardTemp[i]])
                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i][#tableSortCardTemp[i]-1])
            elseif tableSortCardTemp[i] ~= nil and #tableSortCardTemp[i] ==1 and #laiziCardData~= 0 and #laiziCardData[1] >= 1  then
                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i][#tableSortCardTemp[i]])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.remove(laiziCardData[1],1)
            elseif i == 12 then 
                if #laiziCardData~= 0 and #laiziCardData[1] >= 2 then
                    table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                    table.remove(laiziCardData[1],1)
                    table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                    table.remove(laiziCardData[1],1)
                else
                    tableReturnCard = {}
                    laiziCardData = clone(tableSortCard[20]) 
                    return tableCard
                end
            else
                shunzhiYesorNo = false
            end 
            if  shunzhiYesorNo == true then 
                for j = i+1, 14 do   
                    if tableSortCardTemp[j] ~= nil and #tableSortCardTemp[j] >=2 and #tableSortCardTemp[j] <= 3 then
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[j][#tableSortCardTemp[j]])
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[j][#tableSortCardTemp[j]-1])
                    elseif tableSortCardTemp[j] ~= nil and #tableSortCardTemp[j] ==1 and #laiziCardData~= 0 and #laiziCardData[1] >= 1  then
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[j][#tableSortCardTemp[j]])
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                    elseif #laiziCardData~= 0 and #laiziCardData[1] >= 2 then
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                    else
                        if #tableReturnCard >= 6 and #tableReturnCard%2 == 0 then
                            table.insert(tableCard,#tableCard+1,tableReturnCard)                                              
                        end 
                        laiziCardData = clone(tableSortCard[20])   
                        tableReturnCard = {}
                    end                    
                end 
                tableReturnCard = {}
            end
        end
    end
    return tableCard
end

------三带————————————————————————
function DDZTableLayer:LogicThree(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 

    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])

    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)   
        if targetValue == 1 then
            targetValue = 14
        elseif targetValue == 2 then
            targetValue = 15
        end
        if targetCardData[1] == 78 then 
            targetValue = 16 
        elseif targetCardData[1] == 79 then 
            targetValue = 17 
        end
    end
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[3]) do
        local value = Bit:_and(var[1],0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if var[1] == 78 then 
            value = 16 
        elseif var[1] == 79 then 
            value = 17 
        end
        if value > targetValue then
            local tableReturnCard = clone(var)
            table.insert(tableCard,#tableCard+1,tableReturnCard)
        end
    end
    if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then  
        for key, var in pairs(tableSortCardTemp[2]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end
        end
    elseif #laiziCardData~= 0 and #laiziCardData[1] >= 2 then  
        for key, var in pairs(tableSortCardTemp[1]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end
        end
    end 
    return tableCard
end 

function DDZTableLayer:LogicThreeToOne(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 

    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])

    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)   
        if targetValue == 1 then
            targetValue = 14
        elseif targetValue == 2 then
            targetValue = 15
        end
        if targetCardData[1] == 78 then 
            targetValue = 16 
        elseif targetCardData[1] == 79 then 
            targetValue = 17 
        end
    end
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[3]) do
        local value = Bit:_and(var[1],0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if var[1] == 78 then 
            value = 16 
        elseif var[1] == 79 then 
            value = 17 
        end
        if value > targetValue then
            local tableReturnCard = clone(var)
            if #tableReturnCard%4 ~= 0 then
                for k, v in pairs(tableSortCardTemp[1]) do
                    for kKey, vVar in pairs(v) do
                        table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                        if #tableReturnCard%4 == 0 then break end
                    end
                    if #tableReturnCard%4 == 0 then break end
                end
            end
            if #tableReturnCard%4 ~= 0 then
                for k, v in pairs(tableSortCardTemp[2]) do
                    for kKey, vVar in pairs(v) do
                        table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                        if #tableReturnCard%4 == 0 then break end
                    end
                    if #tableReturnCard%4 == 0 then break end
                end
            end
            if #tableReturnCard%4 ~= 0 then
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
                            if #tableReturnCard%4 == 0 then break end
                        end
                        if #tableReturnCard%4 == 0 then break end
                    end
                end
            end
            if #tableReturnCard%4 == 0 then 
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end
        end
    end
    if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then  
        for key, var in pairs(tableSortCardTemp[2]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])

                if #tableReturnCard%4 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[1]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%4 == 0 then break end
                        end
                        if #tableReturnCard%4 == 0 then break end
                    end
                end
                if #tableReturnCard%4 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[2]) do
                        local value1 = Bit:_and(v[1],0x0F)
                        if value1 == 1 then
                            value1 = 14
                        elseif value1 == 2 then
                            value1 = 15
                        end
                        if value ~= value1 then
                            for kKey, vVar in pairs(v) do
                                table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                                if #tableReturnCard%4 == 0 then break end
                            end
                            if #tableReturnCard%4 == 0 then break end
                        end
                    end
                end
                if #tableReturnCard%4 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[3]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%4 == 0 then break end
                        end
                        if #tableReturnCard%4 == 0 then break end
                    end
                end
                if #tableReturnCard%4 == 0 then
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        end
    elseif #laiziCardData~= 0 and #laiziCardData[1] >= 2 then  
        for key, var in pairs(tableSortCardTemp[1]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])

                if #tableReturnCard%4 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[1]) do
                        local value1 = Bit:_and(v[1],0x0F)
                        if value1 == 1 then
                            value1 = 14
                        elseif value1 == 2 then
                            value1 = 15
                        end
                        if value ~= value1 then
                            for kKey, vVar in pairs(v) do
                                table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                                if #tableReturnCard%4 == 0 then break end
                            end
                            if #tableReturnCard%4 == 0 then break end
                        end
                    end
                end
                if #tableReturnCard%4 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[2]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%4 == 0 then break end
                        end
                        if #tableReturnCard%4 == 0 then break end
                    end
                end
                if #tableReturnCard%4 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[3]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%4 == 0 then break end
                        end
                        if #tableReturnCard%4 == 0 then break end
                    end
                end
                if #tableReturnCard%4 == 0 then
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end 
            end
        end
    end 
    return tableCard
end 

function DDZTableLayer:LogicThreeToTwe(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 

    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])

    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)   
        if targetValue == 1 then
            targetValue = 14
        elseif targetValue == 2 then
            targetValue = 15
        end
        if targetCardData[1] == 78 then 
            targetValue = 16 
        elseif targetCardData[1] == 79 then 
            targetValue = 17 
        end
    end
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[3]) do
        local value = Bit:_and(var[1],0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if var[1] == 78 then 
            value = 16 
        elseif var[1] == 79 then 
            value = 17 
        end
        if value > targetValue then
            local tableReturnCard = clone(var)

            if #tableReturnCard%5 ~= 0 then
                for k, v in pairs(tableSortCardTemp[2]) do
                    for kKey, vVar in pairs(v) do
                        table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                        if #tableReturnCard%5 == 0 then break end
                    end
                    if #tableReturnCard%5 == 0 then break end
                end
            end
            if #tableReturnCard%5 ~= 0 then
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
                            if #tableReturnCard%5 == 0 then break end
                        end
                        if #tableReturnCard%5 == 0 then break end
                    end
                end
            end

            -- if #tableReturnCard%5 ~= 0 then
            --     for k, v in pairs(tableSortCardTemp[1]) do
            --         for kKey, vVar in pairs(v) do
            --             table.insert(tableReturnCard,#tableReturnCard+1,vVar)
            --             if #tableReturnCard%5 == 0 then break end
            --         end
            --         if #tableReturnCard%5 == 0 then break end
            --     end
            -- end
            if #tableReturnCard%5 == 0 then 
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end
        end
    end
    if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then  
        for key, var in pairs(tableSortCardTemp[2]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                if #tableReturnCard%5 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[2]) do
                        local value1 = Bit:_and(v[1],0x0F)
                        if value1 == 1 then
                            value1 = 14
                        elseif value1 == 2 then
                            value1 = 15
                        end
                        if value ~= value1 then
                            for kKey, vVar in pairs(v) do
                                table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                                if #tableReturnCard%5 == 0 then break end
                            end
                            if #tableReturnCard%5 == 0 then break end
                        end 
                    end
                end
                if #tableReturnCard%5 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[3]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%5 == 0 then break end
                        end
                        if #tableReturnCard%5 == 0 then break end
                    end
                end
                if #tableReturnCard%5 ~= 0 and #laiziCardData[1] >= 2 then
                    for k, v in pairs(tableSortCardTemp[1]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])
                            if #tableReturnCard%5 == 0 then break end
                        end
                        if #tableReturnCard%5 == 0 then break end
                    end
                end
                if #tableReturnCard%5 == 0 then 
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end 
            end
        end
    elseif #laiziCardData~= 0 and #laiziCardData[1] >= 2 then  
        for key, var in pairs(tableSortCardTemp[1]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])

                if #tableReturnCard%5 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[2]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%5 == 0 then break end
                        end
                        if #tableReturnCard%5 == 0 then break end
                    end
                end
                if #tableReturnCard%5 ~= 0 then
                    for k, v in pairs(tableSortCardTemp[3]) do
                        for kKey, vVar in pairs(v) do
                            table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                            if #tableReturnCard%5 == 0 then break end
                        end
                        if #tableReturnCard%5 == 0 then break end
                    end
                end

                if #tableReturnCard%5 ~= 0 and #laiziCardData[1] >= 2 then
                    for k, v in pairs(tableSortCardTemp[1]) do
                        local value1 = Bit:_and(v[1],0x0F)
                        if value1 == 1 then
                            value1 = 14
                        elseif value1 == 2 then
                            value1 = 15
                        end
                        if value ~= value1 then
                            for kKey, vVar in pairs(v) do
                                table.insert(tableReturnCard,#tableReturnCard+1,vVar)
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][3])
                                if #tableReturnCard%5 == 0 then break end
                            end
                            if #tableReturnCard%5 == 0 then break end
                        end 
                    end
                end
                if #tableReturnCard%5 == 0 then 
                    table.insert(tableCard,#tableCard+1,tableReturnCard)
                end
            end
        end
    end 
    return tableCard
end 
------飞机————————————————————————
function DDZTableLayer:LogicThePlane(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 
    local tableReturnCard = {}
    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])
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
                if v[1] == 78 then 
                    value = 16 
                elseif v[1] == 79 then 
                    value = 17 
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
        if targetCardData ~= nil and targetCardData[1] == 78 then 
            targetValue = 16 
        elseif targetCardData ~= nil and targetCardData[1] == 79 then 
            targetValue = 17 
        end
        targetMinValue = targetMinValue + 1
    end
    if targetCardData ~= nil then
        local count  = 0
        if #targetCardData%5 == 0 then
            count = #targetCardData/5
        elseif #targetCardData%4 == 0 then
            count = #targetCardData/4
        elseif #targetCardData%3 == 0 then
            count = #targetCardData/3
        end 
        for i = targetMinValue , 14 do
            tableReturnCard = {}
            local isAirplane = true
            for j = 0, count-1 do
                if tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] == 3 then
                    --table3SameValue[i+j] = true
                    for key, var in pairs(tableSortCardTemp[i+j]) do
                        table.insert(tableReturnCard,#tableReturnCard+1,var)
                    end
                else
                    isAirplane = false
                    break
                end
            end
            if isAirplane == true then
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end
        end
       --有癞子  
       if #tableReturnCard < #targetCardData then 
            for i = targetMinValue , 14 do
                tableReturnCard = {}
                for j = 0, count-1 do
                    if i+j <= 14 then 
                        if tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] >=3 and #tableSortCardTemp[i+j] <= 4 then
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]-1])
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])

                        elseif tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] ==2 then
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]-1])
                            if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                            else
                                laiziCardData = clone(tableSortCard[20])
                                tableReturnCard = {}
                            end
                        elseif tableSortCardTemp[i+j] ~= nil and #tableSortCardTemp[i+j] ==1 then
                            table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i+j][#tableSortCardTemp[i+j]])
                            if #laiziCardData~= 0 and #laiziCardData[1] >= 2 then
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                            else
                                laiziCardData = clone(tableSortCard[20])
                                tableReturnCard = {}
                            end
                        else
                            if #laiziCardData~= 0 and #laiziCardData[1] >= 3 then
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                                table.remove(laiziCardData[1],1)
                            else
                                laiziCardData = clone(tableSortCard[20])
                                tableReturnCard = {}
                            end
                        end
                        if #tableReturnCard == 3*count then
                            table.insert(tableCard,#tableCard+1,tableReturnCard)
                            laiziCardData = clone(tableSortCard[20])
                            tableReturnCard = {}
                        end
                    end
                end
            end
        end     
    else

        tableReturnCard = {}
        for i = 0, 14 do
            local shunzhiYesorNo = true   
            if tableSortCardTemp[i] ~= nil and #tableSortCardTemp[i] >=3 and #tableSortCardTemp[i] <= 4 then
                for key, var in pairs(tableSortCardTemp[i]) do
                    table.insert(tableReturnCard,#tableReturnCard+1,var)
                end
            elseif tableSortCardTemp[i] ~= nil and #tableSortCardTemp[i] == 2 and #laiziCardData~= 0 and #laiziCardData[1] >= 1  then
                for key, var in pairs(tableSortCardTemp[i]) do
                    table.insert(tableReturnCard,#tableReturnCard+1,var)
                end
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.remove(laiziCardData[1],1)
            elseif tableSortCardTemp[i] ~= nil and #tableSortCardTemp[i] ==1 and #laiziCardData~= 0 and #laiziCardData[1] >= 2  then
                table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[i][#tableSortCardTemp[i]])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.remove(laiziCardData[1],1)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.remove(laiziCardData[1],1)
            elseif i == 13 then 
                if #laiziCardData~= 0 and #laiziCardData[1] >= 3 then
                    table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                    table.remove(laiziCardData[1],1)
                    table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                    table.remove(laiziCardData[1],1)
                    table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                    table.remove(laiziCardData[1],1)
                else
                    tableReturnCard = {}
                    laiziCardData = clone(tableSortCard[20]) 
                    return tableCard
                end
            else
                shunzhiYesorNo = false
            end 
            if  shunzhiYesorNo == true then 
                for j = i+1, 14 do   
                    if tableSortCardTemp[j] ~= nil and #tableSortCardTemp[j] >=3 and #tableSortCardTemp[j] <= 4 then
                        for key, var in pairs(tableSortCardTemp[i]) do
                            table.insert(tableReturnCard,#tableReturnCard+1,var)
                        end
                    elseif tableSortCardTemp[j] ~= nil and #tableSortCardTemp[j] ==2 and #laiziCardData~= 0 and #laiziCardData[1] >= 1  then
                        for key, var in pairs(tableSortCardTemp[i]) do
                            table.insert(tableReturnCard,#tableReturnCard+1,var)
                        end
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                    elseif tableSortCardTemp[j] ~= nil and #tableSortCardTemp[j] ==1 and #laiziCardData~= 0 and #laiziCardData[1] >= 1  then
                        table.insert(tableReturnCard,#tableReturnCard+1,tableSortCardTemp[j][#tableSortCardTemp[j]])
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                    elseif #laiziCardData~= 0 and #laiziCardData[1] >= 3 then
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                        table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                        table.remove(laiziCardData[1],1)
                    else
                        if #tableReturnCard >= 6 and #tableReturnCard%3 == 0 then
                            table.insert(tableCard,#tableCard+1,tableReturnCard)                                              
                        end 
                        laiziCardData = clone(tableSortCard[20])   
                        tableReturnCard = {}
                    end                    
                end
                tableReturnCard = {} 
            end
        end
    end
    return tableCard
end 
------四带————————————————————————
function DDZTableLayer:LogicFour(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 

    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])

    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)
    end
    if targetValue == 1 then
        targetValue = 14
    elseif targetValue == 2 then
        targetValue = 15
    end
    if targetCardData ~= nil and targetCardData[1] == 78 then 
        targetValue = 16 
    elseif targetCardData ~= nil and targetCardData[1] == 79 then 
        targetValue = 17 
    end
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[4]) do
        local value = Bit:_and(var[1],0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if var[1] == 78 then 
            value = 16 
        elseif var[1] == 79 then 
            value = 17 
        end
        if value > targetValue then
            local tableReturnCard = clone(var)
            table.insert(tableCard,#tableCard+1,tableReturnCard)
        end
    end
    return tableCard
end

function DDZTableLayer:LogicFourlaizi(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 
    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])

    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)
    end
    if targetValue == 1 then
        targetValue = 14
    elseif targetValue == 2 then
        targetValue = 15
    end
    if targetCardData ~= nil and targetCardData[1] == 78 then 
        targetValue = 16 
    elseif targetCardData ~= nil and targetCardData[1] == 79 then 
        targetValue = 17 
    end
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[4]) do
        local value = Bit:_and(var[1],0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if var[1] == 78 then 
            value = 16 
        elseif var[1] == 79 then 
            value = 17 
        end
        local tableReturnCard = clone(var)
        table.insert(tableCard,#tableCard+1,tableReturnCard)

    end
    if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then  
        for key, var in pairs(tableSortCardTemp[3]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end
        end
    end
    if #laiziCardData~= 0 and #laiziCardData[1] >= 2 then  
        for key, var in pairs(tableSortCardTemp[2]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end
        end
    end 
    if #laiziCardData~= 0 and #laiziCardData[1] >= 3 then  
        for key, var in pairs(tableSortCardTemp[1]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            if value > targetValue then
                local tableReturnCard = clone(var)
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])
                table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][3])
                table.insert(tableCard,#tableCard+1,tableReturnCard)
            end 
        end
    end 
    return tableCard
end

function DDZTableLayer:LogicFourDone(tableSortCard,targetCardData,tableCard)
    if tableCard == nil then
        tableCard = {}
    end 
    local laiziCardData = {}   --癞子
    laiziCardData = clone(tableSortCard[20])

    local targetValue = 0
    if targetCardData ~= nil then
        targetValue = Bit:_and(targetCardData[1],0x0F)
    end
    if targetValue == 1 then
        targetValue = 14
    elseif targetValue == 2 then
        targetValue = 15
    end
    if targetCardData ~= nil and targetCardData[1] == 78 then 
        targetValue = 16 
    elseif targetCardData ~= nil and targetCardData[1] == 79 then 
        targetValue = 17 
    end
    local tableSortCardTemp = clone(tableSortCard)
    for key, var in pairs(tableSortCardTemp[4]) do
        local value = Bit:_and(var[1],0x0F)
        if value == 1 then
            value = 14
        elseif value == 2 then
            value = 15
        end
        if var[1] == 78 then 
            value = 16 
        elseif var[1] == 79 then 
            value = 17 
        end
        local tableReturnCard = clone(var)
        table.insert(tableCard,#tableCard+1,tableReturnCard)

    end
    if #laiziCardData~= 0 and #laiziCardData[1] >= 1 then  
        for key, var in pairs(tableSortCardTemp[3]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            local tableReturnCard = clone(var)
            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
            table.insert(tableCard,#tableCard+1,tableReturnCard)
        end
    end 
    if #laiziCardData~= 0 and #laiziCardData[1] >= 2 then  
        for key, var in pairs(tableSortCardTemp[2]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            local tableReturnCard = clone(var)
            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])
            table.insert(tableCard,#tableCard+1,tableReturnCard)
        end
    end 
    if #laiziCardData~= 0 and #laiziCardData[1] >= 3 then  
        for key, var in pairs(tableSortCardTemp[1]) do
            local value = Bit:_and(var[1],0x0F)
            if value == 1 then
                value = 14
            elseif value == 2 then
                value = 15
            end
            if var[1] == 78 then 
                value = 16 
            elseif var[1] == 79 then 
                value = 17 
            end
            local tableReturnCard = clone(var)
            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][1])
            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][2])
            table.insert(tableReturnCard,#tableReturnCard+1,laiziCardData[1][3])
            table.insert(tableCard,#tableCard+1,tableReturnCard)
        end
    end 
    return tableCard
end

---------------------------------------

function DDZTableLayer:EVENT_TYPE_SKIN_CHANGE(event)
    local data = event._usedata
    -- if data ~= 2 then
    --     return
    -- end
    --背景
    -- local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    -- local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
    -- if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 4 then
    --     UserDefault_Pukepaizhuo = 1
    --     cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
    -- end
    -- uiPanel_bg:removeAllChildren()
    -- uiPanel_bg:addChild(ccui.ImageView:create(string.format("puke/ui/beijing_%d.jpg",UserDefault_Pukepaizhuo)))

    self:changeBgLayer()

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
    if DDZGameCommon.gameConfig.bPlayerCount then
        for i = 0 , DDZGameCommon.gameConfig.bPlayerCount-1 do
            local wChairID = i
            if DDZGameCommon.player ~= nil and DDZGameCommon.player[wChairID] ~= nil then
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
function DDZTableLayer:setUnCardGrey()
    local Panel_handCard1 = ccui.Helper:seekWidgetByName(self.root, "Panel_handCard1")
    local tableCardArr = Panel_handCard1:getChildren()

    if type(self.lastOutCardInfo) ~= 'table' then
        printError('DDZTableLayer:setUnCardGrey data format error')
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
function DDZTableLayer:autoSelOnlyType()
    local Panel_handCard1 = ccui.Helper:seekWidgetByName(self.root, "Panel_handCard1")
    local tableCardArr = Panel_handCard1:getChildren()

    if type(self.lastOutCardInfo) ~= 'table' then
        printError('DDZTableLayer:setUnCardGrey data format error')
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

function DDZTableLayer:EVENT_TYPE_SIGNAL(event)
    local time = event._usedata
    local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
    local uiText_signal = ccui.Helper:seekWidgetByName(self.root,"Text_signal")
    if DDZGameCommon.tableConfig.nTableType ~= TableType_Playback then
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

function DDZTableLayer:EVENT_TYPE_ELECTRICITY(event)
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
function DDZTableLayer:setUserHeadCliping(headNode, headPath)
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
function DDZTableLayer:resetUserCountTimeAni()
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

function DDZTableLayer:getViewWorldPosByChairID(wChairID)
	for key, var in pairs(DDZGameCommon.player) do
		if wChairID == var.wChairID then
			local viewid = DDZGameCommon:getViewIDByChairID(var.wChairID, true)
			local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewid))
			local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
			return uiImage_avatar:getParent():convertToWorldSpace(cc.p(uiImage_avatar:getPosition()))
		end
	end
end

function DDZTableLayer:playSketlAnim(sChairID, eChairID, index,indexEx)

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
function DDZTableLayer:playSkelStartToEndPos(sChairID, eChairID, index)
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('PDKOpenUserEffect', true) --是否接受别人的互动
	
	if DDZGameCommon.meChairID == sChairID then --我发出
		if sChairID == eChairID then
			for i, v in pairs(DDZGameCommon.player or {}) do
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
				for i, v in pairs(DDZGameCommon.player or {}) do
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
function DDZTableLayer:pleaseOnlinePlayer()
    local dwClubID = DDZGameCommon.tableConfig.dwClubID
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(dwClubID):createView("PleaseOnlinePlayerLayer"))
end

function DDZTableLayer:refreshTableInfo()
    local playerNum = 0
    for k, v in pairs(DDZGameCommon.player or {}) do
        playerNum = playerNum + 1
    end
    local Button_Invitation = ccui.Helper:seekWidgetByName(self.root, "Button_Invitation")
    local Button_ready = ccui.Helper:seekWidgetByName(self.root, "Button_ready")
    if playerNum >= DDZGameCommon.gameConfig.bPlayerCount then
        Button_Invitation:setVisible(false)
        Button_ready:setVisible(true)        
        --距离报警  
        if DDZGameCommon.tableConfig.wCurrentNumber ~= nil and DDZGameCommon.tableConfig.wCurrentNumber == 0 and DDZGameCommon.DistanceAlarm ~= 1  then
            if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
                DDZGameCommon.DistanceAlarm = 1 
                if DDZGameCommon.tableConfig.nTableType == TableType_FriendRoom or DDZGameCommon.tableConfig.nTableType == TableType_ClubRoom then
                    if DDZGameCommon.gameConfig.bPlayerCount ~= 2 then 
                        --require("common.PositionLayer"):create(GameCommon.tableConfig.wKindID)
                        --require("common.DistanceAlarm"):create(DDZGameCommon.tableConfig.wKindID)
                        local tips = require("common.DistanceTip")
                        tips:checkDis(DDZGameCommon.tableConfig.wKindID)
                    end  
                end                  
            end 
        end  
    else
        Button_Invitation:setVisible(true)
        Button_ready:setVisible(false)
    end

    local Button_position = ccui.Helper:seekWidgetByName(self.root, "Button_position")
    if DDZGameCommon.gameConfig.bPlayerCount <= 2 and Button_position then
        Button_position:removeFromParent()
    end
end

function DDZTableLayer:requireClass(name)
	local path = string.format("game.%s.%s", APPNAME, name)
	return path
end

return DDZTableLayer