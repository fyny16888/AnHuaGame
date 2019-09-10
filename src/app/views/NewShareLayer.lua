local Common = require("common.Common")
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local  HttpUrl = require("common.HttpUrl")
local NewShareLayer = class("NewShareLayer", cc.load("mvc").ViewBase)

function NewShareLayer:onEnter()
    self.interval = 0
end

function NewShareLayer:onExit()

end

function NewShareLayer:onCleanup()

end

function NewShareLayer:onCreate(params)
    local shareData = params[1]
    local callback = params[2]
    -- if shareData == nil then
    --     require("common.MsgBoxLayer"):create(0,nil,"分享配置错误!")
    --     -- return
    -- end
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("NewShareLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    Common:addTouchEventListener(self.root,function() 
        require("common.SceneMgr"):switchTips()
        --self:removeFromParent()
    end,true)

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_close"),function() 
        self:removeFromParent()
    end)

    local Button_WXShare = ccui.Helper:seekWidgetByName(self.root,"Button_WXShare")
    Common:addTouchEventListener(Button_WXShare,function() 
        local data = clone(UserData.Share.tableShareParameter[0])
        data.cbTargetType = 2
        UserData.Share:doShare(data,function(ret) 
            local record = UserData.Welfare.tableWelfare[1004]
            if ret == 1 then
                if record ~= nil and record.IsEnded == 0 then
                    UserData.Welfare:sendMsgRequestWelfare(1004)  
                else
                    require("common.MsgBoxLayer"):create(0,nil,"分享成功，您今天已经领取过奖励！")
                end
            else
                require("common.MsgBoxLayer"):create(0,nil,"分享失败")  
            end
        end)
        require("app.MyApp"):create(data):createView("ShareLayer")   
    end)

    local Button_PengShare = ccui.Helper:seekWidgetByName(self.root,"Button_PengShare")
    Common:addTouchEventListener(Button_PengShare,function() 
        local data = clone(UserData.Share.tableShareParameter[0])
        data.cbTargetType = 1
        UserData.Share:doShare(data,function(ret) 
            local record = UserData.Welfare.tableWelfare[1005]
            if ret == 1 then
                if record ~= nil and record.IsEnded == 0 then
                    UserData.Welfare:sendMsgRequestWelfare(1005)  
                else
                    require("common.MsgBoxLayer"):create(0,nil,"邀请成功，您今天已经领取过奖励！")
                end
            else
                require("common.MsgBoxLayer"):create(0,nil,"邀请失败")  
            end  
        end)
    end)
    require("common.SceneMgr"):switchTips(self)   
end


return NewShareLayer

