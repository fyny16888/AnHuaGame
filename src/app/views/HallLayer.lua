local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local NetMsgId = require("common.NetMsgId")
local HttpUrl = require("common.HttpUrl")

local HallLayer = class("HallLayer", cc.load("mvc").ViewBase)
function HallLayer:onEnter()
    NetMgr:getGameInstance():closeConnect()
    EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:registListener(EventType.EVENT_TYPE_WITH_NEW,self,self.EVENT_TYPE_WITH_NEW)
    EventMgr:registListener(EventType.EVENT_TYPE_EMAIL_NEW,self,self.EVENT_TYPE_EMAIL_NEW)
    EventMgr:registListener(EventType.RET_HAVE_UNREAD_MAIL,self,self.RET_HAVE_UNREAD_MAIL)
    EventMgr:registListener(EventType.RET_JOIN_GUILD,self,self.RET_JOIN_GUILD)      --加入公会
    EventMgr:registListener(EventType.EVENT_TYPE_EXTERNAL_START_GAME,self,self.EVENT_TYPE_EXTERNAL_START_GAME) 
    EventMgr:registListener(EventType.EVENT_TYPE_RECHARGE_365,self,self.EVENT_TYPE_RECHARGE_365)
    EventMgr:registListener(EventType.RET_SPORTS_STATE,self,self.RET_SPORTS_STATE)
    EventMgr:registListener(EventType.RET_CLUB_CHAT_BACK_RECORD, self, self.RET_CLUB_CHAT_BACK_RECORD)
    EventMgr:registListener(EventType.RET_NOTICE_GAME_START, self, self.RET_NOTICE_GAME_START)
    cc.Director:getInstance():getRunningScene():addChild(cc.CSLoader:createNode("EffectsLayer.csb"),0x10001,0x10001)
    
    local OperationLayer = cc.UserDefault:getInstance():getStringForKey("UserDefault_Operation","")
    if OperationLayer == "NewClubInfoLayer" then
        local dwClubID = cc.UserDefault:getInstance():getIntegerForKey("UserDefault_NewClubID", 0)
        if dwClubID ~= 0 then
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubInfoLayer"))
        end
    elseif OperationLayer ~= "" then
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView(OperationLayer))
    end
    local gotoIndex = cc.UserDefault:getInstance():getIntegerForKey("record_hall",0)
    if gotoIndex == 1 then
        local box = require("app.MyApp"):create():createView('NewRecord')
        require("common.SceneMgr"):switchOperation(box)
    end

    UserData.User:sendMsgUpdateUserInfo(1) 
    UserData.Sports:getSportsState()
    UserData.Email:sendMsgRequestEmail()
    UserData.Chat:sendChat()
    self:createGlobalCustomNode()
end

function HallLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
    EventMgr:unregistListener(EventType.EVENT_TYPE_WITH_NEW,self,self.EVENT_TYPE_WITH_NEW)
    EventMgr:unregistListener(EventType.EVENT_TYPE_EMAIL_NEW,self,self.EVENT_TYPE_EMAIL_NEW)
    EventMgr:unregistListener(EventType.RET_HAVE_UNREAD_MAIL,self,self.RET_HAVE_UNREAD_MAIL)
    EventMgr:unregistListener(EventType.RET_JOIN_GUILD,self,self.RET_JOIN_GUILD) 
    EventMgr:unregistListener(EventType.EVENT_TYPE_EXTERNAL_START_GAME,self,self.EVENT_TYPE_EXTERNAL_START_GAME) 
    EventMgr:unregistListener(EventType.EVENT_TYPE_RECHARGE_365,self,self.EVENT_TYPE_RECHARGE_365)
    EventMgr:unregistListener(EventType.RET_SPORTS_STATE,self,self.RET_SPORTS_STATE)
    EventMgr:unregistListener(EventType.RET_CLUB_CHAT_BACK_RECORD, self, self.RET_CLUB_CHAT_BACK_RECORD)
    EventMgr:unregistListener(EventType.RET_NOTICE_GAME_START, self, self.RET_NOTICE_GAME_START)
end

