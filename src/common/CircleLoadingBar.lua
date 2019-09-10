local Common = require("common.Common")
local CircleLoadingBar = class("CircleLoadingBar", function()
    return cc.Node:create()
end)

function CircleLoadingBar:create(loadingBar)
    local view = CircleLoadingBar.new()
    view:onCreate(loadingBar)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit()
        elseif eventType == "cleanup" then
            view:onCleanup()
        end  
    end 
    view:registerScriptHandler(onEventHandler)
    return view
end

function CircleLoadingBar:onEnter()

end

function CircleLoadingBar:onExit()
    if self.scheduleUpdateObj then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
        self.scheduleUpdateObj = nil
    end
end

function CircleLoadingBar:onCleanup()

end

function CircleLoadingBar:onCreate(loadingBar)
    local sprite = cc.Sprite:create(loadingBar)  
    self.circleProgressBar = cc.ProgressTimer:create(sprite)  
    self.circleProgressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)  
    self.circleProgressBar:setPercentage(0)
    self:addChild(self.circleProgressBar)
end

function CircleLoadingBar:start(time)
    local currentTime = 0
    if self.scheduleUpdateObj then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
        self.scheduleUpdateObj = nil
    end
    self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta)
        if currentTime > time then
            if self.scheduleUpdateObj then
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
                self.scheduleUpdateObj = nil
                self:setVisible(false)
            end
        end 
        currentTime = currentTime + delta
        local value = (currentTime)/time*100
        self.circleProgressBar:setPercentage(value) 
    end, 0 ,false)
end

return CircleLoadingBar
