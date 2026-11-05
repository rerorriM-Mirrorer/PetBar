-- PetBar's Franklet-derived EnemyBar2 animation defaults, with the latest
-- November 2 Cioara ghost adjustment (1px lift, then 2px downward drift).
-- Only HP adopts impact effects; TP keeps blue gains and no damage shake.
local animation_settings=require('animationSettings')
local preset={}
function preset.defaults()
    local e=animation_settings.snapshot({})
    e.animation_duration=3
    e.damage_trail=true
    e.trail_delay=2
    e.trail_duration=.5
    e.trail_color={red=167,green=57,blue=96,alpha=255}
    e.healing_effect=true
    e.heal_duration=.35
    e.text_effect=true
    e.text_duration=1.2
    e.hit_shake=true
    e.shake_style='classic'
    e.super_settle='both'
    e.shake_hold=10 -- retained for fidelity; only impact mode reads this.
    e.shake_super_px=1
    e.low_hp_pulse=true
    e.foreground_period=.1
    e.underbar_period=.1
    e.foreground_flash_alpha=0
    e.ghost_hit=true
    e.ghost_alpha=100
    e.ghost_contact_duration=0
    e.ghost_lift_up=1
    e.ghost_lift_right=0
    e.ghost_lift_duration=.9
    e.ghost_hover_duration=0
    e.ghost_drift_up=-2
    e.ghost_drift_right=1
    e.ghost_fade_duration=1
    e.ghost_period=.1
    e.ghost_glow=true
    e.ghost_glow_alpha=255
    e.ghost_glow_height=33
    e.ghost_glow_duration=10
    e.ghost_glow_color={red=240,green=76,blue=100}
    e.ghost_flare_alpha=200
    e.ghost_flare_height=60
    e.ghost_flare_width=33
    e.ghost_fade_to='white'
    e.ghost_height_mode='snap'
    e.ghost_glow_flicker=true
    e.underbar_glow=true
    e.underbar_glow_alpha=50
    e.underbar_glow_height=33
    e.underbar_flare_alpha=78
    e.underbar_flare_height=45
    e.underbar_flare_width=30
    e.underbar_size_mode='scaled'
    e.healing_glow=true
    e.death_spark=true
    e.death_spark_style='vivid'
    return e
end
return preset
