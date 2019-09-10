local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local UserData = require("app.user.UserData")
local NetMsgId = require("common.NetMsgId")
local NetMsgId = require("common.NetMsgId")
local NetMgr = require("common.NetMgr")
local EventMgr = require("common.EventMgr")
local EventType = require("common.EventType")
local EventType = require("common.EventType")

local RoomJoinLayer = class("RoomJoinLayer", cc.load("mvc").ViewBase)

function RoomJoinLayer:onEnter()
    
end

function RoomJoinLayer:onExit()
    
end

function RoomJoinLayer:onCleanup()

end

function RoomJoinLayer:onCreate(parames)
    NetMgr:getGameInstance():closeConnect()
    UserData.User.externalAdditional = ""
    local roomID = parames[1]
    if roomID ~= nil then
        self:joinRoom(roomID)      
        return
    end
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("RoomJoinLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    local uiButton_return = ccui.Helper:seekWidgetByName(self.root,"Button_return")
    uiButton_return:setPressedActionEnabled(true)
    local function onEventReturn(sender,event)
    	if event == ccui.TouchEventType.ended then
            Common:palyButton()
            -- local callback = function( ... )
            --     require("common.SceneMgr"):switchOperation()
            -- end
            -- Common:playExitAnim(self.root, callback)
            self:removeFromParent()
    	end
    end
    uiButton_return:addTouchEventListener(onEventReturn)
    local function roomNumberDefault()
        for i = 1 , 6 do      
            local uiText_number = ccui.Helper:seekWidgetByName(self.root,string.format("AtlasLabel_number%d",i))
            uiText_number:setString("")
        end
    end
    roomNumberDefault()
    local function roomNumberAdd(num)
        local roomNumber = ""
        for i = 1 , 6 do
            local uiText_number = ccui.Helper:seekWidgetByName(self.root,string.format("AtlasLabel_number%d",i))
            if uiText_number:getString() == "" then
                uiText_number:setString(tostring(num))
                roomNumber = roomNumber..uiText_number:getString()
                if i == 6 then  
                    local gameID = tonumber(string.sub(roomNumber,1,2))
                    print ("房间ID",gameID)
                    if UserData.Game.tableGames[gameID] == nil then
                        require("common.MsgBoxLayer"):create(0,nil,"房间号输入错误!")
                            roomNumberDefault()
                    	return
                    end
                    self:joinRoom(roomNumber)                      
                end
                break
            else
                roomNumber = roomNumber..uiText_number:getString()
            end
        end
    end
    local function roomNumberDel()
        for i = 6 , 1 , -1 do
            local uiText_number = ccui.Helper:seekWidgetByName(self.root,string.format("AtlasLabel_number%d",i))
            if uiText_number:getString() ~= "" then
                uiText_number:setString("")
                break
            end
        end
    end
    local function onEventInput(sender,event)
    	if event == ccui.TouchEventType.ended then
    	   Common:palyButton()
    	   local index = sender.index
    	   if index == 10 then
    	       roomNumberDefault()
    	   elseif index == 11 then
    	       roomNumberDel()
    	   else
    	       roomNumberAdd(index)
    	   end
    	end
    end
    for i = 0 , 11 do
        local uiButton_num = ccui.Helper:seekWidgetByName(self.root,string.format("Button_num%d",i))
        uiButton_num:setPressedActionEnabled(true)
        uiButton_num:addTouchEventListener(onEventInput)
        uiButton_num.index = i
    end  

    -- Common:playPopupAnim(self.root)  
end

function RoomJoinLayer:joinRoom(roomNumber)
    local roomNumber = tonumber(roomNumber)
    self:addChild(require("app.MyApp"):create(roomNumber):createView("InterfaceJoinRoomNode"))
end



return RoomJoinLayer

