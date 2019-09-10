--[[
*名称:NewClubInputFatigueLayer
*描述:设置疲劳值输入框
*作者:admin
*创建日期:2019-4-2 14:30:52
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

local NewClubInputFatigueLayer = class("NewClubInputFatigueLayer", cc.load("mvc").ViewBase)

function NewClubInputFatigueLayer:onConfig()
    self.widget         = {
        {"Image_frame"},
        {"Text_user_info"},
        {"Text_flag"},
        {"Button_yes", "onYes"},
        {"Panel_btnNum"},
        {"Image_input"},
    }
end

function NewClubInputFatigueLayer:onEnter()
end

function NewClubInputFatigueLayer:onExit()
end

function NewClubInputFatigueLayer:onCreate(param)
    self.data = param[1]
    self.flag = param[2]
    self.callback = param[3]

    if self.flag == 1 then
        self.Text_user_info:setString(string.format('%s ID:%d 疲劳值:%d', self.data.name, self.data.userID, self.data.fatigue))
        self.Text_flag:setString('加')
    elseif self.flag == 2 then
        self.Text_user_info:setString(string.format('%s ID:%d 疲劳值:%d', self.data.name, self.data.userID, self.data.fatigue))
        self.Text_flag:setString('减')
    elseif self.flag == 3 then
        self.Text_flag:setVisible(false)
        if self.data == 0 then
            self.Text_user_info:setVisible(false)
        else
            self.Text_user_info:setString('元宝最低限度：' .. self.data .. ' (输入数量必须从小到大)')
        end
    end

	self:initNumberArea()
	Common:registerScriptMask(self.Image_frame, function()
		self:removeFromParent()
	end)
end

function NewClubInputFatigueLayer:onYes()
	local roomNumber = ""
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_input, numName)
        if Text_number:getString() ~= "" then
            roomNumber = roomNumber .. Text_number:getString()
        end
    end

    local inputVal = tonumber(roomNumber) or 0
    if self.flag == 3 and self.data > inputVal then
        require("common.MsgBoxLayer"):create(0,nil,"输入数量应大于最低值!")
        return
    end

    self.callback(inputVal)
    self:removeFromParent()
end


------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function NewClubInputFatigueLayer:initNumberArea()
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
        local Button_num = ccui.Helper:seekWidgetByName(self.Panel_btnNum, btnName)
        Button_num:setPressedActionEnabled(true)
        Button_num:addTouchEventListener(onEventInput)
        Button_num.index = i
    end
end

--重置数字
function NewClubInputFatigueLayer:resetNumber()
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_input, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
end

--输入数字
function NewClubInputFatigueLayer:inputNumber(num)
    local roomNumber = ""
    for i = 1 , 8 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_input, numName)
        if Text_number:getString() == "" then
            Text_number:setString(tostring(num))
            roomNumber = roomNumber .. Text_number:getString()
            if i == 8 then
                -- UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
            end
            break
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
end

--删除数字
function NewClubInputFatigueLayer:deleteNumber()
    for i = 8 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_input, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            break
        end
    end
end


return NewClubInputFatigueLayer