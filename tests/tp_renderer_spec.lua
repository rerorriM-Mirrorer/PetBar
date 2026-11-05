package.path='./?.lua;'..package.path
local instances={}
package.preload.ffxiGauge=function()
    return {new=function(width,color,opt)
        local o={width=width,color=color,options=opt,visible=false,last=0}
        function o:set_value(v,immediate) self.last=v;self.immediate=immediate end
        function o:set_color(c) self.color=c end
        function o:set_pulse(v,style) self.pulse=v;self.style=style end
        function o:show() self.visible=true end
        function o:hide() self.visible=false end
        function o:move(x,y) self.x=x;self.y=y end
        function o:destroy() self.dead=true end
        instances[#instances+1]=o
        return o
    end}
end
local clock=0
local tr=require('tpRenderer').new(260,function()
    return {effects={},healing_effect=true}
end,function()return clock end,'white')
assert(#instances==2,'Only a base + one overlay should be allocated')
local base,top=instances[1],instances[2]
assert(not base.options.fill_only and top.options.fill_only)
assert(base.options.full_flash_enabled)
assert(top.color.alpha==238)
tr:move(50,80);tr:show()
tr:set_value(650,true)
assert(base.last==.65 and not top.visible and not base.pulse)
tr:set_value(1000,false)
assert(base.last==1 and not top.visible)
assert(base.pulse and base.style.period==.8)
tr:set_value(1450,false)
assert(top.visible and top.last==.45 and base.pulse)
assert(top.color.alpha==238)
tr:set_value(2000,false)
assert(base.pulse and base.style.period==.4)
assert(base.color.red==124 and not top.visible)
tr:set_value(2600,false)
assert(top.visible and top.last==.6 and top.color.blue==255)
assert(top.color.green==229 and top.color.alpha==238)
tr:set_value(3000,false)
assert(base.last==1 and base.color.red==38)
assert(base.style.mode=='fullflash' and base.style.period==.3)
assert(base.style.target.red==255 and not top.visible)
assert(tr:set_flash_target('black') and base.style.target.red==0)
assert(tr:set_flash_target('white') and base.style.target.red==255)
assert(not tr:set_flash_target('purple'))
tr:set_value(500,true)
assert(base.last==.5 and not top.visible and not base.pulse)
tr:hide()
assert(not base.visible)
tr:destroy()
assert(base.dead and top.dead)
print('PetBar actual-style TP overlay renderer: PASS')
