from test_bufftap import test
from test_supplies import test as resting_test

# Queue of further pending buffs below the reminder: secure, click-validated, out of combat only.
Q="local B=BuffTap; local function q(i) return _G['BuffTapQueueButton'..i] end; local function on(i) return q(i)~=nil and q(i):IsShown()==true end; "
PALADIN='''
playerClass='PALADIN'; spells={}; book={}
spell(20217,'Blessing of Kings',20); spell(19740,'Blessing of Might',4); spell(19742,'Blessing of Wisdom',4)
spell(25898,'Greater Blessing of Kings',60); spell(25782,'Greater Blessing of Might',52); spell(25894,'Greater Blessing of Wisdom',54)
UnitLevel=function() return 60 end
classes={player='PALADIN',party1='WARRIOR',party2='PRIEST',target='WARRIOR'}
UnitClass=function(u) return 'Class',classes[u] end
bags[21177]=20
BuffTap.db.group=true; BuffTap.db.buffQueue=true
'''

test('Buff queue is off by default and creates no secure buttons',Q+"refresh(); assert(B.db.buffQueue==false); assert(q(1)==nil)")

test('Buff queue shows the next own buff as a smaller secure spell icon',Q+"B.db.buffQueue=true; refresh(); assert(B.action.id==5232); assert(on(1),'icon'); local b=q(1); assert(b.attrs.spell==467 and b.attrs.unit=='player' and b.attrs.type1=='spell'); assert(b.width<B.db.size and b.width>=16,tostring(b.width)); assert(not on(2)); assert(b.protected)")

test('Buff queue groups further recipients of one buff with a count',Q+"B.db.buffQueue=true; B.db.group=true; B.db.buffs.thorns=false; refresh(); assert(B.action.key=='motw'); assert(on(1) and not on(2)); assert(q(1).count.text=='2',tostring(q(1).count.text)); assert(q(1).action.targetGUID~=B.action.targetGUID)")

test('Buff queue never offers a group spell and leaves the group family to the main reminder',Q+"spell(21849,'Gift of the Wild',50); UnitLevel=function() return 60 end; B.db.buffQueue=true; B.db.group=true; refresh(); assert(B.action.groupCast); assert(on(1)); assert(q(1).action.key=='thorns' and not q(1).action.groupCast,tostring(q(1).action.key)); for i=1,4 do if on(i) then assert(q(i).action.key~='motw' and q(i).action.key~='gotw') end end")

test('Buff queue installs no key bindings',Q+"B.db.buffQueue=true; refresh(); for key,value in pairs(bindings) do assert(not tostring(value):find('Queue',1,true),value) end")

test('Combat clears the queue through the secure driver and refreshes after',Q+"B.db.buffQueue=true; refresh(); assert(on(1)); combat=true; safety('blocked'); local b=q(1); b.secure=true; local fn=assert(loadstring('local self,newstate=...; '..b.attrs['_onstate-safety'])); fn(b,'blocked'); b.secure=false; assert(not b.shown and b.attrs.type1==nil and b.attrs.spell==nil); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); B:Refresh(); assert(not b.shown); combat=false; safety('ready'); B.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); assert(on(1) and q(1).attrs.spell==467)")

test('Queue click refuses a changed recipient identity',Q+"B.db.buffQueue=true; B.db.group=true; B.db.buffs.thorns=false; refresh(); local b=q(1); local unit=b.action.target; assert(unit~='player'); local old=UnitGUID; UnitGUID=function(u) return u==unit and 'Other' or old(u) end; b.scripts.PreClick(b,'LeftButton',false); assert(b.attrs.type1==nil and not b.shown)")

test('Queue click refuses a buff that is no longer missing',Q+"B.db.buffQueue=true; refresh(); local b=q(1); auras.player=auras.player or {}; table.insert(auras.player,{spellId=467,name='Thorns',duration=600,expirationTime=now+600}); b.scripts.PreClick(b,'LeftButton',false); assert(b.attrs.type1==nil and not b.shown)")

