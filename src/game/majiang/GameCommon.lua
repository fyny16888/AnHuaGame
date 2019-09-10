local Common = require("common.Common")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local Bit = require("common.Bit")
local Default = require("common.Default")
local LocationSystem = require("common.LocationSystem")

local GameCommon = {
    -------------------------------------------------------------------------------
    --宏定义
    
    --麻将动作定义
    WIK_NULL = 0x00,                         --没有类型
    WIK_LEFT = 0x01,                         --左吃类型
    WIK_CENTER = 0x02,                       --中吃类型
    WIK_RIGHT = 0x04,                        --右吃类型
    WIK_PENG = 0x08,                         --碰牌类型
    WIK_FILL = 0x10,                         --补牌类型
    WIK_GANG = 0x20,                         --杠牌类型
    WIK_CHI_HU = 0x40,                       --吃胡类型
    WIK_HAIDI = 0x80,                        --海底类型
    WIK_BIHU  =0x200,                        --必胡

    WIK_MING_PAI = 0x80,                        --明牌类型
    --麻将胡牌定义
    
    --非胡类型
    CHK_NULL = 0x0000,                       --非胡类型

    --王闯王钓定义
    WIK_WD = 0x01,                          --王钓
    WIK_WC = 0x02,                          --王闯
    cbOperateCode = 0 ,                     --最高胜分（王钓王闯）
    --小胡类型
    CHK_PING_HU = 0x0001,                    --平胡类型
    CHK_SIXI_HU = 0x0002,                    --四喜胡牌
    CHK_BANBAN_HU = 0x0004,                  --无将胡牌
    CHK_LIULIU_HU = 0x0008,                  --六六顺牌
    CHK_QUEYISE_HU = 0x0010,                 --缺一色牌
    CHK_BUBUGAO_HU = 0x0020,                 --步步高牌
    CHK_SANTONG_HU = 0x0040,                 --三同牌
    CHK_YIZHIHUA_HU = 0x0080,                --一枝花牌
    CHK_ZTSX_HU = 0x0100,                    --中途四喜
    CHK_ZTLLS_HU = 0x0200,                   --中途六六顺
    CHK_JTYN_HU	= 0x0400,					 --金童玉女

    --大胡类型
    CHK_PENG_PENG = 0x0002,                  --碰碰胡
    CHK_JIANG_JIANG = 0x0004,                --将将胡
    CHR_QING_YI_SE = 0x0008,                 --清一色   (王钓麻将 清水胡)
    CHR_QUAN_QIU_REN = 0x0010,               --全求人   (王钓麻将 清一色)
    CHR_HAIDI = 0x0020,                      --海底胡				--权位
    CHK_QI_XIAO_DUI = 0x0040,                --七小对
    CHK_QI_XIAO_DUI_HAO = 0x0080,            --豪华七小对
    CHR_GANG = 0x0100,                       --杠上开花			--权位
    CHR_GANG_SHUANG = 0x0200,                --长沙：双杠上花  益阳：报听胡          --权位
    CHK_QI_XIAO_DUI_HAO_SHUANG = 0x0400,            --双豪华七小对   
    CHK_QI_XIAO_DUI_HAO_CHAO = 0x0800,            --超豪华七小队   
    CHR_QIANG_GANG_HU = 0x1000,               --抢杠胡
    CHR_MENQING_HU = 0x2000,                  --门清 


    --操作字节 

    WIK_CHI_HU_EX =	0x80,					--杠上开花类型
    ------------------------
    ---卡五星结算胡公共字节---
    ------------------------
    --非胡类型
    KWX_CHK_NULL=		 0x0000,								--非胡类型
    --胡类型
    KWX_CHK_PING_HU	=		0x0001,								    --平胡类型(卡五星)
    KWX_CHK_PENG_PENG	=		0x0002,								--碰碰胡(卡五星)
    KWX_CHK_QI_XIAO_DUI	=		0x0004,								--七小对(卡五星)
    KWX_CHK_QI_XIAO_HAO	=		0x0008,								--豪华七小对(卡五星)
    KWX_CHK_QI_XIAO_HAO_CHAO=	0x0010,								--超豪华七小对(卡五星)
    KWX_CHK_QI_XIAO_HAO_CHAO_D=	0x0020,								--超超豪华七小对(卡五星)
    

    --胡名堂
    KWX_CHR_KA_WU_XING	=		0x0001,								--卡五星(卡五星）
    KWX_CHR_XIAO_SAN_YUAN=	0x0002,								    --小三元(卡五星）
    KWX_CHR_DA_SAN_YUAN	=	0x0004,								    --大三元(卡五星）
    KWX_CHR_QING_YI_SE	=		0x0008,								--清一色(卡五星)
    KWX_CHR_QUAN_QIU_REN=	0x0010,							        --全求人__手抓一(卡五星)
    KWX_CHR_MING_SI_GUI	=		0x0020,								--明四归(卡五星)
    KWX_CHR_AN_SI_GUI=		0x0040,								    --暗四归(卡五星)
    KWX_CHR_GANG_KAI=	0x0080,								        --杠开(卡五星)--自己摸牌胡（1杠2番、2杠4番、3杠8番、4杠16番）
    KWX_CHR_GANG_SHANG_GANG=0x0100,								    --杠上杠(卡五星)
    KWX_CHR_GANG_SHANG_PAO=	0x0200,								    --杠上炮(卡五星)
    KWX_CHR_GANG_MING=	0x0400,								        --明牌(卡五星)
    CHR_HAIDILAO =				0x0800,								--海底捞
    CHR_HAIDIPAO =				0x1000,								--海底炮
    CHR_BAOHU =					0x2000,								--包胡
    CHR_QIANG_GANG_HU  =		0x4000,								--抢杠胡


    --动作定义
--    ACK_NULL                    =0,                                --空
--    ACK_TI                      =1,                                --提
--    ACK_PAO                     =2 ,                               --跑
--    ACK_WEI                     =4,                                --偎
--    ACK_WD                      =8 ,                               --王钓
--    ACK_WC                      =16   ,                              --王闯
--    ACK_CHI                     =32   ,                             --吃
--    ACK_CHI_EX                  =64    ,                            --吃
--    ACK_PENG                    =128    ,                            --碰
--    ACK_CHIHU                   =256   ,                           --胡
--    ACK_BIHU				        =512,						    --必胡

    --吃牌类型
--    CK_NULL = 0,         --无效类型
--    CK_XXD = 1,          --小小大搭
--    CK_XDD = 2,          --小大大搭
--    CK_EQS = 4,          --二七十吃
--    CK_LEFT = 16,        --靠左对齐
--    CK_CENTER = 32,      --居中对齐
--    CK_RIGHT = 64,       --靠右对齐
--    CK_YWS	=128,		--一五十吃
    --数值定义
    MAX_WEAVE = 4,       --最大组合
    MAX_INDEX = 34,      --最大索引
    MAX_COUNT = 14,      --最大数目
    MAX_REPERTORY = 108,    --最大库存
    MASK_COLOR = 0xF0,    --花色掩码
    MASK_VALUE = 0x0F,     --数值掩码
    --主要用于桌面显示
--    ACK_CHOUWEI = 5,     --臭偎
    --牌间隔
    CARDHEIGH = 90,
    CARDWIDTH = 84,
    BASEPOSITIONY = 130,
    BASEPOSITIONX = 120,
--    CARD_HUXI_HEIGHT = 40,
--    CARD_HUXI_WIDTH = 40,
--    CARD_COM_HEIGHT = 226,
--    CARD_COM_WIDTH = 76,
    --游戏结束开始时间
--    Game_end_time = 25.0,
    
    GameView_updataHuxi = 1,        --跟新胡息
    GameView_updataHardCard = 2,    --跟新手牌
    GameView_showOutCardTips = 3,   --显示出牌提示
    GameView_closeOutCardTips = 4,  --关闭出牌提示
    GameView_BegainMsg = 5,         --开始处理消息
    GameView_endMsg = 6,            --处理完消息了
    GameView_UpOpration = 7,        --更新操作超时
    GameView_OutOpration = 8,       --操作超时
    GameView_SpecialStart = 9,
    GameView_SpecialOver = 10,
    GameView_UpdataUserScore = 11,  --跟新金币
    GameView_SortCardOver = 12,


    --骰子数据
    SiceType_gameStart = 0,
    SiceType_gangCard = 1,

    --服务端接收校验类型
    ReceiveClientKind_Null = 0,
    ReceiveClientKind_Xihu = 1,
    ReceiveClientKind_OutCard = 2,
    ReceiveClientKind_OperateSelf = 3,
    ReceiveClientKind_OperateAll = 4,
    ReceiveClientKind_Yaoshuaibuzhang = 5,
    ReceiveClientKind_HaiDi = 6,

--    ACTION_TIP = 1,                 --提示动作
--    ACTION_TI_CARD = 2,             --提牌动作
--    ACTION_PAO_CARD = 3,            --跑牌动作
--    ACTION_WEI_CARD = 4,            --偎牌动作
--    ACTION_PENG_CARD = 5,           --碰牌动作
--    ACTION_HU_CARD = 6,             --胡牌动作
--    ACTION_CHI_CARD = 7,            --吃牌动作
--    ACTION_OUT_CARD = 8,            --出牌动作
--    ACTION_SEND_CARD = 9,           --发牌动作
--    ACTION_OPERATE_NOTIFY = 10,     --发牌动作
--    ACTION_OUT_CARD_NOTIFY = 11,    --发牌动作
--    ACTION_FANG_CARD = 12,          --翻省动作
--    ACTION_VIEW_CARD = 13,          --表现动作
--    ACTION_HUANG = 14,              --黄庄动作
--    ACTION_WD = 15,                 --王钓动作
--    ACTION_WC = 16,                 --王闯动作
--    ACTION_SISHOU = 17,             --死守动作
--    ACTION_WPei = 18,               --有王赔钱动作
--    ACTION_ADDBASE=19,          --加倍动作
    
    Actor_chi = 0,                  --吃
    Actor_peng = 1,                 --碰
    Actor_gang = 2,                 --杠
    Actor_fill = 3,                 --补
    Actor_hu = 4,                   --胡

    Actor_dsx = 5,                  --大四喜
    Actor_lls = 6,                  --66顺
    Actor_qys = 7,                  --却一色
    Actor_wjh = 8,                  --无将胡（板板胡）
--    Animition_chi = 0,          --吃
--    Animition_peng = 1,         --碰
--    Animition_hu = 2,           --胡
--    Animition_ti = 3,           --提
--    Animition_pao = 4,          --跑
--    Animition_wei = 5,           --偎
--    Animition_chouwei = 6,      --臭偎
--    Animition_bi = 7,           --比
--    Animition_wd = 8,           --王钓
--    Animition_sishou = 9,       --死守
--    Animition_wc = 10,          --王闯
--    Animition_fang = 11,        --翻省    
--    Animition_Huang = 12,       --黄庄
--    Animition_wpei = 13,        --王霸赔钱
    
--    Animition_qing = 14,        --提变倾
--    Animition_xiao = 15,        --偎变啸
--    Animition_chouxiao = 16,    --臭啸
--    Animition_xiahuo = 17,      --比变下火
--    Animition_fangpao = 18,     --放炮
    --字牌变化
--    Animition_sao = 19,         --煨变扫
--    Animition_guosao = 20,      --臭喂变过扫
--    Animition_saoquang = 21,    --提变扫穿
--    Animition_tuo = 22,         --跑变开拓  
    
--    Animition_addBase=23,       --加倍
--    Animition_addBase_no=24,    --不加倍


    Soundeffect_RunAction = 0,      --动作
    Soundeffect_YaoShuaiZi = 1,     --要帅
    Soundeffect_time = 2,           --时间
    Soundeffect_Huang = 3,          --黄庄
    Soundeffect_Chi = 4,            --吃
    Soundeffect_Peng = 5,           --碰
    Soundeffect_Gang = 6,           --杠
    Soundeffect_Hu = 7,             --胡
    Soundeffect_outCard = 8,        --出牌
    Soundeffect_send4Card = 9,      --发牌
    Soundeffect_AddSz = 10,         --加钻

    Soundeffect_xiPaiAnimation = 11,    --洗牌
--    Soundeffect_RunAction = 0,  --动作
--    Soundeffect_RunCard = 1,    --卡牌
--    Soundeffect_Huang = 2,      --黄庄
--    Soundeffect_FangX = 3,      --翻省
--    Soundeffect_getSz = 4,      --获取闪砖
--    Soundeffect_getW = 5,       --摸到王牌
    
    timeAction_Null = 0,
    timeAction_OutCard = 1,
    timeAction_Opration = 2,
    CardData_WW = 49,
    
    leftalignment=1,
    centrealignment = 2,
    rightalignment = 3,
    
--    CARDHEIGH = 90.0,
--    CARDWIDTH = 95.0,
--    BASEPOSITIONY = 55.0,
--    BASEPOSITIONX = 50.0,
    
    ClientSockEvent_connectFaild = 1,                 --链接失败
    ClientSockEvent_connectError = 2,                 --网络错误
    ClientSockEvent_connectSucceed = 3,               --链接成功
    
    INVALID_TEAM = 65535,    --无效组号
    INVALID_TABLE = 65535,   --无效桌子
    INVALID_CHAIR = 65535,  
    INVALID_ID = 4294967295,
    
    --无效数值
    INVALID_BYTE	=			0xFF,						--无效数值
    INVALID_WORD	=		    0xFFFF,					--无效数值
    INVALID_DWORD	=			0xFFFFFFFF,				--无效数值
    
    EARTH_RADIUS = 6371.004,                      --地球半径   
    DistanceAlarm = 1 ,                 -- 距离判断（0：没有判断多，需要判断。1：判断过或不需要判断）
    IsOfHu = 0 ,                        -- 是否胡牌提醒
    IsQIangGangHu = 0 ,                 -- 是否是抢杠胡
    iNOoutcard = false ,                -- 是否需操作出牌，
    -------------------------------------------------------------------------------
    number_dwHorse = 0,                 --扎鸟数
    
    meChairID = 0,

    --漂分
    wPiaoTF = {};
    wPiaoCount = {};
}

function GameCommon:init()
    self.regionSound = 0
	    --数据
    self.tagUserInfoList = {}
    self.wPlayerCount = 0
--    self.dwUserID = 0
    self.gameType = 0
    self.bIsMyTurn = false                      --轮到我出牌了
    self.m_bIsGang = false                      --自己扛牌了
    self.m_bIsBaoTing = false                   --自己报听了
    self.m_MyTurnPos = {}                       --我出牌位置
    self.m_MyHandCardPos = {}                   --摸到手里位置
    self.m_SpecialTempCardData = {}                     --
    self.m_SpecialCardCout = 0                          --
    self.m_SpeciallGameScore = {[1] = 0,[2] = 0,[3] = 0,[4] = 0}    --游戏输赢积分 (长沙麻将表示特殊牌型)
    self.m_GangAllGameScore = {[1] = 0,[2] = 0,[3] = 0,[4] = 0}     --游戏输赢积分 (转转麻将表示杠牌出钱)
    self.wBankerUser = 0                  --庄家用户
    self.m_cbLeftCardCount = 0              --剩余数目
    self.m_cbCardIndex = {}                 --手中扑克
    self.m_cbWeaveCount = {}                --组合数目
    self.m_WeaveItemArray = {}              --组合扑克
    self.m_wSiceCount = 0                   --起始摇甩
    self.m_SiceType = 0                     --摇甩状态
    self.m_wDiceCard = {}                   --摇帅的牌
    self.m_wDiceCount = 0                   --要甩点数
    self.m_wDiceUser = 0                    --
    self.m_data_c = {}                      --记录打乱的牌
    self.m_cout_c = 0                       --记录打乱的牌数
    self.isFriendGameStart = false          --游戏开始
    self.m_GuoZhangGang = {[1] = 0,[2] = 0,[3] = 0,[4] = 0}     --碰了不能再杠的牌

    --是否加票
    self.m_jiaPiao = 0 --默认不加漂
--    self.leftCardCount = 0
--    self.cardStackWidth = 0
--    self.handCardalignment = 0
 --   self.cbCardIndex = {}
 --   self.wBankerUser = 0
 --   self.bWeaveItemCount = {[1] = 0 , [2] = 0 , [3] = 0 }
 --   self.weaveItemArray = {}
 --   self.bUserCardCount = {}
    if self.bellv==nil then
        self.bellv = 0
    end
 --   self.cbWWCout = 0
 --   self.restart = false
    self.restart = false
    self.isHuangZhuang = nil
    
    self.GameState_Init = 0
    self.GameState_Start = 1
    self.GameState_Over = 2
    self.gameState = 0

    --是否明牌
    self.isMingPai = false 
    self.wUserOpreaCount = 0
end

function GameCommon:getRoleChairID()
    for key, var in pairs(self.tagUserInfoList) do
        if var.dwUserID == self.dwUserID then
            return var.wChairID
        end
    end
    return self.meChairID
end

--isChangePos 是否更改位置
function GameCommon:getViewIDByChairID(wChairID,isnoChangePos)
    local location = 1          --主角位置
    local wPlayerCount = self.gameConfig.bPlayerCount      --玩家人数
    local meChairID = self:getRoleChairID()     --主角的座位号
    local viewID = (wChairID + location - meChairID)%wPlayerCount
    if viewID == 0 then
        viewID = wPlayerCount
    end
    if wPlayerCount == 2 and viewID == 2 then
        viewID = 3
    end
    if not isnoChangePos then
        if viewID == 3 and wPlayerCount == 3 then
            viewID = 4
        end
    end
    return viewID

end

function GameCommon:getRoleChairID()
    return self.meChairID
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

-- 大数字转化
function GameCommon:itemNumberToString(num)  
    if num >= 1000000 then  
            return string.format("%d千公里", math.floor(num / 1000000))    
    elseif num >= 1000 then  
        if num % 1000 < 100 then  
            return string.format("%d公里", math.floor(num / 1000))  
        else  
            return string.format("%.1f公里", (num - num % 100)/1000)  
        end  
    elseif num <= 1000 then   
        return string.format("%d米", num/1)  
    else
        return tostring("太远无法定位")  
    end  
end


function GameCommon:rad(d)
    return d* math.pi / 180.0
end 

function GameCommon:GetDistance(lat1,lat2)
    local radLat1 = self:rad(lat1.x)
    local radLat2 = self:rad(lat2.x)
    local a = radLat1 - radLat2
    local b = self:rad(lat1.y) - self:rad(lat2.y)
    local s = 2 * math.asin(math.sqrt(math.pow(math.sin(a/2),2) +math.cos(radLat1)*math.cos(radLat2)*math.pow(math.sin(b/2),2)))
    s = s * self.EARTH_RADIUS*1000
    return s
end 

--手牌资源
function GameCommon:GetCardHand(data,viewID)
    if data == nil then
        data = 0
    end
    local cardIndex = nil 
    if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',0)
    else
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',0)
    end 
    if (GameCommon.tableConfig.wKindID == 65 or GameCommon.tableConfig.wKindID == 54)and data == 0x31 then 
	    if viewID == 2 then
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            if cardIndex == 0 then
                return ccui.ImageView:create(string.format("majiang/card/card0/desktop_card_left%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 1 then
                return ccui.ImageView:create(string.format("majiang/card/card1/desktop_card_left%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 2 then
                return ccui.ImageView:create(string.format("majiang/card/card2/desktop_card_left%d%d_1.png",cbColor,cbValue))
            else
                return ccui.ImageView:create(string.format("majiang/card/card%d/desktop_card_left%d%d_1.png",cardIndex,cbColor,cbValue))
            end
	    elseif viewID == 3 then
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            if cardIndex == 0 then
                return ccui.ImageView:create(string.format("majiang/card/card0/desktop_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 1 then
                return ccui.ImageView:create(string.format("majiang/card/card1/desktop_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex ==2 then
                return ccui.ImageView:create(string.format("majiang/card/card2/desktop_card%d%d_1.png",cbColor,cbValue))
            else
                return ccui.ImageView:create(string.format("majiang/card/card%d/desktop_card%d%d_1.png",cardIndex,cbColor,cbValue))
            end

	    elseif viewID == 4 then
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            if cardIndex == 0 then
                return ccui.ImageView:create(string.format("majiang/card/card0/desktop_card_right%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 1 then
                return ccui.ImageView:create(string.format("majiang/card/card1/desktop_card_right%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 2 then
                return ccui.ImageView:create(string.format("majiang/card/card2/desktop_card_right%d%d_1.png",cbColor,cbValue))
            else
                return ccui.ImageView:create(string.format("majiang/card/card%d/desktop_card_right%d%d_1.png",cardIndex,cbColor,cbValue))
            end

	    else
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            if cardIndex == 0 then
                return ccui.ImageView:create(string.format("majiang/card/card0/hand_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 1 then
                return ccui.ImageView:create(string.format("majiang/card/card1/hand_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 2 then
                return ccui.ImageView:create(string.format("majiang/card/card2/hand_card%d%d_1.png",cbColor,cbValue))
            else
                return ccui.ImageView:create(string.format("majiang/card/card%d/hand_card%d%d_1.png",cardIndex,cbColor,cbValue))
            end
	    end
    else
	    if viewID == 2 then
	        if data == 0 then
                return self:createLeftOrRightHandCard(cardIndex,true)
	        else
	            local cbValue = Bit:_and(data,0x0F)
                local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
                return self:createLeftOrRightOutCard(cardIndex,cbColor,cbValue)
	        end
	    elseif viewID == 3 then
	        if data == 0 then
                return self:creteHandCardBg(cardIndex)
	        else
	            local cbValue = Bit:_and(data,0x0F)
                local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
                local node = self:createOutDeskTopCard(cardIndex,cbColor,cbValue)
                return node
	        end
	    elseif viewID == 4 then
	        if data == 0 then
                return self:createLeftOrRightHandCard(cardIndex,false)
	        else
	            local cbValue = Bit:_and(data,0x0F)
                local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
                return self:createLeftOrRightOutCard(cardIndex,cbColor,cbValue,false)
	            -- if cardIndex == 0 then
	            --     return ccui.ImageView:create(string.format("majiang/card/card0/desktop_card_right%d%d.png",cbColor,cbValue))
	            -- elseif cardIndex == 1 then
	            --     return ccui.ImageView:create(string.format("majiang/card/card1/desktop_card_right%d%d.png",cbColor,cbValue))
	            -- elseif cardIndex == 2 then
	            --     return ccui.ImageView:create(string.format("majiang/card/card2/desktop_card_right%d%d.png",cbColor,cbValue))
                -- else
                --     return ccui.ImageView:create(string.format("majiang/card/card%d/desktop_card_right%d%d.png",cardIndex,cbColor,cbValue))
	            -- end
	        end
	    else
	        if data == 0 then
	            if cardIndex == 0 then
	                return ccui.ImageView:create("majiang/card/card0/desktop_card_bg.png")
	            elseif cardIndex == 1 then
	                return ccui.ImageView:create("majiang/card/card1/desktop_card_bg.png")
	            elseif cardIndex == 2 then
	                return ccui.ImageView:create("majiang/card/card2/desktop_card_bg.png")
                elseif cardIndex == 3 then
                    return ccui.ImageView:create("majiang/card/card3/desktop_card_bg.png")
	            end
	        else
	            local cbValue = Bit:_and(data,0x0F)
                local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
                local node = self:createUpCard(cardIndex,cbColor,cbValue)
                return node
	        end
	    end
    end    
end

function GameCommon:createUpCard( cardIndex, cbColor,cbValue)
    local colorNode = ccui.ImageView:create(string.format("majiang/card/%d%d.png",cbColor,cbValue))
    local bgNode = ccui.ImageView:create(string.format("majiang/card/bg_%d.png",cardIndex or 0))

    bgNode:addChild(colorNode)
    local size = bgNode:getContentSize()
    colorNode:setPosition(cc.p(size.width/2,size.height/2-15))
    return bgNode;
end




function GameCommon:creteHandCardBg( cardIndex)
    local bgNode = ccui.ImageView:create(string.format("majiang/card/hand_card_bg_%d.png",cardIndex or 0))
    return bgNode;
end

function GameCommon:creteOutCardBg( cardIndex)
    local bgNode = ccui.ImageView:create(string.format("majiang/card/cardwei%d.png",cardIndex or 0))
    return bgNode;
end

function GameCommon:createTopDownBg( cardIndex )
    local bgNode = ccui.ImageView:create(string.format("majiang/card/carweitop%d.png",cardIndex or 0))
    return bgNode;
end

function GameCommon:createBigTopBg( cardIndex )
    local bgNode = ccui.ImageView:create(string.format("majiang/card/cardbg_player1_extra%d.png",cardIndex or 0))
    return bgNode;
end

function GameCommon:createOppositBg( cardIndex )
    local bgNode = ccui.ImageView:create(string.format("majiang/card/opposite%d.png",cardIndex or 0))
    return bgNode;
end

function GameCommon:createLeftOrRightHandCard(cardIndex, isLeft )
    local bgNode = ccui.ImageView:create(string.format("majiang/card/card1_card_side_%d.png",cardIndex or 0))
    if not isLeft then
        bgNode:setFlippedX(true)
    end
    return bgNode;
end

function GameCommon:createSmallLeftOrRightOutCard(cardIndex, cbColor,cbValue,isLeft )
    local colorNode = ccui.ImageView:create(string.format("majiang/card/%d%d.png",cbColor,cbValue))
    local bgNode = ccui.ImageView:create(string.format("majiang/card/card_player2_extra%d.png",cardIndex or 0))
    bgNode:addChild(colorNode)
    local size = bgNode:getContentSize()
    colorNode:setPosition(cc.p(size.width/2,size.height/2+8))
    colorNode:setScale(0.38,0.43)
    if isLeft then
        colorNode:setRotation(90)
    else
        colorNode:setRotation(270)
    end
    return bgNode;
end

function GameCommon:createLeftOrRightOutCard(cardIndex, cbColor,cbValue,isLeft )
    local colorNode = ccui.ImageView:create(string.format("majiang/card/%d%d.png",cbColor,cbValue))
    local bgNode = ccui.ImageView:create(string.format("majiang/card/card_out%d.png",cardIndex or 0))
    bgNode:addChild(colorNode)
    local size = bgNode:getContentSize()
    colorNode:setPosition(cc.p(size.width/2,size.height/2+8))
    colorNode:setScale(0.5)
    if isLeft then
        colorNode:setRotation(90)
    else
        colorNode:setRotation(270)
    end
    return bgNode;
end

function GameCommon:createMingPaiHandCard(  data,viewID )
    
    local cardIndex = nil 
    if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',1)
    else
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',0)
    end 

    local cbValue = Bit:_and(data,0x0F)
    local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)

    local colorNode = ccui.ImageView:create(string.format("majiang/card/%d%d.png",cbColor,cbValue))

    if viewID == 1 then
        return self:createOutDeskTopCard(cardIndex,cbColor,cbValue)
    elseif viewID == 2 then
        return self:createLeftOrRightOutCard(cardIndex,cbColor,cbValue,true)
    elseif viewID == 3 then
        return self:createSmallOutDeskTopCard(cardIndex,cbColor,cbValue,true)
    elseif viewID == 4 then
        return self:createLeftOrRightOutCard(cardIndex,cbColor,cbValue,false)
    end
end


--打出牌
function GameCommon:createOutDeskTopCard(cardIndex, cbColor,cbValue )
    local colorNode = ccui.ImageView:create(string.format("majiang/card/%d%d.png",cbColor,cbValue))
    local bgNode = ccui.ImageView:create(string.format("majiang/card/card_player1_extra%d.png",cardIndex or 0))
    bgNode:addChild(colorNode)
    local size = bgNode:getContentSize()
    colorNode:setPosition(cc.p(size.width/2,size.height/2+5))
    colorNode:setScale(0.87)
    return bgNode;
end

--打出牌
function GameCommon:createSmallOutDeskTopCard(cardIndex, cbColor,cbValue,isOpposit )
    local colorNode = ccui.ImageView:create(string.format("majiang/card/%d%d.png",cbColor,cbValue))
    local bgNode = ccui.ImageView:create(string.format("majiang/card/card_playertop_extra%d.png",cardIndex or 0))
    bgNode:addChild(colorNode)
    local size = bgNode:getContentSize()
    colorNode:setPosition(cc.p(size.width/2,size.height/2+5))
    colorNode:setScale(0.46)
    if isOpposit then--对面
        colorNode:setRotation(180)
    else
        colorNode:setRotation(0)
    end
    return bgNode;
end

function GameCommon:GetHUCard(data)
    local cardIndex = nil 
    if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',1)
    else
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',0)
    end 
    local cbValue = Bit:_and(data,0x0F)
    local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
    if (GameCommon.tableConfig.wKindID == 65 or GameCommon.tableConfig.wKindID == 54)and data == 0x31 then 
        local node = self:createUpCard(cardIndex,cbColor,cbValue)
        return node
    else
        local node = self:createUpCard(cardIndex,cbColor,cbValue)
        return node
    end 
end 

function GameCommon:getSmallDiscardCardAndWeaveItemArray( data,viewID)
    local cardIndex = nil 
    if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',1)
    else
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',0)
    end 
    if viewID == 1 then
        local cbValue = Bit:_and(data,0x0F)
        local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
        return self:createSmallOutDeskTopCard(cardIndex,cbColor,cbValue,false)
    elseif viewID == 3 then
        local cbValue = Bit:_and(data,0x0F)
        local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
        return self:createSmallOutDeskTopCard(cardIndex,cbColor,cbValue,false)
    end
end


--获取棋牌或者吃牌组合资源
function GameCommon:getDiscardCardAndWeaveItemArray(data,viewID)
    local cardIndex = nil 
    if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',1)
    else
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',0)
    end 
    if (GameCommon.tableConfig.wKindID == 65 or GameCommon.tableConfig.wKindID == 54)and data == 0x31 then 
	     if viewID == 2 then
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            if cardIndex == 0 then
                return ccui.ImageView:create(string.format("majiang/card/card0/desktop_card_left%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 1 then
                return ccui.ImageView:create(string.format("majiang/card/card1/desktop_card_left%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 2 then
                return ccui.ImageView:create(string.format("majiang/card/card2/desktop_card_left%d%d_1.png",cbColor,cbValue))
            else
                return ccui.ImageView:create(string.format("majiang/card/card%d/desktop_card_left%d%d_1.png",cardIndex,cbColor,cbValue))
            end 
	    elseif viewID == 4 then
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            return self:createLeftOrRightOutCard(cardIndex,cbColor,cbValue,false)
	    elseif viewID == 3 then
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            if cardIndex == 0 then
                return ccui.ImageView:create(string.format("majiang/card/card0/desktop_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 1 then
                return ccui.ImageView:create(string.format("majiang/card/card1/desktop_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 2 then
                return ccui.ImageView:create(string.format("majiang/card/card2/desktop_card%d%d_1.png",cbColor,cbValue))
            else
                return ccui.ImageView:create(string.format("majiang/card/card%d/desktop_card%d%d_1.png",cardIndex,cbColor,cbValue))
            end           
	    else
            local cbValue = Bit:_and(data,0x0F)
            local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
            if cardIndex == 0 then
                return ccui.ImageView:create(string.format("majiang/card/card0/desktop_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 1 then
                return ccui.ImageView:create(string.format("majiang/card/card1/desktop_card%d%d_1.png",cbColor,cbValue))
            elseif cardIndex == 2 then
                return ccui.ImageView:create(string.format("majiang/card/card2/desktop_card%d%d_1.png",cbColor,cbValue))
            else
                return ccui.ImageView:create(string.format("majiang/card/card%d/desktop_card%d%d_1.png",cardIndex,cbColor,cbValue))
            end
	    end
    else
	    if viewID == 2 then
	        if data == 0 then
	            return self:creteOutCardBg(cardIndex)
	        else
	            local cbValue = Bit:_and(data,0x0F)
                local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
                return self:createSmallLeftOrRightOutCard(cardIndex,cbColor,cbValue,true)
	        end
	    elseif viewID == 4 then
	        if data == 0 then
                return self:creteOutCardBg(cardIndex)
	        else
	            local cbValue = Bit:_and(data,0x0F)
                local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
                return self:createSmallLeftOrRightOutCard(cardIndex,cbColor,cbValue,false)
	        end
	    elseif viewID == 3 then
	        if data == 0 then
                return self:createOppositBg(cardIndex)
	        else
                local node = self:getSmallDiscardCardAndWeaveItemArray(data,viewID)
                return node
	        end
	    else
	        if data == 0 then
                return self:createBigTopBg(cardIndex)           
	        else
	            local cbValue = Bit:_and(data,0x0F)
                local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
                local node = self:createOutDeskTopCard(cardIndex,cbColor,cbValue)
                return node
	        end
	    end
    end
end


function GameCommon:getSendOrOutCard(data)
    local cardIndex = nil 
    if CHANNEL_ID == 20 or CHANNEL_ID == 21 then 
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',1)
    else
        cardIndex = cc.UserDefault:getInstance():getIntegerForKey('kwxmj',0)
    end 
    local cbValue = Bit:_and(data,0x0F)
    local cbColor = Bit:_rshift(Bit:_and(data,0xF0),4)
    if (GameCommon.tableConfig.wKindID == 65 or GameCommon.tableConfig.wKindID == 54)and data == 0x31 then 
        if cardIndex == 0 then
            return  ccui.ImageView:create(string.format("majiang/card/card0/hand_card%d%d_1.png",cbColor,cbValue))
        elseif cardIndex == 1 then
            return ccui.ImageView:create(string.format("majiang/card/card1/hand_card%d%d_1.png",cbColor,cbValue))
        elseif cardIndex == 2 then
            return  ccui.ImageView:create(string.format("majiang/card/card2/hand_card%d%d_1.png",cbColor,cbValue))
        else
            return  ccui.ImageView:create(string.format("majiang/card/card%d/hand_card%d%d_1.png",cardIndex,cbColor,cbValue))
        end
    else
        local node = self:createUpCard(cardIndex,cbColor,cbValue)
        return node
    end 

end

function GameCommon:playAnimation(root,id, wChairID)
    local Animation = require("game.majiang.Animation")
    if Animation[id] == nil then
        return
    end
    local AnimationData = Animation[id][GameCommon.regionSound]
    if AnimationData == nil then
        return
    end
    if AnimationData.png ~= "" then  --animFile
        local visibleSize = cc.Director:getInstance():getVisibleSize()
        local uiPanel_tipsCard = ccui.Helper:seekWidgetByName(root,"Panel_tipsCard")


        -- ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(AnimationData.animFile)
        -- local armature = ccs.Armature:create(AnimationData.animName)        
        -- if AnimationData.playName and AnimationData.playName ~= '' then
        --     armature:getAnimation():play(AnimationData.playName,-1,0)
        --     -- armature:getAnimation():playWithIndex(5,-1,0) 
        -- end   
        
        local armature = ccui.ImageView:create(AnimationData.png)
        
        uiPanel_tipsCard:addChild(armature)       
        armature:setScale(1.5)

        armature:runAction(cc.Sequence:create(
            cc.ScaleTo:create(0.1,1),
            cc.DelayTime:create(0.6),
            cc.FadeOut:create(0.5),
            cc.RemoveSelf:create()))
        if id == "黄庄" then
            armature:setPosition(visibleSize.width/2, visibleSize.height/2)
            require("common.Common"):playEffect("common/huangzhuang.mp3")  
        elseif id == '上楼' then
            armature:setPosition(visibleSize.width/2, visibleSize.height/2)
        else
            local viewID = GameCommon:getViewIDByChairID(wChairID)
            local uiPanel_tipsCardPos = ccui.Helper:seekWidgetByName(root,string.format("Panel_tipsCardPos%d",viewID))
            armature:setPosition(uiPanel_tipsCardPos:getPosition())
			if(id == "胡" or id == "自摸" ) and( CHANNEL_ID == 6 or CHANNEL_ID == 7) then
				require("common.Common"):playEffect("common/win.mp3")
			end 
        end
    end
    local soundFile = ""
    if wChairID ~= nil then
        soundFile = AnimationData.sound[GameCommon.player[wChairID].cbSex]
    else
        soundFile = AnimationData.sound[0]
    end

    if soundFile ~= "" then
        require("common.Common"):playEffect(AnimationData.sound[GameCommon.player[wChairID].cbSex])
    end
end

function GameCommon:sendXiaoHu(cbOperateCode,tableCardData)
    local net = NetMgr:getGameInstance()
    if net.connected == false then
        return
    end
    if #tableCardData <= 0 then
        return
    end
    net.cppFunc:beginSendBuf(NetMsgId.MDM_GF_GAME,NetMsgId.SUB_C_Xihu)
    net.cppFunc:writeSendBool(true,0)
    net.cppFunc:writeSendWORD(cbOperateCode,0)
    for key, var in pairs(tableCardData) do
        net.cppFunc:writeSendByte(var,0)
    end
    for i = #tableCardData+1, 14 do
        net.cppFunc:writeSendByte(0,0)
    end
    net.cppFunc:endSendBuf()
    net.cppFunc:sendSvrBuf()
end

--获取除了刻子的手牌
function GameCommon:getExpKZCard( keziArray,cbCardArray,length)
    local kzArray = clone(keziArray)
    length = length or #cbCardArray
    local temp = {}
    for i=1,length do
        table.insert(temp, cbCardArray[i])
    end
    local _cardData = clone(temp)

    --排除零
    local _i = #_cardData
    while _i > 0 do
        if _cardData[_i] == 0 then
            table.remove( _cardData, _i ) 
        end
        _i = _i - 1
    end

    --排除零
    local _ii = #kzArray
    while _ii > 0 do
        if kzArray[_ii] == 0 then
            table.remove( kzArray, _ii ) 
        end
        _ii = _ii - 1
    end

    for j=1,#kzArray do
        local i = #_cardData
        local index = 0
        while i > 0 do
            if index == 3 then
                break
            end
            if _cardData[i] == kzArray[j] then
                table.remove( _cardData, i ) 
                index = index + 1
            end
            i = i-1
        end
    end
    return _cardData
end

return GameCommon