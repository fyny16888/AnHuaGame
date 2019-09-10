local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local HttpUrl = require("common.HttpUrl")
local json = require("json")
local Common = require("common.Common")
local LocationSystem = require("common.LocationSystem")

local Time = {
    isReconecting = false,      --是否正在重连
    
    serverTimer = os.time(),    --当前服务器时间
    timeSub = 0,                --服务器时间与本地时间间隔
    schedulerId = nil,          --时钟定时器
    
    logicStartDetect = false,   --逻辑服开始检测
    logicTimeOut = 0,           --逻辑服超时时间
    logicHeartbeatTime = 0,     --逻辑服心跳间隔时间
    
    gameStartDetect = false,    --游戏服开始检测
    gameTimeOut = 0,            --游戏服超时时间
    gameHeartbeatTime = 0,      --游戏服心跳时间
    gameLocationTime = 0,       --游戏定位时间
    
    lastGetIPTime = 5,          --获取IP的时间    
}

function Time:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_NET_DISCONNET,self,self.EVENT_TYPE_NET_DISCONNET)
    EventMgr:registListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS) 
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER) 
    EventMgr:registListener(EventType.EVENT_TYPE_NET_CLOSE,self,self.EVENT_TYPE_NET_CLOSE) 
    self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(delta) self:update(delta) end, 0 ,false)
end

function Time:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_DISCONNET,self,self.EVENT_TYPE_NET_DISCONNET)
    EventMgr:unregistListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS) 
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER) 
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_CLOSE,self,self.EVENT_TYPE_NET_CLOSE) 
    
    if self.scheduleUpdateObj then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
        self.scheduleUpdateObj = nil
    end

    if self.schedulerId then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerId)
        self.schedulerId = nil
    end
end

function Time:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    elseif netID == NetMgr.NET_GAME then
        netInstance = NetMgr:getGameInstance()
    else
        return
    end
    
    local luaFunc = netInstance.cppFunc
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_KN_COMMAND and subCmdID == NetMsgId.SUB_KN_NETWORK_DELAY then
        self.logicTimeOut = 0
        
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_KN_COMMAND and subCmdID == NetMsgId.SUB_KN_NETWORK_DELAY then
        local time = luaFunc:readRecvLong()
        local delay = 0
        if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
            delay = 0
        else
            local currentTime = cus.Help:getInstance():getTickCount()
            delay = currentTime - time
        end
        EventMgr:dispatch(EventType.EVENT_TYPE_SIGNAL,delay)
        
        self.gameTimeOut = 0
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_SERVER_TIME then
        self.serverTimer = luaFunc:readRecvDWORD()
        self:synServerTimer(self.serverTimer)
    else

    end
end

function Time:SUB_CL_LOGON_SUCCESS(event)
    self.logicStartDetect = true
    self.logicTimeOut = 0
    self.logicHeartbeatTime = os.time()
    local currentTime = 0
    if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
        currentTime = 0
    else
        currentTime = cus.Help:getInstance():getTickCount()
    end
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_KN_COMMAND, NetMsgId.SUB_KN_NETWORK_DELAY,"d",currentTime)
    self:sendMsgGetServerTime()
end

function Time:SUB_GR_USER_ENTER(event)
    self.gameStartDetect = true
    self.gameTimeOut = 0
    self.gameHeartbeatTime = os.time()
    self.gameLocationTime = os.time()
    local currentTime = 0
    if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
        currentTime = 0
    else
        currentTime = cus.Help:getInstance():getTickCount()
    end
    NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_KN_COMMAND, NetMsgId.SUB_KN_NETWORK_DELAY,"d",currentTime) 
end

function Time:EVENT_TYPE_NET_CLOSE(event)
    local netID = event._usedata
    if netID == NetMgr.NET_LOGIC then
        self.logicStartDetect = false
    elseif netID == NetMgr.NET_GAME then
        self.gameStartDetect = false
    end 
end

function Time:EVENT_TYPE_NET_DISCONNET(event)
    local netID = event._usedata
    if netID ~= NetMgr.NET_LOGIC and netID ~= NetMgr.NET_GAME then
        return
    end
    
    if self.isReconecting == true then
        return
    end 
    
    self.logicStartDetect = false
    self.gameStartDetect = false
    
    if SceneMgr.sceneName == SCENE_HALL then
        require("common.SceneMgr"):switchHallReconnect(require("app.MyApp"):create():createView("ReconnectLayer"))
    elseif SceneMgr.sceneName == SCENE_GAME then
        require("common.SceneMgr"):switchGameReconnect(require("app.MyApp"):create():createView("ReconnectLayer"))
    else
        
    end
end

