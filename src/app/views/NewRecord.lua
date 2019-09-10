---------------
--   战绩
---------------
local Bit = require("common.Bit")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local NewRecord = class("NewRecord", cc.load("mvc").ViewBase)

local MAX_ITEM = 4 --请求数量
local DAY_TYPE = {
	TODAY=1,
	YESTDAY=2,
	EVE = 3,--前天
}
--数据类型
local RECORD_TYPE = {
	PERSON_RECORD = 1,
	CLUB_RECORD = 2,
}

local Page_State = {
	RECORD_PAGE = 1,
	DETAIL_PAGE = 2,
}

function NewRecord:onConfig(...)
	self.widget = {
		{'Panel_record'},
		{'Button_close','onClose'},
		{'Image_template'},
		{'Image_name_template'},
		{'Panel_details'},
		{'ListView_details'},
		{'Image_detail_template'},
		{'Button_record','onCallOtherReplay'},
		{"Button_choice", "onchoice"},
		{"Button_Ordinary", "onOrdinary"},
		{"Button_friends", "onfriends"}
	}
end

function NewRecord:onEnter(...)
	EventMgr:registListener(EventType.RET_CL_MAIN_RECORD_BY_TYPE0, self, self.RET_CL_MAIN_RECORD_BY_TYPE0)
	EventMgr:registListener(EventType.RET_CL_MAIN_RECORD_BY_TYPE1, self, self.RET_CL_MAIN_RECORD_BY_TYPE1)
	EventMgr:registListener(EventType.SUB_CL_SUB_RECORD, self, self.SUB_CL_SUB_RECORD)
	EventMgr:registListener(EventType.SUB_CL_SUB_REPLAY_SHAREID, self, self.SUB_CL_SUB_REPLAY_SHAREID)
	EventMgr:registListener(EventType.SUB_CL_SUB_SHARE_REPLAY_DATA, self, self.SUB_CL_SUB_SHARE_REPLAY_DATA)
	EventMgr:registListener(EventType.SUB_CL_SUB_REPLAY, self, self.SUB_CL_SUB_REPLAY)
	EventMgr:registListener(EventType.SUB_CL_MAIN_RECORD_FINISH, self, self.SUB_CL_MAIN_RECORD_FINISH)
	EventMgr:registListener(EventType.RET_CL_MAIN_RECORD_TOTAL_SCORE,self, self.RET_CL_MAIN_RECORD_TOTAL_SCORE)
end

function NewRecord:onExit(...)
	EventMgr:unregistListener(EventType.RET_CL_MAIN_RECORD_BY_TYPE0, self, self.RET_CL_MAIN_RECORD_BY_TYPE0)
	EventMgr:unregistListener(EventType.RET_CL_MAIN_RECORD_BY_TYPE1, self, self.RET_CL_MAIN_RECORD_BY_TYPE1)
	EventMgr:unregistListener(EventType.SUB_CL_SUB_RECORD, self, self.SUB_CL_SUB_RECORD)
	EventMgr:unregistListener(EventType.SUB_CL_SUB_SHARE_REPLAY_DATA, self, self.SUB_CL_SUB_SHARE_REPLAY_DATA)
	EventMgr:unregistListener(EventType.SUB_CL_SUB_REPLAY, self, self.SUB_CL_SUB_REPLAY)
	EventMgr:unregistListener(EventType.SUB_CL_MAIN_RECORD_FINISH, self, self.SUB_CL_MAIN_RECORD_FINISH)
	EventMgr:unregistListener(EventType.SUB_CL_SUB_REPLAY_SHAREID, self, self.SUB_CL_SUB_REPLAY_SHAREID)
	EventMgr:unregistListener(EventType.RET_CL_MAIN_RECORD_TOTAL_SCORE,self, self.RET_CL_MAIN_RECORD_TOTAL_SCORE)
end

