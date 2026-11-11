-- PetBar Test 1: independent SMN avatar HP and TP HUD.
-- The vendored ffxiGauge/healthMotion/ghostMotion/animationSettings modules
-- preserve EnemyBar2's native animation behavior and attribution.
_addon.name='PetBar'
_addon.author='A'
_addon.version='0.4.3-test4d'
_addon.language='English'
_addon.commands={'pb','petbar'}

local config=require('config')
local texts=require('texts')
local packets=require('packets')
require('chat')
local gauge=require('ffxiGauge')
local anim=require('animationSettings')
local layout_model=require('layoutModel')
local tp_renderer=require('tpRenderer')
local pet_animation=require('petAnimationPreset')
local transitions=require('petTransitions')
local transition_colors=require('transitionColors')
local life_guard_class=require('petLifeGuard')

local summon_kinds=require('summonKinds')
local is_avatar=summon_kinds.is_summon
local defaults={
    visible=true,locked=false,layout='vertical',
    pos={x=-1,y=-1},width=260,hp_width=0,tp_width=0,
    gap=6,scale=1,font_size=13,
    tp_flash_1000=.8,tp_flash_2000=.4,tp_flash_3000=.3,
    tp_alpha_under=255,tp_alpha_over=238,
    offsets={hp={x=0,y=0},tp={x=0,y=0},
        name={x=0,y=0},tptext={x=0,y=0}},
    effects=pet_animation.defaults()
}
local settings=config.load(defaults)
settings.pos=settings.pos or {x=-1,y=-1}
settings.effects=settings.effects or defaults.effects
-- Merge new fields into older saved configurations without moving anyone's HUD.
settings.offsets=settings.offsets or {}
for key,initial in pairs(defaults.offsets) do
    settings.offsets[key]=settings.offsets[key] or {}
    local entry=settings.offsets[key]
    if type(entry.x)~='number' then entry.x=initial.x end
    if type(entry.y)~='number' then entry.y=initial.y end
end
settings.hp_width=tonumber(settings.hp_width) or 0
settings.tp_width=tonumber(settings.tp_width) or 0
-- Existing per-character coordinates and effect values are authoritative.
-- Old tp_flash_target XML values remain harmless; they are not overwritten.
for _,level in ipairs({'1000','2000','3000'}) do
    local key='tp_flash_'..level
    local n=tonumber(settings[key])
    local original=defaults[key]
    settings[key]=n and n==n and n>=.1 and n<=5 and n or original
end
-- These are native 0..255 fill alphas, not percentages of the existing alpha.
-- Keep saved per-character values; reject invalid XML values without reset.
for _,side in ipairs({'under','over'}) do
    local key='tp_alpha_'..side
    local value=tonumber(settings[key])
    settings[key]=value and value==math.floor(value) and
        value>=0 and value<=255 and value or defaults[key]
end
local function tp_alphas()
    return {settings.tp_alpha_under,settings.tp_alpha_over}
end
local function tp_periods()
    return {settings.tp_flash_1000,settings.tp_flash_2000,settings.tp_flash_3000}
end
local s={pet=nil,pet_id=nil,pet_index=nil,hpp=nil,tp=nil,
    last_packet_hp=-999,last_scan=-999,preview=nil,
    in_cs=false,stopping=false,drag=nil,ctrl={},ctrl_down=false,
    ui_w=nil,ui_h=nil}
local hp,tp,caption,tp_label
local x,y,width,tp_width,total_w,total_h=0,0,260,260,260,50
local visible=false
local fade=transitions.new()
local life=life_guard_class.new()
local label_palette={red=245,green=238,blue=242,alpha=255}
local tp_palette={red=177,green=211,blue=255,alpha=255}
local stroke_palette={red=12,green=12,blue=12,alpha=180}

local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function rnd(v) return math.floor(v+.5) end
local function dimensions()
    local u=windower.get_windower_settings() or {}
    return tonumber(u.ui_x_res or u.x_res) or 1280,
        tonumber(u.ui_y_res or u.y_res) or 720
end
local function msg(value,bad)
    windower.add_to_chat(0,('PetBar'):color(167)..(' -> '):color(200)..
        tostring(value):color(bad and 123 or 207))
end
local function save() config.save(settings) end
local function eligible(p)
    return p and (p.main_job=='SMN' or p.sub_job=='SMN')
