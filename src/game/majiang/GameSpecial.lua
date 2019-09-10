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

function GameOpration:create(pBuffer)
    local view = GameOpration.new()
    view:onCreate(pBuffer)
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

end

function GameOpration:onCreate(pBuffer)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerMaJiang_Special.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    uiPanel_contents:setVisible(false)
    uiPanel_contents:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            uiPanel_contents:setVisible(false)
        end
    end)
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    uiListView_Opration:removeAllItems()
    uiListView_Opration:setVisible(true)
    
    for i = 1, 6 do
        local item = ccui.Helper:seekWidgetByName(self.root,string.format("Button_item%d",i))
        item:setVisible(false)
        Common:addTouchEventListener(item,function() 
            self:sendSpecialCard(item.cbUserAction,item.cbCardData)
        end)
    end
    self:showSpecialCard(pBuffer)
    
    uiListView_Opration:refreshView()
    uiListView_Opration:setPositionX(cc.Director:getInstance():getVisibleSize().width*0.82-uiListView_Opration:getInnerContainerSize().width)
    uiListView_Opration:setDirection(ccui.ScrollViewDir.none)
end

function GameOpration:sendSpecialCard(cbUserAction,cbCardData)
    local net = NetMgr:getGameInstance()
    if net.connected == false then
        return
    end
    if cbCardData == nil then
        cbCardData = {}
    end
    for i = #cbCardData + 1, 14 do
        cbCardData[i] = 0
    end
    net.cppFunc:beginSendBuf(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_Xihu)
    net.cppFunc:writeSendBool(true,0)
    net.cppFunc:writeSendWORD(cbUserAction,0)
    for i = 1, 14 do
        net.cppFunc:writeSendByte(cbCardData[i],0)
    end
    net.cppFunc:endSendBuf()
    net.cppFunc:sendSvrBuf()
end

function GameOpration:showSpecialCard(pBuffer)
    local wActionUser = pBuffer.wActionUser
    local cbUserAction = pBuffer.cbUserAction
    local cbCardData = pBuffer.cbCardData
    local uiListView_Opration = ccui.Helper:seekWidgetByName(self.root,"ListView_Opration")
    
    --四喜胡牌
    if Bit:_and(cbUserAction,GameCommon.CHK_SIXI_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_dasixi.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:switchSiXi(cbCardData)
        end)
    end
    --无将胡牌
    if Bit:_and(cbUserAction,GameCommon.CHK_BANBAN_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_wujianghu.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:sendSpecialCard(GameCommon.CHK_BANBAN_HU)
            self:removeFromParent()
        end)
    end
    --六六顺牌
    if Bit:_and(cbUserAction,GameCommon.CHK_LIULIU_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_liuliushun.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:switchLiuLiu(cbCardData)
        end)
    end
    --缺一色牌
    if Bit:_and(cbUserAction,GameCommon.CHK_QUEYISE_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_queyise.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:sendSpecialCard(GameCommon.CHK_QUEYISE_HU)
            self:removeFromParent()
        end)
    end
    --步步高牌
    if Bit:_and(cbUserAction,GameCommon.CHK_BUBUGAO_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_bubugao.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:switchBuBuGao(cbCardData)
        end)
    end
    --三同牌
    if Bit:_and(cbUserAction,GameCommon.CHK_SANTONG_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_santong.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function() 
            self:switchSanTong(cbCardData)
        end)
    end
    --一枝花牌
    if Bit:_and(cbUserAction,GameCommon.CHK_YIZHIHUA_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_yizhihua.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function()
            self:sendSpecialCard(GameCommon.CHK_YIZHIHUA_HU)
            self:removeFromParent()
        end)
    end
    --中途四喜
    if Bit:_and(cbUserAction,GameCommon.CHK_ZTSX_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/qs_zhongtusx.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function()
            self:sendSpecialCard(GameCommon.CHK_ZTSX_HU)
            self:removeFromParent()
        end)
    end

    --中途六六顺
    if Bit:_and(cbUserAction,GameCommon.CHK_ZTLLS_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_zhongtull.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function()
            self:sendSpecialCard(GameCommon.CHK_ZTLLS_HU)
            self:removeFromParent()
        end)
    end

    --金童玉女
    if Bit:_and(cbUserAction,GameCommon.CHK_JTYN_HU) ~= 0 then
        local img = "majiang/ui/operatechangsha/op_jintyn.png"
        local item = ccui.Button:create(img,img,img)
        item:setScale(0.8)
        uiListView_Opration:pushBackCustomItem(item)
        Common:addTouchEventListener(item,function()
            self:sendSpecialCard(GameCommon.CHK_JTYN_HU)
            self:removeFromParent()
        end)
    end
    
    --过
    local img = "majiang/ui/operate/n_playLabel_8.png"
    local item = ccui.Button:create(img,img,img)
    item:setScale(0.8)
    uiListView_Opration:pushBackCustomItem(item)
    Common:addTouchEventListener(item,function() 
        print('->>>>>>>>>>>>>>>>>>>>>xxxxxxxxxxxxxxxxx')
        self:sendSpecialCard(GameCommon.WIK_NULL)
        self:removeFromParent()
    end)
