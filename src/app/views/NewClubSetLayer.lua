--[[
*名称:NewClubSetLayer
*描述:亲友圈设置
*作者:admin
*创建日期:2018-06-14 15:41:55
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

local NewClubSetLayer       = class("NewClubSetLayer", cc.load("mvc").ViewBase)

function NewClubSetLayer:onConfig()
    self.widget             = {
        {"Image_tittle"},
        {"Button_close", "onClose"},
        {"Image_head"},
        {"TextField_name"},
        {"Button_modify", "onModify"},
        {"Button_liveClub","onLiveClub"},
        --{"Text_playWay"},
        --{"Button_set", "onSet"},
        {"Image_open", "onOpenCustom"},
        {"Image_openLight"},
        {"Image_close", "onCloseCustom"},
        {"Image_closeLight"},
        {"TextField_notice"},
        {"Button_quitClub", "onQuitClub"},

        {"Image_run", "onClubRun"},
        {"Image_runLight"},
        {"Image_stop", "onClubStop"},
        {"Image_stopLight"},

        {"Button_info","onInfo"},
        {"Image_info"},
        {"Button_playway","onPlayWay"},
        {"Image_playway"},
        {"Button_record","onRecord"},
        {"Image_record"},
        {"Panel_info"},
        {"Panel_playway"},
        {"Panel_record"},
        {"Image_item"},
        {"ListView_playway"},
        {"ListView_record"},
        {"Panel_item"},
        {"Image_downFlag"},
    }
    self.clubData = {}          --亲友圈大厅数据
    self.isRecordOver = false   --记录请求是否结束
    self.curRecordEndTime = 0   --记录上次请求结束时间
    self.isUseSave = false      --是否按保存修改
end

function NewClubSetLayer:onEnter()
    EventMgr:registListener(EventType.RET_REMOVE_CLUB,self,self.RET_REMOVE_CLUB)
    EventMgr:registListener(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,self,self.EVENT_TYPE_SETTINGS_CLUB_PARAMETER)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:registListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
    EventMgr:registListener(EventType.RET_GET_CLUB_OPERATE_RECORD,self,self.RET_GET_CLUB_OPERATE_RECORD)
    EventMgr:registListener(EventType.RET_GET_CLUB_OPERATE_RECORD_FINISH,self,self.RET_GET_CLUB_OPERATE_RECORD_FINISH)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_PLAY,self,self.RET_SETTINGS_CLUB_PLAY)
end

function NewClubSetLayer:onExit()
    EventMgr:unregistListener(EventType.RET_REMOVE_CLUB,self,self.RET_REMOVE_CLUB)
    EventMgr:unregistListener(EventType.EVENT_TYPE_SETTINGS_CLUB_PARAMETER,self,self.EVENT_TYPE_SETTINGS_CLUB_PARAMETER)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:unregistListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_OPERATE_RECORD,self,self.RET_GET_CLUB_OPERATE_RECORD)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_OPERATE_RECORD_FINISH,self,self.RET_GET_CLUB_OPERATE_RECORD_FINISH)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_PLAY,self,self.RET_SETTINGS_CLUB_PLAY)
    self.Panel_item:release()
end

function NewClubSetLayer:onCreate(param)
    self.Panel_item:retain()
    self.ListView_record:removeAllItems()
    self:initUI(param)
    self.ListView_playway:addScrollViewEventListener(handler(self, self.listViewEventListen))
end

function NewClubSetLayer:listViewEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        self.Image_downFlag:setVisible(false)
    else
        self.Image_downFlag:setVisible(true)
    end
end

function NewClubSetLayer:onClose()
    self:removeFromParent()
end

