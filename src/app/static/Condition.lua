local Condition = {
    --id="用户等级",name="名称",isUseTaijidun="是否使用太极盾",loginIp="登陆服ip",logicIp="逻辑服ip",gameIp="游戏服ip",gameCount="游戏局数",
    [1]={ id=1, name="通用高防", isUseTaijidun=false, taijidunName = "wstfcccthjgm25", loginIp="%s", logicIp="%s", gameIp="%s", gameCount=0}, 
    [2]={ id=2, name="二级专线", isUseTaijidun=false, taijidunName = "", loginIp="middle%s", logicIp="middle%s", gameIp="middle%s", gameCount=100}, 
    [3]={ id=3, name="三级专线", isUseTaijidun=false, taijidunName = "", loginIp="vip%s", logicIp="vip%s", gameIp="vip%s", gameCount=500}
}

return Condition
