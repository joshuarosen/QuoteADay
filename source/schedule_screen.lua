import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/timer"
import "Corelibs/crank"

import "time"
import "audio/audio_manager"
import "ui/category_dialog"
import "ui/category_list"
import "util/anim_util"
import "util/table_util"
import "util/string_util"

ScheduleScreen = {}

local gfx <const> = playdate.graphics
local topMargin <const> = 70

local screenWidth, screenHeight = playdate.display.getSize()

local titleFont = gfx.font.new('fonts/Dico-24')

local divider = gfx.image.new("img/Divider2")
local _dividerWidth, _dividerHeight = divider:getSize()
local dividerSize = { width = _dividerWidth,
                      height = _dividerHeight }

local transitionAnimator = nil

-- Key repeat timer for scrolling while holding down a key.
local scrollRepeatTimer = nil

local categoryDialog = CategoryDialog()
local categoryList = nil

-- TODO: I am too lazy to fix this, but this should use an image table for these different
-- pre-computed fade images.
-- See fade_image_patterns.lua for a correct example.
local faded = false
local fadeImage1 = gfx.image.new(screenWidth, screenHeight)
gfx.pushContext(fadeImage1)
    gfx.setStencilPattern(0.05)
    gfx.fillRect(0, 0, screenWidth, screenHeight)
gfx.popContext()

local fadeImage2 = gfx.image.new(screenWidth, screenHeight)
gfx.pushContext(fadeImage2)
    gfx.setStencilPattern(0.1)
    gfx.fillRect(0, 0, screenWidth, screenHeight)
gfx.popContext()

local fadeImage3 = gfx.image.new(screenWidth, screenHeight)
gfx.pushContext(fadeImage3)
    gfx.setStencilPattern(0.15)
    gfx.fillRect(0, 0, screenWidth, screenHeight)
gfx.popContext()

local fadeImage4 = gfx.image.new(screenWidth, screenHeight)
gfx.pushContext(fadeImage4)
    gfx.setStencilPattern(0.2)
    gfx.fillRect(0, 0, screenWidth, screenHeight)
gfx.popContext()

local fadeImage5 = gfx.image.new(screenWidth, screenHeight)
gfx.pushContext(fadeImage5)
    gfx.setStencilPattern(0.25)
    gfx.fillRect(0, 0, screenWidth, screenHeight)
gfx.popContext()

local function getFadeFromTable(alpha)
    if alpha <= 0.05 then
        return fadeImage1
    elseif alpha <= 0.1 then
        return fadeImage2
    elseif alpha <= 0.15 then
        return fadeImage3
    elseif alpha <= 0.2 then
        return fadeImage4
    else
        return fadeImage5
    end
end

local curFadeImage = fadeImage1

local savedFadeImage = gfx.image.new(screenWidth, screenHeight)

local fadeTimer = nil
local fadeImage = gfx.image.new(screenWidth, screenHeight)
local function setFadeImage(alpha)
    gfx.pushContext(fadeImage)
        gfx.clear(gfx.kColorClear)
        gfx.setStencilPattern(alpha)
        gfx.fillRect(0, 0, screenWidth, screenHeight)
    gfx.popContext()
end

function ScheduleScreen:initialize()
    faded = false
    hasSavedFadeImage = false
    savedFadeImage = gfx.image.new(screenWidth, screenHeight)

    self.todayIndex = Time:getTime().weekday
    categoryList = CategoryList(ScheduleScreen.quoteScheduleData, self.todayIndex, topMargin)
    categoryList:scrollToToday()
end

function ScheduleScreen:setup()
    faded = false
    hasSavedFadeImage = false
    savedFadeImage = gfx.image.new(screenWidth, screenHeight)

    gfx.clear()
    gfx.sprite.removeAll()

    categoryDialog:setup(ScheduleScreen.categories)
    categoryList:runSelected()
end

function ScheduleScreen:teardown()
    faded = false
    hasSavedFadeImage = false
    savedFadeImage = gfx.image.new(screenWidth, screenHeight)

    -- Hide category dialog if showing
    if categoryDialog:isShowing() then
        categoryDialog:hide()
    end

    -- Reset the selected item back to today when we leave this screen.
    categoryList:scrollToToday()
    categoryList:stopAllAnimations()
end

-- Draws the title and list of schedule options.
function ScheduleScreen:drawSchedule() 
    if faded and hasSavedFadeImage then
        savedFadeImage:draw(0, 0)
        return
    end   

    gfx.pushContext()
        gfx.setFont(titleFont)
        local titleWidth, titleHeight = gfx.getTextSize("Quote Schedule")
        local titleXPos = (screenWidth / 2) - (titleWidth / 2)
        local dividerPadding <const> = 5
        local titleYPos = (topMargin / 2) - ((titleHeight + dividerSize.height + dividerPadding) / 2)
        gfx.drawText("Quote Schedule", titleXPos, titleYPos + 9)
        divider:draw(0, titleYPos + titleHeight + dividerPadding + 9)
    gfx.popContext()

    -- Draw the list of days/categories
    if categoryList ~= nil then
        categoryList:drawInRect()
    end
end

function ScheduleScreen:saveFadeImage()
    gfx.pushContext(savedFadeImage)
        gfx.clear()
        self:drawSchedule()
        -- Save fade image at highest level of fade.
        fadeImage:draw(0, 0)
    gfx.popContext()
end

