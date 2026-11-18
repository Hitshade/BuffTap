"""Additional bundled sounds: real picker/playback integration and encoded assets."""
from test_bufftap import test, ROOT
import json,hashlib,struct
report=json.loads((ROOT/'research/owner-sounds-1267.json').read_text(encoding='utf-8'))
for file,record in report['new'].items():
 data=(ROOT/'addon/BuffTap/Media/Sounds'/file).read_bytes()
 assert data.startswith(b'OggS')
 packet=data.index(b'\x01vorbis'); assert data[packet+11]==record['channels']==2 and struct.unpack('<I',data[packet+12:packet+16])[0]==44100
 assert hashlib.sha256(data).hexdigest()==record['sha256']
 assert .7<=record['duration']<=1 and record['peak_db']<=-6 and abs(record['lufs']-report['target_lufs'])<.1
 key=record['key']
 test('New bundled sound '+key+' is selectable normalized and previewed',"local B=BuffTap; local n=0; for _,s in ipairs(B:SoundChoices()) do if s.key=='"+key+"' then n=n+1; assert(s.name=='"+record['name']+"') end end; assert(n==1); B.db.reminderSound='"+key+"'; B:NormalizeAlerts(); assert(B.db.reminderSound=='"+key+"'); local path; PlaySoundFile=function(f) path=f; return true end; assert(B:PlayAlert('reminder',true)); assert(path:find('"+file+"',1,true))")
for file,record in report['reference'].items():
 assert hashlib.sha256((ROOT/'addon/BuffTap/Media/Sounds'/file).read_bytes()).hexdigest()==record['sha256'],file

test('Owner sounds do not replace existing saved category choices',"local B=BuffTap; B.db.reminderSound='playful'; B.db.supplySound='twinbells'; B.db.campAlertSound='harp'; B.db.cleanseSound='bell'; B:NormalizeAlerts(); assert(B.db.reminderSound=='playful' and B.db.supplySound=='twinbells' and B.db.campAlertSound=='harp' and B.db.cleanseSound=='bell')")
test('Eighteen bundled sounds register without duplicate SharedMedia choices',"local B=BuffTap; local media={}; local count=0; LibStub=function() return {Register=function(_,kind,name,file) count=count+1; media[name]=file end,HashTable=function() return media end} end; B.sharedSoundsRegistered=nil; B:RegisterSharedSounds(); assert(count==18); local n=0; for _,v in ipairs(B:SoundChoices()) do if v.key=='moonlitbells' or v.key=='lsm:BuffTap: Moonlit bells' then n=n+1 end end; assert(n==1 and count==18)")
test('New sound preview works muted and does not arm or alter action',"local B=BuffTap; local a=B.action; B.db.sound=false; B.db.reminderSound='holylight'; local count=0; PlaySoundFile=function() count=count+1; return true end; assert(B:PlayAlert('reminder',true) and count==1 and B.action==a and B.db.reminderSound=='holylight'); assert(not B:PlayAlert('reminder') and count==1)")

for old,new in [('softpluck','gentleharp'),('amber','crystalchime'),('ripple','holylight'),('wood','elvenharp'),('silver','moonlitbells')]:
 test('Rejected beta choice migrates '+old,'local B=BuffTap; B.db.reminderSound="'+old+'"; B.db.buffAlerts.personal.motw={enabled=false,sound="'+old+'"}; B:NormalizeAlerts(); assert(B.db.reminderSound=="'+new+'" and B.db.buffAlerts.personal.motw.sound=="'+new+'" and not B:BuffAlertEnabled("personal","motw")); for _,s in ipairs(B:SoundChoices()) do assert(s.key~="'+old+'") end')
