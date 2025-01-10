import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/easing"

import "time"
import "audio/audio_manager"
import "audio/intro_jingle_player"
import "data/game_data"
import "util/math_util"
import "util/string_util"

local gfx <const> = playdate.graphics
local ui <const> = playdate.ui

local font = gfx.font.new('fonts/Lucian_Schoenschrift_CAT')
local screenWidth, screenHeight = playdate.display.getSize()

IntroScreen = {}

local introImage = gfx.image.new(screenWidth, screenHeight)
local yPosition = 0
local velocity = 0
local friction <const> = 0.4
local acceleration_scale <const> = 0.25
local max_velocity <const> = 10
local transitionThreshold <const> = 75

local transition_started = false
local introFadeTime <const> = 300

local indicatorWaitTimeMs = 6000 + introFadeTime
local indicatorTimer = nil
local showIndicator = false

local divider = gfx.image.new("img/Divider")
local _dividerWidth, _dividerHeight = divider:getSize()
local dividerSize = { width = _dividerWidth,
                      height = _dividerHeight }
local dividerPadding <const> = 13

local blackImgFadeTimer = playdate.timer.new(introFadeTime, 0, 1)
local fadeEasingFunction = playdate.easingFunctions.inQuart
local blackImg = gfx.image.new(screenWidth, screenHeight, gfx.kColorBlack)
local blackImgMask = gfx.image.new(screenWidth, screenHeight, gfx.kColorWhite)
blackImg:setMaskImage(blackImgMask)

local fading = true

function IntroScreen:setup()
    playIntroJingle()

    local today_index = Time:getTime().weekday
    local text = "Happy " .. WEEKDAY_STRINGS[today_index]

    introImage:clear(gfx.kColorBlack)
    gfx.pushContext(introImage)
        gfx.pushContext()
            local ditherEdgeSize <const> = 15
            gfx.setColor(gfx.kColorWhite)
            gfx.setDitherPattern(0.75, gfx.image.kDitherTypeBayer8x8)
            gfx.fillRect(0, 0, screenWidth, 8)
            gfx.fillRect(0, screenHeight - 8, screenWidth, 8)

            gfx.setColor(gfx.kColorWhite)
            gfx.setDitherPattern(0.85, gfx.image.kDitherTypeBayer8x8)
            gfx.fillRect(0, 8, screenWidth, 8)
            gfx.fillRect(0, screenHeight - 16, screenWidth, 8)            
        gfx.popContext()

        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.setFont(font)
        gfx.drawTextAligned(text, screenWidth / 2 - font:getTextWidth(text) / 2, screenHeight / 2 - font:getHeight() / 2)
        divider:drawCentered(screenWidth / 2, screenHeight / 2 + font:getHeight() / 2 + dividerPadding)
    gfx.popContext()

    -- Decrease indicator wait time if this is the first app launch. We don't want the
    -- user to get stuck on this screen if they don't realize they can crank.
    if GameData:isFirstAppLaunch() then
        indicatorWaitTimeMs = 2500 + introFadeTime
    end
    indicatorTimer = playdate.timer.new(indicatorWaitTimeMs, function() 
        showIndicator = true
    end)
    ui.crankIndicator.clockwise = false

    yPosition = 0
    velocity = 0
    transition_started = false

    -- Immediately start the transition, since the player can start cranking as soon as
    -- they like.
    self:startTransition()
end

function IntroScreen:update()
    if not fading then
        -- For accessibility, let the player use the buttons to transition the screen in
        -- addition to the crank.
        if playdate.buttonIsPressed(playdate.kButtonUp) then
            self:updateVelocity(-5)
        elseif playdate.buttonIsPressed(playdate.kButtonDown) then
            self:updateVelocity(5)
        end
    end

    if velocity ~= 0 then
        -- If applying friction causes us to change direction, just set velocity to 0.
        if math.abs(velocity) - friction < 0 then
            velocity = 0
        else
            velocity += -1 * sign(velocity) * friction
        end
    end
    yPosition += velocity

    -- When the intro screen moves past a threshold, trigger the transition threshold to
    -- the next screen.
    if not transition_started and yPosition >= transitionThreshold then
        transition_started = true
        self:transitionTrigger()
    end

    -- Clamp the yPosition at the boundaries.
    yPosition = math.max(0, math.min(screenHeight, yPosition))

    -- If we've reached the bottom of the screen, finish the transition
    if yPosition == screenHeight then
        self:endTransition()
        GameData:markDismissedIntro()
    end

    introImage:draw(0, yPosition)

    if fading then
        gfx.pushContext(blackImgMask)
            gfx.clear()
            gfx.setStencilPattern(fadeEasingFunction(blackImgFadeTimer.value, 0, 1, 1), gfx.image.kDitherTypeBayer8x8)
            gfx.fillRect(0, 0, 400, 240)
        gfx.popContext()
        blackImg:setMaskImage(blackImgMask)
        blackImg:draw(0, 0)

        if blackImgFadeTimer.value >= 1 then
            fading = false
        end
    end

    -- Wait for fade to finish before considering showing indicator
    if not fading and showIndicator then
        ui.crankIndicator:draw(0, 0)
    end

    playdate.timer.updateTimers()
end

function IntroScreen:updateVelocity(acceleratedChange)
    velocity += acceleratedChange * acceleration_scale
    -- Clamp velocity between negative/positive max_velocity
    velocity = math.max(math.min(velocity, max_velocity), -max_velocity)
end

function IntroScreen:cranked(change, acceleratedChange)
    -- Prevent cranking until intro image finishes fade
    if fading then
        return
    end

    -- If player is cranking in the right direction, turn off indicator.
    if indicatorTimer ~= nil then
        if acceleratedChange > 0 then
            indicatorTimer:remove()
            showIndicator = false
        end
    end

    self:updateVelocity(acceleratedChange)
end