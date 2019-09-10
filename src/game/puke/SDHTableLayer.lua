local StaticData = require("app.static.StaticData")
local SDHGameCommon = require("game.puke.SDHGameCommon") 
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
local GameDesc = require("common.GameDesc")
local SDHTableLayer = class("SDHTableLayer",function()
    return ccui.Layout:create()
end)

local APPNAME = 'puke'

function SDHTableLayer:create(root)
    local view = SDHTableLayer.new()
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

function SDHTableLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:registListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:registListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)
    if SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
        if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
            local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
            if uiImage_signal ~= nil then 
                uiImage_signal:setVisible(false) 
            end
        end
    end
    UserData.User:initByLevel()
end

function SDHTableLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_SKIN_CHANGE,self,self.EVENT_TYPE_SKIN_CHANGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_SIGNAL,self,self.EVENT_TYPE_SIGNAL)
    EventMgr:unregistListener(EventType.EVENT_TYPE_ELECTRICITY,self,self.EVENT_TYPE_ELECTRICITY)
end

function SDHTableLayer:onCreate(root)
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

function SDHTableLayer:switchCard(location,touchType)
    local wChairID = SDHGameCommon:getRoleChairID()
    if SDHGameCommon.gameState ~= SDHGameCommon.GameState_Start then
        return
    end
    if SDHGameCommon.player[wChairID].cbCardData == nil then
    	return
    end
    local cardScale = 0.8
    local cardWidth = 161 * cardScale
    local cardHeight = 231 * cardScale
    local stepX = cardWidth * 0.4
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    local pos = uiPanel_handCard:convertToNodeSpace(cc.p(location))
    if touchType == "began" then
        self.beganPos = pos
        if cc.rectContainsPoint(uiPanel_handCard:getBoundingBox(),location) == false then
            return
        end
        local zOrder = 0
        local tempNode = nil
        for key, var in pairs(tableCardNode) do
            if var:getColor().r ~= 171 then
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
        end
        if tempNode then
            tempNode:setColor(cc.c3b(170,170,170))
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
        local beganY = self.beganPos.y
        local endY = pos.y
        if endX < beganX then
            endX = self.beganPos.x
            beganX = pos.x
        end

        for key, var in pairs(tableCardNode) do
            if var:getColor().r ~= 171 then
                local nodeLeftX = cc.p(var:getPosition()).x
                local nodeRightX = nodeLeftX + stepX
                if key == #tableCardNode then
                    nodeRightX = nodeLeftX + cardWidth
                end

                local nodeBottomY = cc.p(var:getPosition()).y
                local nodeTopY = nodeBottomY + cardHeight
                if nodeBottomY >= cardHeight*0.5 then
                    nodeBottomY = cardHeight
                    nodeTopY = nodeBottomY + cardHeight * 0.5
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
        end
    else
        local time =0.1
        local tableSwitchCard = {}
        local tableSwitchCardNode = {}
        for key, var in pairs(tableCardNode) do
            local color = var:getColor()
            if color.r == 170 then
                if var:getPositionY() > 0 and var:getPositionY() <= 20 then
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),0)))
--                    var:setPositionY(0)
                elseif math.floor(var:getPositionY()) > cardHeight * 0.5 then
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(),cardHeight * 0.5)))
                else
                    var:stopAllActions()
                    var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(), var:getPositionY()+20)))
