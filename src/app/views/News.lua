local Common = require("common.Common")
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")

local News = class("News", cc.load("mvc").ViewBase)

function News:onEnter()

end

function News:onExit()

end

function News:onCleanup()

end

function News:onCreate()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("News.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")   
    Common:addTouchEventListener(self.root,function() 
        require("common.SceneMgr"):switchOperation()
       -- self:removeFromParent()
    end,true)

    local uiText_News = ccui.Helper:seekWidgetByName(self.root,"Text_News")
    if UserData.Notice.notice ~= nil and UserData.Notice.notice.wNoticeType == 0 then
        uiText_News:setString(UserData.Notice.notice.szNoticeInfo)
    end
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        -- Common:playExitAnim(Image_bg, callback)
        --require("common.SceneMgr"):switchOperation()
        self:removeFromParent()
    end)
end


return News

