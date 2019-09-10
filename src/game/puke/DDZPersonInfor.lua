--[[*名称:DDZPersonInfor
*描述:个人信息
*作者:cxx
*创建日期:2018-07-06 14:07:55
*修改日期:
]]
local EventMgr			= require("common.EventMgr")
local EventType			= require("common.EventType")
local NetMgr			= require("common.NetMgr")
local NetMsgId			= require("common.NetMsgId")
local StaticData		= require("app.static.StaticData")
local UserData			= require("app.user.UserData")
local Common			= require("common.Common")
local Default			= require("common.Default")
local GameConfig		= require("common.GameConfig")
local Log				= require("common.Log")
local DDZGameCommon		= require("game.puke.DDZGameCommon")



local DDZPersonInfor	= class("DDZPersonInfor", cc.load("mvc").ViewBase)

function DDZPersonInfor:onConfig()
	self.widget			= {
		{'mask','onClose'},
		{'Image_avatar_player'},
		{'Text_name'},
		{'Text_id'},
		{'ScrollView_image'},
		{'expimage_template'},
		{"Button_contol", "onControl"},
	}
end

function DDZPersonInfor:onEnter()
	
end

function DDZPersonInfor:onExit()
	cc.UserDefault:getInstance():setBoolForKey('PDKOpenUserEffect', self.isOpen)
end

function DDZPersonInfor:onCreate(param)
	local data = param[1]
	self.uid = data.dwUserID
	self.tableObj = param[2]
	self:updateInfo(data)
	self:updateScrollviewImage()
	self.isOpen = cc.UserDefault:getInstance():getBoolForKey('PDKOpenUserEffect', true)
	self:updateControl()
end

function DDZPersonInfor:updateInfo( data )
	local playInfo = self:getPlayerInfoByUserID(data.dwUserID)
	Common:requestUserAvatar(data.dwUserID, playInfo.szPto, self.Image_avatar_player, "img")
	self.Text_name:setString(playInfo.szNickName)
	self.Text_id:setString('ID:' .. data.dwUserID)
	if data.dwShamUserID ~= 0 and (DDZGameCommon.tableConfig.nTableType == TableType_GoldRoom or DDZGameCommon.tableConfig.nTableType == TableType_RedEnvelopeRoom) then
        self.Text_id:setString('ID:' .. data.dwShamUserID)
    end
end

function DDZPersonInfor:updateControl( ... )
    if not self.isOpen then
        local path = 'puke/ui/switch_close.png'
        self.Button_contol:loadTextures(path, path, path)
    else
        local path = 'puke/ui/switch_open.png'
        self.Button_contol:loadTextures(path, path, path)
    end
end

function DDZPersonInfor:onControl()
    --是否开启
    self.isOpen = not self.isOpen
    self:updateControl()
end

function DDZPersonInfor:getPlayerInfoByUserID(dwUserID)

	for i, v in pairs(DDZGameCommon.player or {}) do
		if v.dwUserID == dwUserID then
			return v
		end
	end
end

function DDZPersonInfor:updateScrollviewImage()	
	local anim = require("game.puke.Animation") [24]
	local viewSize = self.ScrollView_image:getContentSize()
	local innersize = nil
	local y = self.expimage_template:getSize()
	local ontentSize = 4 *(y.height) 
	self.ScrollView_image:setInnerContainerSize(cc.size(viewSize.width, height))

	for i = 1, #anim do
		local node = self.expimage_template:clone()
		node:setVisible(true)
		local scale = 1
		node:setScale(scale)
		local animData = anim[i]
		local path = ''
		if animData then
			path = animData.imageFile .. '.png'
			local child = node:getChildByName('exp_image')
			child:loadTextures(path, path)
			child:ignoreContentAdaptWithSize(true)
		end
		node:setName(i)
		local size = node:getSize()
		innersize = size
		local row = math.floor((i - 1) / 4) -- 5行
		local colum =(i - 1) % 4  -- 3行
		local posx = 60 +(((size.width + 5) * scale ) * colum)
		local posy =(viewSize.height - 60 -(size.height * scale ) * row)
		node:setPosition(posx, posy)
		self:addListener(node, handler(self, self.buttonCall))
		self.ScrollView_image:addChild(node)
	end
end


function DDZPersonInfor:buttonCall(sender)
	local index = sender:getName()
	print('===>>>>>>',index)
	local targetChair = nil   
	for key,info in pairs(DDZGameCommon.player or {}) do
		if info.dwUserID ~= 0 and info.dwUserID == self.uid then
			targetChair = info.wChairID
		   break
		end
	end
	local playerNum = 0
	for k, v in pairs(DDZGameCommon.player or {}) do
		playerNum = playerNum + 1
	end
	if playerNum == 1 then
		require("common.MsgBoxLayer"):create(0,nil,"暂时不能发送")
		return
	end
	NetMgr:getGameInstance():sendMsgToSvr(NetMsgId.MDM_GF_GAME, NetMsgId.SUB_GF_USER_EFFECTS, "www", tonumber(index), DDZGameCommon:getRoleChairID(),targetChair)
	self:removeFromParent()
end

function DDZPersonInfor:addListener(btn, callback)
	btn:addTouchEventListener(function(sender, event)
		if event == ccui.TouchEventType.ended then
			Common:palyButton()
			if callback then
				callback(sender)
			end
		end
	end)
end

function DDZPersonInfor:onClose()
	self:removeFromParent()
end
return DDZPersonInfor 