from test_supplies import test
from test_bufftap import tests, ROOT

setup='''
playerClass='PALADIN'; spells={}; book={}
spell(20217,'Blessing of Kings',20); spell(19740,'Blessing of Might',4); spell(19742,'Blessing of Wisdom',4)
spell(1038,'Blessing of Salvation',26); spell(19977,'Blessing of Light',40)
spell(25898,'Greater Blessing of Kings',60); spell(25782,'Greater Blessing of Might',52)
spell(25894,'Greater Blessing of Wisdom',54); spell(25895,'Greater Blessing of Salvation',60)
UnitLevel=function() return 60 end
classes={player='PALADIN',party1='WARRIOR',party2='PRIEST',target='WARRIOR'}
UnitClass=function(u) return 'Class',classes[u] end
BuffTap.db.group=true; BuffTap.db.blessingAssignments=true
BuffTap.db.blessingClasses={PALADIN='skip',WARRIOR='bom',PRIEST='bow'}
bags[21177]=20
refresh()
'''

test('Assignments default off preserve legacy settings', "assert(not BuffTap.db.blessingAssignments); assert(not next(BuffTap.db.blessingClasses))")
test('Different recipient classes resolve independently of global priority',setup+"assert(BuffTap.action.key=='bom' and BuffTap.action.target=='party1'); aura('party1',19740,'Blessing of Might'); refresh(); assert(BuffTap.action.key=='bow' and BuffTap.action.target=='party2')")
test('Healthy desired blessings never cycle to another family',setup+"aura('party1',19740,'Blessing of Might'); aura('party2',19742,'Blessing of Wisdom'); refresh(); assert(not BuffTap.action)")
test('Explicit choice works even when legacy buff toggle is off',setup+"BuffTap.db.buffs.bom=false; refresh(); assert(BuffTap.action.key=='bom')")
test('Unlearned explicit blessing never substitutes another blessing',setup+"spells[19740].known=false; BuffTap.bookDirty=true; BuffTap.db.blessingClasses.PRIEST='skip'; refresh(); assert(not BuffTap.action and BuffTap.db.blessingClasses.WARRIOR=='bom')")
test('Mixed same-class player exceptions forbid Greater',setup+"classes.party2='WARRIOR'; BuffTap:InvalidateRoster(); BuffTap:SetBlessingPlayer({unit='party2'},'bow',false); refresh(); assert(BuffTap.action.key=='bom' and not BuffTap.action.groupCast); aura('party1',19740,'Blessing of Might'); refresh(); assert(BuffTap.action.key=='bow' and not BuffTap.action.groupCast)")
test('Uniform class assignments permit reagent Greater',setup+"classes.party2='WARRIOR'; BuffTap:InvalidateRoster(); refresh(); assert(BuffTap.action.key=='gbom' and BuffTap.action.groupCast)")
test('Matching player exception does not block Greater',setup+"classes.party2='WARRIOR'; BuffTap:InvalidateRoster(); BuffTap:SetBlessingPlayer({unit='party2'},'bom',false); refresh(); assert(BuffTap.action.key=='gbom')")
test('Skipped affected player blocks Greater and preserves skip',setup+"classes.party2='WARRIOR'; BuffTap:InvalidateRoster(); BuffTap:SetBlessingPlayer({unit='party2'},'skip',false); refresh(); assert(BuffTap.action.key=='bom' and not BuffTap.action.groupCast); aura('party1',19740,'Blessing of Might'); refresh(); assert(not BuffTap.action)")
test('Tank protection prevents normal and Greater Salvation',setup+"classes.party2='WARRIOR'; BuffTap.db.blessingClasses.WARRIOR='bos'; BuffTap:InvalidateRoster(); BuffTap:SetBlessingPlayer({unit='party2'},nil,true); refresh(); assert(BuffTap.action.key=='bos' and BuffTap.action.target=='party1' and not BuffTap.action.groupCast); aura('party1',1038,'Blessing of Salvation'); refresh(); assert(not BuffTap.action)")
test('Group selection remains authoritative for explicit choices',setup+"BuffTap.db.raidGroups[1]=false; refresh(); assert(not BuffTap.action)")
test('Unknown class blocks affected Greater safety',setup+"local r={{unit='party1',class='WARRIOR',group=1},{unit='party2',group=1}}; assert(not BuffTap:BlessingGreaterSafe('bom','WARRIOR',r))")
test('Changed single player preference cancels prepared click',setup+"BuffTap.db.blessingClasses.WARRIOR='bow'; BuffTap.button.scripts.PreClick(nil,'LeftButton',false); assert(not BuffTap.action and not BuffTap.button.attrs.type1)")
test('Changed override cancels prepared Greater without substituting',setup+"classes.party2='WARRIOR'; BuffTap:InvalidateRoster(); refresh(); assert(BuffTap.action.groupCast); BuffTap:SetBlessingPlayer({unit='party2'},'bow',false); BuffTap.button.scripts.PreClick(nil,'LeftButton',false); assert(not BuffTap.action)")
test('Desired normal or Greater from another Paladin is coverage',setup+"aura('party1',25782,'Greater Blessing of Might'); auras.party1[1].sourceUnit='party2'; aura('party2',19742,'Blessing of Wisdom'); auras.party2[1].sourceUnit='other'; refresh(); assert(not BuffTap.action)")
test('Only one player missing uses normal not reagent recast',setup+"classes.party2='WARRIOR'; BuffTap:InvalidateRoster(); aura('party1',25782,'Greater Blessing of Might'); refresh(); assert(BuffTap.action.key=='bom' and BuffTap.action.target=='party2' and not BuffTap.action.groupCast)")
test('Solo personal behavior ignores group class choices',setup+"GetNumSubgroupMembers=function() return 0 end; BuffTap:InvalidateRoster(); refresh(); assert(not BuffTap:BlessingAssignmentsActive() and BuffTap.action.key=='bok' and BuffTap.action.target=='player')")
test('Ungrouped explicit target retains target priorities',setup+"BuffTap.db.friendlyTarget=true; BuffTap.db.buffs.bom=true; BuffTap.db.buffs.bok=false; BuffTap.db.priorities.bom=1; refresh(); assert(BuffTap.action.quickTarget and BuffTap.action.key=='bom')")
test('Grouped friendly target uses same recipient assignment',setup+"BuffTap.db.friendlyTarget=true; UnitGUID=function(u) return 'Player-'..(u=='target' and 'party2' or u) end; classes.target='PRIEST'; refresh(); assert(BuffTap.action.quickTarget and BuffTap.action.key=='bow')")
test('Exception identity does not follow recycled party token',setup+"BuffTap:SetBlessingPlayer({unit='party1'},'bow',false); UnitGUID=function(u) return 'New-'..u end; refresh(); assert(BuffTap.action.key=='bom')")
test('Leaving group clears session exceptions',setup+"BuffTap:SetBlessingPlayer({unit='party1'},'bow',false); GetNumSubgroupMembers=function() return 0 end; BuffTap:InvalidateRoster(); refresh(); assert(not BuffTap.blessingPlayers)")
test('Assignment settings sanitize invalid classes and families',setup+"BuffTap.db.blessingClasses={WARRIOR='invalid',UNKNOWN='bom',PRIEST=12,DRUID='skip'}; BuffTap:InitDB(); assert(not BuffTap.db.blessingClasses.WARRIOR and not BuffTap.db.blessingClasses.UNKNOWN and not BuffTap.db.blessingClasses.PRIEST and BuffTap.db.blessingClasses.DRUID=='skip')")
test('Options displays class table and inline players',setup+"BuffTap:Options(); local f=BuffTap.options; assert(f.blessingPanel.shown and not f.legacyGroups.shown and #f.blessingRows==9); f.expandedBlessing='WARRIOR'; BuffTap:Options(); assert(f.blessingDetail.shown and f.blessingPlayerRows[1].guid=='Player-party1')")
test('Class dropdown inherit clears explicit preference',setup+"BuffTap:Options(); local f=BuffTap.options; f.blessingRows[1].pick.scripts.OnClick(f.blessingRows[1].pick); local option=f.blessingMenu.priorityAutomatic; option.scripts.OnClick(option); assert(BuffTap.db.blessingClasses.WARRIOR==nil)")
test('Player dropdown inherit preserves tank protection',setup+"BuffTap:SetBlessingPlayer({unit='party1'},'bow',true); BuffTap:Options(); local f=BuffTap.options; f.expandedBlessing='WARRIOR'; BuffTap:Options(); local pick=f.blessingPlayerRows[1].pick; pick.scripts.OnClick(pick); f.blessingMenu.rows[1].scripts.OnClick(f.blessingMenu.rows[1]); assert(BuffTap.blessingPlayers['Player-party1'].choice==nil and BuffTap.blessingPlayers['Player-party1'].neverSalvation)")
test('Combat cannot change player exception',setup+"combat=true; BuffTap:SetBlessingPlayer({unit='party1'},'bow',true); assert(not BuffTap.blessingPlayers)")
test('No inspection chat or polling introduced by assignments',setup+"BuffTap:CancelWakeTimer(); BuffTap:CancelRefreshTimer(); assert(not BuffTap.events.registered.INSPECT_READY and not BuffTap.events.registered.CHAT_MSG_ADDON); assert(not BuffTap.button.scripts.OnUpdate)")


