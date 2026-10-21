from test_bufftap import test, tests

party="BuffTap.db.group=true; BuffTap.db.buffs.thorns=false; aura('player',5232,'Mark of the Wild'); "
flags="UnitIsPVP=function(u) return u=='party1' end; "
test('PvP guard enabled by default and personal buffs remain available',flags+"refresh(); assert(BuffTap.db.pvpProtection and BuffTap.action.target=='player')")
test('Flagged party recipient skipped for safe member',party+flags+"refresh(); assert(BuffTap.action.target=='party2' and BuffTap.pvpBlocked)")
test('FFA recipient skipped even without ordinary flag',party+"UnitIsPVPFreeForAll=function(u) return u=='party1' end; refresh(); assert(BuffTap.action.target=='party2')")
test('Unreadable target flag does not count as unflagged',party+"UnitIsPVP=function(u) return u=='party1' and {secret=true} or false end; refresh(); assert(BuffTap.action.target=='party2')")
test('Missing flag API fails closed for external targets',party+"UnitIsPVP=nil; refresh(); assert(not BuffTap.action and BuffTap.pvpBlocked)")
test('Opt out permits flagged recipients',party+flags+"BuffTap.db.pvpProtection=false; refresh(); assert(BuffTap.action.target=='party1')")
test('Actively flagged caster permits other flagged players',party+"UnitIsPVP=function() return true end; refresh(); assert(BuffTap.action.target=='party1')")
test('Countdown retains protection',party+flags+"local old=UnitIsPVP; UnitIsPVP=function(u) return u=='player' or old(u) end; IsPVPTimerRunning=function() return true end; refresh(); assert(BuffTap.action.target=='party2')")
test('Missing countdown API does not permit extending flag',party+flags+"local old=UnitIsPVP; UnitIsPVP=function(u) return u=='player' or old(u) end; IsPVPTimerRunning=nil; refresh(); assert(BuffTap.action.target=='party2')")
for kind in ('pvp','arena'):
 test('PvP guard exempt in '+kind,party+flags+f"IsInInstance=function() return true,'{kind}' end; refresh(); assert(BuffTap.action.target=='party1')")
test('PvP flag change before click clears secure action',party+"refresh(); "+flags+"BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not BuffTap.button.attrs.spell)")
test('Flag change event refreshes eligible recipients',party+"refresh(); "+flags+"BuffTap.events.scripts.OnEvent(nil,'UNIT_FLAGS','party1'); advance(.1); assert(BuffTap.action.target=='party2')")
test('Group cast cannot reach flagged already-covered member',"spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end; BuffTap.db.group=true; BuffTap.db.groupNeed=2; aura('party1',5232,'Mark of the Wild'); "+flags+"refresh(); assert(BuffTap.action.id==5232 and not BuffTap.action.groupCast)")
test('Self group cast protects actual group even with group buffing off',"spell(21849,'Gift of the Wild',50); "+flags+"local a=BuffTap:Resolve(BuffTap:FindBuff('gotw'),'player'); assert(not BuffTap:PvPActionAllowed(a))")
test('Greater blessing protects same class in excluded raid subgroup',"""
IsInRaid=function() return true end; GetNumGroupMembers=function() return 3 end
UnitExists=function() return true end
GetRaidRosterInfo=function(i) return 'Name',0,i end
UnitIsUnit=function(a,b) return a==b or a=='raid1' and b=='player' end
UnitClass=function(u) return 'Paladin','PALADIN' end
UnitIsPVP=function(u) return u=='raid3' end
assert(not BuffTap:PvPActionAllowed({key='gbok',target='raid2'}))
""")
test('Group click rechecks newly flagged secondary recipient',"spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end; BuffTap.db.group=true; refresh(); assert(BuffTap.action.groupCast); "+flags+"BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not BuffTap.button.attrs.spell)")