--                    var:setPositionY(20)
                    table.insert(tableSwitchCard,#tableSwitchCard+1,var.data)
                    table.insert(tableSwitchCardNode,#tableSwitchCardNode+1,var)
                end
            end
            if color.r ~= 171 then
                var:setColor(cc.c3b(255,255,255))
            end
        end
    end
end

function SDHTableLayer:doAction(action,pBuffer)
    if action == NetMsgId.SDH_SUB_S_GAME_START then
        self:showCountDown(pBuffer.wCurrentUser, true)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        local uiButton_out = ccui.Helper:seekWidgetByName(self.root,"Button_out")
        uiButton_out:setVisible(false)
                             
    elseif action == NetMsgId.SDH_SUB_S_OUT_CARD then 
        --音效
        local targetType = pBuffer.bCardType or 0
        if targetType == 1 then
            --单牌类型
            local value = Bit:_and(pBuffer.cbCardData[1], 0x0F)
            SDHGameCommon:playAnimationEx(value, pBuffer.wOutCardUser)
        elseif targetType == 2 then
            --对牌类型
            local value = Bit:_and(pBuffer.cbCardData[1], 0x0F)
            SDHGameCommon:playAnimationEx(string.format("对%d", value), pBuffer.wOutCardUser)
        elseif targetType >= 5 and targetType <= 7 then
            --拖拉机类型
            SDHGameCommon:playAnimationEx("拖拉机", pBuffer.wOutCardUser)
        elseif targetType == 8 then
            --甩牌类型
            SDHGameCommon:playAnimationEx("甩牌", pBuffer.wOutCardUser)
        else
            SDHGameCommon:playAnimationEx("甩牌", pBuffer.wOutCardUser)
        end

        local wChairID = pBuffer.wOutCardUser
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
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
        local beganX = (size.width - ((SDHGameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)) / 2
        if anchorPoint.x == 0 then
            beganX = cardWidth/2
        elseif anchorPoint.x == 1 then
            beganX = size.width + cardWidth/2 - ((pBuffer.cbCardCount-1) * stepX + cardWidth)
        else
            beganX = (size.width - ((pBuffer.cbCardCount-1) * stepX + cardWidth)) / 2 + cardWidth/2
        end

        local index = 1
        for i = 1, pBuffer.cbCardCount do
            local var = pBuffer.cbCardData[i]
            local pos = self:removeHandCard(wChairID,var)
            local card = SDHGameCommon:getCardNode(var)
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
        self:showHandCard(wChairID,3)

        --大牌标记
        if pBuffer.wWinerUser then
            local flag = ccui.Helper:seekWidgetByName(self.root, 'big_card_flag')
            if flag then
                flag:removeFromParent()
            end
            local winner = SDHGameCommon:getViewIDByChairID(pBuffer.wWinerUser)
            local uiPanel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_weaveItemArray%d",winner))
            local cardNode = uiPanel_weaveItemArray:getChildren()[#uiPanel_weaveItemArray:getChildren()]
            if cardNode then
                flag = ccui.ImageView:create('sdh/ok_ui_sdh_bigest.png')
                cardNode:addChild(flag)
                flag:setName('big_card_flag')
                flag:setPosition(cardNode:getContentSize().width * 0.75, cardNode:getContentSize().height * 0.81)
            end
        end
        
        --最后一手自动出牌
        if pBuffer.bLastTurn == true and pBuffer.wCurrentUser == SDHGameCommon:getRoleChairID() then
            local wChairID = SDHGameCommon:getRoleChairID()
            local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
            local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
            local tableCardNode = uiPanel_handCard:getChildren()
            local tableCardData = {}
            for key, var in pairs(tableCardNode) do
                table.insert(tableCardData,var.data)
            end
            self:sendCard(wChairID,tableCardData)
        end

        --出牌提示
        if not (pBuffer.bFirstOut == true and pBuffer.wOutCardUser == SDHGameCommon:getRoleChairID()) and pBuffer.wCurrentUser ~= 65535 then
            self:setOutCardTips(pBuffer.wCurrentUser)
        end
        
    elseif action == NetMsgId.SDH_SUB_S_TURN_BALANCE then
        local score = 0
        for i,v in ipairs(pBuffer.PlayerScore) do
            if i ~= SDHGameCommon.wBankerUser+1 then
                score = score + v
            end
        end
        local AtlasLabel_score = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_score")
        AtlasLabel_score:setVisible(true)
        AtlasLabel_score:setString(score)

        local Panel_weaveItemArray = ccui.Helper:seekWidgetByName(self.root,'Panel_weaveItemArray')
        local callback = function() 
            for i,v in ipairs(Panel_weaveItemArray:getChildren()) do
                v:removeAllChildren()
            end
        end
        performWithDelay(Panel_weaveItemArray, callback, 0.8)
        
    elseif action == NetMsgId.SUB_S_GAME_END_PDK then
        for i = 1 , SDHGameCommon.gameConfig.bPlayerCount do
            local viewID = SDHGameCommon:getViewIDByChairID(i-1)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local BitmapFontLabel_score = ccui.Helper:seekWidgetByName(uiPanel_player,"BitmapFontLabel_score")
            BitmapFontLabel_score:setVisible(true)
            if pBuffer.lScore[i] > 0 then
                BitmapFontLabel_score:setString('+' .. pBuffer.lScore[i])
            else
                BitmapFontLabel_score:setString(pBuffer.lScore[i])
            end
        end

        local node = self:getChildByName('SDHSurrenderLayer')
        if node then
            node:removeFromParent()
        end

        local node = self:getChildByName('SDHConcealLayer')
        if node then
            node:removeFromParent()
        end

        local uiPanel_out = ccui.Helper:seekWidgetByName(self.root,"Panel_out")
        uiPanel_out:setVisible(false)
        SDHGameCommon.bIsOutCard = false
    
    elseif action == NetMsgId.SDH_SUB_S_SEND_CONCEAL then
        self:conCealCtr(pBuffer)

    elseif action == NetMsgId.SDH_SUB_S_BACK_CARD then
        if pBuffer.wCurrentUser == SDHGameCommon:getRoleChairID() then
            local Button_buttomCard = ccui.Helper:seekWidgetByName(self.root,"Button_buttomCard")
            Button_buttomCard:setTouchEnabled(true)
            Button_buttomCard:setColor(cc.c3b(255, 255, 255))
        end
        self:shoutBankerCtr(pBuffer)

    elseif action == NetMsgId.SDH_SUB_S_GAME_PLAY then
        local wChairID = SDHGameCommon:getRoleChairID()
        SDHGameCommon.mainColor = pBuffer.cbMainColor
        SDHGameCommon.player[wChairID].bUserCardCount = pBuffer.cbCardCount
        self:setHandCard(wChairID,SDHGameCommon.player[wChairID].bUserCardCount, pBuffer.cbCardData)
        self:showHandCard(wChairID,3)

        local Image_bankColor = ccui.Helper:seekWidgetByName(self.root,"Image_bankColor")
        Image_bankColor:setVisible(true)
        local color = Bit:_rshift(Bit:_and(pBuffer.cbMainColor,0xF0),4) + 1
        Image_bankColor:loadTexture(string.format('sdh/ok_ui_sdh_color_%d.png', color))
        local AtlasLabel_score = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_score")
        AtlasLabel_score:setVisible(true)
        AtlasLabel_score:setString(0)

    elseif action == NetMsgId.SDH_SUB_S_LOOK_RECARD_CARD then
        if not self:getChildByName('SDHLookOutCardLayer') then
            local path = self:requireClass('SDHLookOutCardLayer')
            local node = require("app.MyApp"):create(pBuffer):createGame(path)
            self:addChild(node)
            node:setName('SDHLookOutCardLayer')
        end

    elseif action == NetMsgId.SDH_SUB_S_USER_SURRENDER then
        local node = self:getChildByName('SDHSurrenderLayer')
        if pBuffer.bCode == 2 then
            --拒绝
            if node then
                node:removeFromParent()
            end

            if pBuffer.wChairID ~= SDHGameCommon:getRoleChairID() then
                local name = SDHGameCommon.player[pBuffer.wChairID].szNickName
                local context = string.format('玩家【%s】拒绝庄家的投降请求', name)
                require("common.MsgBoxLayer"):create(2,nil,context,function()
                end)
            end
            return
        end

        if not node then
            local path = self:requireClass('SDHSurrenderLayer')
            node = require("app.MyApp"):create(pBuffer):createGame(path)
            self:addChild(node)
            node:setName('SDHSurrenderLayer')
        else
            --刷新
            node:refreshUI(pBuffer)
        end
    end
end

function SDHTableLayer:showCountDown(wChairID,isHide)
    if wChairID == 65535 then
        return
    end
    self:resetUserCountTimeAni()
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
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
    if wChairID == SDHGameCommon:getRoleChairID() then
        if isHide ~= true and SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
            uiPanel_out:setVisible(true)
            local Button_tx = ccui.Helper:seekWidgetByName(uiPanel_out,"Button_tx")
            local Button_outCard = ccui.Helper:seekWidgetByName(uiPanel_out,"Button_outCard")
            if wChairID == SDHGameCommon.wBankerUser and not SDHGameCommon.bIsOutCard then
                Button_tx:setVisible(true)
                Button_outCard:setPositionX(uiPanel_out:getContentSize().width * 0.6)
                if SDHGameCommon.tableConfig.tableParameter.b35Down and SDHGameCommon.bLandScore <= 35 then
                    Button_tx:setTouchEnabled(false)
                    Button_tx:setColor(cc.c3b(170, 170, 170))
                end
            else
                Button_tx:setVisible(false)
                Button_outCard:setPositionX(uiPanel_out:getContentSize().width * 0.5)
            end
            SDHGameCommon.bIsOutCard = true
        end
    end
end

-------------------------------------------------------手牌-----------------------------------------------------
--设置手牌
function SDHTableLayer:setHandCard(wChairID,bUserCardCount,cbCardData)
    SDHGameCommon.player[wChairID].bUserCardCount = bUserCardCount
    SDHGameCommon.player[wChairID].cbCardData = cbCardData
end

--@ fux
function SDHTableLayer:changeBgLayer()
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
    if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 2 then
        UserDefault_Pukepaizhuo = 1
        cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
    end
    uiPanel_bg:removeAllChildren()
    uiPanel_bg:addChild(ccui.ImageView:create(string.format("sdh/beijing_%d.png",UserDefault_Pukepaizhuo)))

end

--删除手牌
function SDHTableLayer:removeHandCard(wChairID, cbCardData)
    --SDHGameCommon.player[wChairID].bUserCardCount = SDHGameCommon.player[wChairID].bUserCardCount - 1
    if SDHGameCommon.player[wChairID].cbCardData == nil then
        return
    end
    for key, var in pairs(SDHGameCommon.player[wChairID].cbCardData) do
    	if var == cbCardData then
    	   table.remove(SDHGameCommon.player[wChairID].cbCardData,key)
    	   break
    	end
    end
    local deleteNode = nil
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
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
function SDHTableLayer:showHandCard(wChairID,effectsType,isShowEndCard)
    if SDHGameCommon.player[wChairID].cbCardData == nil then
        return
    end
    local isCanMove = false
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
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
    local cardScale = 0.8
    local cardWidth = 180 * cardScale    
    if viewID ~= 1 then
        cardScale = 0.7
        cardWidth = 120 * cardScale 
    end
    local cardHeight = 231 * cardScale
    local stepX = cardWidth * 0.4
    local stepY = cardHeight
    local beganX = 0
    local rowMaxNum = 20
    local rowSubValue = SDHGameCommon.player[wChairID].bUserCardCount - rowMaxNum

    if anchorPoint.x == 0 then
        beganX = 0
    elseif anchorPoint.x == 1 then
        if rowSubValue > 0 then
            beganX = size.width - ((rowMaxNum-1) * stepX + cardWidth)
        else
            beganX = size.width - ((SDHGameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)
        end
    else
        if rowSubValue > 0 then
            beganX = (size.width - (rowMaxNum * stepX + cardWidth - 20)) / 2
        else
            beganX = (size.width - ((SDHGameCommon.player[wChairID].bUserCardCount-1) * stepX + cardWidth)) / 2
        end
    end

    if effectsType == 2 then
        local tableCardNode = uiPanel_handCard:getChildren()
        for key, var in pairs(tableCardNode) do
            var:setColor(cc.c3b(255,255,255))
            var:stopAllActions()
            var:runAction(cc.MoveTo:create(time,var.pt))
        end
        return
    end
    uiPanel_handCard:removeAllChildren()

    if rowSubValue > 0 then
        for i=1,rowSubValue-1 do
            local data = SDHGameCommon.player[wChairID].cbCardData[i]
            local card = SDHGameCommon:getCardNode(data)
            uiPanel_handCard:addChild(card)
            card:setLocalZOrder(i)
            card:setScale(cardScale)
            card:setAnchorPoint(cc.p(0,0))
            card.data = data
            local pt = cc.p(visibleSize.width-beganX-70-(rowSubValue-i)*stepX, stepY*0.5)
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

        local idx = 0
        for i = rowSubValue, SDHGameCommon.player[wChairID].bUserCardCount do
            idx = idx + 1
            local data = SDHGameCommon.player[wChairID].cbCardData[i]
            local card = SDHGameCommon:getCardNode(data)
            uiPanel_handCard:addChild(card)
            card:setLocalZOrder(i)
            card:setScale(cardScale)
            card:setAnchorPoint(cc.p(0,0))
            card.data = data
            local pt = cc.p(beganX + (idx-1)*stepX, 0)
            if anchorPoint.x == 0 then
                card:setPosition(-cardWidth*2, 0)
            else
                card:setPosition(visibleSize.width + cardWidth*2, 0)
            end
            
            if effectsType == 1 then
                card.pt = pt
                card:stopAllActions()
                card:runAction(cc.Sequence:create(cc.DelayTime:create(1*idx*0.03),cc.MoveTo:create(time,pt)))
            else
                card.pt = pt
                card:setPosition(card.pt)
            end
        end
    else
        for i = 1, SDHGameCommon.player[wChairID].bUserCardCount do
            local data = SDHGameCommon.player[wChairID].cbCardData[i]
            local card = SDHGameCommon:getCardNode(data)

            uiPanel_handCard:addChild(card)
            card:setLocalZOrder(i)
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

function SDHTableLayer:initUI()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    require("common.Common"):playEffect("game/pipeidonghua.mp3")
    local wKindID = SDHGameCommon.tableConfig.wKindID
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
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_outCard"),function() 
        SDHGameCommon.hostedTime = os.time()
        local wChairID = SDHGameCommon:getRoleChairID()
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
        local tableCardNode = uiPanel_handCard:getChildren()
        local tableCardData = {}
        local cardScale = 0.8
        local cardHeight = 231 * cardScale
        for key, var in pairs(tableCardNode) do
            if var:getPositionY() > 0 and var:getPositionY() <= 20 then
                table.insert(tableCardData,var.data)
            elseif math.floor(var:getPositionY()) > cardHeight*0.5 then
                table.insert(tableCardData,var.data)
            end
        end
        self:sendCard(wChairID,tableCardData)
    end)

    local Button_tx = ccui.Helper:seekWidgetByName(self.root,"Button_tx")
    Common:addTouchEventListener(Button_tx,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_GIVEUP_GAME,'b', 0)
    end)

    --用户层
    for i = 1, 4 do
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        uiPanel_player:setVisible(false)
        local uiImage_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
        self:setUserHeadCliping(uiImage_avatar)

        uiImage_avatarFrame:setTouchEnabled(true)
        uiImage_avatarFrame:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then
                for key, var in pairs(SDHGameCommon.player) do
                    if SDHGameCommon:getViewIDByChairID(var.wChairID) == i then
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

        local BitmapFontLabel_score = ccui.Helper:seekWidgetByName(uiPanel_player,"BitmapFontLabel_score")
        BitmapFontLabel_score:setVisible(false)
    end
    
    --UI层
    local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    local Button_lookRecord = ccui.Helper:seekWidgetByName(self.root,"Button_lookRecord")
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
			local box = require("app.MyApp"):create(SDHGameCommon.tableConfig.wKindID):createGame(path)
			box:setName('PDKChat')
			self:addChild(box)
        end
    end
    uiButton_expression:addTouchEventListener(onEventExpression)
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
        uiButton_voice:stopAllActions()
        uiButton_voice:runAction(cc.ScaleTo:create(0.2,0))
        uiButton_expression:stopAllActions()
        uiButton_expression:runAction(cc.ScaleTo:create(0.2,0))
        Button_lookRecord:stopAllActions()
        Button_lookRecord:runAction(cc.ScaleTo:create(0.2,0))
    end)
    uiPanel_function:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            uiPanel_function:stopAllActions()
            uiPanel_function:runAction(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
                uiPanel_function:setEnabled(false)
            end),cc.MoveTo:create(0.2,cc.p(0,0))))
            uiButton_menu:stopAllActions()
            uiButton_menu:runAction(cc.ScaleTo:create(0.2,1))
            uiButton_voice:stopAllActions()
            uiButton_voice:runAction(cc.ScaleTo:create(0.2,1))
            uiButton_expression:stopAllActions()
            uiButton_expression:runAction(cc.ScaleTo:create(0.2,1))
            Button_lookRecord:stopAllActions()
            Button_lookRecord:runAction(cc.ScaleTo:create(0.2,1))
        end
    end)  
    local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_skin"),function() 
        local box = require("app.MyApp"):create():createGame('game.puke.KwxPukeColor')
		self:addChild(box) 
        -- local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
        -- UserDefault_Pukepaizhuo = UserDefault_Pukepaizhuo + 1
        -- if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 2 then
        --     UserDefault_Pukepaizhuo = 1
        -- end
        -- cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
        -- uiPanel_bg:removeAllChildren()
        -- uiPanel_bg:addChild(ccui.ImageView:create(string.format("sdh/beijing_%d.png",UserDefault_Pukepaizhuo)))
    end)
    local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
    if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 2 then
        UserDefault_Pukepaizhuo = 1
        cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
    end
    if UserDefault_Pukepaizhuo ~= 0 then
        uiPanel_bg:removeAllChildren()
        uiPanel_bg:addChild(ccui.ImageView:create(string.format("sdh/beijing_%d.png",UserDefault_Pukepaizhuo)))
    end
    
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
    local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
    uiButton_ready:setVisible(false)
    Common:addTouchEventListener(uiButton_ready,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_READY,"o",false)
    end)
    local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
    Common:addTouchEventListener(uiButton_Invitation,function() 
        local currentPlayerCount = 0
        for key, var in pairs(SDHGameCommon.player) do
            currentPlayerCount = currentPlayerCount + 1
        end
        local player = "("
        for key, var in pairs(SDHGameCommon.player) do
            if key == 0 then
                player = player..var.szNickName
            else
                player = player.."、"..var.szNickName
            end
        end
        player = player..")"
        local data = clone(UserData.Share.tableShareParameter[3])
        if data then
            data.dwClubID = SDHGameCommon.tableConfig.dwClubID
            data.szShareTitle = string.format(data.szShareTitle,StaticData.Games[SDHGameCommon.tableConfig.wKindID].name,
                SDHGameCommon.tableConfig.wTbaleID,SDHGameCommon.tableConfig.wTableNumber,
                SDHGameCommon.gameConfig.bPlayerCount,SDHGameCommon.gameConfig.bPlayerCount-currentPlayerCount)..player
            data.szShareContent = GameDesc:getGameDesc(SDHGameCommon.tableConfig.wKindID,SDHGameCommon.gameConfig,SDHGameCommon.tableConfig).." (点击加入游戏)"
            data.szShareUrl = string.format(data.szShareUrl, SDHGameCommon.tableConfig.szGameID)
            if SDHGameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
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
        require("common.PositionLayer"):create(SDHGameCommon.tableConfig.wKindID)
       -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createGame("game.puke.KwxLocationLayer"))
       -- require("game.yongzhou.PositionLayer"):create(SDHGameCommon.tableConfig.wKindID)
    end)

    local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
    if SDHGameCommon.tableConfig.wCurrentNumber == 0 and  SDHGameCommon.tableConfig.nTableType == TableType_FriendRoom or SDHGameCommon.tableConfig.nTableType == TableType_ClubRoom then
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
 
    local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
    local uiText_des = ccui.Helper:seekWidgetByName(self.root,"Text_des")
    uiText_title:setString(StaticData.Games[SDHGameCommon.tableConfig.wKindID].name)    
    if SDHGameCommon.tableConfig.nTableType == TableType_FriendRoom or SDHGameCommon.tableConfig.nTableType == TableType_ClubRoom then
        self:addVoice()
        local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")
        if  StaticData.Hide[CHANNEL_ID].btn10 == 0 then 
            uiListView_function:removeItem(uiListView_function:getIndex(uiButton_position)) 
            uiPanel_playerInfoBg:setVisible(false) 
        end
        uiButton_cancel:setVisible(false)
        if SDHGameCommon.gameState == SDHGameCommon.GameState_Start  then
            local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
            uiPanel_ready:setVisible(false)
            if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
                uiButton_Invitation:setVisible(false)
                uiButton_out:setVisible(false)
            else
                uiButton_Invitation:setVisible(true)
                uiButton_out:setVisible(true)
            end

        elseif SDHGameCommon.tableConfig.wCurrentNumber > 0 then
            uiButton_Invitation:setVisible(false)
            uiButton_out:setVisible(false)
            uiButton_SignOut:setVisible(false)
        end
        if StaticData.Hide[CHANNEL_ID].btn4 ~= 1 then
            uiButton_Invitation:setVisible(false)
            -- uiButton_out:setPositionX(visibleSize.width*0.5)   
        end
        uiText_des:setString(string.format("房间号:%d 局数:%d/%d",SDHGameCommon.tableConfig.wTbaleID, SDHGameCommon.tableConfig.wCurrentNumber, SDHGameCommon.tableConfig.wTableNumber))

        -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/dengdaihaoyou/dengdaihaoyou.ExportJson")
        -- local waitArmature=ccs.Armature:create("dengdaihaoyou")
        -- waitArmature:setPosition(-179.2,150)
        -- if CHANNEL_ID == 6 or  CHANNEL_ID  == 7 or CHANNEL_ID == 8 or  CHANNEL_ID  == 9 then
        --     waitArmature:setPosition(0,150)
        -- end 
        -- waitArmature:getAnimation():playWithIndex(0)
        -- uiButton_Invitation:addChild(waitArmature)   

    elseif SDHGameCommon.tableConfig.nTableType == TableType_GoldRoom or SDHGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then            
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
        if SDHGameCommon.tableConfig.cbLevel == 2 then
            uiText_des:setString(string.format("中级场 倍率 %d",SDHGameCommon.tableConfig.wCellScore))
        elseif SDHGameCommon.tableConfig.cbLevel == 3 then
            uiText_des:setString(string.format("高级场 倍率 %d",SDHGameCommon.tableConfig.wCellScore))
        else
            uiText_des:setString(string.format("初级场 倍率 %d",SDHGameCommon.tableConfig.wCellScore))
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
    if SDHGameCommon.tableConfig.nTableType == TableType_ClubRoom and SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
        if SDHGameCommon.gameState == SDHGameCommon.GameState_Start or SDHGameCommon.tableConfig.wCurrentNumber > 0 then
            Button_clubTable:setVisible(false)
            Button_expression:setVisible(true)
            Button_voice:setVisible(true)
        else
            Button_clubTable:setVisible(true)
            Button_expression:setVisible(false)
            Button_voice:setVisible(false)
        end

        Common:addTouchEventListener(Button_clubTable,function()
            local dwClubID = SDHGameCommon.tableConfig.dwClubID
            self:addChild(require("app.MyApp"):create(dwClubID):createView("NewClubFreeTableLayer"))
        end)
    else
        Button_clubTable:setVisible(false)
    end

    local Panel_shoutBank = ccui.Helper:seekWidgetByName(self.root,"Panel_shoutBank")
    Panel_shoutBank:setVisible(false)
    local Image_bankColor = ccui.Helper:seekWidgetByName(self.root,"Image_bankColor")
    Image_bankColor:setVisible(false)
    Image_bankColor:ignoreContentAdaptWithSize(true)
    local AtlasLabel_shoutScore = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_shoutScore")
    AtlasLabel_shoutScore:setVisible(false)
    local AtlasLabel_score = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_score")
    AtlasLabel_score:setVisible(false)

    for i=1,4 do
        local Panel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        local Panel_shoutScore = Panel_player:getChildByName("Panel_shoutScore")
        Panel_shoutScore:setVisible(false)
        local uiImage_paishu = ccui.Helper:seekWidgetByName(Panel_player,"Image_paishu")
        uiImage_paishu:setVisible(false)   
    end

    local Button_buttomCard = ccui.Helper:seekWidgetByName(self.root,"Button_buttomCard")
    local Button_recordCard = ccui.Helper:seekWidgetByName(self.root,"Button_recordCard")
    Button_buttomCard:setVisible(false)
    Button_recordCard:setVisible(false)
    Button_buttomCard:setTouchEnabled(false)
    Button_buttomCard:setColor(cc.c3b(170, 170, 170))

    Common:addTouchEventListener(Button_lookRecord,function()
        if SDHGameCommon.GameState_Start ~= SDHGameCommon.gameState then
            require("common.MsgBoxLayer"):create(0,nil,'游戏开始后查看!')
            return
        end

        if not Button_lookRecord:isBright() then
            Button_buttomCard:setVisible(false)
            Button_recordCard:setVisible(false)
            Button_lookRecord:setBright(true)
        else
            Button_buttomCard:setVisible(true)
            Button_recordCard:setVisible(true)
            Button_lookRecord:setBright(false)
        end
    end)
    Common:addTouchEventListener(Button_buttomCard,function()
        Button_buttomCard:setVisible(false)
        Button_recordCard:setVisible(false)
        Button_lookRecord:setBright(true)
        local path = self:requireClass('SDHLookConcealLayer')
        self:addChild(require("app.MyApp"):create():createGame(path))
    end)
    Common:addTouchEventListener(Button_recordCard,function()
        Button_buttomCard:setVisible(false)
        Button_recordCard:setVisible(false)
        Button_lookRecord:setBright(true)
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_LOOK_RECORD_CARD,'')
    end)

    if SDHGameCommon.tableConfig.nTableType == TableType_Playback or SDHGameCommon.tableConfig.tableParameter.bNoLookCard then
        Button_lookRecord:setVisible(false)
    end
