"""Regression coverage carried forward from the unchanged 1.26.3 audit."""
import test_bufftap as harness
from test_nearby import setup as NEAR, macro_model
from test_blessings import setup as PAL
from test_revive import R as REVIVE
from test_cleanse import S as CLEANSE
from test_readiness import ready as PET
from test_manual_consumables import BASE as MANUAL

results = []
def case(area, name, code):
    title = 'Regression 1.26.4 '+area+' '+name
    before = len(harness.failures)
    harness.test(title, code)
    results.append({'area':area,'name':name,'passed':len(harness.failures)==before,
                    'error':harness.full.get(title)})

MAGE = """
local B=BuffTap; playerClass='MAGE'; spells={}; book={}
spell(1459,'Arcane Intellect',1); spell(1460,'Arcane Intellect',14); spell(1461,'Arcane Intellect',28)
B.bookDirty=true; refresh(); local def=B:FindBuff('ai')
"""
case('A','highest compatible ranks for mixed recipients and learned self',MAGE+"""
UnitLevel=function(u) return u=='party1' and 3 or u=='party2' and 4 or 60 end
assert(B:Resolve(def,'party1').id==1459); assert(B:Resolve(def,'party2').id==1460)
assert(B:Resolve(def,'target').id==1461 and B:Resolve(def,'player').id==1461)
""")
for level in ('nil','{secret=true}','0'):
    case('A','unknown recipient level '+level,MAGE+f"""
UnitLevel=function() return {level} end; assert(not B:Resolve(def,'target'))
""")
case('A','pending rank metadata recovers through actual spell-data event',MAGE+"""
local get=C_Spell.GetSpellName
C_Spell.GetSpellName=function(id) if id==1461 then return nil end return get(id) end
B:ScanBook(); assert(B:Resolve(def,'target').id==1460)
C_Spell.GetSpellName=get; UnitLevel=function() return 60 end
B.events.scripts.OnEvent(nil,'SPELL_DATA_LOAD_RESULT',1461,true); advance(.2)
assert(B:Resolve(def,'target').id==1461)
""")
for event in ('SPELLS_CHANGED','PLAYER_TALENT_UPDATE','ACTIVE_TALENT_GROUP_CHANGED'):
    case('A','rank cache invalidation via '+event,MAGE+f"""
UnitLevel=function() return 60 end; assert(B:Resolve(def,'target').id==1461)
spells[1461].known=false; B.events.scripts.OnEvent(nil,'{event}'); advance(.2)
assert(B:Resolve(def,'target').id==1460)
""")
case('A','Nearby pins lower rank in exact macro',NEAR+"""
spell(9885,'Mark of the Wild',60); B=BuffTap; B.bookDirty=true; refresh()
assert(B.action.id==5232 and B.action.macroText:find('Mark of the Wild(Rank 2)',1,true))
""")

SCAN = """
local B=BuffTap; B.db.group=true; B.db.buffs.thorns=false
aura('player',5232,'Mark of the Wild'); B:InvalidateAura(); refresh()
"""
for api, response in [('UnitGUID','{secret=true}'),('UnitLevel','{secret=true}'),
                      ('UnitIsConnected','{secret=true}'),('UnitIsVisible','{secret=true}')]:
    case('B','one unreadable '+api+' does not stop other recipients',SCAN+f"""
local old={api}; {api}=function(u) if u=='party1' then return {response} end return old(u) end
B:InvalidateRoster(); refresh(); assert(not B.lastError,tostring(B.lastError))
assert(B.action and B.action.target=='party2',B.action and B.action.target or B.reason)
""")
case('B','unknown class is isolated where class policy requires it',"""
local B=BuffTap; B.db.group=true; B.db.buffs.motw=false
local old=UnitClass; UnitClass=function(u) if u=='party1' then return 'Unknown',{secret=true} end return old(u) end
aura('player',467,'Thorns'); B:InvalidateRoster(); refresh()
assert(B.action and B.action.target=='party2' and not B.lastError)
""")
for kind in ('error','partial'):
    case('B','one '+kind+' aura scan permits valid neighbor and recovers',SCAN+f"""
local old=C_UnitAuras.GetAuraDataByIndex; local broken=true
C_UnitAuras.GetAuraDataByIndex=function(u,i,f)
 if u=='party1' and broken then {'error("restricted")' if kind=='error' else 'if i==1 then return {secret=true} end return nil'} end
 return old(u,i,f)
end
B:InvalidateAura(); refresh(); assert(B.action and B.action.target=='party2' and not B.lastError)
broken=false; B.events.scripts.OnEvent(nil,'UNIT_AURA','party1'); advance(.2)
assert(B.action and B.action.target=='party1')
""")
case('B','aura cache never follows recycled nameplate identity',NEAR+"""
local B=BuffTap; aura('nameplate1',5232,'Mark of the Wild'); B:InvalidateAura('nameplate1')
local old=B:GetAuras('nameplate1'); assert(#old==1)
local guid=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Replacement' or guid(u) end
auras.nameplate1={}; local new=B:GetAuras('nameplate1'); assert(#new==0 and new~=old)
""")

