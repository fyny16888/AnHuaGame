local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventType = require("common.EventType")
local Default = require("common.Default")
local Bit = require("common.Bit")
local GoldGameLayer = class("GoldGameLayer", cc.load("mvc").ViewBase)

function GoldGameLayer:onEnter()
    cc.UserDefault:getInstance():setStringForKey("UserDefault_Operation","GoldGameLayer")
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:registListener(EventType.SUB_CL_GOLDROOM_CONFIG,self,self.SUB_CL_GOLDROOM_CONFIG)
    EventMgr:registListener(EventType.SUB_CL_GOLDROOM_CONFIG_END,self,self.SUB_CL_GOLDROOM_CONFIG_END)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:registListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
end

function GoldGameLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:unregistListener(EventType.SUB_CL_GOLDROOM_CONFIG,self,self.SUB_CL_GOLDROOM_CONFIG)
    EventMgr:unregistListener(EventType.SUB_CL_GOLDROOM_CONFIG_END,self,self.SUB_CL_GOLDROOM_CONFIG_END)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
end

function GoldGameLayer:onCleanup()

end

function GoldGameLayer:onCreate(parameter)
    NetMgr:getGameInstance():closeConnect()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GoldGameLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function(sender,event) 
        cc.UserDefault:getInstance():setStringForKey("UserDefault_Operation","")
        self:removeFromParent()
    end)

    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   

    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")    
    uiText_gold:setString(string.format("%s",Common:itemNumberToString(UserData.User.dwGold)))   

    local uiText_money = ccui.Helper:seekWidgetByName(self.root,"Text_money")    
    uiText_money:setString(string.format("%d",UserData.Bag:getBagPropCount(1008))) 




    local uiImage_title = ccui.Helper:seekWidgetByName(self.root,"Image_title")
    local uiListView_gameTypeBtn = ccui.Helper:seekWidgetByName(self.root,"ListView_gameTypeBtn")
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
--    local uiButton_zipai = ccui.Helper:seekWidgetByName(self.root,"Button_zipai")
--    local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")
--    local uiButton_puke = ccui.Helper:seekWidgetByName(self.root,"Button_puke")
    local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
    local locationID = parameter[1]
    
    local uiButton_zipai = ccui.Helper:seekWidgetByName(self.root,"Button_zipai")      
    local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")  
    local uiButton_puke = ccui.Helper:seekWidgetByName(self.root,"Button_puke")      
    local armature1 = ccui.Helper:seekWidgetByName(self.root,"Image_zipai")
    local armature2 = ccui.Helper:seekWidgetByName(self.root,"Image_majiang")
    local armature3 = ccui.Helper:seekWidgetByName(self.root,"Image_puke")

    local uiButton_iten = ccui.Helper:seekWidgetByName(self.root,"Button_iten")
    uiButton_iten:retain()
    uiButton_iten:setVisible(false)
    
    if locationID == nil then
        locationID = UserData.Game.talbeCommonGames[1]
    end
    local function showGameType(type)
        if type == 1 then
            uiButton_zipai:setBright(true)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(false)    
            armature1:loadTexture( "newroom/newroom_paohuziliang.png")
            armature2:loadTexture( "newroom/newroom_majiangan.png")
            armature3:loadTexture( "newroom/newroom_paodekuaian.png")
        elseif type == 2 then
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(true)
            armature1:loadTexture( "newroom/newroom_paohuzian.png")
            armature2:loadTexture( "newroom/newroom_majiangan.png")
            armature3:loadTexture( "newroom/newroom_paodekuailiang.png")
        elseif type == 3 then
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(true)
            uiButton_puke:setBright(false)
            armature1:loadTexture( "newroom/newroom_paohuzian.png")
            armature2:loadTexture( "newroom/newroom_majiangliang.png")
            armature3:loadTexture( "newroom/newroom_paodekuaian.png")
        else
            uiImage_title:setVisible(true)
            uiListView_gameTypeBtn:setVisible(false)
        end
        uiListView_games:removeAllItems()
        local games = clone(UserData.Game.tableSortGames)
        local isFound = false
        for key, var in pairs(games) do
            local wKindID = tonumber(var)
            local data = StaticData.Games[wKindID]
            if UserData.Game.tableGames[wKindID] ~= nil and Bit:_and(data.friends,0x04) ~= 0 and data.type == type then
                local item = uiButton_iten:clone()
                item.wKindID = wKindID
                item:setBright(false)
                item:setVisible(true)
                local uiImage_icon1 = ccui.Helper:seekWidgetByName(item,"Image_icon1")
                local uiImage_icon2 = ccui.Helper:seekWidgetByName(item,"Image_icon2")
                uiImage_icon1:loadTexture(data.icon1)
                uiImage_icon2:loadTexture(data.icons)
                uiImage_icon1:setVisible(false)
                uiImage_icon2:setVisible(true)
                uiListView_games:pushBackCustomItem(item)
                Common:addTouchEventListener(item,function() self:showGameParameter(wKindID) end)
                if wKindID == locationID then
                    isFound = true
                end
            end 
        end
        if isFound == true then
            local btn = self:showGameParameter(locationID)
            if btn ~= nil then
                btn:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event)
                    --位置刷新
                    uiListView_games:refreshView()
                    local container = uiListView_games:getInnerContainer()
                    local pos = cc.p(btn:getPosition())
                    pos = cc.p(btn:getParent():convertToWorldSpace(pos))
                    pos = cc.p(container:convertToNodeSpace(pos))
                    local value = (1-pos.y/container:getContentSize().height)*100
                    uiListView_games:scrollToPercentVertical(value,1,true)
                end)))
            end
        else
            local item = uiListView_games:getItem(0)
            if item ~= nil then
                self:showGameParameter(item.wKindID)
            end
        end
    end
    Common:addTouchEventListener(uiButton_zipai,function() showGameType(1) end)
    Common:addTouchEventListener(uiButton_puke,function() showGameType(2) end)
    Common:addTouchEventListener(uiButton_majiang,function() showGameType(3) end)
    for i = 1 , 3 do
        local uiButton_roomTypeInfo = ccui.Helper:seekWidgetByName(self.root,string.format("Button_roomTypeInfo%d",i))
        Common:addTouchEventListener(uiButton_roomTypeInfo,function() 
            local data = uiButton_roomTypeInfo.data
            if data == nil then
                require("common.MsgBoxLayer"):create(0,nil,"游戏房间暂未开放!")
                return
            elseif UserData.User.dwGold < data.dwMinScore then
                require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function() 
                    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer"))
                end)
                return
            elseif UserData.User.dwGold > data.dwMaxScore and data.dwMaxScore ~= 0 then
                require("common.MsgBoxLayer"):create(0,nil,"您的金币已超过上限，请前往更高一级匹配")
                return               
            end
            self.cbLevel = data.cbLevel
            UserData.Game:sendMsgGetRoomInfo(data.wKindID, 3)
        end)
    end
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_roomTypeInfo0"),function()
        local isHave = false
        for i = 3 , 1, -1 do
            local uiButton_roomTypeInfo = ccui.Helper:seekWidgetByName(self.root,string.format("Button_roomTypeInfo%d",i))
            local data = uiButton_roomTypeInfo.data
            if data ~= nil then
                isHave = true
            end
            if data ~= nil and UserData.User.dwGold >= data.dwMinScore and (UserData.User.dwGold <= data.dwMaxScore or data.dwMaxScore == 0) then
                self.cbLevel = data.cbLevel
                UserData.Game:sendMsgGetRoomInfo(data.wKindID, 3)
                return
            end
        end
        if isHave == false then
            require("common.MsgBoxLayer"):create(0,nil,"休闲场暂未开放!") 
            return  
        else
            require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer"))
            end)
            return         
        end       
    end)
    if  #UserData.Game.tableSortGames <= 5 then 
        showGameType()
    else
        if locationID == nil then
            showGameType(1)
        else
            showGameType(StaticData.Games[locationID].type)
        end
    end
