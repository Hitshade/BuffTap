from test_weapons import test
from test_bufftap import tests, ROOT

flask = '''
stock(13510,17626); consumables('flask'); BuffTap.db.consumableChoices.flask=13510
BuffTap.db.suppliesEnabled=true; BuffTap:InitDB(); advance(2.1)
function bagEvent() BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(.3) end
'''
poisons = '''
playerClass='ROGUE'; spells={}; book={}; spell(8679,'Instant Poison')
equipWeapon(16,9001); equipWeapon(17,9002)
stock(6947,8679); stock(6949,8686); bags[6947]=2; bags[6949]=3
BuffTap.db.weaponChoices.main='instant-poison'; BuffTap.db.weaponChoices.off='instant-poison'
BuffTap.db.suppliesEnabled=true; BuffTap:InitDB(); advance(2.1)
function bagEvent() BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(.3) end
'''

test('Supplies default off add no inventory calls timers or ready-check event', '''
assert(not BuffTap.db.suppliesEnabled and not BuffTap.db.suppliesChat and not BuffTap.db.suppliesSound and not BuffTap.db.suppliesReadyCheck)
assert(not BuffTap.events.registered.READY_CHECK and countCalls==0 and liveTimers()==0)
''')
test('Login inventory settling never reports a false empty bag', '''
stock(13510,17626); consumables('flask'); BuffTap.db.consumableChoices.flask=13510; bags[13510]=0
BuffTap.db.suppliesEnabled=true; BuffTap.db.suppliesChat=true; BuffTap:InitDB(); BuffTap:SyncSupplies()
assert(BuffTap.supplyEntries[1].state=='loading' and #prints==0 and not BuffTap.supplyBadge)
advance(1); bags[13510]=5; BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(1.1)
assert(BuffTap.supplyEntries[1].state=='ok' and #prints==0)
''')
test('Supplies combine usable poison ranks and deduplicate both hands', poisons+'''
assert(#BuffTap.supplyEntries==1 and BuffTap.supplyEntries[1].count==5)
assert(BuffTap.supplyEntries[1].settings.minimum==5 and not BuffTap.supplyBadge)
''')
test('Unsupported poison rank is not counted as usable stock', poisons+'''
items[6949].usable=false; bagEvent()
assert(BuffTap.supplyEntries[1].count==2 and BuffTap.supplyEntries[1].carried==5 and BuffTap.supplyEntries[1].state=='low')
''')
test('Carried unusable poison is distinguished from empty bags', poisons+'''
items[6947].usable=false; items[6949].usable=false; bagEvent()
assert(BuffTap.supplyEntries[1].state=='unusable' and BuffTap.supplyEntries[1].carried==5)
local _,why=BuffTap:WeaponChoiceSource(BuffTap:WeaponChoice('instant-poison')); assert(why:find('carried') and not why:find('out of stock'))
''')
test('Unknown poison inventory is not described as out of stock', poisons+'''
C_Item.GetItemCount=function() return nil end
local _,why=BuffTap:WeaponChoiceSource(BuffTap:WeaponChoice('instant-poison')); assert(why:find('unavailable'))
bagEvent(); assert(BuffTap.supplyEntries[1].state=='unknown' and BuffTap.supplyEntries[1].carried==nil and #BuffTap.supplyWarnings==0)
''')
test('Selected food stock excludes all alternative foods', '''
stock(6888,1248377); stock(2680,1248378); consumables('food'); BuffTap.db.consumableChoices.food=6888
bags[6888]=1; bags[2680]=50; BuffTap.db.suppliesEnabled=true; BuffTap:InitDB(); advance(2.1)
assert(#BuffTap.supplyEntries==1 and BuffTap.supplyEntries[1].count==1 and BuffTap.supplyEntries[1].state=='low')
''')
test('Auto food stock combines usable supported food without changing preference', '''
stock(6888,1248377); stock(2680,1248378); consumables('food'); bags[6888]=2; bags[2680]=3
BuffTap.db.suppliesEnabled=true; BuffTap:InitDB(); advance(2.1)
assert(BuffTap.supplyEntries[1].count==5 and not BuffTap:ConsumableChoiceID(BuffTap:ConsumableFamily('food')))
''')
test('Enabled supply report ignores inactive consumable families', flask+'''
stock(6888,1248377); BuffTap:InvalidateSupplies(true); BuffTap:SyncSupplies(); assert(#BuffTap.supplyEntries==1)
BuffTap.db.consumablesEnabled=false; BuffTap:InitDB(); BuffTap:SyncSupplies(); assert(#BuffTap.supplyEntries==0)
''')
test('Supply tracking respects an existing elixir default without changing it', '''
BuffTap.db.consumablesEnabled=true; BuffTap.db.consumableFamilies.ferocity=true; BuffTap.db.suppliesEnabled=true
BuffTap:InitDB(); advance(2.1); assert(#BuffTap.supplyEntries==1 and #BuffTap.supplyEntries[1].ids==1 and BuffTap.supplyEntries[1].ids[1]==250350 and not BuffTap.db.consumableChoices.ferocity)
''')
test('Stock badge remains useful with an empty cast queue', flask+'''
aura('player',17626,'Flask of the Titans'); bags[13510]=0; bagEvent()
assert(not BuffTap.action and BuffTap.supplyBadge.shown and not next(bindings))
assert(BuffTap.supplyBadge.parent==UIParent and not BuffTap.supplyBadge.protected)
''')
test('Supply warning never replaces an available class spell', '''
stock(13510,17626); BuffTap.db.consumablesEnabled=true; BuffTap.db.consumableFamilies.flask=true
BuffTap.db.consumableChoices.flask=13510; bags[13510]=0; BuffTap.db.suppliesEnabled=true; BuffTap:InitDB(); advance(2.1); refresh()
assert(BuffTap.action.id==5232 and not BuffTap.action.manual and BuffTap.supplyBadge.shown)
''')
test('Chat alerts occur once per low-stock episode', flask+'''
BuffTap.db.suppliesChat=true; bags[13510]=1; bagEvent(); local n=#prints; assert(n==1)
for i=1,20 do bagEvent() end; assert(#prints==n)
bags[13510]=5; bagEvent(); bags[13510]=1; bagEvent(); assert(#prints==n+1)
''')
test('Sound is optional and fires once per low-stock episode', flask+'''
local sounds=0; PlaySound=function() sounds=sounds+1 end
bags[13510]=1; bagEvent(); assert(sounds==0)
bags[13510]=5; bagEvent(); BuffTap.db.suppliesSound=true; bags[13510]=1; bagEvent(); bagEvent(); assert(sounds==1)
''')
test('Snooze hides alerts and restores badge with one timer', flask+'''
bags[13510]=1; bagEvent(); assert(BuffTap.supplyBadge.shown)
BuffTap:SnoozeSupplies(); assert(not BuffTap.supplyBadge.shown and BuffTap:SupplySnoozed())
advance(600.1); assert(BuffTap.supplyBadge.shown and not BuffTap:SupplySnoozed())
''')
test('Restore alerts cancels snooze immediately', flask+'''
bags[13510]=0; bagEvent(); BuffTap:SnoozeSupplies(); BuffTap:RestoreSupplies()
assert(BuffTap.supplyBadge.shown and not BuffTap.timers['supplies-snooze'])
''')
test('Unchecked supply does not show a badge or shortage report', flask+'''
local settings=BuffTap.supplyEntries[1].settings; settings.enabled=false; bags[13510]=0; bagEvent()
assert(#BuffTap.supplyWarnings==0); BuffTap:ReportSupplies(); assert(prints[#prints]:find('no enabled'))
''')
test('Bag events coalesce into one supply rebuild', flask+'''
local calls=0; local original=BuffTap.SupplyDefinitions
BuffTap.SupplyDefinitions=function(self) calls=calls+1; return original(self) end
for i=1,100 do BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED') end
advance(.3); assert(calls==1)
''')
test('Ordinary aura refreshes never rescan supply inventory', flask+'''
aura('player',17626,'Flask of the Titans'); refresh()
local before=countCalls; for i=1,100 do BuffTap:Refresh() end; assert(countCalls==before)
''')
test('Unrelated item data events do not schedule supply work', flask+'''
BuffTap.supplyDirty=false; BuffTap.events.scripts.OnEvent(nil,'ITEM_DATA_LOAD_RESULT',999999,true)
assert(not BuffTap.supplyDirty and not BuffTap.timers['supplies-update'])
''')
test('Unreadable count does not warn or erase an existing episode', flask+'''
bags[13510]=1; BuffTap.db.suppliesChat=true; bagEvent(); local n=#prints
local count=C_Item.GetItemCount; C_Item.GetItemCount=function() return {secret=true} end; bagEvent()
assert(BuffTap.supplyEntries[1].state=='unknown' and #prints==n and #BuffTap.supplyWarnings==0)
C_Item.GetItemCount=count; bagEvent(); assert(#prints==n)
''')
test('Missing metadata is loading information rather than unusable stock', flask+'''
items[13510].loaded=false; BuffTap.itemMeta={}; bagEvent()
assert(BuffTap.supplyEntries[1].state=='unknown' and #BuffTap.supplyWarnings==0)
items[13510].loaded=true; BuffTap.events.scripts.OnEvent(nil,'ITEM_DATA_LOAD_RESULT',13510,true); advance(.3)
assert(BuffTap.supplyEntries[1].state=='ok')
''')
test('Missing usability information cannot certify a shortage', poisons+'''
C_Item.IsUsableItem=function() return nil end; bagEvent()
assert(BuffTap.supplyEntries[1].state=='unknown' and #BuffTap.supplyWarnings==0)
''')
test('Combat bag events defer supply reads and hide indicator', flask+'''
bags[13510]=0; bagEvent(); local before=countCalls
combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(1)
assert(countCalls==before and not BuffTap.supplyBadge.shown)
combat=false; safety('ready'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(BuffTap.supplyBadge.shown)
''')
test('Ready-check summary is opt-in and private', flask+'''
assert(not BuffTap.events.registered.READY_CHECK); BuffTap.db.suppliesReadyCheck=true; BuffTap:InitDB()
assert(BuffTap.events.registered.READY_CHECK); bags[13510]=0
BuffTap.events.scripts.OnEvent(nil,'READY_CHECK','party1'); assert(prints[#prints]:find('Supply check:') and prints[#prints]:find('0/'))
assert(not SendChatMessage)
''')
test('Healthy ready-check report specifies stock minimums only', flask+'''
BuffTap:ReportSupplies(); assert(prints[#prints]:find('warning minimums'))
''')
test('Ready check during inventory loading never reports empty stock', '''
stock(13510,17626); consumables('flask'); BuffTap.db.suppliesEnabled=true; BuffTap:InitDB(); BuffTap:ReportSupplies()
assert(prints[#prints]:find('not ready or readable'))
''')
test('Combat ready check is deferred without bag or aura reads', flask+'''
BuffTap.db.suppliesReadyCheck=true; BuffTap:InitDB(); bags[13510]=0
combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); local before=countCalls
BuffTap.events.scripts.OnEvent(nil,'READY_CHECK','party1'); assert(countCalls==before and BuffTap.supplyReadyCheckAt)
combat=false; safety('ready'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); assert(prints[#prints]:find('Supply check:'))
''')
test('Expired combat ready check is not reported after a long fight', flask+'''
BuffTap.db.suppliesReadyCheck=true; BuffTap:InitDB(); combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
BuffTap.events.scripts.OnEvent(nil,'READY_CHECK'); advance(31); local n=#prints
combat=false; safety('ready'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); assert(#prints==n and not BuffTap.supplyReadyCheckAt)
''')
test('Turning supply warnings off cancels timers and ready-check registration', flask+'''
bags[13510]=0; bagEvent(); BuffTap.db.suppliesReadyCheck=true; BuffTap:InitDB(); BuffTap:SnoozeSupplies()
BuffTap.db.suppliesEnabled=false; BuffTap:InitDB()
assert(not BuffTap.events.registered.READY_CHECK and not BuffTap.timers['supplies-snooze'] and not BuffTap.supplyBadge.shown)
''')
test('Supply settings sanitize malformed values and obsolete keys', '''
BuffTapDB.supplySettings={junk={},['consumable:flask']={minimum=0/0,target=-20,enabled='bad'},['poison:instant-poison']={minimum=9999,target=1}}
BuffTap:InitDB(); assert(not BuffTap.db.supplySettings.junk)
assert(BuffTap.db.supplySettings['consumable:flask'].minimum==2 and BuffTap.db.supplySettings['consumable:flask'].target==2)
assert(BuffTap.db.supplySettings['poison:instant-poison'].minimum==999 and BuffTap.db.supplySettings['poison:instant-poison'].target==999)
''')
test('Supplies view is integrated and preserves all eight main tabs', flask+'''
BuffTap:ShowSuppliesOptions(); local f=BuffTap.options
assert(#f.pages==8 and f.activeTab==4 and f.supplyBody.shown and not f.consumableBody.shown)
assert(f.supplyRows[1].shown and not f.supplyRows[2].shown and f.supplyRows[1].icon.texture==12345)
f.selectConsumableView(false); assert(f.consumableBody.shown and not f.supplyBody.shown)
''')
test('Supply threshold edits save clamped values without changing cast choices', flask+'''
BuffTap:ShowSuppliesOptions(); local row=BuffTap.options.supplyRows[1]
row.minimum:SetText('12'); row.minimum.scripts.OnEnterPressed(row.minimum)
assert(BuffTap.db.supplySettings['consumable:flask'].minimum==12 and BuffTap.db.supplySettings['consumable:flask'].target==12)
row.target:SetText('9999'); row.target.scripts.OnEnterPressed(row.target)
assert(BuffTap.db.supplySettings['consumable:flask'].target==999 and BuffTap.db.consumableChoices.flask==13510)
''')
test('Supply badge clicks open integrated options or snooze', flask+'''
bags[13510]=0; bagEvent(); local badge=BuffTap.supplyBadge
badge.scripts.OnClick(badge,'LeftButton'); assert(BuffTap.options.activeTab==4 and BuffTap.options.supplyBody.shown)
badge.scripts.OnClick(badge,'RightButton'); assert(BuffTap:SupplySnoozed())
''')
test('Supply view makes no configuration changes while in combat', flask+'''
BuffTap:ShowSuppliesOptions(); local row=BuffTap.options.supplyRows[1]; local minimum=row.entry.settings.minimum
combat=true; row.minimum:SetText('15'); row.minimum.scripts.OnEnterPressed(row.minimum); assert(row.entry.settings.minimum==minimum)
''')
test('Shield and fishing pole offhands do not create supply requirements', poisons+'''
BuffTap.db.weaponMainHand=false; equipShield(17,9002); BuffTap:InitDB(); BuffTap:SyncSupplies(); assert(#BuffTap.supplyEntries==0)
C_Item.GetItemInfoInstant=function() return 9002,'Weapon','Fishing Poles','INVTYPE_2HWEAPON',12345,2,20 end
BuffTap:InvalidateSupplies(false); BuffTap:SyncSupplies(); assert(#BuffTap.supplyEntries==0)
''')

