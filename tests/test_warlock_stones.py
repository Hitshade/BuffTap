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
print('ALL',len(tests),'SCENARIOS PASSED')
