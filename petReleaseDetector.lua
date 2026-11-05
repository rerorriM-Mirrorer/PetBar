-- Pending Release is accepted only when the same owned pet actually departs.
-- FFXI job ability resources list SMN Release as PetCommand ID 90.
-- Windower outgoing action packet 0x01A encodes Category 9 and Param as ability ID.
local detector={}
local methods={}
methods.__index=methods
function detector.new(clock)
    return setmetatable({clock=clock or os.clock,hint=nil,timeout=2.5},methods)
end
function methods:observe(category,param,pet_id,now)
    if pet_id==nil then return false end
    local kind=tonumber(category)
    if kind~=9 and category~='Job ability usage' then return false end
    if tonumber(param)~=90 then return false end
    self.hint={pet_id=pet_id,at=now or self.clock()}
    return true
end
function methods:reason(pet_id,hpp,now)
    now=now or self.clock()
    if hpp==0 then return 'death' end
    local hint=self.hint
    if hint and hint.pet_id==pet_id and now-hint.at>=0 and
        now-hint.at<=self.timeout then
        return 'release'
    end
    return 'missing'
end
function methods:clear() self.hint=nil end
return detector
