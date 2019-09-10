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

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
	luaj = require("cocos.cocos2d.luaj")
end

local User = {
	deviceID = "",          --设备号  
	openId = "",            --开放ID
	token = "",            --令牌
	appKey = "",            --APP  
	externalAdditional = "",   --外部附加参数
	className = "com/coco2dx/org/HelperAndroid",
	
	isFirstEnterHall = true,
	city = "",
	tableStandbyServer = {},                --备用服务器列表
	sendLoginData = {},                     --登录时所发送的数据，用于登录成功保存上一次的登录是数据，下一次免授权和自动登录功能
	logicData = {},                         --逻辑服数据，用于重连
	--用户基本信息
	userID = 0,
	wKind = 0,
	wType = 0,
	dwChannelID = 0,
	dwAgentID = 0,
	dwGuildID = 0,
	szAccount = "",                     --用户账号
	szUnionid = "",                    --Unionid
	szNickName = "",
	szLogoInfo = "",
	szRealName = "",                    --真实姓名
	szIDNumber = "",                    --身份证号码
	--    szEMail = "",                       --邮箱
	szPhone = "",                       --手机号码
	VerificaCode = "",                  --验证码                       
	szPhone = "",
	cbGender = 0,
	dwIngot = 0,
	dwGold = 0,
	dwWinCount = 0,
	dwLostCount = 0,
	dwDrawCount = 0,
	dwLastLoginIP = 0,
	dw365 = - 1,    -- -1  没充值  0 充值 
	isOpenUserEffect = true, --是否开启用户特效
	localIp = 0,         --本地ip
	szErWeiMaLogo = "",  --亲友圈名片
}

function User:onEnter()
	EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE, self, self.EVENT_TYPE_NET_RECV_MESSAGE)
	self:requestLocation()
end

function User:onExit()
	EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE, self, self.EVENT_TYPE_NET_RECV_MESSAGE)
end

