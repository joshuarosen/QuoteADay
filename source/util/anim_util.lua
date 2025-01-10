import "CoreLibs/graphics"
import "CoreLibs/animation"

import "util/math_util"

local gfx <const> = playdate.graphics

TRANSITION_ANIM_DURATION = 900

local TRANSITION_ANIM_EASING <const> = playdate.easingFunctions.outExpo

function createTransitionOutAnimator(direction)
    local endVal = 400 * sign(direction)
    return gfx.animator.new(TRANSITION_ANIM_DURATION, 0, endVal, TRANSITION_ANIM_EASING)
end

function createTransitionInAnimator(direction)
    local startVal = 400 * sign(direction)
    return gfx.animator.new(TRANSITION_ANIM_DURATION, startVal, 0, TRANSITION_ANIM_EASING)
end