end
local function pet_entity(p)
    if not eligible(p) then return nil end
    local index=p.mob and tonumber(p.mob.pet_index)
    local pet=windower.ffxi.get_mob_by_target('pet')
    -- An explicit zero owner pet index means there is no active pet even if
    -- the client retains an old 'pet' target for a short time.
    if index and index<=0 then return nil end
    if index and index>0 then
        local owned=windower.ffxi.get_mob_by_index(index)
        if owned and is_avatar(owned.name) then return owned end
        if pet and pet.index~=index then pet=nil end
    end
    return pet and is_avatar(pet.name) and pet or nil
end
local function reset(clear,retain_exit)
    s.pet,s.pet_id,s.pet_index,s.hpp,s.tp=nil,nil,nil,nil,nil
    s.last_packet_hp=-999
    s.pending_spawn_id=nil
    life:clear()
    if not retain_exit then
        fade:clear()
        s.departure=nil
        s.fading_id=nil
    end
    if clear then gauge.clear_ghosts() end
end
-- Keep the last numbers and pet identity while the actual pet is already gone.
-- Every departure keeps its ordinary colors and fades the same way.
local function depart(reason,now)
    if not s.pet_index then return end
    local identity=s.pet_id
    s.departure={pet=s.pet,hpp=s.hpp,tp=s.tp}
    s.last_departure=reason
    fade:depart(reason,now)
    s.fading_id=identity
    reset(false,true)
end
local function options(istp)
    local e=anim.snapshot(settings.effects)
    for k,v in pairs(settings.effects) do if e[k]==nil then e[k]=v end end
    e.healing_effect,e.text_effect=true,true
    if istp then
        e.hit_shake,e.ghost_hit,e.low_hp_pulse,e.damage_trail=false,false,false,false
        e.trail_color={red=41,green=91,blue=167,alpha=160}
    else
        e.trail_color=settings.effects.trail_color or
            {red=167,green=57,blue=96,alpha=175}
    end
    return {
        animation_duration=settings.effects.animation_duration or .18,
        damage_trail=e.damage_trail,trail_delay=settings.effects.trail_delay or 1.5,
        trail_duration=settings.effects.trail_duration or .45,
        trail_color=e.trail_color,ghost_hit=e.ghost_hit,
        effects=e,ghost_options=e,main_bar=true,
        recovery_color=istp and {red=74,green=168,blue=255} or nil,
        recovery_edge_color=istp and {red=164,green=222,blue=255} or nil,
        recovery_trail_color=istp and {red=95,green=173,blue=247} or nil
    }
end
local function make_text(r,g,b,bold)
    return texts.new('',{
        pos={x=0,y=0},bg={visible=false},padding=0,
        flags={draggable=false,bold=bold,italic=true},
        text={font='Arial',size=settings.font_size,
            red=r,green=g,blue=b,alpha=255,
            stroke={width=2,alpha=180,red=12,green=12,blue=12}}
    })
end
local function hide()
    visible=false
    if hp then hp:hide() end
    if tp then tp:hide() end
    if caption then caption:hide() end
    if tp_label then tp_label:hide() end
end
local function dispose()
    hide()
    gauge.clear_ghosts()
    if hp then hp:destroy();hp=nil end
    if tp then tp:destroy();tp=nil end
    if caption then caption:destroy();caption=nil end
    if tp_label then tp_label:destroy();tp_label=nil end
end
-- Model returns resolved per-client geometry; render primitives stay unscaled
-- vertically to preserve the native 12px EnemyBar2 art.
local function position()
    if not hp then return end
    local uw,uh=dimensions()
    local g=layout_model.calculate(settings,uw,uh)
    x,y,width,tp_width,total_w,total_h=g.x,g.y,g.hp_width,g.tp_width,g.width,g.height
    s.ui_w,s.ui_h=uw,uh
    s.boxes={g.hp,g.tp}
    hp:move(g.hp.x,g.hp.y)
    tp:move(g.tp.x,g.tp.y)
    caption:pos(g.name.x,g.name.y)
    tp_label:pos(g.tptext.x,g.tptext.y)
    caption:size(g.font)
    tp_label:size(g.font)
