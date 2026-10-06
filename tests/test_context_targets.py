from test_mage_release import test, tests, ROOT
from test_blessings import setup
from test_supplies import flask
solo=setup+'''
GetNumSubgroupMembers=function() return 0 end
BuffTap.db.group=false; BuffTap.db.friendlyTarget=true
BuffTap.db.buffs.bom=true; BuffTap.db.buffs.bow=true; BuffTap.db.buffs.bok=true
BuffTap.db.priorities.bom=1; BuffTap.db.priorities.bow=2; BuffTap.db.priorities.bok=3
classes.target='PRIEST'; BuffTap:InvalidateRoster(); refresh()
'''
test('Caster target ignores higher-priority Might',solo+"assert(BuffTap.action.key=='bow' and BuffTap.action.quickTarget)")
test('Each target class uses suitable enabled priority',solo+"for _,c in ipairs(BuffTap.RecipientClasses) do classes.target=c; refresh(); local physical=c=='WARRIOR' or c=='ROGUE' or c=='HUNTER' or c=='PALADIN'; assert(BuffTap.action.key==(physical and 'bom' or 'bow'),c) end")
test('Healthy desired target blessing does not cycle',solo+"aura('target',19742,'Blessing of Wisdom'); refresh(); assert(not BuffTap.action.quickTarget)")
test('Explicit target class choice permits deliberate override',solo+"BuffTap.db.targetBlessingClasses.PRIEST='bom'; refresh(); assert(BuffTap.action.key=='bom' and BuffTap.action.quickTarget)")
test('Explicit target choice independently enables target use',solo+"BuffTap.db.targetBlessingClasses.PRIEST='bom'; BuffTap.db.buffs.bom=false; refresh(); assert(BuffTap.action.key=='bom')")
test('Unlearned target choice falls back without changing saved choice',solo+"BuffTap.db.targetBlessingClasses.PRIEST='bol'; spells[19977].known=false; BuffTap.bookDirty=true; refresh(); assert(BuffTap.action.key=='bow' and BuffTap.db.targetBlessingClasses.PRIEST=='bol')")
test('Target choice skip returns to personal queue',solo+"BuffTap.db.targetBlessingClasses.PRIEST='skip'; refresh(); assert(not BuffTap.action.quickTarget)")
test('Target class change cancels prepared blessing',solo+"classes.target='WARRIOR'; BuffTap.button.scripts.PreClick(nil,'LeftButton'); assert(not BuffTap.action and not BuffTap.button.attrs.type1)")
test('Target preference change cancels prepared blessing',solo+"BuffTap.db.targetBlessingClasses.PRIEST='bok'; BuffTap.button.scripts.PreClick(nil,'LeftButton'); assert(not BuffTap.action)")
test('Unknown target class cannot guess a blessing',solo+"classes.target=nil; refresh(); assert(not BuffTap.action.quickTarget)")
test('Class-aware toggle restores unrestricted priority',solo+"BuffTap.db.targetClassBlessings=false; refresh(); assert(BuffTap.action.key=='bom')")
test('Target preference table sanitizes invalid data',solo+"BuffTap.db.targetBlessingClasses={PRIEST='bad',UNKNOWN='bom',DRUID='skip'}; BuffTap:InitDB(); assert(not BuffTap.db.targetBlessingClasses.PRIEST and not BuffTap.db.targetBlessingClasses.UNKNOWN and BuffTap.db.targetBlessingClasses.DRUID=='skip')")
test('Group target assignment overrides independent target preference',setup+"BuffTap.db.friendlyTarget=true; classes.target='PRIEST'; UnitGUID=function(u) return 'Player-'..(u=='target' and 'party2' or u) end; BuffTap.db.targetBlessingClasses.PRIEST='bom'; refresh(); assert(BuffTap.action.key=='bow' and BuffTap.action.blessingAssigned)")
test('New group assignment cancels prepared independent target',solo+"GetNumSubgroupMembers=function() return 2 end; BuffTap.db.group=true; BuffTap:InvalidateRoster(); UnitGUID=function(u) return 'Player-'..(u=='target' and 'party2' or u) end; BuffTap.button.scripts.PreClick(nil,'LeftButton'); assert(not BuffTap.action)")
test('Resting pause defaults off',"IsResting=function() return true end; refresh(); assert(not BuffTap.db.pauseResting and BuffTap.action)")
test('Rest event clears action and bindings then resumes',"local resting=true; IsResting=function() return resting end; BuffTap.db.pauseResting=true; BuffTap.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(not BuffTap.action and not next(bindings)); resting=false; BuffTap.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(BuffTap.action)")
test('Preclick catches resting transition before event',"IsResting=function() return true end; BuffTap.db.pauseResting=true; BuffTap.button.scripts.PreClick(nil,'LeftButton'); assert(not BuffTap.action and not BuffTap.button.attrs.type1)")
test('Rest transition in combat defers secure writes',"combat=true; IsResting=function() return true end; BuffTap.db.pauseResting=true; BuffTap.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(BuffTap.dirty); combat=false; BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); assert(not BuffTap.action)")
test('Unavailable resting API leaves reminders usable',"BuffTap.db.pauseResting=true; IsResting=function() error('unavailable') end; refresh(); assert(BuffTap.action)")
test('Rest pause and mount hide supply badge',flask+"bags[13510]=0; bagEvent(); assert(BuffTap.supplyBadge.shown); mounted=true; BuffTap.events.scripts.OnEvent(nil,'PLAYER_MOUNT_DISPLAY_CHANGED'); assert(not BuffTap.supplyBadge.shown); mounted=false; IsResting=function() return true end; BuffTap.db.pauseResting=true; BuffTap.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(not BuffTap.supplyBadge.shown)")
test('Paused low stock alerts wait until resume once',flask+"BuffTap.db.suppliesChat=true; mounted=true; bags[13510]=1; bagEvent(); assert(#prints==0); mounted=false; BuffTap.events.scripts.OnEvent(nil,'PLAYER_MOUNT_DISPLAY_CHANGED'); assert(#prints==1); refresh(); assert(#prints==1)")
test('Paused ready check remains quiet',flask+"BuffTap.db.suppliesReadyCheck=true; BuffTap:InitDB(); mounted=true; local n=#prints; BuffTap.events.scripts.OnEvent(nil,'READY_CHECK'); assert(#prints==n)")
test('Sound previews remain available while paused',"mounted=true; local n=0; PlaySound=function() n=n+1 end; BuffTap.db.sound=true; assert(not BuffTap:PlayAlert('reminder',false)); assert(BuffTap:PlayAlert('reminder',true) and n==1)")
test('Paladin target controls appear with independent saved choices',solo+"BuffTap:Options(); local f=BuffTap.options; assert(f.targetBlessingPanel.shown and #f.targetBlessingPicks==9); local pick=f.targetBlessingPicks[5]; pick.scripts.OnClick(pick); local row=f.blessingMenu.priorityRows[3]; row.toggle.scripts.OnClick(row.toggle); assert(BuffTap.db.targetBlessingClasses.PRIEST=='priority' and BuffTap.db.targetBlessingPriorities.PRIEST[3]=='bom' and BuffTap.db.blessingClasses.PRIEST=='bow')")
test('Other classes do not show Paladin target controls',"BuffTap:Options(); assert(not BuffTap.options.targetBlessingPanel.shown)")
for locale in ['esES','deDE','frFR','ptBR']:
 test('Context options build in '+locale,solo+"BuffTap:Options(); assert(BuffTap.options.targetBlessingPanel.shown)",locale=locale)
test('Paused hover in combat never changes protected action',"combat=true; mounted=true; BuffTap.button.scripts.OnEnter(); assert(BuffTap.action)")
test('Options pause toggle immediately quiets and resumes stock',flask+"bags[13510]=0; bagEvent(); IsResting=function() return true end; BuffTap:Options(); local c=BuffTap.options.pauseResting; c:SetChecked(true); c.scripts.OnClick(c); assert(not BuffTap.action and not BuffTap.supplyBadge.shown); c:SetChecked(false); c.scripts.OnClick(c); assert(BuffTap.supplyBadge.shown)")
test('Resting toggle belongs to Helpers rather than Appearance',"BuffTap:Options(); assert(BuffTap.options.pauseResting.parent==BuffTap.helperWindow)")
print('ALL',len(tests),'SCENARIOS PASSED')
