"""Screenshot regressions, native selectable diagnostics and setup opt-ins."""
from test_bufftap import test, tests, ROOT

start=len(tests)
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
for locale in ('enUS','deDE','frFR','esES','ptBR'):
    test('Beta4 Nearby controls reserve separate rows '+locale,RECORD+"""
BuffTap:Options(); local f=BuffTap.options
local function xy(c) local p=c.__draw.points[#c.__draw.points]; return p[2],p[3] end
local seen={}
for _,c in ipairs({f.nearbyBuffing,f.nearbyRankUpgrades,f.nearbyWhileResting,f.nearbyHoldShort,f.nearbyInvites,f.nearbyPvp,
 f.nearbyAll,f.nearbyFullNames,f.nearbyShowLevel,f.nearbyMarkSocial,f.nearbyFavor,f.nearbyManaFloor}) do
 local x,y=xy(c); local k=x..':'..y; assert(not seen[k],'overlap at '..k); seen[k]=true
 assert(y<=-112 and y>=-254)
end
local ux,uy=xy(f.nearbyRankUpgrades); local sx,sy=xy(f.nearbyMarkSocial)
assert(ux<300 and sx>300 and uy~=sy)
local _,fy=xy(f.nearbyFavor); local _,my=xy(f.nearbyManaFloor); assert(fy>my)
""",locale)
    test('Beta4 Diagnostics action buttons do not overlap '+locale,RECORD+"""
BuffTap:Options(); local f=BuffTap.options; local last=12
for _,c in ipairs({f.diagRefresh,f.diagSelectAll,f.diagReset,f.inspectBuffs,f.diagUnknown,f.diagRescan}) do
 local d=c.__draw; local p=d.points[#d.points]; assert(p[2]>=last+4 and p[3]==-604)
 last=p[2]+d.w; assert(last<=704)
end
""",locale)

test('Beta4 main Diagnostics uses a native multiline selectable edit box',"BuffTap:Options(); local f=BuffTap.options; assert(f.diagText:GetObjectType()=='EditBox' and f.diagText:GetParent()==f.diagContent and f.diagText.snapshotText==f.diagText:GetText())")
test('Beta4 Select all focuses and highlights the visible main text',"BuffTap:Options(); local f=BuffTap.options; local selected,focused; f.diagText.SetFocus=function() focused=true end; f.diagText.HighlightText=function() selected=f.diagText:GetText() end; f.diagSelectAll.scripts.OnClick(f.diagSelectAll); assert(focused and selected and selected:find('State:',1,true))")
test('Beta4 Select all focuses the captured inspector report',"BuffTap:Options(); local f=BuffTap.options; BuffTap:ShowDiagnosticsReport('buffs'); local selected; f.discoveryReport.HighlightText=function() selected=f.discoveryReport:GetText() end; f.diagSelectAll.scripts.OnClick(f.diagSelectAll); assert(selected and selected:find('Your active buffs',1,true))")
test('Beta4 selection survives background Diagnostics redraws',"BuffTap:Options(); local f=BuffTap.options; local before=f.diagText:GetText(); f.diagText.HasFocus=function() return true end; BuffTap.DiagnosticsLines=function() return {'Changed after selection'} end; BuffTap:Options(); assert(f.diagText:GetText()==before)")
test('Beta4 Escape releases focus and permits subsequent updates',"BuffTap:Options(); local f=BuffTap.options; local focused=true; f.diagText.HasFocus=function() return focused end; f.diagText.ClearFocus=function() focused=false end; f.diagText.scripts.OnEscapePressed(f.diagText); BuffTap.DiagnosticsLines=function() return {'After escape'} end; BuffTap:Options(); assert(not focused and f.diagText:GetText():find('After escape',1,true))")
test('Beta4 typing cannot alter the main diagnostic snapshot',"BuffTap:Options(); local e=BuffTap.options.diagText; local original=e.snapshotText; e:SetText('accidental edit'); e.scripts.OnTextChanged(e,true); assert(e:GetText()==original)")
test('Beta4 Refresh clears copy focus and returns to main diagnostics',"BuffTap:Options(); local f=BuffTap.options; BuffTap:ShowDiagnosticsReport('buffs'); local cleared=0; f.diagText.ClearFocus=function() cleared=cleared+1 end; f.discoveryReport.ClearFocus=function() cleared=cleared+1 end; f.diagRefresh.scripts.OnClick(f.diagRefresh); assert(cleared>=2 and f.diagScroll.shown and not f.discoveryScroll.shown)")
test('Beta4 live report capture does not refresh action selection',"BuffTap.Refresh=function() error('unexpected refresh') end; local text=BuffTap:ReportText('live',true); assert(text:find('State:',1,true))")
test('Beta4 selectable main display honors name hiding',"BuffTap.DiagnosticsLines=function() return {'Player: '..UnitName('player')} end; BuffTap:Options(); assert(not BuffTap.options.diagText:GetText():find(UnitName('player'),1,true)); BuffTap.reportHideNames=false; BuffTap:Options(); assert(BuffTap.options.diagText:GetText():find(UnitName('player'),1,true))")
test('Beta4 print-to-chat action is removed',RECORD+"BuffTap:Options(); for _,d in ipairs(recorded) do assert(not (d.kind=='frame' and d.text=='Print to chat')) end")
test('Beta4 Full check-up still includes and selects the buff inspector',"BuffTap:Options(); local f=BuffTap.options; f.diagCheckup.scripts.OnClick(f.diagCheckup); assert(f.discoveryReport:GetText():find('== Active buffs ==',1,true)); local selected; f.discoveryReport.HighlightText=function() selected=true end; f.diagSelectAll.scripts.OnClick(f.diagSelectAll); assert(selected)")