test('Explicit threshold supersedes retained legacy per-family threshold',setup+"classes.party2='WARRIOR'; BuffTap.db.buffGroupNeed.bom=5; BuffTap:InvalidateRoster(); refresh(); assert(BuffTap.action.groupCast and BuffTap.action.key=='gbom')")
test('Inherited class choice selects learned legacy family',setup+"BuffTap.db.blessingClasses.WARRIOR=nil; BuffTap.db.buffs.bom=true; spells[20217].known=false; BuffTap.bookDirty=true; refresh(); assert(BuffTap.action.key=='bom')")
test('Unlearned dropdown remains selectable and is clearly marked',setup+"spells[19740].known=false; BuffTap:Options(); local pick=BuffTap.options.blessingRows[1].pick; pick.scripts.OnClick(pick); assert(BuffTap.options.blessingMenu.priorityRows[1].note.text:find('not learned'))")
test('Page switching closes blessing dropdown',setup+"BuffTap:Options(); local f=BuffTap.options; f.blessingRows[1].pick.scripts.OnClick(f.blessingRows[1].pick); assert(f.blessingMenu.shown); f.selectTab(3); assert(not f.blessingMenu.shown)")
test('Turning assignments off cancels stale explicit action',setup+"BuffTap.db.blessingAssignments=false; BuffTap.button.scripts.PreClick(nil,'LeftButton',false); assert(not BuffTap.action)")
test('Other classes retain original Groups controls',"BuffTap:Options(); assert(not BuffTap.options.blessingPanel.shown and BuffTap.options.legacyGroups.shown)")
test('Clear exception restores class assignment',setup+"BuffTap:SetBlessingPlayer({unit='party1'},'bow',false); BuffTap:SetBlessingPlayer({unit='party1'},nil,false); refresh(); assert(BuffTap.action.key=='bom')")
test('Empty reagent bag uses normal spell instead of unusable Greater',setup+"classes.party2='WARRIOR'; bags[21177]=0; BuffTap:InvalidateRoster(); refresh(); assert(BuffTap.action.key=='bom' and not BuffTap.action.groupCast)")
test('Combat group exit clears session exceptions',setup+"BuffTap:SetBlessingPlayer({unit='party1'},'bow',false); combat=true; GetNumSubgroupMembers=function() return 0 end; BuffTap.events.scripts.OnEvent(nil,'GROUP_ROSTER_UPDATE'); assert(not BuffTap.blessingPlayers)")
test('Expanded class rows and footer fit the panel without overlapping',setup+'''
local original=CreateFrame
CreateFrame=function(...)
 local frame=original(...); local size=frame.SetSize
 frame.SetSize=function(self,w,h) self.width=w; self.height=h; size(self,w,h) end
 frame.SetHeight=function(self,h) self.height=h end
 frame.SetPoint=function(self,...) local p={...}; if p[1]=="TOPLEFT" then self.points=p end end
 return frame
end
BuffTap:Options(); local f=BuffTap.options; f.expandedBlessing='WARRIOR'; BuffTap:Options()
assert(f.height==868 and f.blessingDetail.height==78)
for _,row in ipairs(f.blessingRows) do assert(-row.points[3]+row.height<574) end
assert(#f.blessingPlayerRows==2)
''')
test('Large class roster pages all players inside fixed expansion',setup+'''
IsInRaid=function() return true end; GetNumGroupMembers=function() return 10 end
UnitExists=function() return true end
UnitIsUnit=function(a,b) return a==b or (a=='raid1' and b=='player') end
GetRaidRosterInfo=function() return 'Name',0,1 end
UnitClass=function(u) return 'Class',u=='player' or u=='raid1' and 'PALADIN' or 'SHAMAN' end
-- Supply explicit tokens: no reliance on truthy boolean class values.
UnitClass=function(u) if u=='player' or u=='raid1' then return 'Paladin','PALADIN' end; return 'Shaman','SHAMAN' end
BuffTap.db.blessingClasses.SHAMAN='bok'; BuffTap:InvalidateRoster(); BuffTap:Options()
local f=BuffTap.options; f.expandedBlessing='SHAMAN'; f.blessingPlayerOffset=100; BuffTap:Options()
assert(f.blessingPlayerOffset==8 and f.blessingPlayerRows[1].entry.unit=='raid10' and not f.blessingPlayerRows[2].shown)
''')