function HallLayer:onCreate(parames)
    if UserData.User.isFirstEnterHall == true then
        UserData.User.isFirstEnterHall = false
        EventMgr:dispatch(EventType.EVENT_TYPE_FIRST_ENTER_HALL)
    end
    if parames[1] == true then
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(1.0),
            cc.CallFunc:create(function(sender,event) 
                -- if StaticData.Hide[CHANNEL_ID].btn1 == 1 and UserData.Guild.dwGuildID == 0 and Common:isToday(cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_Guil,0)) == false  then
                --     if CHANNEL_ID ~= 20 and  CHANNEL_ID ~= 21 then
                --         self:addChild(require("app.MyApp"):create():createView("GuilLayer"))   
                --     end
                -- end
                -- if StaticData.Hide[CHANNEL_ID].btn12 == 1 and Common:isToday(cc.UserDefault:getInstance():getIntegerForKey(string.format(Default.UserDefault_Sign,UserData.User.userID),0)) == false then
                --     self:addChild(require("app.MyApp"):create(1000):createView("WelfareLayer"))  
                -- end 

                ----暂时屏蔽
                -- if  Common:isToday(cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_TuHaoActivity,0)) == false then
                --     require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("BouncedLayer")) 
                -- end 

            end)))
    end
 	 
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    --local halllayer = StaticData.Channels[CHANNEL_ID].halllayer
    local csb = cc.CSLoader:createNode("HallLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb    
    self.showMode = 0
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    if uiButton_return ~= nil then
        Common:addTouchEventListener(uiButton_return,function()
            require("common.MsgBoxLayer"):create(1,nil,"您确定要退出游戏？",function() 
                NetMgr:getLogicInstance():closeConnect()
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,true):createView("LoginLayer"),SCENE_LOGIN)
                EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
            end)
        end)   
    end 

    local uiButton_Goldgame_1 = ccui.Helper:seekWidgetByName(self.root,"Button_Goldgame_1")
    if uiButton_Goldgame_1 ~= nil then
        Common:addTouchEventListener(uiButton_Goldgame_1,function()
            require("app.MyApp"):create(function() 
                -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("GoldRoomCreateLayer"))

                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("RoomCreateLayer"))
            end):createView("InterfaceCheckRoomNode")
        end)
    end 

    local uiButton_Goldgame_2 = ccui.Helper:seekWidgetByName(self.root,"Button_Goldgame_2")
    if uiButton_Goldgame_2 ~= nil then
        Common:addTouchEventListener(uiButton_Goldgame_2,function()
            require("app.MyApp"):create(function() 
                -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(3):createView("GoldRoomCreateLayer"))
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("RoomCreateLayer"))
            end):createView("InterfaceCheckRoomNode")
        end)
    end 

    local uiButton_Goldgame_3 = ccui.Helper:seekWidgetByName(self.root,"Button_Goldgame_3")
    if uiButton_Goldgame_3 ~= nil then
        Common:addTouchEventListener(uiButton_Goldgame_3,function()
            require("app.MyApp"):create(function() 
                -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("GoldRoomCreateLayer"))
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(3):createView("RoomCreateLayer"))
            end):createView("InterfaceCheckRoomNode")
        end)
    end 

    -- local uiButton_Goldgame = ccui.Helper:seekWidgetByName(self.root,"Button_Goldgame")
    -- if uiButton_Goldgame ~= nil then
    --     Common:addTouchEventListener(uiButton_Goldgame,function()
    --         require("app.MyApp"):create(function() 
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GoldRoomCreateLayer"))
    --         end):createView("InterfaceCheckRoomNode")
    --     end)
    -- end 

    --邀请有礼
    local uiButton_invite = ccui.Helper:seekWidgetByName(self.root,"Button_invite")
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then
        uiButton_invite:setVisible(false)
    end
    if  uiButton_invite ~= nil then
        Common:addTouchEventListener(uiButton_invite,function() 
            --require("app.MyApp"):create(self.data):createView("DailyShareLayer") 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("Recommend"))   
        end) 
    end 
    --代开
    local uiButton_proxy  = ccui.Helper:seekWidgetByName(self.root,"Button_proxy")
    if uiButton_proxy~= nil then 
        if StaticData.Hide[CHANNEL_ID].btn11 == 1 then         
            uiButton_proxy:setVisible(true)        
            Common:addTouchEventListener(uiButton_proxy,function()        
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("ProxyLayer"))
            end) 
        else
            uiButton_proxy:setVisible(false) 
        end 
    end 



    -- --消息
    -- local uiButton_message  = ccui.Helper:seekWidgetByName(self.root,"Button_message")
    -- if uiButton_message~= nil then 
    --     -- if StaticData.Hide[CHANNEL_ID].btn11 == 1 then      
    --         uiButton_message:setVisible(true)        
    --         Common:addTouchEventListener(uiButton_message,function()     
    --         require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("BouncedLayer")) 
    --         end) 
    --     -- else
    --     --     uiButton_proxy:setVisible(false) 
    --     -- end 
    -- end 


    --福利
    local uiButton_welfare = ccui.Helper:seekWidgetByName(self.root,"Button_welfare")
    if uiButton_welfare~= nil then 
        Common:addTouchEventListener(uiButton_welfare,function()      
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("WelfareLayer"))
        end)
        if StaticData.Hide[CHANNEL_ID].btn3 ~= 1 then
            uiButton_welfare:setVisible(false)
        end
    end 

    --切换地区 地区显示
    local uiButton_region = ccui.Helper:seekWidgetByName(self.root,"Button_region") 
    if uiButton_region~= nil then  
        local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
        local uiImage_region = ccui.Helper:seekWidgetByName(self.root,"Image_region")
        uiImage_region:loadTexture(StaticData.Regions[regionID].nameImgs)
        Common:addTouchEventListener(uiButton_region,function() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RegionLayer"))
        end)     
        if StaticData.Hide[CHANNEL_ID].btn6 == 0 then
            local uiImage_bgregion =  ccui.Helper:seekWidgetByName(self.root,"Image_bgregion")
            uiImage_bgregion:setVisible(false)
            uiButton_region:setVisible(false)
            uiImage_region:setVisible(false)
            local uiPanel_quick = ccui.Helper:seekWidgetByName(self.root,"Panel_quick")
            if CHANNEL_ID == 18 or CHANNEL_ID == 19 then     
                uiPanel_quick:setPositionX(uiPanel_quick:getParent():getContentSize().width*0.5)
            else
                uiPanel_quick:setPositionX(uiPanel_quick:getParent():getContentSize().width*0.506)
            end
        end
    end 

    --商城   
    local uiButton_mall = ccui.Helper:seekWidgetByName(self.root,"Button_mall")
    if uiButton_mall~= nil then 
        Common:addTouchEventListener(uiButton_mall,function() 
         --   require("app.views.NewXXMallLayer"):create(2)
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("NewXXMallLayer"))
        end)      
        -- if StaticData.Hide[CHANNEL_ID].btn8 ~= 1 and  StaticData.Hide[CHANNEL_ID].btn9 ~= 1 then 
        --     uiButton_mall:setVisible(false)
        -- end 
    end
  
 
    --公会
    -- local uiButton_guild = ccui.Helper:seekWidgetByName(self.root,"Button_guild")
    -- if uiButton_guild ~= nil then 
    --     if StaticData.Hide[CHANNEL_ID].btn1 ~= 1 then
    --         uiButton_guild:setVisible(false)
    --     end                       
    --     Common:addTouchEventListener(uiButton_guild,function()  
    --         if (CHANNEL_ID == 8 or CHANNEL_ID == 9 ) and UserData.Guild.dwGuildID ~= 0 then
    --             UserData.Share:openURL(StaticData.Channels[CHANNEL_ID].guildFunction)
    --         elseif CHANNEL_ID == 20 or CHANNEL_ID == 21 then             
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer_6"))
    --         else
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GuilLayer"))
    --         end        
    --     end)              
    -- end

    --个人信息
    local uiButton_avatarBg = ccui.Helper:seekWidgetByName(self.root,"Button_avatarBg")
 --   if  uiButton_avatarBg ~= nil and StaticData.Hide[CHANNEL_ID].btn19 == 1 then 
        uiButton_avatarBg:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then    
                    Common:palyButton()        
                    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("UserInfoLayer"))             
            end
        end)             
 --   end 

    --实名认证
    local uiButton_PerfectInfo = ccui.Helper:seekWidgetByName(self.root,"Button_PerfectInfo")
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then
        uiButton_PerfectInfo:setVisible(false)
    end
    if  uiButton_PerfectInfo ~= nil then 
        Common:addTouchEventListener(uiButton_PerfectInfo,function() 
        
            -- if CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 then 
                 require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("PerfectInfoLayer"))
            -- else
            --     require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("PerfectInfoLayer_6"))
            -- end 
        end)   
    end 


    

    
    --溆浦客服信息
    local uiPanel_bounced = ccui.Helper:seekWidgetByName(self.root,"Panel_bounced")
    if uiPanel_bounced ~= nil then 
        uiPanel_bounced:setVisible(false) 
        local uiPanel_Tel = ccui.Helper:seekWidgetByName(self.root,"Panel_Tel")
        local uiText_tel = ccui.Helper:seekWidgetByName(uiPanel_Tel,"Text_tel")
        if UserData.Share.tableCustomerParameter.szSettingInfo ~= nil then
            uiText_tel:setString(UserData.Share.tableCustomerParameter.szSettingInfo)
        end        
        Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_close"),function() 
            --设置
            uiPanel_bounced:setVisible(false)
        end)
    end
        
    --房卡转道具商城    
    local uiButton_roomCardBg = ccui.Helper:seekWidgetByName(self.root,"Button_roomCardBg")
    if uiButton_roomCardBg ~= nil and StaticData.Hide[CHANNEL_ID].btn20 == 1 then   
        uiButton_roomCardBg:setEnabled(true)
        Common:addTouchEventListener(uiButton_roomCardBg,function()             
            require("app.views.AgentLayer"):create()
            --require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) 
        end)      
    end            
   
    local uiImage_roomCard = ccui.Helper:seekWidgetByName(self.root,"Image_roomCard") 
    uiImage_roomCard:setEnabled(true)         
    uiImage_roomCard:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then 
            Common:palyButton() 
            --require("app.views.AgentLayer"):create()
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(2):createView("NewXXMallLayer")) 
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
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(3):createView("NewXXMallLayer")) 
        end)    
    end

    local uiImage_money = ccui.Helper:seekWidgetByName(self.root,"Image_money") 
    uiImage_money:setEnabled(true)         
    uiImage_money:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then 
            Common:palyButton() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(3):createView("NewXXMallLayer")) 
        end 
    end)


     
    --邮件
    local uiButton_email = ccui.Helper:seekWidgetByName(self.root,"Button_email")
    if uiButton_email ~= nil then
        Common:addTouchEventListener(uiButton_email,function() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("EmailLayer"))
        end)
        local uiImage_look = ccui.Helper:seekWidgetByName(self.root,"Image_look")
        uiImage_look:setVisible(false)
    end 
    --设置
    local uiButton_setting = ccui.Helper:seekWidgetByName(self.root,"Button_setting")
    if uiButton_setting ~= nil then
        Common:addTouchEventListener(uiButton_setting,function()             
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(1):createView("SettingsLayer"))
        end)
    end    
    --游戏规则
    local uiButton_game = ccui.Helper:seekWidgetByName(self.root,"Button_game")
    if uiButton_game ~= nil then
        Common:addTouchEventListener(uiButton_game,function()      
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("GameplayLayer"))
        end)
    end  
    --战绩 
    local uiButton_record = ccui.Helper:seekWidgetByName(self.root,"Button_record")
    if uiButton_record ~= nil then
        Common:addTouchEventListener(uiButton_record,function() 
            local box = require("app.MyApp"):create():createView('NewRecord')
            require("common.SceneMgr"):switchOperation(box)
        end) 
    end
    -- if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then 
    --     uiButton_record:setVisible(false)    
    -- end    


    --亲友圈 
    local uiButton_club = ccui.Helper:seekWidgetByName(self.root,"Button_club")
    if uiButton_club ~= nil then
        Common:addTouchEventListener(uiButton_club,function()
            -- local dwClubID = cc.UserDefault:getInstance():getIntegerForKey("UserDefault_NewClubID", 0)
            -- if dwClubID ~= 0 then
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubInfoLayer"))
            -- else
            --     require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubLayer"))
            -- end
        end)
    end

    --创房、加入按钮处理       
    local uiButton_createFriendsRoom = ccui.Helper:seekWidgetByName(self.root,"Button_createFriendsRoom")
    if uiButton_createFriendsRoom ~= nil then
        Common:addTouchEventListener(uiButton_createFriendsRoom,function()  
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RoomCreateLayer"))
            end):createView("InterfaceCheckRoomNode")  
        end)
    end  
    local uiButton_joinFriendsRoom = ccui.Helper:seekWidgetByName(self.root,"Button_joinFriendsRoom")
    if uiButton_joinFriendsRoom ~= nil then
        Common:addTouchEventListener(uiButton_joinFriendsRoom,function() 
            require("app.MyApp"):create(function() 
                require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RoomJoinLayer"))
            end):createView("InterfaceCheckRoomNode")
        end)
    end  


    -- --溆浦游戏创房
    -- local uiButton_xupu = ccui.Helper:seekWidgetByName(self.root,"Button_xupu")
    -- if uiButton_xupu ~= nil then
    --     Common:addTouchEventListener(uiButton_xupu,function()   
    --         require("app.MyApp"):create(function() 
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(42):createView("RoomCreateLayer"))      
    --         end):createView("InterfaceCheckRoomNode")    
    --     end)
    -- end
    -- local uiButton_paohuzi = ccui.Helper:seekWidgetByName(self.root,"Button_paohuzi")
    -- if uiButton_paohuzi ~= nil then
    --     Common:addTouchEventListener(uiButton_paohuzi,function()   
    --         require("app.MyApp"):create(function() 
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(43):createView("RoomCreateLayer"))      
    --         end):createView("InterfaceCheckRoomNode")            
    --     end)
    -- end

    -- local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")
    -- if uiButton_majiang ~= nil then
    --     Common:addTouchEventListener(uiButton_majiang,function()  
    --         require("app.MyApp"):create(function() 
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(52):createView("RoomCreateLayer"))      
    --         end):createView("InterfaceCheckRoomNode")             
    --     end)
    -- end
    -- local uiButton_moregame = ccui.Helper:seekWidgetByName(self.root,"Button_moregame")
    -- if uiButton_moregame ~= nil then
    --     Common:addTouchEventListener(uiButton_moregame,function()  
    --         require("app.MyApp"):create(function() 
    --             require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(25):createView("RoomCreateLayer"))      
    --         end):createView("InterfaceCheckRoomNode")             
    --     end)
    -- end 

    -- --竞技场
    local uiButton_sports = ccui.Helper:seekWidgetByName(self.root,"Button_sports")
    if uiButton_sports ~= nil then
        Common:addTouchEventListener(uiButton_sports,function() 
            --require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("SportsLayer"))
            require("common.MsgBoxLayer"):create(0,nil,"暂未开放")
        end) 
    end  

    --快速开始
    -- local wKindID = cc.UserDefault:getInstance():getIntegerForKey('quick_game_kindId', 78)
    -- local cbLevel = cc.UserDefault:getInstance():getIntegerForKey('quick_game_level', 1)
    -- local Button_quickStart = ccui.Helper:seekWidgetByName(self.root,"Button_quickStart")
    -- Common:addTouchEventListener(Button_quickStart,function() 
    --     require("common.SceneMgr"):switchTips(require("app.MyApp"):create(wKindID):createView("QuickStartGameNode"))
    -- end) 
    -- local Text_quickName = ccui.Helper:seekWidgetByName(self.root,"Text_quickName")
    -- local gameName = StaticData.Games[wKindID].name or ''
    -- local levelName = '(初级场)'
    -- if cbLevel == 2 then
    --     levelName = '(中级场)'
    -- elseif cbLevel == 3 then
    --     levelName = '(高级场)'
    -- end
    -- Text_quickName:setString(gameName .. levelName)

    -- local uiText_donghua1 = ccui.Helper:seekWidgetByName(self.root,"Text_donghua1")
    -- if uiText_donghua1~= nil then  
    --     local function TextActionS(sender,event)
    --         uiText_donghua1:runAction(cc.Sequence:create(--cc.ScaleTo:create(0.2,1.0),
    --         cc.ScaleTo:create(0.4,1.1),cc.ScaleTo:create(0.2,1),
    --         -- cc.ScaleTo:create(0.4,1.1),cc.ScaleTo:create(0.2,1),
    --         -- cc.ScaleTo:create(0.4,1.1),cc.ScaleTo:create(0.2,1),
    --         -- cc.ScaleTo:create(0.1,0),
    --         cc.Sequence:create(cc.DelayTime:create(3),cc.CallFunc:create(TextActionS))))           
    --     end      
    --     TextActionS()
    -- end

    --广播
    local uiPanel_broadcast = ccui.Helper:seekWidgetByName(self.root,"Panel_broadcast")
    local uiText_broadcast = ccui.Helper:seekWidgetByName(self.root,"Text_broadcast")
    local function showBroadcast(sender,event)
        if UserData.Notice.cycleBroadcast ~= nil and uiPanel_broadcast:isVisible() == false then
            local data = UserData.Notice.cycleBroadcast
            uiText_broadcast:setString(data.szBroadcastInfo)
            print(uiText_broadcast:getAutoRenderSize().width)
            local time = (uiText_broadcast:getParent():getContentSize().width + uiText_broadcast:getAutoRenderSize().width)/100
            uiText_broadcast:setPositionX(uiText_broadcast:getParent():getContentSize().width)
            uiText_broadcast:runAction(cc.MoveTo:create(time,cc.p(-uiText_broadcast:getAutoRenderSize().width,uiText_broadcast:getPositionY())))
            uiPanel_broadcast:runAction(cc.Sequence:create(cc.DelayTime:create(time),cc.Hide:create(),cc.DelayTime:create(5),cc.CallFunc:create(showBroadcast)))
            uiPanel_broadcast:setVisible(true)
            uiText_broadcast:setVisible(true)
        else
            uiPanel_broadcast:setVisible(false)
            uiPanel_broadcast:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(showBroadcast)))
        end
    end
    showBroadcast()

    --底排按钮排列距离
    -- if CHANNEL_ID ~= 18 and CHANNEL_ID ~= 19 and CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 and  CHANNEL_ID ~= 4 and CHANNEL_ID ~= 5 then
    --     local uiListView_function = ccui.Helper:seekWidgetByName(self.root,"ListView_function")                
    --     if #uiListView_function:getItems() == 8 then
    --     uiListView_function:setItemsMargin(109)
    --     end
    --     if #uiListView_function:getItems() == 7 then
    --     uiListView_function:setItemsMargin(130)
    --     end
    --     if #uiListView_function:getItems() == 6 then
    --     uiListView_function:setItemsMargin(168)
    --     end
    --     if #uiListView_function:getItems() == 5 then
    --     uiListView_function:setItemsMargin(190)
    --     end
    -- end

    --商务合作
    local uiButton_recruit = ccui.Helper:seekWidgetByName(self.root,"Button_recruit")
    if uiButton_recruit ~= nil then 
        Common:addTouchEventListener(uiButton_recruit,function() 
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("RecruitLayer"))
        end)
    end 
    local uiText_customer_1 = ccui.Helper:seekWidgetByName(self.root,"Text_customer_1") 
    if uiText_customer_1 ~= nil then    
        uiText_customer_1:setString(string.format("%s",StaticData.Channels[CHANNEL_ID].serviceVX_1))
        local uiText_customer_2 = ccui.Helper:seekWidgetByName(self.root,"Text_customer_2")
        uiText_customer_2:setString(string.format("%s",StaticData.Channels[CHANNEL_ID].serviceVX_2))                    
    end
    
    --大厅分享
    local uiButton_doshare = ccui.Helper:seekWidgetByName(self.root,"Button_doshare")
    if uiButton_doshare ~= nil then           
        Common:addTouchEventListener(uiButton_doshare,function() 
            local data = clone(UserData.Share.tableShareParameter[0])
            require("app.MyApp"):create(data):createView("ShareLayer")   
        end)  
    end 


    --分享
    local uiButton_activity = ccui.Helper:seekWidgetByName(self.root,"Button_activity")
    if uiButton_activity ~= nil then           
        Common:addTouchEventListener(uiButton_activity,function() 
            -- local data = clone(UserData.Share.tableShareParameter[0])
            -- require("app.MyApp"):create(data):createView("ActivityLayer")   
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("ActivityLayer"))
        end)  
    end
    

    
    --实名实名认证
    local uiButton_PerfectInfo = ccui.Helper:seekWidgetByName(self.root,"Button_PerfectInfo")
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then
        uiButton_PerfectInfo:setVisible(false)
    end
    if  uiButton_PerfectInfo ~= nil then 
        Common:addTouchEventListener(uiButton_PerfectInfo,function()         
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("PerfectInfoLayer"))
        end)   
    end 

    --郑重声明
    local uiButton_SolemnlyState = ccui.Helper:seekWidgetByName(self.root,"Button_SolemnlyState")
    if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then
        uiButton_SolemnlyState:setVisible(false)
    end
    if  uiButton_SolemnlyState ~= nil then 
        Common:addTouchEventListener(uiButton_SolemnlyState,function()         
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("SolemnlyStateLayer"))
        end)   
    end


    
    
    -- local cusNode = cc.Director:getInstance():getNotificationNode()

    -- -- local cusNode = ccui.Helper:seekWidgetByName(self.root,"cusNode")
	-- local path_1 = string.format('newcommon/anima/diaochan')
    -- local skeletonNode_1 = sp.SkeletonAnimation:create(path_1 .. '.json', path_1 .. '.atlas', 1)
    -- -- skeletonNode:setScale(1.5)
    -- cusNode:addChild(skeletonNode_1)
	-- skeletonNode_1:setPosition(skeletonNode_1:getParent():getContentSize().width/2,skeletonNode_1:getParent():getContentSize().height/2)
	-- skeletonNode_1:setAnimation(0, 'animation', true)
    -- skeletonNode_1:setVisible(true)
    
    -- local cusHuaNode = ccui.Helper:seekWidgetByName(self.root,"cusHuaNode")
	-- local path_2 = string.format('newcommon/anima/taohua')
    -- local skeletonNode_2 = sp.SkeletonAnimation:create(path_2 .. '.json', path_2 .. '.atlas', 1)
    -- -- skeletonNode:setScale(1.0)
    -- cusHuaNode:addChild(skeletonNode_2)
	-- skeletonNode_2:setPosition(skeletonNode_2:getParent():getContentSize().width/2,skeletonNode_2:getParent():getContentSize().height/2)
	-- skeletonNode_2:setAnimation(0, 'animation', true)
	-- skeletonNode_2:setVisible(true)

    -- if StaticData.Hide[CHANNEL_ID].btn20 ~= 1 then 
    --     uiButton_doshare:setVisible(false)    
    -- end    

    --个人历史战绩
    local uiButton_historicalRecord = ccui.Helper:seekWidgetByName(self.root,"Button_historicalRecord")
    if uiButton_historicalRecord ~= nil then
        Common:addTouchEventListener(uiButton_historicalRecord,function() 
            local data = clone(UserData.Share.tableShareParameter[11])
            require("app.MyApp"):create(data):createView("ShareLayer")  
        end) 
    end 

    --代理咨询
    local uiButton_dailis = ccui.Helper:seekWidgetByName(self.root,"Button_dailis")
    if uiButton_dailis ~= nil then
        Common:addTouchEventListener(uiButton_dailis,function()            
            require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("DaiLiLayer"))
        end) 
    end  
    self:updateUserInfo()

    -- --兑换中心
    -- local Button_duihuan = ccui.Helper:seekWidgetByName(self.root,"Button_duihuan")
    -- Common:addTouchEventListener(Button_duihuan,function()            
    --     require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("ExchangeCenterLayer"))
    -- end)
    -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("common/dhzx/dhzx.ExportJson")
    -- local armature=ccs.Armature:create("dhzx")
    -- armature:getAnimation():playWithIndex(0)
    -- Button_duihuan:addChild(armature)
    -- armature:setPosition(armature:getParent():getContentSize().width/2,armature:getParent():getContentSize().height/2)
