-- A: native menu/gauge slices, with separate trough and fill pieces.
-- Only the centers stretch; combat identity stays in bars.lua.
local images = require('images')
local health_motion = require('healthMotion')
local animation_settings=require('animationSettings')
local ghost_motion=require('ghostMotion')
local underbar_motion=require('underbarMotion')
local death_spark=require('deathSpark')
local gauge = {}
local ghosts = {}
local methods = {}
methods.__index = methods

local function image(name, color)
    return images.new({
        pos = {x=0, y=0}, visible = false,
        size = {width=1, height=1},
        color = {alpha=color.alpha or 255, red=color.red,
                 green=color.green, blue=color.blue},
        texture = {path=windower.addon_path..'assets/ffxi/'..name..'.png', fit=true},
        repeatable = {x=1, y=1}, draggable = false,
    })
end

function gauge.new(width, color, options)
    options = options or {}
    local self = setmetatable({
        width=math.max(16, width), x=0, y=0, value=1, visible=false,
        duration=options.animation_duration or 0,
        clock=options.clock or os.clock, target_value=1,
        slide_duration=options.animation_duration or 0, color=color,
        damage_trail=options.damage_trail or false, trail_value=1,
        ghost_hit=options.ghost_hit or false,
        ghost_options=animation_settings.snapshot(options.ghost_options or options.effects or options),
        trail_delay=options.trail_delay or 1.5, trail_duration=options.trail_duration or .45,
        fill_only=options.fill_only or false, pulse_active=false,
        pulse_strength=options.pulse_strength or 0,
        pulse_period=options.pulse_period or .6,
        full_flash_enabled=options.full_flash_enabled or false,
        pulse_style=nil, flash_on=false,
    }, methods)
    if options.effects then self.motion=health_motion.new(options.effects,self.clock) end
    -- The shell is deliberately neutral, independent of the resource tint.
    local shell = {alpha=color.alpha, red=255, green=255, blue=255}
    self.trough = {
        image('trough_left', shell), image('trough_mid', {
            alpha=math.floor((color.alpha or 255)*(options.background_alpha or 128)/255+0.5),
            red=255, green=255, blue=255}),
        image('trough_right', shell),
    }
    if self.damage_trail or self.motion then
        local red = options.trail_color or {red=167,green=57,blue=96,alpha=128}
        local tint = {red=red.red,green=red.green,blue=red.blue,
            alpha=math.floor((color.alpha or 255)*(red.alpha or 128)/255+.5)}
        self.trail_color=tint
        self.trail = {image('fill_left',tint),image('fill_mid',tint),image('fill_right',tint)}
        -- Draw above the red trail, below the live foreground. The glow's foot
        -- must stay visible across the exposed lost-HP section, not be covered
        -- by an opaque red trail created after it.
        if self.ghost_options.underbar_glow then
            self.trail_glow={image('ghost_glow',tint),image('ghost_flare',tint),image('ghost_flare',tint)}
            self.trail_pose={}
        end
    end
    self.fill = {
        image('fill_left', color), image('fill_mid', color),
        image('fill_right', color),
    }
    -- A neutral silhouette is needed for full-TP white/black flashes.
    -- The regular native fill sprite has a cyan cast even when tinted white.
    if self.full_flash_enabled then
        local neutral={red=255,green=255,blue=255,alpha=255}
        self.flash_fill={image('ghost_fill_left',neutral),
            image('ghost_fill_mid',neutral),image('ghost_fill_right',neutral)}
    end
    -- Main-bar recovery ornaments sit above the fill so the white moving edge
    -- remains visible. Secondary bars retain their established healing motion.
    if options.main_bar and self.motion and options.effects.healing_effect and self.ghost_options.healing_glow then
        local base=options.recovery_color or {red=53,green=242,blue=100}
        local green={red=base.red,green=base.green,blue=base.blue,alpha=color.alpha or 255}
        self.heal_glow={image('ghost_glow',green),image('ghost_flare',green),image('ghost_flare',green)}
        self.recovery_edge_color=options.recovery_edge_color or {red=154,green=255,blue=184}
        self.recovery_trail_color=options.recovery_trail_color or {red=209,green=224,blue=151}
    end
    if self.motion and options.effects.low_hp_pulse then
        -- Neutral silhouettes give the alternate state its configured RGB/alpha
        -- without the native texture's cyan cast; normal fill keeps its tint.
        local flash=self.ghost_options.foreground_flash_color
        local white={alpha=math.floor((color.alpha or 255)*self.ghost_options.foreground_flash_alpha/255+.5),
            red=flash.red,green=flash.green,blue=flash.blue}
        self.critical_fill={image('ghost_fill_left',white),image('ghost_fill_mid',white),image('ghost_fill_right',white)}
    end
    self:move(0, 0)
    return self
