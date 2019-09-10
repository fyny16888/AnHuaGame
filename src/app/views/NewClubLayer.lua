--[[
*名称:NewClubLayer
*描述:亲友圈大厅
*作者:admin
*创建日期:2018-06-13 10:30:52
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

local NewClubLayer      = class("NewClubLayer", cc.load("mvc").ViewBase)

function NewClubLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Image_create", "onSelCreate"},
        {"Image_createLight"},
        {"Image_createFont"},
        {"Image_join", "onSelJoin"},
        {"Image_joinLight"},
        {"Image_joinFont"},
        {"Panel_create"},
        {"TextField_name"},
        {"Button_create","onCreateClub"},
        {"Panel_join"},
        {"ListView_apply"},
        {"Image_item"},
        {"Text_tips"},
        {"Panel_input"},
        {"Button_choice"},
        {"Panel_createBtn", "onSelCreate"},
        {"Panel_joinBtn", "onSelJoin"}
    }
    self.curInputClubID = 0
end

function NewClubLayer:onEnter()
    EventMgr:registListener(EventType.RET_CREATE_CLUB,self,self.RET_CREATE_CLUB)
    EventMgr:registListener(EventType.RET_JOIN_CLUB,self,self.RET_JOIN_CLUB)
    EventMgr:registListener(EventType.RET_ADDED_CLUB,self,self.RET_ADDED_CLUB)
    EventMgr:registListener(EventType.RET_GET_CLUB_APPLICATION_RECORD,self,self.RET_GET_CLUB_APPLICATION_RECORD)
    EventMgr:registListener(EventType.RET_REFUSE_JOIN_CLUB,self,self.RET_REFUSE_JOIN_CLUB)
end

function NewClubLayer:onExit()
    EventMgr:unregistListener(EventType.RET_CREATE_CLUB,self,self.RET_CREATE_CLUB)
    EventMgr:unregistListener(EventType.RET_JOIN_CLUB,self,self.RET_JOIN_CLUB)
    EventMgr:unregistListener(EventType.RET_ADDED_CLUB,self,self.RET_ADDED_CLUB)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_APPLICATION_RECORD,self,self.RET_GET_CLUB_APPLICATION_RECORD)
    EventMgr:unregistListener(EventType.RET_REFUSE_JOIN_CLUB,self,self.RET_REFUSE_JOIN_CLUB)
    self.Image_item:release()
end

function NewClubLayer:onCreate(param)
    self.isOS = PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL

    self:createrInput()
    self:initNumberArea()
    self.Image_item:retain()
    self.ListView_apply:removeAllChildren()
    local stype = param[1] or 2
    --self:switchUI(stype)
    UserData.Guild:getClubApplyInfo(UserData.User.userID)
    if stype == 1 then 
        self:switchUI(1)
    else
        self:switchUI(2)
    end 
end

function NewClubLayer:createrInput( ... )
    self.TextField_name:setVisible(not self.isOS)

    if self.isOS then
        local parent = self.TextField_name:getParent()
        self.TextField_name = ccui.EditBox:create(cc.size(300,50), "chat/newclub/club_27.png")
		self.TextField_name:setPosition(parent:getContentSize().width / 2,parent:getContentSize().height / 2)
		self.TextField_name:setAnchorPoint(cc.p(0.5,0.5))
		self.TextField_name:setFontSize(19)
		self.TextField_name:setPlaceHolder("请输入亲友圈昵称")
		self.TextField_name:setPlaceholderFontSize(19)
		self.TextField_name:setFontColor(cc.c3b(148, 93, 30))
		self.TextField_name:setMaxLength(7)
		self.TextField_name:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		self.TextField_name:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
        self.TextField_name:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
		parent:addChild(self.TextField_name)
    end
    if not self.isOS then
        self.TextField_name:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    end
end

function NewClubLayer:onClose()
    self:removeFromParent()
end

function NewClubLayer:onSelCreate()
    self:switchUI(1)
