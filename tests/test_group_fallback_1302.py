from test_bufftap import test

MAGE = '''
local B=BuffTap
playerClass='MAGE'; spells={}; book={}
spell(1459,'Arcane Intellect',1); spell(23028,'Arcane Brilliance',56)
UnitLevel=function(u) return u=='player' and 60 or 46 end
B.db.group=true; B.db.groupNeed=3; bags[17020]=1
refresh(); assert(B.action and B.action.id==23028 and B.action.groupCount==3)
'''
CLICK = MAGE+'''
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(B.groupAttempt and B.groupAttempt.id==23028)
'''
EVENT = "B.events.scripts.OnEvent"

test('Group fallback capture uses real PreClick and current recipient identities', CLICK+'''
assert(#B.groupAttempt.recipients==3)
''')
for before in (True, False):
    err="SPELL_FAILED_LOWLEVEL='Target is too low level'; "+EVENT+"(nil,'UI_ERROR_MESSAGE',1,SPELL_FAILED_LOWLEVEL); "
    fail=EVENT+"(nil,'UNIT_SPELLCAST_FAILED','player','cast-1',23028); "
    test('Group failure level error ordering '+str(before),CLICK+(err+fail if before else fail+err)+'''
advance(1.1); refresh()
assert(B.action and B.action.id==1459 and not B.action.groupCast)
assert(B:GroupFallbackSummary():find('cast rejected',1,true))
advance(301); refresh(); assert(B.action and B.action.id==23028)
''')
test('Group failed unknown reason gets only a short fallback',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_FAILED','player','cast-1',23028)
advance(1.1); refresh(); assert(B.action and not B.action.groupCast)
advance(16); refresh(); assert(B.action and B.action.groupCast)
''')
for symbol in ('SPELL_FAILED_NO_POWER','SPELL_FAILED_REAGENTS','SPELL_FAILED_OUT_OF_RANGE','SPELL_FAILED_LINE_OF_SIGHT','SPELL_FAILED_NOT_READY','SPELL_FAILED_MOVING'):
    test('Group transient failure preserves eligibility '+symbol,CLICK+f'''
{symbol}='{symbol}'
{EVENT}(nil,'UI_ERROR_MESSAGE',1,{symbol})
{EVENT}(nil,'UNIT_SPELLCAST_FAILED','player','cast-1',23028)
advance(1.1); refresh(); assert(B.action and B.action.groupCast)
assert(not B.groupFallbacks or not next(B.groupFallbacks))
''')
test('Group interruption never enables singles fallback',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_INTERRUPTED','player','cast-1',23028)
advance(3); refresh(); assert(B.action and B.action.groupCast)
''')
test('Group mismatched cast failure cannot blacklist group spell',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_FAILED','player','cast-other',1459)
advance(5); refresh(); assert(B.action and B.action.groupCast)
assert(B:GroupFallbackSummary():find('unconfirmed',1,true))
''')
test('Successful group cast that leaves missing members falls back to singles',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast-1',23028)
aura('player',23028,'Arcane Brilliance',3500)
advance(4.2); refresh(); assert(B.action and B.action.id==1459)
assert(B:GroupFallbackSummary():find('still need=2',1,true))
''')
test('Successful complete group cast does not suppress future group spells',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast-1',23028)
for _,u in ipairs({'player','party1','party2'}) do aura(u,23028,'Arcane Brilliance',3500) end
advance(2.2); refresh(); assert(not B.action)
assert(not B.groupFallbacks or not next(B.groupFallbacks))
''')
test('Unreadable group result is reported without inventing a failure',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast-1',23028)
C_UnitAuras.GetAuraDataByIndex=function() return {secret=true} end
advance(2.2); assert(not B.groupFallbacks or not next(B.groupFallbacks))
assert(B:GroupFallbackSummary():find('unverifiable=3',1,true))
''')
test('Entering combat cancels group outcome observation without aura reads',CLICK+'''
combat=true
C_UnitAuras.GetAuraDataByIndex=function() error('combat aura read') end
'''+EVENT+'''(nil,'PLAYER_REGEN_DISABLED')
advance(3); assert(not B.groupAttempt and not B.groupFallbacks)
''')
test('Roster change clears group fallback and pending outcome',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_FAILED','player','cast-1',23028)
advance(1.1)
'''+EVENT+'''(nil,'GROUP_ROSTER_UPDATE')
refresh(); assert(B.action and B.action.groupCast)
''')
test('Changed recipient identity is never blamed for ineffective group cast',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast-1',23028)
local old=UnitGUID; UnitGUID=function(u) return 'changed-'..u end
advance(2.2); assert(not B.groupFallbacks or not next(B.groupFallbacks))
''')

