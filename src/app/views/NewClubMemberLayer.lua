--[[
*名称:NewClubMemberLayer
*描述:亲友圈成员
*作者:admin
*创建日期:2018-06-19 15:59:55
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

local NewClubMemberLayer    = class("NewClubMemberLayer", cc.load("mvc").ViewBase)
local MEMBER_NUM = 7 --成员每次请求数量
function NewClubMemberLayer:onConfig()
    self.widget             = {
        {"Button_close", "onClose"},
        {"Image_memTop", "onMemPage"},
        {"Image_memTopLight"},
        {"Image_partnerTop", "onPartnerPage"},
        {"Image_partnerTopLight"},

        {"Image_memFrame"},
        {"Image_mem", "onSelMem"},
        {"Image_check", "onSelCheck"},
        {"Image_input", "onSelInput"},
        {"Image_fatigue", "onFatigue"},
        {"Panel_mem"},
        {"ListView_mem"},
        {"ListView_find"},
        {"Image_memItem"},
        -- {"Button_exitClub", "onExitClub"},
        {"Panel_check"},
        {"ListView_check"},
        {"Image_checkItem"},
        {"Panel_input"},
        {"Image_noInputTips"},
        {"ListView_input"},
        {"Image_inputItem"},
        {"Image_inputFrame"},
        -- {"Image_findFame"},
        -- {"Text_tips"},
        -- {"Panel_memNumber"},


        {"Image_partnerFrame"},
        {"Image_findFrame"},
        {"Button_memFind", "onMemFind"},
        {"Button_memReturn", "onMemReturn"},
        {"TextField_playerID"},
        {"Text_memNums"},
        {"Button_addMem", "onAddMem"},
        {"Image_addParnter", "onAddParnter"},
        {"Image_myParnter", "onMyParnter"},
        {"Image_myMem"},
        {"Panel_addParnter"},
        {"Panel_myParnter"},
        {"ListView_addParnter"},
        {"Image_parnterItem"},

        {"Image_myParnterItem"},
        {"Image_pushParnterItem"},
        {"Button_changemem"},
        {"ListView_myParnter"},
        {"ListView_findMyParnter"},
        {"ListView_pushParnter"},
        {"Image_topFindMem"},
        {"Text_day_left"},
        {"Text_day_right"},
        {"Image_left", "onImageLeft"},
        {"Image_right", "onImageRight"},
        {"Button_search", "onSearch"},
        {"TextField_parnterID"},
        {"Button_parnterFind", "onParnterFind"},
        {"Text_timeNode"},
        {"ListView_findAddParnter"},
        {"Image_topPartnerMem"},
        {"TextField_partnermem"},
        {"Button_findPartner", "onFindPartnerMem"},
        {"Image_allCount"},
        {"Text_playAllJS"},
        {"Text_dawinSorce"},
        {"TextField_winsorce"},

        {"Panel_newEx"},
        {"Image_newItem"},
        {"Panel_fontItem"},
        {"Text_newPeoples"},
        {"TextField_newInputID"},
        {"Button_newFind", "onNewFind"},
        {"Button_newReturn", "onNewReturn"},
        {"ListView_new"},
        {"ListView_newPush"},
        {"ListView_newFind"},
        {"Image_newFindFrame"},
    }
    self.clubData = {}      --亲友圈大厅数据
    self.searchNum = 0
    self.curPartnerIdx = 1
    self.partnerReqState = 0
    self.beganTime = Common:getStampDay(os.time() ,true)
    self.endTime = Common:getStampDay(os.time() ,false)
    self.pCurPage = 1
    self.pReqState = 0
    self.pCurID = 0

    self.notPartnerMemIdx = 1
    self.notPartnerMemState = 0

    self.curSelPage = 1

    self.newPushPage = 1
    self.newPushState = 0
    self.curNewPushID = 0

end

function NewClubMemberLayer:onEnter(param)
    EventMgr:registListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
    EventMgr:registListener(EventType.RET_CLUB_CHECK_LIST,self,self.RET_CLUB_CHECK_LIST)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER,self,self.RET_GET_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_CLUB_CHECK_RESULT,self,self.RET_CLUB_CHECK_RESULT)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_EX,self,self.RET_GET_CLUB_MEMBER_EX)
    EventMgr:registListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_UPDATE_CLUB_INFO,self,self.RET_UPDATE_CLUB_INFO)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FINISH,self,self.RET_GET_CLUB_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_EX_FINISH	,self,self.RET_GET_CLUB_MEMBER_EX_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_MEMBER ,self,self.RET_FIND_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER ,self,self.RET_GET_CLUB_PARTNER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_FINISH ,self,self.RET_GET_CLUB_PARTNER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_MEMBER ,self,self.RET_GET_CLUB_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_PARTNER_MEMBER_FINISH)
    EventMgr:registListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_FIND_CLUB_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_PARTNER_MEMBER)
    EventMgr:registListener(EventType.RET_GET_CLUB_STATISTICS_ALL ,self,self.RET_GET_CLUB_STATISTICS_ALL)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:registListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
end

function NewClubMemberLayer:onExit()
    EventMgr:unregistListener(EventType.RET_QUIT_CLUB,self,self.RET_QUIT_CLUB)
    EventMgr:unregistListener(EventType.RET_CLUB_CHECK_LIST,self,self.RET_CLUB_CHECK_LIST)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER,self,self.RET_GET_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_REMOVE_CLUB_MEMBER,self,self.RET_REMOVE_CLUB_MEMBER) 
    EventMgr:unregistListener(EventType.RET_CLUB_CHECK_RESULT,self,self.RET_CLUB_CHECK_RESULT)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB,self,self.RET_SETTINGS_CLUB)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_EX,self,self.RET_GET_CLUB_MEMBER_EX)
    EventMgr:unregistListener(EventType.RET_ADD_CLUB_MEMBER,self,self.RET_ADD_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_UPDATE_CLUB_INFO,self,self.RET_UPDATE_CLUB_INFO)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FINISH,self,self.RET_GET_CLUB_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_EX_FINISH,self,self.RET_GET_CLUB_MEMBER_EX_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_MEMBER ,self,self.RET_FIND_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_SETTINGS_CLUB_MEMBER ,self,self.RET_SETTINGS_CLUB_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER ,self,self.RET_GET_CLUB_PARTNER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_FINISH ,self,self.RET_GET_CLUB_PARTNER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_MEMBER ,self,self.RET_GET_CLUB_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_PARTNER_MEMBER_FINISH ,self,self.RET_GET_CLUB_PARTNER_MEMBER_FINISH)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_NOT_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_NOT_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_FIND_CLUB_PARTNER_MEMBER ,self,self.RET_FIND_CLUB_PARTNER_MEMBER)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_STATISTICS_ALL ,self,self.RET_GET_CLUB_STATISTICS_ALL)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD)
    EventMgr:unregistListener(EventType.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH ,self,self.RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH)
    --审核红点操作
    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        local parentNode = self:getParent()
        if parentNode and parentNode.Image_checkRedPoint then
            parentNode.Image_checkRedPoint:setVisible(false)
            UserData.Guild:getClubCheckList(self.clubData.dwClubID)
        end
    end
end

function NewClubMemberLayer:onCreate(param)
    self:initUI(param)
end

function NewClubMemberLayer:onClose()
    self:removeFromParent()
end

function NewClubMemberLayer:onSelMem()
    self:switchPage(1)
end

function NewClubMemberLayer:onSelCheck()
    self:switchPage(2)
end

function NewClubMemberLayer:onSelInput()
    self:switchPage(3)
end

function NewClubMemberLayer:onFatigue()
    self:switchPage(4)
end

function NewClubMemberLayer:onExitClub()
    if self.clubData.dwUserID ~= UserData.User.userID then
        require("common.MsgBoxLayer"):create(1,nil,"您确定要退出亲友圈？",function() 
            UserData.Guild:quitClub(self.clubData.dwClubID)
        end)
    else
        require("common.MsgBoxLayer"):create(0,nil,"群主不能退出亲友圈")
    end
end

function NewClubMemberLayer:onMemFind()
    local playerid = tonumber(self.TextField_playerID:getString())
    if playerid then
        UserData.Guild:findClubMemInfo(self.clubData.dwClubID, playerid)
    end
    self.TextField_playerID:setString("")
end

function NewClubMemberLayer:onMemReturn()
    self.ListView_mem:setVisible(true)
    self.ListView_find:setVisible(false)
    self.Image_findFrame:setVisible(true)
    self.Button_memFind:setVisible(true)
    self.Button_memReturn:setVisible(false)
end

