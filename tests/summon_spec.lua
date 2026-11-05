package.path='./?.lua;'..package.path
local kinds=require('summonKinds')
for _,name in ipairs({'Carbuncle','Fenrir','Siren','Cait Sith',
    'Fire Spirit','Ice Spirit','Air Spirit','Earth Spirit',
    'Thunder Spirit','Water Spirit','Light Spirit','Dark Spirit'}) do
    assert(kinds.is_summon(name),name)
end
assert(kinds.kind('THUNDER SPIRIT')=='spirit')
assert(kinds.kind('Shiva')=='avatar')
for _,name in ipairs({'Tiger','Wyvern','Puppet','Alexander','Odin','Unknown'}) do
    assert(not kinds.is_summon(name),name)
end
print('PetBar SMN summon whitelist: PASS')
