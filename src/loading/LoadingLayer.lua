local Update = require("loading.Update")
Update:setUpdateParameter()

local LoadingLayer = class("LoadingLayer",function()
    return ccui.Layout:create()
end)

function LoadingLayer:create()
    local view = LoadingLayer.new()
    view:onCreate()
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

function LoadingLayer:onEnter()
    self.scheduleUpdateObj = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(dt) self:update(dt) end, 0 ,false)
end

function LoadingLayer:onExit()
    if self.assetsManagerEx ~= nil then
        self.assetsManagerEx:release()
        self.assetsManagerEx = nil
    end
    if self.assetsManagerExListener ~= nil then
        cc.Director:getInstance():getEventDispatcher():removeEventListener(self.assetsManagerExListener)
        self.assetsManagerExListener = nil
    end
end

function LoadingLayer:onCleanup()

end

function LoadingLayer:onCreate()
    local tableFolder = {
        cc.FileUtils:getInstance():getWritablePath().."huyoo/src/loading",
        "src/loading",
    }
    local searchPaths = cc.FileUtils:getInstance():getSearchPaths()
    for key, var in pairs(tableFolder) do
        table.insert(searchPaths,#searchPaths + 1,var)
    end
    cc.FileUtils:getInstance():setSearchPaths(searchPaths)
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local csb = cc.CSLoader:createNode("LoadingLayer.csb")
    self:addChild(csb)
    self.root = csb:getChildByName("Panel_root")
   
    local Musictype = cc.UserDefault:getInstance():getFloatForKey("UserDefault_Musictype",1)
    local mousic = string.format("achannel/%d/music%d.mp3",CHANNEL_ID,Musictype)
    cc.SimpleAudioEngine:getInstance():playMusic(mousic,true)
    self.uiLoadingBar_pro = ccui.Helper:seekWidgetByName(self.root,"LoadingBar_pro")
    self.uiImage_point = ccui.Helper:seekWidgetByName(self.root,"Image_point")
    self.uiImage_point:setPositionX(0)
    self.uiLoadingBar_pro:setPercent(0) 
    local uiText_updateContens = ccui.Helper:seekWidgetByName(self.root,"Text_updateContens")
    uiText_updateContens:setString("正在检测版本...")
    self:startUpdate()
end


function LoadingLayer:startUpdate()
    if IS_OPEN_UPDATE ~= true then
        self:onEventUpdate(-1)
        return
    end

    local storagePath = cc.FileUtils:getInstance():getWritablePath().."huyoo/"
    self.assetsManagerEx = cc.AssetsManagerEx:create(string.format("version/%d/project.manifest",CHANNEL_ID),storagePath)
    self.assetsManagerEx:retain()
    if self.assetsManagerEx:getLocalManifest():isLoaded() == false then
        self:onEventUpdate(-1)
        return
    end
    self.assetsManagerExListener = cc.EventListenerAssetsManagerEx:create(self.assetsManagerEx,function(event) 
        self:onEventUpdate(event) 
    end)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.assetsManagerExListener,1)
    self.assetsManagerEx:update()
    --设置默认版本为当前版本号
    Update.version = self.assetsManagerEx:getLocalManifest():getVersion()
end

local EventAssetsManagerExEventCode = {
    [0] = "ERROR_NO_LOCAL_MANIFEST",
    [1] = "ERROR_DOWNLOAD_MANIFEST",
    [2] = "ERROR_PARSE_MANIFEST",
    [3] = "NEW_VERSION_FOUND",
    [4] = "ALREADY_UP_TO_DATE",
    [5] = "UPDATE_PROGRESSION",
    [6] = "ASSET_UPDATED",
    [7] = "ERROR_UPDATING",
    [8] = "UPDATE_FINISHED",
    [9] = "UPDATE_FAILED",
    [10] = "ERROR_DECOMPRESS",
    [11] = "PROMPTED_TO_UPDATE",
    [12] = "PROMPTED_TO_INSTALL",
}

