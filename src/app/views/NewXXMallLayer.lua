local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Bit = require("common.Bit")
local HttpUrl = require("common.HttpUrl")

local NewXXMallLayer = class("NewXXMallLayer", cc.load("mvc").ViewBase)

function NewXXMallLayer:onEnter()
    EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:registListener(EventType.EVENT_TYPE_RECHARGE_PAY_RESULT,self,self.EVENT_TYPE_RECHARGE_PAY_RESULT)
    EventMgr:registListener(EventType.RET_MALL_EXCHANGE_REDENVELOPE,self,self.RET_MALL_EXCHANGE_REDENVELOPE)
    --EventMgr:registListener(EventType.RET_GET_MALL_LOG,self,self.RET_GET_MALL_LOG)
    EventMgr:registListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
    
end

function NewXXMallLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:unregistListener(EventType.EVENT_TYPE_RECHARGE_PAY_RESULT,self,self.EVENT_TYPE_RECHARGE_PAY_RESULT)
    EventMgr:unregistListener(EventType.RET_MALL_EXCHANGE_REDENVELOPE,self,self.RET_MALL_EXCHANGE_REDENVELOPE)
    --EventMgr:unregistListener(EventType.RET_GET_MALL_LOG,self,self.RET_GET_MALL_LOG)
    EventMgr:unregistListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
    if self.uiListView_gold then
        self.uiListView_gold:release()
        self.uiListView_gold = nil
    end
    if self.uiPanel_gold then
        self.uiPanel_gold:release()
        self.uiPanel_gold = nil
    end
    -- if self.uiPanel_redEnvelope then
    --     self.uiPanel_redEnvelope:release()
    --     self.uiPanel_redEnvelope = nil
    -- end
    if self.uiPanel_malllog then
        self.uiPanel_malllog:release()
        self.uiPanel_malllog = nil
    end
end

function NewXXMallLayer:onCreate(parames)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("NewXXMallLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        self:removeFromParent()
    end)  
    
    local uiListView_TypeBtn = ccui.Helper:seekWidgetByName(self.root,"ListView_TypeBtn")
    local items = uiListView_TypeBtn:getItems()
    for k,v in pairs(items) do
        Common:addTouchEventListener(v,function()
            self:showUI(k)
        end)
    end
    
    local uiListView_items1 = ccui.Helper:seekWidgetByName(self.root,"ListView_items1")
    uiListView_items1:removeAllItems()
    local uiListView_items2 = ccui.Helper:seekWidgetByName(self.root,"ListView_items2")
    uiListView_items2:removeAllItems()
    local uiListView_items3 = ccui.Helper:seekWidgetByName(self.root,"ListView_items3")
    uiListView_items3:removeAllItems()

    self.uiListView_gold = ccui.Helper:seekWidgetByName(self.root,"ListView_gold")
    self.uiListView_gold:retain()
    self.uiPanel_gold = ccui.Helper:seekWidgetByName(self.root,"Panel_gold")
    self.uiPanel_gold:retain()
    self.uiListView_gold:removeAllItems()
    -- self.uiPanel_redEnvelope = ccui.Helper:seekWidgetByName(self.root,"Panel_redEnvelope")
    -- self.uiPanel_redEnvelope:retain()
    -- self.uiListView_gold:removeAllItems()
    -- local uiListView_malllog = ccui.Helper:seekWidgetByName(self.root,"ListView_malllog")
    -- self.uiPanel_malllog = ccui.Helper:seekWidgetByName(self.root,"Panel_malllog")
    -- self.uiPanel_malllog:retain()
    -- uiListView_malllog:removeAllItems()
    -- uiListView_malllog.wPageCount = 0
    -- uiListView_malllog:onScroll(function(event)
    --     if event.name == "SCROLL_TO_BOTTOM" then
    --         if uiListView_malllog.loading == true or uiListView_malllog.finish == true then
    --             return
    --         end
    --         uiListView_malllog.loading = true
    --         uiListView_malllog.wPageCount = uiListView_malllog.wPageCount + 1
    --         UserData.Mall:sendMsgGetRequestmallRecord(uiListView_malllog.wPageCount)
    --     end
    -- end)
    
    self:updateUserInfo()
    self:showUI(parames[1])
end

