from test_bufftap import test
from test_revive import R

for cls,ident in [('PRIEST',2006),('PALADIN',7328),('SHAMAN',2008),('DRUID',437138)]:
    test(cls+' resurrection survives main PreClick after revive validation',R+f"playerClass='{cls}'; spells={{}}; book={{}}; spell({ident},'Resurrection'); B.bookDirty=true; refresh(); assert(B.action and B.action.source=='revive'); B.button.scripts.PreClick(B.button,'LeftButton',true); assert(B.action and B.button.attrs.type1=='spell' and B.button.attrs.spell=={ident})")

for change in ["UnitGUID=function() return 'Player-replaced' end", "dead.party1=false", "ghost.party1=true", "incoming.party1=true", "B.db.reviveEnabled=false"]:
    test('Resurrection click still rejects '+change,R+"refresh(); assert(B.action and B.action.source=='revive'); "+change+"; B.button.scripts.PreClick(B.button,'LeftButton',true); assert(not B.action and not B.button.attrs.type1)")
