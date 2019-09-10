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
local GoldRoomCreateLayer = class("GoldRoomCreateLayer", cc.load("mvc").ViewBase)

function GoldRoomCreateLayer:onEnter()
    cc.UserDefault:getInstance():setStringForKey("UserDefault_Operation","GoldRoomCreateLayer")
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

function GoldRoomCreateLayer:onExit()
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

function GoldRoomCreateLayer:onCleanup()

end

function GoldRoomCreateLayer:onCreate(parameter)
    NetMgr:getGameInstance():closeConnect()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GoldRoomCreateLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function(sender,event) 
        if self.wKindID == 0 then 
            cc.UserDefault:getInstance():setStringForKey("UserDefault_Operation","")
            self:removeFromParent()
        else
            local uiPanel_moregame = ccui.Helper:seekWidgetByName(self.root,"Panel_moregame")
            local uiPanel_onegame = ccui.Helper:seekWidgetByName(self.root,"Panel_onegame")
            uiPanel_moregame:setVisible(true)
            uiPanel_onegame:setVisible(false)
            self.wKindID = 0
        end 
    end)

    local uiImage_avatar = ccui.Helper:seekWidgetByName(self.root,"Image_avatar")
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")    
    uiText_name:setString(string.format("%s",UserData.User.szNickName))
    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")     
    local dwGold = Common:itemNumberToString(UserData.User.dwGold)    
    if  uiText_gold ~=nil then 
        uiText_gold:setString(tostring(dwGold))
    end 
    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   

    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")    
    uiText_gold:setString(string.format("%s",Common:itemNumberToString(UserData.User.dwGold)))   

    local uiText_money = ccui.Helper:seekWidgetByName(self.root,"Text_money")    
    uiText_money:setString(string.format("%d",UserData.Bag:getBagPropCount(1008)))  

    local uiText_ID = ccui.Helper:seekWidgetByName(self.root,"Text_ID")
    uiText_ID:setString(string.format("ID:%d",UserData.User.userID))
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiImage_avatar,"img")



    --房卡转道具商城    
    local uiButton_roomCardBg = ccui.Helper:seekWidgetByName(self.root,"Button_roomCardBg")
    if uiButton_roomCardBg ~= nil and StaticData.Hide[CHANNEL_ID].btn20 == 1 then   
        uiButton_roomCardBg:setEnabled(true)
        Common:addTouchEventListener(uiButton_roomCardBg,function()               
            require("app.views.NewXXMallLayer"):create(2)
        end)      
    end            
    
    local uiImage_roomCard = ccui.Helper:seekWidgetByName(self.root,"Image_roomCard") 
    uiImage_roomCard:setEnabled(true)         
    uiImage_roomCard:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then 
            Common:palyButton() 
            require("app.views.NewXXMallLayer"):create(2)
        end 
    end)
    
    --充值
    local uiButton_goldBg = ccui.Helper:seekWidgetByName(self.root,"Button_goldBg")
    if  uiButton_goldBg ~= nil then
        Common:addTouchEventListener(uiButton_goldBg,function()             
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer")) 
        end)    
    end

    local uiImage_gold = ccui.Helper:seekWidgetByName(self.root,"Image_gold") 
    uiImage_gold:setEnabled(true)         
    uiImage_gold:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then 
            Common:palyButton() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer")) 
        end 
    end)
    
    --兑换
    local uiButton_moneyBg = ccui.Helper:seekWidgetByName(self.root,"Button_moneyBg")
    if  uiButton_moneyBg ~= nil then
        Common:addTouchEventListener(uiButton_moneyBg,function()             
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) 
        end)    
    end

    local uiImage_money = ccui.Helper:seekWidgetByName(self.root,"Image_money") 
    uiImage_money:setEnabled(true)         
    uiImage_money:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then 
            Common:palyButton() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) 
        end 
    end)

    --房卡转道具商城    
    local uiButton_roomCardBg = ccui.Helper:seekWidgetByName(self.root,"Button_roomCardBg")
    if uiButton_roomCardBg ~= nil and StaticData.Hide[CHANNEL_ID].btn20 == 1 then   
        uiButton_roomCardBg:setEnabled(true)
        Common:addTouchEventListener(uiButton_roomCardBg,function()               
            require("app.views.NewXXMallLayer"):create(2)
        end)    
        if StaticData.Hide[CHANNEL_ID].btn9 ~= 1  then
            uiButton_roomCardBg:setVisible(false)                      
        end
    elseif StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then 
        uiButton_roomCardBg:setVisible(false)    
    end   

    
    local uiPanel_moregame = ccui.Helper:seekWidgetByName(self.root,"Panel_moregame")
    local uiPanel_onegame = ccui.Helper:seekWidgetByName(self.root,"Panel_onegame")

    local uiListView_gameTypeBtn = ccui.Helper:seekWidgetByName(self.root,"ListView_gameTypeBtn")
    local uiPageView_goldgame = ccui.Helper:seekWidgetByName(self.root,"PageView_goldgame")

    uiPageView_goldgame:addEventListener(function(sender,event)       --翻页容器自带监控页面变化
       if  event  == ccui.PageViewEventType.turning then 
           -- performWithDelay(self, function( ... )
                local a = uiPageView_goldgame:getCurPageIndex()
                print ("_______获取页面_________",a,n)
                self:showdianButter(a)
            --end, 0.1)
       end

    end)
    uiPageView_goldgame:setCustomScrollThreshold(100)   --滑动距离控制转页
    local uiButton_allgame = ccui.Helper:seekWidgetByName(self.root,"Button_allgame")
    local uiButton_zipai = ccui.Helper:seekWidgetByName(self.root,"Button_zipai")
    local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")
    local uiButton_puke = ccui.Helper:seekWidgetByName(self.root,"Button_puke")
    local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)

    local opLoaclScriteID = parameter[1]
    local locationID = nil 
    self.wKindID = 0

    local armature0 = ccui.Helper:seekWidgetByName(self.root,"Image_allgame")
    local armature1 = ccui.Helper:seekWidgetByName(self.root,"Image_zipai")
    local armature2 = ccui.Helper:seekWidgetByName(self.root,"Image_majiang")
    local armature3 = ccui.Helper:seekWidgetByName(self.root,"Image_puke")

    local uiButton_iten = ccui.Helper:seekWidgetByName(self.root,"Button_iten")
    uiButton_iten:retain()
    uiButton_iten:setVisible(false)

    local uiListView_goldgame = ccui.Helper:seekWidgetByName(self.root,"ListView_goldgame")
    local uiButton_dian = ccui.Helper:seekWidgetByName(self.root,"Button_dian")
    uiButton_dian:retain()
    uiButton_dian:setVisible(false)

    
    if locationID == nil then
        locationID = UserData.Game.talbeCommonGames[1]
    end
    local function showGameType(type)
        uiPanel_moregame:setVisible(true)
        uiPanel_onegame:setVisible(false)       
        if type == 1 then
            uiButton_allgame:setBright(false)
            uiButton_zipai:setBright(true)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(false) 
            armature0:loadTexture( "goldroom/quanbu1_fs8.png")  
            armature1:loadTexture( "goldroom/zipai_fs8.png")
            armature2:loadTexture( "goldroom/majiang1_fs8.png")
            armature3:loadTexture( "goldroom/puke1_fs8.png")
        elseif type == 2 then
            uiButton_allgame:setBright(false)
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(true) 
            armature0:loadTexture( "goldroom/quanbu1_fs8.png")  
            armature1:loadTexture( "goldroom/zipai1_fs8.png")
            armature2:loadTexture( "goldroom/majiang1_fs8.png")
            armature3:loadTexture( "goldroom/puke_fs8.png")        
        elseif type == 3 then
            uiButton_allgame:setBright(false)
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(true)
            uiButton_puke:setBright(false) 
            armature0:loadTexture( "goldroom/quanbu1_fs8.png")  
            armature1:loadTexture( "goldroom/zipai1_fs8.png")
            armature2:loadTexture( "goldroom/majiang_fs8.png")
            armature3:loadTexture( "goldroom/puke1_fs8.png")
        elseif type == 0 then
            uiButton_allgame:setBright(true)
            uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(false) 
            armature0:loadTexture( "goldroom/quanbu_fs8.png")  
            armature1:loadTexture( "goldroom/zipai1_fs8.png")
            armature2:loadTexture( "goldroom/majiang1_fs8.png")
            armature3:loadTexture( "goldroom/puke1_fs8.png")
        else
            uiListView_gameTypeBtn:setVisible(false)
        end
        uiPageView_goldgame:removeAllPages()
        uiListView_goldgame:removeAllItems()
        uiListView_goldgame:setContentSize(cc.size(0,0))  
        local pos = {{x=143.00,y=486.00},{x=450.00,y=486.00},{x=755.00,y=486.00},{x=1060.00,y=486.00},{x=143.00,y=197.00},{x=450.00,y=197.00},{x=755.00,y=197.00},{x=1060.00,y=197.00}}
        local pageindex = 0
        local index = 0
        local isb = true
    
        local games = clone(UserData.Game.tableSortGames)
            -- local isFound = false
        for key, var in pairs(games) do
            local wKindID = tonumber(var)
            local data = StaticData.Games[wKindID]
            if UserData.Game.tableGames[wKindID] ~= nil and Bit:_and(data.friends,2) ~= 0 and (data.type == type or type == 0)then --and wKindID ~= 16
                local item = uiButton_iten:clone()
                -- item:setScale(0.9)
                index = index + 1
                if index > 8 then
                    isb = false
                    index = 1
                    pageindex = pageindex + 1
                end

                if index == 1 then 
                    local dian = uiButton_dian:clone()      
                    dian:setName('uiButton_dian'..pageindex)   
                    if pageindex == 0 then 
                        dian:setBright(true)
                    else
                        dian:setBright(false)
                    end         
                    dian:setVisible(true)
                    dian:setPosition(0,0)
                    uiListView_goldgame:pushBackCustomItem(dian)
                    uiListView_goldgame:refreshView()
                    uiListView_goldgame:setContentSize(cc.size(uiListView_goldgame:getInnerContainerSize().width,uiListView_goldgame:getInnerContainerSize().height))    
                end 
                item.wKindID = wKindID
                item:setBright(false)
                item:setVisible(true)
                item:loadTextures(data.icon_name,data.icon_name,data.icon_name)
                uiPageView_goldgame:addWidgetToPage(item,pageindex,true)

               -- item:setSwallowTouches(false)

                item:setPosition(pos[index].x,pos[index].y)
                Common:addTouchEventListener(item,function() 
                    self:showGameParameter(wKindID) 
                end)
                -- if wKindID == locationID then
                --     isFound = true
                -- end
            end 
        end
    end
    Common:addTouchEventListener(uiButton_allgame,function() showGameType(0) end)
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
                    -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer"))
                    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer"))
                end)
                return
            elseif UserData.User.dwGold > data.dwMaxScore and data.dwMaxScore ~= 0 then
                require("common.MsgBoxLayer"):create(0,nil,"您的金币已超过上限，请前往更高一级匹配")
                return               
            end
            self.cbLevel = data.cbLevel
            UserData.Game:sendMsgGetRoomInfo(data.wKindID, 3)
            --记录
            cc.UserDefault:getInstance():setIntegerForKey('quick_game_kindId', data.wKindID)
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
                --记录
                cc.UserDefault:getInstance():setIntegerForKey('quick_game_kindId', data.wKindID)
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

    if opLoaclScriteID~= nil and  opLoaclScriteID > 10 then 
        locationID = parameter[1]
        uiPanel_moregame:setVisible(false)
        uiPanel_onegame:setVisible(true)
    elseif opLoaclScriteID ~= nil and  opLoaclScriteID <10 then
        --opLoaclScriteID = 0
        showGameType(opLoaclScriteID)
        uiPanel_moregame:setVisible(true)
        uiPanel_onegame:setVisible(false)
    elseif opLoaclScriteID == nil then
        local wKindID = cc.UserDefault:getInstance():getIntegerForKey('quick_game_kindId', 78)
        showGameType(StaticData.Games[wKindID].type)
        uiPanel_moregame:setVisible(true)
        uiPanel_onegame:setVisible(false)
    end  

    -- if  #UserData.Game.tableSortGames <= 5 then 
    --     showGameType()
    -- else
    -- if locationID == nil then
    --     showGameType(1)
    -- else
    --     showGameType(StaticData.Games[locationID].type)
    -- end
    -- end
