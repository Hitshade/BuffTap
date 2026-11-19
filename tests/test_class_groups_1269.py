from test_bufftap import test, ROOT
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
CLASSES=('DRUID','MAGE','PRIEST','PALADIN','WARRIOR','HUNTER','SHAMAN','WARLOCK','ROGUE')
for cls in CLASSES:
 for raid in (False,True):
  for learned in (False,True):
   prefix=RECORD+"playerClass='"+cls+"'; "
   if learned:
    ident,label={'DRUID':(1126,'Mark of the Wild'),'MAGE':(1459,'Arcane Intellect'),'PRIEST':(1243,'Power Word: Fortitude'),'PALADIN':(20217,'Blessing of Kings'),'WARRIOR':(6673,'Battle Shout'),'HUNTER':(19506,'Trueshot Aura'),'SHAMAN':(546,'Water Walking'),'WARLOCK':(132,'Detect Invisibility'),'ROGUE':(8679,'Instant Poison')}[cls]
    prefix+="spell("+str(ident)+",'"+label+"'); "
   if not learned: prefix+="spells={}; book={}; BuffTap.rankChoiceCache=nil; "
   test('Capability page '+cls+' '+str(raid)+' '+str(learned),prefix+"""
local B=BuffTap; B.db.group=true; B.db.buffPets=true
B:Options(); local f=B.options
local c=B:ClassGroupCapabilities()
if f.partyView then
 assert(playerClass=='PALADIN' and f.blessingPanel:IsShown())
else
 if """+str(raid).lower()+""" then f.groupRaid.scripts.OnClick() end
 assert(f.groupEnable:IsShown()==c.targeted)
 assert(f.legacyGroups:IsShown()==c.targeted and f.groupInfo:IsShown()==not c.targeted)
 assert(f.smartGroup:IsShown()==c.pairs and f.groupNeedSlider:IsShown()==c.pairs)
 assert(f.buffPets:IsShown()==c.pets)
 assert(f.roleGuess:IsShown()==c.roles and f.roleMark:IsShown()==c.roles)
 if c.targeted then
  assert(#f.assignRows>0,'unlearned spells must remain configurable')
  for _,row in ipairs(f.assignRows) do
   for _,rb in ipairs(row.roleButtons) do
    local roles=B:BuffGroupCapabilities(row.def).roles
    assert(rb:IsShown()==(roles~=nil and (rb.roleMode=='class' or B:BuffSupportsRole(row.def,rb.roleMode))))
   end
   assert(row.sound and row.classes.WARRIOR)
  end
  assert(f.groupSharedCard.__draw.h==(c.pairs and 146 or 62))
  assert(f.assignmentListCard.__draw.h==f.assignmentDetailCard.__draw.h)
  for _,row in ipairs(f.assignRows) do local p=row.resetClasses.__draw.points[1]; assert(p[3]==(c.pairs and -258 or -342),'footer buttons must follow card height') end
 end
end
assert(B.db.group==true and B.db.buffPets==true,'render must not rewrite saved choices')
""")
for cls in CLASSES:
 test('Fresh group defaults '+cls,"playerClass='"+cls+"'; BuffTapDB={}; BuffTap:InitDB(); assert(BuffTap.db.group=="+str(cls in ('DRUID','MAGE','PRIEST','PALADIN')).lower()+"); assert(BuffTap.db.smartGroup==BuffTap:HasGroupSpellPairs())")
 test('Old explicit group choice preserved '+cls,"playerClass='"+cls+"'; BuffTap.db.group=false; BuffTap.db.groupDefaultVersion=nil; BuffTap:InitDB(); assert(BuffTap.db.group==false); BuffTap.db.group=true; BuffTap:InitDB(); assert(BuffTap.db.group==true)")
for key in ('unending-breath','detect-invis','water-breathing','water-walking','fear-ward','bok'):
 test('Utility pet denied '+key,"local B=BuffTap; B.db.buffPets=true; assert(not B:RecipientAllowed(B:FindBuff('"+key+"'),{unit='pet',pet=true}))")
for key in ('motw','thorns','fort','sp','ai','spirit'):
 test('Approved pet capability '+key,"local B=BuffTap; B.db.buffPets=true; UnitPowerType=function() return 0 end; assert(B:RecipientAllowed(B:FindBuff('"+key+"'),{unit='pet',pet=true})); B.db.buffPets=false; assert(not B:RecipientAllowed(B:FindBuff('"+key+"'),{unit='pet',pet=true}))")
