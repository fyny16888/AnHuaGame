--[[
*名称:NewClubPlayWayInfoLayer
*描述:亲友圈疲劳值玩法设置
*作者:admin
*创建日期:2018-06-14 15:41:55
*修改日期:
]]

local EventMgr              = require("common.EventMgr")
local EventType             = require("common.EventType")
local NetMgr                = require("common.NetMgr")
local NetMsgId              = require("common.NetMsgId")
local StaticData            = require("app.static.StaticData")
local UserData              = require("app.user.UserData")
local Common                = require("common.Common")
local Default               = require("common.Default")
local GameConfig            = require("common.GameConfig")
local Log                   = require("common.Log")

--元宝模式玩法创建最低限制
local AALimit               = 10
local BigLimit              = 30
local WinLimit              = 30

local NewClubPlayWayInfoLayer = class("NewClubPlayWayInfoLayer", cc.load("mvc").ViewBase)

function NewClubPlayWayInfoLayer:onConfig()
    self.widget             = {
        {"Button_close", "onClose"},
        {"Text_playwaydes"},
        {"TextField_playway"},
        {"Text_cardType"},
        {"Image_aatype", "onAAType"},
        {"Image_bigwin", "onBigWin"},
        {"Image_win", "onWin"},
        {"Text_expend"},
        {"ListView_win"},
        {"Text_AA"},
        {"TextField_aaValue"},
        {"Button_setAAValue", "onSetAAValue"},
        {"Text_statistics"},
        {"Button_statistics", "onStatistics"},
        {"Text_critical"},
        {"TextField_criticalNum"},
        {"Button_setCritical", "onSetCritical"},
        {"Text_power"},
        {"TextField_powerNum"},
        {"Button_setPower", "onSetPower"},
        {"Button_cancel", "onCancel"},
        {"Button_achieve", "onAchieve"},
        {"Button_statistics"},
        {"Text_winItem"},
        {"Image_bankerMode", "onBankerMode"},
        {"Image_fatigueMode", "onFatigueMode"},
        {"Image_goldMode", "onGoldMode"},
        {"Text_modeDes"},
    }
    self.gameMode = 0
    self.payMode = 0
end

function NewClubPlayWayInfoLayer:onEnter()
    self.Text_winItem:retain()
end

function NewClubPlayWayInfoLayer:onExit()
    self.Text_winItem:release()
end

function NewClubPlayWayInfoLayer:onCreate(param)
	Log.d(param[1])
	self.clubData = param[1]
	self.TextField_aaValue:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	self.TextField_criticalNum:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	self.TextField_powerNum:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	self.TextField_aaValue:setTouchEnabled(false)
	self.TextField_criticalNum:setTouchEnabled(false)
	self.TextField_powerNum:setTouchEnabled(false)
	self:initUI(self.clubData, param[2])
end

function NewClubPlayWayInfoLayer:onClose()
    self:removeFromParent()
end

function NewClubPlayWayInfoLayer:onAAType()
	self:switchPayMode(3)
end

function NewClubPlayWayInfoLayer:onBigWin()
	self:switchPayMode(1)
end

function NewClubPlayWayInfoLayer:onWin()
	self:switchPayMode(2)
end

function NewClubPlayWayInfoLayer:onBankerMode()
    self:switchPlayerMode(0)
end

function NewClubPlayWayInfoLayer:onFatigueMode()
    self:switchPlayerMode(1)
end

function NewClubPlayWayInfoLayer:onGoldMode()
    self:switchPlayerMode(2)
end

function NewClubPlayWayInfoLayer:onSetAAValue()
    local limitValue = 0
    if self.gameMode == 2 then
        limitValue = AALimit
    end
    local node = require("app.MyApp"):create(limitValue, 3, function(value) 
        self.TextField_aaValue:setString(value)
    end):createView("NewClubInputFatigueLayer")
    self:addChild(node)
end

function NewClubPlayWayInfoLayer:onStatistics()
	if self.clubData.isTableCharge[self.clubData.idx] then
		self.clubData.isTableCharge[self.clubData.idx] = false
    	self:switchTableCharge(false)
	else
		self.clubData.isTableCharge[self.clubData.idx] = true
    	self:switchTableCharge(true)
	end