function NewClubSetLayer:onModify()
    self.isUseSave = false
    local isCustomRoom = self.Image_openLight:isVisible()
    local bIsDisable = self.Image_stopLight:isVisible()
    
    local nickName = self.TextField_name:getString()
    if nickName ~= "" and nickName ~= self.clubData.szClubName then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsdod",
                3,self.clubData.dwClubID,32,nickName,isCustomRoom,256,"",0,bIsDisable,0)
        self.isUseSave = true
    end

    if self.clubData.bHaveCustomizeRoom ~= isCustomRoom then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsdod",
                4,self.clubData.dwClubID,32,nickName,isCustomRoom,256,"",0,bIsDisable,0)
        self.isUseSave = true
    end

    if self.clubData.bIsDisable ~= bIsDisable then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsdod",
                6,self.clubData.dwClubID,32,nickName,isCustomRoom,256,"",0,bIsDisable,0)
        self.isUseSave = true
    end
    
    local noticeStr = self.TextField_notice:getString()
    if noticeStr ~= self.clubData.szAnnouncement then
        NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB3,"bdnsonsdod",
                5,self.clubData.dwClubID,32,nickName,isCustomRoom,256,noticeStr,0,bIsDisable,0)
        self.isUseSave = true
    end

    if not self.isUseSave then
        require("common.MsgBoxLayer"):create(0,nil,"设置信息没有变化")
    end
end

function NewClubSetLayer:onOpenCustom()
    if not self.Image_openLight:isVisible() then
        self.Image_openLight:setVisible(true)
        self.Image_closeLight:setVisible(false)
    end
end

function NewClubSetLayer:onCloseCustom()
    if not self.Image_closeLight:isVisible() then
        self.Image_openLight:setVisible(false)
        self.Image_closeLight:setVisible(true)
    end
end

function NewClubSetLayer:onClubRun()
    if not self.Image_runLight:isVisible() then
        self.Image_runLight:setVisible(true)
        self.Image_stopLight:setVisible(false)
    end
end

function NewClubSetLayer:onClubStop()
    if not self.Image_stopLight:isVisible() then
        self.Image_runLight:setVisible(false)
        self.Image_stopLight:setVisible(true)
    end
end

function NewClubSetLayer:onQuitClub()
    require("common.MsgBoxLayer"):create(1,nil,"您确定要解散亲友圈？",function() 
        UserData.Guild:removeClub(self.clubData.dwClubID)
    end)
end

function NewClubSetLayer:onLiveClub()
    if self.clubData.dwUserID ~= UserData.User.userID then
        require("common.MsgBoxLayer"):create(1,nil,"您确定要退出亲友圈？",function() 
            UserData.Guild:quitClub(self.clubData.dwClubID)
        end)
    else
        require("common.MsgBoxLayer"):create(0,nil,"群主不能退出亲友圈")
    end
end

function NewClubSetLayer:onInfo()
    self:switchPage(1)
end

function NewClubSetLayer:onPlayWay()
    self:switchPage(2)
end

function NewClubSetLayer:onRecord()
    self:switchPage(3)
end

------------------------------------------------------------------------
--                            more page req                           --
------------------------------------------------------------------------
function NewClubSetLayer:recordEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.isRecordOver == true then
            self.isRecordOver = false
            UserData.Guild:getClubCotrolRecord(self.clubData.dwClubID, self.curRecordEndTime)
        end
    end
end

function NewClubSetLayer:RET_GET_CLUB_OPERATE_RECORD_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isEnd == false then
        self.isRecordOver = true
    else
        self.isRecordOver = false
    end
end

function NewClubSetLayer:RET_GET_CLUB_OPERATE_RECORD(event)
    local data = event._usedata
    if type(data) ~= 'table' then
        printError('NewClubSetLayer:RET_GET_CLUB_OPERATE_RECORD data error')
        return
    end
    Log.d(data)
    local des = self:getRecordDes(data)
    if des ~= '' then
        local item = self.Panel_item:clone()
        self.ListView_record:pushBackCustomItem(item)
        local Text_recordDes = self:seekWidgetByNameEx(item, "Text_recordDes")
        Text_recordDes:setColor(cc.c3b(120, 6, 6))
        local timeStr = os.date('%m月%d日%H:%M', data.dwTime)
        Text_recordDes:setString(timeStr .. des)
        self.ListView_record:refreshView()
    end
    self.curRecordEndTime = data.dwTime
end

