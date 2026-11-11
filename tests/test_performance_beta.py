from test_bufftap import test
setup='\nGetNumSubgroupMembers=function() return 0 end\nlocal oldExists=UnitExists\nUnitExists=function(u) return u:match(\'^nameplate%d+$\')~=nil or oldExists(u) end\nlocal oldClass=UnitClass\nUnitClass=function(u) if u:match(\'^nameplate%d+$\') then return \'Warrior\',\'WARRIOR\' end return oldClass(u) end\nlocal oldName=UnitName\nUnitName=function(u) return u:match(\'^nameplate%d+$\') and (\'Ally \'..u) or oldName(u) end\nplatesEnabled=true\nC_CVar={GetCVarBool=function(name) if name=="nameplateShowFriendlyPlayers" then return platesEnabled end end}\nC_NamePlate={GetNamePlates=function() return {{GetUnit=function() return \'nameplate1\' end}} end}\naura(\'player\',5232,\'Mark of the Wild\'); aura(\'player\',467,\'Thorns\')\nBuffTap.db.nearbyEnabled=true; refresh()\n'
probe="""
local builds=0; local scan=BuffTap.ScanMissing
BuffTap.ScanMissing=function(self,def,entries,...) if entries[1] and entries[1].unit:match("^nameplate") then builds=builds+1 end; return scan(self,def,entries,...) end
local function countRefresh() local before=builds; BuffTap:Refresh(); return builds-before end
"""
test('Stable nearby auras reuse need decisions but still validate',setup+probe+'local checks=0; local validate=BuffTap.Validate; BuffTap.Validate=function(self,...) checks=checks+1; return validate(self,...) end; local n=countRefresh(); assert(n==0 and checks>0)')
test('One aura event invalidates only that nearby player',setup+probe+"BuffTap:TrackNearby('nameplate2'); countRefresh(); BuffTap:InvalidateAura('nameplate1'); assert(countRefresh()==2)")
test('Recycled GUID cannot reuse previous recipient needs',setup+probe+"local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Player-New' or old(u) end; BuffTap:TrackNearby('nameplate1'); assert(countRefresh()>0); assert(BuffTap:NearbyCandidates()[1].guid=='Player-New')")
test('Level change recalculates rank selection immediately',setup+probe+"local old=UnitLevel; UnitLevel=function(u) return u=='nameplate1' and 60 or old(u) end; assert(countRefresh()>0)")
test('Nested target settings changes invalidate need decisions',setup+probe+"BuffTap.db.targetBuffs.motw=false; assert(countRefresh()>0); assert(BuffTap.action.key=='thorns')")
test('Profile switch invalidates nearby needs',setup+probe+"assert(BuffTap:CreateSettingsProfile('Performance copy',true)); BuffTap.db.targetBuffs.motw=false; countRefresh(); assert(BuffTap.action.key=='thorns')")
test('Missing buff becomes present without waiting for memo timeout',setup+probe+"aura('nameplate1',5232,'Mark of the Wild'); BuffTap:InvalidateAura('nameplate1'); countRefresh(); assert(BuffTap.action.key=='thorns')")
test('Fresh pre-click scan rejects a buff applied without an event',setup+probe+"aura('nameplate1',5232,'Mark of the Wild'); local row=BuffTap.nearbyFrame.rows[1]; row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)")
test('PvP changes reject cached needs immediately',setup+probe+"UnitIsPVP=function(u) return u=='nameplate1' end; countRefresh(); assert(not BuffTap.action); assert(#BuffTap:NearbyCandidates()==0)")
test('Recipient combat changes reject cached needs immediately',setup+probe+"UnitAffectingCombat=function(u) return u=='nameplate1' end; countRefresh(); assert(not BuffTap.action)")
test('Cached need still checks current mana',setup+probe+'C_Spell.IsSpellUsable=function() return false,true end; countRefresh(); assert(not BuffTap.action and BuffTap.manaBlocked)')
test('Cached need still checks current range',setup+probe+"C_Spell.IsSpellInRange=function(_,u) return u~='nameplate1' end; countRefresh(); assert(not BuffTap.action)")
test('Dismissal suppresses cached need immediately',setup+probe+"BuffTap:DismissHelper(BuffTap.action); countRefresh(); assert(BuffTap.action.key=='thorns')")
test('Memo expires within half a second without aura events',setup+probe+'now=now+.51; assert(countRefresh()>0)')
test('Spellbook rebuild cannot reuse old memo',setup+probe+'BuffTap.bookDirty=true; assert(countRefresh()>0)')
test('Diagnostic refresh builds fresh explanations',setup+probe+"BuffTap.diagnostics={'stale'}; BuffTap:Refresh(true); assert(builds>0 and BuffTap.diagnostics[1]~='stale')")
test('Disabling nearby drops transient memo',setup+probe+'BuffTap.db.nearbyEnabled=false; countRefresh(); assert(not next(BuffTap.nearbyNeedCache))')
test('Removing nearby plate drops its memo',setup+probe+"BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_REMOVED','nameplate1'); assert(not BuffTap.nearbyNeedCache.nameplate1)")
test('Class list is shared inside one pass and rebuilt outside it', "BuffTap.classListPassActive=true; BuffTap.refreshClassList=nil; local a=BuffTap:ClassList(); assert(a==BuffTap:ClassList()); BuffTap.classListPassActive=nil; BuffTap.refreshClassList=nil; BuffTap.db.priorities.thorns=1; BuffTap.db.priorities.motw=2; assert(BuffTap:ClassList()[1].key=='thorns')")

test('Memo never crosses the exact rebuff threshold',setup+probe+"BuffTap.db.targetBuffs.thorns=false; aura('nameplate1',5232,'Mark of the Wild'); local a=auras.nameplate1[1]; a.duration=1800; a.expirationTime=now+BuffTap.db.targetSeconds+.2; BuffTap:InvalidateAura('nameplate1'); countRefresh(); assert(not BuffTap.action); local cache=BuffTap.nearbyNeedCache.nameplate1; assert(cache and cache.untilTime<=now+.21); now=now+.21; countRefresh(); assert(BuffTap.action and BuffTap.action.key=='motw')")
