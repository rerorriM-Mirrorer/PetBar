-- PetBar native gauge smoke with fake image primitives and deterministic time.
-- These are Lua 5.1 offline tests, not in-game Windower texture verification.
package.path='./?.lua;'..package.path
windower={addon_path='PetBar/'}
package.preload.images=function()
    return {new=function(opts)
        local c=opts.color or {}
        local o={_x=0,_y=0,_width=1,_height=1,seen=false,
            r=c.red or 255,g=c.green or 255,b=c.blue or 255,
            a=c.alpha==nil and 255 or c.alpha}
        function o:pos(x,y)
            if x==nil then return self._x,self._y end
            self._x,self._y=x,y
        end
        function o:size(w,h)
            if w==nil then return self._width,self._height end
            self._width,self._height=w,h
        end
        function o:width() return self._width end
        function o:height() return self._height end
        function o:visible(v)
            if v==nil then return self.seen end
            self.seen=v
        end
        function o:color(r,g,b)
            if r==nil then return self.r,self.g,self.b end
            self.r,self.g,self.b=r,g,b
        end
        function o:alpha(a)
            if a==nil then return self.a end
            self.a=a
        end
        function o:destroy() self.destroyed=true end
        return o
    end}
end
local gauge=require('ffxiGauge')
local clock=0
local function now() return clock end
local c={red=120,green=190,blue=245,alpha=255}
local g=gauge.new(260,c,{
    clock=now,animation_duration=.5,damage_trail=true,
    trail_delay=.2,trail_duration=.4,
    ghost_options={underbar_glow=false,healing_glow=false},
})
g:show()
assert(g.width==260)
g:set_value(.5,true)
g:set_value(.9,false)
clock=.25
g:move(20,40)
assert(g.value>.5 and g.value<.9,'fill must advance without another packet')
clock=.6
g:move(20,40)
assert(g.value==.9,'fill must finish when no new packet arrives')
g:set_value(.3,false)
assert(g.value==.3 and g.trail_value>=.9)
clock=.7
g:move(20,40)
assert(g.trail_value>.3,'damage trail must hold')
clock=1.31
g:move(20,40)
assert(g.trail_value==.3,'damage trail must also finish without more packets')
assert(g.trough[3]._x+g.trough[3]._width==20+260,
    'right cap must end at requested width')
-- A normal appearance/disappearance fade only changes alpha; preserve color.
g:set_transition(.5,0)
assert(g.fill[1].a==128 and g.fill[1].r==120)
assert(g.trough[1].a==128)
assert(g.release_mask==nil,'no release-specific white-mask sprites allocated')
g:move(20,40)
g:set_transition(1,0)
assert(g.fill[1].a==255 and g.fill[1].r==120)
g:destroy()

clock=0
local blink=gauge.new(260,c,{clock=now})
blink:show()
blink:set_value(1,true)
blink:set_blink(.4) -- 0.4s full cycle: 0.2 visible, then 0.2 hidden.
clock=.1
blink:move(0,0)
blink:set_transition(1,0)
assert(blink.blink_alpha==1 and blink.fill[1].a==255)
assert(blink.trough[1].a==255)
clock=.3
blink:move(0,0)
blink:set_transition(1,0)
assert(blink.blink_alpha==0 and blink.fill[1].a==0)
assert(blink.fill[2].a==0 and blink.fill[3].a==0,
    'all three foreground fill pieces blink together')
assert(blink.trough[1].a==255 and blink.trough[3].a==255,
    'both capsule end caps must remain visible while the fill flashes off')
assert(blink.trough[2].a==128,
    'recessed background retains its native transparency during TP blink')
clock=.5
blink:move(0,0)
blink:set_transition(.5,0)
assert(blink.fill[1].a==128,'foreground blink on multiplies regular pet fade')
assert(blink.trough[1].a==128,'capsule uses pet fade, not TP blink')
assert(blink.trough[2].a==64,'background uses pet fade, not TP blink')
clock=.7
blink:move(0,0)
blink:set_transition(.5,0)
assert(blink.fill[1].a==0,'foreground blink off during pet fade')
assert(blink.trough[1].a==128 and blink.trough[2].a==64,
    'capsule/background remain visible even when TP blinks during pet fade')
blink:set_blink(nil)
blink:move(0,0)
blink:set_transition(1,0)
assert(blink.fill[1].a==255 and blink.trough[1].a==255)
blink:destroy()
-- Two independent TP fill alphas must be absolute, not relative to 238.
-- The original cyan sprite starts at alpha 238; a value of 255 must
-- actually bring it to 255 without changing its native trough art.
clock=1
local cyan=gauge.new(260,{red=128,green=199,blue=255,alpha=238},{clock=now})
cyan:show()
cyan:set_value(1,true)
local shell_alpha=cyan.trough[1].a
local back_alpha=cyan.trough[2].a
assert(shell_alpha==238 and back_alpha==119,
    'retain the original transparent overlay sprite and shell source')
assert(cyan:set_fill_alpha(238))
cyan:set_transition(1,0)
assert(cyan.transition_original==nil,
    'native default alpha should not add extra per-frame sprite work')
assert(cyan:set_fill_alpha(150))
cyan:move(0,0)
cyan:set_transition(1,0)
assert(cyan.fill[1].a==150 and cyan.fill[2].a==150 and
    cyan.fill[3].a==150,'cyan overlay should honor absolute 150/255 opacity')
assert(cyan.trough[1].a==shell_alpha and cyan.trough[2].a==back_alpha)
assert(cyan:set_fill_alpha(255))
cyan:move(0,0)
cyan:set_transition(1,0)
assert(cyan.fill[1].a==255,'overlay alpha 255 must be fully opaque, not 238')
assert(cyan:set_fill_alpha(0))
cyan:move(0,0)
cyan:set_transition(1,0)
assert(cyan.fill[1].a==0 and cyan.trough[1].a==shell_alpha,
    'foreground 0 alpha must not hide the capsule')
assert(cyan:set_fill_alpha(180))
cyan:set_blink(.4)
clock=1.3
cyan:move(0,0)
cyan:set_transition(1,0)
assert(cyan.fill[1].a==0 and cyan.trough[1].a==shell_alpha,
    'custom alpha still flashes all the way to zero without blinking shell')
clock=1.5
cyan:move(0,0)
cyan:set_transition(.5,0)
assert(cyan.fill[1].a==90,'configured alpha must multiply whole-HUD fade')
assert(cyan.trough[1].a==119 and cyan.trough[2].a==60,
    'normal pet fade must still dim the capsule and background')
assert(not cyan:set_fill_alpha(-1) and not cyan:set_fill_alpha(256) and
    not cyan:set_fill_alpha(120.5),'reject invalid native alpha settings')
cyan:destroy()
print('PetBar fill alpha, static capsule, blink and pet fade: PASS')