function NewClubSetLayer:getRecordDes(data)
    local des = ""
    if self.clubData.dwUserID == data.dwUserID or self:isAdmin(data.dwUserID) then
        des = '管理员'
    else
        des = '玩家'
    end
    des = des .. '(' .. data.szNickName .. ')【ID:' .. data.dwUserID .. '】'

    if data.cbType == 0 then
        des = des .. string.format('设置【ID:%s】成管理员', data.szParameter)
    elseif data.cbType == 1 then
        des = des .. string.format('取消【ID:%s】的管理员', data.szParameter)
    elseif data.cbType == 2 then
        local wKindID = tonumber(data.szParameter)
        des = des .. '修改了玩法：' .. StaticData.Games[wKindID].name
    elseif data.cbType == 3 then
        des = des .. '修改亲友圈昵称为：' .. data.szParameter
    elseif data.cbType == 4 then
        if data.szParameter == "1" then
            des = des .. '开启了自定义房'
        else
            des = des .. '关闭了自定义房'
        end
    elseif data.cbType == 5 then
        des = des .. '修改了公告'
    
    elseif data.cbType == 20 then
        local wKindID = tonumber(data.szParameter)
        des = des .. '添加了玩法：' .. StaticData.Games[wKindID].name
    elseif data.cbType == 21 then
        local wKindID = tonumber(data.szParameter)
        des = des .. '删除了玩法：' .. StaticData.Games[wKindID].name
    elseif data.cbType == 22 then
        local wKindID = tonumber(data.szParameter)
        des = des .. '修改玩法为：' .. StaticData.Games[wKindID].name
    
    elseif data.cbType == 100 then
        des = des .. '创建了亲友圈：' .. data.szParameter
    elseif data.cbType == 101 then
        des = des .. '退出了亲友圈'
    elseif data.cbType == 102 then
        des = des .. string.format('解散了【%s】房间', data.szParameter)
    elseif data.cbType == 103 then
        des = des .. string.format('导入成员【ID:%s】加入亲友圈', data.szParameter)
    elseif data.cbType == 104 then
        des = des .. string.format('踢出成员【ID:%s】', data.szParameter)
    elseif data.cbType == 105 then
        des = des .. string.format('同意成员【ID:%s】加入亲友圈', data.szParameter)
    elseif data.cbType == 106 then
        des = des .. string.format('拒绝成员【ID:%s】加入亲友圈', data.szParameter)
    
    elseif data.cbType == 30 then
        des = des .. '禁止了【ID:' .. data.szParameter .. '】比赛'
    elseif data.cbType == 31 then
        des = des .. '恢复了【ID:' .. data.szParameter .. '】比赛'
    elseif data.cbType == 32 then
        local splitArr = Common:stringSplit(data.szParameter, "|")
        des = des .. '修改【' .. splitArr[1] .. '】的备注为:' .. splitArr[2]
    elseif data.cbType == 33 then
        des = des .. '设置【ID:' .. data.szParameter .. '】为合伙人'
    elseif data.cbType == 34 then
        des = des .. '取消【ID:' .. data.szParameter .. '】合伙人'
    elseif data.cbType == 35 then
        des = des .. '关联【' .. data.szParameter .. '】合伙人'
    elseif data.cbType == 36 then
        local splitArr = Common:stringSplit(data.szParameter, "|")
        des = des .. '修改【ID:' .. splitArr[1] .. '】疲劳值为:' .. splitArr[2]
    elseif data.cbType == 37 then
        local splitArr = Common:stringSplit(data.szParameter, "|")
        des = '合伙人' .. '(' .. data.szNickName .. ')【ID:' .. data.dwUserID .. '】'
        des = des .. '修改成员【ID:' .. splitArr[1] .. '】疲劳值:' .. splitArr[2]
    elseif data.cbType == 38 then
        local splitArr = Common:stringSplit(data.szParameter, "|")
        des = des .. '修改【ID:' .. splitArr[1] .. '】疲劳值为:' .. splitArr[2]
    else
        des = ''
    end
    return des
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
--初始化UI
function NewClubSetLayer:initUI(param)
    local data = param[1]
    local page = param[2]
    Log.d(data)
    if type(data) ~= 'table' then
        printError('enter NewClubSetLayer data error')
        return
    end
    self.clubData = data
    self:switchPage(page)
    self.ListView_record:addScrollViewEventListener(handler(self, self.recordEventListen))

    if not (self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID)) then
        self.Button_record:setVisible(false)
    end