# Reagent-saving selection/click checks cover each supported group spell family.
families = [
    ('DRUID', 1126, 'Mark of the Wild', 21849, 'Gift of the Wild', 'motw', 17021),
    ('MAGE', 1459, 'Arcane Intellect', 23028, 'Arcane Brilliance', 'ai', 17020),
    ('PRIEST', 1243, 'Power Word: Fortitude', 21562, 'Prayer of Fortitude', 'fort', 17028),
    ('PRIEST', 14752, 'Divine Spirit', 27681, 'Prayer of Spirit', 'spirit', 17029),
    ('PRIEST', 976, 'Shadow Protection', 27683, 'Prayer of Shadow Protection', 'sp', 17029),
    ('PALADIN', 20217, 'Blessing of Kings', 25898, 'Greater Blessing of Kings', 'bok', 21177),
    ('PALADIN', 19740, 'Blessing of Might', 25782, 'Greater Blessing of Might', 'bom', 21177),
    ('PALADIN', 19742, 'Blessing of Wisdom', 25894, 'Greater Blessing of Wisdom', 'bow', 21177),
    ('PALADIN', 1038, 'Blessing of Salvation', 25895, 'Greater Blessing of Salvation', 'bos', 21177),
    ('PALADIN', 19977, 'Blessing of Light', 25890, 'Greater Blessing of Light', 'bol', 21177),
]
for class_, single, name, group, group_name, key, reagent in families:
    setup = f'''
playerClass='{class_}'; spells={{}}; book={{}}; UnitLevel=function() return 60 end
for _,b in ipairs(BuffTap.Buffs) do BuffTap.db.buffs[b.key]=false end
spell({single},'{name}'); spell({group},'{group_name}'); bags[{reagent}]=20
BuffTap.db.buffs['{key}']=true; BuffTap.db.group=true; BuffTap.db.groupNeed=3; BuffTap.db.blessingNeed=3
refresh(); assert(BuffTap.action.id=={group} and BuffTap.action.groupCount==3)
'''
    test(f'{group_name}: one late recipient gets a single buff, not a reagent cast', setup+f'''
aura('player',{group},'{group_name}',500); aura('party1',{group},'{group_name}',500); refresh()
assert(BuffTap.action.id=={single} and BuffTap.action.target=='party2' and not BuffTap.action.groupCast)
''')
    test(f'{group_name}: fresh click recount cancels stale group cast', setup+f'''
aura('party1',{group},'{group_name}',500)
BuffTap.button.scripts.PreClick(nil,'LeftButton',true)
assert(not BuffTap.action and not BuffTap.button.attrs.spell and not next(bindings))
advance(.1); assert(BuffTap.action.id=={single} and not BuffTap.action.groupCast)
''')
    test(f'{group_name}: unchanged valid group click remains castable', setup+f'''
BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.action.id=={group} and BuffTap.button.attrs.spell=={group})
''')
    test(f'{group_name}: healthy greater coverage prevents short-single refreshes', setup+f'''
for _,u in ipairs({{'player','party1','party2'}}) do aura(u,{single},'{name}',20); aura(u,{group},'{group_name}',500) end
refresh(); assert(not BuffTap.action)
''')
    test(f'{group_name}: group expiry inside the configured window remains actionable', setup+f'''
for _,u in ipairs({{'player','party1','party2'}}) do aura(u,{group},'{group_name}',20) end
refresh(); assert(BuffTap.action.id=={group} and BuffTap.action.needState=='expiring')
''')