function NewClubMemberLayer:onNewFind()
    local playerid = tonumber(self.TextField_newInputID:getString())
    if playerid then
        UserData.Guild:findClubMemInfo(self.clubData.dwClubID, playerid)
        self.TextField_newInputID:setString("")
    else
        require("common.MsgBoxLayer"):create(0,nil,"玩家ID不合法!")
    end
end

function NewClubMemberLayer:onNewReturn()
    self.ListView_new:setVisible(true)
    self.ListView_newPush:setVisible(false)
    self.ListView_newFind:setVisible(false)
    self.Image_newFindFrame:setVisible(true)
    self.Button_newFind:setVisible(true)
    self.Button_newReturn:setVisible(false)
end

function NewClubMemberLayer:onAddMem()
    local roomNumber = ""
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            require("common.MsgBoxLayer"):create(0,nil,"输入玩家ID不正确")
            return
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
    UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
end

function NewClubMemberLayer:onMemPage()
    local lightBtn = self.Image_memTop:getChildren()[1]
    if not lightBtn:isVisible() then
        lightBtn:setVisible(true)
        self.Image_partnerTop:getChildren()[1]:setVisible(false)
        self.Image_memFrame:setVisible(true)
        self.Image_partnerFrame:setVisible(false)
        -- self.ListView_mem:removeAllItems()
        -- self.memberReqState = 0
        -- self.curClubIndex = 0
        -- self:reqClubMember()
        self:switchPage(1)
    end
end

function NewClubMemberLayer:isHasAdmin()
    return (self.clubData.dwUserID == UserData.User.userID) or self:isAdmin(UserData.User.userID)
end

function NewClubMemberLayer:onPartnerPage()
    if self:isHasAdmin() then
        --群主或管理员
        local lightBtn = self.Image_partnerTop:getChildren()[1]
        if not lightBtn:isVisible() then
            lightBtn:setVisible(true)
            self.Image_memTop:getChildren()[1]:setVisible(false)
            self.Image_memFrame:setVisible(false)
            self.Image_partnerFrame:setVisible(true)
            self.Image_addParnter:setVisible(true)
            self.Image_myParnter:setVisible(true)
            self.Image_myMem:setVisible(false)
            self:switchParnterPage(1)
        end
    else
        --合伙人
        if self.userOffice == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"您还不是合伙人!")
            return
        end

        self.ListView_pushParnter:setVisible(true)
        local lightBtn = self.Image_partnerTop:getChildren()[1]
        if not lightBtn:isVisible() then
            lightBtn:setVisible(true)
            self.Image_memTop:getChildren()[1]:setVisible(false)
            self.Image_memFrame:setVisible(false)
            self.Image_partnerFrame:setVisible(true)
        end

        self.Image_addParnter:setVisible(false)
        self.Image_myParnter:setVisible(false)
        self.Image_myMem:setVisible(true)
        self.Panel_addParnter:setVisible(false)
        self.Panel_myParnter:setVisible(true)
        self.ListView_pushParnter:setVisible(true)
        self.ListView_myParnter:setVisible(false)
        self.Image_allCount:setVisible(false)
        self.Text_dawinSorce:setVisible(false)
        self.ListView_findMyParnter:setVisible(false)
        self.ListView_pushParnter:removeAllItems()
        local path = 'kwxclub/partner_1.png'
        self.Button_changemem:loadTextures(path, path, path)

        -- self.ListView_pushParnter:setVisible(true)
        self.pCurID = UserData.User.userID
        -- self.curPartnerIdx = 1
        -- self:reqClubPartner(self.pCurID)
    end
end

function NewClubMemberLayer:onAddParnter()
    self:switchParnterPage(2)
end

function NewClubMemberLayer:onMyParnter()
    self:switchParnterPage(1)
end

function NewClubMemberLayer:onImageLeft()
    local timeNode = require("app.MyApp"):create(self.beganTime,handler(self,self.leftNodeChange)):createView("TimeNode")
    self.Image_left:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubMemberLayer:onImageRight()
    local timeNode = require("app.MyApp"):create(self.endTime,handler(self,self.rightNodeChange)):createView("TimeNode")
    self.Image_right:addChild(timeNode)
    timeNode:setPosition(80,-90)
end

function NewClubMemberLayer:leftNodeChange( time,stampMin,stampMax )
    self.Text_day_left:setString(time)
    self.beganTime = stampMin

    if self.ListView_myParnter:isVisible() then
        self.ListView_myParnter:removeAllChildren()
    end
    if self.ListView_pushParnter:isVisible() then
        self.ListView_pushParnter:removeAllChildren()
    end
end

function NewClubMemberLayer:rightNodeChange( time,stampMin,stampMax )
    self.Text_day_right:setString(time)
    self.endTime = stampMax

    if self.ListView_myParnter:isVisible() then
        self.ListView_myParnter:removeAllChildren()
    end
    if self.ListView_pushParnter:isVisible() then
        self.ListView_pushParnter:removeAllChildren()
    end
end

function NewClubMemberLayer:onSearch()
    if self.searchNum == 0 then
        self.searchNum = 5
        --查询
        self:research()
        schedule(self.Button_search,function()
            self.searchNum = self.searchNum - 1
            if self.searchNum <= 0 then
                self.searchNum = 0
                self.Button_search:stopAllActions()
            end
        end,1)
    else
        require("common.MsgBoxLayer"):create(0,self,self.searchNum .. "秒之后查询")
    end
end

function NewClubMemberLayer:research()
    if self.ListView_myParnter:isVisible() then
        --合伙人
        self.ListView_myParnter:removeAllItems()
        self.partnerReqState = 0
        self.curPartnerIdx = 1
        self:reqClubPartner()
    else
        --合伙人查询
        -- self.ListView_pushParnter:removeAllItems()
        -- self.pCurPage = 1
        -- self.pReqState = 0
        -- self:reqClubPartnerMember()

        self.curPartnerIdx = 1
        self.ListView_pushParnter:removeAllItems()
        self:reqClubPartner(self.pCurID)
    end
end

function NewClubMemberLayer:onParnterFind()
    if not self.ListView_addParnter:isVisible() then
        return
    end
    local dwUserID = self.TextField_parnterID:getString()
    if dwUserID ~= "" then
        UserData.Guild:findClubNotPartnerMember(self.clubData.dwClubID, tonumber(dwUserID))
    end
end

function NewClubMemberLayer:onFindPartnerMem()
    if not self.ListView_pushParnter:isVisible() then
        return
    end
    local dwUserID = tonumber(self.TextField_partnermem:getString())
    if dwUserID then
        local dwMinWinnerScore = tonumber(self.TextField_winsorce:getString()) or 0
        UserData.Guild:findPartnerMember(self.clubData.dwClubID,self.pCurID,dwUserID,self.beganTime,self.endTime,dwMinWinnerScore)
        print('onFindPartnerMem::',self.clubData.dwClubID,self.pCurID,dwUserID,self.beganTime,self.endTime,dwMinWinnerScore)
    else
        require("common.MsgBoxLayer"):create(0,nil,"输入格式错误！")
    end
end

