
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

local TimerLabel = require("reign.component.TimerLabel")
local TypingLabel = require("reign.component.TypingLabel")

function MainScene:ctor()
    ---[[ TimerLabel
    local timerLabel = TimerLabel.new({
        time = 60000,
        format = "TimerLabel演示:@M:@S"
    })

    timerLabel:addEventListener(TimerLabel.ON_COUNT_DOWN,function(event)
        print("倒计时结束")
    end)

    timerLabel:align(display.LEFT_TOP,50,display.height - 50):addTo(self)
    ---]]
    
    ---[[
    local typingLabel = TypingLabel.new({
        text = "这是一个打字机效果,\n支持中英数组合,\n数字123456英文abcdefg"
    })
    
    typingLabel:addEventListener(TypingLabel.ON_FINISH_TYPING,function(event)
        print("打字机结束")
    end)
    
    typingLabel:align(display.LEFT_TOP,50,display.height - 100):addTo(self)
    
    ---]]
    
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
