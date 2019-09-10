local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")

local ReconnectLayer = class("ReconnectLayer", cc.load("mvc").ViewBase)

function ReconnectLayer:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_LOGIN_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIN_FAILED) 
    EventMgr:registListener(EventType.SUB_GP_LOGON_SUCCESS,self,self.SUB_GP_LOGON_SUCCESS)   
    EventMgr:registListener(EventType.SUB_GP_LOGON_FAILURE,self,self.SUB_GP_LOGON_FAILURE)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_LOGIC_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIC_FAILED)
    EventMgr:registListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_CL_LOGON_ERROR,self,self.SUB_CL_LOGON_ERROR)
    EventMgr:registListener(EventType.SUB_CL_USER_LOCK_SERVER,self,self.SUB_CL_USER_LOCK_SERVER)
    EventMgr:registListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:registListener(EventType.SUB_GR_LOGON_ERROR,self,self.SUB_GR_LOGON_ERROR)
    EventMgr:registListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:registListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:registListener(EventType.EVENT_TYPE_NET_DISCONNET,self,self.EVENT_TYPE_NET_DISCONNET)

    self:startConnect()
end

function ReconnectLayer:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_LOGIN_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIN_FAILED) 
    EventMgr:unregistListener(EventType.SUB_GP_LOGON_SUCCESS,self,self.SUB_GP_LOGON_SUCCESS)   
    EventMgr:unregistListener(EventType.SUB_GP_LOGON_FAILURE,self,self.SUB_GP_LOGON_FAILURE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_LOGIC_FAILED,self,self.EVENT_TYPE_CONNECT_LOGIC_FAILED)
    EventMgr:unregistListener(EventType.SUB_CL_LOGON_SUCCESS,self,self.SUB_CL_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_CL_LOGON_ERROR,self,self.SUB_CL_LOGON_ERROR)
    EventMgr:unregistListener(EventType.SUB_CL_USER_LOCK_SERVER,self,self.SUB_CL_USER_LOCK_SERVER)
    EventMgr:unregistListener(EventType.EVENT_TYPE_CONNECT_GAME_FAILED,self,self.EVENT_TYPE_CONNECT_GAME_FAILED)
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_ERROR,self,self.SUB_GR_LOGON_ERROR)
    EventMgr:unregistListener(EventType.SUB_GR_LOGON_SUCCESS,self,self.SUB_GR_LOGON_SUCCESS)
    EventMgr:unregistListener(EventType.SUB_GR_USER_ENTER,self,self.SUB_GR_USER_ENTER)
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_DISCONNET,self,self.EVENT_TYPE_NET_DISCONNET)
    
    UserData.Time.isReconecting = false
end

function ReconnectLayer:onCreate()   
    UserData.Time.isReconecting = true 
    self.connectCount = 0
    
    if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER then
        Common:screenshot(FileName.screenshot)
    end
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local layer = cc.LayerColor:create(cc.c4b(122,73,21,255))
    self:addChild(layer)
    if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER and cc.FileUtils:getInstance():isFileExist(FileName.screenshot) == true then
        local bg = ccui.ImageView:create(FileName.screenshot)
        layer:addChild(bg)   
        bg:setPosition(visibleSize.width/2,visibleSize.height/2) 
    end
end


function ReconnectLayer:startConnect()
    NetMgr:getLoginInstance():closeConnect()
    NetMgr:getLogicInstance():closeConnect()
    NetMgr:getGameInstance():closeConnect()
    
    self:stopAllActions()
    
    self.connectCount = self.connectCount + 1
    if self.connectCount <= 2 then
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event) 
            local tableLoginInfo ,loginInfo = UserData.User:readLoginInfo()
            UserData.User:sendMsgConnectLogin(loginInfo)
        end)))
        
    elseif self.connectCount <= 3 then
        require("common.MsgBoxLayer"):create(1,self,"请检查您的网络是否稳定,再尝试重新连接?",function() 
            local tableLoginInfo ,loginInfo = UserData.User:readLoginInfo()
            UserData.User:sendMsgConnectLogin(loginInfo)
        end,function() 
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,true):createView("LoginLayer"),SCENE_LOGIN) 
        end)

    else
        require("common.MsgBoxLayer"):create(2,self,"检测到您的网络异常,请重新登陆!",function()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,true):createView("LoginLayer"),SCENE_LOGIN) 
        end)

    end
end

function ReconnectLayer:EVENT_TYPE_NET_DISCONNET(event)
    local netID = event._usedata
    if netID ~= NetMgr.NET_LOGIC and netID ~= NetMgr.NET_GAME then
        return
    end
    self:startConnect()
end

function ReconnectLayer:EVENT_TYPE_CONNECT_LOGIN_FAILED(event)
    local data = event._usedata
    self:startConnect()
end

function ReconnectLayer:SUB_GP_LOGON_FAILURE(event)
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
    require("common.MsgBoxLayer"):create(2,self,errorCode,function()
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,true):createView("LoginLayer"),SCENE_LOGIN) 
    end)
end

function ReconnectLayer:SUB_GP_LOGON_SUCCESS(event)
    UserData.User:sendMsgConnectLogic()
end

function ReconnectLayer:EVENT_TYPE_CONNECT_LOGIC_FAILED(event)
    self:startConnect()
end

function ReconnectLayer:SUB_CL_LOGON_ERROR(event)
    self:SUB_GP_LOGON_FAILURE(event)
end

function ReconnectLayer:SUB_CL_LOGON_SUCCESS(event)
    if SceneMgr.sceneName == SCENE_HALL then
        self:removeFromParent()
        require("common.MsgBoxLayer"):create(0,nil,"重连成功!")
    elseif SceneMgr.sceneName == SCENE_GAME then
        UserData.Game:sendMsgCheckIsPlaying()
    else
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL)
        require("common.MsgBoxLayer"):create(0,nil,"重连成功!")
    end

end

function ReconnectLayer:SUB_CL_USER_LOCK_SERVER(event)
    local data = event._usedata
    if data.cbPlaying == 1 then
        if UserData.Game.tableGames[data.wKindID] == nil then
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL) 
            require("common.MsgBoxLayer"):create(0,nil,string.format("您的账号已经被锁在%d,请联系客服解锁！",data.wKindID))
        else
            UserData.Game:sendMsgConnectGame(data)
        end
    else
        require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL)
        require("common.MsgBoxLayer"):create(0,nil,"重连成功!您上一局游戏已经结束！")
    end
end

function ReconnectLayer:EVENT_TYPE_CONNECT_GAME_FAILED(event)
    self:startConnect()
end

function ReconnectLayer:SUB_GR_LOGON_ERROR(event)
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL)
    require("common.MsgBoxLayer"):create(0,nil,"重连成功!")
end

function ReconnectLayer:SUB_GR_USER_ENTER(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require(StaticData.Games[data.wKindID].luaGameFile):create(UserData.User.userID,data),SCENE_GAME)
    require("common.MsgBoxLayer"):create(0,nil,"重连成功!")
end

function ReconnectLayer:SUB_GR_LOGON_SUCCESS(event)
    local data = event._usedata
    require("common.SceneMgr"):switchScene(require("app.MyApp"):create():createView("HallLayer"),SCENE_HALL)
    require("common.MsgBoxLayer"):create(0,nil,"重连成功!您上一局游戏已经结束！")
    NetMgr:getGameInstance():closeConnect()
end

return ReconnectLayer

