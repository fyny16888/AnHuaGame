--[[
*名称:NewClubFreeTableLayer
*描述:亲友圈空闲牌桌详情
*作者:admin
*创建日期:2019-04-27 09:12
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
local Log               = require("common.Log")

local NewClubFreeTableLayer = class("NewClubFreeTableLayer", cc.load("mvc").ViewBase)

function NewClubFreeTableLayer:onConfig()
    self.widget         = {
        {"Image_bg"},
        {"ScrollView_table"},
        {"Button_tblItem"},
        {"Panel_returnBtn", 'onReturnBtn'},
    }
    self.clubData = {}
    self.curJoinTable = 0
end

function NewClubFreeTableLayer:onEnter()
	EventMgr:registListener(EventType.RET_REFRESH_CLUB,self,self.RET_REFRESH_CLUB)
	EventMgr:registListener(EventType.RET_REFRESH_CLUB_PLAY,self,self.RET_REFRESH_CLUB_PLAY)
	EventMgr:registListener(EventType.RET_GET_CLUB_TABLE,self,self.RET_GET_CLUB_TABLE)
	EventMgr:registListener(EventType.RET_FREE_CLUB_CHANGE_TABLE_NOTICES,self,self.RET_FREE_CLUB_CHANGE_TABLE_NOTICES)
	EventMgr:registListener(EventType.RET_DISBAND_CLUB_TABLE,self,self.RET_DISBAND_CLUB_TABLE)
	EventMgr:registListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED)
end

function NewClubFreeTableLayer:onExit()
	EventMgr:unregistListener(EventType.RET_REFRESH_CLUB,self,self.RET_REFRESH_CLUB)
	EventMgr:unregistListener(EventType.RET_REFRESH_CLUB_PLAY,self,self.RET_REFRESH_CLUB_PLAY)
	EventMgr:unregistListener(EventType.RET_GET_CLUB_TABLE,self,self.RET_GET_CLUB_TABLE)
	EventMgr:unregistListener(EventType.RET_FREE_CLUB_CHANGE_TABLE_NOTICES,self,self.RET_FREE_CLUB_CHANGE_TABLE_NOTICES)
	EventMgr:unregistListener(EventType.RET_DISBAND_CLUB_TABLE,self,self.RET_DISBAND_CLUB_TABLE)
	EventMgr:unregistListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED)
	UserData.Guild.isChangeClubTable = false
end

function NewClubFreeTableLayer:onCreate(param)
	Log.d(param)
    Common:registerScriptMask(self.Image_bg, function() self:removeFromParent() end)
    self.ScrollView_table:removeAllChildren()
    self.clubData.dwClubID = param[1]
    UserData.Guild:refreshClub(self.clubData.dwClubID)
end

function NewClubFreeTableLayer:onReturnBtn()
    self:removeFromParent()
end

function NewClubFreeTableLayer:isFullPeopleTable(data)
    local num = 0
    for k,v in pairs(data.dwUserID) do
        if v ~= 0 then
            num = num + 1
        end
    end

    if num >= data.wChairCount then
        return true
    end
    return false
end

function NewClubFreeTableLayer:getMoreTableIndex(wplayId)
    for i,v in ipairs(self.clubData.dwPlayID or {}) do
        if v == wplayId then
            return i
        end
    end
    return nil
end

function NewClubFreeTableLayer:getPlayWayNums()
    local num = 0
    for i,v in ipairs(self.clubData.wKindID or {}) do
        local gameinfo = StaticData.Games[v]
        if gameinfo then
            num = num + 1
        end
    end
    return num
end

function NewClubFreeTableLayer:megerClubData(data)
    if type(data) ~= 'table' then
        return
    end
    self.clubData = self.clubData or {}
    for k,v in pairs(data) do
        self.clubData[k] = v
    end
end

