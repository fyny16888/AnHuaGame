local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local Bit = require("common.Bit")
local GameLogic = require("game.majiang.GameLogic")
local GameCommon = require("game.majiang.GameCommon")

local GameOpration = class("GameOpration",function()
    return ccui.Layout:create()
end)

function GameOpration:create(pBuffer,opTtype)
    local view = GameOpration.new()
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

function GameOpration:onEnter()
    
end

function GameOpration:onExit()
    if self.uiPanel_opration then
        self.uiPanel_opration:release()
        self.uiPanel_opration = nil
    end
    GameCommon.IsOfHu = 0
end

function GameOpration:onCreate(pBuffer,opTtype)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("KwxGameLayerMaJiang_Operation.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    GameCommon.IsOfHu = 0
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    uiListView_Opration:removeAllItems()
    uiListView_Opration:setVisible(true)
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationType")
    self.uiPanel_opration = uiListView_OprationType:getItem(0)
    self.uiPanel_opration:retain()
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(false)
    if opTtype == 1 then
        self:showHaiDi(pBuffer)
    elseif opTtype == 2 then
        self:showWCWD(pBuffer)
    elseif opTtype == 3 then
        self:showBIHUXIAOHU(pBuffer)
    else
        self:showOpration(pBuffer)
    end
    local uiPanel_pengBG = ccui.Helper:seekWidgetByName(self.root,"Panel_pengBG")
    uiPanel_pengBG:setVisible(false)

    local uiListView_OprationTypes = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationTypes")
    uiListView_OprationTypes:setVisible(false)

    uiListView_Opration:refreshView()
    uiListView_Opration:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_Opration:getInnerContainerSize().width)
    uiListView_Opration:setDirection(ccui.ScrollViewDir.none)
end

