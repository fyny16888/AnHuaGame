local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

local LocationSystem = {
    className = "com/coco2dx/org/HelperAndroid",
    pos = cc.p(0,0)
}

function cc.exports.SetPosition(pos)
    print("游戏位置定位：",pos)
    LocationSystem.pos = cc.p(0,0)
    if pos == "" or pos == "0|0" then
    	return
    end
    local Common = require("common.Common")
    local tablePos = Common:stringSplit(pos,"|")
    if #tablePos == 2 then
        LocationSystem.pos = cc.p(tonumber(tablePos[1]),tonumber(tablePos[2]))
    end
    
end


function LocationSystem:getPosition()
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
        local methodName = "getPosition" 
        local args = {  }  
        local sigs = "(Ljava/lang/String;)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        SetPosition(cus.JniControl:getInstance():getPosition())
    end
end

local loasttime = 60 * 1
local howlong = 60 * 1
function LocationSystem:update(dt)
    loasttime = loasttime + dt
    if loasttime >= howlong then
        loasttime = 0
		self:getPosition()
	end
end

LocationSystem.scheduleUpdate = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) LocationSystem:update(delta) end, 0 ,false)

return LocationSystem