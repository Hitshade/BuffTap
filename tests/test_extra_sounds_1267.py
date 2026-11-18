"""Additional bundled sounds: real picker/playback integration and encoded assets."""
from test_bufftap import test, ROOT
import json,hashlib,struct
report=json.loads((ROOT/'research/extra-sounds-1267.json').read_text(encoding='utf-8'))
for file,record in report['new'].items():
 data=(ROOT/'addon/BuffTap/Media/Sounds'/file).read_bytes()
 assert data.startswith(b'OggS')
 packet=data.index(b'\x01vorbis'); assert data[packet+11]==1 and struct.unpack('<I',data[packet+12:packet+16])[0]==44100
 assert hashlib.sha256(data).hexdigest()==record['sha256']
 assert .7<=record['duration']<=1 and record['peak_db']<=-6 and abs(record['lufs']-report['target_lufs'])<.1
 key=record['key']
 test('New bundled sound '+key+' is selectable normalized and previewed',"local B=BuffTap; local n=0; for _,s in ipairs(B:SoundChoices()) do if s.key=='"+key+"' then n=n+1; assert(s.name=='"+record['name']+"') end end; assert(n==1); B.db.reminderSound='"+key+"'; B:NormalizeAlerts(); assert(B.db.reminderSound=='"+key+"'); local path; PlaySoundFile=function(f) path=f; return true end; assert(B:PlayAlert('reminder',true)); assert(path:find('"+file+"',1,true))")
for file,record in report['reference'].items():
 assert hashlib.sha256((ROOT/'addon/BuffTap/Media/Sounds'/file).read_bytes()).hexdigest()==record['sha256'],file

test('Five new sounds do not replace existing saved category choices',"local B=BuffTap; B.db.reminderSound='playful'; B.db.supplySound='twinbells'; B.db.campAlertSound='harp'; B.db.cleanseSound='bell'; B:NormalizeAlerts(); assert(B.db.reminderSound=='playful' and B.db.supplySound=='twinbells' and B.db.campAlertSound=='harp' and B.db.cleanseSound=='bell')")
test('Thirteen bundled sounds register without duplicate SharedMedia choices',"local B=BuffTap; local media={}; local count=0; LibStub=function() return {Register=function(_,kind,name,file) count=count+1; media[name]=file end,HashTable=function() return media end} end; B.sharedSoundsRegistered=nil; B:RegisterSharedSounds(); assert(count==13); local n=0; for _,v in ipairs(B:SoundChoices()) do if v.key=='silver' or v.key=='lsm:BuffTap: Silver notes' then n=n+1 end end; assert(n==1 and count==13)")
test('New sound preview works muted and does not arm or alter action',"local B=BuffTap; local a=B.action; B.db.sound=false; B.db.reminderSound='ripple'; local count=0; PlaySoundFile=function() count=count+1; return true end; assert(B:PlayAlert('reminder',true) and count==1 and B.action==a and B.db.reminderSound=='ripple'); assert(not B:PlayAlert('reminder') and count==1)")
