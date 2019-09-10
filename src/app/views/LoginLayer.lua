local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local HttpUrl = require("common.HttpUrl")
local Update = require("loading.Update")

UserData.User:setLoginParameter()
UserData.Music:storeVolumeValue()
local LoginLayer = class("LoginLayer", cc.load("mvc").ViewBase)

function LoginLayer:onEnter()
    NetMgr:getLogicInstance():closeConnect()
    NetMgr:getGameInstance():closeConnect()
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_LOGIN_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIN_FAILED) 
    EventMgr:registListener(EventType.SUB_GP_LOGON_SUCCESS,self,self.SUB_GP_LOGON_SUCCESS)   
    EventMgr:registListener(EventType.SUB_GP_LOGON_FAILURE,self,self.SUB_GP_LOGON_FAILURE)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_LOGIC_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIC_FAILED)
    EventMgr:registListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_CL_LOGON_ERROR,self,self.SUB_CL_LOGON_ERROR)
    EventMgr:registListener(EventType.EVENT_TYPE_EXTERNAL_START_GAME,self,self.EVENT_TYPE_EXTERNAL_START_GAME)
    EventMgr:registListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED,2)
    EventMgr:registListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR,2)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED,2)
    
end

function LoginLayer:onExit()
    UserData.User.externalAdditional = ""
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_LOGIN_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIN_FAILED) 
    EventMgr:unregistListener(EventType.SUB_GP_LOGON_SUCCESS,self,self.SUB_GP_LOGON_SUCCESS)   
    EventMgr:unregistListener(EventType.SUB_GP_LOGON_FAILURE,self,self.SUB_GP_LOGON_FAILURE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_LOGIC_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIC_FAILED)
    EventMgr:unregistListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_CL_LOGON_ERROR,self,self.SUB_CL_LOGON_ERROR)
    EventMgr:unregistListener(EventType.EVENT_TYPE_EXTERNAL_START_GAME,self,self.EVENT_TYPE_EXTERNAL_START_GAME)
    EventMgr:unregistListener(EventType.SUB_GR_JOIN_TABLE_FAILED,self,self.SUB_GR_JOIN_TABLE_FAILED)
    EventMgr:unregistListener(EventType.SUB_CL_GAME_SERVER_ERROR,self,self.SUB_CL_GAME_SERVER_ERROR)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    
end

