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

local Guild = {
    dwID = 0,                           --公会key
    dwGuildID = 0,                      --公会ID
    szGuildName = "",                   --公会名字
    szGuildNotice = "",                 --公会公告
    dwMemberCount = 0,                  --公会成员数量
    dwPresidentID = 0,                  --代理ID
    szPresidentName = "",               --代理名字
    szPresidentLogo = "",               --代理头像
    szApplicationList = {},             --申请列表
    tableLastUseClubRecord = {},
    isChangeClubTable = false,          --是否是牌桌俱乐部桌子切换
}

function Guild:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function Guild:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function Guild:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end
    
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    if mainCmdID ~= NetMsgId.MDM_CL_GUILD and mainCmdID ~= NetMsgId.MDM_CL_CLUB then
        return
    end
    
    local luaFunc = NetMgr:getLogicInstance().cppFunc

    if mainCmdID == NetMsgId.MDM_CL_GUILD and subCmdID == NetMsgId.RET_GET_GUILD_INFO then
        --获取公会信息
        local dwTargetUserID = luaFunc:readRecvDWORD()
        self.dwID = luaFunc:readRecvDWORD()
        self.dwGuildID = luaFunc:readRecvDWORD()
        self.dwMemberCount = luaFunc:readRecvDWORD()
        self.szGuildName = luaFunc:readRecvString(32)
        self.szGuildNotice = luaFunc:readRecvString(256)
        self.dwPresidentID = luaFunc:readRecvDWORD()
        self.szPresidentName = luaFunc:readRecvString(32)       
    
    elseif mainCmdID == NetMsgId.MDM_CL_GUILD and subCmdID == NetMsgId.RET_GET_GUILD_INFO_BY_GUILDID then
        --根据公会ID获取公会信息
        local data = {}
        data.dwTargetUserID = luaFunc:readRecvDWORD()
        data.dwID = luaFunc:readRecvDWORD()
        data.dwGuildID = luaFunc:readRecvDWORD()
        data.dwMemberCount = luaFunc:readRecvDWORD()
        data.szGuildName = luaFunc:readRecvString(32)
        data.szGuildNotice = luaFunc:readRecvString(256)
        data.dwPresidentID = luaFunc:readRecvDWORD()
        data.szPresidentName = luaFunc:readRecvString(32)
        EventMgr:dispatch(EventType.RET_GET_GUILD_INFO_BY_GUILDID,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_GUILD and subCmdID == NetMsgId.RET_JOIN_GUILD then
        --加入公会结果
        local data = {}
        data.ret = luaFunc:readRecvLong()
        data.dwTargetUserID = luaFunc:readRecvDWORD()
        data.dwID = luaFunc:readRecvDWORD()
        data.dwGuildID = luaFunc:readRecvDWORD()
        data.dwMemberCount = luaFunc:readRecvDWORD()
        data.szGuildName = luaFunc:readRecvString(32)
        data.szGuildNotice = luaFunc:readRecvString(256)
        data.dwPresidentID = luaFunc:readRecvDWORD()
        data.szPresidentName = luaFunc:readRecvString(32)
        EventMgr:dispatch(EventType.RET_JOIN_GUILD,data)  
    elseif mainCmdID == NetMsgId.MDM_CL_GUILD and subCmdID == NetMsgId.RET_UPDATE_GUILD then
        local data = {}
        data.ret = luaFunc:readRecvLong()
        data.dwGuildID = luaFunc:readRecvDWORD()                          --公会ID
        data.cbUpdateType = luaFunc:readRecvByte()                        --更新的类型 0公告
        data.szGuildNotice = luaFunc:readRecvString(256)                  --公会公告
        EventMgr:dispatch(EventType.RET_UPDATE_GUILD,data)
    -----------------------------------------------------------------------------------------   
    
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_CREATE_CLUB3 then
        --返回创建亲友圈
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.szClubName = luaFunc:readRecvString(32)
        data.dwOnlinePlayerCount = luaFunc:readRecvDWORD()
        data.dwClubPlayerCount = luaFunc:readRecvDWORD()
        data.dwChatRoomID = luaFunc:readRecvDWORD()
        data.bHaveCustomizeRoom = luaFunc:readRecvBool()
        data.bIsDisable = luaFunc:readRecvBool()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPropCount = luaFunc:readRecvDWORD()
        data.isStatisticsVisible = luaFunc:readRecvBool()
        data.szAnnouncement = luaFunc:readRecvString(256)
        data.dwAdministratorID = {}
        for i = 1, 10 do
            data.dwAdministratorID[i] = luaFunc:readRecvDWORD()
        end
        data.szAdministratorName = {}
        for i = 1, 10 do
            data.szAdministratorName[i] = luaFunc:readRecvString(32)
        end
        data.szAdministratorLogoInfo = {}
        for i = 1, 10 do
            data.szAdministratorLogoInfo[i] = luaFunc:readRecvString(256)
        end
        
        EventMgr:dispatch(EventType.RET_CREATE_CLUB,data)
    
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_SETTINGS_CLUB3 then
        --返回设置亲友圈
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.cbSettingsType = luaFunc:readRecvByte()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.szClubName = luaFunc:readRecvString(32)
        data.dwOnlinePlayerCount = luaFunc:readRecvDWORD()
        data.dwClubPlayerCount = luaFunc:readRecvDWORD()
        data.dwChatRoomID = luaFunc:readRecvDWORD()
        data.bHaveCustomizeRoom = luaFunc:readRecvBool()
        data.bIsDisable = luaFunc:readRecvBool()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPropCount = luaFunc:readRecvDWORD()
        data.isStatisticsVisible = luaFunc:readRecvBool()
        data.szAnnouncement = luaFunc:readRecvString(256)
        data.dwAdministratorID = {}
        for i = 1, 10 do
            data.dwAdministratorID[i] = luaFunc:readRecvDWORD()
        end
        data.szAdministratorName = {}
        for i = 1, 10 do
            data.szAdministratorName[i] = luaFunc:readRecvString(32)
        end
        data.szAdministratorLogoInfo = {}
        for i = 1, 10 do
            data.szAdministratorLogoInfo[i] = luaFunc:readRecvString(256)
        end
        data.dwTargetID = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_SETTINGS_CLUB,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_JOIN_CLUB then
        --返回加入亲友圈
        local lRet = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_JOIN_CLUB,{lRet = lRet})
      
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_CLUB_CHECK_LIST then
        --返回亲友圈审核列表
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwApplyTime = luaFunc:readRecvDWORD()
        table.insert(self.szApplicationList,#self.szApplicationList + 1,data) 
        --szApplicationList
        EventMgr:dispatch(EventType.RET_CLUB_CHECK_LIST,data)  
        
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_CLUB_CHECK_RESULT then
        --返回同意或者拒绝加入亲友圈
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwApplyTime = luaFunc:readRecvDWORD()
        data.isAgree = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_CLUB_CHECK_RESULT,data)  
        
        
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_LIST3 then
        --返回亲友圈列表
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.szClubName = luaFunc:readRecvString(32)
        data.dwOnlinePlayerCount = luaFunc:readRecvDWORD()
        data.dwClubPlayerCount = luaFunc:readRecvDWORD()
        data.dwChatRoomID = luaFunc:readRecvDWORD()
        data.bHaveCustomizeRoom = luaFunc:readRecvBool()
        data.bIsDisable = luaFunc:readRecvBool()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPropCount = luaFunc:readRecvDWORD()
        data.isStatisticsVisible = luaFunc:readRecvBool()
        data.szAnnouncement = luaFunc:readRecvString(256)
        data.dwAdministratorID = {}
        for i = 1, 10 do
            data.dwAdministratorID[i] = luaFunc:readRecvDWORD()
        end
        data.szAdministratorName = {}
        for i = 1, 10 do
            data.szAdministratorName[i] = luaFunc:readRecvString(32)
        end
        data.szAdministratorLogoInfo = {}
        for i = 1, 10 do
            data.szAdministratorLogoInfo[i] = luaFunc:readRecvString(256)
        end
        EventMgr:dispatch(EventType.RET_GET_CLUB_LIST,data)
    
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_LIST_FAIL then
        --没有亲友圈返回
        EventMgr:dispatch(EventType.RET_GET_CLUB_LIST_FAIL)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_ADDED_CLUB3 then
        --被添加亲友圈
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.szClubName = luaFunc:readRecvString(32)
        data.dwOnlinePlayerCount = luaFunc:readRecvDWORD()
        data.dwClubPlayerCount = luaFunc:readRecvDWORD()
        data.dwChatRoomID = luaFunc:readRecvDWORD()
        data.bHaveCustomizeRoom = luaFunc:readRecvBool()
        data.bIsDisable = luaFunc:readRecvBool()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPropCount = luaFunc:readRecvDWORD()
        data.isStatisticsVisible = luaFunc:readRecvBool()
        data.szAnnouncement = luaFunc:readRecvString(256)
        data.dwAdministratorID = {}
        for i = 1, 10 do
            data.dwAdministratorID[i] = luaFunc:readRecvDWORD()
        end
        data.szAdministratorName = {}
        for i = 1, 10 do
            data.szAdministratorName[i] = luaFunc:readRecvString(32)
        end
        data.szAdministratorLogoInfo = {}
        for i = 1, 10 do
            data.szAdministratorLogoInfo[i] = luaFunc:readRecvString(256)
        end
        EventMgr:dispatch(EventType.RET_ADDED_CLUB, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_REMOVE_CLUB then
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_REMOVE_CLUB,data)  
        
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_QUIT_CLUB then
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_QUIT_CLUB,data)  
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_MEMBER_EX_FINISH then
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_MEMBER_EX_FINISH,data)  
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_TABLE then
        local data = {}
        data.dwTableID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.nTableType = luaFunc:readRecvInt()
        data.wTableSubType = luaFunc:readRecvWORD()
        data.bIsGameStart = luaFunc:readRecvBool()
        data.wGameCount = luaFunc:readRecvWORD()
        data.wCurrentGameCount = luaFunc:readRecvWORD()
        data.wCellScore = luaFunc:readRecvWORD()
        data.wExpendType = luaFunc:readRecvWORD()
        data.dwExpendSubType = luaFunc:readRecvDWORD()
        data.dwExpendCount = luaFunc:readRecvDWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.wCurrentChairCount = luaFunc:readRecvWORD()
        data.dwCreateTableTime = luaFunc:readRecvDWORD()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwTableOwnerID = luaFunc:readRecvDWORD()
        data.szOwnerName = luaFunc:readRecvString(32)
        data.dwUserID = {}
        for i = 1, 6 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()
        end
        data.szNickName = {}
        for i = 1, 6 do
            data.szNickName[i] = luaFunc:readRecvString(32)
        end
        data.szLogoInfo = {}
        for i = 1, 6 do
            data.szLogoInfo[i] = luaFunc:readRecvString(256)
        end
        local wKindID = math.floor(data.dwTableID/10000)
        data.wKindID = wKindID
        local haveReadByte = 0
        data.tableParameter, haveReadByte = require("common.GameConfig"):getParameter(wKindID,luaFunc)
        if haveReadByte < 128 then
            luaFunc:readRecvBuffer(128-haveReadByte)
        end
        data.lScore = {}
        for i = 1, 6 do
            data.lScore[i] = luaFunc:readRecvLong()
        end
        data.cbUserStatus = {}
        for i = 1, 6 do
            data.cbUserStatus[i] = luaFunc:readRecvByte()
        end
        data.szGameID = luaFunc:readRecvString(32)

        --扩展
        for i = 7, 8 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()
        end
        for i = 7, 8 do
            data.szNickName[i] = luaFunc:readRecvString(32)
        end
        for i = 7, 8 do
            data.szLogoInfo[i] = luaFunc:readRecvString(256)
        end
        for i = 7, 8 do
            data.lScore[i] = luaFunc:readRecvLong()
        end
        EventMgr:dispatch(EventType.RET_GET_CLUB_TABLE,data)
    
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_MEMBER then
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwLastLoginTime = luaFunc:readRecvDWORD()
        data.isEnd = luaFunc:readRecvBool()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOffice = luaFunc:readRecvByte()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.isProhibit = luaFunc:readRecvBool()
        data.szRemarks = luaFunc:readRecvString(32)
        data.lFatigueValue = luaFunc:readRecvLong()
        data.szPartnerNickName = luaFunc:readRecvString(32)
        EventMgr:dispatch(EventType.RET_GET_CLUB_MEMBER,data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_REMOVE_CLUB_MEMBER then
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.lRet = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_REMOVE_CLUB_MEMBER,data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_REFRESH_CLUB3 then
        --刷新亲友圈
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.szClubName = luaFunc:readRecvString(32)
        data.dwOnlinePlayerCount = luaFunc:readRecvDWORD()
        data.dwClubPlayerCount = luaFunc:readRecvDWORD()
        data.dwChatRoomID = luaFunc:readRecvDWORD()
        data.bHaveCustomizeRoom = luaFunc:readRecvBool()
        data.bIsDisable = luaFunc:readRecvBool()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPropCount = luaFunc:readRecvDWORD()
        data.isStatisticsVisible = luaFunc:readRecvBool()
        data.szAnnouncement = luaFunc:readRecvString(256)
        data.dwAdministratorID = {}
        for i = 1, 10 do
            data.dwAdministratorID[i] = luaFunc:readRecvDWORD()
        end
        data.szAdministratorName = {}
        for i = 1, 10 do
            data.szAdministratorName[i] = luaFunc:readRecvString(32)
        end
        data.szAdministratorLogoInfo = {}
        for i = 1, 10 do
            data.szAdministratorLogoInfo[i] = luaFunc:readRecvString(256)
        end
        EventMgr:dispatch(EventType.RET_REFRESH_CLUB,data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_MEMBER_EX then
        --返回亲友圈以外可以导入的成员
        local data = {}
        data.dwOriginType = luaFunc:readRecvDWORD()
        data.dwOriginSubType = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        EventMgr:dispatch(EventType.RET_GET_CLUB_MEMBER_EX, data)
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_ADD_CLUB_MEMBER then
        --返回添加亲友圈成员
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwJoinTime = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_ADD_CLUB_MEMBER, data)
        
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_ADD_CLUB_TABLE then
        --添加亲友圈牌桌
        local data = {}
        data.dwTableID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.nTableType = luaFunc:readRecvInt()
        data.wTableSubType = luaFunc:readRecvWORD()
        data.bIsGameStart = luaFunc:readRecvBool()
        data.wGameCount = luaFunc:readRecvWORD()
        data.wCurrentGameCount = luaFunc:readRecvWORD()
        data.wCellScore = luaFunc:readRecvWORD()
        data.wExpendType = luaFunc:readRecvWORD()
        data.dwExpendSubType = luaFunc:readRecvDWORD()
        data.dwExpendCount = luaFunc:readRecvDWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.wCurrentChairCount = luaFunc:readRecvWORD()
        data.dwCreateTableTime = luaFunc:readRecvDWORD()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwTableOwnerID = luaFunc:readRecvDWORD()
        data.szOwnerName = luaFunc:readRecvString(32)
        data.dwUserID = {}
        for i = 1, 6 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()
        end
        data.szNickName = {}
        for i = 1, 6 do
            data.szNickName[i] = luaFunc:readRecvString(32)
        end
        data.szLogoInfo = {}
        for i = 1, 6 do
            data.szLogoInfo[i] = luaFunc:readRecvString(256)
        end
        local wKindID = math.floor(data.dwTableID/10000)
        data.wKindID = wKindID
        local haveReadByte = 0
        data.tableParameter, haveReadByte = require("common.GameConfig"):getParameter(wKindID,luaFunc)
        if haveReadByte < 128 then
            luaFunc:readRecvBuffer(128-haveReadByte)
        end
        data.lScore = {}
        for i = 1, 6 do
            data.lScore[i] = luaFunc:readRecvLong()
        end
        data.cbUserStatus = {}
        for i = 1, 6 do
            data.cbUserStatus[i] = luaFunc:readRecvByte()
        end

        data.szGameID = luaFunc:readRecvString(32)

        --扩展
        for i = 7, 8 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()
        end
        for i = 7, 8 do
            data.szNickName[i] = luaFunc:readRecvString(32)
        end
        for i = 7, 8 do
            data.szLogoInfo[i] = luaFunc:readRecvString(256)
        end
        for i = 7, 8 do
            data.lScore[i] = luaFunc:readRecvLong()
        end
        EventMgr:dispatch(EventType.RET_ADD_CLUB_TABLE, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_UPDATE_CLUB_TABLE then
        --刷新亲友圈牌桌
        local data = {}
        data.dwTableID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.nTableType = luaFunc:readRecvInt()
        data.wTableSubType = luaFunc:readRecvWORD()
        data.bIsGameStart = luaFunc:readRecvBool()
        data.wGameCount = luaFunc:readRecvWORD()
        data.wCurrentGameCount = luaFunc:readRecvWORD()
        data.wCellScore = luaFunc:readRecvWORD()
        data.wExpendType = luaFunc:readRecvWORD()
        data.dwExpendSubType = luaFunc:readRecvDWORD()
        data.dwExpendCount = luaFunc:readRecvDWORD()
        data.wChairCount = luaFunc:readRecvWORD()
        data.wCurrentChairCount = luaFunc:readRecvWORD()
        data.dwCreateTableTime = luaFunc:readRecvDWORD()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwTableOwnerID = luaFunc:readRecvDWORD()
        data.szOwnerName = luaFunc:readRecvString(32)
        data.dwUserID = {}
        for i = 1, 6 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()
        end
        data.szNickName = {}
        for i = 1, 6 do
            data.szNickName[i] = luaFunc:readRecvString(32)
        end
        data.szLogoInfo = {}
        for i = 1, 6 do
            data.szLogoInfo[i] = luaFunc:readRecvString(256)
        end
        local wKindID = math.floor(data.dwTableID/10000)
        data.wKindID = wKindID
        local haveReadByte = 0
        data.tableParameter, haveReadByte = require("common.GameConfig"):getParameter(wKindID,luaFunc)
        if haveReadByte < 128 then
            luaFunc:readRecvBuffer(128-haveReadByte)
        end
        data.lScore = {}
        for i = 1, 6 do
            data.lScore[i] = luaFunc:readRecvLong()
        end
        data.cbUserStatus = {}
        for i = 1, 6 do
            data.cbUserStatus[i] = luaFunc:readRecvByte()
        end

        data.szGameID = luaFunc:readRecvString(32)

        --扩展
        for i = 7, 8 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()
        end
        for i = 7, 8 do
            data.szNickName[i] = luaFunc:readRecvString(32)
        end
        for i = 7, 8 do
            data.szLogoInfo[i] = luaFunc:readRecvString(256)
        end
        for i = 7, 8 do
            data.lScore[i] = luaFunc:readRecvLong()
        end
        EventMgr:dispatch(EventType.RET_UPDATE_CLUB_TABLE, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_DEL_CLUB_TABLE then
        --删除亲友圈牌桌
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwTableID = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_DEL_CLUB_TABLE, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_UPDATE_CLUB_INFO3 then
        --更新亲友圈信息
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.cbSettingsType = luaFunc:readRecvByte()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.szClubName = luaFunc:readRecvString(32)
        data.dwOnlinePlayerCount = luaFunc:readRecvDWORD()
        data.dwClubPlayerCount = luaFunc:readRecvDWORD()
        data.dwChatRoomID = luaFunc:readRecvDWORD()
        data.bHaveCustomizeRoom = luaFunc:readRecvBool()
        data.bIsDisable = luaFunc:readRecvBool()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPropCount = luaFunc:readRecvDWORD()
        data.isStatisticsVisible = luaFunc:readRecvBool()
        data.szAnnouncement = luaFunc:readRecvString(256)
        data.dwAdministratorID = {}
        for i = 1, 10 do
            data.dwAdministratorID[i] = luaFunc:readRecvDWORD()
        end
        data.szAdministratorName = {}
        for i = 1, 10 do
            data.szAdministratorName[i] = luaFunc:readRecvString(32)
        end
        data.szAdministratorLogoInfo = {}
        for i = 1, 10 do
            data.szAdministratorLogoInfo[i] = luaFunc:readRecvString(256)
        end
        EventMgr:dispatch(EventType.RET_UPDATE_CLUB_INFO, data)
    
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_MEMBER_FINISH then
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_MEMBER_FINISH, data)
    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_DELED_CLUB then
        --被删除亲友圈
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_DELED_CLUB, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_DISBAND_CLUB_TABLE then
        --返回解散亲友圈桌子结果
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_DISBAND_CLUB_TABLE, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_UPDATE_CLUB_ROOMCARD then
        --返回亲友圈的房卡
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwRoomCardCount = luaFunc:readRecvDWORD()
        data.dwDeadlineTime = luaFunc:readRecvDWORD()
        data.dwSavingCount = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_UPDATE_CLUB_ROOMCARD, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_APPLICATION_RECORD then
        --返回亲友圈的申请记录
        local data = {}
        data.dwUserID = luaFunc:readRecvDWORD()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwTime = luaFunc:readRecvDWORD()
        data.cbState = luaFunc:readRecvByte()
        EventMgr:dispatch(EventType.RET_GET_CLUB_APPLICATION_RECORD, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_FIND_CLUB_MEMBER then
        --查看亲友圈成员列表
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwLastLoginTime = luaFunc:readRecvDWORD()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOffice = luaFunc:readRecvByte()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.isProhibit = luaFunc:readRecvBool()
        data.szRemarks = luaFunc:readRecvString(32)
        data.lFatigueValue = luaFunc:readRecvLong()
        data.szPartnerNickName = luaFunc:readRecvString(32)
        EventMgr:dispatch(EventType.RET_FIND_CLUB_MEMBER, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_REFUSE_JOIN_CLUB then
        --被拒绝加入亲友圈
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_REFUSE_JOIN_CLUB, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_OPERATE_RECORD then
        --返回俱乐部操作记录
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.cbType = luaFunc:readRecvByte()
        data.dwTime = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szParameter = luaFunc:readRecvString(256)
        EventMgr:dispatch(EventType.RET_GET_CLUB_OPERATE_RECORD, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_OPERATE_RECORD_FINISH then
        --返回俱乐部操作记录
        local data = {}
        data.isEnd = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_OPERATE_RECORD_FINISH, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_REFRESH_CLUB_PLAY then
        --返回刷新俱乐部玩法
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPlayID = {}
        for i = 1, 10 do
            data.dwPlayID[i] = luaFunc:readRecvDWORD()
        end
        data.wKindID = {}
        for i = 1, 10 do
            data.wKindID[i] = luaFunc:readRecvWORD()
        end
        data.wGameCount = {}
        for i = 1, 10 do
            data.wGameCount[i] = luaFunc:readRecvWORD()
        end
        data.wTableCell = {}
        for i = 1, 10 do
            data.wTableCell[i] = luaFunc:readRecvWORD()
        end

        data.cbMode = {}
        for i=1, 10 do
            data.cbMode[i] = luaFunc:readRecvByte()
        end
        data.cbPayMode = {}
        for i=1, 10 do
            data.cbPayMode[i] = luaFunc:readRecvByte()
        end

        data.dwPayLimit = {}
        for idx=1, 10 do
            data.dwPayLimit[idx] = {}
            for i=1,3 do
                data.dwPayLimit[idx][i] = luaFunc:readRecvDWORD()
            end
        end
        data.dwPayCount = {}
        for idx=1, 10 do
            data.dwPayCount[idx] = {}
            for i=1,3 do
                data.dwPayCount[idx][i] = luaFunc:readRecvDWORD()
            end
        end

        data.lTableLimit = {}
        for i=1,10 do
            data.lTableLimit[i] = luaFunc:readRecvLong()
        end
        data.wFatigueCell = {}
        for i=1,10 do
            data.wFatigueCell[i] = luaFunc:readRecvWORD()
        end
        data.isTableCharge = {}
        for i=1,10 do
            data.isTableCharge[i] = luaFunc:readRecvBool()
        end
        data.lFatigueLimit = {}
        for i=1,10 do
            data.lFatigueLimit[i] = luaFunc:readRecvLong()
        end

        data.szParameterName = {}
        for i = 1,10 do
            data.szParameterName[i] = luaFunc:readRecvString(32)
        end
        data.tableParameter = {}
        for i = 1,10 do
            local haveReadByte = 0
            data.tableParameter[i], haveReadByte = require("common.GameConfig"):getParameter(data.wKindID[i],luaFunc)
            if haveReadByte < 128 then
                luaFunc:readRecvBuffer(128-haveReadByte)
            end
        end

        data.dwTargetID = luaFunc:readRecvDWORD()

        EventMgr:dispatch(EventType.RET_REFRESH_CLUB_PLAY, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_SETTINGS_CLUB_PLAY then
        --返回设置亲友圈玩法
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.cbSettingsType = luaFunc:readRecvByte()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.cbPlayCount = luaFunc:readRecvByte()
        data.dwPlayID = {}
        for i = 1, 10 do
            data.dwPlayID[i] = luaFunc:readRecvDWORD()
        end
        data.wKindID = {}
        for i = 1,10 do
            data.wKindID[i] = luaFunc:readRecvWORD()
        end
        data.wGameCount = {}
        for i = 1,10 do
            data.wGameCount[i] = luaFunc:readRecvWORD()
        end
        data.wTableCell = {}
        for i = 1,10 do
            data.wTableCell[i] = luaFunc:readRecvWORD()
        end

        data.cbMode = {}
        for i=1, 10 do
            data.cbMode[i] = luaFunc:readRecvByte()
        end
        data.cbPayMode = {}
        for i=1,10 do
            data.cbPayMode[i] = luaFunc:readRecvByte()
        end

        data.dwPayLimit = {}
        for idx=1,10 do
            data.dwPayLimit[idx] = {}
            for i=1,3 do
                data.dwPayLimit[idx][i] = luaFunc:readRecvDWORD()
            end
        end
        data.dwPayCount = {}
        for idx=1,10 do
            data.dwPayCount[idx] = {}
            for i=1,3 do
                data.dwPayCount[idx][i] = luaFunc:readRecvDWORD()
            end
        end

        data.lTableLimit = {}
        for i=1,10 do
            data.lTableLimit[i] = luaFunc:readRecvLong()
        end
        data.wFatigueCell = {}
        for i=1,10 do
            data.wFatigueCell[i] = luaFunc:readRecvWORD()
        end
        data.isTableCharge = {}
        for i=1,10 do
            data.isTableCharge[i] = luaFunc:readRecvBool()
        end
        data.lFatigueLimit = {}
        for i=1,10 do
            data.lFatigueLimit[i] = luaFunc:readRecvLong()
        end

        data.szParameterName = {}
        for i = 1,10 do
            data.szParameterName[i] = luaFunc:readRecvString(32)
        end
        data.tableParameter = {}
        for i = 1,10 do
            local haveReadByte = 0
            data.tableParameter[i], haveReadByte = require("common.GameConfig"):getParameter(data.wKindID[i],luaFunc)
            if haveReadByte < 128 then
                luaFunc:readRecvBuffer(128-haveReadByte)
            end
        end

        data.dwTargetID = luaFunc:readRecvDWORD()

        EventMgr:dispatch(EventType.RET_SETTINGS_CLUB_PLAY, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_SETTINGS_CLUB_MEMBER then
        --返回修改亲友圈成员
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.cbSettingsType = luaFunc:readRecvByte()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwLastLoginTime = luaFunc:readRecvDWORD()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOffice = luaFunc:readRecvByte()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.isProhibit = luaFunc:readRecvBool()
        data.szRemarks = luaFunc:readRecvString(32)
        data.lFatigueValue = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_SETTINGS_CLUB_MEMBER, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_PARTNER then
        --返回亲友圈合伙人
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.lScore = luaFunc:readRecvLong()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwCompleteGameCount = luaFunc:readRecvDWORD()
        data.dwPlayerCount = luaFunc:readRecvDWORD()
        data.lFatigue = luaFunc:readRecvLong()
        data.lYuanBaoCount = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_GET_CLUB_PARTNER, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_PARTNER_FINISH then
        --返回亲友圈合伙人完成
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_PARTNER_FINISH, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_PARTNER_MEMBER then
        --返回亲友圈合伙人成员
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.lScore = luaFunc:readRecvLong()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwCompleteGameCount = luaFunc:readRecvDWORD()
        data.dwPlayerCount = luaFunc:readRecvDWORD()
        data.lFatigue = luaFunc:readRecvLong()
        data.lYuanBaoCount = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_GET_CLUB_PARTNER_MEMBER, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_PARTNER_MEMBER_FINISH then
        --返回亲友圈合伙人成员
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_PARTNER_MEMBER_FINISH, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_NOT_PARTNER_MEMBER then
        --返回亲友圈非合伙人成员
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwLastLoginTime = luaFunc:readRecvDWORD()
        data.isEnd = luaFunc:readRecvBool()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOffice = luaFunc:readRecvByte()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.isProhibit = luaFunc:readRecvBool()
        data.szRemarks = luaFunc:readRecvString(32)
        data.lFatigueValue = luaFunc:readRecvLong()
        -- data.dwACard = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH then
        --返回亲友圈非合伙人成员
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_FIND_CLUB_NOT_PARTNER_MEMBER then
        --返回查找亲友圈非合伙人成员
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwLastLoginTime = luaFunc:readRecvDWORD()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOffice = luaFunc:readRecvByte()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.isProhibit = luaFunc:readRecvBool()
        data.szRemarks = luaFunc:readRecvString(32)
        data.lFatigueValue = luaFunc:readRecvLong()
        -- data.dwACard = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_FIND_CLUB_PARTNER_MEMBER then
        --返回查找亲友圈合伙人成员
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.lScore = luaFunc:readRecvLong()
        data.dwWinnerCount = luaFunc:readRecvDWORD()
        data.dwGameCount = luaFunc:readRecvDWORD()
        data.dwCompleteGameCount = luaFunc:readRecvDWORD()
        data.dwPlayerCount = luaFunc:readRecvDWORD()
        data.lFatigue = luaFunc:readRecvLong()
        data.lYuanBaoCount = luaFunc:readRecvLong()
        EventMgr:dispatch(EventType.RET_FIND_CLUB_PARTNER_MEMBER, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_MEMBER_FATIGUE_RECORD then
        --返回俱乐部成员疲劳值记录
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.cbType = luaFunc:readRecvByte()
        data.lOldFatigue = luaFunc:readRecvLong()
        data.lFatigue = luaFunc:readRecvLong()
        data.lNewFatigue = luaFunc:readRecvLong()
        data.dwOperTime = luaFunc:readRecvDWORD()
        data.szDesc = luaFunc:readRecvString(64)
        data.dwOriginID = luaFunc:readRecvDWORD()
        data.szOriginNickName = luaFunc:readRecvString(32)
        data.szOriginLogoInfo = luaFunc:readRecvString(256)
        EventMgr:dispatch(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH then
        --返回俱乐部成员疲劳值记录
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH, data)

    elseif mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_UPDATE_CLUB_PLAYER_INFO then
        --获取疲劳值
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOffice = luaFunc:readRecvByte()
        data.dwPartnerID = luaFunc:readRecvDWORD()
        data.isProhibit = luaFunc:readRecvBool()
        data.szRemarks = luaFunc:readRecvString(32)
        data.lFatigueValue = luaFunc:readRecvLong()
        -- data.dwACard = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_UPDATE_CLUB_PLAYER_INFO, data)

    else
        return
    end
end

function Guild:EVENT_TYPE_FIRST_ENTER_HALL(event)
    self:getGuildInfo()
    self.tableLastUseClubRecord = self:readLastUseClubRecord()
end

--获取公会信息
function Guild:getGuildInfo()
    self.dwGuildID = 0                      --公会ID
    self.szGuildName = ""                   --公会名字
    self.szGuildNotice = ""                 --公会公告
    self.dwMemberCount = 0                  --公会成员数量
    self.dwPresidentID = 0                  --代理ID
    self.szPresidentName = ""               --代理名字
    self.szPresidentLogo = ""               --代理头像
	-- NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_GUILD,NetMsgId.REQ_GET_GUILD_INFO,"")
end

--查询公会
function Guild:getGuildInfoByGuildID(dwGuildID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_GUILD,NetMsgId.REQ_GET_GUILD_INFO_BY_GUILDID,"d",dwGuildID)
end

--加入公会
function Guild:joinGuild(dwGuildID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_GUILD,NetMsgId.REQ_JOIN_GUILD,"d",dwGuildID)
end

----------------------------------------------------------------------------------------------------

--创建亲友圈
function Guild:createClub(szClubName)
    local UserData = require("app.user.UserData")
    if (CHANNEL_ID == 10 or CHANNEL_ID == 11) and UserData.Bag:getBagPropCount(1003) < 200 then
        local data = {}
        data.lRet = 1002
        EventMgr:dispatch(EventType.RET_CREATE_CLUB,data)
        return
    end
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_CREATE_CLUB3,"dns",UserData.User.userID,32,szClubName)
end

--加入亲友圈
function Guild:joinClub(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_JOIN_CLUB,"d",dwClubID)
end

--获取亲友圈审核列表
function Guild:getClubCheckList(dwClubID)
    self.szApplicationList = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_CLUB_CHECK_LIST,"d",dwClubID)
end

--请求同意或拒绝加入亲友圈
function Guild:checkClubResult(dwClubID,dwUserID,isAgree)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_CLUB_CHECK_RESULT,"ddo",dwClubID,dwUserID,isAgree)
end

--获取亲友圈成员列表
function Guild:getClubMember(dwClubID,beginPos,endPos)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_MEMBER,"dww",dwClubID,beginPos,endPos)
end

--请求删除亲友圈成员
function Guild:removeClubMember(dwClubID,dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_REMOVE_CLUB_MEMBER,"dd",dwClubID,dwUserID)
end

--获取亲友圈列表
function Guild:getClubList()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_LIST3,"")
end

--请求退出亲友圈
function Guild:quitClub(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_QUIT_CLUB,"d",dwClubID)
end

--请求解散亲友圈
function Guild:removeClub(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_REMOVE_CLUB,"d",dwClubID)
end

--获取亲友圈桌子列表
function Guild:getClubTable(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_TABLE,"d",dwClubID)
end

--刷新亲友圈
function Guild:refreshClub(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_REFRESH_CLUB3,"d",dwClubID)
end

--获取亲友圈以外可以导入的成员
function Guild:getClubExMember(dwClubID, dwUserID,beginPos,endPos)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_MEMBER_EX,"ddww",dwClubID, dwUserID,beginPos,endPos)
end

