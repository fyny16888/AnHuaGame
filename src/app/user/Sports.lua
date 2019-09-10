local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local Default = require("common.Default")
local HttpUrl = require("common.HttpUrl")
local json = require("json")

local Sports = {
    
}

function Sports:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Sports:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Sports:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end
    
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    if mainCmdID ~= NetMsgId.MDM_CL_SPORTS then
        return
    end
    
    local luaFunc = NetMgr:getLogicInstance().cppFunc
    if mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_CONFIG_LIST then
        --竞技配置表
        local data = {}
        data.dwKey = luaFunc:readRecvDWORD()
        data.dwItemID = luaFunc:readRecvDWORD()
        data.szItemName = luaFunc:readRecvString(32)
        data.szItemImg = luaFunc:readRecvString(256)
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.cbState = luaFunc:readRecvByte()
        data.dwTime = luaFunc:readRecvDWORD()
        data.dwPrice = luaFunc:readRecvDWORD()
        data.dwCreateCost = luaFunc:readRecvDWORD()
        data.dwReturnCost = luaFunc:readRecvDWORD()
        printInfo(data)
        EventMgr:dispatch(EventType.RET_SPORTS_CONFIG_LIST,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_LIST then
        --竞技列表
        local data = {}
        data.dwID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.dwItemID = luaFunc:readRecvDWORD()
        data.szItemName = luaFunc:readRecvString(32)
        data.szItemImg = luaFunc:readRecvString(256)
        data.cbState = luaFunc:readRecvByte()
        data.cbType = luaFunc:readRecvByte()
        data.dwTime = luaFunc:readRecvDWORD()
        data.dwCost = luaFunc:readRecvDWORD()
        data.dwReturnCost = luaFunc:readRecvDWORD()
        data.dwCount = luaFunc:readRecvDWORD()
        data.dwCurrentCount = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwWinnerUserID = luaFunc:readRecvDWORD()
        data.szWinnerNickName = luaFunc:readRecvString(32)
        data.szWinnerLogoInfo = luaFunc:readRecvString(256)
        data.dwMyCount = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.tableParameter = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
        EventMgr:dispatch(EventType.RET_SPORTS_LIST,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_LIST_BY_USER_ID then
        --我的竞技场列表
        local data = {}
        data.dwID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.dwItemID = luaFunc:readRecvDWORD()
        data.szItemName = luaFunc:readRecvString(32)
        data.szItemImg = luaFunc:readRecvString(256)
        data.cbState = luaFunc:readRecvByte()
        data.cbType = luaFunc:readRecvByte()
        data.dwTime = luaFunc:readRecvDWORD()
        data.dwCost = luaFunc:readRecvDWORD()
        data.dwReturnCost = luaFunc:readRecvDWORD()
        data.dwCount = luaFunc:readRecvDWORD()
        data.dwCurrentCount = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwWinnerUserID = luaFunc:readRecvDWORD()
        data.szWinnerNickName = luaFunc:readRecvString(32)
        data.szWinnerLogoInfo = luaFunc:readRecvString(256)
        data.dwMyCount = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.tableParameter = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
        EventMgr:dispatch(EventType.RET_SPORTS_LIST_BY_USER_ID,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_CREATE then
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_SPORTS_CREATE,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_STATE then
        local data = {}
        data.isOpenSports = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_SPORTS_STATE,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_USER_LIST then
        local data = {}
        data.dwID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.dwMyCount = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        EventMgr:dispatch(EventType.RET_SPORTS_USER_LIST,data)
    
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_REWARD_SELF_WINNING then
        local data = {}
        data.dwID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.dwItemID = luaFunc:readRecvDWORD()
        data.szItemName = luaFunc:readRecvString(32)
        data.szItemImg = luaFunc:readRecvString(256)
        data.cbState = luaFunc:readRecvByte()
        data.cbType = luaFunc:readRecvByte()
        data.dwTime = luaFunc:readRecvDWORD()
        data.dwCost = luaFunc:readRecvDWORD()
        data.dwReturnCost = luaFunc:readRecvDWORD()
        data.dwCount = luaFunc:readRecvDWORD()
        data.dwCurrentCount = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwWinnerUserID = luaFunc:readRecvDWORD()
        data.szWinnerNickName = luaFunc:readRecvString(32)
        data.szWinnerLogoInfo = luaFunc:readRecvString(256)
        data.dwMyCount = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.tableParameter = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
        EventMgr:dispatch(EventType.RET_SPORTS_REWARD_SELF_WINNING,data)
       
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_REWARD_SELF_JOIN then
        local data = {}
        data.dwID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.dwItemID = luaFunc:readRecvDWORD()
        data.szItemName = luaFunc:readRecvString(32)
        data.szItemImg = luaFunc:readRecvString(256)
        data.cbState = luaFunc:readRecvByte()
        data.cbType = luaFunc:readRecvByte()
        data.dwTime = luaFunc:readRecvDWORD()
        data.dwCost = luaFunc:readRecvDWORD()
        data.dwReturnCost = luaFunc:readRecvDWORD()
        data.dwCount = luaFunc:readRecvDWORD()
        data.dwCurrentCount = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwWinnerUserID = luaFunc:readRecvDWORD()
        data.szWinnerNickName = luaFunc:readRecvString(32)
        data.szWinnerLogoInfo = luaFunc:readRecvString(256)
        data.dwMyCount = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.tableParameter = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
        EventMgr:dispatch(EventType.RET_SPORTS_REWARD_SELF_JOIN,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_SPORTS and subCmdID == NetMsgId.RET_SPORTS_REWARD_ALL then
        local data = {}
        data.dwID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.dwItemID = luaFunc:readRecvDWORD()
        data.szItemName = luaFunc:readRecvString(32)
        data.szItemImg = luaFunc:readRecvString(256)
        data.cbState = luaFunc:readRecvByte()
        data.cbType = luaFunc:readRecvByte()
        data.dwTime = luaFunc:readRecvDWORD()
        data.dwCost = luaFunc:readRecvDWORD()
        data.dwReturnCost = luaFunc:readRecvDWORD()
        data.dwCount = luaFunc:readRecvDWORD()
        data.dwCurrentCount = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwWinnerUserID = luaFunc:readRecvDWORD()
        data.szWinnerNickName = luaFunc:readRecvString(32)
        data.szWinnerLogoInfo = luaFunc:readRecvString(256)
        data.dwMyCount = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.tableParameter = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
        EventMgr:dispatch(EventType.RET_SPORTS_REWARD_ALL,data) 
        
    else
        return
    end
end

function Sports:getSportsState()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_STATE,"")
end

function Sports:getSportsList(type)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_LIST,"db",CHANNEL_ID,type)
end

function Sports:getMySportsList()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_LIST_BY_USER_ID,"")
end

function Sports:getSportsConfigList()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_CONFIG_LIST,"d",CHANNEL_ID)
end

function Sports:getSportsUserList(dwID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_USER_LIST,"d",dwID)
end

function Sports:getSportsRewardSelfWinning()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_REWARD_SELF_WINNING,"")
end

function Sports:getSportsRewardSelfJoin()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_REWARD_SELF_JOIN,"")
end

function Sports:getSportsRewardAll()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_SPORTS,NetMsgId.REQ_SPORTS_REWARD_ALL,"d",CHANNEL_ID)
end

return  Sports
