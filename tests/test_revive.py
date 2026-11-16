from test_bufftap import test, tests

R=("local B=BuffTap; playerClass='PRIEST'; spell(2006,'Resurrection'); "
 "GetNumSubgroupMembers=function() return 1 end; IsInRaid=function() return false end; "
 "local oldExists=UnitExists; UnitExists=function(u) return u=='party1' or oldExists(u) end; "
 "UnitIsPlayer=function() return true end; UnitIsConnected=function() return true end; "
 "dead={party1=true}; ghost={}; incoming={}; "
 "UnitIsDead=function(u) return dead[u]==true end; UnitIsGhost=function(u) return ghost[u]==true end; "
 "UnitHasIncomingResurrection=function(u) return incoming[u]==true end; "
 "local oldDG=UnitIsDeadOrGhost; UnitIsDeadOrGhost=function(u) if u=='player' then return false end return dead[u]==true or ghost[u]==true end; ")
test('Resurrection is on by default and Rebirth is off',"assert(BuffTap.db.reviveEnabled==true and BuffTap.db.reviveRebirth==false)")
test('A dead group member gets your resurrection spell first',R+"refresh(); local a=B.action; assert(a and a.source=='revive' and a.target=='party1' and a.id==2006, a and a.source); assert(B.button.attrs.spell==2006 and B.button.attrs.unit=='party1')")
test('Released spirits are left alone',R+"ghost.party1=true; dead.party1=false; refresh(); assert(not (B.action and B.action.source=='revive'))")
test('Someone already being resurrected is skipped',R+"incoming.party1=true; refresh(); assert(not (B.action and B.action.source=='revive'))")
test('Turning resurrection off stops it',R+"B.db.reviveEnabled=false; refresh(); assert(not (B.action and B.action.source=='revive'))")
test('A dead player you target can be resurrected',R+"dead.party1=nil; dead.target=true; local oldIn=UnitInParty; UnitInParty=function(u) return false end; refresh(); assert(B.action and B.action.source=='revive' and B.action.target=='target')")
test('Rebirth is only offered when turned on',"local B=BuffTap; playerClass='DRUID'; spell(20484,'Rebirth'); GetNumSubgroupMembers=function() return 1 end; IsInRaid=function() return false end; local oldExists=UnitExists; UnitExists=function(u) return u=='party1' or oldExists(u) end; UnitIsPlayer=function() return true end; UnitIsDead=function(u) return u=='party1' end; UnitIsGhost=function() return false end; UnitHasIncomingResurrection=function() return false end; refresh(); assert(not (B.action and B.action.source=='revive')); B.db.reviveRebirth=true; refresh(); assert(B.action and B.action.source=='revive' and B.action.id==20484)")
test('A resurrection is dropped once they are alive again',R+"refresh(); local a=B.action; dead.party1=false; assert(not B:Validate(a))")
test('Cleanse page has the Resurrection row',R+"B:Options(); local f=B.options; assert(f.reviveEnable and f.reviveGroup and f.reviveTarget and f.reviveRebirth); B:UpdateCleansePage(); assert(not f.reviveRebirth.shown and f.reviveNote.text:find('Resurrection',1,true)); f.reviveEnable:SetChecked(false); f.reviveEnable.scripts.OnClick(f.reviveEnable); assert(B.db.reviveEnabled==false)")
test('Classes that cannot resurrect see a note',"local B=BuffTap; playerClass='MAGE'; spell(475,'Remove Lesser Curse'); B:Options(); B:UpdateCleansePage(); assert(B.options.reviveNote.text:find(\"can't resurrect\",1,true))")
test('Druid without resurrection shows one line, not two (GitHub #4)',"local B=BuffTap; playerClass='DRUID'; B:Options(); local f=B.options; B:UpdateCleansePage(); assert(not f.reviveRebirth.shown,'switch hidden'); assert(f.reviveNote.shown and f.reviveNote.text=='Not learned yet',tostring(f.reviveNote.text))")
