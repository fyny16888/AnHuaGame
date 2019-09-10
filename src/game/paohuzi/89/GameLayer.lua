local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local GameCommon = require("game.paohuzi.GameCommon")  
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local GameDesc = require("common.GameDesc")
local GameLogic = require("game.paohuzi.GameLogic")

local TableLayer = require("game.paohuzi.TableLayer")


local GameLayer = class("GameLayer",function()
    return ccui.Layout:create()
end)

function GameLayer:create(...)
    local view = GameLayer.new()
    view:onCreate(...)
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

function GameLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:registListener(EventType.EVENT_TYPE_OPERATIONAL_OUT_CARD,self,self.EVENT_TYPE_OPERATIONAL_OUT_CARD)
    EventMgr:registListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 0 ,false)
    end
end

function GameLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.SUB_GR_MATCH_TABLE_ING,self,self.SUB_GR_MATCH_TABLE_ING)
    EventMgr:unregistListener(EventType.EVENT_TYPE_OPERATIONAL_OUT_CARD,self,self.EVENT_TYPE_OPERATIONAL_OUT_CARD)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK,self,self.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    if self.scheduleUpdateObj then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
    end
    
end

function GameLayer:onCleanup()

end

function GameLayer:onCreate(...)
    self:startGame(...)
end

function GameLayer:startGame(...)
    self:removeAllChildren()
    self:stopAllActions()
    local params = {...}
    GameCommon.dwUserID = params[1]
    GameCommon.tableConfig = params[2]
    GameCommon.playbackData = params[3]
    GameCommon.player = {}
    GameCommon.gameConfig = {}
        
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayerYZZiPai.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb       
    GameCommon:init()
    GameCommon.wKindID = GameCommon.tableConfig.wKindID
    GameCommon.weiCardType = 1
    GameCommon.tiCardType = 0
    GameCommon.regionSound = 3
    
    self.tableLayer = TableLayer:create(self.root)
    self:addChild(self.tableLayer)
    self.tableLayer:initUI()
    self.tableLayer:updateGameState(GameCommon.GameState_Init)
    self.isRunningActions = false
    self.userMsgArray = {} --消息缓存
    
    self:loadingPlayback()
end

function GameLayer:loadingPlayback()
    if GameCommon.tableConfig.nTableType ~= TableType_Playback then
        return
    end
    local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
    uiPanel_end:setVisible(true)
    uiPanel_end:removeAllChildren()
    uiPanel_end:stopAllActions()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("GameLayer_PlaybacLayer.csb")
    uiPanel_end:addChild(csb)
    local root = csb:getChildByName("Panel_root")
    local uiButton_return = ccui.Helper:seekWidgetByName(root,"Button_return")
    Common:addTouchEventListener(uiButton_return,function() 
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    end)
    local uiButton_play = ccui.Helper:seekWidgetByName(root,"Button_play")
    uiButton_play:setColor(cc.c3b(170,170,170))
    local uiButton_nextStep = ccui.Helper:seekWidgetByName(root,"Button_nextStep")
    Common:addTouchEventListener(uiButton_play,function(sender,event)
        uiButton_nextStep:setColor(cc.c3b(170,170,170))
        uiButton_play:setColor(cc.c3b(255,255,255))
        root:stopAllActions() 
        root:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.DelayTime:create(0),
            cc.CallFunc:create(function(sender,event) self:update(0) end)
            )))
    end)
    Common:addTouchEventListener(uiButton_nextStep,function(sender,event) 
        uiButton_play:setColor(cc.c3b(170,170,170))
        uiButton_nextStep:setColor(cc.c3b(255,255,255))
        root:stopAllActions() 
        self:update()
    end)
    self:AnalysisPlaybackData()
end

function GameLayer:AnalysisPlaybackData()
    if GameCommon.playbackData == nil then
        return
    end
    local luaFunc = require("common.Serialize"):create("",0)
    for key, var in pairs(GameCommon.playbackData) do
        luaFunc:writeSendBuffer(var.cbData,var.wDataSize)
    end
    while 1 do
        local wIdentifier = luaFunc:readRecvWORD()           --类型标示
        local wDataSize = luaFunc:readRecvWORD()             --数据长度
        local mainCmdID = luaFunc:readRecvWORD()            --主命令码
        local subCmdID = luaFunc:readRecvWORD()             --子命令码
        print("回放标志:",wIdentifier,wDataSize,mainCmdID,subCmdID)
        if self:readBuffer(luaFunc,mainCmdID,subCmdID) == false then
            return
        end       
    end
end

function GameLayer:SUB_GR_MATCH_TABLE_ING(event)
    local data = event._usedata
    self:startGame(UserData.User.userID, data)
end

function GameLayer:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    if netID ~= NetMgr.NET_GAME then
       return
    end
    local netInstance = NetMgr:getGameInstance()
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    print(string.format("game: mainCmdID = %d  subCmdID = %d",mainCmdID,subCmdID))
    local luaFunc = netInstance.cppFunc
    self:readBuffer(luaFunc, mainCmdID, subCmdID)
end

