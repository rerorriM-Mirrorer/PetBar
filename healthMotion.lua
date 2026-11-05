-- A: time-based feedback independent of rendering and combat tracking.
-- Every interruption starts at the currently displayed number, not an old goal.
local motion = {}
local animation_settings=require('animationSettings')
local methods = {}
methods.__index = methods
local function clamp(v) return math.max(0,math.min(1,v)) end
function motion.mix(a,b,amount)
    return {red=math.floor(a.red+(b.red-a.red)*amount+.5),
        green=math.floor(a.green+(b.green-a.green)*amount+.5),
        blue=math.floor(a.blue+(b.blue-a.blue)*amount+.5)}
end
function motion.new(options,clock)
    return setmetatable({options=options,tuning=animation_settings.snapshot(options),clock=clock or os.clock,value=1,text_from=1,
        text_duration=options.text_duration or .22,heal_duration=options.heal_duration or .35,
        pulse_period=options.pulse_period or .2,
        foreground_period=options.foreground_period or options.pulse_period or .25,
        underbar_period=options.underbar_period or options.pulse_period or .1,
        direction=options.direction or function() return math.random(0,1)==0 and -1 or 1 end},methods)
end
function methods:update(value,immediate)
    local now=self.clock()
    if immediate then
        self.value,self.text_from=value,value
        self.changed_at,self.heal_at,self.shake_at=nil,nil,nil
        return
    end
    if value==self.value then return end
    local current=self:sample().text_value
    local loss=self.value-value
    self.kind=loss>0 and 'damage' or 'heal'
    self.flash_allowed=self.kind=='heal' or loss>=.25-1e-9
    self.value,self.text_from,self.changed_at=value,current,now
    self.active_text_duration=value==0 and math.min(self.text_duration,.15) or self.text_duration
    self.heal_at=self.kind=='heal' and self.options.healing_effect and now or nil
    self.shake_at=nil
    if self.kind=='damage' and self.options.hit_shake then
        self.shake_at,self.shake_direction=now,self.direction()
        self.shake_large=loss>.5+1e-9
        self.shake_super=self.options.ghost_hit and loss>=.75-1e-9
    end
end
function methods:sample()
    local now=self.clock()
    local out={text_value=self.value,flash=0,white=0,alpha=1,pulse=0,offset=0,offset_x=0,healing=false,low=false}
    if self.changed_at and self.options.text_effect then
        local duration=self.active_text_duration or self.text_duration
        local p=duration<=0 and 1 or clamp((now-self.changed_at)/duration)
        out.text_value=self.text_from+(self.value-self.text_from)*p
        out.flash=self.flash_allowed and 1-clamp((now-self.changed_at)/.25) or 0
        out.flash_kind=self.kind
    end
    if self.heal_at then
        local p=self.heal_duration<=0 and 1 or clamp((now-self.heal_at)/self.heal_duration)
        out.healing=p<1
        out.white=1-p
    end
    if self.options.low_hp_pulse and not out.healing then
        out.red_opacity=1-self.value
        out.low=self.value>0 and self.value<1
        if self.value>0 and self.value<=.5 then
            out.pulse=(1-math.cos(2*math.pi*now/self.underbar_period))/2
            out.critical=self.value<=.10
            if out.critical then
                -- The alternate critical phase uses configured RGB/alpha in the
                -- renderer. Its clock remains independent of the red underbar.
                out.white=(now % self.foreground_period)<self.foreground_period/2 and 0 or 1
            end
        end
    end
    if self.shake_at then
        local age=now-self.shake_at
        local o=self.tuning
        if o.shake_style=='impact' then
            -- One impulse followed by decreasing rebounds, with no neutral pause
            -- or restarted settling sequence. All positions remain integer jumps.
            local strength=self.shake_super and o.shake_super_px or
                (self.shake_large and o.shake_large_px or o.shake_small_px)
            local count=4
            if self.shake_super then
                count=({off=2,small=3,both=4})[o.super_settle] or 3
            end
            local step=age<o.shake_hold-1e-9 and 0 or
                1+math.floor(math.max(0,age-o.shake_hold+1e-9)/o.shake_step)
            if step<count then
                local magnitude=step==0 and strength or
                    strength*o.shake_rebound*o.shake_decay^(step-1)
                out.offset=math.floor(magnitude+.5)*(step%2==0 and 1 or -1)*self.shake_direction
            end
            local x=out.offset*o.shake_horizontal
            out.offset_x=math.floor(math.abs(x)+.5)*(x<0 and -1 or 1)
            return out
        end
        -- Fixed held offsets produce a jolt: no intermediate positions.
        local function small(t)
            if t<.06-1e-9 then return 1 elseif t<.12-1e-9 then return -1 end
            return 0
        end
        local function medium(t)
            if t<.06-1e-9 then return 3 elseif t<.12-1e-9 then return -4 end
            return 0
        end
        if self.shake_super then
            if age<.05-1e-9 then out.offset=6
            elseif age<.10-1e-9 then out.offset=-8
            elseif age>=.13-1e-9 then
                local tail=age-.13
                local settle=self.options.super_settle or 'small'
                if settle=='both' then
                    if tail<.18-1e-9 then out.offset=medium(tail)
                    else out.offset=small(tail-.18) end
                elseif settle=='small' then out.offset=small(tail) end
            end
        elseif self.shake_large then out.offset=medium(age)
        else out.offset=small(age) end
        out.offset=out.offset*self.shake_direction
    end
    return out
end
return motion