end

function SDHTableLayer:addClickItem()
    local Panel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
    local child = {}
    for i=1,4 do
        local child = ccui.Helper:seekWidgetByName(Panel_piaoFen,(i-1))
        Common:addTouchEventListener(child,function() 
            local index= child:getName()
            print('--xx',SDHGameCommon.wPiaoCount[i])
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.REC_SUB_C_JIAPIAO,"b",SDHGameCommon.wPiaoCount[i])
        end)
        --table.insert(childs,child)
    end
end


function SDHTableLayer:drawnout()
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

function SDHTableLayer:updateGameState(state)
    SDHGameCommon.gameState = state 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    if state == SDHGameCommon.GameState_Init then
    elseif state == SDHGameCommon.GameState_Start then
		require("common.SceneMgr"):switchOperation()
        local uiPanel_playerInfoBg = ccui.Helper:seekWidgetByName(self.root,"Panel_playerInfoBg")
        uiPanel_playerInfoBg:setVisible(false)
        local uiPanel_ready = ccui.Helper:seekWidgetByName(self.root,"Panel_ready")
        uiPanel_ready:setVisible(false)
        if SDHGameCommon.tableConfig.nTableType == TableType_FriendRoom or SDHGameCommon.tableConfig.nTableType == TableType_ClubRoom then
            -- --距离报警  
            -- if SDHGameCommon.tableConfig.wCurrentNumber ~= nil and SDHGameCommon.tableConfig.wCurrentNumber == 1 and SDHGameCommon.DistanceAlarm ~= 1  then
            --     if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
            --         SDHGameCommon.DistanceAlarm = 1 
            --         if SDHGameCommon.gameConfig.bPlayerCount ~= 2 then 
            --            require("common.DistanceAlarm"):create(SDHGameCommon)
            --         end                    
            --     end 
            -- end
            for i = 1, 4 do
                local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
                local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
                uiImage_ready:setVisible(false)
            end
        elseif SDHGameCommon.tableConfig.nTableType == TableType_GoldRoom or SDHGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
            local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
            uiButton_expression:setVisible(true)
            local uiButton_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
            uiButton_voice:setVisible(true)
        end         
        local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")  --取消按钮
        uiButton_cancel:setVisible(false)
        local uiImage_timedown = ccui.Helper:seekWidgetByName(self.root,"Image_timedown")
        uiImage_timedown:setVisible(false)
    elseif state == SDHGameCommon.GameState_Over then
        UserData.Game:addGameStatistics(SDHGameCommon.tableConfig.wKindID)
    else
    
    end

    -- @cxx 牌桌查看俱乐部
    local Button_clubTable = ccui.Helper:seekWidgetByName(self.root,"Button_clubTable")
    local Button_voice = ccui.Helper:seekWidgetByName(self.root,"Button_voice")
    local Button_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    if SDHGameCommon.tableConfig.nTableType == TableType_ClubRoom and SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
        if SDHGameCommon.gameState == SDHGameCommon.GameState_Start or SDHGameCommon.tableConfig.wCurrentNumber > 0 then
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
function SDHTableLayer:addVoice()
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
        data.chirID = SDHGameCommon:getRoleChairID()
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
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_GF_USER_VOICE,"wwwdddnsnf",SDHGameCommon:getRoleChairID(),packCount,i,data.time,fileSize,periodSize,32,data.file,periodSize,periodData)
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
            local viewID = SDHGameCommon:getViewIDByChairID(data.chirID)
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

