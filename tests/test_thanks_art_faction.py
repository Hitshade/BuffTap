from test_bufftap import test,ROOT
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
CASES=(("Horde","ThanksSceneHorde"),("Alliance","ThanksScene"),("nil","ThanksScene"),("error","ThanksScene"))
for faction,art in CASES:
  fn={"nil":"function() return nil end","error":"function() error('no faction') end"}.get(faction,"function() return '"+faction+"' end")
  test('Solo thanks picture follows faction: '+faction,RECORD+"UnitFactionGroup="+fn+"; BuffTap:Options(); local t=BuffTap.helperWindow.thanksScene.texture; assert(t and t:find([[Media\\"+art+"]],1,true) and (('"+art+"'=='ThanksScene') == not t:find('Horde',1,true)),tostring(t))")
