local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local Default = require("common.Default")
local GameConfig = require("common.GameConfig")
local Log = require("common.Log")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")
local GameCommon = nil

local PositionLayer = class("PositionLayer", function()
    return ccui.Layout:create()
end)


function PositionLayer:create(wKindID)
    local view = PositionLayer.new()
    view:onCreate(wKindID)
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

function PositionLayer:onEnter()

end

function PositionLayer:onExit()
    
end

function PositionLayer:onCleanup()
end

function PositionLayer:onCreate(wKindID)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("PositionLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    local uiImage_distanceBg = ccui.Helper:seekWidgetByName(self.root,"Image_distanceBg")
    Common:addTouchEventListener(self.root,function() 
        self:removeFromParent()
    end,true)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local wChairID = 0


    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_continue"),function() 
        self:removeFromParent()
    end,true)

    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_exit"),function() 
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
        self:removeFromParent()
    end,true)

    if StaticData.Games[wKindID].type == 1 then
        GameCommon = require("game.paohuzi.GameCommon")
    elseif StaticData.Games[wKindID].type == 2 then
        GameCommon = require("game.puke.PDKGameCommon")   
        if wKindID == 84 then 
            GameCommon = require("game.puke.DDZGameCommon")
        elseif wKindID == 85 then
            GameCommon = require("game.puke.SDHGameCommon")
        end
    elseif StaticData.Games[wKindID].type == 3 then  
        GameCommon = require("game.majiang.GameCommon")
    else
        return
    end

    self.Image_distance2 = ccui.Helper:seekWidgetByName(uiImage_distanceBg,"Image_distance2")
    self.Image_distance3 = ccui.Helper:seekWidgetByName(uiImage_distanceBg,"Image_distance3")
    self.Image_distance4 = ccui.Helper:seekWidgetByName(uiImage_distanceBg,"Image_distance4")

    self.Image_distance2:setVisible(false)
    self.Image_distance3:setVisible(false)
    self.Image_distance4:setVisible(false)

    self:refreshUI()
    
    -- for key, var in pairs(GameCommon.player) do
    --     if var.dwUserID == GameCommon.dwUserID then
    --         wChairID = var.wChairID
    --         break
    --     end
    -- end

--    if GameCommon.gameConfig.bPlayerCount == 2 then
--         if StaticData.Games[wKindID].type == 1 then
--             local uiPanel_player3 = ccui.Helper:seekWidgetByName(self.root,"Panel_player3")
--             uiPanel_player3:setVisible(false)
--         else
--             local uiPanel_player2 = ccui.Helper:seekWidgetByName(self.root,"Panel_player2")
--             uiPanel_player2:setVisible(false)
--         end 
--     end
    -- local viewID = GameCommon:getViewIDByChairID(wChairID) 
    -- for wChairID = 0, 2 do
    --     if GameCommon.player[wChairID] ~= nil then
    --         local viewID = GameCommon:getViewIDByChairID(wChairID)
    --         local uiPanel_player = ccui.Helper:seekWidgetByName(self.root,string.format("Panel_player%d",viewID))
    --         local uiPanel_playerInfo = ccui.Helper:seekWidgetByName(uiPanel_player,"Panel_playerInfo")
    --         uiPanel_playerInfo:setVisible(true)
    --         local uiText_name = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_name")
    --         uiText_name:setString(GameCommon.player[wChairID].szNickName)
    --         local uiText_ID = ccui.Helper:seekWidgetByName(uiPanel_player,"Text_ID")
    --         uiText_ID:setVisible(false)
    --         if GameCommon.player[wChairID].dwOhterID ~= nil and GameCommon.player[wChairID].dwOhterID ~= 0 then
    --             uiText_ID:setString(string.format("%d",GameCommon.player[wChairID].dwOhterID))
    --         else
    --             uiText_ID:setString(string.format("%d",GameCommon.player[wChairID].dwUserID))
    --         end
    --         -- local uiImage_gender = ccui.Helper:seekWidgetByName(uiPanel_player,"Image_gender")
    --         -- uiImage_gender:setVisible(false)
    --         -- if GameCommon.player[wChairID].cbSex == 0 then
    --         --     uiImage_gender:loadTexture("user/user_g.png")
    --         -- end
    --         for wTargetChairID = 0, GameCommon.gameConfig.bPlayerCount-1 do
    --             local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
    --             if wTargetChairID ~= wChairID then
    --                 local uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",viewID,targetViewID))
    --                 if viewID > targetViewID then
    --                     uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",targetViewID,viewID))
    --                 end
    --                 if GameCommon.gameConfig.bPlayerCount == 2 then                
    --                     if StaticData.Games[wKindID].type == 1 then
    --                         uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",1,2))
    --                     else
    --                         uiText_location = ccui.Helper:seekWidgetByName(self.root,string.format("Text_%dto%d",1,3))
    --                     end 
    --                 end 
    --                 if uiText_location ~= nil then
    --                     local distance = uiText_location:getString()
    --                     if GameCommon.gameConfig.bPlayerCount == 3 and (wChairID == 3 or wTargetChairID == 3) then
    --                         distance = ""
    --                     elseif GameCommon.player[wChairID] == nil or GameCommon.player[wTargetChairID] == nil then
    --                         distance = "等待加入..."
    --                     elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
    --                         if distance == "500m" then
    --                             distance = math.random(1000,300000)
    --                         end
    --                     elseif GameCommon.player[wChairID].location.x < 0.1 then
    --                         distance = string.format("%s未开启定位",GameCommon.player[wChairID].szNickName)
    --                     elseif GameCommon.player[wTargetChairID].location.x < 0.1 then
    --                         distance = string.format("%s未开启定位",GameCommon.player[wTargetChairID].szNickName)
    --                     else
    --                         distance = GameCommon:GetDistance(GameCommon.player[wChairID].location,GameCommon.player[wTargetChairID].location) 
    --                     end                     
    --                     if type(distance) == "string" then

    --                     elseif distance > 1000 then
    --                         distance = string.format("%dkm",distance/1000)
    --                     else
    --                         distance = string.format("%dm",distance)
    --                     end
    --                     uiText_location:setString(distance)
    --                 end
    --             end
    --         end
    --     end
    -- end
    require("common.SceneMgr"):switchOperation(self)
