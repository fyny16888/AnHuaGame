--[[
*名称:PaoHuZiLocationLayer
*描述:定位
*作者:[]
*创建日期:2018-07-11 10:07:55
*修改日期:
]]

local EventMgr              = require("common.EventMgr")
local EventType             = require("common.EventType")
local NetMgr                = require("common.NetMgr")
local NetMsgId              = require("common.NetMsgId")
local StaticData            = require("app.static.StaticData")
local UserData              = require("app.user.UserData")
local Common                = require("common.Common")
local Default               = require("common.Default")
local GameConfig            = require("common.GameConfig")
local Log                   = require("common.Log")
local GameCommon            = require("game.paohuzi.GameCommon") 

local PaoHuZiLocationLayer       = class("PaoHuZiLocationLayer", cc.load("mvc").ViewBase)

function PaoHuZiLocationLayer:onConfig()
    self.widget             = {
        {"Image_distance2"},
        {"Image_distance3"},
        {"Image_distance4"},
        {'Button_continue','onClose'},
        {'Button_exit','onQuit'},
    }
end

function PaoHuZiLocationLayer:onEnter()
    EventMgr:registListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)

    EventMgr:registListener(EventType.USER_LEAVETABLE,self,self.USER_LEAVETABLE)

end

function PaoHuZiLocationLayer:onExit()
    EventMgr:unregistListener(EventType.RET_GAMES_USER_POSITION,self,self.RET_GAMES_USER_POSITION)    

    EventMgr:unregistListener(EventType.USER_LEAVETABLE,self,self.USER_LEAVETABLE)
end

function PaoHuZiLocationLayer:onCreate(params)
    self.isDistance = params[1] --是否是距离报警
    self:refreshUI()
end

function PaoHuZiLocationLayer:onQuit( ... )
    if self.isDistance then
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_LEAVE_TABLE_USER,"")
    else
        NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GR_USER,NetMsgId.REQ_GR_DISMISS_TABLE,"")
    end
    self:removeFromParent()
end

function PaoHuZiLocationLayer:onClose()
    self:removeFromParent()
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function PaoHuZiLocationLayer:refreshUI()
    self.Image_distance2:setVisible(false)
    self.Image_distance3:setVisible(false)
    self.Image_distance4:setVisible(false)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    print('------------------------------->>>>',playerNum)
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

function PaoHuZiLocationLayer:showPlayerPosition(rootNode, playerNum)
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

function PaoHuZiLocationLayer:RET_GAMES_USER_POSITION(event)
    local playerNum = GameCommon.gameConfig.bPlayerCount
    local rootNode = self['Image_distance' .. playerNum]
    rootNode:setVisible(true)
    self:showPlayerPosition(rootNode, playerNum)
end

function PaoHuZiLocationLayer:USER_LEAVETABLE( ... )
    if self.isDistance then
        self:removeFromParent()
    end
end

return PaoHuZiLocationLayer