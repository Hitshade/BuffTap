from test_bufftap import test
from test_gcd_queue import SETUP

SWIPE = """
local swipe=B.button.swipe
swipe.SetCooldown=function(s,start,duration) s.testStart=start; s.testDuration=duration end
swipe.SetReverse=function(s,reverse) s.testReverse=reverse end
"""

test('GCD display: queued sweep appears with rebuff sweep disabled', SETUP+SWIPE+"""
B.db.showSwipe=false; cooldown()
assert(swipe.shown and swipe.testStart==start and swipe.testDuration==1.5 and swipe.testReverse==false)
assert(B.action.gcdStart==start and B.action.gcdDuration==1.5)
""")

test('GCD display: completion clears sweep without another cooldown event', SETUP+SWIPE+"""
local original=C_Spell.GetSpellCooldown
C_Spell.GetSpellCooldown=function(id)
 if GetTime()>=start+1.5 then return {startTime=0,duration=0,isEnabled=true,isActive=false} end
 return original(id)
end
cooldown(); assert(swipe.shown); advance(1.6)
assert(B.action and not B.action.gcdStart and not swipe.shown and not B.button.swipeKey)
""")

test('GCD display: queued sweep takes precedence then restores rebuff direction', SETUP+SWIPE+"""
cooldown(); local action=B.action
action.needState='expiring'; action.remaining=20; action.threshold=45; B.db.showSwipe=true
B:UpdateOverlay(); assert(swipe.testDuration==1.5 and swipe.testReverse==false)
action.gcdStart=nil; action.gcdDuration=nil; B:UpdateOverlay()
assert(swipe.shown and swipe.testDuration==45 and swipe.testReverse==true)
""")

test('GCD display: cancelling the action hides the sweep', SETUP+SWIPE+"""
cooldown(); B.db.enabled=false; B:Refresh()
assert(not B.action and not swipe.shown)
""")

test('GCD display: refreshing queued action does not add another alert', SETUP+SWIPE+"""
local count=0; B.PlayAlert=function() count=count+1 end
B.db.sound=true; B.db.soundInterval=0; cooldown(); local before=count
B:Refresh(); B:UpdateOverlay(); cooldown()
assert(count==before)
""")

test('GCD display: GCD expiry adds no secondary alert', SETUP+SWIPE+"""
local original=C_Spell.GetSpellCooldown
C_Spell.GetSpellCooldown=function(id)
 if GetTime()>=start+1.5 then return {startTime=0,duration=0,isEnabled=true,isActive=false} end
 return original(id)
end
local count=0; B.PlayAlert=function() count=count+1 end
B.db.sound=true; B.db.soundInterval=0; cooldown(); local before=count
advance(1.6); assert(B.action and count==before and not swipe.shown)
""")

SHIFT = """
B.db.smartShift=true; B.db.buffs.motw=false; B.db.buffs.thorns=false
spell(768,'Cat Form'); GetShapeshiftForm=function() return 0 end
B.smartShiftIntent={spellID=768,buffID=5232,started=GetTime(),verified=true,exited=true}
"""

test('GCD display: SmartShift return form queues silently and shows GCD', SETUP+SWIPE+SHIFT+"""
cooldown(); assert(B.action and B.action.source=='smartshift' and B.action.id==768)
assert(swipe.shown and B.button.attrs.spell==768 and bindings.MOUSEWHEELDOWN)
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(B.button.attrs.spell==768)
""")

test('GCD display: SmartShift independent cooldown still blocks', SETUP+SHIFT+"""
own=10; cooldown(); assert(not B.action and not B.button.attrs.type1)
""")

test('GCD display: waiting SmartShift wakes on cooldown event without an ordinary action', SETUP+SHIFT+"""
B:Refresh(); assert(not B.action and B.cooldownBlocked)
cooldown(); assert(B.action and B.action.source=='smartshift')
""")

test('GCD display: changed form cancels queued SmartShift click', SETUP+SHIFT+"""
cooldown(); assert(B.action); GetShapeshiftForm=function() return 1 end
B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.button.attrs.type1)
""")

test('GCD display: Shaman return to Ghost Wolf queues with same checks', SETUP+SWIPE+SHIFT+"""
playerClass='SHAMAN'; spell(2645,'Ghost Wolf'); B.smartShiftIntent.spellID=2645
cooldown(); assert(B.action and B.action.id==2645 and swipe.shown)
own=5; B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.button.attrs.type1)
""")

for cls, spell_id in [('MAGE',168),('SHAMAN',324),('HUNTER',13165),('PALADIN',19740)]:
    test('GCD display: '+cls+' ordinary self buff uses shared queue and sweep', SETUP+SWIPE+f"""
playerClass='{cls}'; spell({spell_id},'Self buff')
cooldown()
local action={{id={spell_id},target='player',targetGUID=UnitGUID('player'),key='test-self',name='Self buff',icon=1,secureType='spell'}}
assert(B:Validate(action)); assert(action.gcdStart==start)
B:Commit(action,'self buff'); assert(B.button.attrs.spell=={spell_id} and swipe.shown)
""")