function GameLayer:readBuffer(luaFunc, mainCmdID, subCmdID)
    local _tagMsg = {}
    _tagMsg.mainCmdID = mainCmdID
    _tagMsg.subCmdID = subCmdID
    _tagMsg.pBuffer = {}
    
    if mainCmdID == NetMsgId.MDM_GR_USER then   
       if subCmdID == NetMsgId.SUB_GR_USER_READY then
            --服务器广播用户准备
            local dwUserID = luaFunc:readRecvDWORD()         --用户id
            local wChairID = luaFunc:readRecvWORD()         --椅子号
            GameCommon.player[wChairID].bReady = true
            self:updatePlayerReady()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
            --好友房大结算
            _tagMsg.pBuffer.dwUserCount = luaFunc:readRecvDWORD()                       --用户总数
            _tagMsg.pBuffer.dwDataCount = luaFunc:readRecvDWORD()                       --数据条数
            _tagMsg.pBuffer.tScoreInfo = {}                                             --统计信息
            _tagMsg.pBuffer.bigWinner = 0
            _tagMsg.pBuffer.bigWinerScore = 0
            for i = 1, 8 do
                _tagMsg.pBuffer.tScoreInfo[i] = {}
                _tagMsg.pBuffer.tScoreInfo[i].dwUserID = luaFunc:readRecvDWORD()        --用户ID
                _tagMsg.pBuffer.tScoreInfo[i].player = GameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
                _tagMsg.pBuffer.tScoreInfo[i].totalScore = 0
                _tagMsg.pBuffer.tScoreInfo[i].lScore = {}
                for j = 1, 20 do
                    _tagMsg.pBuffer.tScoreInfo[i].lScore[j] = luaFunc:readRecvLong()       --用户积分
                    _tagMsg.pBuffer.tScoreInfo[i].totalScore = _tagMsg.pBuffer.tScoreInfo[i].totalScore + _tagMsg.pBuffer.tScoreInfo[i].lScore[j]
                end
                if _tagMsg.pBuffer.tScoreInfo[i].totalScore > _tagMsg.pBuffer.bigWinerScore then
                    _tagMsg.pBuffer.bigWinner = _tagMsg.pBuffer.tScoreInfo[i].dwUserID
                    _tagMsg.pBuffer.bigWinerScore = _tagMsg.pBuffer.tScoreInfo[i].totalScore
                end
            end
            _tagMsg.pBuffer.dwTableOwnerID = luaFunc:readRecvDWORD()                    --房主ID
            _tagMsg.pBuffer.szOwnerName = luaFunc:readRecvString(32)                    --房主名字
            _tagMsg.pBuffer.szGameID = luaFunc:readRecvString(32)                    --结算唯一标志
            _tagMsg.pBuffer.tableConfig = GameCommon.tableConfig
            _tagMsg.pBuffer.gameConfig = GameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig)
            _tagMsg.pBuffer.cbOrigin = luaFunc:readRecvByte() --解散原因
        elseif subCmdID == NetMsgId.SUB_GR_GAME_STATISTICS then
            _tagMsg.pBuffer.dwUserCount = luaFunc:readRecvDWORD()                       --用户总数
			_tagMsg.pBuffer.dwDataCount = luaFunc:readRecvDWORD()                       --数据条数
            _tagMsg.pBuffer.tScoreInfo = {}                                             --统计信息
            _tagMsg.pBuffer.statistics = {}                                             --统计
			_tagMsg.pBuffer.bigWinner = 0
			_tagMsg.pBuffer.bigWinerScore = 0
            for i = 1, 8 do
                _tagMsg.pBuffer.statistics[i] = {}
				_tagMsg.pBuffer.tScoreInfo[i] = {}
				_tagMsg.pBuffer.tScoreInfo[i].dwUserID = luaFunc:readRecvDWORD()        --用户ID
				_tagMsg.pBuffer.tScoreInfo[i].player = GameCommon:getUserInfoByUserID(_tagMsg.pBuffer.tScoreInfo[i].dwUserID)
				_tagMsg.pBuffer.tScoreInfo[i].totalScore = luaFunc:readRecvLong()       --用户总积分

                for j=1,16 do
                    _tagMsg.pBuffer.statistics[i][j] = luaFunc:readRecvByte()        --用户ID
                end

			end
			_tagMsg.pBuffer.dwTableOwnerID = luaFunc:readRecvDWORD()                    --房主ID
			_tagMsg.pBuffer.szOwnerName = luaFunc:readRecvString(32)                    --房主名字
            _tagMsg.pBuffer.szGameID = luaFunc:readRecvString(32)                    --结算唯一标志
            _tagMsg.pBuffer.GameCommon = GameCommon
			_tagMsg.pBuffer.tableConfig = GameCommon.tableConfig
			_tagMsg.pBuffer.gameConfig = GameCommon.gameConfig
            _tagMsg.pBuffer.gameDesc = GameDesc:getGameDesc(GameCommon.tableConfig.wKindID, GameCommon.gameConfig, GameCommon.tableConfig)
            _tagMsg.pBuffer.cbOrigin = luaFunc:readRecvByte() --解散原因
        elseif subCmdID == NetMsgId.SUB_GR_USER_CONNECT then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            GameCommon.player[wChairID].cbOnline = 0
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_OFFLINE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            GameCommon.player[wChairID].cbOnline = 0x06
            self:updatePlayerOnline()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_LEAVE then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local dwUserID=luaFunc:readRecvDWORD()
            local wChairID=luaFunc:readRecvWORD()
            if GameCommon.dwUserID == dwUserID then
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            else
                GameCommon.player[wChairID] = nil
                self:updatePlayerInfo()
                self:updatePlayerPosition()
            end
            return true
            
        elseif subCmdID == NetMsgId.RET_GR_USER_SET_POSITION then
            local luaFunc = NetMgr:getGameInstance().cppFunc
            local location = {}
            location.x = luaFunc:readRecvDouble()
            location.y = luaFunc:readRecvDouble()
            local dwUserID = luaFunc:readRecvDWORD()
            local wChairID = luaFunc:readRecvWORD()
            if GameCommon.player[wChairID] ~= nil then
                GameCommon.player[wChairID].location = location
            end
            return true
                
        elseif subCmdID == NetMsgId.SUB_GR_TABLE_STATUS then 
            GameCommon.tableConfig.wTableNumber = luaFunc:readRecvWORD()       --房间局数
            GameCommon.tableConfig.wCurrentNumber = luaFunc:readRecvWORD()    --当前局数
            local uiText_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
            local uiText_des = ccui.Helper:seekWidgetByName(self.root,"Text_des")
            local roomId = GameCommon.tableConfig.wTbaleID or 0
            local randCeil = GameCommon.tableConfig.wCurrentNumber or 0
            local randFloor = GameCommon.tableConfig.wTableNumber or 0
            uiText_title:setString(StaticData.Games[GameCommon.tableConfig.wKindID].name)
            uiText_des:setString(string.format("房间号:%d 局数:%d/%d",roomId,randCeil,randFloor))
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_SUCCESS then
            if GameCommon.gameState ~= GameCommon.GameState_Init  or GameCommon.tableConfig.wCurrentNumber ~= 0 then
                require("common.MsgBoxLayer"):create(0,nil,"房间解散成功！") 
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            else
                require("common.MsgBoxLayer"):create(2,nil,"房间解散成功！",function(sender,event) 
                    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                end)   
            end
            return true

        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_STATE then
            local data = {}
            data.dwDisbandedTime = luaFunc:readRecvDWORD()
            data.wAdvocateDisbandedID = luaFunc:readRecvWORD()
            data.cbDisbandeState = {}
            for i = 1, 8 do
                data.cbDisbandeState[i] = luaFunc:readRecvByte()
            end
            data.dwUserIDALL = {}
            for i = 1, 8 do
                data.dwUserIDALL[i] = luaFunc:readRecvDWORD()
            end
            data.szNickNameALL = {}
            for i = 1, 8 do
                data.szNickNameALL[i] = luaFunc:readRecvString(32)
            end
            require("common.DissolutionLayer"):create(GameCommon.player,data)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_USER_COME then 
            --用户进入
            local data = {}
            data.dwUserID = luaFunc:readRecvDWORD()
            data.wChairID = luaFunc:readRecvWORD()
            data.szNickName = luaFunc:readRecvString(32)
            data.szPto = luaFunc:readRecvString(256)
            data.cbSex = luaFunc:readRecvByte()
            data.lScore = luaFunc:readRecvLong() 
            data.dwPlayAddr = luaFunc:readRecvDWORD() 
            data.cbOnline = luaFunc:readRecvByte() 
            data.bReady = luaFunc:readRecvBool() 
            data.location = {}
            data.location.x = luaFunc:readRecvDouble()
            data.location.y = luaFunc:readRecvDouble()
            data.other = nil
            data.bUserCardCount = 0
            data.cbCardIndex = nil
            data.cbCardCoutWW = 0
            data.bWeaveItemCount = 0
            data.WeaveItemArray = {}
            data.bDiscardCardCount = 0
            data.bDiscardCard = {}
			data.bOutCardMark = {}
            data.cardStackInfo = nil
            data.maxHanCardRow = 0
            printInfo(data)
            GameCommon.player[data.wChairID] = data
            if data.dwUserID == GameCommon.dwUserID or GameCommon.meChairID == nil then
                GameCommon.meChairID = data.wChairID
            end
            self:updatePlayerInfo()
            self:updatePlayerOnline()
            self:updatePlayerReady()
            self:updatePlayerPosition()
            self:updateBtnState()
            return true

        elseif subCmdID == NetMsgId.SUB_GR_PLAYER_INFO then 
            --查看玩家信息
            _tagMsg.pBuffer.dwUserID = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.lWinCount = luaFunc:readRecvLong()  
            _tagMsg.pBuffer.lLostCount = luaFunc:readRecvLong()  
            _tagMsg.pBuffer.dwPlayTimeCount = luaFunc:readRecvDWORD()  
            _tagMsg.pBuffer.dwPlayAddr = luaFunc:readRecvDWORD() 
            _tagMsg.pBuffer.dwShamUserID = luaFunc:readRecvDWORD()
            self.tableLayer:showPlayerInfo(_tagMsg.pBuffer)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_SEND_CHAT then
            --用户语言文字聊天
            _tagMsg.pBuffer.dwUserID = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.dwSoundID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbSex = luaFunc:readRecvByte()
            _tagMsg.pBuffer.szNickName = luaFunc:readRecvString(32)
            _tagMsg.pBuffer.dwChatLength = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.szChatContent = luaFunc:readRecvString(_tagMsg.pBuffer.dwChatLength)
            self.tableLayer:showChat(_tagMsg.pBuffer)
            return
        elseif subCmdID == NetMsgId.RET_GET_REDENVELOPE_REWARD then	
            _tagMsg.pBuffer.lRet = luaFunc:readRecvLong()   --0成功   1活动结束     2参数错误   3 玩家不存在           
            _tagMsg.pBuffer.bType = luaFunc:readRecvByte()      --0金币	1红包
            _tagMsg.pBuffer.lCount = luaFunc:readRecvLong()     -- 数量   
            local a = 10
            self.tableLayer:showReward(_tagMsg.pBuffer)
            return       
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GR_LOGON then
        if subCmdID == NetMsgId.SUB_GR_LOGON_ERROR then
            _tagMsg.pBuffer.wErrolCode = luaFunc:readRecvWORD()    --错误代码
            _tagMsg.pBuffer.wServerID = luaFunc:readRecvWORD()     --错误代码
            _tagMsg.pBuffer.lScore = luaFunc:readRecvLong()        --分数
            _tagMsg.pBuffer.dwServerAddr = luaFunc:readRecvDWORD() --端口
            require("common.MsgBoxLayer"):create(2,nil , "您的金币不符" , function(sender,event) 
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            end)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_LOGON_FINISH then
            return true
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.RET_SC_GAME_CONFIG then
            GameCommon.gameConfig = require("common.GameConfig"):getParameter(GameCommon.tableConfig.wKindID,luaFunc)
            local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
            uiText_desc:setString(GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig))
            if GameCommon.gameConfig.bPlayerCount <= 2 or (GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom) then
                local uiButton_position = ccui.Helper:seekWidgetByName(self.root,"Button_position")
                uiButton_position:setVisible(false)
            end
            return true
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_START then
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()    --庄家用户
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()   --当前用户
            _tagMsg.pBuffer.lCellScore = luaFunc:readRecvLong()     --倍率
            _tagMsg.pBuffer.cbCardData = {}                         --扑克列表
            for i = 1 , 21 do
                if i == 21 then
                    _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
                else
                    _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
                end
            end

            _tagMsg.pBuffer.cbBeginCardData = luaFunc:readRecvByte()--亮起手牌
            _tagMsg.pBuffer.bIsHuangZhuang = luaFunc:readRecvBool()--是否上把黄庄加倍
   
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()
            _tagMsg.pBuffer.cbHuangFanCount = luaFunc:readRecvByte()
           
        elseif subCmdID == NetMsgId.SUB_S_USER_TI_CARD then
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()    --动作用户
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()   --操作扑克
            _tagMsg.pBuffer.cbRemoveCount = luaFunc:readRecvByte()  --删除数目
            
        elseif subCmdID == NetMsgId.SUB_S_USER_PAO_CARD then
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()    --动作用户
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()   --操作扑克
            _tagMsg.pBuffer.cbRemoveCount = luaFunc:readRecvByte()  --删除数目
            
        elseif subCmdID == NetMsgId.SUB_S_USER_WEI_CARD then
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()    --动作用户
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()   --操作扑克
            
        elseif subCmdID == NetMsgId.SUB_S_USER_PENG_CARD then
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()    --动作用户
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()   --操作扑克
            
        elseif subCmdID == NetMsgId.SUB_S_USER_CHI_CARD then
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()    --动作用户
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()   --操作扑克
            _tagMsg.pBuffer.cbResultCount = luaFunc:readRecvByte()  --结果数目
            _tagMsg.pBuffer.cbCardData = {}                         --吃牌组合
            for i = 1 , 3 do
                _tagMsg.pBuffer.cbCardData[i] = {}
                for j = 1 , 3 do 
                    _tagMsg.pBuffer.cbCardData[i][j] = luaFunc:readRecvByte()
                end
            end
            
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_NOTIFY then
            _tagMsg.pBuffer.wResumeUser = luaFunc:readRecvWORD()    --还原用户
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()  --操作扑克
            _tagMsg.pBuffer.cbOperateCode = luaFunc:readRecvWORD()  --操作代码
            
        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_NOTIFY then
            _tagMsg.pBuffer.bOutCard = luaFunc:readRecvByte()  --出牌标志
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()  --当前用户
            
        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD then
            _tagMsg.pBuffer.wOutCardUser = luaFunc:readRecvWORD()  --出牌用户
            _tagMsg.pBuffer.cbOutCardData = luaFunc:readRecvByte()  --出牌扑克
            
        elseif subCmdID == NetMsgId.SUB_S_TING_CARD_NOTIFY then
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbCardIndex = {}
            for i = 1, 20 do
                _tagMsg.pBuffer.cbCardIndex[i] = luaFunc:readRecvByte()
            end

        elseif subCmdID == NetMsgId.SUB_S_TING_CARD_CHANGE_NOTIFY then
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbCardIndex = {}
            for i = 1, 20 do
                _tagMsg.pBuffer.cbCardIndex[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.tTingCard = {}
            for i = 1, 20 do
                _tagMsg.pBuffer.tTingCard[i] = {}
                _tagMsg.pBuffer.tTingCard[i].cbCardCount = luaFunc:readRecvByte()
                _tagMsg.pBuffer.tTingCard[i].cbCardIndex = {}
                for j = 1, 20 do
                    _tagMsg.pBuffer.tTingCard[i].cbCardIndex[j] = luaFunc:readRecvByte()
                end
            end

        elseif subCmdID == NetMsgId.SUB_S_SEND_CARD then
            _tagMsg.pBuffer.cbCardData = luaFunc:readRecvByte()     --发牌扑克
            _tagMsg.pBuffer.cbShow = luaFunc:readRecvByte()         --是否显示,不显示将进入手里
            _tagMsg.pBuffer.wAttachUser = luaFunc:readRecvWORD()    --绑定用户
            
        elseif subCmdID == NetMsgId.SUB_S_CLIENTERROR then
            _tagMsg.pBuffer.cbCardIndex = {}
            for i = 1 , 20 do
                _tagMsg.pBuffer.cbCardIndex[i] = luaFunc:readRecvByte() 
            end
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_END then
            --结束信息
            _tagMsg.pBuffer.cbReason = luaFunc:readRecvByte()--结束原因
            _tagMsg.pBuffer.cbHuCard = luaFunc:readRecvByte()--胡牌扑克
            _tagMsg.pBuffer.wWinUser = luaFunc:readRecvWORD()--胜利用户
            _tagMsg.pBuffer.wProvideUser = luaFunc:readRecvWORD()--放跑用户
            --名堂类型
            _tagMsg.pBuffer.wType = luaFunc:readRecvWORD()--名堂数据
            _tagMsg.pBuffer.wFanCount = luaFunc:readRecvWORD()--总翻数
            _tagMsg.pBuffer.cbHuXiCount = luaFunc:readRecvWORD()--胡息数目
            _tagMsg.pBuffer.wTun = luaFunc:readRecvWORD()--囤数
            _tagMsg.pBuffer.wBeilv = luaFunc:readRecvWORD()--倍率
            --成绩变量
            _tagMsg.pBuffer.lGameTax = luaFunc:readRecvLong()--游戏税收
            _tagMsg.pBuffer.lGameScore = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong()--游戏积分
            end
            --剩余扑克
            _tagMsg.pBuffer.bLeftCardCount = luaFunc:readRecvByte() --剩余数目
            _tagMsg.pBuffer.bLeftCardData = {}                      --剩余扑克
            for i = 1 , 22 do
                _tagMsg.pBuffer.bLeftCardData[i] = luaFunc:readRecvByte()
            end
            --扑克变量
            _tagMsg.pBuffer.bCardCount = {}                     --扑克数目
            for i = 1 , 4 do
                _tagMsg.pBuffer.bCardCount[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bCardData = {}                     --扑克列表
            for i = 1 , 84 do
                if i == 84 then
                    _tagMsg.pBuffer.bCardData[i] = luaFunc:readRecvByte()
                else
                    _tagMsg.pBuffer.bCardData[i] = luaFunc:readRecvByte()
                    print("扑克列表:",i,_tagMsg.pBuffer.bCardData[i])
                end
            end
            _tagMsg.pBuffer.HuCardInfo = {}
            _tagMsg.pBuffer.HuCardInfo.cbCardEye = luaFunc:readRecvByte()--牌眼扑克
            _tagMsg.pBuffer.HuCardInfo.cbHuXiCount = luaFunc:readRecvByte()--胡息数目
            _tagMsg.pBuffer.HuCardInfo.cbWeaveCount = luaFunc:readRecvByte()--组合数目

            _tagMsg.pBuffer.HuCardInfo.WeaveItemArray = {}  --组合扑克
            for i = 1 , 7 do
                _tagMsg.pBuffer.HuCardInfo.WeaveItemArray[i] = {}
                _tagMsg.pBuffer.HuCardInfo.WeaveItemArray[i].cbWeaveKind = luaFunc:readRecvByte()--组合类型
                _tagMsg.pBuffer.HuCardInfo.WeaveItemArray[i].cbCardCount = luaFunc:readRecvByte()--扑克数目
                _tagMsg.pBuffer.HuCardInfo.WeaveItemArray[i].cbCenterCard = luaFunc:readRecvByte()--中心扑克
                _tagMsg.pBuffer.HuCardInfo.WeaveItemArray[i].cbCardList = {}    --扑克列表
                for j = 1 , 4 do
                    _tagMsg.pBuffer.HuCardInfo.WeaveItemArray[i].cbCardList[j] = luaFunc:readRecvByte()
                end
            end
            _tagMsg.pBuffer.HuCardInfo.wDType = luaFunc:readRecvDWORD()--名堂数据 
            _tagMsg.pBuffer.HuCardInfo.dwMingTang = luaFunc:readRecvDWORD()
            _tagMsg.pBuffer.cbHuangFanCount = luaFunc:readRecvByte()  -- 黄番
            _tagMsg.pBuffer.bLeftCardDataEx = {}                      --剩余扑克
            for i = 1 , 64 do
                _tagMsg.pBuffer.bLeftCardDataEx[i] = luaFunc:readRecvByte()
            end  
        elseif subCmdID == NetMsgId.SUB_S_SITFAILED then
            _tagMsg.pBuffer.wErrorCode = luaFunc:readRecvWORD() --错误代码
            _tagMsg.pBuffer.lScore = luaFunc:readRecvLong()     --积分
            require("common.MsgBoxLayer"):create(2,nil , "您的金币不符" , function(sender,event) 
                require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            end)
            return true
            
        elseif subCmdID == NetMsgId.SUB_GF_USER_EXPRESSION then
            _tagMsg.pBuffer.wIndex = luaFunc:readRecvWORD()     --索引
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()   --椅子号
            self.tableLayer:showExperssion(_tagMsg.pBuffer)
            return true
        elseif subCmdID == NetMsgId.SUB_GF_USER_EFFECTS then
            local wIndex = luaFunc:readRecvWORD()     --索引
            local wChairID = luaFunc:readRecvWORD()   --椅子号
            local wTargetD = luaFunc:readRecvWORD()   --目标
            self.tableLayer:playSkelStartToEndPos(wChairID,wTargetD,wIndex) 
            
        elseif subCmdID == NetMsgId.SUB_S_SISHOU then
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()     --当前用户
            
        elseif subCmdID == NetMsgId.SUB_GF_USER_VOICE then
            
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()               --座位号
            _tagMsg.pBuffer.wPackCount = luaFunc:readRecvWORD()             --包总数
            _tagMsg.pBuffer.wPackIndex = luaFunc:readRecvWORD()            --当前包索引
            _tagMsg.pBuffer.dwTime = luaFunc:readRecvDWORD()                --播放时长
            _tagMsg.pBuffer.dwFileSize = luaFunc:readRecvDWORD()            --文件总长度
            _tagMsg.pBuffer.dwPeriodSize = luaFunc:readRecvDWORD()          --文件一段长度
            _tagMsg.pBuffer.szFileName = luaFunc:readRecvString(32)         --文件名字
            _tagMsg.pBuffer.szPeriodData = luaFunc:readRecvBuffer(_tagMsg.pBuffer.dwPeriodSize) --文件数据
            self.tableLayer:OnUserChatVoice(_tagMsg.pBuffer)      
            return true
            
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then 
            --游戏信息
            _tagMsg.pBuffer.lCellScore = luaFunc:readRecvLong()                    --基础积分  
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()                   --庄家用户
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()                  --当前用户
            --出牌信息
            _tagMsg.pBuffer.bOutCard = luaFunc:readRecvByte()                     --出牌标志
            _tagMsg.pBuffer.wOutCardUser = luaFunc:readRecvWORD()                  --出牌用户
            _tagMsg.pBuffer.cbOutCardData = luaFunc:readRecvByte()                 --出牌扑克
            _tagMsg.pBuffer.bDispatch = luaFunc:readRecvBool()                     --发牌标志
            --扑克信息
            _tagMsg.pBuffer.bLeftCardCount = luaFunc:readRecvByte()                --剩余数目
            _tagMsg.pBuffer.cbCardIndex = {}                                       --用户扑克
            for i = 1 , 20 do
                _tagMsg.pBuffer.cbCardIndex[i] = luaFunc:readRecvByte()
                print("断线重连S:",i,_tagMsg.pBuffer.cbCardIndex[i])
            end
            _tagMsg.pBuffer.bUserCardCount = {}                                    --扑克数目
            for i = 1 , 4 do
                _tagMsg.pBuffer.bUserCardCount[i] = luaFunc:readRecvByte() 
            end
            --组合信息
            _tagMsg.pBuffer.bWeaveItemCount = {}                                   --组合数目
            for i = 1, 4 do
                _tagMsg.pBuffer.bWeaveItemCount[i] = luaFunc:readRecvByte()   
            end
            _tagMsg.pBuffer.WeaveItemArray = {}                                    --组合扑克          
            for i = 1 , 4 do
                _tagMsg.pBuffer.WeaveItemArray[i] = {}
                for j = 1 , 7 do
                    _tagMsg.pBuffer.WeaveItemArray[i][j] = {}
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbWeaveKind = luaFunc:readRecvByte()    --组合类型
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbCardCount = luaFunc:readRecvByte()    --扑克数目
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbCenterCard = luaFunc:readRecvByte()   --中心扑克
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbCardList = {}
                    print("断线重连B：",i,j,_tagMsg.pBuffer.WeaveItemArray[i][j].cbWeaveKind,_tagMsg.pBuffer.WeaveItemArray[i][j].cbCardCount, _tagMsg.pBuffer.WeaveItemArray[i][j].cbCenterCard)
                    for o = 1 , 4 do
                        _tagMsg.pBuffer.WeaveItemArray[i][j].cbCardList[o] = luaFunc:readRecvByte()  --扑克列表
                        print("断线重连C：",o,_tagMsg.pBuffer.WeaveItemArray[i][j].cbCardList[o])
                    end
                end
            end
            --动作信息
            _tagMsg.pBuffer.bResponse = luaFunc:readRecvByte()                     --响应标志
            _tagMsg.pBuffer.bUserAction = luaFunc:readRecvWORD()                   --用户动作
            --弃牌
            _tagMsg.pBuffer.bDiscardCard = {}                                      --出牌记录
            for i = 1 , 4 do
                _tagMsg.pBuffer.bDiscardCard[i] = {}
                for j = 1 , 21 do
                    _tagMsg.pBuffer.bDiscardCard[i][j] = luaFunc:readRecvByte()
                end
            end            
            _tagMsg.pBuffer.bDiscardCardCount = {}                                 --出牌数
            for i = 1 , 4 do
                _tagMsg.pBuffer.bDiscardCardCount[i] = luaFunc:readRecvByte()
            end 
            _tagMsg.pBuffer.bIsHuangZhuang = luaFunc:readRecvBool()--是否上把黄庄加倍
            
            _tagMsg.pBuffer.bOutCardMark = {}
			for i = 1, 4 do
				_tagMsg.pBuffer.bOutCardMark[i] = {}
				for j = 1, 21 do
					_tagMsg.pBuffer.bOutCardMark[i] [j] = luaFunc:readRecvBool()
				end
			end	

        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
    else
        print("not found this mainCmdID : %d",mainCmdID)
        return false
    end
    if self.userMsgArray == nil then 
        return false
    end
    table.insert(self.userMsgArray,#self.userMsgArray + 1,_tagMsg)
    
    print("当前消息数量:%d",#self.userMsgArray)
    printInfo(_tagMsg)
    return true
end

function GameLayer:EVENT_TYPE_CACEL_MESSAGE_BLOCK(event)
    self.isRunningActions = false
    self:updatehandplate()
end

--消息队列
function GameLayer:update(delta)
    if self.isRunningActions then
        return
    end
    if self.userMsgArray == nil then
        return
    end
    if #self.userMsgArray <=0 then
        return
    end
    local _tagMsg = self.userMsgArray[1]
    self:OnGameMessageRun(_tagMsg)
    --删除动作
    table.remove(self.userMsgArray,1)
end

--消息执行
function GameLayer:OnGameMessageRun(_tagMsg)
    local mainCmdID = _tagMsg.mainCmdID
    local subCmdID = _tagMsg.subCmdID
    local pBuffer = _tagMsg.pBuffer
    
    if mainCmdID == NetMsgId.MDM_GR_USER then   
        if subCmdID == NetMsgId.SUB_GR_GAME_STATISTICS then
            self:removeAllChildren()
            local layer = require("game.majiang.KwxGameOver"):create(pBuffer)
            self:addChild(layer)
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end
    --  elseif mainCmdID == NetMsgId.MDM_GR_USER then   
    --     if subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
    --         self:removeAllChildren()
    --         local layer = require("common.FriendsRoomEndLayer"):create(pBuffer)
    --         self:addChild(layer)
    --     else
    --         return print("error, not found this :",mainCmdID, subCmdID)
    --     end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.SUB_S_GAME_START then
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            --开始游戏
            local maxHanCardRow = 10
            local wChairID = pBuffer.wChairID
            if wChairID ~= GameCommon:getRoleChairID() then
                maxHanCardRow = 7
            end
            for i = 0, 3 do
                if GameCommon.player[i] ~= nil then
                    if i == pBuffer.wBankerUser then
                         GameCommon.player[i].bUserCardCount = 21
                    else
                        GameCommon.player[i].bUserCardCount = 20
                    end
                end
                print("开始游戏:",GameCommon.player[i],i,pBuffer.wBankerUser,wChairID)
            end
            
            GameCommon.bIsHuangZhuang = pBuffer.bIsHuangZhuang 
            GameCommon.wBankerUser = pBuffer.wBankerUser
            self.tableLayer:showCountDown(GameCommon.wBankerUser)
            local cbCardIndex = GameLogic:SwitchToCardIndexs(pBuffer.cbCardData,GameCommon.player[wChairID].bUserCardCount)
            self.tableLayer:setHandCard(wChairID,GameCommon.player[wChairID].bUserCardCount, cbCardIndex, maxHanCardRow, 0)
            self.tableLayer:showHandCard(wChairID,1)
            local cbLeftCardCount = 80
            if GameCommon.gameConfig.bDeathCard == 1 then
                cbLeftCardCount = cbLeftCardCount - 20
            end
            cbLeftCardCount = cbLeftCardCount - 20*GameCommon.gameConfig.bPlayerCount - 1
            self.tableLayer:updateLeftCardCount(cbLeftCardCount)
            self:updateBankerUser()
            self:updatePlayerInfo()
            self:updatehandplate()

            self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            if pBuffer.cbBeginCardData ~= nil and pBuffer.cbBeginCardData ~= 0x00 and ( GameCommon.tableConfig.nTableType ~= TableType_Playback or wChairID + 1 == GameCommon.gameConfig.bPlayerCount ) then
                self.tableLayer:doAction(GameCommon.ACTION_SHOW_CARD, {wAttachUser = GameCommon.wBankerUser, cbShow = 1, cbCardData = pBuffer.cbBeginCardData})
            end
            
        elseif subCmdID == NetMsgId.SUB_S_USER_TI_CARD then
            self.tableLayer:doAction(GameCommon.ACTION_TI_CARD, pBuffer)
            self:updatePlayerHuXi(pBuffer.wActionUser)

        elseif subCmdID == NetMsgId.SUB_S_USER_PAO_CARD then
            self.tableLayer:doAction(GameCommon.ACTION_PAO_CARD, pBuffer)
            self:updatePlayerHuXi(pBuffer.wActionUser)

        elseif subCmdID == NetMsgId.SUB_S_USER_WEI_CARD then
            self.tableLayer:doAction(GameCommon.ACTION_WEI_CARD, pBuffer)
            self:updatePlayerHuXi(pBuffer.wActionUser)
        elseif subCmdID == NetMsgId.SUB_S_USER_PENG_CARD then
            self.tableLayer:doAction(GameCommon.ACTION_PENG_CARD, pBuffer)
            self:updatePlayerHuXi(pBuffer.wActionUser) 
        elseif subCmdID == NetMsgId.SUB_S_USER_CHI_CARD then
            self.tableLayer:doAction(GameCommon.ACTION_CHI_CARD, pBuffer)
            self:updatePlayerHuXi(pBuffer.wActionUser) 
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_NOTIFY then
            self.tableLayer:doAction(GameCommon.ACTION_OPERATE_NOTIFY,pBuffer)
            
        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_NOTIFY then
            self.tableLayer:doAction(GameCommon.ACTION_OUT_CARD_NOTIFY, pBuffer)

        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD then
            self.tableLayer:doAction(GameCommon.ACTION_OUT_CARD, pBuffer)

        elseif subCmdID == NetMsgId.SUB_S_TING_CARD_NOTIFY then
            self.tableLayer:showTingPaiTips(pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SUB_S_TING_CARD_CHANGE_NOTIFY then
            self.tableLayer:saveDragTPData(pBuffer)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))

        elseif subCmdID == NetMsgId.SUB_S_SEND_CARD then
            self.tableLayer:doAction(GameCommon.ACTION_SEND_CARD, pBuffer)

        elseif subCmdID == NetMsgId.SUB_S_CLIENTERROR then
            local wChairID = GameCommon:getRoleChairID()
            self.tableLayer:setHandCard(wChairID, GameCommon.player[wChairID].bUserCardCount,pBuffer.cbCardIndex,10,0)
            self.tableLayer:showHandCard(wChairID, 0)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_END then
            for i = 0 , GameCommon.gameConfig.bPlayerCount do
                if GameCommon.player[i] ~= nil then
                    GameCommon.player[i].lScore = GameCommon.player[i].lScore + pBuffer.lGameScore[i+1]
                    if GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
                        GameCommon.player[i].lScore = GameCommon.player[i].lScore - GameCommon.tableConfig.wCellScore/2
                        if GameCommon.player[i].lScore < 0 then
                            GameCommon.player[i].lScore = 0
                        end
                    end
                end
            end
            self:updatePlayerlScore()
            self.tableLayer:updateGameState(GameCommon.GameState_Over)
            self.tableLayer:doAction(GameCommon.ACTION_HU_CARD, {cbReason = pBuffer.cbReason, cbHuCard = pBuffer.cbHuCard, wWinUser = pBuffer.wWinUser, wProvideUser = pBuffer.wProvideUser})
            -- if pBuffer.bLeftCardCount > 22 then
            --     pBuffer.bLeftCardCount = 22
            -- end
            self.tableLayer:showLeftCardCount(pBuffer.bLeftCardCount, pBuffer.bLeftCardDataEx)
            local index = 0
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                local cbCardIndex = {}
                for i = 1, 20 do
                    cbCardIndex[i] = 0
                end
                local wChairID = i-1
                for j = 1, pBuffer.bCardCount[i] do
                    index = index + 1
                    local value = GameLogic:SwitchToCardIndex(pBuffer.bCardData[index])
                    cbCardIndex[value] = cbCardIndex[value] + 1
                end
                local bUserCardCount = pBuffer.bCardCount[i]
                self.tableLayer:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create(function(sender,event) 
                    self.tableLayer:setHandCard(wChairID,bUserCardCount, cbCardIndex, 7, 0)
                    self.tableLayer:showHandCard(wChairID,1,true)
                    self.tableLayer:setWeaveItemArray(wChairID, GameCommon.player[wChairID].bWeaveItemCount, GameCommon.player[wChairID].WeaveItemArray)
                end)))
            end
            local uiPanel_showEndCard = ccui.Helper:seekWidgetByName(self.root,"Panel_showEndCard")
            uiPanel_showEndCard:setOpacity(0)
            uiPanel_showEndCard:runAction(cc.FadeIn:create(3))
            local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
            uiPanel_end:setVisible(true)
            uiPanel_end:removeAllChildren()
            uiPanel_end:stopAllActions()
            if pBuffer.wWinUser ~= GameCommon.INVALID_CHAIR then
                uiPanel_end:runAction(cc.Sequence:create(
                    cc.DelayTime:create(2),
                    cc.CallFunc:create(function(sender,event) 
                        uiPanel_end:addChild(require("game.paohuzi.89.GameEndLayer"):create(pBuffer))
                    end),
                    cc.DelayTime:create(20),
                    cc.CallFunc:create(function(sender,event) 
                        if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
                            if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                                EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
--                            else
--                                GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                            end
                        else
                            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                        end
                end)))
            else
                --黄庄      
                if GameCommon.gameConfig.bPlayerCount == 4 then
                    for i = 0 , GameCommon.gameConfig.bPlayerCount do
                        if GameCommon.player[i] ~= nil and pBuffer.lGameScore[i+1] ~= 0 then
                            self.tableLayer:doAction(GameCommon.ACTION_HUANG_PEI,{wAttachUser = i,wMoney = pBuffer.lGameScore[i+1]})
                        end
                    end
                end    
                uiPanel_end:runAction(cc.Sequence:create(
                    cc.DelayTime:create(3),
                    cc.CallFunc:create(function(sender,event) 
                        if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
                            if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                                EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
                            else
                                GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                            end
                        elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
                            GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                        else
                            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                        end
                end)))
            end
            
        elseif subCmdID == NetMsgId.SUB_S_WD then
            if pBuffer.cbSubOperateCode == 0x02 then
                self.tableLayer:doAction(GameCommon.ACTION_WC,pBuffer)
                
            elseif pBuffer.cbSubOperateCode == 0x04 then
                self.tableLayer:doAction(GameCommon.ACTION_3WC,pBuffer)
            else
                self.tableLayer:doAction(GameCommon.ACTION_WD,pBuffer)
            end

        elseif subCmdID == NetMsgId.SUB_S_WC then
            self.tableLayer:doAction(GameCommon.ACTION_WC,pBuffer)

        elseif subCmdID == NetMsgId.SUB_S_SISHOU then
            self.tableLayer:doAction(GameCommon.ACTION_SISHOU,pBuffer)
            
        else 
            return print("error, not found this :",mainCmdID, subCmdID)
        end

    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then
            --游戏重连
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            local wChairID = GameCommon:getRoleChairID()
            GameCommon.wBankerUser = pBuffer.wBankerUser
            GameCommon.bIsHuangZhuang = pBuffer.bIsHuangZhuang 
            --设置臭偎和吃牌的顺序
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                for j = 1, pBuffer.bWeaveItemCount[i] do
                    if pBuffer.WeaveItemArray[i][j].cbWeaveKind == GameCommon.ACK_WEI then
                        for n = 1, pBuffer.bDiscardCardCount[i] do
                            if pBuffer.bDiscardCard[i][n] == pBuffer.WeaveItemArray[i][j].cbCenterCard then
                                pBuffer.WeaveItemArray[i][j].cbWeaveKind = GameCommon.ACK_CHOUWEI
                                break
                            end
                        end
                        for n = 1, GameCommon.gameConfig.bPlayerCount do
                            for m = 1, pBuffer.bWeaveItemCount[n] do
                                if pBuffer.WeaveItemArray[n][m].cbWeaveKind == GameCommon.ACK_CHI and pBuffer.WeaveItemArray[n][m].cbCenterCard == pBuffer.WeaveItemArray[i][j].cbCenterCard then
                                    pBuffer.WeaveItemArray[i][j].cbWeaveKind = GameCommon.ACK_CHOUWEI
                                    break
                                end
                            end
                        end
                    elseif pBuffer.WeaveItemArray[i][j].cbWeaveKind == GameCommon.ACK_CHI then
                        local count = 0
                        while 1 do
                            local isFound = false
                            for key, var in pairs(pBuffer.WeaveItemArray[i][j].cbCardList) do
                                if var == pBuffer.WeaveItemArray[i][j].cbCenterCard then
                                    table.remove(pBuffer.WeaveItemArray[i][j].cbCardList,key)
                                    isFound = true
                                    break
                                end
                            end
                            if isFound == false then
                                break
                            else
                                count = count + 1
                            end
                        end
                        for num = 1, count do
                            table.insert(pBuffer.WeaveItemArray[i][j].cbCardList,3-count+num,pBuffer.WeaveItemArray[i][j].cbCenterCard)
                        end
                    end
                end
            end
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                self.tableLayer:setDiscardCard(i-1, pBuffer.bDiscardCardCount[i], pBuffer.bDiscardCard[i],pBuffer.bOutCardMark[i])
                self.tableLayer:setWeaveItemArray(i-1, pBuffer.bWeaveItemCount[i], pBuffer.WeaveItemArray[i])
                GameCommon.player[i-1].bUserCardCount = pBuffer.bUserCardCount[i]
                self:updatePlayerHuXi(i-1)
            end
            local duijia = (GameCommon.wBankerUser - 1 + GameCommon.gameConfig.bPlayerCount - 1) % GameCommon.gameConfig.bPlayerCount
            if GameCommon.gameConfig.bPlayerCount == 4 and duijia == wChairID then
                self.tableLayer:setHandCard(GameCommon.wBankerUser,pBuffer.bUserCardCount[GameCommon.wBankerUser+1],pBuffer.cbCardIndex,10,0,true)
                self.tableLayer:showHandCard(GameCommon.wBankerUser,0)
            else
                self.tableLayer:setHandCard(wChairID,pBuffer.bUserCardCount[wChairID+1],pBuffer.cbCardIndex,10,0,true)
                self.tableLayer:showHandCard(wChairID,0)
            end
            self:updateBankerUser()
            if pBuffer.bOutCard ~= 0 then
                self.tableLayer:doAction(GameCommon.ACTION_OUT_CARD_NOTIFY, {wCurrentUser = wChairID, bOutCard = nil})
                self.tableLayer:showCountDown(wChairID)
            else
                self.tableLayer:showCountDown(pBuffer.wCurrentUser)
            end
            if pBuffer.wOutCardUser < GameCommon.gameConfig.bPlayerCount and pBuffer.cbOutCardData ~= 0 then
                if (pBuffer.bDispatch==true) then
                    self.tableLayer:doAction(GameCommon.ACTION_SEND_CARD,{cbCardData = pBuffer.cbOutCardData, cbShow = 1, wAttachUser = pBuffer.wOutCardUser})
                else
                    self.tableLayer:doAction(GameCommon.ACTION_OUT_CARD, {wOutCardUser = pBuffer.wOutCardUser, cbOutCardData = pBuffer.cbOutCardData, isNoDelete = true})
                end
            end
            if pBuffer.bResponse == 0 and pBuffer.bUserAction > 0 then
                self.tableLayer:doAction(GameCommon.ACTION_OPERATE_NOTIFY,{wResumeUser = wChairID, cbActionCard = pBuffer.cbOutCardData, cbOperateCode = pBuffer.bUserAction, cbSubOperateCode = pBuffer.bSubUserAction})
            end
            self:updatePlayerInfo()
            self:updatehandplate()
            self.tableLayer:updateLeftCardCount(pBuffer.bLeftCardCount)
            return
            
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end
    else
        return print("error, not found this :",mainCmdID, subCmdID)
    end
    self.isRunningActions = true
    
end

function GameLayer:EVENT_TYPE_OPERATIONAL_OUT_CARD(event)
    local data = event._usedata
    local wChairID = data.wChairID
    local cbCardData = data.cbCardData
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OUT_CARD,"b",cbCardData)
end

