---------------
--   聊天
---------------
local KwxColor = class("KwxColor", cc.load("mvc").ViewBase)
local GameCommon = require("game.majiang.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local Common = require("common.Common")
function KwxColor:onConfig()
	self.widget = {
        {'Button_close','onClose'},
        {'Button_conform','conformCallFunc'},
	}
end

function KwxColor:onEnter()
end

function KwxColor:onCreate(params)

    self.bgNum = self:getDefaultValue('kwxbg',0);
    self.bgMajiong = self:getDefaultValue('kwxmj',0);
    self:initToggle('Button_bg',1,3,'Image_di',self.bgNum+1,handler(self,self.buttonCall));
    self:initToggle('Button_majiang',1,3,'Image_di',self.bgMajiong+1,handler(self,self.majiangCall));
end

function KwxColor:initToggle( templateStr,minNum,maxNum,selectbgstr,defoutSelect,callFunc)
    if not self[templateStr] then
        self[templateStr] = {};
    end

    local setShowDefout = function ( id )
        for i,v in ipairs(self[templateStr]) do
            v.mask:setVisible(i==id)
        end
    end

    for i=minNum,maxNum do
        local str = templateStr .. i;
        local btn = self:seekWidgetByNameEx(self.csb,str);
        local id = i-1;
        btn.id = id;
        local mask = btn:getChildByName(selectbgstr);
        mask:setVisible(false)
        table.insert( self[templateStr],{btn=btn,mask=mask})
        self:addListener(btn,function (sender)
            setShowDefout(i)
            callFunc(id);
        end);
        if i==defoutSelect then
            setShowDefout(i)
            callFunc(id);
        end
    end
end

function KwxColor:buttonCall(id)
    self.bgNum = id;
end

function KwxColor:majiangCall(id)
    self.bgMajiong = id;
end

function KwxColor:getDefaultValue( key,default )
    return cc.UserDefault:getInstance():getIntegerForKey(key,default)
end

function KwxColor:addListener(btn, callback)
	btn:setPressedActionEnabled(false)
	btn:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			if callback then
				callback(sender)
			end
		end
	end)
end

function KwxColor:conformCallFunc( )
    self:save()
    self:onClose()
end

function KwxColor:save()
    cc.UserDefault:getInstance():setIntegerForKey('kwxmj',self.bgMajiong)
	cc.UserDefault:getInstance():setIntegerForKey('kwxbg',self.bgNum)
end

function KwxColor:onClose( )
	self:removeFromParent()
end


function KwxColor:onExit()
	EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE)
end




return KwxColor 