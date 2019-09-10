--游戏逻辑处理
local Bit = require("common.Bit")
local GameLogic = {}

--对手上的牌进行排序
function GameLogic:SortCardList(cbCardData,cbCardCount,cbSortType)
	if cbCardCount == 0 then  --牌数为0返回
	   return
	end
	local cbSortValue = {}
    for i=1,cbCardCount do
        if cbCardData[i]~= nil then 
            cbSortValue[i] = self:GetCardLogicValue(cbCardData[i])  --将自己的牌组中的牌转换成原子后放到数组中
        end 
	end
	local bSorted = false
	local cbThreeCount = 0
	local cbLast = cbCardCount - 1
	repeat
		bSorted = true
		for i=1,cbLast do
            --如果第一张牌小于第二张牌,或者花色也小于
            if cbSortValue[i]~= nil and  cbSortValue[i+1] ~= nil then 
                if (cbSortValue[i]<cbSortValue[i+1] or ((cbSortValue[i]==cbSortValue[i+1]) and (cbCardData[i]<cbCardData[i+1]))) then
                    cbThreeCount = cbCardData[i]
                    cbCardData[i] = cbCardData[i+1]
                    cbCardData[i+1] = cbThreeCount  --自己的牌组换位置
                    cbThreeCount = cbSortValue[i]
                    cbSortValue[i] = cbSortValue[i+1]
                    cbSortValue[i+1] = cbThreeCount  --复制的牌组换位置
                    bSorted = false
                end
            end 
		end
		cbLast = cbLast - 1
	until (bSorted==true)
	
	--数目排序
	if cbSortType == 1 then
	   --分析扑克
	   local cbIndex = 1
	   local AnalyseResult = self:AnalysebCardData(cbCardData,cbCardCount,false)
	   
	   --拷贝四牌
	   for i=1,AnalyseResult.cbFourCount*4 do
            cbCardData[cbIndex] = AnalyseResult.cbFourCardData[i]
            cbIndex = cbIndex + 1
	   end
	   
	   --拷贝三牌
	   for i=1,AnalyseResult.cbThreeCount*3 do
            cbCardData[cbIndex] = AnalyseResult.cbThreeCardData[i]
            cbIndex = cbIndex + 1
	   end
	   --拷贝对牌
        for i=1,AnalyseResult.cbDoubleCount*2 do
            cbCardData[cbIndex] = AnalyseResult.cbDoubleCardData[i]
            cbIndex = cbIndex + 1
        end
        
        --拷贝单牌
        for i=1,AnalyseResult.cbSignedCount do
            cbCardData[cbIndex] = AnalyseResult.cbSignedCardData[i]
            cbIndex = cbIndex + 1
        end
	end
end

--逻辑数值
function GameLogic:GetCardLogicValue(cbCardData)
    --扑克属性
    local cbCardColor = Bit:_and(cbCardData,0xf0)
    local cbCardValue = Bit:_and(cbCardData,0x0f)
    
    --转换数值
    if cbCardColor == 0x40 then
        cbCardValue = cbCardValue+2
    end
    if cbCardValue <= 2 then
        cbCardValue = cbCardValue+13
    end
    return cbCardValue
end

--分析扑克,按照4个相同的牌,3个相同的牌,2个相同的牌,1个牌 分类
function GameLogic:AnalysebCardData(cbCardData,cbCardCount,bFlag)
    local tmpCbCardData = {}  --复制一套临时的牌
    print("cbCardCount",cbCardCount)
    for i=1,cbCardCount do
        tmpCbCardData[i] = cbCardData[i]
    end
    --for i=1,cbCardCount do
    --    print("tmpCbCardData",tmpCbCardData[i])
    --end
	local AnalyseResult = {}
	AnalyseResult.cbSignedCount = 0
	AnalyseResult.cbDoubleCount = 0
	AnalyseResult.cbThreeCount = 0
	AnalyseResult.cbFourCount = 0
	AnalyseResult.cbSignedCardData = {}
	AnalyseResult.cbDoubleCardData = {}
	AnalyseResult.cbThreeCardData = {}
	AnalyseResult.cbFourCardData = {}
	for i=1,cbCardCount do
        if tmpCbCardData[i] ~= -1 then
            local cbSameCount = 1  --相同牌个数
            local cbCardValueTemp = 0  --临时牌值
            local cbLogicValue = self:GetCardLogicValue(tmpCbCardData[i])
            --print("牌",tmpCbCardData[i],cbLogicValue)
            --搜索同牌
            for j=i+1,cbCardCount do
                --获取扑克,不等于-1,而且牌相等
                if tmpCbCardData[j] ~= -1 and self:GetCardLogicValue(tmpCbCardData[j]) == cbLogicValue then
                    cbSameCount = cbSameCount + 1
                    --print("相同的牌",tmpCbCardData[j],cbLogicValue)
                end
            end
            --print("cbSameCount",cbSameCount)
            if cbSameCount == 1 then --如果是单牌
                local cbIndex = AnalyseResult.cbSignedCount
                AnalyseResult.cbSignedCount = AnalyseResult.cbSignedCount + 1
                AnalyseResult.cbSignedCardData[cbIndex*cbSameCount+1] = tmpCbCardData[i]
                tmpCbCardData[i] = -1
            elseif cbSameCount == 2 then
                local cbIndex = AnalyseResult.cbDoubleCount
                AnalyseResult.cbDoubleCount = AnalyseResult.cbDoubleCount + 1
                AnalyseResult.cbDoubleCardData[cbIndex*cbSameCount+1] = tmpCbCardData[i]
                AnalyseResult.cbDoubleCardData[cbIndex*cbSameCount+2] = tmpCbCardData[i+1]
                tmpCbCardData[i] = -1
                tmpCbCardData[i+1] = -1
            elseif cbSameCount == 3 then
                if bFlag then
                    local cbIndex = AnalyseResult.cbDoubleCount
                    AnalyseResult.cbDoubleCount = AnalyseResult.cbDoubleCount + 1
                    AnalyseResult.cbDoubleCardData[cbIndex*2+1] = tmpCbCardData[i]
                    AnalyseResult.cbDoubleCardData[cbIndex*2+2] = tmpCbCardData[i+1]
                    tmpCbCardData[i] = -1
                    tmpCbCardData[i+1] = -1
                else
                    local cbIndex = AnalyseResult.cbThreeCount
                    AnalyseResult.cbThreeCount = AnalyseResult.cbThreeCount + 1
                    AnalyseResult.cbThreeCardData[cbIndex*cbSameCount+1] = tmpCbCardData[i]
                    AnalyseResult.cbThreeCardData[cbIndex*cbSameCount+2] = tmpCbCardData[i+1]
                    AnalyseResult.cbThreeCardData[cbIndex*cbSameCount+3] = tmpCbCardData[i+2]
                    tmpCbCardData[i] = -1
                    tmpCbCardData[i+1] = -1
                    tmpCbCardData[i+2] = -1
                end
            elseif cbSameCount == 4 then
                --print("进入4牌",tmpCbCardData[i],tmpCbCardData[i+1],tmpCbCardData[i+2],tmpCbCardData[i+3])
                local cbIndex = AnalyseResult.cbFourCount
                AnalyseResult.cbFourCount = AnalyseResult.cbFourCount + 1
                AnalyseResult.cbFourCardData[cbIndex*cbSameCount+1] = tmpCbCardData[i]
                AnalyseResult.cbFourCardData[cbIndex*cbSameCount+2] = tmpCbCardData[i+1]
                AnalyseResult.cbFourCardData[cbIndex*cbSameCount+3] = tmpCbCardData[i+2]
                AnalyseResult.cbFourCardData[cbIndex*cbSameCount+4] = tmpCbCardData[i+3]
                tmpCbCardData[i] = -1
                tmpCbCardData[i+1] = -1
                tmpCbCardData[i+2] = -1
                tmpCbCardData[i+3] = -1
                --for i=1,#AnalyseResult.cbFourCardData do
                --    print("AnalyseResult.cbFourCardData",AnalyseResult.cbFourCardData[i])
                --end
            end
	   end
	end
    return AnalyseResult
