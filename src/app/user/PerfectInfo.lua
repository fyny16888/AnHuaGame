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

local PerfectInfo = {
    tableWelfare = {},
    tableWelfareConfig = {},
}

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

function PerfectInfo:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function PerfectInfo:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

--function PerfectInfo:EVENT_TYPE_FIRST_ENTER_HALL(event)
--    --发送寻求玩家信息
--    print("发送寻求玩家信息")  
--    local UserData = require("app.user.UserData")  
--    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_USER, NetMsgId.REQ_CL_USER_DETAIL,"d", UserData.User.userID)
--end

function PerfectInfo:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local UserData = require("app.user.UserData")  
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
    
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_USER and subCmdID == NetMsgId.SUB_CL_SET_USER_DETAIL then 
        local luaFunc = NetMgr:getLoginInstance().cppFunc
        local data = {}
        data.dwCode     = netInstance.cppFunc:readRecvWORD()                   --//消息代码（1000-成功 1001-失败）
        data.dwUserID   = netInstance.cppFunc:readRecvDWORD()                   --//用户ID
        UserData.User.szRealName = netInstance.cppFunc:readRecvString(16)                --//真实姓名
        UserData.User.zIDNumber  = netInstance.cppFunc:readRecvString(20)                --//身份证号码
        UserData.User.szEMail    = netInstance.cppFunc:readRecvString(32)                --//邮箱
        UserData.User.szPhone    = netInstance.cppFunc:readRecvString(16)                --//手机号码
        data.szRealName = UserData.User.szRealName 
        data.zIDNumber = UserData.User.zIDNumber 
        data.szEMail = UserData.User.szEMail
        data.szPhone = UserData.User.szPhone
        print("完善资料结果",data.dwCode,data.dwUserID,data.szRealName,data.zIDNumber,data.szPhone) 
        EventMgr:dispatch(EventType.INFO_SET_USER_DETAIL,data)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_USER and subCmdID == NetMsgId.SUB_CL_USER_DETAIL then   
        local luaFunc = NetMgr:getLoginInstance().cppFunc
        local data = {}
        data.dwCode     = netInstance.cppFunc:readRecvWORD()                   --//消息代码（1000-成功 1001-失败）
        data.dwUserID   = netInstance.cppFunc:readRecvDWORD()                   --//用户ID
        UserData.User.szRealName = netInstance.cppFunc:readRecvString(16)                --//真实姓名
        UserData.User.zIDNumber  = netInstance.cppFunc:readRecvString(20)                --//身份证号码
        UserData.User.szEMail    = netInstance.cppFunc:readRecvString(32)                --//邮箱
        UserData.User.szPhone    = netInstance.cppFunc:readRecvString(16)                --//手机号码
        data.szRealName = UserData.User.szRealName 
        data.zIDNumber = UserData.User.zIDNumber 
        data.szEMail = UserData.User.szEMail
        data.szPhone = UserData.User.szPhone
        print("完善资料结果1",data.szRealName,data.zIDNumber,data.szPhone)  
        EventMgr:dispatch(EventType.UPDATE_SELF_USER_DETAIL,data)
    else

        return
    end    
end

function PerfectInfo:requestVerifyCode(phone)
    print("请求验证码")
--    local function onHttpRequestCompletedPhoneMsg()
--        print("onHttpRequestCompletedPhoneMsg",xmlHttpRequest.status)
--        if xmlHttpRequest.status == 200 then
--            local response = json.decode(xmlHttpRequest.response)
--            print("data",xmlHttpRequest.response)
--            if response["Basis"]["Status"] == 100 then
--                print("aaa = ",response["Result"])
--                if response["Result"] == nil then
--                    EventMgr:dispatch(EventType.UPDATE_SELF_VERIFYCODE,-1) 
--                    return
--                end
--                if response["Result"]["VerifyCode"] ~= nil and type(response["Result"]["VerifyCode"]) == "string" then
--                    local verifyCode = response["Result"]["VerifyCode"]
--                    EventMgr:dispatch(EventType.UPDATE_SELF_VERIFYCODE,verifyCode)
--                elseif type(response["Result"]["ret"]) == "number"  and  response["Result"]["ret"] == -1 then
--                    EventMgr:dispatch(EventType.UPDATE_SELF_VERIFYCODE,-1)
--                elseif type(response["Result"]["ret"]) == "number"  and  response["Result"]["ret"] == -2 then
--                    EventMgr:dispatch(EventType.UPDATE_SELF_VERIFYCODE,-2)
--                else
--                    EventMgr:dispatch(EventType.UPDATE_SELF_VERIFYCODE,-3)
--                end
--            end
--        else
--            EventMgr:dispatch(EventType.UPDATE_SELF_VERIFYCODE,-3)
--        end
--
--    end    
    local UserData = require("app.user.UserData")
    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xmlHttpRequest:setRequestHeader("Content-Type","application/json; charset=utf-8")
    xmlHttpRequest:open("GET",string.format(HttpUrl.POST_URL_phoneMsg,phone,CHANNEL_ID))
    print("公会ID不能为空",phone) 
    local function onHttpRequestCompleted()
        print("getWinXin123",xmlHttpRequest.status)
        if xmlHttpRequest.status == 200 then
            print("getWinXin",xmlHttpRequest.response)
            local data = json.decode(xmlHttpRequest.response)           
            EventMgr:dispatch(EventType.SUB_CL_TASK_REWARD,data)  
            return 
        end
        EventMgr:dispatch(EventType.SUB_CL_TASK_REWARD)  
    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
    xmlHttpRequest:send()   
end

function PerfectInfo:EVENT_TYPE_FIRST_ENTER_HALL(event)
    --发送寻求玩家信息
    print("发送寻求玩家信息")  
    local UserData = require("app.user.UserData")  
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_USER, NetMsgId.REQ_CL_USER_DETAIL,"d", UserData.User.userID)
end

return PerfectInfo