------------------------------------------------------------------------
--                            game logic                              --
------------------------------------------------------------------------
--初始化UI
function NewClubMemberLayer:initUI(param)
    self.Image_memItem:setVisible(false)
    self.Image_checkItem:setVisible(false)
    self.Image_inputItem:setVisible(false)
    self.Image_check:setVisible(false)
    self.Image_input:setVisible(false)
    -- self.Image_fatigue:setVisible(false)
    self.Image_partnerFrame:setVisible(false)

    local data = param[1]
    if type(data) ~= 'table' then
        printError('enter NewClubMemberLayer data error')
        return
    end
    self.clubData = data
    Log.d(self.clubData)

    --职位
    self.userOffice = param[3]
    printInfo('职位:%d', self.userOffice)

    --时间段初始化、合伙人
    self:updateInputStr()
    self.Image_left:setSwallowTouches(false)
    self.Image_right:setSwallowTouches(false)
    self.Image_topFindMem:setVisible(false)

    if data.dwUserID == UserData.User.userID then
        self.TextField_parnterID:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        local function textFieldEvent(sender, eventType)
            if eventType == ccui.TextFiledEventType.attach_with_ime then
            elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            elseif eventType == ccui.TextFiledEventType.insert_text then
            elseif eventType == ccui.TextFiledEventType.delete_backward then
                self.ListView_addParnter:setVisible(true)
                self.ListView_findAddParnter:setVisible(false)
            end
        end
        self.TextField_parnterID:addEventListener(textFieldEvent)
    end

    self.TextField_winsorce:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    self.TextField_partnermem:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
        elseif eventType == ccui.TextFiledEventType.insert_text then
        elseif eventType == ccui.TextFiledEventType.delete_backward then
            self.ListView_pushParnter:setVisible(true)
            self.ListView_findMyParnter:setVisible(false)
        end
    end
    self.TextField_partnermem:addEventListener(textFieldEvent)
    
    --只有群主和管理员有相关权限
    if data.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        self.Image_check:setVisible(true)
        self.Image_input:setVisible(true)
        -- self.Image_fatigue:setVisible(true)
        self:initNumberArea()

        --导入成员
        self.inputMemberState = 0 --0 请求中 1-请求结束 2--全部请求结束
        self.curInputMemberIndex = 0
        self:reqInputMember()
        self.ListView_input:addScrollViewEventListener(handler(self, self.listViewInputMember)) 
    end

    if param[2] then
        self:switchPage(2)
    else
        self:switchPage()
    end
    
    self.Text_memNums:setString(self.clubData.dwClubPlayerCount)
    self.Text_newPeoples:setString(self.clubData.dwClubPlayerCount)

    self.ListView_mem:addScrollViewEventListener(handler(self, self.listViewClubEventListen))
    self.ListView_myParnter:addScrollViewEventListener(handler(self, self.listViewParnterEventListen))
    self.ListView_addParnter:addScrollViewEventListener(handler(self, self.listViewNotParnterMemberEventListen))
    self.ListView_pushParnter:addScrollViewEventListener(handler(self, self.listViewParnterMemberEventListen))
    self.ListView_new:addScrollViewEventListener(handler(self, self.listViewNewEventListen))
    self.ListView_newPush:addScrollViewEventListener(handler(self, self.listViewPushNewEventListen))

    self.ListView_mem:setBounceEnabled(false)

    if self.clubData.dwUserID ~= UserData.User.userID then
        self.Button_changemem:setVisible(false)
        -- Common:addTouchEventListener(self.Button_changemem,function()
        --     local node = require("app.MyApp"):create(self.clubData):createView("NewClubParnterAddMemLayer")
        --     self:addChild(node)
        -- end)
    end

    --屏蔽普通成员可见
    if self:isHasAdmin() then
        self.Text_memNums:setString(self.clubData.dwClubPlayerCount)
        self.Text_newPeoples:setString(self.clubData.dwClubPlayerCount)
        self.Button_memFind:setColor(cc.c3b(255, 255, 255))
        self.Button_memFind:setTouchEnabled(true)
        self.Button_newFind:setColor(cc.c3b(255, 255, 255))
        self.Button_newFind:setTouchEnabled(true)
    else
        self.Text_memNums:setString('?')
        self.Text_newPeoples:setString('?')
        self.Button_memFind:setColor(cc.c3b(170, 170, 170))
        self.Button_memFind:setTouchEnabled(false)
        self.Button_newFind:setColor(cc.c3b(170, 170, 170))
        self.Button_newFind:setTouchEnabled(false)
    end
end

function NewClubMemberLayer:listViewClubEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.memberReqState == 1 then
            self.memberReqState = 0
            self:reqClubMember()
        end
	end
end

function NewClubMemberLayer:listViewNewEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.memberReqState == 1 then
            self.memberReqState = 0
            self:reqClubMember()
        end
    end
end

function NewClubMemberLayer:listViewPushNewEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.newPushState == 1 then
            self.newPushState = 0
            UserData.Guild:getClubFatigueRecord(self.clubData.dwClubID,self.curNewPushID,self.newPushPage)
        end
    end
end

