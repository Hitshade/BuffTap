"""Opt-in shield charges, read-only inspection and class supplies discovery."""
from test_bufftap import test, tests
from test_profile_persistence import boot, table_to_python, passed
from test_nearby import setup as NEAR

start=len(tests)
SHAMAN="""
local B=BuffTap; playerClass='SHAMAN'; spells={}; book={}
spell(324,'Lightning Shield',8); spell(408510,'Water Shield',20)
B:InitDB(); for _,def in ipairs(B.Buffs) do B.db.buffs[def.key]=false end
B.db.buffs['lightning-shield']=true; B.db.weaponReminder=false
B.db.buffCharges={}; auras.player={}; aura('player',324,'Lightning Shield',500,600)
auras.player[1].applications=3; refresh()
"""

test('Shield charge reminders default off and preserve long-duration coverage',SHAMAN+"assert(B:ShieldChargeLimit(B:FindBuff('lightning-shield'))==0 and not B.action)")
for key,sid,name in [('lightning-shield',324,'Lightning Shield'),('water-shield',408510,'Water Shield')]:
    base=SHAMAN+f"B.db.buffs['lightning-shield']=false; B.db.buffs['{key}']=true; auras.player[1].spellId={sid}; auras.player[1].name='{name}'; "
    for limit in (1,2):
        for count in (1,2,3):
            should=count<=limit
            test(f'Shield {key} threshold {limit} with {count} charges',base+f"B.db.buffCharges['{key}']={limit}; auras.player[1].applications={count}; refresh(); "+
                 (f"assert(B.action and B.action.id=={sid} and B.action.needState=='low charges')" if should else "assert(not B.action)"))
    for count in ('nil','{secret=true}','0','-1','1.5','0/0'):
        test('Shield '+key+' unknown/invalid charges '+count,base+f"B.db.buffCharges['{key}']=2; auras.player[1].applications={count}; refresh(); assert(not B.action)")