function User:EVENT_TYPE_NET_RECV_MESSAGE(event)
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
	
	if netID == NetMgr.NET_LOGIN and mainCmdID == NetMsgId.MDM_GP_LOGON and subCmdID == NetMsgId.SUB_GP_LOGON_SUCCESS then
		local luaFunc = NetMgr:getLoginInstance().cppFunc
		self.logicData.dwUserID = luaFunc:readRecvDWORD()
		self.logicData.wSortID = luaFunc:readRecvWORD()
		self.logicData.wServerID = luaFunc:readRecvWORD()
		self.logicData.wServerPort = luaFunc:readRecvWORD()
		self.logicData.dwServerAddr = luaFunc:readRecvDWORD()
		self.logicData.dwOnLineCount = luaFunc:readRecvDWORD()
		self.logicData.szLogicServerURL = luaFunc:readRecvString(32)
		self.logicData.szAuthCode = luaFunc:readRecvString(64)
		printInfo("登录成功")
		printInfo(self.logicData)
		NetMgr:getLoginInstance():closeConnect()
		EventMgr:dispatch(EventType.SUB_GP_LOGON_SUCCESS)
		
		
	elseif netID == NetMgr.NET_LOGIN and mainCmdID == NetMsgId.MDM_GP_LOGON and subCmdID == NetMsgId.SUB_GP_LOGON_FAILURE then
		print("登陆登录服失败")
		local luaFunc = NetMgr:getLoginInstance().cppFunc
		local data = {}
		data.wErrorCode = luaFunc:readRecvLong()
		data.szErrorDescribe = luaFunc:readRecvString(128)
		NetMgr:getLoginInstance():closeConnect()
		EventMgr:dispatch(EventType.SUB_GP_LOGON_FAILURE, data)
		
	elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_LOGON and subCmdID == NetMsgId.SUB_CL_LOGON_SUCCESS then
		print("登录逻辑服成功")
		self.userID = netInstance.cppFunc:readRecvDWORD()
		self.wKind = netInstance.cppFunc:readRecvWORD()
		self.wType = netInstance.cppFunc:readRecvWORD()
		self.dwChannelID = netInstance.cppFunc:readRecvDWORD()
		self.dwAgentID = netInstance.cppFunc:readRecvDWORD()
		self.dwGuildID = netInstance.cppFunc:readRecvDWORD()
		self.szNickName = netInstance.cppFunc:readRecvString(32)
		self.szLogoInfo = netInstance.cppFunc:readRecvString(256)
		self.szPhone = netInstance.cppFunc:readRecvString(16)
		self.cbGender = netInstance.cppFunc:readRecvByte()
		self.dwIngot = netInstance.cppFunc:readRecvDWORD()
		self.dwGold = netInstance.cppFunc:readRecvDWORD()
		self.dwWinCount = netInstance.cppFunc:readRecvDWORD()
		self.dwLostCount = netInstance.cppFunc:readRecvDWORD()
		self.dwDrawCount = netInstance.cppFunc:readRecvDWORD()
		self.dwLastLoginIP = netInstance.cppFunc:readRecvDWORD()		
		self.szErWeiMaLogo = netInstance.cppFunc:readRecvString(256)
		print('名片二维码：', self.szErWeiMaLogo)
		self:saveLoginInfo()
        self:talkdata()
        if cc.PLATFORM_OS_DEVELOPER ~= PLATFORM_TYPE then
            buglySetUserId(tostring(self.userID))
		end

		--丫丫语音登录
		Common:voiceEventTracking("InitLogin",self.userID)

		EventMgr:dispatch(EventType.SUB_CL_LOGON_SUCCESS)
		
	elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_USER and subCmdID == NetMsgId.SUB_CL_USER_INFO then
		print("刷新用户信息成功!")
		self.userID = netInstance.cppFunc:readRecvDWORD()
		self.wKind = netInstance.cppFunc:readRecvWORD()
		self.wType = netInstance.cppFunc:readRecvWORD()
		self.dwChannelID = netInstance.cppFunc:readRecvDWORD()
		self.dwAgentID = netInstance.cppFunc:readRecvDWORD()
		self.dwGuildID = netInstance.cppFunc:readRecvDWORD()
		self.szNickName = netInstance.cppFunc:readRecvString(32)
		self.szLogoInfo = netInstance.cppFunc:readRecvString(256)
		self.szPhone = netInstance.cppFunc:readRecvString(16)
		self.cbGender = netInstance.cppFunc:readRecvByte()
		self.dwIngot = netInstance.cppFunc:readRecvDWORD()
		self.dwGold = netInstance.cppFunc:readRecvDWORD()
		self.dwWinCount = netInstance.cppFunc:readRecvDWORD()
		self.dwLostCount = netInstance.cppFunc:readRecvDWORD()
		self.dwDrawCount = netInstance.cppFunc:readRecvDWORD()
		self.dwLastLoginIP = netInstance.cppFunc:readRecvDWORD()
		self.szErWeiMaLogo = netInstance.cppFunc:readRecvString(256)
		EventMgr:dispatch(EventType.SUB_CL_USER_INFO)
		
	elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_LOGON and subCmdID == NetMsgId.SUB_CL_LOGON_ERROR then
		print("登陆逻辑服失败")
		local luaFunc = NetMgr:getLoginInstance().cppFunc
		local data = {}
		data.wErrorCode = luaFunc:readRecvLong()
		data.szErrorDescribe = luaFunc:readRecvString(128)
		NetMgr:getLogicInstance():closeConnect()
		EventMgr:dispatch(EventType.SUB_CL_LOGON_ERROR, data)
	else
		
		return
	end	
	
end

function User:readLoginInfo()
	local tableLoginInfo = {}
	local lastLoginInfo = nil
	if cc.FileUtils:getInstance():isFileExist(FileName.loginData) == false then
		return tableLoginInfo, lastLoginInfo
	end
	local fileData = cc.FileUtils:getInstance():getStringFromFile(FileName.loginData)
	local wxDataJson = {}
	if fileData ~= nil and fileData ~= "" then
		wxDataJson = json.decode(fileData)	
		for key, var in pairs(wxDataJson) do
			local data = {}
			data.wKind = var["wKind"]
			data.wType = var["wType"]
			data.szAccount = var["szAccount"]
			data.szNickName = var["szNickName"]
			data.szLogoInfo = var["szLogoInfo"]
			data.cbGender = var["cbGender"]
			data.dwChannelID = var["dwChannelID"]	
			data.szUnionid = var["szUnionid"]
			data.time = var["time"]
			if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER and CONST_ACCOUNTS ~= "" then
				data.szAccount = CONST_ACCOUNTS
				data.szNickName = CONST_ACCOUNTS
			end
			if os.time() - data.time < 60 * 60 * 24 * 10 then
				tableLoginInfo[data.wKind] = data
				if lastLoginInfo == nil or data.time > lastLoginInfo.time then
					lastLoginInfo = data
				end
			end		
		end
	end
	return tableLoginInfo, lastLoginInfo
end

