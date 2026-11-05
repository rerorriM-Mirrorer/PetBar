-- A: a detached chunk owns its contact, lift, glow and fade timeline.
-- Sampling absolute elapsed time keeps the effect consistent across client FPS.
local ghost={}
local function clamp(v) return math.max(0,math.min(1,v)) end
function ghost.duration(o)
    return o.ghost_contact_duration+o.ghost_lift_duration+o.ghost_hover_duration+o.ghost_fade_duration
end
function ghost.sample(o,age)
    local elapsed=math.max(0,age-o.ghost_contact_duration)
    local contact=age<o.ghost_contact_duration
    local lift=o.ghost_lift_duration==0 and 1 or clamp(elapsed/o.ghost_lift_duration)
    if contact then lift=0 end
    local fade=clamp((elapsed-o.ghost_lift_duration-o.ghost_hover_duration)/o.ghost_fade_duration)
    local flicker=(contact or o.ghost_period==0) and 1 or (1+math.cos(2*math.pi*elapsed/o.ghost_period))/2
    local release=1-(1-lift)^3
    local glow=o.ghost_glow_duration==0 and 0 or 1-clamp(elapsed/o.ghost_glow_duration)
    local wave=flicker
    if o.ghost_height_mode=='snap' then wave=flicker>=.5 and 1 or 0 end
    local height_scale=1
    if not contact and o.ghost_height_mode~='off' then
        height_scale=1-o.ghost_height_strength*(1-o.ghost_height_min)*(1-wave)
    end
    return {x=o.ghost_lift_right*release+o.ghost_drift_right*fade,
        y=-o.ghost_lift_up*release-o.ghost_drift_up*fade,
        fade=fade,alpha=(1-fade)*flicker,glow=glow,contact=contact,
        flicker=flicker,height_scale=height_scale,
        done=age>=ghost.duration(o)}
end
return ghost
