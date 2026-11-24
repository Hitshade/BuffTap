from test_bufftap import test
from test_revive import R
from test_cleanse import S
from test_cast_result import R as NEAR, CLICK
from test_nearby_cleanse import N

for cls, spell_id in [('DRUID',5225),('WARLOCK',5500)]:
    test(cls+' tracking can be configured before learning without creating a cast',f"""
local B=BuffTap; playerClass='{cls}'; UnitLevel=function() return 1 end
local found=false; for _,choice in ipairs(B:TrackingChoices()) do if choice.id=={spell_id} then found=true; assert(choice.learned==false) end end
assert(found); B.db.helperTracking=true; B.db.helperTracker={spell_id}; refresh()
assert(not (B.action and B.action.id=={spell_id}))
""")
    test(cls+' selected tracking becomes usable only when learned and in the required form',f"""
local B=BuffTap; playerClass='{cls}'; spell({spell_id},'Class tracking')
C_Minimap={{GetNumTrackingTypes=function() return 1 end, GetTrackingInfo=function() return {{spellID={spell_id},name='Class tracking',texture=132328,type='spell',active=false}} end}}
B.db.helperTracking=true; B.db.helperTracker={spell_id}; GetShapeshiftFormID=function() return 1 end
local a=B:TrackingAction(); assert(a and a.id=={spell_id})
if {spell_id}==5225 then GetShapeshiftFormID=function() return 0 end; assert(not B:TrackingAction()) end
""")
test('Class-specific tracking choices do not leak to unrelated classes',"""
playerClass='MAGE'; for _,choice in ipairs(BuffTap:TrackingChoices()) do assert(choice.id~=5225 and choice.id~=5500) end
""")

for cls, ranks in [('PALADIN',(7328,10322,10324,20772,20773)),
                   ('PRIEST',(2006,2010,10880,10881,20770)),
                   ('SHAMAN',(2008,20609,20610,20776,20777))]:
    for rank in ranks:
        test(f'{cls} resurrection rank {rank} selects and arms exact spell',R+f"""
playerClass='{cls}'; spells={{}}; book={{}}; spell({rank},'Resurrection')
refresh(); assert(B.action and B.action.source=='revive' and B.action.id=={rank})
assert(B.button.attrs.spell=={rank} and B.button.attrs.unit=='party1')
""")

for rank in (437138, 1237948, 1237949, 1237950, 1237951):
    test(f'Forever Druid Revive rank {rank} works with Rebirth off', R+f"""
playerClass='DRUID'; spell({rank},'Revive'); spell(20484,'Rebirth'); B.db.reviveRebirth=false
refresh(); assert(B.action and B.action.source=='revive' and B.action.id=={rank})
assert(B.button.attrs.spell=={rank} and B.button.attrs.unit=='party1')
""")

test('Druid normal resurrection uses highest known rank before optional Rebirth', R+"""
playerClass='DRUID'; spell(437138,'Revive'); spell(1237951,'Revive'); spell(20484,'Rebirth')
B.db.reviveRebirth=true; refresh(); assert(B.action.id==1237951)
""")
test('Druid unknown Revive cannot create a secure action', R+"""
playerClass='DRUID'; B.db.reviveRebirth=false; refresh(); assert(not (B.action and B.action.source=='revive'))
""")
test('A corpse returning into range wakes resurrection while a self buff is shown', R+"""
spell(1243,'Power Word: Fortitude')
local inRange=false; C_Spell.IsSpellInRange=function(id,u) return u=='player' or inRange end
refresh(); assert(B.action and B.action.target=='player'); assert(B.rangeBlockedActions and #B.rangeBlockedActions>0)
inRange=true; advance(1.2); assert(B.action and B.action.source=='revive' and B.action.target=='party1')
""")
test('An eligible corpse does not trigger repeated full range refreshes', R+"""
refresh(); assert(B.action.source=='revive'); B:ResetStats(); advance(3.2)
assert(B.stats.refreshes==0,tostring(B.stats.refreshes))
""")
test('A corpse becoming a ghost during a range wait is never offered', R+"""
local inRange=false; C_Spell.IsSpellInRange=function(id,u) return u=='player' or inRange end
refresh(); ghost.party1=true; inRange=true; advance(1.2)
assert(not (B.action and B.action.source=='revive'))
""")

