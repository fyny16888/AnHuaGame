
local ViewBase = class("ViewBase", cc.Node)

function ViewBase:ctor(app, name)
    self:enableNodeEvents()
    self.app_ = app
    self.name_ = name

    -- check CSB resource file
    local res = rawget(self.class, "RESOURCE_FILENAME")
    if res then
        self:createResoueceNode(res)
    end

    local binding = rawget(self.class, "RESOURCE_BINDING")
    if res and binding then
        self:createResoueceBinding(binding)
    end

    if self.onConfig then self:onConfig(self.app_.parameter) end
    
    local function onNodeEvent(eventType)
        if eventType == "enter" then
            if self.onEnter then self:onEnter(self.app_.parameter) end
        elseif eventType == "exit" then
            if self.onExit then self:onExit(self.app_.parameter) end
        elseif eventType == "cleanup" then
            if self.onCleanup then self:onCleanup() end
        end
    end
    self:registerScriptHandler(onNodeEvent)
    self:_loadCsbNode(self.widget)
    if self.onCreate then self:onCreate(self.app_.parameter) end
end

function ViewBase:getApp()
    return self.app_
end

function ViewBase:getName()
    return self.name_
end

function ViewBase:getResourceNode()
    return self.resourceNode_
end

function ViewBase:createResoueceNode(resourceFilename)
    if self.resourceNode_ then
        self.resourceNode_:removeSelf()
        self.resourceNode_ = nil
    end
    self.resourceNode_ = cc.CSLoader:createNode(resourceFilename)
    assert(self.resourceNode_, string.format("ViewBase:createResoueceNode() - load resouce node from file \"%s\" failed", resourceFilename))
    self:addChild(self.resourceNode_)
end

function ViewBase:createResoueceBinding(binding)
    assert(self.resourceNode_, "ViewBase:createResoueceBinding() - not load resource node")
    for nodeName, nodeBinding in pairs(binding) do
        local node = self.resourceNode_:getChildByName(nodeName)
        if nodeBinding.varname then
            self[nodeBinding.varname] = node
        end
        for _, event in ipairs(nodeBinding.events or {}) do
            if event.event == "touch" then
                node:onTouch(handler(self, self[event.method]))
            end
        end
    end
end

function ViewBase:showWithScene(transition, time, more)
    self:setVisible(true)
    local scene = display.newScene(self.name_)
    scene:addChild(self)
    display.runScene(scene, transition, time, more)
    return self
end


---[[@cxx add
---
-- 递归遍历子节点
-- @DateTime 2018-06-13
-- @param  root 根节点 name 目标节点
-- @return node or nil
--
function ViewBase:seekWidgetByNameEx(root,name)
    local rootArr = root:getChildren()
    if rootArr then
        for i,v in ipairs(rootArr) do
            if v:getName() == name then
                return v
            end
            local res = self:seekWidgetByNameEx(v,name)
            if res then
                return res
            end
        end
    end
    return nil 
end

---
-- 加载类对象绑定的csb
-- @DateTime 2018-06-13
-- @param  widget 需要使用的节点表信息
-- @return void
--
function ViewBase:_loadCsbNode(widget)
    if type(widget) ~= 'table' then
        return
    end
    
    local csbName = self.name_ .. ".csb"
    self.csb = cc.CSLoader:createNode(csbName)
    self:addChild(self.csb)

    for i,v in ipairs(widget) do
        self[v[1]] = self:seekWidgetByNameEx(self.csb, v[1])

        if not self[v[1]] then
            printError(v[1] .. ' widget no exist')
        end

        if self[v[2]] then
            self[v[1]]:setTouchEnabled(true)
            if self[v[1]].setPressedActionEnabled then
                self[v[1]]:setPressedActionEnabled(true)
            end
            local function callback(sender)
                require("common.Common"):playEffect("common/buttonplay.mp3")
                self[v[2]](self, sender)
            end
            self[v[1]]:addClickEventListener(callback)
        end
    end
end
--]]

return ViewBase