function NewXXMallLayer:showUI(index)
    local uiListView_items1 = ccui.Helper:seekWidgetByName(self.root,"ListView_items1")
    local uiListView_items2 = ccui.Helper:seekWidgetByName(self.root,"ListView_items2")
    local uiListView_items3 = ccui.Helper:seekWidgetByName(self.root,"ListView_items3")
    local uiImage_wandou = ccui.Helper:seekWidgetByName(self.root,"Image_wandou")
    local uiImage_hongbao = ccui.Helper:seekWidgetByName(self.root,"Image_hongbao")
    local uiImage_guizhe = ccui.Helper:seekWidgetByName(self.root,"Image_guizhe")
    local uiListView_TypeBtn = ccui.Helper:seekWidgetByName(self.root,"ListView_TypeBtn")
    local items = uiListView_TypeBtn:getItems()
    if index == 2 then
        uiImage_wandou:loadTexture("newmall/gmwd.png")  
        uiImage_hongbao:loadTexture("newmall/gmfk1.png")
        uiImage_guizhe:loadTexture("newmall/gmyb.png")
        uiListView_items1:setVisible(false)
        uiListView_items2:setVisible(true)
        uiListView_items3:setVisible(false)
        for key, var in pairs(items) do
            if key == 2 then
                var:setBright(true)
            else
                var:setBright(false)
            end
        end
        
        uiListView_items2:removeAllChildren()
        local tableMall = {}
        if UserData.Mall.tableMallConfig[1] ~= nil then
            tableMall = clone(UserData.Mall.tableMallConfig[1])
        else
            return
        end
        local uiListView_item = nil
        for k,v in pairs(tableMall) do
            if (k-1) % 4 == 0 then
                uiListView_item = self.uiListView_gold:clone()
                uiListView_items2:pushBackCustomItem(uiListView_item)
            end
            local item = self.uiPanel_gold:clone()
            uiListView_item:pushBackCustomItem(item)
            local uiImage_gold = ccui.Helper:seekWidgetByName(item, "Image_gold")
            local textureName = string.format("newmall/%d.png",v.dwGoodsID)
            if textureName ~= nil then
                uiImage_gold:loadTexture(textureName)
            else
                uiImage_gold:setVisible(false)
            end
            local uiText_gold = ccui.Helper:seekWidgetByName(item, "Text_gold")
            uiText_gold:setTextColor(cc.c3b(167,70,21))
            uiText_gold:setString(v.szTitle)
            local uiText_addition = ccui.Helper:seekWidgetByName(item, "Text_addition")
            uiText_addition:setTextColor(cc.c3b(255,0,0))
            if v.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[v.dwGoodsID] ~= nil then
                uiText_addition:setString(string.format("首充赠送%d房卡",v.lFirst))
            elseif v.lGift > 0 then
                uiText_addition:setString(string.format("赠送%d房卡",v.lGift))
            else
                uiText_addition:setString("")
            end
            local uiText_money = ccui.Helper:seekWidgetByName(item, "Text_money")
            uiText_money:setTextColor(cc.c3b(247,240,214))
            uiText_money:setString(string.format("%d元",v.lPrice))
            local function onEventBuy(sender,event)
            	self.goodsData = v
                local data = clone(UserData.Share.tableShareParameter[7])
                UserData.Mall:doPay(2,self.goodsData.dwGoodsID,UserData.User.userID,string.format(data.szShareUrl,self.goodsData.dwGoodsID,UserData.User.userID))
            end
            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item, "Button_buy"),onEventBuy)
            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item, "Button_money"),onEventBuy)
        end
        
    elseif index == 3 then
        uiImage_wandou:loadTexture("newmall/gmwd.png")  
        uiImage_hongbao:loadTexture("newmall/gmfk.png")
        uiImage_guizhe:loadTexture("newmall/gmyb1.png")
        uiListView_items1:setVisible(false)
        uiListView_items2:setVisible(false)
        uiListView_items3:setVisible(true)
        for key, var in pairs(items) do
            if key == 3 then
                var:setBright(true)
            else
                var:setBright(false)
            end
        end
        
        uiListView_items3:removeAllChildren()
        local tableMall = {}
        if UserData.Mall.tableMallConfig[2] ~= nil then
            tableMall = clone(UserData.Mall.tableMallConfig[2])
        else
            return
        end
        local uiListView_item = nil
        for k,v in pairs(tableMall) do
            if (k-1) % 4 == 0 then
                uiListView_item = self.uiListView_gold:clone()
                uiListView_items3:pushBackCustomItem(uiListView_item)
            end
            local item = self.uiPanel_gold:clone()
            uiListView_item:pushBackCustomItem(item)
            local uiImage_gold = ccui.Helper:seekWidgetByName(item, "Image_gold")
            local textureName = string.format("newmall/%d.png",v.dwGoodsID)
            if textureName ~= nil then
                uiImage_gold:loadTexture(textureName)
            else
                uiImage_gold:setVisible(false)
            end
            local uiText_gold = ccui.Helper:seekWidgetByName(item, "Text_gold")
            uiText_gold:setTextColor(cc.c3b(167,70,21))
            uiText_gold:setString(v.szTitle)
            local uiText_addition = ccui.Helper:seekWidgetByName(item, "Text_addition")
            uiText_addition:setTextColor(cc.c3b(255,0,0))
            if v.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[v.dwGoodsID] ~= nil then
                uiText_addition:setString(string.format("首充赠送%d元宝",v.lFirst))
            elseif v.lGift > 0 then
                uiText_addition:setString(string.format("赠送%d元宝",v.lGift))
            else
                uiText_addition:setString("")
            end
            local uiText_money = ccui.Helper:seekWidgetByName(item, "Text_money")
            uiText_money:setTextColor(cc.c3b(247,240,214))
            uiText_money:setString(string.format("%d元",v.lPrice))
            local function onEventBuy(sender,event)
            	self.goodsData = v
                local data = clone(UserData.Share.tableShareParameter[7])
                UserData.Mall:doPay(2,self.goodsData.dwGoodsID,UserData.User.userID,string.format(data.szShareUrl,self.goodsData.dwGoodsID,UserData.User.userID))
            end
            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item, "Button_buy"),onEventBuy)
            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item, "Button_money"),onEventBuy)
        end
    else
        uiImage_wandou:loadTexture("newmall/gmwd1.png")  
        uiImage_hongbao:loadTexture("newmall/gmfk.png")
        uiImage_guizhe:loadTexture("newmall/gmyb.png")
        uiListView_items1:setVisible(true)
        uiListView_items2:setVisible(false)
        uiListView_items3:setVisible(false)
        for key, var in pairs(items) do
            if key == 1 then
                var:setBright(true)
            else
                var:setBright(false)
            end
        end
        
        uiListView_items1:removeAllChildren()
        local tableMall = {}
        if UserData.Mall.tableMallConfig[0] ~= nil then
            tableMall = clone(UserData.Mall.tableMallConfig[0])
        else
            return
        end
        local uiListView_item = nil
        for k,v in pairs(tableMall) do
            if (k-1) % 4 == 0 then
                uiListView_item = self.uiListView_gold:clone()
                uiListView_items1:pushBackCustomItem(uiListView_item)
            end
            local item = self.uiPanel_gold:clone()
            uiListView_item:pushBackCustomItem(item)
            local uiImage_gold = ccui.Helper:seekWidgetByName(item, "Image_gold")
            local textureName = string.format("newmall/%d.png",v.dwGoodsID)
            if textureName ~= nil then
                uiImage_gold:loadTexture(textureName)
            else
                uiImage_gold:setVisible(false)
            end
            local uiText_gold = ccui.Helper:seekWidgetByName(item, "Text_gold")
            uiText_gold:setTextColor(cc.c3b(167,70,21))
            uiText_gold:setString(v.szTitle)
            local uiText_addition = ccui.Helper:seekWidgetByName(item, "Text_addition")
            uiText_addition:setTextColor(cc.c3b(255,0,0))
            if v.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[v.dwGoodsID] ~= nil then
                uiText_addition:setString(string.format("首充赠送%d玩豆",v.lFirst))
            elseif v.lGift > 0 then
                uiText_addition:setString(string.format("赠送%d玩豆",v.lGift))
            else
                uiText_addition:setString("")
            end
            local uiText_money = ccui.Helper:seekWidgetByName(item, "Text_money")
            uiText_money:setTextColor(cc.c3b(247,240,214))
            uiText_money:setString(string.format("%d元",v.lPrice))
            local function onEventBuy(sender,event)
            	self.goodsData = v
                local data = clone(UserData.Share.tableShareParameter[7])
                UserData.Mall:doPay(2,self.goodsData.dwGoodsID,UserData.User.userID,string.format(data.szShareUrl,self.goodsData.dwGoodsID,UserData.User.userID))
            end
            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item, "Button_buy"),onEventBuy)
            Common:addTouchEventListener(ccui.Helper:seekWidgetByName(item, "Button_money"),onEventBuy)
        end
    end
