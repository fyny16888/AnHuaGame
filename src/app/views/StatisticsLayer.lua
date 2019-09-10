local EventMgr			= require("common.EventMgr")
local EventType			= require("common.EventType")
local NetMgr			= require("common.NetMgr")
local NetMsgId			= require("common.NetMsgId")
local StaticData		= require("app.static.StaticData")
local UserData			= require("app.user.UserData")
local Common			= require("common.Common")
local Default			= require("common.Default")
local GameConfig		= require("common.GameConfig")
local Log				= require("common.Log")
local HttpUrl			= require("common.HttpUrl")

local StatisticsLayer = class("StatisticsLayer", cc.load("mvc").ViewBase)
local MEMBER_NUM = 7
local STAITSTICS = {
    PLAY_STATICS = 1,
    DAY_STATICS = 2
}

local ChildStatics = {
    None = 0,
    DYJ_STATICS = 1,--大赢家场次
    JF_STATICS = 2,--积分场次
    ALL_STATICS = 3,--全部场次
    WZ_STATICS=4,--完整场次
}

function StatisticsLayer:onConfig()
    self.widget = {
        {'Panel_player_statics'},
        {'Panel_player_day_statics'},
        {'Button_search','onSearch'},
        {'manager'},
        {'personal'},
        {'Button_up','onBeforDay'},
        {'Button_bottom','onBottomDay'},
        {'Button_all','onAllDay'},
        {'Text_day'},
        {'Image_total'},
        {'Panel_day_template'},
        {'Panel_player_template'},
        {'Image_left','onShowTime'},
        {'Image_right','onShowTime'},
        {'Text_day_left'},
        {'Text_day_right'},
        {'Panel_template'},
        {'ListView_personal'},
        {'TextField_minscore'},
        {'ListView_all'},
    }
end

function StatisticsLayer:onEnter()
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_MYSELF,self,self.RET_GET_CLUB_STATISTICS_MYSELF)
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_ALL,self,self.RET_GET_CLUB_STATISTICS_ALL)
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_MEMBER,self,self.RET_GET_CLUB_STATISTICS_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_MEMBER_FINISH,self,self.RET_GET_CLUB_STATISTICS_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS,self,self.RET_GET_CLUB_STATISTICS)
    
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_FINISH,self,self.RET_GET_CLUB_STATISTICS_FINISH)
    
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_MYSELF_FINISH,self,self.RET_GET_CLUB_STATISTICS_MYSELF_FINISH)
    
end

function StatisticsLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_MYSELF,self,self.RET_GET_CLUB_STATISTICS_MYSELF)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_ALL,self,self.RET_GET_CLUB_STATISTICS_ALL)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_MEMBER,self,self.RET_GET_CLUB_STATISTICS_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_MEMBER_FINISH,self,self.RET_GET_CLUB_STATISTICS_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS,self,self.RET_GET_CLUB_STATISTICS)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_FINISH,self,self.RET_GET_CLUB_STATISTICS_FINISH)

    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_MYSELF_FINISH,self,self.RET_GET_CLUB_STATISTICS_MYSELF_FINISH)
end

function StatisticsLayer:onCreate(params)
    self.clubData = params[1]
    self.isAdmin = params[2]
    self.pageSate  = STAITSTICS.PLAY_STATICS
    self.childPage = ChildStatics.None 
    self.day_reqState   = 0 --每日统计状态
    self.play_reqState  = 0 --玩家统计状态
    self.searchNum  =  0
    self.managerPage = 1
    self.rankID = 0
    self.bsortType = 0 --排序规则
    self.clubPage = 1
    self.stamp =  self:dateChange( os.time(),0) --时间戳
    self.isReqDay = false
    self.leftStamp = Common:getStampDay(os.time() ,true) --服务器
    self.rightStamp = Common:getStampDay(os.time() ,false) --服务器
    self.allButonPanel = {}
    self.childButtonPanelSize = {} --大小
    self.isPersonReqComp = false

    self.personalTotal = {0,0,0,0}

    self.reqTotal = false;

    self:updateToday(self.stamp)  
    self:initUI()
    self:createToggleButton(2,'Button_player_',handler(self,self.onClickToggleRecord),1)
    --注册子节点按钮事件
    self:createToggleButton(4,'Button_child',handler(self,self.onClickChildToggle),-1)
    --注册子button panel
    self:registerButtonPanel('ListView_child_1',STAITSTICS.PLAY_STATICS)
    self:checkPanel()
    self:updateButtonLayout(STAITSTICS.PLAY_STATICS)
