local StaticData = require("app.static.StaticData")
local Common = require("common.Common")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local GameCommon = require("game.majiang.GameCommon")  
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local GameLogic = require("game.majiang.GameLogic")
local GameDesc = require("common.GameDesc")

local TableLayer = require("game.majiang.TableLayer")

local APPNAME = 'majiang'
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
    GameCommon.mHuCard = {}
    GameCommon.mBaoTingCard = {}  -- 报听牌制空 防止上局解散时报听数据没有清空

    GameCommon.mGang = false      --长沙麻将杠精出世

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("KwxGameLayerMaJiang.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb       
    GameCommon:init()
    GameCommon.wKindID = GameCommon.tableConfig.wKindID
    local regionSound = cc.UserDefault:getInstance():getFloatForKey('volumeSelect', 1) 
    if regionSound ~= nil and regionSound == 0 then
        GameCommon.regionSound = 0
    else
        GameCommon.regionSound = 1
    end
    
    self:resetPiaoFen()
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
            uiText_title:setString(string.format("%s 房间号:%d 局数:%d/%d",StaticData.Games[GameCommon.tableConfig.wKindID].name,GameCommon.tableConfig.wTbaleID,GameCommon.tableConfig.wCurrentNumber,GameCommon.tableConfig.wTableNumber))
            self.tableLayer:updatePaijuInfo()
            return true
            
        elseif subCmdID == NetMsgId.SUB_GR_DISMISS_TABLE_SUCCESS then
            if GameCommon.gameState ~= GameCommon.GameState_Init  or GameCommon.tableConfig.wCurrentNumber ~= 0 then
                require("common.MsgBoxLayer"):create(0,nil,"房间解散成功！") 
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            else
                if not UserData.Guild.isChangeClubTable then
                    require("common.MsgBoxLayer"):create(2,nil,"房间解散成功！",function(sender,event) 
                        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                    end)
                else
                    EventMgr:dispatch(EventType.RET_FREE_CLUB_CHANGE_TABLE_NOTICES)
                end   
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
            data.cbCardCount = 0
            data.cbCardData = {}
            data.cbCardIndex = nil
            data.cbCardCoutWW = 0
            data.bWeaveItemCount = 0
            data.WeaveItemArray = {}
            data.cbDiscardCount = 0
            data.cbDiscardCard = {}
            data.cardNode = {}
            printInfo(data)
            GameCommon.player[data.wChairID] = data
            if data.dwUserID == GameCommon.dwUserID or GameCommon.meChairID == nil then
                GameCommon.meChairID = data.wChairID
            end
            self:updatePlayerInfo()
            self:updatePlayerOnline()
            self:updatePlayerReady()
            self:updateBtnState(false)
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
            print("+++++++++++++++++红包",_tagMsg.pBuffer.lRet,_tagMsg.pBuffer.bType)
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
            
        else
            print("not found this subCmdID : %d",subCmdID)
            return false
        end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.RET_SC_GAME_CONFIG then
            GameCommon.gameConfig = require("common.GameConfig"):getParameter(GameCommon.tableConfig.wKindID,luaFunc)
            local uiText_desc = ccui.Helper:seekWidgetByName(self.root,"Text_desc")
            uiText_desc:setString(GameDesc:getGameDesc(GameCommon.tableConfig.wKindID,GameCommon.gameConfig,GameCommon.tableConfig))
            return true
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_SelectZhuang then
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()        --庄家用户
            self:updatePlayerPiaoFen()
            return true                    
        elseif subCmdID == NetMsgId.SUB_S_GAME_START_MAJIANG then
            _tagMsg.pBuffer.wSiceCount = luaFunc:readRecvWORD()         --骰子点数
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()        --庄家用户
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()       --当前用户
            _tagMsg.pBuffer.cbCardData = {}                             --麻将列表
            for i = 1 , 14 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wChairID = luaFunc:readRecvWORD()       --当前用户

        elseif subCmdID == NetMsgId.SUB_S_SpecialCard then
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()        --当前用户
            _tagMsg.pBuffer.cbUserAction = luaFunc:readRecvWORD()       --用户动作
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1, 14 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
 
        elseif subCmdID == NetMsgId.SUB_S_SpecialCard_RESULT then
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()        --当前用户
            _tagMsg.pBuffer.cbUserAction = luaFunc:readRecvWORD()       --用户动作
            _tagMsg.pBuffer.wSiceCount = luaFunc:readRecvWORD()         --骰子点数
            _tagMsg.pBuffer.lGameScore = {}
            for i = 1 , 4 do                                            --游戏输赢积分
                _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong()
            end
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 14 do                                            --麻将列表
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wTargetUser = luaFunc:readRecvWORD()        --目标用户
            
        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_NOTIFY_MAJIANG then             --用户提示出牌
            _tagMsg.pBuffer.wOutCardUser = luaFunc:readRecvWORD()       --还原用户
           print("++++++++++++++++++++++提示用户出牌") 
        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_RESULT then             --用户出牌
            _tagMsg.pBuffer.wOutCardUser = luaFunc:readRecvWORD()       --出牌用户
            _tagMsg.pBuffer.cbOutCardData = luaFunc:readRecvByte()      --出牌麻将
            local a = 1 
        elseif subCmdID == NetMsgId.SUB_S_JIA_PIAO_80 then

            _tagMsg.pBuffer.wPiaoTF = {}
        
            for i=1,4 do
                _tagMsg.pBuffer.wPiaoTF[i] = luaFunc:readRecvBool()
            end

            _tagMsg.pBuffer.mPiaoCount = {}
            for i=1,4 do
                _tagMsg.pBuffer.mPiaoCount[i] = luaFunc:readRecvByte()
            end
            --dump(_tagMsg.pBuffer,'fx------选票-------->>')

        elseif subCmdID == NetMsgId.SUB_S_SEND_CARD_MAJIANG then                   --发牌消息
            _tagMsg.pBuffer.cbCardData = luaFunc:readRecvByte()         --麻将数据
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()       --当前用户
            _tagMsg.pBuffer.wSiceCount = luaFunc:readRecvWORD()       --骰子点数
            _tagMsg.pBuffer.wOperateCode = luaFunc:readRecvWORD()       --执行发牌动作先前动作
            
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_NOTIFY_MAJIANG then              --操作提示
            _tagMsg.pBuffer.wResumeUser = luaFunc:readRecvWORD()        --还原用户
            _tagMsg.pBuffer.cbActionMask = luaFunc:readRecvWORD()       --动作掩码
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()       --动作麻将
            _tagMsg.pBuffer.bIsSelf = luaFunc:readRecvBool()            --
            _tagMsg.pBuffer.cbGangCard = {}
            for i = 1, 4 do
                _tagMsg.pBuffer.cbGangCard[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbBuCard = {}
            for i = 1, 4 do
                _tagMsg.pBuffer.cbBuCard[i] = luaFunc:readRecvByte()
            end

        elseif subCmdID == NetMsgId.SUB_S_BAOTINGOUTCARD then           --报听可删牌数据   
            _tagMsg.pBuffer.cbBTCard = {}    ---  
            for i = 1, 14 do
                _tagMsg.pBuffer.cbBTCard[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.mBTHuCard= {}      ----  
            for i = 1, 14 do
                _tagMsg.pBuffer.mBTHuCard[i]= {}
                for j = 1, 27 do
                    _tagMsg.pBuffer.mBTHuCard[i][j] = luaFunc:readRecvByte()
                end 
            end 
            print("+++++++++报停有理+++++++")
        -- elseif subCmdID == NetMsgId.SUB_S_ACTION_BAOTINGCARD then        --报听可胡哪些牌数据
        --     _tagMsg.pBuffer.cbGangCard = {}
        --     for i = 1, 27 do
        --         _tagMsg.pBuffer.cbGangCard[i] = luaFunc:readRecvByte()
        --     end
        --     self.tableLayer:showBaoting(_tagMsg.pBuffer)
        --     return true
        elseif subCmdID == NetMsgId.SUB_S_GANG_CARD_DATA then        --返回客户端开杠后相关牌数据
							
            _tagMsg.pBuffer.wResumeUser = luaFunc:readRecvWORD()            --还原用户
            _tagMsg.pBuffer.cbCardCount = luaFunc:readRecvByte()            --累加数据
            _tagMsg.pBuffer.mGangItemArray = {}         --组合麻将	2019.2.12  70版新改  （共24张：杠起6张公牌----极限情况下有吃、碰、杠、胡各6次）
            for  i = 1,24 do
                _tagMsg.pBuffer.mGangItemArray[i] = {}
                _tagMsg.pBuffer.mGangItemArray[i].cbGangKind = luaFunc:readRecvWORD()
                _tagMsg.pBuffer.mGangItemArray[i].cbPublicCard = luaFunc:readRecvByte()
                print("++++++++首杠+++++++",i,_tagMsg.pBuffer.mGangItemArray[i].cbGangKind,_tagMsg.pBuffer.mGangItemArray[i].cbPublicCard )
            end 
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_RESULT then              --操作结果
            _tagMsg.pBuffer.wOperateUser = luaFunc:readRecvWORD()       --操作用户
            _tagMsg.pBuffer.wProvideUser = luaFunc:readRecvWORD()       --供应用户
            _tagMsg.pBuffer.cbOperateCode = luaFunc:readRecvWORD()      --操作代码
            _tagMsg.pBuffer.cbOperateCard = luaFunc:readRecvByte()      --操作麻将
            _tagMsg.pBuffer.cbUserCardCout = luaFunc:readRecvByte()     --用户扑克
            _tagMsg.pBuffer.cbPublicCard = luaFunc:readRecvByte()       --用户扑克
            print("---------------用户操作",_tagMsg.pBuffer.cbOperateCode,_tagMsg.pBuffer.wProvideUser,_tagMsg.pBuffer.cbPublicCard,_tagMsg.pBuffer.cbUserCardCout)
        elseif subCmdID == NetMsgId.SUB_S_CASTDICE_NOTIFY then             --要帅提示
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()       --要帅用户
            _tagMsg.pBuffer.bIsTingPai = luaFunc:readRecvBool()         --用户听牌
            return true
            
        elseif subCmdID == NetMsgId.SUB_S_CASTDICE_RESULT then             --要帅结果
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()       --要帅用户
            _tagMsg.pBuffer.wDiceCount = luaFunc:readRecvWORD()         --骰子大小
            -- _tagMsg.pBuffer.wDiceCardOne = luaFunc:readRecvByte()
            -- _tagMsg.pBuffer.wDiceCardTwo = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wDiceCard = {}
            for  i = 1,6 do
                _tagMsg.pBuffer.wDiceCard[i] = luaFunc:readRecvByte()
            end 
            --投骰子的结果
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_END_MAJIANG then                    --游戏结束
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvByte()        --庄家
            _tagMsg.pBuffer.cbChiHuCard = {}
            for i = 1,4 do
                _tagMsg.pBuffer.cbChiHuCard[i] = {}
                for j = 1, 6 do
                    _tagMsg.pBuffer.cbChiHuCard[i][j] = luaFunc:readRecvByte() --吃胡麻将
                end
            end
            _tagMsg.pBuffer.cbZhanNiaoCount = {}
            for i = 1,4 do
                _tagMsg.pBuffer.cbZhanNiaoCount[i] = luaFunc:readRecvByte() --扎鸟次数
            end
            _tagMsg.pBuffer.bZhaNiao = {}
            for i = 1 , 6 do
                _tagMsg.pBuffer.bZhaNiao[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wProvideUser = luaFunc:readRecvWORD()       --点炮用户
            _tagMsg.pBuffer.wWinner = {}
            for i = 1,4 do
                if i == 4 then
                    _tagMsg.pBuffer.wWinner[i] = luaFunc:readRecvBool() --赢家
                else
                    _tagMsg.pBuffer.wWinner[i] = luaFunc:readRecvBool()
                end
            end
            _tagMsg.pBuffer.lGameScore = {}
            for i = 1,4 do
                _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong() --游戏积分
            end
            _tagMsg.pBuffer.wChiHuKind = {}
            for i = 1,4 do
                _tagMsg.pBuffer.wChiHuKind[i] = luaFunc:readRecvWORD() --胡牌类型
            end
            _tagMsg.pBuffer.wSpecialKind = {}
            for i = 1,4 do
                _tagMsg.pBuffer.wSpecialKind[i] = luaFunc:readRecvWORD() --胡牌类型
            end
            _tagMsg.pBuffer.cbCardCount = {}
            for i = 1,4 do
                _tagMsg.pBuffer.cbCardCount[i] = luaFunc:readRecvByte() --麻将数目
            end
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.cbCardData[i] = {}
                for j = 1 , 14 do
                    _tagMsg.pBuffer.cbCardData[i][j] = luaFunc:readRecvByte()   --麻将数据
                end
            end
            _tagMsg.pBuffer.strEnd = {}
            for i = 1 , 100 do
                _tagMsg.pBuffer.strEnd[i] = luaFunc:readRecvByte()
            end

            _tagMsg.pBuffer.lCellScore =  luaFunc:readRecvLong()       --单位游戏币
            _tagMsg.pBuffer.lGameTax = luaFunc:readRecvInt()            --税收
            _tagMsg.pBuffer.cbChiHuSpecial = luaFunc:readRecvBool()     --特殊胡牌

            _tagMsg.pBuffer.cbWeaveItemCount ={}
            for i = 1 , 4 do
                if i == 4 then
                    _tagMsg.pBuffer.cbWeaveItemCount[i] = luaFunc:readRecvByte()    --组合数目
                else
                    _tagMsg.pBuffer.cbWeaveItemCount[i] = luaFunc:readRecvByte()    --组合数目
                end

            end
            _tagMsg.pBuffer.WeaveItemArray ={}
            for i = 1 , 4 do
                _tagMsg.pBuffer.WeaveItemArray[i] = {}
                for j = 1 , 4 do
                    _tagMsg.pBuffer.WeaveItemArray[i][j] = {}
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbWeaveKind = luaFunc:readRecvWORD()   --组合类型
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbCenterCard = luaFunc:readRecvByte()  --中心麻将
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbPublicCard = luaFunc:readRecvByte()  --公开标志
                    _tagMsg.pBuffer.WeaveItemArray[i][j].wProvideUser = luaFunc:readRecvWORD()   --供应用户
                end
            end
            _tagMsg.pBuffer.wDiceCount = {}
            for i = 1,4 do
                _tagMsg.pBuffer.wDiceCount[i] = luaFunc:readRecvByte() --骰子数量
            end
            _tagMsg.pBuffer.mPiaoCount = {}
            for i = 1,4 do
                _tagMsg.pBuffer.mPiaoCount[i] = luaFunc:readRecvByte() --飘分
            end  
            _tagMsg.pBuffer.mFanCount = {}  
            for i = 1,4 do
                _tagMsg.pBuffer.mFanCount[i] = luaFunc:readRecvByte() --番数
            end 

        elseif subCmdID == NetMsgId.SUB_S_OPERATE_HAIDI then
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()           --海底用户
            _tagMsg.pBuffer.bTingPai = luaFunc:readRecvBool()               --用户听牌
            
        elseif subCmdID == NetMsgId.SUB_S_SEND_HAIDICARD then
            _tagMsg.pBuffer.cbCardData = luaFunc:readRecvByte()           --麻将数据
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()               --当前用户
            _tagMsg.pBuffer.wOperateCode = luaFunc:readRecvWORD()               --执行发牌动作先前动作
    
        elseif subCmdID == NetMsgId.SUB_S_SEND_PIAO_RESULT then 
            _tagMsg.pBuffer.mPiaoCount = {}
             for i = 1,4 do   
               _tagMsg.pBuffer.mPiaoCount[i] = luaFunc:readRecvByte()
             end 
             _tagMsg.pBuffer.mPiaoUser = {}
             for i = 1,4 do
                 _tagMsg.pBuffer.mPiaoUser[i] = luaFunc:readRecvBool()  
             end 
             
        elseif subCmdID == NetMsgId.SUB_S_GAME_END_TIPS_MAJIANG then       --游戏胡牌提示
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvByte()        --庄家
            _tagMsg.pBuffer.wProvideUser = luaFunc:readRecvWORD()       --点炮用户
            _tagMsg.pBuffer.wWinner = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.wWinner[i] = luaFunc:readRecvBool()     --赢家
            end
            _tagMsg.pBuffer.bZhaNiao = {}
            for i = 1 , 85 do
                _tagMsg.pBuffer.bZhaNiao[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.bzhaoniaoCount = luaFunc:readRecvByte()
            _tagMsg.pBuffer.lGameScore = {}
            for i = 1,4 do
                _tagMsg.pBuffer.lGameScore[i] = luaFunc:readRecvLong() --游戏积分
            end
            _tagMsg.pBuffer.cbCardCount = {}
            for i = 1,4 do
                _tagMsg.pBuffer.cbCardCount[i] = luaFunc:readRecvByte() --麻将数目
            end
            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.cbCardData[i] = {}
                for j = 1 , 14 do
                    _tagMsg.pBuffer.cbCardData[i][j] = luaFunc:readRecvByte()   --麻将数据
                end
            end
            return true
            
        elseif subCmdID == NetMsgId.SUB_S_ADD_BASE then    --用户加倍
            return
            
        elseif subCmdID == NetMsgId.SUB_S_ADD_BASE_VIEW then    --用户加倍表现
            _tagMsg.pBuffer.wActionUser = luaFunc:readRecvWORD()    --动作用户
            _tagMsg.pBuffer.IsAdd = luaFunc:readRecvBool()    --加倍 
            return true
            
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
            _tagMsg.pBuffer.lCellScore = luaFunc:readRecvLong()                    --单元积分
            _tagMsg.pBuffer.wSiceCount = luaFunc:readRecvWORD()                    --骰子点数
            _tagMsg.pBuffer.wBankerUser = luaFunc:readRecvWORD()                   --庄家用户
            _tagMsg.pBuffer.wCurrentUser = luaFunc:readRecvWORD()                  --当前用户
            --状态变量
            _tagMsg.pBuffer.cbActionCard = luaFunc:readRecvByte()                 --动作麻将
            _tagMsg.pBuffer.cbActionMask = luaFunc:readRecvWORD() 
            _tagMsg.pBuffer.cbLeftCardCount = luaFunc:readRecvByte()               --剩余数目
            --出牌信息
            _tagMsg.pBuffer.wOutCardUser = luaFunc:readRecvWORD()                     --出牌用户
            _tagMsg.pBuffer.cbOutCardData = luaFunc:readRecvByte()                  --出牌麻将
            _tagMsg.pBuffer.cbDiscardCount = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.cbDiscardCount[i] = luaFunc:readRecvByte()          --丢弃数目
            end
            _tagMsg.pBuffer.cbDiscardCard = {}
            for i = 1,4 do
                _tagMsg.pBuffer.cbDiscardCard[i] = {}
                for j = 1 , 55 do
                    _tagMsg.pBuffer.cbDiscardCard[i][j] = luaFunc:readRecvByte()        --丢弃记录
                end
            end
            --麻将数据
            _tagMsg.pBuffer.cbCardCount = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.cbCardCount[i] = luaFunc:readRecvByte()          --麻将数目
            end

            _tagMsg.pBuffer.cbCardData = {}
            for i = 1 , 14 do
                _tagMsg.pBuffer.cbCardData[i] = luaFunc:readRecvByte()          --麻将列表
            end
            --组合麻将
            _tagMsg.pBuffer.cbWeaveCount = {}
            for i = 1 , 4 do
                if i == 4 then
                    _tagMsg.pBuffer.cbWeaveCount[i] = luaFunc:readRecvByte()
                else
                    _tagMsg.pBuffer.cbWeaveCount[i] = luaFunc:readRecvByte()          --组合数目
                end
            end
            _tagMsg.pBuffer.WeaveItemArray = {}                                     --组合麻将
            for i = 1,4 do
                if _tagMsg.pBuffer.WeaveItemArray[i] == nil then
                    _tagMsg.pBuffer.WeaveItemArray[i] = {}
                end
                for j = 1 , 4 do
                    if _tagMsg.pBuffer.WeaveItemArray[i][j] == nil then
                        _tagMsg.pBuffer.WeaveItemArray[i][j] = {}
                    end
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbWeaveKind = luaFunc:readRecvWORD()   --组合类型
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbCenterCard = luaFunc:readRecvByte()  --中心麻将
                    _tagMsg.pBuffer.WeaveItemArray[i][j].cbPublicCard = luaFunc:readRecvByte()  --公开标志
                    _tagMsg.pBuffer.WeaveItemArray[i][j].wProvideUser = luaFunc:readRecvWORD()  --供应用户
                end
            end
            --状态记录
            _tagMsg.pBuffer.cbReceiveClientKind = luaFunc:readRecvByte()            --等待状态
            _tagMsg.pBuffer.cbGangYaoshuai = luaFunc:readRecvBool()                 --是否要甩
            --骰子记录
            _tagMsg.pBuffer.m_wDiceCount = luaFunc:readRecvByte()                   

            _tagMsg.pBuffer.stDiceRecord = {}
            for i = 1 , 20 do
                _tagMsg.pBuffer.stDiceRecord[i] = {}
                _tagMsg.pBuffer.stDiceRecord[i].wSiceUser =  luaFunc:readRecvWORD() --骰子用户
                _tagMsg.pBuffer.stDiceRecord[i].wSiceCount =  luaFunc:readRecvWORD()    --骰子点数
                _tagMsg.pBuffer.stDiceRecord[i].wOperateCode =  luaFunc:readRecvWORD()  --动作
            end
            _tagMsg.pBuffer.m_StoreCardAll = {}
            for i = 1 ,108 do
                _tagMsg.pBuffer.m_StoreCardAll[i] = luaFunc:readRecvByte()              --库存麻将表现
            end
            _tagMsg.pBuffer.wDiceCardOne = luaFunc:readRecvByte()
            _tagMsg.pBuffer.wDiceCardTwo = luaFunc:readRecvByte()
            _tagMsg.pBuffer.cbUserAction = luaFunc:readRecvWORD()        --当前用户
            _tagMsg.pBuffer.cbSpecialCardData = {}                      --起手小胡断线重连处理
            for i = 1, 14 do
                _tagMsg.pBuffer.cbSpecialCardData[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.wHaiDiUser = luaFunc:readRecvWORD()        --当前用户
            _tagMsg.pBuffer.cbGangCard = {}
            for i = 1, 4 do
                _tagMsg.pBuffer.cbGangCard[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.cbBuCard = {}
            for i = 1, 4 do
                _tagMsg.pBuffer.cbBuCard[i] = luaFunc:readRecvByte()
            end 
            _tagMsg.pBuffer.mPiaoUser = {}
            for i = 1,4 do
                _tagMsg.pBuffer.mPiaoUser[i] = luaFunc:readRecvBool()  
            end 
            _tagMsg.pBuffer.mPiaoCount = {}
            for i = 1,4 do   
                _tagMsg.pBuffer.mPiaoCount[i] = luaFunc:readRecvByte()
            end  
	    _tagMsg.pBuffer.mBaoTingCardEx = {}
            for i = 1, 14 do
                _tagMsg.pBuffer.mBaoTingCardEx[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.mAloneBaoTingCardEx = {}
            for i = 1, 27 do
                _tagMsg.pBuffer.mAloneBaoTingCardEx[i] = luaFunc:readRecvByte()
            end 

            _tagMsg.pBuffer.wDiceCard = {}
            for  i = 1,6 do
                _tagMsg.pBuffer.wDiceCard[i] = luaFunc:readRecvByte()
            end 

            _tagMsg.pBuffer.mcbGangItemCount = luaFunc:readRecvByte()--组合数目	2019.2.12  70版新改 

            _tagMsg.pBuffer.mGangItemArray = {}         --组合麻将	2019.2.12  70版新改  （共24张：杠起6张公牌----极限情况下有吃、碰、杠、胡各6次）
            for  i = 1,24 do
                _tagMsg.pBuffer.mGangItemArray[i] = {}
                _tagMsg.pBuffer.mGangItemArray[i].cbGangKind = luaFunc:readRecvWORD()
                _tagMsg.pBuffer.mGangItemArray[i].cbPublicCard = luaFunc:readRecvByte()
                print("++++++++杠+++++++",i,_tagMsg.pBuffer.mGangItemArray[i].cbGangKind,_tagMsg.pBuffer.mGangItemArray[i].cbPublicCard )
            end 

---  垃圾数据   --
            _tagMsg.pBuffer.cbBTCard = {}    ---  
            for i = 1, 14 do
                _tagMsg.pBuffer.cbBTCard[i] = luaFunc:readRecvByte()
            end
            _tagMsg.pBuffer.mBTHuCard= {}      ----  
            for i = 1, 14 do
                _tagMsg.pBuffer.mBTHuCard[i]= {}
                for j = 1, 27 do
                    _tagMsg.pBuffer.mBTHuCard[i][j] = luaFunc:readRecvByte()
                end 
            end   
----------------------------	    
	        _tagMsg.pBuffer.bJiaoPiaoUser = {}                          --加漂操作用户
            for i = 1, 4 do
                _tagMsg.pBuffer.bJiaoPiaoUser[i] = luaFunc:readRecvBool()

            end
            _tagMsg.pBuffer.mJiaoPiaoCount = {}                         --加漂数据
            for i = 1, 4 do
                _tagMsg.pBuffer.mJiaoPiaoCount[i] = luaFunc:readRecvByte()
            end 
            local aa  = 11  
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_SCORE then
            _tagMsg.pBuffer.lUserScore = {}
            for i = 1 , 4 do
                _tagMsg.pBuffer.lUserScore[i] = luaFunc:readRecvLong()
            end	
            return true
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


--牌值转换
function GameLayer:SwitchToCardDataOne(cbCardIndex)--麻将转换
    local cbCardIndex = cbCardIndex - 1
    assert(cbCardIndex<=34)

    local value3 = math.floor(cbCardIndex / 9)

    local value1 = Bit:_lshift(value3,4)
    local value2 = (cbCardIndex % 9 + 1 )
    local value = Bit:_or( value1 , value2)
    return value
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

--------------------------
--des:获取胡牌数据
--time:2018-08-29 14:46:30
--------------------------
function GameLayer:getHuCardData( pBuffer )
    if not pBuffer then
        return nil
    end
    local huCard = nil --胡牌
    local huwChairID = nil  --胡牌chairid
    for i = 1,GameCommon.gameConfig.bPlayerCount do
        for j = 1 , pBuffer.cbCardCount[i] do
            local data = pBuffer.cbCardData[i][j]
            for n = 1 , 6 do 
                if data == pBuffer.cbChiHuCard[i][n] then
                    huCard = data
                    huwChairID = i-1
                    break
                end
            end 
        end
    end
    return huCard,huwChairID
end

--消息执行
function GameLayer:OnGameMessageRun(_tagMsg)
    local mainCmdID = _tagMsg.mainCmdID
    local subCmdID = _tagMsg.subCmdID
    local pBuffer = _tagMsg.pBuffer
    print("-------------消息执行_____------:",mainCmdID,subCmdID,pBuffer)
    if mainCmdID == NetMsgId.MDM_GR_USER then   
        if subCmdID == NetMsgId.SUB_GR_GAME_STATISTICS then
            self:removeAllChildren()
            local layer = require("game.majiang.KwxGameOver"):create(pBuffer)
            self:addChild(layer)
        else
            return print("error, not found this :",mainCmdID, subCmdID)
        end
    -- elseif mainCmdID == NetMsgId.MDM_GR_USER then   
    --     if subCmdID == NetMsgId.SUB_GR_USER_STATISTICS then
    --         self:removeAllChildren()
    --         local layer = require("game.majiang.KwxGameOver"):create(pBuffer)
    --         self:addChild(layer)
    --     else
    --         return print("error, not found this :",mainCmdID, subCmdID)
    --     end
        
    elseif mainCmdID == NetMsgId.MDM_GF_GAME then
        if subCmdID == NetMsgId.SUB_S_GAME_START_MAJIANG then
            --开始游戏
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            local wChairID = pBuffer.wChairID
            GameCommon.waitOutCardUser = pBuffer.wBankerUser
            for i = 0, 3 do
                if GameCommon.player[i] ~= nil then
                    if i == pBuffer.wBankerUser then
                         GameCommon.player[i].cbCardCount = 14
                    else
                        GameCommon.player[i].cbCardCount = 13
                    end
                    if i == wChairID then
                        self.tableLayer:setHandCard(i,GameCommon.player[i].cbCardCount, pBuffer.cbCardData)
                    end
                    self.tableLayer:showHandCard({wChairID = i, cbAction = true})
                end
            end
            local cbLeftCardCount = 108
            if GameCommon.gameConfig.bWuTong == 0 then
                cbLeftCardCount = cbLeftCardCount - 36
            end
            cbLeftCardCount = cbLeftCardCount - 13*GameCommon.gameConfig.bPlayerCount - 1
            self.tableLayer:updateLeftCardCount(cbLeftCardCount)
            GameCommon.wBankerUser = pBuffer.wBankerUser
            self.tableLayer:showCountDown(GameCommon.wBankerUser)
            self:updateBankerUser()
            self:updatePlayerInfo()
            self:updatehandplate()
            self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        
        elseif subCmdID == NetMsgId.SUB_S_SpecialCard then
            self.tableLayer:doAction(NetMsgId.SUB_S_SpecialCard, pBuffer)

        elseif subCmdID == NetMsgId.SUB_S_SpecialCard_RESULT then
            self.tableLayer:doAction(NetMsgId.SUB_S_SpecialCard_RESULT, pBuffer)
                        
        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_NOTIFY_MAJIANG then             --用户提示出牌
            self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_NOTIFY_MAJIANG, pBuffer)

        elseif subCmdID == NetMsgId.SUB_S_OUT_CARD_RESULT then             --用户出牌
            self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_RESULT, pBuffer)
            GameCommon.iNOoutcard = false
            self:updatehandplate()

        elseif subCmdID == NetMsgId.SUB_S_SEND_CARD_MAJIANG then                   --发牌消息
            self.tableLayer:doAction(NetMsgId.SUB_S_SEND_CARD_MAJIANG, pBuffer)
            self:updatehandplate()
        elseif subCmdID == NetMsgId.SUB_S_JIA_PIAO_80 then
            ---加票
            self.tableLayer:updateGameState(GameCommon.GameState_Start)

            for i = 1, GameCommon.gameConfig.bPlayerCount do
                GameCommon.wPiaoCount[i-1] = pBuffer.mPiaoCount[i]
                GameCommon.wPiaoTF[i-1] = pBuffer.wPiaoTF[i]
            end
            self:updatePlayerPiaoFen()
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_NOTIFY_MAJIANG then              --操作提示
            self.tableLayer:doAction(NetMsgId.SUB_S_OPERATE_NOTIFY_MAJIANG,pBuffer)
        elseif subCmdID == NetMsgId.SUB_S_BAOTINGOUTCARD then              --报听可删牌数据      
            -- self.tableLayer:doAction(NetMsgId.SUB_S_BAOTINGOUTCARD,pBuffer)
            self.tableLayer:BaoTingCardShow({cbBTCard = pBuffer.cbBTCard,mBTHuCard = pBuffer.mBTHuCard})
       elseif subCmdID == NetMsgId.SUB_S_ALONE_BAOTINGCARD then           --报听可胡哪些牌数据   
           self.tableLayer:doAction(NetMsgId.SUB_S_ALONE_BAOTINGCARD,pBuffer)
        elseif subCmdID == NetMsgId.SUB_S_GANG_CARD_DATA then        --返回客户端开杠后相关牌数据
            GameCommon.waitGangCardUser = pBuffer.wResumeUser
            self.tableLayer:DataClient(pBuffer)    --相关数据客户端整理运行
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_RESULT then              --操作结果
            GameCommon.iNOoutcard = false
            self.tableLayer:doAction(NetMsgId.SUB_S_OPERATE_RESULT, pBuffer)
        
        elseif subCmdID == NetMsgId.SUB_S_CASTDICE_RESULT then             --要帅结果
            self.tableLayer:doAction(NetMsgId.SUB_S_CASTDICE_RESULT, pBuffer)
            self:updatehandplate()
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_END_MAJIANG then                    --游戏结束
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
            self.tableLayer:updateGameState(GameCommon.GameState_Over)            
            local uiPanel_end = ccui.Helper:seekWidgetByName(self.root,"Panel_end")
            uiPanel_end:setVisible(true)
            uiPanel_end:removeAllChildren()
            uiPanel_end:stopAllActions()
            self:updatePlayerlScore()
            --扎鸟动画
            local visibleSize = cc.Director:getInstance():getVisibleSize()
            local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsCard")
            local index = 0
            for i = 1, GameCommon.gameConfig.bPlayerCount do                
                local count = pBuffer.cbZhanNiaoCount[i]
                local wChairID = i-1
                local viewID = GameCommon:getViewIDByChairID(wChairID)
                for j = 1, count do
                    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("game/niaodonghua/niaodonghua.ExportJson")
                    local armature1 = ccs.Armature:create("niaodonghua")
                    armature1:getAnimation():playWithIndex(0,-1,-1)
                    uiPanel_tipsCard:addChild(armature1)
                    armature1:setPosition(cc.p(armature1:getParent():convertToNodeSpace(cc.p(visibleSize.width*0.5,visibleSize.height*0.5))))
                    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
                    armature1:runAction(cc.Sequence:create(
                    cc.DelayTime:create(index*0.2),
                    cc.MoveTo:create(1,cc.p(armature1:getParent():convertToNodeSpace(cc.p(uiPanel_player:convertToWorldSpace(cc.p(uiPanel_player:getContentSize().width/2,uiPanel_player:getContentSize().height/2)))))),
                    cc.RemoveSelf:create()
                    ))
                end
            end      
            self.tableLayer:doAction(NetMsgId.SUB_S_GAME_END_MAJIANG,{wWinner = pBuffer.wWinner,wProvideUser = pBuffer.wProvideUser})
            
            local huCard,huChairID = self:getHuCardData(pBuffer)
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                GameCommon.player[i-1].cbCardCount = pBuffer.cbCardCount[i]
                self.tableLayer:setHandEndData(i-1,GameCommon.player[i-1].cbCardCount, pBuffer.cbCardData[i],huCard,huChairID)
                self.tableLayer:showHandCard({wChairID = i-1})
            end
            
            --if pBuffer.wProvideUser < GameCommon.gameConfig.bPlayerCount then
            uiPanel_end:runAction(cc.Sequence:create(
                cc.DelayTime:create(2),
                cc.CallFunc:create(function(sender,event) 
                    uiPanel_end:addChild(require("game.majiang.80.GameEndLayer"):create(pBuffer))
                end),
                cc.DelayTime:create(20),
                cc.CallFunc:create(function(sender,event) 
                    if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
                        if GameCommon.tableConfig.wTableNumber == GameCommon.tableConfig.wCurrentNumber then
                            EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
--                        else
--                            GameCommon:ContinueGame(GameCommon.tableConfig.cbLevel)
                        end
                    else
                        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
                    end
                end)))
        elseif subCmdID == NetMsgId.SUB_S_OPERATE_HAIDI then
            self.tableLayer:doAction(NetMsgId.SUB_S_OPERATE_HAIDI, pBuffer)
        
        elseif subCmdID == NetMsgId.SUB_S_SEND_HAIDICARD then
            self.tableLayer:doAction(NetMsgId.SUB_S_SEND_HAIDICARD, pBuffer)
        elseif subCmdID == NetMsgId.SUB_S_SEND_PIAO_RESULT then
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            if  GameCommon.gameConfig.bJiaPiao ~= 0 then
                for i = 1, GameCommon.gameConfig.bPlayerCount do
                    GameCommon.player[i-1].mPiaoCount = pBuffer.mPiaoCount[i]
                    GameCommon.player[i-1].mPiaoUser = pBuffer.mPiaoUser[i]
                end
                self:updatePlayerPiaoFen()
            end
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK) end)))
            
        elseif subCmdID == NetMsgId.SUB_S_GAME_END_TIPS_MAJIANG then       --游戏胡牌提示
        
        else 
            return print("error, not found this :",mainCmdID, subCmdID)
        end

    elseif mainCmdID == NetMsgId.MDM_GF_FRAME then
        if subCmdID == NetMsgId.SUB_GF_SCENE then
            --游戏重连
            self.tableLayer:updateGameState(GameCommon.GameState_Start)
            local wChairID = GameCommon:getRoleChairID()
            GameCommon.wBankerUser = pBuffer.wBankerUser
            GameCommon.waitOutCardUser = pBuffer.wCurrentUser
            if GameCommon.waitOutCardUser == GameCommon:getRoleChairID() and  pBuffer.cbActionMask == 0 then 
                GameCommon.mBaoTingCard = {}         --与报听有关  暂时注释
                for i = 1, 14 do
                    if pBuffer.cbBTCard[i] ~= nil and pBuffer.cbBTCard[i] ~= 0 then
                        GameCommon.mBaoTingCard[i] = pBuffer.cbBTCard[i]
                    end
                end       --pBuffer.mBTHuCard[i][j]
                -- GameCommon.mHuCard = {}
                -- for i = 1, 27 do   
                --     if pBuffer.mAloneBaoTingCardEx[i]~= nil and pBuffer.mAloneBaoTingCardEx[i] ~= 0 then 
                --         GameCommon.mHuCard[i] = pBuffer.mAloneBaoTingCardEx[i]  
                --     end              
                -- end
            elseif GameCommon.waitOutCardUser ~= GameCommon:getRoleChairID() and  pBuffer.cbActionMask == 0 then 
                --if pBuffer.mAloneBaoTingCardEx ~= nil and  pBuffer.mAloneBaoTingCardEx[1] ~= 0 then 
                if  pBuffer.mBTHuCard~= {} and pBuffer.mBTHuCard[1] ~={} and pBuffer.mBTHuCard[1][1] ~= 0 then 
                    -- GameCommon.mHuCard = {}
                    -- for i = 1, 27 do
                    --     if pBuffer.mBTHuCard[1][i]~= nil and pBuffer.mBTHuCard[1][i] ~= 0 then 
                    --         GameCommon.mHuCard[i] = pBuffer.mBTHuCard[1][i]  
                    --     end              
                    -- end
                    local uiButton_chakan = ccui.Helper:seekWidgetByName(self.root,"Button_chakan")  
                    uiButton_chakan:setVisible(true)  
                end
            end
            --设置数据
            for i=1,GameCommon.gameConfig.bPlayerCount do
                GameCommon.player[i-1].gangFen =  GameCommon.player[i-1].lScore -- pBuffer.mGangScore[i] --杠分
                GameCommon.wPiaoCount[i-1] = pBuffer.mJiaoPiaoCount[i]
                GameCommon.wPiaoTF[i-1] =  pBuffer.bJiaoPiaoUser[i]
                self:updatePlayerPiaoFen()
            end
            GameCommon.waitOutCardUser = pBuffer.wCurrentUser
            if pBuffer.wDiceCardOne ~= 0 or pBuffer.wDiceCard[1] ~= 0 then
                GameCommon.waitOutCardUser = nil
            end
            GameCommon.cbLeftCardCount = pBuffer.cbLeftCardCount
            for i = 1, GameCommon.gameConfig.bPlayerCount do
                self.tableLayer:setDiscardCard(i-1, pBuffer.cbDiscardCount[i], pBuffer.cbDiscardCard[i])
                self.tableLayer:setWeaveItemArray(i-1, pBuffer.cbWeaveCount[i], pBuffer.WeaveItemArray[i])
                GameCommon.player[i-1].cbCardCount = pBuffer.cbCardCount[i]
                if i-1 == wChairID then
                    self.tableLayer:setHandCard(i-1,GameCommon.player[i-1].cbCardCount, pBuffer.cbCardData)
                else
                    self.tableLayer:setHandCard(i-1,GameCommon.player[i-1].cbCardCount, {})
                end
                              
                self.tableLayer:showHandCard({wChairID = i-1})
            end
	    
	    -------------------
            ---------报停相关
            -- if GameCommon.mHuCard ~= nil and GameCommon.mHuCard[1]~= 0 then
            --    self.tableLayer:huCardShow(1)
            if  pBuffer.mBTHuCard~= {} and pBuffer.mBTHuCard[1] ~={} and pBuffer.mBTHuCard[1][1] ~= 0 then 
                -- self.tableLayer:BaoTingCardShow({cbBTCard = pBuffer.cbBTCard,mBTHuCard = pBuffer.mBTHuCard})
 
                 self.tableLayer:doAction(NetMsgId.SUB_S_BAOTINGOUTCARD,pBuffer)
             end  
            ------------------
            
            if pBuffer.wDiceCardOne ~= 0 or pBuffer.wDiceCard[1] ~= 0  then
                self.tableLayer:doAction(NetMsgId.SUB_S_CASTDICE_RESULT, {wCurrentUser = pBuffer.wCurrentUser, wDiceCount = 0,wDiceCard= pBuffer.wDiceCard})

            elseif pBuffer.wDiceCardOne ~= 0 then
                self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_RESULT, {wOutCardUser = pBuffer.wCurrentUser, cbOutCardData = pBuffer.wDiceCardOne, isNoDelete = true})
                
            else
                if pBuffer.wCurrentUser == 65535 and pBuffer.wOutCardUser < GameCommon.gameConfig.bPlayerCount and pBuffer.cbOutCardData ~= 0 then
                    self.tableLayer:showCountDown(pBuffer.wOutCardUser)
                    self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_RESULT, {wOutCardUser = pBuffer.wOutCardUser, cbOutCardData = pBuffer.cbOutCardData, isNoDelete = true})
                elseif pBuffer.wCurrentUser ~= 65535 then
                    self.tableLayer:doAction(NetMsgId.SUB_S_OUT_CARD_NOTIFY_MAJIANG, {wOutCardUser = pBuffer.wCurrentUser})
                end
                if pBuffer.wActionUser ~= 65535 and pBuffer.cbUserAction > 0 then
                    self.tableLayer:doAction(NetMsgId.SUB_S_SpecialCard,{wActionUser = wChairID, cbUserAction = pBuffer.cbUserAction, cbCardData = pBuffer.cbSpecialCardData})
                end
            end
            if pBuffer.cbActionMask ~= 0 then
                if pBuffer.wOutCardUser == GameCommon:getRoleChairID() or pBuffer.wOutCardUser == 65535 then
                    self.tableLayer:doAction(NetMsgId.SUB_S_OPERATE_NOTIFY_MAJIANG,{wResumeUser = 0,cbActionMask = pBuffer.cbActionMask, 
                        cbActionCard = pBuffer.cbActionCard,bIsSelf = true,cbGangCard = pBuffer.cbGangCard,cbBuCard = pBuffer.cbBuCard})
                else
                    self.tableLayer:doAction(NetMsgId.SUB_S_OPERATE_NOTIFY_MAJIANG,{wResumeUser = 0,cbActionMask = pBuffer.cbActionMask, 
                        cbActionCard = pBuffer.cbActionCard,bIsSelf = false,cbGangCard = pBuffer.cbGangCard,cbBuCard = pBuffer.cbBuCard})
                end   
            end               
            if pBuffer.mcbGangItemCount ~= 0 then 
                GameCommon.waitGangCardUser = pBuffer.wCurrentUser 
                pBuffer.wResumeUser = 0
                self.tableLayer:DataClient(pBuffer)    --相关数据客户端整理运行
            end  
            if pBuffer.wHaiDiUser <= GameCommon.gameConfig.bPlayerCount then
                self.tableLayer:doAction(NetMsgId.SUB_S_OPERATE_HAIDI, {wCurrentUser = pBuffer.wHaiDiUser, false})
            end