function NewClubMemberLayer:listViewInputMember(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        print('---------->>>>input',self.curInputMemberIndex)
        if self.inputMemberState == 1 then
            self.inputMemberState = 0
            self:reqInputMember()
        end
	end
end

--请求成员
function NewClubMemberLayer:reqClubMember( ... )
    local startPos = self.curClubIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    UserData.Guild:getClubMember(self.clubData.dwClubID,startPos,endPos)
end

--导入成员
function NewClubMemberLayer:reqInputMember( ... )
    local startPos = self.curInputMemberIndex + 1
    local endPos = startPos + MEMBER_NUM - 1
    print('-------->>start',startPos,endPos)
    UserData.Guild:getClubExMember(self.clubData.dwClubID, UserData.User.userID,startPos,endPos)
end

--请求亲友圈合伙人
function NewClubMemberLayer:reqClubPartner(dwPartnerID)
    local dwMinWinnerScore = tonumber(self.TextField_winsorce:getString()) or 0
    UserData.Statistics:req_statisticsManager(self.clubData.dwClubID, self.beganTime, self.endTime, dwMinWinnerScore)
    printInfo(os.date("%y/%m/%d/%H/%M/%S",self.beganTime))
    printInfo(os.date("%y/%m/%d/%H/%M/%S",self.endTime))
    dwPartnerID = dwPartnerID or 0
    UserData.Guild:getClubPartner(self.clubData.dwClubID, dwPartnerID, self.beganTime, self.endTime, self.curPartnerIdx, dwMinWinnerScore)
    print('reqClubPartner::',self.clubData.dwClubID, dwPartnerID, self.beganTime, self.endTime, self.curPartnerIdx, dwMinWinnerScore)
end

function NewClubMemberLayer:listViewParnterEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.partnerReqState == 1 then
            self.partnerReqState = 0
            self:reqClubPartner()
        end
    end
end

--请求亲友圈合伙人成员
function NewClubMemberLayer:reqClubPartnerMember()
    local dwMinWinnerScore = tonumber(self.TextField_winsorce:getString()) or 0
    UserData.Guild:getClubPartnerMember(self.clubData.dwClubID, self.pCurID,0, self.beganTime, self.endTime, self.pCurPage, dwMinWinnerScore)
    print('reqClubPartnerMember::',self.clubData.dwClubID, self.pCurID,0, self.beganTime, self.endTime, self.pCurPage, dwMinWinnerScore)
end

function NewClubMemberLayer:listViewParnterMemberEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.pReqState == 1 then
            self.pReqState = 0
            self:reqClubPartnerMember()
        end
    end
end

--请求亲友圈非合伙人成员
function NewClubMemberLayer:reqNotPartnerMember()
    local startPos = self.notPartnerMemIdx
    local endPos = startPos + MEMBER_NUM - 1
    UserData.Guild:getClubNotPartnerMember(self.clubData.dwClubID, startPos, endPos)
end

function NewClubMemberLayer:listViewNotParnterMemberEventListen(sender, evenType)
    if evenType == ccui.ScrollviewEventType.scrollToBottom then
        if self.notPartnerMemState == 1 then
            self.notPartnerMemState = 0
            self:reqNotPartnerMember()
        end
    end
end


-----------------------------------
--切换UI
function NewClubMemberLayer:switchPage(idx)
    idx = idx or 1
    self.curSelPage = idx
    if idx == 1 then
        self.Panel_mem:setVisible(true)
        self.Panel_check:setVisible(false)
        self.Panel_input:setVisible(false)
        self.Panel_newEx:setVisible(false)
        self.Image_mem:getChildren()[1]:setVisible(true)
        self.Image_check:getChildren()[1]:setVisible(false)
        self.Image_input:getChildren()[1]:setVisible(false)
        self.Image_fatigue:getChildren()[1]:setVisible(false)
        self.ListView_mem:removeAllItems()
        self.memberReqState = 0 -- 0 请求中 1-请求结束 2--全部请求结束
        self.curClubIndex = 0

        if self:isHasAdmin() then
            self:reqClubMember()
        else
            UserData.Guild:findClubMemInfo(self.clubData.dwClubID, UserData.User.userID)
        end
        
    elseif idx == 2 then
        self.Panel_mem:setVisible(false)
        self.Panel_check:setVisible(true)
        self.Panel_input:setVisible(false)
        self.Panel_newEx:setVisible(false)
        self.Image_mem:getChildren()[1]:setVisible(false)
        self.Image_check:getChildren()[1]:setVisible(true)
        self.Image_input:getChildren()[1]:setVisible(false)
        self.Image_fatigue:getChildren()[1]:setVisible(false)
        self.ListView_check:removeAllItems()
        UserData.Guild:getClubCheckList(self.clubData.dwClubID)

    elseif idx == 3 then
        self.Panel_mem:setVisible(false)
        self.Panel_check:setVisible(false)
        self.Panel_input:setVisible(true)
        self.Panel_newEx:setVisible(false)
        self.Image_mem:getChildren()[1]:setVisible(false)
        self.Image_check:getChildren()[1]:setVisible(false)
        self.Image_input:getChildren()[1]:setVisible(true)
        self.Image_fatigue:getChildren()[1]:setVisible(false)

    elseif idx == 4 then
        self.Panel_mem:setVisible(false)
        self.Panel_check:setVisible(false)
        self.Panel_input:setVisible(false)
        self.Panel_newEx:setVisible(true)
        self.Image_mem:getChildren()[1]:setVisible(false)
        self.Image_check:getChildren()[1]:setVisible(false)
        self.Image_input:getChildren()[1]:setVisible(false)
        self.Image_fatigue:getChildren()[1]:setVisible(true)
        self.ListView_new:removeAllItems()
        self.memberReqState = 0 -- 0 请求中 1-请求结束 2--全部请求结束
        self.curClubIndex = 0
        if self:isHasAdmin() then
        self:reqClubMember()
        else
            UserData.Guild:findClubMemInfo(self.clubData.dwClubID, UserData.User.userID)
        end
    end
end

function NewClubMemberLayer:switchParnterPage(idx)
    if idx == 1 then
        self.ListView_myParnter:removeAllItems()
        self.ListView_myParnter:setVisible(true)
        self.Image_allCount:setVisible(true)
        self.Text_dawinSorce:setVisible(true)
        self.ListView_findMyParnter:setVisible(false)
        self.ListView_pushParnter:setVisible(false)
        self.Panel_addParnter:setVisible(false)
        self.Panel_myParnter:setVisible(true)
        self.Image_addParnter:getChildren()[1]:setVisible(false)
        self.Image_myParnter:getChildren()[1]:setVisible(true)
        self.Button_changemem:setVisible(false)
        self.Image_topPartnerMem:setVisible(false)
        self.Text_timeNode:setVisible(true)
        self.Image_topFindMem:setVisible(false)
        -- self.partnerReqState = 0
        -- self.curPartnerIdx = 1
        -- self:reqClubPartner()
    else
        self.ListView_addParnter:removeAllItems()
        self.Panel_addParnter:setVisible(true)
        self.Panel_myParnter:setVisible(false)
        self.Image_allCount:setVisible(false)
        self.Text_dawinSorce:setVisible(false)
        self.Image_addParnter:getChildren()[1]:setVisible(true)
        self.Image_myParnter:getChildren()[1]:setVisible(false)
        self.Button_changemem:setVisible(false)
        self.Image_topPartnerMem:setVisible(false)
        self.Text_timeNode:setVisible(false)
        self.Image_topFindMem:setVisible(true)
        self.notPartnerMemState = 0
        self.notPartnerMemIdx = 1
        self:reqNotPartnerMember()
    end
end

--是否是管理员
function NewClubMemberLayer:isAdmin(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            return true
        end
    end
    return false
end

--移除管理员信息
function NewClubMemberLayer:removeAdminInfo(userid)
    for i,v in ipairs(self.clubData.dwAdministratorID or {}) do
        if v == userid then
            self.clubData.dwAdministratorID[i] = 0
            break
        end
    end
end

--刷新疲劳值
function NewClubMemberLayer:refreshNewList(data, listView)
    if type(data) ~= 'table' then
        printError('NewClubMemberLayer:refreshNewList data error')
        return
    end

    listView = listView or self.ListView_new

    local item = self.Image_newItem:clone()
    item:setVisible(true)
    if data.dwUserID == UserData.User.userID then
        listView:insertCustomItem(item, 0)
    else
        listView:pushBackCustomItem(item)
    end
    listView:refreshView()
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_desTitle = self:seekWidgetByNameEx(item, "Text_desTitle")
    local TextField_des = self:seekWidgetByNameEx(item, "TextField_des")
    local Button_modifyDes = self:seekWidgetByNameEx(item, "Button_modifyDes")
    local Button_newPush = self:seekWidgetByNameEx(item, "Button_newPush")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    TextField_des:setColor(cc.c3b(165, 61, 9))
    Text_desTitle:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)

    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        Text_playerid:setString('ID：' .. data.dwUserID)
        Text_playerid:setVisible(true)
    else
        Text_playerid:setVisible(false)
    end

    item:setName('fatigue_' .. data.dwUserID)
    Text_desTitle:setString('疲劳值:')
    TextField_des:setString(data.lFatigueValue)

    local function textFieldEvent(sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            --设置疲劳值
            local lFatigue = tonumber(TextField_des:getString())
            if Common:isInterNumber(lFatigue) then
                UserData.Guild:reqSettingsClubMember(6, data.dwClubID, data.dwUserID,0,"",lFatigue)
            else
                require("common.MsgBoxLayer"):create(0,nil,"设置疲劳值错误!")
            end
            TextField_des:setTouchEnabled(false)
        elseif eventType == ccui.TextFiledEventType.insert_text then
        elseif eventType == ccui.TextFiledEventType.delete_backward then
        end
    end
    TextField_des:addEventListener(textFieldEvent)

    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then 
        Common:addTouchEventListener(Button_modifyDes,function()
            TextField_des:setTouchEnabled(true)
            TextField_des:attachWithIME()
        end)
    else
        Button_modifyDes:setVisible(false)
    end
    TextField_des:setTouchEnabled(false)

    Common:addTouchEventListener(Button_newPush,function() 
        self.ListView_new:setVisible(false)
        self.ListView_newPush:setVisible(true)
        self.ListView_newFind:setVisible(false)
        self.Image_newFindFrame:setVisible(false)
        self.Button_newFind:setVisible(false)
        self.Button_newReturn:setVisible(false)
        self:loadFatiguePage(item, data)
    end)
    
end

--加载疲劳值下拉页
function NewClubMemberLayer:loadFatiguePage(item, data)
    self.ListView_newPush:removeAllItems()
    local item = item:clone()
    self.ListView_newPush:pushBackCustomItem(item)
    local Button_modifyDes = self:seekWidgetByNameEx(item, "Button_modifyDes")
    local Button_newPush = self:seekWidgetByNameEx(item, "Button_newPush")
    Button_modifyDes:setVisible(false)
    local path = 'kwxclub/partner_5.png'
    Button_newPush:loadTextures(path, path, path)
    Common:addTouchEventListener(Button_newPush,function() 
        self.ListView_new:setVisible(true)
        self.ListView_newPush:setVisible(false)
        self.ListView_newFind:setVisible(false)
        self.Image_newFindFrame:setVisible(true)
        self.Button_newFind:setVisible(true)
        self.Button_newReturn:setVisible(false)
    end)

    --请求疲劳值记录
    self.curNewPushID = data.dwUserID
    UserData.Guild:getClubFatigueRecord(data.dwClubID,data.dwUserID,1)
end

--刷新成员列表
function NewClubMemberLayer:refreshMemList(data)
    if type(data) ~= 'table' then
        printError('NewClubMemberLayer:refreshMemList data error')
        return
    end

    local item = self.Image_memItem:clone()
    item:setVisible(true)
    self.ListView_mem:pushBackCustomItem(item)
    self.ListView_mem:refreshView()
    item:setName('member_' .. data.dwUserID)
    self:setMemberBaseInfo(item, data)
    self:setMemberMgrFlag(item, data)
    self:setMemberMgrControl(item, data)
end

--设置成员基本信息
function NewClubMemberLayer:setMemberBaseInfo(item, data)
    if not (item and data) then
        return
    end
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_notedes = self:seekWidgetByNameEx(item, "Text_notedes")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_partner = self:seekWidgetByNameEx(item, "Text_partner")
    local Text_joinTime = self:seekWidgetByNameEx(item, "Text_joinTime")
    local Text_lastTime = self:seekWidgetByNameEx(item, "Text_lastTime")
    local Text_stopPlayer = self:seekWidgetByNameEx(item, "Text_stopPlayer")
    Text_stopPlayer:setColor(cc.c3b(255, 0, 0))
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_notedes:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_partner:setColor(cc.c3b(165, 61, 9))
    Text_joinTime:setColor(cc.c3b(165, 61, 9))
    Text_lastTime:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    if data.szRemarks == "" or data.szRemarks == " " then
        Text_notedes:setString('备注：暂无')

        if data.dwPartnerID ~= 0 then
            Text_partner:setVisible(true)
            Text_partner:setString(string.format('合伙人:%s(%d)', data.szPartnerNickName, data.dwPartnerID))
        else
            Text_playerid:setVisible(false)
            Text_partner:setVisible(false)
        end
    else
        Text_notedes:setString('备注：' .. data.szRemarks)
    end

    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        Text_playerid:setString('ID：' .. data.dwUserID)
        Text_playerid:setVisible(true)
    else
        Text_playerid:setVisible(false)
    end

    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("加入时间:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_joinTime:setString(joinTimeStr)
    local time = os.date("*t", data.dwLastLoginTime)
    local lastTimeStr = string.format("最近登入:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_lastTime:setString(lastTimeStr)

    if data.isProhibit then
        Text_stopPlayer:setVisible(true)
    else
        Text_stopPlayer:setVisible(false)
    end
end

--设置成员不同权限标识
function NewClubMemberLayer:setMemberMgrFlag(item, data)
    if not (item and data) then
        return
    end
    local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
    if data.dwUserID == self.clubData.dwUserID then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m22.png')
    elseif self:isAdmin(data.dwUserID) then
        Image_memFlag:setVisible(true)
        Image_memFlag:loadTexture('kwxclub/newclub_m21.png')
    else
        Image_memFlag:setVisible(false)
    end

    local Image_memState = self:seekWidgetByNameEx(item, "Image_memState")
    if data.cbOnlineStatus == 1 then
        Image_memState:loadTexture('kwxclub/qyq_44.png')
    elseif data.cbOnlineStatus == 2 or data.cbOnlineStatus == 0 then
        Image_memState:loadTexture('kwxclub/qyq_45.png')
    elseif data.cbOnlineStatus == 100 then
        Image_memState:loadTexture('kwxclub/qyq_46.png')
    else
        Image_memState:setVisible(false)
    end
end

--设置成员不同权限操作
function NewClubMemberLayer:setMemberMgrControl(item, data)
    local Button_memCotrol = self:seekWidgetByNameEx(item, "Button_memCotrol")
    if self.clubData.dwUserID == UserData.User.userID or self:isAdmin(UserData.User.userID) then
        local callback = function()
            local node = require("app.MyApp"):create(data, self.clubData):createView("NewClubMemberInfoLayer")
            self:addChild(node)
        end
        Common:addTouchEventListener(Button_memCotrol,callback)
        Button_memCotrol:setVisible(true)
    else
        Button_memCotrol:setVisible(false)
    end
end

--刷新审核列表
function NewClubMemberLayer:refreshCheckList(data)
    if type(data) ~= 'table' then
        return
    end

    local item = self.Image_checkItem:clone()
    item:setVisible(true)
    self.ListView_check:pushBackCustomItem(item)
    item:setName('check_' .. data.dwUserID)
    local Image_head = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name = self:seekWidgetByNameEx(item, "Text_name")
    local Text_playerid = self:seekWidgetByNameEx(item, "Text_playerid")
    local Text_tille = self:seekWidgetByNameEx(item, "Text_tille")
    local Text_applytime = self:seekWidgetByNameEx(item, "Text_applytime")
    local Button_yes = self:seekWidgetByNameEx(item, "Button_yes")
    local Button_no = self:seekWidgetByNameEx(item, "Button_no")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_applytime:setColor(cc.c3b(165, 61, 9))
    Text_tille:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_applytime:setString(joinTimeStr)

    if self.clubData.dwUserID ~= UserData.User.userID and not self:isAdmin(UserData.User.userID) then
        Button_yes:setVisible(false)
        Button_no:setVisible(false)
    else
        Button_yes:setVisible(true)
        Button_no:setVisible(true)
        Button_yes:setPressedActionEnabled(true)
        Button_yes:addClickEventListener(function(sender)
            UserData.Guild:checkClubResult(data.dwClubID,data.dwUserID,true)
        end)

        Button_no:setPressedActionEnabled(true)
        Button_no:addClickEventListener(function(sender)
            UserData.Guild:checkClubResult(data.dwClubID,data.dwUserID,false)
        end)
    end
end

--刷新导入列表
function NewClubMemberLayer:refreshInputList(data)
    if type(data) ~= 'table' then
        return
    end

    local item = self.Image_inputItem:clone()
    item:setVisible(true)
    self.ListView_input:pushBackCustomItem(item)
    self.ListView_input:refreshView()
    item:setName('input_' .. data.dwUserID)
    local Image_head     = self:seekWidgetByNameEx(item, "Image_head")
    local Text_name      = self:seekWidgetByNameEx(item, "Text_name")
    local Text_clubID    = self:seekWidgetByNameEx(item, "Text_clubID")
    local Button_input   = self:seekWidgetByNameEx(item, "Button_input")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_clubID:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_clubID:setString('ID:' .. data.dwUserID)

    Button_input:setPressedActionEnabled(true)
    Button_input:addClickEventListener(function(sender)
        UserData.Guild:addClubMember(self.clubData.dwClubID, data.dwUserID, UserData.User.userID)
    end)
end

--添加一个查找玩家
function NewClubMemberLayer:addOnceFindMem(data)
    if type(data) ~= 'table' then
        printError('NewClubMemberLayer:addOnceFindMem data error')
        return
    end
    self.ListView_find:removeAllChildren()
    local item = self.Image_memItem:clone()
    item:setVisible(true)
    self.ListView_find:pushBackCustomItem(item)
    self.ListView_find:refreshView()
    self:setMemberBaseInfo(item, data)
    self:setMemberMgrFlag(item, data)
    self:setMemberMgrControl(item, data)
end

function NewClubMemberLayer:dateChange(stamp,dayChange)
    local year,month,day = Common:getYMDHMS(stamp)
    local time=os.time({year=year, month=month, day=day})+dayChange*86400 --一天86400秒
    return time
end

function NewClubMemberLayer:updateInputStr()
    local leftTime = self:getFrmatYear(self.beganTime)
    local rightTime = self:getFrmatYear(self.endTime)
    self.Text_day_left:setString(leftTime)
    self.Text_day_right:setString(rightTime)    
end

function NewClubMemberLayer:getFrmatYear( time )
    return  (os.date('%Y',time).."-" .. os.date('%m',time).."-"..os.date('%d',time))
end


------------------------------------------------------------------------
--                            server rvc                              --
------------------------------------------------------------------------
--退出亲友圈返回
function NewClubMemberLayer:RET_QUIT_CLUB(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,nil,"退出亲友圈成功!")
    -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create():createView("NewClubLayer"))
    require("common.SceneMgr"):switchOperation()
    cc.UserDefault:getInstance():setIntegerForKey("UserDefault_NewClubID", 0)
end

--返回亲友圈成员列表
function NewClubMemberLayer:RET_GET_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)

    if self.Panel_mem:isVisible() then
        self:refreshMemList(data)
    elseif self.Panel_newEx:isVisible() then
        self:refreshNewList(data)
    end
end

--返回剔除成员
function NewClubMemberLayer:RET_REMOVE_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,self,"踢出失败!")
        return
    end
    require("common.MsgBoxLayer"):create(0,self,"踢出成功!")
    self:removeAdminInfo(data.dwUserID)
    local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
    if item then
        local index = self.ListView_mem:getIndex(item)
        self.ListView_mem:removeItem(index)
        self.ListView_mem:refreshView()
        local count = self.ListView_mem:getChildrenCount()
        if count == 1 or count == 0 then
            if self.memberReqState == 1 then
                self.memberReqState = 0
                self:reqClubMember()
            end
        end
    end
    -- self:resetMemInputArea()
end

--返回亲友圈审核列表
function NewClubMemberLayer:RET_CLUB_CHECK_LIST(event)
    local data = event._usedata
    self:refreshCheckList(data)
end

--审核同意或拒绝返回
function NewClubMemberLayer:RET_CLUB_CHECK_RESULT(event)
    local data = event._usedata
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"人数已满!")
        else
            require("common.MsgBoxLayer"):create(0,self,"请求失败!")
        end
        return
    end
    if data.isAgree == true then
        require("common.MsgBoxLayer"):create(0,self,"操作成功,请到成员列表查看!")
    else
        require("common.MsgBoxLayer"):create(0,self,"操作成功!")
    end

    local item = self.ListView_check:getChildByName('check_' .. data.dwUserID)
    if item then
        local index = self.ListView_check:getIndex(item)
        self.ListView_check:removeItem(index)
        self.ListView_check:refreshView()
    end
