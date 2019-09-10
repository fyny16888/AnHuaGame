local Net = require("common.Net")
local EventMgr = require("common.EventMgr")

local NetMgr = {
    NET_LOGIN    = 0x1,     --登录
    NET_LOGIC    = 0x2,     --逻辑服
    NET_GAME     = 0x3,     --游戏服
}



function NetMgr:getLoginInstance()
    if self.netLogin == nil then
        self.netLogin = Net:new()
        self.netLogin.cppFunc = net.WSLuaFunc:create(self.NET_LOGIN)
        self.netLogin.id = self.NET_LOGIN
        self.netLogin.cppFunc:retain()
        self.netLogin.connected = false
        self.netLogin.serverAddr = ""
        self.netLogin.serverPort = 0
    end
    return self.netLogin
end

function NetMgr:getGameInstance()
    if self.netGame == nil then
        self.netGame = Net:new()
        self.netGame.cppFunc = net.WSLuaFunc:create(self.NET_GAME)
        self.netGame.id = self.NET_GAME
        self.netGame.cppFunc:retain()
        self.netGame.connected = false
        self.netGame.serverAddr = ""
        self.netGame.serverPort = 0
    end
    return self.netGame
end

function NetMgr:getLogicInstance()
    if self.netLogic == nil then
        self.netLogic = Net:new()
        self.netLogic.cppFunc = net.WSLuaFunc:create(self.NET_LOGIC)
        self.netLogic.id = self.NET_LOGIC
        self.netLogic.cppFunc:retain()
        self.netLogic.connected = false
        self.netLogic.serverAddr = ""
        self.netLogic.serverPort = 0
    end
    return self.netLogic
end

function cc.exports.OnNetDisconnect(netID)
    printInfo(string.format("网络中断：netID = %d",netID))
    local netInstance = nil
    if netID == NetMgr.NET_LOGIN then
        NetMgr:getLoginInstance():onDisConnect()
        netInstance = NetMgr:getLoginInstance()
    elseif netID == NetMgr.NET_GAME then
        NetMgr:getGameInstance():onDisConnect()
        netInstance = NetMgr:getGameInstance()
    elseif netID == NetMgr.NET_LOGIC then
        NetMgr:getLogicInstance():onDisConnect()
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end
    if netInstance.isActiveNetwork == true then
        EventMgr:dispatch("EVENT_TYPE_NET_CLOSE",netID)
        return
    end
    EventMgr:dispatch("EVENT_TYPE_NET_DISCONNET",netID)
end

function cc.exports.OnNetUpdateInterfaceWithReachability(state)
    print(string.format("OnNetUpdateInterfaceWithReachability切换网络：state = %s",state))
end

function cc.exports.OnNetRecvMsg(netID)
    local netInstance = nil
    if netID == NetMgr.NET_LOGIN then
        netInstance = NetMgr:getLoginInstance()
    elseif netID == NetMgr.NET_GAME then
        netInstance = NetMgr:getGameInstance()
    elseif netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        printError(string.format("没有找到该连接器：%d",netID))
        return
    end
    if netInstance.connected == false then
        return
    end
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    if netID == 2 and  mainCmdID == 0 and subCmdID == 1 then
    elseif netID == 2 and  mainCmdID == 0 and subCmdID == 3 then 
    elseif netID == 3 and  mainCmdID == 0 and subCmdID == 1 then 
    elseif netID == 3 and  mainCmdID == 0 and subCmdID == 3 then 
    elseif netID == 2 and  mainCmdID == 110 and subCmdID == 11000 then 
    else
        printInfo(string.format("接受消息：netID = %d, mainCmdID = %d, subCmdID = %d",netID,mainCmdID,subCmdID))
    end
    EventMgr:dispatch("EVENT_TYPE_NET_RECV_MESSAGE",netID)
    
end

return NetMgr
