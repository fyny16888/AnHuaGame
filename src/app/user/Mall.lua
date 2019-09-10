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

local Mall = {
    className = "com/coco2dx/org/HelperAndroid",
    tableMallConfig = {},
    tableMallFirstChargeRecord = {}
}

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

function Mall:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function Mall:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function Mall:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIN then
        return
    elseif netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end
    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    if mainCmdID ~= NetMsgId.MDM_CL_MALL then
        return
    end

    if subCmdID == NetMsgId.RET_MALL_CONFIG then
        local data = {}
        data.dwChannelType = netInstance.cppFunc:readRecvDWORD()
        data.dwMallID = netInstance.cppFunc:readRecvDWORD()
        data.dwGoodsID = netInstance.cppFunc:readRecvDWORD()
        data.szTitle = netInstance.cppFunc:readRecvString(32)
        data.szContents = netInstance.cppFunc:readRecvString(64)
        data.cbUnit = netInstance.cppFunc:readRecvByte()
        data.lPrice = netInstance.cppFunc:readRecvLong()
        data.cbTargetUnit = netInstance.cppFunc:readRecvByte()
        data.lCount = netInstance.cppFunc:readRecvLong()
        data.lFirst = netInstance.cppFunc:readRecvLong()
        data.lGift = netInstance.cppFunc:readRecvLong()
        if self.tableMallConfig[data.dwMallID] == nil then
            self.tableMallConfig[data.dwMallID] = {}
        end
        table.insert(self.tableMallConfig[data.dwMallID], #self.tableMallConfig[data.dwMallID]+1, data)

    elseif subCmdID == NetMsgId.RET_MALL_FIRST_CHARGE_RECORD then
        local dwCount = netInstance.cppFunc:readRecvLong()
        for i = 1, dwCount do
            local dwGoodsID = netInstance.cppFunc:readRecvDWORD()
            if dwGoodsID ~= 0 then
                self.tableMallFirstChargeRecord[dwGoodsID] = dwGoodsID
            end
        end

    elseif subCmdID == NetMsgId.RET_MALL_EXCHANGE_REDENVELOPE then
        local data = {}
        data.Result = netInstance.cppFunc:readRecvLong()
        data.szCode = netInstance.cppFunc:readRecvString(32)
        EventMgr:dispatch(EventType.RET_MALL_EXCHANGE_REDENVELOPE,data)

    elseif subCmdID == NetMsgId.RET_GET_MALL_LOG then
        local data = {}
        data.dwUserID = netInstance.cppFunc:readRecvDWORD()
        data.dwMallID = netInstance.cppFunc:readRecvDWORD()
        data.dwGoodsID = netInstance.cppFunc:readRecvDWORD()
        data.szOrderID = netInstance.cppFunc:readRecvString(32)
        data.cbUnit = netInstance.cppFunc:readRecvByte()
        data.lPrice = netInstance.cppFunc:readRecvLong()
        data.cbTargetUnit = netInstance.cppFunc:readRecvByte()
        data.lCount = netInstance.cppFunc:readRecvLong()
        data.lFirst = netInstance.cppFunc:readRecvLong()
        data.lGift = netInstance.cppFunc:readRecvLong()
        data.szExchangeCode = netInstance.cppFunc:readRecvString(32)       --领取码
        data.szPayType = netInstance.cppFunc:readRecvString(128)
        data.wStatus = netInstance.cppFunc:readRecvWORD()                  -- 0 不成功  1成功
        data.dwCreateTime = netInstance.cppFunc:readRecvDWORD()            --时间
        data.szNickName = netInstance.cppFunc:readRecvString(32)
        data.szLogoInfo = netInstance.cppFunc:readRecvString(256)
        EventMgr:dispatch(EventType.RET_GET_MALL_LOG,data)

    elseif subCmdID == NetMsgId.RET_GET_MALL_LOG_FINISH then
        local data = {}
        data.lRet = netInstance.cppFunc:readRecvBool()
        EventMgr:dispatch(EventType.RET_GET_MALL_LOG_FINISH,data)
    else
    
    end 
end

function Mall:EVENT_TYPE_FIRST_ENTER_HALL(event)
    self.tableMallConfig = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MALL, NetMsgId.REQ_MALL_CONFIG, "d", 0)
    self:sendMsgGetRechargeRecord()
end

function Mall:sendMsgGetRechargeRecord()
    self.tableMallFirstChargeRecord = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MALL, NetMsgId.REQ_MALL_FIRST_CHARGE_RECORD, "")
end

function Mall:sendMsgGetRequestmallRecord(userID, mallID, page)
    --self.tableMallFirstChargeRecord = {}
    local UserData = require("app.user.UserData")
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MALL, NetMsgId.REQ_GET_MALL_LOG, "ddw",userID,mallID,page)
end

function Mall:doPay(cbType,dwGoodsID,dwUserID,szParameter)
    local Common = require("common.Common")
    if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID  then
        local methodName = "jniDoPay" 
        local args = { tostring(cbType),tostring(dwGoodsID),tostring(dwUserID),szParameter }  
        local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String)V" 
        luaj.callStaticMethod(self.className ,methodName,args , nil)
    elseif PLATFORM_TYPE == cc.PLATFORM_OS_APPLE_REAL then
        cus.JniControl:getInstance():doWPPay(cbType,dwGoodsID,dwUserID,szParameter)
    end    
end

function Mall:doExchange(orderform,UserId)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MALL, NetMsgId.REQ_MALL_EXCHANGE_REDENVELOPE, "dd", UserId, orderform)   
end

--SDK支付回调
function cc.exports.setPayResult(data)
    cc.Director:getInstance():getRunningScene():runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function(sender,event) EventMgr:dispatch(EventType.EVENT_TYPE_RECHARGE_PAY_RESULT,tonumber(data)) end)))    
end

return Mall