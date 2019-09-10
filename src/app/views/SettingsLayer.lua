local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local HttpUrl = require("common.HttpUrl")
local NetMsgId = require("common.NetMsgId")
local SettingsLayer = class("SettingsLayer", cc.load("mvc").ViewBase)

function SettingsLayer:onEnter()
    
end

function SettingsLayer:onExit()
    
end

function SettingsLayer:onCreate(parames)
    local parames = parames[1]
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("SettingsLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.csb = csb

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function() 
        UserData.Music:saveVolume()
        EventMgr:dispatch(EventType.EVENT_TYPE_SKIN_CHANGE,3)
        require("common.SceneMgr"):switchOperation()
    end)

    print("++++++++++++!",parames)
    self:initSound(parames)  
end

function SettingsLayer:initSound(parames)

    print("++++++++++++@",parames)
    --版本信息
    local uiText_edition = ccui.Helper:seekWidgetByName(self.root,"Text_edition")
    if require("loading.Update").version ~= "" then
        local versionInfo = string.format("v%s",require("loading.Update").version)
        versionInfo ="版本:".. versionInfo.."."..tostring(CHANNEL_ID)
        uiText_edition:setString(versionInfo)
    end       

    local volumeSound = UserData.Music:getVolumeSound()
    local volumeMusic = UserData.Music:getVolumeMusic()
    local volumeVoice = UserData.Music:getVolumeVoice()

    local uiSlider_Music = ccui.Helper:seekWidgetByName(self.root,"Slider_Music")
    local uiSlider_Sound = ccui.Helper:seekWidgetByName(self.root,"Slider_Sound")
    uiSlider_Music:setPercent(volumeMusic * 100)
    uiSlider_Sound:setPercent(volumeSound * 100)

    uiSlider_Music:addEventListener(function(sender, eventType)
		local epsilon = sender:getPercent()/ 100
        UserData.Music:setVolumeMusic(epsilon)
	end)

    uiSlider_Sound:addEventListener(function(sender, eventType)
		local epsilon = sender:getPercent()/ 100
        UserData.Music:setVolumeSound(epsilon)
	end)

    local uiButton_qingsong = ccui.Helper:seekWidgetByName(self.root,"Button_qingsong")
    local uiButton_huankuai = ccui.Helper:seekWidgetByName(self.root,"Button_huankuai")
    local uiButton_xiuxian = ccui.Helper:seekWidgetByName(self.root,"Button_xiuxian")
    local items = {uiButton_qingsong, uiButton_huankuai,uiButton_xiuxian}
    local Musictype = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Musictype",1)

    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            local mousic = string.format("achannel/%d/music%d.mp3",CHANNEL_ID,index)
            cc.UserDefault:getInstance():setFloatForKey("UserDefault_Musictype",index)
            cc.SimpleAudioEngine:getInstance():playMusic(mousic,true)
        elseif index == 2 then
            local mousic = string.format("achannel/%d/music%d.mp3",CHANNEL_ID,index)
            cc.UserDefault:getInstance():setFloatForKey("UserDefault_Musictype",index)
            cc.SimpleAudioEngine:getInstance():playMusic(mousic,true)     
        elseif index == 3 then
            local mousic = string.format("achannel/%d/music%d.mp3",CHANNEL_ID,index)
            cc.UserDefault:getInstance():setFloatForKey("UserDefault_Musictype",index)
            cc.SimpleAudioEngine:getInstance():playMusic(mousic,true)         
        end
    end)
    if Musictype == 1 then
        items[1]:setBright(true)
    elseif Musictype == 2 then
        items[2]:setBright(true)
    elseif Musictype == 3 then
        items[3]:setBright(true)
    end
    

    local uiButton_Mandarin = ccui.Helper:seekWidgetByName(self.root,"Button_Mandarin")
    local uiButton_Dialect = ccui.Helper:seekWidgetByName(self.root,"Button_Dialect")
    local items = {uiButton_Mandarin,uiButton_Dialect}
    local Volume = cc.UserDefault:getInstance():getFloatForKey("volumeSelect",1)
    Common:addCheckTouchEventListener(items,false,function(index) 
        if index == 1 then
            cc.UserDefault:getInstance():setFloatForKey("volumeSelect",0)
        elseif index == 2 then
            cc.UserDefault:getInstance():setFloatForKey("volumeSelect",1)
        end
    end)
    if Volume == 0 then
        items[1]:setBright(true)
    elseif Volume == 1 then
        items[2]:setBright(true)
    end

    local uiButton_exit = ccui.Helper:seekWidgetByName(self.root,"Button_exit")    -- 退出游戏
    Common:addTouchEventListener(uiButton_exit,function()        
        NetMgr:getLogicInstance():closeConnect()
        cc.Director:getInstance():endToLua()
        EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
    end)

    local uiButton_logout = ccui.Helper:seekWidgetByName(self.root,"Button_logout") -- 切换账号
    Common:addTouchEventListener(uiButton_logout,function()        
            NetMgr:getLogicInstance():closeConnect()
            require("common.SceneMgr"):switchScene(require("app.MyApp"):create(false,false):createView("LoginLayer"),SCENE_LOGIN)
            EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
    end)


    local uiButton_Dissolution = ccui.Helper:seekWidgetByName(self.root,"Button_Dissolution") -- 切换账号
    Common:addTouchEventListener(uiButton_Dissolution,function()        
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER, NetMsgId.REQ_GR_DISMISS_TABLE, "")
        require("common.SceneMgr"):switchOperation()
        EventMgr:dispatch(EventType.EVENT_TYPE_EXIT_HALL)
    end)
 
    if parames ~= nil and  parames == 1 then
        uiButton_Dissolution:setVisible(false)
        uiButton_Dissolution:setEnabled(false)
    elseif parames ~= nil and  parames == 2 then
        uiButton_Dissolution:setVisible(false)
        uiButton_Dissolution:setEnabled(false)
        uiButton_exit:setVisible(false)
        uiButton_exit:setEnabled(false)
        uiButton_logout:setVisible(false)
        uiButton_logout:setEnabled(false)
    else
        uiButton_exit:setVisible(false)
        uiButton_exit:setEnabled(false)
        uiButton_logout:setVisible(false)
        uiButton_logout:setEnabled(false)
    end

end




return SettingsLayer
