import "CoreLibs/object"

-- Wrapper for Playdate's device time.
-- Useful during development for doing local debugging.

Time = {
    time = playdate.getTime()
}

function Time:load()
    self.time = playdate.getTime()
end

function Time:getTime()
    return self.time
end