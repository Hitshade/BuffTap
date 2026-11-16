from test_tracking import test,tests
from test_blessings import setup
test('Own planned exception survives repeated solo refreshes',setup+"GetNumSubgroupMembers=function() return 0 end; BuffTap:InvalidateRoster(); BuffTap:SetBlessingPlayer({unit='player'},'bow'); refresh(); refresh(); local v=BuffTap.blessingPlayers[UnitGUID('player')]; assert(v.choice=='bow')")
test('Leaving group retains self but removes other session exceptions',setup+"BuffTap:SetBlessingPlayer({unit='player'},'bok'); BuffTap:SetBlessingPlayer({unit='party1'},'bow'); GetNumSubgroupMembers=function() return 0 end; BuffTap:InvalidateRoster(); refresh(); assert(BuffTap.blessingPlayers[UnitGUID('player')].choice=='bok' and not BuffTap.blessingPlayers[UnitGUID('party1')])")
test('Self exception takes precedence after rejoining',setup+"BuffTap:SetBlessingPlayer({unit='player'},'bow'); GetNumSubgroupMembers=function() return 0 end; refresh(); GetNumSubgroupMembers=function() return 2 end; BuffTap:InvalidateRoster(); assert(BuffTap:BlessingChoice({unit='player',class='PALADIN',group=1})=='bow')")
raid=setup+"""
IsInRaid=function() return true end; GetNumGroupMembers=function() return 40 end
UnitExists=function() return true end; UnitIsUnit=function(a,b) return a==b or (a=='raid1' and b=='player') end
GetRaidRosterInfo=function(i) return 'Raider'..i,0,math.ceil(i/5) end
UnitClass=function() return 'Paladin','PALADIN' end
BuffTap:InvalidateRoster(); BuffTap:Options(); local f=BuffTap.options; f.expandedBlessing='PALADIN'; BuffTap:Options()
"""
test('Forty same-class players reach final five by mouse wheel',raid+"for i=1,30 do f.blessingDetail.scripts.OnMouseWheel(nil,-1) end; assert(f.blessingPlayerOffset==35 and f.blessingPlayerRows[1].entry.unit=='raid36' and f.blessingPlayerRows[5].entry.unit=='raid40'); f.blessingDetail.scripts.OnMouseWheel(nil,100); assert(f.blessingPlayerOffset==0)")
test('Scrollbar reaches individual hybrid recipient without changing another',raid+"f.blessingScroll.scripts.OnValueChanged(f.blessingScroll,20); local entry=f.blessingPlayerRows[3].entry; assert(entry.unit=='raid23'); BuffTap:SetBlessingPlayer(entry,'bow'); f.blessingScroll.scripts.OnValueChanged(f.blessingScroll,0); assert(not BuffTap.blessingPlayers[UnitGUID('raid3')]); f.blessingScroll.scripts.OnValueChanged(f.blessingScroll,20); assert(BuffTap:GetBlessingPlayer(UnitGUID('raid23'),'Raid').choice=='bow')")
test('Escape hiding editor clears expanded state',raid+"f.blessingDetail:Hide(); assert(not f.expandedBlessing)")
print('ALL',len(tests),'SCENARIOS PASSED')
test('Own blessing exception survives a reload (Misketadam report)',setup+"""BuffTap:SetBlessingPlayer({unit='player'},'bok')
BuffTap.blessingPlayers=nil; BuffTap:InitDB(); BuffTap:InvalidateRoster(); refresh()
local v=BuffTap:GetBlessingPlayer(UnitGUID('player')); assert(v and v.choice=='bok','own exception kept '..tostring(v and v.choice))
BuffTap:SetBlessingPlayer({unit='party1'},'bow'); BuffTap.blessingPlayers=nil
assert(not BuffTap:GetBlessingPlayer(UnitGUID('party1')),'others stay session-only')
BuffTap:SetBlessingPlayer({unit='player'},nil); assert(BuffTap.db.blessingSelf==nil,'clearing removes it')""")
test('Remembered exception survives a reload, Remove forgets it',setup+"""BuffTap:SetBlessingPlayer({unit='party1'},'bok')
BuffTap:SetBlessingRemember({unit='party1',class='WARRIOR'},true)
local g=UnitGUID('party1'); assert(BuffTap:IsBlessingRemembered(g))
BuffTap.blessingPlayers=nil; BuffTap:InitDB(); refresh()
local v=BuffTap:GetBlessingPlayer(g); assert(v and v.choice=='bok','kept '..tostring(v and v.choice))
BuffTap:SetBlessingPlayer({unit='party1'},'bow'); assert(BuffTap.db.blessingSaved[g].choice=='bow','edit updates saved')
BuffTap:SetBlessingRemember({unit='party1'},false); assert(not BuffTap:IsBlessingRemembered(g)); assert(BuffTap:GetBlessingPlayer(g).choice=='bow','unticking keeps session choice')
BuffTap:SetBlessingRemember({unit='party1'},true); BuffTap:ForgetBlessingPlayer(g); assert(BuffTap.db.blessingSaved==nil)""")
test('Remember needs an exception and leaving group keeps remembered',setup+"""BuffTap:SetBlessingRemember({unit='party1'},true); assert(not BuffTap:IsBlessingRemembered(UnitGUID('party1')))
BuffTap:SetBlessingPlayer({unit='party1'},'bok'); BuffTap:SetBlessingRemember({unit='party1'},true)
GetNumSubgroupMembers=function() return 0 end; BuffTap:InvalidateRoster(); refresh()
assert(BuffTap:GetBlessingPlayer(UnitGUID('party1')).choice=='bok')""")
test('Exceptions panel lists absent remembered players with Remove',raid.replace("f.expandedBlessing='PALADIN'","BuffTap.db.blessingSaved={['Player-9-0001']={choice='bok',name='Dunmar',class='PALADIN'}}; f.expandedBlessing='PALADIN'")+"""
f.blessingPlayerOffset=99; BuffTap:Options(); local found
for _,r in ipairs(f.blessingPlayerRows) do if r:IsShown() and r.entry and r.entry.absent then found=r end end
assert(found and found.forget:IsShown() and not found.remember:IsShown(),'absent row')
found.forget:GetScript("OnClick")(found.forget); assert(BuffTap.db.blessingSaved==nil)""")
test('Exception rows show realm and class colour',setup+"""UnitName=function(u) if u=='party1' then return 'Mizi','Doomhowl' end return 'Me' end
RAID_CLASS_COLORS={HUNTER={r=0.67,g=0.83,b=0.45}}
assert(BuffTap.FullUnitName('party1')=='Mizi Doomhowl'); assert(BuffTap.FullUnitName('player')=='Me')
local t=BuffTap.ClassColoredName('party1','HUNTER'); assert(t=='|cffabd473Mizi Doomhowl|r',t)""")