function LoginLayer:onCreate(parames)
    UserData.User.isFirstEnterHall = true
    if parames[2] == true then
        --免授权登陆
        self.notAuthorization = true
    end
    
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("LoginLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
        
    --版本信息
    local uiText_version = ccui.Helper:seekWidgetByName(self.root,"Text_version")
    if Update.version ~= "" then
        local versionInfo = string.format("v%s",Update.version)
        versionInfo = versionInfo.."."..tostring(CHANNEL_ID)
        uiText_version:setString(versionInfo)
    end


    --用户协议
    local uiPanel_agreement = ccui.Helper:seekWidgetByName(self.root,"Panel_agreement")
    if StaticData.Hide[CHANNEL_ID].btn4 == 0 then
        uiPanel_agreement:setVisible(false)  
    end 
    local uiPanel_lookAt = ccui.Helper:seekWidgetByName(self.root,"Panel_lookAt")
    uiPanel_lookAt:setVisible(false)
    local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
    Common:addTouchEventListener(uiPanel_lookAt,function() 
        uiPanel_lookAt:setVisible(false) 
        uiPanel_contents:removeAllChildren()
    end,true)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_agreement"),function() 
        uiPanel_lookAt:setVisible(true)
        if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER then
            uiPanel_contents:removeAllChildren()
            -- local uiWebView = ccexp.WebView:create()
            -- uiPanel_contents:addChild(uiWebView)
            -- uiWebView:setContentSize(uiPanel_contents:getContentSize())
            -- uiWebView:setAnchorPoint(cc.p(0.5,0.5))
            -- uiWebView:setPosition(uiWebView:getParent():getContentSize().width/2,uiWebView:getParent():getContentSize().height/2)
            -- uiWebView:setScalesPageToFit(true)
            -- uiWebView:loadURL(StaticData.Channels[CHANNEL_ID].loginAgreement)
            --uiWebView:enableDpadNavigation(false)
        end
    end)
    local uiCheckBox_agree = ccui.Helper:seekWidgetByName(self.root,"CheckBox_agree")
    
    --处理登陆方式
    local uiListView_btn = ccui.Helper:seekWidgetByName(self.root,"ListView_btn")
    local loginType = StaticData.Channels[CHANNEL_ID].loginType
    if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
        loginType = 1
    end
    if loginType == 0 and StaticData.Channels[CHANNEL_ID].loginBtn == "" then
    --第三方自动登录
    
    elseif loginType == 0 and StaticData.Channels[CHANNEL_ID].loginBtn ~= "" then
        --显示第三方登录按钮
        local btn = ccui.Button:create(StaticData.Channels[CHANNEL_ID].loginBtn,StaticData.Channels[CHANNEL_ID].loginBtn,StaticData.Channels[CHANNEL_ID].loginBtn)
        uiListView_btn:pushBackCustomItem(btn)
        btn:setPressedActionEnabled(true)
        btn:addTouchEventListener(function(sender,event) 
            if event == ccui.TouchEventType.ended then
                if event == ccui.TouchEventType.ended then
                    Common:palyButton()
                    if uiCheckBox_agree:isSelected() == false then
                        require("common.MsgBoxLayer"):create(0,nil,"请同意游戏协议！")
                        return 
                    end
                    if cc.Director:getInstance():getRunningScene():getChildByTag(LAYER_GLOBAL) ~= nil then
                        require("common.MsgBoxLayer"):create(0,nil,"请不要重复操作！")
                        return 
                    end
                    require("common.LoadingAnimationLayer"):create(6)
                    local tableLoginInfo, lastLoginInfo = UserData.User:readLoginInfo()
                    if UserData.User.isCancellation == false and tableLoginInfo[StaticData.Channels[CHANNEL_ID].loginMode] ~= nil then
                        UserData.User:sendMsgConnectLogin(lastLoginInfo) 
                        return
                    end
                    UserData.User:setJniSdkLogin(0,function(event) self:loginTypeExternal(event) end) 
                end
            end
        end)

    else
        for i = 1 , 3 do
            if Bit:_and(Bit:_rshift(loginType,(i-1)),1) == 1 then
                local btn = nil
                if i == 1 then
                    --手机登录
                    btn = ccui.Button:create("login/login_tourist.png","login/login_tourist.png","login/login_tourist.png")
                    uiListView_btn:pushBackCustomItem(btn)
                    Common:addTouchEventListener(btn,function(sender,event) 
                        if uiCheckBox_agree:isSelected() == false then
                            require("common.MsgBoxLayer"):create(0,nil,"请同意游戏协议！")
                            return 
                        end
                        if cc.Director:getInstance():getRunningScene():getChildByTag(LAYER_GLOBAL) ~= nil then
                            require("common.MsgBoxLayer"):create(0,nil,"请不要重复操作！")
                            return 
                        end
                        require("common.LoadingAnimationLayer"):create(6)
                        self:loginTypeTourist(sender,event)
                    end)
                    
                elseif i == 2 then
                    --QQ登录
                    btn = ccui.Button:create("login/login_qq.png","login/login_qq.png","login/login_qq.png")
                    uiListView_btn:pushBackCustomItem(btn)
                    Common:addTouchEventListener(btn,function(sender,event) 
                        if uiCheckBox_agree:isSelected() == false then
                            require("common.MsgBoxLayer"):create(0,nil,"请同意游戏协议！")
                            return 
                        end
                        if cc.Director:getInstance():getRunningScene():getChildByTag(LAYER_GLOBAL) ~= nil then
                            require("common.MsgBoxLayer"):create(0,nil,"请不要重复操作！")
                            return 
                        end
                        require("common.LoadingAnimationLayer"):create(6)
                        if self.notAuthorization then
                            local tableLoginInfo ,data =UserData.User:readLoginInfo()
                            if data ~= nil then 
                                UserData.User:sendMsgConnectLogin(data) 
                                return
                            end
                        end
                        UserData.User:setJniSdkLogin(2,function(event) self:loginTypeQQ(event) end)
                    end)
                    
                else
                    --微信登录
                    btn = ccui.Button:create("login/login_wx.png","login/login_wx.png","login/login_wx.png")
                    uiListView_btn:pushBackCustomItem(btn)
                    Common:addTouchEventListener(btn,function(sender,event) 
                        if uiCheckBox_agree:isSelected() == false then
                            require("common.MsgBoxLayer"):create(0,nil,"请同意游戏协议！")
                            return 
                        end
                        if cc.Director:getInstance():getRunningScene():getChildByTag(LAYER_GLOBAL) ~= nil then
                            require("common.MsgBoxLayer"):create(0,nil,"请不要重复操作！")
                            return 
                        end
                        require("common.LoadingAnimationLayer"):create(6)
                        if self.notAuthorization then
                            local tableLoginInfo ,data =UserData.User:readLoginInfo()
                            if data ~= nil then 
                                UserData.User:sendMsgConnectLogin(data) 
                                return
                            end
                        end
                        if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
                            UserData.User:setJniSdkLogin(3,function(event) self:loginTypeWXByAndroid(event) end)
                        else
                            UserData.User:setJniSdkLogin(3,function(event) self:loginTypeWXByIOS(event) end)
                        end
                    end)
                end
            end
        end
    end
    uiListView_btn:refreshView()
    uiListView_btn:setPositionX(visibleSize.width/2-uiListView_btn:getInnerContainerSize().width/2)
    uiListView_btn:setPositionY(uiListView_btn:getPositionY()+25)
    uiListView_btn:setDirection(ccui.ScrollViewDir.none)    

    if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER and Update.isHaveUpdateSDK == 0 and parames[1] == true then
        local tableLoginInfo ,data =UserData.User:readLoginInfo()
        if data ~= nil then 
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event)
                require("common.LoadingAnimationLayer"):create(6)
                UserData.User:sendMsgConnectLogin(data)  
            end)))
        end
    else
        if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER and Update.isHaveUpdateSDK == 1 and Update.downloadSDKUrl ~= "" then
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) 
                require("common.MsgBoxLayer"):create(1,nil,"您当前版本过低,请下载最新版本?",function() UserData.Share:openURL(Update.downloadSDKUrl) end)
            end)))
        end
    end