function NewRecord:onCreate(params)
	self.leftToggle = nil
	self.topToggle = nil
	self.dayType = DAY_TYPE.TODAY
	self.recordType = RECORD_TYPE.RECORD_PAGE
	self.oldPage = Page_State.PERSON_PAGE
	self.isCanBottom = false
	self.oldTips = nil
	self:initUI()
	self:initRecordData()
	self.cellSize = cc.size(1040, 175) --宽 高
	self.viewSize = cc.size(1030, 580)
	self.listView = Common:_createList(self.viewSize, handler(self, self._itemUpdateCall), self.cellSize.width, self.cellSize.height, handler(self, self.getDataCount), nil, nil, nil, false)
	self.listView:setPosition(cc.p(257,60))
	self.listView:setBounceable(false)
	self.Panel_record:addChild(self.listView)
	self:reqRecord(DAY_TYPE.TODAY,RECORD_TYPE.PERSON_RECORD)
	self:changePage(Page_State.RECORD_PAGE)

	--计时器
	schedule(self.listView, handler(self,self.checkReq), 0.6)

	self:canGoTo()

	-- if stype == 1 then 
        self.Button_choice:setBright(true)
    --     self:switchUI(1)
    -- else
    --     self.Button_choice:setBright(false)
    --     self:switchUI(2)
    -- end 
end

--是否需要跳转
function NewRecord:canGoTo( ... )
	local defoutTop = 1
	local defoutLeft = 1
	--是否需要进行跳转 0不需要 1 需要
	local canGo = cc.UserDefault:getInstance():getIntegerForKey("record_hall",0)
	if canGo == 1 then
		--1个人战绩 2 亲友圈战绩
		local page = cc.UserDefault:getInstance():getIntegerForKey("hall_pageState",0)
		defoutTop = page
		--0今日1昨日2前日
		local day = cc.UserDefault:getInstance():getIntegerForKey("hall_day",0)
		defoutLeft = day
		self:createToggleButton(2,'Button_top_',handler(self,self.onClickTopRecord),defoutTop);
		self:createToggleButton(3,'Button_statics_',handler(self,self.onClickToggleRecord),defoutLeft)
		--跳转子页签
		self:changePage(Page_State.DETAIL_PAGE)
		self.ListView_details:removeAllChildren()
		self.wKindID = cc.UserDefault:getInstance():getIntegerForKey("hall_kwindID",0)
		self.szMainGameID = cc.UserDefault:getInstance():getStringForKey("hall_mainGameID",'')
		self.totalScore = {}
		UserData.Record:sendMsgGetSubRecord(self.szMainGameID)
		cc.UserDefault:getInstance():setIntegerForKey("record_hall",0)
	else
		self:createToggleButton(2,'Button_top_',handler(self,self.onClickTopRecord),defoutTop);
		self:createToggleButton(3,'Button_statics_',handler(self,self.onClickToggleRecord),defoutLeft)
	end
end

function NewRecord:initUI( ... )
	self.allStatics = {}
	for i=1,3 do
		local score 	= self:seekWidgetByNameEx(self.Panel_record,'Text_score_' .. i)
		local personScore = self:seekWidgetByNameEx(score,'Text_score')
		table.insert( self.allStatics,personScore)
	end
	self.Button_close:setZOrder(100)
end

function NewRecord:initRecordData( ... )
	self.recordData = {}
	self.recordData[RECORD_TYPE.CLUB_RECORD] = {}
	self.recordData[RECORD_TYPE.PERSON_RECORD] = {}
	self.hasReq = {}
	self.hasReq[RECORD_TYPE.CLUB_RECORD] = {}
	self.hasReq[RECORD_TYPE.PERSON_RECORD] = {}
	self.cacheData = {} --数据缓存
	self.cacheData[RECORD_TYPE.CLUB_RECORD] = {}
	self.cacheData[RECORD_TYPE.PERSON_RECORD] = {}

	self.reqState = {} --请求状态
	self.reqState[RECORD_TYPE.CLUB_RECORD] = {}
	self.reqState[RECORD_TYPE.PERSON_RECORD] = {}
	self.reqState[RECORD_TYPE.CLUB_RECORD][DAY_TYPE.TODAY] = 0 --0 正在请求 1可以请求
	self.reqState[RECORD_TYPE.PERSON_RECORD][DAY_TYPE.YESTDAY] = 0
	self.reqState[RECORD_TYPE.PERSON_RECORD][DAY_TYPE.EVE] = 0
