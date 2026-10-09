from test_visual_polish import test, tests
from test_coatings import modern
from test_readiness import ready
lock=modern+'''
playerClass='WARLOCK'; BuffTap.db.weaponCoatings.main=nil
BuffTap.db.weaponChoices.main='warlock-firestone'
stock(13699,17945)
'''
test('Warlock stone preferences default to None',modern+"playerClass='WARLOCK'; BuffTap.db.weaponCoatings.main=nil; stock(13699,17945); refresh(); assert(not BuffTap.action)")
test('Warlock Firestone uses mainhand secure item action',lock+"refresh(); assert(BuffTap.action.itemID==13699 and BuffTap.action.id==17945 and not BuffTap.action.manual and BuffTap.button.attrs['target-slot']==16 and BuffTap.button.attrs.item=='item:13699')")
test('Warlock carried higher Firestone rank wins',lock+"stock(13701,17949); stock(1254,758); refresh(); assert(BuffTap.action.itemID==13701)")
test('Warlock active matching stone satisfies preference',lock+"coat(0,1823,3600,3); refresh(); assert(not BuffTap.action)")
test('Warlock any Firestone rank satisfies Firestone preference',lock+"coat(0,1803,3600,3); refresh(); assert(not BuffTap.action)")
test('Warlock Spellstone is preserved under Firestone until replacement opt-in',lock+"coat(0,8059,3600,3); refresh(); assert(not BuffTap.action); BuffTap.db.weaponReplace=true; refresh(); assert(BuffTap.action.itemID==13699 and BuffTap.action.needState=='different')")
test('Warlock unknown imbue is preserved even with replacement enabled',lock+"coat(0,99999,3600,3); refresh(); assert(not BuffTap.action); BuffTap.db.weaponReplace=true; refresh(); assert(BuffTap.action.manual and not next(bindings))")
test('Warlock expiring stone is reapplied at the threshold',lock+"BuffTap.db.weaponSeconds=60; coat(0,1823,30,3); refresh(); assert(BuffTap.action.itemID==13699 and BuffTap.action.needState=='expiring')")
test('Warlock offhand-only weapon never receives a stone',lock+"local instant=C_Item.GetItemInfoInstant; C_Item.GetItemInfoInstant=function(id) if id==9001 then return id,'Weapon','','INVTYPE_WEAPONOFFHAND',135274,2,15 end return instant(id) end; refresh(); assert(not BuffTap.action)")
test('Warlock staff and two-hander accept stones',lock+"local instant=C_Item.GetItemInfoInstant; C_Item.GetItemInfoInstant=function(id) if id==9001 then return id,'Weapon','','INVTYPE_2HWEAPON',135274,2,10 end return instant(id) end; refresh(); assert(BuffTap.action.itemID==13699)")
test('Warlock offhand preference is never used',lock+"BuffTap.db.weaponMainHand=false; BuffTap.db.weaponChoices.off='warlock-firestone'; equipWeapon(17,9002); refresh(); assert(not BuffTap.action)")
test('Warlock manual mode has no application binding',lock+"BuffTap.db.weaponApply=false; refresh(); assert(BuffTap.action.manual and not next(bindings))")
test('Warlock stone stock change before click clears secure action',lock+"refresh(); bags[13699]=0; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not next(bindings))")
test('Warlock out of stones gives a manual reminder that restocks',lock+"bags[13699]=0; refresh(); assert(BuffTap.action.manual); bags[13699]=1; BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(.2); assert(BuffTap.action.itemID==13699 and not BuffTap.action.manual)")
test('Warlock stones and oils stay independent',lock+"BuffTap.db.weaponCoatings.main='wizard-oil'; coat(0,1823,3600,3); refresh(); assert(BuffTap.action.itemID==20750); table.insert(enchantLists[0],{hasEnchant=true,enchantType=2,enchantID=2627,timeLeft=3600000}); refresh(); assert(not BuffTap.action)")
test('Warlock supplies count the selected stone',lock+"BuffTap.db.suppliesEnabled=true; BuffTap.supplyInventoryReady=true; BuffTap:InvalidateSupplies(true); local rows=BuffTap:SyncSupplies(true); assert(#rows==1 and rows[1].key=='imbue:warlock-firestone' and rows[1].count==5)")
test('Mage cannot select Warlock stones',lock+"playerClass='MAGE'; refresh(); assert(not BuffTap:WeaponPreference('main') and not BuffTap.action)")
test('Every Warlock stone rank prepares and recognizes its exact imbue',lock+'''local count=0
for _,choice in ipairs(BuffTap.WeaponChoices) do if choice.class=='WARLOCK' then
  BuffTap.db.weaponChoices.main=choice.key
  for n,pair in ipairs(choice.items) do bags={}; stock(pair[1],pair[2]); enchantLists[0]={}; refresh()
    assert(BuffTap.action.itemID==pair[1] and BuffTap.action.id==pair[2] and not BuffTap.action.manual,choice.key)
    coat(0,choice.enchants[n],3600,3); refresh(); assert(not BuffTap.action,choice.key); count=count+1 end
end end
assert(count==7)''')

