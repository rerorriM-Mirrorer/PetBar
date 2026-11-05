-- A: exposed interval controls size, independently of damage timing/opacity.
-- Maximum sizes are existing tuning values; minima are capped by those maxima.
local motion={}
local function dimension(maximum,minimum,factor)
    minimum=math.min(maximum,minimum)
    return minimum+(maximum-minimum)*factor
end
function motion.sample(o,width,span,out)
    local height,width_factor=1,1
    if o.underbar_size_mode=='scaled' then
        local reference=math.max(.001,span*o.underbar_size_reference/100)
        local ratio=math.max(0,math.min(1,width/reference))
        height=ratio^o.underbar_height_curve
        width_factor=ratio^o.underbar_width_curve
    end
    out=out or {}
    out.glow_height=dimension(o.underbar_glow_height,o.underbar_glow_min_height,height)
    out.flare_height=dimension(o.underbar_flare_height,o.underbar_flare_min_height,height)
    out.flare_width=math.min(width/2,dimension(o.underbar_flare_width,o.underbar_flare_min_width,width_factor))
    return out
end
return motion