--            if GameCommon.mHuCard ~= nil and GameCommon.mHuCard[1]~= 0 then
--                self.tableLayer:huCardShow(1)
--            end  
            self:updateBankerUser()
            self:updatePlayerInfo()
            self:updatehandplate()
            self.tableLayer:updateLeftCardCount(pBuffer.cbLeftCardCount)
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
    if cbCardData == 0x31 then
        return
    end

    if GameCommon.IsOfHu == 1 then  --如果是胡牌
        require("common.MsgBoxLayer"):create(1,nil,"是否放弃胡牌？",function()  
            if GameCommon.iNOoutcard == true then --当前是明牌
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)
            end
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OUT_CARD,"b",cbCardData)
            GameCommon.waitOutCardUser = GameCommon.INVALID_CHAIR
            self.tableLayer:showHandCard({wChairID = wChairID, cbOutCard = cbCardData})
            self.tableLayer:simulationDiscardCard(wChairID, cbCardData)
        end)  
    else
        if GameCommon.iNOoutcard == true then --当前是明牌
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OPERATE_CARD,"wb",GameCommon.WIK_NULL,0)
        end
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OUT_CARD,"b",cbCardData)
        GameCommon.waitOutCardUser = GameCommon.INVALID_CHAIR
        self.tableLayer:showHandCard({wChairID = wChairID, cbOutCard = cbCardData})
        self.tableLayer:simulationDiscardCard(wChairID, cbCardData)
    end

    --NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_OUT_CARD,"b",cbCardData)
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
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i - 1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        uiPanel_player:setVisible(true)
        
        if GameCommon.player == nil or GameCommon.player[wChairID] == nil then
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            uiPanel_playerInfo:setVisible(false)
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            uiImage_avatar:loadTexture("common/hall_avatar.png")
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
        end
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
        if GameCommon.player[wChairID].cbCardCount <= 3 then
            uiText_Houdplate:setTextColor(cc.c3b(255,40,40))              
        else
            uiText_Houdplate:setTextColor(cc.c3b(255,223,113))   
        end
        uiText_Houdplate:setVisible(false)
        uiText_Houdplate:setString(string.format("%d张",GameCommon.player[wChairID].cbCardCount))
    end
