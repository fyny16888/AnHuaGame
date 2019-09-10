local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameConfig = require("common.GameConfig") 

local EmailLayer = class("EmailLayer", cc.load("mvc").ViewBase)

function EmailLayer:onEnter()
    --EventMgr:registListener(EventType.EVENT_TYPE_EMAIL_NEW,self,self.EVENT_TYPE_EMAIL_NEW)  --邮件刷新     
    EventMgr:registListener(EventType.RET_DEL_MAIL,self,self.RET_DEL_MAIL)
    EventMgr:registListener(EventType.RET_READ_MAIL,self,self.RET_READ_MAIL)
    
end

function EmailLayer:onExit()
    --EventMgr:unregistListener(EventType.EVENT_TYPE_EMAIL_NEW,self,self.EVENT_TYPE_EMAIL_NEW)
    EventMgr:unregistListener(EventType.RET_DEL_MAIL,self,self.RET_DEL_MAIL)
    EventMgr:registListener(EventType.RET_READ_MAIL,self,self.RET_READ_MAIL)
end

function EmailLayer:onCleanup()

end
    
function EmailLayer:onCreate(parameter)
    NetMgr:getGameInstance():closeConnect()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("USEmailLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function(sender,event) self:removeFromParent() end)
    
    local uiPanel_ReadEmail = ccui.Helper:seekWidgetByName(self.root,"Panel_ReadEmail")
    uiPanel_ReadEmail:setVisible(false)
    
    self.Panel_item = ccui.Helper:seekWidgetByName(self.root,"Panel_item") --邮件子项
    self.Panel_item:retain()
    self.Panel_item:setVisible(false)
    
    local ListView_Email = ccui.Helper:seekWidgetByName(self.root,"ListView_Email") --邮件
    ListView_Email:removeAllChildren()
    self:showList()
              
    -- Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_AllDelete"),function()     
    --     for i = 1 , #UserData.Email.tableEmail do
    --         if UserData.Email.tableEmail[i].bRead == true then 
    --             UserData.Email:sendMsgDelEmail(UserData.Email.tableEmail[i].dwMailID)
    --         else 
    --             require("common.MsgBoxLayer"):create(0,nil,"删除邮件失败!有邮件没读取!")
    --         end
    --     end
    -- end)
    
end

function EmailLayer:showList()
    local ListView_Email = ccui.Helper:seekWidgetByName(self.root,"ListView_Email") --邮件
    ListView_Email:removeAllChildren()
    for i = 1 , #UserData.Email.tableEmail do
        local subitem = self.Panel_item:clone()
        subitem:setVisible(true)
        subitem.data = UserData.Email.tableEmail[i]
        subitem:setScaleX(0.8)
        subitem:runAction(cc.Sequence:create(cc.DelayTime:create(0.1*(i-1)),cc.ScaleTo:create(0.4,1.1,1),cc.ScaleTo:create(0.2,1)))        
        ListView_Email:pushBackCustomItem(subitem)       
        local uiImage_item = ccui.Helper:seekWidgetByName(subitem,"Image_item") --名字 
        uiImage_item:loadTexture(string.format("achannel/%d/icon.png",CHANNEL_ID))
        local Text_subject1 = ccui.Helper:seekWidgetByName(subitem,"Text_subject1") --名字
        local Text_subject2 = ccui.Helper:seekWidgetByName(subitem,"Text_subject2") --邮件
        local Text_time = ccui.Helper:seekWidgetByName(subitem,"Text_time") --时间
        Text_subject1:setString("发件人：系统")        
        Text_subject2:setString(string.format("标题：%s",subitem.data.szTitle))
        Text_subject1:setColor(cc.c3b(0,0,0))
        Text_subject2:setColor(cc.c3b(0,0,0))
        Text_time:setColor(cc.c3b(0,0,0))
        local y,m,d,h,mi,s = Common:getYMDHMS(subitem.data.dwSenderTime)
        print("时间：",y,m,d,h,mi,s,subitem.data.dwSenderTime)
        local h0 = ""
        local m0 = "" 
        if h < 10 then
            h0 = "0"
        end
        if mi < 10 then
            m0 = "0"
        end
        Text_time:setString(y.."-"..m.."-"..d.." "..h0..h..":"..m0..mi..":"..s)
        local uiImage_state = ccui.Helper:seekWidgetByName(subitem,"Image_state")                   
        if subitem.data.bRead == true  then 
            uiImage_state:loadTexture("Email/Email_11.png")
        end 
        local uiButton_item = ccui.Helper:seekWidgetByName(subitem,"Button_item")        
        Common:addTouchEventListener(uiButton_item,function() local data = subitem.data  
              self:ShowEmail(data)end)                                         
        end 

end