function GameOpration:showOpration(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local mUserWCWDActionEx = 0
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    --吃
    if Bit:_and(cbOperateCode,GameCommon.WIK_LEFT) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_CENTER) ~= 0 or Bit:_and(cbOperateCode,GameCommon.WIK_RIGHT) ~= 0 then
        local img = "majiang/ui/operate/n_playLabel_4.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)        
        Common:addTouchEventListener(item,function() 

            if GameCommon.IsOfHu == 1 then
                require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
                    if (pBuffer.cbActionCard >= 49 and pBuffer.cbActionCard <= 55) and GameCommon.tableConfig.wKindID == 65 then
                        self:deal65Chi(pBuffer)
                    else                
                        self:dealChi(pBuffer)
                    end
                end)  
            else
                if (pBuffer.cbActionCard >= 49 and pBuffer.cbActionCard <= 55) and GameCommon.tableConfig.wKindID == 65 then
                    self:deal65Chi(pBuffer)
                else                
                    self:dealChi(pBuffer)
                end
            end
        end)
    end
    --碰
    if Bit:_and(cbOperateCode,GameCommon.WIK_PENG) ~= 0 then
        local img = "majiang/ui/operate/n_playLabel_9.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            if GameCommon.IsOfHu == 1 then
                require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
                    self:dealPeng(pBuffer)
                end)   
            else
                self:dealPeng(pBuffer)
            end
        end)
    end
    --补
    if Bit:_and(cbOperateCode,GameCommon.WIK_FILL) ~= 0 then
        local img = "majiang/ui/operate/n_playLabel_3.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealBu(pBuffer)
        end)
    end
    --杠
    if Bit:_and(cbOperateCode,GameCommon.WIK_GANG) ~= 0 then
        local img = "majiang/ui/operate/n_playLabel_6.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            if GameCommon.IsOfHu == 1 then --如果是胡
                require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
                    self:dealGang(pBuffer)
                end)   
            else
                self:dealGang(pBuffer)
            end
        end)
    end


    local isShowMing = true
    if GameCommon.tableConfig then
        if GameCommon.tableConfig.wKindID == 73 then --牌蹲少于12张不显示名
            if GameCommon.cbLeftCardCount < 12 then
                isShowMing = false
            end
        end
    end

    -- --明牌
    -- if Bit:_and(cbOperateCode,GameCommon.WIK_MING_PAI) ~= 0
    -- and isShowMing then
    --     local img = "majiang/ui/operate/n_playLabel_5.png"
    --     local item = ccui.Button:create(img,img,img)
    --     uiListView_Opration:pushBackCustomItem(item)
    --     Common:addTouchEventListener(item,function() 

    --         if GameCommon.IsOfHu == 1 then --如果是胡牌
    --             require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
    --                 EventMgr:dispatch(EventType.EVENT_TYPE_MINGPAI)
    --             end)   
    --         else
    --             EventMgr:dispatch(EventType.EVENT_TYPE_MINGPAI)
    --         end
    --     end)
    -- end

    --胡
    if Bit:_and(cbOperateCode,GameCommon.WIK_CHI_HU) ~= 0 then
        local img = "majiang/ui/operate/n_playLabel_17.png"
        GameCommon.IsOfHu = 1
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealHu(pBuffer)
        end)
        if  pBuffer.mUserWCWDActionEx ~= nil then 
            mUserWCWDActionEx = pBuffer.mUserWCWDActionEx
        end 
        if Bit:_and(GameCommon.cbOperateCode,GameCommon.WIK_WD) ~= 0  or mUserWCWDActionEx == 1   then
            -- if pBuffer.cbActionCard == 65 then
            --     local img = ccui.ImageView:create("yongzhou/table/end_play_wcw.png")
            --     item:addChild(img)
            --     img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
            -- else
                local img = ccui.ImageView:create("yongzhou/ui/end_play_wangdiao.png")
                item:addChild(img)
                img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
            -- end

        elseif Bit:_and(GameCommon.cbOperateCode,GameCommon.WIK_WC) ~= 0   or mUserWCWDActionEx == 2  then
            -- if pBuffer.cbActionCard == 65 then
            --     local img = ccui.ImageView:create("zipai/table/end_play_wangdiaowang.png")
            --     item:addChild(img)
            --     img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
            -- else
                local img = ccui.ImageView:create("yongzhou/ui/end_play_wangchuang.png")
                item:addChild(img)
                img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height)
            -- end
        else
        end

        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xuanzhuanxing/xuanzhuanxing.ExportJson")
        local armature=ccs.Armature:create("xuanzhuanxing")
        armature:getAnimation():playWithIndex(0)
        item:addChild(armature)
        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)

    end

  

    --必胡
    if Bit:_and(cbOperateCode,GameCommon.WIK_BIHU) ~= 0 then
        local img = "majiang/ui/operate/n_playLabel_17.png"
        GameCommon.IsOfHu = 1
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:dealBiHu(pBuffer)
        end)
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/xuanzhuanxing/xuanzhuanxing.ExportJson")
        local armature=ccs.Armature:create("xuanzhuanxing")
        armature:getAnimation():playWithIndex(0)
        item:addChild(armature)
        armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
    elseif #uiListView_Opration:getItems() >= 1 then
        --过
        local img = "majiang/ui/operate/n_playLabel_8.png"
        local item = ccui.Button:create(img,img,img)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            print('-->>>>>>>>>>>>>112xxxxxxx',GameCommon.IsOfHu)
            if GameCommon.IsOfHu == 1 then 
                require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
                    print('-->>>sendxxxx')
                    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)
                    self:removeFromParent()         
                end)   
            else
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)
                self:removeFromParent()
            end 
        end)
    end



    for key, var in pairs(uiListView_Opration:getItems()) do
        var:setScale(0.0)
        var:runAction(cc.Sequence:create(cc.Sequence:create(cc.ScaleTo:create(0, 1))))
    end
end

function GameOpration:showHaiDi()
    --海底
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    local img = "game/op_yaohaidi.png"
    local item = ccui.Button:create(img,img,img)
    uiListView_Opration:pushBackCustomItem(item)
    Common:addTouchEventListener(item,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_HAIDI,"wo",GameCommon:getRoleChairID(),true)
        self:removeFromParent()
    end)
    --过
    local img = "majiang/ui/operate/n_playLabel_8.png"
    local item = ccui.Button:create(img,img,img)
    uiListView_Opration:pushBackCustomItem(item)
    Common:addTouchEventListener(item,function()
        if GameCommon.IsOfHu == 1 then 
            require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)  --GameCommon.bUserOpreaCount
                self:removeFromParent()         
            end)   
        else
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_HAIDI,"wo",GameCommon:getRoleChairID(),false)
            self:removeFromParent()
        end 
    end)
    for key, var in pairs(uiListView_Opration:getItems()) do
        var:setScale(0.0)
        var:runAction(cc.Sequence:create(cc.Sequence:create(cc.ScaleTo:create(0, 1))))
    end
