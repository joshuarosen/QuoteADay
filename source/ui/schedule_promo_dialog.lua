import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/easing"

local gfx <const> = playdate.graphics

-- This dialog will show on first-app-launch to inform the player about the "Schedule" feature.

class('SchedulePromoDialog').extends()

local dialogFont = gfx.font.new('fonts/Nontendo-Light-2x')
local dialogText = "Schedule:  "

local width <const> = 180
local height <const> = 45
local arrowLength <const> = 30

local animatorDuration <const> = 350
local animatorIn <const> = gfx.animator.new(animatorDuration, 3, 1, playdate.easingFunctions.outBack)
local animatorOut <const> = gfx.animator.new(animatorDuration, 1, -3, playdate.easingFunctions.inBack)

function SchedulePromoDialog:init(position)
    self.rect = playdate.geometry.rect.new(position.x - width / 2, position.y - height / 2, width, height)
    self.dialogAnimator = animatorIn
    self.isShowing = false
end

function SchedulePromoDialog:update(screenXOffset)
    if not self.isShowing then
        return
    end

    gfx.pushContext()
        if self.dialogAnimator == animatorIn then
            gfx.setDrawOffset(self.rect.x * self.dialogAnimator:currentValue() + screenXOffset, self.rect.y)
        elseif self.dialogAnimator == animatorOut then
            gfx.setDrawOffset(self.rect.x + screenXOffset, self.rect.y * self.dialogAnimator:currentValue())
        end

        local trianglePoint = { x = width + arrowLength, y = height / 2}
        gfx.setLineWidth(3)
        gfx.drawLine(width + 1, 0,
                     trianglePoint.x, trianglePoint.y)
        gfx.drawLine(width + 1, height,
                     trianglePoint.x, trianglePoint.y)

        gfx.setLineWidth(6)
        gfx.drawRoundRect(0, 0, width + 2, height, 5)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(0, 0, width + 2, height, 5)

        local textWidth = dialogFont:getTextWidth(dialogText)
        gfx.drawText("⊙", 1 + textWidth, height / 4 + 2)
        gfx.drawText("➡️", 55 + textWidth, height / 4 + 2)

        gfx.setFont(dialogFont)
        gfx.drawText(dialogText, 5, height / 4)
        gfx.drawText(" or ", textWidth + 20, height / 4)

        gfx.setColor(gfx.kColorWhite)
        gfx.fillTriangle(width, 1,
                         width, height - 1,
                         trianglePoint.x - 2, trianglePoint.y)
    gfx.popContext()
end

function SchedulePromoDialog:show()
    self.isShowing = true

    self.dialogAnimator = animatorIn
    self.dialogAnimator:reset()
end

function SchedulePromoDialog:hide()
    self.dialogAnimator = animatorOut
    self.dialogAnimator:reset()

    playdate.timer.performAfterDelay(animatorDuration, function () 
        self.isShowing = false
    end)
end