test('Shield charge zero setting explicitly disables extra refresh',SHAMAN+"B.db.buffCharges['lightning-shield']=0; auras.player[1].applications=1; refresh(); assert(not B.action)")
test('Shield timer remains active when charge count is unknown',SHAMAN+"B.db.buffCharges['lightning-shield']=1; auras.player[1].applications=nil; auras.player[1].expirationTime=now+20; refresh(); assert(B.action and B.action.needState=='expiring')")
test('Shield charge option does not replace an alternative shield',SHAMAN+"B.db.buffCharges['lightning-shield']=2; auras.player[1].spellId=408510; auras.player[1].name='Water Shield'; auras.player[1].applications=1; refresh(); assert(not B.action)")
test('Shield count changes wake through real UNIT_AURA event',SHAMAN+"B.db.buffCharges['lightning-shield']=1; auras.player[1].applications=1; B.events.scripts.OnEvent(nil,'UNIT_AURA','player'); advance(.2); assert(B.action and B.action.id==324)")
test('Shield batch aura scan retains verified charge count',SHAMAN+"C_UnitAuras.GetUnitAuras=function() return auras.player end; B.db.buffCharges['lightning-shield']=1; auras.player[1].applications=1; refresh(); assert(B.action and B.action.needState=='low charges')")
test('Shield click disarms when fresh charge information is healthy',SHAMAN+"B.db.buffCharges['lightning-shield']=1; auras.player[1].applications=1; refresh(); assert(B.action); auras.player[1].applications=3; B.button.scripts.PreClick(nil,'LeftButton',false); assert(not B.action and not B.button.attrs.type1)")
test('Shield charge refresh still respects real cooldown',SHAMAN+"B.db.buffCharges['lightning-shield']=1; auras.player[1].applications=1; C_Spell.GetSpellCooldown=function() return {startTime=now,duration=8,isEnabled=true,isActive=true} end; refresh(); assert(not B.action)")
test('Shield charges are never read or inferred during combat',SHAMAN+"B.db.buffCharges['lightning-shield']=1; local calls=0; C_UnitAuras.GetAuraDataByIndex=function() calls=calls+1; error('combat read') end; combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); B.events.scripts.OnEvent(nil,'UNIT_AURA','player'); B:Refresh(); assert(calls==0 and not B.action)")
test('Shield selection remains configurable before spell learning',SHAMAN+"spells[408510].known=false; B:Options(); local row; for _,r in ipairs(B.options.buffRows) do if r.def.key=='water-shield' then row=r end end; assert(row and row.charges.shown); row.charges.scripts.OnClick(row.charges); local pick=row.charges.menu.rows[2]; pick.scripts.OnClick(pick); assert(B:ShieldChargeLimit(row.def,B:EditorSettings('buffs'))==1)")
test('Non-Shaman rows have no shield charge controls',"BuffTap:Options(); for _,r in ipairs(BuffTap.options.buffRows) do assert(not r.charges.shown and not r.chargeLabel.shown) end")
test('Shield row height reserves space for charge selectors',SHAMAN+"B:Options(); for _,r in ipairs(B.options.buffRows) do if r.charges.shown then assert(r:GetHeight()==86) else assert(r:GetHeight()==54) end end")
test('Malformed shield settings normalize to supported bounded values',SHAMAN+"B.db.buffCharges={['lightning-shield']=99,['water-shield']={secret=true},thorns=1}; B:InitDB(); assert(B.db.buffCharges['lightning-shield']==2 and not B.db.buffCharges['water-shield'] and not B.db.buffCharges.thorns)")
test('Shield Party and Raid preferences inherit and override independently',SHAMAN+"B.db.buffCharges['lightning-shield']=1; B:SetSituationValue('party','buffs','buffCharges',0,'lightning-shield'); B:SetSituationValue('raid','buffs','buffCharges',2,'lightning-shield'); assert(B:SituationPreview('party','buffs').buffCharges['lightning-shield']==0 and B:SituationPreview('raid','buffs').buffCharges['lightning-shield']==2); B:CustomizeSituation('party','buffs',false); assert(B:SituationPreview('party','buffs').buffCharges['lightning-shield']==1)")
test('Shield invalid context charge entries are removed',SHAMAN+"local s=B:CleanSituationCategory('buffs',{buffCharges={['lightning-shield']=1,['water-shield']=0,thorns=2}}); assert(s.buffCharges['lightning-shield']==1 and s.buffCharges['water-shield']==0 and not s.buffCharges.thorns)")
test('Shield context runtime uses Party override',SHAMAN+"B.db.buffCharges['lightning-shield']=1; B:SetSituationValue('party','buffs','buffCharges',0,'lightning-shield'); IsInGroup=function() return true end; auras.player[1].applications=1; refresh(); assert(B:Preference('buffCharges')['lightning-shield']==0 and not B.action)")
test('Shield settings export and import for the same class',SHAMAN+"B.db.buffCharges['lightning-shield']=2; local s=B:ExportSettings(); B.db.buffCharges={}; assert(B:ImportSettings(s)); assert(B.db.buffCharges['lightning-shield']==2)")
test('Shield class settings do not import onto another class',SHAMAN+"B.db.buffCharges['lightning-shield']=2; local s=B:ExportSettings(); playerClass='DRUID'; B.db.buffCharges={}; assert(B:ImportSettings(s)); assert(not next(B.db.buffCharges))")