end
local function rebuild()
    local was_visible=visible
    dispose()
    local uw,uh=dimensions()
    local g=layout_model.calculate(settings,uw,uh)
    width,tp_width=g.hp_width,g.tp_width
    -- Windower image objects stack by creation order. Create TP first so
    -- HP and its native end caps always draw above the overlapping TP gauge.
    tp=tp_renderer.new(tp_width,options,nil,tp_periods(),tp_alphas())
    hp=gauge.new(width,{red=243,green=157,blue=184,alpha=255},options(false))
    caption=make_text(label_palette.red,label_palette.green,label_palette.blue,true)
    tp_label=make_text(tp_palette.red,tp_palette.green,tp_palette.blue,false)
    position()
    hp:set_value((s.hpp or 100)/100,true)
    tp:set_value(s.tp,true)
    if was_visible then
        hp:show();tp:show();caption:show();tp_label:show()
        visible=true
    end
end
local function show(yes)
    if visible==yes then return end
    visible=yes
    if not hp then return end
    if yes then
        hp:show();tp:show();caption:show();tp_label:show()
    else hide() end
end
-- Treat a new summon as live only after a positive HP observation. Both
-- the entity table and pet packets can briefly advertise 0% during spawning.
local function adopt_pet(pet,initial_hp,now)
    reset(true,true)
    s.pet,s.pet_index,s.pet_id=pet.name,pet.index,pet.id
    s.departure=nil
    s.fading_id=nil
    s.pending_spawn_id=nil
    s.hpp=clamp(initial_hp,1,100)
    life:track(pet.id)
    life:health(s.hpp,now)
    hp:set_value(s.hpp/100,true)
    tp:set_value(nil,true)
    fade:appear(pet.id,now)
    if settings.debug then msg('Summon acquired: '..pet.name..' ('..s.hpp..'% HP)') end
end

local function scan(now)
    local info=windower.ffxi.get_info()
    local player=info and info.logged_in and windower.ffxi.get_player()
    local observed=player and pet_entity(player)
    local observed_hp=observed and tonumber(observed.hpp)
    -- A dead entity may linger in the mob list, but a positive HP reading
    -- proves that a living/reused entity must not stay permanently blacklisted.
    if not observed then
        s.fading_id=nil
    elseif s.fading_id==observed.id then
        if observed_hp and observed_hp>0 then
            s.fading_id=nil
        else
            observed=nil
        end
    end
    if observed and observed.index and observed.id then
        local is_current=observed.id==s.pet_id and observed.index==s.pet_index
        if not is_current then
            if not observed_hp or observed_hp<=0 then
                -- Uninitialized 0% HP is NOT a fresh death or a hit on the HP bar.
                if settings.debug and s.pending_spawn_id~=observed.id then
                    msg('Awaiting positive HP for '..observed.name..' before showing PetBar')
                    s.pending_spawn_id=observed.id
                end
                if s.pet_index and life:missing(now) then
                    depart('missing',now)
                end
                return
            end
            adopt_pet(observed,observed_hp,now)
        else
            life:present()
            -- Do not let slightly stale entity HP overwrite a recent packet.
            if now-s.last_packet_hp>.30 and type(observed_hp)=='number' then
                local verdict=life:health(observed_hp,now)
                if verdict=='alive' and observed_hp~=s.hpp then
                    s.hpp=clamp(observed_hp,1,100)
                    hp:set_value(s.hpp/100,false)
                elseif verdict=='dead' then
                    -- Only a sustained zero on an established living summon
                    -- can cause a real 0-HP ghost/death fade.
                    s.hpp=0
                    hp:set_value(0,false)
                    if settings.debug then msg('Summon HP stayed at zero; fading departure') end
                    depart('death',now)
                    return
                end
            end
        end
        if fade:sample(now).identity~=observed.id and not s.preview then
            -- Restore real HP/TP after a demonstration; never leave preview TP.
            hp:set_value((s.hpp or 100)/100,true)
            tp:set_value(s.tp,true)
            s.departure=nil
            fade:appear(observed.id,now)
        end
    elseif s.pet_index and life:missing(now) then
        -- Brief missing pet-target/index readings during summoning must not
        -- cancel a still-present summon. Exit only after a stable absence.
        if settings.debug then msg('Summon absent long enough; fading normal departure') end
        depart('missing',now)
    end
