from test_spell_icons import test, tests
test('Existing fractional opacity displays a percentage without migration', "BuffTap.db.opacity=.65; BuffTap:Options(); assert(BuffTap.options.opacityEdit.text=='65' and BuffTap.db.opacity==.65)")
test('Opacity Enter stores fractional value and preserves secure action', "BuffTap:Options(); local f=BuffTap.options; local id=BuffTap.action.id; f.opacityEdit:SetText('45'); f.opacityEdit.scripts.OnEnterPressed(f.opacityEdit); assert(BuffTap.db.opacity==.45 and f.opacityEdit.text=='45' and BuffTap.action.id==id)")
test('Opacity supports zero and clamps percentages over 100', "BuffTap:Options(); local e=BuffTap.options.opacityEdit; e:SetText('0'); e.scripts.OnEnterPressed(e); assert(BuffTap.db.opacity==0); e:SetText('150'); e.scripts.OnEnterPressed(e); assert(BuffTap.db.opacity==1 and e.text=='100')")
test('Unlearned buff status is explicit and red', "UnitClass=function() return 'Paladin','PALADIN' end; BuffTap:Options(); for _,row in ipairs(BuffTap.options.buffRows) do if row.shown then assert(row.detail.text:find('|cffff6666',1,true) and row.detail.text:find('not learned',1,true)) end end")
print('ALL',len(tests),'SCENARIOS PASSED')
