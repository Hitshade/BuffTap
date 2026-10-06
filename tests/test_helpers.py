from test_bufftap import test

test('Helpers default off and preserve existing saved choices', '''
for _,k in ipairs({'helperDismiss','helperBounce','helperTracking','helperCoverage','helperDiscovery','helperThanks','helperQuick'}) do assert(BuffTap.db[k]==false) end
BuffTap.db.helperThanks=true; BuffTap:InitDB(); assert(BuffTap.db.helperThanks)
''')
test('Dismiss advances to next buff and restores on zone change', '''
BuffTap.db.helperDismiss=true
BuffTap.button.scripts.PostClick(nil,'RightButton',false); advance(.1)
assert(BuffTap.action.key=='thorns')
BuffTap.events.scripts.OnEvent(nil,'ZONE_CHANGED_NEW_AREA'); advance(.1)
assert(BuffTap.action.key=='motw')
''')
test('Dismissal is recipient specific and restores manually', '''
BuffTap.db.friendlyTarget=true; refresh(); BuffTap:DismissHelper(BuffTap.action); advance(.1)
assert(BuffTap.action.key=='thorns' and BuffTap.action.quickTarget)
BuffTap:RestoreHelpers(); advance(.1); assert(BuffTap.action.key=='motw')
''')
test('Right click down does not dismiss two consecutive actions', '''
BuffTap.db.helperDismiss=true
BuffTap.button.scripts.PostClick(nil,'RightButton',true); advance(.1); assert(BuffTap.action.key=='motw')
BuffTap.button.scripts.PostClick(nil,'RightButton',false); advance(.1); assert(BuffTap.action.key=='thorns')
''')
test('Dismissed consumable family does not block another family', '''
stock(13510,17626); stock(250350,1250985); consumables('flask'); BuffTap.db.consumableFamilies.ferocity=true
refresh(); BuffTap:DismissHelper(BuffTap.action); advance(.1); assert(BuffTap.action.familyKey=='ferocity')
''')
test('Only recent stronger-effect errors suppress a BuffTap action', '''
BuffTap.db.helperBounce=true; SPELL_FAILED_AURA_BOUNCED='Stronger effect'
BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(not BuffTap.helperDismissed)
BuffTap:BeginHelperAttempt(BuffTap.action); now=now+1
BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(not BuffTap.helperDismissed)
BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:HandleHelperError('Not enough mana'); assert(not BuffTap.helperDismissed)
BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',BuffTap.action.id); BuffTap.events.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,SPELL_FAILED_AURA_BOUNCED)
advance(.1); assert(BuffTap.action.key=='thorns')
''')
test('Successful cast clears error attribution', '''
BuffTap.db.helperBounce=true; SPELL_FAILED_AURA_BOUNCED='Stronger effect'
BuffTap:BeginHelperAttempt(BuffTap.action)
BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',5232)
BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(not BuffTap.helperDismissed)
''')
tracking='''
spell(2383,'Find Herbs'); spell(2580,'Find Minerals'); BuffTap.db.buffs.motw=false; BuffTap.db.buffs.thorns=false
C_Minimap={GetNumTrackingTypes=function() return 2 end,GetTrackingInfo=function(i)
return {spellID=i==1 and 2383 or 2580,name=i==1 and 'Find Herbs' or 'Find Minerals',type='spell',texture=123,active=i==1} end}
BuffTap.db.helperTracking=true; BuffTap.db.helperTracker=2580
'''
test('Explicit tracker queues one validated secure spell',tracking+'''
refresh(); assert(BuffTap.action.source=='tracking' and BuffTap.button.attrs.spell==2580)
BuffTap.button.scripts.PreClick(nil,'LeftButton',false); assert(BuffTap.action)
BuffTap.db.helperTracker=2383; refresh(); assert(not BuffTap.action)
''')
test('Tracker changes before click are rejected',tracking+'''
refresh(); C_Minimap.GetTrackingInfo=function() return {spellID=2580,name='Find Minerals',type='spell',active=true} end
BuffTap.button.scripts.PreClick(nil,'LeftButton',false); assert(not BuffTap.action)
''')
test('Unknown or restricted tracking never queues an action',tracking+'''
C_Minimap.GetTrackingInfo=function() return {secret=true} end; refresh(); assert(not BuffTap.action)
C_Minimap=nil; refresh(); assert(not BuffTap.action)
''')
test('Party coverage works without enabling party casting', '''
BuffTap.db.helperCoverage=true
UnitClass=function(u) return 'Mage',u=='party1' and 'MAGE' or 'DRUID' end
refresh(); local lines=BuffTap:CoverageLines(); assert(table.concat(lines,';'):find('Arcane Intellect'))
assert(BuffTap.coverageFrame:IsShown() and BuffTap.action.target=='player')
aura('player',1459,'Arcane Intellect'); aura('party1',1459,'Arcane Intellect'); aura('party2',1459,'Arcane Intellect')
for _,u in ipairs({'player','party1','party2'}) do BuffTap.events.scripts.OnEvent(nil,'UNIT_AURA',u) end
advance(.1); assert(not table.concat(BuffTap:CoverageLines(),';'):find('Arcane Intellect'))
''')
test('Party coverage never calls unknown data missing or claims raid support', '''
BuffTap.db.helperCoverage=true; UnitClass=function() return 'Mage','MAGE' end
C_UnitAuras.GetAuraDataByIndex=function() error('unreadable') end; refresh(); assert(#BuffTap:CoverageLines()==0)
IsInRaid=function() return true end; assert(#BuffTap:CoverageLines()==0)
''')
test('Coverage treats another blessing as occupied', '''
BuffTap.db.helperCoverage=true; UnitClass=function() return 'Paladin','PALADIN' end
for _,u in ipairs({'player','party1','party2'}) do aura(u,19740,'Blessing of Might') end
refresh(); assert(#BuffTap:CoverageLines()==0)
''')
test('Discovery is informational and cached across aura events', '''
local scans=0; BuffTap.db.helperDiscovery=true; BuffTap.helperDiscoverDirty=true
C_Container={GetContainerNumSlots=function(b) scans=scans+1; return b==0 and 1 or 0 end,GetContainerItemID=function() return 999001 end}
C_Item.GetItemInfo=function() return 'Unknown Elixir',nil,1,1,1,'Consumable','Elixir',20,'',123,1,0 end
refresh(); assert(#BuffTap.helperDiscoveries==1 and BuffTap.action.key=='motw')
local before=scans; for i=1,20 do BuffTap.events.scripts.OnEvent(nil,'UNIT_AURA','player'); advance(.1) end
assert(scans==before)
BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(.3); assert(scans>before)
''')
test('Discovery excludes verified items and equipment', '''
BuffTap.db.helperDiscovery=true
C_Container={GetContainerNumSlots=function(b) return b==0 and 2 or 0 end,GetContainerItemID=function(b,s) return s==1 and 13510 or 999001 end}
C_Item.GetItemInfo=function() return 'Armor',nil,1,1,1,'Armor','Plate',1,'',123,1,4 end
BuffTap:DiscoverConsumables(); assert(#BuffTap.helperDiscoveries==0)
''')
solo='''
IsInGroup=function() return false end; IsInRaid=function() return false end; IsInInstance=function() return false end
UnitIsPlayer=function() return true end; local emotes={}; DoEmote=function(e,u) emotes[#emotes+1]={e,u} end
BuffTap.db.helperThanks=true; BuffTap:ObserveSoloThanks(true)
local function received(id,source) aura('player',id,'External buff',600,600); auras.player[#auras.player].sourceUnit=source; BuffTap:InvalidateAura('player'); BuffTap:ObserveSoloThanks() end
'''
test('Solo thanks requires known caster and coalesces consecutive buffs',solo+'''
received(1459,'target'); assert(#emotes==1 and emotes[1][1]=='THANK' and emotes[1][2]=='Ally')
received(1243,'target'); assert(#emotes==1)
now=now+65; received(14752,'target'); assert(#emotes==1)
''')
test('Thanks skips self, unknown caster, unrelated effects and login buffs',solo+'''
received(1459,'player'); received(1243,nil); received(999999,'target'); assert(#emotes==0)
BuffTap.helperThankSeen=nil; received(14752,'target'); assert(#emotes==0)
''')
test('Thanks stays off in party raid instance and combat',solo+'''
IsInGroup=function() return true end; received(1459,'target'); assert(#emotes==0)
IsInGroup=function() return false end; IsInRaid=function() return true end; received(1243,'target'); assert(#emotes==0)
IsInRaid=function() return false end; IsInInstance=function() return true end; received(14752,'target'); assert(#emotes==0)
IsInInstance=function() return false end; combat=true; received(19740,'target'); assert(#emotes==0)
''')
test('Thanks respects global limit across different providers',solo+'''
received(1459,'target'); received(1243,'party1'); assert(#emotes==1)
now=now+61; received(14752,'party1'); assert(#emotes==2)
''')
test('Unknown grouping and secret caster fail closed',solo+'''
IsInGroup=nil; received(1459,'target'); assert(#emotes==0)
IsInGroup=function() return false end; BuffTap:ObserveSoloThanks(true)
received(1243,{secret=true}); assert(#emotes==0)
''')
test('Helpers UI builds, updates and closes safely in combat',tracking+'''
BuffTap:HelperOptions(); assert(BuffTap.helperWindow:IsShown())
BuffTap.helperWindow.checks.helperThanks:SetChecked(true)
BuffTap.helperWindow.checks.helperThanks.scripts.OnClick(BuffTap.helperWindow.checks.helperThanks)
assert(BuffTap.db.helperThanks)
combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); assert(not BuffTap.helperWindow:IsShown())
''')
test('Quick choices change preference only and preserve secure validation', '''
stock(13510,17626); consumables('flask'); BuffTap.db.helperQuick=true; refresh()
BuffTap:ShowQuickChoices(BuffTap.action); local f=BuffTap.quickChoices; assert(f:IsShown())
f.rows[1].scripts.OnClick(f.rows[1]); assert(BuffTap.db.consumableChoices.flask==13510)
advance(.1); assert(BuffTap.action.itemID==13510)
bags[13510]=0; BuffTap.button.scripts.PreClick(nil,'LeftButton',false); assert(not BuffTap.action)
''')
test('Modern emote API receives a resolved name and never retries a restriction',solo+'''
DoEmote=nil; C_ChatInfo={PerformEmote=function(e,name) emotes[#emotes+1]={e,name}; return false end}
received(1459,'target'); assert(#emotes==1 and emotes[1][2]=='Ally')
received(1243,'target'); assert(#emotes==1 and BuffTap.helperThankStatus:find('restricted'))
''')
test('Auto thanks remains silent when disabled',solo+'''
BuffTap.db.helperThanks=false; received(1459,'target'); assert(#emotes==0)
''')
test('Existing auras at login do not generate a delayed thank',solo+'''
aura('player',1459,'Intellect',600,600); auras.player[#auras.player].sourceUnit='target'
BuffTap.events.scripts.OnEvent(nil,'PLAYER_ENTERING_WORLD'); advance(.2); assert(#emotes==0)
''')
test('All optional helpers suspend cleanly at combat entry',tracking+'''
for _,key in ipairs({'helperDismiss','helperBounce','helperQuick','helperCoverage','helperDiscovery','helperThanks'}) do BuffTap.db[key]=true end
refresh(); BuffTap:HelperOptions()
combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
assert(not BuffTap.action and not next(bindings) and liveTimers()==0)
assert(not BuffTap.helperWindow:IsShown() and (not BuffTap.coverageFrame or not BuffTap.coverageFrame:IsShown()))
''')
test('Tracking events are idle when the feature is disabled', '''
BuffTap:ResetStats(); BuffTap.events.scripts.OnEvent(nil,'MINIMAP_UPDATE_TRACKING'); advance(.1)
assert(BuffTap.stats.refreshes==0 and liveTimers()==0)
''')
test('Unknown item load failures do not create retry loops', '''
BuffTap.db.helperDiscovery=true; local requests=0
C_Container={GetContainerNumSlots=function(b) return b==0 and 1 or 0 end,GetContainerItemID=function() return 999001 end}
C_Item.GetItemInfo=function() return nil end
C_Item.RequestLoadItemDataByID=function() requests=requests+1 end
BuffTap:DiscoverConsumables(); assert(requests==1)
BuffTap.events.scripts.OnEvent(nil,'ITEM_DATA_LOAD_RESULT',999001,false); advance(.2)
assert(requests==1); advance(101); assert(requests<=3 and liveTimers()==0)
''')
test('Unrelated item loads do not schedule discovery', '''
BuffTap.db.helperDiscovery=true; BuffTap:ResetStats()
BuffTap.events.scripts.OnEvent(nil,'ITEM_DATA_LOAD_RESULT',987654,true); advance(.3)
assert(BuffTap.stats.refreshes==0)
''')
test('Group dismissal shares the single family and prevents group bypass', '''
spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end
BuffTap.db.group=true; BuffTap.db.groupNeed=2; refresh(); assert(BuffTap.action.groupCast)
local unit=BuffTap.action.target; BuffTap:DismissHelper(BuffTap.action); advance(.1)
assert(not BuffTap.action.groupCast and BuffTap.action.target~=unit)
''')
test('Dismissing main hand still offers missing off hand manually', '''
playerClass='ROGUE'; spells={}; book={}; spell(8679,'Instant Poison'); equipWeapon(16,9001); equipWeapon(17,9002)
refresh(); assert(BuffTap.action.slot==16); BuffTap:DismissHelper(BuffTap.action); advance(.1)
assert(BuffTap.action.slot==17 and not BuffTap.button.attrs.type1 and not next(bindings))
''')
print('HELPER REGRESSIONS COMPLETE')
test('Helpers opens the main options tab without a second window', '''
BuffTap:HelperOptions()
assert(BuffTap.options:IsShown() and BuffTap.options.activeTab==7)
assert(BuffTap.helperWindow:GetParent()==BuffTap.options)
assert(BuffTapHelperOptions==nil and BuffTap.options.pages[7]==BuffTap.helperWindow)
for key in pairs(BuffTap.helperWindow.checks) do assert(#BuffTap.helperWindow.descriptions[key].text>40) end
BuffTap.options.selectTab(1); assert(not BuffTap.helperWindow:IsShown())
''')
test('Helper setting preserves selected tab and existing buff choices', '''
BuffTap.db.buffSeconds.motw=90; BuffTap:HelperOptions()
local c=BuffTap.helperWindow.checks.helperQuick; c:SetChecked(true); c.scripts.OnClick(c)
assert(BuffTap.options.activeTab==7 and BuffTap.db.helperQuick and BuffTap.db.buffSeconds.motw==90)
''')
test('Discovery report is inside Diagnostics and disabled scan is explained', '''
BuffTap:HelperOptions(); BuffTap:ShowDiscoveryReport()
assert(BuffTap.options.activeTab==8 and BuffTap.options.discoveryScroll:IsShown())
assert(not BuffTap.helperWindow:IsShown() and not BuffTap.options.diagText:IsShown())
assert(BuffTap.options.discoveryReport:GetText():find('Enable Find unrecognized'))
''')