test('Buff inspector reports own readable identity count rank and actual coverage',SHAMAN+"spells[324].rank='Rank 1'; auras.player[1].sourceUnit='player'; local text=table.concat(B:BuffInspectorLines(),'\\n'); assert(text:find('spell 324',1,true) and text:find('Rank 1',1,true) and text:find('stacks/charges 3',1,true) and text:find('Lightning Shield [on]',1,true))")
test('Buff inspector does not mutate action settings bindings or timers',SHAMAN+"local action=B.action; local settings=B:ExportSettings(); local timers=liveTimers(); local bindingsBefore=0; for _ in pairs(bindings) do bindingsBefore=bindingsBefore+1 end; B:BuffInspectorLines(); assert(B.action==action and B:ExportSettings()==settings and liveTimers()==timers); local after=0; for _ in pairs(bindings) do after=after+1 end; assert(after==bindingsBefore)")
test('Buff inspector recognizes selected consumable using real coverage',"stock(13510,17626); consumables('flask'); aura('player',17626,'Flask of the Titans'); local text=table.concat(BuffTap:BuffInspectorLines(),'\\n'); assert(text:find('Flask [on]',1,true))")
test('Buff inspector retains unknown helpful effects without granting actions',"aura('player',900001,'Uncatalogued effect',500,600); local action=BuffTap.action; local text=table.concat(BuffTap:BuffInspectorLines(),'\\n'); assert(text:find('Uncatalogued effect',1,true) and text:find('no class-buff or selected-consumable match',1,true) and BuffTap.action==action)")
test('Buff inspector marks restricted optional fields unknown',SHAMAN+"auras.player[1].applications={secret=true}; auras.player[1].sourceUnit={secret=true}; C_Spell.GetSpellSubtext=function() return {secret=true} end; local text=table.concat(B:BuffInspectorLines(),'\\n'); assert(text:find('stacks/charges unknown',1,true) and text:find('caster unknown',1,true) and not text:find('table:',1,true))")
test('Buff inspector does not reveal caster GUID or character name',SHAMAN+"auras.player[1].sourceUnit='Private Name'; auras.player[1].casterGUID='Private-GUID'; local text=B:ReportText('buffs',false); assert(not text:find('Private',1,true) and text:find('caster other unit',1,true))")
test('Buff inspector refuses combat snapshots without querying aura APIs',SHAMAN+"combat=true; C_UnitAuras.GetAuraDataByIndex=function() error('must not query') end; local text=B:ReportText('buffs',true); assert(text:find('Unavailable in combat',1,true) and not text:find('spell 324',1,true))")
test('Buff inspector handles total aura failure honestly',"C_UnitAuras.GetAuraDataByIndex=function() error('denied') end; local text=table.concat(BuffTap:BuffInspectorLines(),'\\n'); assert(text:find('Buff information unavailable',1,true))")
test('Buff inspector marks partial scans without inventing missing effects',SHAMAN+"local old=C_UnitAuras.GetAuraDataByIndex; C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if i==2 then return {secret=true} end; return old(u,i,f) end; local text=table.concat(B:BuffInspectorLines(),'\\n'); assert(text:find('Partial information',1,true) and text:find('spell 324',1,true))")
test('Buff inspector selected elixir line recognizes equivalent aura',"BuffTap.db.consumablesEnabled=true; BuffTap:ToggleElixir(9187); aura('player',17538,'Elixir of the Mongoose'); local text=table.concat(BuffTap:BuffInspectorLines(),'\\n'); assert(text:find('Elixirs: Elixir of Greater Agility',1,true))")
test('Buff inspector button uses existing copyable report pane',SHAMAN+"B:Options(); B.options.inspectBuffs.scripts.OnClick(B.options.inspectBuffs); assert(B.options.discoveryScroll.shown and B.options.discoveryReport.text:find('Your active buffs',1,true))")
test('Full check-up includes active-buff snapshot',SHAMAN+"local text=B:ReportText('checkup',true); assert(text:find('== Active buffs ==',1,true) and text:find('spell 324',1,true))")

for cls,word in [('HUNTER','arrows or bullets'),('WARLOCK','Soul Shards'),('MAGE','group-buff reagents'),('PRIEST','group-buff reagents'),('DRUID','group-buff reagents'),('PALADIN','group-buff reagents'),('ROGUE','weapon supplies')]:
    test('Onboarding supplies guidance fits '+cls,f"assert(BuffTap:OnboardingSupplyHint('{cls}'):find('{word}',1,true))")
test('Onboarding supplies shortcut opens existing page without auto-enabling warnings',"BuffTap.db.onboardingVersion=nil; BuffTap:ShowOnboarding(); BuffTap:OnboardingFeaturesPage(); local button; for _,r in ipairs(BuffTap.onboarding.pageRegions) do if r.text=='Set up supplies' then button=r end end; assert(button and BuffTap.onboarding.featureScroll); button.scripts.OnClick(button); assert(BuffTap.options.pages[15].shown and not BuffTap.db.suppliesEnabled and #BuffTap.db.supplyCustom==0)")
test('Returning users are not forced through onboarding again',"BuffTap.db.onboardingVersion=1; assert(not BuffTap:OnboardingPending())")

