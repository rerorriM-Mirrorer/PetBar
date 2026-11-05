-- Only persistent SMN pets get PetBar; never assume every player pet is a summon.
local kinds={}
local approved={}
for _,name in ipairs({
    'Carbuncle','Ifrit','Shiva','Garuda','Titan','Ramuh',
    'Leviathan','Fenrir','Diabolos','Cait Sith','Siren',
    'Fire Spirit','Ice Spirit','Air Spirit','Earth Spirit',
    'Thunder Spirit','Water Spirit','Light Spirit','Dark Spirit',
}) do approved[name:lower()]=true end
function kinds.is_summon(name)
    return type(name)=='string' and approved[name:lower()]==true
end
function kinds.kind(name)
    if not kinds.is_summon(name) then return nil end
    return name:lower():find(' spirit',1,true) and 'spirit' or 'avatar'
end
return kinds
