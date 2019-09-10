local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local GameCommon = nil
local Base64 = require("common.Base64")
local Bit = require("common.Bit")

local KwxGameOver = class("KwxGameOver", function()
	return ccui.Layout:create()
end)

local Location = {
	[2] = {
		cc.p(240, 121),
		cc.p(760, 121),
	},
	[3] = {
		cc.p(182, 121),
		cc.p(518, 121),
		cc.p(855, 121),
	},
	[4] = {
		cc.p(48.00, 121),
		cc.p(348.00, 121),
		cc.p(648.00, 121),
		cc.p(950.00, 121),
	}
}
local endDes = {
	[0] = '',
	[1] = '提示：该房间被房主解散',
	[2] = '提示：该房间被管理员解散',
	[3] = '提示：该房间投票解散',
	[4] = '提示：该房间因疲劳值不足被强制解散',
	[5] = '提示：该房间被官方系统强制解散',
	[6] = '提示：该房间因超时未开局被强制解散',
	[7] = '提示：该房间因超时投票解散',
}


--映射关系
local EndList = {
	[-1] = '总囤数',
	[1] = '胡牌次数',
	[2] = '黄庄次数',
	[3] = '自摸次数',
	[4] = '点炮次数',
	[5] = '提牌次数',
	[6] = '跑牌次数',
	[7] = '碰牌次数',
	[8] = '偎牌次数',
	[9] = '中庄次数',
	[10] = '接炮次数',
	[11] = '暗杠次数',
	[12] = '明杠次数',
	[13] = '公杠次数',
}

function KwxGameOver:create(pBuffer)
	local view = KwxGameOver.new()
	view:onCreate(pBuffer)
	local function onEventHandler(eventType)
		if eventType == "enter" then
			view:onEnter()
		elseif eventType == "exit" then
			view:onExit()
		end
	end
	view:registerScriptHandler(onEventHandler)
	return view
end

function KwxGameOver:onEnter()
	--保存游戏截屏
	local Panel_function = ccui.Helper:seekWidgetByName(self.root, "Panel_function")
	Panel_function:setVisible(false)

	local date = os.date("*t", os.time())
	self.endTime = string.format("%d-%02d-%02d  %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec)
	self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
		require("common.Common"):screenshot(FileName.battlefieldScreenshot)
	end), cc.DelayTime:create(0), cc.CallFunc:create(function()
		Panel_function:setVisible(true)
	end)))
end

function KwxGameOver:onExit()
	
end

