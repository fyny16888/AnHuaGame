local PDKGameCommon = require("game.puke.PDKGameCommon")
local Bit = require("common.Bit")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local GameLogic = require("game.puke.GameLogic")
local Common = require("common.Common")

local GameEndLayer = class("GameEndLayer",function()
    return ccui.Layout:create()
end)

function GameEndLayer:create(pBuffer)
    local view = GameEndLayer.new()
    view:onCreate(pBuffer)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit()
        elseif eventType == "cleanup" then
            view:onCleanup()
        end  
    end  
    view:registerScriptHandler(onEventHandler)
    return view
end

function GameEndLayer:onEnter()
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:registListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
end

function GameEndLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_FAILED,self,self.SUB_GR_MATCH_TABLE_FAILED)
    EventMgr:unregistListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
end

function GameEndLayer:onCleanup()

end

function GameEndLayer:onCreate(pBuffer)       
    local csb = cc.CSLoader:createNode("GameLayerPaoDeKuai_End.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
        --动画
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/wuguidonghua/wuguidonghua.ExportJson")
    -- local armature2=ccs.Armature:create("wuguidonghua")
    -- armature2:getAnimation():playWithIndex(0)
    -- local uiImage_bg = ccui.Helper:seekWidgetByName(self.root,"Image_bg")
    -- uiImage_bg:addChild(armature2)
    -- armature2:setPosition(0,armature2:getParent():getContentSize().height)
    -- armature2:runAction(cc.MoveTo:create(20,cc.p(armature2:getParent():getContentSize().width,armature2:getPositionY())))
    
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setPressedActionEnabled(true)
    local function onEventReturn(sender,event)
    	if event == ccui.TouchEventType.ended then
            Common:palyButton()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    	end
    end
    uiButton_return:addTouchEventListener(onEventReturn)
    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
    uiButton_continue:setPressedActionEnabled(true)
    local function onEventContinue(sender,event)
    	if event == ccui.TouchEventType.ended then
            Common:palyButton()
            if PDKGameCommon.tableConfig.nTableType == TableType_FriendRoom or PDKGameCommon.tableConfig.nTableType == TableType_ClubRoom then
                if PDKGameCommon.tableConfig.wTableNumber == PDKGameCommon.tableConfig.wCurrentNumber then
                    EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                else
                    PDKGameCommon:ContinueGame(PDKGameCommon.tableConfig.cbLevel)
                end
            elseif PDKGameCommon.tableConfig.nTableType == TableType_GoldRoom or PDKGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then 
                PDKGameCommon:ContinueGame(PDKGameCommon.tableConfig.cbLevel)
            else
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            end          
    	end
    end
    uiButton_continue:addTouchEventListener(onEventContinue)
    if PDKGameCommon.tableConfig.nTableType == TableType_FriendRoom or PDKGameCommon.tableConfig.nTableType == TableType_ClubRoom then
        uiButton_return:setVisible(false)
        uiButton_continue:setPositionX(uiButton_continue:getParent():getContentSize().width/2)
    end

    local uiPanel_reward = ccui.Helper:seekWidgetByName(self.root,"Panel_reward")
    local uiButton_Gold = ccui.Helper:seekWidgetByName(self.root,"Button_Gold")
    local uiButton_Money = ccui.Helper:seekWidgetByName(self.root,"Button_Money")
    local uiText_Gold = ccui.Helper:seekWidgetByName(self.root,"Text_Gold")
    local uiText_Money = ccui.Helper:seekWidgetByName(self.root,"Text_Money")
    local Gold = math.floor( (pBuffer.lGameScore[PDKGameCommon.meChairID+1]*0.9)/ 1)
    local Money = math.floor( (pBuffer.lGameScore[PDKGameCommon.meChairID+1]*0.35)/ 1)
    uiText_Gold:setString(string.format("+%d",Gold))       
    uiText_Money:setString(string.format("+%d",Money))
    uiPanel_reward:setVisible(false)
    Common:addTouchEventListener(uiButton_Gold,function() 
        PDKGameCommon:GetReward(0)
    end)
    Common:addTouchEventListener(uiButton_Money,function() 
        PDKGameCommon:GetReward(1)
    end)
    local uiText_timedown = ccui.Helper:seekWidgetByName(self.root,"Text_timedown")
    if PDKGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom and pBuffer.lGameScore[PDKGameCommon.meChairID+1] > 0 then 
        uiPanel_reward:setVisible(true)
        uiButton_return:setVisible(false)
        uiButton_continue:setVisible(false)
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(15),
            cc.CallFunc:create(function(sender,event) 
                uiPanel_reward:setVisible(false)
                uiButton_return:setVisible(true)
                uiButton_continue:setVisible(true)
                PDKGameCommon:GetReward(0)
        end)))

        uiText_timedown:setString(15)        
        local function onEventTime(sender,event)
            local currentTime = tonumber(uiText_timedown:getString())
            currentTime = currentTime - 1
            if currentTime < 0 then
                currentTime = 0
            end
            uiText_timedown:setString(tostring(currentTime))   
            -- 自己出牌最后5秒倒计时音效
            if viewID == 1 and currentTime <= 5 and currentTime >=2 then
                self.warningID = Common:playEffect('majiang/sound/timeup_alarm.mp3')
            end
        end   
        uiText_timedown:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(onEventTime)))) 
    end

    local uiPanel_result = ccui.Helper:seekWidgetByName(self.root,"Panel_result")
