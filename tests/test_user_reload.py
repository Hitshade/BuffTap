from test_bufftap import test, tests
test('Saved settings like the developer survive a reload and every options page fills in',"""local B=BuffTap
playerClass='DRUID'
B.db.consumablesEnabled=true; B.db.suppliesEnabled=false; B.db.nearbyEnabled=true
for i=1,14 do B.db.consumableFamilies[B.ElixirFamilies[i].key]=true end
B.db.consumableFamilies.ferocity=true; B.db.supplyCustom={4306,2589,3371}
B.db.supplySettings['custom:4306']={enabled=true,minimum=2,target=8}
B:InitDB(); advance(2.1); refresh()
assert(B.db.enabled==true and B.db.nearbyEnabled==true)
B:Options(); local f=B.options
for i=1,#f.pages do if f.selectTab then f.selectTab(i) end; B:Options() end
assert(f.enable:GetChecked()==true,'enable switch filled in')
for _,v in ipairs({'buff','camp','supply','nearby','binding','interface'}) do B:SetAppearanceView(v); B:Options() end
f.selectConsumableView(true); B:Options(); B:UpdateSupplyOptions()
assert(f.supplyRows[1].entry and f.supplyRows[1].entry.kind=='custom')""")