function SDHTableLayer:OnUserChatVoice(event)
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

function SDHTableLayer:showPlayerPosition()   -- 显示玩家距离    
    local wChairID = 0
    for key, var in pairs(SDHGameCommon.player) do
        if var.dwUserID == SDHGameCommon.dwUserID then
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
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID) 
    for wChairID = 0, 3 do
        if SDHGameCommon.player[wChairID] ~= nil then
            local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
            local uiPanel_players = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_players%d",viewID))
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_players,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_players,"Image_avatar")
            if SDHGameCommon.player[wChairID] ~= nil then 
                uiImage_avatar:loadTexture("common/common_dian2.png")
            end 
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            uiText_name:setString(SDHGameCommon.player[wChairID].szNickName)
            for wTargetChairID = 0, SDHGameCommon.gameConfig.bPlayerCount-1 do
                local targetViewID = SDHGameCommon:getViewIDByChairID(wTargetChairID)
                if SDHGameCommon.gameConfig.bPlayerCount == 3 and wTargetChairID == 3 then
                    viewID = 4
                end
                if wTargetChairID ~= wChairID then
                    local uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",viewID,targetViewID))
                    if viewID > targetViewID then
                        uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",targetViewID,viewID))
                    end
                    if uiText_location ~= nil then
                        local distance = uiText_location:getString()
                        if SDHGameCommon.gameConfig.bPlayerCount == 3 and (wChairID == 3 or wTargetChairID == 3) then
                            distance = ""
                        elseif SDHGameCommon.player[wChairID] == nil or SDHGameCommon.player[wTargetChairID] == nil then
                            distance = "等待加入..."
                        elseif SDHGameCommon.tableConfig.nTableType == TableType_GoldRoom or SDHGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
                            if distance == "500m" then
                                distance = math.random(1000,300000)
                            end
                        elseif SDHGameCommon.player[wChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",SDHGameCommon.player[wChairID].szNickName)
                        elseif SDHGameCommon.player[wTargetChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",SDHGameCommon.player[wTargetChairID].szNickName)
                        else
                            distance = SDHGameCommon:GetDistance(SDHGameCommon.player[wChairID].location,SDHGameCommon.player[wTargetChairID].location) 
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

function SDHTableLayer:showPlayerInfo(infoTbl)       -- 查看玩家信息
    Common:palyButton()
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(infoTbl, SDHGameCommon.tableConfig.wKindID):createGame("game.puke.PDKPersonInfor"))
    --require("common.PersonalLayer"):create(SDHGameCommon.tableConfig.wKindID,dwUserID,dwShamUserID)
end
function SDHTableLayer:showChat(pBuffer)
    local viewID = SDHGameCommon:getViewIDByChairID(pBuffer.dwUserID, true)
	local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewID))
	local uiImage_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_chat")
	local uiText_chat = ccui.Helper:seekWidgetByName(uiPanel_player, "Text_chat")
	uiText_chat:setString(pBuffer.szChatContent)
	uiImage_chat:setVisible(true)
	uiImage_chat:setScale(0)
	uiImage_chat:stopAllActions()
	uiImage_chat:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1), cc.DelayTime:create(5), cc.Hide:create()))
	local wKindID = SDHGameCommon.tableConfig.wKindID
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
		if SDHGameCommon.language ~= 0 then
			local wKindID = SDHGameCommon.tableConfig.wKindID
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