for transition in ('identity','missing','range','disabled'):
    case('C','prepared Nearby row rejects '+transition,NEAR+"""
local B=BuffTap; local row=B.nearbyFrame.rows[1]; assert(row.attrs.type1=='macro')
"""+{
        'identity':"local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Other' or old(u) end;",
        'missing':"local old=UnitExists; UnitExists=function(u) return u~='nameplate1' and old(u) end;",
        'range':"C_Spell.IsSpellInRange=function() return false end;",
        'disabled':"B.db.enabled=false;",
    }[transition]+"row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)")
case('C','failed name lookup cannot cast on old target or self',NEAR+macro_model+"""
local B=BuffTap; local old={guid='Unrelated',friendly=true}
local casts,target=execute(B.action.macroText,{},old)
assert(#casts==0 and target==old)
""")
case('C','hovered row losing its occupant disarms before reordering',NEAR+"""
local B=BuffTap; B:TrackNearby('nameplate2'); refresh(); local row=B.nearbyFrame.rows[1]
row.scripts.OnEnter(row); local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'New' or old(u) end
row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)
refresh(); assert(not (row.action and row.action.targetGUID=='Player-nameplate1'))
""")
case('C','roster removal before group click clears payload',"""
local B=BuffTap; B.db.group=true; B.db.buffs.thorns=false; aura('player',5232,'Mark of the Wild'); refresh()
assert(B.action.target=='party1'); local old=UnitExists; UnitExists=function(u) return u~='party1' and old(u) end
B.events.scripts.OnEvent(nil,'GROUP_ROSTER_UPDATE'); B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1)
""")
case('C','contradictory GCD flag still blocks repeated Nearby input',NEAR+"""
local B=BuffTap; local row=B.nearbyFrame.rows[1]
C_Spell.GetSpellCooldown=function() return {startTime=now,duration=1,isEnabled=true,isActive=false} end
for i=1,5 do row.scripts.PreClick(row,'LeftButton',true) end
assert(not row.attrs.type1 and not B.nearbyCastAttempt)
""")
case('C','secure combat driver revokes a prepared row',NEAR+"""
local B=BuffTap; local row=B.nearbyFrame.rows[1]; assert(row.attrs.type1)
combat=true; row.secure=true; local fn=assert(loadstring('local self,newstate=...; '..row.attrs['_onstate-nearbysafety']))
fn(row,'blocked'); row.secure=false; assert(not row.attrs.type1 and not row.attrs.macrotext)
""")
case('C','scrolling rebinds each visible row to its displayed recipient',NEAR+"""
local B=BuffTap; for i=2,9 do B:TrackNearby('nameplate'..i) end; refresh()
local row=B.nearbyFrame.rows[1]; local previous=row.entry.guid
B.nearbyFrame.scroll.scripts.OnValueChanged(B.nearbyFrame.scroll,3)
assert(row.entry.guid~=previous and row.action.target==row.entry.unit and row.action.targetGUID==row.entry.guid)
row.scripts.PreClick(row,'LeftButton',true)
assert(row.attrs.macrotext:find(B:NearbyCastName(row.action),1,true))
""")
case('C','native template wiring must deliver the registered combat state',"""
-- Model only the template-provided attribute callback, verified in Forever's
-- SecureHandlerTemplates.xml/SecureHandlers.lua. Do not invoke row snippets
-- directly: that would bypass the wiring this regression is checking.
local originalCreate=CreateFrame
CreateFrame=function(kind,name,parent,templates)
 local frame=originalCreate(kind,name,parent,templates)
 if templates and templates:find('SecureHandlerStateTemplate',1,true) then
  frame:SetScript('OnAttributeChanged',function(s,key,value)
   local state=key:match('^state%-(.+)'); local body=state and s:GetAttribute('_onstate-'..state)
   if body then assert(loadstring('local self,stateid,newstate=...; '..body))(s,state,value) end
  end)
 end
 return frame
end
local function deliver(frame,key,value)
 frame:SetAttribute(key,value); local callback=frame.scripts.OnAttributeChanged
 if callback then callback(frame,key,value) end
end
local control=CreateFrame('Button',nil,UIParent,'SecureActionButtonTemplate,SecureHandlerStateTemplate')
control:SetAttribute('type1','macro'); control:SetAttribute('_onstate-audit',"self:SetAttribute('type1',nil)")
deliver(control,'state-audit','blocked'); assert(not control.attrs.type1,'native callback model control failed')
"""+NEAR+"""
local B=BuffTap; local row=B.nearbyFrame.rows[1]; assert(row.attrs.type1=='macro')
combat=true; row.secure=true; deliver(row,'state-nearbysafety','blocked'); row.secure=false
assert(not row.attrs.type1 and not row.attrs.macrotext,'combat state changed but row handler was never wired')
combat=false; deliver(row,'state-nearbysafety','ready'); assert(not row.attrs.type1,'ready restored a stale payload')
B:InvalidateAura(); refresh(); assert(row.attrs.type1=='macro','fresh out-of-combat selection failed')
""")

