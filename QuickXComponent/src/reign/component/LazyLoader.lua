---
--
-- 2015-03-24 17:49:29
-- @author yaoyl
--

local LazyLoader = class("LazyLoader")

LazyLoader.ON_FUNC = "ON_FUNC"
LazyLoader.ON_CALLBACK = "ON_CALLBACK"

function LazyLoader:ctor(params)
	cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
	if params then
		self:setItemList(params.itemList)
		if params.func then
			self:onFunc(params.func)
		end
		if params.callback then
			self:onCallback(params.callback)
		end
	end
end

function LazyLoader:setItemList(itemList)
	self._itemList = itemList
	self._count = #self._itemList
end

function LazyLoader:onFunc(func)
	return self:addEventListener(LazyLoader.ON_FUNC, func)
end

function LazyLoader:onCallback(callback)
	return self:addEventListener(LazyLoader.ON_CALLBACK, callback)
end

function LazyLoader:start()
	if self.updateSchedulerEntry == nil then
		self.updateSchedulerEntry = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self,self.update),0,false)
		self._curIdx = 1
	end
end

function LazyLoader:update(dt)
	if self._curIdx >= self._count then
		if self.updateSchedulerEntry ~= nil then
			cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.updateSchedulerEntry)
		end
		self:dispatchEvent({name = LazyLoader.ON_CALLBACK})
		return
	end

	self:dispatchEvent({name = LazyLoader.ON_FUNC, item = self._itemList[self._curIdx], idx = self._curIdx})
	self._curIdx = self._curIdx + 1

end

return LazyLoader
