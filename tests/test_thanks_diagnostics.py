from test_directed_thanks import test,observed,solo

test('Thanks diagnostics show Warrior settings and current activity without extra gates',solo+"playerClass='WARRIOR'; BuffTap.db.helperThanksResting=true; BuffTap.db.helperThankDelay=2; UnitCastingInfo=function() return 'Fishing' end; local lines=table.concat(BuffTap:SoloThanksDiagnostics(),' '); assert(lines:find('class=WARRIOR',1,true) and lines:find('while resting=true',1,true) and lines:find('delay=2',1,true) and lines:find('casting=active',1,true)); assert(BuffTap:SoloThanksAllowed())")

test('Unresolved caster diagnostics link lookup to spell and retry window',observed+"BuffTap:ObserveSoloThanks(); local text=table.concat(BuffTap:DiagnosticsLines(),' '); assert(text:find('spell=1459',1,true) and text:find('result=no live match',1,true) and text:find('known caster IDs: 1',1,true)); assert(text:find('Player-Driveby',1,true)==nil)")

test('Status ages are distinguishable from fresh observations',observed+"BuffTap:ObserveSoloThanks(); local at=BuffTap.thanksStatusAt; advance(.3); BuffTap:ObserveSoloThanks(); assert(BuffTap.thanksStatusAt==at and BuffTap.thanksObservedAt>at); local text=table.concat(BuffTap:SoloThanksDiagnostics(),' '); assert(text:find('Thanks status changed:',1,true) and text:find('last observation:',1,true))")

test('Thanks timeout is retained in bounded history without names or GUIDs',observed+"BuffTap:ObserveSoloThanks(); for i=1,60 do advance(.21) end; local text=table.concat(BuffTap:SoloThanksDiagnostics(),' '); assert(text:find('10s window expired',1,true)); assert(not text:find('Player-Driveby',1,true)); for i=1,40 do BuffTap:ThanksTrace('test','event '..i) end; assert(#BuffTap.thanksTrace==12)")

test('Actual emote API attempt is recorded separately from eligibility',solo+"received(1459,'target'); local text=table.concat(BuffTap:SoloThanksDiagnostics(),' '); assert(#emotes==1 and text:find('emote API attempted',1,true) and text:find('DoEmote',1,true)); assert(not text:find('Ally',1,true))")

test('Hidden-name reports anonymize an arbitrary profile label',solo+"assert(BuffTap:CreateSettingsProfile('Private Profile Label',true)); local text=BuffTap:ReportText('debug',true); assert(text:find('Thanks context:',1,true) and not text:find('Private Profile Label',1,true))")

test('Debug and full checkup both include detailed thanks observations',observed+"BuffTap:ObserveSoloThanks(); local debug=BuffTap:ReportText('debug',true); local full=BuffTap:ReportText('checkup',true); assert(debug:find('Thanks caster lookup:',1,true)); assert(full:find('Thanks settings:',1,true) and full:find('Thanks recent:',1,true))")

test('Unreadable activity APIs are diagnostic only and stay safe',solo+"UnitCastingInfo=function() error('restricted') end; UnitChannelInfo=function() return {secret=true} end; local text=table.concat(BuffTap:SoloThanksDiagnostics(),' '); assert(text:find('casting=unreadable',1,true) and text:find('channeling=unreadable',1,true)); received(1459,'target'); assert(#emotes==1)")

test('Thanks caster lookup records native and group result paths',solo+"local B=BuffTap; local guid=UnitGUID('party1'); UnitTokenFromGUID=function() return 'party1' end; assert(B:FindCasterUnit(guid)=='party1' and B.thanksLookup.result=='native token'); UnitTokenFromGUID=nil; IsInGroup=function() return true end; GetNumSubgroupMembers=function() return 2 end; assert(B:FindCasterUnit(guid)=='party1' and B.thanksLookup.result=='group unit')")

test('Thanks diagnostics tolerate unavailable class identity',solo+"UnitClass=function() return nil end; local text=table.concat(BuffTap:SoloThanksDiagnostics(),' '); assert(text:find('class=nil',1,true))")
