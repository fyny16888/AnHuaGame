---------------
--   大结算
---------------
local DDZGameRoomEnd = class("DDZGameRoomEnd", cc.load("mvc").ViewBase)
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local DDZGameCommon = require("game.puke.DDZGameCommon")
local Base64 = require("common.Base64")

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

local posDis = {
	[2] = {
		cc.p(456.94, 383.98),
		cc.p(802.32, 383.98),
	},
	[3] = {
		cc.p(456.94, 383.98),
		cc.p(802.32, 383.98),
		cc.p(456.94, 232.91),
	},
	[4] = {
        cc.p(456.94, 383.98),
		cc.p(802.32, 383.98),
		cc.p(456.94, 232.91),
		cc.p(802.32, 232.91),
	}
}

local listPos = 
{
	[2] = cc.p(520.00,418),
	[3] = cc.p(388.00,418),
	[4] = cc.p(372,418),
}

function DDZGameRoomEnd:onConfig()
	self.widget = {
		{'back', 'onBack'},
		{'Button_back','onBack'},
		{'zhanji', 'onHistory'},
		{'fang_num'},
		{'text_time'},
		{'text_club'},
		{'panel_end'},
		{'tishi_des'},
		{'template_player'},
		{'listview'},
		{'Panel_text_template'},
		{'Panel_Childs'}
	}
end

function DDZGameRoomEnd:onEnter()
	require("common.Common"):screenshot(FileName.battlefieldScreenshot)
end

function DDZGameRoomEnd:onExit()
	
end

function DDZGameRoomEnd:onCreate(params)
	self.pBuffer = params[1]

	if self.pBuffer then
		self.fang_num:setString(self.pBuffer.tableConfig.wTbaleID)
		self.tishi_des:setString(endDes[self.pBuffer.cbOrigin])
		self:playerInfo()
	end
	
	local function onEventRefreshTime(sender, event)
		local date = os.date("*t", os.time())
		self.text_time:setString(string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
		--self.text_time:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(onEventRefreshTime)))
	end
	onEventRefreshTime()
	self:initPlayerInfo()
end

local function setNameColor( t,value )
	if t then
		t:setColor(cc.c3b(49,103,155))
		t:setString(value)
	end
end

function DDZGameRoomEnd:initPlayerInfo( ... )
	local userCount = self.pBuffer.dwUserCount;
	self.listview:setPosition(listPos[userCount]);
	local winner = self:getWinner(self.pBuffer)

	dump(self.pBuffer,'fx-------------->>')


	for i = 1, self.pBuffer.dwUserCount do
		local data = self.pBuffer.tScoreInfo[i]
		local isWinner = winner[data.dwUserID] or false
		local item = self.template_player:clone()

		local name = self:seekWidgetByNameEx(item,'name')
		local banker = self:seekWidgetByNameEx(item,'banker')
		local id = self:seekWidgetByNameEx(item,'id')
		local Image_gs = self:seekWidgetByNameEx(item,'Image_gs');
		local image_player = self:seekWidgetByNameEx(item,'image_player')
		local Image_normal = self:seekWidgetByNameEx(item,'Image_normal')
		local Image_bigwinner = self:seekWidgetByNameEx(item,'Image_bigwinner')
		local total_score = self:seekWidgetByNameEx(item,'total_score')
		local total_score_1 = self:seekWidgetByNameEx(item,'total_score_1')

		local ListView_score = self:seekWidgetByNameEx(item,'ListView_score')
		for i=1,self.pBuffer.dwDataCount do
			if data.lScore[i] then
				local score_item = self.Panel_text_template:clone()
				local round = self:seekWidgetByNameEx(score_item,'Text_round')
				local score = self:seekWidgetByNameEx(score_item,'Text_score')
				setNameColor(round,string.format( "第%d局",i))
				setNameColor(score,data.lScore[i])
				ListView_score:pushBackCustomItem(score_item)
				ListView_score:refreshView()
			end
		end

		Image_gs:setVisible(isWinner)
		Image_bigwinner:setVisible(isWinner)
		Image_normal:setVisible(not isWinner)
		if data.totalScore >= 0 then
			total_score_1:setText(data.totalScore)
		else
			total_score:setText(data.totalScore)
		end
		total_score_1:setVisible(data.totalScore >= 0)
		total_score:setVisible(data.totalScore < 0)
		Common:requestUserAvatar(data.dwUserID, data.player.szPto, image_player, "img")
		local L_name = Common:getShortName(data.player.szNickName,8,6)
		--setNameColor(name,data.player.szNickName)
		name:setString(L_name)
		name:setColor(cc.c3b(49,103,155))
		banker:setVisible(data.dwUserID == self.pBuffer.dwTableOwnerID)
		setNameColor(id,string.format("ID %d", data.dwUserID))
		self.listview:pushBackCustomItem(item)
		self.listview:refreshView()
	end	
	if self.pBuffer.dwUserCount == 2 then 	
		self.listview:setItemsMargin(300)
		-- self.listview:setContentSize(cc.size(self.listview:getInnerContainerSize().width,self.listview:getInnerContainerSize().height)) 
		-- self.listview:setPositionX(self.listview:getParent():getContentSize().width/2)
	end 
