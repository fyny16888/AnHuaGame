---------统计----------
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local Statistics = {}

function Statistics:onEnter( ... )
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Statistics:onExit( ... )
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Statistics:EVENT_TYPE_NET_RECV_MESSAGE( event )
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIN then
        netInstance = NetMgr:getLoginInstance()
    elseif netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end

    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    --返回亲友圈统计个人
    if  netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MYSELF then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwDayTime = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.lScore = luaFunc:readRecvLong()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwCompleteGameCount = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MYSELF,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MYSELF_FINISH then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MYSELF_FINISH,data)
    --返回亲友圈统计成员
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MEMBER then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)                     --玩家昵称
        data.szLogoInfo = luaFunc:readRecvString(256) --用户头像
        data.lScore = luaFunc:readRecvLong()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwCompleteGameCount = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MEMBER,data)
    --返回亲友圈统计成员
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwDayTime = luaFunc:readRecvDWORD()
        data.dwPlayGameCount1 = luaFunc:readRecvDWORD()
        data.dwPlayGameCount2 = luaFunc:readRecvDWORD()
        data.dwPlayGameCount3 = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwRoomCard = luaFunc:readRecvDWORD()
        data.dwDAU = luaFunc:readRecvDWORD()
        data.dwDNU = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_ALL then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwMemberCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwRoomCard = luaFunc:readRecvDWORD()
        data.dwDNU = luaFunc:readRecvDWORD()
        data.dwNewUserGameCount = luaFunc:readRecvDWORD()
        data.dwAllPeopleCount = luaFunc:readRecvDWORD()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_ALL,data)
    --//返回亲友圈统计成员
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_MEMBER_FINISH then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_MEMBER_FINISH,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_STATISTICS_FINISH then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_STATISTICS_FINISH,data)
    end
end

--请求俱乐部个人统计
function Statistics:req_statisticsMyself(dwClubID,dwDayTime,dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_MYSELF,"ddd",dwClubID,dwDayTime,dwUserID)
end

--请求亲友圈统计成员
function Statistics:req_statisticsMember(dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_MEMBER,"dddwd",dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore)
end

--请求管理员统计
function Statistics:req_statisticsManager(dwClubID,dwBeganTime,dwEndTime)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_ALL,"ddd",dwClubID,dwBeganTime,dwEndTime)
end

--每日统计REQ_GET_CLUB_STATISTICS
function Statistics:req_dayManager(dwClubID,dwBeganTime,dwEndTime,wPage )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS,"dddw",dwClubID,dwBeganTime,dwEndTime,wPage )
end

--玩家统计REQ_GET_CLUB_STATISTICS_MEMBER //0大赢家 1全部场次 2完整场次 3分数	
function Statistics:req_playerManager(dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore,bSortMode )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CLUB_STATISTICS_MEMBER,"dddwdb",dwClubID,dwBeganTime,dwEndTime,wPage,dwMinWinnerScore,bSortMode)
end


return Statistics