end

--刷新个人信息
function HallLayer:SUB_CL_USER_INFO(event)
    self:updateUserInfo()
end

function HallLayer:updateUserInfo(event)

    local uiImage_avatar = ccui.Helper:seekWidgetByName(self.root,"Image_avatar")
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")    
    uiText_name:setString(string.format("%s",UserData.User.szNickName))
    local uiButton_goldBg = ccui.Helper:seekWidgetByName(self.root,"Button_goldBg")
    
    local uiText_roomCard = ccui.Helper:seekWidgetByName(self.root,"Text_roomCard")    
    uiText_roomCard:setString(string.format("%d",UserData.Bag:getBagPropCount(1003)))   

    local uiText_gold = ccui.Helper:seekWidgetByName(self.root,"Text_gold")    
    uiText_gold:setString(string.format("%s",Common:itemNumberToString(UserData.User.dwGold)))   

    local uiText_money = ccui.Helper:seekWidgetByName(self.root,"Text_money")    
    uiText_money:setString(string.format("%d",UserData.Bag:getBagPropCount(1008)))  

    local uiText_ID = ccui.Helper:seekWidgetByName(self.root,"Text_ID")
    uiText_ID:setString(string.format("ID:%d",UserData.User.userID))
    Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,uiImage_avatar,"img")

    if  CHANNEL_ID ~= 4 and CHANNEL_ID ~= 5  and CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 and self.sCircle~= nil then       
        local number = 2  
        if   UserData.Welfare.tableWelfare[1004] ~=nil and  UserData.Welfare.tableWelfare[1004].IsEnded == 1 then 
            number = number -1 
        end 
        if    UserData.Welfare.tableWelfare[1005] ~=nil and UserData.Welfare.tableWelfare[1005].IsEnded == 1 then 
            number = number -1 
        end          
        self.sCircle:removeAllChildren()
        local uiText_title = cc.Label:createWithSystemFont(number,"Arial",24)
        uiText_title:setAnchorPoint(cc.p(0.5,0.5))
        uiText_title:setTextColor(cc.c3b(255,255,255))
        self.sCircle:addChild(uiText_title)
        uiText_title:setPosition(uiText_title:getParent():getContentSize().width/2,uiText_title:getParent():getContentSize().height/2+3)--cc.p(uiText_title:getPosition()
        if number == 0 then 
            self.sCircle:setVisible(false)
        elseif  number > 0 then  
            self.sCircle:setVisible(true)
        end
    end                
end


function HallLayer:EVENT_TYPE_EXTERNAL_START_GAME(event)
    if UserData.User.externalAdditional ~= "" then
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(tonumber(UserData.User.externalAdditional)):createView("RoomJoinLayer"))
    end
