"""Build original monochrome speaker glyphs for the themed sound buttons."""
from pathlib import Path
from PIL import Image, ImageDraw
OUT=Path(__file__).resolve().parents[1]/'addon/BuffTap/Media'
for muted in (False,True):
 image=Image.new('RGBA',(128,128),(0,0,0,0)); d=ImageDraw.Draw(image)
 d.polygon([(18,48),(40,48),(67,25),(67,103),(40,80),(18,80)],fill='white')
 if muted:
  d.line([(84,46),(113,82)],fill='white',width=9); d.line([(113,46),(84,82)],fill='white',width=9)
 else:
  d.arc((51,34,103,94),-60,60,fill='white',width=7)
  d.arc((46,15,125,113),-55,55,fill='white',width=7)
 image.resize((32,32),Image.Resampling.LANCZOS).save(OUT/('UISpeakerMuted.tga' if muted else 'UISpeaker.tga'))
