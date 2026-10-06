"""Offline cross-check of Mage choices against the reviewed client/tooltip evidence."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'tools/mage-scroll-evidence.json'
rows=json.loads(source.read_text(encoding='utf-8'))
code=(ROOT/'addon/BuffTap/WeaponCoatings.lua').read_text(encoding='utf-8')
pattern=r'\{key="([^"]+)",class="MAGE",name="([^"]+)",ranks=\{(\d+)\},enchants=\{(\d+)\},items=\{\{(\d+),(\d+)\}\},subclasses=(\d+),invTypes=(\d+)\}'
actual={int(m[4]):m for m in re.findall(pattern,code)}
expected={m['itemID']:m for m in rows if m['itemID']!=277503}
assert len(actual)==15 and actual.keys()==expected.keys(), 'Unexpected or missing Mage scroll'
for item,m in expected.items():
 record=actual[item];eq=m['equipment']
 assert int(record[2])==m['spellID']==int(record[5])
 assert int(record[3])==m['effects'][0]['enchantID']
 assert int(record[6])==int(eq['EquippedItemSubclass']) and int(record[7])==int(eq['EquippedItemInvTypes'])
 assert record[1]==m['currentItemName'] and m['tooltipUseSpellMatches'] is True
print('All 15 Mage item/use/enchant/weapon mappings match reviewed evidence. Spellbreak excluded.')