end

function StatisticsLayer:createToggleButton(perssCount,buttonName,callFunc,defoutCallNum)
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

function StatisticsLayer:registerButtonPanel( name,state )
    local panelStatics = self:seekWidgetByNameEx(self.csb,name)
    if panelStatics then
        self.allButonPanel[state] = panelStatics
        self.childButtonPanelSize[state] = panelStatics:getContentSize()
        panelStatics:setContentSize(cc.size(0,0))
        panelStatics:setVisible(false)

    end
end

--更新按钮布局
function StatisticsLayer:updateButtonLayout( pageState )
    --收所有子节点

    for k,v in pairs(self.allButonPanel) do
        local size = self.childButtonPanelSize[k]
        v:setContentSize(cc.size(0,0))
        v:setVisible(false)
    end

    if self.allButonPanel[pageState] then
        local size = self.childButtonPanelSize[pageState]
        self.allButonPanel[pageState]:setContentSize(size)
        self.allButonPanel[pageState]:setVisible(true)
    end
    self.ListView_all:refreshView()
    if self.allButonPanel[pageState] then
        self.allButonPanel[pageState]:refreshView()
    end

end

function StatisticsLayer:initUI()
    --每日统计
    self.day_list = self:seekWidgetByNameEx(self.Panel_player_day_statics,'ListView_child')
    --玩家统计
    self.play_list = self:seekWidgetByNameEx(self.Panel_player_statics,'ListView_child')

    self.day_list:addScrollViewEventListener(handler(self, self.day_list_event))
    self.play_list:addScrollViewEventListener(handler(self, self.player_list_event))
    self.Image_left:setSwallowTouches(false)
    self.Image_right:setSwallowTouches(false)
    self:updateInputStr()
    self.Image_total:setVisible(false)
    self.TextField_minscore:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    self.TextField_minscore:setString('0')
end

function StatisticsLayer:onClickChildToggle( sender )
    if sender.isClick then
		return
    end
	sender:ToggleState(false)
	if self.childTopToggle then
		self.childTopToggle:ToggleState(true)
		self.childTopToggle.isClick = false
	end
	self.childTopToggle = sender
    self.childTopToggle.isClick = true
    local name = sender:getName()
    if name == 'Button_child1' then
        self.childPage = ChildStatics.DYJ_STATICS
    elseif name == 'Button_child2' then
        self.childPage = ChildStatics.JF_STATICS
    elseif name == 'Button_child3' then
        self.childPage = ChildStatics.ALL_STATICS
    elseif name == 'Button_child4' then
        self.childPage = ChildStatics.WZ_STATICS
    end
	print('点击了',sender:getName())
end

function StatisticsLayer:onClickToggleRecord( sender )
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
    local name = sender:getName()
    if name == 'Button_player_1' then
        self.pageSate = STAITSTICS.PLAY_STATICS
    elseif name == 'Button_player_2' then
        self.pageSate = STAITSTICS.DAY_STATICS
    end
    self:updateButtonLayout(self.pageSate)
    self:showPage()
	print('点击了',sender:getName())
end

function StatisticsLayer:showPage()
    self.Panel_player_statics:setVisible(self.pageSate == STAITSTICS.PLAY_STATICS)
    self.Panel_player_day_statics:setVisible(self.pageSate == STAITSTICS.DAY_STATICS)
end

function StatisticsLayer:checkPanel()
    self.manager:setVisible(self.isAdmin)
    self.personal:setVisible(not self.isAdmin)
end

----------------个人统计-------------
function StatisticsLayer:addButtonEventListener(button, callback,isAction)
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
--update---