end

--新的一轮到自己出牌
function GameLogic:getNewFreshOutCardData(cbHandCardData,cbHandCardCount,AnalyseResult)
    if cbHandCardCount <= 0 then
        return false,{}
    end
    local OutCardResult = {}
    OutCardResult.cbCardCount = 0
    OutCardResult.cbResultCard = {}
   
    local ret = true
    local off = -4  --偏移是4,因为碰到炸弹不主动出,除非没牌了
    local tmpcount = cbHandCardCount
    while ret do
        off = off + 4
        tmpcount = tmpcount - off
        if tmpcount > 0 then  --序列大于0才行,因为是数组
            local minCard = cbHandCardData[tmpcount]  --取自己牌右边最小的牌
            if AnalyseResult.cbSignedCount > 0 and OutCardResult.cbCardCount == 0 then  --单张数组
                for i=1,AnalyseResult.cbSignedCount do
                    if AnalyseResult.cbSignedCardData[i] == minCard then
                        OutCardResult.cbResultCard[1] = minCard
                        OutCardResult.cbCardCount = 1
                        print("新一轮自动找出牌1","个数",OutCardResult.cbCardCount,"牌",OutCardResult.cbResultCard[1])
                        ret = false
                        break
                    end
                end
            end
            if AnalyseResult.cbDoubleCount > 0 and OutCardResult.cbCardCount == 0 then  --对子数组
                for i=1,AnalyseResult.cbDoubleCount*2 do
                    if AnalyseResult.cbDoubleCardData[i] == minCard then
                        local mogic = i%2
                        if mogic == 0 then
                            mogic = 2
                        end
                        local index = i-mogic+1
                        OutCardResult.cbResultCard[1] = AnalyseResult.cbDoubleCardData[index]
                        OutCardResult.cbResultCard[2] = AnalyseResult.cbDoubleCardData[index+1]
                        OutCardResult.cbCardCount = 2
                        print("index",index,i)
                        for k=1,AnalyseResult.cbDoubleCount*2 do
                            print("牌",AnalyseResult.cbDoubleCardData[k])
                        end
                        print("新一轮自动找出牌2","个数",OutCardResult.cbCardCount,"牌",OutCardResult.cbResultCard[1],OutCardResult.cbResultCard[2])
                        ret = false
                        break
                    end
                end
            end
            if AnalyseResult.cbThreeCount > 0 and OutCardResult.cbCardCount == 0 then --三个数组
                for i=1,AnalyseResult.cbThreeCount*3 do
                    if AnalyseResult.cbThreeCardData[i] == minCard then
                        local mogic = i%3
                        if mogic == 0 then
                            mogic = 3
                        end
                        local index = i-mogic+1 
                        OutCardResult.cbResultCard[1] = AnalyseResult.cbThreeCardData[index]
                        OutCardResult.cbResultCard[2] = AnalyseResult.cbThreeCardData[index+1]
                        OutCardResult.cbResultCard[3] = AnalyseResult.cbThreeCardData[index+2]
                        OutCardResult.cbCardCount = 3
                        if AnalyseResult.cbSignedCount >= 2 then --单牌里有两个单牌
                            OutCardResult.cbResultCard[4] = AnalyseResult.cbSignedCardData[AnalyseResult.cbSignedCount]
                            OutCardResult.cbResultCard[5] = AnalyseResult.cbSignedCardData[AnalyseResult.cbSignedCount-1]
                            OutCardResult.cbCardCount = 3+2
                        elseif AnalyseResult.cbDoubleCount >= 1 then --对子组里面有至少一对
                            OutCardResult.cbResultCard[4] = AnalyseResult.cbDoubleCardData[AnalyseResult.cbDoubleCount*2]
                            OutCardResult.cbResultCard[5] = AnalyseResult.cbDoubleCardData[AnalyseResult.cbDoubleCount*2-1]
                            OutCardResult.cbCardCount = 3+2
                        end
                        print("index",index)
                        for k=1,AnalyseResult.cbThreeCount*3 do
                            print("牌",AnalyseResult.cbThreeCardData[k])
                        end
                        print("新一轮自动找出牌3","个数",OutCardResult.cbCardCount,"牌",OutCardResult.cbResultCard[1],OutCardResult.cbResultCard[2],OutCardResult.cbResultCard[3],OutCardResult.cbResultCard[4],OutCardResult.cbResultCard[5])
                        ret = false
                        break
                    end
                end
            end
        else
            ret = false
        end   
    end  --while 结束
    
    --如果只找到3张牌,但是三个头不能出,所以只出右边第一张牌
    if OutCardResult.cbCardCount == 3 then
        OutCardResult.cbCardCount = 1
        OutCardResult.cbResultCard[1] = cbHandCardData[cbHandCardCount]
    end
    
    --这个时候还没有出牌数据表示家里只有炸弹了,0表示没找到牌,
    if OutCardResult.cbCardCount == 0 then  
        if cbHandCardCount >= 4 then
            tmpcount = cbHandCardCount - 4 + 1
            OutCardResult.cbCardCount = 4
            OutCardResult.cbResultCard[1] = cbHandCardData[tmpcount]
            OutCardResult.cbResultCard[2] = cbHandCardData[tmpcount+1]
            OutCardResult.cbResultCard[3] = cbHandCardData[tmpcount+2]
            OutCardResult.cbResultCard[4] = cbHandCardData[tmpcount+2]
            print("新一轮自动找出牌4","个数",OutCardResult.cbCardCount,"牌",OutCardResult.cbResultCard[1],OutCardResult.cbResultCard[2],OutCardResult.cbResultCard[3],OutCardResult.cbResultCard[4])
        elseif cbHandCardCount >= 1 then  --就设置一张牌
            OutCardResult.cbCardCount = 1
            OutCardResult.cbResultCard[1] = cbHandCardData[cbHandCardCount]
        else
            return false,OutCardResult
        end
    end
    return true,OutCardResult
