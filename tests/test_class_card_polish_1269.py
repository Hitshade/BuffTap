from test_bufftap import test, ROOT
RECORD=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
for cls in ('DRUID','MAGE','PRIEST','PALADIN','WARRIOR','HUNTER','SHAMAN','WARLOCK','ROGUE'):
 for mode in ('class','custom'):
  test('Uniform card and Nearby geometry '+cls+' '+mode,RECORD+"playerClass='"+cls+"'; local B=BuffTap; B:InitDB(); B.db.optionsAccentMode='"+mode+"'; B.db.optionsAccentColor='29b7ca'; B:Options(); "+"""
local f=B.options; local r,g,b=B:InterfaceAccent()
local function pos(o) local p=o.__draw.points[1]; return p[2],p[3] end
local function accent(o)
 assert(o.optionsSection,'missing section treatment')
 local v=o.__draw.color; assert(v and math.abs(v[1]-r)<.001 and math.abs(v[2]-g)<.001 and math.abs(v[3]-b)<.001,'wrong initial accent')
end
local function card(o,title,body,primary,secondary)
 local x,y=pos(o); assert(x==12 and y==-84 and o.__draw.w==692 and o.__draw.h==172,'inconsistent card')
 x,y=pos(title); assert(x==28 and y==-104); accent(title)
 x,y=pos(body); assert(x==28 and y==-136)
 x,y=pos(primary); assert(x==28 and y==-206)
 x,y=pos(secondary); assert(x==188 and y==-206)
end
for _,i in ipairs({1,3}) do local box=f.pages[i].classEmpty; if box.shown then card(box.infoCard,box.infoTitle,box.infoText,box.primary,box.nearby) end end
if f.groupInfo and f.groupInfo.shown then
 assert(f.groupInfo:GetParent()==f.pages[2],'extra canvas offset')
 card(f.groupInfoCard,f.groupInfoTitle,f.groupInfoText,f.groupWeapons,f.groupNearby)
end
if not B:NearbyCapabilities().actions then
 local x,y=pos(f.nearbyAll); assert(x==26 and y==-112)
 x,y=pos(f.nearbyFullNames); assert(x==26 and y==-140)
 x,y=pos(f.nearbyShowLevel); assert(x==26 and y==-168)
 x,y=pos(f.nearbyInvites); assert(x==374 and y==-112)
 x,y=pos(f.nearbyMarkSocial); assert(x==374 and y==-140)
 x,y=pos(f.nearbyClassHint); assert(x==28 and y==-224 and f.nearbyClassHint.__draw.w==656)
 x,y=pos(f.nearbyGuideCard); assert(x==12 and y==-252)
 B.db.nearbyGuideOpen=true; B:UpdateClassAwarePages(); do local gx,gy=pos(f.nearbyGuideCard); assert(-gy+f.nearbyGuideCard.__draw.h<=720,'open How Nearby works card reaches the footer: '..tostring(-gy+f.nearbyGuideCard.__draw.h)) end; B.db.nearbyGuideOpen=false; B:UpdateClassAwarePages()
 x,y=pos(f.nearbyGuide); assert(x==26 and y==-292)
end
B:Options()
if f.groupInfo and f.groupInfo.shown then accent(f.groupInfoTitle) end
""")
