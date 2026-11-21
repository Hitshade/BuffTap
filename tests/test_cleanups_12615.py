from test_bufftap import test
from test_nearby_invites import social
from test_manual_thanks_12612 import manual

# Manual thanks: idle calls do no work.
test('Disabled manual thanks keeps its queue table across aura events',manual+"B.db.manualThanks=false; B.manualThanksQueue={}; local q=B.manualThanksQueue; for i=1,5 do B:HelperEvent('UNIT_AURA','nameplate1',{}) end; assert(B.manualThanksQueue==q and not B.manualThanksExpiry)")
test('Visible THANK is not rebound on every aura event',manual+"local n=0; local old=SetOverrideBindingClick; SetOverrideBindingClick=function(...) n=n+1; return old(...) end; B:OfferManualThanks(a); assert(bindings.MOUSEWHEELDOWN=='BuffTapManualThanks:LeftButton'); local first=n; for i=1,10 do B:HelperEvent('UNIT_AURA','nameplate1',{}) end; assert(first>0 and n==first and bindings.MOUSEWHEELDOWN=='BuffTapManualThanks:LeftButton')")
test('Visible THANK keeps one expiry timer across aura events',manual+"B:OfferManualThanks(a); local t=B.timers['manual-thanks-expire']; for i=1,5 do B:HelperEvent('UNIT_AURA','nameplate1',{}) end; assert(t and B.timers['manual-thanks-expire']==t)")
test('Changed keys rebind a visible THANK',manual+"B:OfferManualThanks(a); B.db.keys={'F8'}; B:UpdateManualThanks(); assert(bindings.F8=='BuffTapManualThanks:LeftButton')")
test('THANK rebinds after combat clears its keys',manual+"B:OfferManualThanks(a); combat=true; B:HelperEvent('PLAYER_REGEN_DISABLED'); assert(not B.manualThanksButton:IsShown() and not B.manualThanksBindKey); combat=false; B:HelperEvent('PLAYER_REGEN_ENABLED'); bindings={}; now=now+61; a.casterGUID='Player-Second'; UnitNameFromGUID=function() return 'Second','Giver' end; B:OfferManualThanks(a); assert(B.manualThanksButton:IsShown() and bindings.MOUSEWHEELDOWN=='BuffTapManualThanks:LeftButton')")
test('Ordinary empty refresh leaves THANK bound state alone',manual+"B:OfferManualThanks(a); local key=B.manualThanksBindKey; B:Commit(nil,'idle'); assert(B.manualThanksBound and B.manualThanksBindKey==key)")
test('A real action still clears THANK keys first',manual+"B:OfferManualThanks(a); B:Commit({id=5232,valid=true,manual=true,icon=1,name='x',key='motw'},'action'); assert(not B.manualThanksBound)")

# Nearby: keep open in combat, using the same rows.
on=social+"BuffTap.db.nearbyInCombat=true; refresh(); local f=BuffTap.nearbyFrame; local function fight() combat=true; BuffTap.nearbyEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED') end; "
test('Keep open in combat defaults off and keeps the hide driver',social+"local f=BuffTap.nearbyFrame; assert(BuffTap.db.nearbyInCombat==false and f.driver=='[combat] hide')")
test('Keep open in combat removes the hide driver outside combat',on+"assert(f.driver==nil and f.keepsCombat==true); BuffTap.db.nearbyInCombat=false; refresh(); assert(f.driver=='[combat] hide' and f.keepsCombat==false)")
test('Option on keeps every visible slot shown, blank when empty',on+"assert(f.rows[1].entry and f.rows[2].shown and f.rows[5].shown and not f.rows[2].entry and f.rows[2].blank and not f.rows[6].shown); BuffTap.db.nearbyInCombat=false; refresh(); assert(not f.rows[2].shown)")
test('Combat shows the pause banner and moves players under it',on+"fight(); assert(f.pauseRow.shown and f.pauseRow.text.text=='Paused: in combat. Invites still work.'); local r=f.rows[2]; assert(r.entry and r.entry.unit=='nameplate1' and r.invite.shown and not r.action and not r.icons[1].shown)")
test('Players arriving in combat appear in the list',on+"fight(); BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate2'); assert(f.rows[3].entry and f.rows[3].entry.unit=='nameplate2' and f.rows[3].invite.shown)")
test('Players leaving in combat drop out of the list',on+"BuffTap:TrackNearby('nameplate2'); refresh(); fight(); assert(f.rows[3].entry); BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_REMOVED','nameplate1'); assert(f.rows[2].entry.unit=='nameplate2' and f.rows[3].blank and not f.rows[3].entry)")
test('Combat list scrolls with the mouse wheel',on+"for i=2,8 do BuffTap:TrackNearby('nameplate'..i) end; refresh(); fight(); local first=f.rows[2].entry.guid; assert(f.scroll.shown); f.scripts.OnMouseWheel(f,-1); assert(BuffTap.nearbyOffset==1 and f.rows[2].entry.guid~=first)")
test('Invite works in combat only with the option on',social+"local e=BuffTap.nearbyFrame.rows[1].entry; combat=true; assert(not BuffTap:InviteNearby(e) and #invites==0); combat=false; BuffTap.db.nearbyInCombat=true; refresh(); combat=true; BuffTap.nearbyEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); local r=BuffTap.nearbyFrame.rows[2]; r.invite.scripts.OnClick(); assert(#invites==1 and r.invite.text.text=='...')")
test('Combat invite still rejects a recycled nameplate',on+"fight(); local e=f.rows[2].entry; local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Player-Recycled' or old(u) end; assert(not BuffTap:InviteNearby(e) and #invites==0)")
test('Combat rows never regain a cast payload',on+"fight(); local r=f.rows[2]; r.scripts.PreClick(r,'LeftButton',true); assert(not r.action)")
test('List returns to normal after combat',on+"fight(); BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate2'); combat=false; BuffTap.nearbyEvents.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); refresh(); assert(not f.pauseRow.shown and not f.combatDressed and f.rows[1].action and f.rows[1].icons[1].shown and not f.rows[1].combatDressed)")
test('Option off keeps combat invites blocked and window untouched',social+"combat=true; BuffTap.nearbyEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); local f=BuffTap.nearbyFrame; assert(not f.combatDressed and not (f.pauseRow and f.pauseRow.shown))")
test('Keep open in combat switch saves the choice',social+"BuffTap:Options(); local o=BuffTap.options; o.nearbyInCombat:SetChecked(true); o.nearbyInCombat.scripts.OnClick(o.nearbyInCombat); assert(BuffTap.db.nearbyInCombat==true and BuffTap.nearbyFrame.driver==nil)")
test('Keep open in combat follows shared profiles',social+"BuffTap.db.nearbyInCombat=true; assert(BuffTap:CreateSettingsProfile('Combat copy',true)); assert(BuffTap.db.nearbyInCombat==true)")

# Groups buff list scrollbar.
bar="playerClass='PRIEST'; BuffTap:Options(); local s=BuffTap.options.assignScroll; s.ScrollBar=CreateFrame('Slider',nil,s); s.ScrollBar:Show(); "
test('Short Groups buff list hides its scrollbar',bar+"BuffTap:Options(); assert(not s.ScrollBar.shown)")
test('Long Groups buff list keeps its scrollbar',bar+"local old=BuffTap.GroupAssignableBuffs; BuffTap.GroupAssignableBuffs=function(self) local t=old(self); local out={}; for i=1,8 do out[i]=t[((i-1)%#t)+1] end; return out end; BuffTap:Options(); assert(s.ScrollBar.shown)")
