"""Focused review fixes only; does not import the full legacy test chain."""
import ast
import sys
import types
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tests'))
path=ROOT/'tests/test_bufftap.py'
prefix=[]
for node in ast.parse(path.read_text(encoding='utf-8-sig')).body:
 if isinstance(node,ast.Expr) and isinstance(node.value,ast.Call) and getattr(node.value.func,'id',None)=='test': break
 prefix.append(node)
base=types.ModuleType('test_bufftap'); base.__file__=str(path)
exec(compile(ast.Module(body=prefix,type_ignores=[]),str(path),'exec'),base.__dict__)
sys.modules['test_bufftap']=base
import test_buff_sound_editor_1267
import test_abolish_1267
import test_buff_alerts_1267
import test_buff_queue_sound
lua=base.LuaRuntime()
for name in ('Alerts.lua','BuffTap.lua','Profiles.lua','BuffSoundOptions.lua','OptionsStyle.lua','Cleanse.lua','Onboarding.lua','Options.lua','OptionsRefinement.lua'):
 result=lua.eval('loadstring')((ROOT/'addon/BuffTap'/name).read_text(encoding='utf-8-sig'))
 if isinstance(result,tuple): raise RuntimeError(result)
 print('SYNTAX',name,'Lua 5.1 OK')
print('Focused fix scenarios:',len(base.tests),'passed;',len(base.failures),'failed.')
if base.failures: raise SystemExit(1)