end

function NewXXMallLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

function NewXXMallLayer:updateUserInfo()
    local uiImage_avatar = ccui.Helper:seekWidgetByName(self.root,"Image_avatar")
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")    
    uiText_name:setString(string.format("%s",UserData.User.szNickName))
    local uiText_ID = ccui.Helper:seekWidgetByName(self.root,"Text_ID")
    uiText_ID:setString(string.format("ID:%d",UserData.User.userID))
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiImage_avatar,"img")
    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   
    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")    
    uiText_gold:setString(string.format("%s",Common:itemNumberToString(UserData.User.dwGold)))   
    local uiText_money = ccui.Helper:seekWidgetByName(self.root,"Text_money")    
    uiText_money:setString(string.format("%d",UserData.Bag:getBagPropCount(1008)))  

end

function NewXXMallLayer:EVENT_TYPE_RECHARGE_PAY_RESULT(event)
    local data = event._usedata
    if data ~= 0 then
       closeLoadingAnimationLayer()
       require("common.MsgBoxLayer"):create(0,nil,"充值失败！")
       return
    end
    local goodsData = clone(self.goodsData)
    
    local tableReward = {}
    if goodsData.cbTargetUnit == 0 then
        table.insert(tableReward, #tableReward+1, {wPropID = 1001,dwPropCount = goodsData.lCount})
        if goodsData.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[goodsData.dwGoodsID] ~= nil then
            table.insert(tableReward, #tableReward+1, {wPropID = 1001,dwPropCount = goodsData.lFirst})
        elseif goodsData.lGift > 0 then
            table.insert(tableReward, #tableReward+1, {wPropID = 1001,dwPropCount = goodsData.lGift})
        else
        end
        require("common.RewardLayer"):create("充值成功！",nil,tableReward)
    elseif goodsData.cbTargetUnit == 1 then
        table.insert(tableReward, #tableReward+1, {wPropID = 1003,dwPropCount = goodsData.lCount})
        if goodsData.lFirst > 0 and UserData.Mall.tableMallFirstChargeRecord[goodsData.dwGoodsID] ~= nil then
            table.insert(tableReward, #tableReward+1, {wPropID = 1003,dwPropCount = goodsData.lFirst})
        elseif goodsData.lGift > 0 then
            table.insert(tableReward, #tableReward+1, {wPropID = 1003,dwPropCount = goodsData.lGift})
        end
        require("common.RewardLayer"):create("充值成功！",nil,tableReward)
    else
        
    end
    
    UserData.Mall.tableMallFirstChargeRecord[goodsData.dwGoodsID] = nil
    local uiListView_TypeBtn = ccui.Helper:seekWidgetByName(self.root,"ListView_TypeBtn")
    local items = uiListView_TypeBtn:getItems()
    for key, var in pairs(items) do
        if var:isBright() then
            self:showUI(key)
        end
    end
    UserData.User:sendMsgUpdateUserInfo(1)
end

function NewXXMallLayer:RET_MALL_EXCHANGE_REDENVELOPE(event)
    local data = event._usedata
    if data.Result == 0 then 
        require("common.MsgBoxLayer"):create(0,nil,"兑换成功,可在兑换记录中查收兑换码！")
        UserData.User:sendMsgUpdateUserInfo(1)
        self:showUI(4)
    elseif data.Result == 1 then 
        require("common.MsgBoxLayer"):create(0,nil,"玩家不存在!")
    elseif data.Result == 2 then 
        require("common.MsgBoxLayer"):create(0,nil,"商品不存在!")
    elseif data.Result == 3 then 
        require("common.MsgBoxLayer"):create(0,nil,"红包券不足!")      
    elseif data.Result == 4 then 
        require("common.MsgBoxLayer"):create(0,nil,"您今天已兑换过!")  
    end 
end 

-- function NewXXMallLayer:RET_GET_MALL_LOG(event)
--     local data = event._usedata
--     local uiListView_malllog = ccui.Helper:seekWidgetByName(self.root,"ListView_malllog")
--     local item = self.uiPanel_malllog:clone()
--     uiListView_malllog:pushBackCustomItem(item)
--     local uiText_name = ccui.Helper:seekWidgetByName(item,"Text_name")
--     uiText_name:setColor(cc.c3b(131,88,45))
--     uiText_name:setString(string.format("微信%d元红包",data.lCount))
--     local uiText_time = ccui.Helper:seekWidgetByName(item,"Text_time")
--     uiText_time:setColor(cc.c3b(131,88,45))
--     local date = os.date("*t",data.dwCreateTime)
--     uiText_time:setString(string.format("%d-%02d-%02d\n%02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
--     local uiText_id = ccui.Helper:seekWidgetByName(item,"Text_id")
--     uiText_id:setColor(cc.c3b(131,88,45))
--     uiText_id:setString(data.szExchangeCode)
--     local uiText_status = ccui.Helper:seekWidgetByName(item,"Text_status")
--     uiText_status:setColor(cc.c3b(236,100,54))
--     local uiButton_copy = ccui.Helper:seekWidgetByName(item,"Button_copy")
--     Common:addTouchEventListener(uiButton_copy,function() 
--         UserData.User:copydata(data.szExchangeCode) 
--         require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
--     end)
--     if data.wStatus == 1 then
--         uiText_status:setVisible(true)
--         uiButton_copy:setVisible(false)
--     elseif data.wStatus == 2 then
--         uiText_status:setVisible(false)
--         uiButton_copy:setVisible(true)
--     else
--         uiButton_copy:setVisible(false)
--         uiText_status:setVisible(false)
--     end
-- end 

function NewXXMallLayer:RET_GET_MALL_LOG_FINISH(event)
    local data = event._usedata 
    local uiListView_malllog = ccui.Helper:seekWidgetByName(self.root,"ListView_malllog")
    uiListView_malllog.loading = false
    uiListView_malllog.finish = data.lRet
end

return NewXXMallLayer