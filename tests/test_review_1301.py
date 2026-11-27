from test_bufftap import test, ROOT
from test_combat_grid import GRID
from test_combat_cleanse import NATIVE

test('Review grid appearance changes do not allocate native frames or cosmetics',GRID+'''
setup(); local f=B.combatGridFrame; local containers,frames,textures,fonts=#nativeContainers,nativeFrames,nativeTextures,nativeFonts
for i=1,25 do
  B.db.combatGrid={size=18+i,gap=i%6,style=i%2==0 and 'modern' or 'classic',colors={Magic={i/30,.4,.8}}}
  B:SyncCombatGrid()
  assert(B.combatGridFrame==f and #f.buttons==45)
end
assert(#nativeContainers==containers and nativeFrames==frames and nativeTextures==textures and nativeFonts==fonts)
assert(f.buttons[1].container.slots.BUFFTAP_SELF_Magic.button.nativeBorder.customDispelColorMap.Magic.r==25/30)
''')

test('Review grid disable and reenable reuse the complete fixed-unit pool',GRID+'''
setup(); local f=B.combatGridFrame; local count=#nativeContainers; local frames=nativeFrames
for i=1,8 do
  B.db.combatCleanseGroup=false; B:SyncCombatGrid(); assert(not B.combatGridFrame)
  B.db.combatCleanseGroup=true; B:SyncCombatGrid(); assert(B.combatGridFrame==f)
end
assert(#nativeContainers==count and nativeFrames==frames)
''')

test('Review self appearance and position changes reuse one button and native container',NATIVE+'''
B.db.iconStyle='modern'; prepare('PRIEST',{527,528}); local f=B.combatCleanseFrame; local count,frames,textures,fonts=#nativeContainers,nativeFrames,nativeTextures,nativeFonts
for i=1,20 do B.db.x=i; B.db.y=-i; B.db.size=20+i; B.db.opacity=i/20; B.db.iconStyle=i%2==0 and 'modern' or 'classic'; B:SyncCombatCleanse() end
assert(B.combatCleanseFrame==f and #nativeContainers==count and nativeFrames==frames and nativeTextures==textures and nativeFonts==fonts)
local queries=nativeLookups; B.db.x=333; B.db.opacity=.25; B:SyncCombatCleanse(); assert(nativeLookups==queries)
local writes=nativeWrites; combat=true; f.scripts.PostClick(f,'LeftButton',false); assert(B.combatCleanseInputCount==1 and writes==nativeWrites)
''')

test('Review learned spells reuse containers and bound native slots across toggles',GRID+'''
B.db.cleanseTypes.Disease=false; setup(); local f=B.combatGridFrame; local frames=nativeFrames
B.db.cleanseTypes.Disease=true; B:SyncCombatGrid(); assert(B.combatGridFrame==f and nativeFrames==frames+45)
frames=nativeFrames
for i=1,10 do B.db.cleanseTypes.Disease=false; B:SyncCombatGrid(); B.db.cleanseTypes.Disease=true; B:SyncCombatGrid() end
assert(nativeFrames==frames and #nativeContainers==45)
spell(988,'Dispel Magic rank 2'); B:SyncCombatGrid()
assert(B.combatGridFrame==f and nativeFrames==frames and f.buttons[1].attrs['*spell1']==988)
B.db.cleanseTypes.Disease=false; B:SyncCombatGrid()
assert(not f.buttons[1].attrs['*spell2'] and f.buttons[1].container.slots.BUFFTAP_SELF_Disease.enabled==false)
''')

test('Review unchanged refresh skips raid reads and all grid anchor writes',GRID+'''
local reads=0; UnitExists=function(u) return u=='raid1' or u=='raid2' end
GetRaidRosterInfo=function(i) reads=reads+1; return 'Member '..i,0,1 end
setup(); local f=B.combatGridFrame; local before=reads; local placements=0
for _,b in ipairs(f.buttons) do local set=b.SetPoint; b.SetPoint=function(s,...) placements=placements+1; return set(s,...) end end
for i=1,15 do B:Refresh() end
assert(reads==before and placements==0)
B.combatGridEvents.scripts.OnEvent(nil,'GROUP_ROSTER_UPDATE'); advance(.2)
assert(reads>before and placements==45)
''')

test('Review roster changes in combat invalidate once and apply after combat',GRID+'''
setup(); local f=B.combatGridFrame; local old=f.layout; local frames=nativeFrames
combat=true; B.combatGridEvents.scripts.OnEvent(nil,'UNIT_NAME_UPDATE'); B:Refresh()
assert(f.layout==old and nativeFrames==frames)
combat=false; B.combatGridEvents.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); advance(.2)
assert(f.layout~=old and nativeFrames==frames)
''')

test('Review unexpected combat initialization records a note without touching native frames',NATIVE+'''
prepare('PRIEST',{527,528}); local slot=nativeSlots.BUFFTAP_SELF_Magic
local writes=nativeWrites; combat=true
slot.options.initializeFrame(setmetatable({},{__index=function() error('native callback touched a secret frame') end}))
assert(B.combatCleanseLateInitialization and nativeWrites==writes)
assert(table.concat(B:CombatCleanseProbeLines(),' '):find('late initialization=true',1,true))
''')

for family in ['ferocity','utility']:
    for legacy in [False,True]:
        test(f'Review {family} status uses family location instead of legacy {legacy}',f'''
local B=BuffTap; local family=B:ConsumableFamily('{family}'); assert(family and family.multi)
B.db.consumablesEnabled=true; B.db.consumablesInstanceOnly={str(legacy).lower()}
B.db.consumableFamilies[family.key]=true; B.db.consumableLocations[family.key]='instances'
IsInInstance=function() return false,'none' end
assert(B:ConsumableChecklistExplanation(family):find('outside dungeons',1,true))
B.db.consumableLocations[family.key]='everywhere'
assert(not B:ConsumableChecklistExplanation(family):find('outside dungeons',1,true))
''')

for locale in ['deDE','esES','frFR','ptBR']:
    test('Review combat labels and formatting translated in '+locale,'''
local B=BuffTap
for _,key in ipairs({'Combat cleansing','Yourself (main icon)','Left click','Right click','Grow','Right, then down','Self preview','Class idle colors','Icons per line','Combat cleanse: 40 slots (drag to move)'}) do
  assert(B:Text(key)~=key,key)
end
assert(B:Text('40 players: %d x %d px',112,223):find('112',1,true))
assert(B:Text(B.CombatCleanseSafetyText)~=B.CombatCleanseSafetyText)
''',locale=locale)

# Identical names with distinct carried-item IDs are intentional item variants.
test('Review alternate food variants appear once per item ID in picker data','''
local B=BuffTap; local family=B:ConsumableFamily('food'); local ids={}
for _,item in ipairs(family.items) do assert(not ids[item.id]); ids[item.id]=true end
assert(ids[287973] and ids[287974] and ids[13928] and ids[18045])
''')
