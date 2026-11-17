from test_bufftap import test

BASE="""local B=BuffTap
UnitInVehicle=function() return false end
local function manual(key)
 B.db.consumablesEnabled=true; B.db.consumableFamilies[key]=true; B.db.consumableModes[key]='manual'
 return B:ConsumableFamily(key)
end
local function put(f,i)
 local item=f.items[i or 1]; stock(item.id,item.useSpell); return item
end
local function icon(key)
 for _,b in ipairs(B.manualConsumableButtons or {}) do if b.entry and b.entry.family.key==key then return b end end
end
"""

test('Modern glow switches shape immediately and Classic restores its original texture', """
local B=BuffTap; local b=B.button
B:ApplyIconStyle(b,b.icon,'modern'); B:ApplyIconEffect(b,true,{effectStyle='pulse'})
assert(b.glow.texture=='Interface\\\\AddOns\\\\BuffTap\\\\Media\\\\ModernRoundedInnerGlow' and b.glow.shown)
local key=b.buffTapEffectKey
B:ApplyIconStyle(b,b.icon,'classic'); B:ApplyIconEffect(b,true,{effectStyle='pulse'})
assert(b.glow.texture=='Interface\\\\Buttons\\\\CheckButtonHilight-Square' and b.glow.shown and b.buffTapEffectKey~=key)
""")

test('Manual modes default to legacy Auto without inventory work',
     "local B=BuffTap; assert(B:ConsumableMode(B:ConsumableFamily('food'))=='auto'); assert(not B.manualConsumableButtons and countCalls==0)")

test('Five Manual effects never displace a normal class buff or binding', BASE+"""
put(manual('food')); put(manual('flask')); local e=manual('ferocity'); put(e); stock(13452,17538)
B.db.consumableFamilies['elixir:250350']=true; B.db.consumableFamilies['elixir:13452']=true
local u=manual('utility'); local item=put(u); B.db.consumableFamilies['utility:'..item.id]=true
B:InvalidateConsumables(); refresh(); assert(B.action and B.action.id==5232)
assert(B.manualConsumableEntries,'no projection: '..tostring(B.lastError)..' vehicle '..tostring(UnitInVehicle and UnitInVehicle('player')))
assert(#B.manualConsumableEntries==5 and bindings.MOUSEWHEELDOWN=='BuffTapActionButton:LeftButton')
for _,b in ipairs(B.manualConsumableButtons) do if b.action then assert(b.action.manualConsumable and b.attrs.unit=='player' and b.attrs.type1=='item') end end
""")

test('Manual strip survives an idle or hidden main reminder without a wheel binding', BASE+"""
local f=manual('food'); local item=put(f); consumables('food'); B.db.showReminder=false
refresh(); assert(not B.action and not B.button.shown and not next(bindings))
local b=assert(icon('food')); assert(b.shown and b.action and b.parent~=B.button)
""")

for count in (12,3,1,0):
 test('Manual stock overlay reflects known count '+str(count), BASE+f"""
local f=manual('food'); local item=put(f); bags[item.id]={count}; refresh()
local b=assert(icon('food')); assert(b.count.text=='{count}'); assert((b.attrs.type1=='item')==({count}>0))
""")

test('Unknown stock is not a red zero and cannot arm', BASE+"""
local f=manual('food'); local item=put(f); local old=C_Item.GetItemCount
C_Item.GetItemCount=function(id,...) if id==item.id then return nil end return old(id,...) end
B:InvalidateConsumables(); refresh(); local b=assert(icon('food')); assert(b.count.text=='?' and not b.action and not b.attrs.type1)
""")

test('Unreadable auras show uncertainty without a clickable missing assertion', BASE+"""
put(manual('food')); B.GetAuras=function() return nil,'unreadable' end; refresh()
local b=assert(icon('food')); assert(b.count.text=='?' and b.entry.unknown and not b.attrs.type1)
""")

test('Click-only item uses exact stored payload and settles once', BASE+"""
local item=put(manual('food')); refresh(); local b=assert(icon('food')); local exact=b.action.itemID
b.scripts.PreClick(b,'LeftButton',false); assert(b.attrs.item=='item:'..exact and B.itemAttempts[exact])
bags[exact]=bags[exact]-1; b.scripts.PostClick(b,'LeftButton',false)
assert(not b.attrs.type1 and B.consumablePending.food>now); refresh(); assert(not icon('food').attrs.type1)
assert(not (B.action and B.action.source=='consumable'))
""")

test('Item disappearing before click never substitutes another supported food', BASE+"""
local f=manual('food'); local first=put(f); local second=put(f,2); refresh(); local b=assert(icon('food')); local id=b.action.itemID
bags[id]=0; b.scripts.PreClick(b,'LeftButton',false); assert(not b.attrs.type1 and not B.itemAttempt)
assert(bags[second.id]==5); refresh(); assert(icon('food').action.itemID==second.id)
""")