end


function NewRecord:createToggleButton(perssCount,buttonName,callFunc,defoutCallNum)
	for i=1,perssCount do
		local target = self:seekWidgetByNameEx(self.csb,buttonName .. i)
		self:addButtonEventListener(target,callFunc);
		target.press = self:seekWidgetByNameEx(target,'Image_2')
		target.normal = self:seekWidgetByNameEx(target,'Image_1')
		target.imagePress = self:seekWidgetByNameEx(target,'Image_press')
		target.imagePress:setVisible(false)
		target.press:setVisible(false)
		target.normal:setVisible(true)
		target.isClick = false
		target.ToggleState = function (self,isNormal )
			target.normal:setVisible(isNormal)
			target.press:setVisible(not isNormal)
			target.imagePress:setVisible(not isNormal)
		end
		if defoutCallNum and i == defoutCallNum then
			if callFunc then
				callFunc(target)
			end
		end
	end
end

function NewRecord:onClickToggleRecord( sender )
	if sender.isClick then
		return
	end
	sender:ToggleState(false)
	if self.topToggle then
		self.topToggle:ToggleState(true)
		self.topToggle.isClick = false
	end
	self.topToggle = sender
	self.topToggle.isClick = true
	if sender:getName() == 'Button_statics_1' then
		self:changeDay(DAY_TYPE.TODAY)
	elseif sender:getName() == 'Button_statics_2' then
		self:changeDay(DAY_TYPE.YESTDAY)
	elseif sender:getName() == 'Button_statics_3' then
		self:changeDay(DAY_TYPE.EVE)
	end
	print('点击了',sender:getName())
end

function NewRecord:onCallOtherReplay( ... )
	local box = require("app.MyApp"):create():createView('ReplayInput')
	self:addChild(box)
end

function NewRecord:onClickTopRecord( sender )
	if sender.isClick then
		return
	end
	sender:ToggleState(false)
	if self.leftToggle then
		self.leftToggle:ToggleState(true)
		self.leftToggle.isClick = false
	end
	self.leftToggle = sender
	self.leftToggle.isClick = true
	if sender:getName() == 'Button_top_1' then --个人战绩
		self:chageRecord(RECORD_TYPE.PERSON_RECORD)
	elseif sender:getName() == 'Button_top_2' then --亲友圈
		self:chageRecord(RECORD_TYPE.CLUB_RECORD)
	end
	print('点击了',sender:getName())
end

function NewRecord:onClose(  )
	self:gotoPage()
end

function NewRecord:onchoice()
    if self.Button_choice:isBright() == true then 
        self.Button_choice:setBright(false)
		--self:switchUI(2)
		self:chageRecord(RECORD_TYPE.CLUB_RECORD)
    else
        self.Button_choice:setBright(true)
		--self:switchUI(1)
		self:chageRecord(RECORD_TYPE.PERSON_RECORD)
    end 
end 

function NewRecord:onOrdinary()
	self.Button_choice:setBright(true)
	self:chageRecord(RECORD_TYPE.PERSON_RECORD)
end 

function NewRecord:onfriends()
	self.Button_choice:setBright(false)
	self:chageRecord(RECORD_TYPE.CLUB_RECORD)
end 

function NewRecord:addButtonEventListener(button, callback,isAction)
	isAction = isAction or false
	if button then
		button:setPressedActionEnabled(isAction)
		button:addTouchEventListener(function(sender, event)
			if event == ccui.TouchEventType.ended then
				Common:palyButton()
				if callback then
					callback(sender)
				end
			end
		end)
	end
end

