from test_context_targets import test, tests, ROOT, solo
from test_blessings import setup

test('Same player expansion button collapses the open class',setup+"BuffTap:Options(); local f=BuffTap.options; local btn=f.blessingRows[1].players; btn.scripts.OnClick(btn); assert(f.expandedBlessing=='WARRIOR' and f.blessingDetail.shown); btn.scripts.OnClick(btn); assert(not f.expandedBlessing and not f.blessingDetail.shown)")
test('Explicit collapse closes player exceptions',setup+"BuffTap:Options(); local f=BuffTap.options; f.expandedBlessing='WARRIOR'; BuffTap:Options(); f.blessingCollapse.scripts.OnClick(f.blessingCollapse); assert(not f.expandedBlessing and not f.blessingDetail.shown)")
test('Same blessing dropdown click closes its menu',setup+"BuffTap:Options(); local p=BuffTap.options.blessingRows[1].pick; p.scripts.OnClick(p); assert(BuffTap.options.blessingMenu.shown); p.scripts.OnClick(p); assert(not BuffTap.options.blessingMenu.shown)")
test('Opening another dropdown changes menu owner',setup+"BuffTap:Options(); local f=BuffTap.options; local a=f.blessingRows[1].pick; local b=f.blessingRows[2].pick; a.scripts.OnClick(a); b.scripts.OnClick(b); assert(f.blessingMenu.shown and f.blessingMenu.owner==b)")
test('Class editor opens directly and checks retain saved fixed choice',setup+"BuffTap:Options(); local f=BuffTap.options; local p=f.blessingRows[1].pick; p.scripts.OnClick(p); assert(f.blessingMenu.priorityRows[1].toggle.checked and BuffTap.db.blessingClasses.WARRIOR=='bom'); local k=f.blessingMenu.priorityRows[2].toggle; k.scripts.OnClick(k); assert(BuffTap.db.blessingClasses.WARRIOR=='priority' and #BuffTap.db.groupBlessingPriorities.WARRIOR==2 and f.blessingMenu.shown)")
test('Inactive group assignment controls cannot open or change',setup+"BuffTap.db.blessingAssignments=false; BuffTap:Options(); local f=BuffTap.options; local p=f.blessingRows[1].pick; assert(p.disabled); p.scripts.OnClick(p); assert(not f.blessingMenu or not f.blessingMenu.shown); f.blessingRows[1].players.scripts.OnClick(); assert(not f.expandedBlessing)")
test('Party switch also disables class assignment controls',setup+"BuffTap.db.group=false; BuffTap:Options(); assert(BuffTap.options.blessingRows[1].pick.disabled)")
test('One player expansion hides unnecessary paging',setup+"BuffTap:Options(); BuffTap.options.expandedBlessing='WARRIOR'; BuffTap:Options(); assert(not BuffTap.options.blessingScroll.shown)")
test('Target picker shares proper arrow and selected row behavior',solo+"BuffTap:Options(); local f=BuffTap.options; local p=f.targetBlessingPicks[5]; assert(p.arrow.texture and not p:GetText():find(' v')); p.scripts.OnClick(p); assert(f.blessingMenu.priorityRows[1].shown and not next(BuffTap.db.targetBlessingPriorities)); p.scripts.OnClick(p); assert(not f.blessingMenu.shown)")
test('Target picker inactive when friendly-target mode disabled',solo+"BuffTap.db.friendlyTarget=false; BuffTap:Options(); local p=BuffTap.options.targetBlessingPicks[5]; p.scripts.OnClick(p); assert(p.disabled and (not BuffTap.options.blessingMenu or not BuffTap.options.blessingMenu.shown))")
test('Target picker inactive when class-aware mode disabled',solo+"BuffTap.db.targetClassBlessings=false; BuffTap:Options(); assert(BuffTap.options.targetBlessingPicks[5].disabled)")
test('Changing tabs closes blessing menu',setup+"BuffTap:Options(); local f=BuffTap.options; f.blessingRows[1].pick.scripts.OnClick(f.blessingRows[1].pick); f.selectTab(3); assert(not f.blessingMenu.shown)")
test('Combat cannot open a blessing menu',setup+"BuffTap:Options(); local p=BuffTap.options.blessingRows[1].pick; combat=true; p.scripts.OnClick(p); assert(not BuffTap.options.blessingMenu or not BuffTap.options.blessingMenu.shown)")
for loc in ['esES','deDE','frFR','ptBR']:
 test('Blessing selection labels localized '+loc,setup+"BuffTap:Options(); assert(BuffTap:Text('Follow buff settings')~='Follow buff settings'); assert(BuffTap:Text('Enable class assignments')~='Enable class assignments')",locale=loc)
test('Two-player exception details remain inside the page',setup+"""
classes.party2='WARRIOR'; BuffTap:InvalidateRoster()
local original=CreateFrame
CreateFrame=function(...)
 local f=original(...); f.SetSize=function(self,w,h) self.width=w; self.height=h end
 f.SetHeight=function(self,h) self.height=h end
 f.SetPoint=function(self,...) local p={...}; if p[1]=='TOPLEFT' then self.points=p end end
 return f
end
BuffTap:Options(); local f=BuffTap.options; f.expandedBlessing='WARRIOR'; BuffTap:Options()
assert(f.blessingDetail.height==202)
for _,row in ipairs(f.blessingRows) do assert(-row.points[3]+row.height<574) end
assert(not f.blessingScroll.shown)
""")
test('Every Paladin seal is opt-in by default',"playerClass='PALADIN'; for _,def in ipairs(BuffTap:ClassList()) do if def.kind=='seal' then assert(not def.defaultOn and not BuffTap:Enabled(def),def.key) end end")
test('An explicitly enabled seal remains supported',"playerClass='PALADIN'; spells={}; book={}; spell(21084,'Seal of Righteousness',1); BuffTap.db.buffs['seal-righteousness']=true; refresh(); assert(BuffTap.action.key=='seal-righteousness'); BuffTap:InitDB(); assert(BuffTap.db.buffs['seal-righteousness']==true)")
test('Paladin tactical spells never enter the maintenance catalog',"local excluded={['Consecration']=true,['Judgement']=true,['Blessing of Freedom']=true,['Blessing of Protection']=true,['Blessing of Sacrifice']=true,['Divine Shield']=true}; for _,def in ipairs(BuffTap.Buffs) do if def.class=='PALADIN' then assert(not excluded[def.name],def.name) end end")
print('ALL',len(tests),'SCENARIOS PASSED')