end

function PositionLayer:refreshUI()
    self.Image_distance2:setVisible(false)
    self.Image_distance3:setVisible(false)
    self.Image_distance4:setVisible(false)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    print('------------------------------->>>>',playerNum)
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end


function PositionLayer:showPlayerPosition(rootNode, playerNum)
    for i=1,playerNum do
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",i))
        if uiPanel_players then
            uiPanel_players:setVisible(false)
        end
    end
    for wChairID = 0, playerNum - 1 do            
        local viewID = GameCommon:getViewIDByChairID(wChairID) --wChairID + 1
        local uiPanel_players = ccui.Helper:seekWidgetByName(rootNode,string.format("Panel_players%d",viewID))
        print('------------------->>>>',uiPanel_players,viewID)
        local var = GameCommon.player[wChairID]
        if var then

            local x = GameCommon.player[wChairID].location.x
            local y = GameCommon.player[wChairID].location.y
            --已经加入了的
            local imageAvatar =  ccui.Helper:seekWidgetByName(uiPanel_players,'Image_avatar')
         
            Common:requestUserAvatar(var.dwUserID,var.szPto,imageAvatar,"clip")

            uiPanel_players:setVisible(true)
            local Text_name = ccui.Helper:seekWidgetByName(uiPanel_players,"Text_name")
            local Userip = NetMgr:getLogicInstance().cppFunc:int2ip(GameCommon.player[wChairID].dwPlayAddr)
            Text_name:setString(GameCommon.player[wChairID].szNickName)
            for wTargetChairID = 0, playerNum - 1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)  --wTargetChairID + 1
                local isAddHong = false
                if viewID < targetViewID then
                    local uiText_location = ccui.Helper:seekWidgetByName(rootNode,string.format("Text_%dto%d",viewID,targetViewID))
                    local hxLocation = ccui.Helper:seekWidgetByName(rootNode,string.format("Image_%dto%d",viewID,targetViewID))
                    if uiText_location then
                        local distance = ''
                        local disHX = 0
                        if GameCommon.player[wChairID] == nil or GameCommon.player[wTargetChairID] == nil then
                            distance = "等待加入..."
                        elseif GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom then
                            distance = math.random(1000,300000)
                            disHX = distance
                        elseif GameCommon.player[wChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",GameCommon.player[wChairID].szNickName)
                            isAddHong = true
                        elseif GameCommon.player[wTargetChairID].location.x < 0.1 then
                            distance = string.format("%s\n未开启定位",GameCommon.player[wTargetChairID].szNickName)
                            isAddHong = true
                        else
                            distance = GameCommon:GetDistance(GameCommon.player[wChairID].location,GameCommon.player[wTargetChairID].location) 
                        end                     
                        if type(distance) == "string" then

                        elseif distance > 1000 then
                            disHX = distance/1000
                            distance = string.format("%dkm",distance/1000)
                        else
                            disHX = distance
                            distance = string.format("%dm",distance)
                            if disHX < 500 then --500米
                                isAddHong = true
                            end
                        end
                        local path ='majiang/ui/location/'
                        if isAddHong then
                            hxLocation:loadTexture(path .. 'PlayerGPS12.png')
                            uiText_location:setColor(cc.c3b(255, 0, 0))
                        else
                            hxLocation:loadTexture(path .. 'PlayerGPS13.png')
                            uiText_location:setColor(cc.c3b(122,55,36))
                        end
                        uiText_location:setString(distance)
                    end
                end
            end
        else
            uiPanel_players:setVisible(false)
            for wTargetChairID = 0,  playerNum - 1 do
                local targetViewID = GameCommon:getViewIDByChairID(wTargetChairID)
                if wTargetChairID ~= wChairID and viewID < targetViewID  then
                    local uiText_location = ccui.Helper:seekWidgetByName(rootNode,string.format("Text_%dto%d",viewID,targetViewID))
                    print('-->>>>>>>>>',viewID,targetViewID)
                    uiText_location:setColor(cc.c3b(122,55,36))
                    if GameCommon.player[wTargetChairID] then
                        uiText_location:setString("等待加入...")
                    else
                        uiText_location:setString("")
                    end
                end
            end
        end
    end
end

return PositionLayer
    