--游戏逻辑处理
local Bit = require("common.Bit")
local GameCommon = require("game.paohuzi.GameCommon") 
local GameLogic = {}

function GameLogic:RemoveCard(cbCardIndex,cbRemoveCard)--删除扑克
    --效验扑克
    assert(self:IsValidCard(cbRemoveCard))
    assert(cbCardIndex[self:SwitchToCardIndex(cbRemoveCard)]>0)

    --删除扑克
    local cbRemoveIndex = self:SwitchToCardIndex(cbRemoveCard)
    if cbCardIndex[cbRemoveIndex] > 0 then
        cbCardIndex[cbRemoveIndex] = cbCardIndex[cbRemoveIndex] - 1
        return true,cbCardIndex
    end
    --失败效验
    assert(false)
    return false,nil
end

function GameLogic:RemoveCards(cbCardIndex, cbRemoveCard, bRemoveCount)--删除扑克
    --删除扑克
    for i = 0 , bRemoveCount -1 do
        --效验扑克
        assert(self:IsValidCard(cbRemoveCard[i]))
        assert(cbCardIndex[self:SwitchToCardIndex( cbRemoveCard[i])] > 0)

        --删除扑克
        local cbRemoveIndex= self:SwitchToCardIndex(cbRemoveCard[i])
        if cbCardIndex[cbRemoveIndex] == 0 then
            --错误断言
            assert(false)
            --还原删除
            for j = 0 , i - 1 do
                assert(self:IsValidCard(cbRemoveCard[j]))
                local index = self:SwitchToCardIndex( cbRemoveCard[j])
                cbCardIndex[index] = cbCardIndex[index] + 1
            end

            return false,nil
        else 
            --删除扑克
            cbCardIndex[cbRemoveIndex] = cbCardIndex[cbRemoveIndex] - 1
        end
    end

    return true,cbCardIndex
end

function GameLogic:RemoveCardsEx(cbCardData, bCardCount, cbRemoveCard, bRemoveCount)--删除扑克
    --检验数据
    assert(bCardCount <= 21)
    assert(bRemoveCount <= bCardCount)

    --定义变量
    local bDeleteCount=0
    local cbTempCardData = {}
    if bCardCount > 21 then
        return false,nil
    end
    local cbTempCardData = clone(cbCardData)
   
    --置零扑克
    for i = 0 , bRemoveCount - 1 do
        for j = 0 , bCardCount - 1 do
            if cbRemoveCard[i] == cbTempCardData[j] then
                bDeleteCount = bDeleteCount + 1
                cbTempCardData[j]=0
                break
            end
        end
    end

    --成功判断
    if bDeleteCount ~= bRemoveCount then
        assert(false)
        return false
    end

    --清理扑克
    local bCardPos = 0
    for i = 0 , bCardCount - 1 do
        if cbTempCardData[i] ~= 0 then
            bCardPos = bCardPos + 1
            cbCardData[bCardPos] = cbTempCardData[i]
        end
    end
    return true
end

function GameLogic:GetAcitonTiCard(cbCardIndex)--提牌判断
    --提牌搜索
    local cbTiCardIndex = {}
    local cbTiCardCount = 1
    for i = 1 , 20 do
        if cbCardIndex[i]==4 then
            cbTiCardIndex[cbTiCardCount] = i
            cbTiCardCount = cbTiCardCount + 1
        end
    end

    return cbTiCardIndex
end

function GameLogic:GetActionWeiCard(cbCardIndex, cbWeiCardIndex)--畏牌判断
    --畏牌搜索
    local cbWeiCardCount = 0
    for i = 0 , 19 do
        if cbCardIndex[i]==3 then
            cbWeiCardCount = cbWeiCardCount + 1
            cbWeiCardIndex[cbWeiCardCount] = i
        end
    end
    return cbWeiCardCount
end

