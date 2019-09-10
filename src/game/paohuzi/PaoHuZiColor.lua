---------------
--   聊天
---------------
local PaoHuZiColor = class("PaoHuZiColor", cc.load("mvc").ViewBase)
local GameCommon = require("game.paohuzi.GameCommon")
local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local EventMgr = require("common.EventMgr")
local Common = require("common.Common")
local Default = require("common.Default")

function PaoHuZiColor:onConfig()
	self.widget = {
        {'Button_close','onClose'},
        {'Button_conform','onOk'},
        {'Button_bg1','onButton_bg1'},
        {'Button_bg2','onButton_bg2'},
        {'Button_bg3','onButton_bg3'},
        {'Button_cardBg1','onButton_cardBg1'},
        {'Button_cardBg2','onButton_cardBg2'},
        {'Button_card1','onButton_card1'},
        {'Button_card2','onButton_card2'},
        {'Button_card3','onButton_card3'},
        {'Button_card4','onButton_card4'},
	}
end

function PaoHuZiColor:onEnter()
end

function PaoHuZiColor:onCreate()

    local tableButtonAll = {self.Button_bg1,self.Button_bg2,self.Button_bg3,self.Button_cardBg1,self.Button_cardBg2,self.Button_card1,self.Button_card2,self.Button_card3,self.Button_card4}
    local tableButton1 = {self.Button_bg1,self.Button_bg2,self.Button_bg3}
    local tableButton2 = {self.Button_cardBg1,self.Button_cardBg2}
    local tableButton3 = {self.Button_card1,self.Button_card2,self.Button_card3,self.Button_card4}
    for k,v in pairs(tableButtonAll) do
        local uiImage_di = ccui.Helper:seekWidgetByName(v,"Image_di")
        uiImage_di:setVisible(false)
    end

    Common:addCheckTouchEventListener(tableButton1,false,function(index)
        for k,v in pairs(tableButton1) do
            local uiImage_di = ccui.Helper:seekWidgetByName(v,"Image_di")
            if k == index then
                uiImage_di:setVisible(true)
            else
                uiImage_di:setVisible(false)
            end
        end
    end)

    Common:addCheckTouchEventListener(tableButton2,false,function(index)
        for k,v in pairs(tableButton2) do
            local uiImage_di = ccui.Helper:seekWidgetByName(v,"Image_di")
            if k == index then
                uiImage_di:setVisible(true)
            else
                uiImage_di:setVisible(false)
            end
        end
    end)

    Common:addCheckTouchEventListener(tableButton3,false,function(index)
        for k,v in pairs(tableButton3) do
            local uiImage_di = ccui.Helper:seekWidgetByName(v,"Image_di")
            if k == index then
                uiImage_di:setVisible(true)
            else
                uiImage_di:setVisible(false)
            end
        end
    end)

    local index = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaipaizhuo,0)
    if index == 0 then
        tableButton1[1]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton1[1],"Image_di")
        uiImage_di:setVisible(true)
    elseif index == 1 then
        tableButton1[2]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton1[2],"Image_di")
        uiImage_di:setVisible(true)
    elseif index == 2 then
        tableButton1[3]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton1[3],"Image_di")
        uiImage_di:setVisible(true)
    else
        tableButton1[1]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton1[1],"Image_di")
        uiImage_di:setVisible(true)
    end

    local index = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCardBg,0)
    if index == 0 then
        tableButton2[1]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton2[1],"Image_di")
        uiImage_di:setVisible(true)
    elseif index == 1 then
        tableButton2[2]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton2[2],"Image_di")
        uiImage_di:setVisible(true)
    else
        tableButton2[1]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton2[1],"Image_di")
        uiImage_di:setVisible(true)
    end

    local index = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_ZiPaiCard,0)
    if index == 0 then
        tableButton3[1]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton3[1],"Image_di")
        uiImage_di:setVisible(true)
    elseif index == 1 then
        tableButton3[2]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton3[2],"Image_di")
        uiImage_di:setVisible(true)
    elseif index == 2 then
        tableButton3[3]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton3[3],"Image_di")
        uiImage_di:setVisible(true)
    elseif index == 3 then
        tableButton3[4]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton3[4],"Image_di")
        uiImage_di:setVisible(true)
    else
        tableButton3[1]:setBright(true)
        local uiImage_di = ccui.Helper:seekWidgetByName(tableButton3[1],"Image_di")
        uiImage_di:setVisible(true)
    end
end



function PaoHuZiColor:onClose( )
    self:removeFromParent()
end

function PaoHuZiColor:onOk( )
    local tableButton1 = {self.Button_bg1,self.Button_bg2,self.Button_bg3}
    local tableButton2 = {self.Button_cardBg1,self.Button_cardBg2}
    local tableButton3 = {self.Button_card1,self.Button_card2,self.Button_card3,self.Button_card4}
    for k,v in pairs(tableButton1) do
        if v:isBright() then
            cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_ZiPaipaizhuo,k-1)
            break
        end
    end

    for k,v in pairs(tableButton2) do
        if v:isBright() then
            cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_ZiPaiCardBg,k-1)
            break
        end
    end

    for k,v in pairs(tableButton3) do
        if v:isBright() then
            cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_ZiPaiCard,k-1)
            break
        end
    end

    EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE)
    self:removeFromParent()
end

return PaoHuZiColor 