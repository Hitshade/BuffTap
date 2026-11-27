from test_bufftap import test
from test_combat_cleanse import NATIVE

GRID=NATIVE+r'''
playerClass='PRIEST'; spell(527,'Dispel Magic'); spell(528,'Cure Disease')
B.db.cleanseEnabled=true; B.db.combatCleanseGroup=true
local function setup() B:SyncCombatGrid(); assert(B.combatGridFrame and not B.combatGridError,B.combatGridError) end
'''

test('Grid defaults are compact and roster mode is opt-in',"""
local B=BuffTap; local g=B:CombatGridSettings()
assert(B.db.combatCleanseGroup==false and g.size==20 and g.gap==3 and g.subgroup and not g.follow)
assert(not B.combatGridFrame)
""")

for size in [18,20,64]:
    for direction in ['right-down','down-right','left-down','right-up']:
        test(f'Grid 40-slot bounds cover every tile at {size}px, {direction}',f"""
local B=BuffTap; B.db.combatGrid={{size={size},direction='{direction}',gap=3}}
local g=B:CombatGridSettings(); local l=B:CombatGridLayout(40,g); assert(#l.slots==40)
local seen={{}}
for _,p in ipairs(l.slots) do
  assert(p.x>=l.minX and p.x+g.size<=l.minX+l.width)
  assert(p.y<=l.maxY and p.y-g.size>=l.maxY-l.height)
  local k=p.x..':'..p.y; assert(not seen[k]); seen[k]=true
end
assert(l.slots[1].x==0 and l.slots[1].y==0)
""")

test('Grid compact dimensions include subgroup gaps exactly',"""
local B=BuffTap; B.db.combatGrid={size=20,gap=3,subgroup=false,columns=5}
local l=B:CombatGridLayout(40); assert(l.width==112 and l.height==181)
B.db.combatGrid.subgroup=true; l=B:CombatGridLayout(40); assert(l.width==112 and l.height==223)
assert(B:CombatGridLayout(5).slots[1].x==l.slots[1].x)
""")

test('Grid invalid settings are bounded without corrupting saved choices',"""
local B=BuffTap; B.db.combatGrid={size=1,gap=100,columns=0,direction='nonsense',idleColor={false,9,-1}}
local g=B:CombatGridSettings(); assert(g.size==18 and g.gap==12 and g.columns==1 and g.direction=='right-down')
assert(g.idleColor[1]==.25 and g.idleColor[2]==1 and g.idleColor[3]==0)
assert(B.db.combatGrid.size==1)
""")

test('Grid prepares 45 fixed tokens, with matching native aura units and exclusive visibility',GRID+'''
setup(); local f=B.combatGridFrame; assert(#f.buttons==45 and #nativeContainers==45)
for i,b in ipairs(f.buttons) do
  local u=i<=40 and 'raid'..i or i==41 and 'player' or 'party'..(i-41)
  assert(b.unitToken==u and b.attrs.unit==u and b.container.unit==u)
  assert(b.attrs['*spell1']==527 and b.attrs['*spell2']==528 and b.attrs.useOnKeyDown==false)
  assert(b.driver=='[group:'..(i<=40 and 'raid' or 'party')..',@'..u..',exists] show; hide')
  for _,slot in pairs(b.container.slots) do assert(not slot.button.mouse and not slot.button.attrs.type1) end
end
''')

test('Grid roster visibility conditions admit occupied slots only for their own group mode',GRID+'''
setup()
for _,mode in ipairs({'solo','party','raid'}) do
  local present={player=true,party1=true,party2=true,raid1=true,raid2=true,raid3=true,raid4=true,raid5=true,raid6=true}
  local shown=0
  -- Verify emitted driver's group and exists conditions, not Blizzard's actual secure engine.
  for _,b in ipairs(B.combatGridFrame.buttons) do
    local group,unit=b.driver:match('%[group:(%a+),@([%w]+),exists%] show; hide')
    assert(group and unit==b.unitToken)
    if group==mode and present[unit] then shown=shown+1 end
  end
  assert(shown==(mode=='solo' and 0 or mode=='party' and 3 or 6))
end
''')

