local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local Default = require("common.Default")

local Chat = {}



function Chat:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE) 
    self.chatShareData = {};--保存分享数据
    -- EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 
end

function Chat:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE) 
    -- EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 
end

function Chat:EVENT_TYPE_NET_RECV_MESSAGE(event)
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
    --返回聊天
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB  and subCmdID == NetMsgId.RET_CLUB_CHAT_MSG then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD() --俱乐部id
        data.cbType    = luaFunc:readRecvByte() --消息类型
        data.ullSign   = luaFunc:readRecvUnsignedLongLong() --标志
        data.dwUserID = luaFunc:readRecvDWORD() --用户ID
        data.szNickName = luaFunc:readRecvString(32) --用户名
        data.szLogoInfo = luaFunc:readRecvString(256) --用户头像
        local wd = luaFunc:readRecvWORD()
        if data.cbType == 0 then --文字
            data.szContents = luaFunc:readRecvString(256)
        elseif data.cbType == 1 then --表情
            data.cbExpression =  luaFunc:readRecvByte()
        elseif data.cbType == 2 then -- 语音
            data.szVoiceSign = luaFunc:readRecvString(64)
            data.szTime      = luaFunc:readRecvDWORD()
            data.bHaveRead   = luaFunc:readRecvBool() --是否已读
        elseif data.cbType == 3 then --创房
            data.dwTableID = luaFunc:readRecvDWORD()
            data.dwPlayID = luaFunc:readRecvDWORD()
            data.wKindID = luaFunc:readRecvWORD()
            data.wGameCount = luaFunc:readRecvWORD()
        elseif data.cbType == 4 then -- 大结算
            data.dwTableID = luaFunc:readRecvDWORD()
            data.dwPlayID  = luaFunc:readRecvDWORD()
            data.wKindID = luaFunc:readRecvWORD()
            data.cbPaymentMode = luaFunc:readRecvByte()
            data.cbPlayCount  = luaFunc:readRecvByte()
            data.wGameCount = luaFunc:readRecvWORD()
            data.wCurrentGameCount = luaFunc:readRecvWORD()
            data.dwUserID = {}
            for i = 1,8 do
                data.dwUserID[i] = luaFunc:readRecvDWORD()                          --所有玩家ID
            end
            data.szNickName = {}
            for i = 1,8 do
                data.szNickName[i] = luaFunc:readRecvString(32)                     --玩家昵称
            end
            data.lScore = {}
            for i = 1, 8 do
                data.lScore[i] = luaFunc:readRecvLong()
            end
            data.szGameID = luaFunc:readRecvString(32)
        elseif data.cbType == 5 then --组局
            data.dwTargetID = luaFunc:readRecvDWORD()
            data.szClubName = luaFunc:readRecvString(32) --亲友圈名字
            data.szClubLogoInfo = luaFunc:readRecvString(256) --用户头像
            data.dwTableID = luaFunc:readRecvDWORD()
            data.wGameCount = luaFunc:readRecvWORD()
            data.wKindID = luaFunc:readRecvWORD()
            local haveReadByte = 0
            data.tableParameter, haveReadByte = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
            if haveReadByte < 128 then
                luaFunc:readRecvBuffer(128-haveReadByte)
            end
        end
        if data.cbType == 5 then
            EventMgr:dispatch(EventType.RET_CLUB_CHAT_BACK_RECORD,data)
        else
            EventMgr:dispatch(EventType.RET_CLUB_CHAT_MSG,data)
        end
    --返回聊天记录
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB  and subCmdID == NetMsgId.RET_CLUB_CHAT_RECORD then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD() --俱乐部id
        data.cbType    = luaFunc:readRecvByte() --消息类型
        data.ullSign   = luaFunc:readRecvUnsignedLongLong() --标志
        data.dwUserID = luaFunc:readRecvDWORD() --用户ID
        data.szNickName = luaFunc:readRecvString(32) --用户名
        data.szLogoInfo = luaFunc:readRecvString(256) --用户头像
        local wd = luaFunc:readRecvWORD()
        if data.cbType == 0 then --文字
            data.szContents = luaFunc:readRecvString(256)
        elseif data.cbType == 1 then --表情
            data.cbExpression =  luaFunc:readRecvByte()
        elseif data.cbType == 2 then -- 语音
            data.szVoiceSign = luaFunc:readRecvString(64)
            data.szTime      = luaFunc:readRecvDWORD()
            data.bHaveRead   = luaFunc:readRecvBool() --是否已读
        elseif data.cbType == 3 then --创房
            data.dwTableID = luaFunc:readRecvDWORD()
            data.dwPlayID = luaFunc:readRecvDWORD()
            data.wKindID = luaFunc:readRecvWORD()
            data.wGameCount = luaFunc:readRecvWORD()
        elseif data.cbType == 4 then -- 大结算
            data.dwTableID = luaFunc:readRecvDWORD()
            data.dwPlayID  = luaFunc:readRecvDWORD()
            data.wKindID = luaFunc:readRecvWORD()
            data.cbPaymentMode = luaFunc:readRecvByte()
            data.cbPlayCount  = luaFunc:readRecvByte()
            data.wGameCount = luaFunc:readRecvWORD()
            data.wCurrentGameCount = luaFunc:readRecvWORD()
            data.dwUserID = {}
            for i = 1,8 do
                data.dwUserID[i] = luaFunc:readRecvDWORD()                          --所有玩家ID
            end
            data.szNickName = {}
            for i = 1,8 do
                data.szNickName[i] = luaFunc:readRecvString(32)                     --玩家昵称
            end
            data.lScore = {}
            for i = 1, 8 do
                data.lScore[i] = luaFunc:readRecvLong()
            end
            data.szGameID = luaFunc:readRecvString(32)
        elseif data.cbType == 5 then --组局
            data.dwTargetID = luaFunc:readRecvDWORD()
            data.szClubName = luaFunc:readRecvString(32) --亲友圈名字
            data.szLogoInfo = luaFunc:readRecvString(256) --用户头像
            data.dwTableID = luaFunc:readRecvDWORD()
            data.wGameCount = luaFunc:readRecvWORD()
            data.wKindID = luaFunc:readRecvWORD()
            local haveReadByte = 0
            data.tableParameter, haveReadByte = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
            if haveReadByte < 128 then
                luaFunc:readRecvBuffer(128-haveReadByte)
            end
        end
        if data.cbType == 5 then
            EventMgr:dispatch(EventType.RET_CLUB_CHAT_RECORD_ZUJU,data)
        else
            EventMgr:dispatch(EventType.RET_CLUB_CHAT_RECORD,data)
        end

        
    --请求聊天记录结束
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB  and subCmdID == NetMsgId.RET_CLUB_CHAT_RECORD_FINISH then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_CLUB_CHAT_RECORD_FINISH,data) 
    --聊天室亲友圈列表
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_CLUB_CHAT_GET_UNREAD_MSG then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwClubID    = luaFunc:readRecvDWORD() --亲友圈id
        data.isHaveMsg   = luaFunc:readRecvBool() --是否有新消息
        data.szClubName = luaFunc:readRecvString(32) --亲友圈名字
        data.dwUserID   = luaFunc:readRecvDWORD() -- 用户id
        data.szNickName = luaFunc:readRecvString(32) --用户名
        data.szLogoInfo = luaFunc:readRecvString(256) --用户头像
        data.dwClubPlayerCount = luaFunc:readRecvDWORD() -- 俱乐部人数
        EventMgr:dispatch(EventType.RET_CLUB_CHAT_GET_UNREAD_MSG,data) 
        
    --聊天消息返回失败
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_CLUB_CHAT_GET_UNREAD_MSG_FAIL then
        EventMgr:dispatch(EventType.RET_CLUB_CHAT_GET_UNREAD_MSG_FAIL) 
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CLUB and subCmdID == NetMsgId.RET_GET_CHAT_CONFIG then
        --聊天配置
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {} 
        data.dwConfigID = luaFunc:readRecvDWORD()
        data.dwChannelID = luaFunc:readRecvDWORD()
        data.szChatUrl = luaFunc:readRecvString(128)
        self.chatShareData = data;
    end
