from test_bufftap import test

test('Review: disabling BuffTap revokes an ordinary prepared click immediately', """
local B=BuffTap; assert(B.action and B.button.attrs.type1=='spell')
B.db.enabled=false; B.button.scripts.PreClick(nil,'LeftButton',false)
assert(not B.action and not B.button.attrs.type1)
""")

test('Review: Reset look restores all main appearance choices, not just text and size', """
local B=BuffTap
B.db.iconStyle='modern'; B.db.labelPosition='below'; B.db.showSwipe=true; B.db.showOutOfRange=true
B.db.effectUrgency=true; B.db.effectOnce=true; B:Options()
local r=B.options.resetLookButton; r.scripts.OnClick(r); r.scripts.OnClick(r)
assert(B.db.iconStyle=='classic' and B.db.labelPosition=='split')
assert(not B.db.showSwipe and not B.db.showOutOfRange and not B.db.effectUrgency and not B.db.effectOnce)
""")

SHIFT = """
local B=BuffTap; playerClass='DRUID'; spell(768,'Cat Form'); local form=0
GetShapeshiftForm=function() return form end
GetShapeshiftFormInfo=function() return 132115,form>0,true,768 end
C_Spell.GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true,isActive=false} end
B.db.smartShift=true; B.db.buffs.motw=false; B.db.buffs.thorns=false
B.smartShiftIntent={spellID=768,buffID=5232,started=GetTime(),verified=true,exited=true}
local action=assert(B:SmartShiftAction()); B:Commit(action,'review')
"""

for label, change in (
    ('disabled addon', 'B.db.enabled=false'),
    ('temporary pause', 'B.pauseUntil=GetTime()+60'),
    ('edit mode', 'B.editModeActive=true'),
    ('loading pause', 'B.loadingUntil=GetTime()+5'),
    ('resting pause', 'B.db.pauseResting=true; IsResting=function() return true end'),
):
    test('Review: SmartShift respects '+label+' at selection', SHIFT+change+"; refresh(); assert(not B.action)")

test('Review: SmartShift master-off cancels an already prepared hardware click', SHIFT+"""
B.db.enabled=false; B.button.scripts.PreClick(nil,'LeftButton',false)
assert(not B.button.attrs.type1 and not B.action)
""")

for label, change in (
    ('unreadable form', 'GetShapeshiftForm=function() return nil end'),
    ('unreadable active form metadata', 'form=2; GetShapeshiftFormInfo=function() return nil end'),
    ('missing player identity', 'UnitGUID=function() return nil end'),
    ('unconfirmed cooldown', 'C_Spell.GetSpellCooldown=function() return {startTime=0,duration=0} end'),
    ('active cooldown flag', 'C_Spell.GetSpellCooldown=function() return {isEnabled=true,isActive=true,startTime=0,duration=0} end'),
    ('casting', "UnitCastingInfo=function() return 'Another spell' end"),
):
    test('Review: SmartShift rejects '+label, SHIFT+change+"; assert(not B:ValidateSmartShift(action,true))")

test('Review: SmartShift wakes at the end of the form cooldown', SHIFT+"""
B.nextWakeDelay=nil
C_Spell.GetSpellCooldown=function() return {startTime=GetTime(),duration=1.5,isEnabled=true,isActive=true} end
assert(not B:SmartShiftAction()); assert(B.nextWakeDelay and B.nextWakeDelay>0 and B.nextWakeDelay<2)
""")

test('Review: Shaman Ghost Wolf follows the same pause and click safety rules', SHIFT+"""
playerClass='SHAMAN'; spell(2645,'Ghost Wolf'); B.smartShiftIntent.spellID=2645
local wolf=assert(B:SmartShiftAction()); assert(wolf.id==2645)
B:Commit(wolf,'review'); B.pauseUntil=GetTime()+60; refresh(); assert(not B.action)
B.pauseUntil=nil; wolf=assert(B:SmartShiftAction()); B:Commit(wolf,'review')
B.db.enabled=false; B.button.scripts.PreClick(nil,'LeftButton',false); assert(not B.button.attrs.type1)
""")

test('Review: an active hidden Manual effect still schedules its refresh threshold', """
local B=BuffTap; UnitInVehicle=function() return false end
local family=B:ConsumableFamily('flask'); local item=family.items[1]; stock(item.id,item.useSpell)
B.db.consumablesEnabled=true; B.db.consumableFamilies.flask=true; B.db.consumableModes.flask='manual'
B.db.consumableSeconds.flask=60
local effect=assert((item.auraIDs or family.auraSpellIDs)[1])
aura('player',effect,'Flask',120,3600)
B.nextWakeDelay=nil; B:InvalidateAura('player'); B:UpdateManualConsumables()
assert(#B.manualConsumableEntries==0)
assert(B.nextWakeDelay and math.abs(B.nextWakeDelay-60)<.1)
advance(60.1); B:InvalidateAura('player'); B:UpdateManualConsumables()
assert(#B.manualConsumableEntries==1 and B.manualConsumableButtons[1].shown)
""")
