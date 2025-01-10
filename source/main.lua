import "time"
import "quote_screen"
import "schedule_screen"
import "intro_screen"

import "data/game_data"
import "data/seen_data"
import "data/quote_data"

local gfx <const> = playdate.graphics
local datastore <const> = playdate.datastore

-- The default refresh rate is 30. We can support the max of 50 pretty easily.
playdate.display.setRefreshRate(50)

-- For debugging:
local alwaysShowIntro <const> = false
local showFPS <const> = false

local menu = playdate.getSystemMenu()

-- Used for transitions. We need to draw both nextScreen and currentScreen during
-- the transition.
local nextScreen = nil
local currentScreen = nil

-- Forward declare local functions so we can reference them earlier than their definition.
local changeScreen, handleMenuItems

local removeNextScreen = false
local is_transitioning = false

function appStartup()
    time = Time:getTime()

    nextScreen = nil
    currentScreen = nil
    removeNextScreen = false
    is_transitioning = false

    -- Reset "first time setup" flag for QuoteScreen.
    QuoteScreen.firstTimeSetup = true

    -- Load data on startup
    QuoteData:loadData(time.weekday)
    GameData:loadData(time)
    SeenData:loadData()

    -- Determine the screen to start on. If we've already seen the intro screen today, don't
    -- show it again.
    local firstScreen = IntroScreen
    if not alwaysShowIntro and GameData:hasSeenTodayQuote() then
        print("Has seen today quote")
        -- Already seen the intro screen, skip to quote screen
        firstScreen = QuoteScreen
    end

    -- Inject data into relevant screen
    QuoteScreen.quoteData = QuoteData.quoteData
    QuoteScreen.todayCategory = QuoteData.todayCategory
    QuoteScreen.categories = QuoteData.categories
    QuoteScreen.quoteScheduleData = QuoteData.quoteScheduleData

    ScheduleScreen.categories = QuoteData.categories
    ScheduleScreen.quoteScheduleData = QuoteData.quoteScheduleData

    QuoteScreen:initialize()
    ScheduleScreen:initialize()
    
    -- Set up the first screen of the app.
    changeScreen(firstScreen)
end

