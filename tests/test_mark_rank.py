from test_bufftap import test
setup="spell(6756,'Mark of the Wild',20); BuffTap.bookDirty=true; refresh(); local def=BuffTap:FindBuff('motw'); "
test('Rank3 Mark applies at target level10 boundary',setup+"UnitLevel=function() return 10 end; BuffTap.rankChoiceCache={}; assert(BuffTap:Resolve(def,'target').id==6756)")
test('Rank3 Mark is not offered below target level10',setup+"UnitLevel=function() return 9 end; BuffTap.rankChoiceCache={}; assert(BuffTap:Resolve(def,'target').id==5232)")
test('Rank3 Mark stays highest for level22 party and self',setup+"UnitLevel=function() return 22 end; BuffTap.rankChoiceCache={}; assert(BuffTap:Resolve(def,'party1').id==6756 and BuffTap:Resolve(def,'player').id==6756)")
test('Unknown recipient level still rejects rank choice',setup+"UnitLevel=function() return nil end; BuffTap.rankChoiceCache={}; assert(not BuffTap:Resolve(def,'target'))")
test('Mark missing group version names Gift explicitly',setup+"BuffTap:Options(); local text=BuffTap.options.buffRows[1].detail.text; assert(text:find('Gift of the Wild') and text:find('not learned') and not text:find('group spell'))")
