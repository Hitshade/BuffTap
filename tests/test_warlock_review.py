from test_warlock_stones import test, tests, soul, raid, named

test('Raid Soulstone with missing caster never claims absence', raid+"auras.raid2={{spellId=20765,name='Soulstone Resurrection',duration=1800,expirationTime=now+1800}}; refresh(); assert(not BuffTap.action and not next(bindings))")
test('Raid Soulstone with restricted caster never arms an item', raid+"auras.raid2={{spellId=20765,name='Soulstone Resurrection',duration=1800,expirationTime=now+1800,sourceUnit={secret=true}}}; refresh(); assert(not BuffTap.action)")
test('Raid Soulstone with unresolved caster fails closed', raid+"auras.raid2={{spellId=20765,name='Soulstone Resurrection',duration=1800,expirationTime=now+1800,sourceUnit='raid40'}}; refresh(); assert(not BuffTap.action)")
test('Raid Soulstone with unreadable caster identity fails closed', raid+"auras.raid2={{spellId=20765,name='Soulstone Resurrection',duration=1800,expirationTime=now+1800,sourceUnit='raid3'}}; local same=UnitIsUnit; UnitIsUnit=function(a,b) if a=='raid3' then return nil end return same(a,b) end; refresh(); assert(not BuffTap.action)")
test('Unreadable party count never implies solo Soulstone placement', soul+"GetNumSubgroupMembers=function() return nil end; refresh(); assert(not BuffTap.action)")
test('Unreadable raid count never implies no Soulstone coverage', raid+"GetNumGroupMembers=function() return nil end; refresh(); assert(not BuffTap.action)")
test('Incomplete party roster never arms Soulstone', soul+"local exists=UnitExists; UnitExists=function(u) if u=='party2' then return false end return exists(u) end; refresh(); assert(not BuffTap.action)")
test('Unreadable grouping never arms Soulstone', soul+"IsInRaid=function() return nil end; refresh(); assert(not BuffTap.action)")
test('Duplicate assignment names are not silently resolved', named+"names.party1={'Carol','Other'}; BuffTap.db.soulstoneAssigned='Carol'; local unit,why=BuffTap:SoulstoneAssignedUnit(16896,{'player','party1','party2'}); assert(not unit and why:find('ambiguous'))")
regional=soul+"""
RegionalUniqueNamesEnabled=function() return true end
Constants={CharacterNameSeparatorConsts={CHARACTERNAME_SURNAME_SEPARATOR=' '}}
UnitName=function(u) if u=='target' or u=='party2' then return 'Carol','Sunrise' end if u=='party1' then return 'Carol','Moonrise' end return 'Tester','Stone' end
inRange.party1=true; inRange.party2=true
"""
test('Forever assignment saves first name and surname without a fake realm', regional+"assert(BuffTap:SetSoulstoneAssignedFromTarget()); assert(BuffTap.db.soulstoneAssigned=='Carol Sunrise')")
test('Forever assignment distinguishes players with the same first name', regional+"BuffTap.db.soulstoneParty='assigned'; BuffTap.db.soulstoneAssigned='Carol Sunrise'; refresh(); assert(BuffTap.action.target=='party2')")
test('Forever missing surname cannot save an ambiguous assignment', regional+"UnitName=function() return 'Carol' end; assert(not BuffTap:SetSoulstoneAssignedFromTarget())")
test('Soulstone identity changing before click clears the secure payload', named+"BuffTap.db.soulstoneParty='assigned'; BuffTap.db.soulstoneAssigned='Carol'; refresh(); assert(BuffTap.action.target=='party2'); local guid=UnitGUID; UnitGUID=function(u) if u=='party2' then return 'replacement' end return guid(u) end; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action and not next(bindings))")
test('Saving Soulstone target activates party assignment and keeps popup open', soul+"UnitName=function(u) return u=='target' and 'Carol' or 'Tester' end; BuffTap:Options(); local sm=BuffTap.helperWindow.soulMenu; sm:Show(); sm.useTarget.scripts.OnClick(); assert(BuffTap.db.soulstoneAssigned=='Carol' and BuffTap.db.soulstoneParty=='assigned' and BuffTap.db.soulstoneRaid=='remind' and sm:IsShown())")
test('Saving Soulstone target in a raid changes only raid mode', raid+"UnitName=function(u) return u=='target' and 'Carol' or 'Tester' end; BuffTap:Options(); local sm=BuffTap.helperWindow.soulMenu; sm:Show(); sm.useTarget.scripts.OnClick(); assert(BuffTap.db.soulstoneRaid=='assigned' and BuffTap.db.soulstoneParty=='healer' and sm:IsShown())")
test('Rejected Soulstone target preserves the previous assignment', soul+"BuffTap.db.soulstoneAssigned='Carol'; UnitIsPlayer=function(u) return u~='target' end; BuffTap:Options(); local sm=BuffTap.helperWindow.soulMenu; sm:Show(); sm.useTarget.scripts.OnClick(); assert(BuffTap.db.soulstoneAssigned=='Carol' and sm:IsShown() and sm.feedback.text:find('Select a friendly player'))")
test('Soulstone selections and clear keep the menu open', soul+"BuffTap:Options(); local sm=BuffTap.helperWindow.soulMenu; sm:Show(); sm.party.self.scripts.OnClick(); assert(sm:IsShown() and BuffTap.db.soulstoneParty=='self'); sm.party.assigned.scripts.OnClick(); assert(sm:IsShown() and sm.feedback.text:find('Use current target')); sm.clear.scripts.OnClick(); assert(sm:IsShown() and BuffTap.db.soulstoneParty=='healer' and BuffTap.db.soulstoneRaid=='remind')")
test('Soulstone menu uses its own Escape handler and Done without an overlay', soul+"BuffTap:Options(); local sm=BuffTap.helperWindow.soulMenu; assert(not sm.dismiss); sm:Show(); sm.scripts.OnKeyDown(sm,'SPACE'); assert(sm:IsShown()); sm.scripts.OnKeyDown(sm,'ESCAPE'); assert(not sm:IsShown()); sm:Show(); sm.done.scripts.OnClick(); assert(not sm:IsShown())")
print('ALL', len(tests), 'SCENARIOS PASSED')
