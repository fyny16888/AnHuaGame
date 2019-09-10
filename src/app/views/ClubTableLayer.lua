local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")

local ClubTableLayer = class("ClubTableLayer", cc.load("mvc").ViewBase)

function ClubTableLayer:onEnter()
    EventMgr:registListener(EventType.RET_DISBAND_CLUB_TABLE,self,self.RET_DISBAND_CLUB_TABLE)
end

function ClubTableLayer:onExit()
    EventMgr:unregistListener(EventType.RET_DISBAND_CLUB_TABLE,self,self.RET_DISBAND_CLUB_TABLE)
end


function ClubTableLayer:onCreate(parames)
    local data = parames[1]
    local isAdmin = parames[2] or false
    if not data then
        printError('ClubTableLayer:onCreate data error')
        return
    end

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("ClubTableLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Image_bg")
    self.csb = csb
    
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_close"),function() 
        self:removeFromParent()
    end)
    for i = 1, 8 do
        local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",i))
        if i > data.wChairCount then
            uiPanel_player:setVisible(false)
            
        elseif data.dwUserID[i] ~= 0 then
            local uiImage_avatar = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_avatar")
            Common:requestUserAvatar(data.dwUserID[i],data.szLogoInfo[i],uiImage_avatar,"img")
            local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
            uiText_name:setTextColor(cc.c3b(41,20,0))
            uiText_name:setString(data.szNickName[i])
            local uiText_ID = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_ID")
            uiText_ID:setTextColor(cc.c3b(41,20,0))
            uiText_ID:setString(string.format("ID:%d",data.dwUserID[i]))

            local uiText_score = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_score")
            uiText_score:setTextColor(cc.c3b(41,20,0))
            uiText_score:setString(string.format("分数:%d",data.lScore[i]))
            uiText_score:setVisible(isAdmin)
        else
        
        end
    end
    -- local uiText_info = ccui.Helper:seekWidgetByName(self.root,"Text_info")
    -- uiText_info:setString(string.format("当前局数 %d/%d\n当前人数 %d/%d",data.wCurrentGameCount,data.wGameCount,data.wCurrentChairCount,data.wChairCount))
    local uiButton_join = ccui.Helper:seekWidgetByName(self.root,"Button_join")
    uiButton_join:setPressedActionEnabled(true)
    Common:addTouchEventListener(uiButton_join,function() 
        if UserData.Guild.isChangeClubTable then
            require("common.MsgBoxLayer"):create(1,nil,"当前桌子将解散，是否切换牌桌？",function() 
                NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_LEAVE_TABLE_USER,"")
            end)
        else
            uiButton_join:removeAllChildren()
            uiButton_join:addChild(require("app.MyApp"):create(data.dwTableID):createView("InterfaceJoinRoomNode"))
        end
    end)

    local uiButton_exit = ccui.Helper:seekWidgetByName(self.root,"Button_exit")
    uiButton_exit:setPressedActionEnabled(true)
    Common:addTouchEventListener(uiButton_exit,function()
         require("common.MsgBoxLayer"):create(1,nil,"您确定要解散房间？",function() 
            UserData.Guild:exitClubTable(UserData.User.userID, data.dwTableID, data.dwClubID)
        end)
    end)
    self:setShowUI(isAdmin)

    --玩法
    local gameName = StaticData.Games[data.wKindID].name
    local roomDes = string.format(" 房间:%d %d/%d局   ", data.dwTableID, data.wCurrentGameCount,data.wGameCount)
    local playwayDes = require("common.GameDesc"):getGameDesc(data.wKindID, data.tableParameter)
    local Text_playway = ccui.Helper:seekWidgetByName(self.root,"Text_playway")
    Text_playway:setString('玩法介绍：' .. gameName .. roomDes .. playwayDes)
end

function ClubTableLayer:setShowUI(isAdmin)
    local Button_exit = ccui.Helper:seekWidgetByName(self.root,"Button_exit")
    local Button_join = ccui.Helper:seekWidgetByName(self.root,"Button_join")
    local size = Button_join:getParent():getContentSize()
    if isAdmin then
        Button_exit:setVisible(true)
        Button_join:setVisible(true)
        Button_exit:setPositionX(size.width * 0.3)
        Button_join:setPositionX(size.width * 0.7)
    else
        Button_exit:setVisible(false)
        Button_join:setVisible(true)
        Button_join:setPositionX(size.width * 0.5)
    end
end

function ClubTableLayer:RET_DISBAND_CLUB_TABLE(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"解散桌子失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"解散桌子成功!")
    self:removeFromParent()
end

return ClubTableLayer