end

function GoldRoomCreateLayer:showdianButter(event)
    local uiListView_goldgame = ccui.Helper:seekWidgetByName(self.root,"ListView_goldgame")
    local items = uiListView_goldgame:getItems()
    for key, var in pairs(items) do
        var:setSwallowTouches(false)
        var:setBright(false)
        if var:getName() == 'uiButton_dian'..event then 
            var:setBright(true)
        end 
        Common:addTouchEventListener(var,function() 
            for k, v in pairs(items) do   
                --dian:setName('uiButton_dian'..pageindex)     
                if v == var then
                    v:setBright(true)
                else
                    v:setBright(false)
                end
            end
        end)
    end 
end 
function GoldRoomCreateLayer:showGameParameter(wKindID)

    local uiPanel_moregame = ccui.Helper:seekWidgetByName(self.root,"Panel_moregame")
    local uiPanel_onegame = ccui.Helper:seekWidgetByName(self.root,"Panel_onegame")
    uiPanel_moregame:setVisible(false)
    uiPanel_onegame:setVisible(true)

    self.wKindID = wKindID
    self.tableFriendsRoomParams = nil    
    local uiText_Gamename = ccui.Helper:seekWidgetByName(self.root,"Text_Gamename") 
    uiText_Gamename:setString(StaticData.GamesText[self.wKindID].name)
    local uiText_Game8 = ccui.Helper:seekWidgetByName(self.root,"Text_Game8")
    uiText_Game8:setString(StaticData.GamesText[self.wKindID].Text8)
    -- local uiText_Gamerules = ccui.Helper:seekWidgetByName(self.root,"Text_Gamerules")
    -- uiText_Gamerules:setString(StaticData.GamesText[self.wKindID].rules)
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