test('Header navigation fits between borders and stays above page content',setup+"""
local original=CreateFrame
CreateFrame=function(...)
 local frame=original(...)
 frame.SetSize=function(self,w,h) self.width=w; self.height=h end
 frame.SetHeight=function(self,h) self.height=h end
 frame.SetPoint=function(self,...) local p={...}; if p[1]=="TOPLEFT" then self.points=p end end
 return frame
end
BuffTap:Options(); local f=BuffTap.options
local previousRight=18
for _,tab in ipairs(f.tabs) do
 local x,y=tab.points[2],tab.points[3]
 assert(x>=previousRight+6 and x+tab.width<=f.width-24)
 assert(-y+tab.height< -f.pages[1].points[3])
 previousRight=x+tab.width
end
assert(f.tabs[4].width>f.tabs[1].width and f.tabs[6].width>f.tabs[5].width)
assert(f.height-206-32==630) -- Preserve the existing page area.
""")
test('Header Close hides options and all tabs still select their own page',setup+"""
BuffTap:Options(); local f=BuffTap.options
for i,tab in ipairs(f.tabs) do tab.scripts.OnClick(tab); assert(f.activeTab==i and f.pages[i].shown) end
assert(f.shown); f.closeButton.scripts.OnClick(f.closeButton); assert(not f.shown)
""")
test('Options scales the revised window inside a small screen',setup+"""
UIParent.GetWidth=function() return 700 end; UIParent.GetHeight=function() return 650 end
local original=CreateFrame
CreateFrame=function(...) local f=original(...); f.SetScale=function(self,s) self.scale=s end; return f end
BuffTap:Options(); local f=BuffTap.options
assert(f.scale*760<=668 and f.scale*868<=618)
""")

print(f'ALL {len(tests)} SCENARIOS PASSED')
(ROOT/'tests/last-run-blessings.txt').write_text('\n'.join('PASS '+name for name in tests)+f'\n\n{len(tests)} mocked Lua 5.1 scenarios passed. In-game casting/visual checks pending.\n')