end

--设置、取消管理员返回
function NewClubMemberLayer:RET_SETTINGS_CLUB(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"管理员已达上限或数据异常!")
        return
    end

    if data.cbSettingsType == 0 then
        --设置管理员
        local item = self.ListView_mem:getChildByName('member_' .. data.dwTargetID)
        if item then
            local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
            Image_memFlag:setVisible(true)
            self.clubData.dwAdministratorID = data.dwAdministratorID
        end
    elseif data.cbSettingsType == 1 then
        --取消管理员
        local item = self.ListView_mem:getChildByName('member_' .. data.dwTargetID)
        if item then
            local Image_memFlag = self:seekWidgetByNameEx(item, "Image_memFlag")
            Image_memFlag:setVisible(false)
            self.clubData.dwAdministratorID = data.dwAdministratorID
        end
    end
end

--返回亲友圈以外可以导入的成员
function NewClubMemberLayer:RET_GET_CLUB_MEMBER_EX(event)
    local data = event._usedata
    Log.d(data)
    self:refreshInputList(data)
end

--返回添加亲友圈成员
function NewClubMemberLayer:RET_ADD_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,self,"ID输入错误!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,self,"该成员已在亲友圈内，请勿重复操作!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,self,"玩家ID不合法!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,self,"您没有权限导入！")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,self,"人数已满!")
        else
            require("common.MsgBoxLayer"):create(0,self,"请升级游戏版本!")
        end
        return
    end

    require("common.MsgBoxLayer"):create(0,self,"导入成功!")
    local item = self.ListView_input:getChildByName('input_' .. data.dwUserID)
    if item then
        local index = self.ListView_input:getIndex(item)
        self.ListView_input:removeItem(index)
        self.ListView_input:refreshView()
        local count = self.ListView_input:getChildrenCount()
        if count == 0 then
            if self.inputMemberState == 1 then
                self.inputMemberState = 0
                self:reqInputMember()
            end
        end
    end

    --合伙人添加成员
    if self.Image_partnerFrame:isVisible() then
        local event = {}
        event._usedata = data
        self:RET_GET_CLUB_PARTNER_MEMBER(event)
    end
