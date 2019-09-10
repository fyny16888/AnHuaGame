local EventMgr = {}

local eventDispatcher = cc.Director:getInstance():getEventDispatcher()--cc.Node:create():getEventDispatcher()

local listenerDic = {}

local function hasListenerWith(eventName, target, handler)
    --assert( eventName ~= nil, 'EventMgr:hasListenerWith: eventName must not be nil' )
    if nil ~= listenerDic[eventName] then
        local listeners = listenerDic[eventName]
        local length = table.getn(listeners)
        for i = 1, length, 1 do
            local obj = listeners[i]
            if target == obj.target and handler == obj.handler then
                return true
            end
        end
    end
    return false
end

local function removeListenerWith(eventName, target, handler)
    --assert( eventName ~= nil, 'EventMgr:removeListenerWith: eventName must not be nil' )
    local index = 0
    if nil ~= listenerDic[eventName] then
        local listeners = listenerDic[eventName]
        local length = table.getn(listeners)
        for i = 1, length, 1 do
            local obj = listeners[i]
            if target == obj.target and handler == obj.handler then
                index = i
                break
            end
        end
    end
    if index > 0 then
        local listenerObj = table.remove(listenerDic[eventName], index)
        return listenerObj
    end
    return nil
end

function EventMgr:setDispatcher(dispatcher)
    eventDispatcher = dispatcher
end

function EventMgr:getDispatcher()
    return eventDispatcher
end

function EventMgr:registListener(eventName, target, handler, priority) 
    if eventName == nil then
        if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
            assert( eventName ~= nil, 'EventMgr:registListener: eventName must not be nil' )
        end
        return
    end
    if nil == listenerDic[eventName] then
        listenerDic[eventName] = {}
    end
    if false == hasListenerWith(eventName, target, handler) then
        local listenerObj = {}
        listenerObj.target = target
        listenerObj.handler = handler
        listenerObj.realfunc = function(event) listenerObj.handler(listenerObj.target,event) end
        local listener = cc.EventListenerCustom:create(eventName, listenerObj.realfunc)
        listenerObj.listener = listener 
        table.insert(listenerDic[eventName], listenerObj)
        local p = priority or 1
        eventDispatcher:addEventListenerWithFixedPriority(listener, p)
    end
    return handler
end

function EventMgr:unregistListener(eventName, target, handler)
    if PLATFORM_TYPE == cc.PLATFORM_OS_DEVELOPER then
        assert( eventName ~= nil, 'EventMgr:unregistListener: eventName must not be nil' )
    end

    if nil ~= listenerDic[eventName] then 
        local listenerObj = removeListenerWith(eventName, target, handler)
        if nil ~= listenerObj then
            eventDispatcher:removeEventListener(listenerObj.listener)
            listenerObj.target = nil
            listenerObj.handler = nil
            listenerObj.realfunc = nil
            listenerObj.listener = nil
            listenerObj = nil
            if table.getn(listenerDic[eventName]) == 0 then
                listenerDic[eventName] = nil
            end
        end
    end
end

function EventMgr:hasListener(eventName)
    --assert( eventName ~= nil, 'EventMgr:hasListener: eventName must not be nil' )
    if nil ~= listenerDic[eventName] then 
        return true
    end
    return false
end

function EventMgr:getListener(eventName)
    if nil ~= listenerDic[eventName] then 
        return listenerDic[eventName]
    end
    return nil
end

function EventMgr:dispatch(eventName, data)
    if eventName == "EVENT_TYPE_NET_RECV_MESSAGE" then
    elseif eventName == "EVENT_TYPE_SIGNAL" then
    else
        print("EventMgr:dispatch",eventName)
    end
    assert( eventName ~= nil, 'EventMgr:dispatch: eventName must not be nil' )
    local event = cc.EventCustom:new(eventName)
    event._usedata = data
    eventDispatcher:dispatchEvent(event)
end


return EventMgr