cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")
--local breakSocketHandle,debugXpCall = require("LuaDebugjit")("localhost",7003)
require "config"
require "cocos.init"

--渠道ID
cc.exports.CHANNEL_ID = 24

--平台类型整理
--cc.PLATFORM_OS_WINDOWS = 0
--cc.PLATFORM_OS_LINUX   = 1
--cc.PLATFORM_OS_MAC     = 2
--cc.PLATFORM_OS_ANDROID = 3
--cc.PLATFORM_OS_IPHONE  = 4
--cc.PLATFORM_OS_IPAD    = 5
--cc.PLATFORM_OS_BLACKBERRY = 6
--cc.PLATFORM_OS_NACL    = 7
--cc.PLATFORM_OS_EMSCRIPTEN = 8
--cc.PLATFORM_OS_TIZEN   = 9
--cc.PLATFORM_OS_WINRT   = 10
--cc.PLATFORM_OS_WP8     = 11
cc.PLATFORM_OS_APPLE_REAL  = 12   --苹果真机：ipad、iphone等
cc.PLATFORM_OS_DEVELOPER = 13     --开发者模式：mac、windows下

cc.exports.PLATFORM_TYPE = cc.Application:getInstance():getTargetPlatform()
print(cc.PLATFORM_OS_WINDOWS,PLATFORM_TYPE)
if cc.PLATFORM_OS_IPAD == PLATFORM_TYPE or cc.PLATFORM_OS_IPHONE == PLATFORM_TYPE then
    PLATFORM_TYPE = cc.PLATFORM_OS_APPLE_REAL
elseif cc.PLATFORM_OS_WINDOWS == PLATFORM_TYPE or cc.PLATFORM_OS_MAC == PLATFORM_TYPE then
    PLATFORM_TYPE = cc.PLATFORM_OS_DEVELOPER
end

--是否自动开启更新
cc.exports.IS_OPEN_UPDATE = true
if cc.PLATFORM_OS_DEVELOPER == PLATFORM_TYPE then
    IS_OPEN_UPDATE = false
end

cc.exports.CONST_ACCOUNTS = "tanling01"

local searchPaths = cc.FileUtils:getInstance():getSearchPaths()
local path = cc.FileUtils:getInstance():getWritablePath().."huyoo/"
if cc.FileUtils:getInstance():isFileExist(path) == false then
    cc.FileUtils:getInstance():createDirectory(path)
end 
local pathRes = path.."res/"
if cc.FileUtils:getInstance():isFileExist(pathRes) == false then
    cc.FileUtils:getInstance():createDirectory(pathRes)
end 
table.insert(searchPaths,1,pathRes)
local pathSrc = path.."src/"
if cc.FileUtils:getInstance():isFileExist(pathSrc) == false then
    cc.FileUtils:getInstance():createDirectory(pathSrc)
end 
table.insert(searchPaths,1,pathSrc)
cc.FileUtils:getInstance():setSearchPaths(searchPaths)

local function main()
--    require("app.MyApp"):create():run()

    print(collectgarbage("collect"))
    print(collectgarbage("setpause", 100))
    print(collectgarbage("setstepmul", 5000))
    math.randomseed((os.time()) * 1000) 

    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(1334,750,cc.ResolutionPolicy.EXACT_FIT)
    cc.Director:getInstance():setAnimationInterval(1.0/60.0)

    require("StartGame")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