end


--更新亲友圈信息
function NewClubMemberLayer:RET_UPDATE_CLUB_INFO(event)
    local data = event._usedata
    Log.d(data)
    -- self:initUI({data})
end

--亲友群是否返回完成
function NewClubMemberLayer:RET_GET_CLUB_MEMBER_FINISH( event )
    local data = event._usedata
    if data.isFinish then
        self.memberReqState = 2
    else
        self.memberReqState = 1
    end
    self.curClubIndex = self.curClubIndex + MEMBER_NUM
end

function NewClubMemberLayer:RET_GET_CLUB_MEMBER_EX_FINISH( event )
    local data = event._usedata
    if data.isFinish then
        self.inputMemberState = 2
    else
        self.inputMemberState = 1
    end
    self.curInputMemberIndex = self.curInputMemberIndex + MEMBER_NUM
    print('------------返回dd',self.inputMemberState,self.curInputMemberIndex)
    if self.ListView_input then
        local isShow =  self.ListView_input:getChildrenCount () <= 0
        print('------xxxxxxxxx--',isShow,self.ListView_input:getChildrenCount ())
        self.Image_noInputTips:setVisible(isShow)
    end
end

--返回查找亲友圈结果
function NewClubMemberLayer:RET_FIND_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then 
        require("common.MsgBoxLayer"):create(0,nil,"亲友圈成员ID输入错误!")
        return
    end

    if not self:isHasAdmin() then
        if self.Panel_mem:isVisible() then
            self:refreshMemList(data)
        elseif self.Panel_newEx:isVisible() then
            self:refreshNewList(data)
        end
        return
    end

    if self.curSelPage == 1 then
        self.ListView_mem:setVisible(false)
        self.ListView_find:setVisible(true)
        self.Image_findFrame:setVisible(false)
        self.Button_memFind:setVisible(false)
        self.Button_memReturn:setVisible(true)
        self:addOnceFindMem(data)
    elseif self.curSelPage == 4 then
        self.ListView_new:setVisible(false)
        self.ListView_newPush:setVisible(false)
        self.ListView_newFind:setVisible(true)
        self.Image_newFindFrame:setVisible(false)
        self.Button_newFind:setVisible(false)
        self.Button_newReturn:setVisible(true)
        self.ListView_newFind:removeAllItems()
        self:refreshNewList(data, self.ListView_newFind)
    end
end

--返回修改亲友圈成员
function NewClubMemberLayer:RET_SETTINGS_CLUB_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        if data.lRet == 1 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈不存在!")
        elseif data.lRet == 2 then
            require("common.MsgBoxLayer"):create(0,nil,"亲友圈成员不存在!")
        elseif data.lRet == 3 then
            require("common.MsgBoxLayer"):create(0,nil,"亲有圈合伙人已达人数上限!")
        elseif data.lRet == 4 then
            require("common.MsgBoxLayer"):create(0,nil,"普通成员才可以设置为合伙人!")
        elseif data.lRet == 5 then
            require("common.MsgBoxLayer"):create(0,nil,"您的权限不足!")
        elseif data.lRet == 100 then
            require("common.MsgBoxLayer"):create(0,nil,"对局中不能修改疲劳值")
        else
            require("common.MsgBoxLayer"):create(0,nil,"设置错误!")
        end
        return
    end

    if data.cbSettingsType == 0 then
        --禁赛
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_stopPlayer = self:seekWidgetByNameEx(item, "Text_stopPlayer")
            Text_stopPlayer:setVisible(true)
        end
    elseif data.cbSettingsType == 1 then
        --恢复
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_stopPlayer = self:seekWidgetByNameEx(item, "Text_stopPlayer")
            Text_stopPlayer:setVisible(false)
        end
    elseif data.cbSettingsType == 2 then
        --修改备注
        local item = self.ListView_mem:getChildByName('member_' .. data.dwUserID)
        if item then
            local Text_notedes = self:seekWidgetByNameEx(item, "Text_notedes")
            if data.szRemarks == "" or data.szRemarks == " " then
                Text_notedes:setString('备注：暂无')
            else
                Text_notedes:setString('备注：' .. data.szRemarks)
            end
            self:setMemberMgrControl(item, data)
            require("common.MsgBoxLayer"):create(0,nil,"修改备注成功")
        end
    elseif data.cbSettingsType == 3 then
        --设置合伙人
        local item = self.ListView_addParnter:getChildByName('addpartner' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"添加合伙人成功!")
        end
    elseif data.cbSettingsType == 4 then
        --取消合伙人
        local item = self.ListView_myParnter:getChildByName('myparnter' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"取消合伙人成功!")
        end

        --解绑
        local item = self.ListView_pushParnter:getChildByName('pushParnter' .. data.dwUserID)
        if item then
            item:removeFromParent()
            require("common.MsgBoxLayer"):create(0,nil,"解绑成员成功!")
            local dwPartnerID = data.dwPartnerID
            if dwPartnerID <= 0 then
                dwPartnerID = self.pCurID
            end
            self:refreshParnterItemPeoples(dwPartnerID, -1)
        end
    elseif data.cbSettingsType == 5 then
        --调配成员
        local event = {}
        event._usedata = data
        self:RET_GET_CLUB_PARTNER_MEMBER(event)
        self:refreshParnterItemPeoples(data.dwPartnerID, 1)

    elseif data.cbSettingsType == 6 then
        --疲劳值
        local item = self.ListView_new:getChildByName('fatigue_' .. data.dwUserID)
        if item then
            local TextField_des = self:seekWidgetByNameEx(item, "TextField_des")
            TextField_des:setString(data.lFatigueValue)
            require("common.MsgBoxLayer"):create(0,nil,"设置疲劳值成功")
        end

    elseif data.cbSettingsType == 7 then
        --副卡
        local item = self.ListView_new:getChildByName('aacard_' .. data.dwUserID)
        if item then
            local TextField_des = self:seekWidgetByNameEx(item, "TextField_des")
            TextField_des:setString(data.dwACard)
        end
    end
end

