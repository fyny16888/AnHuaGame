local Common = require("common.Common")
local StaticData = require("app.static.StaticData")

local NewChatLayer = class("NewChatLayer", function()
    return ccui.Layout:create()
end)

function NewChatLayer:create(wKindID,expressCallback, quickCallback)
    local view = NewChatLayer.new()
    view:onCreate(wKindID,expressCallback, quickCallback)
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

function NewChatLayer:onEnter()

end

function NewChatLayer:onExit()

end

function NewChatLayer:onCleanup()

end

function NewChatLayer:onCreate(wKindID,expressCallback, quickCallback)  

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("NewChatLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    self.root:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            Common:palyButton()
            self:removeFromParent()
        end
    end)
    local uiPanel_expression = ccui.Helper:seekWidgetByName(self.root,"Panel_expression")
    --Common:playPopupAnim(uiPanel_expression)


    uiPanel_expression:setScale(0.0)
    uiPanel_expression:setAnchorPoint(0.5, 0.5)
    -- local size = uiPanel_expression:getContentSize()
    -- local x = display.width * 0.5
    -- local y = display.height * 0.5
    -- uiPanel_expression:setPosition(x, y)
    local scaleAction1 = cc.ScaleTo:create(0.25, 1.1)
    local scaleAction2 = cc.ScaleTo:create(0.15, 1)
    local seq = cc.Sequence:create(scaleAction1, scaleAction2)
    uiPanel_expression:runAction(seq)
 --   self:registerScriptMaskEx(uiPanel_expression, callback)

    local Chat = require("common.Chat")[0]
    local uiListView_quick = ccui.Helper:seekWidgetByName(self.root,"ListView_quick")
    local uiButton_item = uiListView_quick:getItem(0)
    uiButton_item:retain()
    uiListView_quick:removeAllItems()
    for key, var in pairs(Chat) do
        local item = uiButton_item:clone()
        uiListView_quick:pushBackCustomItem(item)
        local uiText_contents = ccui.Helper:seekWidgetByName(item,"Text_contents")
        uiText_contents:setString(var.text)
        Common:addTouchEventListener(item,function() 
            if quickCallback then
                quickCallback(key,var.text)
            end
            self:removeFromParent()
        end)
    end
    uiButton_item:release()
    local Panel_expressionItem = ccui.Helper:seekWidgetByName(self.root,"Panel_expressionItem") 
    self.emTempLate = ccui.Helper:seekWidgetByName(self.root,"emTempLate") 
	local viewSize = Panel_expressionItem:getContentSize()
	local anim = require("game.cdphz.Animation") [23]
	self.emTempLate:setVisible(false)
	local y = self.emTempLate:getSize()
	local count = #anim
	local contentSize = 0
	
	contentSize = math.floor(count / 3) *(y.height) - 30
	
	if contentSize <= viewSize.height then
		contentSize = viewSize.height
	end
	Panel_expressionItem:setInnerContainerSize(cc.size(viewSize.width, contentSize))
	for i = 1, count do
		local node = self.emTempLate:clone()
		node:setVisible(true)
		local path = anim[i].pngPath
		node:loadTextures(path, path)
		node:setName(i)
		node:ignoreContentAdaptWithSize(true)
		local size = node:getSize()
		local row = math.floor((i - 1) / 3) -- 5行
		local colum =(i - 1) % 3  -- 3列
		local posx = 50 +((size.width + 90) * colum)
		local posy = contentSize -(size.height / 2) *(row + 1) - 60 * row
		node:setPosition(posx, posy)       
        node:setPressedActionEnabled(true)
        node:addTouchEventListener(function(sender, event)
            if event == ccui.TouchEventType.ended then
                Common:palyButton()
                if expressCallback then
                    expressCallback(i)
                end
                self:removeFromParent()
            end
        end)

		Panel_expressionItem:addChild(node)
    end

    -- for i = 1, 6 do
    --     local uiButton_item = ccui.Helper:seekWidgetByName(self.root,string.format("Button_item%d",i))
    --     Common:addTouchEventListener(uiButton_item,function() 
    --         if expressCallback then
    --             expressCallback(i-1)
    --         end
    --         self:removeFromParent()
    --     end)
    -- end
  
    local uiButton_expression = ccui.Helper:seekWidgetByName(self.root,"Button_expression")
    local uiButton_quick = ccui.Helper:seekWidgetByName(self.root,"Button_quick")

    local Panel_expressionItem = ccui.Helper:seekWidgetByName(self.root,"Panel_expressionItem")
  
    local function ShowChange(type)
        if type == 1 then 
            uiButton_expression:setBright(false)
            uiButton_quick:setBright(true)
            Panel_expressionItem:setVisible(false)
            uiListView_quick:setVisible(true)
        else
            uiButton_quick:setBright(false)
            uiButton_expression:setBright(true)
            Panel_expressionItem:setVisible(true)
            uiListView_quick:setVisible(false)
        end 
    end  
    Common:addTouchEventListener(uiButton_expression,function() ShowChange(0)end)
    Common:addTouchEventListener(uiButton_quick,function() ShowChange(1)end)
    ShowChange(0)
    --自由聊天
    local uiTextField_chat = ccui.Helper:seekWidgetByName(self.root,"TextField_chat")

    local uiButton_chat = ccui.Helper:seekWidgetByName(self.root,"Button_chat")
    Common:addTouchEventListener(uiButton_chat,function() 
        local contents =uiTextField_chat:getString()
        if #contents == 0 then
            return
        end   
        if quickCallback then
            uiTextField_chat:setString('')
            quickCallback(0,contents)
        end
        self:removeFromParent()
    end) 
        
    require("common.SceneMgr"):switchOperation(self)
end

return NewChatLayer   