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
g:set_transition(.5,1)
assert(g.release_mask[1].seen and g.release_mask[2].seen and g.release_mask[3].seen)
assert(g.release_mask[1].a==128,'white silhouette must preserve fade opacity')
assert(g.release_mask[3]._x+g.release_mask[3]._width==20+260)
local white_stroke=g.fill[1].r
assert(white_stroke==255,'all visible fill pieces should be whitened')
g:move(20,40)
g:set_transition(1,0)
assert(not g.release_mask[1].seen)
assert(g.release_mask[1].a==128 or g.release_mask[1].a==0,
    'inactive white mask must never render')
g:destroy()

clock=0
local flash=gauge.new(260,c,{clock=now,full_flash_enabled=true})
flash:show()
flash:set_value(1,true)
flash:set_pulse(true,{mode='fullflash',period=.2,
    target={red=0,green=0,blue=0}})
clock=.15
flash:move(0,0)
assert(flash.flash_on and flash.flash_fill[1].seen)
assert(flash.flash_fill[1].r==0)
clock=.25
flash:move(0,0)
assert(not flash.flash_on and not flash.flash_fill[1].seen)
flash:set_pulse(false)
flash:move(0,0)
assert(not flash.flash_fill[1].seen)
flash:destroy()
print('PetBar native gauge frame and full-flash smoke: PASS')