function NewClubMemberLayer:insertOncePartnerMember(data)
    local item = self.Image_myParnterItem:clone()
    self.ListView_pushParnter:pushBackCustomItem(item)
    item:setName('OnceParnter' .. data.dwUserID)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_dyjnum = ccui.Helper:seekWidgetByName(item, "Text_dyjnum")
    local Text_jsnum = ccui.Helper:seekWidgetByName(item, "Text_jsnum")
    local Text_dyj = ccui.Helper:seekWidgetByName(item, "Text_dyj")
    local Text_jushu = ccui.Helper:seekWidgetByName(item, "Text_jushu")
    local Text_playerCountFlag = ccui.Helper:seekWidgetByName(item, "Text_playerCountFlag")
    local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
    local Button_cancel = ccui.Helper:seekWidgetByName(item, "Button_cancel")
    local Button_push = ccui.Helper:seekWidgetByName(item, "Button_push")
    Button_cancel:setVisible(false)
    Button_push:setVisible(self:isHasAdmin())
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_dyjnum:setColor(cc.c3b(165, 61, 9))
    Text_jsnum:setColor(cc.c3b(165, 61, 9))
    Text_playerCountFlag:setColor(cc.c3b(165, 61, 9))
    Text_dyj:setColor(cc.c3b(165, 61, 9))
    Text_jushu:setColor(cc.c3b(165, 61, 9))
    Text_playerCount:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    Text_dyjnum:setString(data.dwWinnerCount)
    Text_jsnum:setString(data.dwGameCount)
    Text_playerCount:setString(data.dwPlayerCount)

    -- Common:addTouchEventListener(Button_cancel,function()
    --     --解除合伙人
    --     require("common.MsgBoxLayer"):create(1,nil,"您确定要解除合伙人？",function() 
    --         UserData.Guild:reqSettingsClubMember(4, data.dwClubID, data.dwUserID,0,"")
    --     end)
    -- end)

    local path = 'kwxclub/partner_5.png'
    Button_push:loadTextures(path, path, path)
    Common:addTouchEventListener(Button_push,function()
        self.Button_changemem:setVisible(false)
        self.Image_topPartnerMem:setVisible(false)
        self.ListView_myParnter:setVisible(true)
        self.Image_allCount:setVisible(true)
        self.Text_dawinSorce:setVisible(true)
        self.ListView_pushParnter:setVisible(false)
    end)
end

--返回亲友圈合伙人
function NewClubMemberLayer:RET_GET_CLUB_PARTNER(event)
    local data = event._usedata
    Log.d(data)
    if data.lRet ~= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"您还不是合伙人!")
        return
    end

    if self.ListView_pushParnter:isVisible() then
        --合伙人成员第一条插入
        if UserData.User.userID ~= self.clubData.dwUserID then
            --合伙人
            local lightBtn = self.Image_partnerTop:getChildren()[1]
            if not lightBtn:isVisible() then
                lightBtn:setVisible(true)
                self.Image_memTop:getChildren()[1]:setVisible(false)
                self.Image_memFrame:setVisible(false)
                self.Image_partnerFrame:setVisible(true)
            end

            self.Image_addParnter:setVisible(false)
            self.Image_myParnter:setVisible(false)
            self.Image_myMem:setVisible(true)
            self.Panel_addParnter:setVisible(false)
            self.Panel_myParnter:setVisible(true)
            self.ListView_pushParnter:setVisible(true)
            self.ListView_myParnter:setVisible(false)
            self.Image_allCount:setVisible(false)
            self.Text_dawinSorce:setVisible(false)
            self.ListView_findMyParnter:setVisible(false)
            self.ListView_pushParnter:removeAllItems()
            local path = 'kwxclub/partner_1.png'
            self.Button_changemem:loadTextures(path, path, path)
        end
        self:insertOncePartnerMember(data)
        self.pCurPage = 1
        self.pReqState = 0
        self:reqClubPartnerMember()
        return
    end

    local item = self.Image_myParnterItem:clone()
    self.ListView_myParnter:pushBackCustomItem(item)
    item:setName('myparnter' .. data.dwUserID)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_dyjnum = ccui.Helper:seekWidgetByName(item, "Text_dyjnum")
    local Text_jsnum = ccui.Helper:seekWidgetByName(item, "Text_jsnum")
    local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
    local Text_dyj = ccui.Helper:seekWidgetByName(item, "Text_dyj")
    local Text_jushu = ccui.Helper:seekWidgetByName(item, "Text_jushu")
    local Text_playerCountFlag = ccui.Helper:seekWidgetByName(item, "Text_playerCountFlag")
    local Button_cancel = ccui.Helper:seekWidgetByName(item, "Button_cancel")
    local Button_push = ccui.Helper:seekWidgetByName(item, "Button_push")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_dyjnum:setColor(cc.c3b(165, 61, 9))
    Text_jsnum:setColor(cc.c3b(165, 61, 9))
    Text_playerCount:setColor(cc.c3b(165, 61, 9))
    Text_dyj:setColor(cc.c3b(165, 61, 9))
    Text_jushu:setColor(cc.c3b(165, 61, 9))
    Text_playerCountFlag:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    Text_dyjnum:setString(data.dwWinnerCount)
    Text_jsnum:setString(data.dwGameCount)
    Text_playerCount:setString(data.dwPlayerCount)

    Common:addTouchEventListener(Button_cancel,function()
        --解除合伙人
        require("common.MsgBoxLayer"):create(1,nil,"您确定要解除合伙人？",function() 
            UserData.Guild:reqSettingsClubMember(4, data.dwClubID, data.dwUserID,0,"")
        end)
    end)

    Common:addTouchEventListener(Button_push,function()
        --展开名下成员
        self.Button_changemem:setVisible(true)
        self.Image_topPartnerMem:setVisible(true)
        self.ListView_myParnter:setVisible(false)
        self.Image_allCount:setVisible(false)
        self.Text_dawinSorce:setVisible(false)
        
        self.ListView_pushParnter:setVisible(true)
        self.ListView_pushParnter:removeAllItems()
        self.pCurID = data.dwUserID
        self.curPartnerIdx = 1
        self:reqClubPartner(self.pCurID)

        --分配成员
        Common:addTouchEventListener(self.Button_changemem,function()
            local node = require("app.MyApp"):create(data):createView("NewClubAllocationLayer")
            self:addChild(node)
        end)
    end)
end

function NewClubMemberLayer:RET_GET_CLUB_PARTNER_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.partnerReqState = 2
    else
        self.partnerReqState = 1
    end
    self.curPartnerIdx = self.curPartnerIdx + 1
end

function NewClubMemberLayer:setNotParnterMemberItem(item,data)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_note = ccui.Helper:seekWidgetByName(item, "Text_note")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_joinTime = ccui.Helper:seekWidgetByName(item, "Text_joinTime")
    local Text_lastTime = ccui.Helper:seekWidgetByName(item, "Text_lastTime")
    local Button_memCotrol = ccui.Helper:seekWidgetByName(item, "Button_memCotrol")
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_note:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_joinTime:setColor(cc.c3b(165, 61, 9))
    Text_lastTime:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    if data.szRemarks == "" or data.szRemarks == " " then
        Text_note:setString('备注:暂无')
    else
        Text_note:setString('备注:' .. data.szRemarks)
    end
    Text_playerid:setString('ID:' .. data.dwUserID)
    local time = os.date("*t", data.dwJoinTime)
    local joinTimeStr = string.format("加入时间:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_joinTime:setString(joinTimeStr)
    local time = os.date("*t", data.dwLastLoginTime)
    local lastTimeStr = string.format("最近登入:%d-%02d-%02d %02d:%02d:%02d",time.year,time.month,time.day,time.hour,time.min,time.sec)
    Text_lastTime:setString(lastTimeStr)

    Common:addTouchEventListener(Button_memCotrol,function()
        --添加合伙人
        require("common.MsgBoxLayer"):create(1,nil,"您确定要添加合伙人？",function() 
            UserData.Guild:reqSettingsClubMember(3, data.dwClubID, data.dwUserID,0,"")
        end)
    end)
end

function NewClubMemberLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    --屏蔽管理员
    if self:isAdmin(data.dwUserID) then
        return
    end

    local item = self.Image_parnterItem:clone()
    self.ListView_addParnter:pushBackCustomItem(item)
    item:setName('addpartner' .. data.dwUserID)
    self:setNotParnterMemberItem(item ,data)
end

function NewClubMemberLayer:RET_GET_CLUB_NOT_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.notPartnerMemState = 2
    else
        self.notPartnerMemState = 1
    end
    self.notPartnerMemIdx = self.notPartnerMemIdx + MEMBER_NUM
end

function NewClubMemberLayer:setPartnerMemberItem(item, data)
    local Image_head = ccui.Helper:seekWidgetByName(item, "Image_head")
    local Text_name = ccui.Helper:seekWidgetByName(item, "Text_name")
    local Text_playerid = ccui.Helper:seekWidgetByName(item, "Text_playerid")
    local Text_jf = ccui.Helper:seekWidgetByName(item, "Text_jf")
    local Text_jfnum = ccui.Helper:seekWidgetByName(item, "Text_jfnum")
    local Text_jushu = ccui.Helper:seekWidgetByName(item, "Text_jushu")
    local Text_jsnum = ccui.Helper:seekWidgetByName(item, "Text_jsnum")
    local Text_dyj = ccui.Helper:seekWidgetByName(item, "Text_dyj")
    local Text_dyjnum = ccui.Helper:seekWidgetByName(item, "Text_dyjnum")
    local Text_alljs = ccui.Helper:seekWidgetByName(item, "Text_alljs")
    local Text_allnum = ccui.Helper:seekWidgetByName(item, "Text_allnum")
    local Button_noBind = ccui.Helper:seekWidgetByName(item, "Button_noBind")
    Text_alljs:setVisible(false)
    Button_noBind:setVisible(self:isHasAdmin() and data.dwUserID ~= data.dwPartnerID)
    Text_name:setColor(cc.c3b(165, 61, 9))
    Text_playerid:setColor(cc.c3b(165, 61, 9))
    Text_jf:setColor(cc.c3b(165, 61, 9))
    Text_jfnum:setColor(cc.c3b(165, 61, 9))
    Text_jushu:setColor(cc.c3b(165, 61, 9))
    Text_jsnum:setColor(cc.c3b(165, 61, 9))
    Text_dyj:setColor(cc.c3b(165, 61, 9))
    Text_dyjnum:setColor(cc.c3b(165, 61, 9))
    Text_alljs:setColor(cc.c3b(165, 61, 9))
    Text_allnum:setColor(cc.c3b(165, 61, 9))
    Common:requestUserAvatar(data.dwUserID, data.szLogoInfo, Image_head, "img")
    Text_name:setString(data.szNickName)
    Text_playerid:setString('ID:' .. data.dwUserID)
    Text_jfnum:setString(data.lScore or 0)
    Text_jsnum:setString(data.dwGameCount or 0)
    Text_dyjnum:setString(data.dwWinnerCount or 0)
    Text_allnum:setString(data.dwCompleteGameCount or 0)

    Common:addTouchEventListener(Button_noBind,function()
        --解绑
        require("common.MsgBoxLayer"):create(1,nil,"您确定要解绑成员？",function() 
            UserData.Guild:reqSettingsClubMember(4, data.dwClubID, data.dwUserID, data.dwPartnerID,"")
        end)
    end)
end

function NewClubMemberLayer:RET_GET_CLUB_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)
    -- if data.lRet ~= 0 then
    --     require("common.MsgBoxLayer"):create(0,nil,"您还不是合伙人!")
    --     return
    -- end

    --合伙人自己
    local item = self.Image_pushParnterItem:clone()
    if data.dwUserID == data.dwPartnerID then
        self.ListView_pushParnter:insertCustomItem(item, 1)
    else
        self.ListView_pushParnter:pushBackCustomItem(item)
    end
    item:setName('pushParnter' .. data.dwUserID)
    self:setPartnerMemberItem(item, data)
