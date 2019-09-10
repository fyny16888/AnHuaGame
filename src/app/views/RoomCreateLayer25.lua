local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventType = require("common.EventType")
local Bit = require("common.Bit")

local RoomCreateLayer = class("RoomCreateLayer", cc.load("mvc").ViewBase)

function RoomCreateLayer:onEnter()
    EventMgr:registListener(EventType.SUB_CL_FRIENDROOM_CONFIG,self,self.SUB_CL_FRIENDROOM_CONFIG)
    EventMgr:registListener(EventType.SUB_CL_FRIENDROOM_CONFIG_END,self,self.SUB_CL_FRIENDROOM_CONFIG_END)
end

function RoomCreateLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_FRIENDROOM_CONFIG,self,self.SUB_CL_FRIENDROOM_CONFIG)
    EventMgr:unregistListener(EventType.SUB_CL_FRIENDROOM_CONFIG_END,self,self.SUB_CL_FRIENDROOM_CONFIG_END)
end

function RoomCreateLayer:onCleanup()

end

function RoomCreateLayer:onCreate(parameter)
    self.wKindID  = parameter[1]
    self.showType = parameter[2]
    self.dwClubID = parameter[3]
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomCreateLayer25.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.recordCreateParameter = UserData.Game:readCreateParameter(self.wKindID)
    if self.recordCreateParameter == nil then
        self.recordCreateParameter = {}
    end
    
    local uiListView_create = ccui.Helper:seekWidgetByName(self.root,"ListView_create")
    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    Common:addTouchEventListener(uiButton_create,function() self:onEventCreate(0) end)
    local uiButton_guild = ccui.Helper:seekWidgetByName(self.root,"Button_guild")
    Common:addTouchEventListener(uiButton_guild,function() self:onEventCreate(1) end)
    local uiButton_help = ccui.Helper:seekWidgetByName(self.root,"Button_help")
    Common:addTouchEventListener(uiButton_help,function() self:onEventCreate(-1) end)
    local uiButton_settings = ccui.Helper:seekWidgetByName(self.root,"Button_settings")
    Common:addTouchEventListener(uiButton_settings,function() self:onEventCreate(-2) end)
    if self.showType ~= nil and self.showType == 1 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        
    elseif self.showType ~= nil and self.showType == 3 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(0)
        
    elseif self.showType ~= nil and self.showType == 2 then
        uiListView_create:removeItem(0)
        uiListView_create:removeItem(1)
        uiListView_create:removeItem(1)       
    else
        uiListView_create:removeItem(3)
        uiListView_create:removeItem(0)             

        if StaticData.Hide[CHANNEL_ID].btn11 ~= 1 then 
           uiListView_create:removeItem(uiListView_create:getIndex(uiButton_help))
        end 
    end
    uiListView_create:refreshView()
    uiListView_create:setContentSize(cc.size(uiListView_create:getInnerContainerSize().width,uiListView_create:getInnerContainerSize().height))
    uiListView_create:setPositionX(uiListView_create:getParent():getContentSize().width/2)
    
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    uiListView_parameterList:getItem(0):setVisible(false)
    Common:addCheckTouchEventListener(items)
    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
        local items  = uiPanel_wanFaContents:getChildren()
        if index == 2 then
            items[1]:setBright(false)
            items[1]:setEnabled(false)
            items[1]:setColor(cc.c3b(170,170,170))
            items[8]:setBright(false)
            items[8]:setVisible(false)   
            items[9]:setBright(false)
            items[9]:setVisible(false)     
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
            local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end  
            local uiText_desc = ccui.Helper:seekWidgetByName(items[9],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end  
        else
            items[1]:setEnabled(true)
            items[1]:setColor(cc.c3b(255,255,255))            
            items[9]:setEnabled(true)
            items[9]:setBright(false)
            items[9]:setVisible(true)
            items[9]:setColor(cc.c3b(255,255,255))            
            items[8]:setBright(false)
            items[8]:setVisible(true)
            if items[6]:isBright() == false then            
                items[8]:setEnabled(true)            
                items[8]:setColor(cc.c3b(255,255,255))
            end 
        end
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
    --首局红桃3必出
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[1]},true)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[1]:setBright(false)
        items[1]:setEnabled(false)
        items[1]:setColor(cc.c3b(170,170,170))
        items[9]:setBright(false)
        items[9]:setVisible(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
        local uiText_desc = ccui.Helper:seekWidgetByName(items[9],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end  
    else
        if (self.wKindID == 25 or self.wKindID == 76) and CHANNEL_ID ~= 20 and  CHANNEL_ID ~= 21 then
            if self.recordCreateParameter["bStartCard"] ~= nil and self.recordCreateParameter["bStartCard"] == 0 then
                items[1]:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
            else
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
            end
        else
            if self.recordCreateParameter["bStartCard"] ~= nil and self.recordCreateParameter["bStartCard"] == 19 then
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
            else
                items[1]:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(140,102,57))
                end
            end
        end
    end
    
    --炸弹可拆
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[2]},true,function(index) 
        if items[2]:isBright() then
            items[4]:setEnabled(true)
            items[4]:setColor(cc.c3b(255,255,255))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
        else
            items[4]:setBright(false)
            items[4]:setEnabled(false)
            items[4]:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
        end
    end)
    if self.recordCreateParameter["bBombSeparation"] ~= nil and self.recordCreateParameter["bBombSeparation"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[2]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
        items[4]:setBright(false)
        items[4]:setEnabled(false)
        items[4]:setColor(cc.c3b(170,170,170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    
    --红桃十可扎鸟
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[3]},true)
    if self.recordCreateParameter["bRed10"] ~= nil and self.recordCreateParameter["bRed10"] == 1 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[3]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    
    --是否可4带3
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[4]},true)
    if self.recordCreateParameter["b4Add3"] ~= nil and self.recordCreateParameter["b4Add3"] == 1 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    elseif self.recordCreateParameter["bBombSeparation"] ~= nil and self.recordCreateParameter["bBombSeparation"] == 0 then
        items[4]:setBright(false)
        items[4]:setEnabled(false)
        items[4]:setColor(cc.c3b(170,170,170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    else
        items[4]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    
    --是否显示牌数量
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[5]},true)
    if self.recordCreateParameter["bShowCardCount"] ~= nil and self.recordCreateParameter["bShowCardCount"] == 1 then
        items[5]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[5]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    
    --春天的最小数量
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[6]},true, function(index)   
        if items[6]:isBright() then
            items[8]:setBright(false)
            items[8]:setEnabled(false)
            items[8]:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end
        else            
            items[8]:setEnabled(true)
            items[8]:setColor(cc.c3b(255,255,255))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(140,102,57))
            end          
        end
    end)
    if self.recordCreateParameter["bSpringMinCount"] ~= nil and self.recordCreateParameter["bSpringMinCount"] == 10 then
        items[6]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[6]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[6],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    
    --放跑包赔
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[7]},true)
    if self.recordCreateParameter["bAbandon"] ~= nil and self.recordCreateParameter["bAbandon"] == 1 then
        items[7]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[7],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[7]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[7],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    
    if CHANNEL_ID == 6 or CHANNEL_ID == 7 then
        items[7]:setVisible(false)
        items[7]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[7],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end        
    end

    --假春天
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()  --or (self.recordCreateParameter["bSpringMinCount"] ~= nil and self.recordCreateParameter["bSpringMinCount"] == 10) 
    Common:addCheckTouchEventListener({items[8]},true)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[8]:setBright(false)
        items[8]:setEnabled(false)
        items[8]:setVisible(false)
        items[8]:setColor(cc.c3b(170,170,170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    elseif self.recordCreateParameter["bSpringMinCount"] ~= nil and self.recordCreateParameter["bSpringMinCount"] == 10 then
        items[8]:setBright(false)
        items[8]:setEnabled(false)
        items[8]:setVisible(false)
        items[8]:setColor(cc.c3b(170,170,170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    elseif self.recordCreateParameter["bFalseSpring"] ~= nil and self.recordCreateParameter["bFalseSpring"] == 1 then
        items[8]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[8]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end

    --防作弊
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[9]},true)
    if self.recordCreateParameter["bCheating"] ~= nil and self.recordCreateParameter["bCheating"] == 1 then
        items[9]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[9],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[9]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[9],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end

    --15秒场
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    Common:addCheckTouchEventListener({items[10]},true)
    if self.recordCreateParameter["bAutoOutCard"] ~= nil and self.recordCreateParameter["bAutoOutCard"] == 1 then
        items[10]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[10],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    else
        items[10]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[10],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(140,102,57))
        end
    end
    

    if self.showType == 3 then
        self.tableFriendsRoomParams = {[1] = {wGameCount = 1}}
        self:SUB_CL_FRIENDROOM_CONFIG_END()
    else
        UserData.Game:sendMsgGetFriendsRoomParam(self.wKindID)
    end
end



function RoomCreateLayer:SUB_CL_FRIENDROOM_CONFIG(event)
    local data = event._usedata
    if data.wKindID ~= self.wKindID then
        return
    end
    if self.tableFriendsRoomParams == nil then
        self.tableFriendsRoomParams = {}
    end
    self.tableFriendsRoomParams[data.dwIndexes] = data
end

function RoomCreateLayer:SUB_CL_FRIENDROOM_CONFIG_END(event)
    if self.tableFriendsRoomParams == nil then
        return
    end
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    local uiListView_parameter = uiListView_parameterList:getItem(0)
    uiListView_parameter:setVisible(true)
    local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
    local isFound = false
    for key, var in pairs(items) do
        local data = self.tableFriendsRoomParams[key]
    	if data then
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            uiText_desc:setString(string.format("%d局",data.wGameCount))
            local uiText_addition = ccui.Helper:seekWidgetByName(var,"Text_addition")
            if data.dwExpendType == 1 then
                uiText_addition:setString(string.format("金币x%d",data.dwExpendCount))
            elseif data.dwExpendType == 2 then
                uiText_addition:setString(string.format("元宝x%d",data.dwExpendCount))
            elseif data.dwExpendType == 3 then
                if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
                    uiText_addition:setString(string.format("(钻石x%d)",data.dwExpendCount)) 
                else
                    uiText_addition:setString(string.format("(%sx%d)",StaticData.Items[data.dwSubType].name,data.dwExpendCount)) 
                end  
            else
                uiText_addition:setString("(无消耗)")
            end
            if isFound == false and self.recordCreateParameter["wGameCount"] ~= nil and self.recordCreateParameter["wGameCount"] == data.wGameCount then
                var:setBright(true)
                isFound = true
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(238,105,40))
                end
            end
    	else
    	   var:setBright(false)
           var:setVisible(false)
           local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
           if uiText_desc ~= nil then 
               uiText_desc:setTextColor(cc.c3b(140,102,57))
           end
    	end
    end
    if isFound == false and items[1]:isVisible() then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(238,105,40))
        end
    end
