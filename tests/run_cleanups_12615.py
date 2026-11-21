from pathlib import Path
import types,sys,os
os.environ['BT_KEEP_GOING']='1'
r=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(r/'tests'))
m=types.ModuleType('test_bufftap');m.__file__=str(r/'tests/test_bufftap.py');sys.modules['test_bufftap']=m
s=Path(m.__file__).read_text();exec(s[:s.index('\ntest(')],m.__dict__)
start=len(m.tests)
import test_cleanups_12615
print('FOCUSED_TOTAL',len(m.tests),'FAILURES',len(m.failures))
for name,detail in m.full.items():print(name,detail)
sys.exit(bool(m.failures))
