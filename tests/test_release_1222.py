from test_bufftap import test, tests
import test_nearby
setup=test_nearby.setup
test('Nothing is offered while stealthed, and buffing resumes after',"IsStealthed=function() return true end; refresh(); assert(not BuffTap.action and BuffTap:ReminderPauseReason()=='stealthed'); IsStealthed=function() return false end; refresh(); assert(BuffTap.action)")
test('Nearby holds back while stealthed',setup+"IsStealthed=function() return true end; refresh(); assert(not BuffTap.action); assert(BuffTap:NearbyEntry('nameplate1')==nil)")
test('A missing stealth API never pauses BuffTap',"IsStealthed=nil; refresh(); assert(BuffTap.action and BuffTap:ReminderPauseReason()==nil)")
test('Nearby page has the PvP protection switch, shared with Helpers',"local B=BuffTap; B:Options(); local f=B.options; assert(f.nearbyPvp and f.nearbyPvp:GetChecked()==(B.db.pvpProtection==true)); f.nearbyPvp:SetChecked(false); f.nearbyPvp.scripts.OnClick(f.nearbyPvp); assert(B.db.pvpProtection==false); B:Options(); assert(not B.options.pvpProtection or B.options.pvpProtection:GetChecked()==false)")
test('Nearby all-players view stays listed while stealthed, with buffing paused',setup+"BuffTap.db.nearbyShowAll=true; IsStealthed=function() return true end; refresh(); BuffTap:UpdateNearbyWindow(); local f=BuffTap.nearbyFrame; assert(BuffTap:NearbyBrowsePause()=='stealthed'); assert(f.count.text:find('Paused: stealthed',1,true)); assert(f.rows[1].entry and #f.rows[1].entry.actions==0 and not f.rows[1].attrs.type1)")
