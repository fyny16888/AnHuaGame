
--距离提示判断
local Common = require("common.Common")
local DistanceTip = {}
local GameCommon = require("game.majiang.GameCommon") 
function DistanceTip:checkDis( isDistance )
    local distance = nil
    local isShowDisAlarm = false
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
        require("common.SceneMgr"):switchOperation(require("app.MyApp"):create(true):createGame("game.majiang.KwxLocationLayer"))
    end
end

return DistanceTip