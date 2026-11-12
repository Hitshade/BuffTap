from test_helpers import test,solo
from test_bg_self import setup as bg
from test_target_priority import priority

fallback=solo+"local caster=UnitGUID('target'); C_UnitAuras.GetAuraCasterGUID=function(u,id) assert(u=='player' and id==44); return caster end; auras.player={{spellId=1459,auraInstanceID=44}}; "
test('Aura caster GUID recovers a missing source token',fallback+"BuffTap:ObserveSoloThanks(); assert(#emotes==1 and emotes[1][2]=='target' and BuffTap.helperThankStatus:find('aura GUID / live unit',1,true))")
test('Aura caster GUID recovers a vanished source token',fallback+"auras.player[1].sourceUnit='vanished'; BuffTap:ObserveSoloThanks(); assert(#emotes==1)")
for val in ["nil","{secret=true}","'Creature-123'","UnitGUID('player')"]:
 test('Unverifiable or self aura caster is not thanked '+val,fallback+"C_UnitAuras.GetAuraCasterGUID=function() return "+val+" end; BuffTap:ObserveSoloThanks(); assert(#emotes==0)")
test('Throwing caster GUID API stays silent',fallback+"C_UnitAuras.GetAuraCasterGUID=function() error('restricted') end; BuffTap:ObserveSoloThanks(); assert(#emotes==0)")
test('Caster lookup does not run without a public aura instance',fallback+"auras.player[1].auraInstanceID={secret=true}; C_UnitAuras.GetAuraCasterGUID=function() error('must not query') end; BuffTap:ObserveSoloThanks(); assert(#emotes==0)")
test('Ignored direct provider is excluded',solo+"C_FriendList={IsIgnored=function(u) return u=='target' end}; received(1459,'target'); assert(#emotes==0)")
test('Provider newly ignored while queued is not thanked',solo+"received(1459,'target'); received(1243,'party1'); C_FriendList={IsIgnored=function(u) return u=='party1' end}; advance(1.1); assert(#emotes==1 and BuffTap.helperThankStatus:find('ignored',1,true))")
for guard in ["IsStealthed=function() return true end","UnitIsFeignDeath=function() return true end","C_ChatInfo={InChatMessagingLockdown=function() return true end}","C_ChatInfo={InChatMessagingLockdown=function() return {secret=true} end}","Enum.AddOnRestrictionType={Chat=5}; Enum.AddOnRestrictionState={Inactive=0}; C_RestrictedActions={GetAddOnRestrictionState=function() return 2 end}"]:
 test('Automatic thanks holds for contextual restriction '+guard,solo+guard+"; received(1459,'target'); assert(#emotes==0 and not BuffTap.helperLastThank and not next(BuffTap.helperThankCooldowns or {}))")
test('Restricted queued thanks is discarded without consuming source cooldown',solo+"received(1459,'target'); received(1243,'party1'); C_ChatInfo={InChatMessagingLockdown=function() return true end}; advance(1.1); assert(#emotes==1 and #BuffTap.helperThankQueue==0 and not BuffTap.helperThankCooldowns['name:Other'])")
test('Public inactive chat state permits thanks',solo+"IsStealthed=function() return false end; UnitIsFeignDeath=function() return false end; C_ChatInfo={InChatMessagingLockdown=function() return false end}; received(1459,'target'); assert(#emotes==1)")
for guid,expect in [("UnitGUID('player')","not BuffTap.action.quickTarget"),("'Player-Other'","BuffTap.action.key=='bow'")]:
 test('Blessing ownership uses exact aura GUID '+guid,priority+"aura('target',20217,'Blessing of Kings'); auras.target[1].auraInstanceID=4; C_UnitAuras.GetAuraCasterGUID=function() return "+guid+" end; refresh(); assert("+expect+")")
test('Secret blessing caster GUID cannot authorize fallback',priority+"aura('target',20217,'Blessing of Kings'); auras.target[1].auraInstanceID=4; C_UnitAuras.GetAuraCasterGUID=function() return {secret=true} end; refresh(); assert(not BuffTap.action.quickTarget)")

ready="C_Spell.GetSpellCooldown=function() return {startTime={secret=true},duration={secret=true},isEnabled=true,isActive=false} end; "
test('Public inactive cooldown permits verified BG self action',bg+ready+"refresh(); assert(BuffTap.action and BuffTap.action.bgSelf); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.action)")
test('Public active hidden cooldown waits for recovery event',bg+"local old=C_Spell.GetSpellCooldown; C_Spell.GetSpellCooldown=function() return {startTime={secret=true},duration={secret=true},isEnabled=true,isActive=true} end; refresh(); assert(not BuffTap.action and BuffTap.cooldownBlocked); C_Spell.GetSpellCooldown=old; BuffTap.events.scripts.OnEvent(nil,'SPELL_UPDATE_COOLDOWN'); advance(.1); assert(BuffTap.action)")
test('Unknown hidden cooldown remains blocked and listens for recovery',bg+"C_Spell.GetSpellCooldown=function() return {startTime={secret=true},duration={secret=true},isEnabled=true,isActive={secret=true}} end; refresh(); assert(not BuffTap.action and BuffTap.cooldownBlocked)")
test('Disabled cooldown cannot be armed despite inactive flag',bg+"C_Spell.GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=false,isActive=false} end; refresh(); assert(not BuffTap.action)")
test('Missing enabled state cannot be armed',bg+"C_Spell.GetSpellCooldown=function() return {startTime=0,duration=0,isActive=false} end; refresh(); assert(not BuffTap.action)")
for key,id,name in [('aspect-hawk',13165,'Aspect of the Hawk'),('aspect-monkey',13163,'Aspect of the Monkey'),('aspect-cheetah',5118,'Aspect of the Cheetah'),('aspect-beast',13161,'Aspect of the Beast')]:
 test('BG self supports '+key,bg+f"playerClass='HUNTER'; spells={{}}; book={{}}; spell({id},'{name}',10); BuffTap.db.buffs['{key}']=true; BuffTap.bookDirty=true; refresh(); assert(BuffTap.action and BuffTap.action.key=='{key}' and BuffTap.action.target=='player')")
