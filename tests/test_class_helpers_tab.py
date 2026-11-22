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
