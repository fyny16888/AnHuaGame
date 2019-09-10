local json = require("json")
local Bit = require("common.Bit")

local Common = {
    wKindID = nil
}

--截屏
function Common:screenshot(fileName)
    --如果已经存在则删除文件并且删除缓存
    if cc.FileUtils:getInstance():isFileExist(fileName) then
        local texture = cc.TextureCache:getInstance():addImage(fileName)
        if texture then
            cc.TextureCache:getInstance():removeTexture(texture)
        end
    end
    local size = cc.Director:getInstance():getWinSize()
    local render = cc.RenderTexture:create(size.width, size.height,cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)    
    render:setPosition(cc.p(size.width/2, size.height/2))
    render:begin()
    cc.Director:getInstance():getRunningScene():visit()
    render:endToLua()
    cc.Director:getInstance():getRenderer():render()
    local fullpath = fileName
    local image1 = render:newImage()  
    image1:saveToFile(fullpath,false)
    image1:release()
end

--请求网络头像
--mode
--img       图片资源替换          node:loadTexture(img)
--btn       按钮资源替换          node:loadTextures(img,img,img)
--clip      裁剪模式添加          node:removeAllChildren() node:addChild(img)

function Common:requestUserAvatar(userID,addr,node,mode)
    local EventMgr = require("common.EventMgr")
    local EventType = require("common.EventType")
    node:retain()
    if string.len(addr) == 1 then
        local index = tonumber(addr)
        if index == 0 then
            local img = "common/hall_avatar.png"
            if mode == "img" then
                node:loadTexture(img)
            elseif mode == "btn" then
                node:loadTextures(img,img,img)
            elseif mode == "clip" then
                self:setUserHeadCliping(node,img)
            else

            end
            node:release()
            return
        end
    end
    local preAddr = cc.UserDefault:getInstance():getStringForKey(string.format("avatar_%d.png",userID),"")
    local fileName = FileDir.dirDownload..string.format("avatar_%d.png",userID)
    if cc.FileUtils:getInstance():isFileExist(fileName) then
        local texture = cc.TextureCache:getInstance():addImage(fileName)
        if texture then
            cc.TextureCache:getInstance():removeTexture(texture)
        end
    end
    if preAddr == addr and cc.FileUtils:getInstance():isFileExist(fileName) == true then
        local img = fileName
        if mode == "img" then
            node:loadTexture(img)
        elseif mode == "btn" then
            node:loadTextures(img,img,img)
        elseif mode == "clip" then
            self:setUserHeadCliping(node,img)
        else

        end
        node:release()
    else
        local xmlHttpRequest = cc.XMLHttpRequest:new()
        xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
        xmlHttpRequest:setRequestHeader("Content-type","image/jpg")
        xmlHttpRequest:open("GET",addr)
        local function onHttpRequestaddr()
            if xmlHttpRequest.status == 200 then
                local response = xmlHttpRequest.response
                local fp = io.open(fileName,"wb+")
                if fp == nil then
                    print("请求头像创建文件失败!",fileName)
                    return
                end
                fp:write(response)
                fp:close()
                
                local img = fileName
                if mode == "img" then
                    node:loadTexture(img)
                elseif mode == "btn" then
                    node:loadTextures(img,img,img)
                elseif mode == "clip" then
                    self:setUserHeadCliping(node,img)
                else

                end
                node:release()
                cc.UserDefault:getInstance():setStringForKey(string.format("avatar_%d.png",userID),addr)
            else
                print("请求头像连接错误!",addr)
            end

        end
        xmlHttpRequest:registerScriptHandler(onHttpRequestaddr)
        xmlHttpRequest:send()
    end
end

