from test_bufftap import test,ROOT
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
for cls in ('DRUID','WARLOCK','HUNTER','PALADIN'):
 for locale in ('enUS','deDE'):
  test('Helpers card separation '+cls+' '+locale,RECORD+"""
playerClass='"""+cls+"""'; BuffTap:Options(); local f=BuffTap.helperWindow
local function y(c) local p=c.__draw.points[#c.__draw.points]; return p[3] end
local requestTop=y(f.helperSections.requests)+y(f.requestCard)
local requestBottom=requestTop-f.requestCard.__draw.h
local trackingTop=y(f.helperSections.tracking)+y(f.trackerCard)
local trackingBottom=trackingTop-f.trackerCard.__draw.h
local readyTop=y(f.readiness)+y(f.readinessCard)
assert(requestBottom>=trackingTop+10,'request/tracking overlap')
assert(trackingBottom>=readyTop+12,'tracking/readiness spacing')
assert(y(f.thankEmote)==y(f.dismissMinutes) and y(f.thankDelay)==y(f.dismissMinutes),'bottom controls misaligned')
local p=f.providerSort.__draw.points[#f.providerSort.__draw.points]
assert(p[2]>=374 and p[3]==-306 and f.providerSort:GetParent()==f.requests)
assert((f.readiness:IsShown()==true)==(playerClass~='DRUID'))
""",locale)
