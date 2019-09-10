---------------
--   聊天
---------------
local KwxPukeColor = class("KwxPukeColor", cc.load("mvc").ViewBase)
local GameCommon = require("game.majiang.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local Common = require("common.Common")
function KwxPukeColor:onConfig()
	self.widget = {
        {'Button_close','onClose'},
        {'Button_conform','conformCallFunc'},
	}
end

function KwxPukeColor:onEnter()
end

function KwxPukeColor:onCreate(params)

    self.bgNum = self:getDefaultValue('PDKBgNum',0);
    self.bgpuke = self:getDefaultValue('PDKSize',0);
    self:initToggle('Button_bg',1,3,'Image_di',self.bgNum+1,handler(self,self.buttonCall));
    self:initToggle('Button_puke',1,2,'Image_di',self.bgpuke+1,handler(self,self.pukeCall));
end

function KwxPukeColor:initToggle( templateStr,minNum,maxNum,selectbgstr,defoutSelect,callFunc)
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

function KwxPukeColor:buttonCall(id)
    self.bgNum = id;
end

function KwxPukeColor:pukeCall(id)
    self.bgpuke = id;
end

function KwxPukeColor:getDefaultValue( key,default )
    return cc.UserDefault:getInstance():getIntegerForKey(key,default)
end

function KwxPukeColor:addListener(btn, callback)
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

function KwxPukeColor:conformCallFunc( )
    self:save()
    self:onClose()
end

function KwxPukeColor:save()
    cc.UserDefault:getInstance():setIntegerForKey('PDKSize',self.bgpuke)
	cc.UserDefault:getInstance():setIntegerForKey('PDKBgNum',self.bgNum)
end

function KwxPukeColor:onClose( )
	self:removeFromParent()
end


function KwxPukeColor:onExit()
	EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE)
end




return KwxPukeColor 