end

function GameLayer:updateBankerUser()
    for i = 1 , GameCommon.gameConfig.bPlayerCount do
        local wChairID = i-1
        local viewID = GameCommon:getViewIDByChairID(wChairID)
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
        local uiImage_banker = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_banker")
        if GameCommon.player[wChairID] ~= nil and GameCommon.player[wChairID].wChairID == GameCommon.wBankerUser then
            uiImage_banker:loadTexture("majiang/table/n_play_label04.png")
            local texture = cc.TextureCache:getInstance():addImage("majiang/table/n_play_label04.png")
            uiImage_banker:setContentSize(texture:getContentSizeInPixels())
            uiImage_banker:setVisible(true)
        else
            uiImage_banker:setVisible(false)
        end 
    end
end

function GameLayer:updateBtnState( )

    local players =  GameCommon.player
    local count = 0
    for _,v in pairs(players) do
        count = count + 1
    end

    local isAll = (count == GameCommon.gameConfig.bPlayerCount) --满员了
    
    if isAll then
        local uiButton_Invitation = ccui.Helper:seekWidgetByName(self.root,"Button_Invitation")
        uiButton_Invitation:setVisible(false)
    end

    --距离报警 
    if count == GameCommon.gameConfig.bPlayerCount and GameCommon.DistanceAlarm ~= 1 then
        if StaticData.Hide[CHANNEL_ID].btn16 ==1 then 
            GameCommon.DistanceAlarm = 1 
            if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
                if GameCommon.gameConfig.bPlayerCount ~= 2 then 
                    --require("common.DistanceAlarm"):create(GameCommon)
                    local tips = require("game.majiang.DistanceTip")
                    tips:checkDis(true)
                end  
            end 
        end
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
                uiButton_ready:setVisible(false)
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

            self:userInfoState(wChairID,true)
        end     
    end
