from test_bufftap import test
setup="""
IsInInstance=function() return true,'pvp' end
C_Secrets={ShouldAurasBeSecret=function() return true end,ShouldSpellAuraBeSecret=function() return false end}
C_UnitAuras.GetAuraDataByIndex=function() error('BG restricted') end
C_UnitAuras.GetPlayerAuraBySpellID=function(id) return playerAuras[id] end
BuffTap.db.group=true; BuffTap.db.friendlyTarget=true
"""
test('BG direct checks offer verified missing self buff only',setup+"refresh(); assert(BuffTap.action and BuffTap.action.bgSelf and BuffTap.action.target=='player' and BuffTap.action.id==5232)")
test('BG present self Mark advances to Thorns',setup+"playerAuras[5232]={secretField=true}; refresh(); assert(BuffTap.action.id==467)")
test('BG higher rank or group coverage suppresses redundant self buff',setup+"playerAuras[21849]={}; playerAuras[467]={}; refresh(); assert(not BuffTap.action)")
test('BG hidden absence never queues a buff',setup+"C_Secrets.ShouldSpellAuraBeSecret=function() return true end; refresh(); assert(not BuffTap.action and BuffTap.buffDataUnavailable)")
test('BG one hidden buff does not block another readable self buff',setup+"local safe={}; for _,id in ipairs(BuffTap:FindBuff('thorns').ranks) do safe[id]=true end; C_Secrets.ShouldSpellAuraBeSecret=function(id) return not safe[id] end; refresh(); assert(BuffTap.action.id==467)")
test('BG missing predicate fails closed',setup+"C_Secrets.ShouldSpellAuraBeSecret=nil; refresh(); assert(not BuffTap.action)")
test('BG missing direct API fails closed',setup+"C_UnitAuras.GetPlayerAuraBySpellID=nil; refresh(); assert(not BuffTap.action)")
test('BG failed direct API fails closed',setup+"C_UnitAuras.GetPlayerAuraBySpellID=function() error('blocked') end; refresh(); assert(not BuffTap.action)")
test('BG secret direct result fails closed',setup+"C_UnitAuras.GetPlayerAuraBySpellID=function() return {secret=true} end; refresh(); assert(not BuffTap.action)")
test('BG secret predicate fails closed',setup+"C_Secrets.ShouldSpellAuraBeSecret=function() return {secret=true} end; refresh(); assert(not BuffTap.action)")
test('BG click rechecks newly applied self buff',setup+"refresh(); playerAuras[5232]={}; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('BG click rechecks newly restricted self buff',setup+"refresh(); C_Secrets.ShouldSpellAuraBeSecret=function() return true end; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('BG click retains verified missing self action',setup+"refresh(); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.action and BuffTap.action.bgSelf and BuffTap.button.attrs.spell==5232)")
test('BG close combat clears payload and resumes only out of combat',setup+"refresh(); combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); assert(not BuffTap.action and not next(bindings)); combat=false; safety('ready'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); assert(BuffTap.action and BuffTap.action.bgSelf)")
test('BG disabled self buff is not queued',setup+"BuffTap.db.buffs.motw=false; refresh(); assert(BuffTap.action.id==467)")
test('BG click rejects disabled settings',setup+"refresh(); BuffTap.db.buffs.motw=false; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('BG exit before click disarms fallback',setup+"refresh(); IsInInstance=function() return false,'none' end; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('BG fallback not applied to normal world secrecy',setup+"IsInInstance=function() return false,'none' end; refresh(); assert(not BuffTap.action)")
test('BG fallback does not alter dungeon restrictions',setup+"IsInInstance=function() return true,'party' end; refresh(); assert(not BuffTap.action)")
test('BG fallback never upgrades a self action to group cast',setup+"BuffTap.db.groupNeed=1; spell(21849,'Gift of the Wild',50); refresh(); assert(BuffTap.action.id==5232 and not BuffTap.action.groupCast)")

paladin=setup+"playerClass='PALADIN'; spells={}; book={}; spell(20217,'Blessing of Kings',20); spell(19740,'Blessing of Might',4); BuffTap.db.buffs.bok=true; BuffTap.db.buffs.bom=true; BuffTap.bookDirty=true; "
test('BG self blessing ignores raid assignment but retains enabled choice',paladin+"BuffTap.db.blessingAssignments=true; refresh(); assert(BuffTap.action and BuffTap.action.key=='bok' and BuffTap.action.target=='player'); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.action)")
test('BG self blessings do not replace an existing different blessing',paladin+"playerAuras[19742]={}; refresh(); assert(not BuffTap.action)")
test('BG higher priority hidden blessing does not imply lower is safe',paladin+"C_Secrets.ShouldSpellAuraBeSecret=function(id) return id==19742 end; refresh(); assert(not BuffTap.action)")

test('Version identifies the current build',"assert(BuffTap.version=='1.16.7')")

warlock=setup+"playerClass='WARLOCK'; spells={}; book={}; spell(19028,'Soul Link',40); BuffTap.bookDirty=true; "
test('BG Soul Link recognises pet aura without offering another cast',warlock+"playerAuras[25228]={}; refresh(); assert(not BuffTap.action)")
test('BG Soul Link casts only original spell when both identities absent',warlock+"refresh(); assert(BuffTap.action and BuffTap.action.id==19028); assert(#BuffTap:Candidates(BuffTap:FindBuff('soul-link'))==1)")
test('BG hidden Soul Link pet aura is unknown rather than missing',warlock+"C_Secrets.ShouldSpellAuraBeSecret=function(id) return id==25228 end; refresh(); assert(not BuffTap.action and BuffTap.buffDataUnavailable)")
test('Normal Soul Link recognises separate aura id despite different name',warlock+"IsInInstance=function() return false,'none' end; C_Secrets=nil; C_UnitAuras.GetAuraDataByIndex=function(u,i) if u=='player' and i==1 then return {spellId=25228,name='Localized aura',duration=0,expirationTime=0} end end; refresh(); assert(not BuffTap.action)")