test('Group ranks do not combine incompatible recipients to meet threshold', '''
spell(21849,'Gift of the Wild',50); spell(21850,'Gift of the Wild',60)
UnitLevel=function(u) return u=='party1' and 55 or 60 end
BuffTap.db.group=true; BuffTap.db.groupNeed=3; refresh()
assert(BuffTap.action.id~=21849 and BuffTap.action.id~=21850 and not BuffTap.action.groupCast)
''')
test('Same-rank subgroup still qualifies in a mixed-level party', '''
spell(21849,'Gift of the Wild',50); spell(21850,'Gift of the Wild',60)
UnitLevel=function(u) return u=='party1' and 55 or 60 end
BuffTap.db.group=true; BuffTap.db.groupNeed=2; refresh()
assert(BuffTap.action.id==21850 and BuffTap.action.groupCount==2)
''')
test('Group click cancels if a second recipient moves out of range', '''
spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end; BuffTap.db.group=true; refresh()
C_Spell.IsSpellInRange=function(_,u) return u~='party2' end
BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not BuffTap.button.attrs.spell)
''')
test('Group click cancels when assignments change after display', '''
spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end; BuffTap.db.group=true; refresh()
BuffTap.db.buffClasses.motw={DRUID=false}
BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not BuffTap.button.attrs.spell)
''')
test('Group click fails closed when another recipient aura is unreadable', '''
spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end; BuffTap.db.group=true; refresh()
local fn=C_UnitAuras.GetAuraDataByIndex; C_UnitAuras.GetAuraDataByIndex=function(u,i) if u=='party2' then error('restricted') end return fn(u,i) end
BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not BuffTap.button.attrs.spell)
''')
test('No new inventory polling or aura scans while supply snapshot is idle', flask+'''
local before=countCalls; local scans=BuffTap.stats and BuffTap.stats.auraScans
for i=1,500 do BuffTap:SyncSupplies() end
assert(countCalls==before and (not scans or BuffTap.stats.auraScans==scans))
''')
test('Changed consumable effect is excluded from usable supply stock', flask+'''
items[13510].spell=999999; BuffTap.itemMeta={}; bagEvent()
assert(BuffTap.supplyEntries[1].count==0 and BuffTap.supplyEntries[1].state=='unusable' and BuffTap.supplyEntries[1].mappingMismatch)
''')
test('Incomplete item spell data never triggers a low-stock warning', flask+'''
items[13510].spell=nil; BuffTap.itemMeta={}; bagEvent()
assert(BuffTap.supplyEntries[1].state=='unknown' and #BuffTap.supplyWarnings==0 and BuffTap.itemRequests[13510])
''')
test('Ready check does not duplicate a newly detected private stock alert', flask+'''
BuffTap.db.suppliesChat=true; bags[13510]=0; local before=#prints; BuffTap:ReportSupplies()
assert(#prints==before+1 and prints[#prints]:find('Supply check:'))
''')
test('Class group reagent checks remain unchanged pending exemption validation', '''
spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end; BuffTap.db.group=true; bags[17021]=0
refresh(); assert(BuffTap.action and not BuffTap.action.groupCast)
assert(not BuffTap.ReagentWaiverAuras and not BuffTap.RecoveryReagents)
''')
test('Uninitialized backpack slots prevent false zero-stock warnings', '''
stock(13510,17626); consumables('flask'); bags[13510]=0; C_Container.GetContainerNumSlots=function() return 0 end
BuffTap.db.suppliesEnabled=true; BuffTap.db.suppliesChat=true; BuffTap:InitDB(); advance(2.1)
assert(not BuffTap.supplyInventoryReady and #prints==0 and #BuffTap.supplyWarnings==0)
bags[13510]=5; C_Container.GetContainerNumSlots=function() return 16 end
BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(2.1)
assert(BuffTap.supplyInventoryReady and BuffTap.supplyEntries[1].state=='ok' and #prints==0)
''')
test('Unavailable bag capacity API leaves stock loading without retry polling', '''
stock(13510,17626); consumables('flask'); BuffTap.db.suppliesEnabled=true; C_Container=nil
BuffTap:InitDB(); advance(2.1); assert(not BuffTap.supplyInventoryReady and #BuffTap.supplyWarnings==0)
local before=countCalls; advance(60); assert(countCalls==before and not BuffTap.timers['supplies-settle'])
''')


