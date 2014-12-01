---
--
-- 下午5:52:30,2014年12月1日
-- @author superyyl
--
local TimerLabel = class("TimerLabel",function(params)
    return display.newTTFLabel(params)
end)

local TimerLabel = class("TimerLabel", function(params)
    return display.newTTFLabel(params)
end)

TimerLabel.ON_COUNT_DOWN = "ON_COUNT_DOWN"

function TimerLabel:ctor(params)
    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    self:setNodeEventEnabled(true)
    self._triggerTime = params.triggerTime or 0
    self._time = params.time
    self._format = params.format
    self:setString(self:formatTime(self._time,self._format))
end

function TimerLabel:formatTime(timeValue, format)
    if not timeValue then
        return "unknow time"
    end
    local as = math.floor(timeValue / 1000)
    local s = as % 60
    local am = math.floor(as / 60)
    local m = am % 60
    local h = math.floor(am / 60)

    local ss =  nil
    if s < 10 then
        ss = string.format("0%d", s)
    else
        ss = string.format("%d", s)
    end

    local ms =  nil
    if m < 10 then
        ms = string.format("0%d", m)
    else
        ms = string.format("%d", m)
    end

    local hs =  nil
    if h < 10 then
        hs = string.format("0%d", h)
    else
        hs = string.format("%d", h)
    end

    local newTimeString = string.gsub(format, "@H", hs)
    newTimeString = string.gsub(newTimeString, "@M", ms)
    newTimeString = string.gsub(newTimeString, "@S", ss)
    return newTimeString
end

function TimerLabel:update(dt)
    local lastTime = math.ceil(self._time / 1000)
    self._time = self._time - dt * 1000
    if self._time <= 0 then
        self._time = 0
    end

    local nowTime = math.ceil(self._time / 1000)
    if lastTime ~= nowTime then
        self:setString(self:formatTime(self._time,self._format))
    end

    if self._time <= self._triggerTime then
        self:dispatchEvent({name = TimerLabel.ON_COUNT_DOWN})
        if self._updateEntry then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._updateEntry)
            self._updateEntry = nil
        end
    end
end

function TimerLabel:onEnter()
    self._updateEntry = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self,self.update),0,false)
end

function TimerLabel:onExit()
    if self._updateEntry then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._updateEntry)
        self._updateEntry = nil
    end
end

return TimerLabel