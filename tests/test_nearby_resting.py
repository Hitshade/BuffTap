from test_bufftap import test, tests
import test_nearby
setup=test_nearby.setup
test('Nearby pauses in towns on its own when Buff while resting is off',setup+"BuffTap.db.pauseResting=false; BuffTap.db.nearbyWhileResting=false; IsResting=function() return true end; refresh(); assert(not (BuffTap.action and BuffTap.action.nearby)); assert(BuffTap:NearbyPauseReason()=='resting')")
test('Nearby buffs in towns when Buff while resting is on, Helpers pause off',setup+"BuffTap.db.pauseResting=false; BuffTap.db.nearbyWhileResting=true; IsResting=function() return true end; refresh(); assert(BuffTap.action and BuffTap.action.nearby)")
test('Nearby buffs in towns with both on',setup+"BuffTap.db.pauseResting=true; BuffTap.db.nearbyWhileResting=true; IsResting=function() return true end; refresh(); assert(BuffTap.action and BuffTap.action.nearby)")
test('Stealth still pauses Nearby in towns',setup+"BuffTap.db.pauseResting=true; BuffTap.db.nearbyWhileResting=true; IsResting=function() return true end; IsStealthed=function() return true end; assert(BuffTap:NearbyPauseReason()=='stealthed')")
test('Existing characters that buffed in towns keep doing so',"local B=BuffTap; BuffTapDB={enabled=true,pauseResting=false,nearbyWhileResting=false}; B:InitDB(); assert(B.db.nearbyWhileResting==true and B.db.nearbyRestingRule==1); B.db.nearbyWhileResting=false; B:InitDB(); assert(B.db.nearbyWhileResting==false,'runs once')")
test('Existing characters with the Helpers pause on keep their choice',"local B=BuffTap; BuffTapDB={enabled=true,pauseResting=true,nearbyWhileResting=false}; B:InitDB(); assert(B.db.nearbyWhileResting==false)")
test('New characters start paused in towns',"local B=BuffTap; BuffTapDB={}; B:InitDB(); assert(B.db.nearbyWhileResting==false and B.db.nearbyRestingRule==1)")
test('The zZ button switches Nearby resting and turns gold',setup+"BuffTap.db.nearbyWhileResting=false; BuffTap:UpdateNearbyWindow(); local b=BuffTap.nearbyFrame.resting; assert(b and b.text.text=='zZ'); b.scripts.OnClick(b); assert(BuffTap.db.nearbyWhileResting==true); b.scripts.OnClick(b); assert(BuffTap.db.nearbyWhileResting==false)")
test('The zZ button hides with the title bar',setup+"BuffTap:UpdateNearbyWindow(); local f=BuffTap.nearbyFrame; local found; for _,p in ipairs(BuffTap:NearbyHeaderParts(f)) do if p==f.resting then found=true end end; assert(found)")