end 
--刷新房间信息
function GoldRoomCreateLayer:SUB_CL_GOLDROOM_CONFIG(event)
    local data = event._usedata
    if data.wKindID ~= self.wKindID then
        return
    end
    if self.tableFriendsRoomParams == nil then
        self.tableFriendsRoomParams = {}
    end
    self.tableFriendsRoomParams[data.cbLevel] = data
end

function GoldRoomCreateLayer:SUB_CL_GOLDROOM_CONFIG_END(event)
    for i = 1 , 3 do
        local uiButton_roomTypeInfo = ccui.Helper:seekWidgetByName(self.root,string.format("Button_roomTypeInfo%d",i))
        local uiText_info = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Text_info")
        local uiText_irate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Text_irate")
        -- local uiAtlasLabel_rate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"AtlasLabel_rate")
        -- local uiImage_rate = ccui.Helper:seekWidgetByName(uiButton_roomTypeInfo,"Image_rate")
        if self.tableFriendsRoomParams ~= nil and self.tableFriendsRoomParams[i] ~= nil then
            local data = self.tableFriendsRoomParams[i]
            uiButton_roomTypeInfo.data = data
            uiText_irate:setVisible(true)
            if data.dwMaxScore ~= 0 then
                uiText_irate:setString(string.format("%d -- %d",data.dwMinScore,data.dwMaxScore))
            else
                uiText_irate:setString(string.format("%d -- 无限",data.dwMinScore))
            end
            uiText_info:setVisible(true)
            uiText_info:setString(string.format("倍率  %d",data.wCellScore))
            -- uiAtlasLabel_rate:setVisible(true)
            -- uiAtlasLabel_rate:setString(string.format("%d",data.wCellScore))
            -- uiImage_rate:setVisible(true)
        end
    end 
