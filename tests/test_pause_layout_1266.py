"""Corrected player-experience behavior, separate from the historical audit."""
import ast
from test_bufftap import test, ROOT

def fixture(filename,key):
 tree=ast.parse((ROOT/'tests'/filename).read_text(encoding='utf-8-sig'))
 return next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(getattr(t,'id',None)==key for t in n.targets))

CAMP=fixture('test_camping.py','setup')+"B.db.campAnywhere=true; B.db.campSound=true; local heard=0; PlaySound=function() heard=heard+1; return true end; PlaySoundFile=PlaySound; "
for state,change in [
 ('temporary pause','B:PauseReminders(5)'),
 ('resting',"B.db.pauseResting=true; IsResting=function() return true end"),
 ('stealth',"IsStealthed=function() return true end"),
 ('Edit Mode',"B:SetEditModeActive(true)")]:
 test('Camping respects '+state+' without a real icon or automatic sound',CAMP+change+
      "; B:UpdateCamping(); assert(not (B.campReminderIcon and B.campReminderIcon.shown) and heard==0); assert(not B.campAlerted)")
test('Temporary pause immediately hides an already active camp reminder and resumes quietly',CAMP+
     "B:UpdateCamping(); assert(B.campReminderIcon.shown and heard==1); B:PauseReminders(5); assert(not B.campReminderIcon.shown); advance(301); assert(B.campReminderIcon.shown and heard==1)")
test('Cancelling a temporary pause restores Camping without inventing another alert',CAMP+
     "B:UpdateCamping(); B:PauseReminders(5); B:PauseReminders(0); assert(B.campReminderIcon.shown and heard==1)")
test('Camping can detect a genuinely new missing effect after resuming',CAMP+
     "B:UpdateCamping(); assert(heard==1); B:PauseReminders(5); campAura(1229741,3600,3600); B:UpdateCamping(); advance(301); assert(not B.campReminderIcon.shown); playerAuras[1229741]=nil; B:UpdateCamping(); assert(B.campReminderIcon.shown and heard==2)")
for event,change in [('PLAYER_UPDATE_RESTING',"B.db.pauseResting=true; IsResting=function() return true end"),('UPDATE_STEALTH',"IsStealthed=function() return true end")]:
 test('Camping independently reacts to '+event,CAMP+
      "B.db.group=false; B.db.nearbyEnabled=false; B.db.friendlyTarget=false; B:UpdateCamping(); assert(B.campReminderIcon.shown); "+change+
      "; assert(B.campingEvents.registered['"+event+"']); B.campingEvents.scripts.OnEvent(B.campingEvents,'"+event+"'); advance(.2); assert(not B.campReminderIcon.shown and heard==1)")
test('Entering Edit Mode hides live Camping and leaves only its unprotected mover',CAMP+
     "B:UpdateCamping(); B:SetEditModeActive(true); assert(B.editCamp.shown and not B.campReminderIcon.shown and heard==1); B:UpdateCamping(); assert(not B.campReminderIcon.shown); B:SetEditModeActive(false); assert(B.campReminderIcon.shown and heard==1)")
test('Camping automatic sound is not classified as a preview and does not need main sounds',CAMP+
     "B.db.sound=false; B:UpdateCamping(); assert(heard==1 and B.lastAlertInfo.kind=='camp' and not B.lastAlertInfo.preview)")
test('Main sound permission cannot enable a disabled Camping sound',CAMP+
     "B.db.sound=true; B.db.campSound=false; assert(not B:PlayAlert('camp')); assert(heard==0)")
test('Automatic Camping sound obeys rate limiting while explicit preview remains available',CAMP+
     "assert(B:PlayAlert('camp')); assert(not B:PlayAlert('camp') and heard==1); B:PauseReminders(5); assert(not B:PlayAlert('camp')); assert(B:PlayAlert('camp',true) and heard==2)")
test('Camp visual preview never emits an automatic alert during a pause',CAMP+
     "B:PauseReminders(5); B:PreviewCampReminder(); assert(B.campReminderIcon.shown and heard==0)")
test('Combat interruption of the pause timer cannot restore a camp icon',CAMP+
     "B:PauseReminders(1); combat=true; B.campingEvents.scripts.OnEvent(B.campingEvents,'PLAYER_REGEN_DISABLED'); advance(61); assert(not (B.campReminderIcon and B.campReminderIcon.shown) and heard==0); combat=false; B.campingEvents.scripts.OnEvent(B.campingEvents,'PLAYER_REGEN_ENABLED'); advance(.2); assert(B.campReminderIcon.shown and heard==1)")

MANUAL=fixture('test_manual_consumables.py','BASE')+"put(manual('food')); refresh(); local b=assert(icon('food')); assert(b.action); "
for state,change in [
 ('resting',"B.db.consumablesPauseResting=true; IsResting=function() return true end"),
 ('global resting',"B.db.pauseResting=true; IsResting=function() return true end"),
 ('temporary pause',"B:PauseReminders(5)"),
 ('excluded instance scope',"B.db.consumablesInstanceOnly=true; IsInInstance=function() return false,'none' end")]:
 test('Manual items caption and holder all hide for '+state,MANUAL+change+
      "; refresh(); for _,v in ipairs(B.manualConsumableButtons) do assert(not v.shown and not v.attrs.type1 and not v.attrs.item) end; assert(not B.manualConsumableCaption.shown and not B.manualConsumableHolder.shown and #B.manualConsumableEntries==0)")