--    local uiPanel_look = ccui.Helper:seekWidgetByName(self.root,"Panel_look")
    local uiButton_look = ccui.Helper:seekWidgetByName(self.root,"Button_look")
    Common:addTouchEventListener(uiButton_look,function() 
        if uiPanel_result:isVisible() then
            uiPanel_result:setVisible(false)
            uiButton_look:setBright(false)
        else
            uiPanel_result:setVisible(true)
            uiButton_look:setBright(true)
        end
    end)
    local uiText_info = ccui.Helper:seekWidgetByName(self.root,"Text_info")
    uiText_info:setString("")
    if PDKGameCommon.tableConfig.nTableType == TableType_GoldRoom or PDKGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
        uiText_info:setString(string.format("倍率：%d\n本局消耗：%d",PDKGameCommon.tableConfig.wCellScore,PDKGameCommon.tableConfig.wCellScore*0.5))
    end
    
    local viewID = PDKGameCommon:getViewIDByChairID(pBuffer.wWinUser)
    local Image_resultBg = ccui.Helper:seekWidgetByName(self.root,"Image_resultBg")
    local Image_result = ccui.Helper:seekWidgetByName(self.root,"Image_result")
    local Image_resultFont = ccui.Helper:seekWidgetByName(self.root,"Image_resultFont")
    local Image_starleft = ccui.Helper:seekWidgetByName(self.root,"Image_starleft")
    local Image_starright = ccui.Helper:seekWidgetByName(self.root,"Image_starright")
    Image_resultBg:ignoreContentAdaptWithSize(true)
    Image_starleft:ignoreContentAdaptWithSize(true)
    Image_starright:ignoreContentAdaptWithSize(true)
    if viewID == 1 then --自己胜
        Image_resultBg:loadTexture('puke/result/ok_ui_pdk_r_light.png')
        Image_result:loadTexture('puke/result/ok_ui_pdk_r_win_bg.png')
        Image_resultFont:loadTexture('puke/result/ok_ui_pdk_r_win_word.png')
        Image_starleft:loadTexture('puke/result/ok_ui_pdk_r_win_title.png')
        Image_starright:loadTexture('puke/result/ok_ui_pdk_r_win_title.png')
    else
        Image_resultBg:loadTexture('puke/result/ok_ui_pdk_r_cloud.png')
        Image_result:loadTexture('puke/result/ok_ui_pdk_r_fail_bg.png')
        Image_resultFont:loadTexture('puke/result/ok_ui_pdk_r_fail.png')
        Image_starleft:loadTexture('puke/result/ok_ui_pdk_r_fail_title.png')
        Image_starright:loadTexture('puke/result/ok_ui_pdk_r_fail_title.png')
    end
    
    local uiListView_player = ccui.Helper:seekWidgetByName(self.root,"ListView_player")
    for key, var in pairs(PDKGameCommon.player) do
        local viewID = PDKGameCommon:getViewIDByChairID(var.wChairID)           
        local root = ccui.Helper:seekWidgetByName(uiListView_player,string.format("Panel_player%d",viewID))
        -- local uiImage_avatar = ccui.Helper:seekWidgetByName(root,"Image_avatar")
        -- Common:requestUserAvatar(var.dwUserID,var.szPto,uiImage_avatar,"img") 
        local uiText_name = ccui.Helper:seekWidgetByName(root,"Text_name")       
        --uiText_name:setString(string.format("%s",var.szNickName)) 
        local name = Common:getShortName(var.szNickName,8,6)
        uiText_name:setString(name)

        local Image_winFlag = ccui.Helper:seekWidgetByName(root,"Image_winFlag")
        if pBuffer.wWinUser == var.wChairID then
            Image_winFlag:setVisible(true)
        else
            Image_winFlag:setVisible(false)
        end

        local uiText_surplus = ccui.Helper:seekWidgetByName(root,"Text_surplus")
        if pBuffer.bUserCardCount[key+1] >= PDKGameCommon.gameConfig.bSpringMinCount then
            uiText_surplus:setString(string.format("%d(全关)",pBuffer.bUserCardCount[key+1]))    
        else
            uiText_surplus:setString(string.format("%d",pBuffer.bUserCardCount[key+1]))
        end
        print("++++++++++++结算+++++++",key+1,pBuffer.cbFalseSpring[key+1])
        if pBuffer.cbFalseSpring[key+1] == true then
            uiText_surplus:setString(string.format("%d(假春天)",pBuffer.bUserCardCount[key+1]))    
        end
        local uiText_bomb = ccui.Helper:seekWidgetByName(root,"Text_bomb")
        uiText_bomb:setString(string.format("%d",pBuffer.cbBombCount[key+1]))
        local uiImage_red10 = ccui.Helper:seekWidgetByName(root,"Image_red10")
        if pBuffer.wChariIDred10 == var.wChairID then
            uiImage_red10:setVisible(true)
        else
            uiImage_red10:setVisible(false)
        end
        local uiText_piao = ccui.Helper:seekWidgetByName(root,"Text_piao")
        if PDKGameCommon.bJiaPiaoCount[key+1] ~= nil and PDKGameCommon.bJiaPiaoCount[key+1] ~= 0  then
           uiText_piao:setString(string.format("%d",PDKGameCommon.bJiaPiaoCount[key+1]))
        end 
        local uiText_result = ccui.Helper:seekWidgetByName(root,"Text_result")
        uiText_result:setString(string.format("%d",pBuffer.lGameScore[key+1]))      
        local uiText_abandon = ccui.Helper:seekWidgetByName(root,"Text_abandon")
        if pBuffer.wChariIDAbandon == var.wChairID then
            uiText_abandon:setString("(放走包赔)")
            Image_winFlag:setVisible(false)
        -- elseif pBuffer.wWinUser == var.wChairID then
        --     uiText_abandon:setString("(上游)")
        else
            uiText_abandon:setString("")
        end

        if var.wChairID == PDKGameCommon.meChairID then 
            uiText_name:setTextColor(cc.c3b(255,226,56))
            uiText_surplus:setTextColor(cc.c3b(255,226,56))
            uiText_bomb:setTextColor(cc.c3b(255,226,56))
            uiText_result:setTextColor(cc.c3b(255,226,56))
            uiText_piao:setTextColor(cc.c3b(255,226,56))
        else
        end 
    end
    for i = PDKGameCommon.gameConfig.bPlayerCount+1, 3 do
        local root = ccui.Helper:seekWidgetByName(uiListView_player,string.format("Panel_player%d",i))
        root:setVisible(false)
    end
    local uiText_time = ccui.Helper:seekWidgetByName(self.root,"Text_time")
    -- uiText_time:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function(sender,event) 
        local date = os.date("*t",os.time())
        uiText_time:setString(string.format("%d-%d-%d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
        -- end),cc.DelayTime:create(1))))
end

function GameEndLayer:RET_GET_MALL_LOG_FINISH(event)
    local uiButton_continue = ccui.Helper:seekWidgetByName(self.root,"Button_continue")
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    local uiPanel_reward = ccui.Helper:seekWidgetByName(self.root,"Panel_reward")
    uiPanel_reward:setVisible(false)
    uiButton_return:setVisible(true)
    uiButton_continue:setVisible(true)
end 

function GameEndLayer:SUB_GR_MATCH_TABLE_FAILED(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    if data.wErrorCode == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您在游戏中!")
    elseif data.wErrorCode == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"游戏配置发生错误!")
    elseif data.wErrorCode == 2 then
        if  StaticData.Hide[CHANNEL_ID].btn8 == 1 and StaticData.Hide[CHANNEL_ID].btn9 == 1  then
            require("common.MsgBoxLayer"):create(2,nil,"您的金币不足,请前往商城充值!",function()             require("app.views.NewXXMallLayer"):create(2) end)
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

return GameEndLayer
