local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local Default = require("common.Default")

local Bag = {
    tableBag = {}
}

function Bag:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE) 
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 
end

function Bag:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE) 
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL) 
end

function Bag:EVENT_TYPE_NET_RECV_MESSAGE(event)
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

    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_USER  and subCmdID == NetMsgId.SUB_CL_USER_PROP then
        local wPropID = netInstance.cppFunc:readRecvWORD() --道具ID
        local dwPropCount = netInstance.cppFunc:readRecvDWORD()  --道具数量
        if StaticData.Items[wPropID] ~= nil then
            self.tableBag[wPropID] = dwPropCount
        end
        if wPropID == 1008 or wPropID == 1003 then
            EventMgr:dispatch(EventType.SUB_CL_USER_INFO)
        end
    else
    
    end
    
end

function Bag:EVENT_TYPE_FIRST_ENTER_HALL(event)

end

--获取背包数据
function Bag:sendMsgGetBag(cbReqRoot)
    self.tableBag = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_USER,NetMsgId.REQ_CL_USER_PROP,"b",cbReqRoot)
end

function Bag:getBagPropCount(itemID)
	if self.tableBag[itemID] == nil then
	   return 0
	end
	
    return self.tableBag[itemID]
end

return Bag