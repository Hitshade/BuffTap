from pathlib import Path
import ast,types,sys,os
os.environ['BT_KEEP_GOING']='1'
r=Path(__file__).resolve().parents[1]
m=types.ModuleType('test_bufftap');m.__file__=str(r/'tests/test_bufftap.py');sys.modules['test_bufftap']=m
s=Path(m.__file__).read_text();exec(s[:s.index('\ntest(')],m.__dict__)
h=types.ModuleType('test_helpers');h.test=m.test
for n in ast.parse((r/'tests/test_helpers.py').read_text()).body:
 if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='solo' for t in n.targets):h.solo=ast.literal_eval(n.value)
sys.modules['test_helpers']=h
for name in ['test_directed_thanks','test_thanks_late_caster','test_thanks_diagnostics','test_thanks_events_12612','test_manual_thanks_12612','test_thanks_payload_12613']:
 mod=types.ModuleType(name);mod.__file__=str(r/('tests/'+name+'.py'));sys.modules[name]=mod;exec(Path(mod.__file__).read_text(),mod.__dict__)
print('FOCUSED_TOTAL',len(m.tests),'FAILURES',len(m.failures))
for name,detail in m.full.items():print(name,detail)
sys.exit(bool(m.failures))
