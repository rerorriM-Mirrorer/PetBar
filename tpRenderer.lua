-- TP display controller: three complete 1000-TP passes across one native gauge.
-- Lower completed fills keep pulsing where the brighter overlay has not covered them.
local gauge=require('ffxiGauge')
local tiers=require('tpTiers')
local renderer={}
local methods={}
methods.__index=methods
local colors={
    {red=105,green=165,blue=242,alpha=255},
    {red=123,green=188,blue=251,alpha=255},
    {red=160,green=213,blue=255,alpha=255}
}
local pulse_strength={.18,.25,.33}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
function renderer.new(width,options_factory,clock)
    local self=setmetatable({
        bars={},x=0,y=0,width=width,visible=false,
        value=nil,info=tiers.sample(nil),
        clock=clock or os.clock,number_from=0,number_started=nil,
    },methods)
    for i=1,3 do
        local options=options_factory(true)
        options.fill_only=i>1
        options.pulse_strength=pulse_strength[i]
        options.pulse_period=.65
        self.bars[i]=gauge.new(width,colors[i],options)
        self.bars[i]:set_value(0,true)
    end
    return self
end
function methods:sync()
    for i,b in ipairs(self.bars) do
        local expected=self.visible and (i==1 or self.info.fill[i]>0)
        b:set_pulse(self.info.known and self.info.pulse[i])
        if b.visible~=expected then
            if expected then b:show() else b:hide() end
        end
    end
end
function methods:move(x,y)
    self.x,self.y=x,y
    for _,b in ipairs(self.bars) do b:move(x,y) end
    self:sync()
end
function methods:set_value(value,immediate)
    local info=tiers.sample(value)
    local old=self.value
    local now=self.clock()
    local previous=self:text_value(now)
    self.value=info.known and info.tp or nil
    self.info=info
    local snap=immediate or not info.known or old==nil or info.tp<old
    self.number_from=snap and info.tp or previous
    self.number_started=snap and nil or now
    for i,b in ipairs(self.bars) do b:set_value(info.fill[i],snap) end
    self:sync()
end
function methods:text_value(now)
    if not self.info.known then return nil end
    if not self.number_started then return self.value end
    local elapsed=(now or self.clock())-self.number_started
    local f=clamp(elapsed/.38,0,1)
    return self.number_from+(self.value-self.number_from)*f
end
function methods:show()
    self.visible=true;self:sync()
end
function methods:hide()
    self.visible=false;self:sync()
end
function methods:destroy()
    self:hide()
    for _,b in ipairs(self.bars) do b:destroy() end
    self.bars={}
end
return renderer
