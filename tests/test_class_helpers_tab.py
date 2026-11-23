from test_bufftap import test,ROOT
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
EXPECT={'DRUID':'Tracking','WARLOCK':'Class helpers','HUNTER':'Pet and tracking','PALADIN':'Class helpers'}
for cls,tab in EXPECT.items():
 for locale in ('enUS','deDE','frFR'):
  test('Class helpers tab '+cls+' '+locale,RECORD+"""
playerClass='"""+cls+"""'; BuffTap:Options(); local f=BuffTap.options; local hp=BuffTap.helperWindow
local g=BuffTap.contextControls.buffs
local function y(c) local p=c.__draw.points[#c.__draw.points]; return type(p[3])=='number' and p[3] or p[5] end
assert(g.helpers and g.helpersRule,'tab exists')
assert(g.helpers:GetText()==BuffTap:Text('"""+tab+"""'),'tab label '..tostring(g.helpers:GetText()))
assert(BuffTap:ClassHelpersLabel()=='"""+tab+"""')
assert(not f.helpersPane:IsShown() and f.buffContent:IsShown(),'opens on the buff list')
BuffTap.editContexts={buffs='party'}; BuffTap:Options(); assert(g.reset:IsShown(),'Use Solo settings in Party')
g.helpers.scripts.OnClick(g.helpers)
assert(BuffTap.buffsHelpersView==true and f.helpersPane:IsShown() and not f.buffContent:IsShown(),'pane replaces the list')
assert(not g.reset:IsShown(),'Use Solo settings hidden on Class helpers')
assert(hp.readiness:GetParent()==f.helpersPane and hp.helperSections.tracking:GetParent()==f.helpersPane,'controls moved to the pane')
assert(hp.soulMenu:GetParent()==f.helpersPane and hp.demonMenu:GetParent()==f.helpersPane,'menus moved to the pane')
local description=f.pageHeaders[1].description:GetText()
assert(description==BuffTap:Text(BuffTap:ClassHelpersSummary()),'subtitle')
local trackTop=y(hp.helperSections.tracking)+y(hp.trackerCard)
local function px(c) local q=c.__draw.points[#c.__draw.points]; return q[2] end
assert(px(hp.trackerCard)==12 and px(hp.checks.helperTracking)==28 and px(hp.trackerHeading)==50,'tracking icon, title and controls line up inside the card')
if hp.readiness:IsShown() then
  local readyTop=y(hp.readiness)+y(hp.readinessCard)
  local readyBottom=readyTop-hp.readinessCard.__draw.h
  assert(readyBottom-trackTop==8,'tracking sits 8 below readiness')
  assert(readyTop==-62,'readiness starts under the tab row')
else
  assert(trackTop==-62,'tracking takes the top when there is no class readiness')
end
assert((hp.readiness:IsShown()==true)==('"""+cls+"""'~='DRUID'))
g.buttons.solo.scripts.OnClick(g.buttons.solo)
assert(BuffTap.buffsHelpersView==nil and not f.helpersPane:IsShown() and f.buffContent:IsShown(),'Solo returns to the list')
g.helpers.scripts.OnClick(g.helpers); f.scripts.OnHide(f)
assert(BuffTap.buffsHelpersView==nil,'closing the window resets the view')
""",locale)

test('Class helpers tab does nothing in combat',RECORD+"""
playerClass='WARLOCK'; BuffTap:Options(); local g=BuffTap.contextControls.buffs
combat=true; g.helpers.scripts.OnClick(g.helpers); combat=false
assert(BuffTap.buffsHelpersView==nil and not BuffTap.options.helpersPane:IsShown())
""")

test('Helpers page points to the Class helpers tab and opens it',RECORD+"""
playerClass='WARLOCK'; BuffTap:Options(); local hp=BuffTap.helperWindow
assert(hp.classHelpersTitle:GetText():lower()==BuffTap:Text('Class helpers'):lower())
assert(hp.classHelpersNote:GetText()==BuffTap:Text('These settings moved to My buffs, on the %s tab.',BuffTap:Text('Class helpers')))
hp.classHelpersOpen.scripts.OnClick(hp.classHelpersOpen)
assert(BuffTap.buffsHelpersView==true and BuffTap.options.activeTab==1 and BuffTap.options.helpersPane:IsShown())
""")

test('Class helpers tab keeps every setting key and value',RECORD+"""
playerClass='WARLOCK'; BuffTap:Options(); local hp=BuffTap.helperWindow; local g=BuffTap.contextControls.buffs
g.helpers.scripts.OnClick(g.helpers)
hp.petCheck:SetChecked(true); hp.petCheck.scripts.OnClick(hp.petCheck); assert(BuffTap.db.helperPet==true)
hp.soulCheck:SetChecked(true); hp.soulCheck.scripts.OnClick(hp.soulCheck); assert(BuffTap.db.helperSoulstone==true)
hp.checks.helperTracking:SetChecked(true); hp.checks.helperTracking.scripts.OnClick(hp.checks.helperTracking); assert(BuffTap.db.helperTracking==true)
hp.soulTarget.scripts.OnClick(hp.soulTarget); assert(hp.soulMenu:IsShown())
g.buttons.party.scripts.OnClick(g.buttons.party); assert(not hp.soulMenu:IsShown(),'menu closes with the tab')
""")