end

--切换分页
function NewClubSetLayer:switchPage(page)
    page = page or 1
    if page == 1 then
        self.Panel_info:setVisible(true)
        self.Panel_playway:setVisible(false)
        self.Panel_record:setVisible(false)
        self.Button_info:setBright(false)
        self.Button_playway:setBright(true)
        self.Button_record:setBright(true)
        self:initInfoPage()
    elseif page == 2 then
        self.Panel_info:setVisible(false)
        self.Panel_playway:setVisible(true)
        self.Panel_record:setVisible(false)
        self.Button_info:setBright(true)
        self.Button_playway:setBright(false)
        self.Button_record:setBright(true)
        self:initWayPage()
    else
        self.Panel_info:setVisible(false)
        self.Panel_playway:setVisible(false)
        self.Panel_record:setVisible(true)
        self.Button_info:setBright(true)
        self.Button_playway:setBright(true)
        self.Button_record:setBright(false)
        self.ListView_record:removeAllItems()
        UserData.Guild:getClubCotrolRecord(self.clubData.dwClubID, 0)
    end
end

function NewClubSetLayer:initInfoPage()
    local data = self.clubData
    self.TextField_name:setString(data.szClubName)
    if data.bHaveCustomizeRoom then
        self.Image_openLight:setVisible(true)
        self.Image_closeLight:setVisible(false)
    else
        self.Image_openLight:setVisible(false)
        self.Image_closeLight:setVisible(true)
    end
    if data.szAnnouncement == " " then
        self.TextField_notice:setString("")
    else
        self.TextField_notice:setString(data.szAnnouncement)
    end

    if data.dwUserID == UserData.User.userID then

    elseif self:isAdmin(UserData.User.userID) then
        self.Button_quitClub:setVisible(false)
        self.Button_liveClub:setPositionX(775 * 0.25)
        self.Button_modify:setPositionX(775 * 0.75) 
    else
        self.Button_quitClub:setVisible(false)
        self.Button_modify:setVisible(false)
        self.TextField_name:setTouchEnabled(false)
        self.TextField_name:setColor(cc.c3b(170,170,170))
        self.Image_open:setTouchEnabled(false)
        self.Image_open:setColor(cc.c3b(170,170,170))
        self.Image_close:setTouchEnabled(false)
        self.Image_close:setColor(cc.c3b(170,170,170))
        self.TextField_notice:setTouchEnabled(false)
        self.TextField_notice:setColor(cc.c3b(170,170,170))
        self.Image_run:setTouchEnabled(false)
        self.Image_run:setColor(cc.c3b(170,170,170))
        self.Image_stop:setTouchEnabled(false)
        self.Image_stop:setColor(cc.c3b(170,170,170))
    end
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, self.Image_head, "img")

    if not data.bIsDisable then
        self.Image_runLight:setVisible(true)
        self.Image_stopLight:setVisible(false)
    else
        self.Image_runLight:setVisible(false)
        self.Image_stopLight:setVisible(true)
    end
end