end

function GoldGameLayer:showGameParameter(wKindID)
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
    local items = uiListView_games:getItems()
    local node = nil
    for key, var in pairs(items) do
        local uiImage_icon1 = ccui.Helper:seekWidgetByName(var,"Image_icon1")
        local uiImage_icon2 = ccui.Helper:seekWidgetByName(var,"Image_icon2")
        if var.wKindID == wKindID then
            if var:isBright() then
                return nil
            end
            node = var
            var:setBright(true)
            uiImage_icon1:setVisible(true)
            uiImage_icon2:setVisible(false)
        else
            var:setBright(false)
            uiImage_icon1:setVisible(false)
            uiImage_icon2:setVisible(true)
        end
    end       
    self.wKindID = wKindID
    self.tableFriendsRoomParams = nil    
    local uiPanel_parameter = ccui.Helper:seekWidgetByName(self.root,"Panel_parameter") 
    local uiImage_8zi = ccui.Helper:seekWidgetByName(uiPanel_parameter,"Image_8zi")
    uiImage_8zi:loadTexture(StaticData.Games[self.wKindID].icon8)
    local uiText_Therules = ccui.Helper:seekWidgetByName(uiPanel_parameter,"Text_Therules")
    uiText_Therules:setString(StaticData.Games[self.wKindID].rules)
    for i = 1 , 3 do
        local uiButton_roomTypeInfo = ccui.Helper:seekWidgetByName(self.root,string.format("Button_roomTypeInfo%d",i))
        local uiText_info = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Text_info")
        -- local uiAtlasLabel_rate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"AtlasLabel_rate")
        -- local uiImage_rate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Image_rate")
        uiText_info:setString("暂未开放")
        -- uiAtlasLabel_rate:setVisible(false)
        -- uiImage_rate:setVisible(false)
        local uiText_irate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Text_irate")
        uiText_irate:setVisible(false)
        uiButton_roomTypeInfo.data = nil
    end
    UserData.Game:sendMsgGetGoldRoomParam(wKindID)     
    for i = 1 , 3 do
        local uiButton_roomTypeInfo = ccui.Helper:seekWidgetByName(self.root,string.format("Button_roomTypeInfo%d",i))
        uiButton_roomTypeInfo:setScale(0)
        uiButton_roomTypeInfo:stopAllActions()
        uiButton_roomTypeInfo:runAction(cc.Sequence:create(cc.DelayTime:create(0.1*(i-1)),cc.ScaleTo:create(0.4,1.1),cc.ScaleTo:create(0.2,1)))             
    end      
    return node
