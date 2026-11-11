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
local creation_order={}
local last_tp_bar=nil
local last_hp_bar=nil
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
        creation_order[#creation_order+1]='HP'
        local bar={width=width,value=1,x=0,y=0,visible=false}
        function bar:move(x,y) self.x=x;self.y=y end
        function bar:set_value(value) self.value=value end
        function bar:show() self.visible=true end
        function bar:hide() self.visible=false end
        function bar:destroy() self.dead=true end
        function bar:set_transition(alpha,white)
            self.fade_alpha=alpha;self.fade_white=white
        end
        last_hp_bar=bar
        return bar
    end
    return m
end
package.preload.tpRenderer=function()
    return {new=function(width)
        creation_order[#creation_order+1]='TP'
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
        function o:set_flash_periods(values) self.periods=values end
        last_tp_bar=o
        return o
    end}
end
assert(loadfile('petbar.lua'))()
assert(events.load and events.prerender and not events['outgoing chunk'])
assert(events['addon command'])
events.load()
events.prerender()
assert(#text_objects==2 and not text_objects[1].visible)
assert(creation_order[1]=='TP' and creation_order[2]=='HP',
    'HP renderer must be created last to sit above TP sprites')
events['addon command']('tpflashperiod')
events['addon command']('tpflashperiod','1000','0.65')
assert(last_tp_bar.periods[1]==.65 and last_tp_bar.periods[2]==.4)
assert(saved[#saved].tp_flash_1000==.65)
events['addon command']('tpflashperiod','all','0.5')
assert(last_tp_bar.periods[1]==.5 and last_tp_bar.periods[3]==.5)
events['addon command']('tpflashperiod','3000','0.24')
assert(last_tp_bar.periods[3]==.24)
events['addon command']('tpflash','black') -- deprecated, must not modify state.
assert(last_tp_bar.periods[3]==.24)
-- Carbuncle may exist with provisional 0% HP during the summon handshake.
mob={index=51,id=4001,name='Carbuncle',hpp=0}
player.mob.pet_index=51
now=1.1
events.prerender()
assert(not text_objects[1].visible,
    'initial 0% HP must not show a fake dead pet or play ghost-hit')
events['incoming chunk'](0x068,{
    ['Owner Index']=25,['Pet Index']=51,['Pet TP']=0,['Current HP%']=0,
})
assert(not text_objects[1].visible,
    'initial zero packet must not adopt a dying summon')
-- The *same* pet ID becomes alive; PetBar should recover immediately.
mob.hpp=99
now=1.2
events.prerender()
assert(text_objects[1].visible)
assert(text_objects[1].content:find('Carbuncle',1,true))
assert(text_objects[1].a==0,'first true-live frame starts at transparent')
now=1.4
events.prerender()
assert(text_objects[1].a>0 and text_objects[1].a<255)
assert(text_objects[1].stroke_a>0 and text_objects[1].stroke_a<180)
now=1.5
events.prerender()
assert(text_objects[1].a==255)
-- Pet TP packet with valid owner/index; number only, no prefix.
events['incoming chunk'](0x068,{
    ['Owner Index']=25,['Pet Index']=51,['Pet TP']=211,['Current HP%']=99,
})
events.prerender()
assert(text_objects[2].content=='211','TP must be numeric only')
-- An isolated zero-HP packet must not animate a fatal 100->0 hit.
now=1.51
events['incoming chunk'](0x068,{
    ['Owner Index']=25,['Pet Index']=51,['Current HP%']=0,
})
assert(last_hp_bar.value>.9,'one provisional zero packet must not empty HP')
now=1.85
events.prerender()
assert(last_hp_bar.value>.9 and text_objects[1].visible,
    'positive owned entity cancels provisional zero packet')
-- One dropped pet lookup does not make the bar exit.
mob=nil
player.mob.pet_index=0
now=1.9
events.prerender()
assert(text_objects[1].visible and text_objects[1].a==255)
mob={index=51,id=4001,name='Carbuncle',hpp=99}
player.mob.pet_index=51
now=2.05
events.prerender()
assert(text_objects[1].a==255,'brief missing lookup must not restart fade')
-- The optional Release convenience command sends an ability but does not
-- hide or recolor until the pet has truly been missing long enough.
events['addon command']('release')
assert(outgoing=='input /pet "Release" <me>')
mob=nil;player.mob.pet_index=0
now=2.15
events.prerender()
assert(text_objects[1].visible and text_objects[1].a==255)
now=2.35
events.prerender()
assert(text_objects[1].visible and text_objects[1].a==255,
    'one short disappearance must not start pet fade')
now=2.6
events.prerender()
assert(text_objects[1].visible,
    'confirmed departure begins a normal-colored fade')
now=2.8
events.prerender()
assert(text_objects[1].stroke[1]==12 and text_objects[1].stroke[2]==12)
assert(text_objects[1].rgb[1]==245 and text_objects[1].rgb[2]==238)
assert(text_objects[1].a>0 and text_objects[1].a<255)
now=3.1
events.prerender()
assert(not text_objects[1].visible,'completed real departure hides')
-- Real death is confirmed only after sustained 0% HP on an established pet.
mob={index=52,id=4002,name='Shiva',hpp=80}
player.mob.pet_index=52
now=3.2
events.prerender()
now=3.5
events.prerender()
assert(text_objects[1].stroke[1]==12)
assert(text_objects[1].rgb[1]==245)
assert(text_objects[1].content:find('Shiva',1,true))
mob.hpp=0
now=3.6
events.prerender()
assert(text_objects[1].visible and last_hp_bar.value>.7)
now=3.8
events.prerender()
assert(text_objects[1].visible,'zero HP must pass the death grace first')
now=4.0
events.prerender()
assert(text_objects[1].visible,'confirmed death begins the ordinary fade')
assert(last_hp_bar.value==0,'real sustained zero should reach HP renderer')
now=4.2
events.prerender()
assert(text_objects[1].stroke[1]==12)
assert(text_objects[1].rgb[1]==245)
now=4.6
events.prerender()
assert(not text_objects[1].visible,'death fade eventually completes')
-- The old bug quarantined the ID indefinitely. If the entity reports
-- positive HP again, it must be allowed to appear.
mob.hpp=86
now=4.7
events.prerender()
assert(text_objects[1].visible,
    'healthy formerly faded pet ID must recover and render again')
now=5.0
events.prerender()
assert(text_objects[1].content:find('Shiva',1,true))
assert(text_objects[1].stroke[1]==12)
-- Both preview aliases are ordinary color-preserving fades.
now=5.2
events['addon command']('preview','release')
events.prerender()
now=5.35
events.prerender()
assert(text_objects[1].stroke[1]==12)
events['addon command']('preview','death')
events.prerender()
now=5.5
events.prerender()
assert(text_objects[1].stroke[1]==12)
events['addon command']('preview','fade')
events.prerender()
events['addon command']('unload')
assert(outgoing=='lua unload PetBar')
os.clock=real_clock
print('PetBar summon race guard, shared fades, TP and layout: PASS')
