"""Run only named nearby/onboarding checks without importing legacy test chains."""
import ast
import sys
import types
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tests'))
source=ROOT/'tests/test_bufftap.py'
tree=ast.parse(source.read_text())
prefix=[]
for node in tree.body:
 if isinstance(node,ast.Expr) and isinstance(node.value,ast.Call) and getattr(node.value.func,'id',None)=='test': break
 prefix.append(node)
base=types.ModuleType('test_bufftap'); base.__file__=str(source)
exec(compile(ast.Module(body=prefix,type_ignores=[]),str(source),'exec'),base.__dict__)
sys.modules['test_bufftap']=base

def selected(filename,names):
 path=ROOT/'tests'/filename
 env=dict(base.__dict__)
 for node in ast.parse(path.read_text()).body:
  if isinstance(node,(ast.Assign,ast.FunctionDef)):
   exec(compile(ast.Module(body=[node],type_ignores=[]),str(path),'exec'),env)
  elif isinstance(node,ast.Expr) and isinstance(node.value,ast.Call) and getattr(node.value.func,'id',None)=='test':
   if ast.literal_eval(node.value.args[0]) in names:
    exec(compile(ast.Module(body=[node],type_ignores=[]),str(path),'exec'),env)

def matching(filename,words):
 names=set()
 for n in ast.parse((ROOT/'tests'/filename).read_text()).body:
  if isinstance(n,ast.Expr) and isinstance(n.value,ast.Call) and getattr(n.value.func,'id',None)=='test':
   name=ast.literal_eval(n.value.args[0])
   if any(w.lower() in name.lower() for w in words): names.add(name)
 return names

selected('test_release_119.py',matching('test_release_119.py',[
 'setup','introduction','Leave me alone','Copy page','Last page','Nearby pitch','Classes already','Existing Nearby','Not now']))
selected('test_release_125.py',{'1.25 class buff configuration is identical at level one and sixty',
 'Manual quick review preserves the profile and Shaman weapon',
 'Quick setup selections persist across Back without applying','Paladin quick review keeps an existing blessing plan'})
selected('test_convenience.py',{'Pause immediately clears secure action and overrides without changing preferences',
 'Completed setup suppresses the legacy welcome card','First-run setup waits until combat ends',
 'Combat-delayed first-run setup resumes after combat'} | matching('test_convenience.py',['Edit Mode']))
selected('test_layout_setup_beta4.py',matching('test_layout_setup_beta4.py',['setup','class recommendation','class reminders','character choices','Existing quick review']))
nearby=ast.parse((ROOT/'tests/test_nearby.py').read_text())
setup=next(ast.literal_eval(n.value) for n in nearby.body if isinstance(n,ast.Assign) and any(getattr(t,'id',None)=='setup' for t in n.targets))
selected('test_nearby.py',{'Friendly nameplates are mandatory without changing CVar','Unreadable nameplate setting cannot arm nearby casts','Enabling seeds existing plates using Blizzard GetUnit','Nearby keeps nameplate help out of the active list'})
selected('test_release_119.py',matching('test_release_119.py',['Edit Mode']))
# The selected existing case needs only the shared Nearby fixture, not its test module.
path=ROOT/'tests/test_release_1200b.py'
for node in ast.parse(path.read_text()).body:
 if isinstance(node,ast.Expr) and isinstance(node.value,ast.Call) and getattr(node.value.func,'id',None)=='test' and ast.literal_eval(node.value.args[0])=='Nearby page carries the guide and appearance moved to Customization':
  exec(compile(ast.Module(body=[node],type_ignores=[]),str(path),'exec'),dict(base.__dict__,setup=setup,B='local B=BuffTap; '))
import test_onboarding_quickstart
fixture=types.ModuleType('test_nearby'); fixture.setup=setup
sys.modules['test_nearby']=fixture
import test_release_1265
import test_mana_wait_display
lua=base.LuaRuntime()
for name in ('Onboarding.lua','Convenience.lua','Alerts.lua','Engine.lua','BuffTap.lua'):
 result=lua.eval('loadstring')((ROOT/'addon/BuffTap'/name).read_text(encoding='utf-8-sig'))
 if isinstance(result,tuple): raise RuntimeError(result)
 print('SYNTAX',name,'Lua 5.1 OK')
print(f'Focused result: {len(base.tests)} passed, {len(base.failures)} failed; no full suite run.')
if base.failures: raise SystemExit(1)