FORM="""
B.db.smartShift=true; spell(768,'Cat Form'); local form=1
GetShapeshiftForm=function() return form end
GetShapeshiftFormInfo=function() return 132115,form==1,true,768 end
"""
for unit in ('player', 'party1'):
    test('SmartShift captures and restores after '+unit+' cleanse', S+FORM+f"""
debuff('{unit}',8552,'Curse of Weakness','Curse',60); refresh()
assert(B.action and B.action.source=='cleanse' and B.action.target=='{unit}')
B.button.scripts.PreClick(nil,'LeftButton',true); assert(B.smartShiftIntent)
form=0; B.events.scripts.OnEvent(nil,'UPDATE_SHAPESHIFT_FORM')
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cleanse',2782)
assert(B.smartShiftIntent.verified and B.smartShiftIntent.exited)
debuffs['{unit}']={{}}; aura('player',5232,'Mark of the Wild'); aura('player',467,'Thorns')
B.events.scripts.OnEvent(nil,'UNIT_AURA','{unit}'); advance(.2); refresh()
assert(B.action and B.action.source=='smartshift'); assert(B.button.attrs.spell==768)
""")
test('SmartShift captures a validated Nearby row cleanse', N+FORM+"""
debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh()
local row=B.nearbyFrame.rows[1]; row.scripts.PreClick(row,'LeftButton',true)
assert(B.smartShiftIntent and B.smartShiftIntent.buffID==2782)
form=0; B.events.scripts.OnEvent(nil,'UPDATE_SHAPESHIFT_FORM')
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cleanse',2782)
debuffs.nameplate1={}; B:InvalidateAura('nameplate1'); refresh()
assert(B.action and B.action.source=='smartshift')
""")
test('Failed cleanse never grants a SmartShift return', S+FORM+"""
debuff('player',8552,'Curse of Weakness','Curse',60); refresh()
B.button.scripts.PreClick(nil,'LeftButton',true); assert(B.smartShiftIntent)
form=0; B.events.scripts.OnEvent(nil,'UPDATE_SHAPESHIFT_FORM')
B.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cleanse',2782)
assert(not B.smartShiftIntent and not B:SmartShiftAction())
""")
test('SmartShift does not capture an ordinary buff on another player', S+FORM+"""
B:SmartShiftBegin({id=5232,target='party1',targetGUID=UnitGUID('party1')}); assert(not B.smartShiftIntent)
""")
test('SmartShift rejects a cleanse after recipient identity changes', S+FORM+"""
debuff('party1',8552,'Curse of Weakness','Curse',60); refresh(); local action=B.action
local old=UnitGUID; UnitGUID=function(u) return u=='party1' and 'Replacement' or old(u) end
B:SmartShiftBegin(action); assert(not B.smartShiftIntent)
""")