end
local function on_pet_packet(id,data)
    if id~=0x067 and id~=0x068 then return end
    local ok,p=pcall(packets.parse,'incoming',data)
    if not ok or type(p)~='table' then return end
    local player=windower.ffxi.get_player()
    if not eligible(player) then return end
    local owner,index=tonumber(p['Owner Index']),tonumber(p['Pet Index'])
    if id==0x067 and tonumber(p['Message Type'])==4 then
        owner,index=index,owner
    end
    if owner~=tonumber(player.index) or not index or index<=0 then return end
    local pet=pet_entity(player)
    if not pet or index~=pet.index then return end
    if s.pet_index and (s.pet_index~=index or s.pet_id~=pet.id) then return end
    local now=os.clock()
    local packet_hp=tonumber(p['Current HP%'])
    local entity_hp=tonumber(pet.hpp)
    local initial_hp=(packet_hp and packet_hp>0 and packet_hp<=100 and packet_hp)
        or (entity_hp and entity_hp>0 and entity_hp<=100 and entity_hp)
    if not s.pet_index then
        if not initial_hp then return end
        -- A healthy entity/packet is allowed to recover from provisional
        -- fade quarantine; a packet reporting 0 alone is not enough.
        adopt_pet(pet,initial_hp,now)
    end
    life:present()
    if packet_hp and packet_hp>=0 and packet_hp<=100 then
        local verdict=life:health(packet_hp,now)
        if verdict=='alive' then
            s.last_packet_hp=now
            if packet_hp~=s.hpp then
                s.hpp=packet_hp
                hp:set_value(packet_hp/100,false)
            end
        end
        -- Ignore provisional 0% packet values. They must not trigger an
        -- immediate ghost hit; a sustained zero will be verified in scan().
    end
    local value=tonumber(p['Pet TP'])
    if value and value>=0 and value<=3000 and value~=s.tp then
        local prev=s.tp
        s.tp=value
        tp:set_value(value,prev==nil or value<prev)
    end
end
-- Restore both foreground and stroke from their immutable palettes.
local function color_labels(sample)
    local name_color,stroke=transition_colors.label(
        label_palette,stroke_palette,sample)
    caption:color(name_color.red,name_color.green,name_color.blue)
    caption:alpha(name_color.alpha)
    caption:stroke_color(stroke.red,stroke.green,stroke.blue)
    caption:stroke_alpha(stroke.alpha)
    local number_color,number_stroke=transition_colors.label(
        tp_palette,stroke_palette,sample)
    tp_label:color(number_color.red,number_color.green,number_color.blue)
    tp_label:alpha(number_color.alpha)
    tp_label:stroke_color(number_stroke.red,number_stroke.green,number_stroke.blue)
    tp_label:stroke_alpha(number_stroke.alpha)
end

local function frame()
    if not hp then return end
    local now=os.clock()
    gauge.update_ghosts()
    local uw,uh=dimensions()
    if uw~=s.ui_w or uh~=s.ui_h then rebuild() end
    if s.preview and now>=s.preview.expires then
        s.preview=nil
        if fade:sample(now).identity=='preview' then
            s.departure={pet='Carbuncle',
                hpp=math.floor((hp.target_value or hp.value or .82)*100+.5),
                tp=tp:text_value(now)}
            fade:depart('missing',now)
        end
        -- A real pet, if present, is picked up by the next scan.
        s.last_scan=-999
    end
    if now-s.last_scan>=.10 and not s.preview and not s.in_cs then
        s.last_scan=now
        scan(now)
    end
    local sample=fade:sample(now)
    if sample.phase=='hidden' then s.departure=nil end
    local should_show=settings.visible and not s.in_cs and
        sample.phase~='hidden'
    show(should_show)
    if not should_show then return end
    -- Native gauge color layers independently rebuild every frame before
    -- the full-unit fade is applied, preserving HP loss and TP pulses.
    hp:move(hp.x,hp.y)
    tp:move(tp.x,tp.y)
    local remembered=s.departure
    local hp_readout=remembered and remembered.hpp or s.hpp
    local hv=remembered and hp_readout or
        (hp.motion and hp.motion:sample().text_value*100 or s.hpp)
    local tv=remembered and remembered.tp or tp:text_value(now)
    if s.preview then
        caption:text('Carbuncle: '..rnd(clamp(hv or 100,0,100))..'%')
    else
        caption:text((remembered and remembered.pet or s.pet or 'Avatar')..
            ': '..rnd(clamp(hv or 0,0,100))..'%')
    end
    tp_label:text(tv~=nil and tostring(rnd(clamp(tv,0,3000))) or '--')
    hp:set_transition(sample.alpha,sample.whiten)
    tp:set_transition(sample.alpha,sample.whiten)
    color_labels(sample)