function SDHTableLayer:showReward(pBuffer)
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

function SDHTableLayer:showExperssion(pBuffer)
	self:playSpine(pBuffer)
end

function SDHTableLayer:playSpine(pBuffer)
    local cusNode = cc.Director:getInstance():getNotificationNode()
    if not cusNode then
    	printInfo('global_node is nil')
    	return
    end
    local arr = cusNode:getChildren()
    for i,v in ipairs(arr) do
        v:setVisible(false)
    end

    local viewID = SDHGameCommon:getViewIDByChairID(pBuffer.wChairID, true)
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
				
				soundData = sound[SDHGameCommon.language]
				if SDHGameCommon.language ~= 0 then
					local wKindID = SDHGameCommon.tableConfig.wKindID
					if wKindID == 47 or wKindID == 48 or wKindID == 49 or wKindID == 60 then
						soundData = sound[2]
					end
				end
				
				if soundData ~= nil then
					local player = SDHGameCommon.player[pBuffer.wChairID]
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

function SDHTableLayer:sendCard(wChairID,tableCardData)
    local net = NetMgr:getGameInstance()
    if net.connected == false then
        return
    end
    if #tableCardData <= 0 then
        return
    end
    net.cppFunc:beginSendBuf(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_OUT_CARD)
    net.cppFunc:writeSendByte(#tableCardData,0)
    for key, var in pairs(tableCardData) do
        net.cppFunc:writeSendByte(var,0)
    end
    for i = #tableCardData+1, SDHGameCommon.MAX_COUNT do
        net.cppFunc:writeSendByte(0,0)
    end
    net.cppFunc:endSendBuf()
    net.cppFunc:sendSvrBuf()
    self:resetCoutCardTips(wChairID)
end

function SDHTableLayer:EVENT_TYPE_SKIN_CHANGE(event)
    local data = event._usedata
    -- if data ~= 2 then
    --     return
    -- end
    --背景
    -- local uiPanel_bg = ccui.Helper:seekWidgetByName(self.root,"Panel_bg")
    -- local UserDefault_Pukepaizhuo = cc.UserDefault:getInstance():getIntegerForKey('PDKBgNum',2)
    -- if UserDefault_Pukepaizhuo < 0 or UserDefault_Pukepaizhuo > 2 then
    --     UserDefault_Pukepaizhuo = 1
    --     cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',UserDefault_Pukepaizhuo)
    -- end
    -- uiPanel_bg:removeAllChildren()
    -- uiPanel_bg:addChild(ccui.ImageView:create(string.format("sdh/beijing_%d.png",UserDefault_Pukepaizhuo)))

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
    if SDHGameCommon.gameConfig.bPlayerCount then
        for i = 0 , SDHGameCommon.gameConfig.bPlayerCount-1 do
            local wChairID = i
            if SDHGameCommon.player ~= nil and SDHGameCommon.player[wChairID] ~= nil then
                self:showHandCard(wChairID,3)
            end
        end
    end
end

function SDHTableLayer:EVENT_TYPE_SIGNAL(event)
    local time = event._usedata
    local uiImage_signal = ccui.Helper:seekWidgetByName(self.root,"Image_signal")
    local uiText_signal = ccui.Helper:seekWidgetByName(self.root,"Text_signal")
    if SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
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

function SDHTableLayer:EVENT_TYPE_ELECTRICITY(event)
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
function SDHTableLayer:setUserHeadCliping(headNode, headPath)
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
function SDHTableLayer:resetUserCountTimeAni()
    for i = 1, 4 do
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

function SDHTableLayer:getViewWorldPosByChairID(wChairID)
	for key, var in pairs(SDHGameCommon.player) do
		if wChairID == var.wChairID then
			local viewid = SDHGameCommon:getViewIDByChairID(var.wChairID, true)
			local uiPanel_player = ccui.Helper:seekWidgetByName(self.root, string.format("Panel_player%d", viewid))
			local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player, "Image_avatar")
			return uiImage_avatar:getParent():convertToWorldSpace(cc.p(uiImage_avatar:getPosition()))
		end
	end
