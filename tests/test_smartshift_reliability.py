from test_bufftap import test
from test_smartshift_nearby import SHIFT

for provider, source in [('SelectConsumable','consumable'), ('TrackingAction','tracking'), ('SelectWeaponReminder','weapon-reminder'), ('SelectReadiness','readiness')]:
    test('SmartShift reliability: return precedes optional '+source, SHIFT+f"""
B.{provider}=function() return {{source='{source}',key='optional',valid=true,secureType='spell'}} end
local action=B:Select(); assert(action and action.source=='smartshift','optional provider holds return')
""")

test('SmartShift reliability: restored power refreshes a waiting return immediately', SHIFT+"""
local usable=false
C_Spell.IsSpellUsable=function(id) if id==768 then return usable,not usable end return true,false end
B:Refresh(); assert(not B.action or B.action.source~='smartshift')
usable=true; B.events.scripts.OnEvent(nil,'UNIT_POWER_UPDATE','player','MANA'); advance(.1)
assert(B.action and B.action.source=='smartshift','power event failed to wake return')
""")

CAPTURE = """
local B=BuffTap; B.db.smartShift=true; spell(768,'Cat Form')
local form=1; GetShapeshiftForm=function() return form end
GetShapeshiftFormInfo=function() return 132115,form==1,true,768 end
B:Refresh(); B.button.scripts.PreClick(nil,'LeftButton',true)
assert(B.smartShiftIntent and not B.smartShiftIntent.verified)
form=0; B.events.scripts.OnEvent(nil,'UPDATE_SHAPESHIFT_FORM')
aura('player',5232,'Mark of the Wild'); B:InvalidateAura('player'); B:Refresh()
assert(B.action and B.action.id==467)
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(B.buffCastAttempt.id==467)
"""

test('SmartShift reliability: queued next buff cannot erase original cast confirmation', CAPTURE+"""
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','first',5232)
assert(B.smartShiftIntent and B.smartShiftIntent.verified,'next buff displaced SmartShift success')
aura('player',467,'Thorns'); B.events.scripts.OnEvent(nil,'UNIT_AURA','player'); advance(.1)
assert(B.action and B.action.source=='smartshift')
""")

test('SmartShift reliability: changed player identity cannot confirm original cast', CAPTURE+"""
UnitGUID=function() return 'Replacement' end
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','first',5232)
assert(not B.smartShiftIntent or not B.smartShiftIntent.verified)
""")

test('SmartShift reliability: rapid input before exit preserves original cast intent', """
local B=BuffTap; B.db.smartShift=true; spell(768,'Cat Form')
GetShapeshiftForm=function() return 1 end
GetShapeshiftFormInfo=function() return 132115,true,true,768 end
B:SmartShiftBegin({id=5232,target='player',targetGUID=UnitGUID('player')})
local original=B.smartShiftIntent
B:SmartShiftBegin({id=467,target='player',targetGUID=UnitGUID('player')})
assert(B.smartShiftIntent==original and original.buffID==5232)
B:SmartShiftEvent('UNIT_SPELLCAST_SUCCEEDED','player','first',5232)
assert(original.verified)
""")

test('SmartShift reliability: stale original success does not grant return', CAPTURE+"""
advance(4.1); B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','first',5232)
assert(not B.smartShiftIntent.verified)
""")

test('SmartShift reliability: another unit success cannot grant return', CAPTURE+"""
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','party1','first',5232)
assert(not B.smartShiftIntent.verified)
""")

test('SmartShift reliability: failed repeated input cannot revoke confirmed original success', CAPTURE+"""
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','first',5232)
assert(B.smartShiftIntent.verified)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','repeated',5232)
assert(B.smartShiftIntent and B.smartShiftIntent.verified)
""")

test('SmartShift reliability: checkup exposes pending return state without player names', SHIFT+"""
B:Refresh(); local report=table.concat(B:DiagnosticsLines(),'\\n')
assert(report:find('SmartShift: buff confirmed | form exit confirmed',1,true))
""")