local function SetPersonProperty( text ,value)
    if text then
        text:setColor(cc.c3b(127,90,46))
        text:setString(value)
    end
end

--个人统计更新
function StatisticsLayer:updateOneLayer(data)
    local item = self.Panel_template:clone()
    
    local wf = self:seekWidgetByNameEx(item,'Text_statics_1')
    local all = self:seekWidgetByNameEx(item,'Text_statics_2')
    local bigwinner = self:seekWidgetByNameEx(item,'Text_statics_3')
    local comp = self:seekWidgetByNameEx(item,'Text_statics_4')
    local score = self:seekWidgetByNameEx(item,'Text_statics_5')

    local game = StaticData.Games[data.wKindID]
    if game then
        SetPersonProperty(wf,game.name)
    else
        SetPersonProperty(wf,'')
    end


    SetPersonProperty(all,data.dwGameCount)
    SetPersonProperty(bigwinner,data.dwWinnerCount)
    SetPersonProperty(comp,data.dwCompleteGameCount)
    SetPersonProperty(score,data.lScore)
    self.ListView_personal:pushBackCustomItem(item)
    self.ListView_personal:refreshView()
    self.personalTotal[1] = self.personalTotal[1] + data.dwGameCount
    self.personalTotal[2] = self.personalTotal[2] + data.dwWinnerCount
    self.personalTotal[3] = self.personalTotal[3] + data.dwCompleteGameCount
    self.personalTotal[4] = self.personalTotal[4] + data.lScore
end

function StatisticsLayer:updateTotal( )
    local count = self.ListView_personal:getChildrenCount()
    self.Image_total:setVisible(count > 0)
    if count > 0 then
        local all = self:seekWidgetByNameEx(self.Image_total,'Text_statics_2')
        local bigwinner = self:seekWidgetByNameEx(self.Image_total,'Text_statics_3')
        local comp = self:seekWidgetByNameEx(self.Image_total,'Text_statics_4')
        local score = self:seekWidgetByNameEx(self.Image_total,'Text_statics_5')
        all:setString(self.personalTotal[1])
        bigwinner:setString(self.personalTotal[2])
        comp:setString(self.personalTotal[3])
        score:setString(self.personalTotal[4])
    end
end

--更新今日显示
function StatisticsLayer:updateToday(time)
    local str = self:getFrmatYear(time)
    self.Text_day:setString(str)
end

function StatisticsLayer:getFrmatYear( time )
    return  (os.date('%Y',time).."-" .. os.date('%m',time).."-"..os.date('%d',time))
end

--更新输入的时间显示
function StatisticsLayer:updateInputStr(  )
    local leftTime = self:getFrmatYear(self.leftStamp)
    local rightTime = self:getFrmatYear(self.rightStamp)
    self.Text_day_left:setString(leftTime)
    self.Text_day_right:setString(rightTime)    
end

--计算前一天,后一天日期
function StatisticsLayer:dateChange(stamp,dayChange)
    local year,month,day = Common:getYMDHMS(stamp)
    local time=os.time({year=year, month=month, day=day})+dayChange*86400 --一天86400秒
    return time
end

function StatisticsLayer:getTimeByYMD(year,month,day,isBefore)
    if isBefore then
        local time=os.time({year=year, month=month, day=day})-1*86400 --一天86400秒
        local _year,_month,_day = Common:getYMDHMS(time)
        return os.time({day=_day, month=_month, year=_year, hour=23, min=59, sec=59})
    else
        return os.time({day=day, month=month, year=year, hour=23, min=59, sec=59})
    end
end

function StatisticsLayer:onSearch()

    if self.pageSate == STAITSTICS.DAY_STATICS
       or self.childPage ~= ChildStatics.None then
        if self.searchNum == 0 then
            self.searchNum = 8
            --查询
            self:research()
            schedule(self.Button_search,function()
                self.searchNum = self.searchNum - 1
                if self.searchNum <= 0 then
                    self.searchNum = 0
                    self.Button_search:stopAllActions()
                end
            end,1)
        else
            require("common.MsgBoxLayer"):create(0,self,self.searchNum .. "秒之后查询")
        end
    end