end

function GameLayer:openDimissTable( params )
    local path = self:requireClass('KwxDisMissTable')
    local box = require("app.MyApp"):create(params):createGame(path)
    box:setName('kwxisMissTable')
    self:addChild(box,100)
    
    require("common.SceneMgr"):switchOperation(nil)
end

function GameLayer:requireClass( name )
    local path = string.format("game.%s.%s", APPNAME, name)
	return path
end

function GameLayer:checkWhoRefuse( data )
    if not data then
        return
    end
    local isHaveRefuse = false
    for i=1,3 do
        if data.dwUserIDALL[i] ~= 0 then
			if data.cbDisbandeState[i] == 2 then --拒绝
                local config = {
                    content = data.szNickNameALL[i] .. '不同意解散房间',
                    button2 = {'确定'}
                }
                --self:openBox(config) 
                isHaveRefuse = true
			end
		end
    end
    return isHaveRefuse
end

function GameLayer:openBox( params )
    local path = self:requireClass('HYNoticeBox')
    local box = require("app.MyApp"):create(params):createGame(path)
    require("common.SceneMgr"):switchTips(box)
end


function GameLayer:resetPiaoFen()
    if GameCommon.tableConfig then
        print('->>>>>>>>>>>>>>xxx',GameCommon.tableConfig.wCurrentNumber)
        if GameCommon.tableConfig.wCurrentNumber == 0 then
            GameCommon.wPiaoTF = {}
            GameCommon.wPiaoCount = {}
            print('------------>>>>>>清除数据');
        end
    end
    
