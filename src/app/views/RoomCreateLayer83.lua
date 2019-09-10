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
    local csb = cc.CSLoader:createNode("RoomCreateLayer83.csb")
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
        -- local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
        -- local items  = uiPanel_wanFaContents:getChildren()
        -- if index == 2 then
        --     items[1]:setBright(false)
        --     items[1]:setEnabled(false)
        --     items[1]:setColor(cc.c3b(170,170,170))
        --     items[8]:setBright(false)
        --     items[8]:setVisible(false)   
        --     items[9]:setBright(false)
        --     items[9]:setVisible(false)     
        --     local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        --     if uiText_desc ~= nil then 
        --         uiText_desc:setTextColor(cc.c3b(109,58,44))
        --     end
        --     local uiText_desc = ccui.Helper:seekWidgetByName(items[8],"Text_desc")
        --     if uiText_desc ~= nil then 
        --         uiText_desc:setTextColor(cc.c3b(109,58,44))
        --     end  
        --     local uiText_desc = ccui.Helper:seekWidgetByName(items[9],"Text_desc")
        --     if uiText_desc ~= nil then 
        --         uiText_desc:setTextColor(cc.c3b(109,58,44))
        --     end  
        -- else
        --     items[1]:setEnabled(true)
        --     items[1]:setColor(cc.c3b(255,255,255))            
        --     items[9]:setEnabled(true)
        --     items[9]:setBright(false)
        --     items[9]:setVisible(true)
        --     items[9]:setColor(cc.c3b(255,255,255))            
        --     items[8]:setBright(false)
        --     items[8]:setVisible(true)
        --     if items[6]:isBright() == false then            
        --         items[8]:setEnabled(true)            
        --         items[8]:setColor(cc.c3b(255,255,255))
        --     end 
        -- end
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择张数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if index == 1 then
            uiText_desc:setString("三A炸弹")
        else
            uiText_desc:setString("三K炸弹")
        end  
    end)
    if self.recordCreateParameter["b15Or16"] ~= nil and self.recordCreateParameter["b15Or16"] == 1 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --选择必压
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"ListView_parameter"):getItems()
        if index == 2 then
            items[1]:setEnabled(true)
            items[1]:setColor(cc.c3b(255,255,255))            
            items[1]:setBright(true)
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(215,86,31))
            end
        else            
            items[1]:setBright(false)
            items[1]:setEnabled(false)
            items[1]:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(109,58,44))
            end
           
        end
    end)
    if self.recordCreateParameter["bMustOutCard"] ~= nil and self.recordCreateParameter["bMustOutCard"] == 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

    --可选
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)

    
    -- local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    -- local items  = uiPanel_wanFaContents:getChildren()
   -- Common:addCheckTouchEventListener({items[2]},true
    -- ,function(index) 
    --     if items[2]:isBright() then
    --         items[4]:setEnabled(true)
    --         items[4]:setColor(cc.c3b(255,255,255))
    --         local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
    --         if uiText_desc ~= nil then 
    --             uiText_desc:setTextColor(cc.c3b(109,58,44))
    --         end
    --     else
    --         items[4]:setBright(false)
    --         items[4]:setEnabled(false)
    --         items[4]:setColor(cc.c3b(170,170,170))
    --         local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
    --         if uiText_desc ~= nil then 
    --             uiText_desc:setTextColor(cc.c3b(109,58,44))
    --         end
    --     end
    -- end)

    --炸弹不可拆
    if self.recordCreateParameter["bBombSeparation"] ~= nil and self.recordCreateParameter["bBombSeparation"] == 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    end

    --显示牌数
   
    if self.recordCreateParameter["bShowCardCount"] ~= nil and self.recordCreateParameter["bShowCardCount"] == 1 then         
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[2]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    end 
    --三带一
    if self.recordCreateParameter["bThreeEx"] ~= nil and self.recordCreateParameter["bThreeEx"] == 1 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[3]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    end


    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    --首局黑桃3必出
    if self.recordCreateParameter["bStartCard"] ~= nil and self.recordCreateParameter["bStartCard"] == 0x03 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[1]:setBright(false)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    end
    local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
    --三A或三K炸弹
    if self.recordCreateParameter["bThreeBomb"] ~= nil and self.recordCreateParameter["bThreeBomb"] == 1 then
        items[2]:setBright(true)    
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[2]:setBright(false)
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    end

    if self.recordCreateParameter["b15Or16"] ~= nil and self.recordCreateParameter["b15Or16"] == 1 then
        uiText_desc:setString("三A炸弹")
    else
        uiText_desc:setString("三K炸弹")
    end

    --红桃10
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bRed10"] ~= nil and self.recordCreateParameter["bRed10"] == 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["bRed10"] ~= nil and self.recordCreateParameter["bRed10"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["bRed10"] ~= nil and self.recordCreateParameter["bRed10"] == 2 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    elseif self.recordCreateParameter["bRed10"] ~= nil and self.recordCreateParameter["bRed10"] == 3 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    else
        items[5]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[5],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
    end

     --飘分
     local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
     Common:addCheckTouchEventListener(items)
     if self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 0 then
         items[1]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end
     elseif self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 1 then
         items[2]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end
     elseif self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 2 then
         items[3]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end
     else
         items[4]:setBright(true)
         local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
         if uiText_desc ~= nil then 
             uiText_desc:setTextColor(cc.c3b(215,86,31))
         end
     end

    --保单上家必压
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    if self.recordCreateParameter["bMustOutCard"] == nil or self.recordCreateParameter["bMustOutCard"] == 0 then
        items[1]:setBright(false)
        items[1]:setEnabled(false)
        items[1]:setColor(cc.c3b(170,170,170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    elseif self.recordCreateParameter["bMustNextWarn"] ~= nil and self.recordCreateParameter["bMustNextWarn"] == 0 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
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
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end
            end
    	else
    	   var:setBright(false)
           var:setVisible(false)
           local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
           if uiText_desc ~= nil then 
               uiText_desc:setTextColor(cc.c3b(109,58,44))
           end
    	end
    end
    if isFound == false and items[1]:isVisible() then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
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

    --选择张数
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.b15Or16 = 1
    elseif items[2]:isBright() then
        tableParameter.b15Or16 = 0
    else
        return
    end

    --选择压牌
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bMustOutCard = 0
    elseif items[2]:isBright() then
        tableParameter.bMustOutCard = 1
    else
        return
    end

    --可选
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bBombSeparation = 0
    else
        tableParameter.bBombSeparation = 1
    end 

    if items[2]:isBright() then
        tableParameter.bShowCardCount = 1
    else
        tableParameter.bShowCardCount = 0
    end 

    if items[3]:isBright() then
        tableParameter.bThreeEx = 1
    else
        tableParameter.bThreeEx = 0
    end 

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    
    if items[1]:isBright() then
        tableParameter.bStartCard = 0x03
    else
        tableParameter.bStartCard = 0
    end 
   
    if items[2]:isBright() then
        tableParameter.bThreeBomb = 1
    else
        tableParameter.bThreeBomb = 0
    end 

    --红桃十可扎鸟
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bRed10 = 0
    elseif items[2]:isBright() then
        tableParameter.bRed10 = 1
    elseif items[3]:isBright() then
        tableParameter.bRed10 = 2
    elseif items[4]:isBright() then
        tableParameter.bRed10 = 3
    elseif items[5]:isBright() then
        tableParameter.bRed10 = 4       
    else
        return
    end

    --飘分
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bJiaPiao = 0
    elseif items[2]:isBright() then
        tableParameter.bJiaPiao = 1
    elseif items[3]:isBright() then
        tableParameter.bJiaPiao = 2
    elseif items[4]:isBright() then
        tableParameter.bJiaPiao = 3     
    else
        return
    end

    --飘分
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bMustNextWarn = 0
    else
        tableParameter.bMustNextWarn = 1
    end
    tableParameter.b4Add3 = 0 
    if tableParameter.b15Or16 == 1 then 
        tableParameter.bSpringMinCount = 16
    else
        tableParameter.bSpringMinCount = 15
    end 
    
    tableParameter.bAbandon = 0
    tableParameter.bCheating = 0
    tableParameter.bFalseSpring = 0
    tableParameter.bAutoOutCard = 0


	-- BYTE b4Add3;				//是否可4带3        0无      1有
	-- BYTE bSpringMinCount;		//春天的最小数量    默认最多  否则其他值
	-- BYTE bAbandon;				//放跑包赔			0无		 1有
	-- BYTE bCheating;				//防止坐标			0无		 1有
	-- BYTE bFalseSpring;			//假春天            0无      1有
	-- BYTE bAutoOutCard;          //自动出牌时间      0无      >0 <256 s


    -- local uiPanel_wanFaContents = ccui.Helper:seekWidgetByName(self.root,"Panel_wanFaContents")
    -- local items  = uiPanel_wanFaContents:getChildren()
    -- --首局出牌要求
    -- if items[1]:isBright() then
    --     tableParameter.bStartCard = 0x03
    -- else
    --     tableParameter.bStartCard = 0
    -- end
    -- --炸弹是否可拆
    -- if items[2]:isBright() then
    --     tableParameter.bBombSeparation = 1
    -- else
    --     tableParameter.bBombSeparation = 0
    -- end
    -- --红桃十可扎鸟
    -- if items[3]:isBright() then
    --     tableParameter.bRed10 = 1
    -- else
    --     tableParameter.bRed10 = 0
    -- end
    -- --是否可4带3
    -- if items[4]:isBright() then
    --     tableParameter.b4Add3 = 1
    -- else
    --     tableParameter.b4Add3 = 0
    -- end
    -- --是否显示牌数量
    -- if items[5]:isBright() then
    --     tableParameter.bShowCardCount = 1
    -- else
    --     tableParameter.bShowCardCount = 0
    -- end
    -- --红桃十可扎鸟
    -- if items[6]:isBright() then
    --     tableParameter.bSpringMinCount = 10
    -- else
    --     if self.wKindID == 25 or self.wKindID == 76  then
    --         tableParameter.bSpringMinCount = 15
    --     else
    --         tableParameter.bSpringMinCount = 16
    --     end
    -- end
    -- --放跑包赔
    -- if items[7]:isBright() then
    --     tableParameter.bAbandon = 1
    -- else
    --     tableParameter.bAbandon = 0
    -- end
    -- --假春天
    -- if items[8]:isBright() then
    --     tableParameter.bFalseSpring = 1
    -- else
    --     tableParameter.bFalseSpring = 0
    -- end

    -- --防作弊
    -- if items[9]:isBright() then
    --     tableParameter.bCheating = 1
    -- else
    --     tableParameter.bCheating = 0
    -- end

    -- --15秒场
    -- if items[10]:isBright() then
    --     tableParameter.bAutoOutCard = 1
    -- else
    --     tableParameter.bAutoOutCard = 0
    -- end

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
        -- uiButton_create:removeAllChildren()
        -- local img = ccui.ImageView:create("newcommon/ft_btn_createroom.png")
        -- uiButton_create:addChild(img,1000)
        -- img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height/2)
        uiButton_create:addChild(require("app.MyApp"):create(TableType_ClubRoom,1,self.wKindID,tableParameter.wGameCount,self.dwClubID,tableParameter):createView("InterfaceCreateRoomNode"))
        return
    end 
    --设置亲友圈   
    if nTableType == TableType_ClubRoom then
        EventMgr:dispatch(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,{wKindID = self.wKindID,wGameCount = tableParameter.wGameCount,tableParameter = tableParameter})      
        return
    end

    local uiButton_create = ccui.Helper:seekWidgetByName(self.root,"Button_create")
    -- uiButton_create:removeAllChildren()
    -- local img = ccui.ImageView:create("newcommon/ft_btn_createroom.png")
    -- uiButton_create:addChild(img,1000)
    -- img:setPosition(img:getParent():getContentSize().width/2,img:getParent():getContentSize().height/2)
    uiButton_create:addChild(require("app.MyApp"):create(nTableType,0,self.wKindID,tableParameter.wGameCount,UserData.Guild.dwPresidentID,tableParameter):createView("InterfaceCreateRoomNode"))

end

return RoomCreateLayer