end

function HallLayer:EVENT_TYPE_WITH_NEW(event)
    local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
    local uiImage_region = ccui.Helper:seekWidgetByName(self.root,"Image_region")
    uiImage_region:loadTexture(StaticData.Regions[regionID].nameImgs)
    UserData.Game:loadGameData()
end

function HallLayer:RET_HAVE_UNREAD_MAIL(event) 
    local ret = event._usedata
    local uiImage_look = ccui.Helper:seekWidgetByName(self.root,"Image_look")
    if ret.lRet ~= nil and ret.lRet > 0 then
        uiImage_look:setVisible(true)
    else
        uiImage_look:setVisible(false)
    end 
    local uiText_number = ccui.Helper:seekWidgetByName(self.root,"Text_number")
    uiText_number:setString(ret.lRet)

end 

function HallLayer:EVENT_TYPE_EMAIL_NEW(event) 
    if  CHANNEL_ID == 18 or   CHANNEL_ID == 19 or  CHANNEL_ID == 20 or   CHANNEL_ID == 21 or  CHANNEL_ID == 4 or   CHANNEL_ID == 5 then 
       return  
    end 
    local uiImage_look = ccui.Helper:seekWidgetByName(self.root,"Image_look")
    local number = 0 
    if UserData.Email.tableEmail == nil then 
        return
    end 
    for i = 1 , #UserData.Email.tableEmail do
        if  UserData.Email.tableEmail[i].bRead == false then 
            number = number + 1
        end 
    end 
   
    if number > 0 then 
        uiImage_look:setVisible(true)
    else
        uiImage_look:setVisible(false)
    end 
    local uiText_number = ccui.Helper:seekWidgetByName(self.root,"Text_number")
    uiText_number:setString(number)
       
