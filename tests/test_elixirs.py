from test_bufftap import test, tests
test('Ticked elixirs each get a reminder; a line-mate covers its line',"""local B=BuffTap
stock(13452,17538); stock(250350,1250985); stock(9187,11334); consumables('ferocity')
B.db.consumableFamilies['elixir:13452']=true; B.db.consumableFamilies['elixir:250350']=true
refresh(); assert(B.action and (B.action.itemID==13452 or B.action.itemID==250350),'first elixir offered')
aura('player',17538,'Elixir of the Mongoose',1700,1800); B:InvalidateConsumables(); refresh()
assert(B.action and B.action.itemID==250350,'second elixir offered while first is up')
aura('player',1250985,'Elixir of Ferocity',1700,1800); B:InvalidateConsumables(); refresh(); assert(not B.action,'all up '..tostring(B.action and (B.action.itemID or B.action.name)))""")
test('Greater Agility counts for a ticked Mongoose',"""local B=BuffTap
stock(13452,17538); consumables('ferocity'); B.db.consumableFamilies['elixir:13452']=true
aura('player',11334,'Greater Agility',1700,1800); refresh(); assert(not B.action,tostring(B.action and (B.action.itemID or B.action.name)))""")
test('Old single choice still works until something is ticked',"""local B=BuffTap
stock(250350,1250985); consumables('ferocity'); refresh(); assert(B.action and B.action.itemID==250350)
assert(B:ElixirTicked(B:ElixirFamilyFor(250350)))""")
test('Ticking an elixir unticks its line-mates',"""local B=BuffTap; consumables('ferocity')
B:ToggleElixir(13452); B:ToggleElixir(9187)
assert(B:ElixirTicked(B:ElixirFamilyFor(9187)) and not B:ElixirTicked(B:ElixirFamilyFor(13452)))
assert(B:ElixirLineTicked(B:ElixirFamilyFor(13452))~=nil)
B:ToggleElixir(250350); assert(B:ElixirTicked(B:ElixirFamilyFor(250350)) and B:ElixirTicked(B:ElixirFamilyFor(9187)))""")
test('Elixir icons and a scrolling supply list',"""local B=BuffTap; B.db.suppliesEnabled=true
for _,id in ipairs({13452,250350,13454,9264,250335,250341,20004}) do stock(id,1); B.db.consumableFamilies['elixir:'..id]=true end
consumables('ferocity'); B.db.consumableFamilies.food=true; B.db.consumableFamilies.flask=true
B:Options()
local f=B.options; local row
for _,r in ipairs(f.consumableRows) do if r.family.key=='ferocity' then row=r end end
local shown=0; for _,b in ipairs(row.strip) do if b:IsShown() then shown=shown+1 end end; assert(shown==7,'icons '..shown)
local bt=B.itemPicker; B.db.pickerBagsOnly=false; B:ChooseConsumable(row.family,row.prev); assert(not B.itemPicker.bags:GetChecked(),'bags filter remembered')
B:UpdateSupplyOptions(); assert(f.supplyMaxOffset>0,'scrolls '..tostring(f.supplyMaxOffset))
f.supplyOffset=1; B:UpdateSupplyOptions(); assert(f.supplyRows[1].entry and f.supplyRows[1].entry.key~=nil)""")
test('Utility is a checklist; Firewaters share a line',"""local B=BuffTap
stock(12217,15852); stock(9088,11371); consumables('utility')
B:ToggleElixir(12217); B:ToggleElixir(9088)
refresh(); assert(B.action and (B.action.itemID==12217 or B.action.itemID==9088))
aura('player',15852,'Dragonbreath Chili',500,600); B:InvalidateConsumables(); refresh(); assert(B.action and B.action.itemID==9088,'second utility')
B:ToggleElixir(246948); B:ToggleElixir(12820); assert(not B:ElixirTicked(B:ElixirFamilyFor(246948)))""")
test('Custom supply items are tracked and removable',"""local B=BuffTap; B.db.suppliesEnabled=true; B:InitSupplies()
stock(2589,1); assert(B:AddSupplyItem('2589')); assert(not B:AddSupplyItem('2589'))
advance(2.1); B:InvalidateSupplies(true); local found
for _,e in ipairs(B:SyncSupplies()) do if e.key=='custom:2589' then found=e end end
assert(found and found.kind=='custom' and found.count>0,'tracked '..tostring(found and found.count))
B:RemoveSupplyItem(2589); B:InvalidateSupplies(true); for _,e in ipairs(B:SyncSupplies()) do assert(e.key~='custom:2589') end""")
test('Dropping an item on the supply list tracks it',"""local B=BuffTap; B.db.suppliesEnabled=true; B:InitSupplies(); B:Options()
GetCursorInfo=function() return 'item',2589 end; ClearCursor=function() end
B.options.supplyList:GetScript('OnReceiveDrag')(B.options.supplyList)
local found=false; for _,id in ipairs(B.db.supplyCustom) do if id==2589 then found=true end end; assert(found,'n='..#B.db.supplyCustom..' cur='..tostring(GetCursorInfo())..' combat='..tostring(InCombatLockdown and InCombatLockdown()))""")
test('Tracked items show even with supply warnings off',"""local B=BuffTap; B.db.suppliesEnabled=false; B.db.supplyCustom={2589}; stock(2589,1); B:Options()
B:UpdateSupplyOptions(); assert(B.options.supplyRows[1]:IsShown() and B.options.supplyRows[1].entry.key=='custom:2589')
assert(B.options.supplyRows[1].remove:IsShown())""")
test('Supplies reminder: resting only by default, anywhere when asked, preview on its tab',"""local B=BuffTap; B.db.suppliesEnabled=true; B.db.supplyCustom={2589}; stock(2589,1)
B.db.supplySettings['custom:2589']={enabled=true,minimum=10,target=12}
B:InitSupplies(); advance(2.1); B:InvalidateSupplies(true); B:SyncSupplies()
assert(#B.supplyWarnings>0,'warning')
IsResting=function() return false end; B:UpdateSupplyBadge(); assert(not (B.supplyBadge and B.supplyBadge:IsShown()),'hidden out in the world')
IsResting=function() return true end; B:UpdateSupplyBadge(); assert(B.supplyBadge and B.supplyBadge:IsShown(),'shown while resting')
assert(B.supplyBadge.time:GetText():find('/ 12'),'count label '..tostring(B.supplyBadge.time:GetText()))
IsResting=function() return false end; B.db.supplyAnywhere=true; B:UpdateSupplyBadge(); assert(B.supplyBadge:IsShown(),'anywhere')
B.db.supplyReminder=false; B:UpdateSupplyBadge(); assert(not B.supplyBadge:IsShown(),'switched off')
B:Options(); assert(B.options.appearancePanes.supply and B.options.supplyShowIcon and B.options.supplyTextFont and B.optionsPreviews.supply,'customize tab and preview')
B:SetAppearanceView('supply'); B:Options()""")
test('Choose window uses the orange check box and Clear all empties the list',"""local B=BuffTap; consumables('ferocity'); B:Options()
local fam=B:ConsumableFamily('ferocity'); B:ChooseConsumable(fam,B.options); local f=B.itemPicker; B.db.pickerBagsOnly=false; f.bags:SetChecked(false); B:UpdateConsumablePicker()
local row=f.rows[1]; local was=row.tick:GetChecked(); row.tick:GetScript('OnClick')(row.tick); B:UpdateConsumablePicker()
assert(f.rows[1].tick:GetChecked()~=was,'tick toggles')
f.clear:GetScript('OnClick')(f.clear); for _,c in ipairs(B.ElixirFamilies) do assert(not B:ElixirTicked(c)) end""")
test('Supplies look settings are its own',"""local B=BuffTap; B:NormalizeSupplyReminder(); B:VisualSetting('supplyEffectStyle','pulse'); B:VisualSetting('supplyIconStyle','modern')
assert(B.db.supplyEffectStyle=='pulse' and B.db.supplyIconStyle=='modern' and B.db.effectStyle~='pulse')""")
test('Clicking the chosen food again unticks it; ticked elixirs untick too',"""local B=BuffTap; stock(6888,1248377); B:Options()
local fam=B:ConsumableFamily('food'); B:ChooseConsumable(fam,B.options); local f=B.itemPicker
local row=f.rows[1]; row.tick:GetScript('OnClick')(row.tick); assert(B:ConsumableChoiceID(fam)==row.itemID,'chosen')
f.rows[1].tick:GetScript('OnClick')(f.rows[1].tick); assert(B:ConsumableChoiceID(fam)==nil,'unticked back to Auto')
assert(not f.rows[1].tick:GetChecked())
local el=B:ConsumableFamily('ferocity'); B:ChooseConsumable(el,B.options); f.bags:SetChecked(false); B:UpdateConsumablePicker()
local r=f.rows[1]; r.tick:GetScript('OnClick')(r.tick); B:UpdateConsumablePicker(); local on=f.rows[1].tick:GetChecked()
f.rows[1].tick:GetScript('OnClick')(f.rows[1].tick); B:UpdateConsumablePicker(); assert(f.rows[1].tick:GetChecked()~=on,'elixir toggles both ways')""")
test('Supplies preview shows the supplies sample, not the buff reminder',"""local B=BuffTap; B:Options(); local f=B.options
if f.selectTab then f.selectTab(8) end; f.activeTab=8; B:SetAppearanceView('supply'); B:UpdateOptionsPreviews()
local p=B.optionsPreviews.supply.icon; assert(tostring(p.icon.texture):find('INV_Crate_01'),'crate with nothing tracked '..tostring(p.icon.texture))
assert(not p.nameLabel:IsShown())
B.db.supplyCustom={4306}; stock(4306,1); B:UpdateOptionsPreviews(); assert(tostring(p.time.text):find('Item 4306') or tostring(p.time.text):find('4306') or not tostring(p.icon.texture):find('INV_Crate_01'),'uses a tracked item')
assert(tostring(f.supplyEffect.text):find('Soft'),'effect selector label '..tostring(f.supplyEffect.text))""")