--请求网络图片 
--==============================--
--desc:
--time:2018-09-25 05:52:29
--@addr:网络地址
--@node:添加节点
--@mode:模式
--@return 
--==============================--
function Common:requestOnlinePicture(userID,addr,node,mode)
    local EventMgr = require("common.EventMgr")
    local EventType = require("common.EventType")
    node:retain()
    if string.len(addr) == 1 then
        local index = tonumber(addr)
        if index == 0 then
            local img = "common/hall_avatar.png"
            if mode == "img" then
                node:loadTexture(img)
            elseif mode == "btn" then
                node:loadTextures(img,img,img)
            elseif mode == "clip" then
                self:setUserHeadCliping(node,img)
            else

            end
            node:release()
            return
        end
    end
    local preAddr = cc.UserDefault:getInstance():getStringForKey(string.format("img_%d.png",userID),"")
    local fileName = FileDir.dirDownload..string.format("img_%d.png",userID)
    if cc.FileUtils:getInstance():isFileExist(fileName) then
        local texture = cc.TextureCache:getInstance():addImage(fileName)
        if texture then
            cc.TextureCache:getInstance():removeTexture(texture)
        end
    end
    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xmlHttpRequest:setRequestHeader("Content-type","image/jpg")
    xmlHttpRequest:open("GET",addr)
    local function onHttpRequestaddr()
        if xmlHttpRequest.status == 200 then
            local response = xmlHttpRequest.response
            local fp = io.open(fileName,"wb+")
            if fp == nil then
                print("请求头像创建文件失败!",addr)
                return
            end
            fp:write(response)
            fp:close()
            
            local img = fileName
            if mode == "img" then
                node:loadTexture(img)
            elseif mode == "btn" then
                node:loadTextures(img,img,img)
            elseif mode == "clip" then
                self:setUserHeadCliping(node,img)
            else

            end
            node:release()
            cc.UserDefault:getInstance():setStringForKey(string.format("img_%d.png",userID),addr)
        else
            print("请求头像连接错误!",addr)
        end

    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestaddr)
    xmlHttpRequest:send()
end

function Common:requestErWeiMaPicture(url, node)
    if type(url) ~= 'string' then
        return
    end

    local fileName = string.match(url, ".+/([^/]*%.%w+)$")
    print('requestErWeiMaPicture = ', url, fileName)
    if not fileName then
        return
    end

    fileName = FileDir.dirDownload .. fileName
    if cc.FileUtils:getInstance():isFileExist(fileName) then
        node:loadTexture(fileName)
        return
    end

    local xmlHttpRequest = cc.XMLHttpRequest:new()
    xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    xmlHttpRequest:setRequestHeader("Content-type","image/jpg")
    xmlHttpRequest:open("GET",url)
    local function onHttpRequestaddr()
        if xmlHttpRequest.status == 200 then
            local response = xmlHttpRequest.response
            local fp = io.open(fileName,"wb+")
            if fp == nil then
                print("请求头像创建文件失败!",url)
                return
            end
            fp:write(response)
            fp:close()

            performWithDelay(node, function() 
                node:loadTexture(fileName)
            end, 0.1)
        else
            print("请求头像连接错误!",url)
        end
    end
    xmlHttpRequest:registerScriptHandler(onHttpRequestaddr)
    xmlHttpRequest:send()
end

--字符串分割
function Common:stringSplit(str, delimiter)
    local pos,arr = 0, {}
    if (str== nil or str == "" or delimiter == nil or delimiter=="") then return arr end

    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

--按钮音效
function Common:palyButton()
    require("common.Common"):playEffect("common/buttonplay.mp3")
end

--检测域名地址是否有效
function Common:isDomain(szDomain)
    local tableType = {".com",".net",".org","red",".pub",".ink",".info",".xyz",".win",".cn",".cx",".com.cn",".wang",".cc",".xin"}
    for key, var in pairs(tableType) do
        if string.find(szDomain,var) then
            return true
        end
    end
    return false
end