-- If the user changes today's category on the schedule screen, we need to also update it
-- on the quote screen (in case the user reloads today's quote).
ScheduleScreen.updateTodayCategory = function (newTodayCategory)
    QuoteScreen.todayCategory = newTodayCategory
end

QuoteScreen.hideMenu = function ()
    menu:removeAllMenuItems()
end

QuoteScreen.showMenu = function ()
    handleMenuItems(QuoteScreen)
end

-- Leaving the schedule screen should navigate to the QuoteScreen
ScheduleScreen.leaveScreen = function()
    is_transitioning = true
    ScheduleScreen:startOutTransition(function()
        changeScreen(QuoteScreen)
        removeNextScreen = true
        is_transitioning = false
    end)
    QuoteScreen:startInTransition()
    nextScreen = QuoteScreen
end

IntroScreen.startTransition = function()
    nextScreen = QuoteScreen
end

-- This trigger may occur as a result of something the main screen is doing to signal to
-- the next screen. For example, intro screen wants to start the quote border animation
-- when we pass a certain crank threshold.
IntroScreen.transitionTrigger = function()
    if nextScreen ~= nil and nextScreen.transitionTrigger ~= nil then
        nextScreen:transitionTrigger()
    end
end

IntroScreen.endTransition = function()
    changeScreen(nextScreen)
    nextScreen = nil 
end

function changeScreen(newScreen)
    if (currentScreen ~= nil and currentScreen.teardown ~= nil) then
        currentScreen:teardown()
    end
    handleMenuItems(newScreen)
    currentScreen = newScreen
    currentScreen:setup()
end

local function screenTransition(oldScreen, newScreen)
    -- If transition is already in progress, this is a no-op.
    if is_transitioning then return end
    is_transitioning = true
    oldScreen:startOutTransition(function() 
        changeScreen(newScreen)
        -- We have to set a flag to remove nextScreen after update loop, if we
        -- set it to nil here then we get a flicker.
        removeNextScreen = true
        is_transitioning = false
    end)
    newScreen:startInTransition()
    nextScreen = newScreen
end

function handleMenuItems(newScreen)
    menu:removeAllMenuItems()
    if (newScreen == QuoteScreen) then
        local scheduleItem, error = menu:addMenuItem("schedule", function()
            screenTransition(QuoteScreen, ScheduleScreen)
        end)
    elseif (newScreen == ScheduleScreen) then
        local scheduleItem, error = menu:addMenuItem("see quote", function()
            screenTransition(ScheduleScreen, QuoteScreen)
        end)
    end
end

-- Do all startup tasks.
Time:load()
appStartup()

function playdate.deviceDidUnlock()
    -- If the day has changed, reset back to app start.
    local prevWeekday = time.weekday
    Time:load()
    if prevWeekday ~= Time:getTime().weekday then
        QuoteScreen:teardown()
        ScheduleScreen:teardown()
        appStartup()
    end
end

function playdate.update()
    gfx.clear()

    -- The order in which we call the following drawTransitionX functions is important to
    -- make sure we draw the screens in the wrong order.
    -- If you think this abstraction is overkill for an app with only 3 screens (intro,
    -- quote, schedule), you might be correct.

    -- If next screen is non-nil, then we're transitioning to a new screen.
    if nextScreen ~= nil and nextScreen.drawTransitionUnder ~= nil then
        -- Draw the next screen first so the current screen is drawn on top.
        nextScreen:drawTransitionUnder()
    end

    if currentScreen ~= nil then
        currentScreen:update()
    end

    if nextScreen ~= nil and nextScreen.drawTransitionOnTop ~= nil then
        nextScreen:drawTransitionOnTop()
    end

    if removeNextScreen then
        nextScreen = nil
        removeNextScreen = false
    end

    if showFPS then
        playdate.drawFPS(380, 0)
    end
end

-- Forward inputs to the current screen.
----------------------------------------
local function handleInput(inputFunc)
    if not is_transitioning and inputFunc ~= nil then
        inputFunc(currentScreen)
    end
end

function playdate.BButtonUp()
    handleInput(currentScreen.BButtonUp)
end

function playdate.AButtonUp()
    handleInput(currentScreen.AButtonUp)
end

function playdate.AButtonDown()
    handleInput(currentScreen.AButtonDown)
end

function playdate.upButtonUp()
    handleInput(currentScreen.upButtonUp)
end

function playdate.downButtonUp()
    handleInput(currentScreen.downButtonUp)
end

function playdate.upButtonDown()
    handleInput(currentScreen.upButtonDown)
end

function playdate.downButtonDown()
    handleInput(currentScreen.downButtonDown)
end

function playdate.rightButtonUp()
    if currentScreen == QuoteScreen and not QuoteScreen.preventTransition then
        screenTransition(QuoteScreen, ScheduleScreen)
    end
end

function playdate.leftButtonUp()
    if currentScreen == ScheduleScreen then
        screenTransition(ScheduleScreen, QuoteScreen)
    end
end

function playdate.crankDocked()
    handleInput(currentScreen.crankDocked)
end

function playdate.crankUndocked()
    handleInput(currentScreen.crankUndocked)
end

function playdate.cranked(change, acceleratedChange)
    if not is_transitioning and currentScreen.cranked ~= nil then
        currentScreen:cranked(change, acceleratedChange)
    end
end
----------------------------------------

function playdate.gameWillPause()
    if currentScreen.gameWillPause ~= nil then
        currentScreen:gameWillPause()
    end
end

local function saveData()
    QuoteData:saveQuoteScheduleData()
    GameData:writeToDisk()
    SeenData:writeToDisk()
end

-- We need to save when the device will lock, as when the device unlocks it may be the
-- next day.
function playdate.deviceWillLock()
    saveData()
end

function playdate.gameWillTerminate()
    saveData()
end

function playdate.deviceWillSleep()
    saveData()
end