test('Nearby repeated presses during pending cast clear payload without replacing result', NEAR+CLICK+"""
local pending=B.nearbyResult; r.scripts.PreClick(r,'LeftButton',true)
assert(not r.attrs.type1 and B.nearbyResult==pending and pending.state=='pending')
""")
test('Nearby success keeps its confirmation and adds a native cooldown swipe during spam', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
local result=B.nearbyResult; assert(result.state=='ok' and r.result.gcdSwipe.shown)
for i=1,8 do r.scripts.PreClick(r,'LeftButton',true) end
assert(B.nearbyResult==result and result.state=='ok' and not r.attrs.type1)
advance(1.6); refresh(); r.scripts.PreClick(r,'LeftButton',true); assert(r.attrs.type1=='macro')
""")
test('Nearby key binding also blocks cooldown-only repeated casts', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.button.attrs.type1)
assert(B.nearbyResult.state=='ok')
""")
test('Nearby guard works with success confirmations switched off', NEAR+"""
B.db.nearbyCastResult=false; r.scripts.PreClick(r,'LeftButton',true)
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
r.scripts.PreClick(r,'LeftButton',true); assert(not r.attrs.type1 and not B.nearbyResult)
""")
test('Nearby known active cooldown blocks first press without a fake failure', NEAR+"""
C_Spell.GetSpellCooldown=function() return {startTime=now,duration=1.5,isEnabled=true,isActive=true} end
r.scripts.PreClick(r,'LeftButton',true); assert(not r.attrs.type1 and not B.nearbyResult)
""")
test('Nearby keybind cleanse blocks repeated input with confirmations off', N+"""
B.db.nearbyCastResult=false; debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh()
B.button.scripts.PreClick(nil,'LeftButton',true); assert(B.nearbyCastAttempt and B.nearbyCastAttempt.id==2782)
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cleanse',2782)
B.button.scripts.PreClick(nil,'LeftButton',true); assert(not B.button.attrs.type1 and B.nearbyCastUntil>now)
""")
test('Nearby cooldown expiry never casts without a new physical press', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
local clicks=B.nearbyClickAt; advance(1.6)
assert(B.nearbyCastUntil==nil and B.nearbyClickAt==clicks)
assert(not B.nearbyCastAttempt,'timer manufactured an input attempt')
""")
test('Nearby cooldown guard and timer clear on combat', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
B.nearbyEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
assert(not B.nearbyCastAttempt and not B.nearbyCastUntil)
assert(not B.timerHandles or not B.timerHandles['nearby-cast-ready'])
""")

FOODS=[(5527,5006,19708),(16971,10256,19710),(21023,25660,25661),(733,1248687,1248688),
       (10841,1249906,1249907),(267341,1294006,1294007),
       (206177,5004,19705),(11584,5004,19705),(7806,5004,19705),(7807,5004,19705),
       (7808,5004,19705),(17197,5004,19705),(17198,21149,19705),(20516,24869,24870),(21254,24869,24870)]
for item,use,buff in FOODS:
    test(f'Recovered food {item} offers exact item and recognizes its buff',f"""
local B=BuffTap; stock({item},{use}); consumables('food'); refresh()
assert(B.action and B.action.itemID=={item}); assert(B.button.attrs.item=='item:{item}')
aura('player',{buff},'Localized food effect',800,900); B:InvalidateAura('player'); refresh()
assert(not (B.action and B.action.familyKey=='food'))
""")

test('Legacy food eating spell suppresses repeat consumption',"""
local B=BuffTap; stock(5527,5006); consumables('food'); aura('player',5006,'Food',20,24)
refresh(); assert(not (B.action and B.action.familyKey=='food'))
""")
test('Recovered foods retain Auto order and expose Stamina and Spirit categories',"""
local B=BuffTap; local food=B:ConsumableFamily('food'); assert(food.items[#food.items].id==21254)
local clams; for _,item in ipairs(food.items) do if item.id==5527 then clams=item end end
assert(clams); local cats={}; for _,key in ipairs(clams.displayCategories) do cats[key]=true end
assert(cats.stamina and cats.spirit); assert(not clams.note:find('experience',1,true))
stock(food.items[1].id,food.items[1].useSpell); stock(5527,5006); consumables('food'); refresh()
assert(B.action and B.action.itemID==food.items[1].id)
""")
test('Lightning in a Bottle is excluded after fresh tooltip removed Well Fed',"""
for _,item in ipairs(BuffTap:ConsumableFamily('food').items) do assert(item.id~=248613) end
""")

test('Confirmation sweep follows absolute progress without restarting on redraw', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
local result=B.nearbyResult; local sweep=r.result.gcdSwipe
assert(sweep.kind=='StatusBar' and sweep:GetValue()>.99)
now=now+.75; sweep.scripts.OnUpdate(sweep); assert(math.abs(sweep:GetValue()-.5)<.01)
B:ShowNearbyRowResult(r,result); assert(math.abs(sweep:GetValue()-.5)<.01)
now=result.untilTime; sweep.scripts.OnUpdate(sweep); assert(not sweep.shown and not sweep.scripts.OnUpdate)
""")
test('Hidden or failed confirmations stop the visual sweep immediately', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
local sweep=r.result.gcdSwipe; assert(sweep.scripts.OnUpdate)
B:ShowNearbyRowResult(r,nil); assert(not sweep.shown and not sweep.scripts.OnUpdate)
B:ShowNearbyRowResult(r,B.nearbyResult); assert(sweep.scripts.OnUpdate)
B:ShowNearbyRowResult(r,{state='fail',at=now,untilTime=now+1.5,reason='Out of range'})
assert(not sweep.shown and not sweep.scripts.OnUpdate)
""")