--窗口抖动效果
function Common:JitterEffects(node)
    node:runAction(cc.Sequence:create(
        cc.MoveBy:create(0.05,cc.p(-15,0)) , cc.MoveBy:create(0.1,cc.p(30,0)) , 
        cc.MoveBy:create(0.1,cc.p(-30,0)) , cc.MoveBy:create(0.1,cc.p(30,0)) ,cc.MoveBy:create(0.05,cc.p(-15,0))))
end

--名字截取功能函数
--@param    sName:要切割的字符串  
--@return   nMaxCount，字符串上限,中文字为2的倍数  
--@param    nShowCount：显示英文字个数，中文字为2的倍数,可为空  
--@note         函数实现：截取字符串一部分，剩余用“...”替换</span>  
function Common:getShortName(sName,nMaxCount,nShowCount)  
    if sName == nil or nMaxCount == nil then  
        return sName
    end  
    local sStr = sName  
    local tCode = {}  
    local tName = {}  
    local nLenInByte = #sStr  
    local nWidth = 0  
    if nShowCount == nil then  
       nShowCount = nMaxCount - 3  
    end  
    for i=1,nLenInByte do  
        local curByte = string.byte(sStr, i)  
        local byteCount = 0;  
        if curByte>0 and curByte<=127 then  
            byteCount = 1  
        elseif curByte>=192 and curByte<223 then  
            byteCount = 2  
        elseif curByte>=224 and curByte<239 then  
            byteCount = 3  
        elseif curByte>=240 and curByte<=247 then  
            byteCount = 4  
        end  
        local char = nil  
        if byteCount > 0 then  
            char = string.sub(sStr, i, i+byteCount-1)  
            i = i + byteCount -1  
        end  
        if byteCount == 1 then  
            nWidth = nWidth + 1  
            table.insert(tName,char)  
            table.insert(tCode,1)  
              
        elseif byteCount > 1 then  
            nWidth = nWidth + 2  
            table.insert(tName,char)  
            table.insert(tCode,2)  
        end  
    end  
      
    if nWidth > nMaxCount then  
        local _sN = ""  
        local _len = 0  
        for i=1,#tName do  
            _sN = _sN .. tName[i]  
            _len = _len + tCode[i]  
            if _len >= nShowCount then  
                break  
            end  
        end  
        sName = _sN .. "..."  
    end  
    return sName
end

--去除字符串两端空格
function Common:trimStartAndEnd(s)
    if type(s)=="string" then
        return s:match("^%s+(.-)%s+$")
    else
        return s
    end
end

--判断时间是否为今天
function Common:isToday(time)
    local UserData = require("app.user.UserData")
	local currentTime = UserData.Time:getServerTimeToTable()
	local srcTime = os.date("*t",time)
	if currentTime.year == srcTime.year and currentTime.month == srcTime.month and currentTime.day == srcTime.day then
    	return true
	end
	return false
end

--按钮点击事件
function Common:addTouchEventListener(btn,callback,isDisabledPressedAction)
    if isDisabledPressedAction ~= true then
        btn:setPressedActionEnabled(true)
    end
    btn:addTouchEventListener(function(sender,event) 
        if event == ccui.TouchEventType.ended then
            self:palyButton()
            if callback then
                callback()
            end
        end
    end)
end

function Common:getYMDHMS(time)
    local today = os.date("*t",time)
    return today.year,today.month,today.day,today.hour,today.min,today.sec
end

function Common:getToday()
    local today = os.date("*t")
    return today.year,today.month,today.day,today.hour,today.min,today.sec
end

function Common:getStampDay( stamp,isMin )
    local _year,_month,_day = Common:getYMDHMS(stamp)
    if isMin then
        return os.time({day=_day, month=_month, year=_year, hour=0, min=0, sec=0})
    else
        return os.time({day=_day, month=_month, year=_year, hour=23, min=59, sec=59})
    end
end

