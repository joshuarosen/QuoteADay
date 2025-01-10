import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "audio/audio_manager"

local gfx <const> = playdate.graphics

-- Dialog that pops up when the user changes a category for a given day.

class('CategoryDialog').extends()

local screenWidth, screenHeight = playdate.display.getSize()

local verticalPadding <const> = 10
local topMargin <const> = 60
local horizontalMargin <const> = 10

local weekdayFont = gfx.font.new('fonts/Cursive')
local categoryFont = gfx.font.new('fonts/Nontendo-Light-2x')

local wrapSelection <const> = true

local dialog_border = gfx.image.new("img/DialogBorder2")

local divider = gfx.image.new("img/Divider")
local _dividerWidth, _dividerHeight = divider:getSize()
local dividerSize = { width = _dividerWidth,
                      height = _dividerHeight }

-- Key repeat timer for scrolling while holding down a key.
local scrollRepeatTimer = nil

local dialogWidth <const> = 240
local dialogHeight <const> = 215

local dialogPos = { x = screenWidth / 2 - dialogWidth / 2,
                                 y = screenHeight / 2 - dialogHeight / 2}

local animatorDuration <const> = 200
local animatorIn <const> = gfx.animator.new(animatorDuration, 100, dialogPos.y, playdate.easingFunctions.outSine)
local animatorOut <const> = gfx.animator.new(animatorDuration, dialogPos.y, 240, playdate.easingFunctions.inSine)

function CategoryDialog:init()
    CategoryDialog.super.init(self)
    self.width = dialogWidth
    self.height = dialogHeight
    self.x = 0
    self.y = 0
    self.is_showing = false

    -- This should be set by calling show()
    self.weekday = nil

    self.dialogAnimator = animatorIn
end