end

function HallLayer:EVENT_TYPE_RECHARGE_365(event)
    local ret = event._usedata
    local uiButton_topup = ccui.Helper:seekWidgetByName(self.root,"Button_topup")
    if ret == 0 then
        uiButton_topup:setVisible(false)
    else
        uiButton_topup:setVisible(true)
    end
end

function HallLayer:RET_JOIN_GUILD(event)
    local data = event._usedata  
    if CHANNEL_ID == 20 or  CHANNEL_ID == 21 then       
        if data.ret == 0 then   
            UserData.Guild.dwID = data.dwID
            UserData.Guild.dwGuildID = data.dwGuildID
            UserData.Guild.szGuildName = data.szGuildName
            UserData.Guild.szGuildNotice = data.szGuildNotice
            UserData.Guild.dwMemberCount = data.dwMemberCount
            UserData.Guild.dwPresidentID = data.dwPresidentID
            UserData.Guild.szPresidentName = data.szPresidentName
            UserData.Guild.szPresidentLogo = ""
            
--            if CHANNEL_ID ~= 8 and  CHANNEL_ID ~= 9 then      
--                require("common.RewardLayer"):create("公会",nil,{{wPropID = 1003,dwPropCount = 5 }})    
--            end 
            UserData.User:sendMsgUpdateUserInfo(1)   
        else 
            require("common.MsgBoxLayer"):create(0,nil,"请求失败！")          
        end
    end