end

--游客登录方式
function LoginLayer:loginTypeTourist(sender,event)
    if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
        if CONST_ACCOUNTS ~= "" then
            --固定账号              
            UserData.User:sendMsgConnectLogin({wKind = 0,wType = 1,szAccount = CONST_ACCOUNTS,szNickName = CONST_ACCOUNTS,
                szLogoInfo = "0",cbGender = math.random(0,1),dwChannelID = CHANNEL_ID,szUnionid = ""})
        else
            --随机账号
            UserData.User:sendMsgConnectLogin({wKind = 0,wType = 1,
                szAccount = string.format("huyoo_test_account_228_%d",math.random(0,9999999999)),szNickName = CONST_ACCOUNTS,
                szLogoInfo = "0",cbGender = math.random(0,1),dwChannelID = CHANNEL_ID,szUnionid = ""})
        end
    else
        local szNickName = ""
        for i = 1 , 6 do             
            szNickName = szNickName..string.char(math.random(97,122))
        end
        UserData.User:sendMsgConnectLogin({wKind = 0,wType = 0,szAccount = UserData.User.deviceID,szNickName = szNickName,
            szLogoInfo = "0",cbGender = math.random(0,1),dwChannelID = CHANNEL_ID,szUnionid = ""})
    end
end


--第三方登录方式
function LoginLayer:loginTypeExternal(event)
    printInfo("第三方登录结果：%d",event)
    if event ~= 1 then
        require("common.MsgBoxLayer"):create(0,nil,"登录失败!")
        closeLoadingAnimationLayer()
        return
    end
    local szNickName = ""
    for i = 1 , 6 do             
        szNickName = szNickName..string.char(math.random(97,122))
    end
    UserData.User:sendMsgConnectLogin({wKind = 0,wType = StaticData.Channels[CHANNEL_ID].loginMode,szAccount = UserData.User.openId,
        szNickName = szNickName,szLogoInfo = "0",cbGender = math.random(0,1),dwChannelID = CHANNEL_ID})
