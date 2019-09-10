local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameDesc = require("common.GameDesc")
local GameConfig = require("common.GameConfig")

local InterfaceCreateRoomNode = class("InterfaceCreateRoomNode", cc.load("mvc").ViewBase)

function InterfaceCreateRoomNode:onEnter()
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:registListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:registListener(EventType.SUB_GR_CREATE_TABLE_FAILED,self,self.SUB_GR_CREATE_TABLE_FAILED)
end

function InterfaceCreateRoomNode:onExit()
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER,self,self.SUB_CL_GAME_SERVER)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:unregistListener(EventType.SUB_GR_CREATE_TABLE_FAILED,self,self.SUB_GR_CREATE_TABLE_FAILED)
end

function InterfaceCreateRoomNode:onCreate(parameter)
    self.nTableType     = parameter[1]
    self.wTableSubType  = parameter[2]
    self.dwTargetID     = parameter[5]   
    if type(parameter[3]) == 'table' then
        self.wKindID        = parameter[3][1]
        self.wGameCount     = parameter[4][1]
        self.tableParameter = parameter[6][1]
    else
        self.wKindID        = parameter[3]
        self.wGameCount     = parameter[4]
        self.tableParameter = parameter[6]
    end

    NetMgr:getGameInstance():closeConnect()

    UserData.Game:sendMsgGetRoomInfo(self.wKindID, 2)
end

function InterfaceCreateRoomNode:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID,data),SCENE_GAME)
end

function InterfaceCreateRoomNode:SUB_GR_CREATE_TABLE_FAILED(event)
    self:removeFromParent()
    local errorID = event._usedata
    if errorID == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"房间配置错误!")
    elseif errorID == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"您的道具不足!")
    elseif errorID == 3 then
        require("common.MsgBoxLayer"):create(0,nil,"房间已满!")
    elseif errorID == 11 then
        require("common.MsgBoxLayer"):create(2,nil,"请先加入公会!")
    elseif errorID == 12 then
        require("common.MsgBoxLayer"):create(2,nil,"代理房卡不够不能创建!")
    elseif errorID == 13 then
        require("common.MsgBoxLayer"):create(2,nil,"未授权代开权限,请联系代理授权代开权限!")
    elseif errorID == 14 then
        require("common.MsgBoxLayer"):create(2,nil,"您已经达到代开房上限，不能再创建了!")
    elseif errorID == 15 then
        require("common.MsgBoxLayer"):create(2,nil,"该亲友圈不存在!",function()
            require("common.SceneMgr"):switchOperation()
            cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
        end)
    elseif errorID == 16 then
        require("common.MsgBoxLayer"):create(2,nil,"您已经不在该亲友圈了!")
    elseif errorID == 17 then
        require("common.MsgBoxLayer"):create(2,nil,"该亲友圈未设置玩法!")
    elseif errorID == 18 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈群主房卡不够不能创建!")
    elseif errorID == 19 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈房卡不够不能创建!")
    elseif errorID == 20 then
        require("common.MsgBoxLayer"):create(2,nil,"您已被群主暂停娱乐,请联系群主恢复!")
    elseif errorID == 21 then
        require("common.MsgBoxLayer"):create(2,nil,"您的疲劳值不够,请联系群主!")
    elseif errorID == 22 then
        require("common.MsgBoxLayer"):create(2,nil,"防沉迷配置错误,请联系群主重新设置!")
    elseif errorID == 23 then
        require("common.MsgBoxLayer"):create(2,nil,"亲友圈玩法不存在,请重新刷新亲友圈!")
    else
        require("common.MsgBoxLayer"):create(2,nil,"请升级您的版本!")
    end
    NetMgr:getGameInstance():closeConnect()
end

