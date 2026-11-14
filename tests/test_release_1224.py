from test_bufftap import test, tests
import test_nearby
setup=test_nearby.setup
R="BuffTap.db.pauseResting=true; BuffTap.db.nearbyWhileResting=true; IsResting=function() return true end; "
test('Buff while resting works with Pause reminders while resting on',setup+R+"refresh(); assert(BuffTap.action and BuffTap.action.nearby and BuffTap.action.target=='nameplate1', BuffTap.action and BuffTap.action.target); assert(BuffTap:Validate(BuffTap.action))")
test('The binding click keeps the Nearby buff while resting',setup+R+"refresh(); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.action and BuffTap.action.nearby)")
test('Your own buffs stay paused while resting',setup+R+"BuffTap.db.nearbyEnabled=false; refresh(); assert(not BuffTap.action)")
test('Without Buff while resting, Nearby stays paused too',setup+"BuffTap.db.pauseResting=true; BuffTap.db.nearbyWhileResting=false; IsResting=function() return true end; refresh(); assert(not BuffTap.action)")
