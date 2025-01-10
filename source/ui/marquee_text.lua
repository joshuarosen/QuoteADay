import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animator"

local gfx <const> = playdate.graphics

-- Because the player can add their own categories, they may add a category that exceeds
-- the character limit. (In fact, some of our default categories exceed the char limit.)
-- MarqueeText handles scrolling text within a specified area.
-- TODO: We should apply MarqueeText to the QUOTES as well, since the user can add their
-- own quotes which will almost certainly exceed the char limit. I didn't get around to
-- doing this since it'll probably be a pain to reconcile this with the FadeImage implementation
-- (email or DM me if this is a feature that you desperately need and we'll figure something out).

class('MarqueeText').extends()

local speed <const> = 0.05

-- Make a slight delay before the scrolling starts.
local initialDelay <const> = 1100
-- Make a slight delay after we finish scrolling before we reset.
local endDelay <const> = 2100

function MarqueeText:init(text, width, font)
    self.text = text
    self.width = width
    self.font = font

    self.runScroll = false
    self.skipScroll = false

    self.animator = nil

    self:initScrollAmount()
end

function MarqueeText:setText(text)
    self.text = text
    -- Reset the animation as well
    self:stopAnimation()
    self:initScrollAmount()
end

function MarqueeText:initScrollAmount()
    self.scrollAmount = self.font:getTextWidth(self.text) - self.width
    if self.scrollAmount < 0 then
        self.skipScroll = true
    else
        -- Add a little extra whitespace to the end of the scroll.
        self.scrollAmount += self.font:getTextWidth(" ")
        self.skipScroll = false
    end
end

function MarqueeText:draw(clipPosition, height, textPosition)
    gfx.pushContext()
        gfx.setFont(self.font)
        gfx.setClipRect(clipPosition.x, clipPosition.y, self.width, height)
        if self.runScroll and self.animator ~= nil then
            local offsetX, offsetY = gfx.getDrawOffset()
            if offsetX ~= nil and offsetY ~= nil then
                gfx.setDrawOffset(self.animator:currentValue() + offsetX, offsetY)
            else
                gfx.setDrawOffset(self.animator:currentValue(), 0)
            end
        end
        gfx.drawText(self.text, textPosition.x, textPosition.y)
    gfx.popContext()
end

function MarqueeText:startAnimation()
    if self.skipScroll then
        return
    end

    if not self.runScroll and self.animator == nil then
        local resetTime = initialDelay + self.scrollAmount / speed + endDelay
        self.repeatTimer = playdate.timer.keyRepeatTimerWithDelay(resetTime, resetTime, function()
            self.animator = nil
            self.delayTimer = playdate.timer.performAfterDelay(initialDelay, function()
                self.animator = gfx.animator.new(self.scrollAmount / speed, 0, -self.scrollAmount)
            end)
        end)
        self.runScroll = true
    end
end

function MarqueeText:stopAnimation()
    if self.delayTimer ~= nil then
        self.delayTimer:remove()
    end
    if self.repeatTimer ~= nil then
        self.repeatTimer:remove()
    end
    if self.runScroll then
        self.runScroll = false
    end
    if self.animator ~= nil then
        self.animator = nil
    end
end