end

--刷新个人信息
function GoldRoomCreateLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

function GoldRoomCreateLayer:updateUserInfo()

    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   

    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")    
    uiText_gold:setString(string.format("%s",Common:itemNumberToString(UserData.User.dwGold)))   

    local uiText_money = ccui.Helper:seekWidgetByName(self.root,"Text_money")    
    uiText_money:setString(string.format("%d",UserData.Bag:getBagPropCount(1008)))  

end

--获取房间ip地址和端口成功
function GoldRoomCreateLayer:SUB_CL_GAME_SERVER(event)
    local data = event._usedata
    UserData.Game:sendMsgConnectGame(data)           
end

function GoldRoomCreateLayer:SUB_CL_GAME_SERVER_ERROR(event)
    local data = event._usedata
    require("common.MsgBoxLayer"):create(0,nil,"服务器暂未开启！")         
end

function GoldRoomCreateLayer:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    local data = event._usedata
    require("common.MsgBoxLayer"):create(0,nil,"连接游戏服失败！")
end

function GoldRoomCreateLayer:SUB_GR_LOGON_SUCCESS(event)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_MATCH_REDENVELOPE_TABLE,"w",self.cbLevel)
    --记录
    cc.UserDefault:getInstance():setIntegerForKey('quick_game_level', self.cbLevel)
end

function GoldRoomCreateLayer:SUB_GR_MATCH_TABLE_ING(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID, data),SCENE_GAME)
end

function GoldRoomCreateLayer:SUB_GR_MATCH_TABLE_FAILED(event)
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

function GoldRoomCreateLayer:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID, data),SCENE_GAME)
end


return GoldRoomCreateLayer

