from test_bufftap import test, tests, failures

start=len(tests)
test('Threshold defaults stay unchanged',"assert(BuffTap.db.groupNeed==3 and BuffTap.db.blessingNeed==2)")
test('One survives legacy and per-buff normalization',"local B=BuffTap; B.db.groupNeed=1; B.db.blessingNeed=1; B.db.buffGroupNeed.motw=1; B:InitDB(); assert(B.db.groupNeed==1 and B.db.blessingNeed==1 and B:GroupNeed(B:FindBuff('gotw'))==1)")
test('One remains independent in Party and Raid after normalization',"local B=BuffTap; local p=B:GroupSettings('Party',true); p.groupNeed=1; p.blessingNeed=1; p.buffGroupNeed.motw=1; local r=B:GroupSettings('Raid',true); r.groupNeed=4; r.blessingNeed=3; r.buffGroupNeed.motw=2; B:InitDB(); assert(B:GroupPreference('groupNeed','Party')==1 and B:GroupPreference('blessingNeed','Party')==1 and B:GroupNeed(B:FindBuff('gotw'),'Party')==1); assert(B:GroupPreference('groupNeed','Raid')==4 and B:GroupNeed(B:FindBuff('gotw'),'Raid')==2)")
test('Per-buff one is saved and remains bounded',"local B=BuffTap; local d=B:FindBuff('gotw'); B:SetGroupNeed(d,1,'Party'); B:InitDB(); assert(B:GroupNeed(d,'Party')==1 and B:GroupNeed(d,'Raid')==3); B:SetGroupNeed(d,0,'Party'); assert(B:GroupNeed(d,'Party')==1); B:SetGroupNeed(d,9,'Party'); assert(B:GroupNeed(d,'Party')==5)")

for single,group,name,class_token in [('motw',21849,'Gift of the Wild','DRUID'),('ai',23028,'Arcane Brilliance','MAGE'),('fort',21562,'Prayer of Fortitude','PRIEST')]:
    single_id={'motw':1126,'ai':1459,'fort':1243}[single]
    single_name={'motw':'Mark of the Wild','ai':'Arcane Intellect','fort':'Power Word: Fortitude'}[single]
    setup=f"local B=BuffTap; playerClass='{class_token}'; spells={{}}; book={{}}; spell({single_id},'{single_name}',1); spell({group},'{name}',60); UnitLevel=function() return 60 end; B.db.group=true; B.db.groupNeed=1; aura('player',{single_id},'{single_name}'); aura('party2',{single_id},'{single_name}'); refresh(); "
    test('One missing recipient selects group '+class_token,setup+f"assert(B.action and B.action.id=={group} and B.action.groupCount==1); B.button.scripts.PreClick(nil,'LeftButton',true); assert(B.button.attrs.type1=='spell')")
    test('One still respects disabled group spells '+class_token,setup+"B.db.smartGroup=false; refresh(); assert(B.action and not B.action.groupCast)")

# The existing Paladin fixture enables explicit assignments with one member per class.
from test_blessings import setup as paladin
test('One enables Greater for a single assigned class member',paladin+"BuffTap.db.blessingNeed=1; refresh(); assert(BuffTap.action and BuffTap.action.id==25782 and BuffTap.action.groupCount==1); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.button.attrs.type1=='spell')")
test('Greater one still respects explicit skip',paladin+"BuffTap.db.blessingNeed=1; BuffTap.db.blessingClasses.WARRIOR='skip'; BuffTap.db.blessingClasses.PRIEST='skip'; refresh(); assert(not BuffTap.action)")
print('NEW_THRESHOLD_CASES',12)
if __name__=='__main__':
    print('FOCUSED_FINAL',len(tests),'PASS',len(failures),'FAIL')
    if failures: raise SystemExit(1)
