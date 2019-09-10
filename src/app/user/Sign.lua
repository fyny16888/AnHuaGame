local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local json = require("json")
local Default = require("common.Default")
local HttpUrl = require("common.HttpUrl")

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

local Sign = {
    className = "com/coco2dx/org/HelperAndroid",

    tableSignData = nil
}

function Sign:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 
end

function Sign:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 
end

function Sign:EVENT_TYPE_NET_RECV_MESSAGE(event)
    local netID = event._usedata
    local netInstance = nil
    if netID == NetMgr.NET_LOGIC then
        netInstance = NetMgr:getLogicInstance()
    else
        return
    end

    local mainCmdID = netInstance.cppFunc:GetMainCmdID()
    local subCmdID = netInstance.cppFunc:GetSubCmdID()
    local luaFunc = NetMgr:getLogicInstance().cppFunc
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CHECKIN and subCmdID == NetMsgId.SUB_CL_CHECKINRECORD then
        local data = {}
        data.dw1Day = luaFunc:readRecvDWORD()             --每日签到奖金
        data.dw3Day = {}
        for i = 1 , 2 do
            data.dw3Day[i] = luaFunc:readRecvDWORD()          --3日签到礼包  0 表示金币数量  1 表示房卡数量
        end
        data.dw5Day = {}
        for i = 1 , 2 do
            data.dw5Day[i] = luaFunc:readRecvDWORD()
        end
        data.dw7Day = {}
        for i = 1 , 2 do
            data.dw7Day[i] = luaFunc:readRecvDWORD()
        end
        data.dw15Day = {}
        for i = 1 , 2 do
            data.dw15Day[i] = luaFunc:readRecvDWORD()
        end
        data.dwallDay = {}
        for i = 1 , 2 do
            data.dwallDay[i] = luaFunc:readRecvDWORD()
        end
        data.dwFee = {} --第一到第五次补签费用
        for i = 1 , 5 do
            data.dwFee[i] = luaFunc:readRecvDWORD()
        end
        data.btData = {}    --对应31天的签到情况 0 未签到  1 已签到  2 补签
        for i = 1 , 31 do   
            data.btData[i] = luaFunc:readRecvByte()
        end
        data.btGetPrice = {}    --对应3日，5日，7日，15日，全勤奖 领奖情况  0 不可领  1 未领  2 已领
        for i = 1 , 5 do
            data.btGetPrice[i] = luaFunc:readRecvByte()
        end   
        data.btSupCheckIndex = luaFunc:readRecvByte()    --表示当前第几次补签 0 表示还未补签
        self.tableSignData = data
    
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CHECKIN and subCmdID == NetMsgId.SUB_CL_CHECKRESULT then
        local data = {} 
        data.btCMD = luaFunc:readRecvByte()     
        data.btResult = luaFunc:readRecvByte()   --操作返回结果 0 成功  1失败 2金币不足(补签)
        EventMgr:dispatch(EventType.SUB_CL_CHECKRESULT,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_CHECKIN and subCmdID == NetMsgId.SUB_CL_FLUSHCHECKRECORD then
        self.tableSignData.btData = {}    --对应31天的签到情况 0 未签到  1 已签到  2 补签
        for i = 1 , 31 do   
            self.tableSignData.btData[i] = luaFunc:readRecvByte()
        end
        self.tableSignData.btGetPrice = {}    --对应3日，5日，7日，15日，全勤奖 领奖情况  0 不可领  1 未领  2 已领
        for i = 1 , 5 do
            self.tableSignData.btGetPrice[i] = luaFunc:readRecvByte()
        end   
        self.tableSignData.btSupCheckIndex = luaFunc:readRecvByte()    --表示当前第几次补签 0 表示还未补签
        EventMgr:dispatch(EventType.SUB_CL_FLUSHCHECKRECORD)
    else

    end
end

function Sign:EVENT_TYPE_FIRST_ENTER_HALL(event)
    self.tableSignData = nil
    --NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CHECKIN,NetMsgId.SUB_CL_CHECKINRECORD,"b",0)
end


return Sign