end

function Chat:isHaveChatShare( ... )
    if self.chatShareData then
        return self.chatShareData.dwConfigID == 0
    end
    return false
end

--聊天
function Chat:sendChat()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_GET_CHAT_CONFIG,"")
end

--文字
function Chat:SendChatWordMsg( clubID,userID,szNickName,logoInfo,szContents)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_CLUB_CHAT_MSG,"dbkdnsnswns",clubID,0,0,userID,32,szNickName,256,logoInfo,0,256,szContents)
end
--表情
function Chat:SendChatExp( clubID,userID,szNickName,logoInfo,expression )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_CLUB_CHAT_MSG,"dbkdnsnswb",clubID,1,0,userID,32,szNickName,256,logoInfo,0,expression)
end
--声音
function Chat:SendVoice( clubID,userID,szNickName,logoInfo,szvoiceSign,szTime)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_CLUB_CHAT_MSG,"dbkdnsnswnsdo",clubID,2,0,userID,32,szNickName,256,logoInfo,0,64,szvoiceSign,szTime,false)
end

--请求历史记录
function Chat:SendRecordMsg( clubID,ullSign )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_CLUB_CHAT_RECORD,"dk",clubID,ullSign)
end

--发送红点状态
function Chat:SendHeadState(clubID ,ullSign )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_CLUB_CHAT_HAVE_READ_MSG,"dk",clubID,ullSign)
end

--获取未读消息
function Chat:SendChatUnReadMsg( )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_CLUB_CHAT_GET_UNREAD_MSG,'')
end

--亲友圈列表红点
function Chat:sendHasReadMsg( clubID )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_CLUB_CHAT_SET_READ_MSG_TIME,"d",clubID)
end

--添加聊天更新到俱乐部
function Chat:addRefreshChatMember( dwClubID )
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_ADD_CLUB_CHAT_REFRESH_MEMBER,"d",dwClubID)
end

--删除聊天及时刷新列表
function Chat:delClubRefreshMember()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB, NetMsgId.REQ_DEL_CLUB_CHAT_REFRESH_MEMBER,"d",0)
end

return Chat