for cls in ('DRUID','WARLOCK','HUNTER','PALADIN','ROGUE','WARRIOR','MAGE','PRIEST','SHAMAN'):
 test('Tracking tab reachable for '+cls,RECORD+"""
playerClass='"""+cls+"""'; BuffTap:Options(); local f=BuffTap.options; local g=BuffTap.contextControls.buffs; local hp=BuffTap.helperWindow
assert(g.helpers and g.helpers:GetText()~='' ,'tab button exists')
assert(f.pages[1].classEmpty.shown~=true and f.pages[1].classHidden==nil,'My buffs page is not replaced by the empty card')
g.helpers.scripts.OnClick(g.helpers)
assert(BuffTap.buffsHelpersView==true and f.helpersPane:IsShown(),'pane opens')
assert(hp.helperSections.tracking:GetParent()==f.helpersPane and hp.checks.helperTracking,'tracking controls are in the pane')
assert(f.pages[1].classEmpty.shown~=true and f.pages[1].classHidden==nil,'still not replaced with the pane open')
BuffTap.buffsHelpersView=nil; BuffTap:Options(); BuffTap.options.activeTab=nil
hp=BuffTap.helperWindow
hp.classHelpersOpen.scripts.OnClick(hp.classHelpersOpen)
assert(BuffTap.buffsHelpersView==true and BuffTap.options.activeTab==1 and BuffTap.options.helpersPane:IsShown(),'Helpers pointer opens the tab')
""")

for cls in ('DRUID','WARLOCK','HUNTER','PALADIN','ROGUE','WARRIOR','MAGE','PRIEST','SHAMAN'):
 test('My buffs compact layout '+cls,RECORD+"""
playerClass='"""+cls+"""'; BuffTap:Options(); local f=BuffTap.options; local g=BuffTap.contextControls.buffs; local hp=BuffTap.helperWindow
local compact=BuffTap:MyBuffsCompact()
assert(compact==(not BuffTap:HasPersonalReminderBuffs()))
if """+('true' if cls=='ROGUE' else 'false')+""" then assert(compact,'Rogue has no aura buffs') end
if compact then
  assert(BuffTap.buffsHelpersView==true and f.helpersPane:IsShown() and not f.buffContent:IsShown(),'Tracking fills the page')
  for _,b in pairs(g.buttons) do assert(not b:IsShown(),'Solo/Party/Raid hidden') end
  assert(not g.helpers:IsShown() and not g.reset:IsShown(),'tab strip hidden')
  assert(f.pageHeaders[1].description:GetText()==BuffTap:Text('This class has no aura buffs to remind. Tracking is below.'),'subtitle explains')
  assert(hp.helperSections.tracking:GetParent()==f.helpersPane and hp.checks.helperTracking,'tracking controls present')
else
  assert(not BuffTap.buffsHelpersView and f.buffContent:IsShown() and not f.helpersPane:IsShown(),'full layout keeps the buff list')
  for _,b in pairs(g.buttons) do assert(b:IsShown(),'pills shown') end
  assert(g.helpers:IsShown(),'tab shown')
end
""")

# 1.28.1 talent probe: the Full check-up reports what the client offers, without raising.
test('Spec probe reports missing talent calls without error',RECORD+"""
local lines=BuffTap:SpecProbeLines(); local text=table.concat(lines,'\\n')
assert(text:find('Read%-only probe'),'header'); assert(text:find('C_SpecializationInfo.GetActiveSpecGroup'),'lists active group call')
assert(text:find('Events seen this session'),'lists events')
local check=table.concat(BuffTap:CheckupLines(),'\\n'); assert(check:find('== Talents and spec =='),'in the full check-up')
""")
test('Spec probe reads spec groups and records events',RECORD+"""
function GetNumSpecGroups() return 2 end
C_SpecializationInfo=C_SpecializationInfo or {}
function C_SpecializationInfo.GetActiveSpecGroup() return 2 end
function C_SpecializationInfo.GetSpecialization(_,_,group) return group==1 and 1 or 3 end
function C_SpecializationInfo.GetSpecializationInfo(index) return 260+index,'Spec'..index,'a','b','DAMAGER' end
function C_SpecializationInfo.GetCombatConfigIDForSpecGroup(group) return 900+group end
local text=table.concat(BuffTap:SpecProbeLines(),'\\n')
assert(text:find('GetNumSpecGroups = 2'),text); assert(text:find('GetActiveSpecGroup = 2'),text)
assert(text:find('Group 1: spec index 1 = 261, Spec1, DAMAGER'),text); assert(text:find('Group 2: spec index 3 = 263, Spec3'),text)
assert(text:find('config 902'),text)
""")