end
local function preview(kind,raw_tp)
    kind=kind or 'show'
    local now=os.clock()
    if kind=='off' then
        if s.preview and fade:sample(now).identity=='preview' then
            s.departure={pet='Carbuncle',hpp=82,tp=1450}
            fade:depart('missing',now)
        end
        s.preview=nil
        msg('Preview off');return
    end
    if kind~='show' and kind~='hit' and kind~='heal' and
        kind~='tp' and kind~='fade' and kind~='release' and kind~='death' then
        msg('Use //pb preview [show|hit|heal|tp|fade|off].',true)
        return
    end
    if s.in_cs then msg('Preview unavailable during cutscenes.',true);return end
    local chosen=raw_tp and tonumber(raw_tp)
    if kind=='tp' and raw_tp and (not chosen or chosen<0 or chosen>3000
        or chosen~=math.floor(chosen)) then
        msg('Use //pb preview tp [0..3000].',true);return
    end
    s.departure=nil
    s.preview={expires=now+8}
    if kind=='fade' or kind=='release' or kind=='death' then
        -- Make the preview fully visible before the simulated departure.
        -- This does NOT affect the real summon or call an actual pet ability.
        hp:set_value(.82,true)
        tp:set_value(1450,true)
        fade:appear('preview',now-fade.fade_in)
        fade:depart('missing',now)
        s.departure={pet='Carbuncle',hpp=82,tp=1450}
        s.preview.expires=now+1
        msg('Preview normal fade; no pet command sent')
        return
    end
    fade:appear('preview',now)
    show(true)
    if kind~='tp' then tp:set_value(1450,true) end
    if kind=='hit' then
        hp:set_value(.95,true);hp:set_value(.20,false)
    elseif kind=='heal' then
        hp:set_value(.25,true);hp:set_value(.82,false)
    elseif kind=='tp' then
        if chosen then tp:set_value(chosen,true)
        else
            tp:set_value(850,true);tp:set_value(1460,false)
        end
    else
        hp:set_value(.82,true)
    end
    msg('Preview '..kind..' (8s); drag while unlocked')
end
local function help()
    local function line(syntax,desc)
        windower.add_to_chat(0,('//pb '):color(200)..syntax:color(207)..
            (' -> '):color(200)..desc:color(0))
    end
    windower.add_to_chat(0,('----- PetBar | SMN -----'):color(140))
    windower.add_to_chat(0,('GENERAL'):color(167))
    line('help','BattleStations-style command list')
    line('status','Version, avatar HP/TP, layout and position')
    line('show | hide | auto','Automatic pet-conditional visibility or hide')
    line('preview [show|hit|heal|tp|off]','Eight-second live HUD effects preview')
    line('preview fade','Preview normal exit (also preview death/release)')
    line('preview tp [0..3000]','Inspect full-width 1000/2000/3000 TP passes')
    line('tpflashperiod [1000|2000|3000|all] [seconds]',
        'Get/set full visible+transparent cycle (0.1..5 seconds)')
    line('tpalpha [under|over] [0..255]','Independent blue underbar / cyan overlay opacity')
    line('tpalpha reset [under|over]','Restore original under=255, over=238')
    windower.add_to_chat(0,('APPEARANCE & POSITION'):color(167))
    line('layout <vertical|horizontal>','Equal-width HP/TP; vertical default')
    line('width <60..800>','Set both gauges; reset individual overrides')
    line('width <hp|tp> <60..800>','Independent base width per gauge')
    line('offset <hp|tp|name|tptext> <x> <y>','Signed pixel offsets from their layout anchors')
    line('offset <hp|tp|name|tptext>','Report one offset; bare reports all')
    line('offset reset [hp|tp|name|tptext|all]','Recover individual/all offsets')
    line('gap <0..40>','Space between gauges')
    line('fontsize <8..24>','Caption font size')
    line('scale <0.65..2>','Width, spacing and caption scale')
    line('pos <x> <y> | resetpos','Save/recover screen-relative position')
    line('lock | unlock','Disable/enable drag; Ctrl-drag snaps to 10px')
    windower.add_to_chat(0,('ANIMATIONS & LIFECYCLE'):color(167))
    line('shake [on|off] | ghost [on|off]','Toggle HP impact effects')
    line('defaults animations','Opt in to Franklet-derived EnemyBar2 animation settings')
    line('debug [on|off]','Log major avatar changes')
    line('save | restart | unload','Save, or cleanly reload/unload once')
    line('release','Issue Summoner Release and mark its outgoing intent')
