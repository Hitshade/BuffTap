"""Real click, edit-mode and resting regressions from the post-1.26.4 review."""
from test_bufftap import test
from test_nearby import setup as NEAR

GRADE=NEAR+"local B=BuffTap; B.db.buffs.thorns=false; aura('nameplate1',1126,'Mark of the Wild',1700,1800); B.db.nearbyRankUpgrades=true; refresh(); "
test('Buff-grade main binding retains exact upgraded macro at real PreClick',GRADE+
     "assert(B.action and B.action.needState=='rank upgrade' and B.action.id==5232); B.button.scripts.PreClick(B.button,'LeftButton',false); assert(B.action and B.action.id==5232 and B.button.attrs.type1=='macro' and B.button.attrs.macrotext:find('Mark of the Wild(Rank 2)',1,true))")
test('Buff-grade row click retains its safe exact upgraded macro',GRADE+
     "B:UpdateNearbyWindow(); local row=B.nearbyFrame.rows[1]; assert(row.action and row.action.needState=='rank upgrade'); row.scripts.PreClick(row,'LeftButton',false); assert(row.attrs.type1=='macro' and row.attrs.macrotext:find('Mark of the Wild(Rank 2)',1,true))")
for change in ["B.db.nearbyRankUpgrades=false", "auras.nameplate1[1].spellId=5232", "auras.nameplate1[1].spellId=6756", "C_UnitAuras.GetAuraDataByIndex=function() return {secret=true} end", "local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Player-replaced' or old(u) end"]:
 test('Buff-grade click rejects changed toggle coverage or identity '+change,GRADE+change+
      "; B.button.scripts.PreClick(B.button,'LeftButton',false); assert(not B.action and not B.button.attrs.type1 and not B.button.attrs.macrotext)")
test('Buff-grade flag cannot upgrade an ordinary targeted buff',GRADE+
     "local a=B.action; a.nearby=nil; local def=B:FindBuff(a.key); local data=B:GetAuras(a.target,true,true); assert(not B:Missing(def,a,data,B:TargetRebuffSeconds(def)))")
test('Buff-grade click remains blocked in combat',GRADE+
     "combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); B.button.scripts.PreClick(B.button,'LeftButton',false); assert(not B.action and not next(bindings))")

OFF="local B=BuffTap; B.db.nearbyEnabled=false; B.db.campReminder=false; B.db.supplyReminder=false; B.db.suppliesEnabled=false; B.db.consumablesEnabled=false; "
test('All disabled module placeholders remain editable without enabling actions',OFF+
     "B:SetEditModeActive(true); for _,f in ipairs({B.editAnchor,B.editNearby,B.editCamp,B.editSupply}) do assert(f and f.shown and not f.protected) end; assert(not B.action and not next(bindings)); B:SetEditModeActive(false); assert(not B.db.nearbyEnabled and not B.db.campReminder and not B.db.supplyReminder and not B.db.suppliesEnabled)")
test('Disabled Camping and Supplies save their positions without toggling modules',OFF+
     "B:SetEditModeActive(true); B.editCamp.GetCenter=function() return 700,600 end; B.editCamp.scripts.OnDragStop(B.editCamp); B.editSupply.GetCenter=function() return 250,300 end; B.editSupply.scripts.OnDragStop(B.editSupply); B:SetEditModeActive(false); assert(B.db.campX==200 and B.db.campY==100 and B.db.supplyX==-250 and B.db.supplyY==-200); assert(not B.db.campReminder and not B.db.supplyReminder)")
test('Cancel restores positions moved while their modules were disabled',OFF+
     "local x,y=B.db.campX,B.db.campY; B:MoveAllFrames(); B.editCamp.GetCenter=function() return 700,600 end; B.editCamp.scripts.OnDragStop(B.editCamp); assert(B.db.campX==200); B:FinishMovingFrames(true); assert(B.db.campX==x and B.db.campY==y and not B.db.campReminder and not B.db.nearbyEnabled)")
test('Detached consumables remain placeable when consumables are disabled',OFF+
     "B.db.manualConsumablesDetached=true; B:SetEditModeActive(true); local f=B.editManualConsumables; assert(f and f.shown); f.GetCenter=function() return 620,630 end; f.scripts.OnDragStop(f); assert(B.db.manualConsumablesX==120 and B.db.manualConsumablesY==130 and not B.db.consumablesEnabled)")
test('Disabled mover sessions do not write protected frames if combat interrupts',OFF+
     "B:SetEditModeActive(true); combat=true; safety('blocked'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); B:SetEditModeActive(false); assert(not B.editCamp.shown and not B.editSupply.shown and not B.editNearby.shown and not next(bindings))")

SOUND="local B=BuffTap; local heard=0; PlaySound=function() heard=heard+1; return true end; PlaySoundFile=PlaySound; B.db.sound=true; B.db.pauseResting=true; "
test('Confirmed city pause suppresses a newly missing self Thorns and its sound',SOUND+
     "IsResting=function() return true end; aura('player',5232,'Mark of the Wild'); B:InvalidateAura(); B.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(not B.action and not B.button.shown and heard==0); assert(not B:PlayAlert('reminder') and heard==0)")
test('Entering an inn clears the existing self action without a second reminder',SOUND+
     "IsResting=function() return false end; aura('player',5232,'Mark of the Wild'); B:InvalidateAura(); refresh(); assert(B.action and B.action.key=='thorns'); heard=0; IsResting=function() return true end; B.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); advance(.2); assert(not B.action and not B.button.shown and heard==0)")
