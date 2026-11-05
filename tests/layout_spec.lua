-- PetBar Test 2: static/offline model tests; run with Lua 5.1 (lua tests/layout_spec.lua).
package.path='./?.lua;'..package.path
local layout=require('layoutModel')
local settings={
    width=260,hp_width=0,tp_width=0,layout='vertical',
    pos={x=-1,y=-1},gap=6,scale=1,font_size=13,
    offsets={hp={x=0,y=0},tp={x=0,y=0},name={x=0,y=0},tptext={x=0,y=0}}
}
local v=layout.calculate(settings,1280,720)
assert(v.hp_width==260 and v.tp_width==260)
assert(v.hp.x==v.tp.x and v.tp.y-v.hp.y==18)
assert(v.name.y>v.tp.y and v.tptext.y==v.name.y)
settings.hp_width=320;settings.tp_width=180
local unequal=layout.calculate(settings,1280,720)
assert(unequal.hp_width==320 and unequal.tp_width==180)
assert(unequal.tptext.x<=unequal.x+unequal.width)
settings.offsets.hp={x=5,y=-2}
settings.offsets.tp={x=-7,y=3}
settings.offsets.name={x=12,y=4}
settings.offsets.tptext={x=-3,y=-1}
local shifted=layout.calculate(settings,1280,720)
assert(shifted.hp.x-shifted.x==5 and shifted.tp.x-shifted.x==-7)
assert(shifted.name.x-shifted.x==15)
assert(shifted.tptext.y-shifted.name.y==-5)
settings.layout='horizontal'
local h=layout.calculate(settings,1280,720)
assert(h.tp.x-h.x==h.hp_width+6-7 and h.hp.y~=h.tp.y)
settings.layout='vertical'
settings.hp_width=0;settings.tp_width=0
settings.offsets={hp={x=0,y=0},tp={x=0,y=0},name={x=0,y=0},tptext={x=0,y=0}}
local small=layout.calculate(settings,960,540)
assert(small.hp.x>=0 and small.hp.x+small.hp_width<=960)
assert(small.tp.y+12<=540)
settings.layout='horizontal'
local narrow=layout.calculate(settings,320,180)
assert(narrow.hp_width+narrow.tp_width+narrow.gap<=320)
assert(narrow.hp.x>=0 and narrow.tp.x+narrow.tp_width<=320)
print('PetBar layout model: PASS')
