from pathlib import Path
import csv, json, hashlib, re, argparse

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description='Build BuffTap class data from Forever client DB2 exports.')
parser.add_argument('--data',type=Path,default=ROOT/'research/review-0.8.1')
DATA=parser.parse_args().data
OUT=ROOT/'addon/BuffTap'
# Product choices, not a source-code transcription. Keys/order are the public
# SavedVariables compatibility contract; client facts are read only from DB2 CSVs.
# class, kind, key, seed spell, enabled, coverage set (optional)
SPEC='''
DRUID group gotw 21849 1 wild
DRUID single motw 1126 1 wild
DRUID single thorns 467 1
DRUID self omen 16864 1
DRUID self natures-grasp 16689 0
MAGE group ab 23028 1 intellect
MAGE single ai 1459 1 intellect
MAGE self mage-armor 6117 1 magearmor
MAGE self ice-armor 7302 0 magearmor
MAGE self frost-armor 168 0 magearmor
MAGE single dampen 604 0 magic
MAGE single amplify 1008 0 magic
PRIEST group pof 21562 1 fortitude
PRIEST single fort 1243 1 fortitude
PRIEST group pos 27681 1 spirit
PRIEST single spirit 14752 1 spirit
PRIEST group posp 27683 0 shadow
PRIEST single sp 976 0 shadow
PRIEST self inner-fire 588 1
PRIEST single fear-ward 6346 0
PRIEST self shadowform 15473 0
PRIEST self shadowguard 18137 0
PRIEST self touch-weakness 2652 0
PALADIN blessing gbok 25898 1 kings
PALADIN blessing bok 20217 1 kings
PALADIN blessing gbom 25782 1 might
PALADIN blessing bom 19740 1 might
PALADIN blessing gbow 25894 1 wisdom
PALADIN blessing bow 19742 1 wisdom
PALADIN blessing gbos 25895 0 salvation
PALADIN blessing bos 1038 0 salvation
PALADIN blessing gbol 25890 0 light
PALADIN blessing bol 19977 0 light
PALADIN self righteous-fury 25780 0
PALADIN aura devotion 465 1 paladinaura
PALADIN aura retribution 7294 0 paladinaura
PALADIN aura concentration 19746 0 paladinaura
PALADIN aura shadow-res-aura 19876 0 paladinaura
PALADIN aura frost-res-aura 19888 0 paladinaura
PALADIN aura fire-res-aura 19891 0 paladinaura
PALADIN tracking sense-undead 5502 0
PALADIN seal seal-righteousness 21084 1 seals
PALADIN seal seal-crusader 21082 0 seals
PALADIN seal seal-command 20375 0 seals
PALADIN seal seal-justice 20164 0 seals
PALADIN seal seal-light 20165 0 seals
PALADIN seal seal-wisdom 20166 0 seals
PALADIN seal seal-fury 1311649 0 seals
WARRIOR group battle-shout 6673 1
HUNTER aspect aspect-hawk 13165 1 aspects
HUNTER aspect aspect-monkey 13163 0 aspects
HUNTER aspect aspect-cheetah 5118 0 aspects
HUNTER aspect aspect-beast 13161 0 aspects
HUNTER aspect aspect-pack 13159 0 aspects
HUNTER aspect aspect-wild 20043 0 aspects
HUNTER group trueshot 19506 1
HUNTER tracking track-beasts 1494 1 hunting
HUNTER tracking track-humanoids 19883 0 hunting
HUNTER tracking track-undead 19884 0 hunting
HUNTER tracking track-hidden 19885 0 hunting
HUNTER tracking track-elementals 19880 0 hunting
HUNTER tracking track-demons 19878 0 hunting
HUNTER tracking track-giants 19882 0 hunting
HUNTER tracking track-dragonkin 19879 0 hunting
HUNTER pet revive-pet 982 1
SHAMAN self water-shield 408510 0 shields
SHAMAN self lightning-shield 324 1 shields
SHAMAN weapon windfury 8232 1 imbues
SHAMAN weapon flametongue 8024 0 imbues
SHAMAN weapon frostbrand 8033 0 imbues
SHAMAN weapon rockbiter 8017 0 imbues
SHAMAN single water-breathing 131 0
SHAMAN single water-walking 546 0
WARLOCK self demon-armor 706 1 demonarmor
WARLOCK self demon-skin 687 0 demonarmor
WARLOCK single unending-breath 5697 0
WARLOCK single detect-invis 132 0
WARLOCK self soul-link 19028 1
ROGUE weapon instant-poison 8679 1
ROGUE weapon deadly-poison 2835 1
ROGUE weapon crippling-poison 3408 0
ROGUE weapon mind-poison 5763 0
ROGUE weapon wound-poison 13220 0
ALL tracking find-herbs 2383 0 gathering
ALL tracking find-minerals 2580 0 gathering
'''
PAIRS={'gotw':'motw','ab':'ai','pof':'fort','pos':'spirit','posp':'sp','gbok':'bok','gbom':'bom','gbow':'bow','gbos':'bos','gbol':'bol'}
TARGETS={'thorns':['WARRIOR','PALADIN','DRUID'], 'bom':['WARRIOR','ROGUE','HUNTER','PALADIN'], 'bow':['MAGE','WARLOCK','PRIEST','SHAMAN','DRUID','PALADIN']}
MASK={'WARRIOR':1,'PALADIN':2,'HUNTER':4,'ROGUE':8,'PRIEST':16,'SHAMAN':64,'MAGE':128,'WARLOCK':256,'DRUID':1024,'ALL':0}
def rows(file):
    with (DATA/file).open(encoding='utf-8-sig',newline='') as f: return list(csv.DictReader(f))
