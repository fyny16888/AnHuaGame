---=========================================---
--des:聊天设置相关
--time:2018-09-30 10:18:49
--author:fu xing
---=========================================---
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

local GroupSettingLayer = class("GroupSettingLayer", cc.load("mvc").ViewBase)

function GroupSettingLayer:onConfig()
    self.widget = {
        {'Button_setting','onSettingCallBack'},
        {'Button_select_hall','onSelectHall'},
        {'Button_select_message','onMessageDisable'},
        {'Button_select_paizuo','onPaiZuoDisable'},
    }
end

function GroupSettingLayer:onEnter()

end

function GroupSettingLayer:onCreate( param )
    self.Group = param[2]
    self:initSelect()
end

function GroupSettingLayer:onExit()

end

function GroupSettingLayer:initSelect( ... )
    self:setSelectState(self.Button_select_hall,true)
    self:setSelectState(self.Button_select_message,false)
    self:setSelectState(self.Button_select_paizuo,false)
end

function GroupSettingLayer:setSelectState( target,isSelect )
    if target then
        local press = self:seekWidgetByNameEx(target,'Image_select')
        press:setVisible(isSelect)
    end
end

--------------------button callBack----
function GroupSettingLayer:onSelectHall( sender)
    self:setSelectState(self.Button_select_hall,true)
end

function GroupSettingLayer:onMessageDisable( sender )
    self:setSelectState(self.Button_select_message,false)
end

function GroupSettingLayer:onPaiZuoDisable( sender )
    self:setSelectState(self.Button_select_paizuo,false)
end

function GroupSettingLayer:onSettingCallBack( ... )
    self.Group:backTo()
end

return GroupSettingLayer