--打印消息
function Common:printLog(obj, objKey, index)
    --local AssetsManagerCustom = require("app.models.AssetsManagerCustom")
    if cc.PLATFORM_OS_WINDOWS ~= cc.Application:getInstance():getTargetPlatform()  then
        return
    end
    if index == nil then
        index = 1
    end
    local steps = "   "
    for i = 1 , index do
        steps = steps.."   "
    end

    if type(obj) == "table" then
        for key, var in pairs(obj) do
            if type(var) == "table" then
                self:printLog(var,key,index + 1)
            else
                print(steps,key,var)
            end
        end   
    else
        if objKey ~= nil then
            print(steps, objKey, obj)
        else
            print(steps, obj)
        end
    end
end

-- 大数字转化
function Common:itemNumberToString(num)  
    if num >= 100000000 then  
        if num % 100000000 < 1000000 then  
            return string.format("%d亿", math.floor(num / 100000000))  
        else  
            return string.format("%.2f亿", (num - num % 1000000)/100000000)  
        end  

    elseif num >= 10000 then  
        if num % 10000 < 100 then  
            return string.format("%d万", math.floor(num / 10000))  
        else  
            return string.format("%.2f万", (num - num % 100)/10000)  
        end  
    elseif  num <= 10000 and num > -10000 then   
        return string.format("%d", num)  
    elseif num <= -10000 and num > -100000000  then  
        num = num *-1
        if num % 10000 < 100 then  
            return string.format("-%d万", math.floor(num / 10000))  
        else  
            return string.format("-%.2f万", (num - num % 100)/10000)  
        end  
    elseif num <= -100000000   then  
        num = num *-1
        if num % 100000000 < 1000000 then  
            return string.format("-%d亿", math.floor(num / 100000000))  
        else  
            return string.format("-%.2f亿", (num - num % 1000000)/100000000)  
        end   
    end  
end  

