from test_bufftap import test, tests
from test_nearby import setup

G=setup+("local B=BuffTap; UnitIsInMyGuild=function(u) return u=='nameplate1' end; "
 "played=0; local lastFile; PlaySoundFile=function(f) played=played+1; lastFile=f; return true end; "
 "B.socialPresent={}; B.socialAlerted={}; B.lastSocialAlert=nil; B.socialReadyAt=nil; "
 "local function scan() B.nearbySnapshot=nil; B:NearbyPlayers(); B:UpdateNearbyWindow() end; ")
test('Friend and guild alert is off by default',"assert(BuffTap.db.nearbySocialAlert==false and BuffTap.db.socialSound=='hello')")
test('Off means no sound for a guildmate',G+"scan(); assert(played==0)")
test('A guildmate showing up plays the friend sound once and lights the row',G+"B.db.nearbySocialAlert=true; scan(); assert(played==1 and lastFile:find('BuffTapHello',1,true)); B:UpdateNearbyWindow(); assert(B.nearbyFrame.rows[1].socialFlash.shown); advance(5); scan(); assert(played==1, 'repeated'); B:UpdateNearbyWindow(); assert(not B.nearbyFrame.rows[1].socialFlash.shown)")
test('Quiet right after a loading screen',G+"B.db.nearbySocialAlert=true; B:SettleSocialAlerts(); scan(); assert(played==0); advance(70); scan(); assert(played==0,'alerted for someone already there')")
test('Coming back after an hour alerts again',G+"B.db.nearbySocialAlert=true; scan(); assert(played==1); advance(3700); scan(); assert(played==2)")
test('No alert in instances or with guild switched off',G+"B.db.nearbySocialAlert=true; IsInInstance=function() return true end; scan(); assert(played==0); IsInInstance=function() return false end; B.socialPresent={}; B.db.nearbySocialGuild=false; scan(); assert(played==0)")
test('Works with the name tags turned off',G+"B.db.nearbySocialAlert=true; B.db.nearbyMarkSocial=false; scan(); assert(played==1)")
test('Friend sound plays while resting and ignores the reminder sound switch',G+"B.db.nearbySocialAlert=true; B.db.sound=false; B.db.pauseResting=true; B.db.nearbyWhileResting=true; IsResting=function() return true end; scan(); assert(played==1)")
test('Binding & sound has the friend sound and its switches',"local B=BuffTap; B:Options(); local f=B.options; assert(f.socialSoundButton and f.socialAlert and f.socialFriends and f.socialGuild); f.socialAlert:SetChecked(true); f.socialAlert.scripts.OnClick(f.socialAlert); assert(B.db.nearbySocialAlert==true)")
test('The friend sound waits until their row is on screen',G+"B.db.nearbySocialAlert=true; B:UpdateNearbyWindow(); played=0; B.socialAlerted={}; B.socialPresent={}; B.socialPending={}; B.lastSocialAlert=nil; local row=B.nearbyFrame.rows[1]; local alpha; rawset(row,'SetAlpha',function(_,a) alpha=a end); B.nearbySnapshot=nil; B:NearbyPlayers(); assert(played==0,'played before shown'); B:UpdateNearbyWindow(); assert(played==1); assert(row.socialFlash.shown and alpha==1, 'glow at full brightness '..tostring(alpha))")
test('A new friend joins a held (hovered) list at the bottom and alerts right away',G+"B.db.nearbySocialAlert=true; B.db.nearbyShowAll=true; B.nearbyHovered='Player-someone'; B.nearbyDisplay={}; scan(); assert(played==1,'no alert'); local found; for i=1,5 do local r=B.nearbyFrame.rows[i]; if r.entry and r.entry.unit=='nameplate1' then found=r end end; assert(found and found.socialFlash.shown,'row not added while held')")
test('Mounted with the all-players view off: the friend sound still plays',G+"B.db.nearbySocialAlert=true; B.db.nearbyShowAll=false; IsMounted=function() return true end; scan(); assert(played==1)")
test('Mounted with the all-players view on: their row (below the pause row) glows',G+"B.db.nearbySocialAlert=true; B.db.nearbyShowAll=true; IsMounted=function() return true end; scan(); assert(played==1); local f=B.nearbyFrame; assert(f.pauseRow and f.pauseRow.shown); assert(f.rows[2].entry and f.rows[2].socialFlash.shown)")
test('A friend who is not listed (needs nothing, buff-only view) still gets the sound',G+"B.db.nearbySocialAlert=true; B.db.nearbyShowAll=false; B.db.nearbyBuffing=false; scan(); assert(played==1)")
test('Stealthed: the friend sound still plays',G+"B.db.nearbySocialAlert=true; IsStealthed=function() return true end; scan(); assert(played==1)")