end

function GameOpration:switchSiXi(cbCardData)
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    local index = 0
    local size = ccui.Helper:seekWidgetByName(self.root,"Button_item1"):getContentSize()
    local nCardStackCount = 4
    local cardScale = 0.6
    local cardWidth = 81 * cardScale
    local cardHeight = 118 * cardScale
    local step = cardWidth+10
    local beganX = (size.width - nCardStackCount * step) / 2
    local tableSameCard = {}
    for key, var in pairs(cbCardData) do
        if var ~= 0 then
            if tableSameCard[var] == nil then
                tableSameCard[var] = 1
            else
                tableSameCard[var] = tableSameCard[var] + 1
            end
        end
    end
    for i = 1, 55 do
        if tableSameCard[i] == nil then
            tableSameCard[i] = 0
        end
    end
    for key, var in pairs(tableSameCard) do
        if var == 4 then
            index = index + 1
            local item = ccui.Helper:seekWidgetByName(self.root,string.format("Button_item%d",index))
            item:setVisible(true)
            local cbCardDataTemp = {}
            cbCardDataTemp[1] = key
            for i = 1 , 4 do
                local card = nil
                if i <= 4 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[1])  
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0)     
                end
                item:addChild(card)
                card:setScale(cardScale)
                card:setPosition(beganX + i*step - step/2,size.height/2)
            end
            item.cbUserAction = GameCommon.CHK_SIXI_HU
            item.cbCardData = cbCardDataTemp
        end
    end
    if index == 1 then
        local item = ccui.Helper:seekWidgetByName(self.root,"Button_item1")
        self:sendSpecialCard(item.cbUserAction,item.cbCardData)
    else
        uiPanel_contents:setVisible(true)
    end
end

function GameOpration:switchLiuLiu(cbCardData)
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    local index = 0
    local size = ccui.Helper:seekWidgetByName(self.root,"Button_item1"):getContentSize()
    local nCardStackCount = 6
    local cardScale = 0.6
    local cardWidth = 81 * cardScale
    local cardHeight = 118 * cardScale
    local step = cardWidth
    local beganX = (size.width - nCardStackCount * step) / 2
    local tableSameCard = {}
    for key, var in pairs(cbCardData) do
        if var ~= 0 then
            if tableSameCard[var] == nil then
                tableSameCard[var] = 1
            else
                tableSameCard[var] = tableSameCard[var] + 1
            end
        end
    end
    for i = 1, 55 do
        if tableSameCard[i] == nil then
            tableSameCard[i] = 0
        end
    end
    for key, var in pairs(tableSameCard) do
        if var >= 3 then
            for k, v in pairs(tableSameCard) do
                if k > key and v >= 3 then
                    index = index + 1
                    local item = ccui.Helper:seekWidgetByName(self.root,string.format("Button_item%d",index))
                    item:setVisible(true)
                    local cbCardDataTemp = {}
                    cbCardDataTemp[1] = key
                    cbCardDataTemp[2] = k
                    for i = 1 , 6 do
                        local card = nil
                        if i <= 3 then
                            card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[1])  
                        elseif i <= 6 then
                            card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[2])  
                        else
                            card = GameCommon:getDiscardCardAndWeaveItemArray(0)     
                        end
                        item:addChild(card)
                        card:setScale(cardScale)
                        card:setPosition(beganX + i*step - step/2,size.height/2)
                    end
                    item.cbUserAction = GameCommon.CHK_LIULIU_HU
                    item.cbCardData = cbCardDataTemp
                end
            end
        end
    end
    if index == 1 then
        local item = ccui.Helper:seekWidgetByName(self.root,"Button_item1")
        self:sendSpecialCard(item.cbUserAction,item.cbCardData)
    else
        uiPanel_contents:setVisible(true)
    end