soul=ready+"""
BuffTap.db.helperPet=false; BuffTap.db.helperSoulstone=true
stock(16896,20765); bags[6265]=2
NUM_BAG_SLOTS=4; freeSlots=4; bagFamily=0; bagContents={}
C_Container={
 GetContainerNumSlots=function(b) return b==0 and 4 or 0 end,
 GetContainerNumFreeSlots=function(b) return freeSlots,bagFamily end,
 GetContainerItemID=function(b,s) return bagContents[s] end,
 GetContainerItemInfo=function(b,s) return bagContents[s] and {itemID=bagContents[s],stackCount=1} end,
}
inRange={}
C_Item.IsItemInRange=function(id,u) return inRange[u] end
classes={party1='WARRIOR',party2='MAGE'}
UnitClass=function(u) return 'Class',u=='player' and 'WARLOCK' or classes[u] end
"""
healer=soul+"classes.party2='PRIEST'; inRange.party2=true\n"
test('Soulstone helper is off by default',"assert(BuffTap.db.helperSoulstone==false)")
test('Soulstone helper is Warlock-only',soul+"playerClass='MAGE'; BuffTap.readinessClassToken=nil; UnitClass=function() return 'Class','MAGE' end; refresh(); assert(not BuffTap.action)")
test('Soulstone without healer uses carried stone on yourself',soul+"refresh(); local a=BuffTap.action; assert(a.key=='soulstone' and a.itemID==16896 and a.id==20765 and a.target=='player'); assert(BuffTap.button.attrs.type1=='item' and BuffTap.button.attrs.item=='item:16896' and BuffTap.button.attrs.unit=='player' and not BuffTap.button.attrs.spell); assert(next(bindings))")
test('Soulstone prefers an in-range healer',healer+"refresh(); assert(BuffTap.action.target=='party2' and BuffTap.button.attrs.unit=='party2')")
test('Soulstone skips healers out of range or with unknown range',healer+"inRange.party2=false; refresh(); assert(BuffTap.action.target=='player'); inRange.party2=nil; refresh(); assert(BuffTap.action.target=='player')")
test('Soulstone skips a dead healer',healer+"UnitIsDeadOrGhost=function(u) if u=='party2' then return true end return false end; refresh(); assert(BuffTap.action.target=='player')")
test('First healer in group order wins',healer+"classes.party1='DRUID'; inRange.party1=true; refresh(); assert(BuffTap.action.target=='party1')")
test('Soulstone on yourself satisfies the helper',soul+"aura('player',20765,'Soulstone Resurrection'); refresh(); assert(not BuffTap.action)")
test('Soulstone on any group member satisfies the helper',soul+"for _,id in ipairs({20707,20762,20763,20764,20765}) do auras={}; aura('party1',id,'Soulstone Resurrection'); refresh(); assert(not BuffTap.action,id) end")
test('Soulstone expiry wakes the helper without polling',soul+"aura('party1',20765,'Soulstone Resurrection',100); refresh(); assert(not BuffTap.action); now=now+50; auras={}; advance(51); assert(BuffTap.action and BuffTap.action.key=='soulstone')")
test('Party Soulstone aura event refreshes with group buffing off',soul+"assert(not BuffTap.db.group); refresh(); assert(BuffTap.action); auras.party2={{spellId=20765,name='Soulstone Resurrection',duration=1800,expirationTime=now+1800}}; event('UNIT_AURA','party2'); advance(1); assert(not BuffTap.action)")
test('Unreadable group aura fails closed',soul+"local get=C_UnitAuras.GetAuraDataByIndex; C_UnitAuras.GetAuraDataByIndex=function(u,i) if u=='party1' then error('blocked') end return get(u,i) end; refresh(); assert(not BuffTap.action)")
test('Soulstone cooldown suppresses placement and wakes',soul+"local cd=true; C_Item.GetItemCooldown=function() if cd then return now-10,1800,true end return 0,0,true end; refresh(); assert(not BuffTap.action); cd=false; advance(1800); assert(BuffTap.action and BuffTap.action.itemID==16896)")
test('Highest carried Soulstone rank is used',soul+"bags[16896]=0; stock(5232,20707); stock(16893,20763); refresh(); assert(BuffTap.action.itemID==16893 and BuffTap.action.id==20763)")
test('Changed Soulstone item spell is rejected',soul+"items[16896].spell=999; refresh(); assert(not BuffTap.action)")
test('No carried Soulstone offers highest learned Create Soulstone',soul+"bags[16896]=0; spell(693,'Create Soulstone'); spell(20757,'Create Soulstone'); refresh(); assert(BuffTap.action.id==20757 and BuffTap.button.attrs.type1=='spell' and BuffTap.button.attrs.unit=='player' and not BuffTap.button.attrs.item)")
test('Create Soulstone needs a shard and a free bag slot',soul+"bags[16896]=0; spell(20757,'Create Soulstone'); bags[6265]=0; refresh(); assert(not BuffTap.action); bags[6265]=1; freeSlots=0; BuffTap.readinessInventory=nil; refresh(); assert(not BuffTap.action)")
test('Create Soulstone unlearned stays silent',soul+"bags[16896]=0; refresh(); assert(not BuffTap.action)")
test('Healthstone and Soulstone inventories are cached separately',soul+"BuffTap.db.helperHealthstone=true; spell(6201,'Create Healthstone'); stock(5512,6262); bags[5512]=0; refresh(); assert(BuffTap.action.id==6201); bags[5512]=1; event('BAG_UPDATE_DELAYED'); advance(.3); assert(BuffTap.action.key=='soulstone')")
test('Healer leaving range before click clears the Soulstone action',healer+"refresh(); assert(BuffTap.action.target=='party2'); inRange.party2=false; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not BuffTap.button.attrs.type1 and not next(bindings))")
test('Soulstone placed by someone else before click clears the action',soul+"refresh(); aura('party1',20765,'Soulstone Resurrection'); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('Soulstone placement rejects movement',soul+"speed=4; refresh(); assert(not BuffTap.action); speed=0; event('PLAYER_STOPPED_MOVING'); advance(.1); assert(BuffTap.action.key=='soulstone')")
test('Soulstone use holds while the cast settles',soul+"refresh(); BuffTap:AfterReadinessClick(BuffTap.action,true); event('UNIT_SPELLCAST_START','player','c',20765); refresh(); assert(not BuffTap.action); event('UNIT_SPELLCAST_SUCCEEDED','player','c',20765); aura('player',20765,'Soulstone Resurrection'); advance(3); assert(not BuffTap.readinessPending and not BuffTap.action)")
test('Soulstone options toggle and tooltip render',soul+"refresh(); BuffTap.button.scripts.OnEnter(); BuffTap:Options()")

create=lock+"""
bags[13699]=0; bags[6265]=2; speed=0; GetUnitSpeed=function() return speed end; UnitInVehicle=function() return false end
function event(e,...) BuffTap.events.scripts.OnEvent(nil,e,...) end
NUM_BAG_SLOTS=4; freeSlots=4; bagFamily=0; bagContents={}
C_Container={
 GetContainerNumSlots=function(b) return b==0 and 4 or 0 end,
 GetContainerNumFreeSlots=function(b) return freeSlots,bagFamily end,
 GetContainerItemID=function(b,s) return bagContents[s] end,
 GetContainerItemInfo=function(b,s) return bagContents[s] and {itemID=bagContents[s],stackCount=1} end,
}
spell(6366,'Create Firestone'); spell(17951,'Create Firestone')
"""
test('Missing Firestone is created first with a plain self cast',create+"refresh(); local a=BuffTap.action; assert(a.source=='readiness' and a.key=='weaponstone' and a.id==17951); assert(BuffTap.button.attrs.type1=='spell' and BuffTap.button.attrs.spell==17951 and BuffTap.button.attrs.unit=='player' and not BuffTap.button.attrs['target-slot'] and not BuffTap.button.attrs.item)")
test('Created Firestone is then applied to the main hand',create+"refresh(); BuffTap:AfterReadinessClick(BuffTap.action,true); event('UNIT_SPELLCAST_START','player','c',17951); event('UNIT_SPELLCAST_SUCCEEDED','player','c',17951); bags[13699]=1; event('BAG_UPDATE_DELAYED'); advance(3); local a=BuffTap.action; assert(a and a.source=='weapon-reminder' and a.itemID==13699 and not a.manual and BuffTap.button.attrs['target-slot']==16)")
test('Highest learned Create Firestone rank is used',create+"spell(17953,'Create Firestone'); stock(13701,17949); bags[13701]=0; refresh(); assert(BuffTap.action.id==17953)")
test('Missing Spellstone is created first',create+"BuffTap.db.weaponChoices.main='warlock-spellstone'; spell(2362,'Create Spellstone'); stock(5522,1237152); bags[5522]=0; refresh(); assert(BuffTap.action.key=='weaponstone' and BuffTap.action.id==2362)")
test('Active preferred stone needs no creation',create+"coat(0,1823,3600,3); refresh(); assert(not BuffTap.action)")
test('Expiring stone with none carried is created ahead of time',create+"coat(0,1823,30,3); refresh(); assert(BuffTap.action.key=='weaponstone')")
test('Other stone kept without replacement creates nothing',create+"coat(0,8059,3600,3); refresh(); assert(not BuffTap.action)")
test('Unknown imbue blocks creation',create+"coat(0,99999,3600,3); refresh(); assert(not BuffTap.action or BuffTap.action.key~='weaponstone')")
test('No Soul Shard falls back to the manual out-of-stock reminder',create+"bags[6265]=0; refresh(); assert(BuffTap.action.source=='weapon-reminder' and BuffTap.action.manual and not next(bindings))")
test('Full bags fall back to the manual out-of-stock reminder',create+"freeSlots=0; refresh(); assert(BuffTap.action.source=='weapon-reminder' and BuffTap.action.manual)")
test('Unlearned Create Firestone falls back to the manual reminder',create+"spells[6366].known=false; spells[17951].known=false; refresh(); assert(BuffTap.action.source=='weapon-reminder' and BuffTap.action.manual)")
test('Incompatible main hand never creates a stone',create+"local instant=C_Item.GetItemInfoInstant; C_Item.GetItemInfoInstant=function(id) if id==9001 then return id,'Weapon','','INVTYPE_WEAPONOFFHAND',135274,2,15 end return instant(id) end; refresh(); assert(not BuffTap.action)")
test('Stone creation waits while moving',create+"speed=3; refresh(); assert(not BuffTap.action or BuffTap.action.key~='weaponstone'); speed=0; event('PLAYER_STOPPED_MOVING'); advance(.1); assert(BuffTap.action.key=='weaponstone')")
test('Stone arriving before click cancels creation',create+"refresh(); bags[13699]=1; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action or BuffTap.action.key~='weaponstone')")
test('Main hand disabled creates nothing',create+"BuffTap.db.weaponMainHand=false; refresh(); assert(not BuffTap.action)")
test('Remind-only mode still creates, then reminds to apply',create+"BuffTap.db.weaponApply=false; refresh(); assert(BuffTap.action.key=='weaponstone'); bags[13699]=1; event('BAG_UPDATE_DELAYED'); advance(.3); assert(BuffTap.action.source=='weapon-reminder' and BuffTap.action.manual)")

roles=soul+"roles={}; UnitGroupRolesAssigned=function(u) return roles[u] or 'NONE' end\n"
raid=soul+"""
IsInRaid=function() return true end; GetNumGroupMembers=function() return 3 end
local exists=UnitExists; UnitExists=function(u) if u=='raid1' or u=='raid2' or u=='raid3' then return true end return exists(u) end
UnitIsUnit=function(a,b) return a==b or (a=='raid1' and b=='player') or (a=='player' and b=='raid1') end
classes.raid2='PRIEST'; classes.raid3='WARLOCK'; inRange.raid2=true
"""
test('Soulstone prefers the Healer role over healing classes',roles+"classes.party1='PRIEST'; roles.party1='DAMAGER'; inRange.party1=true; classes.party2='WARRIOR'; roles.party2='HEALER'; inRange.party2=true; refresh(); assert(BuffTap.action.target=='party2')")
test('Soulstone never picks a tanking or damage healer class when roles are set',roles+"classes.party1='PALADIN'; roles.party1='TANK'; inRange.party1=true; classes.party2='SHAMAN'; roles.party2='DAMAGER'; inRange.party2=true; refresh(); assert(BuffTap.action.target=='player')")
test('Soulstone falls back to healing class when no roles are set',roles+"classes.party2='PRIEST'; inRange.party2=true; refresh(); assert(BuffTap.action.target=='party2')")
test('Raid Soulstone gives a manual reminder without a target or binding',raid+"refresh(); local a=BuffTap.action; assert(a.key=='soulstone' and a.manual and a.targetName=='Soulstone • raid'); assert(not BuffTap.button.attrs.type1 and not BuffTap.button.attrs.unit and not next(bindings))")
test('Raid Soulstone from another Warlock does not count',raid+"auras.raid2={{spellId=20765,name='Soulstone Resurrection',duration=1800,expirationTime=now+1800,sourceUnit='raid3'}}; refresh(); assert(BuffTap.action and BuffTap.action.manual)")
test('Raid Soulstone you cast satisfies the helper',raid+"auras.raid2={{spellId=20765,name='Soulstone Resurrection',duration=1800,expirationTime=now+1800,sourceUnit='player'}}; refresh(); assert(not BuffTap.action); auras.raid2[1].sourceUnit='raid1'; refresh(); assert(not BuffTap.action)")
test('Raid still offers Create Soulstone when none is carried',raid+"bags[16896]=0; spell(20757,'Create Soulstone'); refresh(); assert(BuffTap.action.id==20757 and not BuffTap.action.manual)")

named=roles+"names={party1={'Bob'},party2={'Carol','Realm'}}; UnitName=function(u) if u=='player' then return 'Tester' end local n=names[u]; if n then return n[1],n[2] end return 'Ally' end; classes.party1='PRIEST'; inRange.party1=true; inRange.party2=true\n"
test('Soulstone settings default to Healer in party and reminder in raid',"assert(BuffTap.db.soulstoneParty=='healer' and BuffTap.db.soulstoneRaid=='remind' and BuffTap.db.soulstoneAssigned=='')")
test('Invalid Soulstone settings are reset',"BuffTapDB.soulstoneParty='x'; BuffTapDB.soulstoneRaid=5; BuffTapDB.soulstoneAssigned=string.rep('a',80); BuffTap:InitDB(); assert(BuffTap.db.soulstoneParty=='healer' and BuffTap.db.soulstoneRaid=='remind' and BuffTap.db.soulstoneAssigned=='')")
test('Party mode Me ignores healers',named+"BuffTap.db.soulstoneParty='self'; refresh(); assert(BuffTap.action.target=='player')")
test('Party mode Assigned player targets them by name',named+"BuffTap.db.soulstoneParty='assigned'; BuffTap.db.soulstoneAssigned='carol'; refresh(); assert(BuffTap.action.target=='party2' and BuffTap.button.attrs.unit=='party2')")
test('Assigned name with realm must match the realm',named+"BuffTap.db.soulstoneParty='assigned'; BuffTap.db.soulstoneAssigned='Carol-Realm'; refresh(); assert(BuffTap.action.target=='party2'); BuffTap.db.soulstoneAssigned='Carol-Other'; refresh(); assert(BuffTap.action.target=='party1')")
test('Assigned player missing falls back to the healer',named+"BuffTap.db.soulstoneParty='assigned'; BuffTap.db.soulstoneAssigned='Dave'; refresh(); assert(BuffTap.action.target=='party1')")
test('Assigned player out of range falls back to healer then you',named+"BuffTap.db.soulstoneParty='assigned'; BuffTap.db.soulstoneAssigned='Carol'; inRange.party2=false; refresh(); assert(BuffTap.action.target=='party1'); inRange.party1=false; refresh(); assert(BuffTap.action.target=='player')")
test('Raid assigned player gets the Soulstone',raid+"UnitName=function(u) if u=='raid2' then return 'Carol' end return u=='player' and 'Tester' or 'Ally' end; BuffTap.db.soulstoneRaid='assigned'; BuffTap.db.soulstoneAssigned='Carol'; refresh(); assert(BuffTap.action.target=='raid2' and not BuffTap.action.manual and BuffTap.button.attrs.unit=='raid2')")
test('Raid assigned player out of range gives a manual reminder naming them',raid+"UnitName=function(u) if u=='raid2' then return 'Carol' end return u=='player' and 'Tester' or 'Ally' end; BuffTap.db.soulstoneRaid='assigned'; BuffTap.db.soulstoneAssigned='Carol'; inRange.raid2=false; refresh(); assert(BuffTap.action.manual and BuffTap.action.reason:find('Carol') and not next(bindings))")
test('Raid assigned mode with nobody assigned stays a reminder',raid+"BuffTap.db.soulstoneRaid='assigned'; refresh(); assert(BuffTap.action.manual)")
test('Use current target saves a friendly player name with realm',soul+"UnitName=function(u) if u=='target' then return 'Carol','Realm' end return 'Tester' end; assert(BuffTap:SetSoulstoneAssignedFromTarget() and BuffTap.db.soulstoneAssigned=='Carol-Realm')")
test('Use current target rejects non-players',soul+"UnitIsPlayer=function(u) return u~='target' end; assert(not BuffTap:SetSoulstoneAssignedFromTarget() and BuffTap.db.soulstoneAssigned=='')")
test('Soulstone target popup reflects saved settings',soul+"BuffTap.db.soulstoneParty='assigned'; BuffTap.db.soulstoneRaid='assigned'; BuffTap.db.soulstoneAssigned='Carol'; BuffTap:Options(); local f=BuffTap.helperWindow; assert(f.soulTarget.shown); local sm=f.soulMenu; assert(sm.party.assigned.checked and not sm.party.healer.checked and sm.raid.assigned.checked and not sm.raid.remind.checked); assert(sm.assignedLabel.text:find('Carol')); sm.party.self.scripts.OnClick(sm.party.self); assert(BuffTap.db.soulstoneParty=='self'); sm.clear.scripts.OnClick(sm.clear); assert(BuffTap.db.soulstoneAssigned=='')")
print('ALL',len(tests),'SCENARIOS PASSED')