end

--出牌搜索,查找可以出的牌
function GameLogic:SearchOutCard(cbHandCardData,cbHandCardCount,cbTurnCardData,cbTurnCardCount,OutCardResult)
    print("开始找牌")
    
--    local OutCardResult = {}
--    OutCardResult.cbResultCard = {}
	local cbCardData = {}  --构造扑克
	local cbCardCount = cbHandCardCount
	for i=1,cbHandCardCount do
	   cbCardData[i] = cbHandCardData[i]
	end
	
	--排列扑克
    self:SortCardList(cbCardData,cbCardCount,0)

    
    --获取上家出牌的类型,单牌,对子,三带二等等
    local cbTurnOutType = self:GetCardType(cbTurnCardData,cbTurnCardCount)
    --出牌分析
    if cbTurnOutType == 0 then  --上家牌类型为0表示是错误的牌 
        return false
    end
    
    --手上的牌进行分类
    local AnalyseResultAll = self:AnalysebCardData(cbCardData,cbCardCount,false)
    local AnalyseTurnResult = self:AnalysebCardData(cbTurnCardData,cbTurnCardCount,false)  --分析下上家牌,提出3个头出来,上面GetCardType的类型已经判断了能不能连在一起
    --先看看能不能一把出牌
--    if self:GetCardType(cbCardData,cbCardCount,true) ~= 0 then  --自己手上全部的牌可以一把出
--        print("手上牌可以一把出,上家牌类型",cbTurnOutType,"上家牌个数",cbTurnCardCount)
--        local selfRet,self3lianMaxCard = self:isSanzhangLian(AnalyseResultAll.cbThreeCardData,AnalyseResultAll.cbThreeCount)  --取得自己的牌中飞机的最大牌,魔术值,比如,999777666 ,取得7
--        local trunRet,trun3lianMaxCard = self:isSanzhangLian(AnalyseTurnResult.cbThreeCardData,AnalyseTurnResult.cbThreeCount)  --取得上家牌中飞机的最大牌
--        if cbTurnOutType == 6 and cbTurnCardCount == 5 then  --如果上家的是三带二,而且出牌数为5张,因为是单张,直接判断
--            if AnalyseResultAll.cbThreeCount == 1 and AnalyseTurnResult.cbThreeCount == 1 and self:GetCardLogicValue(AnalyseResultAll.cbThreeCardData[1]) > self:GetCardLogicValue(AnalyseTurnResult.cbThreeCardData[1]) then  --因为是最后一把牌,
--                OutCardResult.cbCardCount = cbCardCount
--                for i=1,cbCardCount do
--                    OutCardResult.cbResultCard[i] = cbCardData[i]
--                end
--                return true
--            end
--        elseif cbTurnOutType == 9 and cbTurnCardCount == 10  then  --上家牌是双连三带二,出牌数必须为10
--            --手牌的飞机判断在GetCardType已经判断了,因为是最后一把牌
--            if AnalyseResultAll.cbThreeCount == 2 and AnalyseTurnResult.cbThreeCount == 2 and selfRet and trunRet and self3lianMaxCard > trun3lianMaxCard then  --因为是最后一把牌,
--                OutCardResult.cbCardCount = cbCardCount
--                for i=1,cbCardCount do
--                    OutCardResult.cbResultCard[i] = cbCardData[i]
--                end
--                return true
--            end
--        elseif cbTurnOutType == 9 and cbTurnCardCount == 15 then  --上家牌是三连三带二,出牌数必须为15  总牌数就是为15
--            local AnalyseTurnResult = self:AnalysebCardData(cbTurnCardData,cbTurnCardCount,false)  --分析下上家牌,提出3个头出来,已经判断了能不能连在一起
--            --手牌的飞机判断在GetCardType已经判断了,因为是最后一把牌
--            if AnalyseResultAll.cbThreeCount == 3 and AnalyseTurnResult.cbThreeCount == 3 and selfRet and trunRet and self3lianMaxCard > trun3lianMaxCard then  --因为是最后一把牌,
--                OutCardResult.cbCardCount = cbCardCount
--                for i=1,cbCardCount do
--                    OutCardResult.cbResultCard[i] = cbCardData[i]
--                end
--                return true
--            end
--        end
--    end
--    print("手上牌不能一把出")
    
    if cbTurnOutType == 1 then   --单牌类型
        --获取上家牌的最大的值,然后在自己的牌里找比它大的
        local cbLogicValue = self:GetCardLogicValue(cbTurnCardData[1]) --上家牌最大的
        --分析自己的牌,将单,双,三,四分组
        local AnalyseResult = self:AnalysebCardData(cbCardData,cbCardCount,false)
        
        --优先寻找单牌
        for i=1,AnalyseResult.cbSignedCount do  --单牌个数
            local cbIndex = AnalyseResult.cbSignedCount - (i - 1) --从最小的单牌开始计算
            if self:GetCardLogicValue(AnalyseResult.cbSignedCardData[cbIndex]) > cbLogicValue then  --自己的单牌大于上家的单牌
                --设置结果
                OutCardResult.cbCardCount = 1 --上家单牌个数
                OutCardResult.cbResultCard[1] = AnalyseResult.cbSignedCardData[cbIndex] --单牌直接复制
                return true
            end
        end
        
        --全部查找,如果自己没有单牌,则从整体数组里找,不用管对子,三个,四个
        for i=1,cbCardCount do
            if self:GetCardLogicValue(cbCardData[cbCardCount-(i-1)]) > cbLogicValue then
                OutCardResult.cbCardCount = 1
                OutCardResult.cbResultCard[1] = cbCardData[cbCardCount-(i-1)]    
                return true
            end
        end
    elseif cbTurnOutType == 2 then   --对牌类型,出一对,对3,对3之类的
        --取上家牌的魔术值
        local cbLogicValue = self:GetCardLogicValue(cbTurnCardData[1])
        --分析扑克,将单,双,三,四分组
        local AnalyseResult = self:AnalysebCardData(cbCardData,cbCardCount,false)
        
        --寻找自己牌中的的对牌,看看能不能找到大的牌
        for i=1,AnalyseResult.cbDoubleCount do
            local cbIndex = (AnalyseResult.cbDoubleCount-(i-1))*2-1  --对牌数组中最左边的下标, 3组 3-0*2=6-1=5 5,6
            if self:GetCardLogicValue(AnalyseResult.cbDoubleCardData[cbIndex]) > cbLogicValue then
                --设置结果
                OutCardResult.cbCardCount = 2
                OutCardResult.cbResultCard[1] = AnalyseResult.cbDoubleCardData[cbIndex]
                OutCardResult.cbResultCard[2] = AnalyseResult.cbDoubleCardData[cbIndex+1]              
                return true
            end
        end
        --拆三张,自己的牌没有对子,直接从3张里面拆
        for i=1,AnalyseResult.cbThreeCount do
            local cbIndex = (AnalyseResult.cbThreeCount-(i-1))*3-2  --3牌数组中最左边的下标  3组,3-(1-1) = 3*3=9-2=7  7,8,9
            if self:GetCardLogicValue(AnalyseResult.cbThreeCardData[cbIndex]) > cbLogicValue then
                --设置结果
                OutCardResult.cbCardCount = 2
                OutCardResult.cbResultCard[1] = AnalyseResult.cbThreeCardData[cbIndex]
                OutCardResult.cbResultCard[2] = AnalyseResult.cbThreeCardData[cbIndex+1]
                return true
            end
        end
    elseif cbTurnOutType == 3 then  --单连类型,3,4,5,6,7,8,等
        --长度判断,当前自己的牌的个数大于上家出的牌的个数
        if cbCardCount >= cbTurnCardCount then
            --获取数值
            local cbLogicValue = self:GetCardLogicValue(cbTurnCardData[1])  --上家顺子最大牌
            --搜索连牌 ,上家牌为7,6,5,4,3 自己的牌为J,10,9,8,8,8,7,6,5,4
            for i=cbTurnCardCount,cbCardCount do --i = 5
                --获取数值 10-5 = 5 == 8 所以要加1
                local cbHandLogicValue = self:GetCardLogicValue(cbCardData[cbCardCount-i+1])
                --构造判断,
                if cbHandLogicValue < 15 then --牌不溢出
                    if cbHandLogicValue > cbLogicValue then --自己左边第i位置的牌大于上家右边最大的牌,i自增
                        --搜索连牌
                        local cbLineCount = 0
                        for j= cbCardCount-i+1,cbCardCount do  -- 10 - 5 + 1 = 6 = 8
                            if self:GetCardLogicValue(cbCardData[j])+cbLineCount == cbHandLogicValue then
                                --增加连数
                                OutCardResult.cbResultCard[cbLineCount+1] = cbCardData[j]
                                cbLineCount = cbLineCount + 1
                                --0 --- 大 --->小
                                --完成判断
                                if cbLineCount == cbTurnCardCount then  --完成单牌
                                    local bContainBomb = false
                                    for i1=1,AnalyseResultAll.cbFourCount do  --如果有炸弹
                                        local bLogicBigValue = self:GetCardLogicValue(OutCardResult.cbResultCard[1]) --最大的牌
                                        local bLogicSmallValue = self:GetCardLogicValue(OutCardResult.cbResultCard[cbTurnCardCount])  --最小的牌
                                        local bLogicBombValue = self:GetCardLogicValue(AnalyseResultAll.cbFourCardData[4*i1])  --炸弹值
                                        if bLogicBombValue >= bLogicSmallValue and bLogicBombValue<=bLogicBigValue then  --炸弹值在中间
                                            bContainBomb = true  --表示有炸弹
                                        end
                                    end
                                    if not bContainBomb then  --如果没有炸弹
                                        OutCardResult.cbCardCount = cbTurnCardCount
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif cbTurnOutType == 4 then  --对连类型,55,44,33  6等, 自己的牌 99,88,77,66,55,44,33  14
        --长度判断
        if cbCardCount >= cbTurnCardCount then
            --获取数值
            local cbLogicValue = self:GetCardLogicValue(cbTurnCardData[1])  --获取对连的左边最大牌5
            --搜索连牌
            for i=cbTurnCardCount,cbCardCount do --i = 6 
                --获取数值
                local cbHandLogicValue = self:GetCardLogicValue(cbCardData[cbCardCount-i+1])  -- 14 - 6+1 = 9 == 5
                --构造判断
                if cbHandLogicValue > cbLogicValue then  --自己的牌大于上家的牌
                    if cbHandLogicValue < 15 then  --牌小于15
                        --搜索连牌
                        local cbLineCount = 0
                        for i1=cbCardCount-i+1,cbCardCount-1 do  --14 -6 + 1 = 9 == 5
                            if (self:GetCardLogicValue(cbCardData[i1])+cbLineCount) == cbHandLogicValue and (self:GetCardLogicValue(cbCardData[i1+1])+cbLineCount) == cbHandLogicValue then
                                --增加连数,将值放进去
                                OutCardResult.cbResultCard[(cbLineCount+1)*2-1] = cbCardData[i1]
                                OutCardResult.cbResultCard[(cbLineCount+1)*2] = cbCardData[i1+1]
                                cbLineCount = cbLineCount + 1
                                
                                --完成判断
                                if cbLineCount*2 == cbTurnCardCount then  
                                    local bContainBomb = false
                                    for i2=1,AnalyseResultAll.cbFourCount do
                                        local bLogicBigValue = self:GetCardLogicValue(OutCardResult.cbResultCard[1])  --最大值
                                        local bLogicSmallValue = self:GetCardLogicValue(OutCardResult.cbResultCard[cbTurnCardCount]) --最小值
                                        local bLogicBombValue = self:GetCardLogicValue(AnalyseResultAll.cbFourCardData[4*i2])  --是都有炸弹
                                        if bLogicBombValue >= bLogicSmallValue and bLogicBombValue <= bLogicBigValue then
                                            bContainBomb = true
                                        end 
                                    end
                                    if not bContainBomb then
                                        OutCardResult.cbCardCount = cbTurnCardCount
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    elseif cbTurnOutType == 9 or cbTurnOutType == 6 then  --三带二,找到自己的三张,在其中选出比上家3张最小大的牌
        if cbCardCount < cbTurnCardCount then  --自己的牌个数小于上家的牌
            print("自己的牌没上家牌多",cbCardCount , cbTurnCardCount)
            --不执行
        elseif AnalyseResultAll.cbThreeCount < AnalyseTurnResult.cbThreeCount then  --自己牌三张的个数小于上家三张的个数
            print("自己的三张",AnalyseResultAll.cbThreeCount,"对方的三张",AnalyseTurnResult.cbThreeCount)
        else
            --找到大于上家3张的牌就返回真,否则继续向下走,找炸弹
        local ret = self:getCompare3lianMaxCard(AnalyseResultAll.cbThreeCardData,AnalyseResultAll.cbThreeCount,AnalyseTurnResult.cbThreeCardData,AnalyseTurnResult.cbThreeCount,cbTurnCardCount,OutCardResult)  --找到比上家3张牌大一点点的牌,并返回位置,1表示1个3张对比,
            print("飞机",ret,OutCardResult.cbCardCount)
            if ret then
                --上面只是收集了3个,这里给收集带的副牌数目
                local num = OutCardResult.cbCardCount-OutCardResult.cbCardCount/3
                print("num",num)
                for i=AnalyseResultAll.cbSignedCount,1,-1 do
                    print("收集单张")
                    table.insert(OutCardResult.cbResultCard,AnalyseResultAll.cbSignedCardData[i])
                    OutCardResult.cbCardCount = OutCardResult.cbCardCount + 1
                    num = num -1
                    if num <= 0 then
                        break
                    end
                end
                print("num",num)
                if num <=0 then
                    return true
                end
                for i=AnalyseResultAll.cbDoubleCount*2,1,-1 do
                    print("收集对子")
                    table.insert(OutCardResult.cbResultCard,AnalyseResultAll.cbDoubleCardData[i])
                    OutCardResult.cbCardCount = OutCardResult.cbCardCount + 1
                    num = num -1
                    if num <= 0 then
                        break
                    end
                end
                if num <=0 then
                    return true
                end
                for i=AnalyseResultAll.cbThreeCount*3,1,-1 do
                    print("收集3张")
                    local waitaddCard = AnalyseResultAll.cbThreeCardData[i]
                    local bAdd = true
                    for i2=1,OutCardResult.cbCardCount do
                        if waitaddCard == OutCardResult.cbResultCard[i2] then
                            bAdd = false
                            break
                        end
                    end
                    if bAdd then
                        print("收集一个")
                        table.insert(OutCardResult.cbResultCard,waitaddCard)
                        OutCardResult.cbCardCount = OutCardResult.cbCardCount + 1
                        num = num -1
                        if num <= 0 then
                            break
                        end
                    end
                end
                if num <=0 then
                    return true
                end
                for i=AnalyseResultAll.cbFourCount*4,1,-1 do
                    print("收集炸弹")
                    table.insert(OutCardResult.cbResultCard,AnalyseResultAll.cbFourCardData[i])
                    OutCardResult.cbCardCount = OutCardResult.cbCardCount + 1
                    num = num -1
                    if num <= 0 then
                        break
                    end
                end
                if num <=0 then
                    return true
                end
            end
        end
    end
    
    --搜索炸弹
    if cbCardCount >= 4 then
        --变量定义
        local cbLogicValue = 0
        if cbTurnOutType == 8 then
            cbLogicValue = self:GetCardLogicValue(cbTurnCardData[1])  --上家左边最大的牌
        end
        --搜索炸弹
        for i=4,cbCardCount do  --8,8,8,7,7,7,6,5,4,3  10-3=7-1=6  6,6,6,3,3    10-4+1 = 7
            --获取数值
            local cbHandLogicValue = self:GetCardLogicValue(cbCardData[cbCardCount-i+1])
            
            --构造判断
            if cbHandLogicValue > cbLogicValue then
                --炸弹判断
                local cbTempLogicValue = self:GetCardLogicValue(cbCardData[cbCardCount-i+1]) --10-4+1 = 7
                local j1=1
                for j=2,4 do
                    if self:GetCardLogicValue(cbCardData[cbCardCount+j-i]) ~= cbTempLogicValue then --10+2-4=8
                        break
                    end
                    j1 = j1 + 1
                end
                if j1 == 4 then
                    --设置结果
                    OutCardResult.cbCardCount = 4
                    OutCardResult.cbResultCard[1] = cbCardData[cbCardCount-i+1]
                    OutCardResult.cbResultCard[2] = cbCardData[cbCardCount-i+2]
                    OutCardResult.cbResultCard[3] = cbCardData[cbCardCount-i+3]
                    OutCardResult.cbResultCard[4] = cbCardData[cbCardCount-i+4]
                    return true
                end
            end
        end
    end
    
    OutCardResult.cbCardCount = 0
    return false
