
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

local TimerLabel = require("reign.component.TimerLabel")

function MainScene:ctor()
    local timerLabel = TimerLabel.new({
        time = 60000,
        format = "TimerLabel演示:@M:@S"
    })

    timerLabel:addEventListener(TimerLabel.ON_COUNT_DOWN,function(event)
        print("倒计时结束")
    end)

    timerLabel:align(display.LEFT_TOP,50,display.height - 50):addTo(self)

end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