function NewClubFreeTableLayer:isAdmin(userid, adminData)
    adminData = adminData or self.clubData.dwAdministratorID
    for i,v in ipairs(adminData or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

---------------------------------------------------
--

function NewClubFreeTableLayer:RET_REFRESH_CLUB(event)
    local data = event._usedata
    Log.d(data)
    self:megerClubData(data)
end

function NewClubFreeTableLayer:RET_REFRESH_CLUB_PLAY(event)
    local data = event._usedata
    Log.d(data)
    self:megerClubData(data)
    UserData.Guild:getClubTable(data.dwClubID)
end

function NewClubFreeTableLayer:RET_GET_CLUB_TABLE(event)
    local data = event._usedata
    Log.d(data)
    if self:isFullPeopleTable(data) or self.clubData.bIsDisable then
    	return
    end

    for i,v in ipairs(data.dwUserID) do
    	if v == UserData.User.userID then
    		return
    	end
    end

    local i = #self.ScrollView_table:getChildren() + 1
    if i > 4 then
    	return
    end

    local inerSize = self.ScrollView_table:getContentSize()
    local scrollW = (inerSize.width / 2) * math.ceil(i / 2)
    self.ScrollView_table:setInnerContainerSize(cc.size(scrollW, inerSize.height))
    local item = self.Button_tblItem:clone()
    self.ScrollView_table:addChild(item)
    item.data = data
    item:setName('free_table_' .. data.dwTableID)
    
    local row = i % 2
    if row == 0 then
        row = 2
    end
    local col = math.ceil(i / 2)
	local x = 120 + (col - 1) * 250
	local y = 220 - (row - 1) * 163
	item:setPosition(x, y)
    
    local Image_tableIdx = ccui.Helper:seekWidgetByName(item,"Image_tableIdx")
    local idx = self:getMoreTableIndex(data.wTableSubType)
    if idx then
        Image_tableIdx:setVisible(true)
        Image_tableIdx:loadTexture(string.format('kwxclub/club_%d.png', 100 + idx))
    else
        Image_tableIdx:setVisible(false)
    end

    local Text_wayName = ccui.Helper:seekWidgetByName(item,"Text_wayName")
    local idx = self:getMoreTableIndex(data.wTableSubType)
    if idx then
        if self.clubData.szParameterName[idx] ~= "" and self.clubData.szParameterName[idx] ~= " " then
            Text_wayName:setString(self.clubData.szParameterName[idx])
        else
            Text_wayName:setString(StaticData.Games[data.wKindID].name)
        end
    else
        Text_wayName:setString(StaticData.Games[data.wKindID].name)
    end

    local Text_turnNum = ccui.Helper:seekWidgetByName(item,"Text_turnNum")
    Text_turnNum:setString('局数:' .. data.wCurrentGameCount .. '/' .. data.wGameCount)

    local playerNum = data.tableParameter.bPlayerCount
    if playerNum == 2 then
        local tableIndex = {1,3}
        for i, var in pairs(tableIndex) do
            local uiPanel_head = ccui.Helper:seekWidgetByName(item,string.format("Panel_head%d",var))
            uiPanel_head:setVisible(true)
            if i <= data.wChairCount and data.dwUserID[i] ~= 0 then
                local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_head,"Image_avatar")
                Common:requestUserAvatar(data.dwUserID[i],data.szLogoInfo[i],uiImage_avatar,"clip")
            else
                local Image_avatar = uiPanel_head:getChildByName('Image_avatar')
                Image_avatar:removeAllChildren()
                Image_avatar:loadTexture('kwxclub/circle_icon_emptyseat.png')
            end
        end
    else
        for i = 1, 3 do
            local uiPanel_head = ccui.Helper:seekWidgetByName(item,string.format("Panel_head%d",i))
            uiPanel_head:setVisible(true)
            if i <= data.wChairCount and data.dwUserID[i] ~= 0 then
                local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_head,"Image_avatar")
                Common:requestUserAvatar(data.dwUserID[i],data.szLogoInfo[i],uiImage_avatar,"clip")
            else
                local Image_avatar = uiPanel_head:getChildByName('Image_avatar')
                Image_avatar:removeAllChildren()
                Image_avatar:loadTexture('kwxclub/circle_icon_emptyseat.png')
            end
        end
    end

    Common:addTouchEventListener(item,function(sender,event)
    	UserData.Guild.isChangeClubTable = true
    	self.curJoinTable = data.dwTableID
    	local isAdmin = false
	    if UserData.User.userID == self.clubData.dwUserID then
	        isAdmin = true
	    end
	    if self:isAdmin(UserData.User.userID) then
	        isAdmin = true
	    end
		self:addChild(require("app.MyApp"):create(item.data, isAdmin):createView("ClubTableLayer"))
    end)
end

function NewClubFreeTableLayer:RET_FREE_CLUB_CHANGE_TABLE_NOTICES()
	require("common.SceneMgr"):switchTips(require("app.MyApp"):create(self.curJoinTable):createView("InterfaceJoinRoomNode"))
end

function NewClubFreeTableLayer:RET_DISBAND_CLUB_TABLE(event)
	local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"解散桌子失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"解散桌子成功!")
    self:removeFromParent()
end

function NewClubFreeTableLayer:SUB_GR_JOIN_TABLE_FAILED()
	self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) 
		require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL)
	end)))
end

return NewClubFreeTableLayer