end

function GameOpration:showWCWD(pBuffer)
      --王闯王钓      
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.mWCWDOperate
    GameCommon.cbOperateCode = 0
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
   
    if Bit:_and(cbOperateCode,GameCommon.WIK_WC) ~= 0 then--王闯
        GameCommon.cbOperateCode = GameCommon.WIK_WC
        local img = "game/op_wangchuang.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_WDWC,"w",2)
            self:removeFromParent()
        end)
    else
        if Bit:_and(cbOperateCode,GameCommon.WIK_WD) ~= 0 then--王钓
            GameCommon.cbOperateCode = GameCommon.WIK_WD
            local img = "game/op_wangdiao.png"
            local item = ccui.Button:create(img,img,img)
            item:setScale(0.8)
            uiListView_Opration:pushBackCustomItem(item)
            Common:addTouchEventListener(item,function() 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_WDWC,"w",1)
                self:removeFromParent()
            end)
        end
    end

    --过
    local img ="majiang/ui/operate/n_playLabel_8.png"
    local item = ccui.Button:create(img,img,img)
    uiListView_Opration:pushBackCustomItem(item)
    Common:addTouchEventListener(item,function() 
        -- NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_WDWC,"w",0)
        -- self:removeFromParent()
        if GameCommon.IsOfHu == 1 then 
            require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function() 
                print('-->>>sendxxxx')
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)
                self:removeFromParent()         
            end)   
        else
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_WDWC,"w",0)
            self:removeFromParent()
        end 

    end)
    for key, var in pairs(uiListView_Opration:getItems()) do
        var:setScale(0.0)
        var:runAction(cc.Sequence:create(cc.Sequence:create(cc.ScaleTo:create(0, 1))))
    end
end 

function GameOpration:showBIHUXIAOHU(pBuffer)
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    local img = "majiang/ui/operate/n_playLabel_17.png"
    local item = ccui.Button:create(img,img,img)
    item:setScale(0.8)
    uiListView_Opration:pushBackCustomItem(item)
    Common:addTouchEventListener(item,function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_StartHu,"w",pBuffer.wCurUser)
        self:removeFromParent()
    end)

end 
function GameOpration:dealChi(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local wResumeUser = pBuffer.wResumeUser
    local bIsSelf = pBuffer.bIsSelf
    local tableActionCard = pBuffer.tableActionCard
    
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationTypes")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableChiCard = {}
    if tableActionCard ~= nil then
        local wChairID = GameCommon:getRoleChairID()
        local cbCardCount = GameCommon.player[wChairID].cbCardCount
        local cbCardData = GameCommon.player[wChairID].cbCardData
        for key, var in pairs(tableActionCard) do
            local cbCardList = {[var-2] = 0,[var-1] = 0,[var+1] = 0,[var+2] = 0}
            for i = 1, cbCardCount do
                if cbCardList[cbCardData[i]] ~= nil then
                    cbCardList[cbCardData[i]] = cbCardList[cbCardData[i]] + 1
                end
            end
            if cbCardList[var+1] > 0 and cbCardList[var+2] > 0 and (tableActionCard[2] == nil or (var+1 ~= tableActionCard[2] and var+2 ~= tableActionCard[2])) then
                table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_LEFT,cbCenterCard = var, cbPublicCard = 0,wProvideUser = wResumeUser})
            end
            if cbCardList[var-1] > 0 and cbCardList[var+1] > 0 and (tableActionCard[2] == nil or (var-1 ~= tableActionCard[2] and var+1 ~= tableActionCard[2])) then
                table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_CENTER,cbCenterCard = var, cbPublicCard = 0,wProvideUser = wResumeUser})
            end
            if cbCardList[var-2] > 0 and cbCardList[var-1] > 0 and (tableActionCard[2] == nil or (var-2 ~= tableActionCard[2] and var-1 ~= tableActionCard[2])) then
                table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_RIGHT,cbCenterCard = var, cbPublicCard = 0,wProvideUser = wResumeUser})
            end
        end
    else
        if Bit:_and(cbOperateCode,GameCommon.WIK_LEFT) ~= 0 then
            table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_LEFT,cbCenterCard = cbOperateCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
        if Bit:_and(cbOperateCode,GameCommon.WIK_CENTER) ~= 0 then
            table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_CENTER,cbCenterCard = cbOperateCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
        if Bit:_and(cbOperateCode,GameCommon.WIK_RIGHT) ~= 0 then
            table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_RIGHT,cbCenterCard = cbOperateCard, cbPublicCard = 0,wProvideUser = wResumeUser})
        end
    end
    
    if #tableChiCard == 1 then
        if GameCommon.tableConfig.wKindID == 65 then 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",tableChiCard[1].cbWeaveKind,tableChiCard[1].cbCenterCard,0,0,0)
        else
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableChiCard[1].cbWeaveKind,tableChiCard[1].cbCenterCard)
        end
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 81 * cardScale
        local cardHeight = 114 * cardScale
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
                        if GameCommon.tableConfig.wKindID == 65 then 
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",var.cbWeaveKind,var.cbCenterCard,0,0,0)
                        else
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        end                 
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