for key in ('ai','spirit'):
 test('Mana pet only '+key,"BuffTap.db.buffPets=true; UnitPowerType=function() return 2 end; assert(not BuffTap:RecipientAllowed(BuffTap:FindBuff('"+key+"'),{unit='pet',pet=true})); UnitPowerType=function() return nil end; assert(not BuffTap:RecipientAllowed(BuffTap:FindBuff('"+key+"'),{unit='pet',pet=true}))")
for cls,key,id,name in [('WARRIOR','battle-shout',6673,'Battle Shout'),('HUNTER','trueshot',19506,'Trueshot Aura')]:
 test('Broadcast self maintenance '+cls,"playerClass='"+cls+"'; spells={}; book={}; spell("+str(id)+",'"+name+"'); local B=BuffTap; B.db.group=false; B.db.buffSelf['"+key+"']=false; B.db.buffRoles['"+key+"']='tank'; B.db.raidGroups[1]=false; B.db.buffGroups['"+key+"']={[1]=false}; refresh(); assert(B.action and B.action.key=='"+key+"' and B.action.target=='player'); assert(not B:RecipientAllowed(B:FindBuff('"+key+"'),{unit='party1'})); assert(B:SelfRecipientAllowed(B:FindBuff('"+key+"'),'Party'))")
for key in ('unending-breath','detect-invis','water-walking','water-breathing','motw','ai','fort'):
 test('Stale unsupported role ignored '+key,"local B=BuffTap; local d=B:FindBuff('"+key+"'); B:GroupSettings('Party',true).buffRoles[B:RootKey(d)]='tank'; assert(B:BuffRoleMode(d,'Party')=='class'); assert(B:GroupSettings('Party').buffRoles[B:RootKey(d)]=='tank')")
test('Thorns and Fear Ward role policy',"local B=BuffTap; assert(B:BuffSupportsRole(B:FindBuff('thorns'),'tank')); assert(not B:BuffSupportsRole(B:FindBuff('thorns'),'healer')); assert(B:BuffSupportsRole(B:FindBuff('fear-ward'),'tank') and B:BuffSupportsRole(B:FindBuff('fear-ward'),'healer'))")
test('Rogue info opens Weapons',"playerClass='ROGUE'; BuffTap:Options(); BuffTap.options.groupWeapons.scripts.OnClick(); assert(BuffTap.options.activeTab==7)")

test('Utility timing ignores hidden top-up state',"local B=BuffTap; B.readyCheckUntil=now+40; assert(B:EarlyTopUpSeconds(45,600,B:FindBuff('unending-breath'))==45); assert(B:EarlyTopUpSeconds(45,600,B:FindBuff('motw'))==300)")
test('Group context retains hidden utility preferences',"playerClass='WARLOCK'; local B=BuffTap; B:InitDB(); local p=B:GroupSettings('Party',true); local r=B:GroupSettings('Raid',true); p.group=true; r.group=false; p.buffRoles['unending-breath']='tank'; r.buffClasses['detect-invis']={WARRIOR=false}; p.smartGroup=true; B.db.buffPets=true; B:InitDB(); assert(B:GroupPreference('group','Party')==true and B:GroupPreference('group','Raid')==false); assert(B:GroupSettings('Party').buffRoles['unending-breath']=='tank'); assert(B:GroupSettings('Raid').buffClasses['detect-invis'].WARRIOR==false); assert(B.db.buffPets==true)")

for cls,key,ident,label in [('WARLOCK','detect-invis',132,'Detect Invisibility'),('SHAMAN','water-walking',546,'Water Walking')]:
 test('Intentional utility party assignment '+cls,"playerClass='"+cls+"'; spells={}; book={}; spell("+str(ident)+",'"+label+"'); local B=BuffTap; B.db.group=true; B.db.smartGroup=true; B.db.buffs['"+key+"']=true; aura('player',"+str(ident)+",'"+label+"'); B:InvalidateRoster(); refresh(); assert(B.action and B.action.key=='"+key+"' and B.action.target=='party1' and not B.action.groupCast); B:GroupSettings('Party',true).buffGroups['"+key+"']={[1]=false}; refresh(); assert(not B.action)")
test('Capability-hidden preferences survive profile copy',"playerClass='WARLOCK'; local B=BuffTap; B:InitDB(); B.db.buffPets=true; B:GroupSettings('Party',true).buffRoles['detect-invis']='tank'; B:GroupSettings('Raid',true).buffClasses['unending-breath']={WARRIOR=false}; B:SaveClassSetup(); local source=B.profileDB:GetCurrentProfile(); local char=B.profileDB.keys.char; B:CreateSettingsProfile('Groups copy',false); assert(B:CopySettingsProfile(source,char)); assert(B:GroupSettings('Party').buffRoles['detect-invis']=='tank'); assert(B:GroupSettings('Raid').buffClasses['unending-breath'].WARRIOR==false)")