function EmailLayer:ShowEmail(data) 
    if data == nil then 
        return
    end 
    
    for i = 1 , #UserData.Email.tableEmail do
        if UserData.Email.tableEmail[i].dwMailID == data.dwMailID then 
            UserData.Email:sendMsgReadEmail(data.dwMailID)
            data = UserData.Email.tableEmail[i]
        end 
    end
    local uiPanel_ReadEmail = ccui.Helper:seekWidgetByName(self.root,"Panel_ReadEmail") --邮件
    uiPanel_ReadEmail:setVisible(false)
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_shut"),
        function(sender,event) uiPanel_ReadEmail:setVisible(false) end)
        
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(uiPanel_ReadEmail,"Button_Delete"),function() 
        --删除邮件
        UserData.Email:sendMsgDelEmail(data.dwMailID)
    end)
    local uiImage_item = ccui.Helper:seekWidgetByName(uiPanel_ReadEmail,"Image_item") --名字 
    uiImage_item:loadTexture(string.format("achannel/%d/icon.png",CHANNEL_ID))
    local uiText_subject1 = ccui.Helper:seekWidgetByName(uiPanel_ReadEmail,"Text_subject1") --名字
    local uiText_subject2 = ccui.Helper:seekWidgetByName(uiPanel_ReadEmail,"Text_subject2") --邮件
    local uiText_time = ccui.Helper:seekWidgetByName(uiPanel_ReadEmail,"Text_time") --时间
    local uiText_EmailTitle = ccui.Helper:seekWidgetByName(uiPanel_ReadEmail,"Text_EmailTitle") --名字
    local uiText_EmailText = ccui.Helper:seekWidgetByName(uiPanel_ReadEmail,"Text_EmailText") --名字    
    uiText_subject1:setString("发件人：系统")        
    uiText_subject2:setString(string.format("标题：%s",data.szTitle))
    
    local y,m,d,h,mi,s = Common:getYMDHMS(data.dwSenderTime)
    local h0 = ""
    local m0 = "" 
    if h < 10 then
        h0 = "0"
    end
    if mi < 10 then
        m0 = "0"
    end
    uiText_time:setString(y.."-"..m.."-"..d.." "..h0..h..":"..m0..mi..":"..s)   
    uiText_EmailTitle:setString(string.format("%s",data.szTitle))
    uiText_EmailText:setString(string.format("%s",data.szContent))
    
    self.Panel_Reward = ccui.Helper:seekWidgetByName(self.root,"Panel_Reward") --奖励子项
    self.Panel_Reward:retain()
    self.Panel_Reward:setVisible(false)
    local ListView_items = ccui.Helper:seekWidgetByName(self.root,"ListView_items") --奖励列表
    ListView_items:removeAllChildren()
    if data.szcProp~= "" then     
--        local tableReward = {}
        local tempTable = Common:stringSplit(data.szcProp,"|")
        for key, var in pairs(tempTable) do
            local tempReward = Common:stringSplit(var,"_")
            local rewardData = {}
            rewardData.wPropID = tonumber(tempReward[1])
            rewardData.dwPropCount = tonumber(tempReward[2])
--            table.insert(tableReward,#tableReward + 1, rewardData)                        
            if StaticData.Items[rewardData.wPropID] ~= nil then
                local subitem = self.Panel_Reward:clone()           
                subitem:setVisible(true)            
                ListView_items:pushBackCustomItem(subitem)          
                local uiImage_icon = ccui.Helper:seekWidgetByName(subitem,"Image_icon") --奖品图片        
                uiImage_icon:loadTexture(StaticData.Items[rewardData.wPropID].img)
                local uiText_count = ccui.Helper:seekWidgetByName(subitem,"Text_count") --奖品图片        
                uiText_count:setString(string.format("%d*%s",rewardData.dwPropCount,StaticData.Items[rewardData.wPropID].name))    
            end        
        end
    else  
    end 
    

end 

function EmailLayer:RET_DEL_MAIL(event) 
    local data = event._usedata
    if data.lRet == 0 then
        for i = 1 , #UserData.Email.tableEmail do
            if UserData.Email.tableEmail[i].dwMailID == data.dwMailID then 
                table.remove(UserData.Email.tableEmail,i)
            end 
        end     
        local uiPanel_ReadEmail = ccui.Helper:seekWidgetByName(self.root,"Panel_ReadEmail") --邮件
        uiPanel_ReadEmail:setVisible(false)
        require("common.MsgBoxLayer"):create(0,nil,"删除邮件成功!")
        self:showList()
    else
        require("common.MsgBoxLayer"):create(0,nil,"删除邮件失败!")
    end
end 

function EmailLayer:RET_READ_MAIL(event) 
    local data = event._usedata
    if data.lRet == 0 then
        local uiPanel_ReadEmail = ccui.Helper:seekWidgetByName(self.root,"Panel_ReadEmail") --邮件
        if uiPanel_ReadEmail ~= nil then         
            uiPanel_ReadEmail:setVisible(true)
        end
                              
        for i = 1 , #UserData.Email.tableEmail do                 
            if UserData.Email.tableEmail[i].dwMailID == data.dwMailID then          
                --处理奖励
                local tableReward = {}
                local temp = false              
                local tempTable = Common:stringSplit(UserData.Email.tableEmail[i].szcProp,"|")
                for key, var in pairs(tempTable) do
                    local tempReward = Common:stringSplit(var,"_")
                    local rewardData = {}
                    rewardData.wPropID = tonumber(tempReward[1])
                    rewardData.dwPropCount = tonumber(tempReward[2])
                    table.insert(tableReward,#tableReward + 1, rewardData)                                    
                    if tableReward[key].rewardData ~= nil and  StaticData.Items[tableReward[key].rewardData.wPropID] ~= nil then   
                       temp = true
                    end         
                end 
                if  UserData.Email.tableEmail[i].bRead == false   then                 
                    UserData.User:sendMsgUpdateUserInfo(0)
                    UserData.Email.tableEmail[i].bRead = true
                    if UserData.Email.tableEmail[i].szcProp ~= "" and temp == true then                     
                        require("common.RewardLayer"):create("奖励",nil,tableReward)
                    end     
                end    
                EventMgr:dispatch(EventType.EVENT_TYPE_EMAIL_NEW)
                    
                            --刷新活动              
            end 
        end      
        self:showList()
  
    else
        require("common.MsgBoxLayer"):create(0,nil,"读取邮件失败!")
    end
end

 
return EmailLayer