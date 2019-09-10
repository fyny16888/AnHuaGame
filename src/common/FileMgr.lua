--目录定义
cc.exports.FileDir = {}
FileDir.dirRoot             = cc.FileUtils:getInstance():getWritablePath().."huyoo/"  --根目录
FileDir.dirTemp             = FileDir.dirRoot.."temp/"          --临时目录,不重要的资源
FileDir.dirRes              = FileDir.dirRoot.."res/"           --从服务器下载下来的资源目录
FileDir.dirDownload         = FileDir.dirRoot.."download/"      --从服务器下载下来的目录
FileDir.dirVoice            = FileDir.dirRoot.."voice/"         --语音文件保存目录
FileDir.dirBattlefield      = FileDir.dirRoot.."battlefield/"   --战报目录

--文件夹创建
for key, var in pairs(FileDir) do
    if cc.FileUtils:getInstance():isFileExist(var) ~= true then
        if cc.FileUtils:getInstance():createDirectory(var) then
            printInfo("FileMgr:文件创建成功!"..var)
        else
            printInfo("FileMgr:文件创建失败!"..var)
        end
    end 
end

--文件定义
cc.exports.FileName = {}
FileName.screenshot = FileDir.dirTemp.."last_screenshot.jpg"
FileName.lastLoginData = FileDir.dirTemp.."lastLoginData.json"
FileName.battlefieldScreenshot = FileDir.dirTemp.."battlefield_screenshot.jpg"
FileName.loginData = FileDir.dirTemp.."logindata.json"
FileName.talbeCommonGames = FileDir.dirTemp.."talbeCommonGames.json"
FileName.tableUserRecord = FileDir.dirTemp.."tableUserRecord.json"
FileName.tableCreateParameter = FileDir.dirTemp.."tableCreateParameter%d.json"
FileName.phzPAI = FileDir.dirTemp.."phzPAI.ini"
FileName.tableLastUseClubRecord = FileDir.dirTemp.."tableLastUseClubRecord.json"