end

--QQ登录方式
function LoginLayer:loginTypeQQ(event)
    if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        UserData.User.openId = cus.JniControl:getInstance():GetOpenID()
        UserData.User.token = cus.JniControl:getInstance():GetAccess_token()
        UserData.User.appKey = cus.JniControl:getInstance():GetOauth_consumer_key()
    end
    printInfo("QQ登录结果：%d",event)
    if event ~= 1 then
        require("common.MsgBoxLayer"):create(0,nil,"登录失败!")
        closeLoadingAnimationLayer()
        return
    end
    local url = string.format(HttpUrl.POST_URL_GameUserInfo,
        UserData.User.token,UserData.User.appKey,UserData.User.openId)
    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
    xmlHttpRequest:open("GET",url)
    local function onHttpRequestCompletedgetQQinfo()
        if xmlHttpRequest.status == 200 then
            local response = xmlHttpRequest.response
            response = string.gsub(response, "\\","")
            response = json.decode(response)   
            if response["ret"] ~= 0 then
                require("common.MsgBoxLayer"):create(0,nil,"拉取用户信息失败!"..response["msg"])
                closeLoadingAnimationLayer()
                return
            end
            local data = {}
            data.wKind = 0 
            data.wType = 3
            data.szAccount = UserData.User.openId
            data.szNickName = response["nickname"]
            if response["gender"] == "男" then
                data.cbGender = 1
            else
                data.cbGender = 0
            end
            data.szLogoInfo = response["figureurl_qq_2"]
            data.dwChannelID = CHANNEL_ID
            UserData.User:sendMsgConnectLogin(data)
        else
            closeLoadingAnimationLayer()
            require("common.MsgBoxLayer"):create(0,nil,"获取QQ信息失败!")
        end

    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestCompletedgetQQinfo)
    xmlHttpRequest:send()
end

