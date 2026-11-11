-- PetBar summon lifetime guard. Windower can briefly report an owned pet
-- with 0% HP or no entity while its summon/zone state is settling.
-- Keep the most recent confirmed positive HP and wait for sustained zero
-- or sustained disappearance before declaring a death/departure.
local guard={}
local methods={}
methods.__index=methods
local function grace(value,fallback)
    local n=tonumber(value)
    return n and n>=0 and n<10 and n or fallback
end
function guard.new(settings)
    settings=settings or {}
    return setmetatable({
        identity=nil,alive=false,zero_since=nil,missing_since=nil,
        zero_grace=grace(settings.zero_grace,.35),
        missing_grace=grace(settings.missing_grace,.40),
    },methods)
end
function methods:clear()
    self.identity,self.alive,self.zero_since,self.missing_since=nil,false,nil,nil
end
function methods:track(identity)
    if identity==nil then return false end
    if self.identity==identity then return false end
    self.identity=identity
    self.alive=false
    self.zero_since=nil
    self.missing_since=nil
    return true
end
function methods:present()
    self.missing_since=nil
end
function methods:health(value,now)
    local h=tonumber(value)
    if not h or h~=h or h<0 or h>100 then return 'unknown' end
    if h>0 then
        self.alive=true
        self.zero_since=nil
        self.missing_since=nil
        return 'alive'
    end
    -- An initial zero is uninitialized summon data, not evidence of death.
    if not self.alive then return 'uninitialized' end
    now=now or os.clock()
    if not self.zero_since then self.zero_since=now end
    return now-self.zero_since>=self.zero_grace and 'dead' or 'zero_pending'
end
function methods:missing(now)
    if not self.identity then return false end
    now=now or os.clock()
    if not self.missing_since then self.missing_since=now end
    return now-self.missing_since>=self.missing_grace
end
return guard