function Common:ToStringEx(value)
    if type(value)=='table' then
        return self:TableToStr(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
        return tostring(value)
    end
end

function Common:TableToStr(t)
    if t == nil then return "" end
    local retstr= "{"

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
            signal = ""
        end

        if key == i then
            retstr = retstr..signal..self:ToStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..self:ToStringEx(key).."]="..self:ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..self:TableToStr(getmetatable(key)).."*e".."="..self:ToStringEx(value)
                else
                    retstr = retstr..signal..key.."="..self:ToStringEx(value)
                end
            end
        end

        i = i+1
    end

    retstr = retstr.."}"
    return retstr
end

function Common:StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end

    return loadstring("return " .. str)()
end

function Common:addCheckTouchEventListener(items,isCheck,callback)
    for key, var in pairs(items) do
        var:setSwallowTouches(false)
        var:setBright(false)
        Common:addTouchEventListener(var,function() 
            print("++++++++++++++触发点击事件1")
            if isCheck ~= true then
                for k, v in pairs(items) do                    
                    local uiText_desc = ccui.Helper:seekWidgetByName(v,"Text_desc")
                    local uiText_addition = ccui.Helper:seekWidgetByName(v,"Text_addition")
                    if uiText_desc ~= nil then 
                        uiText_desc:setTextColor(cc.c3b(215,86,31))
                    end
                    if uiText_addition ~= nil then 
                        uiText_addition:setTextColor(cc.c3b(215,86,31))
                    end
                    if v == var then
                        v:setBright(true)
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(215,86,31))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(215,86,31))
                        end
                    else
                        v:setBright(false)
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(109,58,44))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(109,58,44))
                        end
                    end
                end
            else
                local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                local uiText_addition = ccui.Helper:seekWidgetByName(v,"Text_addition")
                if var:isBright() then
                    var:setBright(false)
                    if uiText_desc ~= nil then 
                        uiText_desc:setTextColor(cc.c3b(109,58,44))
                    end
                    if uiText_addition ~= nil then 
                        uiText_addition:setTextColor(cc.c3b(109,58,44))
                    end
                else
                    var:setBright(true)
                    if uiText_desc ~= nil then 
                        uiText_desc:setTextColor(cc.c3b(215,86,31))
                    end
                    if uiText_addition ~= nil then 
                        uiText_addition:setTextColor(cc.c3b(215,86,31))
                    end
                end
            end
            if callback then
                callback(key)
            end
        end)
    end
    for key, var in pairs(items) do
        local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
        if uiText_desc ~= nil then
            uiText_desc:setTouchEnabled(true)
            Common:addTouchEventListener(uiText_desc,function() 
                if isCheck ~= true then
                    for k, v in pairs(items) do                    
                        local uiText_desc = ccui.Helper:seekWidgetByName(v,"Text_desc")
                        local uiText_addition = ccui.Helper:seekWidgetByName(v,"Text_addition")
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(215,86,31))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(215,86,31))
                        end
                        if v == var then
                            v:setBright(true)
                            if uiText_desc ~= nil then 
                                uiText_desc:setTextColor(cc.c3b(215,86,31))
                            end
                            if uiText_addition ~= nil then 
                                uiText_addition:setTextColor(cc.c3b(215,86,31))
                            end
                        else
                            v:setBright(false)
                            if uiText_desc ~= nil then 
                                uiText_desc:setTextColor(cc.c3b(109,58,44))
                            end
                            if uiText_addition ~= nil then 
                                uiText_addition:setTextColor(cc.c3b(109,58,44))
                            end
                        end
                    end
                else
                    local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                    local uiText_addition = ccui.Helper:seekWidgetByName(v,"Text_addition")
                    if var:isBright() then
                        var:setBright(false)
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(109,58,44))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(109,58,44))
                        end
                    else
                        var:setBright(true)
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(215,86,31))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(215,86,31))
                        end
                    end
                end   
                if callback then
                    callback(key)
                end 
            end,true)
        end
        
        local uiText_addition = ccui.Helper:seekWidgetByName(var,"Text_addition")
        if uiText_addition ~= nil then 
            uiText_addition:setTouchEnabled(true)
            Common:addTouchEventListener(uiText_addition,function() 
                if isCheck ~= true then
                    for k, v in pairs(items) do                    
                        local uiText_desc = ccui.Helper:seekWidgetByName(v,"Text_desc")
                        local uiText_addition = ccui.Helper:seekWidgetByName(v,"Text_addition")
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(215,86,31))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(215,86,31))
                        end
                        if v == var then
                            v:setBright(true)
                            if uiText_desc ~= nil then 
                                uiText_desc:setTextColor(cc.c3b(215,86,31))
                            end
                            if uiText_addition ~= nil then 
                                uiText_addition:setTextColor(cc.c3b(215,86,31))
                            end
                        else
                            v:setBright(false)
                            if uiText_desc ~= nil then 
                                uiText_desc:setTextColor(cc.c3b(109,58,44))
                            end
                            if uiText_addition ~= nil then 
                                uiText_addition:setTextColor(cc.c3b(109,58,44))
                            end
                        end
                    end
                else
                    local uiText_desc = ccui.Helper:seekWidgetByName(var,"Text_desc")
                    local uiText_addition = ccui.Helper:seekWidgetByName(v,"Text_addition")
                    if var:isBright() then
                        var:setBright(false)
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(109,58,44))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(109,58,44))
                        end
                    else
                        var:setBright(true)
                        if uiText_desc ~= nil then 
                            uiText_desc:setTextColor(cc.c3b(215,86,31))
                        end
                        if uiText_addition ~= nil then 
                            uiText_addition:setTextColor(cc.c3b(215,86,31))
                        end
                    end
                end
                if callback then
                    callback(key)
                end 
            end,true)
        end


    end
end

--[
-- @brief  弹框下层遮罩
-- @param  node 遮罩内背景节点
-- @return void
--]
function Common:registerScriptMask(node, callback)
    local function onTouchBegan(touch,event)
        if node:isVisible() then
            return true
        else
            return false
        end
    end

    local function onTouchEnded(touch, event)
        local pos = touch:getLocation()
        pos = node:convertToNodeSpace(pos)
        local size = node:getContentSize()
        if not cc.rectContainsPoint(cc.rect(0,0,size.width,size.height), pos) then
            if callback then
                callback()
            else
                node:removeFromParent()
            end
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,node)
end

