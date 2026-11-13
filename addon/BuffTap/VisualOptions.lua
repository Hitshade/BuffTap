-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
function B:NormalizeVisualOptions()
  local d=self.db
  -- 1.19.2: Nearby shows full names (first name and surname) by default, so the old 210 px default widens once to 240.
  if d.nearbyNameVersion~=1 then
    if d.nearbyWidth==nil or d.nearbyWidth==210 then d.nearbyWidth=240 end
    d.nearbyNameVersion=1
  end
  if type(d.nearbyFullNames)~="boolean" then d.nearbyFullNames=true end
  if type(d.nearbyFont)~="string" or d.nearbyFont=="" then d.nearbyFont="default" end
  local fontKeys={default=true,arialn=true,morpheus=true,skurri=true,names=true,numbers=true}
  if not fontKeys[d.nearbyFont] and not d.nearbyFont:match("^lsm:.") then d.nearbyFont="default" end
  if d.nearbyFont=="names" or d.nearbyFont=="numbers" then d.nearbyFont=self.NormalizeTextFontKey and self:NormalizeTextFontKey(d.nearbyFont) or "default" end
  if type(d.nearbyShowLevel)~="boolean" then d.nearbyShowLevel=false end
  d.nearbyFontSize=A.Number(d.nearbyFontSize) and (d.nearbyFontSize==0 and 0 or math.max(8,math.min(20,math.floor(d.nearbyFontSize)))) or 0
  if not ({none=true,outline=true,thick=true})[d.nearbyFontOutline] then d.nearbyFontOutline="none" end
  for key,spec in pairs({optionsScale={1,.65,1.25},nearbyScale={1,.7,1.5},nearbyRows={5,2,40},nearbyWidth={240,180,360},nearbyOpacity={.5,0,1}}) do
    local value=d[key]; if not A.Number(value) then value=spec[1] end
    d[key]=math.max(spec[2],math.min(spec[3],value))
  end
  d.nearbyRows=math.floor(d.nearbyRows+.5); d.nearbyWidth=math.floor(d.nearbyWidth+.5)
  -- New installs start with the class colour; a saved choice (gold, class or custom) is kept.
  if d.optionsAccentMode==nil then d.optionsAccentMode="class" end
  if d.optionsAccentMode~="class" and d.optionsAccentMode~="custom" then d.optionsAccentMode="gold" end
  if type(d.optionsAccentColor)~="string" or not d.optionsAccentColor:match("^%x%x%x%x%x%x$") then d.optionsAccentColor="75c8da" end
  if type(d.optionsPatchDot)~="boolean" then d.optionsPatchDot=true end
  if type(d.optionsReduceMotion)~="boolean" then d.optionsReduceMotion=false end
end
function B:InterfaceAccent()
  local d=self.db or {}; local r,g,b=.91,.71,.36
  if d.optionsAccentMode=="class" then
    local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[A.Class("player")]
    if c then r,g,b=c.r,c.g,c.b end
  elseif d.optionsAccentMode=="custom" then
    local hex=d.optionsAccentColor or "75c8da"
    r,g,b=(tonumber(hex:sub(1,2),16) or 117)/255,(tonumber(hex:sub(3,4),16) or 200)/255,(tonumber(hex:sub(5,6),16) or 218)/255
  end
  local function lum(v) return v<=.04045 and v/12.92 or ((v+.055)/1.055)^2.4 end
  for _=1,32 do
    if (.2126*lum(r)+.7152*lum(g)+.0722*lum(b)+.05)/.064>=4.5 then break end
    r,g,b=math.min(1,r+.032),math.min(1,g+.032),math.min(1,b+.032)
  end
  return r,g,b
end
-- Nearby list text: the game's standard font at 11 px with no outline unless the player picks otherwise.
local NEARBY_OUTLINES={none="",outline="OUTLINE",thick="THICKOUTLINE"}
-- The game's four built-in faces, plus any font a SharedMedia pack registers.
local BUILTIN_FONTS={{key="arialn",name="Arial Narrow",path="Fonts\\ARIALN.TTF"},{key="morpheus",name="Morpheus",path="Fonts\\MORPHEUS.TTF"},{key="skurri",name="Skurri",path="Fonts\\SKURRI.TTF"}}
local function sharedMedia()
  local ok,lib=pcall(function() return LibStub and LibStub("LibSharedMedia-3.0",true) end)
  if ok and type(lib)=="table" and type(lib.List)=="function" and type(lib.Fetch)=="function" then return lib end
end
-- Draw a menu row's or a box's text in a font choice's own font; with no font, back to the
-- theme's font. Buttons re-apply their font objects on hover, so the font goes into copies of
-- the button's own normal/highlight/disabled font objects rather than onto the text directly.
local previewFonts,previewCount={},0
local function previewObject(base,path)
  if (type(base)~="table" and type(base)~="userdata") or type(CreateFont)~="function" then return nil end
  local id=tostring(base)..path
  local obj=previewFonts[id]
  if not obj then
    previewCount=previewCount+1
    obj=CreateFont("BuffTapFontPreview"..previewCount)
    if obj.CopyFontObject then obj:CopyFontObject(base) end
    local _,size,flags=base:GetFont()
    if not pcall(obj.SetFont,obj,path,A.Number(size) and size or 13,flags or "") then return nil end
    previewFonts[id]=obj
  end
  return obj
