-- PetBar TP layer math, intentionally independent of the Windower renderer.
-- Each layer covers a complete 0..1000 band, not a third of the gauge.
local tiers={}
local function clamp(v) return math.max(0,math.min(1,v)) end
function tiers.sample(value)
    local known=type(value)=='number' and value==value
    local tp=known and math.max(0,math.min(3000,value)) or 0
    return {
        known=known,tp=tp,
        fill={clamp(tp/1000),clamp((tp-1000)/1000),clamp((tp-2000)/1000)},
        pulse={tp>=1000,tp>=2000,tp>=3000},
    }
end
return tiers