end

function NewClubPlayWayInfoLayer:onSetCritical()
	self.TextField_criticalNum:setTouchEnabled(true)
    self.TextField_criticalNum:attachWithIME()
end

function NewClubPlayWayInfoLayer:onSetPower()
	self.TextField_powerNum:setTouchEnabled(true)
    self.TextField_powerNum:attachWithIME()
end

function NewClubPlayWayInfoLayer:onCancel()
	self:removeFromParent()
end

function NewClubPlayWayInfoLayer:onAchieve()
	local data = self.clubData
	local playTbl = {}
	playTbl.szParameterName = self.TextField_playway:getString()

    playTbl.cbMode = self.gameMode
    if self.gameMode ~= 0 then
        playTbl.payMode = self.payMode
        if playTbl.payMode == 0 then
            --免费
            playTbl.payLimit1 = 0
            playTbl.payCount1 = 0
            playTbl.payLimit2 = 0
            playTbl.payCount2 = 0
            playTbl.payLimit3 = 0
            playTbl.payCount3 = 0
        elseif playTbl.payMode == 3 then
            --AA
            playTbl.payCount1 = tonumber(self.TextField_aaValue:getString())
            if not Common:isInterNumber(playTbl.payCount1) then
                require("common.MsgBoxLayer"):create(0,nil,"消耗数量必须非负整数")
                return
            end

            playTbl.payLimit1 = 0
            playTbl.payLimit2 = 0
            playTbl.payCount2 = 0
            playTbl.payLimit3 = 0
            playTbl.payCount3 = 0
        else
            --赢家
            local listArr = self.ListView_win:getChildren()
            local limitNum = nil
            local payCount = nil
            for i=1,3 do
                local item = listArr[i]
                if item then
                    local TextField_expendLimit = ccui.Helper:seekWidgetByName(item, "TextField_expendLimit")
                    playTbl['payLimit' .. i] = tonumber(TextField_expendLimit:getString())
                    if not Common:isInterNumber(playTbl['payLimit' .. i]) then
                        require("common.MsgBoxLayer"):create(0,nil,"消耗数量必须非负整数")
                        return
                    end

                    local TextField_expendNum = ccui.Helper:seekWidgetByName(item, "TextField_expendNum")
                    playTbl['payCount' .. i] = tonumber(TextField_expendNum:getString())
                    if not Common:isInterNumber(playTbl['payCount' .. i]) then
                        require("common.MsgBoxLayer"):create(0,nil,"消耗数量必须非负整数")
                        return
                    end

                    --从小到大检查
                    if limitNum then
                        if limitNum >= playTbl['payLimit' .. i] then
                            require("common.MsgBoxLayer"):create(0,nil,"消耗数量设置错误(从小到大顺序)")
                            return
                        end
                    end
                    limitNum = playTbl['payLimit' .. i]

                    if payCount then
                        if payCount >= playTbl['payCount' .. i] then
                            require("common.MsgBoxLayer"):create(0,nil,"消耗数量设置错误(从小到大顺序)")
                            return
                        end
                    end
                    payCount = playTbl['payCount' .. i]

                else
                    playTbl['payLimit' .. i] = 0
                    playTbl['payCount' .. i] = 0
                end
            end
        end

        playTbl.isTableCharge = data.isTableCharge[data.idx]
        if playTbl.isTableCharge then
            playTbl.tableLimit = tonumber(self.TextField_criticalNum:getString())
            if not Common:isInterNumber(playTbl.tableLimit) then
                require("common.MsgBoxLayer"):create(0,nil,"门槛设置必须非负整数")
                return
            end
            playTbl.fatigueCell = tonumber(self.TextField_powerNum:getString())
            if not Common:isInterNumber(playTbl.fatigueCell) or playTbl.fatigueCell == 0 then
                require("common.MsgBoxLayer"):create(0,nil,"倍率设置必须是大于1的整数")
                return
            end
        else
            playTbl.tableLimit = 0
            playTbl.fatigueCell = 1
        end
    else
        playTbl.payMode = 0
        playTbl.isTableCharge = false
        playTbl.tableLimit = 0
        playTbl.fatigueCell = 1
        playTbl.payLimit1 = 0
        playTbl.payCount1 = 0
        playTbl.payLimit2 = 0
        playTbl.payCount2 = 0
        playTbl.payLimit3 = 0
        playTbl.payCount3 = 0
    end
    playTbl.fatigueLimit = 0

    self:megerSetData(playTbl)
    self:sendSetPlayWay(self.clubData)
    local parentNode = self:getParent()
	parentNode:removeFromParent()
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
--初始化UI
function NewClubPlayWayInfoLayer:initUI(data, isModifyPlayName)
	local desc = require("common.GameDesc"):getGameDesc(data.wKindID, data.tableParameter)
    self.Text_playwaydes:setString(desc)

    if not isModifyPlayName and data.szParameterName[data.idx] ~= "" and data.szParameterName[data.idx] ~= " " then
    	self.TextField_playway:setString(data.szParameterName[data.idx])
    else
    	local text = StaticData.Games[data.wKindID].name
    	self.TextField_playway:setString(text)
    end

    self.gameMode = data.cbMode[data.idx]
    self:switchPlayerMode(self.gameMode)

    self.payMode = data.cbPayMode[data.idx]
    self:switchPayMode(self.payMode)

    local idx = data.idx
    self.TextField_criticalNum:setString(data.lTableLimit[idx])
    self.TextField_powerNum:setString(data.wTableCell[idx])
    self.TextField_aaValue:setString(data.dwPayCount[idx][1])
    self:initLimitRand(data)

    if data.isTableCharge[data.idx] ~= false then
        self:switchTableCharge(true)
    else
        self:switchTableCharge(false)
    end

    local wKindID = self.clubData.wKindID
    if StaticData.Hide[CHANNEL_ID].btn18 ~= 1 or wKindID == 51 or wKindID == 53 or wKindID == 55 then
        self.Text_statistics:setVisible(false)
    end