GROUP = """
local B=BuffTap; B.db.group=true; B.db.buffs.thorns=false; B.db.groupNeed=3
spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end
GetNumSubgroupMembers=function() return 3 end
UnitExists=function(u) return u=='player' or u:match('^party[1-3]$')~=nil end
B.bookDirty=true; B:InvalidateRoster(); refresh()
assert(B.action and B.action.groupCast,'control group cast not prepared: '..tostring(B.reason))
"""
case('D','group cast falls back when one recipient class is excluded',GROUP+"""
local old=UnitClass; UnitClass=function(u) if u=='party3' then return 'Rogue','ROGUE' end return old(u) end
B.db.buffClasses.motw={ROGUE=false}; B:InvalidateRoster(); refresh()
assert(B.action and not B.action.groupCast)
""")
case('D','group cast must not bypass Also on me off',GROUP+"""
IsInGroup=function() return true end; B.db.buffSelf.motw=false; refresh()
assert(B.action and not B.action.groupCast,'group cast still affects explicitly excluded self')
""")
case('D','unknown affected aura state cannot be bypassed by three known needs',GROUP+"""
local old=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if u=='party3' then error('restricted') end return old(u,i,f) end
B:InvalidateAura(); refresh()
assert(B.action and not B.action.groupCast,'group cast still reaches recipient with unreadable buffs')
""")
case('D','reagent disappearance before group click cancels without substitute',GROUP+"""
-- Initial mock reagent supply is provided by IsSpellUsable; make count explicit.
bags[17021]=0; B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1)
""")
case('D','mixed group ranks do not count as one shared rank',GROUP+"""
spell(21850,'Gift of the Wild',60); UnitLevel=function(u) return u=='player' and 60 or u=='party1' and 60 or 50 end
B.bookDirty=true; refresh(); assert(B.action and not B.action.groupCast)
""")
case('D','personal blessing exception is equivalent for single and Greater',PAL+"""
local B=BuffTap; classes.party2='WARRIOR'; B:InvalidateRoster(); B:SetBlessingPlayer({unit='party2'},'skip'); refresh()
assert(B.action.key=='bom' and not B.action.groupCast)
B:SetBlessingPlayer({unit='party2'},'bom'); refresh(); assert(B.action.groupCast)
B:SetBlessingPlayer({unit='party2'},'bow'); B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.button.attrs.type1)
""")
case('D','verified stronger-effect dismissal blocks whole affected group',GROUP+"""
B:DismissHelper({key='motw',target='party3',targetGUID=UnitGUID('party3')},'stronger effect')
refresh(); assert(B.action and not B.action.groupCast)
""")