function NewClubSetLayer:initWayPage()
    self.ListView_playway:removeAllItems()
    for i,id in ipairs(self.clubData.dwPlayID) do
        local item = self.Image_item:clone()
        self.ListView_playway:pushBackCustomItem(item)
        local Panel_noway = ccui.Helper:seekWidgetByName(item, 'Panel_noway')
        local Button_addway = ccui.Helper:seekWidgetByName(item, 'Button_addway')
        local Panel_yesway = ccui.Helper:seekWidgetByName(item, 'Panel_yesway')
        local Text_gamewayIdx = ccui.Helper:seekWidgetByName(item, 'Text_gamewayIdx')
        local Text_wayname = ccui.Helper:seekWidgetByName(item, 'Text_wayname')
        local Text_waypeople = ccui.Helper:seekWidgetByName(item, 'Text_waypeople')
        local Text_waynums = ccui.Helper:seekWidgetByName(item, 'Text_waynums')
        local Text_wayLimit = ccui.Helper:seekWidgetByName(item, 'Text_wayLimit')
        local Text_gamemode = ccui.Helper:seekWidgetByName(item, 'Text_gamemode')
        local Text_waytype = ccui.Helper:seekWidgetByName(item, 'Text_waytype')
        local Text_waydes = ccui.Helper:seekWidgetByName(item, 'Text_waydes')
        local Text_addPlayWay = ccui.Helper:seekWidgetByName(item, 'Text_addPlayWay')
        local Button_removeWay = ccui.Helper:seekWidgetByName(item, 'Button_removeWay')
        local Button_modifyWay = ccui.Helper:seekWidgetByName(item, 'Button_modifyWay')

        Text_gamewayIdx:setColor(cc.c3b(255, 0, 0))
        Text_wayname:setColor(cc.c3b(199,107,61))
        Text_waypeople:setColor(cc.c3b(199,107,61))
        Text_waynums:setColor(cc.c3b(199,107,61))
        Text_wayLimit:setColor(cc.c3b(199,107,61))
        Text_waytype:setColor(cc.c3b(199,107,61))
        Text_gamemode:setColor(cc.c3b(199,107,61))
        Text_waydes:setColor(cc.c3b(85,42,42))
        Text_addPlayWay:setColor(cc.c3b(120,6,6))

        Text_gamewayIdx:setString('玩法'.. i)
        
        local kindid = self.clubData.wKindID[i]
        local gameinfo = StaticData.Games[kindid]
        if id ~= 0 and gameinfo then
            Panel_noway:setVisible(false)
            Panel_yesway:setVisible(true)
            
            if self.clubData.szParameterName[i] ~= "" and self.clubData.szParameterName[i] ~= " " then
                Text_wayname:setString(self.clubData.szParameterName[i])
            else
                Text_wayname:setString(gameinfo.name)
            end

            local parameter = self.clubData.tableParameter[i]
            Text_waypeople:setString(parameter.bPlayerCount .. '人')
            local jushu = self.clubData.wGameCount[i]
            Text_waynums:setString(jushu .. '局')
            
            Text_waytype:setVisible(true)
            if self.clubData.isTableCharge[i] then
                Text_wayLimit:setVisible(true)
                local des = string.format('门槛:%d 倍率:%d', self.clubData.lTableLimit[i], self.clubData.wFatigueCell[i])
                Text_wayLimit:setString(des)
            else
                Text_wayLimit:setVisible(false)
            end

            local cbMode = self.clubData.cbMode[i]
            if cbMode == 1 then
                Text_gamemode:setString('疲劳值模式')
            elseif cbMode == 2 then
                Text_gamemode:setString('元宝模式')
            else
                Text_gamemode:setString('圈主模式')
            end

            local cbPayMode = self.clubData.cbPayMode[i]
            if cbPayMode == 1 then
                local des = string.format('大赢家支付%s',self:getLimitDes(self.clubData.dwPayLimit[i], self.clubData.dwPayCount[i]))
                Text_waytype:setString(des)
            elseif cbPayMode == 2 then
                local des = string.format('赢家支付%s',self:getLimitDes(self.clubData.dwPayLimit[i], self.clubData.dwPayCount[i]))
                Text_waytype:setString(des)
            elseif cbPayMode == 3 then
                local des = string.format('AA支付:%d', self.clubData.dwPayCount[i][1])
                Text_waytype:setString(des)
            else
                local des = string.format('免费')
                Text_waytype:setString(des)
            end
            
            local desc = require("common.GameDesc"):getGameDesc(self.clubData.wKindID[i], self.clubData.tableParameter[i])
            Text_waydes:setString(desc)
        else
            Panel_noway:setVisible(true)
            Panel_yesway:setVisible(false)
        end

        if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
            Button_removeWay:setVisible(true)
            Button_modifyWay:setVisible(true)
        else
            Button_removeWay:setVisible(false)
            Button_modifyWay:setVisible(false)
        end

        Button_addway:setPressedActionEnabled(true)
        Button_addway:addClickEventListener(function(sender)
            require("common.Common"):playEffect("common/buttonplay.mp3")
            if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
                local roomNode = require("app.MyApp"):create(self.clubData.wKindID[i],1):createView("RoomCreateLayer")
                self:addChild(roomNode)
                roomNode.data = {playid = id, settype = 1, idx = i}
                roomNode:setName('RoomCreateLayer')
            else
                require("common.MsgBoxLayer"):create(0,nil,"请联系管理员添加玩法")
            end
        end)
        Button_removeWay:setPressedActionEnabled(true)
        Button_removeWay:addClickEventListener(function(sender)
            require("common.Common"):playEffect("common/buttonplay.mp3")
            local kindid = self.clubData.wKindID[i]
            NetMgr:getLogicInstance():sendMsgToSvr(NetMsgId.MDM_CL_CLUB,NetMsgId.REQ_SETTINGS_CLUB_PLAY,"bddw",
                2,self.clubData.dwClubID,id,kindid)
        end)
        Button_modifyWay:setPressedActionEnabled(true)
        Button_modifyWay:addClickEventListener(function(sender)
            require("common.Common"):playEffect("common/buttonplay.mp3")
            local roomNode = require("app.MyApp"):create(self.clubData.wKindID[i],1):createView("RoomCreateLayer")
            self:addChild(roomNode)
            roomNode.data = {playid = id, settype = 3, idx = i}
            roomNode:setName('RoomCreateLayer')
        end)
    end
