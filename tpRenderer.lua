-- Two drawable TP layers: base + one 93%-opaque overlay.
-- No third bar. At 2000 the underlay changes hue/tempo and the overlay
-- restarts in cyan. At 3000 the full-width blue stage blinks to 0% alpha.
local gauge=require('ffxiGauge')
local tiers=require('tpTiers')
local renderer={}
local methods={}
methods.__index=methods
local palette={
    first={red=105,green=165,blue=242,alpha=255},
    second={red=124,green=198,blue=253,alpha=255},
    darkest={red=38,green=81,blue=150,alpha=255},
    overlay_blue={red=128,green=199,blue=255,alpha=238},
    overlay_cyan={red=158,green=229,blue=255,alpha=238},
}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function valid_periods(values)
    local out={}
    for i=1,3 do
        local value=type(values)=='table' and tonumber(values[i]) or nil
        out[i]=value and value>=.1 and value<=5 and
            value or tiers.default_periods[i]
    end
    return out
end
function renderer.new(width,options_factory,clock,periods)
    local self=setmetatable({
        bars={},x=0,y=0,width=width,visible=false,
        value=nil,info=tiers.sample(nil),
        clock=clock or os.clock,number_from=0,number_started=nil,
        periods=valid_periods(periods),
        palette_stage=nil,
    },methods)
    local base_options=options_factory(true)
    local overlay_options=options_factory(true)
    overlay_options.fill_only=true
    self.bars[1]=gauge.new(width,palette.first,base_options)
    self.bars[2]=gauge.new(width,palette.overlay_blue,overlay_options)
    for _,bar in ipairs(self.bars) do bar:set_value(0,true) end
    return self
end
function methods:sync()
    local stage=self.info.stage
    local base=self.bars[1]
    local overlay=self.bars[2]
    if self.palette_stage~=stage then
        base:set_color(stage==3 and palette.darkest or
            stage==2 and palette.second or palette.first)
        overlay:set_color(stage==2 and palette.overlay_cyan or palette.overlay_blue)
        self.palette_stage=stage
    end
    -- Only the completed underlying gauge blinks. The slightly transparent
    -- advancing overlay remains visible. At 3000 the overlay is hidden and
    -- the entire base gauge alternates between 100% and 0% opacity.
    base:set_blink(stage>0 and self.info.known and self.periods[stage] or nil)
    overlay:set_blink(nil)
    local show_base=self.visible
    local show_overlay=self.visible and self.info.known and
        stage>=1 and stage<=2 and self.info.overlay_fill>0
    if base.visible~=show_base then
        if show_base then base:show() else base:hide() end
    end
    if overlay.visible~=show_overlay then
        if show_overlay then overlay:show() else overlay:hide() end
    end
end
-- The base and its semitransparent overlay must share a single fade amount.
function methods:set_transition(opacity,whitening)
    for _,bar in ipairs(self.bars) do
        bar:set_transition(opacity,whitening)
    end
end

function methods:move(x,y)
    self.x,self.y=x,y
    -- Configure blink before each native gauge calculates its frame alpha.
    self:sync()
    for _,bar in ipairs(self.bars) do bar:move(x,y) end
end
function methods:set_value(value,immediate)
    local info=tiers.sample(value)
    local old=self.value
    local now=self.clock()
    local previous=self:text_value(now) or 0
    local stage_changed=info.stage~=self.info.stage
    self.value=info.known and info.tp or nil
    self.info=info
    local snap=immediate or not info.known or old==nil or info.tp<old
    self.number_from=snap and info.tp or previous
    self.number_started=snap and nil or now
    -- Rebase the two fills at thresholds without animating backwards.
    self.bars[1]:set_value(info.base_fill,snap or stage_changed)
    self.bars[2]:set_value(info.overlay_fill,snap or stage_changed)
    self:sync()
end
function methods:set_flash_periods(values)
    self.periods=valid_periods(values)
    self:sync()
end
function methods:get_flash_periods()
    return {self.periods[1],self.periods[2],self.periods[3]}
end
function methods:text_value(now)
    if not self.info.known then return nil end
    if not self.number_started then return self.value end
    local elapsed=(now or self.clock())-self.number_started
    local f=clamp(elapsed/.38,0,1)
    return self.number_from+(self.value-self.number_from)*f
end
function methods:show()
    self.visible=true
    self:sync()
end
function methods:hide()
    self.visible=false
    self:sync()
end
function methods:destroy()
    self:hide()
    for _,bar in ipairs(self.bars) do bar:destroy() end
    self.bars={}
end
return renderer
