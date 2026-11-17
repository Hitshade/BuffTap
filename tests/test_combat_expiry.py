from test_bufftap import test

# Combat expiry warning: planned out of combat, timers only in combat, real event dispatchers.
START="local B=BuffTap; local E=B.combatExpiryEvents.scripts.OnEvent; local function fight() combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); E(nil,'PLAYER_REGEN_DISABLED') end; local function peace() combat=false; safety('ready'); E(nil,'PLAYER_REGEN_ENABLED'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED') end; local function shown() return B.combatExpiryFrame~=nil and B.combatExpiryFrame:IsShown()==true end; "
PRIEST="playerClass='PRIEST'; spells={}; book={}; B.resolveCache={}; B.rankChoiceCache={}; spell(588,'Inner Fire',1); "

test('Combat expiry warning is off by default and starts no timers',START+"aura('player',5232,'Mark of the Wild',100,1800); refresh(); assert(B.db.combatExpiry==false); assert(B.combatExpiryPlan==nil); fight(); assert(liveTimers()==0,tostring(liveTimers())); advance(200); assert(not shown()); peace()")

test('Combat expiry warns about ten seconds before a pre-combat expiry and clears after combat',START+"B.db.combatExpiry=true; B.db.sound=true; local played=0; B.PlayAlert=function(_,kind) played=played+1; return true end; aura('player',5232,'Mark of the Wild',100,1800); aura('player',467,'Thorns',300,600); refresh(); assert(B.combatExpiryPlan and #B.combatExpiryPlan.entries==2,'plan'); played=0; fight(); advance(89); assert(not shown(),'early'); advance(2); assert(shown(),'warning'); local f=B.combatExpiryFrame; assert(f.icon.texture==136078,tostring(f.icon.texture)); assert(played==1,'sound '..played); assert(tostring(f.label.text):find('estimate',1,true)); advance(200); assert(f.more.text=='+1',tostring(f.more.text)); assert(played==2); peace(); assert(not f:IsShown()); assert(B.combatExpiryActive==nil and B.combatExpiryTimers==nil)")

test('Combat expiry never writes to the secure button in combat',START+"B.db.combatExpiry=true; aura('player',5232,'Mark of the Wild',30,1800); refresh(); fight(); advance(25); assert(shown()); assert(not B.combatExpiryFrame.protected); assert(not B.button.shown); assert(not next(bindings)); peace()")

test('Combat expiry does not depend on target buffs, group buffing or reminder sound',START+"B.db.combatExpiry=true; B.db.friendlyTarget=false; B.db.group=false; B.db.sound=false; local played=0; B.PlayAlert=function() played=played+1 end; aura('player',5232,'Mark of the Wild',50,1800); refresh(); fight(); advance(41); assert(shown()); assert(played==0); peace()")

test('Combat expiry ignores a buff removed before combat',START+"B.db.combatExpiry=true; B.db.buffs.thorns=false; aura('player',5232,'Mark of the Wild',50,1800); refresh(); assert(B.combatExpiryPlan); auras.player={}; B:InvalidateAura('player'); B:Refresh(); assert(B.combatExpiryPlan==nil); fight(); assert(liveTimers()==0); peace()")

test('Combat expiry is not planned or rescheduled from inside combat',START+"B.db.combatExpiry=true; refresh(); assert(B.combatExpiryPlan==nil); fight(); aura('player',5232,'Mark of the Wild',50,1800); B:Refresh(); assert(B.combatExpiryPlan==nil); assert(liveTimers()==0); peace()")

test('Combat expiry drops its plan on death and on a loading screen',START+"B.db.combatExpiry=true; aura('player',5232,'Mark of the Wild',50,1800); refresh(); assert(B.combatExpiryPlan); E(nil,'PLAYER_DEAD'); assert(B.combatExpiryPlan==nil); refresh(); assert(B.combatExpiryPlan); E(nil,'PLAYER_ENTERING_WORLD'); assert(B.combatExpiryPlan==nil)")

test('Combat expiry refuses a plan made for another character',START+"B.db.combatExpiry=true; aura('player',5232,'Mark of the Wild',50,1800); refresh(); B.combatExpiryPlan.guid='Player-other'; fight(); assert(liveTimers()==0); assert(B.combatExpiryPlan==nil); peace()")

test('Combat expiry restarts a self buff estimate when you recast it in combat',START+PRIEST+"B.db.combatExpiry=true; aura('player',588,'Inner Fire',100,600); refresh(); assert(B.combatExpiryPlan and #B.combatExpiryPlan.entries==1,'plan'); fight(); advance(50); E(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',588); advance(95); assert(not shown(),'renewed'); advance(500); assert(shown()); peace()")

test('Combat expiry ignores casts with unreadable spell IDs and casts by other units',START+PRIEST+"B.db.combatExpiry=true; aura('player',588,'Inner Fire',100,600); refresh(); fight(); E(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',{secret=true}); E(nil,'UNIT_SPELLCAST_SUCCEEDED','party1','cast',588); advance(91); assert(shown()); peace()")

test('Combat expiry does not renew single-target buffs from a cast, whose target is unknown',START+"B.db.combatExpiry=true; B.db.buffs.thorns=false; aura('player',5232,'Mark of the Wild',100,1800); refresh(); fight(); E(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',5232); advance(91); assert(shown()); peace()")

test('Combat expiry hides the icon with the reminder hidden but keeps the sound',START+"B.db.combatExpiry=true; B.db.sound=true; B.db.showReminder=false; local played=0; B.PlayAlert=function() played=played+1 end; aura('player',5232,'Mark of the Wild',50,1800); refresh(); played=0; fight(); advance(41); assert(not shown(),'icon hidden'); assert(played==1,'sound '..played); peace()")

test('Combat expiry option is on the buffs page and saves out of combat',START+"B:Options(); local c=B.options.combatExpiry; assert(c,'control'); assert(c:GetChecked()==false); c:SetChecked(true); c.scripts.OnClick(c); assert(B.db.combatExpiry==true); combat=true; c:SetChecked(false); c.scripts.OnClick(c); assert(B.db.combatExpiry==true); combat=false")