end

--判断是不是顺子三个头,一般是最后一把牌才会用到此函数333444,333444555,333444555666,333444555666777
--参数1:三个头数据
--参数2:有几个三个头
function GameLogic:isSanzhangLian(cbCardData,cbCardCount)
	--先从每个三个头里取出第一张牌,魔术下放到数组中
	local sortArr = {}
    if cbCardCount == 2 then  --2连
        sortArr[1] = self:GetCardLogicValue(cbCardData[1])
        sortArr[2] = self:GetCardLogicValue(cbCardData[4])
    elseif cbCardCount == 3 then  --3连
        sortArr[1] = self:GetCardLogicValue(cbCardData[1])
        sortArr[2] = self:GetCardLogicValue(cbCardData[4])
        sortArr[3] = self:GetCardLogicValue(cbCardData[7])
    elseif cbCardCount == 4 then  --4连
        sortArr[1] = self:GetCardLogicValue(cbCardData[1])
        sortArr[2] = self:GetCardLogicValue(cbCardData[4])
        sortArr[3] = self:GetCardLogicValue(cbCardData[7])
        sortArr[4] = self:GetCardLogicValue(cbCardData[10])
    elseif cbCardCount == 5 then  --5连  一副牌总共就15张牌
        sortArr[1] = self:GetCardLogicValue(cbCardData[1])
        sortArr[2] = self:GetCardLogicValue(cbCardData[4])
        sortArr[3] = self:GetCardLogicValue(cbCardData[7])
        sortArr[4] = self:GetCardLogicValue(cbCardData[10])
        sortArr[5] = self:GetCardLogicValue(cbCardData[13])
    end
    --用冒泡法排个序,从大到小
    for i=1,#sortArr do
        for j=i+1,#sortArr do
            if sortArr[i] < sortArr[j] then
                local tmp = sortArr[i]
                sortArr[i] = sortArr[j]
                sortArr[j] = tmp
            end
        end
    end
    --一次将数值进行加索引对比看看是不是相等,相等表示是连起来的三个头
    --需要判断 999777666这种情况
    if #sortArr < 2 then
        return false,0,0
    end
    local maxNum = sortArr[1]
    local tmpNum = 0  --用来过滤999777666这样的牌
    for i=1,#sortArr do
        if maxNum ~= sortArr[i]+(i-1) then  --连在一起的牌断了,先判断前面连接的牌是否大于2,大于2直接返回,不大于2,从小牌开始从新算
            if tmpNum == 2 and #sortArr < 5 then  --表示已经有两个连在一起,而且3连的个数最多为4个 ,KKKQQQ 999888 这种情况,直接返回K
                return true,maxNum,tmpNum  --返回真,最大牌(魔术值),几连
            elseif tmpNum == 2 and #sortArr == 5 then  --KKKQQQ 999888777 这种情况,选择后面3个
                tmpNum = 1
                maxNum = sortArr[i]+(i-1)
            elseif tmpNum == 3 then -- 这种情况为KKKQQQJJJ 999888 前面3个,后面2个,直接返回K
                return true,maxNum,tmpNum
            else  --从小牌的值开始重新算,这个时候要为1,因为在过程中小牌本身不参与对比
                tmpNum = 1
                maxNum = sortArr[i]+(i-1)
            end
        else
            tmpNum = tmpNum + 1  --因为第一张牌是本身,所以2才表示是联在一起的
        end
    end
    --最后判断一下
    if tmpNum >= 2 then
        return true,maxNum,tmpNum
    else
        return false,0,0
    end