test('Manual items resume with fresh payloads when their city pause ends',MANUAL+
     "B.db.consumablesPauseResting=true; IsResting=function() return true end; B.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(not b.shown); IsResting=function() return false end; B.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); b=assert(icon('food')); assert(b.shown and b.action and b.attrs.type1=='item' and B.manualConsumableCaption.shown)")
test('A stale Manual click is disarmed before a pending pause refresh',MANUAL+
     "B.db.consumablesPauseResting=true; IsResting=function() return true end; b.scripts.PreClick(b,'LeftButton',false); assert(not b.attrs.type1 and not b.attrs.item and not B.itemAttempt)")
test('Detached Manual notifications obey the same pause without losing their saved position',MANUAL+
     "B:SetManualConsumablesDetached(true); B.db.manualConsumablesX=222; B.db.manualConsumablesY=111; B:PauseReminders(5); assert(not b.shown and B.db.manualConsumablesDetached); B:PauseReminders(0); assert(icon('food').shown and B.db.manualConsumablesX==222 and B.db.manualConsumablesY==111)")
test('Unknown stock remains a grey informative reminder outside a pause',MANUAL+
     "bags[b.entry.item.id]=0; B:InvalidateConsumables(); refresh(); b=assert(icon('food')); assert(b.shown and not b.action)")

for width,height in [(450,320),(640,360),(640,480),(1024,768),(1920,1080),(2560,1440),(5120,1440),(3840,2160)]:
 test('Starter group separates Camping Supplies Nearby and both attached rows '+str((width,height)),
      f"local B=BuffTap; UIParent:SetSize({width},{height}); local p=B:ReminderDefaultPositions(); for k,v in pairs(p) do B.db[k]=v end; local x,y=B:ManualConsumableAnchor(); for _,c in ipairs({{{{p.campX,p.campY}},{{p.supplyX,p.supplyY}}}}) do assert(math.abs(x-c[1])>82 or math.abs(y-c[2])>42); assert(math.abs(x-c[1])>82 or math.abs(y-26-c[2])>42) end; assert(p.x-105>=-{width}/2 and p.nearbyX+132<={width}/2-16 and p.y+48<={height}/2-16 and p.supplyY-40>=-{height}/2+16); assert(math.abs(p.supplyX-p.campX)>50 or math.abs(p.supplyY-p.campY)>50)")

RESET="local B=BuffTap; local frames={}; local create=CreateFrame; CreateFrame=function(...) local f=create(...); frames[#frames+1]=f; return f end; B:Options(); CreateFrame=create; "
for kind in ['buff','camp','supply']:
 test('Actual '+kind+' reset uses shared defaults and leaves other module positions alone',RESET+
      "local defaults=B:ReminderDefaultPositions(); local before={x=B.db.x,y=B.db.y,campX=B.db.campX,campY=B.db.campY,supplyX=B.db.supplyX,supplyY=B.db.supplyY,nearbyX=B.db.nearbyX,nearbyY=B.db.nearbyY}; local r; "+
      ("r=B.options.resetLookButton; B.db.x=-12; B.db.y=-34; " if kind=='buff' else "for _,f in ipairs(frames) do if f:GetParent()==B.options.appearancePanes['"+kind+"'] and f.text=='Reset look & position' then r=f end end; B.db."+kind+"X=-12; B.db."+kind+"Y=-34; ")+
      "assert(r); r.scripts.OnClick(r); r.scripts.OnClick(r); local own={"+('x=true,y=true' if kind=='buff' else kind+'X=true,'+kind+'Y=true')+"}; for key,old in pairs(before) do assert(B.db[key]==(own[key] and defaults[key] or old),key) end")
test('Resetting positions never changes feature enable choices',
     "local B=BuffTap; B.db.campReminder=false; B.db.suppliesEnabled=true; B.db.nearbyEnabled=false; for _,kind in ipairs({'buff','camp','supply','nearby'}) do assert(B:ResetReminderPosition(kind)) end; assert(not B.db.campReminder and B.db.suppliesEnabled and not B.db.nearbyEnabled)")
test('Combat rejects explicit position resets without changing coordinates',
     "local B=BuffTap; local x=B.db.x; combat=true; assert(not B:ResetReminderPosition('buff') and B.db.x==x)")
for cls,word in [('WARRIOR','power'),('ROGUE','power'),('MAGE','mana'),('DRUID','mana')]:
 test('Resource status terminology fits '+cls,
      "local B=BuffTap; playerClass='"+cls+"'; B.action=nil; B.reason='not enough mana'; assert(B:FriendlyStatus()=='Not enough "+word+" to buff.')")
