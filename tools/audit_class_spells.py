"""Audit Forever class/rank mappings against preserved client tables, offline.

Candidate discovery is not a claim that every record is currently trainable.
Use runtime class/known-spell guards and review candidate purpose before adding.
"""
from pathlib import Path
import argparse, collections, csv, hashlib, json, re
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
CLASSES = {'WARRIOR': 1, 'PALADIN': 2, 'HUNTER': 4, 'ROGUE': 8, 'PRIEST': 16,
           'SHAMAN': 64, 'MAGE': 128, 'WARLOCK': 256, 'DRUID': 1024}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data', type=Path, default=ROOT.parent/'research/review-0.8.1')
    parser.add_argument('--build', default='1.60.1.70009', help='Build of the supplied CSVs; record provenance, not an automatic download')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    hashes = {}
    def rows(name):
        path = args.data/name
        hashes[name] = hashlib.sha256(path.read_bytes()).hexdigest()
        return list(csv.DictReader(path.open(encoding='utf-8-sig')))
    names = {int(x['ID']): x['Name_lang'] for x in rows('spellnames.csv')}
    descriptions = {int(x['ID']): x['Description_lang'] for x in rows('Spell.csv')}
    levels = {int(x['SpellID']): int(x['SpellLevel']) for x in rows('SpellLevels.csv') if x['DifficultyID']=='0'}
    effects = collections.defaultdict(list)
    for x in rows('SpellEffect.csv'):
        if x['DifficultyID']=='0': effects[int(x['SpellID'])].append(x)
    durations = {int(x['ID']): int(x['Duration']) for x in rows('SpellDuration.csv')}
    misc = {int(x['SpellID']): x for x in rows('SpellMisc.csv') if x['DifficultyID']=='0'}
    abilities = rows('SkillLineAbility.csv')
    res_effects = {x['Effect'] for x in effects[2006]}
    dispel_effects = {x['Effect'] for x in effects[2782]}
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT/'tests/mock.lua').read_text(encoding='utf-8-sig'))
    ns = lua.table()
    for line in (ROOT/'addon/BuffTap/BuffTap.toc').read_text().splitlines():
        if line.strip().endswith('.lua'):
            lua.execute((ROOT/'addon/BuffTap'/line.strip()).read_text(encoding='utf-8-sig'), 'BuffTap', ns)
    lua.execute('auditKnownID=nil; BuffTap.API.Known=function(id) return id==auditKnownID end')
    definitions = collections.defaultdict(dict)
    family_names = collections.defaultdict(set)
    for _, definition in ns.Buffs.items():
        family_names[definition['class']].add(definition['name'])
        for _, spell in definition['ranks'].items(): definitions[definition['class']][int(spell)] = definition['key']
    report = []
    reviewed_counts = {}
    for cls, mask in CLASSES.items():
        lua.globals().playerClass = cls
        cleanse = set()
        for kind in ('Magic','Curse','Poison','Disease'):
            specs = ns.CleanseClassSpells(ns, kind)
            if specs:
                for _, spec in specs.items(): cleanse.add(int(spec[1]))
        ids = sorted({int(x['Spell']) for x in abilities if int(x['ClassMask']) & mask})
        reviewed_counts[cls] = len(ids)
        for spell in ids:
            data = misc.get(spell, {})
            passive = bool(int(data.get('Attributes_0', 0)) & 64)
            duration = durations.get(int(data.get('DurationIndex', 0)), 0)
            types = {x['Effect'] for x in effects[spell]}
            category = None
            supported = spell in definitions[cls]
            if types & res_effects:
                category = 'resurrection'
                lua.globals().auditKnownID = spell
                supported = ns.ReviveSpell(ns, False)==spell or ns.ReviveSpell(ns, True)==spell
            elif types & dispel_effects:
                category = 'dispel review'
                supported = spell in cleanse
            elif names.get(spell) in family_names[cls] and not supported and not passive:
                category = 'possible missing maintained-buff rank'
            elif not passive and (duration>=120000 or duration==-1) and any(x['Effect']=='6' for x in effects[spell]):
                category = 'long-duration ability review'
            if category:
                report.append({'class':cls,'id':spell,'name':names.get(spell,''),'level':levels.get(spell),
                               'category':category,'mapped':supported,'durationMS':duration,
                               'description':descriptions.get(spell,''),
                               'effects':sorted(types),'targets':sorted({x['ImplicitTarget_0'] for x in effects[spell]})})
    args.output.mkdir(parents=True,exist_ok=True)
    result = {'scope':'Nine class masks in supplied Forever client tables; not live trainability verification','build':args.build,
              'sourceHashes':hashes,'classSpellCounts':reviewed_counts,'rows':report}
    (args.output/'audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('Class mappings reviewed:',len(CLASSES),'candidate rows:',len(report))
    for cls in CLASSES:
        missing = [x for x in report if x['class']==cls and not x['mapped']]
        groups = collections.defaultdict(list)
        for x in missing: groups[(x['category'],x['name'])].append(x['id'])
        print(cls, json.dumps([{'kind':k[0],'name':k[1],'ids':v} for k,v in groups.items()]))


if __name__=='__main__':main()