--添加亲友圈成员
function Guild:addClubMember(dwClubID, dwUserID, dwAdministratorID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_ADD_CLUB_MEMBER,"ddd",dwClubID, dwUserID, dwAdministratorID)
end

--添加亲友圈及时刷新列表
function Guild:addEnterClub(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_ADD_CLUB_REFRESH_MEMBER, "d", dwClubID)
end

--删除亲友圈及时刷新列表
function Guild:removeCloseClub(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_DEL_CLUB_REFRESH_MEMBER, "d", dwClubID)
end

--请求解散亲友圈桌子
function Guild:exitClubTable(dwUserID, dwTableID, dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_DISBAND_CLUB_TABLE, "ddd", dwUserID,dwTableID,dwClubID)
end

--获取亲友圈的房卡
function Guild:getClubCardInfo(dwClubID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_UPDATE_CLUB_ROOMCARD, "d", dwClubID)
end

--获取亲友圈的申请记录
function Guild:getClubApplyInfo(dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_APPLICATION_RECORD, "d", dwUserID)
end

--查看亲友圈成员列表
function Guild:findClubMemInfo(dwClubID, dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_FIND_CLUB_MEMBER, "dd", dwClubID, dwUserID)
end

--保存亲友圈排序
function Guild:saveLastUseClubRecord(dwClubID)
    local tableLastUseClubRecord = self:readLastUseClubRecord()
    for key, var in pairs(tableLastUseClubRecord) do
    	if var == dwClubID then
            table.remove(tableLastUseClubRecord,key)
    	    break
    	end
    end
    for i = 5, #tableLastUseClubRecord do
        table.remove(tableLastUseClubRecord,#tableLastUseClubRecord)
    end
    table.insert(tableLastUseClubRecord,1,dwClubID)
    local data = json.encode(tableLastUseClubRecord)
    local fp = io.open(FileName.tableLastUseClubRecord, "wb+")
    fp:write(data)
    fp:close()
    
    self.tableLastUseClubRecord = tableLastUseClubRecord
end

--读取亲友圈排序
function Guild:readLastUseClubRecord()
    local tableLastUseClubRecord = {}
    if cc.FileUtils:getInstance():isFileExist(FileName.tableLastUseClubRecord) == false then
        return tableLastUseClubRecord
    end
    local fileData = cc.FileUtils:getInstance():getStringFromFile(FileName.tableLastUseClubRecord)
    if fileData ~= nil and fileData ~= "" then
        tableLastUseClubRecord = json.decode(fileData)
    end
    return tableLastUseClubRecord
end

--获取俱乐部操作记录
function Guild:getClubCotrolRecord(dwClubID, dwTime)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_OPERATE_RECORD, "dd", dwClubID, dwTime)
end