test('Wrong-button and down phases do not start item attempts', BASE+"""
put(manual('flask')); refresh(); local b=assert(icon('flask'))
b.scripts.PreClick(b,'RightButton',false); b.scripts.PostClick(b,'RightButton',false); assert(not B.itemAttempt)
b.scripts.PreClick(b,'LeftButton',true); b.scripts.PostClick(b,'LeftButton',true); assert(not B.itemAttempt)
""")

test('Separate elixir effects produce separate icons and shared lines deduplicate', BASE+"""
manual('ferocity'); stock(13452,17538); stock(9187,11334); stock(250350,1250985)
for _,id in ipairs({13452,9187,250350}) do B.db.consumableFamilies['elixir:'..id]=true end
refresh(); assert(#B.manualConsumableEntries==2)
aura('player',17538,'Mongoose'); refresh(); assert(#B.manualConsumableEntries==1 and B.manualConsumableEntries[1].item.id==250350)
""")

test('Auto Manual toggles synchronously revoke old payloads', BASE+"""
stock(13510,17626); consumables('flask'); refresh(); assert(B.button.attrs.item)
B:SetConsumableMode(B:ConsumableFamily('flask'),'manual'); assert(not B.button.attrs.item and not next(bindings))
local b=assert(icon('flask')); assert(b.attrs.item); B:SetConsumableMode(B:ConsumableFamily('flask'),'auto')
assert(not b.attrs.item and not b.shown and B.action.itemID==13510 and bindings.MOUSEWHEELDOWN)
""")

test('Disabled families revoke Manual buttons without losing saved mode', BASE+"""
put(manual('flask')); refresh(); local b=assert(icon('flask')); B.db.consumableFamilies.flask=false
b.scripts.PreClick(b,'LeftButton',false); assert(not b.attrs.item); refresh(); assert(not b.shown and B.db.consumableModes.flask=='manual')
""")

test('Safety driver disarms in combat and does not restore stale items', BASE+"""
local item=put(manual('food')); refresh(); local b=assert(icon('food')); combat=true; b.secure=true
local fn=assert(loadstring('local self,newstate=...; '..b.attrs['_onstate-safety']))
b.attrs['state-safety']='blocked'; fn(b,'blocked'); b.secure=false
B:UpdateManualConsumables(); b.scripts.PreClick(b,'LeftButton',false); assert(not b.attrs.item and not b.shown)
combat=false; b.secure=true; b.attrs['state-safety']='ready'; fn(b,'ready'); b.secure=false
assert(not b.attrs.item and not b.shown); bags[item.id]=0; refresh(); assert(not b.attrs.type1)
""")

test('Manual mode preserves Auto eating pause but adds no global eating gate', BASE+"""
put(manual('food')); local eat=next(B.EatingSpellIDs); aura('player',eat,'Eating',20,30)
refresh(); assert(B.action and B.action.id==5232); assert(B:ReadinessContext())
B.db.consumableModes.food='auto'; refresh(); assert(not B.action and B.reason=='eating'); assert(not B:ReadinessContext())
""")

test('Rapid different-family attempts confirm independently', BASE+"""
local f=put(manual('food')); local flask=put(manual('flask')); refresh()
local a=assert(icon('food')); local b=assert(icon('flask')); a.scripts.PreClick(a,'LeftButton',false); a.scripts.PostClick(a,'LeftButton',false)
b.scripts.PreClick(b,'LeftButton',false); b.scripts.PostClick(b,'LeftButton',false)
assert(B.itemAttempts[f.id] and B.itemAttempts[flask.id])
bags[f.id]=4; B:ObserveConsumableUse(); assert(B.confirmedItems.food==f.id and B.itemAttempts[flask.id])
B:ObserveConsumableUse(flask.useSpell); assert(B.confirmedItems.flask==flask.id and not B.itemAttempts)
""")

test('Projection does not validate or mutate pending effect checks', BASE+"""
put(manual('flask')); B:RebuildConsumableCache(); local a=B:GetAuras('player',false)
B.ValidateConsumable=function() error('projection must not validate') end
B.confirmedItems={flask=13510}; local list=B:ManualConsumableProjection(a,B.consumableCache)
assert(#list==1 and B.confirmedItems.flask==13510 and not B.confirmedChecks and not B.effectPauses)
""")

test('Every partial icon row is centered under the main anchor', """
local B=BuffTap
for n=1,9 do
 local width=math.min(4,n)*26-4
 for first=1,n,4 do
  local last=math.min(first+3,n); local x=B:ManualConsumableOffset(first,n); local right=B:ManualConsumableOffset(last,n)
  assert(math.abs((x+right+22)/2-width/2)<.01,'not centered '..n..' '..first)
 end
end
""")