case('E','own death and resurrection recover on actual events without reload',"""
local B=BuffTap; dead=true; B.events.scripts.OnEvent(nil,'PLAYER_DEAD'); advance(.2); assert(not B.action)
dead=false; B.events.scripts.OnEvent(nil,'PLAYER_ALIVE'); advance(.2); assert(B.action and B.button.attrs.spell)
""")
case('E','corpse re-entry and identity change do not reuse old resurrection',REVIVE+"""
local inRange=false; C_Spell.IsSpellInRange=function(id,u) return u=='player' or inRange end
refresh(); inRange=true; advance(1.2); assert(B.action and B.action.source=='revive')
local guid=UnitGUID; UnitGUID=function(u) return u=='party1' and 'Recycled' or guid(u) end
B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.button.attrs.type1)
""")
case('E','newly learned normal Druid Revive rank becomes ready on spellbook event',REVIVE+"""
playerClass='DRUID'; spell(437138,'Revive',12); refresh(); assert(B.action.id==437138)
spell(1237948,'Revive',24); B.events.scripts.OnEvent(nil,'SPELLS_CHANGED'); advance(.2)
assert(B.action and B.action.id==1237948)
""")
case('E','released corpse cannot receive a prepared resurrection',REVIVE+"""
refresh(); assert(B.action.source=='revive'); ghost.party1=true
B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.button.attrs.type1)
""")
case('E','cleanse interruption cannot grant SmartShift return',CLEANSE+"""
B.db.smartShift=true; spell(768,'Cat Form'); local form=1
GetShapeshiftForm=function() return form end; GetShapeshiftFormInfo=function() return 132115,form==1,true,768 end
debuff('player',8552,'Curse of Weakness','Curse',60); refresh(); B.button.scripts.PreClick(nil,'LeftButton',true)
assert(B.smartShiftIntent); form=0; B.events.scripts.OnEvent(nil,'UPDATE_SHAPESHIFT_FORM')
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_INTERRUPTED','player','cast',2782)
assert(not B.smartShiftIntent and not B:SmartShiftAction())
""")

CONTEXT = """
local B=BuffTap; context='solo'
IsInRaid=function() return context=='raid' end; IsInGroup=function() return context~='solo' end
GetNumSubgroupMembers=function() return context=='solo' and 0 or 2 end
GetNumGroupMembers=function() return context=='raid' and 3 or 0 end
B:SyncSituation()
"""
for family in ('food','flask','ferocity','utility'):
    for mode in ('auto','manual'):
        case('F',family+' '+mode+' preference persists across contexts and re-init',CONTEXT+f"""
local family=B:ConsumableFamily('{family}'); local chosen=family.items[1].id
for _,ctx in ipairs({{'solo','party','raid'}}) do
 B:SetSituationValue(ctx,'consumables','consumablesEnabled',true)
 B:SetSituationValue(ctx,'consumables','consumableModes','{mode}','{family}')
 B:SetSituationValue(ctx,'consumables','consumableChoices',chosen,'{family}')
end
for _,ctx in ipairs({{'party','raid','solo'}}) do context=ctx; B:SyncSituation(); assert(B:ConsumableMode(family)=='{mode}'); assert(B:ConsumableChoiceID(family)==chosen) end
B:SaveClassSetup(); B:InitDB(); assert(B.db.consumableModes['{family}']=='{mode}' and B.db.consumableChoices['{family}']==chosen)
""")
case('F','selected out-of-stock food persists until replenished without replacement',"""
local B=BuffTap; local f=B:ConsumableFamily('food'); local first=f.items[1]; local second=f.items[2]
stock(first.id,first.useSpell); stock(second.id,second.useSpell); consumables('food'); B:SetConsumableChoice(f,first.id)
refresh(); assert(B.action.itemID==first.id); bags[first.id]=0; B:InvalidateConsumables(); refresh()
assert(not (B.action and B.action.source=='consumable')); assert(B:ConsumableChoiceID(f)==first.id)
bags[first.id]=3; B.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(.2)
assert(B.action and B.action.itemID==first.id)
""")
case('F','Manual strip mode and selected item survive detached positioning',MANUAL+"""
local f=manual('food'); local item=put(f); B:SetConsumableChoice(f,item.id); B.db.manualConsumablesDetached=true
B.db.manualConsumablesX=124; B.db.manualConsumablesY=-83; refresh(); local b=assert(icon('food'))
assert(b.action and not (B.action and B.action.source=='consumable'))
B.db.manualConsumablesDetached=false; refresh(); assert(B:ConsumableChoiceID(f)==item.id and B:ConsumableMode(f)=='manual')
assert(B.db.manualConsumablesX==124 and B.db.manualConsumablesY==-83)
""")
case('F','Manual prepared item is revoked after stock disappears',MANUAL+"""
local f=manual('flask'); local item=put(f); refresh(); local b=assert(icon('flask')); bags[item.id]=0
b.scripts.PreClick(b,'LeftButton',false); assert(not b.attrs.type1 and (not B.itemAttempts or not B.itemAttempts[item.id]))
""")

