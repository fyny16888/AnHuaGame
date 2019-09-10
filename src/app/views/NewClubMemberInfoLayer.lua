--[[
*名称:NewClubMemberInfoLayer
*描述:亲友圈成员信息
*作者:admin
*创建日期:2018-11-14 10:54:27
*修改日期:
]]

local EventMgr          = require("common.EventMgr")
local EventType         = require("common.EventType")
local NetMgr            = require("common.NetMgr")
local NetMsgId          = require("common.NetMsgId")
local StaticData        = require("app.static.StaticData")
local UserData          = require("app.user.UserData")
local Common            = require("common.Common")
local Default           = require("common.Default")
local GameConfig        = require("common.GameConfig")
local Log               = require("common.Log")

local NewClubMemberInfoLayer = class("NewClubMemberInfoLayer", cc.load("mvc").ViewBase)

function NewClubMemberInfoLayer:onConfig()
    self.widget         = {
        {"Button_close", "onClose"},
        {"Image_head"},
        {"Image_state"},
        {"Text_name"},
        {"Text_ID"},
        {"TextField_des"},
        {"Button_setDes","onSetNotes"},
        {"Text_joinTime"},
        {"Text_lastTime"},
        {"Text_position"},
        {"Button_memOut", "onMemOut"},
        {"Button_stopPlay", "onStopPlay"},
        {"Button_setMgr", "onSetMgr"}
    }
end

function NewClubMemberInfoLayer:onEnter()
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
end

function NewClubMemberInfoLayer:onExit()
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
end

function NewClubMemberInfoLayer:onCreate(params)
	Log.d(params[1])
	local data = params[1]
	local clubData = params[2]
	self.data = data
	self.clubData = clubData
	self:initUI()

    local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            local szRemarks = self.TextField_des:getString()
            UserData.Guild:reqSettingsClubMember(2,self.data.dwClubID,self.data.dwUserID,0,szRemarks)
            self.TextField_des:setTouchEnabled(false)
        elseif eventType == ccui.TextFiledEventType.insert_text then
        elseif eventType == ccui.TextFiledEventType.delete_backward then
        end
    end
    self.TextField_des:addEventListener(textFieldEvent)
end

function NewClubMemberInfoLayer:onClose()
    self:removeFromParent()
end

function NewClubMemberInfoLayer:onSetNotes()
    self.TextField_des:setTouchEnabled(true)
	self.TextField_des:attachWithIME()
end

function NewClubMemberInfoLayer:onMemOut()
    if self.data.cbOffice == 3 then
        require("common.MsgBoxLayer"):create(2,self,"请先解除合伙人，再踢出该成员!",function() 
            -- self:removeFromParent()
        end)
    else
        require("common.MsgBoxLayer"):create(1,self,"您确定要踢出该成员？",function() 
            UserData.Guild:removeClubMember(self.data.dwClubID, self.data.dwUserID)
            self:removeFromParent()
        end)
    end
end

function NewClubMemberInfoLayer:onStopPlay()
	self.data.isProhibit = not self.data.isProhibit
	if self.data.isProhibit then
		require("common.MsgBoxLayer"):create(1,self,"您确定将该成员禁赛?",function()
	        UserData.Guild:reqSettingsClubMember(0, self.data.dwClubID, self.data.dwUserID,0,"")
	        self:setStopPlayState(true)
	    end)
	else
		require("common.MsgBoxLayer"):create(1,self,"您确定将该成员恢复比赛?",function()
	        UserData.Guild:reqSettingsClubMember(1, self.data.dwClubID, self.data.dwUserID,0,"")
	        self:setStopPlayState(false)
	    end)
	end
end