end

function SDHTableLayer:playSketlAnim(sChairID, eChairID, index,indexEx)

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
function SDHTableLayer:playSkelStartToEndPos(sChairID, eChairID, index)
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('PDKOpenUserEffect', true) --是否接受别人的互动
	
	if SDHGameCommon.meChairID == sChairID then --我发出
		if sChairID == eChairID then
			for i, v in pairs(SDHGameCommon.player or {}) do
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
				for i, v in pairs(SDHGameCommon.player or {}) do
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
function SDHTableLayer:pleaseOnlinePlayer()
    local dwClubID = SDHGameCommon.tableConfig.dwClubID
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(dwClubID):createView("PleaseOnlinePlayerLayer"))
end

function SDHTableLayer:refreshTableInfo()
    local playerNum = 0
    for k, v in pairs(SDHGameCommon.player or {}) do
        playerNum = playerNum + 1
    end
    local Button_Invitation = ccui.Helper:seekWidgetByName(self.root, "Button_Invitation")
    local Button_ready = ccui.Helper:seekWidgetByName(self.root, "Button_ready")
    if playerNum >= SDHGameCommon.gameConfig.bPlayerCount then
        Button_Invitation:setVisible(false)
        Button_ready:setVisible(true)        
        --距离报警  
        if SDHGameCommon.tableConfig.wCurrentNumber ~= nil and SDHGameCommon.tableConfig.wCurrentNumber == 0 and SDHGameCommon.DistanceAlarm ~= 1  then
            if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
                SDHGameCommon.DistanceAlarm = 1 
                if SDHGameCommon.gameConfig.bPlayerCount ~= 2 then 
                    --require("common.PositionLayer"):create(SDHGameCommon.tableConfig.wKindID)
                    --require("common.DistanceAlarm"):create(SDHGameCommon)
                	local tips = require("common.DistanceTip")
                	tips:checkDis(SDHGameCommon.tableConfig.wKindID)
                end                    
            end 
        end  
    else
        Button_Invitation:setVisible(true)
        Button_ready:setVisible(false)
    end

    local Button_position = ccui.Helper:seekWidgetByName(self.root, "Button_position")
    if SDHGameCommon.gameConfig.bPlayerCount <= 2 and Button_position then
        Button_position:removeFromParent()
    end
