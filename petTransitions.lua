 -- Pet lifecycle animation: identical color-preserving entrance and exit fades.
-- Reason labels are retained for diagnostics only; they do not change the look.
local transitions = {}
local methods = {}
methods.__index = methods

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end
local function duration(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or n < 0 or n == math.huge then return fallback end
    return n
end
local function progress(age, seconds)
    if seconds == 0 then return 1 end
    return clamp(age / seconds, 0, 1)
end

function transitions.new(options)
    options = options or {}
    return setmetatable({
        clock = options.clock or os.clock,
        fade_in = duration(options.fade_in, .24),
        fade_out = duration(options.fade_out, .4),
        phase = 'hidden', identity = nil, reason = nil,
        started_at = 0, from_alpha = 0,
    }, methods)
end

function methods:sample(now)
    now = now or self.clock()
    local age = math.max(0, now - self.started_at)
    local alpha, whiten = 0, 0
    if self.phase == 'entering' then
        alpha = self.from_alpha + (1 - self.from_alpha) * progress(age, self.fade_in)
        if age + 1e-9 >= self.fade_in then self.phase = 'visible'; alpha = 1 end
    elseif self.phase == 'visible' then
        alpha = 1
    elseif self.phase == 'leaving' then
        local seconds = self.fade_out
        alpha = self.from_alpha * (1 - progress(age, seconds))
        if age + 1e-9 >= seconds then
            self.phase, self.identity, self.reason = 'hidden', nil, nil
            alpha, whiten = 0, 0
        end
    end
    return {phase = self.phase, identity = self.identity, reason = self.reason,
        alpha = clamp(alpha, 0, 1), whiten = clamp(whiten, 0, 1),
        draw = self.identity ~= nil and alpha > 0}
end

function methods:appear(identity, now)
    if identity == nil then return false end
    now = now or self.clock()
    local current = self:sample(now)
    if current.identity == identity and
        (self.phase == 'entering' or self.phase == 'visible') then
        return false -- Repeated scans must not restart the entrance.
    end
    local resume_alpha = current.identity == identity and current.alpha or 0
    self.phase, self.identity, self.reason = 'entering', identity, nil
    self.from_alpha, self.started_at = resume_alpha, now
    return true
end

function methods:depart(reason, now)
    now = now or self.clock()
    local current = self:sample(now)
    if not current.identity or self.phase == 'leaving' then return false end
    -- Keep the reason for debugging, not for a different fade.
    if reason ~= 'release' and reason ~= 'death' then reason = 'missing' end
    self.phase, self.reason = 'leaving', reason
    self.started_at, self.from_alpha = now, current.alpha
    return true
end

function methods:clear()
    -- Cutscene, zoning, logout, and unload clean up immediately.
    self.phase, self.identity, self.reason = 'hidden', nil, nil
    self.started_at, self.from_alpha = 0, 0
end

return transitions