function NewClubMemberInfoLayer:onSetMgr()
	require("common.MsgBoxLayer"):create(1,self,"您确定要变更管理员？",function()
        local paramType = 0
        if self:isAdmin(self.data.dwUserID) then
            paramType = 1
        end
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsd",
        paramType,self.clubData.dwClubID,32,"",false,256,"",self.data.dwUserID)
    end)
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
function NewClubMemberInfoLayer:initUI()
	Common:requestUserAvatar(self.data.dwUserID, self.data.szLogoInfo, self.Image_head, "img")
	if self.data.cbOnlineStatus == 1 then
        self.Image_state:loadTexture('kwxclub/qyq_44.png')
    elseif self.data.cbOnlineStatus == 2 then
        self.Image_state:loadTexture('kwxclub/qyq_45.png')
    elseif self.data.cbOnlineStatus == 100 then
        self.Image_state:loadTexture('kwxclub/qyq_46.png')
    else
        self.Image_state:setVisible(false)
    end

    self.Text_name:setString('昵称：' .. self.data.szNickName)
    self.Text_ID:setString('ID：' .. self.data.dwUserID)
    if self.data.szRemarks == "" or self.data.szRemarks == " " then
        self.TextField_des:setString('暂无')
    else
        self.TextField_des:setString(self.data.szRemarks)
    end
    local time = os.date("*t", self.data.dwJoinTime)
    local joinTimeStr = string.format("加入时间:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    self.Text_joinTime:setString(joinTimeStr)
    local time = os.date("*t", self.data.dwLastLoginTime)
    local lastTimeStr = string.format("最近登入:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    self.Text_lastTime:setString(lastTimeStr)

    if self.data.cbOffice == 0 then
        self.Text_position:setString('当前职位：群主')
    elseif self.data.cbOffice == 1 then
        self.Text_position:setString('当前职位：管理员')
    elseif self.data.cbOffice == 3 then
        self.Text_position:setString('当前职位：合伙人')
        self.Button_setMgr:setColor(cc.c3b(170, 170, 170))
        self.Button_setMgr:setTouchEnabled(false)
    else
        self.Text_position:setString('当前职位：普通成员')
    end

    if self.data.dwUserID == UserData.User.userID then
    	--操作自己
    	self.Button_memOut:setVisible(false)
    	self.Button_stopPlay:setVisible(false)
    	self.Button_setMgr:setVisible(false)
	else
		if UserData.User.userID == self.clubData.dwUserID then
			--群主
			self:setAdminState(self:isAdmin(self.data.dwUserID))
		elseif self:isAdmin(UserData.User.userID) then
			--管理员
			self.Button_setMgr:setVisible(false)
		else
			--普通
			self.Button_memOut:setVisible(false)
	    	self.Button_stopPlay:setVisible(false)
	    	self.Button_setMgr:setVisible(false)
	    	self.Button_setDes:setVisible(false)
            self.TextField_des:setTouchEnabled(false)
		end

        if self.data.dwUserID == self.clubData.dwUserID then
            self.Button_memOut:setVisible(false)
            self.Button_stopPlay:setVisible(false)
            self.Button_setMgr:setVisible(false)
            self.Button_setDes:setVisible(false)
            self.TextField_des:setTouchEnabled(false)
        end
    end
    self:setStopPlayState(self.data.isProhibit)
end

function NewClubMemberInfoLayer:isAdmin(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

function NewClubMemberInfoLayer:setAdminState(isAdmin)
	if isAdmin then
        local btnPath = 'kwxclub/club_42.png'
        self.Button_setMgr:loadTextures(btnPath, btnPath, btnPath)
        self.Text_position:setString('当前职位：管理员')
    else
        local btnPath = 'kwxclub/club_16.png'
        self.Button_setMgr:loadTextures(btnPath, btnPath, btnPath)
        if self.data.cbOffice == 3 then
            self.Text_position:setString('当前职位：合伙人')
        else
            self.Text_position:setString('当前职位：普通成员')
        end
    end
end

function NewClubMemberInfoLayer:setStopPlayState(isProhibit)
	if isProhibit then
    	local btnPath = 'kwxclub/club_41.png'
        self.Button_stopPlay:loadTextures(btnPath, btnPath, btnPath)
    else
    	local btnPath = 'kwxclub/club_25.png'
        self.Button_stopPlay:loadTextures(btnPath, btnPath, btnPath)
    end
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
function NewClubMemberInfoLayer:RET_SETTINGS_CLUB(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"管理员已达上限或数据异常!")
        return
    end

    if data.cbSettingsType == 0 then
        --设置管理员
        self:setAdminState(true)
    elseif data.cbSettingsType == 1 then
       	self:setAdminState(false)
    end
    self.clubData.dwAdministratorID = data.dwAdministratorID
end


return NewClubMemberInfoLayer