end

function SDHTableLayer:requireClass(name)
	local path = string.format("game.%s.%s", APPNAME, name)
	return path
end

function SDHTableLayer:shoutSorceCtr(pBuffer)
    local wChairID = SDHGameCommon:getRoleChairID()
    if wChairID == pBuffer.wCurrentUser and SDHGameCommon.tableConfig.nTableType ~= TableType_Playback then
        local baseSorce = 60
        if SDHGameCommon.gameConfig.bPlayerCount > 3 then
            baseSorce = 80
        end
        local path = self:requireClass('SDHShoutSorceLayer')
        self:addChild(require("app.MyApp"):create(pBuffer, baseSorce):createGame(path))
    end

    for wChairID,v in ipairs(pBuffer.wUserScore) do
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID-1)
        local Panel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        if Panel_player and wChairID <= SDHGameCommon.gameConfig.bPlayerCount then
            local Panel_shoutScore = Panel_player:getChildByName("Panel_shoutScore")
            if v ~= 0 then
                Panel_shoutScore:setVisible(true)
                local AtlasLabel_sorce = Panel_shoutScore:getChildByName("AtlasLabel_sorce")
                local Image_noShout = Panel_shoutScore:getChildByName("Image_noShout")
                if v == 255 then
                    AtlasLabel_sorce:setVisible(false)
                    Image_noShout:setVisible(true)
                else
                    AtlasLabel_sorce:setVisible(true)
                    Image_noShout:setVisible(false)
                    AtlasLabel_sorce:setString(v)
                end
            else
                Panel_shoutScore:setVisible(false)
            end
        end
    end
end

function SDHTableLayer:conCealCtr(pBuffer)
    local wChairID = SDHGameCommon:getRoleChairID()
    if wChairID == pBuffer.wCurrentUser then
        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
        uiPanel_handCard:setVisible(false)

        local path = self:requireClass('SDHConcealLayer')
        local node = require("app.MyApp"):create(pBuffer):createGame(path)
        self:addChild(node)
        node:setName('SDHConcealLayer')
    end

    local AtlasLabel_shoutScore = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_shoutScore")
    AtlasLabel_shoutScore:setVisible(true)
    AtlasLabel_shoutScore:setString(pBuffer.bLandScore)

    for i=1,SDHGameCommon.gameConfig.bPlayerCount do
        local Panel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        local Panel_shoutScore = Panel_player:getChildByName("Panel_shoutScore")
        Panel_shoutScore:setVisible(false)
    end
end

function SDHTableLayer:shoutBankerCtr(pBuffer)
    local wChairID = SDHGameCommon:getRoleChairID()
    if wChairID == pBuffer.wCurrentUser then
        SDHGameCommon.player[wChairID].bUserCardCount = pBuffer.cbCardCount
        self:setHandCard(wChairID,SDHGameCommon.player[wChairID].bUserCardCount, pBuffer.cbCardData)
        self:showHandCard(wChairID,3)

        local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
        local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
        local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
        uiPanel_handCard:setVisible(true)

        local Panel_shoutBank = ccui.Helper:seekWidgetByName(self.root,"Panel_shoutBank")
        Panel_shoutBank:setVisible(true)
        local Image_bankFrame = Panel_shoutBank:getChildByName('Image_bankFrame')
        local color = {0x40, 0x30, 0x20, 0x10, 0x00}
        for i,v in ipairs(Image_bankFrame:getChildren()) do
            Common:addTouchEventListener(v, function() 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SDH_SUB_C_CALL_CARD,"b", color[i])
                Panel_shoutBank:setVisible(false)
            end)
        end
    end
end

function SDHTableLayer:reconnectTable(pBuffer)
    if pBuffer.bStatus == 103 then
        local Image_bankColor = ccui.Helper:seekWidgetByName(self.root,"Image_bankColor")
        Image_bankColor:setVisible(true)
        local color = Bit:_rshift(Bit:_and(pBuffer.cbMainColor,0xF0),4) + 1
        Image_bankColor:loadTexture(string.format('sdh/ok_ui_sdh_color_%d.png', color))

        local AtlasLabel_shoutScore = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_shoutScore")
        AtlasLabel_shoutScore:setVisible(true)
        AtlasLabel_shoutScore:setString(pBuffer.bCurrentScore)

        local AtlasLabel_score = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_score")
        AtlasLabel_score:setVisible(true)
        AtlasLabel_score:setString(pBuffer.wGameScore)
    end
end

function SDHTableLayer:refreshScores(score)
    local AtlasLabel_score = ccui.Helper:seekWidgetByName(self.root,"AtlasLabel_score")
    AtlasLabel_score:setVisible(true)
    AtlasLabel_score:setString(score)
end