function NewRecord:addLayerEventListener(target, callback)
	if target then
		target:addTouchEventListener(function(sender, event)
			if event == ccui.TouchEventType.ended then
				if callback then
					callback(sender,'end')
				end
			elseif event == ccui.TouchEventType.began then
				if callback then
					callback(sender,'began')
				end
			elseif event == ccui.TouchEventType.moved then
				if callback then
					callback(sender,'moved')
				end
			end
		end)
	end
end

function NewRecord:getDataCount()
	return #self.recordData[self.recordType][self.dayType]
end

function NewRecord:changeDay( type_day )
	self.isCanBottom = false
	self.dayType = type_day
	self:reqRecord(self.dayType,self.recordType)
	self:showRecordData()
end

function NewRecord:chageRecord( type_record )
	self.isCanBottom = false
	self.recordType = type_record
	self:reqRecord(self.dayType,self.recordType)
	self:showRecordData()
	self:changePage(Page_State.RECORD_PAGE)
end

function NewRecord:gotoPage( ... )
	if self.oldPage == Page_State.RECORD_PAGE then
		self:removeFromParent()
	elseif self.oldPage == Page_State.DETAIL_PAGE then
		self:changePage(Page_State.RECORD_PAGE)
	end
end

function NewRecord:changePage( page )
	self.Panel_record:setVisible( page == Page_State.RECORD_PAGE)
	self.Panel_details:setVisible(page == Page_State.DETAIL_PAGE )
	self.oldPage = page
end

function NewRecord:createSubRecord( data )
	local item = self.Image_detail_template:clone()
	self.ListView_details:pushBackCustomItem(item)
	self.ListView_details:refreshView()
	local count = self.ListView_details:getChildrenCount()
	--4人
	local playerCount = 4
	if data.wChairCount >= 5 then
		playerCount = 8
	end
	local target = nil
	local target_child = nil
	local Panel_4 =  ccui.Helper:seekWidgetByName(self.Panel_details,'Panel_4_1')
	local Panel_8 =  ccui.Helper:seekWidgetByName(self.Panel_details,'Panel_8_1')
	local Panel_4_child = self:seekWidgetByNameEx(item,'Panel_4')
	local Panel_8_child = self:seekWidgetByNameEx(item,'Panel_8')
	Panel_4:setVisible(playerCount == 4)
	Panel_8:setVisible(playerCount == 8)
	Panel_4_child:setVisible(playerCount == 4)
	Panel_8_child:setVisible(playerCount == 8)
	if playerCount == 4 then
		target = Panel_4
		target_child = Panel_4_child
	elseif playerCount == 8 then
		target = Panel_8
		target_child = Panel_8_child
	end

	for i=1,playerCount do
		local child = self:seekWidgetByNameEx(target,'Image_detail_' .. i)
		local Text_playername = self:seekWidgetByNameEx(child,'Text_playername');
		local score = self:seekWidgetByNameEx(target_child,'Text_score_' .. i)
		local Text_total_score_1 = self:seekWidgetByNameEx(target,'Text_total_score_' .. i)
		local isHave = i <= data.wChairCount
		child:setVisible(isHave)
		score:setVisible(isHave)
		Text_total_score_1:setVisible(isHave)
		if isHave then
			local name = Common:getShortName(data.szNickName[i],8,6)
			Text_playername:setString(name)
			if not self.totalScore[i] then
				self.totalScore[i] = 0
			end
			self.totalScore[i] = self.totalScore[i] + data.lScore[i]
			self:setStrColor(score,data.lScore[i],'分')
			self:setStrColor(Text_total_score_1,self.totalScore[i],'分')
		end
		local Panel_click = self:seekWidgetByNameEx(child,'Panel_click')
		self:addLayerEventListener(Panel_click,handler(self,self.showClickName))
		Panel_click.name = data.szNickName[i]
		Panel_click:setSwallowTouches(false)
	end

	local Button_share = self:seekWidgetByNameEx(item,'Button_share')
	Button_share:setName(data.szSubGameID)
	self:addButtonEventListener(Button_share,handler(self,self.shareCallFunc),true)

	local Button_look = item:getChildByName('Button_look')
	Button_look:setName(data.szSubGameID)
	self:addButtonEventListener(Button_look, handler(self, self.reBackPlay),true)
	local Text_num = self:seekWidgetByNameEx(item,'Text_num')
	Text_num:setString(count)
	self:setScoreColor(Text_num,3)
