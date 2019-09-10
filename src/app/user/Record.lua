local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")

local Record = {

    }

function Record:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 
end

function Record:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 

end

function Record:EVENT_TYPE_NET_RECV_MESSAGE(event)
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

    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_CL_MAIN_RECORD_BY_TYPE0 then
        --个人普通房战绩
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.wGameCount = luaFunc:readRecvWORD()                     --创房局数
        data.wPlayCount = luaFunc:readRecvWORD()                     --游戏局数
        data.wServerID = luaFunc:readRecvWORD()                      --游戏服务
        data.wKindID = luaFunc:readRecvWORD()                        --游戏类型
        data.wCellScore = luaFunc:readRecvWORD()                      --桌子倍率
        data.wTableID = luaFunc:readRecvWORD()                        --桌子号
        data.dwPlayTimeStart = luaFunc:readRecvDWORD()                --开始时间
        data.dwPlayTimeCount = luaFunc:readRecvDWORD()               --游戏时长
        data.lScore = luaFunc:readRecvLong()                          --分数
        data.szMainGameID = luaFunc:readRecvString(32)                --游戏主ID
        data.dwUserID = luaFunc:readRecvDWORD()
        data.dwChannel = luaFunc:readRecvDWORD()
        data.dwTableOwnerID = luaFunc:readRecvDWORD()
        data.nTableType = luaFunc:readRecvInt()

        data.dwClubID = luaFunc:readRecvDWORD() --
        data.isBigWinner = luaFunc:readRecvBool()
        data.isExist    = luaFunc:readRecvBool()

        data.dwUserIDEx  = {}
        for i=1,8 do
            data.dwUserIDEx[i] = luaFunc:readRecvDWORD()          
        end
        data.lScoreEx = {}                                              --玩家分数
        for i=1,8 do
            data.lScoreEx[i] = luaFunc:readRecvLong()   
        end
        data.szNickNameEx = {}                                              --玩家昵称
        for i=1,8 do
            data.szNickNameEx[i] = luaFunc:readRecvString(32)  
        end


        EventMgr:dispatch(EventType.RET_CL_MAIN_RECORD_BY_TYPE0,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_CL_MAIN_RECORD_BY_TYPE1 then
        --个人所有亲友圈的战绩
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.wGameCount = luaFunc:readRecvWORD()                     --创房局数
        data.wPlayCount = luaFunc:readRecvWORD()                     --游戏局数
        data.wServerID = luaFunc:readRecvWORD()                      --游戏服务
        data.wKindID = luaFunc:readRecvWORD()                        --游戏类型
        data.wCellScore = luaFunc:readRecvWORD()                      --桌子倍率
        data.wTableID = luaFunc:readRecvWORD()                        --桌子号
        data.dwPlayTimeStart = luaFunc:readRecvDWORD()                --开始时间
        data.dwPlayTimeCount = luaFunc:readRecvDWORD()               --游戏时长
        data.lScore = luaFunc:readRecvLong()                          --分数
        data.szMainGameID = luaFunc:readRecvString(32)                --游戏主ID
        data.dwUserID = luaFunc:readRecvDWORD()
        data.dwChannel = luaFunc:readRecvDWORD()
        data.dwTableOwnerID = luaFunc:readRecvDWORD()
        data.nTableType = luaFunc:readRecvInt()

        data.dwClubID = luaFunc:readRecvDWORD() --
        data.isBigWinner = luaFunc:readRecvBool()
        data.isExist    = luaFunc:readRecvBool()
        data.dwUserIDEx  = {}
        for i=1,8 do
            data.dwUserIDEx[i] = luaFunc:readRecvDWORD()          
        end
        data.lScoreEx = {}                                              --玩家分数
        for i=1,8 do
            data.lScoreEx[i] = luaFunc:readRecvLong()   
        end
        data.szNickNameEx = {}                                              --玩家昵称
        for i=1,8 do
            data.szNickNameEx[i] = luaFunc:readRecvString(32)  
        end

        EventMgr:dispatch(EventType.RET_CL_MAIN_RECORD_BY_TYPE1,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_CL_MAIN_RECORD_TOTAL_SCORE then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.cbType = luaFunc:readRecvByte()
        data.lScore = {}
        data.lTypeScore = {}
        for i=0,2 do
            data.lScore[i] = luaFunc:readRecvLong()
        end
        for i=0,2 do
            data.lTypeScore[i] = luaFunc:readRecvLong()
        end
        EventMgr:dispatch(EventType.RET_CL_MAIN_RECORD_TOTAL_SCORE,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_CL_MAIN_RECORD_BY_TYPE2 then
        --根据个人ID和亲友圈ID的战绩
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.wGameCount = luaFunc:readRecvWORD()                     --创房局数
        data.wPlayCount = luaFunc:readRecvWORD()                     --游戏局数
        data.wServerID = luaFunc:readRecvWORD()                      --游戏服务
        data.wKindID = luaFunc:readRecvWORD()                        --游戏类型
        data.wCellScore = luaFunc:readRecvWORD()                      --桌子倍率
        data.wTableID = luaFunc:readRecvWORD()                        --桌子号
        data.dwPlayTimeStart = luaFunc:readRecvDWORD()                --开始时间
        data.dwPlayTimeCount = luaFunc:readRecvDWORD()               --游戏时长
        data.lScore = luaFunc:readRecvLong()                          --分数
        data.szMainGameID = luaFunc:readRecvString(32)                --游戏主ID
        data.dwUserID = luaFunc:readRecvDWORD()
        data.dwChannel = luaFunc:readRecvDWORD()
        data.dwTableOwnerID = luaFunc:readRecvDWORD()
        data.nTableType = luaFunc:readRecvInt()

        data.dwClubID = luaFunc:readRecvDWORD() --
        data.isBigWinner = luaFunc:readRecvBool()
        data.isExist    = luaFunc:readRecvBool()

        data.dwUserIDEx  = {}
        for i=1,8 do
            data.dwUserIDEx[i] = luaFunc:readRecvDWORD()          
        end
        data.lScoreEx = {}                                              --玩家分数
        for i=1,8 do
            data.lScoreEx[i] = luaFunc:readRecvLong()   
        end
        data.szNickNameEx = {}                                              --玩家昵称
        for i=1,8 do
            data.szNickNameEx[i] = luaFunc:readRecvString(32)  
        end

        EventMgr:dispatch(EventType.RET_CL_MAIN_RECORD_BY_TYPE2,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_CL_MAIN_RECORD_BY_TYPE3 then
        --根据亲友圈ID的战绩
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.wGameCount = luaFunc:readRecvWORD()                     --创房局数
        data.wPlayCount = luaFunc:readRecvWORD()                     --游戏局数
        data.wServerID = luaFunc:readRecvWORD()                      --游戏服务
        data.wKindID = luaFunc:readRecvWORD()                        --游戏类型
        data.wCellScore = luaFunc:readRecvWORD()                      --桌子倍率
        data.wTableID = luaFunc:readRecvWORD()                        --桌子号
        data.dwPlayTimeStart = luaFunc:readRecvDWORD()                --开始时间
        data.dwPlayTimeCount = luaFunc:readRecvDWORD()               --游戏时长
        data.lScore = luaFunc:readRecvLong()                          --分数
        data.szMainGameID = luaFunc:readRecvString(32)                --游戏主ID
        data.dwUserID = luaFunc:readRecvDWORD()
        data.dwChannel = luaFunc:readRecvDWORD()
        data.dwTableOwnerID = luaFunc:readRecvDWORD()
        data.nTableType = luaFunc:readRecvInt()

        data.dwClubID = luaFunc:readRecvDWORD() --
        data.isBigWinner = luaFunc:readRecvBool()
        data.isExist    = luaFunc:readRecvBool()

        data.dwUserIDEx  = {}
        for i=1,8 do
            data.dwUserIDEx[i] = luaFunc:readRecvDWORD()          
        end
        data.lScoreEx = {}                                              --玩家分数
        for i=1,8 do
            data.lScoreEx[i] = luaFunc:readRecvLong()   
        end
        data.szNickNameEx = {}                                              --玩家昵称
        for i=1,8 do
            data.szNickNameEx[i] = luaFunc:readRecvString(32)  
        end

        EventMgr:dispatch(EventType.RET_CL_MAIN_RECORD_BY_TYPE3,data)

    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_MAIN_RECORD_FINISH then
        --获取战绩结束
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.cbType = luaFunc:readRecvByte()
        data.isFinish  = luaFunc:readRecvBool()
        data.cbDay     = luaFunc:readRecvByte()
        EventMgr:dispatch(EventType.SUB_CL_MAIN_RECORD_FINISH,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_RECORD then
        print("获取小战绩")
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.wGameIndex = luaFunc:readRecvWORD()                         --第几局
        data.wBankerChairID = luaFunc:readRecvWORD()                     --庄家
        data.wChairCount = luaFunc:readRecvWORD()                        --椅子数目
        data.dwPlayTimeStart = luaFunc:readRecvDWORD()                   --开始时间
        data.dwPlayTimeCount = luaFunc:readRecvDWORD()                   --游戏时长
        data.dwUserID = {}                                              --所有玩家ID
        for i=1,8 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()          
        end
        data.lScore = {}                                              --玩家分数
        for i=1,8 do
            data.lScore[i] = luaFunc:readRecvLong()   
        end
        data.szNickName = {}                                              --玩家昵称
        for i=1,8 do
            data.szNickName[i] = luaFunc:readRecvString(32)  
        end

        data.szSubGameID = luaFunc:readRecvString(32)            --游戏主ID

        EventMgr:dispatch(EventType.SUB_CL_SUB_RECORD,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_RECORD_FINISH then
        print("获取小战绩结束")
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_REPLAY then
        print("获取回放小局")
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.wKindID = luaFunc:readRecvWORD()
        data.wTotalSize = luaFunc:readRecvWORD()                      --数据总大小
        data.wPos = luaFunc:readRecvWORD()                          --数据位置
        data.wDataSize = luaFunc:readRecvWORD()                            --数据大小
        data.szMD5 = luaFunc:readRecvString(36)                             --MD5
        data.cbData = luaFunc:readRecvBuffer(data.wDataSize)
        if data.wPos == 0 then
            self.playbackData = {}
            table.insert(self.playbackData,#self.playbackData+1,data)
            if data.wDataSize >= data.wTotalSize then
                EventMgr:dispatch(EventType.SUB_CL_SUB_REPLAY,self.playbackData)
            end
        elseif data.wPos + data.wDataSize >= data.wTotalSize then
            table.insert(self.playbackData,#self.playbackData+1,data)
            EventMgr:dispatch(EventType.SUB_CL_SUB_REPLAY,self.playbackData)
        else
            table.insert(self.playbackData,#self.playbackData+1,data)
        end
        
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_SHARE_REPLAY_BASE then
        print("回放桌子信息(分享)")
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        --data.wTableID = luaFunc:readRecvWORD(2)                                 --桌子号
        data.dwPlayTimeCount = luaFunc:readRecvDWORD()                          --游戏时长
        data.dwUserID = {}
        for i = 1,8 do
            data.dwUserID[i] = luaFunc:readRecvDWORD()                          --所有玩家ID
        end
        data.szNickName = {}
        for i = 1,8 do
            data.szNickName[i] = luaFunc:readRecvString(32)                     --玩家昵称
        end
        EventMgr:dispatch(EventType.SUB_CL_SUB_SHARE_REPLAY_BASE,data)   
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_SHARE_REPLAY_DATA then
        print("获取回放分享")
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.wKindID = luaFunc:readRecvWORD()    
        data.wTotalSize = luaFunc:readRecvWORD()                      --数据总大小
        data.wPos = luaFunc:readRecvWORD()                          --数据位置
        data.wDataSize = luaFunc:readRecvWORD()                            --数据大小
        data.szMD5 = luaFunc:readRecvString(36)                             --MD5
        data.cbData = luaFunc:readRecvBuffer(data.wDataSize)
        if data.wPos == 0 then
            self.playbackData = {}
            table.insert(self.playbackData,#self.playbackData+1,data)
        else
            table.insert(self.playbackData,#self.playbackData+1,data)
        end
        if data.wPos + data.wDataSize >= data.wTotalSize then
            EventMgr:dispatch(EventType.SUB_CL_SUB_SHARE_REPLAY_DATA,self.playbackData)
        end
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_SHARE_REPLAY_NOTFOUNT then
        require("common.MsgBoxLayer"):create(0,nil,"该回放未找到")
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_REPLAY_SHAREID then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.szShareID = luaFunc:readRecvString(12)                             --分享ID
        print("获取回放分享ID",data.szShareID)
        EventMgr:dispatch(EventType.SUB_CL_SUB_REPLAY_SHAREID,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.SUB_CL_SUB_REPLAY_SHAREID_ERROR then
        require("common.MsgBoxLayer"):create(0,nil,"回放分享ID分配失败")
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_SC_SUB_GET_PROXY_RECORD then
        local luaFunc = NetMgr:getLogicInstance().cppFunc                                    
        local data = {}
        data.dwOperTime = luaFunc:readRecvDWORD()
        data.wKindID = luaFunc:readRecvWORD()
        data.wGameCount = luaFunc:readRecvWORD()
        data.wExpendType = luaFunc:readRecvWORD(2)
        data.dwExpendSubType = luaFunc:readRecvDWORD()
        data.dwExpendCount = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szWinNickName = luaFunc:readRecvString(32)
        EventMgr:dispatch(EventType.RET_SC_SUB_GET_PROXY_RECORD,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_RECORD and subCmdID == NetMsgId.RET_SC_SUB_GET_PROXY_TABLE then
        local luaFunc = NetMgr:getLogicInstance().cppFunc
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
        data.tableParameter = require("common.GameConfig"):getParameter(wKindID,luaFunc)
        EventMgr:dispatch(EventType.RET_SC_SUB_GET_PROXY_TABLE,data)
       
    else

        return
    end    


end

function Record:EVENT_TYPE_FIRST_ENTER_HALL(event)

end

--发送战绩大局消息
function Record:sendMsgGetMainRecord(cbType, dwClubID, dwCount, szMainGameID,dwUserID,cbDay)
--    BYTE                                cbType;                         //类型    0个人普通房战绩    1个人亲友圈战绩 2个人所在亲友圈战绩 3亲友圈战绩
--    DWORD                               dwClubID;                       //亲友圈ID
--    DWORD                               dwCount;                        //单次获取的数量
--    TCHAR                               szMainGameID[32];               //上一次的战绩ID
--    cbDay                               cbDay                            --日期
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CL_MAIN_RECORD_BY_TYPE,"bdddnsb",cbType, dwClubID,dwUserID, dwCount, 32, szMainGameID,cbDay)
end

--发送战绩子局消息
function Record:sendMsgGetSubRecord(szMainGameID)
    if NetMgr:getLogicInstance().connected then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CL_SUB_RECORD,"ns",32,szMainGameID)
    end
end
--请求回放(小局)
function Record:sendMsgGetMainReplay(szMainGameID)
    if NetMgr:getLogicInstance().connected then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CL_SUB_REPLAY,"ns",32,szMainGameID)
        print("请求回放(小局)",szMainGameID)
    end
end
--请求分享回放(小局)
function Record:sendMsgGetMainShare(szMainGameID)
    if NetMgr:getLogicInstance().connected then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CL_SUB_SHARE_REPLAY,"ns",32,szMainGameID)
    end
end
--请求回放的分享ID
function Record:REQ_CL_SUB_GET_REPLAY_SHAREID(wKindID, szMainGameID,szSubGameID)
    if NetMgr:getLogicInstance().connected then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CL_SUB_GET_REPLAY_SHAREID,"nsnsw",32,szMainGameID,32,szSubGameID,wKindID)
    end
end
--用分享ID请求回放
function Record:SUB_CL_SUB_GET_REPLAY_BY_SHAREID(szShareID)
    if NetMgr:getLogicInstance().connected then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.SUB_CL_SUB_GET_REPLAY_BY_SHAREID,"ns",12,szShareID)
    end
end

--请求代开记录
function Record:sendMsgGetGuildRecord(startPos,overPos)
    if NetMgr:getLogicInstance().connected then
        local UserData = require("app.user.UserData")
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CS_SUB_GET_GUILD_RECORD,"dww",UserData.User.userID,startPos,overPos)
    end
end

--请求公会房记录
function Record:sendMsgGetProxyRecord(startPos,overPos)
    if NetMgr:getLogicInstance().connected then
        local UserData = require("app.user.UserData")
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CS_SUB_GET_PROXY_RECORD,"dww",UserData.User.userID,startPos,overPos)
    end
end

--请求代开房间
function Record:sendMsgGetProxyRoomTable()
    if NetMgr:getLogicInstance().connected then
        local UserData = require("app.user.UserData")
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_RECORD, NetMsgId.REQ_CS_SUB_GET_PROXY_TABLE,"")
    end
end


return Record