end

function methods:move(x, y)
    -- PetBar updates only on observed pet changes; progress unfinished animations
    -- every rendered frame rather than requiring a second HP/TP packet.
    self:advance()
    self.x, self.y = x, y
    self.feedback=self.motion and self.motion:sample() or nil
    local shake=self.feedback and self.feedback.offset or 0
    local sx=x+(self.feedback and self.feedback.offset_x or 0)
    self.trough[1]:pos(sx, y+shake)
    self.trough[1]:size(6, 12)
    self.trough[2]:pos(sx+6, y+shake)
    self.trough[2]:size(self.width-12, 12)
    self.trough[3]:pos(sx+self.width-6, y+shake)
    self.trough[3]:size(6, 12)
    self:layout_fill()
end

function methods:advance()
    local now = self.clock()
    if self.started_at then
        local progress = math.min(1, math.max(0, (now-self.started_at)/self.slide_duration))
        self.value = self.start_value+(self.target_value-self.start_value)*progress
        if progress == 1 then self.started_at = nil end
    end
    if self.trail_at and now >= self.trail_at then
        local progress = (self.active_trail_duration or self.trail_duration) <= 0 and 1 or math.min(1,(now-self.trail_at)/(self.active_trail_duration or self.trail_duration))
        self.trail_value = self.trail_start+(self.target_value-self.trail_start)*progress
        if progress == 1 then self.trail_at = nil end
    end
end

