from test_bufftap import test
SETUP="""
local B=BuffTap; playerClass='WARRIOR'; spells={}; book={}; spell(6673,'Battle Shout'); B:NormalizeGroupContexts()
local low=true; C_Spell.IsSpellUsable=function() return not low,low end
B.db.sound=false; refresh()
"""
test('Warrior low rage hides passive icon without arming a cast',SETUP+"assert(B.powerBlocked and B.manaBlocked and not B.action and not B.manaWaitVisible and not B.button.shown); assert(not B.button.attrs.type1 and not next(bindings))")
test('Warrior rage event restores missing cast and hides again after loss',SETUP+"low=false; B.events.scripts.OnEvent(nil,'UNIT_POWER_UPDATE','player','RAGE'); advance(.1); assert(B.action and B.action.key=='battle-shout' and B.button.attrs.type1=='spell' and B.button.shown); low=true; refresh(); assert(not B.action and not B.manaWaitVisible and not B.button.shown and not B.button.attrs.type1 and not next(bindings))")
test('Warrior combat still disarms action and low rage stays hidden after combat',SETUP+"combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); assert(not B.action and not B.manaWaitVisible); combat=false; safety('ready'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); advance(.1); assert(not B.action and not B.manaWaitVisible and not B.button.shown)")
