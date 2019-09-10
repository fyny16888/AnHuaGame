local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Common = require("common.Common")
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local Default = require("common.Default")
local LocationSystem = require("common.LocationSystem")

local GameCommon = 
{
    GameState_Init = 0,
    GameState_Start = 1,
    GameState_Over = 2,
    gameState = 0,
    
    EARTH_RADIUS = 6371.004 ,                     --地球半径  
        
    MAX_COUNT = 15,
    CardType_error          = 0,    --错误牌型
    CardType_single         = 1,    --单牌
    CardType_pair           = 2,    --对子
    CardType_straight       = 3,    --顺子
    CardType_straightPair   = 4,    --连对 
    CardType_3Add2          = 5,    --三带二
    CardType_airplane       = 6,    --飞机
    CardType_4Add3          = 7,    --四带三
    CardType_bomb           = 8,    --炸弹
        
    dwUserID = 0,
    wBankerUser = 0,
    palyer = nil,
    serverData = nil,
    gameConfig = nil,
    playbackData = nil,
    meChairID = 0,
    
    --双十类型
    NiuType_NULL = 0,       --散牌
    NiuType_1 = 1,          --1
    NiuType_2 = 2,          --2
    NiuType_3 = 3,          --3
    NiuType_4 = 4,          --4
    NiuType_5 = 5,          --5
    NiuType_6 = 6,          --6
    NiuType_7 = 7,          --7
    NiuType_8 = 8,          --8
    NiuType_9 = 9,          --9
    NiuType_Niu = 10,       --双十
    NiuType_Silver = 20,    --银花
    NiuType_Gold = 30,      --金花
    NiuType_Gourd = 40,     --葫芦
    NiuType_Bomb = 50,      --炸弹
    NiuType_Niu5 = 60,      --五小
    NiuType_Flush = 70,     --同花顺
    
    --三公类型
    SanType_NULL = 0,       --无点
    SanType_1 = 1,          --1点
    SanType_2 = 2,          --2点
    SanType_3 = 3,          --3点
    SanType_4 = 4,          --4点
    SanType_5 = 5,          --5点
    SanType_6 = 6,          --6点
    SanType_7 = 7,          --7点
    SanType_8 = 8,          --8点
    SanType_9 = 9,          --9点
    SanType_Mix = 10,       --混三公
    SanType_Large = 20,     --小三公
    SanType_Small = 30,     --大三公   
    NiuType_ZZSG   = 40,    --至尊三公   
    
    DistanceAlarm = 1 ,                 -- 距离判断（0：没有判断多，需要判断。1：判断过或不需要判断）
}

function GameCommon:init()
    self.gameState = 0
end

function GameCommon:getViewIDByChairID(wChairID)
    local location = 1          --主角位置
    local wPlayerCount = self.gameConfig.bPlayerCount      --玩家人数
    local meChairID = self:getRoleChairID()     --主角的座位号
    local viewID = (wChairID + wPlayerCount - meChairID)%wPlayerCount+1
    return viewID
end

function GameCommon:getRoleChairID()
    return self.meChairID
end

function GameCommon:ContinueGame(cbLevel)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SET_POSITION,"aad",LocationSystem.pos.x, LocationSystem.pos.y, GameCommon.dwUserID)
    if GameCommon.tableConfig.nTableType == TableType_FriendRoom or GameCommon.tableConfig.nTableType == TableType_ClubRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_NEXT_GAME,"")
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_READY,"")
    elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_CONTINUE_GAME,"b",cbLevel)
    elseif GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_CONTINUE_REDENVELOPE,"b",cbLevel)
    end
end

function GameCommon:GetReward(cbLevel)
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GET_REDENVELOPE_REWARD,"b",cbLevel)
end 

function GameCommon:getUserInfo(charID)
    for key, var in pairs(self.player) do
        if var.wChairID == charID then
            return clone(var)
        end
    end
    local var = {}
    var.cbSex = 0
    return var
end

function GameCommon:getUserInfoByUserID(dwUserID)
    for key, var in pairs(self.player) do
        if var.dwUserID == dwUserID then
            return var
        end
    end
    return nil
end

function GameCommon:rad(d)
    return d* math.pi / 180.0;
end 

function GameCommon:GetDistance(lat1,lat2)
    local radLat1 = self:rad(lat1.x)
    local radLat2 = self:rad(lat2.x)
    local a = radLat1 - radLat2
    local b = self:rad(lat1.y) - self:rad(lat2.y)
    local s = 2 * math.asin(math.sqrt(math.pow(math.sin(a/2),2) +math.cos(radLat1)*math.cos(radLat2)*math.pow(math.sin(b/2),2)))
    s = s * self.EARTH_RADIUS*1000
    --   s = math.round(s * 10000) / 10000  
    return s;
end 

