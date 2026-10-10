from test_tracking import test,tests
from test_blessings import setup
test('Own planned exception survives repeated solo refreshes',setup+"GetNumSubgroupMembers=function() return 0 end; BuffTap:InvalidateRoster(); BuffTap:SetBlessingPlayer({unit='player'},'bow',true); refresh(); refresh(); local v=BuffTap.blessingPlayers[UnitGUID('player')]; assert(v.choice=='bow' and v.neverSalvation)")
test('Leaving group retains self but removes other session exceptions',setup+"BuffTap:SetBlessingPlayer({unit='player'},'bok',false); BuffTap:SetBlessingPlayer({unit='party1'},'bow',true); GetNumSubgroupMembers=function() return 0 end; BuffTap:InvalidateRoster(); refresh(); assert(BuffTap.blessingPlayers[UnitGUID('player')].choice=='bok' and not BuffTap.blessingPlayers[UnitGUID('party1')])")
test('Self exception takes precedence after rejoining',setup+"BuffTap:SetBlessingPlayer({unit='player'},'bow',false); GetNumSubgroupMembers=function() return 0 end; refresh(); GetNumSubgroupMembers=function() return 2 end; BuffTap:InvalidateRoster(); assert(BuffTap:BlessingChoice({unit='player',class='PALADIN',group=1})=='bow')")
raid=setup+"""
IsInRaid=function() return true end; GetNumGroupMembers=function() return 40 end
UnitExists=function() return true end; UnitIsUnit=function(a,b) return a==b or (a=='raid1' and b=='player') end
GetRaidRosterInfo=function(i) return 'Raider'..i,0,math.ceil(i/5) end
UnitClass=function() return 'Paladin','PALADIN' end
BuffTap:InvalidateRoster(); BuffTap:Options(); local f=BuffTap.options; f.expandedBlessing='PALADIN'; BuffTap:Options()
"""
test('Forty same-class players reach final five by mouse wheel',raid+"for i=1,30 do f.blessingDetail.scripts.OnMouseWheel(nil,-1) end; assert(f.blessingPlayerOffset==35 and f.blessingPlayerRows[1].entry.unit=='raid36' and f.blessingPlayerRows[5].entry.unit=='raid40'); f.blessingDetail.scripts.OnMouseWheel(nil,100); assert(f.blessingPlayerOffset==0)")
test('Scrollbar reaches individual hybrid recipient without changing another',raid+"f.blessingScroll.scripts.OnValueChanged(f.blessingScroll,20); local entry=f.blessingPlayerRows[3].entry; assert(entry.unit=='raid23'); BuffTap:SetBlessingPlayer(entry,'bow',true); f.blessingScroll.scripts.OnValueChanged(f.blessingScroll,0); assert(not BuffTap.blessingPlayers[UnitGUID('raid3')]); f.blessingScroll.scripts.OnValueChanged(f.blessingScroll,20); assert(f.blessingPlayerRows[3].protect.checked and BuffTap.blessingPlayers[UnitGUID('raid23')].choice=='bow')")
test('Escape hiding editor clears expanded state',raid+"f.blessingDetail:Hide(); assert(not f.expandedBlessing)")
print('ALL',len(tests),'SCENARIOS PASSED')