function methods:set_value(value, immediate)
    value = math.max(0, math.min(1, value))
    self:advance()
    -- Snapshot the lost segment before identity/reset or later movement can change it.
    local loss=self.target_value-value
    local killing_hit=self.target_value>0 and value==0
    if not immediate and self.visible and self.ghost_hit and
        (loss>=.75-1e-9 or killing_hit) then
        local tint=self.trail_color or {red=167,green=57,blue=96,alpha=200}
        local g={x=self.x+6+(self.width-12)*value,y=self.y+1,
            width=(self.width-12)*(self.target_value-value),born=self.clock(),clock=self.clock,tint=tint,
            size_scale=math.sqrt(math.min(1,loss/.75)),
            alpha=(self.color.alpha or 255)*self.ghost_options.ghost_alpha/255,
            options=animation_settings.snapshot(self.ghost_options)}
        -- Glow primitives precede the white chunk so its foot stays crisp.
        if g.options.ghost_glow then
            g.glow={image('ghost_glow',g.options.ghost_glow_color),
                image('ghost_flare',g.options.ghost_glow_color),image('ghost_flare',g.options.ghost_glow_color)}
        end
        -- Neutral silhouettes preserve native alpha while allowing a true white
        -- contact flash; tinting the cyan native texture alone cannot do that.
        g.parts={image('ghost_fill_left',tint),image('ghost_fill_mid',tint),image('ghost_fill_right',tint)}
        ghosts[#ghosts+1]=g
        gauge.update_ghosts() -- draw the detached white copy immediately at detection
    end
    if not immediate and self.visible and killing_hit then
        -- Freeze the unshaken closing endpoint now. Aggro hide/reflow and target
        -- switches must not cancel or move this scheduled finishing accent.
        local delay=self.damage_trail and self.duration>0 and .15 or 0
        death_spark.spawn(self.x+6,self.y+5.5,self.ghost_options,self.color.alpha or 255,self.clock,delay)
    end
    if self.motion then self.motion:update(value,immediate or self.duration<=0) end
    if immediate or self.duration <= 0 then
        self.value, self.target_value, self.started_at = value, value, nil
        self.trail_value, self.trail_at = value, nil
    elseif self.damage_trail and value < self.target_value then
        -- A hit freezes a moving trail at its current edge and restarts the hold.
        self.trail_value = math.max(self.trail_value,self.value,value)
        self.active_trail_duration=value==0 and .15 or self.trail_duration
        self.trail_start, self.trail_at = self.trail_value, self.clock()+(value==0 and 0 or self.trail_delay)
        self.value, self.target_value, self.started_at = value, value, nil
    elseif self.target_value ~= value then
        self:advance()
        self.start_value, self.started_at, self.target_value = self.value, self.clock(), value
        self.slide_duration=self.motion and self.motion.heal_at and self.motion.heal_duration or self.duration
        if self.slide_duration<=0 then self.value,self.started_at=value,nil end
        self.trail_value, self.trail_at = value, nil
    else
        self:advance()
    end
    self:move(self.x,self.y)
end

function methods:layout_parts(parts, value, offset, offset_x)
    local filled = (self.width-12)*value
    -- A nearly empty bar must not retain two full-width caps or overfill.
    local cap = math.min(3, filled/2)
    local x=self.x+(offset_x or 0)
    parts[1]:pos(x+6, self.y+1+(offset or 0))
    parts[1]:size(cap, 9)
    parts[2]:pos(x+6+cap, self.y+1+(offset or 0))
    parts[2]:size(math.max(0, filled-2*cap), 9)
    parts[3]:pos(x+6+filled-cap, self.y+1+(offset or 0))
    parts[3]:size(cap, 9)
end

function methods:layout_fill()
    if self.trail then self:layout_parts(self.trail,self.trail_value) end
    self:layout_parts(self.fill,self.value,self.feedback and self.feedback.offset or 0,
        self.feedback and self.feedback.offset_x or 0)
    if self.critical_fill then
        self:layout_parts(self.critical_fill,self.value,self.feedback and self.feedback.offset or 0,
            self.feedback and self.feedback.offset_x or 0)
    end
    if self.flash_fill then
        self:layout_parts(self.flash_fill,self.value,0,0)
    end
    if self.feedback then
        local fill=health_motion.mix(self.color,{red=255,green=255,blue=255},self.feedback.white)
        for _,p in ipairs(self.fill) do
            p:color(fill.red,fill.green,fill.blue)
            p:alpha(math.floor((self.color.alpha or 255)*self.feedback.alpha+.5))
        end
        local trail=self.feedback.healing and (self.recovery_trail_color or {red=209,green=224,blue=151}) or
            health_motion.mix(self.trail_color,{red=224,green=86,blue=130},self.feedback.pulse)
        self.active_trail_color=trail
        self.active_trail_alpha=math.floor(self.trail_color.alpha+
            ((self.color.alpha or 255)-self.trail_color.alpha)*(self.feedback.red_opacity or 0)+.5)
        for _,p in ipairs(self.trail) do
            p:color(trail.red,trail.green,trail.blue)
            p:alpha(self.active_trail_alpha)
        end
    end
    -- TP has two independent effects: a completed underlay pulses beneath
    -- the semitransparent gain fill, and full 3000 TP alternates a single
    -- neutral silhouette against the darkest blue. HP never enters this path.
    self.flash_on=false
    if self.pulse_active and self.pulse_style then
        local style=self.pulse_style
        local period=math.max(.05,style.period or .8)
        if style.mode=='fullflash' then
            self.flash_on=(self.clock()%period)>=period/2
        elseif not (self.feedback and self.feedback.healing) then
            local phase=(1-math.cos(2*math.pi*self.clock()/period))/2
            local glow=health_motion.mix(style.from or self.color,
                style.to or {red=220,green=244,blue=255},phase)
            for _,part in ipairs(self.fill) do
                part:color(glow.red,glow.green,glow.blue)
            end
        end
    end
    if self.flash_fill then
        local target=(self.pulse_style and self.pulse_style.target) or
            {red=255,green=255,blue=255}
        for _,part in ipairs(self.flash_fill) do
            part:color(target.red,target.green,target.blue)
            part:alpha(self.flash_on and (self.color.alpha or 255) or 0)
        end
    end
    self:layout_trail_glow()
    self:layout_heal_glow()
    self:refresh_visibility()
end

function methods:layout_heal_glow()
    if not self.heal_glow then return end
    local o=self.ghost_options
    local span=self.width-12
    local width=span*math.max(0,self.target_value-self.value)
    self.heal_glow_width=width
    -- The exposed green interval closes as the white foreground catches up.
    -- A square-root curve keeps small recoveries legible without oversized tips.
    local size=math.sqrt(math.min(1,width/(span*.25)))
    local strength=self.feedback and self.feedback.healing and self.feedback.white or 0
    local alpha=(self.color.alpha or 255)*strength
    local x,y=self.x+6+span*self.value,self.y+1
    local height=o.healing_glow_height*size
    local middle=self.heal_glow[1]
    middle:pos(x,y-height);middle:size(width,9+2*height)
    middle:alpha(math.floor(alpha*o.healing_glow_alpha/255+.5))
    local flare_width=math.min(o.healing_flare_width*size,width/2)
    local flare_height=o.healing_flare_height*size
    for i=2,3 do
        local p=self.heal_glow[i]
        p:pos((i==2 and x or x+width)-flare_width/2,y-flare_height)
        p:size(flare_width,9+flare_height)
        -- Moving foreground edge is white; destination edge gathers pale green.
        if i==2 then p:color(255,255,255) else p:color(self.recovery_edge_color.red,self.recovery_edge_color.green,self.recovery_edge_color.blue) end
        p:alpha(math.floor(alpha*o.healing_flare_alpha/255+.5))
    end
end

function methods:layout_trail_glow()
    if not self.trail_glow then return end
    local o=self.ghost_options
    -- Only the exposed damage interval glows: current HP edge -> trailing edge.
    -- The right edge slides toward the left as the red trail catches up.
    local span=self.width-12
    local x,y=self.x+6+span*self.value,self.y+1
    local width=span*math.max(0,self.trail_value-self.value)
    self.trail_glow_width=width
    local size=underbar_motion.sample(o,width,span,self.trail_pose)
    local tint=self.active_trail_color or self.trail_color
    -- Brighter red separates the halo from its opaque red foot, without adding
    -- a white pulse to the underbar at critical HP.
    local glow_tint=health_motion.mix(tint,{red=255,green=110,blue=145},.4)
    local flare_tint=health_motion.mix(tint,{red=255,green=110,blue=145},.65)
    local alpha=self.active_trail_alpha or self.trail_color.alpha
    local middle=self.trail_glow[1]
    middle:pos(x,y-size.glow_height)
    middle:size(width,9+2*size.glow_height)
    middle:color(glow_tint.red,glow_tint.green,glow_tint.blue)
    middle:alpha(math.floor(alpha*o.underbar_glow_alpha/255+.5))
    -- Cap width on nearly empty trails so the two flares do not grow wider
    -- than the bar they decorate. Their centres follow the actual endpoints.
    local flare_width=size.flare_width
    for i=2,3 do
        local p=self.trail_glow[i]
        p:pos((i==2 and x or x+width)-flare_width/2,y-size.flare_height)
        p:size(flare_width,9+size.flare_height)
        p:color(flare_tint.red,flare_tint.green,flare_tint.blue)
        p:alpha(math.floor(alpha*o.underbar_flare_alpha/255+.5))
    end
end

function methods:trail_visible()
    return self.visible and self.trail_value>0 and (self.trail_value>self.value or
        (self.feedback~=nil and self.feedback.low))
end

function methods:refresh_visibility()
    for _, part in ipairs(self.trough) do
        part:visible(self.visible and not self.fill_only and part:width() > 0)
    end
    local white=self.critical_fill and self.feedback and self.feedback.critical and self.feedback.white==1
    for _, part in ipairs(self.fill) do
        part:visible(self.visible and part:width() > 0 and self.value > 0 and not white)
    end
    for _,part in ipairs(self.critical_fill or {}) do
        part:visible(self.visible and part:width()>0 and self.value>0 and white or false)
    end
    for _,part in ipairs(self.flash_fill or {}) do
        part:visible(self.visible and self.flash_on and self.value>0 and part:width()>0)
    end
    for _, part in ipairs(self.trail or {}) do
        part:visible(self:trail_visible() and part:width()>0)
    end
    for i,part in ipairs(self.trail_glow or {}) do
        local enabled=i==1 and self.ghost_options.underbar_glow_alpha>0 or
            i>1 and self.ghost_options.underbar_flare_alpha>0
        part:visible(self:trail_visible() and not (self.feedback and self.feedback.healing)
            and (self.trail_glow_width or 0)>0 and part:width()>0 and enabled)
    end
    for i,part in ipairs(self.heal_glow or {}) do
        local enabled=i==1 and self.ghost_options.healing_glow_alpha>0 or
            i>1 and self.ghost_options.healing_flare_alpha>0
        part:visible(self.visible and self.feedback.healing and
            (self.heal_glow_width or 0)>0 and part:width()>0 and enabled)
    end
end

function methods:set_color(color)
    -- Applies only to this gauge's foreground; the native neutral shell stays.
    self.color={red=color.red,green=color.green,blue=color.blue,
        alpha=color.alpha or self.color.alpha or 255}
    self:layout_fill()
end
function methods:set_pulse(active,style)
    self.pulse_active=active==true
    self.pulse_style=active and style or nil
    if not active then self.flash_on=false end
end

function methods:show()
    self.visible = true
    self:advance()
    -- Texture loading can restore a primitive's source-image dimensions
    -- after construction. The images library caches our requested sizes,
    -- so width() cannot detect that reset. Reassert all six sizes on draw,
    -- including a stationary, full-HP target; dragging must not be required.
    self:move(self.x, self.y)
end

function methods:hide()
    if not self.visible then return end
    self.visible = false
    self:refresh_visibility()
end

function methods:hover(x, y)
    return self.visible and x >= self.x and x <= self.x+self.width
        and y >= self.y and y <= self.y+12
end

function methods:destroy()
    for _, part in ipairs(self.trough) do part:destroy() end
    for _, part in ipairs(self.fill) do part:destroy() end
    for _, part in ipairs(self.trail or {}) do part:destroy() end
    for _, part in ipairs(self.trail_glow or {}) do part:destroy() end
    for _, part in ipairs(self.critical_fill or {}) do part:destroy() end
    for _, part in ipairs(self.flash_fill or {}) do part:destroy() end
    for _, part in ipairs(self.heal_glow or {}) do part:destroy() end
end

-- Independent overlays survive target switches, hide, and gauge recreation.
-- Scene transitions/unload clear both detached chunks and scheduled glints.
local function destroy_ghost(g)
    for _,p in ipairs(g.parts) do p:destroy() end
    for _,p in ipairs(g.glow or {}) do p:destroy() end
end
function gauge.clear_ghosts()
    death_spark.clear()
    for _,g in ipairs(ghosts) do destroy_ghost(g) end
    ghosts={}
end
function gauge.update_ghosts()
    death_spark.update()
    for i=#ghosts,1,-1 do
        local g=ghosts[i]
        local age=math.max(0,g.clock()-g.born)
        local o=g.options
        local pose=ghost_motion.sample(o,age)
        if pose.done then
            destroy_ghost(g)
            table.remove(ghosts,i)
        else
            local tint=health_motion.mix({red=255,green=255,blue=255},g.tint,
                o.ghost_fade_to=='trail' and pose.fade or 0)
            local cap=math.min(3,g.width/2)
            local y=g.y+pose.y
            local x=g.x+pose.x
            if g.glow then
                local strength=pose.glow*(1-pose.fade)
                if o.ghost_glow_flicker then strength=strength*pose.flicker end
                local height=9+2*o.ghost_glow_height*pose.glow*pose.height_scale*g.size_scale
                g.glow[1]:pos(x,y-(height-9)/2)
                g.glow[1]:size(g.width,height)
                g.glow[1]:alpha(math.floor(g.alpha*o.ghost_glow_alpha/255*strength+.5))
                g.glow[1]:visible(strength>0 and o.ghost_glow_alpha>0)
                local flare_height=9+o.ghost_flare_height*pose.glow*pose.height_scale*g.size_scale
                local flare_width=o.ghost_flare_width
                if g.size_scale<1 then flare_width=math.min(flare_width*g.size_scale,g.width/2) end
                local bright=health_motion.mix(o.ghost_glow_color,{red=255,green=255,blue=255},.5)
                for j=2,3 do
                    local p=g.glow[j]
                    p:pos((j==2 and x or x+g.width)-flare_width/2,y+9-flare_height)
                    p:size(flare_width,flare_height)
                    p:color(bright.red,bright.green,bright.blue)
                    p:alpha(math.floor(g.alpha*o.ghost_flare_alpha/255*strength+.5))
                    p:visible(strength>0 and o.ghost_flare_alpha>0 and o.ghost_flare_width>0)
                end
            end
            local widths={cap,math.max(0,g.width-2*cap),cap}
            local xs={x,x+cap,x+g.width-cap}
            for j,p in ipairs(g.parts) do
                p:pos(xs[j],y);p:size(widths[j],9)
                p:color(tint.red,tint.green,tint.blue)
                p:alpha(math.floor(g.alpha*pose.alpha+.5))
                p:visible(widths[j]>0)
            end
        end
    end
end
return gauge
