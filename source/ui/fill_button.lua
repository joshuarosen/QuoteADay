import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/easing"

local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

-- Just a radial button that fills up over time (with a fun sound!)
-- Used for the ReloadDialog.

class('FillButton').extends()

local synth = sound.synth.new(sound.kWaveSine)
synth:setADSR(0.2, 0.2, 1, 0.2)
synth:setVolume(0.65)

local lfo = sound.lfo.new()
lfo:setDepth(0)
synth:setFrequencyMod(lfo)

-- Used for LFO to smoothly change frequency in the synth.
local oneStep <const> = 0.083333
local finalCenter = oneStep * 12

function FillButton:init(position, radius, buttonImg, crankImg, circleWidth, arcWidth, fillTime, easingFunc, callback)
    self.position = position
    self.radius = radius
    self.buttonImg = buttonImg
    self.crankImg = crankImg
    self.circleWidth = circleWidth or 1
    self.arcWidth = arcWidth or radius

    self.fillTime = 0.0
    self.totalFillTime = fillTime or 1000.0
    self.easingFunc = easingFunc or playdate.easingFunctions.outQuad

    self.filled = false
    self.callbackTriggered = false
    self.callback = callback

    self.lastTimeMs = 0

    self.use_crank = false
    self.enable_input = false
end

function FillButton:setCallback(callback)
    self.callback = callback
end

function FillButton:disableInput()
    self.enable_input = false
end

function FillButton:enableInput()
    self.enable_input = true
end

function FillButton:reset(showCrank)
    self.enable_input = false
    self.filled = false
    self.callbackTriggered = false
    self.fillTime = 0.0
    self.lastTimeMs = 0
    self.use_crank = showCrank or false
end

function FillButton:update()
    local ct = playdate.getCurrentTimeMilliseconds()
    local dt = 0
    if self.lastTimeMs > 0 then
        dt = ct - self.lastTimeMs
    end
    self.lastTimeMs = ct

    local change, acceleratedChange = playdate.getCrankChange()
    if not self.use_crank and change ~= 0 then
        self.use_crank = true
    end
    if self.use_crank and playdate.buttonIsPressed(playdate.kButtonA) then
        self.use_crank = false
    end

    if not self.filled then
        -- We want to maintain fill position if player stops cranking.
        if self.use_crank then
            local amountToFill = change / 360.0 * self.totalFillTime
            self.fillTime = math.max(math.min(self.totalFillTime, self.fillTime + amountToFill), 0)
        else
            if playdate.buttonIsPressed(playdate.kButtonA) and self.enable_input then
                self.fillTime = math.min(self.totalFillTime, self.fillTime + dt)
            else
                self.fillTime = math.max(0.0, self.fillTime - dt)
            end
        end
    end

    if self.fillTime >= self.totalFillTime then
        self.filled = true
        if not self.callbackTriggered then
            self.callbackTriggered = true
            self.callback()
        end
    end

    self:draw(change)
end

function FillButton:draw(crankChange)
    local t = self.fillTime / self.totalFillTime

    local curCenter = playdate.easingFunctions.linear(t, 0, finalCenter, 1)
    lfo:setCenter(curCenter)
    if curCenter >= finalCenter then
        synth:noteOff()
    elseif curCenter <= 0 then
        synth:noteOff()
    else
        synth:playNote("G3")
    end

    -- If we're using crank and we stop cranking, turn note off too
    if self.use_crank and crankChange == 0 then
        synth:noteOff()
    end

    local finalScale = self.easingFunc(t, 0, 1, 1)

    gfx.pushContext()
        if not self.use_crank then
            self.buttonImg:drawCentered(self.position.x, self.position.y)
        else
            self.crankImg:drawCentered(self.position.x, self.position.y)
        end
        gfx.setLineWidth(self.circleWidth)
        gfx.drawCircleAtPoint(self.position.x, self.position.y, self.radius)
        gfx.setLineWidth(self.arcWidth)
        if finalScale > 0 then
            gfx.drawArc(self.position.x, self.position.y, self.radius - (self.arcWidth / 2), 0, 360 * finalScale)
        end
    gfx.popContext()
end