--[
-- @brief  弹框下层遮罩扩展
-- @param  node 遮罩内背景节点
-- @param  callback 点击背景之外执行回调
-- @return void
--]
function Common:registerScriptMaskEx(node, callback)
    if not callback then
        return
    end

    local function onTouchBegan(touch,event)
        return true
    end

    local function onTouchEnded(touch, event)
        local pos = touch:getLocation()
        print('onTouchEnded::', pos.x, pos.y)
        pos = node:convertToNodeSpace(pos)
        local size = node:getContentSize()
        if not cc.rectContainsPoint(cc.rect(0,0,size.width,size.height), pos) then
            self:playExitAnim(node, callback)
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,node)
end

function Common:registerNodeEvent(node, callFunc,isSwallow)
    local function onTouchBegan(touch,event)
        
        local pos = touch:getLocation()
        if callFunc then
            callFunc({name='begin',x=pos.x,y=pos.y})
        end
        return true
    end

    local function onTouchEnded(touch, event)
        local pos = touch:getLocation()
        if callFunc then
            callFunc({name='end',x=pos.x,y=pos.y})
        end
    end

    local function onTouchMoved( touch,event )
        local pos = touch:getLocation()
        if callFunc then
            callFunc({name='moved',x=pos.x,y=pos.y})
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(isSwallow)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,node)
end

--[
-- @brief  非全屏弹框加载动作
-- @param  node 执行动作节点
-- @param  isSecond 是否是二级弹框类型
-- @param  callback 点击node之外执行回调
-- @return void
--]
function Common:playPopupAnim(node, isSecond, callback)
    if not isSecond then
        node:setScale(0.0)
        node:setAnchorPoint(0.5, 0.5)
        local size = node:getContentSize()
        local x = display.width * 0.5
        local y = display.height * 0.5
        node:setPosition(x, y)
        local scaleAction1 = cc.ScaleTo:create(0.25, 1.1)
        local scaleAction2 = cc.ScaleTo:create(0.15, 1)
        local seq = cc.Sequence:create(scaleAction1, scaleAction2)
        node:runAction(seq)
        self:registerScriptMaskEx(node, callback)
    else
        require("common.CommonLayer"):create(0.3, node)
        node:setScale(0.0)
        node:setAnchorPoint(0, 0)
        
        local scaleW = display.width / 1280
        local scaleH = display.height / 720
        local size = node:getContentSize()
        local x = (display.width - size.width * scaleW) * 0.5
        local y = (display.height - size.height * scaleH) * 0.5
        node:setPosition(x, y)
        local scaleAction1 = cc.ScaleTo:create(0.25, 1.01)
        local scaleAction2 = cc.ScaleTo:create(0.15, 1)
        local seq = cc.Sequence:create(scaleAction1, scaleAction2)
        node:runAction(seq)
    end
end

--[
-- @brief  非全屏弹框退出动作
-- @param  animNode 执行动作节点
-- @param  callback 退出执行回调
-- @return void
--]
function Common:playExitAnim(animNode, callback)
    local scaleTo  = cc.ScaleTo:create(0.1, 0.5)
    local callFunc = cc.CallFunc:create(callback)
    local seq = cc.Sequence:create(scaleTo, callFunc)
    animNode:runAction(seq)
end

--[
-- @brief  一个个显示动作
-- @param  itemList 列表节点
-- @return void
--]
function Common:playOneByoneAnim(itemList)
    if type(itemList) ~= 'table' then
        printError('param itemList error')
        return
    end

    for i,item in ipairs(itemList) do
        item:stopAllActions()
    end

    for i,item in ipairs(itemList) do
        local speed = 0.1
        local delayTime    = (i - 1) * speed * 2
        local delayAction  = cc.DelayTime:create(delayTime)
        local scaleAction1 = cc.ScaleTo:create(speed, 0.95)
        local scaleAction2 = cc.ScaleTo:create(speed, 1.05)
        local scaleAction3 = cc.ScaleTo:create(speed, 1)
        local seq = cc.Sequence:create(delayAction, scaleAction1, scaleAction2, scaleAction3)
        item:runAction(seq)
    end