test('Grid subgroup allocation leaves every absent future token a unique reserved slot',GRID+'''
UnitExists=function(u) return u=='raid1' or u=='raid2' or u=='raid3' end
GetRaidRosterInfo=function(i) return 'Member '..i,0,i==1 and 8 or 1 end
local positions=B:CombatGridRaidPositions(B:CombatGridSettings())
assert(positions[1]==36 and positions[2]==1 and positions[3]==2)
local seen={}; for i=1,40 do local n=positions[i]; assert(n>=1 and n<=40 and not seen[n]); seen[n]=true end
setup(); assert(B.combatGridFrame.buttons[1].gridSlot==36)
''')

test('Grid does not move, rebuild or retarget in combat; roster layout updates afterward',GRID+'''
local group=1
UnitExists=function(u) return u=='raid1' or u=='raid2' end
GetRaidRosterInfo=function(i) return 'Player '..i,0,group end
setup(); local f=B.combatGridFrame; local first=f.buttons[1]; local old=first.gridSlot; local writes=nativeWrites
combat=true; group=8
B.combatGridEvents.scripts.OnEvent(nil,'GROUP_ROSTER_UPDATE'); B:SyncCombatGrid()
assert(B.combatGridFrame==f and first.gridSlot==old and nativeWrites==writes and first.attrs.unit=='raid1')
combat=false; B.combatGridEvents.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); advance(.2)
assert(B.combatGridFrame==f and first.gridSlot==36 and first.attrs.unit=='raid1')
''')

test('Grid disabling is immediate even with a pending appearance update',GRID+'''
setup(); local f=B.combatGridFrame
B:SetCombatGridSetting('size',32); assert(B.combatGridSyncPending)
B.db.combatCleanseGroup=false; B:SyncCombatGrid()
assert(not B.combatGridFrame and not f.shown)
for _,b in ipairs(f.buttons) do assert(not b.shown and not b.driver and not b.container.enabled) end
''')

test('Grid edit preview is non-casting and always contains all 40 actual-size tiles',GRID+'''
B.db.combatGrid={size=18,gap=2,subgroup=false,columns=8}
B:ShowCombatGridEditPreview(); local f=B.editCombatGrid; local l=B:CombatGridLayout(40)
assert(f.shown and #f.cells==40 and f.width==l.width and f.height==l.height and f.layout.slots[40])
for _,cell in ipairs(f.cells) do assert(cell.width==18 and cell.height==18 and not cell.protected and not cell.attrs.type1) end
assert(not f.protected and not f.attrs.type1)
combat=true; B.combatGridEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); assert(not f.shown)
''')

test('Grid mover saves the logical origin and turns off following without changing main position',GRID+'''
B.db.x=123; B.db.y=45; B.db.combatGrid={direction='left-down',follow=true}
B:ShowCombatGridEditPreview(); local f=B.editCombatGrid
UIParent.GetCenter=function() return 500,400 end
f.GetLeft=function() return 200 end; f.GetTop=function() return 300 end
f.savePosition(f)
assert(B.db.combatGrid.x==200-500-f.layout.minX and B.db.combatGrid.y==300-400-f.layout.maxY)
assert(not B.db.combatGrid.follow and B.db.x==123 and B.db.y==45)
''')

test('Grid Edit Mode integration shows and hides the full preview even while solo',GRID+'''
B:SetEditModeActive(true); assert(B.editCombatGrid and B.editCombatGrid.shown and #B.editCombatGrid.cells==40)
B:SetEditModeActive(false); assert(not B.editCombatGrid.shown)
''')

test('Grid tabs separate settings and keep original cleanse/revive controls usable',GRID+'''
B:Options(); local f=B.options
assert(f.cleansePanes.cleansing.shown and not f.cleansePanes.combat.shown)
B:SetCleanseView('combat'); assert(f.cleansePanes.combat.shown and not f.cleansePanes.cleansing.shown)
assert(f.combatCleanse:GetParent()==f.cleansePanes.combat)
assert(f.combatGridUI.enabled:GetParent()==f.cleansePanes.combat and #f.combatGridUI.preview.cells==40)
assert(f.reviveEnable:GetParent()==f.cleanseRevivePane)
assert(f.cleanseInput:GetParent()==f.cleanseNeverPane and not f.cleansePanes.never)
B:SetCleanseView('cleansing'); assert(f.cleanseBorder:GetParent()==f.cleansePanes.cleansing)
''')

