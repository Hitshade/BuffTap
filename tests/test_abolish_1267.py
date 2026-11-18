from test_bufftap import test
from test_cleanse import S
for cls,kind,abolish,cure in [('DRUID','Poison',2893,8946),('PRIEST','Disease',552,528)]:
 for duration,stacks in [(4,0),(6,1),(30,3)]:
  test('Learned Abolish preference '+cls+' '+str((duration,stacks)),S+"playerClass='"+cls+"'; spell("+str(abolish)+",'Abolish'); spell("+str(cure)+",'Cure'); B.db.cleansePreferAbolish=false; debuff('player',999,'Effect','"+kind+"',"+str(duration)+","+str(stacks)+"); refresh(); assert(B.action.id=="+str(abolish)+"); B.button.scripts.PreClick(nil,'LeftButton',true); assert(B.button.attrs.spell=="+str(abolish)+")")
 test('Cure fallback before Abolish learning '+cls,S+"playerClass='"+cls+"'; spells["+str(abolish)+"]=nil; spell("+str(cure)+",'Cure'); B.bookDirty=true; debuff('player',999,'Effect','"+kind+"',6,0); refresh(); assert(B.action.id=="+str(cure)+")")
 test('Class-specific automatic Abolish guidance '+cls,"local B=BuffTap; playerClass='"+cls+"'; B:InitDB(); B:Options(); assert(B.options.cleanseAbolishInfo.shown and B.options.cleanseAbolishInfo.text:find('"+kind+"') and not B.options.cleansePreferAbolish)")
