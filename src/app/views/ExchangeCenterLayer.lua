--[[
*名称:ExchangeCenterLayer
*描述:兑换中心
*作者:admin
*创建日期:2019-07-24 15:18:35
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

local ExchangeCenterLayer = class("ExchangeCenterLayer", cc.load("mvc").ViewBase)

function ExchangeCenterLayer:onConfig()
    self.widget         = {
    	{"Button_close", "onClose"},
        {"Image_red", "onRed"},
        {"Image_redLight"},
        {"Image_rule", "onRule"},
        {"Image_ruleLight"},
        {"Image_record", "onRecord"},
        {"Image_recordLight"},
        {"Image_head"},
        {"Text_name"},
        {"Text_number"},
        {"Panel_right"},
        {"ScrollView_red"},
        {"Panel_rule"},
        {"Panel_rocord"},
        {"Button_kfcopy", "onKFCopy"},
        {"Button_gzhcopy", "onGZHCopy"},
        {"ListView_record"},
        {"Button_item"},
        {"Panel_recordItem"},
        {"Panel_item"},
    }
    self.tableView = nil
    self.itemArray = {}
end

function ExchangeCenterLayer:onEnter()
	EventMgr:registListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
	EventMgr:registListener(EventType.RET_MALL_EXCHANGE_REDENVELOPE,self,self.RET_MALL_EXCHANGE_REDENVELOPE)
	EventMgr:registListener(EventType.RET_GET_MALL_LOG,self,self.RET_GET_MALL_LOG)
    EventMgr:registListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
end

function ExchangeCenterLayer:onExit()
	EventMgr:unregistListener(EventType.SUB_CL_USER_INFO,self,self.SUB_CL_USER_INFO)
	EventMgr:unregistListener(EventType.RET_MALL_EXCHANGE_REDENVELOPE,self,self.RET_MALL_EXCHANGE_REDENVELOPE)
	EventMgr:unregistListener(EventType.RET_GET_MALL_LOG,self,self.RET_GET_MALL_LOG)
    EventMgr:unregistListener(EventType.RET_GET_MALL_LOG_FINISH,self,self.RET_GET_MALL_LOG_FINISH)
end

function ExchangeCenterLayer:onCreate()
	Common:requestUserAvatar(UserData.User.userID,UserData.User.szLogoInfo,self.Image_head,"img")
	self.Text_name:setString(string.format("%s",UserData.User.szNickName))
	self.Text_number:setString(string.format("兑换券数量：%d",UserData.Bag:getBagPropCount(1008)))
	self:switchMenu(1)

	self.ListView_record:removeAllChildren()
    self.ListView_record.wPageCount = 0
    self.ListView_record:onScroll(function(event)
        if event.name == "SCROLL_TO_BOTTOM" then
            if self.ListView_record.loading == true or self.ListView_record.finish == true then
                return
            end
            self.ListView_record.loading = true
            self.ListView_record.wPageCount = self.ListView_record.wPageCount + 1
            UserData.Mall:sendMsgGetRequestmallRecord(UserData.User.userID, 2, self.ListView_record.wPageCount)
        end
    end)

    --红包兑换记录
    UserData.Mall:sendMsgGetRequestmallRecord(0, 11, 1)

    -- for i=1,10 do
    --     local temp = {
    --         name = 'test_' .. i,
    --         count = 50,
    --     }
    --     table.insert(self.itemArray, temp)
    -- end
    -- self:setTableView()
end

function ExchangeCenterLayer:onClose()
	self:removeFromParent()
end

function ExchangeCenterLayer:onRed()
	self:switchMenu(1)
end

function ExchangeCenterLayer:onRule()
	self:switchMenu(2)
end

function ExchangeCenterLayer:onRecord()
	self:switchMenu(3)
end

function ExchangeCenterLayer:onKFCopy()
	UserData.User:copydata("dxxqp668") 
    require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
end

function ExchangeCenterLayer:onGZHCopy()
	UserData.User:copydata("dxxqp168") 
    require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
end

function ExchangeCenterLayer:switchMenu(index)
	if index == 1 then
		self.Image_redLight:setVisible(true)
		self.Image_ruleLight:setVisible(false)
		self.Image_recordLight:setVisible(false)
		self.ScrollView_red:setVisible(true)
		self.Panel_rule:setVisible(false)
		self.Panel_rocord:setVisible(false)
		self:gotoRedPage()
	elseif index == 2 then
		self.Image_redLight:setVisible(false)
		self.Image_ruleLight:setVisible(true)
		self.Image_recordLight:setVisible(false)
		self.ScrollView_red:setVisible(false)
		self.Panel_rule:setVisible(true)
		self.Panel_rocord:setVisible(false)
	else
		self.Image_redLight:setVisible(false)
		self.Image_ruleLight:setVisible(false)
		self.Image_recordLight:setVisible(true)
		self.ScrollView_red:setVisible(false)
		self.Panel_rule:setVisible(false)
		self.Panel_rocord:setVisible(true)
		self:gotoRecordPage()
	end
end

function ExchangeCenterLayer:gotoRedPage()
	self.ScrollView_red:removeAllChildren()
    if not UserData.Mall.tableMallConfig[11] then
        return
    end

    local tableMall = clone(UserData.Mall.tableMallConfig[11])
    local index = 0
    for k,v in pairs(tableMall) do
        local item = self.Button_item:clone()
        self.ScrollView_red:addChild(item)
        index = index + 1
        local col = index % 3
        if col == 0 then
            col = 3
        end
        local row = math.ceil(index / 3)
        local x = 132 + (col - 1) * 243
        local y = 480 - (row - 1) * 255
        item:setPosition(x, y)

        local Text_ziti = ccui.Helper:seekWidgetByName(item,"Text_ziti")
        Text_ziti:setTextColor(cc.c3b(141,69,0))
        local Text_money = ccui.Helper:seekWidgetByName(item,"Text_money")
        Text_money:setTextColor(cc.c3b(255,0,0))
        Text_money:setString(string.format("%d元",v.lCount))
        local Text_number = ccui.Helper:seekWidgetByName(item,"Text_number")
        Text_number:setString(string.format("%d",v.lPrice))
     
        Common:addTouchEventListener(item, function()
            if UserData.Bag:getBagPropCount(1008) < v.lPrice then
                require("common.MsgBoxLayer"):create(0,nil,"您的红包券不足!")
                return
            end
            require("common.MsgBoxLayer"):create(1,nil,string.format("您确定花费%d红包券兑换%d元红包?",v.lPrice,v.lCount),function()
                UserData.Mall:doExchange(v.dwGoodsID,UserData.User.userID)
            end)
        end)
    end
end

function ExchangeCenterLayer:gotoRecordPage()
	self.ListView_record:removeAllChildren()
	self.ListView_record.loading = true
    self.ListView_record.finish = false
    self.ListView_record.wPageCount = 1
    UserData.Mall:sendMsgGetRequestmallRecord(UserData.User.userID, 2, self.ListView_record.wPageCount)
end

-------------------tableview(head)------------------------
--
function ExchangeCenterLayer:setCeil(item,idx)
    print('curCeil <--------->', idx)
    if type(self.itemArray) ~= 'table' then
        return
    end

    local v = self.itemArray[idx + 1]
    if type(v) ~= 'table' then
        return
    end

    local Text_gx = self:seekWidgetByNameEx(item,'Text_gx')
    local Text_name = self:seekWidgetByNameEx(item,'Text_name')
    local Text_cgdh = self:seekWidgetByNameEx(item,'Text_cgdh')
    local Text_number = self:seekWidgetByNameEx(item,'Text_number')
    local Text_wxhb = self:seekWidgetByNameEx(item,'Text_wxhb')
    Text_gx:setColor(cc.c3b(109,58,44))
    Text_name:setColor(cc.c3b(232,30,33))
    Text_cgdh:setColor(cc.c3b(109,58,44))
    Text_number:setColor(cc.c3b(255,107,26))
    Text_wxhb:setColor(cc.c3b(109,58,44))
    Text_name:setString(v.name)
    Text_number:setString(string.format("%d元",v.count))
end

function ExchangeCenterLayer:cellSizeForTable(table,idx) 
    return 60, 324
end

function ExchangeCenterLayer:tableCellAtIndex(table, idx)
    local item = nil
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
        item = self.Panel_item:clone()
        cell:add(item)
        item:setTag(123)
        local x = item:getContentSize().width / 2
        local y = item:getContentSize().height / 2
        item:setPosition(cc.p(x, y))
    else
        item = cell:getChildByTag(123)
    end

    if nil ~= item then
        self:setCeil(item,idx)
    end

    return cell
end

function ExchangeCenterLayer:numberOfCellsInTableView(table)
    return #self.itemArray
end

function ExchangeCenterLayer:setTableView()
    --待优化
    local temp = clone(self.itemArray)
    for i=1,10 do
        for i,v in ipairs(temp) do
            table.insert(self.itemArray, v)
        end
    end

    if self.tableView then
        self.tableView:reloadData()
        return
    end
    self.tableView = cc.TableView:create(cc.size(324,397))
    self.tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableView:setDelegate()
    self.tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.Panel_right:addChild(self.tableView)
    self.tableView:registerScriptHandler(handler(self,self.cellSizeForTable),cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableView:registerScriptHandler(handler(self,self.tableCellAtIndex),cc.TABLECELL_SIZE_AT_INDEX)
    self.tableView:registerScriptHandler(handler(self,self.numberOfCellsInTableView),cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.tableView:reloadData()

    self:stopAllActions()
    local offset = self.tableView:getContentOffset()
    local tempOffset = 0
    local buttomHeight = #self.itemArray * 60 - 397
    local callback = function()
        tempOffset = tempOffset + 0.2
        -- print('tempOffset => ', tempOffset)
        if tempOffset > buttomHeight then
            tempOffset = 0
        end
        self.tableView:setContentOffset(cc.p(offset.x, offset.y + tempOffset))
    end
    schedule(self, callback, 0)
end
--
--------------------tableview(end)--------------------



function ExchangeCenterLayer:SUB_CL_USER_INFO(event)
	local data = event._usedata
    Log.d(data)
    self.Text_number:setString(string.format("兑换券数量：%d",UserData.Bag:getBagPropCount(1008)))
end

function ExchangeCenterLayer:RET_MALL_EXCHANGE_REDENVELOPE(event)
    local data = event._usedata
    Log.d(data)
    if data.Result == 0 then
        require("common.MsgBoxLayer"):create(0,nil,"兑换成功,可在兑换记录中查收兑换码！")
        UserData.User:sendMsgUpdateUserInfo(1)
    elseif data.Result == 1 then
        require("common.MsgBoxLayer"):create(0,nil,"玩家不存在!")
    elseif data.Result == 2 then
        require("common.MsgBoxLayer"):create(0,nil,"商品不存在!")
    elseif data.Result == 3 then
        require("common.MsgBoxLayer"):create(0,nil,"红包券不足!")      
    elseif data.Result == 4 then
        require("common.MsgBoxLayer"):create(0,nil,"您今天已兑换过!")  
    end
end

function ExchangeCenterLayer:RET_GET_MALL_LOG(event)
    local data = event._usedata
    Log.d(data)

    if not self.Image_recordLight:isVisible() then
        local temp = {
            name = data.szNickName,
            count = data.lCount,
        }
        table.insert(self.itemArray, temp)
        return
    end

    local item = self.Panel_recordItem:clone()
    self.ListView_record:pushBackCustomItem(item)
    local Text_des = ccui.Helper:seekWidgetByName(item,"Text_des")
    Text_des:setColor(cc.c3b(109,58,44))
    Text_des:setString(string.format("%d元微信红包",data.lCount))
    local Text_time = ccui.Helper:seekWidgetByName(item,"Text_time")
    Text_time:setColor(cc.c3b(109,58,44))
    local date = os.date("*t",data.dwCreateTime)
    Text_time:setString(string.format("%d/%02d/%02d %02d:%02d:%02d",date.year,date.month,date.day,date.hour,date.min,date.sec))
    local Text_code = ccui.Helper:seekWidgetByName(item,"Text_code")
    Text_code:setColor(cc.c3b(109,58,44))
    Text_code:setString(data.szExchangeCode)
    local Button_control = ccui.Helper:seekWidgetByName(item,"Button_control")
    if data.wStatus == 2 then
        Button_control:setTouchEnabled(true)
        Button_control:setBright(false)
        Common:addTouchEventListener(Button_control,function() 
	        UserData.User:copydata(data.szExchangeCode) 
	        require("common.MsgBoxLayer"):create(0,nil,"复制成功！")
	    end)
    else
        Button_control:setTouchEnabled(false)
        Button_control:setBright(true)
    end
end

function ExchangeCenterLayer:RET_GET_MALL_LOG_FINISH(event)
    local data = event._usedata
    Log.d(data)

    if not self.Image_recordLight:isVisible() then
        self:setTableView()
        return
    end

    self.ListView_record.loading = false
    self.ListView_record.finish = data.lRet
end

return ExchangeCenterLayer