test('Queue click refuses while paused, dismissed or disabled',Q+"B.db.buffQueue=true; refresh(); local b=q(1); mounted=true; b.scripts.PreClick(b,'LeftButton',false); assert(b.attrs.type1==nil); mounted=false; refresh(); b=q(1); B.db.enabled=false; b.scripts.PreClick(b,'LeftButton',false); assert(b.attrs.type1==nil)")

test('Queue click refuses a recipient that became PvP flagged',Q+"B.db.buffQueue=true; B.db.group=true; B.db.buffs.thorns=false; refresh(); local b=q(1); local unit=b.action.target; UnitIsPVP=function(u) return u==unit end; b.scripts.PreClick(b,'LeftButton',false); assert(b.attrs.type1==nil and not b.shown)")

test('A valid queue click keeps its payload and refreshes after the cast',Q+"B.db.buffQueue=true; refresh(); local b=q(1); b.scripts.PreClick(b,'LeftButton',false); assert(b.attrs.type1=='spell' and b.attrs.spell==467 and b.shown); B:ResetStats(); b.scripts.PostClick(b,'LeftButton',false); advance(.2); assert(B.stats.refreshes>=1)")

test('Right-clicking a queue icon does nothing',Q+"B.db.buffQueue=true; refresh(); local b=q(1); b.scripts.PreClick(b,'RightButton',false); assert(b.attrs.type1=='spell' and b.shown)")

test('Queue passes leave status, wake and range state as the main selection left it',Q+"aura('player',5232,'Mark of the Wild',600,1800); B.db.buffs.thorns=true; refresh(); local wake,reason,range=B.nextWakeDelay,B.reason,B.rangeBlocked; local timersOff=liveTimers(); B.db.buffQueue=true; refresh(); assert(B.nextWakeDelay==wake and B.reason==reason and B.rangeBlocked==range); assert(B.queuePass==nil and B.queueExclude==nil)")

test('Hidden or empty reminder shows no queue',Q+"B.db.buffQueue=true; B.db.showReminder=false; refresh(); assert(not on(1)); B.db.showReminder=true; aura('player',5232,'Mark of the Wild'); aura('player',467,'Thorns'); refresh(); assert(not B.action and not on(1))")

test('Manual consumables move below the queue row',Q+"local _,y1=B:ManualConsumableAnchor(); B.db.buffQueue=true; refresh(); assert(on(1)); local _,y2=B:ManualConsumableAnchor(); assert(y2<y1-B:BuffQueueIconSize(),tostring(y1)..' '..tostring(y2)); B.db.manualConsumablesDetached=true; B.db.manualConsumablesY=5; local _,y3=B:ManualConsumableAnchor(); assert(y3==5)")

test('Queue option lives in the buff reminder icon settings',Q+"B:Options(); local c=B.options.queueCheck; assert(c); assert(c:GetChecked()==false); c:SetChecked(true); c.scripts.OnClick(c); assert(B.db.buffQueue==true); advance(.1); assert(on(1))")

resting_test('Queued blessings never give a player a second blessing family',PALADIN+Q+"B.db.blessingAssignments=true; B.db.blessingClasses={PALADIN='skip',WARRIOR='bom',PRIEST='bow'}; refresh(); assert(B.action.key=='bom' and B.action.target=='party1'); assert(on(1) and not on(2)); assert(q(1).action.key=='bow' and q(1).action.target=='party2')")

resting_test('Legacy blessings queue one family per player',PALADIN+Q+"B.db.buffs.bok=true; B.db.buffs.bom=true; refresh(); assert(B.action.key=='bok',tostring(B.action.key)); assert(on(1) and q(1).count.text=='2' and not on(2)); for i=1,4 do if on(i) then assert(q(i).action.key=='bok',tostring(q(i).action.key)) end end")

resting_test('A Greater Blessing on the main reminder suppresses queued blessings',PALADIN+Q+"classes.party2='WARRIOR'; B:InvalidateRoster(); B.db.blessingAssignments=true; B.db.blessingClasses={PALADIN='skip',WARRIOR='bom',PRIEST='bow'}; refresh(); assert(B.action.groupCast); assert(not on(1))")
