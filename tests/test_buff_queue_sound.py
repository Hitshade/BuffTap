from test_bufftap import test

SOUND = """
local B=BuffTap; local heard=0
B.PlayAlert=function(_,kind) if kind=='reminder' then heard=heard+1 end end
B.db.sound=true; B.db.cleanseSoundEnabled=true; B.db.soundInterval=0; B:Commit(nil,'start'); B:Refresh()
assert(heard==1,'initial reminder should sound')
"""

test('Queue sound: next class buff after explicit press does not sound again', SOUND+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
aura('player',5232,'Mark of the Wild'); B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',5232)
advance(1.6); B:Refresh()
assert(B.action and B.action.id==467); assert(heard==1,'next buff replayed reminder sound')
""")

test('Queue sound: same buff returning after confirmed aura grace stays quiet', SOUND+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',5232)
B:Refresh(); advance(.85); B:Refresh()
assert(B.action and B.action.id==5232 and heard==1)
""")

test('Queue sound: genuinely new need after interaction pause can alert', SOUND+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
aura('player',5232,'Mark of the Wild'); aura('player',467,'Thorns'); B:Refresh()
advance(5); auras.player={}; B:InvalidateAura('player'); B:Refresh()
assert(B.action and heard==2)
""")

test('Queue sound: higher-priority cleanse alert is not muted by class buffing', SOUND+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
local action={id=5232,key='new-cleanse',source='cleanse',valid=true,secureType='spell',target='player',targetGUID=UnitGUID('player'),name='Cleanse',targetName='You',icon=1}
B:Commit(action,'cleanse'); assert(heard==2)
""")

test('Queue sound: no interaction preserves alert for changed class reminder', SOUND+"""
aura('player',5232,'Mark of the Wild'); B:Refresh()
assert(B.action.id==467 and heard==2)
""")

test('Queue sound: repeated presses keep a sequence longer than five seconds quiet', SOUND+"""
for i=1,4 do B.button.scripts.PreClick(nil,'LeftButton',true); advance(1.5) end
B.button.scripts.PreClick(nil,'LeftButton',true)
aura('player',5232,'Mark of the Wild'); B:Refresh()
assert(B.action.id==467 and heard==1)
""")

test('Queue sound: combat boundary restores normal reminder alerts', SOUND+"""
B.button.scripts.PreClick(nil,'LeftButton',true)
combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
combat=false; safety('ready'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(B.action and heard==2)
""")