function LoadingLayer:onEventUpdate(event)
    if event == -1 then
        self.proValue = 100
        return
    end
    local code = event:getEventCode()
    local codeString = EventAssetsManagerExEventCode[code]
    local assetId = event:getAssetId()
    local percent = event:getPercent()
    local percentByFile = event:getPercentByFile()
    local message = event:getMessage()
    printInfo("游戏更新("..codeString.."):".."      assetId"..assetId.."      percent"..percent.."      percentByFile"..percentByFile.."      message"..message)
    
    if codeString == "ERROR_NO_LOCAL_MANIFEST" then
        self.proValue = 100
        local uiText_updateContens = ccui.Helper:seekWidgetByName(self.root,"Text_updateContens")
        uiText_updateContens:setString("检测失败,请检测网络.")
    elseif codeString == "ERROR_DOWNLOAD_MANIFEST" then
        self.proValue = 100
        local uiText_updateContens = ccui.Helper:seekWidgetByName(self.root,"Text_updateContens")
        uiText_updateContens:setString("检测失败,请检测网络.")
    elseif codeString == "NEW_VERSION_FOUND" then
        Update.newVersion = self.assetsManagerEx:getRemoteManifest():getVersion()
        Update.updateConten = self.assetsManagerEx:getRemoteManifest():getUpdateContent()
        printInfo("发现新版本"..Update.newVersion)
    elseif codeString == "ALREADY_UP_TO_DATE" then
        self.proValue = 100
        local uiText_updateContens = ccui.Helper:seekWidgetByName(self.root,"Text_updateContens")
        uiText_updateContens:setString("已是最新版本,正在加载游戏...")
    elseif codeString == "UPDATE_PROGRESSION" then
        if assetId == "@version" then        
        elseif assetId ==  "@manifest" then
        elseif assetId == "@batch_install" then
        else
            self.proValue = percentByFile
            --还有一个安装过程
            if self.proValue >= 100 then
                self.proValue = 99
            end
        end
        
    elseif codeString == "ERROR_UPDATING" then
        if self.errorCount == nil then
            self.errorCount = 0
        end
        self.errorCount = self.errorCount + 1
        printInfo(string.format("下载单个文件失败：%d",self.errorCount))
        
    elseif codeString == "UPDATE_FAILED" then
        if self.failedCount == nil then
            self.failedCount = 0
        end
        printInfo(string.format("下载文件失败：",self.errorCount))
        if self.errorCount > 20 or self.failedCount >= 3 then
            self.proValue = 100
            local uiText_updateContens = ccui.Helper:seekWidgetByName(self.root,"Text_updateContens")
            uiText_updateContens:setString("更新失败,请检测网络.")
        else
            self.failedCount = self.failedCount + 1
            self.errorCount = 0
            self.assetsManagerEx:downloadFailedAssets()
        end
        self.assetsManagerEx:downloadFailedAssets()
    elseif codeString == "PROMPTED_TO_UPDATE" then
        local currentVersion = self.assetsManagerEx:getLocalManifest():getVersion()
        local newVersion = self.assetsManagerEx:getRemoteManifest():getVersion()
        --设置默认版本为当前版本号
        Update.version = self.assetsManagerEx:getLocalManifest():getVersion()
        local newVersionSDK = string.sub(newVersion,1,3)
        local uiText_updateContens = ccui.Helper:seekWidgetByName(self.root,"Text_updateContens")
        if PLATFORM_TYPE ~= cc.PLATFORM_OS_DEVELOPER and newVersionSDK ~= Update.versionSDK then
            --开发模式下面是没有SDK版本，所以默认相同
            printInfo(string.format("SDK版本不一致跳过更新：versionSDK = %s , newVersion = %s",Update.versionSDK,newVersionSDK))
            self.proValue = 100
            if newVersionSDK < Update.versionSDK then
                uiText_updateContens:setString("已是最新版本,正在加载游戏...")
            else
                uiText_updateContens:setString("更新失败.")
            end
            return
        end
        if currentVersion > newVersion then
            --当前版本号比新版本号要搞，则跳过更新
            printInfo(string.format("服务器版本太低：currentVersion = %s , newVersion = %s",currentVersion,newVersion))
            self.proValue = 100
            uiText_updateContens:setString("已是最新版本,正在加载游戏...")
            return
        end
        if IS_OPEN_UPDATE == false then
            printInfo(string.format("更新被关闭了：currentVersion = %s , newVersion = %s",currentVersion,newVersion))
            self.proValue = 100
            uiText_updateContens:setString("更新被强制关闭.")
            return
        end
        printInfo("开始更新!")
        uiText_updateContens:setString(string.format("最新版本:%s.%d,正在更新...",Update.newVersion,CHANNEL_ID))
        self.assetsManagerEx:startUpdate()
        Update.isLuaUpdated = true
        
    elseif codeString == "PROMPTED_TO_INSTALL" then
        self.assetsManagerEx:updateSucceed()
        
    elseif codeString == "UPDATE_FINISHED" then
        Update.version = Update.newVersion
        printInfo(string.format("==================更新完毕%s=================",Update.version))
        self.proValue = 100
    else
        
    end
    
end

function LoadingLayer:update(dt)
    if self.delayTime == nil then
        self.delayTime = 0
    end
    if self.proValue == nil then
        self.proValue = 0
    end
    self.delayTime = self.delayTime + dt
    local pro = self.uiLoadingBar_pro:getPercent()
    if pro < self.proValue then
        pro = pro + 3
        if pro > self.proValue then
            pro = self.proValue
        end
        self.delayTime = 0
    elseif self.delayTime > 5 and pro < 99 then
        pro = pro + 0.01
        self.delayTime = 0
    else

    end
    self.uiImage_point:setPositionX(pro/100*self.uiImage_point:getParent():getContentSize().width)
    self.uiLoadingBar_pro:setPercent(pro)
    if pro >= 100 and self.proValue >= 100 then
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(0),
            cc.CallFunc:create(function(sender,event) 
                if self.scheduleUpdateObj then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleUpdateObj)
                    self.scheduleUpdateObj = nil
                end
                require("EnterGame")
            end)
        ))
    end
end

return LoadingLayer