test('Grid never mutates the regular reminder binding or action',GRID+'''
local action=B.action; local binding=bindings.MOUSEWHEELDOWN
setup(); B:ShowCombatGridEditPreview()
assert(B.action==action and bindings.MOUSEWHEELDOWN==binding)
''')

test('Grid slider changes debounce native rebuilds while layout changes reuse prepared buttons',GRID+'''
setup(); local f=B.combatGridFrame
B:SetCombatGridSetting('gap',6); advance(.2)
assert(B.combatGridFrame==f and f.layout.slots[2].x==26)
B:SetCombatGridSetting('size',24); B:SetCombatGridSetting('size',28)
assert(B.combatGridFrame==f)
advance(.2); assert(B.combatGridFrame~=f and B.combatGridFrame.buttons[1].width==28)
assert(not f.shown and not f.buttons[1].container.enabled)
''')

test('Grid master switch and missing learned spell retire prepared buttons',GRID+'''
setup(); local f=B.combatGridFrame
B.db.cleanseEnabled=false; B:SyncCombatGrid(); assert(not B.combatGridFrame and not f.shown)
B.db.cleanseEnabled=true; B.db.cleanseTypes.Magic=false; B.db.cleanseTypes.Disease=false
B:SyncCombatGrid(); assert(not B.combatGridFrame and B.combatGridError)
''')

test('Grid refuses combat settings changes and observes the fixed clicked unit only',GRID+'''
setup(); local b=B.combatGridFrame.buttons[43]; local g=B:CombatGridSettings(); local writes=nativeWrites
combat=true; assert(B:SetCombatGridSetting('size',64)==false)
b.scripts.PostClick(b,'RightButton',false)
assert(B:CombatGridSettings().size==g.size and nativeWrites==writes)
assert(B.combatCleanseLastUnit=='party2' and B.combatCleanseLastInput=='RightButton')
''')

test('Grid native setup error cleans up partial fixed buttons',GRID+'''
local configure=B.ConfigureCombatCleanseButton; local count=0; local partial
B.ConfigureCombatCleanseButton=function(self,root,...)
  count=count+1; partial=root
  configure(self,root,...)
  if count==3 then error('simulated native failure') end
end
B:SyncCombatGrid()
assert(not B.combatGridFrame and B.combatGridError:find('simulated native failure'))
assert(not partial.shown and not partial.driver and not partial.container.enabled)
''')

test('Grid move control has the usual Done bar and returns to Combat frames',GRID+'''
B:Options(); B:SetCleanseView('combat')
B.options.combatGridUI.move.scripts.OnClick()
assert(B.movingFrames and B.moveDoneBar.shown and B.editCombatGrid.shown)
B.moveDoneBar.done.scripts.OnClick()
assert(not B.movingFrames and not B.moveDoneBar.shown and not B.editCombatGrid.shown)
assert(B.cleanseView=='combat' and B.options.cleansePanes.combat.shown)
''')

test('Grid move Cancel restores its position and follow setting',GRID+'''
B.db.combatGrid={x=123,y=-45,follow=true}; B:MoveAllFrames('cleanse-combat')
B.db.combatGrid.x=777; B.db.combatGrid.y=888; B.db.combatGrid.follow=false
B:FinishMovingFrames(true)
assert(B.db.combatGrid.follow and B.db.combatGrid.x~=777 and B.db.combatGrid.y~=888)
assert(not B.editCombatGrid.shown)
''')

test('Grid and main-icon combat switches are independent, and both can coexist while grouped',GRID+'''
setup(); assert(not B.combatCleanseFrame)
B.db.combatCleanse=true; B:SyncCombatCleanse()
assert(B.combatCleanseFrame and B.combatGridFrame)
assert(B.combatCleanseFrame.driver=='[combat,nodead] show; hide')
B.db.combatCleanse=false; B:SyncCombatCleanse()
assert(not B.combatCleanseFrame and B.combatGridFrame)
''')