test('Preview contains noninteractive samples and leaves Supplies alone', """
local B=BuffTap; B:Options(); local p=B.optionsPreviews.buff
assert(p:GetHeight()==248 and #p.manualSamples==3 and not p.hint.shown)
for _,s in ipairs(p.manualSamples) do assert(not s.protected and not s.attrs.type1 and not s.scripts.OnClick) end
assert(B.optionsPreviews.supply:GetHeight()==328)
assert(p.manualCaption and p.manualCaption.text==B:Text('Consumables'))
""")

test('Consumables caption follows strip visibility and secure safety', BASE+"""
put(manual('food')); refresh(); local c=assert(B.manualConsumableCaption)
assert(c.shown and c.text.text==B:Text('Consumables') and not c.attrs.type1)
combat=true; c.secure=true
local fn=assert(loadstring('local self,newstate=...; '..c.attrs['_onstate-safety']))
c.attrs['state-safety']='blocked'; fn(c,'blocked'); assert(not c.shown)
c.attrs['state-safety']='ready'; fn(c,'ready'); assert(not c.shown)
c.secure=false; combat=false; refresh(); assert(c.shown)
B.db.consumableFamilies.food=false; refresh(); assert(not c.shown)
""")

for name,change in (
 ('mounted', 'IsMounted=function() return true end'),
 ('dead', 'UnitIsDeadOrGhost=function() return true end'),
 ('vehicle', 'UnitInVehicle=function() return true end'),
 ('pet battle', 'C_PetBattles={IsInBattle=function() return true end}'),
 ('unknown vehicle', 'UnitInVehicle=function() return nil end'),
 ('changed player identity', "local old=UnitGUID; UnitGUID=function(u) if u=='player' then return 'replacement' end return old(u) end"),
 ('disabled master', 'B.db.consumablesEnabled=false'),
 ('disabled family', 'B.db.consumableFamilies.food=false'),
 ('quarantined item', "B.itemQuarantine={[item.id]='test quarantine'}"),
 ('unloaded metadata', 'items[item.id].loaded=false'),
 ('changed use spell', 'items[item.id].spell=999999'),
 ('active cooldown', 'C_Item.GetItemCooldown=function() return GetTime(),30,true end'),
 ('unmet item level', 'UnitLevel=function() return 0 end'),
):
 test('Exact Manual click cancels for '+name, BASE+"""
local item=put(manual('food')); refresh(); local b=assert(icon('food')); assert(b.attrs.type1=='item')
"""+change+"""
b.scripts.PreClick(b,'LeftButton',false); assert(not b.attrs.type1 and not b.attrs.item and not B.itemAttempt)
""")

test('Detaching preserves first-row center and reattaches to the current buff position', BASE+"""
put(manual('food')); refresh(); local x,y=B:ManualConsumableAnchor()
assert(not B.db.manualConsumablesDetached and B:SetManualConsumablesDetached(true))
assert(B.db.manualConsumablesX==x and B.db.manualConsumablesY==y)
B.db.x=B.db.x+140; B.db.y=B.db.y+70
local dx,dy=B:ManualConsumableAnchor(); assert(dx==x and dy==y)
assert(B:SetManualConsumablesDetached(false)); dx,dy=B:ManualConsumableAnchor(); assert(dx==x+140 and dy==y+70)
""")

test('Detached edit mover works without active items and saves on drag stop', BASE+"""
B:SetManualConsumablesDetached(true); B.db.nearbyEnabled=false; B.db.campReminder=false; B.db.supplyReminder=false
B:SetEditModeActive(true); local m=assert(B.editManualConsumables); assert(m.shown and not m.protected and not m.attrs.type1)
m.GetCenter=function() return 700,350 end; m.scripts.OnDragStart(m); B:SetEditModeActive(false)
assert(B.db.manualConsumablesX==200 and B.db.manualConsumablesY==-150 and not m.shown and not m.dragging)
""")

test('Attached consumables have no independent edit mover', BASE+"""
B:SetEditModeActive(true); assert(not B.editManualConsumables); B:SetEditModeActive(false)
""")

test('Detach switch changes attachment without opening move mode', BASE+"""
B:Options(); local f=B.options; assert(not f.detachConsumables:GetChecked() and f.moveReminders and not f.moveConsumables)
f.detachConsumables:SetChecked(true); f.detachConsumables.scripts.OnClick(f.detachConsumables)
assert(B.db.manualConsumablesDetached and not B.editModeActive)
f.moveReminders.scripts.OnClick(); assert(B.editModeActive and B.moveDoneBar.cancel)
B.moveDoneBar.cancel.scripts.OnClick(); assert(not B.editModeActive)
f.detachConsumables:SetChecked(false); f.detachConsumables.scripts.OnClick(f.detachConsumables)
assert(not B.db.manualConsumablesDetached)
""")

