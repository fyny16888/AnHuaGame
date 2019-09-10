local Bit = require("common.Bit")
local Common = require("common.Common")
local Net = require("common.Net")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local StaticData = require("app.static.StaticData")
local EventType = require("common.EventType")
local Default = require("common.Default")

local Email = { 
    tableEmail = {},
}

local luaj = nil
if PLATFORM_TYPE == cc.PLATFORM_OS_ANDROID then
    luaj = require("cocos.cocos2d.luaj")
end

function Email:onEnter()
    EventMgr:registListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:registListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end

function Email:onExit()
    EventMgr:unregistListener(EventType.EVENT_TYPE_NET_RECV_MESSAGE,self,self.EVENT_TYPE_NET_RECV_MESSAGE)
    EventMgr:unregistListener(EventType.EVENT_TYPE_FIRST_ENTER_HALL,self,self.EVENT_TYPE_FIRST_ENTER_HALL)
end


function Email:EVENT_TYPE_FIRST_ENTER_HALL(event)
   -- self:sendMsgRequestEmail()
   self:sendMsgHAVEUNREADMAIL()
end

function Email:sendMsgRequestEmail()
    self.tableEmail = {}
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MAIL,NetMsgId.REQ_GET_MAIL_LIST,"")
end

function Email:sendMsgReadEmail(data)
    --读取邮件
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MAIL,NetMsgId.REQ_READ_MAIL,"d",data)
end

function Email:sendMsgHAVEUNREADMAIL()
    self.tableEmail = {}--暂时屏蔽
    --NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MAIL,NetMsgId.REQ_HAVE_UNREAD_MAIL,"")
end

function Email:sendMsgDelEmail(data)
    --删除邮件
    NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_MAIL,NetMsgId.REQ_DEL_MAIL,"d",data)
end

function Email:EVENT_TYPE_NET_RECV_MESSAGE(event)
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
    
    if netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_MAIL  and subCmdID == NetMsgId.RET_GET_MAIL_LIST then    --获取邮件列表
            local data = {}
            data.dwMailID = netInstance.cppFunc:readRecvDWORD()                     --邮件ID
            data.bRead = netInstance.cppFunc:readRecvBool()                         --是否已读
            data.szTitle = netInstance.cppFunc:readRecvString(64)                   --邮件标题
            data.szContent = netInstance.cppFunc:readRecvString(512)                --邮件内容
            data.dwSenderTime = netInstance.cppFunc:readRecvDWORD()                 --发送的时间
            data.dwSenderID = netInstance.cppFunc:readRecvDWORD()                   --发件人ID
            data.szSenderName = netInstance.cppFunc:readRecvString(32)              --发件人名字
            data.szSenderLogoInfo = netInstance.cppFunc:readRecvString(256)          --发件人头像
            data.szcProp = netInstance.cppFunc:readRecvString(256)   --道具
            table.insert(self.tableEmail,#self.tableEmail + 1,data)     
            print("当前邮件数量:%d",#self.tableEmail,data.dwMailID)
            EventMgr:dispatch(EventType.EVENT_TYPE_EMAIL_NEW)
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_MAIL  and subCmdID == NetMsgId.RET_DEL_MAIL then       --返回删除邮件
            local data = {}
            data.lRet = netInstance.cppFunc:readRecvLong()
            data.dwMailID = netInstance.cppFunc:readRecvDWORD()                     --邮件ID
            EventMgr:dispatch(EventType.RET_DEL_MAIL,data)    
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_MAIL  and subCmdID == NetMsgId.RET_READ_MAIL then  --返回读取邮件
            local data = {}
            data.lRet = netInstance.cppFunc:readRecvLong()
            data.dwMailID = netInstance.cppFunc:readRecvDWORD()                     --邮件ID
            EventMgr:dispatch(EventType.RET_READ_MAIL,data)   
    elseif netID == NetMgr.NET_LOGIC and mainCmdID == NetMsgId.MDM_CL_MAIL  and subCmdID == NetMsgId.RET_HAVE_UNREAD_MAIL then  --返回是否有未读邮件 
            local data = {}
            data.lRet = netInstance.cppFunc:readRecvLong() 
            EventMgr:dispatch(EventType.RET_HAVE_UNREAD_MAIL,data)          
    end 
end

return Email