end

function NewClubLayer:onSelJoin()
    self:switchUI(2)
end

function NewClubLayer:onCreateClub()
    local input = ''
	if self.isOS then
		input = self.TextField_name:getText()
	else
		input = self.TextField_name:getString()
	end
    if input == "" then
        require("common.MsgBoxLayer"):create(0,self,"请输入亲友圈昵称!")
        return
    end
    UserData.Guild:createClub(input)
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
--切换分页
function NewClubLayer:switchUI(stype)
    if stype == 1 then
        self.Panel_create:setVisible(true)
        self.Panel_join:setVisible(false)
        self.Image_createLight:setVisible(true)
        self.Image_createFont:loadTexture("newclub/club_14.png")
        self.Image_joinLight:setVisible(false)
        self.Image_joinFont:loadTexture("newclub/club_15.png")
        self.Button_choice:setBright(true)
    else
        self.Panel_create:setVisible(false)
        self.Panel_join:setVisible(true)
        self.Image_createLight:setVisible(false)
        self.Image_createFont:loadTexture("newclub/club_13.png")
        self.Image_joinLight:setVisible(true)
        self.Image_joinFont:loadTexture("newclub/club_16.png")
        self.Button_choice:setBright(false)
    end
end

function NewClubLayer:initNumberArea()
    self:resetNumber()
    local function onEventInput(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local index = sender.index
            if index == 10 then
                self:resetNumber()
            elseif index == 11 then
                self:deleteNumber()
            else
                self:inputNumber(index)
            end
        end
    end

    for i = 0 , 11 do
        local btnName = string.format("Button_num%d", i)
        local Button_num = ccui.Helper:seekWidgetByName(self.Panel_join, btnName)
        Button_num:setPressedActionEnabled(true)
        Button_num:addTouchEventListener(onEventInput)
        Button_num.index = i
    end
end

--加入亲友圈请求
function NewClubLayer:sendJoinClub(dwClubID)
    self.curInputClubID = tonumber(dwClubID)
    UserData.Guild:joinClub(self.curInputClubID)
end

--重置数字
function NewClubLayer:resetNumber()
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Panel_join, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
    self.Text_tips:setVisible(true)
    self.Panel_input:setVisible(false)
end

--输入数字
function NewClubLayer:inputNumber(num)
    local roomNumber = ""
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Panel_join, numName)
        if Text_number:getString() == "" then
            Text_number:setString(tostring(num))
            roomNumber = roomNumber .. Text_number:getString()
            if i == 6 then  
                self:sendJoinClub(roomNumber)                      
            end
            break
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
    self.Text_tips:setVisible(false)
    self.Panel_input:setVisible(true)
end

--删除数字
function NewClubLayer:deleteNumber()
    for i = 6 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Panel_join, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            if i <= 1 then
                self.Text_tips:setVisible(true)
                self.Panel_input:setVisible(false)
            end
            break
        end
    end
end