end

local function isNumber(str )
    return  tonumber(str) ~= nil and string.len( str ) >= 1
end


--开始查询
function StatisticsLayer:research(  )
    self:resetPlayManager()
    self:resetDayManager()
    --请求各个子页签数据
    if self.pageSate == STAITSTICS.PLAY_STATICS then
        if self.childPage == ChildStatics.DYJ_STATICS then
            self.bsortType = 0
            self.rankID = 0
            self:req_player()
        elseif self.childPage == ChildStatics.ALL_STATICS then
            self.bsortType = 1
            self.rankID = 0
            self:req_player()
        elseif self.childPage == ChildStatics.JF_STATICS then
            self.bsortType = 3
            self.rankID = 0
            self:req_player()
        elseif self.childPage == ChildStatics.WZ_STATICS then
            self.bsortType = 2
            self.rankID = 0
            self:req_player()
        end
        if self.childPage ~= ChildStatics.None then
            self:req_statisticsManager()
        end
    elseif self.pageSate == STAITSTICS.DAY_STATICS then
        self:req_clubStatics() --每日统计
        self:req_statisticsManager()
    end
    
end

local function getMinScore( score )
    local minScore = tonumber(score)
    minScore = (minScore == nil) and 0 or minScore
    return minScore
end

function StatisticsLayer:req_player( )
    local beginTime = self.leftStamp
    local endTime   = self.rightStamp
    local textScore = self.TextField_minscore:getString()
    local minScore = getMinScore(textScore)
    UserData.Statistics:req_playerManager(self.clubData.dwClubID,beginTime,endTime,self.managerPage,minScore,self.bsortType)
end

function StatisticsLayer:req_clubStatics()
    local beginTime = self.leftStamp
    local endTime   = self.rightStamp
    UserData.Statistics:req_dayManager(self.clubData.dwClubID, beginTime,endTime,self.clubPage)
end

--每日统计
function StatisticsLayer:resetDayManager( ... )
    self.clubPage = 1
    self.day_list:removeAllChildren()
    self.day_reqState = 0
end

--玩家统计
function StatisticsLayer:resetPlayManager( ... )
    self.managerPage = 1
    self.play_list:removeAllChildren()
    self.play_reqState = 0
end

--all 查询全部场次对局占比的
function StatisticsLayer:req_statisticsManager(  )
    local beginTime = self.leftStamp
    local endTime   = self.rightStamp
    UserData.Statistics:req_statisticsManager(self.clubData.dwClubID, beginTime,endTime)
end

function StatisticsLayer:onBeforDay()
    if not self.isPersonReqComp then --个人请求完成
        return
    end
    self.ListView_personal:removeAllChildren()
    self.personalTotal = {0,0,0,0}
    self.stamp = self:dateChange(self.stamp,-1) --时间戳
    self:updateToday(self.stamp)
    self:reqMyself()
end

function StatisticsLayer:onBottomDay()
    if not self.isPersonReqComp then --个人请求完成
        return
    end
    self.ListView_personal:removeAllChildren()
    self.personalTotal = {0,0,0,0}
    self.stamp = self:dateChange(self.stamp,1) --时间戳
    self:updateToday(self.stamp)
    self:reqMyself()
end

function StatisticsLayer:onAllDay()
    if not self.isPersonReqComp then --个人请求完成
        return
    end
    self.ListView_personal:removeAllChildren()
    self.personalTotal = {0,0,0,0}
    self.stamp =  self:dateChange( os.time(),0) --时间戳
    self:updateToday(self.stamp)
    self:reqMyself()
end

function StatisticsLayer:onShowTime( sender )
    local name = sender:getName()
    if name == 'Image_left' then
        local timeNode = require("app.MyApp"):create(self.leftStamp,handler(self,self.leftNodeChange)):createView("TimeNode")
        self.Image_left:addChild(timeNode)
        timeNode:setPosition(80,-90)
    elseif name == 'Image_right' then
        local timeNode = require("app.MyApp"):create(self.rightStamp,handler(self,self.rightNodeChange)):createView("TimeNode")
        self.Image_right:addChild(timeNode)
        timeNode:setPosition(80,-90)
    end