end
--获取类型,是顺子还是对连 等等,isLast表示当前传过来的是全部的牌,看看能不能一把出,最后一把牌可以三个和三带一一把出
function GameLogic:GetCardType(cbCardData,cbCardCount,isLast)
    if isLast == nil then
        isLast = false
    end
	--简单牌型
	if cbCardCount == 0 then  --空牌
	   return 0
	elseif cbCardCount == 1 then  --单牌
	   return 1
    elseif cbCardCount == 2 then  --对牌,而且两个相等返回2,不相等表示错误
        if self:GetCardLogicValue(cbCardData[1]) == self:GetCardLogicValue(cbCardData[2]) then
            return 2
        end
        return 0
	end
	--分析牌的信息
	local AnalyseResult = self:AnalysebCardData(cbCardData,cbCardCount,false)
    --如果isLast为真,表示是最后一把牌
    if isLast then
        if cbCardCount == 3 then --当手上的牌只有三张时,看看是不是三张一样的
            if AnalyseResult.cbThreeCount == 1 then --分析的牌中有3个头
                return 6  --三带二的类型表示6
            end
        elseif cbCardCount == 4 then  --当手上的牌只有三个头带一张时
            if AnalyseResult.cbThreeCount == 1 then --分析的牌中有3个头
                return 6  --三带二的类型表示6
            end
        elseif AnalyseResult.cbThreeCount == 2 and cbCardCount >= 6 and cbCardCount <= 9 then  --两队飞机带1或2或3张单牌,这里只判断最后一把牌,
            local ret,max,num = self:isSanzhangLian(AnalyseResult.cbThreeCardData,AnalyseResult.cbThreeCount)
            if ret and num == AnalyseResult.cbThreeCount then
                return 9
            end
        elseif AnalyseResult.cbThreeCount == 3 and cbCardCount >= 9 and cbCardCount <= 14 then  --三对飞机带1或2或3或4或5张单牌
            local ret,max,num = self:isSanzhangLian(AnalyseResult.cbThreeCardData,AnalyseResult.cbThreeCount)
            if ret and num == AnalyseResult.cbThreeCount then
                return 9
            elseif ret and num == 2 and cbCardCount >= 6 and cbCardCount <= 9 then  --三个三连,但是只有两个是连起来的,这里,牌数目也要跟双连飞机一样
                return 9
            end
        elseif AnalyseResult.cbThreeCount == 4 or AnalyseResult.cbThreeCount == 5 then --4个三个头或者5个三个头就随便了
            local ret,max,num = self:isSanzhangLian(AnalyseResult.cbThreeCardData,AnalyseResult.cbThreeCount)
            if ret and num == AnalyseResult.cbThreeCount then
                return 9
            elseif ret and num == 4 then
                return 9
            elseif ret and num == 3 and cbCardCount >= 9 and cbCardCount <= 14 then  --三连三个飞机
                return 9
            elseif ret and num == 2 and cbCardCount >= 6 and cbCardCount <= 9 then  --三个三连,但是只有两个是连起来的,这里,牌数目也要跟双连飞机一样
                return 9 
            end
        end
    end
	
	--如果有4个相等的牌,返回8,表示炸弹
    if AnalyseResult.cbFourCount == 1 and cbCardCount == 4 then
	     return 8
	end
	
	--判断三带二
	if AnalyseResult.cbThreeCount == 1 and cbCardCount == 5 then --有一个三个头,牌数为5张,表示三带二
        return 6
    end
    
    --判断飞机, 555 666 34 78   这种类型
    if AnalyseResult.cbThreeCount >= 2 then
        local ret,max,num = self:isSanzhangLian(AnalyseResult.cbThreeCardData,AnalyseResult.cbThreeCount)
        if ret and num == 2 and cbCardCount == 10 then
            return 9
        elseif ret and num == 3 and cbCardCount == 15 then
            return 9
        elseif ret and num == 3 and cbCardCount == 10 then
            return 9
        end
    end
	
	--双连类型
	if AnalyseResult.cbDoubleCount >= 2 then  --得到的双连大于2对
	   --变量定义
	   local cbCardData = AnalyseResult.cbDoubleCardData[1] --取得2对的第一对的第一个值,这个值最大
	   local cbFirstLogicValue = self:GetCardLogicValue(cbCardData)  --转换一下
	   
	   --错误过滤
	   if cbFirstLogicValue >= 15 then
	       return 0
	   end
	   
	   --连牌判断,上面已经拿到连牌的第一对,这里拿第二对与后面,后面的值加序列等于第一个值才表示是对连
	   for i=2,AnalyseResult.cbDoubleCount do
	       local cbCardData = AnalyseResult.cbDoubleCardData[i*2-1]
	       if cbFirstLogicValue ~= (self:GetCardLogicValue(cbCardData)+(i-1)) then
	           return 0
	       end
	   end
	   
	   --二连判断,对连并且个数对的
	   if (AnalyseResult.cbDoubleCount*2) == cbCardCount then
	       return 4  --对联类型
	   end
	   
	   return 0
	end
	
	--单连判断,牌数大于等于5,且牌数相等
	if (AnalyseResult.cbSignedCount >= 5) and (AnalyseResult.cbSignedCount == cbCardCount) then
	   --变量定义
	   local cbCardData = AnalyseResult.cbSignedCardData[1]  --拿到第一个牌,最大的那张
	   local cbFirstLogicValue = self:GetCardLogicValue(cbCardData)
	   
	   --错误过滤
	   if cbFirstLogicValue >= 15 then
	       return 0
	   end
	   
	   --连牌判断
	   for i=2,AnalyseResult.cbSignedCount do
	       local cbCardData = AnalyseResult.cbSignedCardData[i]
	       if cbFirstLogicValue ~= (self:GetCardLogicValue(cbCardData)+(i-1)) then
	           return 0
	       end
	   end
	   --print("单连类型")
	   return 3  --单连类型
	end
	return 0
