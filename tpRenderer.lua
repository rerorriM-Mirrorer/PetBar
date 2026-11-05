-- Two drawable TP layers: base + one 93%-opaque overlay.
-- No separate third bar. At 2000 the underlay changes hue/tempo and the
-- same overlay starts again in cyan. At 3000 only one full-width fill flashes.
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
function renderer.new(width,options_factory,clock,flash_target)
    local self=setmetatable({
        bars={},x=0,y=0,width=width,visible=false,
        value=nil,info=tiers.sample(nil),
        clock=clock or os.clock,number_from=0,number_started=nil,
        flash_target=flash_target=='black' and 'black' or 'white',
        palette_stage=nil,
    },methods)
    local base_options=options_factory(true)
    base_options.full_flash_enabled=true
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
    if stage==3 and self.info.known then
        local target=self.flash_target=='black' and
            {red=0,green=0,blue=0} or {red=255,green=255,blue=255}
        base:set_pulse(true,{
            mode='fullflash',period=self.info.pulse_period,target=target,
        })
    elseif stage==2 and self.info.known then
        base:set_pulse(true,{
            mode='pulse',period=self.info.pulse_period,
            from=palette.second,to={red=215,green=243,blue=255},
        })
    elseif stage==1 and self.info.known then
        base:set_pulse(true,{
            mode='pulse',period=self.info.pulse_period,
            from=palette.first,to={red=203,green=232,blue=255},
        })
    else
        base:set_pulse(false)
    end
    overlay:set_pulse(false)
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
    for _,bar in ipairs(self.bars) do bar:move(x,y) end
    self:sync()
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
function methods:set_flash_target(target)
    if target~='white' and target~='black' then return false end
    self.flash_target=target
    self:sync()
    return true
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
