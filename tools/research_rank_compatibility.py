"""Preserve primary Forever data for rank and consumable research; no addon edits."""
from pathlib import Path
import concurrent.futures, csv, hashlib, html, json, re, urllib.request
from datetime import datetime, timezone
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parent/'research/rank-compatibility-1.26.4'
OUT.mkdir(parents=True,exist_ok=True)
OLD=ROOT.parent/'research/class-spell-review-1.26.3-current'
sources=[]
def fetch(pair):
    key,url=pair
    try:
        body=urllib.request.urlopen(url,timeout=30).read()
        (OUT/key).write_bytes(body)
        return {'key':key,'url':url,'bytes':len(body),'sha256':hashlib.sha256(body).hexdigest()}
    except Exception as exc:
        return {'key':key,'url':url,'error':str(exc)}

lua=LuaRuntime(unpack_returned_tuples=True)
ns=lua.table()
lua.execute((ROOT/'addon/BuffTap/Catalog.lua').read_text(encoding='utf-8-sig'),'BuffTap',ns)
lua.execute((ROOT/'addon/BuffTap/ConsumableData.lua').read_text(encoding='utf-8-sig'),'BuffTap',ns)
buffs=[b for _,b in ns.Buffs.items() if b.kind in ('single','group','blessing')]
ids=sorted({int(v) for b in buffs for _,v in b.ranks.items()})
items={int(i.id):int(i.useSpell) for _,f in ns.ConsumableFamilies.items() if not f.hidden for _,i in f['items'].items()}
jobs=[(f'spell-{i}.json',f'https://nether.wowhead.com/forever/tooltip/spell/{i}') for i in ids]
jobs += [(f'item-{i}.json',f'https://nether.wowhead.com/forever/tooltip/item/{i}') for i in items]
jobs += [(f'{table}-70938.csv',f'https://wago.tools/db2/{table}/csv?build=1.60.1.70938') for table in ('SpellLevels','SpellMisc','SpellAuraOptions','SpellAuraRestrictions','SpellCategories')]
base='https://raw.githubusercontent.com/Gethe/wow-ui-source/3d8abb1da73acd38e412e24fb3f99454a6392346/Interface/AddOns/'
jobs += [(name,base+path) for name,path in [('SpellDocumentation.lua','Blizzard_APIDocumentationGenerated/SpellDocumentation.lua'),('ActionButton.lua','Blizzard_ActionBar/Shared/ActionButton.lua')]]
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    sources=list(pool.map(fetch,jobs))
(OUT/'sources.json').write_text(json.dumps({'retrievedUTC':datetime.now(timezone.utc).isoformat(),'sources':sources},indent=2))
levels={int(x['SpellID']):x for x in csv.DictReader((OLD/'SpellLevels.csv').open(encoding='utf-8-sig')) if x['DifficultyID']=='0'}
misc={int(x['SpellID']):x for x in csv.DictReader((OLD/'SpellMisc.csv').open(encoding='utf-8-sig')) if x['DifficultyID']=='0'}
def plain(text): return html.unescape(re.sub('<[^>]+>',' ',text))
result=[]
for b in buffs:
    for _,i in b.ranks.items():
        i=int(i); p=OUT/f'spell-{i}.json'; tip=json.loads(p.read_text()) if p.exists() else {}
        result.append({'key':b.key,'id':i,'levels':levels.get(i),'attributes':{k:v for k,v in misc.get(i,{}).items() if 'Attributes' in k},'tooltip':plain(tip.get('tooltip',''))})
(OUT/'ranks.json').write_text(json.dumps(result,indent=2))
print('Sources:',len(sources),'success:',sum('error' not in s for s in sources))
print('Failures:',json.dumps([s for s in sources if 'error' in s]))
for r in result: print(r['key'],r['id'],r['levels'],r['tooltip'])