GRADE=NEAR+"""
local B=BuffTap; B.db.buffs.thorns=false
aura('nameplate1',1126,'Mark of the Wild',1700,1800)
B.db.nearbyRankUpgrades=true; refresh()
"""
test('Nearby buff-grade is opt-in',NEAR+"BuffTap.db.buffs.thorns=false; aura('nameplate1',1126,'Mark of the Wild',1700,1800); refresh(); assert(not BuffTap.db.nearbyRankUpgrades and not BuffTap.action)")
test('Nearby buff-grade offers exact higher known rank on healthy lower effect',GRADE+"assert(B.action and B.action.id==5232 and B.action.needState=='rank upgrade' and B.action.macroText:find('Mark of the Wild(Rank 2)',1,true))")
test('Nearby buff-grade leaves an equal rank alone',GRADE+"auras.nameplate1[1].spellId=5232; refresh(); assert(not B.action)")
test('Nearby buff-grade leaves a higher rank alone',GRADE+"auras.nameplate1[1].spellId=6756; refresh(); assert(not B.action)")
test('Nearby buff-grade does not infer an unknown aura rank from its name',GRADE+"auras.nameplate1[1].spellId=900001; refresh(); assert(not B.action)")
test('Nearby buff-grade does not infer a restricted aura identity',GRADE+"auras.nameplate1[1].spellId={secret=true}; refresh(); assert(not B.action)")
test('Nearby buff-grade leaves group equivalents alone',GRADE+"auras.nameplate1[1].spellId=21849; auras.nameplate1[1].name='Gift of the Wild'; refresh(); assert(not B.action)")
test('Nearby buff-grade requires complete readable evidence',GRADE+"local old=C_UnitAuras.GetAuraDataByIndex; C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if u=='nameplate1' and i==2 then return {secret=true} end; return old(u,i,f) end; refresh(); assert(not B.action)")
test('Nearby buff-grade still obeys recipient level for new rank',GRADE+"spell(6756,'Mark of the Wild',20); spells[6756].rank='Rank 3'; UnitLevel=function(u) return u=='nameplate1' and 9 or 60 end; refresh(); assert(B.action and B.action.id==5232)")
test('Nearby buff-grade does not affect ordinary friendly-target or self coverage',GRADE+"local def=B:FindBuff('motw'); local a=B:Resolve(def,'nameplate1'); local missing=B:Missing(def,a,B:GetAuras('nameplate1',true,true)); assert(not missing and not B.nearbyRankUpgradeScan)")
test('Nearby buff-grade toggle invalidates cached decision',GRADE+"assert(B.action); B.db.nearbyRankUpgrades=false; B.nearbySnapshot=nil; B:Refresh(); assert(not B.action)")
test('Nearby buff-grade click clears if another player supplied the upgrade',GRADE+"auras.nameplate1[1].spellId=5232; B.button.scripts.PreClick(nil,'LeftButton',false); assert(not B.action and not B.button.attrs.type1)")
test('Nearby buff-grade click clears after toggle disabled',GRADE+"B.db.nearbyRankUpgrades=false; B.button.scripts.PreClick(nil,'LeftButton',false); assert(not B.action and not B.button.attrs.type1)")
test('Nearby buff-grade respects current range checks',GRADE+"C_Spell.IsSpellInRange=function() return false end; refresh(); assert(not B.action)")
test('Nearby buff-grade option is visible and explicit',"BuffTap:Options(); local c=BuffTap.options.nearbyRankUpgrades; assert(c and not c:GetChecked()); c:SetChecked(true); c.scripts.OnClick(c); assert(BuffTap.db.nearbyRankUpgrades)")
for cls in ('HUNTER','SHAMAN','WARLOCK','WARRIOR','ROGUE'):
    test('Nearby buff-grade control is hidden for inapplicable class '+cls,f"playerClass='{cls}'; BuffTap:Options(); assert(not BuffTap.options.nearbyRankUpgrades.shown)")
test('Nearby buff-grade preference exports and imports',"BuffTap.db.nearbyRankUpgrades=true; local s=BuffTap:ExportSettings(); BuffTap.db.nearbyRankUpgrades=false; assert(BuffTap:ImportSettings(s) and BuffTap.db.nearbyRankUpgrades)")
test('Nearby buff-grade scope clears even when scanning fails',GRADE+"B.nearbyNeedCache=nil; B.ScanMissing=function() error('probe') end; local ok=pcall(B.NearbyNeeds,B,{unit='nameplate1',guid=UnitGUID('nameplate1'),class='WARRIOR'},{B:FindBuff('motw')}); assert(not ok and not B.nearbyRankUpgradeScan and not B.favorScan)")

first=boot('ShieldPersist','SHAMAN')
first.execute("BuffTap.db.buffCharges['lightning-shield']=2; BuffTap:SetSituationValue('party','buffs','buffCharges',0,'lightning-shield'); BuffTap:SaveClassSetup()")
again=boot('ShieldPersist','SHAMAN',shared=table_to_python(first.globals().BuffTapProfiles),legacy=table_to_python(first.globals().BuffTapDB))
again.execute("assert(BuffTap.db.buffCharges['lightning-shield']==2 and BuffTap:SituationPreview('party','buffs').buffCharges['lightning-shield']==0)")
passed('Shield charge settings survive fresh-Lua reload with context overrides')
print('SHIELD_INSPECTOR_CASES',len(tests)-start)
