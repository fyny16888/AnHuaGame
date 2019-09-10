local Common = require("common.Common")


local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")

local MsgBoxLayer = class("MsgBoxLayer", function()
    return cc.Node:create()
end)

--@param    type: 0文本提示   1确定取消  2确定  3同意拒绝 
--@return   node: 制定加入的父节点
--require("common.MsgBoxLayer"):create(0,nil,"恭喜您获得1000金币")
--require("common.MsgBoxLayer"):create(1,nil,"您确定要退出游戏？",okCallback,cancelCallback)
--require("common.MsgBoxLayer"):create(2,nil,"请稍后...",okCallback)
--require("common.MsgBoxLayer"):create(3,nil,"是否同意该协议？",agreeCallback,refuseCallback)


function MsgBoxLayer:create(type,node,...)
    local view = MsgBoxLayer.new()
    view:onCreate(type,node,...)
    local function onEventHandler(eventType)  
        if eventType == "enter" then  
            view:onEnter() 
        elseif eventType == "exit" then
            view:onExit()
        elseif eventType == "cleanup" then
            view:onCleanup()
        end  
    end 
    view:registerScriptHandler(onEventHandler)
    return view
end

function MsgBoxLayer:onEnter()

end

function MsgBoxLayer:onExit()

end

function MsgBoxLayer:onCleanup()

end

function MsgBoxLayer:onCreate(type,node,...)
    local visibleSize = cc.Director:getInstance():getVisibleSize()    
    local csb = nil
    if type == 5 then
        csb = cc.CSLoader:createNode("NewXXMallLayer.csb")
    elseif type == 6 or type == 7 then
        csb = cc.CSLoader:createNode("ZZMsgBoxLayer.csb")
    else
        csb = cc.CSLoader:createNode("MsgBoxLayer.csb")
    end

    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb
    local params = {...}

    if type == 6 or type == 7 then
        self:initZZMsgBoxUI(type, params)
        if node ~= nil then
            node:addChild(self)
        else
            require("common.SceneMgr"):switchTips(self)
        end
        return
    end
    
    local uiPanel_ok = nil
    local uiPanel_okCancel = nil
    local uiPanel_agreeCancel = nil
    local uiPanel_tips = nil
    local uiPanel_Blackscreen = nil
    if type ~= 5 then
        uiPanel_ok = ccui.Helper:seekWidgetByName(self.root,"Panel_ok")
        uiPanel_okCancel = ccui.Helper:seekWidgetByName(self.root,"Panel_okCancel")
        uiPanel_agreeCancel = ccui.Helper:seekWidgetByName(self.root,"Panel_agreeCancel")
        uiPanel_tips = ccui.Helper:seekWidgetByName(self.root,"Panel_tips")
        uiPanel_Blackscreen = ccui.Helper:seekWidgetByName(self.root,"Panel_Blackscreen")

    end 
    if type == 0 then
        --文本提示
        uiPanel_ok:removeFromParent()
        uiPanel_okCancel:removeFromParent()
        uiPanel_agreeCancel:removeFromParent()
        uiPanel_tips:setVisible(true)
        uiPanel_Blackscreen:setVisible(false)
        local uiPanel_tipsBg = ccui.Helper:seekWidgetByName(self.root,"Panel_tipsBg")
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1])
        if uiText_contents:getAutoRenderSize().width + 50 < 600 then 
        else
             uiPanel_tipsBg:setContentSize(cc.size(uiText_contents:getAutoRenderSize().width + 50,50))
        end  
        uiText_contents:setPosition(uiText_contents:getParent():getContentSize().width/2,uiText_contents:getParent():getContentSize().height/2)
        uiPanel_tipsBg:setPosition(visibleSize.width/2,uiPanel_tipsBg:getPositionY())--,cc.MoveBy:create(2,cc.p(0,100))
        uiPanel_tipsBg:setOpacity(0)
        uiPanel_tipsBg:runAction(cc.Sequence:create(cc.FadeIn:create(0.2),cc.DelayTime:create(1.0),cc.MoveTo:create(0.5, cc.p(visibleSize.width/2,uiPanel_tipsBg:getPositionY()+100)),cc.FadeOut:create(0.2),cc.CallFunc:create(function(sender,event) self:removeFromParent() end)))
        self.root:setTouchEnabled(false)

    elseif type == 1 then
        --确定取消
        uiPanel_ok:removeFromParent()
        uiPanel_okCancel:setVisible(true)
        uiPanel_agreeCancel:removeFromParent()
        uiPanel_tips:removeFromParent()
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1]) 
        local uiButton_ok = ccui.Helper:seekWidgetByName(self.root,"Button_ok")
        Common:addTouchEventListener(uiButton_ok,function() 
            self:removeFromParent()
            if params[2] ~= nil then
                params[2]()
            end
        end)
        local uiButton_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")
        Common:addTouchEventListener(uiButton_cancel,function() 
            self:removeFromParent()
            if params[3] ~= nil then
                params[3]()
            end
        end)
        self.root:setTouchEnabled(true)