end

--是否是管理员
function NewClubSetLayer:isAdmin(userid, adminData)
    adminData = adminData or self.clubData.dwAdministratorID
    for i,v in ipairs(adminData or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

function NewClubSetLayer:megerClubData(data)
    if type(data) ~= 'table' then
        return
    end
    self.clubData = self.clubData or {}
    for k,v in pairs(data) do
        self.clubData[k] = v
    end
end

function NewClubSetLayer:getLimitDes(limitArr, payCountArr)
    local des = ""
    for i,v in ipairs(limitArr) do
        if i == 1 then
            des = string.format('>%d:%d', v, payCountArr[i])
        else
            if v > 0 then
                des = des .. string.format(' >%d:%d', v, payCountArr[i])
            end
        end
    end
    return des
end

------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
--亲友圈解散
function NewClubSetLayer:RET_REMOVE_CLUB(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"解散亲友圈失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"解散亲友圈成功!")
    require("common.SceneMgr"):switchOperation()
    cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
end

--退出亲友圈
function NewClubSetLayer:RET_QUIT_CLUB(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈成功!")
    require("common.SceneMgr"):switchOperation()
    cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
end

--设置玩法消息回调
function NewClubSetLayer:EVENT_TYPE_SETTINGS_CLUB_PARAMETER(event)
    local data = event._usedata
    Log.d(data)
    local roomNode = self:getChildByName('RoomCreateLayer')
    if roomNode then
        local isModifyPlayName = self.clubData.wKindID[roomNode.data.idx] ~= data.wKindID
        local cloneData = {}
        cloneData = self:cloneSetData(cloneData, self.clubData)
        cloneData = self:cloneSetData(cloneData, data)
        cloneData = self:cloneSetData(cloneData, roomNode.data)
        local setNode = require("app.MyApp"):create(cloneData, isModifyPlayName):createView("NewClubPlayWayInfoLayer")
        roomNode:addChild(setNode)
    end
end

function NewClubSetLayer:cloneSetData(src, dir)
    for k,v in pairs(dir) do
        src[k] = v
    end
    return src
end

--亲友圈设置返回
function NewClubSetLayer:RET_SETTINGS_CLUB(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"设置亲友圈失败")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"设置亲友圈成功")
    UserData.Guild:refreshClub(data.dwClubID)
    if self.isUseSave then
        self:removeFromParent()
    end
end

--返回设置亲友圈玩法
function NewClubSetLayer:RET_SETTINGS_CLUB_PLAY(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"设置玩法失败")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"设置玩法成功")
    UserData.Guild:refreshClub(data.dwClubID)
    self:megerClubData(data)
    self:initWayPage()
end

return NewClubSetLayer