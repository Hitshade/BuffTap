from test_warlock_review import test, tests
treasure="""
spell(2481,'Find Treasure'); spell(2383,'Find Herbs')
BuffTap.db.buffs.motw=false; BuffTap.db.buffs.thorns=false
treasureActive=false; herbsActive=true
C_Minimap={GetNumTrackingTypes=function() return 2 end,GetTrackingInfo=function(i)
return {spellID=i==1 and 2383 or 2481,name=i==1 and 'Find Herbs' or 'Find Treasure',type='spell',texture=123,active=i==1 and herbsActive or treasureActive} end}
BuffTap.db.helperTracker=2383
"""
test('Treasure tracking defaults off',treasure+"assert(BuffTap.db.helperTreasure==false); refresh(); assert(not BuffTap.action)")
test('Treasure works independently of gathering toggle',treasure+"BuffTap.db.helperTreasure=true; refresh(); assert(BuffTap.action.id==2481 and BuffTap.button.attrs.spell==2481 and BuffTap.db.helperTracker==2383)")
test('Active treasure tracking needs no reminder',treasure+"BuffTap.db.helperTreasure=true; treasureActive=true; refresh(); assert(not BuffTap.action)")
test('Gathering and treasure each receive a reminder',treasure+"BuffTap.db.helperTreasure=true; BuffTap.db.helperTracking=true; herbsActive=false; refresh(); assert(BuffTap.action.id==2383); herbsActive=true; refresh(); assert(BuffTap.action.id==2481)")
test('Treasure activation before click clears stale action',treasure+"BuffTap.db.helperTreasure=true; refresh(); treasureActive=true; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('Treasure opt-out before click clears stale action',treasure+"BuffTap.db.helperTreasure=true; refresh(); BuffTap.db.helperTreasure=false; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('Treasure control appears only for a learned spell',treasure+"BuffTap:Options(); assert(BuffTap.helperWindow.treasure:IsShown()); assert(#BuffTap:GatheringTrackers()==1 and #BuffTap:GatheringTrackers(true)==2)")
test('Unlearned treasure is not offered',"BuffTap.db.helperTreasure=true; BuffTap:Options(); assert(not BuffTap.helperWindow.treasure:IsShown()); assert(not BuffTap:TrackingAction())")
test('Treasure tracking events refresh independently',treasure+"BuffTap.db.helperTreasure=true; refresh(); treasureActive=true; BuffTap.events.scripts.OnEvent(nil,'MINIMAP_UPDATE_TRACKING'); advance(.2); assert(not BuffTap.action)")
print('ALL',len(tests),'SCENARIOS PASSED')
