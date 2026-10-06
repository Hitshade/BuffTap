from test_blessing_ui import test, tests
from test_context_targets import solo
priority=solo+"BuffTap.db.targetBlessingClasses.PRIEST='bok'; UnitIsUnit=function(a,b) return a==b end; UnitExists=function(u) return u=='player' or u=='target' or u=='other' end; refresh(); "
test('Other Paladin Kings permits Wisdom fallback',priority+"aura('target',20217,'Blessing of Kings'); auras.target[1].sourceUnit='other'; refresh(); assert(BuffTap.action.quickTarget and BuffTap.action.key=='bow')")
test('Own Kings is maintained without switching',priority+"aura('target',20217,'Blessing of Kings'); auras.target[1].sourceUnit='player'; refresh(); assert(not BuffTap.action.quickTarget)")
test('Own lower priority Wisdom prevents Kings replacement',priority+"aura('target',19742,'Blessing of Wisdom'); auras.target[1].sourceUnit='player'; refresh(); assert(not BuffTap.action.quickTarget)")
test('Unknown owner stops fallback',priority+"aura('target',20217,'Blessing of Kings'); refresh(); assert(not BuffTap.action.quickTarget)")
test('Unresolved caster stops fallback',priority+"aura('target',20217,'Blessing of Kings'); auras.target[1].sourceUnit='vanished'; refresh(); assert(not BuffTap.action.quickTarget)")
test('All eligible blessings covered stops target queue',priority+"aura('target',20217,'Blessing of Kings'); aura('target',19742,'Blessing of Wisdom'); for _,a in ipairs(auras.target) do a.sourceUnit='other' end; refresh(); assert(not BuffTap.action.quickTarget)")
test('Disabled fallback keeps single class preference',priority+"BuffTap.db.targetBlessingFallback=false; aura('target',20217,'Blessing of Kings'); auras.target[1].sourceUnit='other'; refresh(); assert(not BuffTap.action.quickTarget)")
test('Changed ownership before click cancels fallback',priority+"aura('target',20217,'Blessing of Kings'); auras.target[1].sourceUnit='other'; refresh(); assert(BuffTap.action.key=='bow'); auras.target[1].sourceUnit='player'; BuffTap.button.scripts.PreClick(nil,'LeftButton'); assert(not BuffTap.action)")
test('Greater Kings from another Paladin permits fallback',priority+"aura('target',25898,'Greater Blessing of Kings'); auras.target[1].sourceUnit='other'; refresh(); assert(BuffTap.action.key=='bow' and not BuffTap.action.groupCast)")
test('Target skip remains authoritative with fallback',priority+"BuffTap.db.targetBlessingClasses.PRIEST='skip'; refresh(); assert(not BuffTap.action.quickTarget)")
test('Own expiring Kings refreshes Kings instead of Wisdom',priority+"aura('target',20217,'Blessing of Kings'); auras.target[1].sourceUnit='player'; auras.target[1].duration=3600; auras.target[1].expirationTime=GetTime()+10; refresh(); assert(BuffTap.action.quickTarget and BuffTap.action.key=='bok')")
test('Own unavailable blessing blocks replacement',priority+"aura('target',19740,'Blessing of Might'); auras.target[1].sourceUnit='player'; refresh(); assert(not BuffTap.action.quickTarget)")
print('ALL',len(tests),'SCENARIOS PASSED')
