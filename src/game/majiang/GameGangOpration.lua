local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local Bit = require("common.Bit")
local GameLogic = require("game.majiang.GameLogic")
local GameCommon = require("game.majiang.GameCommon")

local GameGangOpration = class("GameGangOpration",function()
    return ccui.Layout:create()
end)

function GameGangOpration:create(pBuffer,opTtype)
    local view = GameGangOpration.new()
    view:onCreate(pBuffer,opTtype)
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

function GameGangOpration:onEnter()
    
end

function GameGangOpration:onExit()
    if self.uiPanel_opration then
        self.uiPanel_opration:release()
        self.uiPanel_opration = nil
    end
end

function GameGangOpration:onCreate(pBuffer)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("KwxGameLayerMaJiang_Operation.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    uiListView_Opration:removeAllItems()
    uiListView_Opration:setVisible(true)
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    self.uiPanel_opration = uiListView_OprationType:getItem(0)
    self.uiPanel_opration:retain()
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(false)
    GameCommon.IsOfHu =0
    self:showOpration(pBuffer)
    local uiPanel_pengBG = ccui.Helper:seekWidgetByName(self.root,"Panel_pengBG")
    uiPanel_pengBG:setVisible(false)
    
    uiListView_Opration:refreshView()
    uiListView_Opration:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_Opration:getInnerContainerSize().width)
    uiListView_Opration:setDirection(ccui.ScrollViewDir.none)
end

function GameGangOpration:showOpration(pBuffer)

    -- pBuffer.tableChiCard = {} 
    -- pBuffer.tablePengCard = {} 
    -- pBuffer.tableGangCard = {}
    -- pBuffer.tableBuCard = {}
    -- pBuffer.tableHuCard = {}

    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local mUserWCWDActionEx = 0
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    --吃
    if pBuffer.tableChiCard[1]~= nil then
        -- if Bit:_and(cbOperateCode,GameCommon.WIK_LEFT) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_CENTER) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_RIGHT) ~= 0 then
        local img = "game/op_chi.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)        
        Common:addTouchEventListener(item,function()             
            self:dealChi(pBuffer)
        end)
        -- end
    end 
    --碰
    if pBuffer.tablePengCard[1]~= nil then
        local img = "game/op_peng.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealPeng(pBuffer)
        end)
    end 
    --补
    if pBuffer.tableBuCard[1]~= nil then
        local img = "game/op_bu.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealBu(pBuffer)
        end)
    end
    --杠 
    if pBuffer.tableGangCard[1]~= nil then
        local img = "game/op_gang.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealGang(pBuffer)
        end)
    end 
    --胡
    if pBuffer.tableHuCard[1]~= nil then
        GameCommon.IsOfHu = 1
        local img = "game/op_hu.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealHu(pBuffer)
        end)
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xuanzhuanxing/xuanzhuanxing.ExportJson")
        local armature=ccs.Armature:create("xuanzhuanxing")
        armature:getAnimation():playWithIndex(0)
        item:addChild(armature)
        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
    end 

    --必胡

    if pBuffer.tableBiHuCard[1]~= nil then
        local img = "game/op_hu.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealBiHu(pBuffer)
        end)
        -- if GameCommon.tableConfig.wKindID == 50 or  GameCommon.tableConfig.wKindID == 70 then 
        --     self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) self:dealBiHu(pBuffer) end)))
        -- end 
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xuanzhuanxing/xuanzhuanxing.ExportJson")
        local armature=ccs.Armature:create("xuanzhuanxing")
        armature:getAnimation():playWithIndex(0)
        item:addChild(armature)
        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
    else
        --过
        local img = "game/op_guo.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            print('-->>>>>>>xxxx',GameCommon.IsOfHu)
            if GameCommon.IsOfHu == 1 then 
                require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,GameCommon.bUserOpreaCount)  
                    self:removeFromParent()         
                end)   
            else
                self:removeFromParent()
            end 
        end)
    end
    for key, var in pairs(uiListView_Opration:getItems()) do
        var:setScale(0.0)
        var:runAction(cc.Sequence:create(cc.Sequence:create(cc.ScaleTo:create(0.2, 0.8))))
    end
end