end
local function status()
    msg('Fade '..fade:sample().phase..' | last departure '..
        tostring(s.last_departure or 'none'))
    msg('v'.._addon.version..' | '..settings.layout..
        ' | '..(settings.visible and 'auto' or 'hidden')..
        ' | '..(settings.locked and 'locked' or 'draggable'))
    msg('Avatar '..(s.pet or 'none')..' | HP '..tostring(s.hpp~=nil and s.hpp or '--')..
        '% | TP '..tostring(s.tp or '--')..
        ' | cutscene '..tostring(s.in_cs))
    if settings.debug then
        msg('Pet guard | confirmed alive '..tostring(life.alive)..
            ' | zero pending '..tostring(life.zero_since~=nil)..
            ' | missing pending '..tostring(life.missing_since~=nil)..
            ' | awaiting first HP '..tostring(s.pending_spawn_id~=nil)..
            ' | fading pet '..tostring(s.fading_id or 'none'))
    end
    msg('TP fills: under '..settings.tp_alpha_under..
        '/255 | over '..settings.tp_alpha_over..'/255')
    msg('TP alpha flash cycles: 1000='..settings.tp_flash_1000..
        's, 2000='..settings.tp_flash_2000..
        's, 3000='..settings.tp_flash_3000..
        's (full on/off period)')
    msg('HP animation '..tostring(settings.effects.animation_duration)..
        's, trail '..tostring(settings.effects.trail_delay)..'s + '..
        tostring(settings.effects.trail_duration)..'s, shake '..
        tostring(settings.effects.shake_style))
    msg('Position '..x..','..y..' | HP width '..width..
        ' | TP width '..tp_width..
        ' | offsets hp('..settings.offsets.hp.x..','..settings.offsets.hp.y..
        ') tp('..settings.offsets.tp.x..','..settings.offsets.tp.y..
        ') name('..settings.offsets.name.x..','..settings.offsets.name.y..
        ') tptext('..settings.offsets.tptext.x..','..settings.offsets.tptext.y..
        ')'..
        ' | scale '..settings.scale)
end
local function boolean_command(field,arg,target)
    local v=target[field]
    if arg=='on' then v=true
    elseif arg=='off' then v=false
    elseif arg==nil then v=not v
    else msg('Expected on or off.',true);return end
    target[field]=v
    save();rebuild()
    msg(field..' '..(v and 'on' or 'off'))