---------------------------------------------
--请求修改亲友圈成员
function Guild:reqSettingsClubMember(cbSettingsType,dwClubID,dwUserID,dwPartner,szRemarks,lFatigue)
    lFatigue = lFatigue or 0
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_MEMBER, "bdddnsl", cbSettingsType, dwClubID, dwUserID,dwPartner, 32, szRemarks,lFatigue)
end

--请求亲友圈合伙人
function Guild:getClubPartner(dwClubID, dwPartnerID, dwBeganTime, dwEndTime, wPage, dwMinWinnerScore)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_PARTNER, "ddddwd", dwClubID, dwPartnerID,dwBeganTime, dwEndTime, wPage, dwMinWinnerScore)
end

--请求亲友圈合伙人成员
function Guild:getClubPartnerMember(dwClubID, dwPartnerID,dwParnterMemberID, dwBeganTime, dwEndTime, wPage, dwMinWinnerScore)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_PARTNER_MEMBER, "dddddwd", dwClubID, dwPartnerID,dwParnterMemberID, dwBeganTime, dwEndTime, wPage, dwMinWinnerScore)
end

--请求亲友圈非合伙人成员
function Guild:getClubNotPartnerMember(dwClubID, wBagenPos, wEndPos)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_NOT_PARTNER_MEMBER, "dww", dwClubID, wBagenPos, wEndPos)
end

