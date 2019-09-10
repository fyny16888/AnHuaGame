local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventType = require("common.EventType")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")

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
    local csb = cc.CSLoader:createNode("RoomCreateLayer78.csb")
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
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"ListView_parameter"):getItems()
        if index == 3 then
            local isHaveDefault = false
            for key, var in pairs(items) do           
                var:setEnabled(true)
                var:setColor(cc.c3b(255,255,255))
                if var:isBright() then
                    isHaveDefault = true
                end
            end
            if isHaveDefault == false then
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end  
            end
        else    
            for key, var in pairs(items) do
                var:setBright(false)
                var:setEnabled(false)
                var:setColor(cc.c3b(170,170,170))
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
            items[1]:setEnabled(true)
            items[1]:setBright(true)
            items[1]:setColor(cc.c3b(255,255,255))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(215,86,31))
            end 
        end
    end
    )
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    elseif self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 3 then
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

    --选择癞子
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()
        if index == 1 then
            items[1]:setBright(false)
            items[1]:setEnabled(false)
            items[1]:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(109,58,44))
            end
        else
            local items_7 = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
            if items_7[4]:isBright() == false then 
                local isHaveDefault = false
                items[1]:setEnabled(true)
                items[1]:setColor(cc.c3b(255,255,255))
                if items[1]:isBright() then
                    isHaveDefault = true
                end
                if isHaveDefault == false then
                    items[1]:setBright(true)
                    local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                    if uiText_desc ~= nil then 
                        uiText_desc:setTextColor(cc.c3b(215,86,31))
                    end  
                end
            end          
        end
    end
    )
    if self.recordCreateParameter["mLaiZiCount"] ~= nil and self.recordCreateParameter["mLaiZiCount"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    elseif self.recordCreateParameter["mLaiZiCount"] ~= nil and self.recordCreateParameter["mLaiZiCount"] == 2 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
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

    --玩法
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bJiePao"] ~= nil and self.recordCreateParameter["bJiePao"] == 0 then
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
    Common:addCheckTouchEventListener(items,true,function(index) 
        if index == 2 then       
            local target = items[index]
            if target:isBright() then
                items[3]:setEnabled(true)
                items[3]:setColor(cc.c3b(255,255,255))
                -- local uiText_desc = ccui.Helper:seekWidgetByName(items[3], "Text_desc")
                -- if uiText_desc ~= nil then
                --     uiText_desc:setTextColor(cc.c3b(215,86,31))
                -- end
            else
                items[3]:setEnabled(false)
                items[3]:setColor(cc.c3b(170,170,170))
                local uiText_desc = ccui.Helper:seekWidgetByName(items[3], "Text_desc")
                if uiText_desc ~= nil then
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
        end
    end)
    if self.recordCreateParameter["bQGHu"] ~= nil and self.recordCreateParameter["bQGHu"] == 1 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
        if self.recordCreateParameter["bQGHuBaoPei"] ~= nil and self.recordCreateParameter["bQGHuBaoPei"] == 0 then
            items[3]:setBright(true)
            --items[3]:setColor(cc.c3b(255,255,255))
            -- local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
            -- if uiText_desc ~= nil then 
            --     uiText_desc:setTextColor(cc.c3b(215,86,31))
            -- end  
        end 
    else
        items[3]:setEnabled(false)
        items[3]:setColor(cc.c3b(170,170,170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3], "Text_desc")
        if uiText_desc ~= nil then
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    end 
    if self.recordCreateParameter["bQiDui"] ~= nil and self.recordCreateParameter["bQiDui"] == 1 then 
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    end

    --充分
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
        if index == 1 or index == 2 or index == 3 then
            for key, var in pairs(items) do
                var:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
        else
            local isHaveDefault = false
            for key, var in pairs(items) do
                if var:isBright() then
                    isHaveDefault = true
                end
            end
            if isHaveDefault == false then
                items[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end  
            end
        end
    end)
    if self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 3 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    elseif self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 4 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    elseif self.recordCreateParameter["bJiaPiao"] == nil or self.recordCreateParameter["bJiaPiao"] == 0 then
        --if self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 4 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    --else 
    end
    
    --充几分
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
        if index == 1 or index == 2 then
            for key, var in pairs(items) do
                var:setBright(false)
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
        else
            local isHaveDefault = false
            for key, var in pairs(items) do
                if var:isBright() then
                    isHaveDefault = true
                end
            end
            if isHaveDefault == false then
                items[2]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end  
            end
        end
    end) 
    if self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 1 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    elseif self.recordCreateParameter["bJiaPiao"] ~= nil and self.recordCreateParameter["bJiaPiao"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    else
    end

    --抓鸟
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,false,function(index) 
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"ListView_parameter"):getItems()
        if index == 4 then
            for key, var in pairs(items) do
                var:setBright(false)
                var:setEnabled(false)
                var:setColor(cc.c3b(170,170,170))
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
        elseif index == 3 then
            for key, var in pairs(items) do
                var:setBright(false)
                var:setEnabled(false)
                var:setColor(cc.c3b(170,170,170))
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
        else
            local isHaveDefault = false
            for key, var in pairs(items) do
                var:setEnabled(true)
                var:setColor(cc.c3b(255,255,255))
                if var:isBright() then
                    isHaveDefault = true
                end
            end
            if isHaveDefault == false then
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end  
            end
        end
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(9),"ListView_parameter"):getItems()
        if index == 4 then
            for key, var in pairs(items) do
                var:setBright(false)
                var:setEnabled(false)
                var:setColor(cc.c3b(170,170,170))
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
        elseif index == 3 then
            for key, var in pairs(items) do
                var:setBright(false)
                var:setEnabled(false)
                var:setColor(cc.c3b(170,170,170))
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(109,58,44))
                end
            end
        else
            local isHaveDefault = false
            for key, var in pairs(items) do
                var:setEnabled(true)
                var:setColor(cc.c3b(255,255,255))
                if var:isBright() then
                    isHaveDefault = true
                end
            end
            if isHaveDefault == false then
                items[1]:setBright(true)
                local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end  
            end
        end
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()
        if index == 4 then
            items[1]:setBright(false)
            items[1]:setEnabled(false)
            items[1]:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(109,58,44))
            end
        else
            local items_2 = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
            if items_2[1]:isBright() == false then 
                local isHaveDefault = false
                items[1]:setEnabled(true)
                items[1]:setColor(cc.c3b(255,255,255))
                if items[1]:isBright() then
                    isHaveDefault = true
                end
                if isHaveDefault == false then
                    items[1]:setBright(true)
                    local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
                    if uiText_desc ~= nil then 
                        uiText_desc:setTextColor(cc.c3b(215,86,31))
                    end  
                end
            end
        end
    end)
    if self.recordCreateParameter["bMaType"] ~= nil and self.recordCreateParameter["bMaType"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    elseif self.recordCreateParameter["bMaType"] ~= nil and self.recordCreateParameter["bMaType"] == 3 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    elseif self.recordCreateParameter["bMaType"] ~= nil and self.recordCreateParameter["bMaType"] == 4 then
        items[4]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[4],"Text_desc")
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

    --一码几分
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)  
    if self.recordCreateParameter["bMaType"] ~= nil and (self.recordCreateParameter["bMaType"] == 4 or self.recordCreateParameter["bMaType"] == 3 ) then
        for key, var in pairs(items) do
            var:setBright(false)
            var:setEnabled(false)
            var:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(109,58,44))
            end
        end
    elseif self.recordCreateParameter["mNiaoType"] ~= nil and self.recordCreateParameter["mNiaoType"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    else
        --if self.recordCreateParameter["mNiaoType"] ~= nil and self.recordCreateParameter["mNiaoType"] == 1 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end  
    end

    --奖几码
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(9),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)  
    if self.recordCreateParameter["bMaType"] ~= nil and ( self.recordCreateParameter["bMaType"] == 4 or self.recordCreateParameter["bMaType"] == 3 ) then
        for key, var in pairs(items) do
            var:setBright(false)
            var:setEnabled(false)
            var:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(109,58,44))
            end
        end
    elseif self.recordCreateParameter["bMaCount"] ~= nil and self.recordCreateParameter["bMaCount"] == 2 then
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end    
    elseif self.recordCreateParameter["bMaCount"] ~= nil and self.recordCreateParameter["bMaCount"] == 4 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end    
    else
        --if self.recordCreateParameter["bQGHu"] ~= nil and self.recordCreateParameter["bMaCount"] == 6 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end    
    end

    --选择筒子
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bPlayerCount"] == nil or self.recordCreateParameter["bPlayerCount"] ~= 2 then
        for key, var in pairs(items) do
            var:setBright(false)
            var:setEnabled(false)
            var:setColor(cc.c3b(170,170,170))
            local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
            if uiText_desc ~= nil then 
                uiText_desc:setTextColor(cc.c3b(109,58,44))
            end
        end
        items[1]:setEnabled(true)
        items[1]:setBright(true)
        items[1]:setColor(cc.c3b(255,255,255))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end   
    elseif self.recordCreateParameter["bWuTong"] ~= nil and self.recordCreateParameter["bWuTong"] == 0 then
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

    --可选
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items,true)
    if self.recordCreateParameter["bMaType"] ~= nil and self.recordCreateParameter["bMaType"] == 4 then
        items[1]:setBright(false)
        items[1]:setEnabled(false)
        items[1]:setColor(cc.c3b(170,170,170))
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(109,58,44))
        end
    elseif self.recordCreateParameter["mHongNiao"] ~= nil and self.recordCreateParameter["mHongNiao"] == 1 then
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
        tableParameter.bPlayerCount = 4
    elseif items[2]:isBright() then
        tableParameter.bPlayerCount = 3
    elseif items[3]:isBright() then
        tableParameter.bPlayerCount = 2
    else
        return
    end
    --癞子红中
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.mLaiZiCount = 0
    elseif items[2]:isBright() then
        tableParameter.mLaiZiCount = 1
    elseif items[3]:isBright() then
        tableParameter.mLaiZiCount = 2
    else
        return
    end
    --玩法

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bJiePao = 0
    elseif items[2]:isBright() then
        tableParameter.bJiePao = 1
    end
       
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(4),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bQiDui = 1
    else
        tableParameter.bQiDui = 0
    end
    if items[2]:isBright() then
        tableParameter.bQGHu = 1
    else
        tableParameter.bQGHu = 0 
    end
    tableParameter.bQGHuBaoPei = 1
    if items[3]:isBright() then
        tableParameter.bQGHuBaoPei = 0
    else
        tableParameter.bQGHuBaoPei = 1
    end
    
    --充分
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(5),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bJiaPiao = 0
    elseif items[2]:isBright() then
        tableParameter.bJiaPiao = 3
    elseif items[3]:isBright() then
        tableParameter.bJiaPiao = 4
    else
    end
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(6),"ListView_parameter"):getItems()

    if items[1]:isBright() then
        tableParameter.bJiaPiao = 1
    elseif items[2]:isBright() then
        tableParameter.bJiaPiao = 2
    else
    end
    --抓鸟
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(7),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bMaType = 1
    elseif items[2]:isBright() then
        tableParameter.bMaType = 2
    elseif items[3]:isBright() then
        tableParameter.bMaType = 3
        tableParameter.bMaCount = 0
        tableParameter.mNiaoType = 0
    elseif items[4]:isBright() then
        tableParameter.bMaType = 4
        tableParameter.bMaCount = 0
        tableParameter.mNiaoType = 0
    end
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(8),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.mNiaoType = 1
    elseif items[2]:isBright() then
        tableParameter.mNiaoType = 2
    end
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(9),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bMaCount = 2
    elseif items[2]:isBright() then
        tableParameter.bMaCount = 4
    elseif items[3]:isBright() then
        tableParameter.bMaCount = 6
    end
    tableParameter.bWuTong = 1
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(10),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bWuTong = 1
    elseif items[2]:isBright() then
        tableParameter.bWuTong = 0
    end

    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(11),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.mHongNiao = 1
    else
        tableParameter.mHongNiao = 0
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
    uiButton_create:addChild(require("app.MyApp"):create(nTableType,0,self.wKindID,tableParameter.wGameCount,UserData.Guild.dwPresidentID,tableParameter):createView("InterfaceCreateRoomNode"))
    
end

return RoomCreateLayer

