--明牌数据处理
local GameCommon = require("game.majiang.GameCommon") 
local MingPaiData = {}

function MingPaiData:init()
    self.curMingPaiCount = 0 --对象的数量
    self.isHaveKZ = false --是否有刻子
    self.tingPaiData = {} --明牌对象数据
    self.useKz = {} --缓存刻子
    self.deleteKz = {} --移除的刻子
    self.cardData = {} --手牌数据 只有在明牌的时候使用
    self.pushCard = {} --按下的牌值
    self.cacheTingPaiData = nil
    self.totalCount = 0 --总数
    self.isTPing = false --是否听牌中
    self.showTPData = {} --显示的听牌数据

    self.tpItem = nil --听牌item
end

function MingPaiData:isEqual( ... )
    print('-->>>>>>>>>>>>xx',self.curMingPaiCount,self.totalCount)
    if GameCommon.playbackData then
        return true
    end
    return self.curMingPaiCount == self.totalCount
end

function MingPaiData:setTotalCount( count )
    self.totalCount = count
    print('-->>>>mingPaidataC',count)
end

function MingPaiData:setHandData(cardArry)
    local data = clone(cardArry)
    self.cardData = data
end

function MingPaiData:handCardData( ... )
    return self.cardData
end

--移除手牌 --最多3个
function MingPaiData:removeKzByValue( value )
    local i = #self.cardData
    local index = 0
    while i > 0 do
        if index == 3 then
            break
        end
        if self.cardData[i].data == value then
            table.remove( self.cardData, i ) 
            index = index + 1
        end
        i = i-1
    end
    --dump(self.cardData,'fx MingPaiData-------------->>')
end

--获取按下的刻子
function MingPaiData:getPushKZ( ... )
    local kz = {}

    for i=1,4 do
        local data = self.pushCard[i] or 0
        table.insert( kz,data)
    end
    --dump(kz,'fx---kz----------->>')
    return kz
end

function MingPaiData:pushData( buffer )
    local data = {}
    self.curMingPaiCount = self.curMingPaiCount + 1
    data.MingCardEx = buffer.MingCardEx
    data.MingCardCount = buffer.MingCardCount
    if buffer.MingCardCount > 0 and not self.isHaveKZ then
        self.isHaveKZ = true
    end
    data.ShanCard = buffer.ShanCard
    data.HuCard = buffer.HuCard
    data.index = self.curMingPaiCount - 1
    print('-->setCount',self.curMingPaiCount)
    self.isTPing = true
    print('-->xx',self.isTPing)
    table.insert( self.tingPaiData, data)
end

--获取可
function MingPaiData:getTingPaiData(  )
   local count = #self.pushCard
   --dump(self.pushCard,'fx-------------->>')
   --dump(self.tingPaiData,'fx-------------->>')
   for _,v in ipairs(self.tingPaiData) do
       if count == v.MingCardCount then --个数相等
           local isFind = false
           if count == 0 then
               isFind = true
               return v
           end
           for _,va in ipairs(self.pushCard) do
                local isContain = false
                for _,pur in ipairs(v.MingCardEx) do
                    if va == pur then
                        isContain = true
                        break
                    end
                end
                if not isContain then
                    isFind = false
                    break
                end
                isFind = true
           end
           if isFind then
               return v
           end
       end
   end
   return nil
end

--获取胡牌数据
function MingPaiData:getHuPaiData(value)
    --牌值 index
    if not self.cacheTingPaiData then
        return nil
    end
    local showData = {}
    local index = 0
    local ShanCard = self.cacheTingPaiData.ShanCard
    local huPaiCard = self.cacheTingPaiData.HuCard
    for i=1,14 do
        if ShanCard[i] == value then
            index = i
            break
        end
    end
    
    return  huPaiCard[index]
end

--获取听牌数据 明牌时显示听牌 
function MingPaiData:getTPData( ... )
    local tpCardData = {}
    for i,v in ipairs(self.tingPaiData) do
        if v.MingCardCount == 0 then --明牌数量为零
            self.tpItem = v
            return v
        end
    end
    return nil
end

--获取胡牌 听牌可以用 数组
function MingPaiData:getHuCardArray(tpItem,value)
    if not tpItem then
        return nil
    end
    local index = 0
    for i=1,14 do
        if tpItem.ShanCard[i] == value then
            index = i
            break
        end
    end
    if index == 0 then
        return nil
    end
    --dump(tpItem,'asdfafsaf')
    local useHuPaiCard  = tpItem.HuCard[index]
    return useHuPaiCard
end

function MingPaiData:getHandCardTPArray( value)
    if self.tpItem then
        return self:getHuCardArray(self.tpItem,value)
    end
    return nil
end


--清除push数据
function MingPaiData:clearPush( ... )
    self.pushCard = {}
end

--重置 栓选所有刻子
function MingPaiData:resetKZ(  )
    self.useKz = {}
    for _,v in ipairs(self.tingPaiData) do
        for i=1,v.MingCardCount do
            local kz = v.MingCardEx[i]
            local isContain = false
            for _,val in ipairs(self.useKz) do
                if val == kz then
                    isContain = true
                    break
                end
            end
            if kz ~= 0 and not isContain then
                table.insert(self.useKz, kz)
            end
        end
    end
    self.deleteKz = {}
    --dump(self.useKz,'fx-------------->>')
end

function MingPaiData:useKzCount( ... )
    return #self.useKz
end

function MingPaiData:getDeleteKz( ... )
    return self.deleteKz
end

--删除其中某个刻子 
function MingPaiData:deleteOneCard( value )
    local index = 0
    for index,v in ipairs(self.useKz) do
        if v == value then --移除
            table.remove( self.useKz,index )
            table.insert( self.deleteKz,value )
            break
        end
    end
    --移除手牌
    self:removeKzByValue(value)
end

--改牌值是否在刻子里面
function MingPaiData:isInTingPaiData( value )
    
    for _,v in ipairs(self.useKz) do
        if v == value then
            return true
        end
    end
    return false
end


--清理明牌数据
function MingPaiData:clear(  )
    self.curMingPaiCount = 0 --对象的数量
    self.isHaveKZ = false --是否有刻子
    self.tingPaiData = {} --明牌对象数据
    self.useKz = {} --缓存刻子
    self.deleteKz = {} --移除的刻子
    self.cardData = {} --手牌数据 只有在明牌的时候使用
    self.pushCard = {} --按下的牌值
    self.cacheTingPaiData = nil
    self.totalCount = 0 --总数
    self.tingPaiCard = {} --清除听牌数据
    self.isTPing = false
    self.showTPData = {}
    self.tpItem  = nil
    print('-->>>>clear')
end

return MingPaiData