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
    local csb = cc.CSLoader:createNode("RoomCreateLayer60.csb")
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
        local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"ListView_parameter"):getItems()
    table.remove(items,3)
    local uiButton_deathCard = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"Button_deathCard")
    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            uiButton_deathCard:setVisible(false)
        else
            uiButton_deathCard:setVisible(true)
        end
    end)
    if self.recordCreateParameter["bPlayerCount"] ~= nil and self.recordCreateParameter["bPlayerCount"] == 2 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
        uiButton_deathCard:setVisible(true)
        if self.recordCreateParameter["bDeathCard"] ~= nil and self.recordCreateParameter["bDeathCard"] == 1 then
            uiButton_deathCard:setBright(true)
        end
    else
        items[1]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[1],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end
        uiButton_deathCard:setVisible(false)
    end
    Common:addCheckTouchEventListener({uiButton_deathCard},true)
    --起胡胡息
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bCanHuXi"] ~= nil and self.recordCreateParameter["bCanHuXi"] == 18 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    elseif self.recordCreateParameter["bCanHuXi"] ~= nil and self.recordCreateParameter["bCanHuXi"] == 21 then
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
    --选择加底
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    Common:addCheckTouchEventListener(items)
    if self.recordCreateParameter["bStartTun"] ~= nil and self.recordCreateParameter["bStartTun"] == 3 then
        items[2]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[2],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    elseif self.recordCreateParameter["bStartTun"] ~= nil and self.recordCreateParameter["bStartTun"] ==5 then
        items[3]:setBright(true)
        local uiText_desc = ccui.Helper:seekWidgetByName(items[3],"Text_desc")
        if uiText_desc ~= nil then 
            uiText_desc:setTextColor(cc.c3b(215,86,31))
        end 
    elseif self.recordCreateParameter["bStartTun"] ~= nil and self.recordCreateParameter["bStartTun"] == 8 then
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
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                if uiText_desc ~= nil then 
                    uiText_desc:setTextColor(cc.c3b(215,86,31))
                end 
                isFound = true
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
    table.remove(items,3)
    local uiButton_deathCard = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(1),"Button_deathCard")
    tableParameter.bDeathCard = 0
    if items[1]:isBright() then
        tableParameter.bPlayerCount = 3
        tableParameter.bPlayerCountType = 0
    elseif items[2]:isBright() then
        tableParameter.bPlayerCount = 2
        tableParameter.bPlayerCountType = 0
        if uiButton_deathCard:isBright() then
            tableParameter.bDeathCard = 1 
        end
    else
        return
    end
    --起胡胡息
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(2),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bCanHuXi = 15
    elseif items[2]:isBright() then
        tableParameter.bCanHuXi = 18
    elseif items[3]:isBright() then
        tableParameter.bCanHuXi = 21
    else
        return
    end
    --选择加底
    local items = ccui.Helper:seekWidgetByName(uiListView_parameterList:getItem(3),"ListView_parameter"):getItems()
    if items[1]:isBright() then
        tableParameter.bStartTun = 1
    elseif items[2]:isBright() then
        tableParameter.bStartTun = 3
    elseif items[3]:isBright() then
        tableParameter.bStartTun = 5
    elseif items[4]:isBright() then
        tableParameter.bStartTun = 8
    else
        return
    end

    tableParameter.FanXing = {}
    tableParameter.FanXing.bType = 0
    tableParameter.FanXing.bCount = 0
    tableParameter.FanXing.bAddTun = 0
    tableParameter.bLaiZiCount = 0
    tableParameter.bMaxLost = 0 
    tableParameter.bYiWuShi = 0
    tableParameter.bLiangPai = 0
    tableParameter.bHuType = 0
    tableParameter.bFangPao = 0
    tableParameter.bSettlement = 0
    tableParameter.bSocreType = 1
    tableParameter.dwMingTang = 0xFFF
    tableParameter.bTurn = 0
    tableParameter.bStartBanker = 0
    
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
                            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足,请前往商城充值？",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的金币不足!")
                        end
                        return
                end  
                elseif data.dwExpendType == 2 then--元宝
                    if UserData.User.dwIngot  < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的元宝不足,请前往商城购买？",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) end)
                        else
                            require("common.MsgBoxLayer"):create(0,nil,"您的元宝不足!")
                        end
                        return
                end 
                elseif data.dwExpendType == 3 then--道具
                    local itemCount = UserData.Bag:getBagPropCount(data.dwSubType)
                    if itemCount < data.dwExpendCount then
                        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
                            require("common.MsgBoxLayer"):create(1,nil,"您的道具不足,请前往商城购买?",function() require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) end)
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