for pact in (False,True):
    for state,aura_id in [('none',None),('same',18789),('different',18791)]:
        code=PET+"local B=BuffTap; "
        if pact: code+="spell(425464,'Demonic Pact'); "
        if aura_id: code+=f"aura('player',{aura_id},'Demonic Sacrifice',3600,7200); "
        expected=not aura_id or (pact and state=='different')
        code+="refresh(); local candidate,why=B:ReadinessCandidate('pet'); "
        code+=("assert(candidate and candidate.id==688,'expected preferred different demon; '..tostring(why))" if expected else "assert(not candidate,'would cancel the intended sacrifice')")
        case('G',f'Pact={pact} sacrifice={state}',code)
case('G','Soul Link upkeep coexists with sacrifice and a living different demon',PET+"""
local B=BuffTap; spell(425464,'Demonic Pact'); spell(19028,'Soul Link'); B.db.buffs['soul-link']=true
petExists=true; aura('player',18791,'Sacrifice',3600,7200); refresh()
assert(B.action and B.action.id==19028)
aura('player',25228,'Soul Link',0,0); B.events.scripts.OnEvent(nil,'UNIT_AURA','player'); advance(.2)
assert(not B.action and not B:ReadinessCandidate('pet'))
""")
case('G','learning Pact should release different-pet suppression without reload',PET+"""
local B=BuffTap; aura('player',18791,'Sacrifice',3600,7200); refresh(); assert(not B.action)
spell(425464,'Demonic Pact'); B.events.scripts.OnEvent(nil,'PLAYER_TALENT_UPDATE'); advance(.2)
local candidate,why=B:ReadinessCandidate('pet'); assert(candidate and candidate.id==688,tostring(why))
""")
case('G','restricted sacrifice data cannot authorize pet summon',PET+"""
local B=BuffTap; spell(425464,'Demonic Pact'); local old=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if u=='player' then error('restricted') end return old(u,i,f) end
B:InvalidateAura(); refresh(); assert(not B:ReadinessCandidate('pet'))
""")

case('H','existing report explains nameplates off without new UI',NEAR+"""
local B=BuffTap; platesEnabled=false; refresh(); local report=table.concat(B:NearbyDiagnosticsLines(),'\\n')
assert(report:lower():find('nameplate',1,true)); assert(B.nearbyFrame.status.text:find('Shift+V',1,true))
""")
case('H','range and incomplete data remain distinct in existing diagnostics',SCAN+"""
B.captureDiagnostics=true; C_Spell.IsSpellInRange=function(id,u) return u=='player' end; refresh()
local report=table.concat(B:DiagnosticsLines(),'\\n')..'\\n'..table.concat(B.diagnostics or {},'\\n')
assert(report:lower():find('range',1,true))
""")
case('H','existing Groups page explains the blocked Greater fallback',PAL+"""
local B=BuffTap; classes.party2='WARRIOR'; B:InvalidateRoster(); B:SetBlessingPlayer({unit='party2'},'bow')
B.captureDiagnostics=true; refresh(); B:Options()
assert(not B.action.groupCast)
local report=B.options.blessingFooter.text
assert(report:find('Individual blessings',1,true) and report:find('assignments differ',1,true),tostring(report))
""")

