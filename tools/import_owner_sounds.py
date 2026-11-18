"""Gain-match owner-supplied Oggs; originals and eight shipped sounds stay untouched.
Build-only dependencies: numpy, soundfile. Stereo loudness sums K-weighted channel
energy (BS.1770 front-channel weights), never averages/downmixes the channels.
"""
from pathlib import Path
import argparse,sys,importlib.util,json,hashlib
import numpy as np
import soundfile as sf
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'addon/BuffTap/Media/Sounds'
spec=importlib.util.spec_from_file_location('meter',ROOT/'tools/build_extra_sounds.py');meter=importlib.util.module_from_spec(spec);spec.loader.exec_module(meter)
FILES=[('01_crystal_chime.ogg','crystalchime','Crystal chime','BuffTapCrystalChime.ogg'),('03_elven_harp.ogg','elvenharp','Elven harp','BuffTapElvenHarp.ogg'),('04_holy_light.ogg','holylight','Holy light','BuffTapHolyLight.ogg'),('05_fairy_ping.ogg','fairyping','Fairy ping','BuffTapFairyPing.ogg'),('08_celestial_lift.ogg','celestiallift','Celestial lift','BuffTapCelestialLift.ogg'),('11_soft_glow.ogg','softglow','Soft glow','BuffTapSoftGlow.ogg'),('12_moonlit_bells.ogg','moonlitbells','Moonlit bells','BuffTapMoonlitBells.ogg'),('13_gentle_harp.ogg','gentleharp','Gentle harp','BuffTapGentleHarp.ogg'),('14_warm_welcome.ogg','warmwelcome','Warm welcome','BuffTapWarmWelcome.ogg'),('15_lullaby_ping.ogg','lullabyping','Lullaby ping','BuffTapLullabyPing.ogg')]
def loudness(y,sr):
 if y.ndim==1:y=y[:,None]
 energy=None
 for channel in y.T:
  if sr!=48000:channel=np.interp(np.arange(round(len(channel)*48000/sr))/48000,np.arange(len(channel))/sr,channel)
  z=meter.biquad(channel,[1.53512485958697,-2.69169618940638,1.19839281085285],[1,-1.69065929318241,.73248077421585])
  z=meter.biquad(z,[1,-2,1],[1,-1.99004745483398,.99007225036621])
  if len(z)<19200:z=np.pad(z,(0,19200-len(z)))
  e=np.array([np.mean(z[i:i+19200]**2) for i in range(0,len(z)-19200+1,4800)])
  energy=e if energy is None else energy+e
 energy=energy[(-.691+10*np.log10(np.maximum(energy,1e-15)))>-70]
 preliminary=-.691+10*np.log10(np.mean(energy));energy=energy[(-.691+10*np.log10(energy))>preliminary-10]
 return float(-.691+10*np.log10(np.mean(energy)))
def metrics(path):
 y,sr=sf.read(path,always_2d=True)
 return {'rate':sr,'channels':y.shape[1],'duration':len(y)/sr,'lufs':loudness(y,sr),'peak_db':float(20*np.log10(np.max(np.abs(y)))),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
def main(source,report):
 refs={f:metrics(OUT/f) for f in meter.REFERENCE};target=float(np.median([r['lufs'] for r in refs.values()]));new={}
 for src,key,name,dst in FILES:
  original=source/src;before=metrics(original);y,sr=sf.read(original,always_2d=True)
  gain=target-before['lufs'];path=OUT/dst
  for _ in range(3):
   sf.write(path,y*10**(gain/20),sr,format='OGG',subtype='VORBIS');after=metrics(path)
   if abs(after['lufs']-target)<.1:break
   gain+=target-after['lufs']
  assert abs(after['lufs']-target)<.1 and after['peak_db']<=-6,(dst,after)
  assert after['channels']==before['channels'] and after['rate']==before['rate'] and after['duration']==before['duration']
  assert hashlib.sha256(original.read_bytes()).hexdigest()==before['sha256']
  new[dst]={'key':key,'name':name,'sourceFile':src,'source':before,'gain_db':gain,**after}
 for file,record in refs.items():assert hashlib.sha256((OUT/file).read_bytes()).hexdigest()==record['sha256']
 data={'target_lufs':target,'method':'Gain only, decoded-file gated K-weighted energy; mono/stereo channel energies summed, stereo preserved. No trimming, fades, synthesis, limiting or compression. Ogg Vorbis copies re-encoded for gain adjustment.','ownerOriginalsUnchanged':True,'reference':refs,'new':new}
 report.write_text(json.dumps(data,indent=2),encoding='utf-8');print(json.dumps({'target_lufs':target,'clips':[{'name':r['name'],'source_lufs':r['source']['lufs'],'gain_db':r['gain_db'],'lufs':r['lufs'],'peak_db':r['peak_db']} for r in new.values()]},indent=2))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--report',type=Path,default=ROOT/'research/owner-sounds-1267.json');args=p.parse_args();main(args.source,args.report)
