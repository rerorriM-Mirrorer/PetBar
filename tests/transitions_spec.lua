package.path='./?.lua;'..package.path
local transitions=require('petTransitions')
local colors=require('transitionColors')
local function near(a,b)
    assert(math.abs(a-b)<.00001,('expected %s got %s'):format(b,a))
end
local now=0
local timeline=transitions.new({
    clock=function() return now end,fade_in=.2,fade_out=.4,
})
assert(timeline:sample().phase=='hidden')
assert(timeline:appear('carbuncle'))
assert(not timeline:appear('carbuncle'))
now=.1
near(timeline:sample().alpha,.5)
now=.2
assert(timeline:sample().phase=='visible')
local text={red=240,green=140,blue=182,alpha=255}
local stroke={red=12,green=12,blue=12,alpha=180}
local function normal_fade(reason)
    assert(timeline:depart(reason,now))
    local starting=timeline:sample()
    assert(starting.reason==reason)
    near(starting.alpha,1)
    now=now+.2
    local mid=timeline:sample()
    near(mid.alpha,.5)
    near(mid.whiten,0)
    local fg,outline=colors.label(text,stroke,mid)
    assert(fg.red==240 and fg.green==140 and outline.red==12)
    assert(fg.alpha==128 and outline.alpha==90)
    now=now+.2
    assert(timeline:sample().phase=='hidden')
    near(timeline:sample().alpha,0)
end
normal_fade('death')
timeline:appear('carbuncle',now-.2)
assert(timeline:sample().phase=='visible')
normal_fade('release')
timeline:appear('carbuncle',now-.2)
assert(timeline:sample().phase=='visible')
normal_fade('missing')
assert(stroke.red==12 and stroke.alpha==180,'original stroke must remain unchanged')
now=2
timeline:appear('shiva')
now=2.2
timeline:depart('missing')
now=2.3
assert(timeline:appear('shiva'),'same pet can reappear while departing')
assert(timeline:sample().alpha>0)
now=2.4
assert(timeline:appear('carbuncle'),'replacement enters as new identity')
near(timeline:sample().alpha,0)
timeline:clear()
assert(timeline:sample().phase=='hidden')
local instant=transitions.new({clock=function() return now end,
    fade_in=0,fade_out=0})
instant:appear('fenrir')
assert(instant:sample().alpha==1)
instant:depart('release')
assert(instant:sample().phase=='hidden')
print('PetBar unified color-preserving departure timelines: PASS')