function GameOpration:deal65Chi(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local wResumeUser = pBuffer.wResumeUser
    local bIsSelf = pBuffer.bIsSelf
    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationTypes")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tableChiCard = {}
    local wChairID = GameCommon:getRoleChairID()
    local cbCardCount = GameCommon.player[wChairID].cbCardCount
    local cbCardData = GameCommon.player[wChairID].cbCardData
    local cbCardList = {[49] = 0,[50] = 0,[51] = 0,[52] = 0,[53] = 0,[54] = 0,[55] = 0}
    for i = 1, cbCardCount do
        if cbCardList[cbCardData[i]] ~= nil then
            cbCardList[cbCardData[i]] = cbCardList[cbCardData[i]] + 1
        end
    end
    cbCardList[cbOperateCard] = cbCardList[cbOperateCard]+1 
    if(cbCardList[49]~= 0 and cbCardList[50]~= 0 and cbCardList[51]~= 0 )and (cbOperateCard == 49 or cbOperateCard == 50 or cbOperateCard == 51 or cbOperateCard == 70 or cbOperateCard == 80) then 
        local ChiCard = {}
        ChiCard[1] = 49 
        ChiCard[2] = 50 
        ChiCard[3] = 51 
        table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_LEFT,cbCenterCard = cbOperateCard,m_ChiCard = ChiCard ,cbPublicCard = 0,wProvideUser = wResumeUser})
    end     
    if(cbCardList[49]~= 0 and cbCardList[50]~= 0 and cbCardList[52]~= 0 )and (cbOperateCard == 49 or cbOperateCard == 50 or cbOperateCard == 52 or cbOperateCard == 70 or cbOperateCard == 80) then 
        local ChiCard = {}
        ChiCard[1] = 49 
        ChiCard[2] = 50 
        ChiCard[3] = 52 
        table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_LEFT,cbCenterCard = cbOperateCard,m_ChiCard = ChiCard ,cbPublicCard = 0,wProvideUser = wResumeUser})
    end    
    if(cbCardList[49]~= 0 and cbCardList[51]~= 0 and cbCardList[52]~= 0 )and (cbOperateCard == 49 or cbOperateCard == 51 or cbOperateCard == 52) then 
        local ChiCard = {}
        ChiCard[1] = 49 
        ChiCard[2] = 51 
        ChiCard[3] = 52
        table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_LEFT,cbCenterCard = cbOperateCard,m_ChiCard = ChiCard ,cbPublicCard = 0,wProvideUser = wResumeUser})
    end    
    if(cbCardList[50]~= 0 and cbCardList[51]~= 0 and cbCardList[52]~= 0 )and (cbOperateCard == 50 or cbOperateCard == 51 or cbOperateCard == 52 or cbOperateCard == 70 or cbOperateCard == 80) then 
        local ChiCard = {}
        ChiCard[1] = 50 
        ChiCard[2] = 51 
        ChiCard[3] = 52 
        table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_LEFT,cbCenterCard = cbOperateCard,m_ChiCard = ChiCard ,cbPublicCard = 0,wProvideUser = wResumeUser})
    end
    
    if(cbCardList[53]~= 0 and cbCardList[54]~= 0 and cbCardList[55]~= 0 )and (cbOperateCard == 53 or cbOperateCard == 54 or cbOperateCard == 55) then 
        local ChiCard = {}
        ChiCard[1] = 53 
        ChiCard[2] = 54 
        ChiCard[3] = 55 
        table.insert(tableChiCard,#tableChiCard+1,{cbWeaveKind = GameCommon.WIK_LEFT,cbCenterCard = cbOperateCard,m_ChiCard = ChiCard ,cbPublicCard = 0,wProvideUser = wResumeUser})
    end

    if #tableChiCard == 1 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",tableChiCard[1].cbWeaveKind,tableChiCard[1].cbCenterCard,tableChiCard[1].m_ChiCard[1],tableChiCard[1].m_ChiCard[2],tableChiCard[1].m_ChiCard[3])
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 81 * cardScale
        local cardHeight = 114 * cardScale
        local beganX = cardWidth/2
        local beganY = cardHeight/2
        local stepX = cardWidth*3
        local stepY = 0
        for key, var in pairs(tableChiCard) do
            local item = self.uiPanel_opration:clone()
            uiListView_OprationType:pushBackCustomItem(item)
            local cbCardList = {}
            if Bit:_and(var.cbWeaveKind,GameCommon.WIK_LEFT) ~= 0 then
                cbCardList = var.m_ChiCard         
            end
            for k, v in pairs(cbCardList) do
                local card = GameCommon:getDiscardCardAndWeaveItemArray(v)     
                item:addChild(card)
                card:setScale(cardScale) 
                card:setPosition(cardWidth/2+(k-1)*cardWidth+28,card:getParent():getContentSize().height/2)
                item:addTouchEventListener(function(sender,event)
                    if event == ccui.TouchEventType.ended then
                        Common:palyButton()
                        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",var.cbWeaveKind,var.cbCenterCard,cbCardList[1],cbCardList[2],cbCardList[3])
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

function GameOpration:dealPeng(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local wResumeUser = pBuffer.wResumeUser
    local bIsSelf = pBuffer.bIsSelf
    local tableActionCard = pBuffer.tableActionCard

    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationTypes")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local tablePengCard = {}
    if tableActionCard ~= nil then
        local wChairID = GameCommon:getRoleChairID()
        local cbCardCount = GameCommon.player[wChairID].cbCardCount
        local cbCardData = GameCommon.player[wChairID].cbCardData
        for key, var in pairs(tableActionCard) do
            local count = 0
            for i = 1, cbCardCount do
                if cbCardData[i] == var then
                    count = count + 1
                end
            end
            if count >= 2 and (#tablePengCard <= 0 or tablePengCard[1].cbCenterCard ~= var) then
                table.insert(tablePengCard,#tablePengCard+1,{cbWeaveKind = GameCommon.WIK_PENG,cbCenterCard = var, cbPublicCard = 0,wProvideUser = wResumeUser})
            end
        end
    else
        table.insert(tablePengCard,#tablePengCard+1,{cbWeaveKind = GameCommon.WIK_PENG,cbCenterCard = cbOperateCard, cbPublicCard = 0,wProvideUser = wResumeUser})
    end

    if #tablePengCard == 1 then
        if GameCommon.tableConfig.wKindID == 65 then 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",tablePengCard[1].cbWeaveKind,tablePengCard[1].cbCenterCard,0,0,0)
        else
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tablePengCard[1].cbWeaveKind,tablePengCard[1].cbCenterCard)
        end
        self:removeFromParent()
    else
        local cardScale = 0.8
        local cardWidth = 81 * cardScale
        local cardHeight = 114 * cardScale
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
                        if GameCommon.tableConfig.wKindID == 65 then 
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",var.cbWeaveKind,var.cbCenterCard,0,0,0)
                        else
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        end
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

function GameOpration:dealBu(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local wResumeUser = pBuffer.wResumeUser
    local bIsSelf = pBuffer.bIsSelf
    local tableActionCard = pBuffer.tableActionCard
    local cbGangCard = pBuffer.cbGangCard
    local cbBuCard = pBuffer.cbBuCard

    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationTypes")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    local wChairID = GameCommon:getRoleChairID()
    local cbCardCount = GameCommon.player[wChairID].cbCardCount
    local cbCardData = GameCommon.player[wChairID].cbCardData
    local bWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount
    local WeaveItemArray = GameCommon.player[wChairID].WeaveItemArray
    local tableWeaveItem = {}
    for key, var in pairs(cbBuCard) do
        if var ~= 0 then
            table.insert(tableWeaveItem,#tableWeaveItem+1,{cbWeaveKind = GameCommon.WIK_FILL,cbCenterCard = var, cbPublicCard = 1,wProvideUser = wResumeUser})
        end
    end
    if #tableWeaveItem == 1 then
        if GameCommon.tableConfig.wKindID == 65 then 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard,0,0,0)
        else
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard)
        end
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
                        if GameCommon.tableConfig.wKindID == 65 then 
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",var.cbWeaveKind,var.cbCenterCard,0,0,0)
                        else
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        end
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

function GameOpration:dealGang(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local wResumeUser = pBuffer.wResumeUser
    local bIsSelf = pBuffer.bIsSelf
    local tableActionCard = pBuffer.tableActionCard
    local cbGangCard = pBuffer.cbGangCard
    local cbBuCard = pBuffer.cbBuCard
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


    for key, var in pairs(cbGangCard) do
        if var ~= 0 then
            table.insert(tableWeaveItem,#tableWeaveItem+1,{cbWeaveKind = GameCommon.WIK_GANG,cbCenterCard = var, cbPublicCard = 1,wProvideUser = wResumeUser})
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
        if GameCommon.tableConfig.wKindID == 65 then 
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard,0,0,0)
        else
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",tableWeaveItem[1].cbWeaveKind,tableWeaveItem[1].cbCenterCard)
        end
        self:removeFromParent()
    else
        uiPanel_pengBG:setVisible(true)
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
                        if GameCommon.tableConfig.wKindID == 65 then 
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",var.cbWeaveKind,var.cbCenterCard,0,0,0)
                        else
                            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",var.cbWeaveKind,var.cbCenterCard)
                        end
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

function GameOpration:dealHu(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local wResumeUser = pBuffer.wResumeUser
    local bIsSelf = pBuffer.bIsSelf
    local tableActionCard = pBuffer.tableActionCard

    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationTypes")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do
            if GameCommon.tableConfig.wKindID == 65 then 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",GameCommon.WIK_CHI_HU,cbOperateCard,0,0,0)
            else
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_CHI_HU,var)
            end
            self:removeFromParent()
            return
        end
    end
    if GameCommon.tableConfig.wKindID == 65 then 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",GameCommon.WIK_CHI_HU,cbOperateCard,0,0,0)
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_CHI_HU,cbOperateCard)
    end
    self:removeFromParent()    
end

function GameOpration:dealBiHu(pBuffer)
    local cbOperateCard = pBuffer.cbActionCard
    local cbOperateCode = pBuffer.cbActionMask
    local wResumeUser = pBuffer.wResumeUser
    local bIsSelf = pBuffer.bIsSelf
    local tableActionCard = pBuffer.tableActionCard

    local uiListView_OprationType = ccui.Helper:seekWidgetByName(self.root,"ListView_OprationTypes")
    uiListView_OprationType:removeAllChildren()
    uiListView_OprationType:setVisible(true)
    if tableActionCard ~= nil then
        for key, var in pairs(tableActionCard) do
            if GameCommon.tableConfig.wKindID == 65 then 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",GameCommon.WIK_BIHU,var,0,0,0)
            else
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_BIHU,var)
            end
            self:removeFromParent()
            return
        end
    end
    if GameCommon.tableConfig.wKindID == 65 then 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wbbbb",GameCommon.WIK_BIHU,cbOperateCard,0,0,0)
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_BIHU,cbOperateCard)
    end
    self:removeFromParent()    
end

return GameOpration