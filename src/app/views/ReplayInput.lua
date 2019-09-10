---------------
--   回放输入
---------------
local Bit = require("common.Bit")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local ReplayInput = class("ReplayInput", cc.load("mvc").ViewBase)

function ReplayInput:onConfig( ... )
    self.widget = {
        {'Button_return','onClose'}
    }
end

function ReplayInput:onEnter( ... )
 
end

function ReplayInput:onExit( ... )
  
end

function ReplayInput:onCreate( params )
    self.inputText = {}
    local Panel_btnNum = self:seekWidgetByNameEx(self.csb,'Panel_btnNum')
    for i=0,11 do
        local btn = self:seekWidgetByNameEx(Panel_btnNum,'Button_num' ..i)
        self:addButtonEventListener(btn,handler(self,self.clickNumbBtn))
    end
    for i=1,6 do
        local numb = self:seekWidgetByNameEx(self.csb,'AtlasLabel_number' .. i)
        self.inputText[i] = numb
    end
    self.inputValue = {}
end

function ReplayInput:clickNumbBtn( sender )
    local name = sender:getName()

    if name == 'Button_num10' then --重新输入
        self.inputValue = {}
    elseif name == 'Button_num11' then -- 删除
        table.remove( self.inputValue, #self.inputValue)
    else
        local num = string.sub(name, string.len(name), string.len(name)) 
        if #self.inputValue < 6 then
            table.insert( self.inputValue,tonumber(num))
            if #self.inputValue == 6 then
                self:callReplayGame()
            end
        end
    end
    self:updateUI()
end

function ReplayInput:callReplayGame( ... )
    local str = ''
    for i=1,6 do
        str = str .. self.inputValue[i] or ''
    end
    UserData.Record:sendMsgGetMainShare(str)   
end

function ReplayInput:updateUI( ... )
    for i=1,6 do
        local str = self.inputText[i]
        local value = self.inputValue[i]
        if not value then
            value = ''
        end
        str:setString(value)
    end
end

function ReplayInput:addButtonEventListener(button, callback)
	if button then
		button:setPressedActionEnabled(true)
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

function ReplayInput:onClose( ... )
    self:removeFromParent()
end


return ReplayInput