test('Nearby short GCD expires exactly, without a minimum display tail', NEAR+CLICK+"""
local start=now
C_Spell.GetSpellCooldown=function() return {startTime=start,duration=1,isEnabled=true,isActive=now<start+1} end
now=start+.95; B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
assert(math.abs(B.nearbyResult.untilTime-(start+1))<.001)
assert(B:NearbyClickWaiting(act)); now=start+1; assert(not B:NearbyClickWaiting(act))
""")
test('Nearby does not invent a cooldown when the API reports none', NEAR+CLICK+"""
C_Spell.GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true,isActive=false} end
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
assert(B.nearbyResult.untilTime==now and B.nearbyCastUntil==now)
assert(not B:NearbyClickWaiting(act))
""")
test('Unconfirmed input cannot add a two-second delay after a ready cooldown', NEAR+CLICK+"""
now=now+.01; assert(not B:NearbyClickWaiting(act),'pending attempt introduced a fixed wait')
""")
test('Nearby macro still waits on GCD timing when isActive is false', NEAR+"""
C_Spell.GetSpellCooldown=function() return {startTime=now,duration=1,isEnabled=true,isActive=false} end
r.scripts.PreClick(r,'LeftButton',true); assert(not r.attrs.type1 and not B.nearbyCastAttempt)
""")
test('Uncorrelated range message cannot mark a successful Nearby cast failed', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',51,'Out of range.')
assert(B.nearbyResult.state=='pending' and not (r.result and r.result.shown))
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
assert(B.nearbyResult.state=='ok' and r.result.shown)
""")
test('Matching failure preserves the range reason in either event order', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',51,'Out of range.')
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',act.id); advance(.11)
assert(B.nearbyResult.state=='fail' and B.nearbyResult.reason:find('Out of range',1,true))
""")
test('Confirmed success overrides a provisional failure and cancels its timer', NEAR+CLICK+"""
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',act.id)
B.nearbyEvents.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',51,'Out of range.')
assert(B.nearbyResult.state=='fail')
C_Spell.GetSpellCooldown=function() return {startTime=now,duration=1.5,isEnabled=true,isActive=true} end
B.nearbyEvents.scripts.OnEvent(nil,'UNIT_SPELLCAST_SUCCEEDED','player','cast',act.id)
assert(B.nearbyResult.state=='ok'); advance(.11); assert(B.nearbyResult.state=='ok')
""")
test('Right-click dismiss removes the greyed out-of-range reminder for a blessing',R+"""
B.db.showOutOfRange=true; B.db.helperDismiss=true
local blocked={key='bok',id=20217,target='party1',targetGUID='Player-1-0001',name='Blessing of Kings',icon=135995,targetName='Ann'}
B.rangeBlocked=true; B.rangeBlockedActions={blocked}; B.rangeBlockedKeys={}
local shown=B:OutOfRangeDisplay(); assert(shown and shown.source=='range' and shown.key=='bok')
B:DismissHelper(shown)
assert(not B:HelperSuppressed(blocked),'the real reminder is NOT dismissed, so it returns when they are in range')
assert(B:OutOfRangeDisplay()==nil,'icon is gone after the dismiss')
local other={key='bok',id=20217,target='party2',targetGUID='Player-1-0002',name='Blessing of Kings',icon=135995,targetName='Bo'}
B.rangeBlockedActions={blocked,other}; local next=B:OutOfRangeDisplay(); assert(next and next.target=='party2','the next out-of-range player still shows')
B:RestoreHelpers(); B.rangeBlockedActions={blocked}; assert(B:OutOfRangeDisplay(),'Restore reminders brings it back')
""")