end

function NewClubPlayWayInfoLayer:initLimitRand(data)
    self.ListView_win:removeAllItems()
    local idx = data.idx
    local count = 0
    for i=1,3 do
        local limitData = data.dwPayLimit[idx][i] or 0
        local countData = data.dwPayCount[idx][i] or 0
        if count == 0 or (limitData and limitData > 0) then
            count = count + 1
            local item = self.Text_winItem:clone()
            self.ListView_win:pushBackCustomItem(item)
            self:setLimitItem(item, limitData, countData, count)
        end
    end
end

function NewClubPlayWayInfoLayer:setLimitItem(item, limitData, countData, count)
    local TextField_expendLimit = ccui.Helper:seekWidgetByName(item, "TextField_expendLimit")
    local Button_setExpendLimit = ccui.Helper:seekWidgetByName(item, "Button_setExpendLimit")
    local TextField_expendNum = ccui.Helper:seekWidgetByName(item, "TextField_expendNum")
    local Button_setExpend = ccui.Helper:seekWidgetByName(item, "Button_setExpend")
    local Button_expendCotrol = ccui.Helper:seekWidgetByName(item, "Button_expendCotrol")
    local Text_kouFont = ccui.Helper:seekWidgetByName(item, "Text_kouFont")
    item:setColor(cc.c3b(255,0,0))
    Text_kouFont:setColor(cc.c3b(99,61,58))

    TextField_expendLimit:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    TextField_expendLimit:setTouchEnabled(false)
    TextField_expendLimit:setString(limitData)

    TextField_expendNum:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    TextField_expendNum:setTouchEnabled(false)
    TextField_expendNum:setString(countData)

    if count <= 1 then
        local path = 'club/club_48.png'
        Button_expendCotrol:loadTextures(path, path, path)
    else
        local path = 'club/club_47.png'
        Button_expendCotrol:loadTextures(path, path, path)
    end

    Common:addTouchEventListener(Button_setExpendLimit, function(sender, event)
        local limitValue = 0
        local node = require("app.MyApp"):create(limitValue, 3, function(value) 
            TextField_expendLimit:setString(value)
        end):createView("NewClubInputFatigueLayer")
        self:addChild(node)
    end)

    Common:addTouchEventListener(Button_setExpend, function(sender, event)
        local limitValue = 0
        if self.gameMode == 2 then
            if self.payMode == 1 then
                --大赢家
                limitValue = BigLimit
            elseif self.payMode == 2 then
                --赢家
                limitValue = WinLimit
            end
        end
        local node = require("app.MyApp"):create(limitValue, 3, function(value) 
            TextField_expendNum:setString(value)
        end):createView("NewClubInputFatigueLayer")
        self:addChild(node)
    end)

    Common:addTouchEventListener(Button_expendCotrol, function(sender, event)
        if count <= 1 then
            --添加
            local itemCount = #self.ListView_win:getChildren()
            if itemCount < 3 then
                local item = self.Text_winItem:clone()
                self.ListView_win:pushBackCustomItem(item)
                self:setLimitItem(item, 0, 0, itemCount + 1)
            else
                require("common.MsgBoxLayer"):create(0,nil,"最多添加3个！")
            end
        else
            --移除
            item:removeFromParent()
        end
    end)