end

function GameLogic:GetHandMaxCard(cbCardData,cbCardCount)
    local HandCard = {}
    local HandCount = 0
    HandCount = cbCardCount
    for i=1,HandCount do
       if cbCardData[i] ~= 0 and cbCardData[i]~=nil then  
            HandCard[i] = cbCardData[i]
       end 
    end
	self:SortCardList(HandCard,HandCount,0)
	return HandCard
end

--在自己的牌里面删除传过来要删除的牌,如果传过来的牌自己的牌有
function GameLogic:RemoveCard(cbRemoveCard,cbRemoveCount,cbCardData,cbCardCount)
	if cbRemoveCount > cbCardCount then --传过来的牌要小于自己的牌个数
	   return
	end
    
    local cbDeleteCount = 0
    local cbTempCardData = {}
    for i=1,cbCardCount do  
        cbTempCardData[i] = cbCardData[i]  --先将自己的牌复制一份
    end
    
    for i=1,cbRemoveCount do  --删除的牌个数
        for j=1,cbCardCount do  --自己的牌个数
            if cbRemoveCard[i] == cbTempCardData[j] then  --删除的牌组中某个牌等于自己的牌组中某个牌
                cbDeleteCount = cbDeleteCount + 1 --将要删除的牌加1
                cbTempCardData[j] = 0  --自己的牌组中相等的牌为0
                break
            end
        end
    end
    if cbDeleteCount ~= cbRemoveCount then  --将要删除的牌和传过来要删除的牌不相等,表示传过来的牌组中的某个牌再自己的牌组中没有
        return false
    end
    
    
    for i=1,cbCardCount do
        cbCardData[i] = 0  --先将自己的牌组清零
    end
    
    --将已经删除的临时自己的牌组里有用的值复制到自己的牌组中
    local cbCardPos = 0
    for i=1,cbCardCount do 
        if cbTempCardData[i] ~= 0 then
            cbCardPos = cbCardPos + 1
            cbCardData[cbCardPos] = cbTempCardData[i]
        end
    end
    return true
