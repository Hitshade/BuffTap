"""Read-only audit reproductions against shipped 1.26.5, not fix regressions.

Loads the existing mocked-runtime harness without running its unrelated suite.
An observation passing means the described shipped behavior was reproduced.
"""
import ast
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'tests/test_bufftap.py'
nodes=[]
for node in ast.parse(path.read_text(encoding='utf-8-sig')).body:
 if isinstance(node,ast.Expr) and isinstance(node.value,ast.Call) and getattr(node.value.func,'id',None)=='test': break
 nodes.append(node)
env={'__file__':str(path)}
exec(compile(ast.Module(body=nodes,type_ignores=[]),str(path),'exec'),env)
test=env['test']

def fixture(filename,key):
 tree=ast.parse((ROOT/'tests'/filename).read_text(encoding='utf-8-sig'))
 return next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(getattr(t,'id',None)==key for t in n.targets))

CAMP=fixture('test_camping.py','setup')+"B.db.campAnywhere=true; B.db.campSound=true; local heard=0; PlaySound=function() heard=heard+1; return true end; PlaySoundFile=PlaySound; "
test('Observed: Camping still displays and sounds during temporary Pause reminders',CAMP+
     "B:PauseReminders(5); B:UpdateCamping(); assert(B:ReminderPauseReason()=='temporary pause'); assert(B.campReminderIcon and B.campReminderIcon.shown and heard==1); assert(B.lastAlertInfo.kind=='camp' and B.lastAlertInfo.preview==true)")
test('Observed: Camping still displays and sounds while stealthed',CAMP+
     "IsStealthed=function() return true end; B:UpdateCamping(); assert(B:ReminderPauseReason()=='stealthed'); assert(B.campReminderIcon.shown and heard==1)")
test('Observed: Camping still displays and sounds after entering Edit Mode',CAMP+
     "B:SetEditModeActive(true); B:UpdateCamping(); assert(B.editCamp.shown and B.campReminderIcon.shown and heard==1)")
test('Observed: global resting pause does not silence automatic Camping sound',CAMP+
     "B.db.pauseResting=true; IsResting=function() return true end; B:UpdateCamping(); assert(B:ReminderPauseReason()=='resting' and B.campReminderIcon.shown and heard==1)")

MANUAL=fixture('test_manual_consumables.py','BASE')+"put(manual('food')); refresh(); local b=assert(icon('food')); assert(b.action); "
test('Observed: Manual food remains visible but disarmed during its resting pause',MANUAL+
     "B.db.consumablesPauseResting=true; IsResting=function() return true end; refresh(); b=assert(icon('food')); assert(b.shown and not b.action and b.attrs.type1==nil); assert(b.reason=='paused while resting')")
test('Observed: Manual food remains visible but disarmed during global temporary pause',MANUAL+
     "B:PauseReminders(5); b=assert(icon('food')); assert(b.shown and not b.action and b.attrs.type1==nil and b.reason=='temporary pause')")
test('Observed: Manual food remains visible but disarmed in an excluded outdoor area',MANUAL+
     "B.db.consumablesInstanceOnly=true; IsInInstance=function() return false,'none' end; refresh(); b=assert(icon('food')); assert(b.shown and not b.action and b.attrs.type1==nil and b.reason=='paused outside dungeons and raids')")
test('Observed: fresh attached Manual icons intersect the default Camping icon',MANUAL+
     "local x,y=B:ManualConsumableAnchor(); assert(not B.db.manualConsumablesDetached); assert(math.abs(x-B.db.campX)<(22+B.db.campSize)/2 and math.abs(y-B.db.campY)<(22+B.db.campSize)/2)")

test('Observed: Warrior resource wait is described as mana in the status text',
     "local B=BuffTap; playerClass='WARRIOR'; spells={}; book={}; spell(6673,'Battle Shout'); B:NormalizeGroupContexts(); C_Spell.IsSpellUsable=function() return false,true end; refresh(); assert(B.manaWaitVisible and not B.action); assert(B:FriendlyStatus()=='Not enough mana to buff.')")

test('Observed: main Reset look and position returns to a different location than fresh defaults',
     "local B=BuffTap; local defaults=B:ReminderDefaultPositions(); assert(defaults and (defaults.x~=0 or defaults.y~=-180)); B:Options(); local r=B.options.resetLookButton; r.scripts.OnClick(r); r.scripts.OnClick(r); assert(B.db.x==0 and B.db.y==-180 and (B.db.x~=defaults.x or B.db.y~=defaults.y))")
test('Observed: Camping Reset look and position uses a third hardcoded location',
     "local B=BuffTap; local frames={}; local create=CreateFrame; CreateFrame=function(...) local f=create(...); frames[#frames+1]=f; return f end; B:Options(); CreateFrame=create; local pane=B.options.appearancePanes.camp; local reset; for _,f in ipairs(frames) do if f:GetParent()==pane and f.text=='Reset look & position' then reset=f end end; assert(reset); reset.scripts.OnClick(reset); reset.scripts.OnClick(reset); local defaults=B:ReminderDefaultPositions(); assert(B.db.campX==100 and B.db.campY==0 and (B.db.campX~=defaults.campX or B.db.campY~=defaults.campY))")

test('Checked: paused Manual icons cannot consume an item through a stale click',MANUAL+
     "B.db.consumablesPauseResting=true; IsResting=function() return true end; b.scripts.PreClick(b,'LeftButton',false); assert(not b.attrs.type1 and not b.attrs.item and not B.itemAttempt)")
test('Checked: real city pause hides the power-wait indicator',
     "local B=BuffTap; C_Spell.IsSpellUsable=function() return false,true end; refresh(); assert(B.manaWaitVisible); B.db.pauseResting=true; IsResting=function() return true end; B.events.scripts.OnEvent(nil,'PLAYER_UPDATE_RESTING'); assert(not B.manaWaitVisible and not B.button.shown)")
print('Audit observations and control checks:',len(env['tests']),'passed; shipped code unchanged.')
