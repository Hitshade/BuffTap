from test_bufftap import test

WRAP="""local make=CreateFrame
CreateFrame=function(...) local f=make(...); f.SetFrameStrata=function(s,v) s.testStrata=v end; return f end
"""

test('Missing-buff button shares MEDIUM strata with other addon windows', WRAP+"""
local B=BuffTap; B.button=nil; B:CreateButton()
assert(B.button and B.button.testStrata=='MEDIUM','strata '..tostring(B.button and B.button.testStrata))
""")

test('Manual consumable buttons share MEDIUM strata with other addon windows', WRAP+"""
local B=BuffTap; UnitInVehicle=function() return false end
B.db.consumablesEnabled=true; B.db.consumableFamilies.food=true; B.db.consumableModes.food='manual'
local item=B:ConsumableFamily('food').items[1]; stock(item.id,item.useSpell)
B:InvalidateConsumables(); refresh()
assert(B.manualConsumableHolder,'no holder: '..tostring(B.lastError))
assert(B.manualConsumableHolder.testStrata=='MEDIUM','strata '..tostring(B.manualConsumableHolder.testStrata))
""")