end

--刷新房间信息
function GoldGameLayer:SUB_CL_GOLDROOM_CONFIG(event)
    local data = event._usedata
    if data.wKindID ~= self.wKindID then
        return
    end
    if self.tableFriendsRoomParams == nil then
        self.tableFriendsRoomParams = {}
    end
    self.tableFriendsRoomParams[data.cbLevel] = data
end

function GoldGameLayer:SUB_CL_GOLDROOM_CONFIG_END(event)
    for i = 1 , 3 do
        local uiButton_roomTypeInfo = ccui.Helper:seekWidgetByName(self.root,string.format("Button_roomTypeInfo%d",i))
        local uiText_info = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Text_info")
        local uiText_irate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Text_irate")
        -- local uiAtlasLabel_rate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"AtlasLabel_rate")
        -- local uiImage_rate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Image_rate")
        if self.tableFriendsRoomParams ~= nil and self.tableFriendsRoomParams[i] ~= nil then
            local data = self.tableFriendsRoomParams[i]
            uiButton_roomTypeInfo.data = data
            if data.dwMaxScore ~= 0 then
                uiText_info:setString(string.format("%d -- %d",data.dwMinScore,data.dwMaxScore))
            else
                uiText_info:setString(string.format("%d -- 无限",data.dwMinScore))
            end
            uiText_irate:setVisible(true)
            uiText_irate:setString(string.format("倍率    %d",data.wCellScore))
            -- uiAtlasLabel_rate:setVisible(true)
            -- uiAtlasLabel_rate:setString(string.format("%d",data.wCellScore))
            -- uiImage_rate:setVisible(true)
        end
    end 
end

--刷新个人信息
function GoldGameLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

function GoldGameLayer:updateUserInfo()
    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   

    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")    
    uiText_gold:setString(string.format("%s",Common:itemNumberToString(UserData.User.dwGold)))   

    local uiText_money = ccui.Helper:seekWidgetByName(self.root,"Text_money")    
    uiText_money:setString(string.format("%d",UserData.Bag:getBagPropCount(1008)))  

    
end

--获取房间ip地址和端口成功
function GoldGameLayer:SUB_CL_GAME_SERVER(event)
    local data = event._usedata
    UserData.Game:sendMsgConnectGame(data)           
end

function GoldGameLayer:SUB_CL_GAME_SERVER_ERROR(event)
    local data = event._usedata
    require("common.MsgBoxLayer"):create(0,nil,"服务器暂未开启！")         
end

function GoldGameLayer:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    local data = event._usedata
    require("common.MsgBoxLayer"):create(0,nil,"连接游戏服失败！")
end

function GoldGameLayer:SUB_GR_LOGON_SUCCESS(event)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_MATCH_REDENVELOPE_TABLE,"w",self.cbLevel)
end

function GoldGameLayer:SUB_GR_MATCH_TABLE_ING(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID, data),SCENE_GAME)
end

function GoldGameLayer:SUB_GR_MATCH_TABLE_FAILED(event)
    local data = event._usedata
    if data.wErrorCode == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您在游戏中!")
    elseif data.wErrorCode == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"游戏配置发生错误!")
    elseif data.wErrorCode == 2 then
        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
            require("common.MsgBoxLayer"):create(1,nil,"您的金币不足,请前往商城充值!",function()             require("app.views.NewXXMallLayer"):create(2) end)
        else
            require("common.MsgBoxLayer"):create(0,nil,"您的金币不足!")
        end
    elseif data.wErrorCode == 3 then
        require("common.MsgBoxLayer"):create(0,nil,"您的金币已超过上限，请前往更高一级匹配!")
    elseif data.wErrorCode == 4 then
        require("common.MsgBoxLayer"):create(0,nil,"房间已满,稍后再试!")
    else
        require("common.MsgBoxLayer"):create(0,nil,"未知错误,请升级版本!") 
    end
end

function GoldGameLayer:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID, data),SCENE_GAME)
end


return GoldGameLayer