--        Common:playPopupAnim(uiPanel_okCancel)
    elseif type == 2 then
        --确定
        uiPanel_ok:setVisible(true)
        uiPanel_okCancel:removeFromParent()
        uiPanel_agreeCancel:removeFromParent()
        uiPanel_tips:removeFromParent()
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1]) 
        local uiButton_ok = ccui.Helper:seekWidgetByName(self.root,"Button_ok")
        Common:addTouchEventListener(uiButton_ok,function()
            self:removeFromParent() 
            if params[2] ~= nil then
                params[2]()
            end
        end)
        self.root:setTouchEnabled(true)
--        Common:playPopupAnim(uiPanel_ok)
    elseif type == 3 then
        --同意取消
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1]) 
        local uiButton_agree = ccui.Helper:seekWidgetByName(self.root,"Button_agree")
        Common:addTouchEventListener(uiButton_agree,function()
            self:removeFromParent() 
            if params[2] ~= nil then
                params[2]()
            end
        end)
        local uiButton_refuse = ccui.Helper:seekWidgetByName(self.root,"Button_refuse")
        Common:addTouchEventListener(uiButton_refuse,function() 
            self:removeFromParent()
            if params[3] ~= nil then
                params[3]()
            end
        end)
        self.root:setTouchEnabled(true)
--        Common:playPopupAnim(uiPanel_agreeCancel)
    elseif type == 5 then
        Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
            self:removeFromParent()
        end)   
        local uiText_contents = ccui.Helper:seekWidgetByName(self.root,"Text_contents")
        uiText_contents:setString(params[1])

    
        
        local uiText_1 = ccui.Helper:seekWidgetByName(self.root,"Text_1")
        local uiText_2 = ccui.Helper:seekWidgetByName(self.root,"Text_2")
        local uiText_3 = ccui.Helper:seekWidgetByName(self.root,"Text_3")
        uiText_1:setString(StaticData.Channels[CHANNEL_ID].serviceVX_1)
        uiText_2:setString(StaticData.Channels[CHANNEL_ID].serviceVX_2)
        uiText_3:setString(StaticData.Channels[CHANNEL_ID].serviceVX_2)
        local uiButton_1 = ccui.Helper:seekWidgetByName(self.root,"Button_1")
        local uiButton_2 = ccui.Helper:seekWidgetByName(self.root,"Button_2")
        local uiButton_3 = ccui.Helper:seekWidgetByName(self.root,"Button_3")    
        Common:addTouchEventListener(uiButton_1,function()   
            local btnName =  uiText_1:getString()
            UserData.User:copydata(btnName)
            require("common.MsgBoxLayer"):create(0,nil,"复制成功")
        end)
        Common:addTouchEventListener(uiButton_2,function()   
            local btnName = uiText_2:getString()
            UserData.User:copydata(btnName)
            require("common.MsgBoxLayer"):create(0,nil,"复制成功")
        end)
        Common:addTouchEventListener(uiButton_3,function()   
            local btnName = uiText_3:getString()
            UserData.User:copydata(btnName)
            require("common.MsgBoxLayer"):create(0,nil,"复制成功")
        end)
    else
        print("MsgBoxLayer,类型错误!",type)
        return
    end
    
    if node ~= nil then
        node:addChild(self)
    else
        require("common.SceneMgr"):switchTips(self)
    end
end


function MsgBoxLayer:initZZMsgBoxUI(type, params)
    local Text_title = ccui.Helper:seekWidgetByName(self.root,"Text_title")
    Text_title:setString(params[1])

    local Text_context = ccui.Helper:seekWidgetByName(self.root,"Text_context")
    Text_context:setString(params[2]) 
    
    if type == 6 then
        local Button_yes = ccui.Helper:seekWidgetByName(self.root,"Button_yes")
        Common:addTouchEventListener(Button_yes, function() 
            self:removeFromParent()
            if params[3] then
                params[3]()
            end
        end)

        local Button_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")
        Common:addTouchEventListener(Button_cancel, function() 
            self:removeFromParent()
            if params[4] then
                params[4]()
            end
        end)

    elseif type == 7 then
        local Button_yes = ccui.Helper:seekWidgetByName(self.root,"Button_yes")
        Button_yes:setPositionX(Button_yes:getParent():getContentSize().width / 2)
        Common:addTouchEventListener(Button_yes, function() 
            self:removeFromParent()
            if params[3] then
                params[3]()
            end
        end)

        local Button_cancel = ccui.Helper:seekWidgetByName(self.root,"Button_cancel")
        Button_cancel:setVisible(false)
    end
    
end

return MsgBoxLayer