--安卓微信登录方式
function LoginLayer:loginTypeWXByAndroid(event)
    printInfo("微信登录结果：%d",event)
    if event ~= 1 then
        if event == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"请先安装微信!")
        else
            require("common.MsgBoxLayer"):create(0,nil,"登录失败!")
        end
        closeLoadingAnimationLayer()
        return
    end
    local function getWinXinGoOn()
        local xmlHttpRequest = cc.XMLHttpRequest:new()
        xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
        xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
        xmlHttpRequest:open("GET",string.format(HttpUrl.POST_URL_GameUserSns,UserData.User.token,UserData.User.openId))
        local function onHttpRequestCompleted()
            print("getWinXinGoOn",xmlHttpRequest.status)
            if xmlHttpRequest.status == 200 then
                print("getWinXinGoOn",xmlHttpRequest.response)
                local response = string.gsub(xmlHttpRequest.response, "\\","")
                response = json.decode(response)
                if response["errcode"] ~= nil  then
                    require("common.MsgBoxLayer"):create(0,nil,"拉取用户信息失败!"..response["errmsg"])
                    closeLoadingAnimationLayer()
                    return
                end
                local data = {}
                data.wKind = 0 
                data.wType = 2
                data.szAccount = response["openid"]
                data.szNickName = response["nickname"]
                data.szLogoInfo = response["headimgurl"]
                data.szUnionid = response["unionid"]
                if response["sex"] == 1 then
                    data.cbGender = 1
                else
                    data.cbGender = 0
                end
                data.dwChannelID = CHANNEL_ID
                UserData.User:sendMsgConnectLogin(data)
            else
                require("common.MsgBoxLayer"):create(0,nil,"网络异常!")
                closeLoadingAnimationLayer()
            end

        end
        xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
        xmlHttpRequest:send()  
    end
    local function getWinXin()
        local xmlHttpRequest = cc.XMLHttpRequest:new()
        xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
        xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
        xmlHttpRequest:open("GET",string.format(HttpUrl.POST_URL_GameUserAuth,UserData.User.token,UserData.User.openId))
        local function onHttpRequestCompleted()
            print("getWinXin",xmlHttpRequest.status)
            if xmlHttpRequest.status == 200 then
                print("getWinXin",xmlHttpRequest.response)
                local response = json.decode(xmlHttpRequest.response)
                if response["errcode"] ~= 0 then
                    require("common.MsgBoxLayer"):create(0,nil,"检验授权凭证错误!"..response["errmsg"])
                    closeLoadingAnimationLayer()
                    return
                end
                getWinXinGoOn()
            else
                require("common.MsgBoxLayer"):create(0,nil,"网络异常!")
                closeLoadingAnimationLayer()
            end

        end
        xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
        xmlHttpRequest:send()   
    end
    getWinXin()
end

--苹果微信登录方式
function LoginLayer:loginTypeWXByIOS(event)
    if PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        UserData.User.openId = cus.JniControl:getInstance():GetOpenID()
        UserData.User.token = cus.JniControl:getInstance():GetAccess_token()
        UserData.User.appKey = cus.JniControl:getInstance():GetOauth_consumer_key()
    end
    printInfo("IOS微信登录结果：%d",event)
    if event ~= 1 then
        require("common.MsgBoxLayer"):create(0,nil,"登录失败!")
        closeLoadingAnimationLayer()
        return
    end
    local function getWinXinGoOn()
        local xmlHttpRequest = cc.XMLHttpRequest:new()
        xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
        xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
        xmlHttpRequest:open("GET",string.format(HttpUrl.POST_URL_GameUserToken,UserData.User.token,UserData.User.openId))
        local function onHttpRequestCompleted()
            print("getWinXinGoOn",xmlHttpRequest.status)
            if xmlHttpRequest.status == 200 then
                print("getWinXinGoOn",xmlHttpRequest.response)
                local response = string.gsub(xmlHttpRequest.response, "\\","")
                response = json.decode(response)
                if response["errcode"] ~= nil  then
                    require("common.MsgBoxLayer"):create(0,nil,"拉取用户信息失败!"..response["errmsg"])
                    closeLoadingAnimationLayer()
                    return
                end
                local data = {}
                data.wKind = 0 
                data.wType = 2
                data.szAccount = response["openid"]
                data.szNickName = response["nickname"]
                data.szLogoInfo = response["headimgurl"]
                data.szUnionid = response["unionid"]
                if response["sex"] == 1 then
                    data.cbGender = 1
                else
                    data.cbGender = 0
                end
                data.dwChannelID = CHANNEL_ID
                UserData.User:sendMsgConnectLogin(data)
            else
                require("common.MsgBoxLayer"):create(0,nil,"网络异常!")
                closeLoadingAnimationLayer()
            end

        end 
        xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
        xmlHttpRequest:send()  
    end
    local function getWinXin()
        local xmlHttpRequest = cc.XMLHttpRequest:new()
        xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
        xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
        xmlHttpRequest:open("GET",string.format(HttpUrl.POST_URL_GameUserOauth,
            StaticData.Channels[CHANNEL_ID].appID,StaticData.Channels[CHANNEL_ID].appSecret,UserData.User.token))
        local function onHttpRequestCompleted()
            print("getWinXin",xmlHttpRequest.status)
            if xmlHttpRequest.status == 200 then
                print("getWinXin",xmlHttpRequest.response)
                local response = json.decode(xmlHttpRequest.response)
                if response["errcode"] ~= nil then
                    require("common.MsgBoxLayer"):create(0,nil,"检验授权凭证错误!"..response["errmsg"])
                    closeLoadingAnimationLayer()
                    return
                end
                UserData.User.token = response["access_token"]
                UserData.User.openId = response["openid"]
                getWinXinGoOn()
            else
                require("common.MsgBoxLayer"):create(0,nil,"网络异常!")
                closeLoadingAnimationLayer()
            end

        end
        xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
        xmlHttpRequest:send()   
    end
    getWinXin()
