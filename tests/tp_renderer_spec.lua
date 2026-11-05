package.path='./?.lua;'..package.path
local instances={}
package.preload.ffxiGauge=function()
    return {new=function(width,color,opt)
        local o={width=width,color=color,options=opt,visible=false,last=0}
        function o:set_value(v,immediate) self.last=v;self.immediate=immediate end
        function o:set_pulse(v) self.pulse=v end
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
end,function()return clock end)
assert(#instances==3 and instances[1].options.fill_only==false)
assert(instances[2].options.fill_only and instances[3].options.fill_only)
tr:move(50,80);tr:show()
tr:set_value(650,true)
assert(instances[1].last==.65 and not instances[2].visible)
tr:set_value(1000,false)
assert(instances[1].last==1 and instances[1].pulse)
tr:set_value(1450,false)
assert(instances[2].visible and instances[2].last==.45 and instances[1].pulse)
tr:set_value(2000,false)
assert(instances[2].pulse and instances[2].last==1)
tr:set_value(2600,false)
assert(instances[3].visible and instances[3].last==.6)
tr:set_value(3000,false)
assert(instances[3].pulse and instances[3].last==1)
tr:set_value(500,true)
assert(instances[1].last==.5 and not instances[2].visible and not instances[3].visible)
assert(instances[1].immediate)
tr:hide()
assert(not instances[1].visible)
tr:destroy()
assert(instances[1].dead and instances[2].dead and instances[3].dead)
print('PetBar tier renderer: PASS')