function GameLogic:GetActionChiCard(cbCardIndex, cbCurrentCard)--吃牌判断
    --效验扑克
    local ChiCardInfo = {}
    assert(cbCurrentCard ~= 0)
    if cbCurrentCard == 0 then
        return #ChiCardInfo,ChiCardInfo
    end
    --变量定义
    local cbCurrentIndex = self:SwitchToCardIndex(cbCurrentCard)
    
    --三牌判断
    if cbCardIndex[cbCurrentIndex] >= 3 then
        return #ChiCardInfo,ChiCardInfo
    end
    
    --大小搭吃
    local cbReverseIndex = cbCurrentIndex + 10
    if cbReverseIndex > 20 then
        cbReverseIndex = cbCurrentIndex - 10
    end

    if cbCardIndex[cbCurrentIndex] >= 1 and cbCardIndex[cbReverseIndex] >= 1 and cbCardIndex[cbReverseIndex] <= 2 then
        --构造扑克
        local cbCardIndexTemp = clone(cbCardIndex)

        --删除扑克
        cbCardIndexTemp[cbCurrentIndex] = cbCardIndexTemp[cbCurrentIndex] - 1
        cbCardIndexTemp[cbReverseIndex] = cbCardIndexTemp[cbReverseIndex] - 1
        
        --提取判断
        local data = {}
        data.cbCardData = {}
        data.cbCenterCard=cbCurrentCard
        data.cbChiKind= GameCommon.CK_XDD
        if Bit:_and(cbCurrentCard , GameCommon.MASK_COLOR) == 0 then
            data.cbChiKind = GameCommon.CK_XXD
        end
        
        local tempData = {}
        tempData[1] = cbCurrentCard
        tempData[2] = cbCurrentCard
        tempData[3] = self:SwitchToCardData(cbReverseIndex)
        table.insert(data.cbCardData,#data.cbCardData+1,tempData)
        
        while cbCardIndexTemp[cbCurrentIndex] > 0 do
            local ret = 0 
            local tempData = nil
            ret , tempData , cbCardIndexTemp = self:TakeOutChiCard(cbCardIndexTemp,cbCurrentCard)
            if ret ~= 0 then
                table.insert(data.cbCardData,#data.cbCardData+1,tempData)
            else 
                break
            end
        end
        
        if cbCardIndexTemp[cbCurrentIndex] == 0 then
            data.cbResultCount= #data.cbCardData
            table.insert(ChiCardInfo,#ChiCardInfo + 1,data)   
        end
    end
    --大小搭吃
    if cbCardIndex[cbReverseIndex] == 2 then
        --构造扑克
        local cbCardIndexTemp = clone(cbCardIndex)

        --删除扑克
        cbCardIndexTemp[cbReverseIndex] = cbCardIndexTemp[cbReverseIndex] - 2

        --提取判断
        local data = {}
        data.cbCardData = {}
        data.cbCenterCard=cbCurrentCard
        data.cbChiKind= GameCommon.CK_XXD
        if Bit:_and(cbCurrentCard , GameCommon.MASK_COLOR) == 0 then
            data.cbChiKind = GameCommon.CK_XDD
        end
        
        local tempData = {}
        tempData[1] = cbCurrentCard
        tempData[2] = self:SwitchToCardData(cbReverseIndex)
        tempData[3] = self:SwitchToCardData(cbReverseIndex)
        table.insert(data.cbCardData,#data.cbCardData+1,tempData)
        
        while cbCardIndexTemp[cbCurrentIndex] > 0 do
            local ret = 0
            local tempData = nil
            ret, tempData , cbCardIndexTemp = self:TakeOutChiCard(cbCardIndexTemp,cbCurrentCard)
            if ret ~= 0 then
                table.insert(data.cbCardData,#data.cbCardData+1,tempData)
            else 
                break
            end
        end
        
        if cbCardIndexTemp[cbCurrentIndex] == 0 then
            data.cbResultCount= #data.cbCardData
            table.insert(ChiCardInfo,#ChiCardInfo + 1,data)   
        end
    end
    
    --二七十吃
    local bCardValue = cbCurrentIndex
    if bCardValue > 10 then
        bCardValue = cbCurrentIndex - 10
    end
    if bCardValue == 2 or bCardValue == 7 or bCardValue == 10 then
        --变量定义
        local cbExcursion = {[1] = 2,[2] = 7, [3] = 10}
        local cbInceptIndex = 0
        if cbCurrentIndex > 10 then
            cbInceptIndex = 10
        end

        --类型判断
        local index = 0
        for i = 1 , #cbExcursion do
            local cbIndex = cbInceptIndex + cbExcursion[i]
            if (cbIndex ~= cbCurrentIndex) and ((cbCardIndex[cbIndex] == 0) or (cbCardIndex[cbIndex] >= 3)) then
                break
            end
            index = i
        end

        --提取判断
        if index == #cbExcursion then
            --构造扑克
            local cbCardIndexTemp = clone(cbCardIndex)

            --删除扑克
            for j = 1 , #cbExcursion do
                local cbIndex = cbInceptIndex + cbExcursion[j]
                if cbIndex ~= cbCurrentIndex then
                    cbCardIndexTemp[cbIndex] = cbCardIndexTemp[cbIndex] - 1
                end
            end
            
            --提取判断
            local data = {}
            data.cbCardData = {}
            data.cbCenterCard=cbCurrentCard
            data.cbChiKind = GameCommon.CK_EQS
  
            local tempData = {}
            tempData[1] = self:SwitchToCardData(cbInceptIndex+cbExcursion[1])
            tempData[2] = self:SwitchToCardData(cbInceptIndex+cbExcursion[2])
            tempData[3] = self:SwitchToCardData(cbInceptIndex+cbExcursion[3])
            table.insert(data.cbCardData,#data.cbCardData+1,tempData)
            
            while cbCardIndexTemp[cbCurrentIndex] > 0 do
                local ret = 0 
                local tempData = nil
                ret , tempData , cbCardIndexTemp = self:TakeOutChiCard(cbCardIndexTemp,cbCurrentCard)
                if ret ~= 0 then
                    table.insert(data.cbCardData,#data.cbCardData+1,tempData)
                else 
                    break
                end
            end
            
            if cbCardIndexTemp[cbCurrentIndex] == 0 then
                data.cbResultCount= #data.cbCardData
                table.insert(ChiCardInfo,#ChiCardInfo + 1,data)   
            end
        end
    end

    --一五十吃
    if GameCommon.gameConfig ~= nil and GameCommon.gameConfig.bYiWuShi ~= nil and type(GameCommon.gameConfig.bYiWuShi) == "number" and GameCommon.gameConfig.bYiWuShi == 1 then
        local bCardValue = cbCurrentIndex
        if bCardValue > 10 then
            bCardValue = cbCurrentIndex - 10
        end
        if bCardValue == 1 or bCardValue == 5 or bCardValue == 10 then
            --变量定义
            local cbExcursion = {[1] = 1,[2] = 5, [3] = 10}
            local cbInceptIndex = 0
            if cbCurrentIndex > 10 then
                cbInceptIndex = 10
            end
    
            --类型判断
            local index = 0
            for i = 1 , #cbExcursion do
                local cbIndex = cbInceptIndex + cbExcursion[i]
                if (cbIndex ~= cbCurrentIndex) and ((cbCardIndex[cbIndex] == 0) or (cbCardIndex[cbIndex] >= 3)) then
                    break
                end
                index = i
            end
    
            --提取判断
            if index == #cbExcursion then
                --构造扑克
                local cbCardIndexTemp = clone(cbCardIndex)
    
                --删除扑克
                for j = 1 , #cbExcursion do
                    local cbIndex = cbInceptIndex + cbExcursion[j]
                    if cbIndex ~= cbCurrentIndex then
                        cbCardIndexTemp[cbIndex] = cbCardIndexTemp[cbIndex] - 1
                    end
                end
    
                --提取判断
                local data = {}
                data.cbCardData = {}
                data.cbCenterCard=cbCurrentCard
                data.cbChiKind = GameCommon.CK_YWS
    
                local tempData = {}
                tempData[1] = self:SwitchToCardData(cbInceptIndex+cbExcursion[1])
                tempData[2] = self:SwitchToCardData(cbInceptIndex+cbExcursion[2])
                tempData[3] = self:SwitchToCardData(cbInceptIndex+cbExcursion[3])
                table.insert(data.cbCardData,#data.cbCardData+1,tempData)
    
                while cbCardIndexTemp[cbCurrentIndex] > 0 do
                    local ret = 0 
                    local tempData = nil
                    ret , tempData , cbCardIndexTemp = self:TakeOutChiCard(cbCardIndexTemp,cbCurrentCard)
                    if ret ~= 0 then
                        table.insert(data.cbCardData,#data.cbCardData+1,tempData)
                    else 
                        break
                    end
                end
    
                if cbCardIndexTemp[cbCurrentIndex] == 0 then
                    data.cbResultCount= #data.cbCardData
                    table.insert(ChiCardInfo,#ChiCardInfo + 1,data)   
                end
            end
        end
    end
    --顺子类型
    local cbExcursion = {[1]= 1,[2]= 2,[3]= 3}
    for i = 1 , #cbExcursion do
        local cbValueIndex=cbCurrentIndex
        if cbCurrentIndex > 10 then
            cbValueIndex=cbCurrentIndex - 10
        end
        if (cbValueIndex >= cbExcursion[i]) and ((cbValueIndex - cbExcursion[i]) <= 7) then
            --索引定义
            local cbFirstIndex = cbCurrentIndex - cbExcursion[i]
            --吃牌判断
            local index = 0
            for j = 1 , 3 do
                local cbIndex = cbFirstIndex + j
                if  (cbIndex ~= cbCurrentIndex) and (cbCardIndex[cbIndex]==0 or cbCardIndex[cbIndex] >= 3) then
                    break        
                end
                index = j
            end
            --提取判断
            if index == #cbExcursion then
                --构造扑克
                local cbCardIndexTemp = clone(cbCardIndex)

                --删除扑克
                for j = 1 , 3 do
                    local cbIndex=cbFirstIndex + j
                    if cbIndex ~= cbCurrentIndex then
                        cbCardIndexTemp[cbIndex] = cbCardIndexTemp[cbIndex] - 1
                    end
                end

                --提取判断
                local cbChiKind = {[1] = GameCommon.CK_LEFT,[2] = GameCommon.CK_CENTER,[3] = GameCommon.CK_RIGHT}
                local data = {}
                data.cbCardData = {}
                data.cbCenterCard=cbCurrentCard
                data.cbChiKind= cbChiKind[i]

                local tempData = {}
                tempData[1] = self:SwitchToCardData(cbFirstIndex+1)
                tempData[2] = self:SwitchToCardData(cbFirstIndex+2)
                tempData[3] = self:SwitchToCardData(cbFirstIndex+3)
                table.insert(data.cbCardData,#data.cbCardData+1,tempData)
                
                while cbCardIndexTemp[cbCurrentIndex] > 0 do
                    local ret = 0
                    local tempData = nil
                    ret , tempData , cbCardIndexTemp = self:TakeOutChiCard(cbCardIndexTemp,cbCurrentCard)
                    if ret ~= 0 then
                        table.insert(data.cbCardData,#data.cbCardData+1,tempData)
                    else 
                        break
                    end
                end
                if cbCardIndexTemp[cbCurrentIndex] == 0 then
                    data.cbResultCount= #data.cbCardData
                    table.insert(ChiCardInfo,#ChiCardInfo + 1,data)   
                end
            end
        end
    end
    return #ChiCardInfo,ChiCardInfo
end


function GameLogic:IsChiCard(cbCardIndex, cbCurrentCard)--是否吃牌
    --效验扑克
    assert(cbCurrentCard~=0)
    if cbCurrentCard ==0 then
        return false
    end

    --构造扑克
    local cbCardIndexTemp = clone(cbCardIndex)

    --插入扑克
    local cbCurrentIndex = self:SwitchToCardIndex(cbCurrentCard)
    cbCardIndexTemp[cbCurrentIndex] = cbCardIndexTemp[cbCurrentIndex] + 1

    --提取判断
    while cbCardIndexTemp[cbCurrentIndex] > 0 do
        local cbResult = {}
        if self:TakeOutChiCard(cbCardIndexTemp,cbCurrentCard,cbResult) == 0 then
            break
        end
    end
    
    if cbCardIndexTemp[cbCurrentIndex] == 0 then
    	return true
    end
    return false
end

function GameLogic:IsTiPaoCard(cbCardIndex, cbCurrentCard)--是否提跑
    --效验扑克
    assert(cbCurrentCard ~=0)
    if (cbCurrentCard==0) then
        return false
    end

    --转换索引
    local cbCurrentIndex = self:SwitchToCardIndex(cbCurrentCard)

    --碰牌判断
    if cbCardIndex[cbCurrentIndex]==3 then
    	return true
    end
    return false
end

function GameLogic:IsWeiPengCard(cbCardIndex, cbCurrentCard)--是否偎碰
    --效验扑克
    assert(cbCurrentCard ~=0)
    if (cbCurrentCard==0) then
        return false
    end

    --转换索引
    local cbCurrentIndex=self:SwitchToCardIndex(cbCurrentCard)

    --跑偎判断
    if cbCardIndex[cbCurrentIndex]==2 then
    	return true
    end
    return false
end

local function getPlayerHuXi(wChairID)
	local huXiCount = 0
	local viewID = GameCommon:getViewIDByChairID(wChairID)
	if GameCommon.player[wChairID].WeaveItemArray ~= nil then
		for key, var in pairs(GameCommon.player[wChairID].WeaveItemArray) do	
			if(var.cbWeaveKind == GameCommon.ACK_TI and GameCommon.tiCardType == 1 and wChairID ~= GameCommon:getRoleChairID()) or
			(var.cbWeaveKind == GameCommon.ACK_WEI and GameCommon.weiCardType == 1 and wChairID ~= GameCommon:getRoleChairID()) then
				
			else
				huXiCount = huXiCount + GameLogic:GetWeaveHuXi(var)
			end
		end
	end
	return huXiCount
end

function GameLogic:GetHuCardInfoData(wChairID, cbCardIndex, cbCurrentCard)--胡牌结果

    local ret = false                               --能不能组合
    local paotiwei = false                          --是否有跑提偎


	local stuTingCardInfo = {}    -- 可能的提牌
	stuTingCardInfo.cbCardData = 0
	stuTingCardInfo.isTingCard = false
	stuTingCardInfo.cbTingCount = 0
    stuTingCardInfo.cbCardIndexTing = {}
    
	local tempWeaveItemCount = GameCommon.player[wChairID].bWeaveItemCount
	local tempWeaveItemArray = clone(GameCommon.player[wChairID].WeaveItemArray)

    --手牌四张变提 
    --手牌三张变喂 
    --变量定义
    local AnalyseItemArray = {}
    --构造扑克   新牌
    local cbCardIndexTemp = clone(cbCardIndex)
    --设置结果
    local HuCardInfo = {}
    HuCardInfo.cbWeaveCount = 0
    HuCardInfo.cbHuXiCount = 0
    HuCardInfo.WeaveItemArray = {}
    --提取三牌
    for i = 1 , 20 do
        if (cbCardIndexTemp[i]==4) then
            --设置扑克
            cbCardIndexTemp[i]=0
            --设置组合
            local cbCardData = self:SwitchToCardData(i)
            HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
            local cbIndex=HuCardInfo.cbWeaveCount
            HuCardInfo.WeaveItemArray[cbIndex] = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardCount=4
            HuCardInfo.WeaveItemArray[cbIndex].cbWeaveKind=GameCommon.ACK_TI
            HuCardInfo.WeaveItemArray[cbIndex].cbCenterCard=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[1]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[2]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[3]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[4]=cbCardData
            --设置胡息
            HuCardInfo.cbHuXiCount = HuCardInfo.cbHuXiCount + self:GetWeaveHuXi(HuCardInfo.WeaveItemArray[cbIndex])
        elseif (cbCardIndexTemp[i]==3) then
            --设置扑克
            cbCardIndexTemp[i]=0
            --设置组合
            local cbCardData = self:SwitchToCardData(i)
            HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
            local cbIndex=HuCardInfo.cbWeaveCount
            HuCardInfo.WeaveItemArray[cbIndex] = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardCount=3
            HuCardInfo.WeaveItemArray[cbIndex].cbWeaveKind=GameCommon.ACK_WEI
            HuCardInfo.WeaveItemArray[cbIndex].cbCenterCard=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[1]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[2]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[3]=cbCardData
            --设置胡息
            HuCardInfo.cbHuXiCount = HuCardInfo.cbHuXiCount + self:GetWeaveHuXi(HuCardInfo.WeaveItemArray[cbIndex])
        end
    end
    local cbCardIndexTemp1 = clone(cbCardIndexTemp)
    local bUserHuXiCountModify1 = 0
    local bUserHuXiCountModify2 = 0
	local cbCardIndexModify = {}
	local WeaveItemCountModify = 0
	local WeaveItemArrayModify = {}

	local weiCardType = 1
    local tiCardType = 0
    
    -- local cbCurrentCard = GameLogic:SwitchToCardData(i)
    bUserHuXiCountModify1 = getPlayerHuXi(wChairID)
    bUserHuXiCountModify2 = bUserHuXiCountModify1
    WeaveItemCountModify = GameCommon.player[wChairID].bWeaveItemCount
    cbCardIndexModify = clone(cbCardIndex)
    WeaveItemArrayModify = clone(GameCommon.player[wChairID].WeaveItemArray)
    local cbCenterCard = GameLogic:SwitchToCardData(cbCurrentCard)	

    if cbCardIndex[cbCurrentCard] == 2 then
        --判断是否可以偎
        WeaveItemCountModify = WeaveItemCountModify + 1
        WeaveItemArrayModify[WeaveItemCountModify] = WeaveItemArrayModify[WeaveItemCountModify] or {}
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList = WeaveItemArrayModify[WeaveItemCountModify].cbCardList or {}
        WeaveItemArrayModify[WeaveItemCountModify].cbCardCount = 3
        WeaveItemArrayModify[WeaveItemCountModify].cbWeaveKind = GameCommon.ACK_WEI
        WeaveItemArrayModify[WeaveItemCountModify].cbCenterCard = cbCenterCard
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList[1] = cbCenterCard
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList[2] = cbCenterCard
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList[3] = cbCenterCard
        cbCardIndexTemp[cbCurrentCard] = 0
        if cbCurrentCard <= 10 then
            bUserHuXiCountModify2 = bUserHuXiCountModify2 + 3
        else
            bUserHuXiCountModify2 = bUserHuXiCountModify2 + 6
        end
        paotiwei = true
    elseif cbCardIndex[cbCurrentCard] == 3 then
        WeaveItemCountModify = WeaveItemCountModify + 1
        WeaveItemArrayModify[WeaveItemCountModify] = WeaveItemArrayModify[WeaveItemCountModify] or {}
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList = WeaveItemArrayModify[WeaveItemCountModify].cbCardList or {}
        WeaveItemArrayModify[WeaveItemCountModify].cbCardCount=4
        WeaveItemArrayModify[WeaveItemCountModify].cbWeaveKind=GameCommon.ACK_TI
        WeaveItemArrayModify[WeaveItemCountModify].cbCenterCard=cbCenterCard
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList[1]=cbCenterCard
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList[2]=cbCenterCard
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList[3]=cbCenterCard
        WeaveItemArrayModify[WeaveItemCountModify].cbCardList[4]=cbCenterCard
        cbCardIndexTemp[cbCurrentCard] = 0
        if cbCurrentCard <= 10 then
            bUserHuXiCountModify2 = bUserHuXiCountModify2 + 9
        else
            bUserHuXiCountModify2 = bUserHuXiCountModify2 + 12
        end
        --判断是否可以提
        paotiwei = true
    else
        for i=1,WeaveItemCountModify do
            if WeaveItemArrayModify[i].cbWeaveKind == GameCommon.ACK_WEI and WeaveItemArrayModify[i].cbCenterCard == cbCenterCard then
                WeaveItemArrayModify[i].cbWeaveKind = GameCommon.ACK_TI
                WeaveItemArrayModify[i].cbCardList[4] = cbCurrentCard
                bUserHuXiCountModify2 = bUserHuXiCountModify2 + 6
                paotiwei = true
                break
            end
            if WeaveItemArrayModify[i].cbWeaveKind == GameCommon.ACK_PENG and WeaveItemArrayModify[i].cbCenterCard == cbCenterCard then
                WeaveItemArrayModify[i].cbWeaveKind = GameCommon.ACK_PAO
                WeaveItemArrayModify[i].cbCardList[4] = cbCurrentCard
                if cbCenterCard > 10 then
                    bUserHuXiCountModify2 = bUserHuXiCountModify2 + 6
                else
                    bUserHuXiCountModify2 = bUserHuXiCountModify2 + 5
                end 
                paotiwei = true
                break
            end
        end      
    end
    if GameCommon.gameConfig.bCanHuXi == 0 then 
        GameCommon.gameConfig.bCanHuXi = 15
    end 
    if paotiwei then
        --组合
        local WeaveItemArray = nil
        ret, WeaveItemArray = self:AnalyseCard(cbCardIndexTemp)
        
        if ret == true then
            for i = 1 , #WeaveItemArray do
                --胡息分析
                if (WeaveItemArray[i].cbHuXiCount>=0) then
                    bUserHuXiCountModify2=bUserHuXiCountModify2+WeaveItemArray[i].cbHuXiCount
                end
            end
            --算胡息
            if bUserHuXiCountModify2 + HuCardInfo.cbHuXiCount >= GameCommon.gameConfig.bCanHuXi then
                return true
            end
        end
    end  

    cbCardIndexTemp = clone(cbCardIndexTemp1)
    cbCardIndexTemp[cbCurrentCard] = cbCardIndexTemp[cbCurrentCard] +1
    local WeaveItemArray = nil
    ret, WeaveItemArray = self:AnalyseCard(cbCardIndexTemp)
      
    if ret == true then
        for i = 1 , #WeaveItemArray do
            --胡息分析
            if (WeaveItemArray[i].cbHuXiCount>=0) then
                bUserHuXiCountModify1=bUserHuXiCountModify1+WeaveItemArray[i].cbHuXiCount
            end
        end
        --算胡息
        if bUserHuXiCountModify1 + HuCardInfo.cbHuXiCount >= GameCommon.gameConfig.bCanHuXi then
            return true
        end
    end
    
    return false


end

function GameLogic:GetHuCardInfo(cbCardIndex, cbCurrentCard, cbHuXiWeave)--胡牌结果
    --变量定义
    local AnalyseItemArray = {}
    --构造扑克
    local cbCardIndexTemp = clone(cbCardIndex)

    --设置结果
    local HuCardInfo = {}
    HuCardInfo.cbWeaveCount = 0
    HuCardInfo.cbHuXiCount = 0
    HuCardInfo.WeaveItemArray = {}
    
    --提取三牌
    for i = 1 , 20 do
        if (cbCardIndexTemp[i]==4) then
            --设置扑克
            cbCardIndexTemp[i]=0

            --设置组合
            local cbCardData = self:SwitchToCardData(i)
            HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
            local cbIndex=HuCardInfo.cbWeaveCount
            HuCardInfo.WeaveItemArray[cbIndex] = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardCount=4
            HuCardInfo.WeaveItemArray[cbIndex].cbWeaveKind=GameCommon.ACK_TI
            HuCardInfo.WeaveItemArray[cbIndex].cbCenterCard=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[1]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[2]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[3]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[4]=cbCardData

            --设置胡息
            HuCardInfo.cbHuXiCount = HuCardInfo.cbHuXiCount + self:GetWeaveHuXi(HuCardInfo.WeaveItemArray[cbIndex])
        elseif (cbCardIndexTemp[i]==3) then
            --设置扑克
            cbCardIndexTemp[i]=0

            --设置组合
            local cbCardData = self:SwitchToCardData(i)
            HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
            local cbIndex=HuCardInfo.cbWeaveCount
            HuCardInfo.WeaveItemArray[cbIndex] = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList = {}
            HuCardInfo.WeaveItemArray[cbIndex].cbCardCount=3
            HuCardInfo.WeaveItemArray[cbIndex].cbWeaveKind=GameCommon.ACK_WEI
            HuCardInfo.WeaveItemArray[cbIndex].cbCenterCard=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[1]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[2]=cbCardData
            HuCardInfo.WeaveItemArray[cbIndex].cbCardList[3]=cbCardData

            --设置胡息
            HuCardInfo.cbHuXiCount = HuCardInfo.cbHuXiCount + self:GetWeaveHuXi(HuCardInfo.WeaveItemArray[cbIndex])
        end
    end

    --提取碰牌
    if ((cbCurrentCard ~=0) and (self:IsWeiPengCard(cbCardIndexTemp,cbCurrentCard)==true)) then
        local index = self:SwitchToCardIndex(cbCurrentCard)
        cbCardIndexTemp[index] = cbCardIndexTemp[index] + 1
        AnalyseItemArray = {}

        --先分析吃牌如果胡息总数满足15胡息以上就直接返回啦，没有碰的组合，这个地方需要修改
        --只有吃牌组合的胡息，和有碰牌的胡息进行比较谁的胡息大就选择哪个组合
        local ChiHuCardInfo = {}
        ChiHuCardInfo.cbWeaveCount  = 0 
        ChiHuCardInfo.WeaveItemArray = {}
        local PengHuCardInfo = {}

        local bHuCardChi=false
        local bHuCardPeng=false
        ---------
        ------特定胡牌有问题
        --吃组合的胡牌判断
        if(self:AnalyseCard(cbCardIndexTemp,AnalyseItemArray)==true) then
            --寻找最优
            local cbHuXiCard=0
            local nBestItem=0
            for i = 1 , #AnalyseItemArray do
                --胡息分析
                if (AnalyseItemArray[i].cbHuXiCount>=cbHuXiCard) then
                
                    nBestItem=i
                    cbHuXiCard=AnalyseItemArray[i].cbHuXiCount
                end
            end
            --设置结果
            ChiHuCardInfo.cbHuXiCount=cbHuXiCard   
            if (nBestItem>0) then
                --牌眼
                ChiHuCardInfo.cbCardEye=AnalyseItemArray[nBestItem].cbCardEye   

                --设置组合
                for i = 1 , AnalyseItemArray[nBestItem].cbWeaveCount do
                    ChiHuCardInfo.cbWeaveCount = ChiHuCardInfo.cbWeaveCount + 1
                    local cbIndex=ChiHuCardInfo.cbWeaveCount
                    ChiHuCardInfo.WeaveItemArray[cbIndex]=AnalyseItemArray[nBestItem].WeaveItemArray[i]
                end
            end
            bHuCardChi=true
        else
            bHuCardChi=false
        end

        ----------------------------------------------------/碰组合判断
        PengHuCardInfo.cbHuXiCount = 0
        PengHuCardInfo.cbWeaveCount = 0
        PengHuCardInfo.cbWeaveCount = PengHuCardInfo.cbWeaveCount + 1
        local cbIndex1=PengHuCardInfo.cbWeaveCount
        PengHuCardInfo.WeaveItemArray = PengHuCardInfo.WeaveItemArray or {}
        PengHuCardInfo.WeaveItemArray[cbIndex1] = PengHuCardInfo.WeaveItemArray[cbIndex1] or {}
        PengHuCardInfo.WeaveItemArray[cbIndex1].cbCardList = PengHuCardInfo.WeaveItemArray[cbIndex1].cbCardList or {}
        PengHuCardInfo.WeaveItemArray[cbIndex1].cbCardCount=3
        PengHuCardInfo.WeaveItemArray[cbIndex1].cbWeaveKind=GameCommon.ACK_PENG
        PengHuCardInfo.WeaveItemArray[cbIndex1].cbCenterCard=cbCurrentCard
        PengHuCardInfo.WeaveItemArray[cbIndex1].cbCardList[1]=cbCurrentCard
        PengHuCardInfo.WeaveItemArray[cbIndex1].cbCardList[2]=cbCurrentCard
        PengHuCardInfo.WeaveItemArray[cbIndex1].cbCardList[3]=cbCurrentCard    

        PengHuCardInfo.cbHuXiCount = PengHuCardInfo.cbHuXiCount + self:GetWeaveHuXi(PengHuCardInfo.WeaveItemArray[cbIndex1])
        --删除扑克
        cbCardIndexTemp[ self:SwitchToCardIndex(cbCurrentCard) ]=0
        --分析扑克
        AnalyseItemArray = {}
        if (self:AnalyseCard(cbCardIndexTemp,AnalyseItemArray)==true) then
            --寻找最优
            local cbHuXiCard=0
            local nBestItem= 0
            for i=1 , #AnalyseItemArray do
                --胡息分析
                if (AnalyseItemArray[i].cbHuXiCount>=cbHuXiCard) then
                    nBestItem=i
                    cbHuXiCard=AnalyseItemArray[i].cbHuXiCount
                end
            end
            PengHuCardInfo.cbHuXiCount = PengHuCardInfo.cbHuXiCount + cbHuXiCard
            --设置结果
            if (nBestItem > 0) then
                ----------设置牌眼
                PengHuCardInfo.cbCardEye=AnalyseItemArray[nBestItem].cbCardEye   

                --------/设置组合
                for i = 1 , AnalyseItemArray[nBestItem].cbWeaveCount do
                    PengHuCardInfo.cbWeaveCount = PengHuCardInfo.cbWeaveCount + 1
                    local cbIndex=PengHuCardInfo.cbWeaveCount
                    PengHuCardInfo.WeaveItemArray[cbIndex]=AnalyseItemArray[nBestItem].WeaveItemArray[i]  
                end
            end
            bHuCardPeng=true
        else
            bHuCardPeng=false
        end

        --两种方式的对比选择胡息更大的作为更优的结果
        --如果吃碰都能组合完成则需要比较
        if((bHuCardChi==true) and (bHuCardPeng==true)) then
            if(PengHuCardInfo.cbHuXiCount>ChiHuCardInfo.cbHuXiCount) then
                if((PengHuCardInfo.cbHuXiCount+HuCardInfo.cbHuXiCount+cbHuXiWeave)>=GameCommon.gameConfig.bCanHuXi) then
                    HuCardInfo.cbCardEye=PengHuCardInfo.cbCardEye
                    HuCardInfo.cbHuXiCount = HuCardInfo.cbHuXiCount + PengHuCardInfo.cbHuXiCount
                    for i = 1 , PengHuCardInfo.cbWeaveCount do
                        HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
                        local cbIndex=HuCardInfo.cbWeaveCount
                        HuCardInfo.WeaveItemArray[cbIndex]=PengHuCardInfo.WeaveItemArray[i]
                    end
                    return true , HuCardInfo
                end
            else  
                if((ChiHuCardInfo.cbHuXiCount+HuCardInfo.cbHuXiCount+cbHuXiWeave)>=GameCommon.gameConfig.bCanHuXi) then
                    HuCardInfo.cbCardEye=ChiHuCardInfo.cbCardEye
                    HuCardInfo.cbHuXiCount = HuCardInfo.cbHuXiCount+ ChiHuCardInfo.cbHuXiCount
                    for i = 1 , ChiHuCardInfo.cbWeaveCount do
                        HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
                        local cbIndex=HuCardInfo.cbWeaveCount
                        HuCardInfo.WeaveItemArray[cbIndex]=ChiHuCardInfo.WeaveItemArray[i]
                    end
                    return true , HuCardInfo
                end
            end
        end

        --吃能完成组合，碰不能完成组合，如果吃的胡息大于15则可以胡牌
        if((bHuCardChi==true) and (bHuCardPeng==false)) then
            if((ChiHuCardInfo.cbHuXiCount+HuCardInfo.cbHuXiCount+cbHuXiWeave)>=GameCommon.gameConfig.bCanHuXi) then
                HuCardInfo.cbCardEye=ChiHuCardInfo.cbCardEye
                HuCardInfo.cbHuXiCount= HuCardInfo.cbHuXiCount + ChiHuCardInfo.cbHuXiCount
                for i = 1 , ChiHuCardInfo.cbWeaveCount do
                    HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
                    local cbIndex=HuCardInfo.cbWeaveCount
                    HuCardInfo.WeaveItemArray[cbIndex]=ChiHuCardInfo.WeaveItemArray[i]
                end
                return true , HuCardInfo
            end
        end

        --如果吃不能组合，碰能组合完成，如果胡息能大于15，选择碰胡牌
        if((bHuCardPeng==true) and (bHuCardChi==false)) then
            if((PengHuCardInfo.cbHuXiCount+HuCardInfo.cbHuXiCount+cbHuXiWeave)>=15) then
                HuCardInfo.cbCardEye=PengHuCardInfo.cbCardEye
                HuCardInfo.cbHuXiCount= HuCardInfo.cbHuXiCount + PengHuCardInfo.cbHuXiCount
                for i = 1 ,PengHuCardInfo.cbWeaveCount do
                    HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
                    local cbIndex=HuCardInfo.cbWeaveCount
                    HuCardInfo.WeaveItemArray[cbIndex]=PengHuCardInfo.WeaveItemArray[i]
                end
                return true , HuCardInfo
            end
        end

        return false , HuCardInfo
    elseif (cbCurrentCard ~=0) then
        local index = self:SwitchToCardIndex(cbCurrentCard)
        cbCardIndexTemp[index] = cbCardIndexTemp[index] + 1
    end

    --分析扑克
    AnalyseItemArray = {}
    if self:AnalyseCard(cbCardIndexTemp,AnalyseItemArray)==false then
        return false , HuCardInfo
    end

    --寻找最优
    local cbHuXiCard=0
    local nBestItem=0
    for i = 1 , #AnalyseItemArray do
        --胡息分析
        if (AnalyseItemArray[i].cbHuXiCount>=0) then
            nBestItem=i
            cbHuXiCard=cbHuXiCard+AnalyseItemArray[i].cbHuXiCount
        end
    end
    HuCardInfo.cbHuXiCount = HuCardInfo.cbHuXiCount + cbHuXiCard

    --设置结果
    if (nBestItem > 0) then
        --设置变量
        HuCardInfo.cbCardEye=AnalyseItemArray[nBestItem].cbCardEye

        --设置组合
        for i = 1 , AnalyseItemArray[nBestItem].cbWeaveCount do
            HuCardInfo.cbWeaveCount = HuCardInfo.cbWeaveCount + 1
            local cbIndex=HuCardInfo.cbWeaveCount
            HuCardInfo.WeaveItemArray[cbIndex]=AnalyseItemArray[nBestItem].WeaveItemArray[i]
        end
    end
    if HuCardInfo.cbHuXiCount+cbHuXiWeave >= GameCommon.gameConfig.bCanHuXi then
        return true , HuCardInfo
    end
    return false , HuCardInfo
end

function GameLogic:IsValidCard(cbCardData)--有效判断
    if not cbCardData then
        return false
    end
    local cbValue= Bit:_and(cbCardData,15)
    local cbColor= Bit:_rshift( Bit:_and(cbCardData,240), 4)
    if cbValue>=1 and cbValue<=10 and cbColor<=2 then
    	return true
    end
    return false
end

function GameLogic:GetCardCount(cbCardIndex)--扑克数目
    local cbCount=0
    for i = 0 , 19 do
        cbCount = cbCount + cbCardIndex[i]
    end
    return cbCount
end

function GameLogic:GetWeaveHuXi(WeaveItem)--获取胡息
    --计算胡息
    if WeaveItem.cbWeaveKind == GameCommon.ACK_TI then    --提
        if Bit:_and(WeaveItem.cbCenterCard, GameCommon.MASK_COLOR)==16 then
            return 12
        else
        return 9
        end

    elseif WeaveItem.cbWeaveKind == GameCommon.ACK_PAO then   --跑
        if Bit:_and(WeaveItem.cbCenterCard, GameCommon.MASK_COLOR)==16 then
            return 9
        else
            return 6
        end

    elseif WeaveItem.cbWeaveKind == GameCommon.ACK_WEI then   --偎
        if Bit:_and(WeaveItem.cbCenterCard, GameCommon.MASK_COLOR)==16 then
            return 6
        else
            return 3
        end
    elseif WeaveItem.cbWeaveKind == GameCommon.ACK_CHOUWEI then   --臭偎
        if Bit:_and(WeaveItem.cbCenterCard, GameCommon.MASK_COLOR)==16 then
            return 6
    else
        return 3
    end
    elseif WeaveItem.cbWeaveKind == GameCommon.ACK_PENG then  --碰
        if Bit:_and(WeaveItem.cbCenterCard, GameCommon.MASK_COLOR)==16 then
            return 3
        else
            return 1
        end
    elseif WeaveItem.cbWeaveKind == GameCommon.ACK_CHI then   --吃
        local cbValue1= Bit:_and(WeaveItem.cbCardList[1], GameCommon.MASK_VALUE)
        if WeaveItem.cbCardList[1] == 33 then
            cbValue1 = 33
        end
        local cbValue2= Bit:_and(WeaveItem.cbCardList[2], GameCommon.MASK_VALUE)
        if WeaveItem.cbCardList[2] == 33 then
            cbValue1 = 33
        end
        local cbValue3= Bit:_and(WeaveItem.cbCardList[3], GameCommon.MASK_VALUE)
        if WeaveItem.cbCardList[3] == 33 then
            cbValue1 = 33
        end
    
        local table123 = {[1] = 1,[2] = 2, [3] = 3}
        local table2710 = {[1] = 2, [2] = 7 , [3] = 10}
        local table1510 = {[1] = 1, [2] = 5 , [3] = 10}
        local wwCount = 0
        local color = nil
        for i = 1 , 3 do
            if WeaveItem.cbCardList[i] == 33 then
                wwCount = wwCount + 1
            elseif color == nil or Bit:_and(WeaveItem.cbCardList[i],GameCommon.MASK_COLOR) == color then
                color = Bit:_and(WeaveItem.cbCardList[i], GameCommon.MASK_COLOR)
                local cbValue = Bit:_and(WeaveItem.cbCardList[i], GameCommon.MASK_VALUE)
                for key, var in pairs(table123) do
                    if var == cbValue then
                        table.remove(table123,key)
                        break
                    end
                end
                for key, var in pairs(table2710) do
                    if var == cbValue then
                        table.remove(table2710,key)
                        break
                    end
                end
                for key, var in pairs(table1510) do
                    if var == cbValue then
                        table.remove(table1510,key)
                        break
                    end
                end
            end
    
        end
    
    if #table123 == wwCount or #table2710 == wwCount or #table1510 == wwCount then
            if color == 16 then
                return 6
            else
                return 3
            end
        end
    
    else
    
    end
    
    return 0
end


function GameLogic:SwitchToCardData(cbCardIndex)--扑克转换
    local cbCardIndex = cbCardIndex - 1
    assert(cbCardIndex<=20)
    local value = Bit:_xor( Bit:_lshift(cbCardIndex / 10,4) , (cbCardIndex % 10 + 1 ))
    return value
end

function GameLogic:SwitchToCardIndex(cbCardData)--扑克转换
    assert(self:IsValidCard(cbCardData))
    local value = Bit:_rshift( Bit:_and(cbCardData,240),4) * 10 + Bit:_and(cbCardData,15) - 1 
    return value + 1
end

function GameLogic:SwitchToCardDatas(cbCardIndex, cbCardData, bMaxCount)--扑克转换
    --转换扑克
    local bPosition=0
    for i = 1 , 20 do
        local cbIndex=(i%2)*10+i/2
        if (cbCardIndex[cbIndex] ~= 0) then
            for j = 0 , cbCardIndex[cbIndex] - 1 do
                assert(bPosition<bMaxCount)
                bPosition = bPosition + 1
                cbCardData[bPosition]= self:SwitchToCardData(cbIndex)
            end
        end
    end

    return bPosition
end

function GameLogic:SwitchToCardIndexs(cbCardData, bCardCount)--扑克转换
    --设置变量
    local cbCardIndex = {}

    --转换扑克
    for i = 1 , bCardCount do
        if cbCardIndex[i] == nil then
            cbCardIndex[i] = 0
        end
        print("cbCardData[i]",i,cbCardData[i],bCardCount)
        if self:IsValidCard(cbCardData[i]) then
            local index = self:SwitchToCardIndex(cbCardData[i])
            if cbCardIndex[index] == nil then
                cbCardIndex[index] = 0
            end
            cbCardIndex[index] = cbCardIndex[index] + 1
        end
    end
    for i = 1 , 21 do
        if cbCardIndex[i] == nil then
        	cbCardIndex[i] = 0
        end
    end
    return cbCardIndex
end

--分析扑克
function GameLogic:AnalyseCard(cbCardIndex,data)
    --变量定义
    local AnalyseItemArray = {}
    local cbWeaveItemCount=0
    local WeaveItem = {}

    --数目统计
    local cbCardCount=0
    for i = 1 , 20 do
        cbCardCount = cbCardCount + cbCardIndex[i]
    end

    --数目判断
    if (cbCardCount==0) then
        return true,AnalyseItemArray
    end
    if ((cbCardCount%3 ~= 0) and ((cbCardCount+1)%3 ~=0)) then
        return false,AnalyseItemArray
    end

    --需求计算
    local bLessWeavItem=math.floor(cbCardCount/3)
    local bNeedCardEye=((cbCardCount+1)%3==0)

    --单吊判断
    if ((bLessWeavItem==0) and (bNeedCardEye==true)) then
        --牌眼判断
        for i = 1 , 20 do
            if (cbCardIndex[i]==2) then
                --变量定义
                local AnalyseItem = {}

                --设置结果
                AnalyseItem.cbHuXiCount=0
                AnalyseItem.cbWeaveCount=0
                AnalyseItem.cbCardEye= self:SwitchToCardData(i)

                --插入结果
                table.insert(AnalyseItemArray,AnalyseItem)
                return true,AnalyseItemArray
            end
        end

        return false,AnalyseItemArray
    end

    return self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye,data)
end

function GameLogic:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye,data)

    local ectDui  = 2
	local ectEat  = 3
    local cbWeaveItemCount=0
    local WeaveItem = {}
    --变量定义
    local AnalyseItem = {}
    --设置结果
    AnalyseItem.cbHuXiCount=0
    AnalyseItem.cbCardEye=cbCardEye
    AnalyseItem.cbWeaveCount=bLessWeavItem
    AnalyseItem.WeaveItemArray = {}
    local I = self:NewRemain(cbCardIndex)
    if(I == 100) then 
        return true , AnalyseItemArray -- 递归退出条件：如果没有剩牌，则和牌返回。
    end    
    local cbCardData= self:SwitchToCardData(I) 
    if data == nil then  
        --3张组合
        if(cbCardIndex[I] >=3) then 
            cbCardIndex[I] = cbCardIndex[I] - 3
            if(self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye)) then	
                if(cbWeaveItemCount < 0 or cbWeaveItemCount > 7)then
                    cbWeaveItemCount = 0
                end  
                cbWeaveItemCount = cbWeaveItemCount + 1
                WeaveItem[cbWeaveItemCount] = WeaveItem[cbWeaveItemCount] or {}
                WeaveItem[cbWeaveItemCount].cbCardList = WeaveItem[cbWeaveItemCount].cbCardList or {}
                WeaveItem[cbWeaveItemCount].cbCardCount= 3
                WeaveItem[cbWeaveItemCount].cbWeaveKind=GameCommon.ACK_WEI
                WeaveItem[cbWeaveItemCount].cbCenterCard=I
                WeaveItem[cbWeaveItemCount].cbCardList[1]=cbCardData
                WeaveItem[cbWeaveItemCount].cbCardList[2]=cbCardData
                WeaveItem[cbWeaveItemCount].cbCardList[3]= cbCardData    
                AnalyseItem.WeaveItemArray[cbWeaveItemCount]= WeaveItem[cbWeaveItemCount]
                AnalyseItem.cbHuXiCount = AnalyseItem.cbHuXiCount + self:GetWeaveHuXi(AnalyseItem.WeaveItemArray[cbWeaveItemCount])
                --插入结果
                table.insert(AnalyseItemArray,AnalyseItem)               
                cbCardIndex[I] =cbCardIndex[I] + 3
                return true , AnalyseItemArray
            end
            cbCardIndex[I] = cbCardIndex[I] + 3
            
        end
    end 
	--2张组合(将牌)
	if(cbCardIndex[I] >=2) then 
		if (bNeedCardEye == true) then   --如果之前没有将牌，且当前牌不少于2张
			bNeedCardEye = false
			cbCardIndex[I] = cbCardIndex[I] - 2
			if(self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye)) 	then	
				if(cbWeaveItemCount < 0 or cbWeaveItemCount > 7)then
					cbWeaveItemCount = 0
                end                 
				cbCardIndex[I] =cbCardIndex[I] + 2
				return true , AnalyseItemArray
            end
			cbCardIndex[I] = cbCardIndex[I] + 2
			bNeedCardEye = true
        end
    end

	--顺子组合方式
	local FengCheckerCount = 0
	local FengChecker ={}
	local K = 0
	if  (I >= 1 and  I<= 8) or (I >=11 and I<=18) then
	 	K = 2
    end
	for  J = I + 1,I + K do
		if (cbCardIndex[ J ] > 0 ) then		
			if(FengCheckerCount > 2)then			
				FengCheckerCount = 0
            end
            FengChecker[FengCheckerCount] = J            
            FengCheckerCount = FengCheckerCount + 1
        end
    end
	if ( FengCheckerCount == 2 ) then
	 --找到原始顺子
		cbCardIndex[ I ] = cbCardIndex[ I ] -1
		cbCardIndex[ FengChecker [ 0 ] ] = cbCardIndex[ FengChecker [ 0 ] ]-1
		cbCardIndex[ FengChecker [ 1 ] ] = cbCardIndex[ FengChecker [ 1 ] ] -1      --和牌数减1	
		if (self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye)) then
			if(cbWeaveItemCount < 0 or cbWeaveItemCount > 7) then
				cbWeaveItemCount = 0;
            end            
            cbWeaveItemCount = cbWeaveItemCount + 1
            WeaveItem[cbWeaveItemCount] = WeaveItem[cbWeaveItemCount] or {}
            WeaveItem[cbWeaveItemCount].cbCardList = WeaveItem[cbWeaveItemCount].cbCardList or {}
            WeaveItem[cbWeaveItemCount].cbCardCount= 3
            WeaveItem[cbWeaveItemCount].cbWeaveKind=GameCommon.ACK_CHI
            WeaveItem[cbWeaveItemCount].cbCenterCard=cbCardData
            WeaveItem[cbWeaveItemCount].cbCardList[1]=cbCardData
            WeaveItem[cbWeaveItemCount].cbCardList[2]=cbCardData +1
            WeaveItem[cbWeaveItemCount].cbCardList[3]= cbCardData +2

            AnalyseItem.WeaveItemArray[cbWeaveItemCount]= WeaveItem[cbWeaveItemCount]
            AnalyseItem.cbHuXiCount = AnalyseItem.cbHuXiCount + self:GetWeaveHuXi(AnalyseItem.WeaveItemArray[cbWeaveItemCount])
            --插入结果
            table.insert(AnalyseItemArray,AnalyseItem)

			cbCardIndex[ I ] =cbCardIndex[ I ] +1
			cbCardIndex[ FengChecker [ 0 ] ] =cbCardIndex[ FengChecker [ 0 ] ] +1
			cbCardIndex[ FengChecker [ 1 ] ] =cbCardIndex[ FengChecker [ 1 ] ] +1
			return true , AnalyseItemArray
        end
        cbCardIndex[ I ] =cbCardIndex[ I ] +1
        cbCardIndex[ FengChecker [ 0 ] ] =cbCardIndex[ FengChecker [ 0 ] ] +1
        cbCardIndex[ FengChecker [ 1 ] ] =cbCardIndex[ FengChecker [ 1 ] ] +1
    end

    --大小，小大吃组合方式
	local FengCheckerCount = 0
	local FengChecker ={}
	local K = 0

    --变量定义
    local idx = (I+10)%21
    if idx == 0 then
        idx = 1
    end
    --大小搭吃
    if ((cbCardIndex[I]>=2) and (cbCardIndex[idx]>=1)) then
        cbCardIndex[ I ] = cbCardIndex[ I ] - 2
		cbCardIndex[ idx ] = cbCardIndex[ idx ]-1
		if (self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye)) then
			if(cbWeaveItemCount < 0 or cbWeaveItemCount > 7) then
				cbWeaveItemCount = 0;
            end            
            cbWeaveItemCount = cbWeaveItemCount + 1
            WeaveItem[cbWeaveItemCount] = WeaveItem[cbWeaveItemCount] or {}
            WeaveItem[cbWeaveItemCount].cbCardList = WeaveItem[cbWeaveItemCount].cbCardList or {}
            WeaveItem[cbWeaveItemCount].cbCardCount= 3
            WeaveItem[cbWeaveItemCount].cbWeaveKind=GameCommon.ACK_CHI
            WeaveItem[cbWeaveItemCount].cbCenterCard=I
            WeaveItem[cbWeaveItemCount].cbCardList[1]=cbCardData
            WeaveItem[cbWeaveItemCount].cbCardList[2]=cbCardData
            WeaveItem[cbWeaveItemCount].cbCardList[3]= (cbCardData+16)%32

            AnalyseItem.WeaveItemArray[cbWeaveItemCount]= WeaveItem[cbWeaveItemCount]
            AnalyseItem.cbHuXiCount = AnalyseItem.cbHuXiCount + self:GetWeaveHuXi(AnalyseItem.WeaveItemArray[cbWeaveItemCount])
            --插入结果
            table.insert(AnalyseItemArray,AnalyseItem)
            cbCardIndex[ I ] = cbCardIndex[ I ] + 2
            cbCardIndex[ idx ] = cbCardIndex[ idx ] + 1
			return true , AnalyseItemArray
        end
        cbCardIndex[ I ] = cbCardIndex[ I ] + 2
        cbCardIndex[ idx ] = cbCardIndex[ idx ] + 1
    end

    --大小搭吃
    if ((cbCardIndex[I]>=1) and (cbCardIndex[idx]>=2)) then
        cbCardIndex[ I ] = cbCardIndex[ I ] - 1
		cbCardIndex[ idx ] = cbCardIndex[ idx ]-2
		if (self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye)) then
			if(cbWeaveItemCount < 0 or cbWeaveItemCount > 7) then
				cbWeaveItemCount = 0;
            end            
            cbWeaveItemCount = cbWeaveItemCount + 1
            WeaveItem[cbWeaveItemCount] = WeaveItem[cbWeaveItemCount] or {}
            WeaveItem[cbWeaveItemCount].cbCardList = WeaveItem[cbWeaveItemCount].cbCardList or {}
            WeaveItem[cbWeaveItemCount].cbCardCount= 3
            WeaveItem[cbWeaveItemCount].cbWeaveKind=GameCommon.ACK_CHI
            WeaveItem[cbWeaveItemCount].cbCenterCard=I
            WeaveItem[cbWeaveItemCount].cbCardList[1]=cbCardData
            WeaveItem[cbWeaveItemCount].cbCardList[2]=(cbCardData+16)%32
            WeaveItem[cbWeaveItemCount].cbCardList[3]=(cbCardData+16)%32

            AnalyseItem.WeaveItemArray[cbWeaveItemCount]= WeaveItem[cbWeaveItemCount]
            AnalyseItem.cbHuXiCount = AnalyseItem.cbHuXiCount + self:GetWeaveHuXi(AnalyseItem.WeaveItemArray[cbWeaveItemCount])
            --插入结果
            table.insert(AnalyseItemArray,AnalyseItem)
            cbCardIndex[ I ] = cbCardIndex[ I ] + 1
            cbCardIndex[ idx ] = cbCardIndex[ idx ] + 2
			return true , AnalyseItemArray
        end
        cbCardIndex[ I ] = cbCardIndex[ I ] + 1
        cbCardIndex[ idx ] = cbCardIndex[ idx ] + 2
    end

    --二七十吃
    if I == 2 or I == 12 then
        if ((cbCardIndex[I+5]>=1) and (cbCardIndex[I+8]>=1)) then
		cbCardIndex[ I ] = cbCardIndex[ I ] -1
		cbCardIndex[ I+5 ] = cbCardIndex[I+5]-1
		cbCardIndex[I+8 ] = cbCardIndex[I+8] -1      --和牌数减1	
            if (self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye)) then
                if(cbWeaveItemCount < 0 or cbWeaveItemCount > 7) then
                    cbWeaveItemCount = 0;
                end
                cbWeaveItemCount = cbWeaveItemCount + 1
                WeaveItem[cbWeaveItemCount] = WeaveItem[cbWeaveItemCount] or {}
                WeaveItem[cbWeaveItemCount].cbCardList = WeaveItem[cbWeaveItemCount].cbCardList or {}
                WeaveItem[cbWeaveItemCount].cbCardCount=3
                WeaveItem[cbWeaveItemCount].cbWeaveKind=GameCommon.ACK_CHI
                WeaveItem[cbWeaveItemCount].cbCenterCard=cbCardData
                WeaveItem[cbWeaveItemCount].cbCardList[1]=cbCardData
                WeaveItem[cbWeaveItemCount].cbCardList[2]=cbCardData+5
                WeaveItem[cbWeaveItemCount].cbCardList[3]=cbCardData+8         
                
                AnalyseItem.WeaveItemArray[cbWeaveItemCount]= WeaveItem[cbWeaveItemCount]
                AnalyseItem.cbHuXiCount = AnalyseItem.cbHuXiCount + self:GetWeaveHuXi(AnalyseItem.WeaveItemArray[cbWeaveItemCount])
                --插入结果
                table.insert(AnalyseItemArray,AnalyseItem)
                cbCardIndex[ I ] =cbCardIndex[ I ] +1
                cbCardIndex[ I+5 ] =cbCardIndex[I+5] +1
                cbCardIndex[ I+8 ] =cbCardIndex[ I+8 ] +1
                return true , AnalyseItemArray
            end
        cbCardIndex[ I ] =cbCardIndex[ I ] +1
        cbCardIndex[ I+5] =cbCardIndex[I+5 ] +1
        cbCardIndex[ I+8 ] =cbCardIndex[ I+8 ] +1
        end
    end

    
    --一五十吃
    if GameCommon.gameConfig ~= nil and GameCommon.gameConfig.bYiWuShi ~= nil and type(GameCommon.gameConfig.bYiWuShi) == "number" and GameCommon.gameConfig.bYiWuShi == 1 then
        if I == 1 or I == 11 then
            if ((cbCardIndex[I+4]>=1) and (cbCardIndex[I+9]>=1)) then
            cbCardIndex[ I ] = cbCardIndex[ I ] -1
            cbCardIndex[ I+4] = cbCardIndex[I+4]-1
            cbCardIndex[I+9 ] = cbCardIndex[I+9] -1      --和牌数减1	
                if (self:NewHupai(cbCardIndex, AnalyseItemArray,bLessWeavItem,bNeedCardEye)) then
                    if(cbWeaveItemCount < 0 or cbWeaveItemCount > 7) then
                        cbWeaveItemCount = 0;
                    end
                    cbWeaveItemCount = cbWeaveItemCount + 1
                    WeaveItem[cbWeaveItemCount] = WeaveItem[cbWeaveItemCount] or {}
                    WeaveItem[cbWeaveItemCount].cbCardList = WeaveItem[cbWeaveItemCount].cbCardList or {}
                    WeaveItem[cbWeaveItemCount].cbCardCount=3
                    WeaveItem[cbWeaveItemCount].cbWeaveKind=GameCommon.ACK_CHI
                    WeaveItem[cbWeaveItemCount].cbCenterCard=cbCardData
                    WeaveItem[cbWeaveItemCount].cbCardList[1]=cbCardData
                    WeaveItem[cbWeaveItemCount].cbCardList[2]=cbCardData+4
                    WeaveItem[cbWeaveItemCount].cbCardList[3]=cbCardData+9         
                    
                    AnalyseItem.WeaveItemArray[cbWeaveItemCount]= WeaveItem[cbWeaveItemCount]
                    AnalyseItem.cbHuXiCount = AnalyseItem.cbHuXiCount + self:GetWeaveHuXi(AnalyseItem.WeaveItemArray[cbWeaveItemCount])
                    --插入结果
                    table.insert(AnalyseItemArray,AnalyseItem)
                    cbCardIndex[ I ] =cbCardIndex[ I ] +1
                    cbCardIndex[ I+4 ] =cbCardIndex[I+4] +1
                    cbCardIndex[ I+9 ] =cbCardIndex[ I+9 ] +1
                    return true , AnalyseItemArray
                end
            cbCardIndex[ I ] =cbCardIndex[ I ] +1
            cbCardIndex[ I+4] =cbCardIndex[I+4] +1
            cbCardIndex[ I+9 ] =cbCardIndex[I+9] +1
            end
        end
    end
	-- 无法全部组合，不和！
	return false
end 

function GameLogic:NewRemain(cbCardIndex) 
    for i = 1, 20 do
        if cbCardIndex[i] ~= 0 then 
			return i
        end 
    end 
	return 100;

end


function GameLogic:TakeOutChiCard(cbCardIndex, cbCurrentCard)--提取吃牌
    local cbResultCard = {}
    --效验扑克
    assert(cbCurrentCard~=0)
    if (cbCurrentCard==0) then
        return 0,cbResultCard,cbCardIndex
    end
    
    --变量定义
    local cbFirstIndex=0
    local cbCurrentIndex=self:SwitchToCardIndex(cbCurrentCard)

    --大小搭吃
    local cbReverseIndex= cbCurrentIndex + 10
    if cbReverseIndex > 20 then
        cbReverseIndex = cbCurrentIndex - 10
    end
    if ((cbCardIndex[cbCurrentIndex] >= 2) and (cbCardIndex[cbReverseIndex]>=1) and (cbCardIndex[cbReverseIndex] < 3)) then
        --删除扑克
        cbCardIndex[cbCurrentIndex] = cbCardIndex[cbCurrentIndex] - 1
        cbCardIndex[cbCurrentIndex] = cbCardIndex[cbCurrentIndex] - 1
        cbCardIndex[cbReverseIndex] = cbCardIndex[cbReverseIndex] - 1

        --设置结果
        cbResultCard[1]=cbCurrentCard
        cbResultCard[2]=cbCurrentCard
        cbResultCard[3]= self:SwitchToCardData(cbReverseIndex)
        
        if Bit:_and(cbCurrentCard , GameCommon.MASK_COLOR)== 0 then
            return GameCommon.CK_XXD,cbResultCard,cbCardIndex
        end
        return GameCommon.CK_XDD,cbResultCard,cbCardIndex
    end

    --大小搭吃
    if (cbCardIndex[cbReverseIndex]==2) then
        --删除扑克
        cbCardIndex[cbCurrentIndex] = cbCardIndex[cbCurrentIndex] - 1
        cbCardIndex[cbReverseIndex] = cbCardIndex[cbReverseIndex] - 2

        --设置结果
        cbResultCard[1]=cbCurrentCard
        cbResultCard[2]= self:SwitchToCardData(cbReverseIndex)
        cbResultCard[3]= self:SwitchToCardData(cbReverseIndex)
        if Bit:_and(cbCurrentCard , GameCommon.MASK_COLOR)== 0 then
            return GameCommon.CK_XDD,cbResultCard,cbCardIndex
        end
        return GameCommon.CK_XXD,cbResultCard,cbCardIndex
    end

    --二七十吃
    local bCardValue = cbCurrentIndex
    if bCardValue > 10 then
        bCardValue = cbCurrentIndex - 10
    end
    if bCardValue == 2 or bCardValue == 7 or bCardValue == 10 then
        --变量定义
        local cbExcursion = {[1] = 2,[2] = 7, [3] = 10}
        local cbInceptIndex = 0
        if cbCurrentIndex > 10 then
            cbInceptIndex = 10
        end
        
        --类型判断
        local index= 1
        for i=1 , #cbExcursion  do
            local cbIndex=cbInceptIndex+cbExcursion[i]
            if ((cbCardIndex[cbIndex]==0) or (cbCardIndex[cbIndex]>=3)) then
                break
            end
            index = i
        end
        --成功判断
        if (index== #cbExcursion) then
            --删除扑克
            cbCardIndex[cbInceptIndex+cbExcursion[1]] = cbCardIndex[cbInceptIndex+cbExcursion[1]] - 1
            cbCardIndex[cbInceptIndex+cbExcursion[2]] = cbCardIndex[cbInceptIndex+cbExcursion[2]] - 1
            cbCardIndex[cbInceptIndex+cbExcursion[3]] = cbCardIndex[cbInceptIndex+cbExcursion[3]] - 1

            --设置结果
            cbResultCard[1]=self:SwitchToCardData(cbInceptIndex+cbExcursion[1])
            cbResultCard[2]=self:SwitchToCardData(cbInceptIndex+cbExcursion[2])
            cbResultCard[3]=self:SwitchToCardData(cbInceptIndex+cbExcursion[3])
            return GameCommon.CK_EQS,cbResultCard,cbCardIndex
        end
    end
    
    if GameCommon.gameConfig ~= nil and GameCommon.gameConfig.bYiWuShi ~= nil and type(GameCommon.gameConfig.bYiWuShi) == "number" and GameCommon.gameConfig.bYiWuShi == 1 then
        --一五十吃
        local bCardValue = cbCurrentIndex
        if bCardValue > 10 then
            bCardValue = cbCurrentIndex - 10
        end
        if bCardValue == 1 or bCardValue == 5 or bCardValue == 10 then
            --变量定义
            local cbExcursion = {[1] = 1,[2] = 5, [3] = 10}
            local cbInceptIndex = 0
            if cbCurrentIndex > 10 then
                cbInceptIndex = 10
            end
    
            --类型判断
            local index= 1
            for i=1 , #cbExcursion  do
                local cbIndex=cbInceptIndex+cbExcursion[i]
                if ((cbCardIndex[cbIndex]==0) or (cbCardIndex[cbIndex]>=3)) then
                    break
                end
                index = i
            end
            --成功判断
            if (index== #cbExcursion) then
                --删除扑克
                cbCardIndex[cbInceptIndex+cbExcursion[1]] = cbCardIndex[cbInceptIndex+cbExcursion[1]] - 1
                cbCardIndex[cbInceptIndex+cbExcursion[2]] = cbCardIndex[cbInceptIndex+cbExcursion[2]] - 1
                cbCardIndex[cbInceptIndex+cbExcursion[3]] = cbCardIndex[cbInceptIndex+cbExcursion[3]] - 1
    
                --设置结果
                cbResultCard[1]=self:SwitchToCardData(cbInceptIndex+cbExcursion[1])
                cbResultCard[2]=self:SwitchToCardData(cbInceptIndex+cbExcursion[2])
                cbResultCard[3]=self:SwitchToCardData(cbInceptIndex+cbExcursion[3])
                return GameCommon.CK_YWS,cbResultCard,cbCardIndex
            end
        end
    end
    
    --顺子判断
    local cbExcursion = {[1]= 1,[2]= 2,[3]= 3}
    for i = 1 , #cbExcursion do
        local cbValueIndex=cbCurrentIndex
        if cbCurrentIndex > 10 then
            cbValueIndex=cbCurrentIndex - 10
        end
        if (cbValueIndex >= cbExcursion[i]) and ((cbValueIndex - cbExcursion[i]) <= 7) then
            --索引定义
            local cbFirstIndex = cbCurrentIndex - cbExcursion[i] + 1
            
            if ((cbCardIndex[cbFirstIndex]==0) or (cbCardIndex[cbFirstIndex]>=3)) then
            
            elseif ((cbCardIndex[cbFirstIndex+1]==0) or (cbCardIndex[cbFirstIndex+1]>=3)) then
            
            elseif ((cbCardIndex[cbFirstIndex+2]==0) or (cbCardIndex[cbFirstIndex+2]>=3)) then
            
            else
                --删除扑克
                cbCardIndex[cbFirstIndex] = cbCardIndex[cbFirstIndex] - 1
                cbCardIndex[cbFirstIndex+1] = cbCardIndex[cbFirstIndex+1] - 1
                cbCardIndex[cbFirstIndex+2] = cbCardIndex[cbFirstIndex+2] - 1
                --设置结果
                cbResultCard[1]=self:SwitchToCardData(cbFirstIndex)
                cbResultCard[2]=self:SwitchToCardData(cbFirstIndex+1)
                cbResultCard[3]=self:SwitchToCardData(cbFirstIndex+2)
                local cbChiKind = {[1] = GameCommon.CK_LEFT,[2] = GameCommon.CK_CENTER,[3] = GameCommon.CK_RIGHT}
                return cbChiKind[i],cbResultCard,cbCardIndex
            end
        end
    end
    
    return 0,cbResultCard,cbCardIndex
end

--跑胡子手牌排列方式控制
function GameLogic:sortHandCard(cardIndex, maxHanCardRow,pos,num)
    local cardIndex = cardIndex
    local maxHanCardRow = maxHanCardRow
    local pos = pos
    local num = num
    local cardStackInfo = {}
    if num == 1  then 
        cardStackInfo = self:sortHandCardone(cardIndex, maxHanCardRow,pos)
    elseif num == 2  then 
        cardStackInfo = self:sortHandCardtwo(cardIndex, maxHanCardRow,pos)
    elseif num == 3  then 
        cardStackInfo = self:sortHandCardthree(cardIndex, maxHanCardRow,pos) 
    end 
    return cardStackInfo 
end
--手牌排序1
function GameLogic:sortHandCardone(cardIndex, maxHanCardRow,pos)
    local cardStackInfo = {}
    --3,4张遍历
    for i=1 , 20 do
        if cardIndex[i] >= 3 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i]=0
        end
    end

    --对子
    for i=1 , 20 do
        if cardIndex[i]==2 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i]=0
        end
    end

    --大二七十
    for i = 1, 2 do
        if cardIndex[12] >= 1  and  cardIndex[17] >= 1  and  cardIndex[20] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[20]=cardIndex[20]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(20)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


            cardIndex[17]=cardIndex[17]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(17)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[12]=cardIndex[12]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(12)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    --大一二三
    for i = 1, 2 do
        if cardIndex[11] >= 1  and  cardIndex[12] >= 1  and  cardIndex[13] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[13]=cardIndex[13]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(13)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[12]=cardIndex[12]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(12)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[11]=cardIndex[11]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(11)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)



            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    --大一五十
    if GameCommon.gameConfig.bYiWuShi == 1 then
        for i = 1, 2 do
            if cardIndex[11] >= 1  and  cardIndex[15] >= 1  and  cardIndex[20] >= 1  and #cardStackInfo <=maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 3
                cardinfo.cbCardData = {}

                cardIndex[20]=cardIndex[20]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(20)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                cardIndex[15]=cardIndex[15]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(15)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                cardIndex[11]=cardIndex[11]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(11)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            end
        end
    end

    --小二七十
    for i = 1, 2 do
        if cardIndex[2] >= 1  and  cardIndex[7] >= 1  and  cardIndex[10] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[10]=cardIndex[10]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(10)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[7]=cardIndex[7]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(7)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[2]=cardIndex[2]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(2)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end
    --小一二三
    for i = 1, 2 do
        if cardIndex[1] >= 1  and  cardIndex[2] >= 1  and  cardIndex[3] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[3]=cardIndex[3]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(3)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[2]=cardIndex[2]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(2)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[1]=cardIndex[1]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(1)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end
    --小一五十
    if GameCommon.gameConfig.bYiWuShi == 1 then
        for i = 1, 2 do
            if cardIndex[1] >= 1  and  cardIndex[5] >= 1  and  cardIndex[10] >= 1  and #cardStackInfo <=maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 3
                cardinfo.cbCardData = {}

                cardIndex[10]=cardIndex[10]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(10)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                cardIndex[5]=cardIndex[5]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(5)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                cardIndex[1]=cardIndex[1]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(1)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            end
        end
    end

    --顺子
    local i = 1 
    while i <= 18 do
        if cardIndex[i]==1  and  cardIndex[i+1]==1  and  cardIndex[i+2] ==1 then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}


            cardIndex[i+2]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+2)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i+1]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+1)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
        if i==8 then
            i=10
        end
        i = i + 1
    end

    --两个大小
    for i=1 , 10 do
        if cardIndex[i]==1  and  cardIndex[i+10]==1  and #cardStackInfo < maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 2
            cardinfo.cbCardData = {}

            cardIndex[i+10]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+10)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    --补单1、2、3、7、10、5
    local tableTemp = {20,17,12}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    local tableTemp = {13,12,11}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    if GameCommon.gameConfig.bYiWuShi == 1 then
        local tableTemp = {20,15,11}
        local cardinfo = {}
        cardinfo.nCardCount = 0
        cardinfo.cbCardData = {}
        for iKey, iVar in pairs(tableTemp) do
            if cardIndex[iVar] == 1 then
                cardinfo.nCardCount = cardinfo.nCardCount + 1
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(iVar)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
        end
        if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
            for key, var in pairs(cardinfo.cbCardData) do
                local index = GameLogic:SwitchToCardIndex(var.data)
                cardIndex[index]=0
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    local tableTemp = {10,7,2}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 and #cardStackInfo < maxHanCardRow then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    local tableTemp = {3,2,1}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    if GameCommon.gameConfig.bYiWuShi == 1 then
        local tableTemp = {10,5,1}
        local cardinfo = {}
        cardinfo.nCardCount = 0
        cardinfo.cbCardData = {}
        for iKey, iVar in pairs(tableTemp) do
            if cardIndex[iVar] == 1 then
                cardinfo.nCardCount = cardinfo.nCardCount + 1
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(iVar)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
        end
        if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
            for key, var in pairs(cardinfo.cbCardData) do
                local index = GameLogic:SwitchToCardIndex(var.data)
                cardIndex[index]=0
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    --对子上补成大小吃
    for i=1 , 20 do
        if cardIndex[i]==1 then
            local data = GameLogic:SwitchToCardData(i)
            local value = Bit:_and(data,0x0F)
            local color = Bit:_rshift(Bit:_and(data,0xF0),4)
            for key, var in pairs(cardStackInfo) do
                if var.nCardCount == 2 then
                    local data1 = var.cbCardData[1].data
                    local data2 = var.cbCardData[2].data
                    local value1 = Bit:_and(data1,0x0F)
                    local color1 = Bit:_rshift(Bit:_and(data1,0xF0),4)
                    if data1 == data2 and value == value1 and color1 ~= color then
                        var.nCardCount = var.nCardCount + 1
                        cardIndex[i]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i)
                        _cardData.pt = pos
                        table.insert(var.cbCardData,#var.cbCardData+1,_cardData)
                        break
                    end
                end 
            end
        end
    end

    --2个顺子
    local i = 1
    while #cardStackInfo < maxHanCardRow and i <= 19 do
        if cardIndex[i]==1  and  cardIndex[i+1]==1 then
            local cardinfo = {}
            cardinfo.nCardCount = 2
            cardinfo.cbCardData = {}

            cardIndex[i+1]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+1)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)    
        end
        if i==9 then
            i=10
        end
        i = i + 1
    end

    --随便铺
    for i=1 ,20 do
        if cardIndex[i]==1 then
            if #cardStackInfo < maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 1
                cardinfo.cbCardData = {}
                for j= 1 , cardIndex[i] do 
                    local _cardData = {}
                    _cardData.data=GameLogic:SwitchToCardData(i)
                    _cardData.pt = pos
                    table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
                end
                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            else
                for j= #cardStackInfo , 1 , -1 do
                    if cardStackInfo[j].nCardCount < 3 then
                        cardStackInfo[j].nCardCount = cardStackInfo[j].nCardCount + 1
                        cardIndex[i]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i)
                        _cardData.pt = pos
                        table.insert(cardStackInfo[j].cbCardData,#cardStackInfo[j].cbCardData+1,_cardData)
                        break
                    end
                end
            end
        end
    end
    return cardStackInfo
end


--手牌排序2
function GameLogic:sortHandCardtwo(cardIndex, maxHanCardRow,pos)
    local cardStackInfo = {}
    --3,4张遍历
    for i=1 , 20 do
        if cardIndex[i] >= 3 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i]=0
        end
    end

    --大二七十
    for i = 1, 2 do
        if cardIndex[12] >= 1  and  cardIndex[17] >= 1  and  cardIndex[20] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[20]=cardIndex[20]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(20)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[17]=cardIndex[17]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(17)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[12]=cardIndex[12]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(12)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    --大一二三
    for i = 1, 2 do
        if cardIndex[11] >= 1  and  cardIndex[12] >= 1  and  cardIndex[13] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[13]=cardIndex[13]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(13)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[12]=cardIndex[12]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(12)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[11]=cardIndex[11]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(11)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    --大一五十
    if GameCommon.gameConfig.bYiWuShi == 1 then
        for i = 1, 2 do
            if cardIndex[11] >= 1  and  cardIndex[15] >= 1  and  cardIndex[20] >= 1  and #cardStackInfo <=maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 3
                cardinfo.cbCardData = {}

                cardIndex[20]=cardIndex[20]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(20)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                cardIndex[15]=cardIndex[15]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(15)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                cardIndex[11]=cardIndex[11]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(11)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            end
        end
    end

    --小二七十
    for i = 1, 2 do
        if cardIndex[2] >= 1  and  cardIndex[7] >= 1  and  cardIndex[10] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[10]=cardIndex[10]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(10)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[7]=cardIndex[7]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(7)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[2]=cardIndex[2]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(2)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)



            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end
    --小一二三
    for i = 1, 2 do
        if cardIndex[1] >= 1  and  cardIndex[2] >= 1  and  cardIndex[3] >= 1  and #cardStackInfo <=maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[3]=cardIndex[3]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(3)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[2]=cardIndex[2]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(2)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


            cardIndex[1]=cardIndex[1]-1    
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(1)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)



            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end
    --小一五十
    if GameCommon.gameConfig.bYiWuShi == 1 then
        for i = 1, 2 do
            if cardIndex[1] >= 1  and  cardIndex[5] >= 1  and  cardIndex[10] >= 1  and #cardStackInfo <=maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 3
                cardinfo.cbCardData = {}

                cardIndex[10]=cardIndex[10]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(10)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

                cardIndex[5]=cardIndex[5]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(5)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


                cardIndex[1]=cardIndex[1]-1    
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(1)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            end
        end
    end

    --对子
    for i=1 , 20 do
        if cardIndex[i]==2 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i]=0
        end
    end

    --顺子
    local i = 1 
    while i <= 18 do
        if cardIndex[i]==1  and  cardIndex[i+1]==1  and  cardIndex[i+2] ==1 then
            local cardinfo = {}
            cardinfo.nCardCount = 3
            cardinfo.cbCardData = {}

            cardIndex[i+2]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+2)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i+1]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+1)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)


            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
        if i==8 then
            i=10
        end
        i = i + 1
    end

    --补单1、2、3、7、10、5
    local tableTemp = {20,17,12}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    local tableTemp = {13,12,11}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    if GameCommon.gameConfig.bYiWuShi == 1 then
        local tableTemp = {20,15,11}
        local cardinfo = {}
        cardinfo.nCardCount = 0
        cardinfo.cbCardData = {}
        for iKey, iVar in pairs(tableTemp) do
            if cardIndex[iVar] == 1 then
                cardinfo.nCardCount = cardinfo.nCardCount + 1
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(iVar)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
        end
        if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
            for key, var in pairs(cardinfo.cbCardData) do
                local index = GameLogic:SwitchToCardIndex(var.data)
                cardIndex[index]=0
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end

    local tableTemp = {10,7,2}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 and #cardStackInfo < maxHanCardRow then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    local tableTemp = {3,2,1}
    local cardinfo = {}
    cardinfo.nCardCount = 0
    cardinfo.cbCardData = {}
    for iKey, iVar in pairs(tableTemp) do
        if cardIndex[iVar] == 1 then
            cardinfo.nCardCount = cardinfo.nCardCount + 1
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(iVar)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
        end
    end
    if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
        for key, var in pairs(cardinfo.cbCardData) do
            local index = GameLogic:SwitchToCardIndex(var.data)
            cardIndex[index]=0
        end
        table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
    end
    if GameCommon.gameConfig.bYiWuShi == 1 then
        local tableTemp = {10,5,1}
        local cardinfo = {}
        cardinfo.nCardCount = 0
        cardinfo.cbCardData = {}
        for iKey, iVar in pairs(tableTemp) do
            if cardIndex[iVar] == 1 then
                cardinfo.nCardCount = cardinfo.nCardCount + 1
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(iVar)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
        end
        if cardinfo.nCardCount == 2 and #cardStackInfo < maxHanCardRow then
            for key, var in pairs(cardinfo.cbCardData) do
                local index = GameLogic:SwitchToCardIndex(var.data)
                cardIndex[index]=0
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end
    --两个大小
    for i=1 , 10 do
        if cardIndex[i]==1  and  cardIndex[i+10]==1  and #cardStackInfo < maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 2
            cardinfo.cbCardData = {}
            
            cardIndex[i+10]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+10)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            
            cardIndex[i]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)



            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end
    end
    --对子上补成大小吃
    for i=1 , 20 do
        if cardIndex[i]==1 then
            local data = GameLogic:SwitchToCardData(i)
            local value = Bit:_and(data,0x0F)
            local color = Bit:_rshift(Bit:_and(data,0xF0),4)
            for key, var in pairs(cardStackInfo) do
                if var.nCardCount == 2 then
                    local data1 = var.cbCardData[1].data
                    local data2 = var.cbCardData[2].data
                    local value1 = Bit:_and(data1,0x0F)
                    local color1 = Bit:_rshift(Bit:_and(data1,0xF0),4)
                    if data1 == data2 and value == value1 and color1 ~= color then
                        var.nCardCount = var.nCardCount + 1
                        cardIndex[i]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i)
                        _cardData.pt = pos
                        table.insert(var.cbCardData,#var.cbCardData+1,_cardData)
                        break
                    end
                end 
            end
        end
    end

    --2个顺子
    local i = 1
    while #cardStackInfo < maxHanCardRow and i <= 19 do
        if cardIndex[i]==1  and  cardIndex[i+1]==1 then
            local cardinfo = {}
            cardinfo.nCardCount = 2
            cardinfo.cbCardData = {}

            cardIndex[i+1]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+1)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)



            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)    
        end
        if i==9 then
            i=10
        end
        i = i + 1
    end

    --随便铺
    for i=1 ,20 do
        if cardIndex[i]==1 then
            if #cardStackInfo < maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 1
                cardinfo.cbCardData = {}
                for j= 1 , cardIndex[i] do 
                    local _cardData = {}
                    _cardData.data=GameLogic:SwitchToCardData(i)
                    _cardData.pt = pos
                    table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
                end
                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            else
                for j= #cardStackInfo , 1 , -1 do
                    if cardStackInfo[j].nCardCount < 3 then
                        cardStackInfo[j].nCardCount = cardStackInfo[j].nCardCount + 1
                        cardIndex[i]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i)
                        _cardData.pt = pos
                        table.insert(cardStackInfo[j].cbCardData,#cardStackInfo[j].cbCardData+1,_cardData)
                        break
                    end
                end
            end
        end
    end
    return cardStackInfo
end


--手牌排序3
function GameLogic:sortHandCardthree(cardIndex, maxHanCardRow,pos)
    local cardStackInfo = {}
    --3,4张遍历
    for i=1 , 10 do
        if cardIndex[i] >= 3 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i]=0
        end
        if cardIndex[i+10] >= 3 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i+10]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i+10] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i+10)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i+10]=0
        end

        if cardIndex[i]==2 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i]=0
        end
        if cardIndex[i+10]==2 then
            local cardinfo = {}
            cardinfo.nCardCount = cardIndex[i+10]
            cardinfo.cbCardData = {}
            for j= 1 , cardIndex[i+10] do 
                local _cardData = {}
                _cardData.data=GameLogic:SwitchToCardData(i+10)
                _cardData.pt = pos
                table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
            end
            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            cardIndex[i+10]=0
        end
        if cardIndex[i]==1  and  cardIndex[i+10]==1  and #cardStackInfo < maxHanCardRow then
            local cardinfo = {}
            cardinfo.nCardCount = 2
            cardinfo.cbCardData = {}

            cardIndex[i+10]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i+10)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            cardIndex[i]=0
            local _cardData = {}
            _cardData.data=GameLogic:SwitchToCardData(i)
            _cardData.pt = pos
            table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)

            table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
        end

        if cardIndex[i]==1 then
            local data = GameLogic:SwitchToCardData(i)
            local value = Bit:_and(data,0x0F)
            local color = Bit:_rshift(Bit:_and(data,0xF0),4)
            for key, var in pairs(cardStackInfo) do
                if var.nCardCount == 2 then
                    local data1 = var.cbCardData[1].data
                    local data2 = var.cbCardData[2].data
                    local value1 = Bit:_and(data1,0x0F)
                    local color1 = Bit:_rshift(Bit:_and(data1,0xF0),4)
                    if data1 == data2 and value == value1 and color1 ~= color then
                        var.nCardCount = var.nCardCount + 1
                        cardIndex[i]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i)
                        _cardData.pt = pos
                        table.insert(var.cbCardData,#var.cbCardData+1,_cardData)
                        break
                    end
                end 
            end
        end
        if cardIndex[i+10]==1 then
            local data = GameLogic:SwitchToCardData(i+10)
            local value = Bit:_and(data,0x0F)
            local color = Bit:_rshift(Bit:_and(data,0xF0),4)
            for key, var in pairs(cardStackInfo) do
                if var.nCardCount == 2 then
                    local data1 = var.cbCardData[1].data
                    local data2 = var.cbCardData[2].data
                    local value1 = Bit:_and(data1,0x0F)
                    local color1 = Bit:_rshift(Bit:_and(data1,0xF0),4)
                    if data1 == data2 and value == value1 and color1 ~= color then
                        var.nCardCount = var.nCardCount + 1
                        cardIndex[i+10]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i+10)
                        _cardData.pt = pos
                        table.insert(var.cbCardData,#var.cbCardData+1,_cardData)
                        break
                    end
                end 
            end
        end

        if cardIndex[i]==1 then
            if #cardStackInfo < maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 1
                cardinfo.cbCardData = {}
                for j= 1 , cardIndex[i] do 
                    local _cardData = {}
                    _cardData.data=GameLogic:SwitchToCardData(i)
                    _cardData.pt = pos
                    table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
                end
                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            else
                for j= #cardStackInfo , 1 , -1 do
                    if cardStackInfo[j].nCardCount < 3 then
                        cardStackInfo[j].nCardCount = cardStackInfo[j].nCardCount + 1
                        cardIndex[i]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i)
                        _cardData.pt = pos
                        table.insert(cardStackInfo[j].cbCardData,#cardStackInfo[j].cbCardData+1,_cardData)
                        break
                    end
                end
            end
        end

        if cardIndex[i+10]==1 then
            if #cardStackInfo < maxHanCardRow then
                local cardinfo = {}
                cardinfo.nCardCount = 1
                cardinfo.cbCardData = {}
                for j= 1 , cardIndex[i+10] do 
                    local _cardData = {}
                    _cardData.data=GameLogic:SwitchToCardData(i+10)
                    _cardData.pt = pos
                    table.insert(cardinfo.cbCardData,#cardinfo.cbCardData + 1,_cardData)
                end
                table.insert(cardStackInfo,#cardStackInfo+1,cardinfo)
            else
                for j= #cardStackInfo , 1 , -1 do
                    if cardStackInfo[j].nCardCount < 3 then
                        cardStackInfo[j].nCardCount = cardStackInfo[j].nCardCount + 1
                        cardIndex[i+10]=0
                        local _cardData = {}
                        _cardData.data=GameLogic:SwitchToCardData(i+10)
                        _cardData.pt = pos
                        table.insert(cardStackInfo[j].cbCardData,#cardStackInfo[j].cbCardData+1,_cardData)
                        break
                    end
                end
            end
        end
    end
    return cardStackInfo
end


--计算一列胡息
function GameLogic:CalculateColHuXi(colData)
    colData = clone(colData)

    if type(colData) ~= 'table' then
        return 0
    end

    local len = #colData
    if len <= 2 then
        return 0
    elseif len == 3 then
        return self:_calculateThreeHuXi(colData)
    elseif len == 4 then
        return self:_calculateFourHuXi(colData)
    else
        return 0
    end
end

function GameLogic:_calculateThreeHuXi(colData)
    local comp = function(a, b)
        if a.data < b.data then
            return true
        end
        return false
    end
    table.sort(colData, comp)

    local isCardEquil = function(colData)
        local isEquil = true
        local value = nil
        for k,v in pairs(colData) do
            if value and value ~= v.data then
                isEquil = false
                break
            end
            value = v.data
        end
        return isEquil
    end

    if isCardEquil(colData) then
        if colData[1].data > 10 then
            return 6
        else
            return 3
        end
    else
        if colData[1].data == 1 and colData[2].data == 2 and colData[3].data == 3 then
            return 3
        elseif colData[1].data== 2 and colData[2].data == 7 and colData[3].data == 10 then
            return 3
        elseif colData[1].data == 17 and colData[2].data == 18 and colData[3].data == 19 then
            return 6
        elseif colData[1].data == 18 and colData[2].data == 23 and colData[3].data == 26 then
            return 6
        end
    end
    return 0
end

function GameLogic:_calculateFourHuXi(colData)
    local isEquil = true
    local value = nil
    for k,v in pairs(colData) do
        if value and value ~= v.data then
            isEquil = false
            break
        end
        value = v.data
    end
    
    if isEquil then
        if colData[1].data > 10 then
            return 12
        else
            return 9
        end
    else
        return 0  
    end
end


return GameLogic