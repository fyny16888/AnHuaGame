local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local NetMgr = require("common.NetMgr")
local NetMsgId = require("common.NetMsgId")
local UserData = require("app.user.UserData")
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local NetMsgId = require("common.NetMsgId")

local Default = require("common.Default")
local GameConfig  = require("common.GameConfig")
local Log  = require("common.Log")


local PersonalLayer = class("PersonalLayer", function()
    return ccui.Layout:create()
end)

function PersonalLayer:create(wKindID,dwUserID,dwShamUserID)
    local view = PersonalLayer.new()
    view:onCreate(wKindID,dwUserID,dwShamUserID)
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

function PersonalLayer:onEnter()

end

function PersonalLayer:onExit()
    
end

function PersonalLayer:onCleanup()
end

function PersonalLayer:onCreate(wKindID,dwUserID,dwShamUserID)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("PersonInfoLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")

    Common:addTouchEventListener(self.root,function() 
        self:removeFromParent()
    end,true)
    
    local Image_bg = self.root:getChildByName("Image_bg")
    local callback = function()
        require("common.SceneMgr"):switchOperation()
    end  
    Common:playPopupAnim(Image_bg, nil, callback)
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setVisible(false)

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local wChairID = 0
    self.GameCommon = nil
    if wKindID == 42 then
        self.GameCommon = require("game.laopai.GameCommon")
    elseif wKindID == 43 then
        self.GameCommon = require("game.paohuzi.43.GameCommon") 
    elseif StaticData.Games[wKindID].type == 1 then
        self.GameCommon = require("game.paohuzi.GameCommon")
    elseif StaticData.Games[wKindID].type == 2 then
        self.GameCommon = require("game.puke.PDKGameCommon")
        if wKindID == 84 then 
            self.GameCommon = require("game.puke.DDZGameCommon")
        end 
    elseif StaticData.Games[wKindID].type == 3 then
        self.GameCommon = require("game.majiang.GameCommon")
    elseif StaticData.Games[wKindID].type == 4 then
        self.GameCommon = require("game.laopai.GameCommon")
    elseif StaticData.Games[wKindID].type == 5 then
        self.GameCommon = require("game.paohuzi.43.GameCommon")            
        return
    end
    for key, var in pairs(self.GameCommon.player) do
        if var.dwUserID == dwUserID then
            wChairID = var.wChairID
            break
        end
    end
    local viewID = self.GameCommon:getViewIDByChairID(wChairID) 
    
    local player = self.GameCommon:getUserInfoByUserID(dwUserID)
    if player == nil then
        return
    end
    
    local uiPanel_look = ccui.Helper:seekWidgetByName(self.root,"Panel_look")
    uiPanel_look:setVisible(false)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local uiButton_avatar = ccui.Helper:seekWidgetByName(self.root,"Button_avatar")
    Common:requestUserAvatar(player.dwUserID,player.szPto,uiButton_avatar,"btn")
    local uiText_name = ccui.Helper:seekWidgetByName(self.root,"Text_name")
    uiText_name:setString(player.szNickName)
    uiText_name:setString(string.format("%s",player.szNickName))
    local uiText_ID = ccui.Helper:seekWidgetByName(self.root,"Text_id")
    if dwShamUserID == 0 then
        uiText_ID:setString(string.format("%d",player.dwUserID))
    else
        uiText_ID:setString(string.format("%d",dwShamUserID))
    end
    local uiImage_genderIcon = ccui.Helper:seekWidgetByName(self.root,"Image_genderIcon")   
    if player.cbSex == 0 then
        uiImage_genderIcon:loadTexture("user/user_g.png")
    end
    self.ListView_face  = ccui.Helper:seekWidgetByName(self.root,"ListView_face")   
    self:setFaceActions(dwUserID)

    self.isOpen = cc.UserDefault:getInstance():getBoolForKey('HHOpenUserEffect', true)

    self.Button_contol = ccui.Helper:seekWidgetByName(self.root,"Button_contol")
    self.Text_contol = ccui.Helper:seekWidgetByName(self.root,"Text_contol")
    if viewID ~= 1 then 
        self.Button_contol:setVisible(false)
    else
        self.Button_contol:setVisible(true)
    end 
    Common:addTouchEventListener(self.Button_contol,function() 
        self:onControl()
    end,true)

	self:setButtonBrightState(self.isOpen)
    -- local uiText_ip = ccui.Helper:seekWidgetByName(self.root,"Text_ip")
    -- uiText_ip:setVisible(false)
    -- if self.GameCommon.player[wChairID].location.x < 0.1 then
    --     uiText_ip:setVisible(false)
    -- else
    --     uiText_ip:setString(string.format("%d %d",self.GameCommon.player[wChairID].location.x,self.GameCommon.player[wChairID].location.y))
    -- end 
    require("common.SceneMgr"):switchOperation(self)
end

function PersonalLayer:onControl()
    self.isOpen = not self.isOpen
    self:setButtonBrightState(self.isOpen)
end

function PersonalLayer:setButtonBrightState(isBright)
	if isBright then
		local path = 'user/setting_btn_on.png'
		self.Button_contol:loadTextures(path, path, path)
		self.Text_contol:setPositionX(47.5)
		self.Text_contol:setString('开')
	else
		local path = 'user/setting_btn_off.png'
		self.Button_contol:loadTextures(path, path, path)
		self.Text_contol:setPositionX(86.5)
		self.Text_contol:setString('关')
    end   
    cc.UserDefault:getInstance():setBoolForKey('HHOpenUserEffect', self.isOpen)
end

local AnimCnf = {
    {'user/info/quantao', 'expression/baodai'},
    {'user/info/daoshui', 'expression/daoshui'},
    {'user/info/fq', 'expression/fq'},
    {'user/info/yiduohua', 'expression/meigui008'},
    {'user/info/pengbei', 'expression/pengbei'},
    {'user/info/yibahua', 'expression/xianhua'},
}


function PersonalLayer:setFaceActions(dwUserID)
    local faceArr = self.ListView_face:getChildren()
    for i,v in ipairs(faceArr) do
        v:setVisible(false)
    end

    for i,v in ipairs(AnimCnf) do
        local item = faceArr[i]
        if not item then
            item = faceArr[1]:clone()
            self.ListView_face:pushBackCustomItem(item)
        end
        item:setVisible(true)
        local Image_faceIcon = ccui.Helper:seekWidgetByName(item,'Image_faceIcon')
        Image_faceIcon:loadTexture(v[1] .. '.png')

        Image_faceIcon:ignoreContentAdaptWithSize(true)

        item:setPressedActionEnabled(true)
        item:addClickEventListener(function()
            --- 房
            local targetChair = nil           
            for key,info in pairs(self.GameCommon.player or {}) do
                if info.dwUserID ~= 0 and info.dwUserID == dwUserID then
                    targetChair = info.wChairID
                   break
                end
            end
            local count = 0
            for k,v in pairs(self.GameCommon.player or {}) do
                count = count + 1
            end
            if count == 1 then
                require("common.MsgBoxLayer"):create(0,nil,"暂时无法发送")
                self:removeFromParent()
                return
            end
            if targetChair  then
                 NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EFFECTS, "www", i, self.GameCommon:getRoleChairID(),targetChair)
            else 
                require("common.MsgBoxLayer"):create(0,nil,"暂时无法发送")
            end
            
            self:removeFromParent()
        end)
    end
end

return PersonalLayer