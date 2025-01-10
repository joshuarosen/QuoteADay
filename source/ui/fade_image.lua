import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"

import "util/extended_timer"
import "ui/fade_image_patterns"

local gfx <const> = playdate.graphics

-- An image that fades in/out over time (in chunks from left-to-right).

class('FadeImage').extends()

local QUOTE_TYPE <const> = 1
local ATTRIBUTION_TYPE <const> = 2

class('QuoteFadeImage', {type = QUOTE_TYPE}).extends('FadeImage')
class('AttributionFadeImage', {type = ATTRIBUTION_TYPE}).extends('FadeImage')

-- 32 as our chunk width strikes a nice balance between being performant and appearing smooth.
local chunkWidth <const> = 32

-- fade_time_per_chunk and fade_delay_between_chunks should be expressed in milliseconds
-- If fade_out is false or unspecified, the image will be transparent and then fade in.
function FadeImage:init(image, fade_time_per_chunk, fade_delay_between_chunks, fade_out)
    FadeImage.super.init(self)

    self.image = image
    self.position = { x = 0, y = 0 }

    image:addMask()
    self.mask = image:getMaskImage()

    self.fade_time_per_chunk = fade_time_per_chunk
    self.fade_delay_between_chunks = fade_delay_between_chunks

    -- Calculate the total number of chunk rows/columns
    -- Chunks are faded in individually
    local width, height = image:getSize()
    self.num_cols = math.ceil(width / chunkWidth)

    self.fade_out = fade_out or false
    self.total_fade_time = self.fade_delay_between_chunks * (self.num_cols - 1) + self.fade_time_per_chunk
    self.fade_timer = ExtendedTimer(self.total_fade_time)
    -- Pause the fade timer by default. Caller must call the startFade function.
    self.fade_timer:pause()
end

function FadeImage:moveTo(x, y)
    self.position = { x = x, y = y }
end

function FadeImage:getFadeTime()
    return self.total_fade_time
end

-- delay is a time in milliseconds to wait before starting the fade.
function FadeImage:startFade(delay, fade_out)
    self.fade_out = fade_out or false

    -- Reset old vars
    self.fade_timer:reset()
    gfx.pushContext(self.mask)
        gfx.clear()
    gfx.popContext()

    if (delay ~= nil and delay > 0) then
        self.delay_timer = playdate.timer.performAfterDelay(delay, function() self.fade_timer:start() end)
    else 
        self.fade_timer:start()
    end
end

-- Instantly advance to the end of the fade.
function FadeImage:finishFade()
    if (self.delay_timer ~= nil) then
        self.delay_timer:remove()
    end
    
    -- Automatically advance to the end of the fade
    self.fade_timer:advanceToEnd()
end

local function drawPatternChunk(type, x, alpha, fade_out)
    local alpha = alpha
    if fade_out then
        alpha = 1 - alpha
    end

    if type == ATTRIBUTION_TYPE then
        FadeImagePatterns:getAttributionPattern(alpha):draw(x, 0)
    elseif type == QUOTE_TYPE then
        FadeImagePatterns:getQuotePattern(alpha):draw(x, 0)
    else
        print("Unsupported fade image type.")
    end
end

function FadeImage:update()
    gfx.pushContext(self.mask)
        for col = 0, self.num_cols - 1, 1 do
            -- Alpha goes from >1 to 0
            local total_index = col + 1
            local alpha = (self.fade_timer:timeLeft() - (self.fade_delay_between_chunks * (self.num_cols - total_index))) / self.fade_time_per_chunk
            -- Clamp alpha between 0 and 1
            alpha = math.min(math.max(alpha, 0), 1)
    
            drawPatternChunk(self.type, chunkWidth * col, alpha, self.fade_out)
        end
    gfx.popContext()

    self.image:draw(self.position.x, self.position.y)
end