end

function NewRecord:shareCallFunc( sender )
	print("分享：", self.wKindID, self.szMainGameID, sender:getName())
	UserData.Record:REQ_CL_SUB_GET_REPLAY_SHAREID(self.wKindID, self.szMainGameID, sender:getName())
end

--回放
function NewRecord:reBackPlay(sender)
	print("回放", sender:getName())
	self:saveRecord()
	UserData.Record:sendMsgGetMainReplay(sender:getName())            --回放
end

function NewRecord:saveRecord( ... )
	cc.UserDefault:getInstance():setIntegerForKey("record_hall",1)
	cc.UserDefault:getInstance():setIntegerForKey("hall_pageState",self.recordType)
	cc.UserDefault:getInstance():setIntegerForKey("hall_day",self.dayType)
	cc.UserDefault:getInstance():setIntegerForKey("hall_kwindID",self.wKindID)
	cc.UserDefault:getInstance():setStringForKey("hall_mainGameID",self.szMainGameID)
end

function NewRecord:showRecordData( )
	if not self.recordData[self.recordType][self.dayType] then
		self.recordData[self.recordType][self.dayType] = {}
	end
	self:reloadData()
end

function NewRecord:getServerTypeDay( day_type )
	if day_type == 1 then
		return 1
	elseif day_type == 2 then
		return 2
	elseif day_type == 3 then
		return 3
	end
end

function NewRecord:getServerTypRecord( record_type )
	if record_type ==  1 then
		return 0
	elseif record_type == 2 then
		return 1
	end
end

function NewRecord:getLocalTypeRecord( server_record )
	if server_record == 0 then
		return RECORD_TYPE.PERSON_RECORD
	elseif server_record == 1 then --个人俱乐部战绩
		return RECORD_TYPE.CLUB_RECORD 
	end
end

function NewRecord:getLoalTypeDay(server_day)
	if server_day == 1 then
		return DAY_TYPE.TODAY
	elseif server_day == 2 then
		return DAY_TYPE.YESTDAY
	elseif server_day == 3 then
		return DAY_TYPE.EVE
	end
end


function NewRecord:recordKye( time )
    local today = os.date("*t",os.time())
    local endTime = os.time({day=today.day, month=today.month, year=today.year, hour=24, minute=0, second=0})
    local gameTime = time
    if gameTime > endTime then
        local key = os.date("*t",time) 
        return string.format("%d-%d-%d", key.year, key.month, key.day)
    end

    local differenceDay = math.ceil((endTime - gameTime)/(24*60*60))
    if differenceDay <= 3 then
        return differenceDay
    else
        local key = os.date("*t",time) 
        return string.format("%d-%d-%d", key.year, key.month, key.day)
    end
end

function NewRecord:getLoaclByServerTime( time )
	local str = self:recordKye(time)
	if str == 1 then
		return DAY_TYPE.TODAY
	elseif str == 2 then
		return DAY_TYPE.YESTDAY
	elseif str == 3 then
		return DAY_TYPE.EVE
	end
end

function NewRecord:reqRecord( day_type,record_type )
	if not self.hasReq[record_type][day_type] then
		local dayType 	 = self:getServerTypeDay(day_type)
		local recordType = self:getServerTypRecord(record_type)
		print('-------->>>recordType,dayType',recordType,dayType)
		UserData.Record:sendMsgGetMainRecord(recordType, 0, MAX_ITEM, '',UserData.User.userID,dayType) --普通场
		self.hasReq[record_type][day_type] = true
	end
end

