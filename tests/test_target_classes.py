from test_bufftap import test, tests
from test_nearby import setup

has="local function has(k) for _,a in ipairs((BuffTap:NearbyCandidates()[1] or {actions={}}).actions) do if a.key==k then return true end end return false end; "
rogue=setup.replace("return 'Warrior','WARRIOR'","return 'Rogue','ROGUE'")
test('Nearby keeps its default class lists',rogue+has+"aura('nameplate1',5232,'Mark of the Wild'); refresh(); assert(not has('thorns'))")
test('Thorns can be allowed for Rogues on Nearby',rogue+has+"aura('nameplate1',5232,'Mark of the Wild'); BuffTap:SetTargetClassAllowed(BuffTap:FindBuff('thorns'),'ROGUE',true); refresh(); assert(has('thorns')); BuffTap:ResetTargetClasses(BuffTap:FindBuff('thorns')); refresh(); assert(not has('thorns'))")
test('A class can be removed from an everyday buff on Nearby',setup+has+"assert(has('motw')); BuffTap:SetTargetClassAllowed(BuffTap:FindBuff('motw'),'WARRIOR',false); refresh(); assert(not has('motw') and has('thorns'))")
test('Defaults: Intellect skips Warriors everywhere, a clicked target still gets Thorns',"local B=BuffTap; local ai,th=B:FindBuff('ai'),B:FindBuff('thorns'); assert(not B:TargetClassAllowed(ai,'WARRIOR') and not B:TargetClassAllowed(ai,'WARRIOR',true) and B:TargetClassAllowed(ai,'PRIEST',true)); assert(B:TargetClassAllowed(th,'ROGUE') and not B:TargetClassAllowed(th,'ROGUE',true))")
test('A saved class choice applies to targets and Nearby alike, groups stay separate',"local B=BuffTap; local th=B:FindBuff('thorns'); B:SetTargetClassAllowed(th,'WARRIOR',false); assert(not B:TargetClassAllowed(th,'WARRIOR') and not B:TargetClassAllowed(th,'WARRIOR',true) and B:GroupClassAllowed(th,'WARRIOR'))")