end

function NewClubPlayWayInfoLayer:switchPlayerMode(pType)
    print('game mode = ', pType)
    self.gameMode = pType
    if pType == 1 then
        --疲劳值
        self.Image_bankerMode:getChildByName('Image_light'):setVisible(false)
        self.Image_fatigueMode:getChildByName('Image_light'):setVisible(true)
        self.Image_goldMode:getChildByName('Image_light'):setVisible(false)
        self.Text_modeDes:setString('疲劳值模式:消耗圈主房卡和玩家疲劳值')
    elseif pType == 2 then
        --元宝模式
        self.Image_bankerMode:getChildByName('Image_light'):setVisible(false)
        self.Image_fatigueMode:getChildByName('Image_light'):setVisible(false)
        self.Image_goldMode:getChildByName('Image_light'):setVisible(true)
        self.Text_modeDes:setString('元宝模式:消耗玩家元宝')
    else
        --房卡模式
        self.Image_bankerMode:getChildByName('Image_light'):setVisible(true)
        self.Image_fatigueMode:getChildByName('Image_light'):setVisible(false)
        self.Image_goldMode:getChildByName('Image_light'):setVisible(false)
        self.Text_modeDes:setString('圈主模式:消耗圈主房卡')
    end

    if pType == 0 then
        self.Text_cardType:setVisible(false)
        self.Text_expend:setVisible(false)
    else
        self.Text_cardType:setVisible(true)
        self.Text_expend:setVisible(true)
        self:switchPayMode(self.payMode)
    end
end

function NewClubPlayWayInfoLayer:switchPayMode(pType)
    --默认AA
    if not pType or pType == 0 then
        pType = 3
    end
    self.payMode = pType
    if pType == 1 then
        --大赢家
        self.Image_aatype:getChildByName('Image_light'):setVisible(false)
        self.Image_bigwin:getChildByName('Image_light'):setVisible(true)
        self.Image_win:getChildByName('Image_light'):setVisible(false)
        self.ListView_win:setVisible(true)
        self.Text_AA:setVisible(false)

    elseif pType == 2 then
        --所有赢家
        self.Image_aatype:getChildByName('Image_light'):setVisible(false)
        self.Image_bigwin:getChildByName('Image_light'):setVisible(false)
        self.Image_win:getChildByName('Image_light'):setVisible(true)
        self.ListView_win:setVisible(true)
        self.Text_AA:setVisible(false)

    elseif pType == 3 then
        --AA值
        self.Image_aatype:getChildByName('Image_light'):setVisible(true)
        self.Image_bigwin:getChildByName('Image_light'):setVisible(false)
        self.Image_win:getChildByName('Image_light'):setVisible(false)
        self.ListView_win:setVisible(false)
        self.Text_AA:setVisible(true)
    end

    --元宝模式
    if self.gameMode == 2 then
        if pType == 1 then
            local data = {
                idx = 1,
                dwPayLimit = {{0}}, 
                dwPayCount = {{BigLimit}}
            }
            self:initLimitRand(data)

        elseif pType == 2 then
            local data = {
                idx = 1,
                dwPayLimit = {{0}}, 
                dwPayCount = {{WinLimit}}
            }
            self:initLimitRand(data)

        elseif pType == 3 then
            self.TextField_aaValue:setString(AALimit)
        end
    end