end
local function command(cmd,...)
    cmd=cmd and cmd:lower() or 'help'
    local a={...}
    if cmd=='help' then help();return end
    if s.stopping or not hp then return end
    if cmd=='status' then status();return end
    if cmd=='restart' or cmd=='unload' then
        s.stopping=true
        dispose()
        msg('Cleaned up; '..cmd..' requested')
        windower.send_command('lua '..(cmd=='restart' and 'reload' or 'unload')..' PetBar')
        return
    end
    if cmd=='save' then save();msg('Settings saved');return end
    if cmd=='release' then
        if not s.pet_id then
            msg('No summoned pet to release.',true);return
        end
        -- Convenience command; normal /pet Release has identical fade behavior.
        windower.send_command('input /pet "Release" <me>')
        msg('Release requested; waiting for pet departure')
        return
    end
    if cmd=='tpalpha' then
        local side=a[1] and a[1]:lower()
        local function report(which)
            if which then
                msg('TP '..which..' fill alpha '..settings['tp_alpha_'..which]..'/255')
            else
                msg('TP fills: under '..settings.tp_alpha_under..
                    '/255 | over '..settings.tp_alpha_over..'/255')
            end
        end
        if not side then report();return end
        if side=='reset' then
            local which=a[2] and a[2]:lower()
            if which and which~='under' and which~='over' then
                msg('Use //pb tpalpha reset [under|over].',true);return
            end
            if not which or which=='under' then
                settings.tp_alpha_under=defaults.tp_alpha_under
            end
            if not which or which=='over' then
                settings.tp_alpha_over=defaults.tp_alpha_over
            end
            save();tp:set_fill_alphas(settings.tp_alpha_under,settings.tp_alpha_over)
            report()
            return
        end
        if side~='under' and side~='over' then
            msg('Use //pb tpalpha [under|over] [0..255].',true);return
        end
        if a[2]==nil then report(side);return end
        local alpha=tonumber(a[2])
        if not alpha or alpha~=math.floor(alpha) or alpha<0 or alpha>255 then
            msg('Fill alpha must be a whole number from 0 to 255.',true);return
        end
        settings['tp_alpha_'..side]=alpha
        save();tp:set_fill_alphas(settings.tp_alpha_under,settings.tp_alpha_over)
        report(side)
        return
    end
    if cmd=='tpflashperiod' or cmd=='tpperiod' then
        local band=a[1] and a[1]:lower()
        local all=(not band or band=='all')
        if not all and band~='1000' and band~='2000' and band~='3000' then
            msg('Use //pb tpflashperiod [1000|2000|3000|all] [0.1..5].',true)
            return
        end
        if not a[2] then
            if all then
                msg('TP flash period (full cycle): 1000='..settings.tp_flash_1000..
                    's, 2000='..settings.tp_flash_2000..
                    's, 3000='..settings.tp_flash_3000..'s')
            else
                msg(band..' TP full flash cycle '..settings['tp_flash_'..band]..'s')
            end
            return
        end
        local seconds=tonumber(a[2])
        if not seconds or seconds~=seconds or seconds<.1 or seconds>5 then
            msg('Flash cycle must be 0.1..5 seconds.',true)
            return
        end
        if all then
            for _,key in ipairs({'1000','2000','3000'}) do
                settings['tp_flash_'..key]=seconds
            end
        else
            settings['tp_flash_'..band]=seconds
        end
        save()
        tp:set_flash_periods(tp_periods())
        msg('TP flash cycle '..(all and 'all' or band)..': '..seconds..'s')
        return
    end
    if cmd=='tpflash' then
        msg('TP color flashing retired; use //pb tpflashperiod.',true)
        return
    end
    if cmd=='defaults' then
        if a[1]~='animations' then
            msg('Use //pb defaults animations.',true);return
        end
        -- Explicit opt-in. A reload only merges new keys, never resets a save.
        settings.effects=pet_animation.defaults()
        save();rebuild()
        msg('Franklet-derived animation defaults applied; layout retained')
        return
    end
    if cmd=='hide' or cmd=='show' or cmd=='auto' then
        settings.visible=cmd~='hide';save()
        msg(settings.visible and 'Automatic pet visibility enabled' or 'HUD hidden')
        return
    end
    if cmd=='preview' then preview(a[1] and a[1]:lower(),a[2]);return end
    if cmd=='lock' or cmd=='unlock' then
        settings.locked=cmd=='lock';save()
        msg(settings.locked and 'Dragging locked' or 'Dragging unlocked')
        return
    end
    if cmd=='layout' then
        local value=a[1] and a[1]:lower()
        if value~='vertical' and value~='horizontal' then
            msg('Use //pb layout <vertical|horizontal>.',true);return
        end
        settings.layout=value;save();rebuild();msg('Layout '..value);return
    end
    if cmd=='shake' then boolean_command('hit_shake',a[1],settings.effects);return end
    if cmd=='ghost' then boolean_command('ghost_hit',a[1],settings.effects);return end
    if cmd=='debug' then boolean_command('debug',a[1],settings);return end
    if cmd=='resetpos' then
        settings.pos={x=-1,y=-1};save();position()
        msg('Default position restored');return
    end
    if cmd=='width' then
        local role=(a[1] or 'both'):lower()
        local raw=a[2]
        if role~='hp' and role~='tp' and role~='both' then
            raw=a[1];role='both'
        end
        if raw==nil then
            msg('Widths: HP '..tostring(settings.hp_width>0 and settings.hp_width or settings.width)..
                ', TP '..tostring(settings.tp_width>0 and settings.tp_width or settings.width))
            return
        end
        local v=tonumber(raw)
        if not v or v<60 or v>800 or v~=math.floor(v) then
            msg('Use //pb width [hp|tp] <60..800>.',true);return
        end
        if role=='both' then
            settings.width=v
            settings.hp_width,settings.tp_width=0,0
        else
            settings[role..'_width']=v
        end
        save();rebuild()
        msg((role=='both' and 'Both widths' or role:upper()..' width')..' '..v)
        return
    end
    if cmd=='offset' then
        local roles={'hp','tp','name','tptext'}
        local function mapped(value)
            if value=='pet' then return 'name' end
            if value=='value' or value=='tpnumber' then return 'tptext' end
            return value
        end
        local function show_offset(role)
            local p=settings.offsets[role]
            msg(role..' offset x='..p.x..' y='..p.y)
        end
        local role=mapped(a[1] and a[1]:lower())
        if not role then
            for _,key in ipairs(roles) do show_offset(key) end
            return
        end
        if role=='reset' then
            local target=mapped(a[2] and a[2]:lower()) or 'all'
            if target~='all' and not settings.offsets[target] then
                msg('Use //pb offset reset [hp|tp|name|tptext|all].',true);return
            end
            for _,key in ipairs(roles) do
                if target=='all' or target==key then
                    settings.offsets[key].x,settings.offsets[key].y=0,0
                end
            end
            save();position()
            msg('Offset reset '..target);return
        end
        if not settings.offsets[role] then
            msg('Choose hp, tp, name, or tptext.',true);return
        end
        if not a[2] and not a[3] then show_offset(role);return end
        local dx,dy=tonumber(a[2]),tonumber(a[3])
        if not dx or not dy or dx~=math.floor(dx) or dy~=math.floor(dy)
            or dx < -1000 or dx>1000 or dy < -1000 or dy>1000 then
            msg('Use //pb offset '..role..' <x -1000..1000> <y -1000..1000>.',true)
            return
        end
        settings.offsets[role].x,settings.offsets[role].y=dx,dy
        save();position();show_offset(role);return
    end
    local limits={gap={0,40},fontsize={8,24},scale={.65,2}}
    if limits[cmd] then
        local v=tonumber(a[1]);local range=limits[cmd]
        if not v or v<range[1] or v>range[2] or
            (cmd~='scale' and v~=math.floor(v)) then
            msg('Use //pb '..cmd..' <'..range[1]..'..'..range[2]..'>.',true);return
        end
        settings[cmd=='fontsize' and 'font_size' or cmd]=v
        save();rebuild();msg(cmd..' '..v);return
    end
    if cmd=='pos' then
        local px,py=tonumber(a[1]),tonumber(a[2])
        if not px or not py or px<0 or py<0 or
            px~=math.floor(px) or py~=math.floor(py) then
            msg('Use //pb pos <x> <y>.',true);return
        end
        settings.pos={x=px,y=py};save();position()
        msg('Position '..x..','..y);return
    end
    msg('Unknown command '..cmd,true);help()