function CategoryDialog:setup(categories)
    if scrollRepeatTimer ~= nil then
        scrollRepeatTimer:remove()
    end
    
    self.categories = categories

    local categoryList = playdate.ui.gridview.new(0, 10)
    categoryList:setNumberOfRows(#categories)
    categoryList:setCellSize(0, categoryFont:getHeight() + verticalPadding)

    categoryList.marquees = {}
    for i, category in ipairs(categories) do
        categoryList.marquees[i] = MarqueeText(category, self.width - (horizontalMargin * 2), categoryFont)
    end

    function categoryList:drawCell(section, row, column, selected, x, y, width, height)
        gfx.pushContext()
            gfx.setFont(categoryFont)
            local textWidth, textHeight = gfx.getTextSize(categories[row])
            -- Center in available space
            local textXCoord = x + (width - textWidth) / 2
            local textYCoord = y + (height - textHeight) / 2 + 1
            -- If the width is too large to center, left-align instead
            if textWidth > width then
                textXCoord = x
            end

            if selected then
                gfx.fillRoundRect(x, y, width, height, 4)
            else
                gfx.setLineWidth(1)
                gfx.drawLine(x + 10, y + height + 1, x + width - 10, y + height + 1)
            end

            if selected then
                gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            end

            local marqueeHeight = height
            local listYPos = weekdayFont:getHeight() + 30
            local clipYPos = textYCoord
            if textYCoord < listYPos then
                clipYPos = listYPos
                marqueeHeight -= (textYCoord - listYPos)
            end

            -- Fix bottom clipping
            local listBottomMargin <const> = 10
            local listBottomYCoord = listYPos + dialogHeight - weekdayFont:getHeight() - 30 - listBottomMargin
            if clipYPos + marqueeHeight > listBottomYCoord then
                local difference = (clipYPos + marqueeHeight) - listBottomYCoord
                marqueeHeight -= difference
            end

            local clipPosition = {x = textXCoord, y = clipYPos}
            local textPosition = {x = textXCoord, y = textYCoord}
            self.marquees[row]:draw(clipPosition, marqueeHeight, textPosition)
        gfx.popContext()
    end
    self.categoryList = categoryList
end

function CategoryDialog:moveTo(x, y)
    self.x = x
    self.y = y
end

function CategoryDialog:draw()
    if (not self.is_showing) then
        return
    end
    self:moveTo(screenWidth / 2 - self.width / 2, self.dialogAnimator:currentValue())
    gfx.pushContext()
        gfx.setDrawOffset(self.x, self.y)

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(0, 0, self.width, self.height, 4)
        
        -- Draw the border.
        gfx.setLineWidth(2)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRoundRect(0, 0, self.width, self.height, 4)

        gfx.setFont(weekdayFont)
        gfx.drawText(self.weekday, self.width / 2 - weekdayFont:getTextWidth(self.weekday) / 2, 15)

        divider:draw(self.width / 2 - dividerSize.width / 2, 52)

        local listBottomMargin <const> = 10
        local listYPos = weekdayFont:getHeight() + 30
        self.categoryList:drawInRect(horizontalMargin, listYPos, self.width - (horizontalMargin * 2), self.height - weekdayFont:getHeight() - 30 - listBottomMargin)
    gfx.popContext()
end

function CategoryDialog:show(weekday, category_index)
    if scrollRepeatTimer ~= nil then
        scrollRepeatTimer:remove()
    end

    self.weekday = weekday
    self.categoryList:setSelectedRow(category_index)
    self.categoryList:scrollToRow(category_index, false)

    -- Start animating marquee
    local selectedMarquee = self.categoryList.marquees[self.categoryList:getSelectedRow()]
    selectedMarquee:startAnimation()

    self.is_showing = true

    self.dialogAnimator = animatorIn
    self.dialogAnimator:reset()

    self.is_animating = true
    playdate.timer.performAfterDelay(animatorDuration, function() self.is_animating = false end)
end

function CategoryDialog:hide()
    if scrollRepeatTimer ~= nil then
        scrollRepeatTimer:remove()
    end

    -- Stop animating marquee
    local selectedMarquee = self.categoryList.marquees[self.categoryList:getSelectedRow()]
    selectedMarquee:stopAnimation()

    self.dialogAnimator = animatorOut
    self.dialogAnimator:reset()

    self.is_animating = true
    playdate.timer.performAfterDelay(animatorDuration, function()
        self.is_animating = false
        self.is_showing = false
        self.weekday = nil
    end)
end

function CategoryDialog:isShowing()
    return self.is_showing
end

function CategoryDialog:isAnimating()
    return self.is_animating
end

function CategoryDialog:getSelection()
    return self.categoryList:getSelectedRow()
end

function CategoryDialog:handleCrankScroll()
    if not self.is_showing then
        return
    end

    -- Pass in the count of list items so that completing a full revolution will scroll
    -- across the full list (+3 makes so it's not QUITE a full rotation, feels better.)
    local crankTicks = playdate.getCrankTicks(#self.categories + 3)
    if crankTicks == 1 then
        local prevSelectedRow = self.categoryList:getSelectedRow()
        self.categoryList:selectNextRow(true, true, true)
        if self.categoryList:getSelectedRow() ~= prevSelectedRow then
            AudioManager:playScrollDown()

            -- Stop animating previous marquee
            local prevSelectedMarquee = self.categoryList.marquees[prevSelectedRow]
            prevSelectedMarquee:stopAnimation()

            -- Start animating selected marquee
            local selectedMarquee = self.categoryList.marquees[self.categoryList:getSelectedRow()]
            selectedMarquee:startAnimation()
        end
    elseif crankTicks == -1 then
        local prevSelectedRow = self.categoryList:getSelectedRow()
        self.categoryList:selectPreviousRow(true, true, true)
        if self.categoryList:getSelectedRow() ~= prevSelectedRow then
            AudioManager:playScrollUp()

            -- Stop animating previous marquee
            local prevSelectedMarquee = self.categoryList.marquees[prevSelectedRow]
            prevSelectedMarquee:stopAnimation()

            -- Start animating selected marquee
            local selectedMarquee = self.categoryList.marquees[self.categoryList:getSelectedRow()]
            selectedMarquee:startAnimation()
        end
    end
end

function CategoryDialog:upButtonDown()
    if self.is_showing then
        local function timerCallback()
            local prevSelectedRow = self.categoryList:getSelectedRow()
            self.categoryList:selectPreviousRow(wrapSelection, true, true)
            if self.categoryList:getSelectedRow() ~= prevSelectedRow then
                AudioManager:playScrollUp()

                -- Stop animating previous marquee
                local prevSelectedMarquee = self.categoryList.marquees[prevSelectedRow]
                prevSelectedMarquee:stopAnimation()

                -- Start animating selected marquee
                local selectedMarquee = self.categoryList.marquees[self.categoryList:getSelectedRow()]
                selectedMarquee:startAnimation()
            end
        end
        scrollRepeatTimer = playdate.timer.keyRepeatTimer(timerCallback)
    end
end

function CategoryDialog:upButtonUp()
    if self.is_showing then
        scrollRepeatTimer:remove()
    end
end

function CategoryDialog:downButtonDown()
    if self.is_showing then
        local function timerCallback()
            local prevSelectedRow = self.categoryList:getSelectedRow()
            self.categoryList:selectNextRow(wrapSelection, true, true)
            if self.categoryList:getSelectedRow() ~= prevSelectedRow then
                AudioManager:playScrollDown()

                -- Stop animating previous marquee
                local prevSelectedMarquee = self.categoryList.marquees[prevSelectedRow]
                prevSelectedMarquee:stopAnimation()

                -- Start animating selected marquee
                local selectedMarquee = self.categoryList.marquees[self.categoryList:getSelectedRow()]
                selectedMarquee:startAnimation()
            end
        end
        scrollRepeatTimer = playdate.timer.keyRepeatTimer(timerCallback)
    end
end

function CategoryDialog:downButtonUp()
    if self.is_showing then
        scrollRepeatTimer:remove()
    end
end