end

function NewClubPlayWayInfoLayer:switchTableCharge(isOpen)
    if isOpen then
        self.Text_critical:setVisible(true)
        self.Text_power:setVisible(true)
        local path = 'kwxclub/kwxclub_159.png'
        self.Button_statistics:loadTextures(path, path, path)
    else
        self.Text_critical:setVisible(false)
        self.Text_power:setVisible(false)
        local path = 'kwxclub/kwxclub_158.png'
        self.Button_statistics:loadTextures(path, path, path)
    end

    local itemArr =self.ListView_win:getChildren()
    for i,v in ipairs(itemArr) do
        if isOpen then
            self.Text_winItem:setString('疲劳值大于')
            v:setString('疲劳值大于')
        else
            self.Text_winItem:setString('积分大于')
            v:setString('积分大于')
        end
    end
end

function NewClubPlayWayInfoLayer:megerSetData(data)
    self.clubData = self.clubData or {}
    for k,v in pairs(data) do
        self.clubData[k] = v
    end
end


---------------------------------------------
-- 发送设置玩法确定请求  TODO[待优化] copy ClubInfoLayer
---------------------------------------------
--[[
BYTE	cbSettingsType;								//设置类型			1添加一种玩法 2删除一种玩法 3修改一种玩法

DWORD	dwClubID;									//俱乐部ID(8位随机)
DWORD	dwPlayID;									//玩法ID
WORD	wKindID;									//游戏ID
WORD	wGameCount;									//游戏局数
WORD	wTableCell;									//游戏倍率	

bool	cbMode;										//游戏模式           0圈主模式 1疲劳值模式 2元宝模式
BYTE    cbPayMode;									//房费付费模式		0不扣 1大赢家 2所有赢家 3AA制
DWORD	dwPayLimit;									//房费付费下限		0不限制必须扣 积分>=下限则扣（大赢家和所有赢家有效）
DWORD	dwPayCount;									//房费费用			用于群主抽成
LONG	lTableLimit;								//桌子下限			限制玩家进入游戏
WORD    wFatigueCell 								//疲劳值倍率
bool	isTableCharge;								//桌子交易			是否用于交易 0不交易 1交易

TCHAR	szParameterName[NAME_LEN];					//游戏参数名字
TCHAR	pParameter[128];							//游戏参数

DWORD	dwTargetID;

]]