SETUP="""
local B=BuffTap; spells={}; book={}; B.db.onboardingVersion=nil
B.db.cleanseEnabled=false; B.db.reviveEnabled=false; B.db.cleanseFirst=false; B.db.smartShift=false
local function reviewAll(force)
 B:ShowOnboarding(force); B:OnboardingSettingsPage()
 local f=B.onboarding; local pick={}
 for offset=0,#f.recommendations-1,11 do
  B:OnboardingSettingsPage(offset)
  for _,row in ipairs(f.choices) do pick[row.spec.key]=row end
 end
 return pick,f
end
"""
classes=[('DRUID',True,True,True),('PRIEST',True,True,False),('PALADIN',True,True,False),('SHAMAN',True,True,True),('MAGE',True,False,False),('WARLOCK',False,False,False),('HUNTER',False,False,False),('ROGUE',False,False,False),('WARRIOR',False,False,False)]
for cls,cleanse,revive,shift in classes:
    checks=[]
    for field,on in [('cleanseEnabled',cleanse),('reviveEnabled',revive),('cleanseFirst',cleanse and revive),('smartShift',shift)]:
        checks.append(f"assert(pick.{field} and pick.{field}.check:GetChecked())" if on else f"assert(not pick.{field})")
    test('Beta4 fresh unlearned class setup offers appropriate defaults '+cls,SETUP+f"playerClass='{cls}'; B.db.welcomeSeen=false; local pick=reviewAll(false); "+'; '.join(checks))
test('Beta4 fresh setup applies selected class reminders without learning gates',SETUP+"playerClass='DRUID'; B.db.welcomeSeen=false; local pick,f=reviewAll(false); B:ApplyOnboarding(); assert(B.db.cleanseEnabled and B.db.reviveEnabled and B.db.cleanseFirst and B.db.smartShift and not B:CanRevive())")
test('Beta4 class defaults are visible and apply from the first setup page',SETUP+"playerClass='DRUID'; B.db.welcomeSeen=false; B:ShowOnboarding(); B:OnboardingSettingsPage(); local pick={}; for _,r in ipairs(B.onboarding.choices) do pick[r.spec.key]=r end; for _,k in ipairs({'cleanseEnabled','reviveEnabled','cleanseFirst','smartShift'}) do assert(pick[k] and pick[k].check:GetChecked()) end; B:ApplyOnboarding(); assert(B.db.cleanseEnabled and B.db.reviveEnabled and B.db.cleanseFirst and B.db.smartShift)")
test('Beta4 class-first setup retains the Paladin blessing recommendation',SETUP+"playerClass='PALADIN'; B.db.welcomeSeen=false; B:NormalizeGroupContexts(); B:ShowOnboarding(); B:OnboardingSettingsPage(); local pick={}; for _,r in ipairs(B.onboarding.choices) do pick[r.spec.key]=r end; assert(pick.blessings and pick.reviveEnabled and pick.cleanseEnabled)")
test('Beta4 new player may decline all class recommendations',SETUP+"playerClass='DRUID'; B.db.welcomeSeen=false; local pick,f=reviewAll(false); for _,field in ipairs({'cleanseEnabled','reviveEnabled','cleanseFirst','smartShift'}) do f.selection[field]=false; pick[field].check:SetChecked(false) end; B:ApplyOnboarding(); assert(not B.db.cleanseEnabled and not B.db.reviveEnabled and not B.db.cleanseFirst and not B.db.smartShift)")
test('Beta4 existing character choices are not preselected or silently changed',SETUP+"playerClass='DRUID'; B.db.welcomeSeen=true; local pick,f=reviewAll(true); for _,field in ipairs({'cleanseEnabled','reviveEnabled','cleanseFirst','smartShift'}) do assert(pick[field] and not pick[field].check:GetChecked()) end; assert(not B.db.cleanseEnabled and not B.db.reviveEnabled and not B.db.cleanseFirst and not B.db.smartShift)")
test('Beta4 existing class recommendation review still requires confirmation',SETUP+"playerClass='DRUID'; B.db.welcomeSeen=true; local pick,f=reviewAll(true); f.selection.cleanseEnabled=true; pick.cleanseEnabled.check:SetChecked(true); B:ApplyOnboarding(); assert(not B.db.cleanseEnabled); B:ApplyOnboarding(true); assert(B.db.cleanseEnabled)")
test('Beta4 leaving setup alone retains disabled class reminders',SETUP+"playerClass='DRUID'; B.db.welcomeSeen=false; reviewAll(false); B:FinishOnboarding(); assert(not B.db.cleanseEnabled and not B.db.reviveEnabled and not B.db.cleanseFirst and not B.db.smartShift)")

print('LAYOUT_SETUP_BETA4_CASES',len(tests)-start)