failure="""
SPELL_FAILED_LINE_OF_SIGHT='Not visible'; SPELL_FAILED_OUT_OF_RANGE='Too far'
BuffTap:BeginHelperAttempt(BuffTap.action)
BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',5232)
BuffTap.events.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,SPELL_FAILED_LINE_OF_SIGHT)
"""
test('Confirmed failed recipient deferred and queue continues',party+"refresh(); "+failure+"advance(.1); assert(BuffTap.action.target=='party2' and BuffTap.deferredBlocked)")
test('Deferred recipient automatically retried after ten seconds',party+"refresh(); "+failure+"advance(.1); assert(BuffTap.action.target=='party2'); advance(10.1); assert(BuffTap.action.target=='party1')")
test('Deferral does not create persistent dismissal',party+"refresh(); "+failure+"assert(not BuffTap.helperDismissed or not next(BuffTap.helperDismissed))")
test('Failure event order can be reversed',party+"refresh(); SPELL_FAILED_OUT_OF_RANGE='Too far'; BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap.events.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,'Too far'); BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',5232); advance(.1); assert(BuffTap.action.target=='party2')")
test('Unrelated error alone cannot defer a recipient',party+"refresh(); SPELL_FAILED_LINE_OF_SIGHT='Not visible'; BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap.events.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,'Not visible'); advance(.1); assert(not BuffTap.failedRecipients)")
test('Unmatched spell failure cannot defer a recipient',party+"refresh(); SPELL_FAILED_LINE_OF_SIGHT='Not visible'; BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',999); BuffTap.events.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,'Not visible'); assert(not BuffTap.failedRecipients)")
test('Successful cast clears failure attribution',party+"refresh(); BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',5232); assert(not BuffTap.failedAttempt)")
test('Expired attempt cannot defer a recipient',party+"refresh(); "+failure.replace("BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED'","now=now+2; BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED'")+"assert(not BuffTap.failedRecipients)")
test('Temporary failure is keyed by player identity not unit token',party+"refresh(); "+failure+"local a={target='party1',targetGUID='Player-New'}; assert(not BuffTap:HelperSuppressed(a))")
test('Group changes clear temporary failures',party+"refresh(); "+failure+"BuffTap.events.scripts.OnEvent(nil,'GROUP_ROSTER_UPDATE'); assert(not BuffTap.failedRecipients)")
test('Unknown aura data has explicit visible status',"C_UnitAuras.GetAuraDataByIndex=function() error('unavailable') end; refresh(); assert(BuffTap.buffDataUnavailable and BuffTap:FriendlyStatus():find('unavailable',1,true)); assert(table.concat(BuffTap:DiagnosticsLines(),' '):find('incomplete',1,true))")
test('PvP guard preference copies through general profiles',"BuffTap.db.pvpProtection=false; assert(BuffTap:CreateSettingsProfile('Safe copy',true)); assert(not BuffTap.db.pvpProtection); assert(BuffTap:CreateSettingsProfile('New defaults',false)); assert(BuffTap.db.pvpProtection)")
test('Helpers exposes default-on safety toggle',"BuffTap:Options(); assert(BuffTap.options.pvpProtection:GetChecked())")
test('Incomplete raid roster blocks area casting',"IsInRaid=function() return true end; GetNumGroupMembers=function() return 3 end; UnitExists=function(u) return u~='raid3' end; GetRaidRosterInfo=function(i) return 'Name',0,1 end; assert(not BuffTap:PvPActionAllowed({key='gotw',target='raid1'}))")
test('Known dead flagged members do not block group spell',flags+"local old=UnitIsDeadOrGhost; UnitIsDeadOrGhost=function(u) return u=='party1' end; assert(BuffTap:PvPActionAllowed({key='gotw',target='player'}))")
test('Unwatched party flag changes refresh area safety',"BuffTap.db.group=false; BuffTap.events.scripts.OnEvent(nil,'UNIT_FLAGS','party1'); assert(BuffTap.refreshDue)")
test('Key release does not start a second error attribution',party+"refresh(); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.failedAttempt); BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',5232); BuffTap.button.scripts.PreClick(nil,'LeftButton',false); assert(not BuffTap.failedAttempt)")
test('Expired failure entries are pruned on a new failure',party+"refresh(); BuffTap.failedRecipients={old=now-1}; "+failure+"assert(not BuffTap.failedRecipients.old)")
print('ALL',len(tests),'SCENARIOS PASSED')
