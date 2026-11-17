from test_bufftap import test

SETUP = """
local B=BuffTap
local start=GetTime(); local own=0; local classified=true
C_Spell.GetSpellCooldown=function(id)
 return {startTime=start,duration=1.5,isEnabled=true,isActive=true,isOnGCD=classified}
end
C_Spell.GetSpellCooldownDuration=function(id,ignore)
 assert(ignore==true)
 return {GetRemainingDuration=function() return own end}
end
local function cooldown() B.events.scripts.OnEvent(nil,'SPELL_UPDATE_COOLDOWN') end
"""

test('Queue: GCD event keeps verified next buff ready 1.5 seconds before GCD ends', SETUP+"""
aura('player',5232,'Mark of the Wild'); B:InvalidateAura('player'); cooldown()
assert(B.action and B.action.id==467 and bindings.MOUSEWHEELDOWN)
assert(GetTime()==start and B.button.attrs.spell==467)
advance(1.1); B.button.scripts.PreClick(nil,'LeftButton',true)
assert(B.action and B.button.attrs.spell==467 and not B.inCooldownEvent)
""")

test('Queue: classification outside cooldown event is never trusted', SETUP+"""
B:Refresh(); assert(not B.action and B.cooldownBlocked)
cooldown(); assert(B.action and B.button.attrs.spell==5232)
""")

test('Queue: real spell cooldown blocks even when GCD classification is true', SETUP+"""
own=10; cooldown(); assert(not B.action and not B.button.attrs.type1)
""")

test('Queue: a new independent cooldown cancels a previously prepared click', SETUP+"""
cooldown(); assert(B.action); own=10
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.action and not B.button.attrs.type1)
""")

test('Queue: changed timing cannot reuse the preceding GCD evidence', SETUP+"""
cooldown(); assert(B.action); start=start+.1
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.action and not B.button.attrs.type1)
""")

test('Queue: lost event classification revokes previous GCD evidence', SETUP+"""
cooldown(); assert(B.action); classified=false; cooldown()
assert(not B.action and not B.button.attrs.type1)
""")

for label, expression in [
    ('missing duration API', 'C_Spell.GetSpellCooldownDuration=nil'),
    ('nil duration', 'C_Spell.GetSpellCooldownDuration=function() end'),
    ('throwing duration method', 'C_Spell.GetSpellCooldownDuration=function() return {GetRemainingDuration=function() error("unavailable") end} end'),
    ('restricted remaining duration', 'own={secret=true}'),
    ('unknown classification', 'classified=nil'),
    ('restricted classification', 'classified={secret=true}'),
]:
    test('Queue: '+label+' retains conservative cooldown behavior', SETUP+expression+"; cooldown(); assert(not B.action and not B.button.attrs.type1)")

test('Queue: fresh aura prevents recasting a covered buff during GCD', SETUP+"""
cooldown(); assert(B.action.id==5232)
aura('player',5232,'Mark of the Wild')
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1)
""")

test('Queue: disabled setting cancels the GCD-ready click', SETUP+"""
cooldown(); B.db.enabled=false; B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1)
""")

test('Queue: combat discards GCD evidence and protected payload', SETUP+"""
cooldown(); combat=true; safety('blocked')
B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
assert(not B.gcdEvidence and not B.action and not next(bindings))
""")

test('Queue: helper and consumable sources cannot use ordinary buff GCD permission', SETUP+"""
cooldown(); local cd=C_Spell.GetSpellCooldown(5232)
for _,source in ipairs({'readiness','consumable','cleanse','revive','tracking','weapon'}) do
 assert(not B:OnlyGlobalCooldown({id=5232,source=source},cd),source)
end
""")

test('Queue: event scope is cleared after a refresh exception', SETUP+"""
B.Refresh=function() error('test failure') end; cooldown()
assert(not B.inCooldownEvent and B.lastError)
""")

test('Queue: unchanged recipient identity remains mandatory during GCD', SETUP+"""
B.db.group=true; B.db.buffs.thorns=false
aura('player',5232,'Mark of the Wild'); B:InvalidateAura(); cooldown()
assert(B.action and B.action.target=='party1')
local old=UnitGUID; UnitGUID=function(u) return u=='party1' and 'Replacement' or old(u) end
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1)
""")

test('Queue: expired evidence cannot turn an active real cooldown into GCD', SETUP+"""
cooldown(); advance(1.6); B:Refresh()
assert(not B.action)
""")

test('Queue: aura arriving after cooldown event prepares next spell during the GCD', SETUP+"""
cooldown(); assert(B.action and B.action.id==5232)
advance(.05); aura('player',5232,'Mark of the Wild')
B.events.scripts.OnEvent(nil,'UNIT_AURA','player'); advance(.06)
assert(B.action and B.action.id==467 and B.button.attrs.spell==467 and bindings.MOUSEWHEELDOWN)
assert(GetTime()<start+1.5)
""")
