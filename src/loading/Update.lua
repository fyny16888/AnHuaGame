
local Update = {
    version = "",           --游戏版本也是lua版本
    versionSDK = "",        --SDK版本
    isHaveUpdateSDK = 0,    --SDK是否有更新,android下才用到
    downloadSDKUrl = "",    --SDK下载地址
    className = "com/coco2dx/org/HelperAndroid",
    isLuaUpdated = false,   --是否有更新lua
    newVersion = "",        --lua最新版本
    updateConten = "",     --lua最新版本内容
}

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

-------------------------设置更新参数信息--------------------------
function Update:checkVersionSDK()
    local json = require("json")
    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
    xmlHttpRequest:open("GET","http://download.hy.qilaigame.com/downloadapk/channelsversion.json")
    local function onHttpRequestCompletedPhone()
        if xmlHttpRequest.status == 200 then
            print("xmlHttpRequest.response")
            local response = json.decode(xmlHttpRequest.response)
            local channelID = tostring(CHANNEL_ID)
            if response[channelID] ~= nil and response[channelID]["open"] == true and Update.versionSDK ~= response[channelID]["version"] then
                Update.isHaveUpdateSDK  = 1
                Update.downloadSDKUrl  = response[channelID]["url"]
            end
        end
    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestCompletedPhone)
    xmlHttpRequest:send()
end

function Update:setUpdateParameter()
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
        local methodName = "setUpdateParameter" 
        local args = { "V", setVersionSDK }  
        local sigs = "(V;I)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        self.versionSDK = cus.JniControl:getInstance():getVersionSDK()
        self:checkVersionSDK()
    else
        self:checkVersionSDK()
    end
end

function cc.exports.setVersionSDK(version)
    Update.versionSDK = version
    Update:checkVersionSDK()
end

function cc.exports.setHaveUpdate(isHaveUpdate)
    --Update.isHaveUpdateSDK = tonumber(isHaveUpdate)
end

return Update