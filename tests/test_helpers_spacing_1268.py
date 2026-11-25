from test_bufftap import test,ROOT
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
for cls in ('DRUID','WARLOCK','HUNTER','PALADIN'):
 for locale in ('enUS','deDE'):
  test('Helpers card separation '+cls+' '+locale,RECORD+"""
playerClass='"""+cls+"""'; BuffTap:Options(); local f=BuffTap.helperWindow
local function y(c) local p=c.__draw.points[#c.__draw.points]; return p[3] end
-- 1.28 order: Solo thanks (art), Buff requests, Conveniences, then the Class helpers pointer card, all 8 apart.
local function bottom(c,section) return y(section)+y(c)-c.__draw.h end
local thanksTop=y(f.helperSections.thanks)+y(f.thanksCard)
local thanksBottom=bottom(f.thanksCard,f.helperSections.thanks)
local requestTop=y(f.helperSections.requests)+y(f.requestCard)
local requestBottom=bottom(f.requestCard,f.helperSections.requests)
local convTop=y(f.helperSections.grid)+y(f.conveniencesCard)
local convBottom=bottom(f.conveniencesCard,f.helperSections.grid)
local pointerTop=y(f.classHelpersCard)
assert(thanksBottom-requestTop==8,'thanks/request gap '..tostring(thanksBottom-requestTop))
assert(requestBottom-convTop==8,'request/conveniences gap')
assert(convBottom-pointerTop==8,'conveniences/pointer gap')
assert(f.thanksCard.__draw.w==692 and f.requestCard.__draw.w==692 and f.conveniencesCard.__draw.w==692,'full width cards')
assert(pointerTop-f.classHelpersCard.__draw.h>=-722,'footer clearance')
assert(f.thanksScene and f.thanksScene.optionsDecoration==true and f.thanksSceneEdge,'thanks art')
assert(y(f.thankEmote)>y(f.thankDelay) and y(f.thankDelay)>y(f.thankMessage),'emote, then delay, then the full-width message')
assert(f.thankMessage.__draw.w>=350,'message spans the bottom')
local mp=f.thankMessage.__draw.points[#f.thankMessage.__draw.points]; local rp=f.thankMessageReset.__draw.points[#f.thankMessageReset.__draw.points]
assert(rp[2]-(mp[2]+f.thankMessage.__draw.w)==8,'message and Reset gap')
local p=f.providerSort.__draw.points[#f.providerSort.__draw.points]
assert(p[2]==484 and p[3]==-456 and f.providerSort:GetParent()==f.requests)
assert(f.dismissMinutes.__draw.points[#f.dismissMinutes.__draw.points][2]+f.dismissMinutes.__draw.w==690,'dismiss right edge')
assert(f.requestMessage.__draw.points[#f.requestMessage.__draw.points][2]+f.requestMessage.__draw.w==690,'message right edge')
local bp=f.classHelpersOpen.__draw.points[#f.classHelpersOpen.__draw.points]
assert(bp[3]-y(f.classHelpersCard)==-26,'pointer button sits clear of the title hairline')
assert((f.readiness:IsShown()==true)==(playerClass~='DRUID'))
""",locale)
