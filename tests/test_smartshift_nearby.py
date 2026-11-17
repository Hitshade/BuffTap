from test_bufftap import test
from test_nearby import setup

SHIFT = setup+"""
local B=BuffTap; spell(768,'Cat Form'); GetShapeshiftForm=function() return 0 end
B.db.smartShift=true
B.smartShiftIntent={spellID=768,buffID=5232,started=GetTime(),verified=true,exited=true}
"""

test('SmartShift priority: return form precedes real Nearby buff on main binding', SHIFT+"""
B:Refresh(); assert(B.action and B.action.source=='smartshift' and B.button.attrs.spell==768)
B.button.scripts.PreClick(nil,'LeftButton',true); assert(B.button.attrs.spell==768)
assert(B.nearbyFrame.rows[1].action,'independent Nearby row remains available')
""")

test('SmartShift priority: remaining own buff still precedes return', SHIFT+"""
auras.player={}; B:InvalidateAura('player'); B:Refresh()
assert(B.action and B.action.id==5232 and not B.action.nearby)
""")

test('SmartShift priority: Nearby resumes after confirmed form restoration', SHIFT+"""
B:Refresh(); assert(B.action.source=='smartshift')
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',768); advance(.1)
assert(not B.smartShiftIntent and B.action and B.action.nearby)
""")

test('SmartShift priority: inactive or unverified intent leaves Nearby unchanged', SHIFT+"""
B.smartShiftIntent.verified=false; B:Refresh(); assert(B.action and B.action.nearby)
B.smartShiftIntent.verified=true; B.db.smartShift=false; B:Refresh(); assert(B.action and B.action.nearby)
""")

test('SmartShift priority: waiting for return cooldown does not hand binding to Nearby', SHIFT+"""
local start=GetTime()
C_Spell.GetSpellCooldown=function(id)
 if id==768 and GetTime()<start+1.5 then return {startTime=start,duration=1.5,isEnabled=true,isActive=true} end
 return {startTime=0,duration=0,isEnabled=true,isActive=false}
end
B:Refresh(); assert(not B.action and B.wakeDue and B.wakeDue<start+2)
advance(1.6); assert(B.action and B.action.source=='smartshift')
""")

test('SmartShift priority: real Nearby queued buff yields to queued return during GCD', SHIFT+"""
local start=GetTime()
C_Spell.GetSpellCooldown=function() return {startTime=start,duration=1.5,isEnabled=true,isActive=true,isOnGCD=true} end
C_Spell.GetSpellCooldownDuration=function() return {GetRemainingDuration=function() return 0 end} end
B.events.scripts.OnEvent(nil,'SPELL_UPDATE_COOLDOWN')
assert(B.action and B.action.source=='smartshift' and B.button.attrs.spell==768 and B.button.swipe.shown)
""")

test('SmartShift priority: Shaman return wins over optional Nearby buffs too', SHIFT+"""
playerClass='SHAMAN'; spell(2645,'Ghost Wolf'); B.smartShiftIntent.spellID=2645
-- Keep a real eligible Nearby request available across the class change.
local nearby=B.action or B:SelectNearby(); assert(nearby and nearby.nearby)
B.SelectNearby=function() return nearby end
B:Refresh(); assert(B.action and B.action.source=='smartshift' and B.action.id==2645)
""")

test('SmartShift priority: Nearby cleanse retains existing priority', SHIFT+"""
local cleanse={source='cleanse',nearby=true,id=2782,target='nameplate1',valid=true}
B.SelectNearby=function() return cleanse end
local action=B:Select(); assert(action==cleanse)
""")
