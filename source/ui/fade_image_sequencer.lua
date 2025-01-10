import "CoreLibs/timer"

import "fade_image"

class('FadeImageSequencer').extends()

function FadeImageSequencer:init()
    FadeImageSequencer.super.init(self)
    self.fade_images = {}
    self.totalFadeTime = 0
    self.is_finished = false
end

-- Append the given fade_image to the sequence. The fade_image will fade after the
-- previous image in the sequenced has finished its fade.
-- Optionally provide a delay in milliseconds to wait longer after the previous image
-- finishes its fade. If the delay is negative, the fade_image will start its fade
-- BEFORE the previous image fade finishes.
function FadeImageSequencer:append(fade_image, delay)
    local _delay = delay or 0
    self.totalFadeTime += _delay + fade_image:getFadeTime()
    if (#self.fade_images > 0) then
        local prev_fade_image = self.fade_images[#self.fade_images]
        _delay += prev_fade_image.image:getFadeTime()
    end
    _delay = math.max(_delay, 0)
    table.insert(self.fade_images, { image = fade_image, delay = _delay } )
end

function FadeImageSequencer:getTotalFadeTime()
    return self.totalFadeTime
end

-- Appends list of fade sprites all with the same delay.
function FadeImageSequencer:appendAllWithDelay(fade_images, delay)
    for i, image in ipairs(fade_images) do
        self:append(fade_images[i], delay)
    end 
end

function FadeImageSequencer:startFade(delay)
    local _delay = delay or 0
    self.is_finished = false
    self.initial_timer = playdate.timer.performAfterDelay(_delay, function() self:runFade(1) end)
end

-- Fades out all images at the same time.
-- Returns the total time it takes to fade out all images.
function FadeImageSequencer:fadeOut()
    self.is_finished = false
    local fadeOutTime = 0
    for _, fadeImage in ipairs(self.fade_images) do
        fadeImage.image:startFade(0, true)
        fadeOutTime = math.max(fadeOutTime, fadeImage.image:getFadeTime())
    end
    playdate.timer.performAfterDelay(fadeOutTime, function() self.is_finished = true end)
    return fadeOutTime
end

function FadeImageSequencer:runFade(index)
    self.fade_images[index].image:startFade()
    index += 1
    if (index > #self.fade_images) then
        playdate.timer.performAfterDelay(self.fade_images[index - 1].image:getFadeTime(), function () self.is_finished = true end)
        return
    end
    local delay = self.fade_images[index].delay
    -- Store this timer so that we can cancel it if we need
    self.active_timer = playdate.timer.performAfterDelay(delay, function () self:runFade(index) end)
end

function FadeImageSequencer:update()
    for i, fade_image in ipairs(self.fade_images) do
        fade_image.image:update()
    end
end

-- Immediately end fade
function FadeImageSequencer:finishFade()
    -- Cancel the active timer if it's running.
    if (self.active_timer ~= nil) then
        self.active_timer:remove()
    end
    if (self.initial_timer ~= nil) then
        self.initial_timer:remove()
    end

    -- Automatically advance all the fade_images to full alpha
    for i, fade_image in ipairs(self.fade_images) do
        fade_image.image:finishFade()
    end
    self.is_finished = true
end

function FadeImageSequencer:isFinished()
    return self.is_finished
end