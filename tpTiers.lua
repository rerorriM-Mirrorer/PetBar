-- Two drawable TP layers, three successive 1000-TP passes.
-- State 0: filling base. State 1: base flashes, 93%-opaque blue overlay grows.
-- State 2: base flashes faster, same overlay turns brighter cyan and grows.
-- State 3: a single full-width flash alternates from dark blue to white/black.
local tiers={}
local function clamp(v) return math.max(0,math.min(1,v)) end
function tiers.sample(value)
    local valid=type(value)=='number' and value==value and
        value~=math.huge and value~=-math.huge
    local tp=valid and math.max(0,math.min(3000,value)) or 0
    local stage=tp>=3000 and 3 or tp>=2000 and 2 or tp>=1000 and 1 or 0
    local overlay=stage==1 and clamp((tp-1000)/1000)
        or stage==2 and clamp((tp-2000)/1000) or 0
    return {
        known=valid, tp=tp, stage=stage,
        base_fill=stage==0 and clamp(tp/1000) or 1,
        overlay_fill=overlay,
        overlay_alpha=238, -- 93.3%; original FFXI opacity sample still pending.
        pulse_period=stage==1 and .8 or stage==2 and .4 or stage==3 and .3 or nil,
        full_flash=stage==3,
    }
end
return tiers