end

--请求俱乐部个人统计
function StatisticsLayer:reqMyself()

    if not self.isAdmin then
        --UserData.Statistics:req_statisticsMyself(self.clubData.dwClubID,self.stamp,UserData.User.userID)
    end
end

function StatisticsLayer:RET_GET_CLUB_STATISTICS_MYSELF(event)
    local data = event._usedata
    dump(data,'fx----------个人统计---->>')
    self:updateOneLayer(data)
end

function StatisticsLayer:RET_GET_CLUB_STATISTICS_MYSELF_FINISH(event)
    local data = event._usedata
    self.isPersonReqComp = data.isFinish
    if data.isFinish then
        self:updateTotal()
    end
    print('=====================personal is over:',self.isPersonReqComp)
end

---------------------管理员统计---------------------------


function StatisticsLayer:updateManagerTop( data )
    dump(data,'fx-------------->>')
--玩家统计
    --全部场次
    local _t1 = self:seekWidgetByNameEx(self.Panel_player_statics,'Text_1')
    local num_t1 = self:seekWidgetByNameEx(_t1,'Text_num')
    num_t1:setString(data.dwGameCount)
    --总消耗
    local _t2 = self:seekWidgetByNameEx(self.Panel_player_statics,'Text_2')
    local num_t2 = self:seekWidgetByNameEx(_t2,'Text_num')
    num_t2:setString(data.dwRoomCard)

    --大赢家总数
    local _t3 = self:seekWidgetByNameEx(self.Panel_player_statics,'Text_3')
    local num_t3 = self:seekWidgetByNameEx(_t3,'Text_num')
    num_t3:setString(data.dwWinnerCount)

--每日统计
    --玩家总数
    local _t1_player = self:seekWidgetByNameEx(self.Panel_player_day_statics,'Text_1')
    local _t1_player_num = self:seekWidgetByNameEx(_t1_player,'Text_num')
    _t1_player_num:setString(data.dwMemberCount)
    --新增
    local _t2_player = self:seekWidgetByNameEx(self.Panel_player_day_statics,'Text_2')
    local _t2_player_num = self:seekWidgetByNameEx(_t2_player,'Text_num')
    _t2_player_num:setString(data.dwDNU)
    --对局占比：
    local _t3_player = self:seekWidgetByNameEx(self.Panel_player_day_statics,'Text_3')
    local _t3_player_num = self:seekWidgetByNameEx(_t3_player,'Text_num')
    if data.dwAllPeopleCount == 0 then
        _t3_player_num:setString('0%')
    else
        local percent = math.floor(data.dwNewUserGameCount / data.dwAllPeopleCount) * 100
        _t3_player_num:setString(percent .. '%')
    end
   
end

local function SetTextProperty( text ,value)
    if text then
        text:setColor(cc.c3b(127,90,46))
        text:setString(value)
    end
end

local function getGameDes( kind )
    local game = StaticData.Games[kind]
    if game then
       return game.name
    end
    return ''
end

--添加每日统计
function StatisticsLayer:addDailyStatistics( data )
    local item = self.Panel_day_template:clone()

    --日期
    local day           = self:seekWidgetByNameEx(item,'Text_1')
    --玩法一
    local play_1        = self:seekWidgetByNameEx(item,'Text_2')
    local play_2        = self:seekWidgetByNameEx(item,'Text_3')
    local play_3        = self:seekWidgetByNameEx(item,'Text_4')
    local rh_num        = self:seekWidgetByNameEx(item,'Text_5')
    local all_playnum   = self:seekWidgetByNameEx(item,'Text_6')
    local total_cost    = self:seekWidgetByNameEx(item,'Text_7')
    local new_add       = self:seekWidgetByNameEx(item,'Text_add')
    local y,m,d = Common:getYMDHMS(data.dwDayTime)
    SetTextProperty(day, y .. '-' .. m .. '-' .. d)
    SetTextProperty(play_1,data.dwPlayGameCount1)
    SetTextProperty(play_2,data.dwPlayGameCount2)
    SetTextProperty(play_3,data.dwPlayGameCount3)
    SetTextProperty(rh_num,data.dwDAU)
    SetTextProperty(all_playnum,data.dwGameCount)
    SetTextProperty(total_cost,data.dwRoomCard)
    SetTextProperty(new_add,data.dwDNU)
    play_1:setVisible(false)
    play_2:setVisible(false)
    play_3:setVisible(false)

    self.day_list:pushBackCustomItem(item)
    self.day_list:refreshView()