test('Cancel restores every moved position including an unfinished drag', BASE+"""
B:SetManualConsumablesDetached(true); B.db.nearbyEnabled=true; B.db.campReminder=true
local keys={'x','y','nearbyX','nearbyY','campX','campY','supplyX','supplyY','manualConsumablesX','manualConsumablesY'}
local before={}; for i,k in ipairs(keys) do B.db[k]=50+i; before[k]=B.db[k] end
B:MoveAllFrames('buff')
for i,k in ipairs(keys) do B.db[k]=300+i end
B.editManualConsumables.GetCenter=function() return 900,900 end
B.editManualConsumables.scripts.OnDragStart(B.editManualConsumables)
B.moveDoneBar.cancel.scripts.OnClick()
for _,k in ipairs(keys) do assert(B.db[k]==before[k],k) end
assert(not B.editModeActive and not B.editManualConsumables.shown and not B.movePositionSnapshot)
""")

test('Reset look and position reattaches consumables without changing modes', BASE+"""
manual('food'); B.db.x=300; B.db.y=200; B:SetManualConsumablesDetached(true)
B.db.manualConsumablesX=400; B.db.manualConsumablesY=500; B:Options()
local r=B.options.resetLookButton; r.scripts.OnClick(r); assert(B.db.manualConsumablesDetached)
r.scripts.OnClick(r)
assert(B.db.x==0 and B.db.y==-180 and not B.db.manualConsumablesDetached)
assert(B.db.manualConsumablesX==0 and B.db.manualConsumablesY==0 and B.db.consumableModes.food=='manual')
""")

test('Done saves positions and a later Cancel uses the new session baseline', BASE+"""
B:MoveAllFrames('buff'); B.db.x=123; B.moveDoneBar.done.scripts.OnClick(); assert(B.db.x==123)
B:MoveAllFrames('buff'); B.db.x=456; B:MoveAllFrames('buff'); B.moveDoneBar.cancel.scripts.OnClick()
assert(B.db.x==123 and not B.movePositionSnapshot)
""")

test('Detached edit mode disarms real items and restores only on exit', BASE+"""
put(manual('food')); B:SetManualConsumablesDetached(true); refresh(); local b=assert(icon('food')); assert(b.attrs.type1)
B:SetEditModeActive(true); assert(not b.shown and not b.attrs.type1 and not B.manualConsumableCaption.shown)
B:SetEditModeActive(false); assert(b.shown and b.attrs.type1=='item')
""")

test('Combat refuses detaching and interrupts the consumables mover without saving', BASE+"""
B:SetManualConsumablesDetached(true); local x,y=B:ManualConsumableAnchor(); B:SetEditModeActive(true)
local m=B.editManualConsumables; m.GetCenter=function() return 900,900 end; m.scripts.OnDragStart(m)
combat=true; m.scripts.OnEvent(m,'PLAYER_REGEN_DISABLED'); assert(not m.shown and not m.dragging)
assert(not B:SetManualConsumablesDetached(false) and B.db.manualConsumablesDetached)
assert(B.db.manualConsumablesX==x and B.db.manualConsumablesY==y)
""")

test('Detached anchor round-trips with profile settings', BASE+"""
B:SetManualConsumablesDetached(true); B.db.manualConsumablesX=177; B.db.manualConsumablesY=-233
local text=B:ExportSettings(); B.db.manualConsumablesDetached=false; B.db.manualConsumablesX=0
assert(B:ImportSettings(text)); assert(B.db.manualConsumablesDetached and B.db.manualConsumablesX==177 and B.db.manualConsumablesY==-233)
""")

test('Manual projection and secure pool remain bounded with overflow', BASE+"""
manual('ferocity'); manual('utility')
for _,f in ipairs(B.ConsumableFamilies) do
 if f.parent and (f.parent.key=='ferocity' or f.parent.key=='utility') then
  B.db.consumableFamilies[f.key]=true; put(f)
 end
end
B:InvalidateConsumables(); refresh(); assert(#B.manualConsumableEntries>8)
local clickable=0
for _,b in ipairs(B.manualConsumableButtons) do if b.attrs.type1 then clickable=clickable+1 end end
assert(clickable<=8 and #B.manualConsumableButtons==9)
local extra=B.manualConsumableButtons[9]; assert(extra.overflow and not extra.attrs.type1 and extra.count.text:sub(1,1)=='+')
""")
