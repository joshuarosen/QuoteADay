import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/ui"

import "ui/marquee_text"
import "util/string_util"

local gfx <const> = playdate.graphics

-- The list of categories that the user can choose from. Used in the ScheduleScreen.

class('CategoryList').extends()

local weekdayFont = gfx.font.new('fonts/Cursive')
local categoryFont = gfx.font.new('fonts/Nontendo-Light-2x')

local screenWidth, screenHeight = playdate.display.getSize()

local cellHeight <const> = 10

local verticalPadding <const> = 10
local horizontalMargin <const> = 12
local weekdayLeftMargin <const> = 5
local weekdayRightMargin <const> = 5
local categoryRightMargin <const> = 10

local weekday_largest_width = weekdayFont:getTextWidth(WEEKDAY_STRINGS[1] .. ":")
for _, weekday in ipairs(WEEKDAY_STRINGS) do
    weekday_largest_width = math.max(weekday_largest_width, weekdayFont:getTextWidth(weekday .. ":"))
end

function CategoryList:init(quoteScheduleData, todayIndex, yMargin)
    CategoryList.super.init(self)

    self.listview = playdate.ui.gridview.new(0, cellHeight)
    self.listview:setNumberOfRows(#WEEKDAY_STRINGS)
    self.listview:setCellSize(0, weekdayFont:getHeight() + verticalPadding)
    self.listview:setCellPadding(0, 0, 0, cellHeight)

    -- Override drawCell for listview.
    self.listview.quoteScheduleData = quoteScheduleData
    self.listview.drawCell = self.drawCell

    self.todayIndex = todayIndex

    local width = (screenWidth - (horizontalMargin * 2))
    local weekdayWidth = weekdayLeftMargin + weekday_largest_width
    local categoryWidth = width - weekdayWidth - weekdayRightMargin
    -- Amount of space (width) available for weekday and category.
    self.listview.weekdayWidth = weekdayWidth
    self.listview.categoryWidth = categoryWidth
    
    self.listview.marquees = {}
    for i, category in ipairs(quoteScheduleData) do
        self.listview.marquees[i] = MarqueeText(category, categoryWidth, categoryFont)
    end
    self.yMargin = yMargin
    self.listview.yMargin = yMargin
end

function CategoryList:scrollToToday()
    self.listview:setSelectedRow(self.todayIndex)
    self.listview:scrollToRow(self.todayIndex, false)
end

function CategoryList:getSelectedRow()
    return self.listview:getSelectedRow()
end

function CategoryList:runSelected()
    local selectedRow = self.listview:getSelectedRow()
    self.listview.marquees[selectedRow]:startAnimation()
end

-- Use when we leave the screen.
function CategoryList:stopAllAnimations()
    for i, marquee in ipairs(self.listview.marquees) do
        marquee:stopAnimation()
    end
end

function CategoryList:stopAnimation(row)
    self.listview.marquees[row]:stopAnimation()
end

function CategoryList:drawInRect()
    self.listview:drawInRect(horizontalMargin, self.yMargin,
        screenWidth - (horizontalMargin * 2), screenHeight - self.yMargin)
end

-- Returns false if we're already at the bottom
function CategoryList:scrollDown()    
    local prevSelectedRow = self.listview:getSelectedRow()
    self.listview:selectNextRow(false, true, true)
    
    local difRows = self.listview:getSelectedRow() ~= prevSelectedRow

    -- Don't stop animation if we're already at the bottom/top.
    if difRows then
        self:stopAnimation(prevSelectedRow)
        self:runSelected()
    end

    return difRows
end

-- Returns false if we're already at the top
function CategoryList:scrollUp()
    local prevSelectedRow = self.listview:getSelectedRow()
    self.listview:selectPreviousRow(false, true, true)

    local difRows = self.listview:getSelectedRow() ~= prevSelectedRow

    -- Don't stop animation if we're already at the bottom/top.
    if difRows then
        self:stopAnimation(prevSelectedRow)
        self:runSelected()
    end

    return difRows
end

function CategoryList:updateRowText(row, text)
    self.listview.marquees[row]:setText(text)
end

function CategoryList:drawCell(section, row, column, selected, x, y, width, height)
    gfx.pushContext()
        if selected then 
            gfx.fillRoundRect(x, y, width, height, 4)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end

        gfx.setFont(weekdayFont)
        local textYCoord = y + (verticalPadding / 2)

        -- We want to right-align the weekday text
        local weekdayXPos = x + self.weekdayWidth - weekdayFont:getTextWidth(WEEKDAY_STRINGS[row] .. ":")
        gfx.drawText(WEEKDAY_STRINGS[row] .. ":", weekdayXPos, textYCoord + 3)

        local textPosition = { x = weekdayXPos + weekdayFont:getTextWidth(WEEKDAY_STRINGS[row] .. ":") + weekdayRightMargin, y = textYCoord + 9}
        -- Make sure the provided clip height is within the bounds of the actual list
        -- height.
        -- If the y of this cell would be drawn below the yMargin that the list is placed
        -- at, calculate the amount of visible cell height.
        local clipYPos = y
        local marqueeHeight = height
        if y < self.yMargin then
            clipYPos = self.yMargin
            marqueeHeight -= (y - self.yMargin)
        end
        local clipPosition = {x = textPosition.x, y = clipYPos}

        self.marquees[row]:draw(clipPosition, marqueeHeight, textPosition)

    gfx.popContext()
end