function ScheduleScreen:drawFade()
    if faded and not hasSavedFadeImage then
        fadeImage = getFadeFromTable(fadeTimer.value)
        fadeImage:draw(0, 0)
        if fadeTimer.value >= 0.25 then
            self:saveFadeImage()
            hasSavedFadeImage = true
        end
    end
end

function ScheduleScreen:update()
    gfx.pushContext()
    gfx.setDrawOffset(math.ceil(transitionAnimator:currentValue()), 0)

    self:drawSchedule()

    -- Draw fade
    self:drawFade()

    categoryDialog:draw()

    self:handleCrankScroll()
    categoryDialog:handleCrankScroll()
    
    playdate.timer:updateTimers()
    gfx.popContext()
end

function ScheduleScreen:startOutTransition(endOutTransitionFunc)
    AudioManager:playTransition(1.25)

    -- Hide category dialog if showing
    if categoryDialog:isShowing() then
        categoryDialog:hide()
    end

    transitionAnimator = createTransitionOutAnimator(1)
    playdate.timer.performAfterDelay(TRANSITION_ANIM_DURATION, endOutTransitionFunc)
end

function ScheduleScreen:startInTransition()
    transitionAnimator = createTransitionInAnimator(1)
end

function ScheduleScreen:drawTransitionOnTop()
    gfx.pushContext()
        gfx.setDrawOffset(math.ceil(transitionAnimator:currentValue()), 0)
        self:drawSchedule()
    gfx.popContext()
end

function ScheduleScreen:handleCrankScroll()
    if categoryDialog:isShowing() then
        return
    end
    
    -- Pass in the count of list items so that completing a full revolution will scroll
    -- across the full list. (+3 makes so it's not QUITE a full rotation, feels better.)
    local crankTicks = playdate.getCrankTicks(#WEEKDAY_STRINGS + 3)
    if crankTicks == 1 then
        if categoryList:scrollDown() then
            AudioManager:playScrollDown()
        end
    elseif crankTicks == -1 then
        if categoryList:scrollUp() then
            AudioManager:playScrollUp()
        end
    end
end

function ScheduleScreen:upButtonDown()
    if categoryDialog:isShowing() then
        categoryDialog:upButtonDown()
    else
        local function timerCallback()
            if categoryList:scrollUp() then
                AudioManager:playScrollUp()
            end
        end
        scrollRepeatTimer = playdate.timer.keyRepeatTimerWithDelay(150, 150, timerCallback)
    end
end

function ScheduleScreen:upButtonUp()
    if categoryDialog:isShowing() then
        categoryDialog:upButtonUp()
    else
        if scrollRepeatTimer ~= nil then scrollRepeatTimer:remove() end
    end
end

function ScheduleScreen:downButtonDown()
    if categoryDialog:isShowing() then
        categoryDialog:downButtonDown()
    else
        local function timerCallback()
            if categoryList:scrollDown() then
                AudioManager:playScrollDown()
            end
        end
        scrollRepeatTimer = playdate.timer.keyRepeatTimerWithDelay(150, 150, timerCallback)
    end
end

function ScheduleScreen:downButtonUp()
    if categoryDialog:isShowing() then
        categoryDialog:downButtonUp()
    else
        if scrollRepeatTimer ~= nil then scrollRepeatTimer:remove() end
    end
end

function ScheduleScreen:runFade()
    faded = true
    fadeTimer = playdate.timer.new(200, 0, 0.25)
end

function ScheduleScreen:endFade()
    fadeTimer = playdate.timer.new(200, 0.245, 0)
    hasSavedFadeImage = false
    playdate.timer.performAfterDelay(200, function() faded = false end)
end

function ScheduleScreen:AButtonUp()
    if categoryDialog:isShowing() and not categoryDialog:isAnimating() then
        AudioManager:playDialogConfirmClick()
        local selectedCategoryIndex = categoryDialog:getSelection()
        local newCategory = ScheduleScreen.categories[selectedCategoryIndex]

        local prevCategory = ScheduleScreen.quoteScheduleData[categoryList:getSelectedRow()]
        ScheduleScreen.quoteScheduleData[categoryList:getSelectedRow()] = newCategory
        
        categoryList:updateRowText(categoryList:getSelectedRow(), newCategory)
        categoryList:runSelected()

        if categoryList:getSelectedRow() == self.todayIndex and prevCategory ~= newCategory then
            -- If the category was changed for TODAY then we need to update today's category
            -- in case the user reloads the quote.
            ScheduleScreen.updateTodayCategory(newCategory)
        end

        -- Hide category dialog after selection is chosen.
        categoryDialog:hide()
        self:endFade()
    else
        self:runFade()
        
        AudioManager:playConfirmClick()
        local cur_weekday = WEEKDAY_STRINGS[categoryList:getSelectedRow()]
        local cur_category = ScheduleScreen.quoteScheduleData[categoryList:getSelectedRow()]

        categoryList:stopAnimation(categoryList:getSelectedRow())
        categoryDialog:show(cur_weekday, indexOf(ScheduleScreen.categories, cur_category))
    end
end

function ScheduleScreen:BButtonUp()
    if categoryDialog:isShowing() and not categoryDialog:isAnimating() then
        AudioManager:playTransition()
        categoryDialog:hide()
        categoryList:runSelected()
        self:endFade()
    else
        self:endFade()
        self:leaveScreen()
    end
end