# Reuse the established fresh-Lua reload factory, rather than equating InitDB
# in the same VM with a real logout/reload reconstruction.
from test_profile_persistence import boot, table_to_python
for mode in ('auto','manual'):
    title='Regression 1.26.4 F fresh-Lua reload and profile switch preserve all families '+mode
    try:
        first=boot('ConsumableAudit',legacy={'group':False})
        first.execute("""
local B=BuffTap; B.db.consumablesEnabled=true
for _,key in ipairs({'food','flask','ferocity','utility'}) do
 local f=B:ConsumableFamily(key); B.db.consumableChoices[key]=f.items[1].id
 B.db.consumableModes[key]='"""+mode+"""'
 for _,ctx in ipairs({'party','raid'}) do
  B:SetSituationValue(ctx,'consumables','consumableChoices',f.items[1].id,key)
  B:SetSituationValue(ctx,'consumables','consumableModes','"""+mode+"""',key)
 end
end
B:SaveClassSetup()
""")
        saved=table_to_python(first.globals().BuffTapProfiles)
        legacy=table_to_python(first.globals().BuffTapDB)
        again=boot('ConsumableAudit',shared=saved,legacy=legacy)
        again.execute("""
local B=BuffTap
for _,key in ipairs({'food','flask','ferocity','utility'}) do
 local f=B:ConsumableFamily(key); local id=f.items[1].id
 assert(B.db.consumableModes[key]=='"""+mode+"""' and B.db.consumableChoices[key]==id)
 for _,ctx in ipairs({'party','raid'}) do
  local settings=B:SituationPreview(ctx,'consumables')
  assert(settings.consumableModes[key]=='"""+mode+"""' and settings.consumableChoices[key]==id)
 end
end
assert(B:CreateSettingsProfile('Temporary',true)); assert(B:SelectSettingsProfile('ConsumableAudit - Test Realm'))
assert(B.db.consumableModes.food=='"""+mode+"""')
""")
        harness.tests.append(title); print('PASS',title)
        results.append({'area':'F','name':title,'passed':True,'error':None})
    except Exception as exc:
        print('FAIL',title,str(exc)); results.append({'area':'F','name':title,'passed':False,'error':str(exc)})

for result in ('false','error'):
    case('C','failed row state registration remains disarmed '+result,"""
local original=RegisterStateDriver
RegisterStateDriver=function(frame,state,condition)
 if state=='nearbysafety' then """+("return false" if result=='false' else "error('unavailable')")+""" end
 return original(frame,state,condition)
end
"""+NEAR+"""
local B=BuffTap; local row=B.nearbyFrame.rows[1]
assert(not row.nearbySafetyReady and not row.attrs.type1)
row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1 and not B.nearbyCastAttempt)
""")

