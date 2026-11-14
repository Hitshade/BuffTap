from test_bufftap import test, tests
from test_nearby import setup

G=setup+("local B=BuffTap; UnitIsInMyGuild=function(u) return u=='nameplate1' end; "
 "played=0; local lastFile; PlaySoundFile=function(f) played=played+1; lastFile=f; return true end; "
 "B.socialPresent={}; B.socialAlerted={}; B.lastSocialAlert=nil; B.socialReadyAt=nil; "
 "local function scan() B.nearbySnapshot=nil; B:NearbyPlayers() end; ")
test('Friend and guild alert is off by default',"assert(BuffTap.db.nearbySocialAlert==false and BuffTap.db.socialSound=='hello')")
test('Off means no sound for a guildmate',G+"scan(); assert(played==0)")
test('A guildmate showing up plays the friend sound once and lights the row',G+"B.db.nearbySocialAlert=true; scan(); assert(played==1 and lastFile:find('BuffTapHello',1,true)); B:UpdateNearbyWindow(); assert(B.nearbyFrame.rows[1].socialFlash.shown); advance(5); scan(); assert(played==1, 'repeated'); B:UpdateNearbyWindow(); assert(not B.nearbyFrame.rows[1].socialFlash.shown)")
test('Quiet right after a loading screen',G+"B.db.nearbySocialAlert=true; B:SettleSocialAlerts(); scan(); assert(played==0); advance(70); scan(); assert(played==0,'alerted for someone already there')")
test('Coming back after an hour alerts again',G+"B.db.nearbySocialAlert=true; scan(); assert(played==1); advance(3700); scan(); assert(played==2)")
test('No alert in instances or with guild switched off',G+"B.db.nearbySocialAlert=true; IsInInstance=function() return true end; scan(); assert(played==0); IsInInstance=function() return false end; B.socialPresent={}; B.db.nearbySocialGuild=false; scan(); assert(played==0)")
test('Works with the name tags turned off',G+"B.db.nearbySocialAlert=true; B.db.nearbyMarkSocial=false; scan(); assert(played==1)")
test('Friend sound plays while resting and ignores the reminder sound switch',G+"B.db.nearbySocialAlert=true; B.db.sound=false; B.db.pauseResting=true; B.db.nearbyWhileResting=true; IsResting=function() return true end; scan(); assert(played==1)")
test('Binding & sound has the friend sound and its switches',"local B=BuffTap; B:Options(); local f=B.options; assert(f.socialSoundButton and f.socialAlert and f.socialFriends and f.socialGuild); f.socialAlert:SetChecked(true); f.socialAlert.scripts.OnClick(f.socialAlert); assert(B.db.nearbySocialAlert==true)")