end

--[
-- @brief  从上倒下掉下来发牌动作
-- @param  node 执行动作节点
-- @return void
--]
function Common:playGetCardAnim(node)
    --[[node:stopAllActions()
    local curPos = cc.p(node:getPosition())
    node:setPositionY(curPos.y + 60)
    local moveTo = cc.MoveTo:create(0.5, curPos)
    local easeAtn = cc.EaseElasticOut:create(moveTo)
    node:runAction(easeAtn)
    -- require("common.Common"):playEffect("game/audio_get_card.mp3")
    --]]

    ---[[old code:
    node:setOpacity(0)
    node:runAction(cc.FadeIn:create(0.1))
    --]]
end

--[
-- @brief  单双击操作
-- @param  node 节点  onceBack 单击回调 doubleBack 双击回调 clickBack 点击回调
-- @return void
--]
function Common:onceDblClick(node, onceBack, doubleBack, clickBack)
    local pressCount = 0
    local time = 0
    local isCreate = true
    node:setTouchEnabled(true)
    node:addTouchEventListener(function(sender,event)
        if event == ccui.TouchEventType.ended then
            pressCount = pressCount + 1
            if isCreate then
                isCreate = false
                local update = function()
                    if pressCount == 1 then
                        --单击
                        if onceBack then
                            onceBack(sender)
                        end
                    else
                        --双击
                        if doubleBack then
                            doubleBack(sender)
                        end
                    end
                    pressCount = 0
                    time = 0
                    isCreate = true
                end
                performWithDelay(node, update, 0.3)
            end

            if clickBack then
                --点击
                clickBack(sender)
            end
        end
    end)
end

--[
-- @brief  设置用户头像裁剪
-- @param  headNode 用户头像节点
-- @param  headPath 用户头像路径 默认黑白头像
-- @return void
--]
function Common:setUserHeadCliping(headNode, headPath)
    if not headNode then
        return
    end

    local headCliping = headNode:getChildByName('headCliping')
    if headCliping then
        headCliping:removeFromParent()
    end

    local clipNode = cc.Sprite:create("common/hall_paohuzi_head.png")
    local headsize = headNode:getContentSize()
    local clip_size = clipNode:getContentSize() 
    local clip_node = cc.ClippingNode:create(clipNode)
    clip_node:setScale(headsize.width / clip_size.width, headsize.height / clip_size.height)
    headNode:addChild(clip_node)

    headPath = headPath or "common/hall_avatar.png"
    local realHeadNode = cc.Sprite:create(headPath)
    if realHeadNode == nil then 
        realHeadNode = cc.Sprite:create("common/hall_avatar.png")
    end 
    local head_size = realHeadNode:getContentSize()
    realHeadNode:setScale(clip_size.width / head_size.width, clip_size.height / head_size.height)
    clip_node:addChild(realHeadNode)
    clip_node:setAlphaThreshold(0)
    clip_node:setName('headCliping')
    clip_node:setPosition(headsize.width / 2, headsize.height / 2)
end

--[
-- @brief  十进制IP转换点分字符串
-- @param  intIP 十进制ip
-- @return 点分字符串
--]
function Common:ipint2str(intIP)
    local ret = ""
    local i = 0
    while i < 4 do
        local a = Bit:_and((Bit:_rshift(intIP, i * 8)), 0xFF)
        if i < 3 then
            ret = ret .. a .. '.'
        else
            ret = ret .. a
        end
        i = i + 1
    end
    return ret
end