end

--玩家统计
function StatisticsLayer:addPlayerStatistics( data )
    local item = self.Panel_player_template:clone()
    self.rankID = self.rankID + 1
    local Text_name             = self:seekWidgetByNameEx(item,'Text_name')
    local Text_rank             = self:seekWidgetByNameEx(item,'Text_rank')
    --玩法一
    local Text_id               = self:seekWidgetByNameEx(item,'Text_id')
    local Text_big_winner       = self:seekWidgetByNameEx(item,'Text_big_winner')
    local Text_all_comp         = self:seekWidgetByNameEx(item,'Text_all_comp')
    local Text_comp             = self:seekWidgetByNameEx(item,'Text_comp')
    local Text_score            = self:seekWidgetByNameEx(item,'Text_score')
    local Image_avatar          = self:seekWidgetByNameEx(item,'Image_avatar')

    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_avatar, 'img')
    local name = Common:getShortName(data.szNickName,12,6);
    SetTextProperty(Text_name,data.szNickName)
    SetTextProperty(Text_id,data.dwUserID)
    SetTextProperty(Text_big_winner,data.dwWinnerCount)
    SetTextProperty(Text_all_comp,data.dwGameCount)
    SetTextProperty(Text_comp,data.dwCompleteGameCount)
    SetTextProperty(Text_score,data.lScore)
    SetTextProperty(Text_rank,self.rankID)

    self.play_list:pushBackCustomItem(item)
    self.play_list:refreshView()
end

function StatisticsLayer:day_list_event(sender, evenType)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
		if self.day_reqState == 1 then
			self.day_reqState = 0
            self:req_clubStatics()
		end
	end
end

function StatisticsLayer:player_list_event(sender, evenType)
	if evenType == ccui.ScrollviewEventType.scrollToBottom then
		if self.play_reqState == 1 then
			self.play_reqState = 0
            self:req_player()
		end
	end
end

function StatisticsLayer:leftNodeChange( time,stampMin,stampMax )
    self.Text_day_left:setString(time)
    self.leftStamp = stampMin
end

function StatisticsLayer:rightNodeChange( time,stampMin,stampMax )
    self.Text_day_right:setString(time)
    self.rightStamp = stampMax
end

function StatisticsLayer:RET_GET_CLUB_STATISTICS_ALL( event )
    local data = event._usedata
    self:updateManagerTop(data)
end

function StatisticsLayer:RET_GET_CLUB_STATISTICS_MEMBER( event)
    local data = event._usedata
    self:addPlayerStatistics(data)
end

function StatisticsLayer:RET_GET_CLUB_STATISTICS( event)
    local data = event._usedata
    self:addDailyStatistics(data)
end

function StatisticsLayer:RET_GET_CLUB_STATISTICS_MEMBER_FINISH(event)
    local data = event._usedata
	if data.isFinish then
        self.play_reqState = 2 --所有结束
        require("common.MsgBoxLayer"):create(0,self,"没有更多的数据查询")
	else
		self.play_reqState = 1 --本次结束
    end
    self.managerPage = self.managerPage + 1
end

function StatisticsLayer:RET_GET_CLUB_STATISTICS_FINISH(event)
    local data = event._usedata
	if data.isFinish then
        self.day_reqState = 2 --所有结束
        require("common.MsgBoxLayer"):create(0,self,"没有更多的数据查询")
	else
		self.day_reqState = 1 --本次结束
    end
    self.clubPage = self.clubPage + 1
end

return StatisticsLayer

