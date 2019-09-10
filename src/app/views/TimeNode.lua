local NetMgr = require("common.NetMgr")
local EventType = require("common.EventType")
local NetMsgId = require("common.NetMsgId")
local Common = require("common.Common")
local TimeNode = class("TimeNode", cc.load("mvc").ViewBase)

function TimeNode:onConfig( )
    self.widget = {
        {'Button_year_add','onAdd'},
        {'Button_month_add','onAdd'},
        {'Button_day_add','onAdd'},
        {'Button_year_dec','onDecrease'},
        {'Button_month_dec','onDecrease'},
        {'Button_day_dec','onDecrease'},
        {'Text_year'},
        {'Text_month'},
        {'Text_day'},
    }
end

function TimeNode:onEnter( )
    local parent = self:getParent()
    if parent then
        parent:setSwallowTouches(false)
    end
end

function TimeNode:onCreate( params )
    self.year,self.month,self.day = Common:getYMDHMS(params[1]) --获取今日日期
    self.closeFunc = params[2]
    self:calDayCount() --计算日总数
    self:updateTime()
    self:registerdNode()
end

function TimeNode:registerdNode( ... )
    Common:registerScriptMask(self,function ( ... )
        if self.closeFunc then
            local time = self:getShowStamp()
            local stampMin = os.time({year=self.year, month=self.month, day=self.day,hour=0, min=0, sec=0})
            local stampMax = os.time({year=self.year, month=self.month, day=self.day,hour=23, min=59, sec=59})
            self.closeFunc(time,stampMin,stampMax)
        end
        self:close()
    end)
end

function TimeNode:onExit(  )

end

--计算前一天,后一天日期
function TimeNode:_dateChange(stamp,dayChange)
    local year,month,day = Common:getYMDHMS(stamp)
    local time=os.time({year=year, month=month, day=day})+dayChange*86400
    return time
end

function TimeNode:getTimeByYMD(year,month,day,isBefore)
    if isBefore then
        local time=os.time({year=year, month=month, day=day})-1*86400 --一天86400秒
        local _year,_month,_day = Common:getYMDHMS(time)
        return os.time({day=_day, month=_month, year=_year, hour=23, min=59, sec=59})
    else
        return os.time({day=day, month=month, year=year, hour=23, min=59, sec=59})
    end
end

--获取某年某月总共多少天
function TimeNode:getDayCount( year,month )
    local d =  os.date("%d",os.time({year=year,month=month+1,day=0}))
    return tonumber(d)
end

function TimeNode:calDayCount()
    self.dayCount = self:getDayCount(self.year,self.month)
    if self.day >= self.dayCount then
        self.day = self.dayCount
    end
end

function TimeNode:onAdd( sender )
    local name = sender:getName()

    if name == 'Button_year_add' then
        self:calDayCount()
        self.year = self.year+1
    elseif name == 'Button_month_add' then
        self:monthChage(true)
        self:calDayCount()
    elseif name == 'Button_day_add' then
        self:dayChange(true)
    end
    self:updateTime()
end

function TimeNode:onDecrease( sender )
    local name = sender:getName()
    if name == 'Button_year_dec' then
        self:calDayCount()
        self.year = self.year-1
    elseif name == 'Button_month_dec' then
        self:monthChage(false)
        self:calDayCount()
    elseif name == 'Button_day_dec' then
        self:dayChange(false)
        
    end
    self:updateTime()
end

function TimeNode:updateTime()
    self.Text_day:setString(self.day)
    self.Text_month:setString(self.month)
    self.Text_year:setString(self.year)
end

function TimeNode:dayChange( isAdd)
    if isAdd then
        self.day = (self.day >= self.dayCount) and 1 or (self.day+1)
    else
        self.day = (self.day <= 1) and self.dayCount or (self.day-1);
    end
end

function TimeNode:monthChage( isAdd )
    if isAdd then
        self.month = self.month >= 12 and 1 or (self.month+1)
    else
        self.month = self.month <= 1 and 12 or (self.month-1)
    end
end

function TimeNode:getTimeStamp(isbefor )
    return self:getTimeByYMD(self.year,self.month,self.day,isbefor)
end

function TimeNode:getShowStamp( )
    return string.format( "%d-%d-%d",self.year,self.month,self.day )
end

function TimeNode:show( ... )
    self:setVisible(true)
end

function TimeNode:hide( ... )
    self:setVisible(false)
end

function TimeNode:close(  )
    self:removeFromParent()
end

return TimeNode

