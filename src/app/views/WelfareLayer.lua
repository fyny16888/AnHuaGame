
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")

local WelfareLayer = class("WelfareLayer", cc.load("mvc").ViewBase)

function WelfareLayer:onEnter()
    self.interval = 0
    EventMgr:registListener(EventType.SUB_SC_ACTIONRESULT,self,self.SUB_SC_ACTIONRESULT)
end

function WelfareLayer:onExit()
    EventMgr:unregistListener(EventType.SUB_SC_ACTIONRESULT,self,self.SUB_SC_ACTIONRESULT)
end

function WelfareLayer:onCleanup()
    
end

function WelfareLayer:onCreate(params)
    local shareData = params[1]
    local callback = params[2]
    if shareData == nil then
        -- require("common.MsgBoxLayer"):create(0,nil,"分享配置错误!")
        -- return
    end
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("WelfareLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    local Button_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    Common:addTouchEventListener(Button_return,function() 
        self:removeFromParent()
    end)

    self:initShare()            --分享朋友圈  

    self:initBankruptcy()       --破产金

    local Button_SignIn = ccui.Helper:seekWidgetByName(self.root,"Button_SignIn")
    Common:addTouchEventListener(Button_SignIn,function() 
        -- self:removeFromParent()
        Button_SignIn:setBright(false)
        Button_SignIn:setEnabled(false)
    end)

    local Button_BindingCell = ccui.Helper:seekWidgetByName(self.root,"Button_BindingCell")
    Common:addTouchEventListener(Button_BindingCell,function() 
        -- self:removeFromParent()
        Button_BindingCell:setBright(false)
        Button_BindingCell:setEnabled(false)
    end)

end

function WelfareLayer:initShare()            --分享朋友圈

    local tableWelfareConfig =  UserData.Welfare.tableWelfareConfig
    local tableWelfare =  UserData.Welfare.tableWelfare
    local uiPanel_FriendSharing = ccui.Helper:seekWidgetByName(self.root,"Panel_FriendSharing")

    local Panel_FriendSharing = ccui.Helper:seekWidgetByName(self.root,"Panel_FriendSharing")
    local Button_FriendSharing = ccui.Helper:seekWidgetByName(self.root,"Button_FriendSharing")
    Common:addTouchEventListener(Button_FriendSharing,function() 
        require("app.MyApp"):create():createView("NewShareLayer")
        self:removeFromParent()
        -- Button_FriendSharing:setBright(false)
        -- Button_FriendSharing:setEnabled(false)
    end) 
    if tableWelfare == nil or tableWelfare[1004] == nil or tableWelfare[1004].IsEnded ~= 0 then 
        -- Button_FriendSharing:setBright(false)
        -- Button_FriendSharing:setEnabled(false)
    end 

    local tableTemp = Common:stringSplit(tableWelfareConfig[1004].tcPrize,"_")
   
    local Text_Reward = ccui.Helper:seekWidgetByName(Panel_FriendSharing,"Text_Reward")
    Text_Reward:setString("X"..tableTemp[2])

end 
function WelfareLayer:initBankruptcy()       --破产金

    local tableWelfareConfig =  UserData.Welfare.tableWelfareConfig
    local tableWelfare =  UserData.Welfare.tableWelfare
    
    local Panel_Relief = ccui.Helper:seekWidgetByName(self.root,"Panel_Relief")
    local Button_Relief = ccui.Helper:seekWidgetByName(Panel_Relief,"Button_Relief")
    Common:addTouchEventListener(Button_Relief,function() 
        if UserData.User.dwGold > 50 then
            require("common.MsgBoxLayer"):create(0,nil,"您的玩豆不少于50，不能领取救济金!")
        else
            UserData.Welfare:sendMsgRequestWelfare(1007)
        end
    end)

    if  tableWelfare == nil or tableWelfare[1007] == nil or tableWelfare[1007].IsEnded ~= 0 then 
        Button_Relief:setBright(false)
        Button_Relief:setEnabled(false)
    end 

    local tableTemp = Common:stringSplit(tableWelfareConfig[1007].tcPrize,"_")
   
    local Text_Reward = ccui.Helper:seekWidgetByName(Panel_Relief,"Text_Reward")
    Text_Reward:setString("X"..tableTemp[2])
end 


function WelfareLayer:SUB_SC_ACTIONRESULT(event)
	local data = event._usedata
    if data.wCode == 0 then
        UserData.User:sendMsgUpdateUserInfo(0)
        --处理奖励
        local tableReward = {}
        local tempTable = Common:stringSplit(data.szReward,"|")
        for key, var in pairs(tempTable) do
            local tempReward = Common:stringSplit(var,"_")
            local rewardData = {}
            rewardData.wPropID = tonumber(tempReward[1])
            rewardData.dwPropCount = tonumber(tempReward[2])
            table.insert(tableReward,#tableReward + 1, rewardData)
        end
        local data = event._usedata
        --刷新活动
        if data.dwActID == 1001 then

        elseif data.dwActID == 1002 then
        elseif data.dwActID == 1003 then
    
        elseif data.dwActID == 1004 then
        
        elseif data.dwActID == 1005 then
    
        elseif data.dwActID == 1006 then            
        elseif data.dwActID == 1007 then
            self:initBankruptcy()     
        else
            return
        end
        require("common.RewardLayer"):create("福利奖励",nil,tableReward)
    else
        require("common.MsgBoxLayer"):create(0,nil,"领取奖励失败!")
    end
end

return WelfareLayer