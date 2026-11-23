from test_bufftap import test, ROOT
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
for cls in ('DRUID','MAGE','PRIEST','PALADIN','WARRIOR','HUNTER','SHAMAN','WARLOCK','ROGUE'):
 for locale in ('enUS','deDE'):
  for learned in (False,True):
   test('Class-aware pages '+cls+' '+locale+' '+str(learned),RECORD+"playerClass='"+cls+"'; "+("spells={}; book={}; " if not learned else '')+"""
local B=BuffTap; B:InitDB(); B.db.nearbyWhileResting=false; B.db.nearbyManaFloor=50
B.db.nearbyReturnFavor=true; B:Options(); local f=B.options; local c=B:NearbyCapabilities()
assert(f.nearbyBuffing.shown==c.buffs and f.nearbyFavor.shown==c.buffs)
assert(f.nearbyPvp.shown==c.actions and f.nearbyManaFloor.shown==c.actions)
assert(f.nearbyManaFloor.valueText.shown==c.actions and f.nearbyWhileResting.shown==c.actions)
assert(f.nearbyRankUpgrades.shown==c.upgrades and f.nearbyHoldShort.shown==(c.buffs and c.short))
assert(f.nearbyAll.shown~=false and f.nearbyInvites.shown~=false and f.nearbyFullNames.shown~=false,'base controls: '..tostring(f.nearbyAll.shown)..'/'..tostring(f.nearbyInvites.shown)..'/'..tostring(f.nearbyFullNames.shown))
assert(f.nearbySettingsCard.__draw.h==(c.actions and 216 or 138))
local noTarget=playerClass=='WARRIOR' or playerClass=='HUNTER' or playerClass=='ROGUE'
assert(f.pages[3].classEmpty.shown==noTarget,'target applicability')
assert(f.pages[1].classEmpty.shown~=true and f.pages[1].classHidden==nil,'My buffs stays open for every class: the Tracking tab lives there')
assert(B.db.nearbyManaFloor==50 and B.db.nearbyReturnFavor==true,'hidden prefs retained')
if not c.actions then
 local p=f.nearbyInvites.__draw.points[1]; assert(p[2]==374 and p[3]==-112)
 assert(f.nearbyGuide.__draw.points[1][3]==-292,'guide must move with compact card')
 IsResting=function() return true end; B.db.pauseResting=false; B.ManaFloorReached=function() error('no meaningless mana read') end
 assert(not B:NearbyPauseReason(),'browsing should not be paused for unusable casting preferences')
 B.db.nearbyEnabled=true; B:CreateNearbyWindow(); B:UpdateNearbyWindow(); assert(not B.nearbyFrame.resting.shown)
end
""",locale)
WEAPON="""
playerClass='ROGUE'; spells={}; book={}; UnitLevel=function() return 1 end
Enum.WeaponSlot={MainHand=0,OffHand=1}; Enum.ItemEnchantType={None=0,Permanent=1,Temporary=2,Imbue=3}
C_Item.GetWeaponEnchantInfo=function() return {} end
local B=BuffTap; B:InitDB(); B.db.group=false; B.db.weaponReminder=true
B.db.weaponCoatings.main='elemental-sharpening-stone'; B.db.weaponOffHand=false
equipWeapon(16,9001); B:InvalidateRoster()
local old=C_Item.GetItemInfo
C_Item.GetItemInfo=function(id) if id==18262 then return 'Elemental Sharpening Stone','item:18262',1,60,50,'Consumable','',1,'',12345 end return old(id) end
"""
for apply in (False,True):
 test('Level-one rogue saved stone stays quiet '+str(apply),WEAPON+"B.db.weaponApply="+str(apply).lower()+"; refresh(); assert(not B.action); assert(B.db.weaponCoatings.main=='elemental-sharpening-stone')")
test('Missing item metadata cannot emit impossible alert',WEAPON+"C_Item.GetItemInfo=function() return nil end; refresh(); assert(not B.action)")
test('Level-eligible saved coating can still remind when empty',WEAPON+"UnitLevel=function() return 60 end; refresh(); assert(B.action and B.action.coating and B.action.manual)")
test('Skip empty still suppresses eligible coating',WEAPON+"UnitLevel=function() return 60 end; B.db.weaponSkipEmpty=true; refresh(); assert(not B.action)")
test('Carried unusable stone cannot emit reminder',WEAPON+"stock(18262,22756); items[18262].usable=false; refresh(); assert(not B.action)")
test('Level check does not trust a contradictory usable result',WEAPON+"stock(18262,22756); refresh(); assert(not B.action)")
test('Level-one Rogue with clean preferences has no weapon alert',WEAPON+"B.db.weaponCoatings={}; B.db.weaponChoices={}; B.db.weaponApply=true; refresh(); assert(not B.action and not B:WeaponReminderAvailable())")
test('Carried unusable poison does not unlock generic poison alert',WEAPON+"B.db.weaponCoatings={}; B.db.weaponChoices.main='deadly-poison'; stock(2892,2823); items[2892].usable=false; refresh(); assert(not B.action and not B:WeaponReminderAvailable())")
test('Usable carried Forever poison remains supported without spellbook entry',WEAPON+"B.db.weaponCoatings={}; B.db.weaponChoices.main='atrophic-poison'; B.db.weaponApply=true; stock(217347,439465); refresh(); assert(B.action and B.action.itemID==217347)")
test('Lower usable coating rank wins when higher level rank is blocked',WEAPON+"B.db.weaponCoatings.main='sharpening-stone'; stock(12404,16138); stock(2862,2828); local old=C_Item.GetItemInfo; C_Item.GetItemInfo=function(id) if id==12404 then return 'Dense stone','item:12404',1,1,50,'Consumable','',1,'',12345 end return old(id) end; B.db.weaponApply=true; refresh(); assert(B.action and B.action.itemID==2862)")

test('Weapon click rechecks item level',WEAPON+"UnitLevel=function() return 60 end; stock(18262,22756); B.db.weaponApply=true; refresh(); assert(B.action and B.action.itemID==18262); UnitLevel=function() return 1 end; B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.action and not B.button.attrs.item and not next(bindings))")
test('Level metadata completion resumes a valid empty preference',WEAPON+"UnitLevel=function() return 60 end; local info=C_Item.GetItemInfo; C_Item.GetItemInfo=function() return nil end; refresh(); assert(not B.action and B.itemRequests[18262]); C_Item.GetItemInfo=info; B.events.scripts.OnEvent(nil,'ITEM_DATA_LOAD_RESULT',18262,true); advance(.2); assert(B.action and B.action.manual and B.action.coating)")
test('Opening fresh Rogue settings never selects items',WEAPON+"B.db.weaponChoices={}; B.db.weaponCoatings={}; B:Options(); assert(not next(B.db.weaponChoices) and not next(B.db.weaponCoatings))")
