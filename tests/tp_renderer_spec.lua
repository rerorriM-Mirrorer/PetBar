package.path='./?.lua;'..package.path
local instances={}
package.preload.ffxiGauge=function()
    return {new=function(width,color,opt)
        local o={width=width,color=color,options=opt,visible=false,last=0}
        function o:set_value(v,immediate) self.last=v;self.immediate=immediate end
        function o:set_color(c) self.color=c end
        function o:set_blink(period) self.blink=period end
        function o:set_fill_alpha(value) self.fill_alpha=value end
        function o:show() self.visible=true end
        function o:hide() self.visible=false end
        function o:move(x,y)
            self.x=x;self.y=y
            self.blink_when_moved=self.blink
        end
        function o:set_transition(a,w) self.fade=a;self.whiten=w end
        function o:destroy() self.dead=true end
        instances[#instances+1]=o
        return o
    end}
end
local clock=0
local tr=require('tpRenderer').new(260,function()
    return {effects={},healing_effect=true}
end,function()return clock end,{.8,.4,.3},{255,238})
assert(#instances==2,'Only a base and its overlay should be allocated')
local base,top=instances[1],instances[2]
assert(not base.options.fill_only and top.options.fill_only)
assert(not base.options.full_flash_enabled,'no white/black fullflash mask needed')
assert(top.color.alpha==238)
assert(base.fill_alpha==255 and top.fill_alpha==238)
local initial_under,initial_over=tr:get_fill_alphas()
assert(initial_under==255 and initial_over==238)
tr:set_fill_alphas(160,205)
assert(base.fill_alpha==160 and top.fill_alpha==205,
    'two TP foreground layers must update independently')
assert(top.color.alpha==238,'native overlay palette stays intact')
tr:set_fill_alphas(0,255)
assert(base.fill_alpha==0 and top.fill_alpha==255,
    'zero must be a valid base alpha; overlay may become completely opaque')
tr:set_fill_alphas(170,210)
tr:move(50,80);tr:show()
tr:set_value(650,true)
assert(base.last==.65 and not top.visible and not base.blink)
tr:set_value(1000,false)
assert(base.last==1 and not top.visible and base.blink==.8)
tr:set_value(1450,false)
assert(top.visible and top.last==.45 and base.blink==.8)
assert(top.color.alpha==238 and not top.blink)
tr:set_value(2000,false)
assert(base.blink==.4 and base.color.red==124 and not top.visible)
tr:set_value(2600,false)
assert(top.visible and top.last==.6 and top.color.green==229)
assert(top.color.alpha==238)
tr:set_value(3000,false)
assert(base.last==1 and base.color.red==38)
assert(base.blink==.3 and not top.visible)
assert(base.fill_alpha==170 and top.fill_alpha==210,
    'TP stage transitions must not reset saved alphas')
tr:set_flash_periods({.9,.55,.25})
assert(base.blink==.25 and tr:get_flash_periods()[2]==.55)
tr:move(50,80)
assert(base.blink_when_moved==.25,'blink period must set before drawing frame')
tr:set_transition(.75,0)
assert(base.fade==.75 and top.fade==.75)
tr:set_value(1450,true)
assert(base.blink==.9 and base.fill_alpha==170 and top.fill_alpha==210)
tr:set_value(2000,true)
assert(base.blink==.55 and base.fill_alpha==170 and top.fill_alpha==210)
tr:set_flash_periods({-1,50,'invalid'})
assert(base.blink==.4 and tr:get_flash_periods()[1]==.8)
tr:set_fill_alphas(-1,999)
assert(base.fill_alpha==255 and top.fill_alpha==238,
    'invalid alpha values revert to historical defaults')
tr:set_value(500,true)
assert(base.last==.5 and not top.visible and not base.blink)
tr:hide()
assert(not base.visible)
tr:destroy()
assert(base.dead and top.dead)
print('PetBar independently adjustable two-layer alpha blink: PASS')
