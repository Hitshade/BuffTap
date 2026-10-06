from pathlib import Path
import csv,json,hashlib,sys
r=Path(__file__).resolve().parents[1]
a=r/'addon/BuffTap'
data=Path(sys.argv[1]) if len(sys.argv)>1 else r/'research/review-0.8.1'
out=r/'research/weapon-consumables-1.7.0'; out.mkdir(exist_ok=True)
read=lambda n:list(csv.DictReader((data/(n+'.csv')).open(encoding='utf-8-sig')))
effects={x['ID']:x for x in read('ItemEffect')};links=read('ItemXItemEffect');fx=read('SpellEffect');restr={x['SpellID']:x for x in read('SpellEquippedItems')}
groups=[('minor-wizard-oil','Minor Wizard Oil',[20744]),('lesser-wizard-oil','Lesser Wizard Oil',[20746]),('wizard-oil','Wizard Oil',[20750]),('brilliant-wizard-oil','Brilliant Wizard Oil',[20749]),('minor-mana-oil','Minor Mana Oil',[20745]),('lesser-mana-oil','Lesser Mana Oil',[20747]),('brilliant-mana-oil','Brilliant Mana Oil',[20748]),('sharpening-stone','Sharpening Stone',[12404,7964,2871,2863,2862]),('weightstone','Weightstone',[12643,7965,3241,3240,3239]),('elemental-sharpening-stone','Elemental Sharpening Stone',[18262]),('shadow-oil','Shadow Oil',[3824]),('frost-oil','Frost Oil',[3829])]
choices=[]
for key,name,items in groups:
 c={'key':key,'name':name,'class':'ALL','items':[],'enchants':[],'ranks':[],'uses':items[0] in range(20744,20751)}
 for item in items:
  ls=[x for x in links if x['ItemID']==str(item)];assert len(ls)==1
  spell=effects[ls[0]['ItemEffectID']]['SpellID'];ef=[x for x in fx if x['SpellID']==spell and x['Effect']=='54'];assert len(ef)==1
  re=restr[spell];c['items'].append([item,int(spell)]);c['ranks'].append(int(spell));c['enchants'].append(int(ef[0]['EffectMiscValue_0']))
  mask=int(re['EquippedItemSubclass']);inv=int(re['EquippedItemInvTypes']);assert c.get('subclasses',mask)==mask and c.get('invTypes',inv)==inv;c['subclasses']=mask;c['invTypes']=inv
 choices.append(c)
def lua(x):
 if isinstance(x,bool):return 'true' if x else 'false'
 if isinstance(x,str):return json.dumps(x,ensure_ascii=False)
 if isinstance(x,list):return '{'+','.join(lua(v) for v in x)+'}'
 if isinstance(x,dict):return '{'+','.join(k+'='+lua(v) for k,v in x.items())+'}'
 return str(x)
(a/'CoatingData.lua').write_text('-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.\n-- See LICENSE-MPL-2.0.txt. Generated from Forever 1.60.1.70009 DB2 exports.\nlocal _,B=...\nB.CoatingChoices='+lua(choices)+'\n',encoding='utf-8')
(out/'catalog-evidence.json').write_text(json.dumps({'build':'1.60.1.70009','tables':{n:hashlib.sha256((data/(n+'.csv')).read_bytes()).hexdigest() for n in ['ItemEffect','ItemXItemEffect','SpellEffect','SpellEquippedItems']},'choices':choices,'newestExportAttempt':'1.60.1.70205: HTTP 403; retained verified local export. Runtime item-effect and equipment checks required.'},indent=2),encoding='utf-8')
