from test_profiles import tests
from test_bufftap import ROOT,ADDON,LuaRuntime
import json

def table_to_python(value):
 if hasattr(value,'items'):return {k:table_to_python(v) for k,v in value.items()}
 return value
def to_lua(lua,value):
 if isinstance(value,dict):
  t=lua.table()
  for k,v in value.items():t[k]=to_lua(lua,v)
  return t
 return value
def boot(name,cls='DRUID',shared=None,legacy=None,forever=False):
 lua=LuaRuntime(unpack_returned_tuples=True)
 lua.execute((ROOT/'tests/mock.lua').read_text(encoding='utf-8'))
 lua.execute('playerClass='+json.dumps(cls)+'; UnitNameUnmodified=function() return '+json.dumps(name)+', '+('"Surname"' if forever else 'nil')+' end')
 if forever:lua.execute('RegionalUniqueNamesEnabled=function() return true end; C_GameRules={IsGameRuleActive=function() return false end}; Enum.GameRule={HardcoreRuleset=1,RPRuleset=2,PvPRuleset=3}')
 if shared is not None:lua.globals().BuffTapProfiles=to_lua(lua,shared)
 if legacy is not None:lua.globals().BuffTapDB=to_lua(lua,legacy)
 ns=lua.table()
 for f in [x.strip() for x in (ADDON/'BuffTap.toc').read_text().splitlines() if x.strip().endswith('.lua')]:lua.execute((ADDON/f).read_text(encoding='utf-8-sig'),'BuffTap',ns)
 lua.execute('BuffTap:InitDB(); BuffTap:Refresh()')
 return lua
def passed(name):tests.append(name);print('PASS',name)

first=boot('First',legacy={'size':92,'keys':{1:'ALT-B'},'buffs':{'thorns':False}})
first.execute('BuffTap:SaveClassSetup()')
store=table_to_python(first.globals().BuffTapProfiles); legacy=table_to_python(first.globals().BuffTapDB)
again=boot('First',shared=store,legacy=legacy)
again.execute("assert(BuffTap.db.size==92 and BuffTap.db.keys[1]=='ALT-B' and not BuffTap.db.buffs.thorns); assert(#BuffTap:ProfileNames()==1)")
passed('Real reload reconstructs migrated profile and character-only settings')

second=boot('Second',shared=store,legacy={'size':72,'buffs':{'thorns':True}})
second.execute("assert(BuffTap.db.size==72 and BuffTap.db.buffs.thorns); assert(BuffTap.profileDB:GetCurrentProfile()=='Second - Test Realm'); assert(BuffTap:SelectSettingsProfile('First - Test Realm')); assert(BuffTap.db.size==92 and BuffTap.db.keys[1]=='ALT-B' and BuffTap.db.buffs.thorns); BuffTap.db.size=104; BuffTap:SaveClassSetup()")
passed('Second same-class alt starts independent and can link general preferences')
thirdStore=table_to_python(second.globals().BuffTapProfiles)
firstReload=boot('First',shared=thirdStore,legacy=legacy)
firstReload.execute('assert(BuffTap.db.size==104 and not BuffTap.db.buffs.thorns)')
passed('Shared edits reach another character on its next login without changing buffs')

paladin=boot('Paladin','PALADIN',shared=thirdStore,legacy={'blessingAssignments':True,'blessingClasses':{'WARRIOR':'bom'}})
paladin.execute("assert(#BuffTap:ClassCopySources('First - Test Realm')==0); assert(BuffTap:SelectSettingsProfile('First - Test Realm')); assert(BuffTap.db.size==104 and BuffTap.db.blessingAssignments and BuffTap.db.blessingClasses.WARRIOR=='bom')")
passed('Different-class alt shares appearance and bindings but retains its blessing setup')

second.execute("assert(BuffTap:SelectSettingsProfile('Second - Test Realm')); assert(BuffTap:CopySettingsProfile('First - Test Realm','First - Test Realm')); assert(not BuffTap.db.buffs.thorns); assert(BuffTap.profileDB:GetCurrentProfile()=='Second - Test Realm')")
passed('Same-class alt explicitly imports source buff preferences into an independent profile')

forever=boot('Hero',forever=True)
forever.execute("assert(BuffTap.profileDB.keys.char=='Hero Surname'); assert(BuffTap:CreateSettingsProfile('Forever',true))")
passed('Unmodified AceDB uses Forever surnames and regional name identity')

bad=boot('Repair',shared={'profiles':'bad','profileKeys':True,'global':1},legacy={'size':81})
bad.execute('assert(BuffTap.db.size==81 and type(BuffTap.profileDB.sv.profileKeys)=="table")')
passed('Malformed account-wide top-level storage recovers without losing legacy appearance')
recovered=boot('First',shared={},legacy=legacy)
recovered.execute('assert(BuffTap.db.size==92 and BuffTap.db.keys[1]=="ALT-B" and not BuffTap.db.buffs.thorns)')
passed('Missing account-wide profile data can recover the retained migration backup')
print('ALL',len(tests),'SCENARIOS PASSED')