for outsider in ('WARRIOR','ROGUE'):
    test('Default benefit filter does not veto group cast '+outsider,MAGE+f'''
GetNumSubgroupMembers=function() return 3 end
local old=UnitExists; UnitExists=function(u) return u=='party3' or old(u) end
UnitClass=function(u) return 'Class',u=='party3' and '{outsider}' or 'MAGE' end
B:InvalidateRoster(); refresh()
assert(B.action and B.action.id==23028 and B.action.groupCount==3)
B.db.buffClasses.ai={{['{outsider}']=false}}; refresh()
assert(B.action and not B.action.groupCast)
''')

test('Non-mana pet cannot veto or inflate a group cast',MAGE+'''
B.db.buffPets=true
local old=UnitExists; UnitExists=function(u) return u=='partypet1' or old(u) end
UnitClass=function(u) return 'Class',u=='party1' and 'HUNTER' or 'MAGE' end
UnitPowerType=function(u) return u=='partypet1' and 2 or 0 end
B:InvalidateRoster(); refresh(); assert(B.action and B.action.id==23028 and B.action.groupCount==3)
''')

RAID = '''
IsInRaid=function() return true end
GetNumGroupMembers=function() return 4 end
UnitExists=function(u) return u=='player' or u:match('^raid[1-4]$')~=nil end
UnitIsUnit=function(a,b) if a=='raid1' then a='player' end; if b=='raid1' then b='player' end; return a==b end
GetRaidRosterInfo=function(i) return 'Raider'..i,0,i<=2 and 1 or 2 end
UnitClass=function() return 'Mage','MAGE' end
'''
test('Raid-wide needs count across subgroups and still honor explicit exclusions',MAGE+RAID+'''
B:InvalidateRoster(); refresh(); assert(B.action and B.action.id==23028 and B.action.groupCount==4)
B.db.raidGroups[2]=false; refresh(); assert(B.action and not B.action.groupCast)
''')
test('Outdoor PvP protection includes flagged members in another subgroup',MAGE+RAID+'''
B.db.pvpProtection=true
UnitIsPVP=function(u) return u=='raid4' end
UnitIsPVPFreeForAll=function() return false end
IsPVPTimerRunning=function() return false end
B:InvalidateRoster(); refresh(); assert(B.action and not B.action.groupCast)
''')
for kind in ('party','raid'):
    test('PvE '+kind+' skips all PvP flag API checks',MAGE+f'''
B.db.pvpProtection=true
IsInInstance=function() return true,'{kind}' end
UnitIsPVP=function() error('PvP gate must be skipped inside PvE instances') end
UnitIsPVPFreeForAll=UnitIsPVP
refresh(); assert(B.action and B.action.id==23028)
''')
test('Caster-centered area cast does not require direct range to each recipient',MAGE+'''
aura('player',23028,'Arcane Brilliance',3500)
B.db.groupNeed=2
C_Spell.IsSpellInRange=function(id,u) return u=='player' end
UnitDistanceSquared=function(u) return u=='player' and 0 or 3600,true end
refresh(); assert(B.action and B.action.id==23028 and B.action.target=='player' and B.action.groupCount==2)
''')
test('Late aura updates settle before enabling a fallback',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast-1',23028)
advance(2.2); assert(not B.groupFallbacks or not next(B.groupFallbacks))
for _,u in ipairs({'player','party1','party2'}) do aura(u,23028,'Arcane Brilliance',3500) end
advance(2.2); assert(not B.groupFallbacks or not next(B.groupFallbacks))
''')
test('Group cast GUID match rejects stale results from another cast',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SENT','player','Tester','cast-real',23028)
'''+EVENT+'''(nil,'UNIT_SPELLCAST_FAILED','player','cast-stale',23028)
advance(1.2); assert(B.groupAttempt and not B.groupAttempt.terminal)
'''+EVENT+'''(nil,'UNIT_SPELLCAST_FAILED','player','cast-real',23028)
advance(1.1); assert(B.groupFallbacks and next(B.groupFallbacks))
''')
test('Unreadable sent spell identity is ignored without altering the attempt',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SENT','player','Tester','cast-secret',{secret=true})
assert(B.groupAttempt and not B.groupAttempt.castGUID)
''')
test('Disabled addon does not inspect a delayed group outcome',CLICK+EVENT+'''(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast-1',23028)
B.db.enabled=false
C_UnitAuras.GetAuraDataByIndex=function() error('disabled aura read') end
advance(5); assert(not B.groupFallbacks or not next(B.groupFallbacks))
''')
test('Group validation diagnostics name mana failure rather than implying reagent shortage',MAGE+'''
local old=C_Spell.IsSpellUsable
C_Spell.IsSpellUsable=function(id) if id==23028 then return false,true end return old(id) end
B:InvalidateAura(); B:Refresh(true)
local text=table.concat(B.diagnostics,' | ')
assert(text:find('ab spell=23028 skipped: not enough mana',1,true))
assert(text:find('17020=1',1,true))
''')
