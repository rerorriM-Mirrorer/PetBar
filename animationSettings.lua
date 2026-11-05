-- A: one source of defaults and command ranges for animation tuning.
local settings={}
settings.defaults={foreground_period=.25,underbar_period=.1,ghost_lift_up=6,
    ghost_lift_right=1,ghost_drift_up=9,ghost_drift_right=1,
    ghost_lift_duration=.2,ghost_hover_duration=.8,ghost_fade_duration=1,
    ghost_alpha=255,ghost_period=.1,super_settle='small',
    shake_style='impact',shake_small_px=1,shake_large_px=4,shake_super_px=8,
    shake_rebound=.5,shake_decay=.5,shake_hold=.05,shake_step=1/30,shake_horizontal=0,
    ghost_contact_duration=.05,ghost_glow=true,ghost_glow_alpha=160,
    ghost_glow_color={red=240,green=76,blue=100},ghost_glow_height=6,
    ghost_glow_duration=.4,ghost_flare_alpha=230,ghost_flare_height=18,ghost_flare_width=3,
    underbar_glow=true,underbar_glow_alpha=80,underbar_glow_height=3,
    underbar_flare_alpha=140,underbar_flare_height=8,underbar_flare_width=3,
    foreground_flash_color={red=255,green=255,blue=255},foreground_flash_alpha=255,
    ghost_fade_to='white',ghost_height_mode='snap',ghost_height_min=.35,
    ghost_height_strength=1,ghost_glow_flicker=true,
    underbar_size_mode='scaled',underbar_size_reference=25,
    underbar_glow_min_height=2,underbar_flare_min_height=4,underbar_flare_min_width=1,
    underbar_height_curve=.5,underbar_width_curve=1,
    healing_glow=true,healing_glow_alpha=160,healing_glow_height=12,
    healing_flare_alpha=230,healing_flare_height=24,healing_flare_width=6,
    death_spark_style='vivid',death_spark_h_cap=5,death_spark_v_cap=7,
    death_spark=true,death_spark_alpha=230,death_spark_duration=.2,death_spark_size=16}
settings.ranges={foreground_period={.02,10},underbar_period={.02,10},
    ghost_lift_up={-100,100},ghost_lift_right={-100,100},ghost_drift_up={-100,100},
    ghost_drift_right={-100,100},ghost_lift_duration={0,10},ghost_hover_duration={0,10},
    ghost_fade_duration={.01,10},ghost_alpha={0,255},ghost_period={0,10},
    shake_small_px={0,100},shake_large_px={0,100},shake_super_px={0,100},
    shake_rebound={0,2},shake_decay={0,1},shake_hold={0,10},shake_step={.001,10},
    shake_horizontal={-2,2},ghost_contact_duration={0,10},ghost_glow_alpha={0,255},
    ghost_glow_height={0,100},ghost_glow_duration={0,10},ghost_flare_alpha={0,255},
    ghost_flare_height={0,100},ghost_flare_width={0,100},
    underbar_glow_alpha={0,255},underbar_glow_height={0,100},
    underbar_flare_alpha={0,255},underbar_flare_height={0,100},underbar_flare_width={0,100},
    foreground_flash_alpha={0,255},ghost_height_min={0,1},ghost_height_strength={0,1},
    underbar_size_reference={1,100},underbar_glow_min_height={0,100},
    underbar_flare_min_height={0,100},underbar_flare_min_width={0,100},
    underbar_height_curve={.1,4},underbar_width_curve={.1,4},
    healing_glow_alpha={0,255},healing_glow_height={0,100},
    healing_flare_alpha={0,255},healing_flare_height={0,100},healing_flare_width={0,100},
    death_spark_h_cap={1,16},death_spark_v_cap={1,16},
    death_spark_alpha={0,255},death_spark_duration={.05,2},death_spark_size={2,64}}
settings.enums={death_spark_style={'classic','vivid'},ghost_fade_to={'white','trail'},ghost_height_mode={'off','snap','smooth'},
    underbar_size_mode={'fixed','scaled'}}
function settings.valid(name,raw)
    local v=tonumber(raw);local r=settings.ranges[name]
    return v and r and v>=r[1] and v<=r[2] and
        (not name:match('_alpha$') or v==math.floor(v))
end
local function copy(value)
    if type(value)~='table' then return value end
    local out={}
    for k,v in pairs(value) do out[k]=copy(v) end
    return out
end
function settings.snapshot(options)
    local result={}
    for name,value in pairs(settings.defaults) do
        -- Explicit false must survive, and colors must belong to this snapshot.
        local chosen=options[name]
        if chosen==nil then chosen=value end
        result[name]=copy(chosen)
    end
    return result
end
return settings
