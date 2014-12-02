
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

local TimerLabel = require("reign.component.TimerLabel")
local TypingLabel = require("reign.component.TypingLabel")
local RichLabel = require("reign.component.RichLabel")

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
    
    ---[[RichLabel
    local label = RichLabel.new({
        text = "<div fontcolor=#ff0000>hello</div><div fontcolor=#00ff00>hello</div><div fontsize=12>你</div><div fontSize=26 fontcolor=#ff00bb>好</div>ok",
        fontSize = 20,
        fontColor = cc.c3b(255, 255, 255),
        maxWidth=90,
        lineSpace=0,
        charSpace=0,
    })
    label:align(display.LEFT_TOP,50,display.height - 250)
    label:playAnimation()
    self:addChild(label)
    
    ---]]
    
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