--请求查找亲友圈非合伙人成员
function Guild:findClubNotPartnerMember(dwClubID, dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_FIND_CLUB_NOT_PARTNER_MEMBER, "dd", dwClubID, dwUserID)
end

--查找亲友圈合伙人成员
function Guild:findPartnerMember(dwClubID, dwPartnerID, dwParnterMemberID, dwBeganTime, dwEndTime, dwMinWinnerScore)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_FIND_CLUB_PARTNER_MEMBER, "dddddwd", dwClubID,dwPartnerID,dwParnterMemberID,dwBeganTime,dwEndTime,1,dwMinWinnerScore)
end

--请求俱乐部成员疲劳值记录
function Guild:getClubFatigueRecord(dwClubID, dwUserID, wPage)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_MEMBER_FATIGUE_RECORD, "ddw", dwClubID, dwUserID, wPage)
end

--请求疲劳值
function Guild:getUpdateClubInfo(dwClubID, dwUserID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_UPDATE_CLUB_PLAYER_INFO, "dd", dwClubID, dwUserID)
end

--请求亲友圈疲劳值统计
function Guild:getClubFatigueStatistics(dwClubID, wBagenPos, wEndPos)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_GET_CLUB_FATIGUE_STATISTICS, "dww", dwClubID, wBagenPos, wEndPos)
end

return Guild