function GameLayer:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    self:startGame(UserData.User.userID, data)
end

--更新玩家信息
function GameLayer:updatePlayerInfo()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    uiPanel_player:setVisible(true)
    local online = true
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i - 1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        uiPanel_player:setVisible(true)
        local uiImage_other = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_other")
        if GameCommon.bIsHuangZhuang == true and GameCommon.tableConfig.nTableType ~= TableType_GoldRoom then
            local logo = ("zipai/table/end_play_huangfan.png")
            local texture = cc.TextureCache:getInstance():addImage(logo)        
            uiImage_other:loadTexture(logo)
            uiImage_other:setContentSize(texture:getContentSizeInPixels())
        else
            local logo = ("common/hall_5.png")
            local texture = cc.TextureCache:getInstance():addImage(logo)        
            uiImage_other:loadTexture(logo)
            uiImage_other:setContentSize(texture:getContentSizeInPixels())
        end  
        if GameCommon.player == nil or GameCommon.player[wChairID] == nil then
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(false)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            online =  false
        else
            print(wChairID, viewID,GameCommon.player[wChairID].szNickName)
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(true)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            Common:requestUserAvatar(GameCommon.player[wChairID].dwUserID,GameCommon.player[wChairID].szPto,uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
            uiText_name:setString(GameCommon.player[wChairID].szNickName)
            local Text_huXi = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_huXi") 
            local Text_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score") 
            --个人添加
            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            local dwGold = Common:itemNumberToString(GameCommon.player[wChairID].lScore)
            uiText_score:setString(tostring(dwGold))   
            self:updatePlayerHuXi(wChairID)            
        end
    end
    if online then 
        local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
        uiButton_Invitation:setVisible(false)
        local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
        uiButton_ready:setPositionX(uiButton_ready:getParent():getContentSize().width*0.5)
    else
        local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
        uiButton_Invitation:setVisible(true)
        local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
        uiButton_ready:setPositionX(uiButton_ready:getParent():getContentSize().width*0.6)
    end
    local uiImage_other = ccui.Helper:seekWidgetByName(self.root,"Image_huangfan")
    if GameCommon.bIsHuangZhuang == true and GameCommon.tableConfig.nTableType ~= TableType_GoldRoom then
        local logo = ("zipai/table/end_play_huangfan.png")
        local texture = cc.TextureCache:getInstance():addImage(logo)        
        uiImage_other:loadTexture(logo)
        uiImage_other:setContentSize(texture:getContentSizeInPixels())
    else
        local logo = ("common/hall_5.png")
        local texture = cc.TextureCache:getInstance():addImage(logo)        
        uiImage_other:loadTexture(logo)
        uiImage_other:setContentSize(texture:getContentSizeInPixels())
    end 
end

function GameLayer:updatePlayerlScore()
    if GameCommon.gameConfig == nil then
        return
    end
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
        local dwGold = Common:itemNumberToString(GameCommon.player[wChairID].lScore)
        uiText_score:setString(tostring(dwGold))   
    end
end

function GameLayer:updatehandplate()
    if  GameCommon.gameConfig == nil then
        return
    end
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiText_Houdplate = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_Houdplate")
        if uiText_Houdplate == nil then
            return
        end
        local Text_fontIcon = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_fontIcon")
        if GameCommon.player[wChairID].bUserCardCount <= 3 then
            uiText_Houdplate:setTextColor(cc.c3b(255,40,40))
            Text_fontIcon:setTextColor(cc.c3b(255,40,40))
        else
            uiText_Houdplate:setTextColor(cc.c3b(255,223,113))
            Text_fontIcon:setTextColor(cc.c3b(255,223,113)) 
        end
        uiText_Houdplate:setString(GameCommon.player[wChairID].bUserCardCount)
    end
end

function GameLayer:updateBankerUser()
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
        if GameCommon.player[wChairID] ~= nil and GameCommon.player[wChairID].wChairID == GameCommon.wBankerUser then
            uiImage_banker:loadTexture("game/game_table_banker.png")
            local texture = cc.TextureCache:getInstance():addImage("game/game_table_banker.png")
            uiImage_banker:setContentSize(texture:getContentSizeInPixels())
            uiImage_banker:setVisible(true)
        else
            local duijia = (GameCommon.wBankerUser - 1 + GameCommon.gameConfig.bPlayerCount - 1) % GameCommon.gameConfig.bPlayerCount
            if GameCommon.gameConfig.bPlayerCount == 4 and wChairID == duijia then
                uiImage_banker:loadTexture("game/paohuzi10.png")
                local texture = cc.TextureCache:getInstance():addImage("game/paohuzi10.png")
                uiImage_banker:setContentSize(texture:getContentSizeInPixels())
                uiImage_banker:setVisible(true)
            else
                uiImage_banker:setVisible(false)
            end
        end 
    end
end

function GameLayer:updatePlayerHuXi(wChairID)
    local huXiCount = 0
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    if GameCommon.player[wChairID].WeaveItemArray ~= nil then
        for key, var in pairs(GameCommon.player[wChairID].WeaveItemArray) do     
            if (var.cbWeaveKind == GameCommon.ACK_TI and GameCommon.tiCardType == 1 and wChairID ~= GameCommon:getRoleChairID()) or
                (var.cbWeaveKind == GameCommon.ACK_WEI and GameCommon.weiCardType == 1 and wChairID ~= GameCommon:getRoleChairID()) then
                
            else
                huXiCount = huXiCount + GameLogic:GetWeaveHuXi(var) 
            end                
        end
    end
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    local uiText_huXi = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_huXi")
    GameCommon.player[wChairID].huXiCount = huXiCount
    uiText_huXi:setString(string.format("%d胡息",huXiCount))
    if viewID == 1  then
        uiText_huXi:setString(string.format("%d胡息",huXiCount+GameCommon.handHuXiNum))
    end 
end

function GameLayer:updatePlayerReady()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_ready = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_ready")
            if GameCommon.player[wChairID].bReady == true then
                uiImage_ready:setVisible(true)
            else
                uiImage_ready:setVisible(false)
            end
            if  GameCommon.player[wChairID].dwUserID == GameCommon.dwUserID and GameCommon.player[wChairID].bReady == true or GameCommon.gameState == GameCommon.GameState_Start  then
                local uiButton_ready = ccui.Helper:seekWidgetByName(self.root,"Button_ready")
                if GameCommon.tableConfig.wCurrentNumber == 0 then 
                    uiButton_ready:setBright(false)
                else
                    uiButton_ready:setVisible(false)
                end 
            end
        end     
    end
    --距离报警 
    if GameCommon.tableConfig.wCurrentNumber ~= nil and GameCommon.tableConfig.wCurrentNumber == 0 then
        GameCommon.DistanceAlarm = 0
    end
end

function GameLayer:updatePlayerOnline()
    if GameCommon.gameConfig == nil then
        return
    end
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,"Panel_player")
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
            local uiImage_offline = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_offline")
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            if GameCommon.player[wChairID].cbOnline == 0x06 then
                uiImage_offline:setVisible(true)
                uiImage_avatar:setColor(cc.c3b(170,170,170))
            else
                uiImage_offline:setVisible(false)
                uiImage_avatar:setColor(cc.c3b(255,255,255))
            end
        end     
    end
end

function GameLayer:updatePlayerPosition()
    if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom and GameCommon.tableConfig.wCurrentNumber == 0  then
        self.tableLayer:showPlayerPosition(GameCommon.tableConfig.wKindID)
    end
end

function GameLayer:updateBtnState( )
    if GameCommon.gameConfig.bPlayerCount <=2 then
        return
    end
    
    if GameCommon.tableConfig.nTableType ~= TableType_FriendRoom and GameCommon.tableConfig.nTableType ~= TableType_ClubRoom then
        return
    end

    if GameCommon.tableConfig.wCurrentNumber == nil or GameCommon.tableConfig.wCurrentNumber ~= 0 then
        return
    end

    local bCurrentPlayerCount = 0
    for k,v in pairs(GameCommon.player) do
        bCurrentPlayerCount = bCurrentPlayerCount + 1
    end
    if bCurrentPlayerCount ~= GameCommon.gameConfig.bPlayerCount then
        return
    end

    local tips = require("common.DistanceTip")
    tips:checkDis(GameCommon.tableConfig.wKindID)
end

return GameLayer