function Common:playEffect(filename)
    local UserData = require("app.user.UserData")
   -- local volumeSound = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Sound",1)
    if UserData.Music.volumeSound > 0   and UserData.Music.volumeSound <= 1 then

        if cc.FileUtils:getInstance():isFileExist(filename) then
            return cc.SimpleAudioEngine:getInstance():playEffect(filename)
        else
            print('文件不存在',filename)
        end
    end
end

--禁止播放音效
function Common:stopEffect( soundID )
    if soundID then
        cc.SimpleAudioEngine:getInstance():stopEffect(soundID)
    end
end

function Common:playVoice(filename)
    local UserData = require("app.user.UserData")
   -- local volumeVoice = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Voice",1)

    if UserData.Music.volumeVoice > 0  and UserData.Music.volumeVoice <= 1 then
     
        if cc.FileUtils:getInstance():isFileExist(filename) then
            cc.SimpleAudioEngine:getInstance():playEffect(filename)
        else
            print('文件不存在',filename)
        end
    end
end

--语音
function Common:voiceEventTracking(typeName,data )
    if not voiceEventTracking then
        return
    end
    voiceEventTracking(typeName,data) 
end


--- 创建列表TableView
-- @param viewSize list宽高
-- @param itemUpdateCall 子项创建函数
-- @param cellWidth 子项宽
-- @param cellHeight 子项高
-- @param cellCount 子项总数 为空时，调用self._numberOfCellsInTableView获取总数
-- @param cellTouchedCall 子项点击响应函数 call(view, cell)
-- @param direction 方向，默认为纵向
-- @param sliderBar 滚动条
--d
function Common:_createList(viewSize, itemUpdateCall, cellWidth, cellHeight, cellCount, cellTouchedCall, direction, sliderBar, loadData,nodeIndex)
    direction = direction or cc.SCROLLVIEW_DIRECTION_VERTICAL
    if loadData == nil then
        loadData = true
    end
    local listView = cc.TableView:create(viewSize)
    listView:setDirection(direction)
    listView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)

    if nodeIndex then
        listView.nodeIndex = nodeIndex
    end

    local function cellSize(view, index)

        return cellHeight,cellWidth
    end

    local function numberOfCellsInTableView(view)
        return cellCount
    end

    local function numberOfCellsInCellCount()
        return cellCount(nodeIndex)
    end

    local function tableCellAtIndex(view, index)
        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:new()
            local item = itemUpdateCall(index,nil,nodeIndex)
            item:setTag(10)
            cell:addChild(item)
        else
            itemUpdateCall(index, cell:getChildByTag(10),nodeIndex)
        end
        return cell
    end

    local function listScrool(view)
        sliderBar:setValue(-view:getContentOffset().y / (view:getContentSize().height - view:getViewSize().height))
    end

    if cellTouchedCall then
        listView:registerScriptHandler(cellTouchedCall, cc.TABLECELL_TOUCHED)
    end
    if sliderBar and type(sliderBar) ~= "function" then
        listView:registerScriptHandler(listScrool, cc.SCROLLVIEW_SCRIPT_SCROLL)
    elseif sliderBar and type(sliderBar) == "function" then
        listView:registerScriptHandler(sliderBar, cc.SCROLLVIEW_SCRIPT_SCROLL)
    end
    if cellCount then
        if type(cellCount) == "function" then
            listView:registerScriptHandler(numberOfCellsInCellCount, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
        else
            listView:registerScriptHandler(numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
        end
    else
        listView:registerScriptHandler(handler(self, self._numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    end
    listView:registerScriptHandler(cellSize, cc.TABLECELL_SIZE_FOR_INDEX)
    listView:registerScriptHandler(tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)
    listView:setDelegate()
    if loadData then
        listView:reloadData()
    end
    return listView
end

function Common:isInterNumber(srcNum)
    local num = tonumber(srcNum)
    if num then
        if num < 0 or math.floor(num) < num then
            return false
        else
            return true
        end
    else
        return false
    end
end

return Common