test('Upgrade removes only retired potion settings', "BuffTap.db.consumableFamilies['potion-stock']=true; BuffTap.db.consumableChoices['potion-stock']=118; BuffTap.db.consumableSeconds['potion-stock']=120; BuffTap.db.consumableChoices.food=6888; BuffTap.db.consumableFamilies.food=true; BuffTap.db.helperThanks=true; BuffTap:InitDB(); assert(BuffTap.db.consumableFamilies['potion-stock']==nil and BuffTap.db.consumableChoices['potion-stock']==nil and BuffTap.db.consumableSeconds['potion-stock']==nil); assert(BuffTap.db.consumableChoices.food==6888 and BuffTap.db.consumableFamilies.food and BuffTap.db.helperThanks)")
test('Consumable options have only maintainable buff families', "BuffTap:Options(); assert(#BuffTap.ConsumableFamilies==3 and #BuffTap.options.consumableRows==3); for _,family in ipairs(BuffTap.ConsumableFamilies) do assert(not family.stockOnly and family.key~='potion-stock'); for _,item in ipairs(family.items) do assert(item.id~=118) end end; assert(BuffTap.version=='1.9.0')")

test('Bounce requires matching failure and reason in either order', """
BuffTap.db.helperBounce=true; SPELL_FAILED_AURA_BOUNCED='Stronger effect'
BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED)
assert(not BuffTap.helperDismissed)
BuffTap:HandleHelperFailure(999); assert(not BuffTap.helperDismissed and not BuffTap.helperAttempt)
BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:HandleHelperFailure(BuffTap.action.id)
assert(not BuffTap.helperDismissed); BuffTap:HandleHelperError('Other error'); assert(not BuffTap.helperAttempt)
BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED)
BuffTap:HandleHelperFailure(BuffTap.action.id); advance(.1); assert(BuffTap.action.key=='thorns')
""")
test('Late and interrupted failures cannot suppress reminders', """
BuffTap.db.helperBounce=true; SPELL_FAILED_AURA_BOUNCED='Stronger effect'
BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED)
now=now+1; BuffTap:HandleHelperFailure(BuffTap.action.id); assert(not BuffTap.helperDismissed)
BuffTap:BeginHelperAttempt(BuffTap.action)
BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_INTERRUPTED','player','cast',BuffTap.action.id)
BuffTap:HandleHelperFailure(BuffTap.action.id); BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED)
assert(not BuffTap.helperDismissed)
""")
test('Consumable bounce matches use spell rather than item ID', """
stock(13510,17626); consumables('flask'); refresh()
BuffTap.db.helperBounce=true; SPELL_FAILED_AURA_BOUNCED='Stronger effect'
BuffTap:BeginHelperAttempt(BuffTap.action); assert(BuffTap.helperAttempt.spellID==17626)
BuffTap:HandleHelperFailure(13510); assert(not BuffTap.helperAttempt)
BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:HandleHelperFailure(17626)
BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(BuffTap:HelperSuppressed(BuffTap.action))
""")
test('Tracker selection is explicit and invalid preferences reset', tracking+"""
BuffTap.db.helperTracker=nil; BuffTap:InitDB(); assert(BuffTap.db.helperTracker==0)
refresh(); assert(not BuffTap.action)
for _,value in ipairs({999,'2580',0/0,{}}) do BuffTap.db.helperTracker=value; BuffTap:InitDB(); assert(BuffTap.db.helperTracker==0) end
BuffTap.db.helperTracker=2580; BuffTap:InitDB(); assert(BuffTap.db.helperTracker==2580)
""")
test('Party coverage includes Shadow Protection', """
BuffTap.db.helperCoverage=true; UnitClass=function() return 'Priest','PRIEST' end
refresh(); assert(table.concat(BuffTap:CoverageLines(),';'):find('Shadow Protection'))
for _,u in ipairs({'player','party1','party2'}) do aura(u,976,'Shadow Protection') end
refresh(); assert(not table.concat(BuffTap:CoverageLines(),';'):find('Shadow Protection'))
""")
