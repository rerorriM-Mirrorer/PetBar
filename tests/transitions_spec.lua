package.path = './?.lua;' .. package.path
local transitions = require('petTransitions')
local colors = require('transitionColors')
local function near(actual, wanted)
    assert(math.abs(actual - wanted) < .00001,
        ('expected %s, got %s'):format(wanted, actual))
end
local now = 0
local m = transitions.new({clock = function() return now end,
    fade_in = .2, fade_out = .4, release_fade_out = .5, release_white = .1})
assert(m:sample().phase == 'hidden')
assert(m:appear('carbuncle'))
assert(not m:appear('carbuncle')) -- repeated scans must not restart
near(m:sample().alpha, 0)
now = .1
near(m:sample().alpha, .5)
now = .2
assert(m:sample().phase == 'visible')
assert(m:depart('death'))
assert(not m:depart('release')) -- late releases cannot relabel deaths
now = .4
local dying = m:sample()
near(dying.alpha, .5)
assert(dying.whiten == 0 and dying.reason == 'death')
local text = {red = 240, green = 140, blue = 182, alpha = 255}
local stroke = {red = 12, green = 12, blue = 12, alpha = 180}
local normal_text, normal_stroke = colors.label(text, stroke, dying)
assert(normal_text.red == 240 and normal_stroke.red == 12)
assert(normal_stroke.alpha == 90)
now = .6
assert(m:sample().phase == 'hidden' and m:sample().identity == nil)

now = 1
assert(m:appear('ice spirit'))
now = 1.2
assert(m:sample().phase == 'visible')
assert(m:depart('release'))
assert(m:sample().whiten == 0)
now = 1.25
local half_white = m:sample()
near(half_white.whiten, .5)
near(half_white.alpha, .9)
local partly_tinted, partly_stroke = colors.label(text, stroke, half_white)
assert(partly_tinted.red > text.red and partly_stroke.red > stroke.red)
now = 1.3
local white = m:sample()
near(white.whiten, 1)
local whitened_text, whitened_stroke = colors.label(text, stroke, white)
assert(whitened_text.red == 255 and whitened_text.green == 255 and whitened_text.blue == 255)
assert(whitened_stroke.red == 255 and whitened_stroke.green == 255 and whitened_stroke.blue == 255)
assert(whitened_text.alpha < 255 and whitened_stroke.alpha < 180)
assert(stroke.red == 12, 'must not mutate original outline color')
now = 1.7
assert(m:sample().phase == 'hidden' and not m:sample().draw)

now = 2
m:appear('shiva')
now = 2.2
m:depart('missing')
now = 2.3
assert(m:sample().whiten == 0, 'unknown disappearance must not whiten')
assert(m:appear('shiva'), 'reappearing pet resumes from fading alpha')
assert(m:sample().whiten == 0)
assert(m:sample().alpha > 0)
now = 2.4
assert(m:appear('carbuncle'), 'replacement must fade in as a new identity')
near(m:sample().alpha, 0)
assert(m:sample().identity == 'carbuncle')
m:clear()
assert(m:sample().phase == 'hidden' and not m:sample().draw)

local instant = transitions.new({clock=function() return now end,
    fade_in = 0, fade_out = 0, release_fade_out = 0, release_white = 0})
instant:appear('fenrir')
assert(instant:sample().alpha == 1)
instant:depart('release')
assert(instant:sample().phase == 'hidden')
print('PetBar inactive transition + text-stroke color smoke: PASS')
