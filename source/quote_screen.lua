import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/animator"

import "quote_orchestrator"

import "audio/audio_manager"
import "ui/fade_image"
import "ui/fill_button"
import "ui/fade_image_sequencer"
import "ui/quote_image_builder"
import "ui/reload_dialog"
import "ui/schedule_promo_dialog"
import "util/string_util"
import "util/anim_util"

import "data/game_data"
import "data/seen_data"

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer
local screenWidth, screenHeight = playdate.display.getSize()

QuoteScreen = { 
    -- If this is true, run first-time setup operations when setup() is called.
    firstTimeSetup = true,
    preventTransition = false
}

-- For debugging:
local use_quote_override = false
local quote_override = {
    quote = "Never let anyone - any person or any force - dampen, dim or diminish your light.",
    attribution = "Margaret Elizabeth Sangster"
}
local always_fade_in = false
local always_run_border_anim = false

-- The animation for the border "ribbon" around today's quote.
-- We only play this animation when the user first launches the app.
local borderAnim = gfx.imagetable.new("img/FullBorderAnim")
local borderDuration <const> = 4500
local curBorderDuration = 0
local borderAnimator = nil
local skipAnimation = false
local borderAnimFinished = false

-- Animator for transitioning to the schedule screen. We slide the quote screen to the
-- left using xOffset.
local transitionAnimator = nil
local xOffset = 0

local enableShowDialog = true
local reloadDialog = ReloadDialog({x = 322, y = 175})

local schedulePromoDialog = SchedulePromoDialog({x = 265, y = 50})

local orchestrator = QuoteOrchestrator()

local hasFinishedImg = false
local finishedImg = gfx.image.new(screenWidth, screenHeight)

-- If user has transitioned at all, don't bother showing the schedule promo.
local hasTransitioned = false

function table.clone(org)
    return {table.unpack(org)}
end