end

function DDZGameRoomEnd:onBack(...)
	require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"), SCENE_HALL)
end

function DDZGameRoomEnd:onHistory(...)
    local data = clone(UserData.Share.tableShareParameter[4])
    data.dwClubID = self.pBuffer.tableConfig.dwClubID
    data.szShareTitle = string.format("战绩分享-房间号:%d,局数:%d/%d",self.pBuffer.tableConfig.wTbaleID, self.pBuffer.tableConfig.wCurrentNumber, self.pBuffer.tableConfig.wTableNumber)
    data.szShareContent = ""
    local maxScore = 0
    for i = 1, 8 do
        if self.pBuffer.tScoreInfo[i].dwUserID ~= nil and self.pBuffer.tScoreInfo[i].dwUserID ~= 0 and self.pBuffer.tScoreInfo[i].totalScore > maxScore then 
            maxScore = self.pBuffer.tScoreInfo[i].totalScore
        end
    end
    for i = 1, 8 do
        if self.pBuffer.tScoreInfo[i].dwUserID ~= nil and self.pBuffer.tScoreInfo[i].dwUserID ~= 0 then
            if data.szShareContent ~= "" then
                data.szShareContent = data.szShareContent.."\n"
            end
            if maxScore ~= 0 and self.pBuffer.tScoreInfo[i].totalScore >= maxScore then
                data.szShareContent = data.szShareContent..string.format("【%s:%d(大赢家)】",self.pBuffer.tScoreInfo[i].player.szNickName,self.pBuffer.tScoreInfo[i].totalScore)
            else
                data.szShareContent = data.szShareContent..string.format("【%s:%d】",self.pBuffer.tScoreInfo[i].player.szNickName,self.pBuffer.tScoreInfo[i].totalScore)
            end
        end
    end
    data.szShareUrl = string.format(data.szShareUrl,self.pBuffer.szGameID)
	data.szShareImg = FileName.battlefieldScreenshot
	data.szGameID = self.pBuffer.szGameID
	data.isInClub = self:isClub(self.pBuffer);
    require("app.MyApp"):create(data):createView("ShareLayer")
end

function DDZGameRoomEnd:onLianJie(...)
	--
end

function DDZGameRoomEnd:isClub(...)
	return self.pBuffer.tableConfig.nTableType == TableType_ClubRoom and self.pBuffer.tableConfig.dwClubID ~= 0
end

function DDZGameRoomEnd:playerInfo(...)
	self.text_club:setString('亲友圈ID: ' .. self.pBuffer.tableConfig.dwClubID)
	self.text_club:setVisible(self:isClub())
end

function DDZGameRoomEnd:getWinner(pBuffer)
	if not pBuffer then
		return
	end
	local max = - 1
	local score = - 1
	local winner = {}
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = - 1
		else
			score = pBuffer.tScoreInfo[i].totalScore or - 1
		end
		if score >= max then
			max = score
		end
	end
	for i = 1, 8 do
		if not pBuffer.tScoreInfo[i] then
			score = - 1
		else
			score = pBuffer.tScoreInfo[i].totalScore or - 1
		end
		if score == max and max > 0 then
			local id = pBuffer.tScoreInfo[i].dwUserID
			winner[id] = true
		end
	end
	return winner
end

return DDZGameRoomEnd 