local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local EventType = require("common.EventType")
local EventMgr = require("common.EventMgr")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local Default = require("common.Default")
local Bit = require("common.Bit")


local GameplayLayer = class("GameplayLayer", cc.load("mvc").ViewBase)

function GameplayLayer:onEnter()

end

function GameplayLayer:onExit()

end

function GameplayLayer:onCreate(parameter)
    local locationID = parameter[1]
    self.showType    = parameter[2]    --显示类型  0默认     1设置亲友圈参数  2亲友圈自定义创房 3竞技场设置玩法
    self.dwClubID = parameter[3]
    NetMgr:getGameInstance():closeConnect()
    self.tableFriendsRoomParams = nil
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomCreateLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    Common:addTouchEventListener(ccui.Helper:seekWidgetByName(self.root,"Button_return"),function(sender,event) self:removeFromParent() end)
    
    
    local uiImage_biaoqian = ccui.Helper:seekWidgetByName(self.root,"Image_biaoqian")
    local textureName = "roomcreate/ft_title_rules.png"
    -- 图片大小配对 
    local texture = cc.TextureCache:getInstance():addImage(textureName)
    uiImage_biaoqian:loadTexture(textureName)
    uiImage_biaoqian:setContentSize(texture:getContentSizeInPixels())    
   -- uiImage_biaoqian:setVisible(false)
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
    --  列表间距              uiListView_betting:setItemsMargin(10)
    local uiButton_zipai = ccui.Helper:seekWidgetByName(self.root,"Button_zipai")      
    local uiButton_majiang = ccui.Helper:seekWidgetByName(self.root,"Button_majiang")  
    local uiButton_puke = ccui.Helper:seekWidgetByName(self.root,"Button_puke")      
    -- local regionID = cc.UserDefault:getInstance():getIntegerForKey(Default.UserDefault_RegionID,0)
    if locationID == nil or locationID == 0 then
        for key, var in pairs(UserData.Game.talbeCommonGames) do
            if var ~= 51 and var ~= 53 then
                locationID = var
                break
            end
        end
    end

    local uiButton_iten = ccui.Helper:seekWidgetByName(self.root,"Button_iten")
    uiButton_iten:retain()
    uiButton_iten:setVisible(false)

    local Text_8 = ccui.Helper:seekWidgetByName(self.root,"Text_8")
    Text_8:setVisible(false)
    local uiPanel_parameter = ccui.Helper:seekWidgetByName(self.root,"Panel_parameter")
    local uiPanel_para = ccui.Helper:seekWidgetByName(self.root,"Panel_para")
    uiPanel_parameter:setVisible(false)
    local function showGameType(type)
        if type == 1 then
            uiButton_zipai:setBright(true)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(false)    
        elseif type == 2 then
             uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(false)
            uiButton_puke:setBright(true)
        elseif type == 3 then
             uiButton_zipai:setBright(false)
            uiButton_majiang:setBright(true)
            uiButton_puke:setBright(false)
        end
        uiListView_games:removeAllItems()
        local games = {}
        games = clone(UserData.Game.tableSortGames)
        local isFound = false
        for key, var in pairs(games) do
            local wKindID = tonumber(var)
            local data = StaticData.Games[wKindID]
            if UserData.Game.tableGames[wKindID] ~= nil and Bit:_and(data.friends,1) ~= 0  and (data.type == type or type == nil ) and (wKindID ~= 51 or locationID == 51 or tableNiuNiuUserID[UserData.User.userID] ~= nil) and (wKindID ~= 53 or locationID == 53 or tableNiuNiuUserID[UserData.User.userID] ~= nil) then
                local item = uiButton_iten:clone()
                item.wKindID = wKindID
                item:setBright(false)
                item:setVisible(true)
                item:loadTextures(data.icon1,data.icon1,data.icons)
                uiListView_games:pushBackCustomItem(item)
                item:setAnchorPoint(cc.p(0,0.5))
                Common:addTouchEventListener(item,function() self:showGameParameter(wKindID) end)
                if wKindID == locationID then
                    isFound = true
                end
            end 
        end
        if isFound == true then
            local btn = self:showGameParameter(locationID)
            if btn ~= nil then
                btn:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function(sender,event)
                    --位置刷新
                    uiListView_games:refreshView()
                    local container = uiListView_games:getInnerContainer()
                    local pos = cc.p(btn:getPosition())
                    pos = cc.p(btn:getParent():convertToWorldSpace(pos))
                    pos = cc.p(container:convertToNodeSpace(pos))
                    local value = (1-pos.y/container:getContentSize().height)*100
                    if value <= 5 then
                        value = 0
                    elseif value >= 95 then
                        value = 100
                    end
                    uiListView_games:scrollToPercentVertical(value,1,true)
                end)))
            end
        else
            local item = uiListView_games:getItem(0)
            if item ~= nil then
                self:showGameParameter(item.wKindID)
            end
        end
    end 

    Common:addTouchEventListener(uiButton_zipai,function() showGameType(1) end)
    Common:addTouchEventListener(uiButton_puke,function() showGameType(2) end)
    Common:addTouchEventListener(uiButton_majiang,function() showGameType(3) end)
    -- if  #UserData.Game.tableSortGames <= 5 then  
    --     showGameType()
    -- else
    if locationID == nil or locationID == 0 or UserData.Game.tableGames[locationID] == nil then
        showGameType(3)
    else
        showGameType(StaticData.Games[locationID].type)
    end
    -- end
    -- showGameType(3)
end

function GameplayLayer:showGameParameter(wKindID)
    local uiListView_games = ccui.Helper:seekWidgetByName(self.root,"ListView_games")
    local items = uiListView_games:getItems()
    local node = nil
    for key, var in pairs(items) do
    	if var.wKindID == wKindID then
    	   if var:isBright() then
    	       return nil
    	   end
    	   node = var
           var:setBright(true)
    	else
            var:setBright(false)
    	end
    end

    local uiPanel_para = ccui.Helper:seekWidgetByName(self.root,"Panel_para")
    local uiListView_para = ccui.Helper:seekWidgetByName(self.root,"ListView_para")
    uiListView_para:removeAllItems()

    local para = ccui.ImageView:create(StaticData.Games[wKindID].ruleBtn)
    uiListView_para:pushBackCustomItem(para)
        -- uiPanel_para:removeAllChildren()  
        -- local uiWebView = ccexp.WebView:create()
        -- uiPanel_para:addChild(uiWebView)
        -- uiWebView:setContentSize(uiPanel_para:getContentSize())
        -- uiWebView:setAnchorPoint(cc.p(0.5,0.5))
        -- uiWebView:setPosition(uiWebView:getParent():getContentSize().width/2,uiWebView:getParent():getContentSize().height/2)
        -- uiWebView:setScalesPageToFit(true)
        -- uiWebView:loadURL(StaticData.Games[wKindID].ruleCSB)
        --uiWebView:enableDpadNavigation(false)

    return node
end

return GameplayLayer