end

--cbFirstCard 表示出牌的数据  cbFirstCount 表示出牌的牌数
--cbNextCard 表示自己的牌数据  cbNextCount 表示自己的牌数

function GameLogic:CompareCard(cbFirstCard,cbNextCard,cbFirstCount,cbNextCount,isLast)
    if isLast == nil then
        isLast = false
    end
    local cbNextType = self:GetCardType(cbNextCard,cbNextCount,isLast)
	local cbFirstType = self:GetCardType(cbFirstCard,cbFirstCount)
	
	if cbNextType == 0 then
	   return false
	end
	
    if cbFirstType == 0 then
        return
	end
	
	if cbFirstType ~= 8 and cbNextType == 8 then  --自己是炸弹
	   return true
	end
	if cbFirstType == 8 and cbNextType ~= 8 then  --上家是炸弹自己不是炸弹
	   return false
	end
	
	if cbFirstType ~= cbNextType then  --两者的类型不一样返回false
	   return false
	end
	
	--单张,对子,单连,对连,炸弹
	if cbNextType == 1 or cbNextType == 2 or cbNextType == 3 or cbNextType == 4 or cbNextType == 5 or cbNextType == 7 or cbNextType == 8 then
	   local cbNextLogicValue = self:GetCardLogicValue(cbNextCard[1])
	   local cbFirstLogicValue = self:GetCardLogicValue(cbFirstCard[1])
        if cbNextLogicValue > cbFirstLogicValue and cbNextCount == cbFirstCount then
            return true
	   end
    elseif cbNextType == 6 and cbFirstType == 6 then  --三带二
        local nResult = self:AnalysebCardData(cbNextCard,cbNextCount,false)  --自己的牌
        local fResult = self:AnalysebCardData(cbFirstCard,cbFirstCount,false)  --上家的牌
        if nResult.cbThreeCount ~= 0 and fResult.cbThreeCount ~= 0 and self:GetCardLogicValue(nResult.cbThreeCardData[1]) > self:GetCardLogicValue(fResult.cbThreeCardData[1]) then
            return true
        end	
    elseif cbNextType == 9 and cbFirstType == 9 then  --飞机
        local nResult = self:AnalysebCardData(cbNextCard,cbNextCount,false)  --自己的牌
        local fResult = self:AnalysebCardData(cbFirstCard,cbFirstCount,false)  --上家的牌
        
        local nret,nMaxNum,nNum = self:isSanzhangLian(nResult.cbThreeCardData,nResult.cbThreeCount)  --返回true,最大牌魔术值,几连
        local fret,fMaxNum,fNum = self:isSanzhangLian(fResult.cbThreeCardData,fResult.cbThreeCount)  --返回true,最大牌魔术值,几连
        if fNum == 3 and cbFirstCount == 10 then
            fNum = 2
        end
        print("结果",nret,nMaxNum,nNum,fret,fMaxNum,fNum)
        if nret and fret and nNum >= fNum and nMaxNum>fMaxNum then
            return true
        end
	end
	return false