--保存上一次登陆成功时的结构，以便下次重连
function User:saveLoginInfo()
	local tableLoginInfo = self:readLoginInfo()
	if tableLoginInfo == nil then
		tableLoginInfo = {}
	end
	
	self.sendLoginData.time = os.time()
	for key, var in pairs(tableLoginInfo) do
		if var.wKind == self.sendLoginData.wKind then
			table.remove(tableLoginInfo, key)
			break
		end
	end
	tableLoginInfo[self.sendLoginData.wKind] = self.sendLoginData
	local data = json.encode(tableLoginInfo)
	local fp = io.open(FileName.loginData, "wb+")
	fp:write(data)
	fp:close()
end

--请求备用域名
function User:requestStandbyServer()
	if 1 then return end
	--检测本地备用服务器日期是否过期
	local xmlHttpRequest = cc.XMLHttpRequest:new()
	xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xmlHttpRequest:setRequestHeader("Content-Type", "application/json; charset=utf-8")
	xmlHttpRequest:open("GET", HttpUrl.POST_URL_StandbyServer)
	local function onHttpRequestCompletedPhone()
		if xmlHttpRequest.status == 200 then
			self.tableStandbyServer = json.decode(xmlHttpRequest.response)
		end
	end
	xmlHttpRequest:registerScriptHandler(onHttpRequestCompletedPhone)
	xmlHttpRequest:send()
end

function User:readUserLevel()
	if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
        return 1
    end
	local UserData = require("app.user.UserData")
	local totalCount = UserData.Game:getGameStatistics()
	--三级专线
	if totalCount >= StaticData.Condition[3].gameCount then
		return 3
	end
	--二级专线
	if totalCount >= StaticData.Condition[2].gameCount then
		return 2
	end
	return 1
end

--连接登陆服
function User:sendMsgConnectLogin(data)
    local function callback(ip, port)
        if ip ~= nil and port ~= nil and NetMgr:getLoginInstance():connectGameSvr(ip, port) then
            NetMgr:getLoginInstance():sendMsgToSvr(NetMsgId.MDM_GP_LOGON, NetMsgId.SUB_GP_LOGON_ACCOUNTS, "wwnsnsnsbdns",
                data.wKind, data.wType, 64, data.szAccount, 32, data.szNickName, 256,
                data.szLogoInfo, data.cbGender, data.dwChannelID, 64, data.szUnionid)
            self.sendLoginData = data
            self.szAccount = data.szAccount
            self.szUnionid = data.szUnionid
        else
            EventMgr:dispatch(EventType.EVENT_TYPE_CONNECT_LOGIN_FAILED, {ip, port})
        end
    end
    
    local UserLevel = self:readUserLevel()
    local ip = string.format(StaticData.Condition[UserLevel].loginIp,SERVER_INFO.ip)
    local port = SERVER_INFO.port
    if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER and StaticData.Condition[UserLevel].isUseTaijidun == true and OPEN_TAIJIDUN == true then
        self:taijidun(StaticData.Condition[UserLevel].taijidunName,port,callback)
    else
        callback(ip, port)
    end
end

--连接逻辑服
function User:sendMsgConnectLogic()
    local function callback(ip, port)
        if ip ~= nil and port ~= nil and NetMgr:getLogicInstance():connectGameSvr(ip, port) then
            NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_LOGON, NetMsgId.REQ_CL_LOGON_USERID, "dns", self.logicData.dwUserID, 64, self.logicData.szAuthCode)
        else
            EventMgr:dispatch(EventType.EVENT_TYPE_CONNECT_LOGIC_FAILED, {ip, port})
        end
    end
    local UserLevel = self:readUserLevel()
    local ip = string.format(StaticData.Condition[UserLevel].logicIp,self.logicData.szLogicServerURL)
    if ip == "0" then
        ip = NetMgr:getLogicInstance().cppFunc:int2ip(self.logicData.dwServerAddr)
    end
    local port = self.logicData.wServerPort
    if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER and StaticData.Condition[UserLevel].isUseTaijidun == true and OPEN_TAIJIDUN == true then
        self:taijidun(StaticData.Condition[UserLevel].taijidunName,port,callback)
    else
        callback(ip, port)
    end
end

--刷新玩家数据
function User:sendMsgUpdateUserInfo(cbReqRoot)
	--cbReqRoot  0缓存刷新     1数据库刷新    
	NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_USER, NetMsgId.REQ_CL_USER_INFO, "b", cbReqRoot)
	require("app.user.UserData").Bag:sendMsgGetBag(cbReqRoot)	
end


