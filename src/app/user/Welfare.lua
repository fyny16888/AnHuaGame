local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local Default = require("common.Default")

local Welfare = {
    tableWelfare = {},
    tableWelfareConfig = {},
}

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

function Welfare:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function Welfare:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function Welfare:EVENT_TYPE_NET_RECV_MESSAGE(event)
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
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_ACTIVE  and subCmdID == NetMsgId.SUB_SC_ACTIVECONFIG then
        local data = {}
        data.dwChanel = netInstance.cppFunc:readRecvDWORD()                   --渠道ID
        data.dwActID = netInstance.cppFunc:readRecvDWORD()                     --福利ID
        data.IsActing = netInstance.cppFunc:readRecvByte()                       --福利状态
        data.dwBeginTime = netInstance.cppFunc:readRecvDWORD()                   --开启时间
        data.dwEndTime = netInstance.cppFunc:readRecvDWORD()                     --结束时间
        data.btEndType = netInstance.cppFunc:readRecvByte()                     --周期类型
        data.tcPrize = netInstance.cppFunc:readRecvString(256)                   --附加参数
        self.tableWelfareConfig[data.dwActID] = data
       
                
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_ACTIVE  and subCmdID == NetMsgId.SUB_SC_ACTIVERECORD then
        local data = {}
        data.dwChannel = netInstance.cppFunc:readRecvDWORD()                      --渠道ID
        data.dwUserID = netInstance.cppFunc:readRecvDWORD()                       --渠道ID
        data.dwActID = netInstance.cppFunc:readRecvDWORD()                     --福利ID
        data.IsEnded = netInstance.cppFunc:readRecvByte()                  --完成状态   标记本周期内是否已完成 0未完成 1已完成
        data.dwEndedTime = netInstance.cppFunc:readRecvDWORD()                   --修改时间
        data.stInfo = netInstance.cppFunc:readRecvString(256)                    --完成次数
        self.tableWelfare[data.dwActID] = data
        EventMgr:dispatch(EventType.SUB_SC_ACTIVERECORD,data)
        
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_ACTIVE  and subCmdID == NetMsgId.SUB_SC_ACTIONRESULT then
        local recordData = {}
        recordData.dwChannel = netInstance.cppFunc:readRecvDWORD()                      --渠道ID
        recordData.dwUserID = netInstance.cppFunc:readRecvDWORD()                       --渠道ID
        recordData.dwActID = netInstance.cppFunc:readRecvDWORD()                     --福利ID
        recordData.IsEnded = netInstance.cppFunc:readRecvByte()                  --完成状态   标记本周期内是否已完成 0未完成 1已完成
        recordData.dwEndedTime = netInstance.cppFunc:readRecvDWORD()                   --修改时间
        recordData.stInfo = netInstance.cppFunc:readRecvString(256)                    --完成次数
        self.tableWelfare[recordData.dwActID] = recordData
        
        local data = {}
        data.dwActID = recordData.dwActID                    --福利ID
        data.wCode = netInstance.cppFunc:readRecvByte()                        
        data.szReward = netInstance.cppFunc:readRecvString(256)    
        data.parame = netInstance.cppFunc:readRecvString(256)             --附加参数      
        
        EventMgr:dispatch(EventType.SUB_SC_ACTIONRESULT,data)
    else
    
    end
end

function Welfare:EVENT_TYPE_FIRST_ENTER_HALL(event)
    self.tableWelfare = {}
    self.tableWelfareConfig = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_ACTIVE,NetMsgId.SUB_CS_GETACTIVECONFIG,"d",CHANNEL_ID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_ACTIVE,NetMsgId.SUB_CS_GETACTIVERECORD,"d",CHANNEL_ID)
end

function Welfare:sendMsgRequestWelfare(wWelfareID)
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_ACTIVE,NetMsgId.SUB_CS_ACTIONACTIVE,"dd",CHANNEL_ID,wWelfareID)
end

return Welfare