end

function NewClubMemberLayer:RET_GET_CLUB_PARTNER_MEMBER_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.pReqState = 2
    else
        self.pReqState = 1
    end
    self.pCurPage = self.pCurPage + 1
end

function NewClubMemberLayer:RET_FIND_CLUB_NOT_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)

    if data.lRet == 0 then
        self.ListView_addParnter:setVisible(false)
        self.ListView_findAddParnter:setVisible(true)
        self.ListView_findAddParnter:removeAllItems()
        local item = self.Image_parnterItem:clone()
        self.ListView_findAddParnter:pushBackCustomItem(item)
        self:setNotParnterMemberItem(item ,data)
    else
        require("common.MsgBoxLayer"):create(0,nil,"玩家ID不存在")
    end
end

function NewClubMemberLayer:RET_FIND_CLUB_PARTNER_MEMBER(event)
    local data = event._usedata
    Log.d(data)

    if data.lRet == 0 then
        self.ListView_pushParnter:setVisible(false)
        self.ListView_findMyParnter:setVisible(true)
        self.ListView_findMyParnter:removeAllItems()
        local item = self.Image_pushParnterItem:clone()
        self.ListView_findMyParnter:pushBackCustomItem(item)
        self:setPartnerMemberItem(item, data)
    else
        require("common.MsgBoxLayer"):create(0,nil,"玩家ID不存在")
    end
end

function NewClubMemberLayer:RET_GET_CLUB_STATISTICS_ALL(event)
    local data = event._usedata
    Log.d(data)
    self.Text_playAllJS:setString(data.dwAllPeopleCount)
end

function NewClubMemberLayer:refreshParnterItemPeoples(dwUserID, num)
    local item = self.ListView_myParnter:getChildByName('myparnter' .. dwUserID)
    if item then
        local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
        local curnum = tonumber(Text_playerCount:getString())
        curnum = curnum + num
        if curnum < 0 then
            curnum = 0
        end
        Text_playerCount:setString(curnum)
    end

    local item = self.ListView_pushParnter:getChildByName('OnceParnter' .. dwUserID)
    if item then
        local Text_playerCount = ccui.Helper:seekWidgetByName(item, "Text_playerCount")
        local curnum = tonumber(Text_playerCount:getString())
        curnum = curnum + num
        if curnum < 0 then
            curnum = 0
        end
        Text_playerCount:setString(curnum)
    end
end

function NewClubMemberLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD(event)
    local data = event._usedata
    Log.d(data)

    if data.cbType == 0 then
        --设置
        local item = self.Panel_fontItem:clone()
        self.ListView_newPush:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local des = string.format(' 管理员设置%d,当前剩余%d.', data.lFatigue, data.lNewFatigue)
        Text_desfont:setString(timeStr .. des)
        self.ListView_newPush:refreshView()
    elseif data.cbType == 1 then
        --房费
        local item = self.Panel_fontItem:clone()
        self.ListView_newPush:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local gameName = ""
        if StaticData.Games[data.wKindID] then
            gameName = '(' .. StaticData.Games[data.wKindID].name .. ')'
        end

        if data.lFatigue >= 0 then
            local des = string.format(' %s游戏消耗+%d,当前剩余%d.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        else
            local des = string.format(' %s游戏消耗%d,当前剩余%d.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        end
        self.ListView_newPush:refreshView()
    elseif data.cbType == 2 then
        --战局
        local item = self.Panel_fontItem:clone()
        self.ListView_newPush:pushBackCustomItem(item)
        local Text_desfont = ccui.Helper:seekWidgetByName(item, "Text_desfont")
        Text_desfont:setColor(cc.c3b(165, 61, 9))
        local timeStr = os.date('%Y年%m月%d日 %H:%M:%S', data.dwOperTime)
        local gameName = ""
        if StaticData.Games[data.wKindID] then
            gameName = '(' .. StaticData.Games[data.wKindID].name .. ')'
        end

        if data.lFatigue >= 0 then
            local des = string.format(' %s游戏对局+%d,当前剩余%d.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        else
            local des = string.format(' %s游戏对局%d,当前剩余%d.', gameName, data.lFatigue, data.lNewFatigue)
            Text_desfont:setString(timeStr .. des)
        end
        self.ListView_newPush:refreshView()
    end
end

function NewClubMemberLayer:RET_GET_CLUB_MEMBER_FATIGUE_RECORD_FINISH(event)
    local data = event._usedata
    Log.d(data)
    if data.isFinish then
        self.newPushState = 2
    else
        self.newPushState = 1
    end
    self.newPushPage = self.newPushPage + 1
end

------------------------------------------------------------------------
--                            按键区域2                                --
------------------------------------------------------------------------
function NewClubMemberLayer:initNumberArea()
    self:resetNumber()

    local function onEventInput(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            local index = sender.index
            if index == 10 then
                self:resetNumber()
            elseif index == 11 then
                self:deleteNumber()
            else
                self:inputNumber(index)
            end
        end
    end

    for i = 0 , 11 do
        local btnName = string.format("Button_num%d", i)
        local Button_num = ccui.Helper:seekWidgetByName(self.Image_inputFrame, btnName)
        Button_num:setPressedActionEnabled(true)
        Button_num:addTouchEventListener(onEventInput)
        Button_num.index = i
    end
end

--重置数字
function NewClubMemberLayer:resetNumber()
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number then
            Text_number:setString("")
        end
    end
end

--输入数字
function NewClubMemberLayer:inputNumber(num)
    local roomNumber = ""
    for i = 1 , 6 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() == "" then
            Text_number:setString(tostring(num))
            roomNumber = roomNumber .. Text_number:getString()
            if i == 6 then
                -- UserData.Guild:addClubMember(self.clubData.dwClubID, tonumber(roomNumber), UserData.User.userID)
            end
            break
        else
            roomNumber = roomNumber .. Text_number:getString()
        end
    end
end

--删除数字
function NewClubMemberLayer:deleteNumber()
    for i = 6 , 1 , -1 do
        local numName = string.format("Text_number%d", i)
        local Text_number = ccui.Helper:seekWidgetByName(self.Image_inputFrame, numName)
        if Text_number:getString() ~= "" then
            Text_number:setString("")
            break
        end
    end
end

return NewClubMemberLayer