local function getTodayQuotes()
    local todayCategory = QuoteScreen.todayCategory
    if todayCategory == "random" then
        local category_index = math.random(2, #QuoteScreen.categories)
        todayCategory = QuoteScreen.categories[category_index]
    end

    -- We need to clone the quoteData table to remove from it if we've already seen the
    -- quote.
    return table.clone(QuoteScreen.quoteData[todayCategory])
end

local function generateQuote()
    if (use_quote_override) then
        return quote_override.quote, quote_override.attribution
    end

    local today_quotes = getTodayQuotes()
    local quote = nil
    repeat
        -- Keep going until we hit an unseen quote.
        -- Probably not great perf-wise... but works fine for our data.
        local dataIndex = math.floor(math.random(1, #today_quotes))
        quote = today_quotes[dataIndex]
        if SeenData:hasSeenQuote(quote.quote, quote.attribution) then
            table.remove(today_quotes, dataIndex)
            quote = nil
            if #today_quotes == 0 then
                SeenData:clear()
                today_quotes = getTodayQuotes()
            end
        end
    until quote ~= nil

    return quote.quote, quote.attribution 
end

local function drawBorder()
    local frame_index = 1
    if borderAnimator ~= nil then
        frame_index = math.min(math.ceil(borderAnimator:currentValue()), borderAnim:getLength())
    end
    if skipAnimation and not always_run_border_anim then
        frame_index = borderAnim:getLength()
    end
    if frame_index == borderAnim:getLength() then
        borderAnimFinished = true
    end
    borderAnim:getImage(frame_index):draw(0, 0)
    borderAnim:getImage(frame_index):draw(200, 0, gfx.kImageFlippedX)
end

function QuoteScreen:setup()
    self.preventTransition = false
    -- Only generate the quote on the first time we see the QuoteScreen. If we return to
    -- the quote screen from a different screen, just use the previously saved quote.
    if self.firstTimeSetup then
        local quote, attribution
        local showFade = true
        -- If we've already seen a quote today, use that one. Don't generate a new one.
        if GameData:hasSeenTodayQuote() then
            showFade = false
            quote, attribution = GameData:getLatestQuote()
            if (use_quote_override) then
                quote = quote_override.quote
                attribution = quote_override.attribution
            end
            skipAnimation = true
        else
            quote, attribution = generateQuote()
        end
        -- For debugging:
        if always_fade_in then
            showFade = true
        end

        orchestrator:setQuote(quote, attribution)
        if showFade then
            -- If this is the first time the user has launched the app, then show the
            -- schedule promo dialog after the fade finishes.
            if GameData:isFirstAppLaunch() then
                orchestrator:fadeIn(function()
                    playdate.timer.performAfterDelay(2000, function()
                        -- Don't bother showing the promo if user has already transitioned.
                        if not hasTransitioned then
                            schedulePromoDialog:show()
                        end
                        -- We can mark the app launched now, after we've seen everything that
                        -- depends on it.
                        GameData:markAppLaunched()
                    end)

                    self:saveFinishedImage()
                end)
            else
                orchestrator:fadeIn(function()
                    self:saveFinishedImage()
                end)
            end
        else
            orchestrator:finishFade()
            self:saveFinishedImage()
        end

        GameData:markSeenQuote(quote, attribution)
        SeenData:markSeenQuote(quote, attribution)

        reloadDialog:setCallback(function() self:onReloadClicked() end)
        self.firstTimeSetup = false
    end
end

function QuoteScreen:initialize()
    orchestrator = QuoteOrchestrator()
    curBorderDuration = 0
    borderAnimator = nil
    skipAnimation = false
    borderAnimFinished = false
    transitionAnimator = nil
    xOffset = 0
    enableShowDialog = true
    reloadDialog = ReloadDialog({x = 322, y = 175})
    schedulePromoDialog = SchedulePromoDialog({x = 265, y = 50})
    hasFinishedImg = false
    self.preventTransition = false
end

function QuoteScreen:saveFinishedImage()
    gfx.pushContext(finishedImg)
        gfx.clear()
        -- Need to remove the offset, so we don't save the screen mid-transition.
        self:drawScreen(true)
    gfx.popContext()
    hasFinishedImg = true
end

function QuoteScreen:transitionTrigger()
    -- We're animating past the end of the borderAnim length by a little bit to keep some
    -- extra curve acceleration.
    AudioManager:playUnroll()
    borderAnimator = playdate.graphics.animator.new(borderDuration, 1, borderAnim:getLength() + 8,
        playdate.easingFunctions.outSine)
    self:setup()
end

function QuoteScreen:startOutTransition(endOutTransitionFunc)
    hasTransitioned = true
    AudioManager:playTransition()

    -- Hide dialogs if showing
    if reloadDialog:isShowing() then
        reloadDialog:hide()
    end
    if schedulePromoDialog.isShowing then
        schedulePromoDialog:hide()
    end

    transitionAnimator = createTransitionOutAnimator(-1)
    timer.performAfterDelay(TRANSITION_ANIM_DURATION, endOutTransitionFunc)
end

function QuoteScreen:gameWillPause()
    -- Hide when user presses pause button. Dialog will actually hide when game resumes.
    if schedulePromoDialog.isShowing then
        schedulePromoDialog:hide()
    end
end

function QuoteScreen:startInTransition()
    transitionAnimator = createTransitionInAnimator(-1)
end

function QuoteScreen:drawTransitionUnder()
    self:update()
end

function QuoteScreen:teardown()
    AudioManager:cancelScrawl()
    AudioManager:cancelUnroll()
    orchestrator:finishFade()
    skipAnimation = true
    self:saveFinishedImage()
    self.preventTransition = false

    if reloadDialog:isShowing() then
        reloadDialog:hide()
    end
end

-- If all conditions are met, reload dialog is shown.
-- If showCrank is true, default to the crank image. Otherwise, use the A image.
function QuoteScreen:maybeShowReloadDialog(showCrank)
    if enableShowDialog and orchestrator:isFinished()
        and not reloadDialog:isShowing() and not reloadDialog:isAnimating() then
        AudioManager:playOpenReloadDialog()
        reloadDialog:show(showCrank)
    end
end

function QuoteScreen:maybeHideReloadDialog()
    if reloadDialog:isShowing() and not reloadDialog:isAnimating() then
        AudioManager:playCloseReloadDialog()
        reloadDialog:hide()
    end
end

function QuoteScreen:cranked(change, acceleratedChange) 
    -- If user wiggles the crank, show the reload dialog if not already shown.
    if change ~= 0 then
        self:maybeShowReloadDialog(true)
    end
end

function QuoteScreen:crankUndocked()
    self:maybeShowReloadDialog(true)
end

function QuoteScreen:crankDocked()
    self:maybeHideReloadDialog()
end

function QuoteScreen:AButtonDown()
    self:maybeShowReloadDialog(false)
end

function QuoteScreen:BButtonUp()
    self:maybeHideReloadDialog()
end

function QuoteScreen:reloadNewQuote()
    self.preventTransition = true
    self:hideMenu()
    hasFinishedImg = false

    enableShowDialog = false
    local fadeOutTime = orchestrator:fadeOut()
    timer.performAfterDelay(fadeOutTime + 250, function() 
        enableShowDialog = true

        local quote, attribution = generateQuote()
        orchestrator:setQuote(quote, attribution)
        orchestrator:fadeIn(function()
            self.preventTransition = false
            self:showMenu()
            self:saveFinishedImage()
        end)

        GameData:markSeenQuote(quote, attribution)
        SeenData:markSeenQuote(quote, attribution)
    end)
end

function QuoteScreen:onReloadClicked()
    if reloadDialog:isShowing() then
        AudioManager:playCloseReloadDialog()
        reloadDialog:hide()
    end

    self:reloadNewQuote()
end

function QuoteScreen:update()
    if transitionAnimator ~= nil then
        xOffset = math.ceil(transitionAnimator:currentValue())
    end

    if hasFinishedImg then
        gfx.pushContext()
            gfx.setDrawOffset(xOffset, 0)
            finishedImg:draw(0, 0)
        gfx.popContext()
    else
        self:drawScreen()
    end

    reloadDialog:update(xOffset)
    schedulePromoDialog:update(xOffset)

    timer.updateTimers()
end

function QuoteScreen:drawScreen(removeOffset)
    local removeOffset = removeOffset or false
    gfx.pushContext()
        if not removeOffset then
            gfx.setDrawOffset(xOffset, 0)
        end
        drawBorder()
        orchestrator:update()
    gfx.popContext()
end