import "CoreLibs/object"
import "CoreLibs/timer"

class('ExtendedTimer').extends()

-- Extends the default playdate.timer with some additional methods (advanceToEnd).
function ExtendedTimer:init(duration)
    ExtendedTimer.super.init(self)
    self.duration = duration
    self.timer = playdate.timer.new(duration)
    self.atEnd = false
end

function ExtendedTimer:pause()
    self.timer:pause()
end

function ExtendedTimer:start()
    self.timer:start()
end

function ExtendedTimer:reset()
    self.atEnd = false
    self.timer = playdate.timer.new(self.duration)
end

function ExtendedTimer:timeLeft()
    if (self.atEnd) then
        return 0
    end
    return self.timer.timeLeft
end

function ExtendedTimer:advanceToEnd()
    self.timer:remove()
    self.atEnd = true
end