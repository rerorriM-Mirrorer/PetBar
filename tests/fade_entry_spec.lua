-- Lua 5.1 mock integration: all departures share the same color-preserving fade.
-- No Windower runtime: verifies that the actual petbar.lua entrypoint wires events.
package.path='./?.lua;'..package.path
local events={}
local now=1
local real_clock=os.clock
os.clock=function() return now end
local mob=nil
local outgoing=nil
local player={
    index=25,main_job='SMN',sub_job='WHM',status=0,
    mob={pet_index=0}
}
windower={
    addon_path='./',
    register_event=function(name,cb) events[name]=cb end,
    add_to_chat=function() end,
    send_command=function(cmd) outgoing=cmd end,
    get_windower_settings=function()
        return {ui_x_res=1280,ui_y_res=720}
    end,
    ffxi={
        get_info=function() return {logged_in=true} end,
        get_player=function() return player end,
        get_mob_by_target=function(which) return which=='pet' and mob or nil end,
        get_mob_by_index=function(index)
            return mob and mob.index==index and mob or nil
        end,
    }
}
function string:color() return self end
local saved={}
package.preload.config=function()
    return {
        load=function(defaults) return defaults end,
        save=function(settings) saved[#saved+1]=settings end,
    }
end
local text_objects={}
package.preload.texts=function()
    return {new=function(_,options)
        local obj={visible=false,options=options,content='',stroke={}}
        function obj:show() self.visible=true end
        function obj:hide() self.visible=false end
        function obj:destroy() self.dead=true end
        function obj:pos(x,y) self.x=x;self.y=y end
        function obj:size(n) self.font_size=n end
        function obj:text(str) self.content=str end
        function obj:color(r,g,b) self.rgb={r,g,b} end
        function obj:alpha(a) self.a=a end
        function obj:stroke_color(r,g,b) self.stroke={r,g,b} end
        function obj:stroke_alpha(a) self.stroke_a=a end
        text_objects[#text_objects+1]=obj
        return obj
    end}
end
package.preload.packets=function()
    return {parse=function(direction,data) return data end}
end
package.preload.chat=function() return {} end
package.preload.petAnimationPreset=function()
    return {defaults=function()
        return {animation_duration=.2,ghost_hit=false}
    end}
end
package.preload.ffxiGauge=function()
    local m={clear_ghosts=function() end,update_ghosts=function() end}
    function m.new(width,color,options)
        local bar={width=width,value=1,x=0,y=0,visible=false}
        function bar:move(x,y) self.x=x;self.y=y end
        function bar:set_value(value) self.value=value end
        function bar:show() self.visible=true end
        function bar:hide() self.visible=false end
        function bar:destroy() self.dead=true end
        function bar:set_transition(alpha,white)
            self.fade_alpha=alpha;self.fade_white=white
        end
        return bar
    end
    return m
end
package.preload.tpRenderer=function()
    return {new=function(width)
        local o={x=0,y=0,value=nil,visible=false}
        function o:move(x,y) self.x=x;self.y=y end
        function o:set_value(v) self.value=v end
        function o:text_value() return self.value end
        function o:show() self.visible=true end
        function o:hide() self.visible=false end
        function o:destroy() self.dead=true end
        function o:set_transition(alpha,white)
            self.fade_alpha=alpha;self.fade_white=white
        end
        function o:set_flash_target(value) self.flash=value end
        return o
    end}
end
assert(loadfile('petbar.lua'))()
assert(events.load and events.prerender and not events['outgoing chunk'])
assert(events['addon command'])
events.load()
events.prerender()
assert(#text_objects==2 and not text_objects[1].visible)
mob={index=51,id=4001,name='Carbuncle',hpp=99}
player.mob.pet_index=51
now=1.2
events.prerender()
assert(text_objects[1].visible)
assert(text_objects[1].content:find('Carbuncle',1,true))
assert(text_objects[1].a==0,'first frame of fade must be transparent')
now=1.4
events.prerender()
assert(text_objects[1].a>0 and text_objects[1].a<255)
assert(text_objects[1].stroke_a>0 and text_objects[1].stroke_a<180)
now=1.5
events.prerender()
assert(text_objects[1].a==255)
-- Pet TP packet, verified owner + index; number only, no prefix.
events['incoming chunk'](0x068,{
    ['Owner Index']=25,['Pet Index']=51,['Pet TP']=211,['Current HP%']=99,
})
events.prerender()
assert(text_objects[2].content=='211','TP label should be numeric only')
-- The optional Release convenience command sends the ability without changing
-- visibility or color. The exit begins only when the pet disappears.
events['addon command']('release')
assert(outgoing=='input /pet "Release" <me>')
assert(text_objects[1].a==255,'release command must not hide early')
mob=nil;player.mob.pet_index=0
now=1.6
events.prerender()
assert(text_objects[1].visible)
now=1.75
events.prerender()
assert(text_objects[1].stroke[1]==12 and text_objects[1].stroke[2]==12,
    'release must keep ordinary dark text stroke')
assert(text_objects[1].rgb[1]==245 and text_objects[1].rgb[2]==238,
    'release must keep original text colors')
assert(text_objects[1].a>0 and text_objects[1].a<255)
now=2.2
events.prerender()
assert(not text_objects[1].visible,'completed departure must hide')
-- A fresh pet has its normal text and stroke without special reset effects.
mob={index=52,id=4002,name='Shiva',hpp=80}
player.mob.pet_index=52
now=2.4
events.prerender()
now=2.7
events.prerender()
assert(text_objects[1].stroke[1]==12)
assert(text_objects[1].rgb[1]==245)
assert(text_objects[1].content:find('Shiva',1,true))
-- Dead pet: no whitening, including when the old Release hint is gone.
mob.hpp=0
now=2.8
events.prerender()
now=2.9
events.prerender()
assert(text_objects[1].stroke[1]==12)
assert(text_objects[1].rgb[1]==245)
-- Preview can show both modes without changing the player's pet.
now=3.7
events['addon command']('preview','release')
events.prerender()
now=3.85
events.prerender()
assert(text_objects[1].stroke[1]==12)
events['addon command']('preview','death')
events.prerender()
now=4.0
events.prerender()
assert(text_objects[1].stroke[1]==12)
events['addon command']('preview','fade')
events.prerender()
events['addon command']('unload')
assert(outgoing=='lua unload PetBar')
os.clock=real_clock
print('PetBar shared-fade lifecycle and numeric TP with mocked Windower: PASS')
