from test_bufftap import test

for locale in ('deDE','esES','frFR','ptBR'):
 test('1.25 category and setup labels translated '+locale,
      "local B=BuffTap; assert(B:Text('Review class setup')~='Review class setup'); B:Options(); B:ChooseConsumable(B:ConsumableFamily('food')); assert(B.itemPicker.category:GetText()~='Category: All')",locale=locale)

test('1.25 class buff configuration is identical at level one and sixty',
     "local B=BuffTap; spells={}; book={}; for _,class in ipairs({'DRUID','PALADIN','PRIEST','SHAMAN','MAGE','WARLOCK','WARRIOR','ROGUE','HUNTER'}) do playerClass=class; UnitLevel=function() return 1 end; local low=B:ClassList(); UnitLevel=function() return 60 end; local high=B:ClassList(); assert(#low==#high,class); for i,b in ipairs(low) do assert(b.key==high[i].key,class) end end")

test('Manual quick review preserves the profile and Shaman weapon',"local B=BuffTap; playerClass='SHAMAN'; B.db.welcomeSeen=true; B.db.weaponChoices.main='rockbiter'; local original=B.profileDB:GetCurrentProfile(); B:ShowOnboarding(true); B:OnboardingSettingsPage(); B:ApplyOnboarding(); assert(B.profileDB:GetCurrentProfile()==original and B.db.weaponChoices.main=='rockbiter' and not B.profileDB.sv.profiles[original..' backup'])")

test('Quick setup selections persist across Back without applying','local B=BuffTap; B:ShowOnboarding(true); B:OnboardingSettingsPage(); B.onboarding.quickSelection.sounds=true; B:OnboardingWelcomePage(); assert(not B.db.sound and B.onboarding.quickSelection.sounds); B:OnboardingSettingsPage(); B:ApplyOnboarding(); assert(B.db.sound)')

test('1.25 UI mock rejects parenting a frame to a texture',
     "local f=CreateFrame('Frame'); local t=f:CreateTexture(); assert(not pcall(function() f:SetParent(t) end))")

test('1.25 Food and Elixir categories open a selectable menu',
     "local B=BuffTap; B:Options(); for _,key in ipairs({'food','ferocity'}) do local family=B:ConsumableFamily(key); assert(family,key); B:ChooseConsumable(family); local f=B.itemPicker; assert(#f.categoryChoices>1,key); f.category.scripts.OnClick(f.category); assert(f.category.menu:IsShown(),key); local row=f.category.menu.rows[2]; assert(row and row.choice); row.scripts.OnClick(row); assert(f.categoryKey~='all' and not f.category.menu:IsShown(),key) end")

test('Paladin quick review keeps an existing blessing plan',"local B=BuffTap; playerClass='PALADIN'; B.db.welcomeSeen=true; B.db.blessingClasses={WARRIOR='bom'}; B:ShowOnboarding(true); B:OnboardingSettingsPage(); B:ApplyOnboarding(); assert(B.db.blessingClasses.WARRIOR=='bom')")

FORM=("local B=BuffTap; playerClass='DRUID'; spell(768,'Cat Form'); "
      "local form=1; GetShapeshiftForm=function() return form end; "
      "GetShapeshiftFormInfo=function(i) if i==1 then return 132115,form==1,true,768 end end; "
      "C_Spell.GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true} end; "
      "B.db.smartShift=true; ")

test('1.25 SmartShift is opt in and class scoped',
     "local B=BuffTap; assert(B.db.smartShift==false); B:Options(); playerClass='DRUID'; B:Options(); assert(B.options.smartShift.shown); playerClass='MAGE'; B:Options(); assert(not B.options.smartShift.shown)")

test('1.25 SmartShift captures a real form spell and offers one silent return',
     FORM+"local a={source='spell',id=5232,target='player',targetGUID=UnitGUID('player')}; B:SmartShiftBegin(a); assert(B.smartShiftIntent and B.smartShiftIntent.spellID==768); form=0; B:SmartShiftCastSucceeded(5232); local r=B:SmartShiftAction(); assert(r and r.source=='smartshift' and r.id==768 and r.target=='player'); local heard=0; PlaySound=function() heard=heard+1; return true end; B.db.sound=true; B:Commit(r,'test'); assert(B.action==r and B.button.attrs.spell==768 and heard==0)")

test('1.25 SmartShift never toggles an already active form',
     FORM+"B.smartShiftIntent={spellID=768,buffID=5232,started=GetTime(),verified=true,exited=true}; assert(not B:SmartShiftAction(),'active'); form=0; local r=B:SmartShiftAction(); assert(r,'missing restore'); B:Commit(r,'test'); form=1; B.button.scripts.PreClick(nil,'LeftButton',false); assert(not (B.action and B.action.source=='smartshift') and not B.button.attrs.spell,'stale action')")

test('1.25 SmartShift cancels failures combat zones and manual form changes',
     FORM+"B:SmartShiftBegin({source='spell',id=5232,target='player',targetGUID=UnitGUID('player')}); B:SmartShiftEvent('UNIT_SPELLCAST_FAILED','player',nil,5232); assert(not B.smartShiftIntent); B:SmartShiftBegin({source='spell',id=5232,target='player',targetGUID=UnitGUID('player')}); form=2; GetShapeshiftFormInfo=function(i) if i==2 then return 1,true,true,783 end end; spell(783,'Travel Form'); B:SmartShiftEvent('UPDATE_SHAPESHIFT_FORM'); assert(not B.smartShiftIntent)")

test('1.25 approved poison manifest uses exact item effect and enchant IDs',
     "local found={}; for _,c in ipairs(BuffTap.WeaponChoices) do found[c.key]=c end; assert(found['atrophic-poison'].items[1][1]==217347 and found['atrophic-poison'].enchants[1]==7256); assert(found['numbing-poison'].items[1][2]==439464 and found['sebacious-poison'].enchants[1]==7254); local o=found['occult-poison']; assert(o.items[1][1]==234444 and o.items[1][2]==1214171 and o.items[2][1]==226374 and o.items[2][2]==458821)")

test('1.25 food and elixir metadata is display only and multi category',
     "local food=BuffTap:ConsumableFamily('food'); local ferocity; for _,i in ipairs(BuffTap:ConsumableFamily('ferocity').items) do if i.id==250350 then ferocity=i end end; assert(food.items[1].benefitShort and #food.items[1].displayCategories>0); local seen={}; for _,k in ipairs(ferocity.displayCategories) do seen[k]=true end; assert(seen.strength and seen.agility and seen.hybrid); assert(not BuffTap:ConsumableFamily('potion'))")

test('1.25 SmartShift and adaptive ownership survive class profile export',
     "local B=BuffTap; playerClass='DRUID'; B.db.smartShift=true; B.db.smartPreset={version=1,managed={['weapon:main']=true}}; local text=B:ExportSettings(); B.db.smartShift=false; B.db.smartPreset=nil; local ok=B:ImportSettings(text); assert(ok and B.db.smartShift==true and B.db.smartPreset.managed['weapon:main']==true)")

