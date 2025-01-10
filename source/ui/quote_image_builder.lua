import "CoreLibs/graphics"
import "CoreLibs/object"

import "util/string_util"
import "ui/fade_image"
import "ui/fade_image_sequencer"

local gfx <const> = playdate.graphics

local screenWidth, screenHeight = playdate.display.getSize()

local quoteFont = gfx.font.new('fonts/BirchLeaf-24-Exported')
local attributionFont = gfx.font.new('fonts/Dico-24')

-- Margin to apply to either side horizontally/vertically for content.
local contentMargin = { x = 18, y = 13 }
-- The size of the area that we can use for content. Content may not fill this space if
-- it's not big enough.
local availableContentSize = { width = screenWidth - (contentMargin.x * 2),
                               height = screenHeight - (contentMargin.y * 2) }

local divider = gfx.image.new("img/Divider")
local _dividerWidth, _dividerHeight = divider:getSize()
local dividerSize = { width = _dividerWidth,
                      height = _dividerHeight }
local dividerPadding <const> = 13

QuoteImageBuilder = {}

local function buildQuoteFadeImages(lines, startingY)
    local quoteFadeImages = {}
    for i, line in ipairs(lines) do
        local newImg = gfx.image.new(quoteFont:getTextWidth(line), quoteFont:getHeight(), gfx.kColorWhite)
        local newFadeImage = QuoteFadeImage(newImg, 600, 100, false)

        local centerPadding = (availableContentSize.width - newImg.width) / 2
        newFadeImage:moveTo(contentMargin.x + centerPadding, startingY + ((i - 1) * quoteFont:getHeight()))

        gfx.pushContext(newImg)
            gfx.clear(gfx.kColorWhite)
            gfx.setFont(quoteFont)
            gfx.drawText(line, 0, 0)
        gfx.popContext()

        table.insert(quoteFadeImages, newFadeImage)
    end

    return quoteFadeImages
end

-- Builds FadeImage containing both divider and attribution.
local function buildAttributionFadeImage(attribution, yPos)
    local height = dividerSize.height + dividerPadding + attributionFont:getHeight()
    -- Take the greater of the two widths
    local width = math.max(attributionFont:getTextWidth(attribution), dividerSize.width)
    local attributionImg = gfx.image.new(width, height, gfx.kColorWhite)
    local attributionFadeImage = AttributionFadeImage(attributionImg, 600, 100, false)

    -- Center the attribution image in the available area.
    local attributionXMargin = (availableContentSize.width - width) / 2

    attributionFadeImage:moveTo(contentMargin.x + attributionXMargin, yPos)

    -- Center the x-pos for attribution text or divider, based on which one is wider.
    local attributionXPos = 0
    local dividerXPos = 0
    if width == attributionFont:getTextWidth(attribution) then
        dividerXPos = (width - dividerSize.width) / 2
    else
        attributionXPos = (width - attributionFont:getTextWidth(attribution)) / 2
    end

    gfx.pushContext(attributionImg)
        gfx.clear(gfx.kColorWhite)
        divider:draw(dividerXPos, 0)
        gfx.setFont(attributionFont)
        gfx.drawText(attribution, attributionXPos, dividerSize.height + dividerPadding)
    gfx.popContext()

    return attributionFadeImage
end

function QuoteImageBuilder:buildFadeImages(quote, attribution)
    local lines = getLines(quote, availableContentSize.width, availableContentSize.height, quoteFont)

    -- Now that we know the quote content, we can determine how much space it needs to
    -- take up.
    local quoteHeight = quoteFont:getHeight() * #lines
    -- The total content height is the quote + divider + attribution + padding.
    local contentHeight = quoteHeight + dividerSize.height + attributionFont:getHeight() + (dividerPadding * 2)

    -- Start the quotes at the top of the available space assuming that we center
    -- the quote/divider/attribution as one block.
    local yPos = contentMargin.y + (availableContentSize.height - contentHeight) / 2

    local quoteFadeImages = buildQuoteFadeImages(lines, yPos)

    yPos += quoteHeight + dividerPadding
    local attributionFadeImage = buildAttributionFadeImage(attribution, yPos)

    return quoteFadeImages, attributionFadeImage
end