function InterfaceCreateRoomNode:SUB_GR_LOGON_SUCCESS(event)
    if self.wKindID == 15 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount)

    elseif self.wKindID == 25 or self.wKindID == 26 or self.wKindID == 76 or self.wKindID == 77  then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount, self.tableParameter.bStartCard,self.tableParameter.bBombSeparation,self.tableParameter.bRed10,
            self.tableParameter.b4Add3,self.tableParameter.bShowCardCount,self.tableParameter.bSpringMinCount,self.tableParameter.bAbandon,
            self.tableParameter.bCheating,self.tableParameter.bFalseSpring,self.tableParameter.bAutoOutCard)
    elseif self.wKindID == 44 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bPaoTips,self.tableParameter.bStartBanker,self.tableParameter.bDeathCard)

    elseif self.wKindID == 60 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bStartBanker,self.tableParameter.bDeathCard)  
    elseif self.wKindID == 83   then
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbbbbbbb",
                CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
                self.tableParameter.bPlayerCount, self.tableParameter.bStartCard,self.tableParameter.bBombSeparation,self.tableParameter.bRed10,
                self.tableParameter.b4Add3,self.tableParameter.bShowCardCount,self.tableParameter.bSpringMinCount,self.tableParameter.bAbandon,
                self.tableParameter.bCheating,self.tableParameter.bFalseSpring,self.tableParameter.bAutoOutCard,self.tableParameter.bThreeBomb,
                self.tableParameter.b15Or16,self.tableParameter.bMustOutCard,self.tableParameter.bMustNextWarn,self.tableParameter.bJiaPiao,
                self.tableParameter.bThreeEx)
    elseif self.wKindID == 84   then
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbb",
                CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
                self.tableParameter.bPlayerCount,self.tableParameter.bShowCardCount,self.tableParameter.bCheating,self.tableParameter.bPlayWayType,
                self.tableParameter.bShoutBankerType,self.tableParameter.bBombMaxNum,self.tableParameter.bBankerWayType)
    elseif self.wKindID == 78 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,self.tableParameter.bPlayerCount,  
            self.tableParameter.mLaiZiCount, self.tableParameter.bJiePao,self.tableParameter.bQiDui, self.tableParameter.bQGHu, 
            self.tableParameter.bQGHuBaoPei, self.tableParameter.bJiaPiao, self.tableParameter.bMaType, self.tableParameter.bMaCount, self.tableParameter.mNiaoType, 
            self.tableParameter.mHongNiao, self.tableParameter.bWuTong)  
    elseif self.wKindID == 79 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,self.tableParameter.bPlayerCount,  
            self.tableParameter.mLaiZiCount,self.tableParameter.bJiePao, self.tableParameter.bQiDui, self.tableParameter.bQGHuBaoPei, self.tableParameter.bJiaPiao, 
            self.tableParameter.bMaType, self.tableParameter.bMaCount, self.tableParameter.mNiaoType,self.tableParameter.mHongNiao,self.tableParameter.bZhuangXian,
            self.tableParameter.bWuTong) 
    elseif self.wKindID == 80 then 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,self.tableParameter.bPlayerCount,  
            self.tableParameter.mZXFlag, self.tableParameter.bBBGFlag, self.tableParameter.bSTFlag, self.tableParameter.bXHBJPFlag, 
            self.tableParameter.bYZHFlag, self.tableParameter.mZTSXlag, self.tableParameter.mJTYNFlag, self.tableParameter.mZTLLSFlag, self.tableParameter.bMQFlag, 
            self.tableParameter.bJJHFlag, self.tableParameter.bLLSFlag, self.tableParameter.bQYSFlag, self.tableParameter.bWJHFlag, self.tableParameter.bDSXFlag,
            self.tableParameter.bJiaPiao,self.tableParameter.bMaType,self.tableParameter.bMaCount,self.tableParameter.mNiaoType,self.tableParameter.mKGNPFlag,
            self.tableParameter.bWuTong)  
    elseif self.wKindID == 81 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,self.tableParameter.bPlayerCount,  
            self.tableParameter.mLaiZiCount,self.tableParameter.bJiePao, self.tableParameter.bQiDui, self.tableParameter.bQGHuBaoPei, self.tableParameter.bJiaPiao, 
            self.tableParameter.bMaType, self.tableParameter.bMaCount, self.tableParameter.mNiaoType,self.tableParameter.mHongNiao,self.tableParameter.bZhuangXian,
            self.tableParameter.bWuTong) 
    elseif self.wKindID == 82 then 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbbbbbbbbbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,self.tableParameter.bPlayerCount,  
            self.tableParameter.mBanBanHu, self.tableParameter.mJiangJiangHu, self.tableParameter.bQiDui, self.tableParameter.bHaoHuaQiDui, 
            self.tableParameter.bGangShangPao, self.tableParameter.bGangShangHua, self.tableParameter.bQingYiSe, self.tableParameter.bPPHu, self.tableParameter.bHuangZhuangHG, 
            self.tableParameter.bSiHZHu, self.tableParameter.bQGHu, self.tableParameter.bJiePao, self.tableParameter.mLaiZiCount, self.tableParameter.bJiaPiao,
            self.tableParameter.bMaType,self.tableParameter.bMaCount,self.tableParameter.mNiaoType,self.tableParameter.mHongNiao,self.tableParameter.bWuTong)  
    elseif self.wKindID == 85 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbooooooo",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount, self.tableParameter.bShowCardCount, self.tableParameter.bCheating,self.tableParameter.bPlayWayType,
            self.tableParameter.bSettleType,self.tableParameter.bSurrenderStage,self.tableParameter.bRemoveKingCard,self.tableParameter.bRemoveSixCard,
            self.tableParameter.bPaiFei,self.tableParameter.bDaDaoEnd,self.tableParameter.bNoTXPlease, self.tableParameter.bNoLookCard, self.tableParameter.b35Down)
    elseif self.wKindID == 89 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbbbwbbbbbbbbdbbbbbbb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.FanXing.bType,self.tableParameter.FanXing.bCount,self.tableParameter.FanXing.bAddTun,
            self.tableParameter.bPlayerCountType,self.tableParameter.bPlayerCount,self.tableParameter.bLaiZiCount,self.tableParameter.bMaxLost,
            self.tableParameter.bYiWuShi,self.tableParameter.bLiangPai,self.tableParameter.bCanHuXi,self.tableParameter.bHuType,
            self.tableParameter.bFangPao,self.tableParameter.bSettlement,self.tableParameter.bStartTun,self.tableParameter.bSocreType,
            self.tableParameter.dwMingTang,self.tableParameter.bTurn,self.tableParameter.bPaoTips,self.tableParameter.bStartBanker,
            self.tableParameter.bDeathCard,self.tableParameter.bMingType,self.tableParameter.bMingWei,self.tableParameter.b3Long5Kan)  

    elseif self.wKindID == 88 then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_CREATE_TABLE,"diwwwwdbbbbdb",
            CHANNEL_ID,self.nTableType,self.wTableSubType,self.wKindID,self.wGameCount,1,self.dwTargetID,
            self.tableParameter.bPlayerCount,self.tableParameter.bDeathCard,self.tableParameter.bZhuangFen,
            self.tableParameter.bChongFen,self.tableParameter.dwMingTang,self.tableParameter.bChiNoPeng)  
    else
    end
end

function InterfaceCreateRoomNode:SUB_CL_GAME_SERVER_ERROR(event)
    local data = event._usedata
    self:removeFromParent() 
    require("common.MsgBoxLayer"):create(0,nil,"创建房间失败！")  
    
end

function InterfaceCreateRoomNode:SUB_CL_GAME_SERVER(event)
	local data = event._usedata
    UserData.Game:sendMsgConnectGame(data)
end

function InterfaceCreateRoomNode:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    local data = event._usedata
    self:removeFromParent()
    require("common.MsgBoxLayer"):create(0,nil,"连接游戏失败,请查看您的网络状态！")
end
return InterfaceCreateRoomNode