--牌资源
function GameCommon:getCardNode(data)
 
    local cardIndex = cc.UserDefault:getInstance():getIntegerForKey('PDKSize',0) 
    
    local cardBgIndex = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_PukeCardBg,0)
 
    if data == 0 or data == nil then
        if cardBgIndex == 0 then 
            return ccui.ImageView:create("puke/table/puke_bg0.png")
        elseif cardBgIndex == 1 then 
            return ccui.ImageView:create("puke/table/puke_bg1.png")
        elseif cardBgIndex == 2 then 
            return ccui.ImageView:create("puke/table/puke_bg2.png")
        end 
    end
    local value = Bit:_and(data,0x0F)
    local color = Bit:_rshift(Bit:_and(data,0xF0),4)    
    local card = nil
    -- if cardIndex ~= 1 then
        card = ccui.ImageView:create(string.format("puke/card/card0/puke_%d_%d.png",color,value))
    -- else
    --     card = ccui.ImageView:create(string.format("puke/card/card1/puke_%d_%d.png",color,value))
    -- end
    return card
end

function GameCommon:playAnimation(root,id, wChairID)
    local Animation = nil
    if GameCommon.tableConfig.wKindID == 51 or GameCommon.tableConfig.wKindID == 55 or GameCommon.tableConfig.wKindID == 56 or GameCommon.tableConfig.wKindID == 57 or GameCommon.tableConfig.wKindID == 58 or GameCommon.tableConfig.wKindID == 59 then
        Animation = require("game.puke.AnimationNiu")
    elseif GameCommon.tableConfig.wKindID == 53 then
        Animation = require("game.puke.AnimationSan")
    else
        Animation = require("game.puke.Animation")
    end
    if Animation[id] == nil then
        return
    end
    local AnimationData = Animation[id][GameCommon.regionSound]
    if AnimationData == nil then
        return
    end
    if AnimationData.animFile ~= "" then
        if id == "报警" then
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_player = ccui.Helper:seekWidgetByName(root,string.format("Panel_player%d",viewID))
            local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
            local visibleSize = cc.Director:getInstance():getVisibleSize()
            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(AnimationData.animFile)
            local armature = ccs.Armature:create(AnimationData.animName)
            uiPanel_playerInfo:addChild(armature)
            armature:setPosition(cc.p(armature:getParent():convertToNodeSpace(cc.p(visibleSize.width/2,visibleSize.height/2))))
            local pt = cc.p(uiPanel_playerInfo:getContentSize().width + 0,uiPanel_playerInfo:getContentSize().height/2)
            if viewID == 2 then
                pt = cc.p(-0,uiPanel_playerInfo:getContentSize().height/2)
            end
            armature:setScale(1.5)
            armature:getAnimation():playWithIndex(0,-1,1)
            armature:runAction(cc.Spawn:create(
                cc.ScaleTo:create(0.5,0.5),
                cc.MoveTo:create(0.5,pt)
            ))
        else
            local visibleSize = cc.Director:getInstance():getVisibleSize()
            local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(root,"Panel_tipsCard")
            ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(AnimationData.animFile)
            local armature = ccs.Armature:create(AnimationData.animName)
            uiPanel_tipsCard:addChild(armature)
            armature:setScale(1.5)
            armature:getAnimation():playWithIndex(0,-1,0)
            if GameCommon.tableConfig.wKindID == 51 or GameCommon.tableConfig.wKindID == 53 or GameCommon.tableConfig.wKindID == 55 or GameCommon.tableConfig.wKindID == 56 or GameCommon.tableConfig.wKindID == 57 or GameCommon.tableConfig.wKindID == 58 or GameCommon.tableConfig.wKindID == 59 then
                armature:runAction(cc.Sequence:create(
                    cc.DelayTime:create(1.0),
                    cc.ScaleTo:create(0.2,0.8)))
            else
                armature:runAction(cc.Sequence:create(
                    cc.ScaleTo:create(0.1,1),
                    cc.DelayTime:create(1.0),
                    cc.FadeOut:create(0.5),
                    cc.RemoveSelf:create()))
            end
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_tipsCardPosUser = ccui.Helper:seekWidgetByName(root,string.format("Panel_tipsCardPos%d",viewID))
            armature:setPosition(uiPanel_tipsCardPosUser:getPosition())
        end

    end
    local soundFile = ""
    if wChairID ~= nil then
        soundFile = AnimationData.sound[GameCommon.player[wChairID].cbSex]
    else
        soundFile = AnimationData.sound[0]
    end
    if soundFile ~= "" then
        if id ~= "我先出" or wChairID == self:getRoleChairID()  then 
            require("common.Common"):playEffect(AnimationData.sound[GameCommon.player[wChairID].cbSex])
        end  
    end
    if (id == "我赢啦" or id == "赢")and( CHANNEL_ID == 6 or CHANNEL_ID == 7)  then 
        require("common.Common"):playEffect("common/win.mp3")
    end 
end

return GameCommon