end

function LoginLayer:SUB_GP_LOGON_SUCCESS(event)
    UserData.User:sendMsgConnectLogic()
end

function LoginLayer:SUB_GP_LOGON_FAILURE(event)
    local data = event._usedata
    local errorCode = ""
    if data.wErrorCode == 0 then
        errorCode = "服务器维护中"
    elseif data.wErrorCode == 1 then
        errorCode = "账号不存在"
    elseif data.wErrorCode == 2 then
        errorCode = "禁止登录"
    elseif data.wErrorCode == 3 then
        errorCode = "逻辑服未开启"
    elseif data.wErrorCode == 4 then
        errorCode = "数据库异常"
    elseif data.wErrorCode == 5 then
        errorCode = "缓存未找到记录"
    elseif data.wErrorCode == 6 then
        errorCode = "验证码错误"
    else    
        errorCode = "未知错误"
    end
    print(data.wErrorCode,data.szErrorDescribe)
    if data.wErrorCode == 0 then
        require("common.MsgBoxLayer"):create(0,nil,string.format("%s",errorCode))
    else
        require("common.MsgBoxLayer"):create(0,nil,string.format("连接失败!错误代码：%s",errorCode))
    end
    closeLoadingAnimationLayer()
end

function LoginLayer:SUB_CL_LOGON_ERROR(event)
    self:SUB_GP_LOGON_FAILURE(event)
end

function LoginLayer:EVENT_TYPE_CONNECT_LOGIN_FAILED(event)
    local data = event._usedata
    if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
        print("连接登录服失败",data[1],data[2]) 
    end 
    closeLoadingAnimationLayer()
    require("common.MsgBoxLayer"):create(0,nil,"连接失败!")
end

function LoginLayer:EVENT_TYPE_CONNECT_LOGIC_FAILED(event)
    local data = event._usedata
    if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
        print("连接逻辑服失败",data[1],data[2])
    end 
    closeLoadingAnimationLayer()
    require("common.MsgBoxLayer"):create(0,nil,"连接大厅失败!")
end

function LoginLayer:SUB_CL_LOGON_SUCCESS(event)
    if UserData.User.externalAdditional ~= "" then
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(tonumber(UserData.User.externalAdditional)):createView("InterfaceJoinRoomNode"))
    else
        require("app.MyApp"):create(function() 
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true):createView("HallLayer"),SCENE_HALL)
        end):createView("InterfaceCheckRoomNode")
    end
end

function LoginLayer:EVENT_TYPE_EXTERNAL_START_GAME(event)
    if Update.isHaveUpdateSDK == 0 then
        local tableLoginInfo ,data =UserData.User:readLoginInfo()
        if data ~= nil then 
            UserData.User:sendMsgConnectLogin(data) 
        end
    else
        UserData.User.externalAdditional = ""
    end
end

function LoginLayer:SUB_GR_JOIN_TABLE_FAILED(event)
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true):createView("HallLayer"),SCENE_HALL)
end

function LoginLayer:SUB_CL_GAME_SERVER_ERROR(event)
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true):createView("HallLayer"),SCENE_HALL)
end

function LoginLayer:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create(true):createView("HallLayer"),SCENE_HALL)
end

return LoginLayer

