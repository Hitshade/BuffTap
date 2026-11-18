"""Original short additive-synthesis alerts (MPL-2.0).
Requires numpy and soundfile. Creates only the five named additions; existing
recordings are read-only references. K-weighted 400ms gated loudness is measured
at 48kHz, mono, with BS.1770 filter coefficients and 100ms hop.
"""
from pathlib import Path
import argparse, hashlib, json, math
import numpy as np
import soundfile as sf
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'addon/BuffTap/Media/Sounds'
NEW=[('softpluck','Soft pluck','BuffTapSoftPluck.ogg',.76,'pluck',[(0,523.251,1),(.16,783.991,.72)]),
 ('amber','Amber chime','BuffTapAmber.ogg',.90,'bell',[(0,659.255,.85),(.14,987.767,.48)]),
 ('ripple','Gentle ripple','BuffTapRipple.ogg',.84,'ripple',[(0,391.995,.85),(.11,493.883,.75),(.22,587.330,.65)]),
 ('wood','Wooden bloom','BuffTapWood.ogg',.78,'wood',[(0,523.251,1),(.095,659.255,.65),(.19,783.991,.48)]),
 ('silver','Silver notes','BuffTapSilver.ogg',.88,'silver',[(0,587.330,.9),(.155,880,.62)])]
REFERENCE=['BuffTapBell.ogg','BuffTapCleanse.ogg','BuffTapGlass.ogg','BuffTapHarp.ogg','BuffTapHello.ogg','BuffTapMarimba.ogg','BuffTapPlayful.ogg','BuffTapTwinBells.ogg']
def biquad(x,b,a):
 y=np.empty_like(x); x1=x2=y1=y2=0.
 for i,v in enumerate(x):
  y0=b[0]*v+b[1]*x1+b[2]*x2-a[1]*y1-a[2]*y2
  y[i]=y0; x2=x1; x1=v; y2=y1; y1=y0
 return y

def loudness(y,sr):
 if y.ndim>1:y=y.mean(axis=1)
 if sr!=48000:y=np.interp(np.arange(round(len(y)*48000/sr))/48000,np.arange(len(y))/sr,y)
 y=biquad(y,[1.53512485958697,-2.69169618940638,1.19839281085285],[1,-1.69065929318241,.73248077421585])
 y=biquad(y,[1,-2,1],[1,-1.99004745483398,.99007225036621])
 if len(y)<19200:y=np.pad(y,(0,19200-len(y)))
 energies=np.array([np.mean(y[i:i+19200]**2) for i in range(0,len(y)-19200+1,4800)])
 levels=-.691+10*np.log10(np.maximum(energies,1e-15))
 energies=energies[levels>-70]
 preliminary=-.691+10*np.log10(np.mean(energies))
 energies=energies[(-.691+10*np.log10(energies))>preliminary-10]
 return float(-.691+10*np.log10(np.mean(energies)))

def metrics(p):
 y,sr=sf.read(p,always_2d=True)
 return {'rate':sr,'channels':y.shape[1],'duration':len(y)/sr,'lufs':loudness(y,sr),'peak_db':float(20*np.log10(np.max(np.abs(y)))),'rms_db':float(20*np.log10(np.sqrt(np.mean(y*y)))),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}

def synth(duration,kind,notes,sr=44100):
 t=np.arange(round(duration*sr))/sr; y=np.zeros_like(t)
 profiles={'pluck':[(1,1,.15),(2,.22,.08),(3,.065,.05)],'bell':[(1,1,.22),(2.01,.22,.13),(3.98,.035,.07)],'ripple':[(1,1,.17),(2,.12,.10),(3,.035,.06)],'wood':[(1,1,.12),(2.76,.14,.035),(5.4,.022,.02)],'silver':[(1,1,.23),(2,.18,.12),(3,.035,.065)]}
 for onset,freq,amp in notes:
  u=np.maximum(0,t-onset); attack=(1-np.exp(-u/.005))**2
  for ratio,gain,decay in profiles[kind]:
   y+=amp*gain*attack*np.exp(-u/decay)*np.sin(2*np.pi*freq*ratio*u)*(t>=onset)
 # Restrained close reflection adds softness without a long reverb tail.
 delay=round(.029*sr); y[delay:]+=.055*y[:-delay].copy()
 fade=round(.03*sr); y[-fade:]*=np.linspace(1,0,fade)**2
 return y

def build(report):
 refs={name:metrics(OUT/name) for name in REFERENCE}; target=float(np.median([v['lufs'] for v in refs.values()]))
 generated={}
 for key,name,file,duration,kind,notes in NEW:
  y=synth(duration,kind,notes); y*=10**((target-loudness(y,44100))/20)
  # Keep generous peak headroom. Soft-limit only if this particular transient
  # would exceed the existing set's loudest decoded peak.
  peak_limit=10**(-6.8/20)
  if np.max(np.abs(y))>peak_limit:
   y=peak_limit*np.tanh(y/peak_limit); y*=10**((target-loudness(y,44100))/20)
  path=OUT/file;sf.write(path,y,44100,format='OGG',subtype='VORBIS')
  # Check the decoded delivery file rather than just the synthesis buffer.
  m=metrics(path);assert abs(m['lufs']-target)<.75,(file,m,target)
  assert m['peak_db']<=-6,(file,m)
  assert m['channels']==1 and .7<=m['duration']<=1
  generated[file]={'key':key,'name':name,**m}
 for file,m in refs.items():assert hashlib.sha256((OUT/file).read_bytes()).hexdigest()==m['sha256']
 data={'method':'Original additive synthesis; mono Ogg Vorbis, 44.1kHz. Matched to median gated K-weighted loudness of eight existing recordings. No subjective listening claimed.','target_lufs':target,'reference':refs,'new':generated}
 report.write_text(json.dumps(data,indent=2),encoding='utf-8');print(json.dumps({'target_lufs':target,'new':generated},indent=2))
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--report',type=Path,default=ROOT/'research/extra-sounds-1267.json');build(parser.parse_args().report)
