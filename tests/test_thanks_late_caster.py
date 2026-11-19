from test_directed_thanks import test,observed,solo

test('Known caster appearing after two seconds is thanked exactly once',observed+"local old=UnitGUID; BuffTap:ObserveSoloThanks(); for i=1,16 do advance(.21) end; assert(#emotes==0 and BuffTap.helperThankRetryPending); UnitGUID=function(u) return u=='target' and 'Player-Driveby' or old(u) end; for i=1,4 do advance(.51) end; assert(#emotes==1 and emotes[1][2]=='target'); for i=1,25 do advance(.51) end; assert(#emotes==1)")

test('Known caster appearing after the ten-second window is not thanked',observed+"local old=UnitGUID; BuffTap:ObserveSoloThanks(); for i=1,55 do advance(.21) end; assert(not BuffTap.helperThankRetryPending and #emotes==0); UnitGUID=function(u) return u=='target' and 'Player-Driveby' or old(u) end; BuffTap:ObserveSoloThanks(); assert(#emotes==0)")

test('Late target with the wrong caster identity is never thanked',observed+"BuffTap:ObserveSoloThanks(); for i=1,60 do advance(.21) end; assert(#emotes==0 and not BuffTap.helperThankRetryPending)")

test('Combat cancels extended pending caster resolution',observed+"BuffTap:ObserveSoloThanks(); for i=1,12 do advance(.21) end; combat=true; BuffTap:HelperEvent('PLAYER_REGEN_DISABLED'); for i=1,25 do advance(.51) end; assert(#emotes==0 and not BuffTap.helperThankRetryPending)")

test('Thanks disabled during extended wait cannot send later',observed+"BuffTap:ObserveSoloThanks(); for i=1,12 do advance(.21) end; BuffTap.db.helperThanks=false; for i=1,25 do advance(.51) end; assert(#emotes==0 and not BuffTap.helperThankRetryPending)")

test('Initial unresolved baseline is not thanked when its caster appears later',solo+"C_UnitAuras.GetAuraCasterGUID=function() return 'Player-Driveby' end; auras.player={{spellId=1459,auraInstanceID=88}}; BuffTap:ObserveSoloThanks(true); local old=UnitGUID; UnitGUID=function(u) return u=='target' and 'Player-Driveby' or old(u) end; BuffTap:ObserveSoloThanks(); assert(#emotes==0)")

test('Delayed thanks can rebind the same player to a different live token',solo+"received(1459,'target'); received(1243,'party1'); local guid=UnitGUID('party1'); local oldG,oldN,oldE=UnitGUID,UnitName,UnitExists; UnitExists=function(u) return u=='focus' or oldE(u) end; UnitGUID=function(u) if u=='party1' then return 'Player-Bystander' elseif u=='focus' then return guid end return oldG(u) end; UnitName=function(u) if u=='focus' then return 'Other' end return oldN(u) end; advance(1.1); assert(#emotes==2 and emotes[2][2]=='focus')")
