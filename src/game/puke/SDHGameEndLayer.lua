
--[[
*名称:SDHGameEndLayer
*描述:三打哈小结算
*作者:admin
*创建日期:2019-06-11 09:48:45
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local Default           = require("common.Default")
local GameConfig        = require("common.GameConfig")
local SDHGameCommon 	= require("game.puke.SDHGameCommon")  
local Log               = require("common.Log")

local SDHGameEndLayer 	= class("SDHGameEndLayer", cc.load("mvc").ViewBase)

function SDHGameEndLayer:onConfig()
    self.widget         = {
    	{"Image_settleFrame"},
    	{"Image_settleFont"},
    	{"Panel_card"},
    	{"AtlasLabel_score"},
        {"Button_ready", "onReady"},
    }
end

function SDHGameEndLayer:onEnter()
end

function SDHGameEndLayer:onExit()
end

function SDHGameEndLayer:onCreate(param)
    local pBuffer = param[1]
	Log.d(pBuffer)
    self.AtlasLabel_score:setString(pBuffer.wConcealScore)

    local score = pBuffer.wGameScore
    if pBuffer.bAddConceal then
        score = score + pBuffer.wConcealScore
    end

    local stage = 1
    if score >= SDHGameCommon.bLandScore then
        stage = 1
    end
    if score >= SDHGameCommon.bLandScore+40 then
        stage = 2
    end
    if score >= SDHGameCommon.bLandScore+70 then
        stage = 3
    elseif score == 0 then
        stage = 3
    elseif score < 30 and score < SDHGameCommon.bLandScore then
        stage = 2
    elseif score < SDHGameCommon.bLandScore then
        stage = 1
    end

    if SDHGameCommon:getRoleChairID() == SDHGameCommon.wBankerUser then
        --庄家
        if score < SDHGameCommon.bLandScore then
            --赢了
            self.Image_settleFrame:loadTexture('sdh/ok_ui_sdh_win_bg.png')
            self.Image_settleFont:loadTexture(string.format('sdh/ok_ui_sdh_bnaker_w_%d.png', stage))
        else
            --输了
            self.Image_settleFrame:loadTexture('sdh/ok_ui_sdh_fail_bg.png')
            self.Image_settleFont:loadTexture(string.format('sdh/ok_ui_sdh_bnaker_f_%d.png', stage))
        end
    else
        --咸家
        if score >= SDHGameCommon.bLandScore then
            --赢了
            self.Image_settleFrame:loadTexture('sdh/ok_ui_sdh_win_bg.png')
            self.Image_settleFont:loadTexture(string.format('sdh/ok_ui_sdh_xian_w_%d.png', stage))
        else
            --输了
            self.Image_settleFrame:loadTexture('sdh/ok_ui_sdh_fail_bg.png')
            self.Image_settleFont:loadTexture(string.format('sdh/ok_ui_sdh_xian_f_%d.png', stage))
        end
    end

    local cardScale = 0.6
    for i = 1, pBuffer.cbConcealCount do
        local data = pBuffer.cbConcealCard[i]
        local card = SDHGameCommon:getCardNode(data)
        self.Panel_card:addChild(card)
        card:setScale(cardScale)
        card:setAnchorPoint(cc.p(0,0))
        local pt = cc.p((i-1)*40, 0)
        card:setPosition(pt)
    end

    if pBuffer.cbConcealCount <=8 then
        self.Panel_card:setPositionX(self.Panel_card:getPositionX() + 20)
    end
end

function SDHGameEndLayer:onReady()
	if SDHGameCommon.tableConfig.nTableType == TableType_FriendRoom or SDHGameCommon.tableConfig.nTableType == TableType_ClubRoom then
        if SDHGameCommon.tableConfig.wTableNumber == SDHGameCommon.tableConfig.wCurrentNumber then
            EventMgr:dispatch(EventType.EVENT_TYPE_CACEL_MESSAGE_BLOCK)
        else
            SDHGameCommon:ContinueGame(SDHGameCommon.tableConfig.cbLevel)
        end
    elseif SDHGameCommon.tableConfig.nTableType == TableType_GoldRoom or SDHGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then 
        SDHGameCommon:ContinueGame(SDHGameCommon.tableConfig.cbLevel)
    else
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
    end          
end

return SDHGameEndLayer