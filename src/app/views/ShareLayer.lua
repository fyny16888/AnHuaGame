local Common = require("common.Common")
local UserData = require("app.user.UserData")
local Bit = require("common.Bit")
local  HttpUrl = require("common.HttpUrl")
local ShareLayer = class("ShareLayer", cc.load("mvc").ViewBase)

function ShareLayer:onEnter()
    self.interval = 0
end

function ShareLayer:onExit()

end

function ShareLayer:onCleanup()

end

function ShareLayer:onCreate(params)
    local shareData = params[1]
    local callback = params[2]
    if shareData == nil then
        require("common.MsgBoxLayer"):create(0,nil,"分享配置错误!")
        return
    end
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("ShareLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
    
    Common:addTouchEventListener(self.root,function() 
        require("common.SceneMgr"):switchTips()
    end,true)

    local Button_close = ccui.Helper:seekWidgetByName(self.root,"Button_close")
    Common:addTouchEventListener(Button_close,function() 
        self:removeFromParent()
    end)
    
    local function onEventShare(cbTargetType)
        local data = clone(shareData)
        data.cbTargetType = cbTargetType
        if cbTargetType == 64 then
            local szShareUrl = clone(UserData.Share.tableShareParameter[8].szShareUrl)
            szShareUrl = string.format(szShareUrl, shareData.szGameID)
            local xmlHttpRequest = cc.XMLHttpRequest:new()
            xmlHttpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
            xmlHttpRequest:setRequestHeader("Content-Type", "application/json; charset=utf-8")
            xmlHttpRequest:open("GET",szShareUrl)
            local function onHttpRequestCompleted()
                if xmlHttpRequest.status == 200 then
                    if tonumber(xmlHttpRequest.response)  == 1 then
                        require("common.MsgBoxLayer"):create(0,nil,"发送成功！")
                    else
                        require("common.MsgBoxLayer"):create(0,nil,string.format("发送失败,错误码:%d",xmlHttpRequest.response))--string.format("发送失败,错误码:%d",xmlHttpRequest.response) .. xmlHttpRequest.response
                    end
                else
                    
                end
            end
            xmlHttpRequest:registerScriptHandler(onHttpRequestCompleted)
            xmlHttpRequest:send()
            return
        end
        require("common.LoadingAnimationLayer"):create(0.3)
        UserData.Share:doShare(data)
    end
    
    local isInClub = shareData.isInClub;
    local uiListView_btn = ccui.Helper:seekWidgetByName(self.root,"ListView_btn")
    for i = 0, 6 do
        if Bit:_and((Bit:_rshift(shareData.cbTargetType,i)),1) == 1 then
            print('-->>>>',i);
            if i ~= 3 then
                if i == 6 and (not isInClub) then--不在俱乐部不显示6
                    
                else
                    local btnName = string.format("newshare/newshare_%d.png",i)
                    local item = ccui.Button:create(btnName,btnName,btnName)  
                    local uitext = nil 
                    if i == 0 then 
                        uitext = ccui.Text:create("朋友圈","fonts/DFYuanW7-GB2312.ttf",30)
                    elseif i == 1 then 
                        uitext = ccui.Text:create("微信好友","fonts/DFYuanW7-GB2312.ttf",30)
                    elseif i == 2 then 
                        uitext = ccui.Text:create("闲聊","fonts/DFYuanW7-GB2312.ttf",30)
                    elseif i == 3 then 
                        uitext = ccui.Text:create("聊天室","fonts/DFYuanW7-GB2312.ttf",30)
                    elseif i == 4 then 
                        uitext = ccui.Text:create("战绩链接","fonts/DFYuanW7-GB2312.ttf",30)
                    elseif i == 5 then
                        uitext = ccui.Text:create("邀请在线好友","fonts/DFYuanW7-GB2312.ttf",30)
                    elseif i == 6 then
                        uitext = ccui.Text:create("聊天室","fonts/DFYuanW7-GB2312.ttf",30)
                    end 
                    uitext:setVisible(false)
                    uitext:setTextColor(cc.c3b(118,63,25))              
                    item:addChild(uitext)
                    uitext:setPosition(uitext:getParent():getContentSize().width/2,-30)
                    uiListView_btn:pushBackCustomItem(item)
                    item.cbTargetType = Bit:_lshift(1,i)
                    Common:addTouchEventListener(item,function() 
                        if i == 5 then
                            if callback then
                                self:removeFromParent()
                                callback()
                            end
                        else
                            onEventShare(item.cbTargetType)
                        end
                    end)
                end
            end
        end
    end
    
    local items = uiListView_btn:getItems()
    if #items <= 0 then
        require("common.MsgBoxLayer"):create(0,nil,"分享配置错误!")
        return
    elseif #items == 1 then
        local item = items[1]
        Common:addTouchEventListener(item,onEventShare(item.cbTargetType))
    else
        local uiPanel_contents = ccui.Helper:seekWidgetByName(self.root,"Panel_contents")
        local margin = (uiPanel_contents:getContentSize().width-items[1]:getContentSize().width*#items)/(#items+1) + 60
        uiListView_btn:refreshView()
        uiListView_btn:setItemsMargin(margin)--间距
        uiListView_btn:setContentSize(cc.size(items[1]:getContentSize().width*#items + margin*(#items-1) ,uiPanel_contents:getContentSize().height))
        -- uiListView_btn:setPositionX((uiPanel_contents:getContentSize().width - uiListView_btn:getContentSize().width)/2 + 10)
        uiListView_btn:setPositionX(uiPanel_contents:getContentSize().width / 2)
        require("common.SceneMgr"):switchTips(self)    
    end
end


return ShareLayer