end

function GameOpration:switchBuBuGao(cbCardData)
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    local index = 0
    local size = ccui.Helper:seekWidgetByName(self.root,"Button_item1"):getContentSize()
    local nCardStackCount = 6
    local cardScale = 0.6
    local cardWidth = 81 * cardScale
    local cardHeight = 118 * cardScale
    local step = cardWidth
    local beganX = (size.width - nCardStackCount * step) / 2
    local tableSameCard = {}
    for key, var in pairs(cbCardData) do
        if var ~= 0 then
            if tableSameCard[var] == nil then
                tableSameCard[var] = 1
            else
                tableSameCard[var] = tableSameCard[var] + 1
            end
        end
    end
    for i = 1, 55 do
        if tableSameCard[i] == nil then
            tableSameCard[i] = 0
        end
    end
    for key, var in pairs(tableSameCard) do
        if key > 2 and tableSameCard[key] >= 2 and tableSameCard[key-1] >= 2 and tableSameCard[key-2] >= 2 then
            index = index + 1
            local item = ccui.Helper:seekWidgetByName(self.root,string.format("Button_item%d",index))
            item:setVisible(true)
            local cbCardDataTemp = {}
            cbCardDataTemp[1] = key-2
            cbCardDataTemp[2] = key-1
            cbCardDataTemp[3] = key-0
            for i = 1 , 6 do
                local card = nil
                if i <= 2 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[1])  
                elseif i <= 4 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[2])  
                elseif i <= 6 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[3]) 
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0)     
                end
                item:addChild(card)
                card:setScale(cardScale)
                card:setPosition(beganX + i*step - step/2,size.height/2)
            end
            item.cbUserAction = GameCommon.CHK_BUBUGAO_HU
            item.cbCardData = cbCardDataTemp
        end
    end
    if index == 1 then
        local item = ccui.Helper:seekWidgetByName(self.root,"Button_item1")
        self:sendSpecialCard(item.cbUserAction,item.cbCardData)
    else
        uiPanel_contents:setVisible(true)
    end
end

function GameOpration:switchSanTong(cbCardData)
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    local index = 0
    local size = ccui.Helper:seekWidgetByName(self.root,"Button_item1"):getContentSize()
    local nCardStackCount = 6
    local cardScale = 0.6
    local cardWidth = 81 * cardScale
    local cardHeight = 118 * cardScale
    local step = cardWidth
    local beganX = (size.width - nCardStackCount * step) / 2
    local tableSameCard = {}
    for key, var in pairs(cbCardData) do
        if tableSameCard[var] == nil then
            tableSameCard[var] = 1
        else
            tableSameCard[var] = tableSameCard[var] + 1
        end
    end
    for i = 1, 55 do
        if tableSameCard[i] == nil then
            tableSameCard[i] = 0
        end
    end
    for i = 1, 9 do
        local card1 = i
        local card2 = Bit:_or(0x10,i)
        local card3 = Bit:_or(0x20,i)
        if tableSameCard[card1] >= 2 and tableSameCard[card2] >= 2 and tableSameCard[card3] >= 2 then
            index = index + 1
            local item = ccui.Helper:seekWidgetByName(self.root,string.format("Button_item%d",index))
            item:setVisible(true)
            local cbCardDataTemp = {}
            cbCardDataTemp[1] = card1
            cbCardDataTemp[2] = card2
            cbCardDataTemp[3] = card3
            for i = 1 , 6 do
                local card = nil
                if i <= 2 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[1])  
                elseif i <= 4 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[2])  
                elseif i <= 6 then
                    card = GameCommon:getDiscardCardAndWeaveItemArray(cbCardDataTemp[3]) 
                else
                    card = GameCommon:getDiscardCardAndWeaveItemArray(0)     
                end
                item:addChild(card)
                card:setScale(cardScale)
                card:setPosition(beganX + i*step - step/2,size.height/2)
            end
            item.cbUserAction = GameCommon.CHK_SANTONG_HU
            item.cbCardData = cbCardDataTemp
        end
    end
    if index == 1 then
        local item = ccui.Helper:seekWidgetByName(self.root,"Button_item1")
        self:sendSpecialCard(item.cbUserAction,item.cbCardData)
    else
        uiPanel_contents:setVisible(true)
    end
end

return GameOpration