----------------------
--数量不足提起
--对牌提起
--花色判断
function SDHTableLayer:setOutCardTips(wCurrentUser)
    local wChairID = SDHGameCommon:getRoleChairID()
    if wCurrentUser ~= wChairID then
        return
    end

    if SDHGameCommon.firstOutCount <= 0 then
        return
    end

    --主牌或副牌数量不足自动提
    local firstColor = Bit:_and(SDHGameCommon.firstOutCard[1],0xF0)
    if self:isMainCardData(SDHGameCommon.firstOutCard[1]) then
        local mainCount = self:getMainCardCount(wChairID)
        if mainCount <= SDHGameCommon.firstOutCount then
            if mainCount == SDHGameCommon.firstOutCount then
                self:resetCoutCardTips(wChairID, true)
            end
            
            if mainCount > 0 then
                self:autoCardUp(1, wChairID)
            end
            return
        end
    else
        local colorCount = self:getColorCardCount(wChairID, firstColor)
        if colorCount <= SDHGameCommon.firstOutCount then
            if colorCount == SDHGameCommon.firstOutCount then
                self:resetCoutCardTips(wChairID, true)
            end

            if colorCount > 0 then
                self:autoCardUp(2, wChairID, firstColor)
            end
            return
        end
    end

    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    for key, var in pairs(tableCardNode) do
        if self:isMainCardData(SDHGameCommon.firstOutCard[1]) then
            --首牌是主
            if not self:isMainCardData(var.data) then
                var:setColor(cc.c3b(171, 171, 171))
            end
            if SDHGameCommon.firstOutCount % 2 == 0 then
                self:autoCardUp(3, wChairID)
            end

        else
            --首牌不是主
            local curColor = Bit:_and(var.data,0xF0)
            if firstColor ~= curColor or self:isMainCardData(var.data) then
                var:setColor(cc.c3b(171, 171, 171))
            end
            if SDHGameCommon.firstOutCount % 2 == 0 then
                self:autoCardUp(4, wChairID, firstColor)
            end
        end
    end
end

function SDHTableLayer:resetCoutCardTips(wChairID, isGrey)
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    for key, var in pairs(tableCardNode) do
        if isGrey then
            var:setColor(cc.c3b(171, 171, 171))
        else
            var:setColor(cc.c3b(255, 255, 255))
        end
    end
end

function SDHTableLayer:resetCardNodeYPos(wChairID)
    local cardScale = 0.8
    local cardHeight = 231 * cardScale
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    for key, var in pairs(tableCardNode) do
        if var:getPositionY() > 0 and var:getPositionY() <= 20 then
            var:setPositionY(0)
        elseif math.floor(var:getPositionY()) > cardHeight * 0.5 then
            var:setPositionY(cardHeight * 0.5)
        end
    end
end

function SDHTableLayer:isMainCardData(data)
    local value = Bit:_and(data,0x0F)
    local color = Bit:_and(data,0xF0)
    local mainColor = Bit:_and(SDHGameCommon.mainColor,0xF0)
    if color == mainColor or value == 7 or value == 2 or data == 0x4E or data == 0x4F then
        return true
    end
    return false
end

function SDHTableLayer:getMainCardCount(wChairID)
    local count = 0
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    for key, var in pairs(tableCardNode) do
        if self:isMainCardData(var.data) then
            count = count + 1
        end
    end
    return count
end

function SDHTableLayer:getColorCardCount(wChairID, cardColor)
    local count = 0
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    for key, var in pairs(tableCardNode) do
        local value = Bit:_and(var.data,0x0F)
        local color = Bit:_and(var.data,0xF0)
        if value ~= 2 and value ~= 7 and var.data ~= 0x4E and var.data ~= 0x4F and color == cardColor then
            count = count + 1
        end
    end
    return count
end

--ctype 1:主<=自动提  2:副牌<=自动提 3:主牌对子自动提 4:副牌对子自动提 colorEx:牌颜色
function SDHTableLayer:autoCardUp(ctype, wChairID, colorEx)
    self:resetCardNodeYPos(wChairID)
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()

    if ctype < 3 then
        for key, var in pairs(tableCardNode) do
            local value = Bit:_and(var.data,0x0F)
            local color = Bit:_and(var.data,0xF0)
            if ctype == 1 and self:isMainCardData(var.data) then
                var:stopAllActions()
                var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(), var:getPositionY()+20)))
                var:setColor(cc.c3b(255, 255, 255))
            elseif ctype == 2 and value ~= 2 and value ~= 7 and var.data ~= 0x4E and var.data ~= 0x4F and color == colorEx then
                var:stopAllActions()
                var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(), var:getPositionY()+20)))
                var:setColor(cc.c3b(255, 255, 255))
            end
        end
    end
    
    if ctype == 3 or ctype == 4 then
        if SDHGameCommon.firstOutCount % 2 ~= 0 then
            return
        end

        local doubleNum = SDHGameCommon.firstOutCount / 2
        local curDoubleTbl = self:getDoubleCardTable(wChairID, colorEx)
        local curDoubleNum = #curDoubleTbl / 2
        if curDoubleNum == doubleNum then
            self:resetCoutCardTips(wChairID, true)
            for i,var in ipairs(curDoubleTbl) do
                var:stopAllActions()
                var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(), var:getPositionY()+20)))
                var:setColor(cc.c3b(255, 255, 255))
            end
        elseif curDoubleNum > doubleNum then
            self:resetCoutCardTips(wChairID, true)
            for i,var in ipairs(curDoubleTbl) do
                var:setColor(cc.c3b(255, 255, 255))
            end

        elseif curDoubleNum ~= 0 and curDoubleNum < doubleNum then
            for i,var in ipairs(curDoubleTbl) do
                var:stopAllActions()
                var:runAction(cc.MoveTo:create(0.1,cc.p(var:getPositionX(), var:getPositionY()+20)))
            end
        end
    end
end

-- colorEx nil主牌， 其它对应牌颜色
function SDHTableLayer:getDoubleCardTable(wChairID, colorEx)
    local viewID = SDHGameCommon:getViewIDByChairID(wChairID)
    local uiPanel_card = ccui.Helper:seekWidgetByName(self.root,"Panel_card")
    local uiPanel_handCard = ccui.Helper:seekWidgetByName(uiPanel_card,string.format("Panel_handCard%d",viewID))
    local tableCardNode = uiPanel_handCard:getChildren()
    local tempTable = {}
    local lastCard = nil
    for key, var in ipairs(tableCardNode) do
        local value = Bit:_and(var.data,0x0F)
        local color = Bit:_and(var.data,0xF0)
        if not colorEx then
            --主牌对子
            if self:isMainCardData(var.data) then
                if lastCard and value == Bit:_and(lastCard.data,0x0F) and color == Bit:_and(lastCard.data,0xF0) then
                    table.insert(tempTable, lastCard)
                    table.insert(tempTable, var)
                    lastCard = nil
                end
                lastCard = var
            end
        else
            --副牌对子
            if value ~= 2 and value ~= 7 and var.data ~= 0x4E and var.data ~= 0x4F and color == colorEx then
                if lastCard and value == Bit:_and(lastCard.data,0x0F) and color == Bit:_and(lastCard.data,0xF0) then
                    table.insert(tempTable, lastCard)
                    table.insert(tempTable, var)
                    lastCard = nil
                end
                lastCard = var
            end
        end
    end
    --dump(tempTable, '对子数组:')
    return tempTable
end

function SDHTableLayer:reconnectSurrender(pBuffer)
    local isSurrender = false
    for i,v in ipairs(pBuffer.bSurrenderUser) do
        if v ~= 0 then
            isSurrender = true
            break
        end
    end

    if isSurrender then
        local path = self:requireClass('SDHSurrenderLayer')
        local node = require("app.MyApp"):create(pBuffer):createGame(path)
        self:addChild(node)
        node:setName('SDHSurrenderLayer')
    end
end

return SDHTableLayer