end

function GameLayer:updatePlayerPiaoFen()
    if GameCommon.gameConfig == nil then
        return
   end


   local isAddPiao = false

   local uiPanel_piaoFen = ccui.Helper:seekWidgetByName(self.root,"Panel_piaoFen")
   uiPanel_piaoFen:setVisible(false)
   if GameCommon.gameConfig  then
       local jiaPiao = GameCommon.gameConfig.bJiaPiao
       print('--->>>>>x',jiaPiao)
       local wChairID = GameCommon:getRoleChairID()
       local isPiao =  GameCommon.wPiaoTF[wChairID]
       if jiaPiao == 0 then --关闭
           uiPanel_piaoFen:setVisible(false)
       elseif jiaPiao == 1 then --固定漂1 
           isAddPiao = false;
       elseif jiaPiao == 2 then --改成固定漂2
           isAddPiao = false
       elseif jiaPiao == 3 then -- 选一次漂
           print('-.isPiao>>>>>',isPiao)
           print('-.wCurrentNumber>>>>>',GameCommon.tableConfig.wCurrentNumber)
           if isPiao  then
               uiPanel_piaoFen:setVisible(false)
           else
               uiPanel_piaoFen:setVisible(true)
               isAddPiao = true
           end
       elseif jiaPiao == 4 then -- 每小局选票
           print('-.ss>>>>>',GameCommon.tableConfig.wCurrentNumber,count,isPiao)
           if not isPiao then
               uiPanel_piaoFen:setVisible(true)
               isAddPiao = true
           else
               uiPanel_piaoFen:setVisible(false)
           end
       end
   end

   if isAddPiao then
       self.tableLayer:addClickItem()
   end


    for i = 1 , GameCommon.gameConfig.bPlayerCount do
       local wChairID = i-1
       if GameCommon.player ~= nil and GameCommon.player[wChairID] ~= nil  then
           local viewID = GameCommon:getViewIDByChairID(wChairID)
           local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
           local uiImage_piao = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_piao")
           uiImage_piao:setVisible(false)

           local bJiaPiaoCount = GameCommon.gameConfig.bJiaPiaoCount
           local jiaPiao = GameCommon.gameConfig.bJiaPiao
           if jiaPiao == 1 or jiaPiao == 2 then
               GameCommon.wPiaoTF[wChairID] = true
               GameCommon.wPiaoCount[wChairID] = jiaPiao
           end
           print('--->>xx>>>x',jiaPiao,bJiaPiaoCount)
           print('xxxxxxxxxxxxx',GameCommon.wPiaoTF[wChairID],GameCommon.wPiaoCount[wChairID])
           if jiaPiao == 0 then
               uiImage_piao:setVisible(false)
           else
               if GameCommon.wPiaoTF[wChairID] == true then
                   if GameCommon.wPiaoCount[wChairID] == 0 then
                       uiImage_piao:loadTexture("game/mj_piaofen_1.png")
                       uiImage_piao:setVisible(true)
                   elseif GameCommon.wPiaoCount[wChairID] == 1 then
                       uiImage_piao:loadTexture("game/pukenew_score_1.png")
                       uiImage_piao:setVisible(true)
                   elseif GameCommon.wPiaoCount[wChairID] == 2 then
                       uiImage_piao:loadTexture("game/pukenew_score_2.png")
                       uiImage_piao:setVisible(true)
                   elseif GameCommon.wPiaoCount[wChairID] == 3 then
                       uiImage_piao:loadTexture("game/pukenew_score_3.png")
                       uiImage_piao:setVisible(true)
                   else
                       uiImage_piao:setVisible(false)
                   end
               end  
           end
       end
    end
end




--isInGame 是否在游戏里面
function GameLayer:userInfoState( wChairID,isInGame )
    local viewID = GameCommon:getViewIDByChairID(wChairID)
    local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    if viewID == 1 then
        return
    end
    if uiPanel_player then
        local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame_defout")

        uiPanel_playerInfo:setVisible(not isInGame)
    
        local Image_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
        Image_avatar:setVisible(isInGame)
    
        local Image_avatarFrame = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatarFrame")
        Image_avatarFrame:setVisible(isInGame)
    end
end



return GameLayer