end

--在自己的手牌中找到比上家3张或者顺子3张大一点点的牌
function GameLogic:getCompare3lianMaxCard(selfCardData,selfCount,turnCardData,turnCount,cbTurnCardCount,OutCardResult)
    if selfCount <= 0 then
        return false
    end
    print("自己的3张有几个",selfCount)
	--先取得自己牌中所有3张的第一个数,转换成魔术,放到数组
    local selfsortArr = {}
    if selfCount == 1 then  --1连
        selfsortArr[1] = self:GetCardLogicValue(selfCardData[1])
    elseif selfCount == 2 then  --2连
        selfsortArr[1] = self:GetCardLogicValue(selfCardData[1])
        selfsortArr[2] = self:GetCardLogicValue(selfCardData[4])
    elseif selfCount == 3 then  --3连
        selfsortArr[1] = self:GetCardLogicValue(selfCardData[1])
        selfsortArr[2] = self:GetCardLogicValue(selfCardData[4])
        selfsortArr[3] = self:GetCardLogicValue(selfCardData[7])
    elseif selfCount == 4 then  --4连
        selfsortArr[1] = self:GetCardLogicValue(selfCardData[1])
        selfsortArr[2] = self:GetCardLogicValue(selfCardData[4])
        selfsortArr[3] = self:GetCardLogicValue(selfCardData[7])
        selfsortArr[4] = self:GetCardLogicValue(selfCardData[10])
    elseif selfCount == 5 then  --5连  一副牌总共就15张牌
        selfsortArr[1] = self:GetCardLogicValue(selfCardData[1])
        selfsortArr[2] = self:GetCardLogicValue(selfCardData[4])
        selfsortArr[3] = self:GetCardLogicValue(selfCardData[7])
        selfsortArr[4] = self:GetCardLogicValue(selfCardData[10])
        selfsortArr[5] = self:GetCardLogicValue(selfCardData[13])
    end
    
    --取得上家牌中3张的最大的牌,不管几连
    local turnMaxCard = 0
    local turnLian = 0
    local ret = false
    if turnCount == 1 then
        turnMaxCard = self:GetCardLogicValue(turnCardData[1])
        turnLian = 1
        ret = true
    else
        ret,turnMaxCard,turnLian = self:isSanzhangLian(turnCardData,turnCount)
        if turnLian == 3 and cbTurnCardCount == 10 then 
            turnLian = 2
        end
    end
    if not ret then  --上家分析3张牌出错
        return false
    end
    
    print("上家最大的牌",turnMaxCard,"上家几个3张",turnLian,cbTurnCardCount)
    print("自己三张数组",#selfsortArr)
    local index = 0
    for i=#selfsortArr,1,-1 do  --找出比上家的3张大一点点的牌,从最小的牌开始
        if selfsortArr[i] > turnMaxCard then  --找到大于上家3张最大的牌
            if turnLian == 1 then  --上家只有1个3张
                index = i
                break
            elseif turnLian == 2 then  --上家有两个三张
                if i+1 <= #selfsortArr and selfsortArr[i+1]+1 == selfsortArr[i] then
                    index = i
                    break
                end
            elseif turnLian == 3 then  --上家有3个3张
                if i+1 <= #selfsortArr and selfsortArr[i+1]+1 == selfsortArr[i] and i+2 <= #selfsortArr and selfsortArr[i+2]+2 == selfsortArr[i] then
                    index = i
                    break
                end
            elseif turnLian == 4 then  --上家有4个3张
                if i+1 <= #selfsortArr and selfsortArr[i+1]+1 == selfsortArr[i] and i+2 <= #selfsortArr and selfsortArr[i+2]+2 == selfsortArr[i] and i+3 <= #selfsortArr and selfsortArr[i+3]+3 == selfsortArr[i] then
                    index = i
                    break
                end
            elseif turnLian == 5 then  --上家有5个3张
                if i+1 <= #selfsortArr and selfsortArr[i+1]+1 == selfsortArr[i] and i+2 <= #selfsortArr and selfsortArr[i+2]+2 == selfsortArr[i] and i+3 <= #selfsortArr and selfsortArr[i+3]+3 == selfsortArr[i] and i+4 <= #selfsortArr and selfsortArr[i+4]+4 == selfsortArr[i] then
                    index = i
                    break
                end
            end
        end
    end
    if index == 0 then  --自己的3张没有大于上家的
        return false
    end
    print("index",index)
    --收集牌
    local ii = 0 --从哪个下标开始收集
    if index == 5 then
        ii = 13
    elseif index == 4 then
        ii = 10
    elseif index == 3 then
        ii = 7
    elseif index == 2 then
        ii = 4
    elseif index == 1 then
        ii = 1
    end
    print("ii",ii)
    if ii == 0 then
        return false
    end
    
    local sjret = turnLian*3  --一共要收集的个数
    local sjtmp = 0
    print("收集下标",ii,"一共收集个数",sjret,"自己有牌数为",#selfsortArr*3)
    for i=ii,#selfsortArr*3 do
        sjtmp = sjtmp + 1
        OutCardResult.cbResultCard[sjtmp] = selfCardData[i]
        if sjtmp >= sjret then  --大于等于表示收集完了
            OutCardResult.cbCardCount = sjret  --表示3张
            break
        end
    end
    
    if OutCardResult.cbCardCount == 0 then
        return false
    end
    
    return true
end
return GameLogic