--插入数据
function NewRecord:insertRecordData( type_day,type_record ,value)
	print('----插入数据',type_day,type_record ,value)
	local data = self.recordData[type_record]
	if not data[type_day] then
		self.recordData[type_record][type_day] = {}
	end
	table.insert( self.recordData[type_record][type_day], value)
end

function NewRecord:insertCacheRecordData( type_day,type_record ,value )
	local data = self.cacheData[type_record]
	if not data[type_day] then
		self.cacheData[type_record][type_day] = {}
	end
	table.insert( self.cacheData[type_record][type_day], value)
end

function NewRecord:getRecordData( index )
	local recrodData = self.recordData[self.recordType]
	local dayData    = recrodData[self.dayType]
	return dayData[index]
end

function NewRecord:getEndMainID( ... )
	local recrodData = self.recordData[self.recordType][self.dayType]
	local endData = recrodData[#recrodData]
	return endData
end


function NewRecord:reloadData( )
	self.listView:reloadData()
end

function NewRecord:setColor( text,value )
	if value < 0 then
		self:setScoreColor(text,2)
	else
		self:setScoreColor(text,0)
	end
	text:setString(value)
end

function NewRecord:setStrColor( text,value,str )
	if value < 0 then
		self:setScoreColor(text,2)
	else
		self:setScoreColor(text,0)
	end
	text:setString(value .. str)
end


function NewRecord:setScoreColor( text,type )
	if not text then
		return
	end
	if type == 0 then --正分数
		text:setColor(cc.c3b(124,164,46))
	elseif type == 1 then --0
		text:setColor(cc.c3b(231,0,0))
	elseif type == 2 then  --负分数
		text:setColor(cc.c3b(210,86,31))
	elseif type == 3 then --标题
		text:setColor(cc.c3b(109,58,44))
	end
end

---update--
function NewRecord:_itemUpdateCall( index,item)
	if not item then
		item = self.Image_template:clone()
		item:setPosition(self.cellSize.width / 2,self.cellSize.height / 2)
		local Button_detail 	 = self:seekWidgetByNameEx(item,'Button_detail')
		self:addButtonEventListener(Button_detail,handler(self,self.clickDetail),true)
	end
	self:updateChildItem(item,index)


	return item
end

function NewRecord:updateChildItem( item,index )
	local Text_roomid             = self:seekWidgetByNameEx(item,'Text_roomid')
	local Text_name				  = self:seekWidgetByNameEx(item,'Text_name')
	local Text_round			  = self:seekWidgetByNameEx(item,'Text_round')
	local Text_time				  = self:seekWidgetByNameEx(item,'Text_time')
	local Button_detail 	 	  = self:seekWidgetByNameEx(item,'Button_detail')
	local data 					  = self:getRecordData(index+1)
	Button_detail.index = index+1
	Button_detail.szMainGameID = data.szMainGameID
	Button_detail.wKindID = data.wKindID
	self:setScoreColor(Text_roomid,3)
	self:setScoreColor(Text_name,3)
	self:setScoreColor(Text_round,3)
	self:setScoreColor(Text_time,3)
	local tableID = data.wServerID * 1000 + data.wTableID
	Text_roomid:setString(tableID .. '房间')
	local gameData = StaticData.Games[data.wKindID]
	if gameData then
		gameData = gameData.name
	end
	Text_name:setString(gameData or '')
	Text_round:setString(data.wPlayCount .. "/" .. data.wGameCount .. '局')
	local y, m, d, h, mi, s = Common:getYMDHMS(data.dwPlayTimeStart+data.dwPlayTimeCount)
	local time = string.format("%d-%02d-%02d %02d:%02d:%02d", y, m, d, h, mi, s)
	Text_time:setString(time)
	self:updateNameItem(item,data)
	if not tolua.isnull(self.oldTips) then
		self.oldTips:removeFromParent()
	end
end

function NewRecord:checkReq( dt )
	if self:isBottom() then
		if self.reqState[self.recordType][self.dayType] == 1 then
			self.reqState[self.recordType][self.dayType] = 0
			if self.recordType == RECORD_TYPE.PERSON_RECORD then --个人场
				local main = self:getEndMainID()
				if main then
					print('----分页请求个人')
					UserData.Record:sendMsgGetMainRecord(0, 0, MAX_ITEM, tostring(main.szMainGameID),UserData.User.userID,self.dayType) --普通场
				end
			elseif self.recordType == RECORD_TYPE.CLUB_RECORD then --普通房
				local main = self:getEndMainID()
				if main then
					print('----分页请求普通房')
					UserData.Record:sendMsgGetMainRecord(1, 0, MAX_ITEM, tostring(main.szMainGameID),UserData.User.userID,self.dayType) ----普通场
				end 
			end
		end
	end
end

--更新名字显示
function NewRecord:updateNameItem( item,data )
	local count = 0
	local target = nil
	local t_4 = self:seekWidgetByNameEx(item,'Panel_4')
	local t_8 = self:seekWidgetByNameEx(item,'Panel_8')
	t_4:setVisible(false)
	t_8:setVisible(false)
	target = t_4
	for i=1,8 do
		local isHave = data.dwUserIDEx[i] ~= 0
		if isHave then
			count = count+1
		end
	end

	if count > 4 then
		count = 8 --多人场
		target = t_8
	else
		count = 4
	end
	target:setVisible(true)
	for i=1,count do
		local name_player = target:getChildByName('Image_' .. i)
		local text_playername = name_player:getChildByName('Text_playername')
		local text_score = name_player:getChildByName('Text_score')
		local Panel_click = name_player:getChildByName('Panel_click')
		local userID = data.dwUserIDEx[i]
		local isHave = userID ~= 0
		name_player:setVisible(isHave)
		if isHave then
			local name = Common:getShortName(data.szNickNameEx[i], 9, 8)
			if count == 4 then
				name = Common:getShortName(data.szNickNameEx[i], 9, 6)
			end
			self:addLayerEventListener(Panel_click,handler(self,self.showClickName))
			Panel_click.name = data.szNickNameEx[i]
			Panel_click:setSwallowTouches(false)
			text_playername:setString(name)
			self:setScoreColor(text_playername,3)
			self:setColor(text_score,data.lScoreEx[i])
		end
	end
end

--type==0 普通场 1 个人俱乐部
function NewRecord:updateTotalScore( today,another,eve )
	self:setColor(self.allStatics[1],today)
	self:setColor(self.allStatics[2],another)
	self:setColor(self.allStatics[3],eve)
end

function NewRecord:showClickName( sender,state )
	if state == 'began' then
		self:showTips(sender)
	elseif state == 'end' or state == 'moved' then
		
	end
end

function NewRecord:showTips( sender )
	sender:removeAllChildren()
	if not tolua.isnull(self.oldTips) then
		self.oldTips:removeFromParent()
	end
	local item = self.Image_name_template:clone()
	local cs = sender:getContentSize()
	sender:addChild(item,200)
	item:setPosition(cc.p(cs.width / 2,cs.height+40))
	local childName = self:seekWidgetByNameEx(item,'Text_name')
	childName:setString(sender.name or '')
	local contentSize = childName:getContentSize()
	local size = item:getContentSize()
	if contentSize.width <= 50 then
		contentSize.width = 50
	end
	item:setContentSize(cc.size(contentSize.width+30,size.height))
	self.oldTips = item
	performWithDelay(self.csb,function ()
		if not tolua.isnull(item) then
			item:removeFromParent()
		end
	end,2)
end

function NewRecord:clickDetail( sender )
	local index = sender.index
	self:changePage(Page_State.DETAIL_PAGE)
	self.ListView_details:removeAllChildren()
	self.wKindID = sender.wKindID
	self.szMainGameID = sender.szMainGameID
	self.totalScore = {}
	UserData.Record:sendMsgGetSubRecord(sender.szMainGameID)
end

function NewRecord:isBottom(  )
	if not self.recordData[self.recordType][self.dayType] 
	   or #self.recordData[self.recordType][self.dayType] <= 0  then
		return false
	end
	local curX = self.listView:getContentOffset().y --当前的偏移值
	return curX > -2
end

-------server
--普通场
function NewRecord:RET_CL_MAIN_RECORD_BY_TYPE0( event )
	local data = event._usedata
	local lDay = self:getLoaclByServerTime(data.dwPlayTimeStart)
	self:insertCacheRecordData(lDay,RECORD_TYPE.PERSON_RECORD,data)
end

--==============================--
--desc: 亲友圈场
--time:2018-07-26 03:38:23
--==============================--
function NewRecord:RET_CL_MAIN_RECORD_BY_TYPE1(event)
	local data = event._usedata
	local lDay = self:getLoaclByServerTime(data.dwPlayTimeStart)
	self:insertCacheRecordData(lDay,RECORD_TYPE.CLUB_RECORD,data)
end

--请求结束
function NewRecord:SUB_CL_MAIN_RECORD_FINISH(event)
	local data = event._usedata
	local lType = self:getLocalTypeRecord(data.cbType)
	local lDay = self:getLoalTypeDay(data.cbDay)
	print(data.cbDay,lDay,lType)
	if not data.isFinish then
		self.reqState[self.recordType][self.dayType] = 1
	else
		self.reqState[self.recordType][self.dayType] = 2
	end
	if self.cacheData[lType][lDay] then
		print('-->>>插入',lDay)
		local count = #self.cacheData[lType][lDay]
		for _,v in ipairs(self.cacheData[lType][lDay]) do
			self:insertRecordData(lDay,lType,v)
		end
		self.cacheData[lType][lDay] = {}
		print('结束协议')
		--当前位置刷新数据
		local point = self.listView:getContentOffset()
		self:reloadData()
		if self.isCanBottom then
			self.listView:setContentOffset(cc.p(0,-point.y-count * (180 - 2)), false)
		end
		self.isCanBottom = true
	end
end

--总战绩分刷新
function NewRecord:RET_CL_MAIN_RECORD_TOTAL_SCORE( event )
	local data = event._usedata
	self:updateTotalScore(data.lScore[0],data.lScore[1],data.lScore[2])
end

function NewRecord:SUB_CL_SUB_RECORD( event )
	local data = event._usedata
	self:createSubRecord(data)
end

function NewRecord:SUB_CL_SUB_REPLAY_SHAREID(event)
	local param = event._usedata
	local data = clone(UserData.Share.tableShareParameter[5])
	data.cbTargetType = 2
	data.szShareTitle = string.format(data.szShareTitle, StaticData.Games[self.wKindID].name, param.szShareID)
	data.szShareUrl = string.format("%s&Account=%s&channelID=%d", data.szShareUrl, UserData.User.szAccount, CHANNEL_ID)
	UserData.Share:doShare(data)
end

function NewRecord:SUB_CL_SUB_REPLAY(event)
	local data = event._usedata
	self:enterGameRePlay(data)
end

function NewRecord:SUB_CL_SUB_SHARE_REPLAY_DATA(event)
	local data = event._usedata
	self.wKindID = data[1].wKindID
	self:enterGameRePlay(data)
end

function NewRecord:enterGameRePlay(data)
	local tableConfig = {}
	tableConfig.wTbaleID = 0
	tableConfig.bGameStart = 0
	tableConfig.wKindID = self.wKindID
	tableConfig.nTableType = TableType_Playback
	tableConfig.dwUserID = UserData.User.userID
	tableConfig.dwClubID = 0
	tableConfig.cbLevel = 0
	tableConfig.wCellScore = 0
	tableConfig.wTableNumber = 0
	tableConfig.wCurrentNumber = 0
	if StaticData.Games[self.wKindID].luaGameFile then
		require("common.SceneMgr"):switchScene(require(StaticData.Games[self.wKindID].luaGameFile):create(UserData.User.userID, tableConfig, data), SCENE_GAME)
	else
		print('===========>>>未配置回放脚本，查看Games')
	end
end

return NewRecord

