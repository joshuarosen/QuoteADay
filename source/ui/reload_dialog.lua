import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/easing"

local gfx <const> = playdate.graphics

-- This dialog allows the player to reload today's quote and get a new quote in the same category.

class ('ReloadDialog').extends()

local dialogFont = gfx.font.new('fonts/Nontendo-Light-2x')
local reloadButtonFont = gfx.font.new('fonts/Roobert-11-Medium')

-- The player can use either the A button or the crank to confirm the quote reload action.
local reloadButtonImg = gfx.image.new(reloadButtonFont:getTextWidth("A") + 1, reloadButtonFont:getHeight())
gfx.pushContext(reloadButtonImg)
    gfx.setFont(reloadButtonFont)
    gfx.drawText("A", 1, 0)
gfx.popContext()

local reloadButtonCrankImg = gfx.image.new(18, 18)
gfx.pushContext(reloadButtonCrankImg)
    gfx.drawText("🎣", 0, 0)
gfx.popContext()

local width <const> = 145
local height <const> = 90

local animatorDuration <const> = 200
local animatorIn <const> = gfx.animator.new(animatorDuration, 100, 0, playdate.easingFunctions.outBack)
local animatorOut <const> = gfx.animator.new(animatorDuration, 0, 100, playdate.easingFunctions.inBack)

function ReloadDialog:init(position)
    self.rect = playdate.geometry.rect.new(position.x - width / 2, position.y - height / 2, width, height)
    self.reloadButton = FillButton({x = self.rect.x + width / 2, y = self.rect.y + height - 30}, 17, reloadButtonImg, reloadButtonCrankImg, 8, nil, 1200, nil, callback)
    self.reloadButton:disableInput()
    self.is_showing = false

    self.x = 0
    self.y = 0

    self.dialogAnimator = animatorIn
end

function ReloadDialog:setCallback(callback)
    self.reloadButton:setCallback(callback)
end

function ReloadDialog:moveTo(x, y)
    self.x = x
    self.y = y
end

function ReloadDialog:update(screenXOffset)
    if not self.is_showing then
        return
    end
    self:moveTo(0, self.dialogAnimator:currentValue())
    local screenXOffset = screenXOffset or 0

    local arrowWidth <const> = 40
    local arrowHeight <const> = 20
    local xOffset <const> = 32
    gfx.pushContext()
        gfx.setDrawOffset(self.x + screenXOffset, self.y)

        -- Some fun geometry for drawing the dialog border, with an arrow pointing down at the A button.
        gfx.setLineWidth(3)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(xOffset + self.rect.x + self.rect.width / 2 - arrowWidth / 2, self.rect.y + self.rect.height,
                    xOffset + self.rect.x + self.rect.width / 2, self.rect.y + self.rect.height + arrowHeight)
        gfx.drawLine(xOffset + self.rect.x + self.rect.width / 2 + arrowWidth / 2, self.rect.y + self.rect.height,
                    xOffset + self.rect.x + self.rect.width / 2, self.rect.y + self.rect.height + arrowHeight)
                    
        gfx.setLineWidth(6)
        gfx.drawRoundRect(self.rect, 5)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(self.rect, 5)
        gfx.setFont(dialogFont)

        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(xOffset + self.rect.x + self.rect.width / 2 - arrowWidth / 2 + 2, self.rect.y + self.rect.height,
                    xOffset + self.rect.x + self.rect.width / 2 + arrowWidth / 2 - 2, self.rect.y + self.rect.height,
                    xOffset + self.rect.x + self.rect.width / 2, self.rect.y + self.rect.height + arrowHeight - 2)

        local textWidth = dialogFont:getTextWidth("New quote")
        local textHeight = dialogFont:getHeight()
        gfx.drawText("New quote", self.rect.x + self.rect.width / 2 - textWidth / 2,
            self.rect.y + 5)
    gfx.popContext()

    gfx.pushContext()
        gfx.setDrawOffset(self.x + screenXOffset, self.y)
        self.reloadButton:update()
    gfx.popContext()
end

function ReloadDialog:show(showCrank)
    self.reloadButton:reset(showCrank)
    self.is_showing = true

    self.dialogAnimator = animatorIn
    self.dialogAnimator:reset()

    self.is_animating = true
    playdate.timer.performAfterDelay(animatorDuration, function() 
        self.is_animating = false
        self.reloadButton:enableInput()
    end)
end

function ReloadDialog:hide()
    self.reloadButton:disableInput()
 
    self.dialogAnimator = animatorOut
    self.dialogAnimator:reset()

    self.is_animating = true
    playdate.timer.performAfterDelay(animatorDuration, function () 
        self.is_showing = false
        self.is_animating = false
        self.reloadButton:reset()
    end)
end

function ReloadDialog:isAnimating()
    return self.is_animating
end

function ReloadDialog:isShowing()
    return self.is_showing
end