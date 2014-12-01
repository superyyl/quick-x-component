#quick-x-component
这个仓库提交了一些平时开发过程中用到的实用组件或工具类

##TimerLabel
	TimerLabel.new({time = 60000,format = "@M:@S"})
		:align(display.LEFT_TOP,50,50)
		:addTo(self)
		:addEventListener(TimerLabel.ON_COUNT_DOWN,handler(self,self.onCountDown))
除了text外,display.newTTFLabel里的所有参数都有效
新增了time参数(单位毫秒),format参数(支持H M S),triggerTime参数(触发事件,不传时为0)
倒计时结束会触发TimerLabel.ON_COUNT_DOWN