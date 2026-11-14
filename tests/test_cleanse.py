from test_bufftap import test, tests

# Debuffs live in their own table; the default mock returns the same list for every filter.
S=("local B=BuffTap; debuffs={}; "
 "local base=C_UnitAuras.GetAuraDataByIndex; "
 "C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if f=='HARMFUL' then return (debuffs[u] or {})[i] end return base(u,i,f) end; "
 "function debuff(u,id,name,kind,left,stacks) debuffs[u]=debuffs[u] or {}; table.insert(debuffs[u],{spellId=id,name=name,dispelName=kind,applications=stacks or 0,duration=30,expirationTime=now+(left or 20)}); B:InvalidateAura(u) end; "
 "spell(2893,'Abolish Poison'); spell(8946,'Cure Poison'); spell(2782,'Remove Curse'); "
 "B.db.cleanseEnabled=true; ")

test('Cleanse is off by default',"local B=BuffTap; assert(B.db.cleanseEnabled==false and B.db.cleanseNearby==false and B.db.cleanseSound=='harp')")
test('A stacked poison gets Abolish Poison before buffs',S+"debuff('player',3396,'Corrosive Poison','Poison',20,3); refresh(); local a=B.action; assert(a and a.source=='cleanse' and a.id==2893 and a.target=='player' and a.name:find('(3)',1,true)); assert(B.button.attrs.spell==2893)")
test('A single short poison gets the plain cure',S+"debuff('player',3396,'Corrosive Poison','Poison',6,0); refresh(); assert(B.action.id==8946)")
test('Abolish already ticking is left to work',S+"debuff('player',3396,'Corrosive Poison','Poison',20,3); aura('player',2893,'Abolish Poison',6,8); refresh(); assert(not (B.action and B.action.source=='cleanse'))")
test('Curse uses Remove Curse and turned-off types are skipped',S+"debuff('player',8552,'Curse of Weakness','Curse',60); refresh(); assert(B.action.id==2782); B.db.cleanseTypes.Curse=false; refresh(); assert(not (B.action and B.action.source=='cleanse'))")
test('Types the class cannot remove are ignored',S+"debuff('player',1,'Shadow Word: Pain','Magic',18); refresh(); assert(not (B.action and B.action.source=='cleanse'))")
test('Debuffs about to expire are skipped',S+"debuff('player',3396,'Corrosive Poison','Poison',2); refresh(); assert(not (B.action and B.action.source=='cleanse'))")
test('Never list by name and the built-in list are honoured',S+"debuff('player',3396,'Corrosive Poison','Poison',20); B:SetCleanseNever('corrosive POISON',true); refresh(); assert(not (B.action and B.action.source=='cleanse')); B.profileDB.global.cleanseNever={}; debuffs.player={}; debuff('player',28169,'Mutating Injection','Disease',10); playerClass='PRIEST'; spell(552,'Abolish Disease'); refresh(); assert(not (B.action and B.action.source=='cleanse'))")
test('Group members are cleansed after you',S+"GetNumSubgroupMembers=function() return 1 end; IsInRaid=function() return false end; UnitExists=function(u) return u=='player' or u=='party1' or u=='target' and false end; debuff('party1',8552,'Curse of Weakness','Curse',60); refresh(); assert(B.action.source=='cleanse' and B.action.target=='party1')")
test('Right-click adds the debuff to the shared never list',S+"debuff('player',3396,'Corrosive Poison','Poison',20); refresh(); B.button.scripts.PostClick(nil,'RightButton',false); assert(B.profileDB.global.cleanseNever['corrosive poison']); refresh(); assert(not (B.action and B.action.source=='cleanse'))")
test('Click revalidates and drops a cleansed debuff',S+"debuff('player',3396,'Corrosive Poison','Poison',20); refresh(); assert(B.action.source=='cleanse'); debuffs.player={}; B.button.scripts.PreClick(nil,'LeftButton',false); assert(not (B.action and B.action.source=='cleanse'))")
test('Cleanse reminders play the cleanse sound and get a coloured border',S+"debuff('player',3396,'Corrosive Poison','Poison',20); refresh(); local played; PlaySoundFile=function(f) played=f; return true end; B.db.sound=true; B.lastAlertSound=nil; B:PlayAlert('reminder'); assert(played and played:find('arp',1,true)); B:UpdateOverlay(); assert(B.button.cleanseEdge and B.button.cleanseEdge.shown)")
test('Cleanse page sits after My buffs and lists the class spells',S+"B:Options(); local f=B.options; assert(f.pages[14] and f.cleanseEnable.headerSwitch); assert(not f.tabs[14].navHidden); B:UpdateCleansePage(); assert(f.cleanseRows[1].kind=='Poison' and f.cleanseRows[1].spell.text:find('Abolish Poison',1,true)); assert(f.cleanseRows[4].spell.text:find(\"can't\",1,true))")
test('Classes without cleanses do not see the page',"playerClass='WARRIOR'; local B=BuffTap; assert(not B:CanCleanseAnything()); B:Options(); assert(B.options.tabs[14].navHidden)")
