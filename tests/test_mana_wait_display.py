from test_bufftap import test

WAIT = """
local B=BuffTap; local low=true
C_Spell.IsSpellUsable=function() return not low,low end
B.PlayAlert=function() error('mana wait must be silent') end
B.db.showBuffName=true; B.db.showTargetName=true
B.db.sound=true; B:Refresh()
"""

test('Mana status: main reminder explains pause without Nearby or secure action', WAIT+"""
assert(not B.db.nearbyEnabled and not B.action and B.manaWaitVisible and B.button.shown)
assert(B.button.nameLabel.text=='Waiting for mana' and B.button.label.text=='Resumes when ready')
assert(not B.button.attrs.type1 and not B.button.attrs.spell and not B.button.attrs.item and not next(bindings))
""")

test('Mana status: power recovery restores normal buff action', WAIT+"""
B.db.sound=false; low=false; B.events.scripts.OnEvent(nil,'UNIT_POWER_UPDATE','player','MANA'); advance(.1)
assert(B.action and B.button.attrs.type1=='spell' and not B.manaWaitVisible)
""")

test('Mana status: clicking status cannot cast or begin an attempt', WAIT+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.buffCastAttempt and not B.button.attrs.type1 and not next(bindings))
""")

for label,change in [('master off','B.db.enabled=false'),('mounted','mounted=true'),('temporary pause','B.pauseUntil=GetTime()+30'),('dead','dead=true')]:
    test('Mana status: '+label+' hides waiting display', WAIT+change+"; B:Refresh(); assert(not B.manaWaitVisible and not B.button.shown)")

test('Mana status: combat revokes passive display state', WAIT+"""
combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
assert(not B.manaWaitVisible and not B.button.attrs.type1 and not next(bindings))
""")

test('Mana status: unknown usability does not invent a mana shortage', """
local B=BuffTap; C_Spell.IsSpellUsable=function() return nil,nil end; B:Refresh()
assert(not B.manaWaitVisible and not B.action)
""")

test('Mana status: reserve alone cannot invent a main shortage', WAIT+"""
B:Commit(nil,'nothing actionable'); B.mainManaBlocked=nil
B.manaBlocked=false; B.manaFloorBlocked=true; B:ShowManaWait()
assert(not B.manaWaitVisible and not B.button.shown)
""")

test('Mana status: hidden reminder preference is retained', WAIT+"""
B.button.SetAlpha=function(s,v) s.testAlpha=v end
B.button.EnableMouse=function(s,v) s.testMouse=v end
B.db.showReminder=false; B:Refresh(); assert(B.button.testAlpha==0 and B.button.testMouse==false)
""")

test('Mana status: non-mana classes are labelled as power', WAIT+"""
playerClass='ROGUE'; B:ShowManaWait(); assert(B.button.nameLabel.text=='Waiting for power')
""")

from test_nearby import setup as NEARBY

test('Mana status: Nearby reserve stays in Nearby when personal buffs are complete', NEARBY+"""
local B=BuffTap; UnitPower=function() return 10 end; UnitPowerMax=function() return 100 end
B.db.nearbyManaFloor=25; B.db.friendlyTarget=true; refresh()
assert(B.manaFloorBlocked and B.powerBlocked and not B.action)
assert(not B.mainManaBlocked and not B.manaWaitVisible and not B.button.shown)
assert(not B.button.attrs.type1 and not next(bindings))
""")

test('Mana status: Nearby spell shortage cannot light the main reminder', NEARBY+"""
local B=BuffTap; C_Spell.IsSpellUsable=function() return false,true end; refresh()
assert(B.manaBlocked and B.powerBlocked and not B.action)
assert(not B.mainManaBlocked and not B.manaWaitVisible and not B.button.shown)
""")

test('Mana status: real personal shortage survives Nearby reserve and clears after buffing', NEARBY+"""
local B=BuffTap; B.db.showBuffName=true; auras={}; B:InvalidateAura()
C_Spell.IsSpellUsable=function() return false,true end
UnitPower=function() return 10 end; UnitPowerMax=function() return 100 end
B.db.nearbyManaFloor=25; B.db.friendlyTarget=true; refresh()
assert(B.mainManaBlocked and B.manaWaitVisible and B.button.shown)
assert(B.button.nameLabel.text=='Waiting for mana')
aura('player',5232,'Mark of the Wild'); aura('player',467,'Thorns'); refresh()
assert(not B.mainManaBlocked and not B.manaWaitVisible and not B.button.shown)
""")