test('Resting permits opted-in Nearby actions while self buffs stay silent',NEAR+SOUND+
     "IsResting=function() return true end; B.db.nearbyWhileResting=true; B:InvalidateAura(); refresh(); assert(B.action and B.action.nearby and B.action.target~='player' and heard==0); assert(not B:PlayAlert('reminder'))")
for state in ["return nil", "error('temporarily unavailable')", "return {secret=true}"]:
 test('Automatic sound is quiet when resting state cannot be read '+state,SOUND+
      "IsResting=function() "+state+" end; assert(not B:PlayAlert('reminder') and heard==0)")
test('Outdoors resting-pause preference permits normal automatic reminders',SOUND+
     "IsResting=function() return false end; assert(B:PlayAlert('reminder') and heard==1); assert(B.lastAlertInfo.kind=='reminder' and not B.lastAlertInfo.preview and B.lastAlertInfo.resting==false)")
test('Explicit sound previews retain their deliberate resting exception',SOUND+
     "IsResting=function() return true end; assert(B:PlayAlert('reminder',true) and heard==1); assert(B.lastAlertInfo.preview and B.lastAlertInfo.pauseResting)")
test('Sound diagnostics distinguish the most recent actual sound without player identities',SOUND+
     "IsResting=function() return true end; B:PlayAlert('reminder',true); local lines=table.concat(B:DiagnosticsLines(),string.char(10)); assert(lines:find('Last sound: reminder',1,true) and lines:find('preview: true',1,true) and lines:find('Resting pause: true',1,true))")

WAIT="local B=BuffTap; C_Spell.IsSpellUsable=function() return false,true end; B.db.showBuffName=false; B.db.showTargetName=false; B:Refresh(); "
test('Power wait can show a grey icon with both visible labels disabled',WAIT+
     "assert(B.manaWaitVisible and B.button.shown and B.button.nameLabel.text=='' and B.button.label.text==''); assert(not B.action and not B.button.attrs.type1 and not next(bindings))")
test('Power wait title and lower label each follow their existing visibility switch',WAIT+
     "B.db.showBuffName=true; B:Refresh(); assert(B.button.nameLabel.text=='Waiting for mana' and B.button.label.text==''); B.db.showBuffName=false; B.db.showTargetName=true; B:Refresh(); assert(B.button.nameLabel.text=='' and B.button.label.text=='Resumes when ready')")
test('City pause hides an existing resource-wait indicator as well as normal buffs',WAIT+
     "B.db.pauseResting=true; IsResting=function() return true end; B.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(not B.manaWaitVisible and not B.button.shown)")
test('Warrior power wait respects city pause independently of Nearby',WAIT+
     "playerClass='WARRIOR'; B.db.pauseResting=true; IsResting=function() return true end; B:Refresh(); assert(not B.action and not B.manaWaitVisible and not B.button.shown)")

for width,height in [(450,320),(640,480),(1024,768),(1920,1080),(2560,1440),(5120,1440),(3840,2160)]:
 test('Fresh layout keeps the whole group inside scaled UI space '+str((width,height)),
      f"local B=BuffTap; UIParent:SetSize({width},{height}); local p=B:ReminderDefaultPositions(); assert(p); assert(p.x-105>=-{width}/2 and p.nearbyX+132<={width}/2-16); assert(p.y+48<={height}/2-16 and p.supplyY-40>=-{height}/2+16); assert(p.campX==p.x and (p.supplyX==p.x or p.supplyX==p.nearbyX) and p.y>p.campY and (p.campY>p.supplyY or (p.campY==p.supplyY and p.supplyX~=p.campX)) and p.nearbyX>p.x+170)")
test('First-run layout is applied only when all positions are genuinely unset',
     "local B=BuffTap; B.db.welcomeSeen=false; B.db.onboardingVersion=nil; for _,k in ipairs({'x','y','campX','campY','supplyX','supplyY','nearbyX','nearbyY'}) do B.db[k]=nil end; local p=B:ReminderDefaultPositions(); B:InitDB(); assert(B.db.x==p.x and B.db.y==p.y and B.db.campY==p.campY and B.db.nearbyX==p.nearbyX and B.db.supplyY==p.supplyY)")
test('Existing coordinates and resized UI never trigger automatic repositioning',
     "local B=BuffTap; B.db.x=100; B.db.y=-50; B.db.campX=-300; B.db.supplyY=80; B.db.nearbyX=400; UIParent:SetSize(640,480); B:InitDB(); assert(B.db.x==100 and B.db.y==-50 and B.db.campX==-300 and B.db.supplyY==80 and B.db.nearbyX==400)")
test('Copied profile keeps its own positions instead of the starter layout',
     "local B=BuffTap; local current=B.profileDB:GetCurrentProfile(); B:CreateSettingsProfile('Position source',false); B.db.x=-111; B.db.y=222; B.db.campX=-333; B:SelectSettingsProfile(current); assert(B:CopySettingsProfile('Position source')); assert(B.db.x==-111 and B.db.y==222 and B.db.campX==-333)")
test('Unavailable UI geometry falls back without inventing placement coordinates',
     "local B=BuffTap; UIParent.GetSize=function() return nil,nil end; assert(B:ReminderDefaultPositions()==nil)")