--获取登录参数
function User:setLoginParameter()
	if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
		local methodName = "setLoginParameter"
		local args = {"V", setDeviceId}
		local sigs = "(V;I)V"
		luaj.callStaticMethod(self.className, methodName, args, nil)
	elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
		self.deviceID = cus.JniControl:getInstance():GetDeviceId()
		self.openId = cus.JniControl:getInstance():GetOpenID()
		self.token = cus.JniControl:getInstance():GetAccess_token()
		self.appKey = cus.JniControl:getInstance():GetOauth_consumer_key()
	end
end

--获取设备码
function cc.exports.setDeviceId(deviceID)
	User.deviceID = deviceID
end

--获取openID
function cc.exports.setOpenId(openId)
	User.openId = openId
end

--获取tokenID
function cc.exports.setAccessToken(token)
	User.token = token
end

--获取appKey
function cc.exports.setAppKey(appKey)
	User.appKey = appKey
end

--SDK登陆
function User:setJniSdkLogin(type, callback)
	self.sdkLoginCallback = callback
	if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
		local methodName = "setJniSdkLogin"
		local args = {string.format("%s", type), setSDKLoginOver}
		local sigs = "(Ljava/lang/String;I)V"
		luaj.callStaticMethod(self.className, methodName, args, nil)
	elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
		cus.JniControl:getInstance():onSDKLogin(type)
	end
end

--SDK登陆回调
function cc.exports.setSDKLoginOver(data)
	cc.Director:getInstance():getRunningScene():runAction(cc.Sequence:create(
	cc.DelayTime:create(1),
	cc.CallFunc:create(function(sender, event)
		User.sdkLoginCallback(tonumber(data))
	end)))
end

--==============================--
--desc:获取用户详细地址 posx posy 经纬度 callFunc
--time:2018-07-23 11:43:08
--==============================--
function User:getDetailLocation(posx, posy, callFunc)
	print('===>>>posx,posy', posx, posy)
	local xmlHttpRequest = cc.XMLHttpRequest:new()
	xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xmlHttpRequest:setRequestHeader("Content-Type", "application/json; charset=utf-8")
	local http = string.format(HttpUrl.POST_URL_GameUserDetailLocation, posx or 0, posy or 0)
	xmlHttpRequest:open("GET", http)
	
	local function onHttpRequestCompletedPhone(...)
		if xmlHttpRequest.status == 200 then
			local response = json.decode(xmlHttpRequest.response)
			dump(response)
			local function nameOfAddr(key, data)
                if type(data) == 'table' then
                    local value = data[key]
					if type(value) == 'string' then
						return value
                    else
                        return ''
                    end
                else
                    return ''
                end
			end
			local addData = response['regeocode'] ['addressComponent']
			local address = ''
			if addData then
				local city = nameOfAddr('city', addData)
				local district = nameOfAddr('district', addData)
				local township = nameOfAddr('township', addData)
				local streeData = addData['streetNumber']
				local street = nameOfAddr('street', streeData)
				local number = nameOfAddr('number', streeData)
				address = city .. district .. township .. street .. number
				if string.len( address ) <= 0 then
					address = '未知地点'
				end
			else
				address = '未知地点'
			end
			
			if callFunc then
				callFunc(address)
			end
		end
	end
	xmlHttpRequest:registerScriptHandler(onHttpRequestCompletedPhone)
	xmlHttpRequest:send()
end

function User:requestLocation()
	local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID, - 1)
	if regionID == - 1 then
		cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_RegionID, 0)
	end
	print("游戏开始定位：", os.time(), regionID)
	local addr = NetMgr:getLogicInstance().cppFunc:int2ip(self.dwLastLoginIP)
	local xmlHttpRequest = cc.XMLHttpRequest:new()
	xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xmlHttpRequest:setRequestHeader("Content-Type", "application/json; charset=utf-8")
	xmlHttpRequest:open("GET", HttpUrl.POST_URL_GameUserLocation)
	local function onHttpRequestCompletedPhone()
		if xmlHttpRequest.status == 200 then
			print("定位:", xmlHttpRequest.response)
			local response = json.decode(xmlHttpRequest.response)
			if response["province"] == "湖南省" then
				for key, var in pairs(StaticData.Regions) do
					local province = response["province"]
					local city = response["city"]
					self.city = province .. city
					city = string.sub(city, 1, 6)
					print(string.len(city))
					if string.find(var.name, city) then
						if regionID == - 1 and StaticData.Hide[CHANNEL_ID].btn6 == 1 then
							cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_RegionID, var.id)
						end
					end
				end
			end
		end
	end
	xmlHttpRequest:registerScriptHandler(onHttpRequestCompletedPhone)
	xmlHttpRequest:send()
