from test_helpers import test

ready='''
BuffTap:ResetStats()
for _,b in ipairs(BuffTap.Buffs) do BuffTap.db.buffs[b.key]=false end
playerClass='WARLOCK'; spells={}; book={}; BuffTap.bookDirty=true
petExists=false; petDead=false; petID='Pet-one'; speed=0; vehicle=false
local exists=UnitExists
UnitExists=function(u) if u=='pet' then return petExists end return exists(u) end
UnitIsDeadOrGhost=function(u) if u=='pet' then return petDead end return dead end
local guid=UnitGUID
UnitGUID=function(u) if u=='pet' then return petID end return guid(u) end
UnitInVehicle=function() return vehicle end
GetUnitSpeed=function() return speed end
function event(e,...) BuffTap.events.scripts.OnEvent(nil,e,...) end
spell(688,'Summon Imp'); spell(697,'Summon Voidwalker'); spell(712,'Summon Succubus'); spell(713,'Summon Incubus'); spell(691,'Summon Felhunter')
BuffTap.db.helperPet=true; BuffTap.db.helperDemon=688
'''
stone=ready+'''
BuffTap.db.helperPet=false; BuffTap.db.helperHealthstone=true
spell(6201,'Create Healthstone'); stock(5512,6262); bags[5512]=0; bags[6265]=2
NUM_BAG_SLOTS=4; freeSlots=4; bagFamily=0; bagContents={}
C_Container={
 GetContainerNumSlots=function(b) return b==0 and 4 or 0 end,
 GetContainerNumFreeSlots=function(b) return freeSlots,bagFamily end,
 GetContainerItemID=function(b,s) return bagContents[s] end,
 GetContainerItemInfo=function(b,s) return bagContents[s] and {itemID=bagContents[s],stackCount=1} end,
}
'''
test('Readiness stays off with zero inventory or pet probes', '''
playerClass='WARLOCK'; for _,b in ipairs(BuffTap.Buffs) do BuffTap.db.buffs[b.key]=false end
local before=countCalls; local base=UnitExists
UnitExists=function(u) assert(u~='pet'); return base(u) end
for i=1,100 do BuffTap:Refresh() end
assert(not BuffTap.db.helperPet and not BuffTap.db.helperHealthstone and countCalls==before)
assert(not BuffTap.events.registered.UNIT_PET)
''')
test('Preferred demon prepares a spell and explicit player target',ready+'''
refresh(); assert(BuffTap.action.id==688 and BuffTap.action.source=='readiness')
assert(BuffTap.button.attrs.type1=='spell' and BuffTap.button.attrs.spell==688 and BuffTap.button.attrs.unit=='player' and not BuffTap.button.attrs.item)
''')
test('Any living demon satisfies regardless of preference',ready+"petExists=true; refresh(); assert(not BuffTap.action)")
test('Dead demon permits preferred replacement',ready+"petExists=true; petDead=true; refresh(); assert(BuffTap.action.id==688)")
test('No preference produces a manual unbound reminder',ready+"BuffTap.db.helperDemon=0; refresh(); assert(BuffTap.action.manual and not BuffTap.action.secureType and not BuffTap.button.attrs.type1 and not next(bindings)); BuffTap.button.scripts.OnEnter()")
test('Unlearned preference never silently selects another demon',ready+"spells[688].known=false; refresh(); assert(BuffTap.action.manual and BuffTap.db.helperDemon==688)")
test('Demonic Sacrifice suppresses summon and schedules expiry',ready+"aura('player',18791,'Sacrifice',60,7200); refresh(); assert(not BuffTap.action); advance(61); auras={}; refresh(); assert(BuffTap.action.id==688)")
test('Unreadable sacrifice aura does not arm a summon',ready+"C_UnitAuras.GetAuraDataByIndex=function() error('unreadable') end; refresh(); assert(not BuffTap.action and not BuffTap.lastError)")
test('Summons require shards except Imp',ready+"BuffTap.db.helperDemon=697; bags[6265]=0; refresh(); assert(not BuffTap.action); bags[6265]=1; event('BAG_UPDATE_DELAYED'); advance(.3); assert(BuffTap.action.id==697)")
test('Readiness rejects movement and resumes on stop',ready+"speed=4; refresh(); assert(not BuffTap.action); speed=0; event('PLAYER_STOPPED_MOVING'); advance(.1); assert(BuffTap.action.id==688); speed=3; event('PLAYER_STARTED_MOVING'); assert(not BuffTap.action and not next(bindings))")
test('Mounted vehicle casting and dead states suppress recovery',ready+'''
mounted=true; refresh(); assert(not BuffTap.action); mounted=false; vehicle=true; refresh(); assert(not BuffTap.action)
vehicle=false; UnitCastingInfo=function() return 'Casting' end; refresh(); assert(not BuffTap.action)
UnitCastingInfo=function() return nil end; dead=true; refresh(); assert(not BuffTap.action)
''')
test('Dismount grace ends once without polling',ready+"mounted=true; refresh(); mounted=false; event('PLAYER_MOUNT_DISPLAY_CHANGED'); advance(1); assert(not BuffTap.action); advance(1.2); assert(BuffTap.action.id==688); local before=BuffTap.stats.refreshes; advance(100); assert(BuffTap.stats.refreshes==before)")
test('Hunter absent pet never guesses call versus revive',ready+"playerClass='HUNTER'; spell(883,'Call Pet'); spell(982,'Revive Pet'); C_StableInfo={GetStablePetInfo=function() return {petNumber=7} end}; refresh(); assert(BuffTap.action.manual and not BuffTap.button.attrs.type1 and not next(bindings))")
test('Hunter without assigned pet stays silent',ready+"playerClass='HUNTER'; spell(883,'Call Pet'); C_StableInfo={GetStablePetInfo=function() return nil end}; refresh(); assert(not BuffTap.action)")
test('Hunter visible dead pet offers revive and cancels stale identity',ready+"playerClass='HUNTER'; spell(982,'Revive Pet'); petExists=true; petDead=true; refresh(); assert(BuffTap.action.id==982); petID='Different'; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('Pet arriving before click cancels stale summon',ready+"refresh(); petExists=true; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not next(bindings))")
test('Foreign pet events do not schedule work',ready+"refresh(); local before=BuffTap.stats.refreshes; event('UNIT_PET','party1'); event('UNIT_FLAGS','target'); advance(1); assert(BuffTap.stats.refreshes==before)")
test('Disabling helper unregisters added events and cancels wake',ready+"refresh(); BuffTap:AfterReadinessClick(BuffTap.action,true); BuffTap.db.helperPet=false; refresh(); assert(not BuffTap.action and not BuffTap.events.registered.UNIT_PET and not BuffTap.readinessPending); advance(20); assert(not BuffTap.action)")
test('Spell failure releases pending without suppressing reminder',ready+"refresh(); BuffTap:AfterReadinessClick(BuffTap.action,true); event('UNIT_SPELLCAST_FAILED','player','cast',688); advance(.2); assert(not BuffTap.readinessPending and BuffTap.action.id==688)")
test('Success holds briefly and observed pet satisfies after settling',ready+"refresh(); BuffTap:AfterReadinessClick(BuffTap.action,true); event('UNIT_SPELLCAST_START','player','cast',688); event('UNIT_SPELLCAST_SUCCEEDED','player','cast',688); petExists=true; event('UNIT_PET','player'); advance(3); assert(not BuffTap.readinessPending and not BuffTap.action)")
test('Mismatched cast cannot release pending attempt',ready+"refresh(); BuffTap:AfterReadinessClick(BuffTap.action,true); event('UNIT_SPELLCAST_START','player','ours',688); event('UNIT_SPELLCAST_FAILED','player','other',688); assert(BuffTap.readinessPending); event('UNIT_SPELLCAST_INTERRUPTED','player','ours',688); assert(not BuffTap.readinessPending)")
test('Combat secure suspension remains authoritative',ready+"refresh(); combat=true; safety('blocked'); event('PLAYER_REGEN_DISABLED'); assert(not BuffTap.button.attrs.type1 and not next(bindings)); BuffTap:Refresh(); combat=false; safety('ready'); event('PLAYER_REGEN_ENABLED'); advance(.3); assert(BuffTap.action.id==688)")
test('Healthstone prepares creation never item consumption',stone+"refresh(); assert(BuffTap.action.id==6201 and BuffTap.action.key=='healthstone'); assert(BuffTap.button.attrs.type1=='spell' and not BuffTap.button.attrs.item)")
test('Any carried rank or improved stone satisfies',stone+"for _,id in ipairs({5512,19004,19005,5511,19006,19007,5509,19008,19009,5510,19010,19011,9421,19012,19013}) do bags[id]=1; BuffTap.readinessInventory=nil; refresh(); assert(not BuffTap.action,id); bags[id]=0 end")
test('Healthstone cooldown and unloaded item names do not imply absence',stone+"bags[19013]=1; C_Item.GetItemCooldown=function() error('must not check use cooldown') end; C_Item.GetItemInfo=function() return nil end; refresh(); assert(not BuffTap.action)")
test('Highest learned creation rank is selected',stone+"spell(11730,'Create Healthstone'); stock(9421,11732); bags[9421]=0; refresh(); assert(BuffTap.action.id==11730)")
test('Creation needs shard and a general bag slot',stone+"bags[6265]=0; refresh(); assert(not BuffTap.action); bags[6265]=1; freeSlots=0; BuffTap.readinessInventory=nil; refresh(); assert(not BuffTap.action); freeSlots=4; bagFamily=4; BuffTap.readinessInventory=nil; refresh(); assert(not BuffTap.action)")
test('Unreadable bag or count data fails closed',stone+"C_Item.GetItemCount=function() return nil end; refresh(); assert(not BuffTap.action)")
test('Unresolved occupied slot blocks creation',stone+"bagContents[1]=999; C_Container.GetContainerItemInfo=function() return nil end; refresh(); assert(not BuffTap.action)")
test('Container stone overrides stale zero counts',stone+"bagContents[1]=19013; refresh(); assert(not BuffTap.action)")
test('Empty or unavailable backpack data blocks creation',stone+"C_Container.GetContainerNumSlots=function() return 0 end; refresh(); assert(not BuffTap.action)")
test('Output metadata mismatch prevents unverified creation',stone+"items[5512].spell=999; refresh(); assert(not BuffTap.action)")
test('Loaded Healthstone output metadata resumes on matching event',stone+"items[5512].loaded=false; refresh(); assert(not BuffTap.action); items[5512].loaded=true; event('ITEM_DATA_LOAD_RESULT',5512,true); advance(.3); assert(BuffTap.action and BuffTap.action.id==6201)")
test('Carried stone arriving just before click cancels creation',stone+"refresh(); bags[5512]=1; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not BuffTap.button.attrs.type1)")
test('Full bags just before click cancel creation',stone+"refresh(); freeSlots=0; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('Inventory is cached across ordinary aura refreshes',stone+"refresh(); local n=BuffTap.stats.readinessBagScans; for i=1,100 do refresh() end; assert(BuffTap.stats.readinessBagScans==n); event('BAG_UPDATE_DELAYED'); advance(.3); assert(BuffTap.stats.readinessBagScans==n+1)")
test('Healthstone works independently of global consumables toggle',stone+"assert(not BuffTap.db.consumablesEnabled); refresh(); bags[5512]=1; event('BAG_UPDATE_DELAYED'); advance(.3); assert(not BuffTap.action)")
test('Ready Healthstone is not blocked by missing demon preference',stone+"BuffTap.db.helperPet=true; BuffTap.db.helperDemon=0; refresh(); assert(BuffTap.action.key=='healthstone')")
test('Broken pet provider does not block Healthstone',stone+"BuffTap.db.helperPet=true; BuffTap.PetReadinessCandidate=function() error('fault') end; refresh(); assert(BuffTap.action.key=='healthstone' and not BuffTap.lastError)")
test('Ordinary buffs remain ahead of readiness',ready+"spell(687,'Demon Skin'); BuffTap.db.buffs['demon-skin']=true; refresh(); assert(BuffTap.action.id==687 and BuffTap.action.source~='readiness')")
test('Eating suppression also protects readiness',stone+"BuffTap.db.consumablesEnabled=true; BuffTap.db.consumableFamilies.food=true; aura('player',1248401,'Eating',15,30); refresh(); assert(not BuffTap.action)")
test('Helpers integrate explicit demon choice and retain settings',ready+"BuffTap:HelperOptions(); local f=BuffTap.helperWindow; assert(f.readiness:GetParent()==f and f.readiness:IsShown()); assert(#f.demonMenu.rows==5); f.demonMenu.rows[2].scripts.OnClick(f.demonMenu.rows[2]); assert(BuffTap.db.helperDemon==697 and BuffTap.options.activeTab==8); assert(not f.demonMenu:IsShown())")
test('Hunter options hide Healthstones and demon choice',ready+"playerClass='HUNTER'; BuffTap:HelperOptions(); local f=BuffTap.helperWindow; assert(f.readiness:IsShown() and not f.stoneCheck:IsShown() and not f.demonChoice:IsShown())")
test('Other classes have no readiness options or scans',ready+"playerClass='DRUID'; BuffTap:HelperOptions(); assert(not BuffTap.helperWindow.readiness:IsShown()); local n=countCalls; refresh(); assert(countCalls==n and not BuffTap.events.registered.UNIT_PET)")
test('Generated client ranks fix missing seals and armor ownership',"""
local defs={}; for _,b in ipairs(BuffTap.Buffs) do defs[b.key]=b end
local function contains(t,id) for _,v in ipairs(t) do if v==id then return true end end end
assert(contains(defs['seal-righteousness'].ranks,20288))
assert(contains(defs['demon-armor'].ranks,706) and not contains(defs['demon-skin'].ranks,706))
assert(BuffTap.RankLevel[706]==20 and BuffTap.RankLevel[11735]==60)
assert(contains(defs.trueshot.ranks,1299346) and contains(defs['seal-fury'].ranks,20423))
assert(not contains(defs['lightning-shield'].ranks,26363))
""")
print('READINESS AND CATALOG REGRESSIONS COMPLETE')

test('Invalid demon preference is sanitized without altering profiles',ready+"BuffTap.db.helperDemon='688'; BuffTap.db.buffSeconds.motw=90; BuffTap.db.priorities.thorns=7; BuffTap.db.consumableChoices.food=6888; BuffTap:InitDB(); assert(BuffTap.db.helperDemon==0 and BuffTap.db.buffSeconds.motw==90 and BuffTap.db.priorities.thorns==7 and BuffTap.db.consumableChoices.food==6888)")
test('Dismiss and restore applies to readiness',ready+"refresh(); BuffTap:DismissHelper(BuffTap.action); advance(.2); assert(not BuffTap.action); BuffTap:RestoreHelpers(); advance(.2); assert(BuffTap.action.id==688)")
test('Unknown movement or vehicle APIs do not arm recovery',ready+"GetUnitSpeed=nil; refresh(); assert(not BuffTap.action); GetUnitSpeed=function() return 0 end; UnitInVehicle=nil; refresh(); assert(not BuffTap.action)")
test('Recovery still respects cooldown and power',ready+"spells[688].usable=false; refresh(); assert(not BuffTap.action); spells[688].usable=true; C_Spell.GetSpellCooldown=function() return {startTime=now,duration=2,isEnabled=true} end; refresh(); assert(not BuffTap.action)")
test('Mouse release cannot enqueue a second readiness cast',ready+"refresh(); local a=BuffTap.action; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); BuffTap.button.scripts.PostClick(nil,'LeftButton',true); local pending=BuffTap.readinessPending; assert(pending); BuffTap.button.scripts.PreClick(nil,'LeftButton',false); BuffTap.button.scripts.PostClick(nil,'LeftButton',false); assert(BuffTap.readinessPending==pending and not BuffTap.action)")
test('Right click does not claim a readiness cast',ready+"refresh(); BuffTap.button.scripts.PostClick(nil,'RightButton',false); assert(not BuffTap.readinessPending)")
test('Failed creation never falls back to consuming the stone',stone+"refresh(); BuffTap:AfterReadinessClick(BuffTap.action,true); event('UNIT_SPELLCAST_FAILED','player','cast',6201); advance(.3); assert(BuffTap.action.id==6201 and BuffTap.button.attrs.type1=='spell' and not BuffTap.button.attrs.item)")
