--[[
*名称:PaoHuZiPeopleInfo
*描述:个人信息
*作者:[]
*创建日期:2018-07-11 09:07:55
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

local AnimCnf = {
    {'yongzhou/ui/personInfo/hudonggun'},
    {'yongzhou/ui/personInfo/hudongnieji'},
    {'yongzhou/ui/personInfo/hudongzhadan'},
    {'yongzhou/ui/personInfo/hudongshuitong'},
    {'yongzhou/ui/personInfo/hudongmeigui'},
    {'yongzhou/ui/personInfo/hudongxihongshi'},
    {'yongzhou/ui/personInfo/hudongwoshou'},
    {'yongzhou/ui/personInfo/hudongpijiu'},
}

local PaoHuZiPeopleInfo= class("PaoHuZiPeopleInfo", cc.load("mvc").ViewBase)

function PaoHuZiPeopleInfo:onConfig()
    self.widget             = {
        {"Image_bg"},
        {"Image_avatar"},
        {"Text_name"},
        {"Text_id"},
        {'Panel_root','onClose'},
        {"Image_faceBg"},
        {"ListView_face"},
        {'Text_ip'},
        {'Text_loaction'},
        {'Button_location','onClickLocation'},
        {'Button_contol','onControl'},
        {'Text_contol'}
    }
end

function PaoHuZiPeopleInfo:onEnter()
end

function PaoHuZiPeopleInfo:onExit()
end

function PaoHuZiPeopleInfo:onCreate(param)
    local data = param[1]
    self.tableObj = param[2]
    self:refreshUI(data)
    self.isOpen = cc.UserDefault:getInstance():getBoolForKey('paohuziEffect', true)
    self:setButtonBrightState(self.isOpen)

    if GameCommon.gameConfig.bPlayerCount <= 2 or (GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom) then
        self.Button_location:setVisible(false)
    end
end

function PaoHuZiPeopleInfo:onClose()
    self:removeFromParent()
end

function PaoHuZiPeopleInfo:onControl()
    self.isOpen = not self.isOpen
    self:setButtonBrightState(self.isOpen)
end

function PaoHuZiPeopleInfo:setButtonBrightState(isBright)
	if isBright then
		local path = 'yongzhou/ui/personInfo/setting_btn_on.png'
		self.Button_contol:loadTextures(path, path, path)
		self.Text_contol:setPositionX(47.5)
		self.Text_contol:setString('开')
	else
		local path = 'yongzhou/ui/personInfo/setting_btn_off.png'
		self.Button_contol:loadTextures(path, path, path)
		self.Text_contol:setPositionX(86.5)
		self.Text_contol:setString('关')
    end   
    cc.UserDefault:getInstance():setBoolForKey('paohuziEffect', self.isOpen)
end


------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function PaoHuZiPeopleInfo:refreshUI(data)
    if type(data) ~= 'table' then
        printError('PaoHuZiPeopleInfo:refreshUI data error')
        return
    end
    
    local playInfo = self:getPlayerInfoByUserID(data.dwUserID)
    if not playInfo then
        return
    end

    Common:requestUserAvatar(data.dwUserID,playInfo.szPto,self.Image_avatar,"clip")
    self.Text_name:setString('昵称：' .. playInfo.szNickName)
    self.Text_id:setString('ID:' .. data.dwUserID)
    self.Text_ip:setString('IP: '.. Common:ipint2str(data.dwPlayAddr));
    if data.dwShamUserID ~= 0 and (GameCommon.tableConfig.nTableType == TableType_GoldRoom or GameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom) then
        self.Text_id:setString('ID:' .. data.dwShamUserID)
    end

    local city =  UserData.User.city;
    if city then
        city = '位置：' .. UserData.User.city;
    else
        city = '未知地点';
    end
    self.Text_loaction:setString(city);

    self:setFaceActions(data)
end

function PaoHuZiPeopleInfo:getPlayerInfoByUserID(dwUserID)
    for i,v in pairs(GameCommon.player or {}) do
        if v.dwUserID == dwUserID then
            return v
        end
    end
end

function PaoHuZiPeopleInfo:onClickLocation()
    self:onClose();
    require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(false):createGame("game.paohuzi.PaoHuZiLocationLayer"))
end

function PaoHuZiPeopleInfo:setFaceActions(data)
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
            for key,info in pairs(GameCommon.player or {}) do
                if info.dwUserID ~= 0 and info.dwUserID == data.dwUserID then
                    targetChair = info.wChairID
                   break
                end
            end
            local count = 0
            for k,v in pairs(GameCommon.player or {}) do
                count = count + 1
            end
            

            if count == 1 then
                require("common.MsgBoxLayer"):create(0,nil,"暂时无法发送")
                self:removeFromParent()
                return
            end
            if targetChair then
                 NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EFFECTS, "www", i, GameCommon:getRoleChairID(),targetChair)
            end
            
            self:removeFromParent()
        end)
    end
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------

return PaoHuZiPeopleInfo