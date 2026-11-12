-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
function B:NormalizeVisualOptions()
  local d=self.db
  for key,spec in pairs({optionsScale={1,.65,1.25},nearbyScale={1,.7,1.5},nearbyRows={5,2,40},nearbyWidth={210,180,360},nearbyOpacity={.5,0,1}}) do
    local value=d[key]; if not A.Number(value) then value=spec[1] end
    d[key]=math.max(spec[2],math.min(spec[3],value))
  end
  d.nearbyRows=math.floor(d.nearbyRows+.5); d.nearbyWidth=math.floor(d.nearbyWidth+.5)
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
function B:NearbyLayout()
  local d=self.db; local scale=d.nearbyScale or 1
  local height=A.Call(UIParent and UIParent.GetHeight,UIParent)
  local maximum=A.Number(height) and math.max(2,math.floor((height/scale-72)/21)) or 40
  return d.nearbyWidth or 210,math.min(d.nearbyRows or 5,maximum),scale
end