function KwxGameOver:onCreate(pBuffer)
	cc.Director:getInstance():getRunningScene():removeChildByTag(LAYER_TIPS)
	self.ShareName = string.format("%d.jpg", os.time())
	self.root = nil
	self.pBuffer = pBuffer
	local csb = cc.CSLoader:createNode("KwxGameOver.csb")
	self:addChild(csb)
	self.root = csb:getChildByName("Panel_root")

	GameCommon = self.pBuffer.GameCommon
	local tishi_des = ccui.Helper:seekWidgetByName(self.root,"tishi_des")
    tishi_des:setString(endDes[self.pBuffer.cbOrigin])

	self:initVar()
	local uiButton_return = ccui.Helper:seekWidgetByName(self.root, "Button_return")
	uiButton_return:setPressedActionEnabled(true)
	local function onEventReturn(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
		end
	end
	uiButton_return:addTouchEventListener(onEventReturn)
	self.ListView_end = ccui.Helper:seekWidgetByName(self.root, "ListView_end")
	self.Panel_score = ccui.Helper:seekWidgetByName(self.root, "Panel_score")
	self:updatePlayerInfo(pBuffer)


	
	local Button_zhanji = ccui.Helper:seekWidgetByName(self.root, "Button_zhanji")
    Button_zhanji:setPressedActionEnabled(true)
    local function onEventHistory(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
            local data = clone(UserData.Share.tableShareParameter[4])
            data.dwClubID = pBuffer.tableConfig.dwClubID
            data.szShareTitle = string.format("战绩分享-房间号:%d,局数:%d/%d",pBuffer.tableConfig.wTbaleID, pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber)
            data.szShareContent = ""
            local maxScore = 0
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 and pBuffer.tScoreInfo[i].totalScore > maxScore then 
                    maxScore = pBuffer.tScoreInfo[i].totalScore
                end
            end
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 then
                    if data.szShareContent ~= "" then
                        data.szShareContent = data.szShareContent.."\n"
                    end
                    if maxScore ~= 0 and pBuffer.tScoreInfo[i].totalScore >= maxScore then
                        data.szShareContent = data.szShareContent..string.format("【%s:%d(大赢家)】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    else
                        data.szShareContent = data.szShareContent..string.format("【%s:%d】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    end
                end
            end
            data.szShareUrl = string.format(data.szShareUrl,pBuffer.szGameID)
            data.szShareImg = FileName.battlefieldScreenshot
            data.szGameID = pBuffer.szGameID
            data.isInClub = self:isInClub(pBuffer);
            data.cbTargetType = Bit:_and(data.cbTargetType, 80)
            require("app.MyApp"):create(data):createView("ShareLayer")
		end
    end
    Button_zhanji:addTouchEventListener(onEventHistory)


	local uiButton_share = ccui.Helper:seekWidgetByName(self.root, "Button_share")
	uiButton_share:setPressedActionEnabled(true)
	local function onEventShare(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
            local data = clone(UserData.Share.tableShareParameter[4])
            data.dwClubID = pBuffer.tableConfig.dwClubID
            data.szShareTitle = string.format("战绩分享-房间号:%d,局数:%d/%d",pBuffer.tableConfig.wTbaleID, pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber)
            data.szShareContent = ""
            local maxScore = 0
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 and pBuffer.tScoreInfo[i].totalScore > maxScore then 
                    maxScore = pBuffer.tScoreInfo[i].totalScore
                end
            end
            for i = 1, 8 do
                if pBuffer.tScoreInfo[i].dwUserID ~= nil and pBuffer.tScoreInfo[i].dwUserID ~= 0 then
                    if data.szShareContent ~= "" then
                        data.szShareContent = data.szShareContent.."\n"
                    end
                    if maxScore ~= 0 and pBuffer.tScoreInfo[i].totalScore >= maxScore then
                        data.szShareContent = data.szShareContent..string.format("【%s:%d(大赢家)】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    else
                        data.szShareContent = data.szShareContent..string.format("【%s:%d】",pBuffer.tScoreInfo[i].player.szNickName,pBuffer.tScoreInfo[i].totalScore)
                    end
                end
            end
            data.szShareUrl = string.format(data.szShareUrl,pBuffer.szGameID)
            data.szShareImg = FileName.battlefieldScreenshot
            data.szGameID = pBuffer.szGameID
            data.isInClub = self:isInClub(pBuffer);
            data.cbTargetType = Bit:_and(data.cbTargetType, 6)
            require("app.MyApp"):create(data):createView("ShareLayer")
		end
	end
	uiButton_share:addTouchEventListener(onEventShare)
	local uiText_time = ccui.Helper:seekWidgetByName(self.root, "Text_time")
	-- local function onEventRefreshTime(sender, event)
		local date = os.date("*t", os.time())
		uiText_time:setString(string.format("%d-%02d-%02d  %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
	-- 	uiText_time:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(onEventRefreshTime)))
	-- end
	-- onEventRefreshTime()
	local uiText_homeowner = ccui.Helper:seekWidgetByName(self.root, "Text_homeowner")
	uiText_homeowner:setString(string.format("房主:%s(%d)", pBuffer.szOwnerName, pBuffer.dwTableOwnerID))
	local uiText_roomInfo = ccui.Helper:seekWidgetByName(self.root, "Text_roomInfo")
	--uiText_roomInfo:setString(string.format("局数:%d/%d\n房间号:%d",pBuffer.tableConfig.wCurrentNumber,pBuffer.tableConfig.wTableNumber,pBuffer.tableConfig.wTbaleID))
	uiText_roomInfo:setString(string.format("房间号:%d", pBuffer.tableConfig.wTbaleID))
	local uiText_roomInfo1 = ccui.Helper:seekWidgetByName(self.root, "Text_roomInfo_num")
	uiText_roomInfo1:setString(string.format(string.format("局数:%d/%d", pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber)))
	local uiText_roomInfo2 = ccui.Helper:seekWidgetByName(self.root, "Text_roomInfo_name")
	uiText_roomInfo2:setString(StaticData.Games[pBuffer.tableConfig.wKindID].name)
	local uiText_gameInfo = ccui.Helper:seekWidgetByName(self.root, "Text_gameInfo")
	if pBuffer.gameDesc ~= nil and pBuffer.gameDesc ~= "" then
		uiText_gameInfo:setString(string.format("%s", StaticData.Games[pBuffer.tableConfig.wKindID].name .. " " .. pBuffer.gameDesc))
	else
		uiText_gameInfo:setString(string.format("%s", StaticData.Games[pBuffer.tableConfig.wKindID].name))
	end
	local gameDes = ccui.Helper:seekWidgetByName(self.root, "gameDes")
	gameDes:setString(pBuffer.gameDesc)
end

function KwxGameOver:isInClub( pBuffer )
    return pBuffer.tableConfig.nTableType == TableType_ClubRoom and pBuffer.tableConfig.dwClubID ~= 0
end

function KwxGameOver:initVar(...)
	self.Panel_payerInfo = ccui.Helper:seekWidgetByName(self.root, "Panel_payerInfo")
	self.center = ccui.Helper:seekWidgetByName(self.root, "center")
	self.updateItems = {}
end

function KwxGameOver:updatePlayerInfo(pBuffer)
	dump(pBuffer,'fx-------------->>')
	if not pBuffer then
		return
	end
	local Pos = Location[pBuffer.dwUserCount]
	
	local winner = self:getWinner(pBuffer)
	
	for i = 1, pBuffer.dwUserCount do
		local item = self.Panel_payerInfo:clone()
		local tScoreInfo = pBuffer.tScoreInfo[i]
		local uiImage_avatar = ccui.Helper:seekWidgetByName(item, "Image_avatar")
		Common:requestUserAvatar(tScoreInfo.dwUserID, tScoreInfo.player.szPto, uiImage_avatar, "clip")
		local uiText_palyerName = ccui.Helper:seekWidgetByName(item, "Text_palyerName")
		uiText_palyerName:setString(tScoreInfo.player.szNickName)
		uiText_palyerName:setColor(cc.c3b(129, 18, 18))
		local uiText_id = ccui.Helper:seekWidgetByName(item, "Text_id")
		uiText_id:setString(string.format("ID:%d", tScoreInfo.dwUserID))
		uiText_id:setColor(cc.c3b(129, 18, 18))
		local uiImage_host = ccui.Helper:seekWidgetByName(item, "Image_host")
		if tScoreInfo.dwUserID == pBuffer.dwTableOwnerID then
			uiImage_host:setVisible(true)
		else
			uiImage_host:setVisible(false)
		end
		local Image_winner = ccui.Helper:seekWidgetByName(item, "Image_winner")
		Image_winner:setVisible(false)
		if winner[tScoreInfo.dwUserID] then
			Image_winner:setVisible(true)
		end
		
	

		local uiAtlasLabel_integral = ccui.Helper:seekWidgetByName(item, "AtlasLabel_integral")
		local addAtlasLab = ccui.Helper:seekWidgetByName(item,'AtlasLabel_integraladd');
		addAtlasLab:setVisible(tScoreInfo.totalScore >= 0)
		uiAtlasLabel_integral:setVisible(tScoreInfo.totalScore < 0)
		if tScoreInfo.totalScore >= 0 then
			addAtlasLab:setStringValue('/'.. self:getScore(tScoreInfo.totalScore))
		else
			uiAtlasLabel_integral:setStringValue( '/'.. self:getScore(tScoreInfo.totalScore))
		end
		self:updatePlayerStatics(item, pBuffer.statistics[i],tScoreInfo.totalScore)

		self.center:addChild(item)
		item:setPosition(Pos[i])
	end
end

--获取倍数
function KwxGameOver:getScore ( score )
	local wKindID = GameCommon.tableConfig.wKindID
	if GameCommon.gameConfig.bPlayerCount == 2 and wKindID == 40 then
		local tempScore = math.abs(score)
		local bei = GameCommon.gameConfig.bMinLostCell or 1
		if bei <= 0 then
			bei = 1
		end
		if GameCommon.gameConfig.bMinLost == 0 then
			if bei > 1 then --不限分加倍
				return score * bei
			else
				return score
			end
		else
			if tempScore <= GameCommon.gameConfig.bMinLost   then
				return score * bei
			else
				return score
			end
		end
	else
		return score
	end
end

function KwxGameOver:getWinner(pBuffer)
	if not pBuffer then
		return
	end
	local max = - 1
	local winner = {}
	local score = -1
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = -1
		else
			score = pBuffer.tScoreInfo[i].totalScore or -1
		end
		if score >= max then
			max = score
		end
	end
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = -1
		else
			score = pBuffer.tScoreInfo[i].totalScore or -1
		end
		if score == max and max > 0 then
			local id = pBuffer.tScoreInfo[i].dwUserID
			winner[id] = true
		end
	end
	return winner
end

--用户统计
function KwxGameOver:updatePlayerStatics(root, statics,score)
	local showEnd = {3,10,4,11,12}
	local wkindID = GameCommon.tableConfig.wKindID  
	if wkindID == 44 or wkindID == 60  or wkindID == 89 then
		showEnd = {-1,1,3,5,6}
	elseif wkindID == 88 then
		showEnd = {-1,1,3}
	end
	local listEnd = root:getChildByName('ListView_end')
	local _minggang = statics[12] or 0;
	local _angang = statics[13] or 0;
	for i=1,#showEnd do
		local item = self.Panel_score:clone()
		local Text_name = item:getChildByName('Text_name')
		local Text_num = item:getChildByName('Text_num')
		Text_name:setColor(cc.c3b(177, 76, 15))
		Text_num:setColor(cc.c3b(177, 76, 15))
		local index = showEnd[i]
		Text_name:setString(EndList[index])
		if index == -1 then --胡息总数
			if wkindID == 88 then
				Text_name:setString("总积分")
			end
			Text_num:setString(score)
		else
			if index == 12 then
				Text_num:setString(_minggang + _angang)
			else
				Text_num:setString(statics[index] or 0)
			end
		end
		listEnd:pushBackCustomItem(item)
	end
end

local posDis = {
	[2] = {
		cc.p(414, 448),
		cc.p(873, 450),
	},
	[3] = {
		cc.p(414, 448),
		cc.p(873, 450),
		cc.p(414, 242),
	},
	[4] = {
        cc.p(414, 448),
		cc.p(873, 450),
		cc.p(414, 242),
		cc.p(873, 242),
	}
}


--复制总战绩
function KwxGameOver:copyData()
    local pBuffer = self.pBuffer
    local clubId = '亲友圈ID:' .. pBuffer.tableConfig.dwClubID .. '\n'
    dump(pBuffer.tableConfig)
	local strRoom = '房间号:' .. pBuffer.tableConfig.wTbaleID .. '\n'
	local endRoo = '结束时间:' .. self.endTime .. '\n'
	local roomBanker = '房主:' .. pBuffer.szOwnerName .. '\n'
	
	local des = StaticData.Games[pBuffer.tableConfig.wKindID].name .. string.format(" 局数:%d/%d", pBuffer.tableConfig.wCurrentNumber, pBuffer.tableConfig.wTableNumber) .. '\n'
	local endDes = ''
    for i = 1, pBuffer.dwUserCount do
        local tScoreInfo = pBuffer.tScoreInfo[i]
        endDes = endDes .. tScoreInfo.player.szNickName .. ' ID：' .. tScoreInfo.dwUserID .. ' ' ..   tScoreInfo.totalScore .. '\n'
	end
    local history = clubId .. strRoom .. endRoo .. roomBanker .. des .. endDes
    print('------------------>>',history)
    return history
end

return KwxGameOver