end

function HallLayer:RET_SPORTS_STATE(event)
--     local data = event._usedata
--     local uiButton_sports = ccui.Helper:seekWidgetByName(self.root,"Button_sports")
--     local uiImage_sports = ccui.Helper:seekWidgetByName(self.root,"Image_sports")
--     -- if uiButton_sports == nil then
--     --     return
--     -- end
--     if data.isOpenSports == true then
-- --        uiButton_sports:setEnabled(true)
--         if CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 then
--              uiImage_sports:setVisible(false)
--         end 
--     else
--         uiButton_sports:setEnabled(false)
--         uiButton_sports:setVisible(false)
--         if CHANNEL_ID ~= 20 and CHANNEL_ID ~= 21 then
--             uiImage_sports:setVisible(true)
--             uiImage_sports:loadTexture("common/hall_97.png")
--         end 
--     end
end


--@cxx add 骨骼动画ios上释放崩溃，所以这里做个全局保存
function HallLayer:createGlobalCustomNode()
    local scene = cc.Director:getInstance():getRunningScene()
    local node = cc.Director:getInstance():getNotificationNode()
    if not node then
        node = cc.Node:create()
        scene:addChild(node)
        cc.Director:getInstance():setNotificationNode(node)
        printInfo('create global_node ...')
    else
        local arr = node:getChildren()
        for i,v in ipairs(arr) do
            v:setVisible(false)
        end
    end
