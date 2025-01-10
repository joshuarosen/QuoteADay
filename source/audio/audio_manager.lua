import "CoreLibs/timer"

local sound <const> = playdate.sound
local timer <const> = playdate.timer

AudioManager = {}

local zipClickPlayer = sound.sampleplayer.new("audio/ZipClick")
zipClickPlayer:setVolume(0.22)

local confirmClickPlayer = sound.sampleplayer.new("audio/ConfirmClick")
confirmClickPlayer:setVolume(0.25)

local transitionPlayer = sound.sampleplayer.new("audio/ScreenTransition")

local scrawlPlayer = sound.sampleplayer.new("audio/QuoteScrawl")
local scrawlFadeTime <const> = 250
local fadeRepeatTimer = nil
local initialTimer = nil
local stopTimer = nil

local erasePlayer = sound.sampleplayer.new("audio/Erase")
local eraseFadeTime <const> = 250

local openReloadPlayer = sound.sampleplayer.new("audio/Select2")
local closeReloadPlayer = sound.sampleplayer.new("audio/Select1")

local unrollPlayer = sound.sampleplayer.new("audio/Unroll")

function AudioManager:playUnroll()
    unrollPlayer:play(1)
end

function AudioManager:cancelUnroll()
    unrollPlayer:stop()
end

function AudioManager:playScrollUp()
    zipClickPlayer:play(1)
end

function AudioManager:playScrollDown()
    -- We pitch scrolling down slightly lower with a lower rate.
    zipClickPlayer:play(1, 0.8)
end

function AudioManager:playConfirmClick()
    confirmClickPlayer:play(1, 0.65)
end

function AudioManager:playDialogConfirmClick()
    confirmClickPlayer:play(1, 0.8)
end

function AudioManager:playTransition(rateOverride)
    local rateOverride = rateOverride or 1
    transitionPlayer:setRate(rateOverride)
    transitionPlayer:play(1)
end

function AudioManager:playOpenReloadDialog()
    openReloadPlayer:play(1)
end

function AudioManager:playCloseReloadDialog()
    closeReloadPlayer:play(1)
end

-- Cancel all scrawl timers, stop scrawl audio.
function AudioManager:cancelScrawl()
    if fadeRepeatTimer ~= nil then
        fadeRepeatTimer:remove()
    end
    if initialTimer ~= nil then
        initialTimer:remove()
    end
    if stopTimer ~= nil then
        stopTimer:remove()
    end
    scrawlPlayer:stop()
    scrawlPlayer:setVolume(1)
end

local function fadeOutAudio(fadeTime, audioPlayer)
    local fadeTickInterval <const> = 100.0
    local step = 1.0 / (fadeTime / fadeTickInterval)
    local function timerCallback()
        local newVol = math.max(0, audioPlayer:getVolume() - step)
        audioPlayer:setVolume(newVol)
        if (newVol == 0) then
            audioPlayer:stop()
            fadeRepeatTimer:remove()
        end
    end
    fadeRepeatTimer = timer.keyRepeatTimerWithDelay(fadeTickInterval,
        fadeTickInterval,
        timerCallback)
end

-- Initial delay is how many ms to wait before starting scrawl.
-- Length is how many ms to play the scrawl for.
function AudioManager:playScrawl(initialDelay, length)
    initialTimer = timer.performAfterDelay(initialDelay, function() 
        scrawlPlayer:setVolume(1)
        scrawlPlayer:play(1) 
    end)
    -- Need to manually fade out the scrawl, since sampleplayer doesn't support it.
    -- Fileplayer supports a volume fade, but requires a higher CPU overhead.
    stopTimer = timer.performAfterDelay(initialDelay + length, function() fadeOutAudio(scrawlFadeTime, scrawlPlayer) end)
end

function AudioManager:playErase(length)
    erasePlayer:setVolume(1)
    erasePlayer:play(1)
    stopTimer = timer.performAfterDelay(length, function() fadeOutAudio(eraseFadeTime, erasePlayer) end)
end