"""Ordinary Classic recipient policy, using independently enumerated rank fixtures.

These verify beta selection and safety, not Forever server acceptance.
"""
import json
from test_bufftap import test, tests
from test_nearby import setup as NEAR

start = len(tests)
FAMILIES = [
    ('motw','Mark of the Wild',[(1126,1),(5232,10),(6756,20),(5234,30),(8907,40),(9884,50),(9885,60)]),
    ('thorns','Thorns',[(467,6),(782,14),(1075,24),(8914,34),(9756,44),(9910,54)]),
    ('ai','Arcane Intellect',[(1459,1),(1460,14),(1461,28),(10156,42),(10157,56)]),
    ('dampen','Dampen Magic',[(604,12),(8450,24),(8451,36),(10173,48),(10174,60)]),
    ('amplify','Amplify Magic',[(1008,18),(8455,30),(10169,42),(10170,54)]),
    ('fort','Power Word: Fortitude',[(1243,1),(1244,12),(1245,24),(2791,36),(10937,48),(10938,60)]),
    ('spirit','Divine Spirit',[(14752,30),(14818,40),(14819,50),(27841,60)]),
    ('sp','Shadow Protection',[(976,30),(10957,42),(10958,56)]),
    ('bom','Blessing of Might',[(19740,4),(19834,12),(19835,22),(19836,32),(19837,42),(19838,52),(25291,60)]),
    ('bow','Blessing of Wisdom',[(19742,14),(19850,24),(19852,34),(19853,44),(19854,54),(25290,60)]),
]

def setup(key, name, ranks):
    code='local B=BuffTap; spells={}; book={}\n'
    for rank,(spell_id,level) in enumerate(ranks,1):
        code+=f'spell({spell_id},{json.dumps(name)},{level}); spells[{spell_id}].rank="Rank {rank}"\n'
    return code+f'B:ScanBook(); local def=B:FindBuff({json.dumps(key)}); '

for key,name,ranks in FAMILIES:
    for index,(spell_id,level) in enumerate(ranks):
        base=setup(key,name,ranks[:index+1])
        minimum=max(1,level-10)
        test(f'Recipient rank {key} {spell_id} accepts exact minimum {minimum}',base+f'''
UnitLevel=function() return {minimum} end
local a=B:Resolve(def,'target'); assert(a and a.id=={spell_id})
assert(a.level=={level},'learning metadata must remain separate')
''')
        lower=minimum-1
        expected=next((sid for sid,lev in reversed(ranks[:index]) if lower>=max(1,lev-10)),None)
        check=f'assert(a and a.id=={expected})' if expected else 'assert(not a)'
        test(f'Recipient rank {key} {spell_id} rejects below minimum {lower}',base+f'''
UnitLevel=function() return {lower} end
local a=B:Resolve(def,'target'); {check}
''')

MAGE=setup('ai','Arcane Intellect',FAMILIES[2][2])
for value in ('nil','{secret=true}','0','-1','0/0'):
    test('Recipient rank unreadable/invalid external level '+value,MAGE+f'''
UnitLevel=function() return {value} end; assert(not B:Resolve(def,'target'))
''')
test('Recipient rank self still uses highest known spell despite hidden level',MAGE+'''
UnitLevel=function() return nil end; assert(B:Resolve(def,'player').id==10157)
''')
test('Recipient rank never infers ownership of lower folded ranks',setup('ai','Arcane Intellect',[(1461,28)])+'''
UnitLevel=function() return 17 end; assert(not B:Resolve(def,'target'))
''')
test('Recipient rank uses client rank record despite adjusted learned-level API',MAGE+'''
for _,s in pairs(spells) do s.level=1 end
B:ScanBook(); UnitLevel=function() return 18 end; assert(B:Resolve(def,'target').id==1461)
''')
test('Recipient rank cache remains recipient-level-specific',MAGE+'''
UnitLevel=function(u) return u=='party1' and 17 or 18 end
assert(B:Resolve(def,'party1').id==1460 and B:Resolve(def,'party2').id==1461)
assert(B:Resolve(def,'party1').id==1460)
''')
test('Recipient rank removal invalidates cache through spellbook event',MAGE+'''
UnitLevel=function() return 18 end; assert(B:Resolve(def,'target').id==1461)
spells[1461].known=false; B.events.scripts.OnEvent(nil,'SPELLS_CHANGED'); advance(.2)
assert(B:Resolve(def,'target').id==1460)
''')
test('Recipient rank missing catalog level receives no allowance',MAGE+'''
B.RankLevel[1461]=nil; UnitLevel=function() return 18 end
assert(B:Resolve(def,'target').id==1460)
''')
test('Recipient rank remapped same-name spell receives no inferred allowance',MAGE+'''
spell(900001,'Arcane Intellect',70); spells[900001].rank='Rank 6'; B:ScanBook()
UnitLevel=function() return 60 end; assert(B:Resolve(def,'target').id==10157)
''')
for key,name,spell_id,level in [
    ('ab','Arcane Brilliance',23028,56),('gotw','Gift of the Wild',21849,50),
    ('pof','Prayer of Fortitude',21562,48),('pos','Prayer of Spirit',27681,60),
    ('posp','Prayer of Shadow Protection',27683,56),('gbom','Greater Blessing of Might',25782,52),
    ('gbow','Greater Blessing of Wisdom',25894,54),('bok','Blessing of Kings',20217,20),
    ('fear-ward','Fear Ward',6346,20),('water-walking','Water Walking',546,28),
    ('unending-breath','Unending Breath',5697,16),('detect-invis','Detect Invisibility',11743,50),
    ('battle-shout','Battle Shout',11551,52),('trueshot','Trueshot Aura',20906,60),
]:
    group = key in ('ab','gotw','pof','pos','posp','gbom','gbow')
    if group:
        test('Group rank permits the ten-level recipient allowance for '+key,setup(key,name,[(spell_id,level)])+f'''
UnitLevel=function() return {level-10} end; assert(B:Resolve(def,'target').id=={spell_id})
B.rankChoiceCache={{}}; UnitLevel=function() return {level-11} end; assert(not B:Resolve(def,'target'))
B.rankChoiceCache={{}}; UnitLevel=function() return nil end
assert(not B:Resolve(def,'target'))
''')
        continue
    test('Recipient rank preserves separate policy for '+key,setup(key,name,[(spell_id,level)])+f'''
UnitLevel=function() return {level-1} end; assert(not B:Resolve(def,'target'))
B.rankChoiceCache={{}}; UnitLevel=function() return {level} end
assert(B:Resolve(def,'target').id=={spell_id})
''')

test('Recipient rank Nearby macro pins newly eligible Thorns rank',NEAR+'''
spell(782,'Thorns',14); spells[782].rank='Rank 2'
BuffTap:ScanBook(); local a=BuffTap:Resolve(BuffTap:FindBuff('thorns'),'nameplate1')
assert(a and a.id==782 and a.rank=='Rank 2')
local text=BuffTap:NearbyMacro(a); assert(text and text:find('Thorns(Rank 2)',1,true))
''')

test('Recipient rank Nearby click clears cast after recipient becomes too low',NEAR+'''
spell(782,'Thorns',14); spells[782].rank='Rank 2'
aura('nameplate1',5232,'Mark of the Wild'); refresh()
assert(BuffTap.action and BuffTap.action.id==782)
UnitLevel=function(u) return u=='nameplate1' and 3 or 60 end
BuffTap.button.scripts.PreClick(nil,'LeftButton',false)
assert(not BuffTap.action and not BuffTap.button.attrs.type1)
''')

print('RECIPIENT_RANK_CASES',len(tests)-start)
