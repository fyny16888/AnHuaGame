local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local json = require("json")
local Default = require("common.Default")
local LocationSystem = require("common.LocationSystem")

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

--cc.exports.TableType_GuildRoom = 1    --公会房
cc.exports.TableType_FriendRoom = 0   --好友房
--cc.exports.TableType_HelpRoom = -1    --代开房
cc.exports.TableType_ClubRoom = -2    --亲友圈房
cc.exports.TableType_GoldRoom = -11   --金币房
--cc.exports.TableType_SportsRoom = -12 --竞技房
cc.exports.TableType_RedEnvelopeRoom = -13--红包房
cc.exports.TableType_Playback = -100  --回放

local Game = {
    className = "com/coco2dx/org/HelperAndroid",
    
    tableGames = {},                --游戏列表
    tableSortGames = {},            --游戏列表已排序
    talbeCommonGames = {},          --常玩游戏列表     
 }

function Game:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Game:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function Game:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    elseif netID == NetMgr.NET_GAME then
        netInstance = NetMgr:getGameInstance()
    else
        return
    end

    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_USER_LOCK_SERVER then
        print("检测玩家是否正在游戏房中")      
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.cbPlaying = luaFunc:readRecvByte()
        data.wKindID = luaFunc:readRecvWORD()--名称号码
        data.wServerPort = luaFunc:readRecvWORD()--房间端口
        data.dwServerAddr = luaFunc:readRecvDWORD()--房间地址
        data.szServerName = luaFunc:readRecvString(32)--房间名称
        EventMgr:dispatch(EventType.SUB_CL_USER_LOCK_SERVER,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_GOLDROOM_CONFIG then
        --返回金币场配置
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwChannelID = luaFunc:readRecvDWORD()      --单元积分
        data.wKindID = luaFunc:readRecvWORD()           --游戏ID
        data.cbLevel = luaFunc:readRecvByte()           --等级
        data.wChairCount = luaFunc:readRecvWORD()       --玩家数量
        data.wCellScore = luaFunc:readRecvDWORD()      --单元积分
        data.dwMinScore = luaFunc:readRecvDWORD()       --积分下线
        data.dwMaxScore = luaFunc:readRecvDWORD()       --积分上线
        EventMgr:dispatch(EventType.SUB_CL_GOLDROOM_CONFIG,data)
   
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_GOLDROOM_CONFIG_END then
        --返回金币场配置结束
        EventMgr:dispatch(EventType.SUB_CL_GOLDROOM_CONFIG_END)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_GAME_SERVER then
        print("获取房间ip地址和端口成功！")      
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.cbPlaying = luaFunc:readRecvByte()
        data.wKindID = luaFunc:readRecvWORD()--名称号码
        data.wServerPort = luaFunc:readRecvWORD()--房间端口
        data.dwServerAddr = luaFunc:readRecvDWORD()--房间地址
        data.szServerName = luaFunc:readRecvString(32)--房间名称
        EventMgr:dispatch(EventType.SUB_CL_GAME_SERVER,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_GAME_SERVER_ERROR then
        print("获取房间ip地址和端口失败！")
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        EventMgr:dispatch(EventType.SUB_CL_GAME_SERVER_ERROR,data)    
        
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_LOGON and subCmdID == NetMsgId.SUB_GR_LOGON_SUCCESS then
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.cbPlaying = luaFunc:readRecvByte()
        EventMgr:dispatch(EventType.SUB_GR_LOGON_SUCCESS,data)
        
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_LOGON and subCmdID == NetMsgId.SUB_GR_LOGON_ERROR then
        EventMgr:dispatch(EventType.SUB_GR_LOGON_ERROR)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_FRIENDROOM_CONFIG then 
        print("获取好友房参数")
        local luaFunc = NetMgr:getLogicInstance().cppFunc
        local data = {}
        data.dwChannelID = luaFunc:readRecvDWORD()      --渠道ID
        data.wKindID = luaFunc:readRecvWORD()         --游戏ID
        data.dwIndexes = luaFunc:readRecvWORD()        --局数索引
        data.wGameCount = luaFunc:readRecvWORD()      --游戏局数
        data.dwExpendType = luaFunc:readRecvWORD()     --消耗类型
        data.dwSubType = luaFunc:readRecvDWORD()        --消耗子类型
        data.dwExpendCount = luaFunc:readRecvDWORD()    --消耗数量
        data.szExtraInfo = luaFunc:readRecvString(32)   --附加信息
        EventMgr:dispatch(EventType.SUB_CL_FRIENDROOM_CONFIG,data)
    
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_HALL and subCmdID == NetMsgId.SUB_CL_FRIENDROOM_CONFIG_END then 
        print("获取好友房参数完成")
        EventMgr:dispatch(EventType.SUB_CL_FRIENDROOM_CONFIG_END) 
        
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.SUB_GR_MATCH_TABLE_ING then 
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.wTbaleID = luaFunc:readRecvDWORD()             --桌子ID
        data.bGameStart = luaFunc:readRecvBool()
        data.wKindID = luaFunc:readRecvWORD()
        data.nTableType = luaFunc:readRecvInt()             --房间类型
        data.dwUserID = luaFunc:readRecvDWORD()             --房主
        data.dwClubID = luaFunc:readRecvDWORD()             --亲友圈ID
        data.cbLevel = luaFunc:readRecvByte()
        data.wCellScore = luaFunc:readRecvWORD()            --用户 倍率
        data.wTableNumber = luaFunc:readRecvWORD()          --总局数
        data.wCurrentNumber = luaFunc:readRecvWORD()        --当前局数
        local haveReadByte = 0
        data.tableParameter, haveReadByte = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
        if haveReadByte < 128 then
            luaFunc:readRecvBuffer(128-haveReadByte)
        end
        data.szGameID = luaFunc:readRecvString(32)
        EventMgr:dispatch(EventType.SUB_GR_MATCH_TABLE_ING,data)
        
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.SUB_GR_MATCH_TABLE_FAILED then 
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.wErrorCode = luaFunc:readRecvWORD()
        EventMgr:dispatch(EventType.SUB_GR_MATCH_TABLE_FAILED,data)
    
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.SUB_GR_USER_ENTER then 
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.wTbaleID = luaFunc:readRecvDWORD()             --桌子ID
        data.bGameStart = luaFunc:readRecvBool()
        data.wKindID = luaFunc:readRecvWORD()
        data.nTableType = luaFunc:readRecvInt()             --房间类型
        data.dwUserID = luaFunc:readRecvDWORD()             --房主
        data.dwClubID = luaFunc:readRecvDWORD()             --亲友圈ID
        data.cbLevel = luaFunc:readRecvByte()
        data.wCellScore = luaFunc:readRecvWORD()            --用户 倍率
        data.wTableNumber = luaFunc:readRecvWORD()          --总局数
        data.wCurrentNumber = luaFunc:readRecvWORD()        --当前局数
        local haveReadByte = 0
        data.tableParameter, haveReadByte = require("common.GameConfig"):getParameter(data.wKindID,luaFunc)
        if haveReadByte < 128 then
            luaFunc:readRecvBuffer(128-haveReadByte)
        end
        data.szGameID = luaFunc:readRecvString(32)
        EventMgr:dispatch(EventType.SUB_GR_USER_ENTER,data)
 
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.SUB_GR_JOIN_TABLE_FAILED then 
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.wErrorCode = luaFunc:readRecvWORD()
        data.wKindID = luaFunc:readRecvWORD()
        EventMgr:dispatch(EventType.SUB_GR_JOIN_TABLE_FAILED,data)
        
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.SUB_GR_CREATE_TABLE_FAILED then 
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local errorID = luaFunc:readRecvWORD()
        EventMgr:dispatch(EventType.SUB_GR_CREATE_TABLE_FAILED,errorID)
        
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.REQ_GR_USER_CONTINUE_CLUB_FAILD then
        EventMgr:dispatch(EventType.REQ_GR_USER_CONTINUE_CLUB_FAILD)
    
    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.RET_GET_CLUB_ONLINE_MEMBER then
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwLastLoginTime = luaFunc:readRecvDWORD()
        data.isEnd = luaFunc:readRecvBool()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        EventMgr:dispatch(EventType.RET_GET_CLUB_ONLINE_MEMBER, data)

    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.RET_GET_CLUB_ONLINE_MEMBER_FINISH then
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.isFinish = luaFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_CLUB_ONLINE_MEMBER_FINISH, data)

    elseif netID == NetMgr.NET_GAME and mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.RET_FIND_CLUB_ONLINE_MEMBER then
        local luaFunc = NetMgr:getGameInstance().cppFunc
        local data = {}
        data.lRet = luaFunc:readRecvLong()
        data.dwClubID = luaFunc:readRecvDWORD()
        data.dwUserID = luaFunc:readRecvDWORD()
        data.szNickName = luaFunc:readRecvString(32)
        data.szLogoInfo = luaFunc:readRecvString(256)
        data.dwJoinTime = luaFunc:readRecvDWORD()
        data.cbOnlineStatus = luaFunc:readRecvByte()
        EventMgr:dispatch(EventType.RET_FIND_CLUB_ONLINE_MEMBER, data)

    elseif mainCmdID == NetMsgId.MDM_GR_USER and subCmdID == NetMsgId.RET_NOTICE_GAME_START then
        -- 通知牌桌人满进入
        print('通知牌桌人满进入')
        local luaFunc = netInstance.cppFunc
        local data = {}
        data.dwTableID = luaFunc:readRecvDWORD()
        data.dwTargetID = luaFunc:readRecvDWORD()
        EventMgr:dispatch(EventType.RET_NOTICE_GAME_START, data)
    end
    
end

--加载游戏
function Game:loadGameData()
	self.tableGames = {}
    local strGame = StaticData.Channels[CHANNEL_ID].games
    local tableGames = Common:stringSplit(strGame,";")
    for key, var in pairs(tableGames) do
        local wKindID = tonumber(var)
        if StaticData.Games[wKindID] ~= nil and self.tableGames[wKindID] == nil then
            self.tableGames[wKindID] = wKindID
        end
    end
    
    --游戏排序
    self.tableSortGames = {}
    if StaticData.Hide[CHANNEL_ID].btn6 == 1 then
        --根据所有地区排序
        local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
        local games = Common:stringSplit(StaticData.Regions[regionID].games,";")
        for key, var in pairs(games) do
            local wKindID = tonumber(var)
            if StaticData.Games[wKindID] ~= nil and self.tableGames[wKindID] ~= nil then
                table.insert(self.tableSortGames,#self.tableSortGames + 1,wKindID)
            end
        end
    else
        local tableGames = Common:stringSplit(strGame,";")
        for key, var in pairs(tableGames) do
            local wKindID = tonumber(var)
            if self.tableGames[wKindID] ~= nil then
                table.insert(self.tableSortGames,#self.tableSortGames + 1,wKindID)
            end
        end
    end
    
end
Game:loadGameData()

--常玩游戏
function Game:addCommonGames(wKindID)
    for key, var in pairs(self.talbeCommonGames) do
    	if var == wKindID then
            table.remove(self.talbeCommonGames,key)
            break
    	end
    end
    table.insert(self.talbeCommonGames,1,wKindID)
    local delCount = #self.talbeCommonGames - 6
    printInfo(self.talbeCommonGames)
    for i = 1, delCount do
        table.remove(self.talbeCommonGames,#self.talbeCommonGames)
    end
    self:saveCommonGames()
end

function Game:saveCommonGames()
    if #self.talbeCommonGames <= 0 then
        return
    end
    local data = json.encode(self.talbeCommonGames)
    local fp = io.open(FileName.talbeCommonGames,"wb+")
    fp:write(data)
    fp:close()
end

function Game:loadCommonGames()
	self.talbeCommonGames = {}
    if cc.FileUtils:getInstance():isFileExist(FileName.talbeCommonGames) == true then
        local fileData = cc.FileUtils:getInstance():getStringFromFile(FileName.talbeCommonGames)
        local jsonData = {}
        if fileData ~= nil and fileData ~= "" then
            jsonData = json.decode(fileData)     
            for key, var in pairs(jsonData) do
                table.insert(self.talbeCommonGames,#self.talbeCommonGames+1,var)
                if #self.talbeCommonGames >= 6 then
                    break
                end
            end   
        end
    end
    if #self.talbeCommonGames <= 0 then
        for key, var in pairs(self.tableSortGames) do
            table.insert(self.talbeCommonGames,#self.talbeCommonGames+1,var)
        	if #self.talbeCommonGames >= 6 then
        	   break
        	end
        end
    end
    for key, var in pairs(self.talbeCommonGames) do
    	printInfo(var)
    end
end
Game:loadCommonGames()

--游戏统计
function Game:addGameStatistics(wKindID)
    local count = cc.UserDefault:getInstance():getIntegerForKey(string.format(Default.UserDefault_GameStatistics,wKindID),0)
    count = count + 1
    cc.UserDefault:getInstance():setIntegerForKey(string.format(Default.UserDefault_GameStatistics,wKindID),count)
end

function Game:getGameStatistics()
    local totalCount = 0
    for key, var in pairs(self.tableGames) do
    	totalCount = totalCount + cc.UserDefault:getInstance():getIntegerForKey(string.format(Default.UserDefault_GameStatistics,var),0)
    end
    return totalCount 
end

--连接游戏服
function Game:sendMsgConnectGame(data)  
    local UserData = require("app.user.UserData")
    local function callback(ip, port)
        if ip ~= nil and port ~= nil and NetMgr:getGameInstance():connectGameSvr(ip,port) then
            NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_LOGON,NetMsgId.REQ_GR_LOGON_USERID,"daad",UserData.User.userID,LocationSystem.pos.x,LocationSystem.pos.y,UserData.User.localIp)
            self:addCommonGames(data.wKindID)
        else
            EventMgr:dispatch(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,data)    
        end
    end
    local UserLevel = UserData.User:readUserLevel()
    local ip = NetMgr:getGameInstance().cppFunc:int2ip(data.dwServerAddr)
    if Common:isDomain(data.szServerName) then
        ip = string.format(StaticData.Condition[UserLevel].gameIp,data.szServerName)
    end
    local port = data.wServerPort
    if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER and StaticData.Condition[UserLevel].isUseTaijidun == true and OPEN_TAIJIDUN == true then
        UserData.User:taijidun(StaticData.Condition[UserLevel].taijidunName,port,callback)
    else
        callback(ip, port)
    end
end

--请求房间信息,这里获取的是房间的ip和地址
function Game:sendMsgGetRoomInfo(wKindID, wType)
    if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
        wType = 0
    end
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL, NetMsgId.REQ_CL_GAME_SERVER,"w",wKindID)
end

--检测是否在游戏中
function Game:sendMsgCheckIsPlaying()
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL, NetMsgId.REQ_CL_USER_LOCK_SERVER,"")
end

--获取好友房配置
function Game:sendMsgGetFriendsRoomParam(wKindID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL, NetMsgId.REQ_CL_FRIENDROOM_CONFIG,"dw",CHANNEL_ID,wKindID)
end

--请求金币房配置
function Game:sendMsgGetGoldRoomParam(wKindID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_HALL, NetMsgId.REQ_CL_GOLDROOM_CONFIG,"dw",CHANNEL_ID,wKindID)
end

--加入好友房时获取房间信息
function Game:sendMsgGetGameServerInfoByJoin(roomID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_CL_USER_GET_SERVER_BY_ID,"w",roomID)
end

--开始录音
function Game:startVoice(fileName,maxTime,voiceCallback)
    self.voiceCallback = voiceCallback
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
        local methodName = "startVoice"
        local args = { fileName,tostring(maxTime) }  
        local sigs = "(Ljava/lang/String;)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)
        
        local UserData = require("app.user.UserData")
        if cc.UserDefault:getInstance():getBoolForKey(Default.UserDefault_FirestVoice,true) == true then
            print("Android第一次录音")
            cc.UserDefault:getInstance():setBoolForKey(Default.UserDefault_FirestVoice,false)
            cc.Director:getInstance():getRunningScene():runAction(cc.Sequence:create(cc.DelayTime:create(5),cc.CallFunc:create(function(sender,event) 
                self:overVoice()
            end)))
        end
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():startVoice(fileName,maxTime)
    end
end

--取消录音
function Game:cancelVoice()
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
        local methodName = "cancelVoice" 
        local args = {  }  
        local sigs = "(Ljava/lang/String;)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():cancelVoice()
    end
end

--结束录音
function Game:overVoice()
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
        local methodName = "overVoice" 
        local args = {  }  
        local sigs = "(Ljava/lang/String;)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():overVoice()
    end
end

--语音回调
function cc.exports.voiceformSdkEventHandler(eventtype, response)
	printInfo("voiceformSdkEventHandler:语音url地址回调")
	local data = {}
	data.eventtype = eventtype
    data.response = response
	if eventtype == 'UpLoad' then
        cc.Director:getInstance():getRunningScene():runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) 
             print('-->>>事件分发：12112311', eventtype, response)
            local event = cc.EventCustom:new('VOICE_SDK_EVENT')
            event._usedata = data
            cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
        end)))
	end
end

function cc.exports.overVoice(parameters)
    print('fx-----cc.exports.overVoice------',parameters)
    if Game.voiceCallback then
        local scene = cc.Director:getInstance():getRunningScene()
        scene:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) Game.voiceCallback(parameters) end)))
    end
end

function Game:readCreateParameter(wKindID)
    if cc.FileUtils:getInstance():isFileExist(string.format(FileName.tableCreateParameter,wKindID)) == false then
        return nil
    end
    local fileData = cc.FileUtils:getInstance():getStringFromFile(string.format(FileName.tableCreateParameter,wKindID))
    local dataJson = {}
    if fileData ~= nil and fileData ~= "" then
        return json.decode(fileData)     
    end
    return nil
end

function Game:saveCreateParameter(wKindID, tableCreateParameter)
    local data = json.encode(tableCreateParameter)
    local fp = io.open(string.format(FileName.tableCreateParameter,wKindID),"wb+")
    fp:write(data)
    fp:close()
end

return Game