end

function RoomCreateLayer:onEventCreate(nTableType)
    NetMgr:getGameInstance():closeConnect()
    local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
    local tableParameter = {}
    --选择局数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(0),"ListView_parameter"):getItems()
    if items[1]:isBright() and self.tableFriendsRoomParams[1] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[1].wGameCount
    elseif items[2]:isBright() and self.tableFriendsRoomParams[2] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[2].wGameCount
    elseif items[3]:isBright() and self.tableFriendsRoomParams[3] then
        tableParameter.wGameCount = self.tableFriendsRoomParams[3].wGameCount
    else
        return
    end
    --选择人数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bPlayerCount = 3
    elseif items[2]:isBright() then
        tableParameter.bPlayerCount = 2
    else
        return
    end
    local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    local items  = uiPanel_wanFaContents:getChildren()
    --首局出牌要求
    if items[1]:isBright() then
        tableParameter.bStartCard = 0x13
    else
        tableParameter.bStartCard = 0
    end
    --炸弹是否可拆
    if items[2]:isBright() then
        tableParameter.bBombSeparation = 1
    else
        tableParameter.bBombSeparation = 0
    end
    --红桃十可扎鸟
    if items[3]:isBright() then
        tableParameter.bRed10 = 1
    else
        tableParameter.bRed10 = 0
    end
    --是否可4带3
    if items[4]:isBright() then
        tableParameter.b4Add3 = 1
    else
        tableParameter.b4Add3 = 0
    end
    --是否显示牌数量
    if items[5]:isBright() then
        tableParameter.bShowCardCount = 1
    else
        tableParameter.bShowCardCount = 0
    end
    --红桃十可扎鸟
    if items[6]:isBright() then
        tableParameter.bSpringMinCount = 10
    else
        if self.wKindID == 25 or self.wKindID == 76  then
            tableParameter.bSpringMinCount = 15
        else
            tableParameter.bSpringMinCount = 16
        end
    end
    --放跑包赔
    if items[7]:isBright() then
        tableParameter.bAbandon = 1
    else
        tableParameter.bAbandon = 0
    end
    --假春天
    if items[8]:isBright() then
        tableParameter.bFalseSpring = 1
    else
        tableParameter.bFalseSpring = 0
    end

    --防作弊
    if items[9]:isBright() then
        tableParameter.bCheating = 1
    else
        tableParameter.bCheating = 0
    end

    --15秒场
    if items[10]:isBright() then
        tableParameter.bAutoOutCard = 1
    else
        tableParameter.bAutoOutCard = 0
    end

   if self.showType ~= 2 and nTableType == TableType_FriendRoom then
        --普通创房和代开需要判断金币
        local uiListView_parameterList = ccui.Helper:seekWidgetByName(self.root,"ListView_parameterList")
        local uiListView_parameter = uiListView_parameterList:getItem(0)
        local items = ccui.Helper:seekWidgetByName(uiListView_parameter,"ListView_parameter"):getItems()
        for key, var in pairs(items) do
            if var:isBright() then
                local data = self.tableFriendsRoomParams[key]
                if data.dwExpendType == 0 then--无消耗
                elseif data.dwExpendType == 1 then--金币
                    if UserData.User.dwGold  < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足,请前往商城充值？",function()             require("app.views.NewXXMallLayer"):create(2) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的金币不足!")
                        end
                        return
                end  
                elseif data.dwExpendType == 2 then--元宝
                    if UserData.User.dwIngot  < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的元宝不足,请前往商城购买？",function()             require("app.views.NewXXMallLayer"):create(2) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的元宝不足!")
                        end
                        return
                end 
                elseif data.dwExpendType == 3 then--道具
                    local itemCount = UserData.Bag:getBagPropCount(data.dwSubType)
                    if itemCount < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的道具不足,请前往商城购买?",function()             require("app.views.NewXXMallLayer"):create(2) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的道具不足!")
                        end
                        return
                    end
                else
                    return
                end
                break
            end
        end
    end

    UserData.Game:saveCreateParameter(self.wKindID,tableParameter)

    --亲友圈自定义创房
    if self.showType == 2 then
        local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
        uiButton_create:removeAllChildren()
        local img = ccui.ImageView:create("newcommon/ft_btn_createroom.png")
        uiButton_create:addChild(img,1000)
        img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height/2)
        uiButton_create:addChild(require("app.MyApp"):create(TableType_ClubRoom,1,self.wKindID,tableParameter.wGameCount,self.dwClubID,tableParameter):createView("InterfaceCreateRoomNode"))
        return
    end 
    --设置亲友圈   
    if nTableType == TableType_ClubRoom then
        EventMgr:dispatch(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,{wKindID = self.wKindID,wGameCount = tableParameter.wGameCount,tableParameter = tableParameter})      
        return
    end

    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    uiButton_create:removeAllChildren()
    local img = ccui.ImageView:create("newcommon/ft_btn_createroom.png")
    uiButton_create:addChild(img,1000)
    img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height/2)
    uiButton_create:addChild(require("app.MyApp"):create(nTableType,0,self.wKindID,tableParameter.wGameCount,UserData.Guild.dwPresidentID,tableParameter):createView("InterfaceCreateRoomNode"))

end

return RoomCreateLayer

