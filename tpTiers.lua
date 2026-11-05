-- Two drawable TP layers, three successive 1000-TP passes.
-- State 0: charge steadily. States 1/2: completed underlay alternates
-- between 100% and 0% alpha under the translucent second fill.
-- Stage 3: the full bar alternates between visible and transparent.
local tiers={}
tiers.default_periods={.8,.4,.3} -- Full on/off cycle in seconds.
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
        blink_stage=stage>0 and stage or nil,
        full_flash=stage==3,
    }
end
return tiers