end
function B:PreviewChoiceFont(button,path)
  if not button or type(button.GetNormalFontObject)~="function" then return end
  if not button.choiceBase then
    button.choiceBase={normal=button:GetNormalFontObject(),highlight=button.GetHighlightFontObject and button:GetHighlightFontObject(),disabled=button.GetDisabledFontObject and button:GetDisabledFontObject()}
  end
  local base=button.choiceBase
  if button.choiceFont==path then return end
  if type(path)=="string" and path~="" then
    local normal=previewObject(base.normal,path)
    if normal then
      button:SetNormalFontObject(normal)
      if base.highlight and button.SetHighlightFontObject then button:SetHighlightFontObject(previewObject(base.highlight,path) or normal) end
      if base.disabled and button.SetDisabledFontObject then button:SetDisabledFontObject(previewObject(base.disabled,path) or normal) end
      button.choiceFont=path; return
    end
  end
  if button.choiceFont then
    if base.normal then button:SetNormalFontObject(base.normal) end
    if base.highlight and button.SetHighlightFontObject then button:SetHighlightFontObject(base.highlight) end
    if base.disabled and button.SetDisabledFontObject then button:SetDisabledFontObject(base.disabled) end
  end
  button.choiceFont=nil
end
-- The font file behind a font choice, so menus can show each name in its own font.
function B:FontPathForKey(key)
  local path=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  if key=="names" and type(UNIT_NAME_FONT)=="string" then return UNIT_NAME_FONT end
  if key=="numbers" and type(DAMAGE_TEXT_FONT)=="string" then return DAMAGE_TEXT_FONT end
  if type(key)=="string" and key:match("^lsm:") then
    local lsm=sharedMedia()
    if lsm then local ok,p=pcall(lsm.Fetch,lsm,"font",key:sub(5),true); if ok and type(p)=="string" and p~="" then return p end end
    return path
  end
  for _,f in ipairs(BUILTIN_FONTS) do if f.key==key then return f.path end end
  return path
end
function B:NearbyFonts()
  local choices={{key="default",name=self.GameFontLabel and self:GameFontLabel() or "Game font"}}
  for _,f in ipairs(BUILTIN_FONTS) do choices[#choices+1]={key=f.key,name=f.name} end
  if type(UNIT_NAME_FONT)=="string" and self.NormalizeTextFontKey and self:NormalizeTextFontKey("names")=="names" then choices[#choices+1]={key="names",name="Unit-name font"} end
  if type(DAMAGE_TEXT_FONT)=="string" and self.NormalizeTextFontKey and self:NormalizeTextFontKey("numbers")=="numbers" then choices[#choices+1]={key="numbers",name="Combat-number font"} end
  local lsm=sharedMedia()
  if lsm then
    local ok,list=pcall(lsm.List,lsm,"font")
    local seen={["Friz Quadrata TT"]=true,["Arial Narrow"]=true,["Morpheus"]=true,["Skurri"]=true}
    if ok and type(list)=="table" then
      for _,name in ipairs(list) do if type(name)=="string" and not seen[name] then seen[name]=true; choices[#choices+1]={key="lsm:"..name,name=name} end end
    end
  end
  local d=self.db or {}
  if type(d.nearbyFont)=="string" and d.nearbyFont:match("^lsm:") then
    local found=false; for _,c in ipairs(choices) do if c.key==d.nearbyFont then found=true end end
    if not found then choices[#choices+1]={key=d.nearbyFont,name=self:Text("%s (not installed)",d.nearbyFont:sub(5)),missing=true} end
  end
  for _,c in ipairs(choices) do if not c.missing then c.font=self:FontPathForKey(c.key) end end
  return choices
end
function B:NearbyFont()
  local d=self.db or {}
  local path=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  local key=d.nearbyFont
  if key=="names" and type(UNIT_NAME_FONT)=="string" then path=UNIT_NAME_FONT
  elseif key=="numbers" and type(DAMAGE_TEXT_FONT)=="string" then path=DAMAGE_TEXT_FONT
  elseif type(key)=="string" and key:match("^lsm:") then
    local lsm=sharedMedia()
    if lsm then local ok,p=pcall(lsm.Fetch,lsm,"font",key:sub(5),true); if ok and type(p)=="string" and p~="" then path=p end end
  else for _,f in ipairs(BUILTIN_FONTS) do if f.key==key then path=f.path end end end
  local size=A.Number(d.nearbyFontSize) and d.nearbyFontSize>0 and d.nearbyFontSize or 11
  return path,size,NEARBY_OUTLINES[d.nearbyFontOutline] or ""
end
-- Rows grow with larger text so names are never clipped; 21 px fits the default 11 px font.
function B:NearbyRowHeight()
  local _,size=self:NearbyFont()
  return math.max(21,size+10)
end
function B:NearbyTextSizes()
  local choices={{key=0,name=self:Text("Default (11 px)")}}
  for i=8,20 do choices[#choices+1]={key=i,name=tostring(i).." px"} end
  return choices
end
function B:NearbyLayout()
  local d=self.db; local scale=d.nearbyScale or 1
  local height=A.Call(UIParent and UIParent.GetHeight,UIParent)
  local maximum=A.Number(height) and math.max(2,math.floor((height/scale-72)/self:NearbyRowHeight())) or 40
  return d.nearbyWidth or 240,math.min(d.nearbyRows or 5,maximum),scale
end