names={int(r['ID']):r['Name_lang'] for r in rows('spellnames.csv')}
levels={int(r['SpellID']):int(r['SpellLevel']) for r in rows('SpellLevels.csv') if r['DifficultyID']=='0'}
abilities=rows('SkillLineAbility.csv')
subtexts={int(r['ID']):r['NameSubtext_lang'] for r in rows('Spell.csv')}
effects={}
for r in rows('SpellEffect.csv'): effects.setdefault(int(r['SpellID']),set()).add(int(r['Effect']))
definitions=[]; coverage={}
for line in SPEC.splitlines():
    if not line.strip(): continue
    cls,kind,key,seed,on,*group=line.split(); seed=int(seed); name=names[seed]
    if cls=='ROGUE':
        # Poison recipes/application spells can carry Roman numerals in their names.
        stem=lambda s: re.sub(r' [IVX]+$','',s)
        ids={i for i,n in names.items() if stem(n)==stem(name) and levels.get(i,0)>0 and effects.get(i,set()) & {24,54,360}}
    else:
        ids={int(r['Spell']) for r in abilities if names.get(int(r['Spell']))==name and (int(r['ClassMask']) in (0,MASK[cls])) and levels.get(int(r['Spell']),0)>0}
    if cls!='ROGUE':
        ids={i for i in ids if 2 not in effects.get(i,set()) and (i==seed or re.match(r'^Rank [0-9]+$',subtexts.get(i,'')))}
    # Retain the explicitly verified spell as a client alias even if its skill row is absent.
    ids.add(seed)
    ranks=sorted(ids,key=lambda i:(levels.get(i,0),i),reverse=True)
    d=dict(key=key,class_=cls,kind=kind,name=name,ranks=ranks,defaultOn=on=='1')
    if group:
        d['coverage']=group[0]; coverage.setdefault(group[0],[]).append(name)
    else: d['covers']=[] if kind=='pet' else [name]
    if key in PAIRS: d.update(singleKey=PAIRS[key],minNeed=2 if kind=='blessing' else 3)
    for g,s in PAIRS.items():
        if key==s: d['groupKey']=g
    target=TARGETS.get(PAIRS.get(key,key))
    if target: d['target']=target
    definitions.append(d)
# Gathering helper recognizes these independently of the dormant class entries.
coverage['gathering'] += [names[2481],names[43308]]
def lua(v):
    if isinstance(v,bool): return str(v).lower()
    if isinstance(v,str): return json.dumps(v,ensure_ascii=False)
    if isinstance(v,list): return '{'+','.join(lua(x) for x in v)+'}'
    if isinstance(v,dict): return '{'+','.join(('class' if k=='class_' else k)+'='+lua(x) for k,x in v.items())+'}'
    return str(v)
lines=['-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.', '-- See LICENSE-MPL-2.0.txt.', '-- Generated from Forever 1.60.1.70009 client tables by tools/build_catalog.py.', '-- Setting keys and ordering preserve BuffTap saved-profile compatibility.', 'local _,B=...', 'local coverage='+lua(coverage), 'B.Buffs={']
lines += ['  '+lua(d)+',' for d in definitions]
lines += ['}', 'for _,definition in ipairs(B.Buffs) do', '  if definition.coverage then definition.covers=coverage[definition.coverage]; definition.coverage=nil end', 'end', 'B.RankLevel={']
allids={i for d in definitions for i in d['ranks']}
lines += [f'  [{i}]={levels.get(i,1)},' for i in sorted(allids)]
lines += ['}', 'B.GroupReagents={']
groupids={i for d in definitions if 'singleKey' in d for i in d['ranks']}
for r in sorted(rows('SpellReagents.csv'),key=lambda r:int(r['SpellID'])):
    i=int(r['SpellID'])
    if i in groupids:
        reagents=[[int(r[f'Reagent_{j}']),int(r[f'ReagentCount_{j}'])] for j in range(8) if int(r[f'Reagent_{j}'])>0 and int(r[f'ReagentCount_{j}'])>0]
        if reagents: lines.append(f'  [{i}]='+lua(reagents)+',')
lines += ['}', '']
(OUT/'Catalog.lua').write_text('\n'.join(lines),encoding='utf-8')
evidence={'build':'1.60.1.70009','source':'Blizzard DB2 tables exported through wago.tools','tables':{n:hashlib.sha256((DATA/n).read_bytes()).hexdigest() for n in ['spellnames.csv','SpellLevels.csv','SkillLineAbility.csv','SpellEffect.csv','SpellReagents.csv','Spell.csv']},'definitions':definitions,'ranks':len(allids)}
(ROOT/'tools/catalog-evidence.json').write_text(json.dumps(evidence,indent=2),encoding='utf-8')
print(f'Generated {len(definitions)} families, {len(allids)} client spell records.')
