--场景管理器
cc.exports.SceneMgr = {}
cc.exports.SCENE_LOGIN = 1
cc.exports.SCENE_HALL = 2
cc.exports.SCENE_GAME = 3

SceneMgr.sceneName = nil

function SceneMgr:switchScene(node, sceneName)
    if sceneName >= 1 and sceneName <= 3 then
        local scene = cc.Director:getInstance():getRunningScene()
        scene:removeAllChildren()
        scene:addChild(node,LAYER_SCENE,LAYER_SCENE)
        self.sceneName = sceneName
    end
end

function SceneMgr:switchOperation(node)
    local scene = cc.Director:getInstance():getRunningScene()
    local proNode = scene:getChildByTag(LAYER_OPERATION)
    if proNode ~= nil then
--        if proNode.root then
--            proNode.root:setScale(1)
--            proNode.root:runAction(cc.ScaleTo:create(0.2,0))
--            proNode:runAction(cc.Sequence:create(cc.DelayTime:create(0.2),cc.RemoveSelf:create()))
--        else
            proNode:removeFromParent()
--        end
    end
    if node then
        scene:addChild(node,LAYER_OPERATION,LAYER_OPERATION)
--        if node.root then
--            node.root:setScale(0)
--            node.root:ignoreAnchorPointForPosition(false)
--            node.root:setAnchorPoint(cc.p(0.5,0.5))
--            node.root:runAction(cc.Sequence:create(cc.EaseBackOut:create(cc.ScaleTo:create(0.3,1))))
--        end
    end

    
end

function SceneMgr:switchTips(node)
    local scene = cc.Director:getInstance():getRunningScene()
    scene:removeChildByTag(LAYER_TIPS)
    if node then
        scene:addChild(node,LAYER_TIPS,LAYER_TIPS)
    end
end

function SceneMgr:switchGlobal(node)
    local scene = cc.Director:getInstance():getRunningScene()
    scene:removeChildByTag(LAYER_GLOBAL)
    scene:addChild(node,LAYER_GLOBAL,LAYER_GLOBAL)
end

function SceneMgr:switchHallReconnect(node)
    local scene = cc.Director:getInstance():getRunningScene()
    scene:removeChildByTag(LAYER_RECONNECT)
    scene:addChild(node,LAYER_RECONNECT,LAYER_RECONNECT)
end

function SceneMgr:switchGameReconnect(node)
    local scene = cc.Director:getInstance():getRunningScene()
    scene:removeChildByTag(LAYER_SCENE)
    scene:removeChildByTag(LAYER_OPERATION)
    scene:removeChildByTag(LAYER_TIPS)
    scene:removeChildByTag(LAYER_GLOBAL)
    scene:removeChildByTag(LAYER_RECONNECT)
    scene:addChild(node,LAYER_RECONNECT,LAYER_RECONNECT)
end

return SceneMgr