RAID="""
local B=BuffTap; B.db.group=true; B.db.buffs.thorns=false; B.db.groupNeed=3
spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end
IsInRaid=function() return true end; IsInGroup=function() return true end
GetNumGroupMembers=function() return 4 end
UnitExists=function(u) return u=='player' or u:match('^raid[1-4]$')~=nil end
UnitIsUnit=function(a,b) return a==b or (a=='raid1' and b=='player') or (b=='raid1' and a=='player') end
UnitGUID=function(u) return 'Player-'..(u=='raid1' and 'player' or u) end
GetRaidRosterInfo=function(i) return 'Raider'..i,0,1 end
B.bookDirty=true; B:InvalidateRoster()
"""
case('D','raid group also respects explicit self exclusion',RAID+"""
B.db.buffSelf.motw=false; refresh(); assert(B.action and not B.action.groupCast)
""")
case('D','self exclusion does not block a different raid subgroup',RAID+"""
GetRaidRosterInfo=function(i) return 'Raider'..i,0,i==1 and 1 or 2 end
B.db.buffSelf.motw=false; refresh()
assert(B.action and B.action.groupCast and B.action.target~='player')
""")
case('D','healthy covered recipient still permits a justified group cast',GROUP+"""
aura('party3',5232,'Mark of the Wild',1000,1800); B:InvalidateAura(); refresh()
assert(B.action and B.action.groupCast and B.action.groupCount==3)
""")
case('D','readable positive coverage survives an unrelated restricted aura',GROUP+"""
aura('party3',5232,'Mark of the Wild',1000,1800); auras.party3[2]={secret=true}
B:InvalidateAura(); refresh(); assert(B.action and B.action.groupCast and B.action.groupCount==3)
""")
case('D','known corpse does not require an unavailable helpful-aura scan',GROUP+"""
local deadState=UnitIsDeadOrGhost; UnitIsDeadOrGhost=function(u) return u=='party3' or deadState(u) end
local get=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if u=='party3' then error('corpse aura unavailable') end return get(u,i,f) end
B:InvalidateAura(); refresh(); assert(B.action and B.action.groupCast and B.action.groupCount==3)
""")
case('D','new unreadable affected recipient cancels the prepared group click',GROUP+"""
local get=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if u=='party3' then error('restricted after preparation') end return get(u,i,f) end
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1 and not B.button.attrs.spell)
""")
case('D','greater blessing checks a covered affected recipient outside its bucket',PAL+"""
local B=BuffTap; GetNumSubgroupMembers=function() return 3 end
local exists=UnitExists; UnitExists=function(u) return u=='party3' or exists(u) end
classes.party2='WARRIOR'; classes.party3='WARRIOR'; aura('party3',19740,'Blessing of Might',1000,1800)
B:InvalidateRoster(); B:InvalidateAura(); refresh(); assert(B.action and B.action.groupCast)
local get=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if u=='party3' then error('unknown') end return get(u,i,f) end
B:InvalidateAura(); refresh(); assert(B.action and not B.action.groupCast)
""")

SACRIFICED={18789:(688,),18790:(691,),18791:(712,713),18792:(697,)}
for aura_id, family in SACRIFICED.items():
    for selected in (688,697,712,713,691):
        expected=selected not in family
        case('G',f'Pact sacrifice {aura_id} preferred demon {selected}',PET+f"""
local B=BuffTap; spell(425464,'Demonic Pact'); B.db.helperDemon={selected}
aura('player',{aura_id},'Sacrifice',3600,7200); refresh()
local candidate=B:ReadinessCandidate('pet')
"""+(f"assert(candidate and candidate.id=={selected})" if expected else "assert(not candidate,'same sacrificed family would be replaced')"))
case('G','unknown Pact readings retain conservative sacrifice suppression',PET+"""
local B=BuffTap; local known=C_SpellBook.IsSpellKnown
C_SpellBook.IsSpellKnown=function(id,bank) if id==425464 then return {secret=true} end return known(id,bank) end
IsPlayerSpell=function() return {secret=true} end
aura('player',18791,'Sacrifice',3600,7200); refresh(); assert(not B:ReadinessCandidate('pet'))
""")
case('G','public IsPlayerSpell can independently verify Pact ownership',PET+"""
local B=BuffTap; IsPlayerSpell=function(id) return id==425464 end
aura('player',18791,'Sacrifice',3600,7200); refresh()
assert(B:ReadinessCandidate('pet').id==688)
""")
case('G','removing Pact revokes a previously prepared summon at click',PET+"""
local B=BuffTap; spell(425464,'Demonic Pact'); aura('player',18791,'Sacrifice',3600,7200)
refresh(); assert(B.action and B.action.id==688)
spells[425464].known=false; B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.button.attrs.type1)
""")
case('G','Pact does not bypass shard requirements for the selected demon',PET+"""
local B=BuffTap; spell(425464,'Demonic Pact'); B.db.helperDemon=697; bags[6265]=0
aura('player',18791,'Sacrifice',3600,7200); refresh(); assert(not B.action)
bags[6265]=1; B.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED'); advance(.2)
assert(B.action and B.action.id==697)
""")

print('REGRESSION_1264',len(results),sum(x['passed'] for x in results),sum(not x['passed'] for x in results))
if any(not x['passed'] for x in results): raise AssertionError('1.26.4 regression failure')