end
windower.register_event('load',function()
    if not hp then rebuild() end
    local p=windower.ffxi.get_player()
    s.in_cs=p and p.status==4 or false
end)
windower.register_event('prerender',function()
    if not s.stopping then frame() end
end)
windower.register_event('incoming chunk',function(id,data)
    if hp and not s.stopping and not s.preview then on_pet_packet(id,data) end
end)
windower.register_event('status change',function(code)
    s.in_cs=code==4
    if s.in_cs then
        reset(true)
        s.preview=nil
        hide()
    end
end)
windower.register_event('zone change',function() reset(true);hide() end)
windower.register_event('job change',function() reset(true);hide() end)
windower.register_event('logout',function() reset(true);hide() end)
windower.register_event('unload',function() dispose() end)
windower.register_event('addon command',command)
windower.register_event('keyboard',function(dik,down)
    if dik==29 or dik==157 then
        s.ctrl[dik]=down
        s.ctrl_down=s.ctrl[29] or s.ctrl[157] or false
    end
end)
windower.register_event('mouse',function(kind,mx,my,delta,blocked)
    if blocked or settings.locked or not visible then return false end
    if kind==1 then
        for _,b in ipairs(s.boxes or {}) do
            if mx>=b.x and mx<=b.x+b.width and my>=b.y and my<=b.y+12 then
                s.drag={mx=mx,my=my,x=x,y=y}
                return true
            end
        end
    elseif kind==0 and s.drag then
        local px=s.drag.x+mx-s.drag.mx
        local py=s.drag.y+my-s.drag.my
        if s.ctrl_down then px=rnd(px/10)*10;py=rnd(py/10)*10 end
        settings.pos.x,settings.pos.y=px,py
        position()
        return true
    elseif kind==2 and s.drag then
        s.drag=nil
        settings.pos.x,settings.pos.y=x,y
        save()
        return true
    end
    return false
end)
