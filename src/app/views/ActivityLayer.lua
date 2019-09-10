local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameConfig = require("common.GameConfig")


local ActivityLayer = class("ActivityLayer", cc.load("mvc").ViewBase)


function ActivityLayer:onEnter()

end

function ActivityLayer:onExit()

end

function ActivityLayer:onCreate(parames)
    cc.UserDefault:getInstance():setIntegerForKey(Default.UserDefault_TuHaoActivity,os.time())  
    local data = parames[1]

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("ActivityLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        self:removeFromParent()
    end)

    local uiButton_meiju = ccui.Helper:seekWidgetByName(self.root,"Button_meiju")
    local uiButton_daili = ccui.Helper:seekWidgetByName(self.root,"Button_daili")
    local uiButton_zuobi = ccui.Helper:seekWidgetByName(self.root,"Button_zuobi")


    local uiImage_meiju1 = ccui.Helper:seekWidgetByName(self.root,"Image_meiju1")
    local uiImage_meiju2 = ccui.Helper:seekWidgetByName(self.root,"Image_meiju2")
    local uiImage_daili1 = ccui.Helper:seekWidgetByName(self.root,"Image_daili1")
    local uiImage_daili2 = ccui.Helper:seekWidgetByName(self.root,"Image_daili2")
    local uiImage_zuobi1 = ccui.Helper:seekWidgetByName(self.root,"Image_zuobi1")
    local uiImage_zuobi2 = ccui.Helper:seekWidgetByName(self.root,"Image_zuobi2")
    uiImage_meiju1:setVisible(false)
    uiImage_meiju2:setVisible(false)
    uiImage_daili1:setVisible(false)
    uiImage_daili2:setVisible(false)
    uiImage_zuobi1:setVisible(false)
    uiImage_zuobi2:setVisible(false)
    local uiPanel_dl = ccui.Helper:seekWidgetByName(self.root,"Panel_dl")
    local uiPanel_mj = ccui.Helper:seekWidgetByName(self.root,"Panel_mj")
    local uiPanel_zb = ccui.Helper:seekWidgetByName(self.root,"Panel_zb")
    
    local function showUI(index) 
        if index == 1 then 
            uiButton_meiju:setBright(true)
            uiButton_daili:setBright(false)
            uiButton_zuobi:setBright(false)

            uiButton_meiju:setEnabled(false)
            uiButton_daili:setEnabled(true)
            uiButton_zuobi:setEnabled(true)

            uiImage_meiju1:setVisible(true)
            uiImage_meiju2:setVisible(false)
            uiImage_daili1:setVisible(false)
            uiImage_daili2:setVisible(true)
            uiImage_zuobi1:setVisible(false)
            uiImage_zuobi2:setVisible(true)

            uiPanel_dl:setVisible(false)
            uiPanel_mj:setVisible(true)
            uiPanel_zb:setVisible(false)

        elseif  index == 2 then 
            uiButton_meiju:setBright(false)
            uiButton_daili:setBright(true)
            uiButton_zuobi:setBright(false)
            uiButton_meiju:setEnabled(true)
            uiButton_daili:setEnabled(false)
            uiButton_zuobi:setEnabled(true)

            uiImage_meiju1:setVisible(false)
            uiImage_meiju2:setVisible(true)
            uiImage_daili1:setVisible(true)
            uiImage_daili2:setVisible(false)
            uiImage_zuobi1:setVisible(false)
            uiImage_zuobi2:setVisible(true)

            uiPanel_dl:setVisible(true)
            uiPanel_mj:setVisible(false)
            uiPanel_zb:setVisible(false)
        
        elseif  index == 3 then 

            uiButton_meiju:setBright(false)
            uiButton_daili:setBright(false)
            uiButton_zuobi:setBright(true)
            uiButton_meiju:setEnabled(true)
            uiButton_daili:setEnabled(true)
            uiButton_zuobi:setEnabled(false)

            uiImage_meiju1:setVisible(false)
            uiImage_meiju2:setVisible(true)
            uiImage_daili1:setVisible(false)
            uiImage_daili2:setVisible(true)
            uiImage_zuobi1:setVisible(true)
            uiImage_zuobi2:setVisible(false)

            uiPanel_dl:setVisible(false)
            uiPanel_mj:setVisible(false)
            uiPanel_zb:setVisible(true)

        end   
    end
    showUI(2)  
    
    Common:addTouchEventListener(uiButton_meiju,function() showUI(1)  end)  
    Common:addTouchEventListener(uiButton_daili,function() showUI(2)  end)  
    Common:addTouchEventListener(uiButton_zuobi,function() showUI(3)  end)  


    --快速开始
    local wKindID = cc.UserDefault:getInstance():getIntegerForKey('quick_game_kindId', 78)
    local cbLevel = cc.UserDefault:getInstance():getIntegerForKey('quick_game_level', 1)
    local Button_lkqw = ccui.Helper:seekWidgetByName(self.root,"Button_lkqw")
    Common:addTouchEventListener(Button_lkqw,function() 
        require("common.SceneMgr"):switchTips(require("app.MyApp"):create(wKindID):createView("QuickStartGameNode"))
    end) 


    local Button_wx = ccui.Helper:seekWidgetByName(self.root,"Button_wx")
    Common:addTouchEventListener(Button_wx,function() 
        UserData.User:copydata("dxxqp668") 
        require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
    end)

    local Button_gzh = ccui.Helper:seekWidgetByName(self.root,"Button_gzh")
    Common:addTouchEventListener(Button_gzh,function() 
        UserData.User:copydata("dxxqp168") 
        require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
    end)

end 

return ActivityLayer