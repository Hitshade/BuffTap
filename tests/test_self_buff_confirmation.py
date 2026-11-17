from test_bufftap import test

THORNS = """
local B=BuffTap; B.db.priorities.motw=1; B.db.priorities.thorns=2; B.db.buffSeconds.thorns=0
aura('player',5232,'Mark of the Wild'); B:Refresh()
assert(B.action and B.action.id==467)
"""

test('Thorns report: fresh aura respects zero refresh and second priority', THORNS+"""
aura('player',467,'Thorns',600,600); B:Refresh(); assert(not B.action)
""")

test('Thorns report: applied aura arriving before next press blocks duplicate', THORNS+"""
aura('player',467,'Thorns',600,600); B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1)
""")

test('Thorns report: successful self cast waits briefly for delayed aura before retry', THORNS+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',467)
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1,'same buff rearmed before its aura update')
""")

test('Thorns report: missing aura permits retry after bounded grace', THORNS+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',467)
B:Refresh(); assert(not B.action)
advance(.85); assert(B.action and B.action.id==467)
""")

test('Thorns report: a different missing self buff is not delayed', THORNS+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',467)
auras.player={}; B:InvalidateAura('player'); B:Refresh()
assert(B.action and B.action.id==5232)
""")

test('Thorns report: failed or unconfirmed clicks do not start grace', THORNS+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',467)
assert(not B:SelfBuffAwaitingAura(B.action))
""")

test('Thorns report: another unit success cannot start grace', THORNS+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','party1','cast',467)
assert(not B:SelfBuffAwaitingAura(B.action))
""")

test('Thorns report: party recipients and group casts are not deferred', THORNS+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',467)
assert(not B:SelfBuffAwaitingAura({id=467,target='party1',targetGUID=UnitGUID('party1')}))
assert(not B:SelfBuffAwaitingAura({id=467,target='player',targetGUID=UnitGUID('player'),groupCast=true}))
""")

test('Thorns report: a displaced general attempt still confirms the original self cast', THORNS+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B:BeginHelperAttempt({id=5232,target='player',targetGUID=UnitGUID('player')})
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',467)
assert(B:SelfBuffAwaitingAura({id=467,target='player',targetGUID=UnitGUID('player')}))
""")
