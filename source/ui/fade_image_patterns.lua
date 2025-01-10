local gfx <const> = playdate.graphics

-- We pre-compute a bunch of patterns to use as masks for the FadeImage.
-- It's much faster to select a pre-computed mask for a chunk at a specific alpha value
-- than generating it at runtime. And the thresholding is not very noticeable with this
-- approach.

FadeImagePatterns = {}

local patternWidth <const> = 32

local quotePatternHeight <const> = 34
local attributionPatternHeight <const> = 58

local function buildPattern(alpha, height)
    local pattern = gfx.image.new(patternWidth, height, gfx.kColorBlack)
    if alpha == 1 then
        return pattern
    end
    if alpha == 0 then
        return gfx.image.new(patternWidth, height, gfx.kColorWhite)
    end
    gfx.pushContext(pattern)
        gfx.setColor(gfx.kColorWhite)
        gfx.setDitherPattern(alpha, gfx.image.kDitherTypeBayer8x8)
        gfx.fillRect(0, 0, patternWidth, height)
    gfx.popContext()
    return pattern
end

local function buildPatternTable(patternCount, height)
    local patterns = {}
    for i=0,patternCount do
        local alpha = i / patternCount
        patterns[i+1] = buildPattern(alpha, height)
    end
    return patterns
end

local quotePatternTable = buildPatternTable(10, quotePatternHeight)
local attributionPatternTable = buildPatternTable(10, attributionPatternHeight)

local function getPatternFromTable(alpha, curTable)
    local index = math.min(math.floor(alpha * #curTable) + 1, #curTable)
    return curTable[index]
end

function FadeImagePatterns:getQuotePattern(alpha)
    return getPatternFromTable(alpha, quotePatternTable)
end

function FadeImagePatterns:getAttributionPattern(alpha)
    return getPatternFromTable(alpha, attributionPatternTable)
end