function NewClubPlayWayInfoLayer:sendSetPlayWay(data)
    if type(data) ~= 'table' then
        printError('NewClubPlayWayInfoLayer:sendSetPlayWay data error!')
        return
    end
    Log.d(data)

    if data.wKindID == 16 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount,data.tableParameter.bSuccessive,data.tableParameter.bQiangHuPai,data.tableParameter.bLianZhuangSocre) 

    elseif data.wKindID == 25 or data.wKindID == 26 or data.wKindID == 76 or data.wKindID == 77  then  
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbbbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount, data.tableParameter.bStartCard,data.tableParameter.bBombSeparation,data.tableParameter.bRed10,
            data.tableParameter.b4Add3,data.tableParameter.bShowCardCount,data.tableParameter.bSpringMinCount,data.tableParameter.bAbandon,
            data.tableParameter.bCheating,data.tableParameter.bFalseSpring,data.tableParameter.bAutoOutCard)
    elseif data.wKindID == 83   then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbbbbbbbbbbbb",
        data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
        data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
        data.tableParameter.bPlayerCount, data.tableParameter.bStartCard,data.tableParameter.bBombSeparation,data.tableParameter.bRed10,
        data.tableParameter.b4Add3,data.tableParameter.bShowCardCount,data.tableParameter.bSpringMinCount,data.tableParameter.bAbandon,
        data.tableParameter.bCheating,data.tableParameter.bFalseSpring,data.tableParameter.bAutoOutCard,data.tableParameter.bThreeBomb,
        data.tableParameter.b15Or16,data.tableParameter.bMustOutCard,data.tableParameter.bMustNextWarn,data.tableParameter.bJiaPiao,
        data.tableParameter.bThreeEx)
    elseif data.wKindID == 84   then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbb",
        data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
        data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
        data.tableParameter.bPlayerCount,data.tableParameter.bShowCardCount,data.tableParameter.bCheating,data.tableParameter.bPlayWayType,
        data.tableParameter.bShoutBankerType,data.tableParameter.bBombMaxNum,data.tableParameter.bBankerWayType)
    elseif data.wKindID == 78 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbbbbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount, data.tableParameter.mLaiZiCount, data.tableParameter.bJiePao, data.tableParameter.bQiDui, data.tableParameter.bQGHu, 
            data.tableParameter.bQGHuBaoPei, data.tableParameter.bJiaPiao, data.tableParameter.bMaType, data.tableParameter.bMaCount, data.tableParameter.mNiaoType, 
            data.tableParameter.mHongNiao, data.tableParameter.bWuTong)  
    elseif data.wKindID == 79 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbbbbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount, data.tableParameter.mLaiZiCount, data.tableParameter.bJiePao, data.tableParameter.bQiDui, data.tableParameter.bQGHuBaoPei, data.tableParameter.bJiaPiao, 
            data.tableParameter.bMaType, data.tableParameter.bMaCount, data.tableParameter.mNiaoType,data.tableParameter.mHongNiao,data.tableParameter.bZhuangXian,
            data.tableParameter.bWuTong)  
    elseif data.wKindID == 80 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbbbbbbbbbbbbbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount, data.tableParameter.mZXFlag, data.tableParameter.bBBGFlag, data.tableParameter.bSTFlag, data.tableParameter.bXHBJPFlag, 
            data.tableParameter.bYZHFlag, data.tableParameter.mZTSXlag, data.tableParameter.mJTYNFlag, data.tableParameter.mZTLLSFlag, data.tableParameter.bMQFlag, 
            data.tableParameter.bJJHFlag, data.tableParameter.bLLSFlag, data.tableParameter.bQYSFlag, data.tableParameter.bWJHFlag, data.tableParameter.bDSXFlag,
            data.tableParameter.bJiaPiao,data.tableParameter.bMaType,data.tableParameter.bMaCount,data.tableParameter.mNiaoType,data.tableParameter.mKGNPFlag,
            data.tableParameter.bWuTong)
    elseif data.wKindID == 81 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbbbbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount, data.tableParameter.mLaiZiCount, data.tableParameter.bJiePao, data.tableParameter.bQiDui, data.tableParameter.bQGHuBaoPei, data.tableParameter.bJiaPiao, 
            data.tableParameter.bMaType, data.tableParameter.bMaCount, data.tableParameter.mNiaoType,data.tableParameter.mHongNiao,data.tableParameter.bZhuangXian,
            data.tableParameter.bWuTong)    
    elseif data.wKindID == 82 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbbbbbbbbbbbbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount, data.tableParameter.mBanBanHu, data.tableParameter.mJiangJiangHu, data.tableParameter.bQiDui, 
            data.tableParameter.bHaoHuaQiDui, data.tableParameter.bGangShangPao, data.tableParameter.bGangShangHua, data.tableParameter.bQingYiSe, 
            data.tableParameter.bPPHu, data.tableParameter.bHuangZhuangHG, data.tableParameter.bSiHZHu, data.tableParameter.bQGHu, 
            data.tableParameter.bJiePao, data.tableParameter.mLaiZiCount, data.tableParameter.bJiaPiao,data.tableParameter.bMaType,
            data.tableParameter.bMaCount,data.tableParameter.mNiaoType,data.tableParameter.mHongNiao,data.tableParameter.bWuTong) 

    elseif data.wKindID == 85 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbooooooo",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount, data.tableParameter.bShowCardCount, data.tableParameter.bCheating,data.tableParameter.bPlayWayType,
            data.tableParameter.bSettleType,data.tableParameter.bSurrenderStage,data.tableParameter.bRemoveKingCard,data.tableParameter.bRemoveSixCard,
            data.tableParameter.bPaiFei,data.tableParameter.bDaDaoEnd,data.tableParameter.bNoTXPlease,data.tableParameter.bNoLookCard,data.tableParameter.b35Down) 

    elseif data.wKindID == 44 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbwbbbbbbbbdbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.FanXing.bType,data.tableParameter.FanXing.bCount,data.tableParameter.FanXing.bAddTun,
            data.tableParameter.bPlayerCountType,data.tableParameter.bPlayerCount,data.tableParameter.bLaiZiCount,data.tableParameter.bMaxLost,
            data.tableParameter.bYiWuShi,data.tableParameter.bLiangPai,data.tableParameter.bCanHuXi,data.tableParameter.bHuType,
            data.tableParameter.bFangPao,data.tableParameter.bSettlement,data.tableParameter.bStartTun,data.tableParameter.bSocreType,
            data.tableParameter.dwMingTang,data.tableParameter.bTurn,data.tableParameter.bPaoTips,data.tableParameter.bStartBanker,data.tableParameter.bDeathCard)

    elseif data.wKindID == 60 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbwbbbbbbbbdbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.FanXing.bType,data.tableParameter.FanXing.bCount,data.tableParameter.FanXing.bAddTun,
            data.tableParameter.bPlayerCountType,data.tableParameter.bPlayerCount,data.tableParameter.bLaiZiCount,data.tableParameter.bMaxLost,
            data.tableParameter.bYiWuShi,data.tableParameter.bLiangPai,data.tableParameter.bCanHuXi,data.tableParameter.bHuType,
            data.tableParameter.bFangPao,data.tableParameter.bSettlement,data.tableParameter.bStartTun,data.tableParameter.bSocreType,
            data.tableParameter.dwMingTang,data.tableParameter.bTurn,data.tableParameter.bStartBanker,data.tableParameter.bDeathCard) 

    elseif data.wKindID == 89 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbbbwbbbbbbbbdbbbbbbb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.FanXing.bType,data.tableParameter.FanXing.bCount,data.tableParameter.FanXing.bAddTun,
            data.tableParameter.bPlayerCountType,data.tableParameter.bPlayerCount,data.tableParameter.bLaiZiCount,data.tableParameter.bMaxLost,
            data.tableParameter.bYiWuShi,data.tableParameter.bLiangPai,data.tableParameter.bCanHuXi,data.tableParameter.bHuType,
            data.tableParameter.bFangPao,data.tableParameter.bSettlement,data.tableParameter.bStartTun,data.tableParameter.bSocreType,
            data.tableParameter.dwMingTang,data.tableParameter.bTurn,data.tableParameter.bPaoTips,data.tableParameter.bStartBanker,
            data.tableParameter.bDeathCard,data.tableParameter.bMingType,data.tableParameter.bMingWei,data.tableParameter.b3Long5Kan) 

    elseif data.wKindID == 88 then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddwwwbbddddddlwolnsbbbbdb",
            data.settype,data.dwClubID,data.playid,data.wKindID,data.wGameCount,1,
            data.cbMode,data.payMode,data.payLimit1,data.payCount1,data.payLimit2,data.payCount2,data.payLimit3,data.payCount3,data.tableLimit,data.fatigueCell,data.isTableCharge,data.fatigueLimit,32,data.szParameterName,
            data.tableParameter.bPlayerCount,data.tableParameter.bDeathCard,data.tableParameter.bZhuangFen,
            data.tableParameter.bChongFen,data.tableParameter.dwMingTang,data.tableParameter.bChiNoPeng)

    else
    end
end

return NewClubPlayWayInfoLayer