function GameGangOpration:dealChi(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableChiCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableChiCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end
    
    if #tableChiCard == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableChiCard[1].cbWeaveKind,tableChiCard[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableChiCard) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            local cbCardList = {}
            if Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                cbCardList = {var.cbCenterCard,var.cbCenterCard+1,var.cbCenterCard+2}
            elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_CENTER) ~= 0 then
                cbCardList = {var.cbCenterCard-1,var.cbCenterCard,var.cbCenterCard+1}
            elseif Bit:_and(var.cbWeaveKind,GameCommon.WIK_RIGHT) ~= 0 then
                cbCardList = {var.cbCenterCard-2,var.cbCenterCard-1,var.cbCenterCard}
            end
            for k, v in pairs(cbCardList) do
                local card = GameCommon:getDiscardCardAndWeaveItemArray(v)     
                item:addChild(card)
                card:setScale(cardScale) 
                card:setPosition(cardWidth/2+(k-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)              
                        self:removeFromParent()
                    end
                end)
            end
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealPeng(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tablePengCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tablePengCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tablePengCard,#tablePengCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end

    if #tablePengCard == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tablePengCard[1].cbWeaveKind,tablePengCard[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tablePengCard) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            local cbCardList = {var.cbCenterCard,var.cbCenterCard,var.cbCenterCard}
            for k, v in pairs(cbCardList) do
                local card = GameCommon:getDiscardCardAndWeaveItemArray(v)     
                item:addChild(card)
                card:setScale(cardScale) 
                card:setPosition(cardWidth/2+(k-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        self:removeFromParent()
                    end
                end)
            end
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealBu(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableBuCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableWeaveItem = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableWeaveItem,#tableWeaveItem+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end
    if #tableWeaveItem == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableWeaveItem) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            for i = 1, 4 do
                local card = nil
                if var.cbPublicCard == 2 and i < 4 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(var.cbCenterCard)     
                end
                item:addChild(card)
                if i == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(2-1)*cardWidth+28,card:getParent():getContentSize().height/2+10)
                else
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(i-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                end
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        self:removeFromParent()
                    end
                end)
            end
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealGang(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableGangCard
    local uiPanel_pengBG = ccui.Helper:seekWidgetByName(self.root,"Panel_pengBG")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(uiPanel_pengBG,"Button_return"),function() 
        uiPanel_pengBG:setVisible(false)
    end)
    self.uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")   
    self.uiListView_OprationType:retain()  
    local uiListView_OprationAllType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationAllType")
    uiListView_OprationAllType:removeAllChildren()
    local uiListView_list0  = nil  
    local uiListView_list1  = nil 
    -- local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    -- uiListView_OprationType:removeAllChildren()
    --uiListView_OprationType:setVisible(true)
    local wChairID = GameCommon:getRoleChairID()
    local cbCardCount = GameCommon.player[wChairID].cbCardCount
    local cbCardData = GameCommon.player[wChairID].cbCardData
    local bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount
    local WeaveItemArray = GameCommon.player[wChairID].WeaveItemArray
    local tableWeaveItem = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableWeaveItem,#tableWeaveItem+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end
    if #tableWeaveItem > 1 then 
        uiListView_list0 = self.uiListView_OprationType:clone() 
        uiListView_list0:removeAllChildren()
        uiListView_list0:setVisible(true)   
        uiListView_OprationAllType:pushBackCustomItem(uiListView_list0)  
        if #tableWeaveItem > 2 then 
            uiListView_list1 = self.uiListView_OprationType:clone()  
            uiListView_list1:removeAllChildren()
            uiListView_list1:setVisible(true)     
            uiListView_OprationAllType:pushBackCustomItem(uiListView_list1)                
        end  
    end  
    if #tableWeaveItem == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 81 * cardScale
        local cardHeight = 114 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableWeaveItem) do
            local item = self.uiPanel_opration:clone()
            if key <= 2 then 
                uiListView_list0:pushBackCustomItem(item)
            else
                uiListView_list1:pushBackCustomItem(item)               
            end 
            for i = 1, 4 do
                local card = nil
                if var.cbPublicCard == 2 and i < 4 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0)
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(var.cbCenterCard)     
                end
                item:addChild(card)
                if i == 4 then
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(2-1)*cardWidth+20,card:getParent():getContentSize().height/2+10)
                else
                    card:setScale(cardScale) 
                    card:setPosition(cardWidth/2+(i-1)*cardWidth+20,card:getParent():getContentSize().height/2)
                end
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        self:removeFromParent()
                    end
                end)
            end
        end
        if  uiListView_list0 ~= nil then 
            uiListView_list0:refreshView()          
            uiListView_list0:setContentSize(cc.size(uiListView_list0:getInnerContainerSize().width,uiListView_list0:getInnerContainerSize().height)) 
            print("+++++++大小++++++++",uiListView_list0:getInnerContainerSize().width)
            if  uiListView_list1 ~= nil then
                uiListView_list1:refreshView()
                uiListView_list1:setContentSize(cc.size(uiListView_list1:getInnerContainerSize().width,uiListView_list1:getInnerContainerSize().height)) 
            end     
        end 

        if #uiListView_OprationAllType:getItems() > 0 then
            local height = 0
            local width = 0
            for key, var in pairs(uiListView_OprationAllType:getItems()) do
                height = height + var:getContentSize().height            
            end                    
            width = uiListView_list0:getContentSize().width              
            uiListView_OprationAllType:refreshView()
            print("+++++++大小++",width,height)
            uiListView_OprationAllType:setContentSize(cc.size(width,height))
        end
 

        -- uiListView_OprationType:refreshView()
        -- uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.5-uiListView_OprationType:getInnerContainerSize().width/2)
        -- uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
end

function GameGangOpration:dealHu(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableHuCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableHuCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableHuCard,#tableHuCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end

    if #tableHuCard == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_CHI_HU,tableHuCard[1].cbCenterCard)
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 60 * cardScale
        local cardHeight = 85 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableHuCard) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            local card = GameCommon:getDiscardCardAndWeaveItemArray(var.cbCenterCard)     
            item:addChild(card)
            card:setScale(cardScale) 
            card:setPosition(cardWidth/2+(k-1)*cardWidth+28,card:getParent():getContentSize().height/2)
            item:addTouchEventListener(function(sender,event)
                if event == ccui.TouchEventType.ended then
                    Common:palyButton()
                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_CHI_HU,var.cbCenterCard)
                    self:removeFromParent()
                end
            end) 
        end
        uiListView_OprationType:refreshView()
        uiListView_OprationType:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_OprationType:getInnerContainerSize().width)
        uiListView_OprationType:setDirection(ccui.ScrollViewDir.none)
    end
   -- self:removeFromParent()    
end

function GameGangOpration:dealBiHu(pBuffer)
    local wResumeUser = pBuffer.wResumeUser
    local tableActionCard = pBuffer.tableBiHuCard
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableHuCard = {}
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do    
            table.insert(tableHuCard,#tableHuCard+1,{cbWeaveKind =var.cbOperateCode,cbCenterCard = var.tableActionCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end

    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_BIHU,tableHuCard[1].cbCenterCard)
    
    self:removeFromParent()  
end

return GameGangOpration