test('Supply choice setter refreshes preferences without recounting stock', flask+'''
stock(13512,17628); bags[13512]=9; bagEvent()
local before=countCalls; BuffTap:SetConsumableChoice(BuffTap:ConsumableFamily('flask'),13512); BuffTap:SyncSupplies()
assert(BuffTap.supplyEntries[1].ids[1]==13512 and BuffTap.supplyEntries[1].count==9 and countCalls==before)
''')
test('Main item picker refreshes tracked supply immediately', flask+'''
stock(13512,17628); bags[13512]=9; bagEvent(); BuffTap:Options(); BuffTap:ChooseConsumable(BuffTap:ConsumableFamily('flask'))
local row=BuffTap.itemPicker.rows[1]; row.itemID=13512; row.scripts.OnClick(row)
assert(BuffTap.supplyEntries[1].ids[1]==13512 and BuffTap.supplyEntries[1].count==9)
''')
test('Quick item chooser refreshes tracked supply', flask+'''
stock(13512,17628); bags[13512]=9; bagEvent(); BuffTap:Refresh(); BuffTap.db.helperQuick=true; BuffTap:ShowQuickChoices(BuffTap.action)
local row=BuffTap.quickChoices.rows[1]; row.itemID=13512; row.scripts.OnClick(row); advance(.1)
assert(BuffTap.supplyEntries[1].ids[1]==13512)
''')
test('Consumable master options removes disabled supply warnings', flask+'''
bags[13510]=0; bagEvent(); assert(#BuffTap.supplyWarnings==1); BuffTap:Options()
local c=BuffTap.options.consumablesEnable; c:SetChecked(false); c.scripts.OnClick(c)
assert(#BuffTap.supplyEntries==0 and #BuffTap.supplyWarnings==0 and not BuffTap.supplyBadge.shown)
''')
test('Consumable family options removes disabled supply', flask+'''
BuffTap:Options(); local c=BuffTap.options.consumableRows[2].enable; c:SetChecked(false); c.scripts.OnClick(c)
assert(#BuffTap.supplyEntries==0)
''')
test('Consumables slash toggle refreshes stock definitions', flask+'''
SlashCmdList.BUFFTAP('consumables off'); assert(#BuffTap.supplyEntries==0)
SlashCmdList.BUFFTAP('consumables on'); assert(#BuffTap.supplyEntries==1)
''')
test('Weapon picker refreshes and deduplicates new poison preferences', poisons+'''
stock(2892,2823); bags[2892]=8; bagEvent(); BuffTap:Options()
local rows=BuffTap.options.weaponPickers.main.menu.rows
for _,r in ipairs(rows) do if r.choice=='deadly-poison' then r.scripts.OnClick(r); break end end
assert(#BuffTap.supplyEntries==2 and BuffTap.supplyEntries[1].key=='poison:deadly-poison')
for _,r in ipairs(rows) do if r.choice==nil then r.scripts.OnClick(r); break end end
assert(#BuffTap.supplyEntries==1 and BuffTap.supplyEntries[1].key=='poison:instant-poison')
''')

print(f'ALL {len(tests)} SCENARIOS PASSED')
(ROOT/'tests/last-run-1.3.0.txt').write_text('\n'.join('PASS '+name for name in tests)+
    f'\n\n{len(tests)} scenarios passed under Lua 5.1. Mocked APIs; no in-client cast or visual verification.\n')