function Time:update(dt)
    if self.logicStartDetect == true then
        if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER then
            self.logicTimeOut = self.logicTimeOut + dt
            if self.logicTimeOut > 16 then
                print("检测逻辑服网络超时",self.logicTimeOut)
                NetMgr:getLogicInstance():closeConnect()
                EventMgr:dispatch(EventType.EVENT_TYPE_NET_DISCONNET,NetMgr.NET_LOGIC)
            end
        end
        
        self.logicHeartbeatTime = self.logicHeartbeatTime + dt
        if self.logicHeartbeatTime >= 2 then
            self.logicHeartbeatTime = 0
            local currentTime = 0
			if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
                currentTime = 0
            else
                currentTime = cus.Help:getInstance():getTickCount()
            end
            NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_KN_COMMAND, NetMsgId.SUB_KN_NETWORK_DELAY,"d",currentTime)
        end
    end
    
    if self.gameStartDetect == true then
        if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER then
            self.gameTimeOut = self.gameTimeOut + dt
            if self.gameTimeOut > 16 then
                print("检测游戏服网络超时",self.gameTimeOut)
                NetMgr:getGameInstance():closeConnect()
                EventMgr:dispatch(EventType.EVENT_TYPE_NET_DISCONNET,NetMgr.NET_GAME)
            end
        end
        
        self.gameHeartbeatTime = self.gameHeartbeatTime + dt
        if self.gameHeartbeatTime >= 2 then
            self.gameHeartbeatTime = 0
            local currentTime = 0
			if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL and cus.JniControl:getInstance():getSystemVersion() < 10.0 then
                currentTime = 0
            else
                currentTime = cus.Help:getInstance():getTickCount()
            end
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_KN_COMMAND, NetMsgId.SUB_KN_NETWORK_DELAY,"d",currentTime)
        end
        
        self.gameLocationTime = self.gameLocationTime + dt
        if self.gameLocationTime >= 60 then
            self.gameLocationTime = 0
            local UserData = require("app.user.UserData")
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_USER_SET_POSITION,"aad",LocationSystem.pos.x, LocationSystem.pos.y, UserData.User.userID)
        end
    end
    
    self.lastGetIPTime = self.lastGetIPTime + dt
    local UserData = require("app.user.UserData")
    if (UserData.User.localIp == 0 and self.lastGetIPTime >= 5) or (UserData.User.localIp ~= 0 and self.lastGetIPTime >= 5*60) then
        self.lastGetIPTime = 0
        local xmlHttpRequest = cc.XMLHttpRequest:new()
        xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
        xmlHttpRequest:setRequestHeader("Content-Type", "application/json; charset=utf-8")
        xmlHttpRequest:open("GET", HttpUrl.POST_URL_GetGameIpAddr)
        local function onHttpRequestCompleted()
            if xmlHttpRequest.status == 200 then
                print("POST_URL_GetGameIpAddr:",xmlHttpRequest.response)
                local response = xmlHttpRequest.response
                if string.find(response,"cip") == nil then
                	return
                end
                response = string.sub(response,string.find(response, "{"),string.len(response) - string.find(string.reverse(response),"}")+1)
                response = string.gsub(response,"\"","'")
                response = json.decode(response)
                local ip = response["cip"]
                local tableIp = Common:stringSplit(ip,".")
                local ip1 = tableIp[1]
                local ip2 = tableIp[2]
                local ip3 = tableIp[3]
                local ip4 = tableIp[4]
                UserData.User.localIp = 256 * 256 * 256 * ip4 + 256 * 256 * ip3 + 256 * ip2 + ip1 
            end
        end
        xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
        xmlHttpRequest:send()
    end
end

function Time:getServerTimeToTable()
    local data = os.date("*t",os.time())--os.date("*t",self.serverTimer)
    return data
end

function Time:sendMsgGetServerTime()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL,NetMsgId.REQ_CL_SERVER_TIME,"")
    -- printInfo('同步服务器时间请求')
end

--同步服务器时间
function Time:synServerTimer(time)
    if not time then
        return
    end
    self.serverTimer = time
    self.timeSub = self.serverTimer - os.time() 
    
    if self.schedulerId then
        return
    end

    local synSub = 10
    local idx = 0
    local function update(dt)
        idx = idx + 1
        if idx >= synSub then
            idx = 0
            self:sendMsgGetServerTime()
        end

        self.serverTimer = os.time() + self.timeSub
        -- printInfo(os.date("%y/%m/%d/%H/%M/%S",self.serverTimer))
    end
    self.schedulerId = cc.Director:getInstance():getScheduler():scheduleScriptFunc(update, 1 ,false)
end

--获取服务器时间
function Time:getServerTimer()
    return self.serverTimer or os.time()
end

return Time