from test_bufftap import test, tests
from test_nearby import setup

# Hidden current mana: UnitPower is secret, max readable, spells say what you can afford.
RULER=("local B=BuffTap; mana=500; UnitPower=function() return {secret=true} end; UnitPowerMax=function() return 1000 end; "
 "local costs={[9001]=100,[9002]=200,[9003]=300,[9004]=500,[9005]=800}; "
 "C_Spell=C_Spell or {}; C_Spell.GetSpellPowerCost=function(id) local c=costs[id]; return c and {{type=0,cost=c}} or {} end; "
 "C_Spell.IsSpellUsable=function(id) local c=costs[id]; if not c then return true,false end; return mana>=c, mana<c end; "
 "B.book={{id=9001},{id=9002},{id=9003},{id=9004},{id=9005}}; B.manaRuler=nil; B.db.nearbyManaFloor=25; "
 "local function check(m) mana=m; B.manaFloorAt=nil; return B:ManaFloorReached() end; ")
test('Hidden mana: an unaffordable cheap spell means below the reserve',RULER+"assert(check(150)==true, B.manaReading)")
test('Hidden mana: an affordable expensive spell means above the reserve',RULER+"B.manaFloorSaving=nil; assert(check(600)==false, B.manaReading)")
test('Hidden mana: in between, the middle of what is known decides',RULER+"B.manaFloorSaving=nil; assert(check(220)==false); assert(B.manaReading:find('estimate',1,true))")
test('Saving waits for 5% above the reserve before buffing again',RULER+"assert(check(150)==true); assert(check(290)==true,'resumed too early'); assert(check(600)==false)")
test('Readable mana still uses the exact value',"local B=BuffTap; B.db.nearbyManaFloor=25; UnitPower=function() return 200 end; UnitPowerMax=function() return 1000 end; B.manaFloorAt=nil; B.manaFloorSaving=nil; assert(B:ManaFloorReached()==true and B.manaReading:find('exact 20%',1,true))")
test('No usable information means no block',"local B=BuffTap; B.db.nearbyManaFloor=25; UnitPower=function() return {secret=true} end; UnitPowerMax=function() return 1000 end; C_Spell=C_Spell or {}; C_Spell.IsSpellUsable=function() return {secret=true},{secret=true} end; B.manaFloorAt=nil; B.manaFloorSaving=nil; assert(B:ManaFloorReached()==false and B.manaReading=='unreadable')")
test('Hidden mana below the reserve stops Nearby buffing',setup+RULER+"mana=150; local old=C_Spell.GetSpellPowerCost; C_Spell.GetSpellPowerCost=function(id) local r=old(id); if #r==0 then return {{type=0,cost=50}} end return r end; B.events.scripts.OnEvent(nil,'UNIT_POWER_UPDATE','player','MANA'); advance(.2); refresh(); assert(#B:NearbyCandidates(true)==0 and not (B.action and B.action.nearby), B.manaReading)")
test('Mana reserve shows in Nearby diagnostics',RULER+"check(150); local t=table.concat(B:NearbyDiagnosticsLines(),' '); assert(t:find('Mana reserve: 25%',1,true) and t:find('estimate',1,true))")
