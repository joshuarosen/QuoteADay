import "CoreLibs/object"

import "ui/quote_image_builder"

-- QuoteOrchestrator handles the sequence of events for showing a quote:
-- 1. Fade in the quote, line by line.
-- 2. After a short delay, fade in the divider and the attribution simultaneously.

class('QuoteOrchestrator').extends()

function QuoteOrchestrator:init()
    self.sequencer = FadeImageSequencer()
end

function QuoteOrchestrator:setQuote(quote, attribution)
    self.quoteFadeImages, self.attributionFadeImage = QuoteImageBuilder:buildFadeImages(quote, attribution)
    self.sequencer = FadeImageSequencer()

    -- This looks odd, but the sequencer supports appending with a negative delay.
    -- This means that the each line will start its fade 500ms BEFORE the previous line
    -- finishes. It looks better to have the lines overlap slightly in their timing.
    local quote_lines_delay_ms <const> = -500
    self.sequencer:appendAllWithDelay(self.quoteFadeImages, quote_lines_delay_ms)

    local attribution_delay_ms <const> = 500
    self.sequencer:append(self.attributionFadeImage, attribution_delay_ms)
end

local function playFadeInAudio(quoteFadeImages, attributionFadeImage)
    -- Play two scrawls, one for the quote and one for the attribution (with a delay between them.)
    -- Get time for all quoteImages to run
    local quoteFadeTime = 0
    for _, image in ipairs(quoteFadeImages) do
        quoteFadeTime += image:getFadeTime()
    end
    AudioManager:playScrawl(0, quoteFadeTime - 1400)

    local attrScrawlDelay = quoteFadeTime + attributionFadeImage:getFadeTime() - 1250
    AudioManager:playScrawl(attrScrawlDelay, attributionFadeImage:getFadeTime() - 550)
end

function QuoteOrchestrator:fadeIn(callback)
    if callback ~= nil then
        playdate.timer.performAfterDelay(self.sequencer:getTotalFadeTime() + 1000, callback)
    end

    self.sequencer:startFade()
    playFadeInAudio(self.quoteFadeImages, self.attributionFadeImage)
end

local function playFadeOutAudio(fadeOutTime)
    AudioManager:playErase(fadeOutTime - 250)
end

-- Returns time in ms it takes to fade out.
function QuoteOrchestrator:fadeOut()
    local fadeOutTime = self.sequencer:fadeOut()
    playFadeOutAudio(fadeOutTime)
    return fadeOutTime
end

function QuoteOrchestrator:finishFade()
    self.sequencer:finishFade()
end

function QuoteOrchestrator:isFinished()
    return self.sequencer:isFinished()
end

function QuoteOrchestrator:update()
    self.sequencer:update()
end