end

-- 显示大厅骨骼动画
function HallLayer:showHallAnimation()
    --local cusNode = cc.Director:getInstance():getNotificationNode()     
    
    -- item:setName(data.dwClubID)
    -- local cusHuaNode = ccui.Helper:seekWidgetByName(self.root,"cusHuaNode")    
    -- cusNode:addChild(cusHuaNode) 
    -- cusHuaNode:setPosition(667.00,375.00)
	-- local path_1 = string.format('newcommon/anima/diaochan')
    -- local skeletonNode_1 = sp.SkeletonAnimation:create(path_1 .. '.json', path_1 .. '.atlas', 1)
    -- -- skeletonNode:setScale(1.5)
    -- cusHuaNode:addChild(skeletonNode_1)
	-- skeletonNode_1:setPosition(319.00,330.00)
	-- skeletonNode_1:setAnimation(0, 'animation', true)
    -- skeletonNode_1:setVisible(true)


   
    -- local path_2 = string.format('newcommon/anima/taohua')
    -- local skeletonNode_2 = sp.SkeletonAnimation:create(path_2 .. '.json', path_2 .. '.atlas', 1)
    -- -- skeletonNode:setScale(1.0)
    -- cusHuaNode:addChild(skeletonNode_2)
    -- skeletonNode_2:setPosition(667.00,375.00)
    -- skeletonNode_2:setAnimation(0, 'animation', true)
    -- skeletonNode_2:setVisible(true)
end 

function HallLayer:ShutDownHallAnimation()
    -- local cusNode = cc.Director:getInstance():getNotificationNode()
    -- local cusHuaNode = ccui.Helper:seekWidgetByName(cusNode,"cusHuaNode")    
    -- if (not cusNode)  and (not cusHuaNode) then
    --     printInfo('global_node is nil!')
    --     return
    -- end
    -- cusHuaNode:setVisible(false)
end 

function HallLayer:RET_CLUB_CHAT_BACK_RECORD(event)
    local data = event._usedata
    require("common.SceneMgr"):switchTips(require("app.MyApp"):create(data):createView("PleaseReciveLayer"))
end

function HallLayer:RET_NOTICE_GAME_START(event)
    local data = event._usedata
    dump(data,'游戏人满:')
    require("common.MsgBoxLayer"):create(1, nil, "游戏人数已满,是否进入?", function()
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(data.dwTableID):createView("InterfaceJoinRoomNode"))
    end)
end

return HallLayer