end

function cc.exports.setAdditional(data)
    if data == "" then
        return
    end
	--解析外部附加参数
	User.externalAdditional = data
	local scene = cc.Director:getInstance():getRunningScene()
	scene:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_EXTERNAL_START_GAME) end)))
	
end

--上传公告
function User:requestLog(describe, log)
	--    local xmlHttpRequest = cc.XMLHttpRequest:new()
	--    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	--    xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
	--    xmlHttpRequest:open("GET",HttpUrl.POST_URL_StandbyServer)
	--    local function onHttpRequestCompletedPhone()
	--        if xmlHttpRequest.status == 200 then
	--            
	--        end
	--    end
	--    xmlHttpRequest:registerScriptHandler(onHttpRequestCompletedPhone)
	--    xmlHttpRequest:send()
end

--初始化电量
function User:initByLevel()
	if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
		local methodName = "initByLevel"
		local args = {}
		local sigs = "(Ljava/lang/String;)V"
		luaj.callStaticMethod(self.className, methodName, args, nil)
	elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
		cus.JniControl:getInstance():initByLevel()
	end
end

--电量变化
function cc.exports.setByLevel(value)
	local scene = cc.Director:getInstance():getRunningScene()
	scene:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_ELECTRICITY, tonumber(value)) end)))
end

--复制功能
function User:copydata(buffer)
	if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
		local methodName = "copydata"
		local args = {buffer}
		local sigs = "(Ljava/lang/String;)V"
		luaj.callStaticMethod(self.className, methodName, args, nil)
	elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
		cus.JniControl:getInstance():copydata(buffer)
	end
end

--打开外部程序
function User:OpenExternal(index)
	if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
		local methodName = "OpenExternal"
		local args = {index}
		local sigs = "(Ljava/lang/String;)V"
		luaj.callStaticMethod(self.className, methodName, args, nil)
	elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
		cus.JniControl:getInstance():OpenExternal(index)
	end
end

--talkdata数据统计
function User:talkdata()
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
        local methodName = "talkdata"
        local args = {tostring(self.userID), tostring(self.dwChannelID), self.szNickName, self.szPhone, tostring(self.cbGender), tostring(self.dwLastLoginIP)}
        local sigs = "(Ljava/lang/String;)V"
        luaj.callStaticMethod(self.className, methodName, args, nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():talkdata(tostring(self.userID), tostring(self.dwChannelID), self.szNickName, self.szPhone, tostring(self.cbGender), tostring(self.dwLastLoginIP))
    end
end

--太极盾
function User:taijidun(ip, port, callback)
    self.taijidunCallback = callback
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
        local methodName = "taijidun"
        local args = {ip, tostring(port)}
        local sigs = "(Ljava/lang/String;)V"
        --luaj.callStaticMethod(self.className, methodName, args, nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():taijidun(ip, tostring(port))
    end
end

function cc.exports.taijidunCallback(data)
    local scene = cc.Director:getInstance():getRunningScene()
    scene:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function(sender, event)
        if User.taijidunCallback then
            local tableData = Common:stringSplit(data,"|")
            if tableData[1] ~= nil and tableData[2] ~= nil and tableData[1] ~= "" and tableData[2] ~= "" then
                User.taijidunCallback(tableData[1], tonumber(tableData[2]))
            else
                print("error:",data)
                User.taijidunCallback()
            end            
        end
    end)))
end

function User:openPhotoAlbum()
	if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
        local methodName = "openPhotoAlbum" 
        local args = {  }  
        local sigs = "(Ljava/lang/String;)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)

	elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():openPhotoAlbum()
	end
end

function cc.exports.openPhotoAlbumResult(filePath)
    local scene = cc.Director:getInstance():getRunningScene()
    scene:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function(sender, event) EventMgr:dispatch(EventType.EVENT_TYPE_OPEN_PHOTO_ALBUM, filePath) end)))
end

function User:requestUploadErWeiMa(url,data)
    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
    xmlHttpRequest:open("POST",url)
    local function onHttpRequestCompleted()
        print("requestUploadErWeiMa",xmlHttpRequest.status)
        if xmlHttpRequest.status == 200 then
            print("response",xmlHttpRequest.response)
            EventMgr:dispatch(EventType.EVENT_TYPE_UPLOAD_ERWEIMA, xmlHttpRequest.response)
            return
        end
        EventMgr:dispatch(EventType.EVENT_TYPE_UPLOAD_ERWEIMA, 0)
    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
    xmlHttpRequest:send(data)
end

return User 