--添加一个节点
function NewClubLayer:addOnceApplyItem(data)
    if type(data) ~= 'table' then
        printError('NewClubInfoLayer:addOnceApplyItem data error')
        return
    end
    local item = self.Image_item:clone()
    self.ListView_apply:pushBackCustomItem(item)
    item:setName('apply_clubid_' .. data.dwClubID)
    local Text_time = self:seekWidgetByNameEx(item, "Text_time")
    local Text_clubid = self:seekWidgetByNameEx(item, "Text_clubid")
    local Text_state    = self:seekWidgetByNameEx(item, "Text_state")
    Text_time:setColor(cc.c3b(114, 67, 13))
    Text_clubid:setColor(cc.c3b(114, 67, 13))
    Text_state:setColor(cc.c3b(114, 67, 13))
    local year, month, day, hour, mim, sec = Common:getYMDHMS(data.dwTime)
    local timestr = string.format("时间：%02d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, mim, sec)
    Text_time:setString(timestr)
    Text_clubid:setString('亲友圈ID：' .. data.dwClubID)
    if data.cbState == 0 then
        Text_state:setString('状态：审核中')
    elseif data.cbState == 1 then
        Text_state:setString('状态：已加入')
    elseif data.cbState == 2 then
        Text_state:setString('状态：被拒绝')
    else
        Text_state:setString('未知状态:' .. data.cbState)
    end
end

function NewClubLayer:refreshApplyClubItem(dwClubID, cbState)
    local item = self.ListView_apply:getChildByName('apply_clubid_' .. dwClubID)
    if item then
        local Text_time = self:seekWidgetByNameEx(item, "Text_time")
        local Text_state    = self:seekWidgetByNameEx(item, "Text_state")
        local year, month, day, hour, mim, sec = Common:getYMDHMS(os.time())
        local timestr = string.format("时间：%02d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, mim, sec)
        Text_time:setString(timestr)
        if cbState == 0 then
            Text_state:setString('状态：审核中')
        elseif cbState == 1 then
            Text_state:setString('状态：已加入')
        elseif cbState == 2 then
            Text_state:setString('状态：被拒绝')
        else
            Text_state:setString('未知状态:' .. cbState)
        end
        return true
    end
    return false
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
--创建亲友圈返回
function NewClubLayer:RET_CREATE_CLUB(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"您不是代理不能创建亲友圈!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"请联系代理授权创建亲友圈")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"您的房卡不足100张,不能创建亲友圈!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"您的亲友圈数量已达上线,不能再创建亲友圈!")
        elseif data.lRet == 1001 then
            require("common.MsgBoxLayer"):create(0,nil,"您的房卡不足100张,不能创建亲友圈!")
        elseif data.lRet == 1002 then
            require("common.MsgBoxLayer"):create(0,nil,"您的房卡不足200张,不能创建亲友圈!")
        elseif data.lRet == 1003 then
            require("common.MsgBoxLayer"):create(0,nil,"您的房卡不足300张,不能创建亲友圈!")
        elseif data.lRet == 1004 then
            require("common.MsgBoxLayer"):create(0,nil,"您的房卡不足400张,不能创建亲友圈!")
        elseif data.lRet == 1005 then
            require("common.MsgBoxLayer"):create(0,nil,"您的房卡不足500张,不能创建亲友圈!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"未知错误,请升级版本!")
        end
        return
    end
    self:removeFromParent()
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(data):createView("NewClubInfoLayer"))
end

--加入亲友圈
function NewClubLayer:RET_JOIN_CLUB(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet == 0 then
        if not self:refreshApplyClubItem(self.curInputClubID, 0) then
            local tmpTbl = {}
            tmpTbl.dwTime = os.time()
            tmpTbl.dwClubID = self.curInputClubID
            tmpTbl.cbState = 0
            self:addOnceApplyItem(tmpTbl)
        end
        require("common.MsgBoxLayer"):create(2,nil,"您已经申请加入，请等待群主审核!")
    elseif data.lRet == 1 then 
        require("common.MsgBoxLayer"):create(0,nil,"亲友圈ID输入错误!")
    elseif data.lRet == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"您已经存在该亲友圈,不可重复提交申请!")
    else
        require("common.MsgBoxLayer"):create(0,nil,"申请加入失败,请升级到最新版本!")
    end
end

--被添加亲友圈
function NewClubLayer:RET_ADDED_CLUB(event)
    local data = event._usedata
    Log.d(data)
    self:removeFromParent()
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(data):createView("NewClubInfoLayer"))
end

function NewClubLayer:RET_GET_CLUB_APPLICATION_RECORD(event)
    local data = event._usedata
    Log.d(data)
    self:addOnceApplyItem(data)
end

function NewClubLayer:RET_REFUSE_JOIN_CLUB(event)
    local data = event._usedata
    Log.d(data)
    self:refreshApplyClubItem(data.dwClubID, 2)
end

return NewClubLayer