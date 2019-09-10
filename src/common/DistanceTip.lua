
--距离提示判断
local Common = require("common.Common")
local StaticData = require("app.static.StaticData")
local DistanceTip = {}
local GameCommon = nil
function DistanceTip:checkDis( wKindID )
    local distance = nil
    local isShowDisAlarm = false

    if StaticData.Games[wKindID].type == 1 then
        GameCommon = require("game.paohuzi.GameCommon")
    elseif StaticData.Games[wKindID].type == 2 then
        GameCommon = require("game.puke.PDKGameCommon")   
        if wKindID == 84 then 
            GameCommon = require("game.puke.DDZGameCommon")
        elseif wKindID == 85 then
            GameCommon = require("game.puke.SDHGameCommon")
        end
    elseif StaticData.Games[wKindID].type == 3 then  
        GameCommon = require("game.majiang.GameCommon")
    else
        return
    end

    for wChairID = 0, 3 do
        if GameCommon.player[wChairID] ~= nil then        
           if GameCommon.player[wChairID].location.x < 0.1 then
                isShowDisAlarm = true
                break
           else
                for wTargetChairID = wChairID+1, GameCommon.gameConfig.bPlayerCount-1 do
                    if GameCommon.player[wTargetChairID].location.x > 0.1 then
                        local desc = nil                         
                        desc = GameCommon:GetDistance(GameCommon.player[wChairID].location,GameCommon.player[wTargetChairID].location)                                     
                        if desc~= nil and desc < 500 then
                            isShowDisAlarm = true
                            break
                        end
                    end 
                end
            end
        end
    end
    if isShowDisAlarm then
       -- require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(true):createGame("game.majiang.KwxLocationLayer"))
        require("common.PositionLayer"):create(GameCommon.tableConfig.wKindID)
    end
end

return DistanceTip