for key,id,name in [('aspect-pack',13159,'Aspect of the Pack'),('aspect-wild',20043,'Aspect of the Wild')]:
 test('BG self does not silently enable party aspect '+key,bg+f"playerClass='HUNTER'; spells={{}}; book={{}}; spell({id},'{name}',10); BuffTap.db.buffs['{key}']=true; BuffTap.bookDirty=true; refresh(); assert(not BuffTap.action)")
test('BG self supports learned enabled seal',bg+"playerClass='PALADIN'; spells={}; book={}; spell(21084,'Seal of Righteousness',1); BuffTap.db.buffs['seal-righteousness']=true; BuffTap.bookDirty=true; refresh(); assert(BuffTap.action and BuffTap.action.key=='seal-righteousness')")
test('BG hidden aspect still fails closed',bg+"playerClass='HUNTER'; spells={}; book={}; spell(13165,'Aspect of the Hawk',10); BuffTap.bookDirty=true; C_Secrets.ShouldSpellAuraBeSecret=function() return true end; refresh(); assert(not BuffTap.action)")
test('Combat still prevents aspect updates',bg+"playerClass='HUNTER'; spells={}; book={}; spell(13165,'Aspect of the Hawk',10); BuffTap.bookDirty=true; refresh(); combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); assert(not BuffTap.action and not next(bindings))")

test('Empty aura updates do not scan thanks or invalidate cached player data',solo+"local old=C_UnitAuras.GetAuraDataByIndex; local reads=0; C_UnitAuras.GetAuraDataByIndex=function(...) reads=reads+1; return old(...) end; local cached={sentinel=true}; BuffTap.auraCache.player=cached; for i=1,100 do BuffTap.events.scripts.OnEvent(nil,'UNIT_AURA','player',{isFullUpdate=false}) end; assert(reads==0 and BuffTap.auraCache.player==cached)")
for payload in ["{isFullUpdate=true}","{isFullUpdate={secret=true}}","{isFullUpdate=false,addedAuras={secret=true}}","{isFullUpdate=false,addedAuras={{spellId=1459}}}","{isFullUpdate=false,removedAuraInstanceIDs={2}}","{isFullUpdate=false,updatedAuraInstanceIDs={2}}","nil","{}"]:
 test('Ambiguous or meaningful aura update is retained '+payload,"assert(not BuffTap.API.EmptyAuraUpdate("+payload+"))")
test('Public empty delta arrays are ignored',"assert(BuffTap.API.EmptyAuraUpdate({isFullUpdate=false,addedAuras={},removedAuraInstanceIDs={},updatedAuraInstanceIDs={}}))")
test('Bag updates preserve an unfinished appearance field',"BuffTap:Options(); local f=BuffTap.options; f.selectTab(8); f.sizeEdit:SetText('99'); BuffTap.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); assert(f.sizeEdit:GetText()=='99' and BuffTap.db.size==64)")
test('General options refresh preserves dirty numeric text until Escape',"BuffTap:Options(); local e=BuffTap.options.sizeEdit; e:SetText('99'); e.scripts.OnTextChanged(e,true); BuffTap:Options(); assert(e:GetText()=='99'); e.scripts.OnEscapePressed(e); assert(e:GetText()=='64' and not e.unsaved)")
test('Enter commits and normalizes a dirty numeric edit',"BuffTap:Options(); local e=BuffTap.options.sizeEdit; e:SetText('999'); e.scripts.OnTextChanged(e,true); e.scripts.OnEnterPressed(e); assert(BuffTap.db.size==160 and e:GetText()=='160' and not e.unsaved)")
test('Normal status explains insufficient mana',"C_Spell.IsSpellUsable=function() return false,true end; refresh(); assert(not BuffTap.action and BuffTap:FriendlyStatus():find('mana',1,true))")
test('Normal status explains cooldown wait',"C_Spell.GetSpellCooldown=function() return {startTime=now,duration=10,isEnabled=true,isActive=true} end; refresh(); assert(not BuffTap.action and BuffTap:FriendlyStatus():find('cooldown',1,true))")
test('Deprecated active Salvation preference is discarded without losing migration',"BuffTap.db.salvationGroup=true; BuffTap.db.salvationMigration={saved=true}; BuffTap:InitDB(); assert(BuffTap.db.salvationGroup==nil and BuffTap.db.salvationMigration.saved)")

test('Switching profiles discards unfinished edits from previous profile',"BuffTap:Options(); local e=BuffTap.options.sizeEdit; e:SetText('99'); e.scripts.OnTextChanged(e,true); assert(BuffTap:CreateSettingsProfile('Clean switch',false)); BuffTap:Options(); assert(not e.unsaved and e:GetText()=='64')")

for loc in ['deDE','frFR','esES','ptBR']:
 test('Resource status is localized '+loc,"C_Spell.IsSpellUsable=function() return false,true end; refresh(); assert(BuffTap:FriendlyStatus()~='Not enough mana to buff.')",locale=loc)

