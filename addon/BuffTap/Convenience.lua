-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
local _,B=...
local A=B.API
local ICON="Interface\\AddOns\\BuffTap\\Media\\BuffTapIcon"
-- Shared image artwork: 512x256 RGB TGA, cropped with native texture coordinates.
-- The source is resized for format conversion; coordinates remove its dark vertical padding.
function B:AddMiniBanner(parent,width)
  local h=CreateFrame("Frame",nil,parent)
  local artWidth=math.min(600,width-32)
  local height=artWidth*420/2043
  h:SetPoint("TOPLEFT",8,-8); h:SetSize(width-16,height)
  h.background=h:CreateTexture(nil,"BACKGROUND"); h.background:SetAllPoints(); h.background:SetColorTexture(0,0,0,0) -- the art is keyed, so the window colour shows through
  h.art=h:CreateTexture(nil,"ARTWORK"); h.art:SetPoint("TOPLEFT",8,0); h.art:SetSize(artWidth,height)
  h.artWidth=artWidth; h.artHeight=height
  h.art:SetTexture("Interface\\AddOns\\BuffTap\\Media\\BuffTapMiniBanner.tga")
  h.art:SetTexCoord(0,1,176/770,596/770)
  return h
end
local colors={default={1,1,1},gold={1,.82,.1},cyan={.4,.9,1},green={.45,1,.65},red={1,.3,.25},white={1,1,1}}
function B:BaseTextFont(fontObject)
  local object=type(fontObject)=="string" and _G[fontObject] or fontObject
  if object and type(object.GetFont)=="function" then
    local ok,path,size,flags=pcall(object.GetFont,object)
    if ok and type(path)=="string" and A.Number(size) and size>0 then return path,size,type(flags)=="string" and flags or "" end
  end
end
function B:GameFontLabel()
  local path=self:BaseTextFont("GameFontHighlightSmall")
  if not path then return self:Text("Game UI font") end
  local face=path:match("([^/\\]+)%.[^%.]+$") or path
  face=({FRIZQT__="Friz Quadrata",ARIALN="Arial Narrow",MORPHEUS="Morpheus",SKURRI="Skurri"})[face:upper()] or face
  return self:Text("Game font: %s",face)
end
function B:TextSizeLabel(value)
  if A.Number(value) and value>0 then return tostring(value).." px" end
  local _,size=self:BaseTextFont("GameFontHighlightSmall")
  return size and self:Text("Game: %s px",tostring(size)) or self:Text("Game size")
end
function B:GameTextOutline()
  local _,_,flags=self:BaseTextFont("GameFontHighlightSmall")
  if flags and flags:find("THICKOUTLINE",1,true) then return "thick" end
  if flags and flags:find("OUTLINE",1,true) then return "outline" end
  return "none"
end
local function sameFont(a,b)
  return type(a)=="string" and type(b)=="string" and a:lower():gsub("/","\\")==b:lower():gsub("/","\\")
end
function B:NormalizeTextFontKey(key)
  if key~="names" and key~="numbers" then return "default" end
  -- Not an and/or chain: a missing UNIT_NAME_FONT must not fall through to the combat-number font.
  local path; if key=="names" then path=UNIT_NAME_FONT else path=DAMAGE_TEXT_FONT end
  local game=self:BaseTextFont("GameFontHighlightSmall")
  if sameFont(path,game) then return "default" end
  if key=="numbers" and sameFont(path,UNIT_NAME_FONT) then return "names" end
  return key
end
function B:ReminderFonts(selected)
  local choices={{key="default",name=self:GameFontLabel()}}
  if type(UNIT_NAME_FONT)=="string" and self:NormalizeTextFontKey("names")=="names" then choices[#choices+1]={key="names",name="Unit-name font"} end
  if type(DAMAGE_TEXT_FONT)=="string" and self:NormalizeTextFontKey("numbers")=="numbers" then choices[#choices+1]={key="numbers",name="Combat-number font"} end
  selected=selected or (self.db and self.db.labelFont)
  if selected=="names" and type(UNIT_NAME_FONT)~="string" then choices[#choices+1]={key="names",name="Unit-name font (unavailable)"} end
  if selected=="numbers" and type(DAMAGE_TEXT_FONT)~="string" then choices[#choices+1]={key="numbers",name="Combat-number font (unavailable)"} end
  return choices
end
function B:ReminderColors(uniform)
  local choices={}
  if not uniform then choices[#choices+1]={key="default",name="Text: white + gold count"} end
  for _,entry in ipairs({{key="gold",name="Text: gold"},{key="cyan",name="Text: cyan"},{key="green",name="Text: green"},{key="red",name="Text: red"},{key="white",name="Text: white"}}) do choices[#choices+1]=entry end
  return choices
end
function B:NormalizeConvenience()
  local d=self.db
  d.labelFont=self:NormalizeTextFontKey(d.labelFont)
  if not colors[d.labelColor] then d.labelColor="default" end
  d.labelSize=A.Number(d.labelSize) and (d.labelSize==0 and 0 or math.max(8,math.min(20,math.floor(d.labelSize)))) or 0
  d.labelGap=A.Number(d.labelGap) and math.max(0,math.min(20,math.floor(d.labelGap))) or 5
  if not ({none=true,outline=true,thick=true})[d.labelOutline] then d.labelOutline=self:GameTextOutline() end
  if type(d.welcomeSeen)~="boolean" then d.welcomeSeen=false end
  if d.iconStyle~="modern" then d.iconStyle="classic" end
  if d.campIconStyle~="modern" then d.campIconStyle="classic" end
  if d.labelPosition~="above" and d.labelPosition~="below" then d.labelPosition="split" end
  for _,key in ipairs({"showSwipe","showOutOfRange","helperThanksResting","nearbyRequests"}) do if type(d[key])~="boolean" then d[key]=false end end
  if d.nearbyButtonSide~="right" then d.nearbyButtonSide="left" end
  -- Players who already use Nearby have seen what it does; the introduction is for first-time use.
  if d.nearbyEnabled==true then d.nearbyIntroSeen=true end
  if type(d.requestMessage)~="string" or #d.requestMessage>200 then d.requestMessage="" end
  for key,value in pairs(d.requestBuffs) do if type(key)~="string" or type(value)~="boolean" then d.requestBuffs[key]=nil end end
end
-- Icon styles. Classic shows the game's full icon art (its bevelled frame included). Modern crops the bevel
-- and draws a crisp dark edge, like a typical modern action bar.
function B:IconStyleChoices() return {{key="classic",name="Classic"},{key="modern",name="Modern square"}} end
local function hairlines(owner,anchor,inset,layer,sub)
  local lines={}
  for i=1,4 do local t=owner:CreateTexture(nil,layer,nil,sub); t:SetColorTexture(1,1,1,1); lines[i]=t end
  lines[1]:SetPoint("TOPLEFT",anchor,"TOPLEFT",-inset,inset); lines[1]:SetPoint("TOPRIGHT",anchor,"TOPRIGHT",inset,inset); lines[1]:SetHeight(1)
  lines[2]:SetPoint("BOTTOMLEFT",anchor,"BOTTOMLEFT",-inset,-inset); lines[2]:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",inset,-inset); lines[2]:SetHeight(1)
  lines[3]:SetPoint("TOPLEFT",anchor,"TOPLEFT",-inset,inset); lines[3]:SetPoint("BOTTOMLEFT",anchor,"BOTTOMLEFT",-inset,-inset); lines[3]:SetWidth(1)
  lines[4]:SetPoint("TOPRIGHT",anchor,"TOPRIGHT",inset,inset); lines[4]:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",inset,-inset); lines[4]:SetWidth(1)
  return lines
end
function B:ApplyIconStyle(frame,texture,style)
  if not frame or not texture then return end
  local modern=style=="modern"
  if modern then texture:SetTexCoord(.08,.92,.08,.92) else texture:SetTexCoord(0,1,0,1) end
  if modern and not frame.modernFrame then
    frame.modernFrame={outer=hairlines(frame,texture,1,"OVERLAY",6),inner=hairlines(frame,texture,0,"OVERLAY",7)}
  end
  if frame.modernFrame then
    for _,t in ipairs(frame.modernFrame.outer) do t:SetVertexColor(0,0,0,1); t:SetShown(modern) end
    for _,t in ipairs(frame.modernFrame.inner) do t:SetVertexColor(0,0,0,.55); t:SetShown(modern) end
  end
end
function B:TextSizeChoices()
  local choices={{key=0,name=self:TextSizeLabel(0)}}
  for i=8,20 do choices[#choices+1]={key=i,name=tostring(i).." px"} end
  return choices
end
function B:TextOutlineChoices()
  return {{key="none",name="Outline: none"},{key="outline",name="Outline: thin"},{key="thick",name="Outline: thick"}}
end
local outlines={none="",outline="OUTLINE",thick="THICKOUTLINE"}
local fallbackFonts=setmetatable({},{__mode="k"})
function B:ApplyLabelStyle(fs,settings,fontObject,defaultColor)
  if not fs then return end
  fs:SetFontObject(fontObject or "GameFontHighlightSmall")
  local path,size,flags=self:BaseTextFont(fontObject or "GameFontHighlightSmall")
  if not path then
    local base=fallbackFonts[fs]
    if not base then
      local p,s,f=fs:GetFont()
      if type(p)=="string" and A.Number(s) then base={p,s,f or ""}; fallbackFonts[fs]=base end
    end
    if base then path,size,flags=base[1],base[2],base[3] end
  end
  local chosen=settings.labelFont=="names" and UNIT_NAME_FONT or settings.labelFont=="numbers" and DAMAGE_TEXT_FONT
  if type(chosen)=="string" then path=chosen end
  if A.Number(settings.labelSize) and settings.labelSize>0 then size=settings.labelSize end
  local outline=outlines[settings.labelOutline]
  if outline~=nil then flags=outline end
  if type(path)=="string" and A.Number(size) then fs:SetFont(path,size,flags or "") end
  local col=settings.labelColor=="default" and defaultColor or colors[settings.labelColor]
  col=col or colors.default
  fs:SetTextColor(col[1],col[2],col[3])
end
function B:ApplyReminderStyle(frame)
  local d=self.db
  for _,entry in ipairs({{frame.nameLabel,"GameFontHighlightSmall"},{frame.label or frame.recipient,"GameFontHighlightSmall"},{frame.timerLabel or frame.timer,"GameFontHighlightSmall"},{frame.groupLabel or frame.count,"GameFontNormalSmall"}}) do
    self:ApplyLabelStyle(entry[1],d,entry[2],(entry[1]==frame.groupLabel or entry[1]==frame.count) and colors.gold or nil)
  end
  local gap=d.labelGap or 5
  local name=frame.nameLabel; local recipient=frame.label or frame.recipient
  -- Split: buff name above, recipient below. Above / below stack both labels on one side, name first.
  if d.labelPosition=="above" and name and recipient then
    recipient:ClearAllPoints(); recipient:SetPoint("BOTTOM",frame,"TOP",0,gap)
    name:ClearAllPoints(); name:SetPoint("BOTTOM",recipient,"TOP",0,2)
  elseif d.labelPosition=="below" and name and recipient then
    name:ClearAllPoints(); name:SetPoint("TOP",frame,"BOTTOM",0,-gap)
    recipient:ClearAllPoints(); recipient:SetPoint("TOP",name,"BOTTOM",0,-2)
  else
    if name then name:ClearAllPoints(); name:SetPoint("BOTTOM",frame,"TOP",0,gap) end
    if recipient then recipient:ClearAllPoints(); recipient:SetPoint("TOP",frame,"BOTTOM",0,-gap) end
  end
  self:ApplyIconStyle(frame,frame.icon,d.iconStyle)
end
-- Session-only pause: one expiry timer, no saved timestamps or polling.
function B:PauseReminders(minutes)
  if A.Combat() or not self.db then return false end
  if not A.Number(minutes) or minutes<=0 then
    self.pauseUntil=nil; self:CancelTimer("manual-pause")
  else
    local seconds=math.max(60,math.min(1800,minutes*60))
    self.pauseUntil=GetTime()+seconds
    local deadline=self.pauseUntil
    self:StartTimer("manual-pause",seconds,function()
      if B.pauseUntil~=deadline then return end
      B.pauseUntil=nil; B:RequestRefresh("pause ended",0)
    end)
  end
  self:Refresh(false)
  return true
end
local function window(name,title,width,height)
  local f=CreateFrame("Frame",name,UIParent,"BackdropTemplate")
  f:SetSize(width,height); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetToplevel(true); f:SetClampedToScreen(true); f:EnableMouse(true)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  f:SetBackdropColor(unpack(B.OptionsTheme.window)); f:SetBackdropBorderColor(.60,.48,.25,1)
  f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.title:SetPoint("TOPLEFT",16,-16); f.title:SetText(B:Text(title))
  f:SetScript("OnEvent",function(s) s:Hide() end); f:RegisterEvent("PLAYER_REGEN_DISABLED")
  if name then UISpecialFrames[#UISpecialFrames+1]=name end
  return f
end
-- Close higher-stratum selectors before presenting a foreground window.
function B:HideOptionsPopups()
  local f=self.options
  if f then
    for _,key in ipairs({"activeSelector","blessingMenu","resetConfirm"}) do
      if f[key] then f[key]:Hide() end
    end
  end
  if self.itemPicker then self.itemPicker:Hide() end
end
local function control(parent,text,y,callback)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); b:SetSize(parent.width-32,26); b:SetPoint("TOPLEFT",16,y)
  b:SetText(B:Text(text)); b:SetScript("OnClick",function() if not A.Combat() then parent:Hide(); callback() end end)
  return b
end
function B:ShowQuickMenu()
  if A.Combat() then self.Print(self:Text("Settings are available after combat.")); return end
  if not self.quickMenu then
    local f=window("BuffTapQuickMenu","BuffTap",248,302); self.quickMenu=f; f.width=248
    f.status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.status:SetPoint("TOPLEFT",16,-44); f.status:SetWidth(216); f.status:SetHeight(34); f.status:SetWordWrap(true)
    control(f,"Open settings",-82,function() B:Options() end)
    f.toggle=control(f,"Disable BuffTap",-112,function() B.db.enabled=not B.db.enabled; B:RequestRefresh("toggle",0) end)
    f.resume=control(f,"Resume reminders",-142,function() B:PauseReminders(0) end)
    local hint=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); hint:SetPoint("TOPLEFT",16,-174); hint:SetText(B:Text("Pause reminders for:"))
    for i,minutes in ipairs({5,15,30}) do
      local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); b:SetSize(68,26); b:SetPoint("TOPLEFT",16+(i-1)*74,-194)
      b:SetText(B:Text("%d min",minutes)); b:SetScript("OnClick",function() if not A.Combat() then f:Hide(); B:PauseReminders(minutes) end end)
    end
    control(f,"Preview reminder",-226,function() B:PreviewAppearance() end)
    control(f,"Close",-258,function() end)
  end
  local f=self.quickMenu
  if f:IsShown() then f:Hide(); return end
  self:HideOptionsPopups()
  if self.welcome then self.welcome:Hide() end
  f.resume:SetEnabled(self.pauseUntil~=nil and GetTime()<self.pauseUntil)
  f.status:SetText(self:FriendlyStatus()); f.toggle:SetText(self:Text(self.db.enabled and "Disable BuffTap" or "Enable BuffTap"))
  f:ClearAllPoints()
  if type(GetCursorPosition)=="function" then local x,y=GetCursorPosition(); local scale=UIParent:GetEffectiveScale(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale)
  else f:SetPoint("CENTER",UIParent,"CENTER",0,0) end
  f:Show(); f:Raise()
end
function B:ShowWelcome(force)
  if A.Combat() or not self.db or (not force and self.db.welcomeSeen) then return end
  if not self.welcome then
    local f=window("BuffTapWelcome","",560,450); self.welcome=f; f.width=560; f.title:Hide()
    f.banner=self:AddMiniBanner(f,560)
    f.heading=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.heading:SetPoint("TOPLEFT",24,-128); f.heading:SetText(self:Text("Ready when you are."))
    f.steps={}
    for i,text in ipairs({"Choose your buffs — pick what to maintain in Settings.","Use your binding — scroll or click when a reminder appears.","Keep adventuring — BuffTap prepares your next action."}) do
      local row=CreateFrame("Frame",nil,f); row:SetPoint("TOPLEFT",24,-164-(i-1)*44); row:SetSize(512,40)
      row.number=row:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); row.number:SetPoint("TOPLEFT",0,0); row.number:SetText(tostring(i)..".")
      row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlight"); row.text:SetPoint("TOPLEFT",32,0); row.text:SetWidth(476); row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(true); row.text:SetText(self:Text(text)); f.steps[i]=row
    end
    f.binding=CreateFrame("Frame",nil,f,"BackdropTemplate"); f.binding:SetPoint("TOPLEFT",24,-300); f.binding:SetSize(512,48)
    f.binding:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); f.binding:SetBackdropColor(.043,.070,.085,1); f.binding:SetBackdropBorderColor(.22,.35,.4,1)
    f.bindingLabel=f.binding:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.bindingLabel:SetPoint("LEFT",12,0); f.bindingLabel:SetWidth(220); f.bindingLabel:SetJustifyH("LEFT"); f.bindingLabel:SetText(self:Text("Your current binding"))
    f.body=f.binding:CreateFontString(nil,"OVERLAY","GameFontHighlight"); f.body:SetPoint("RIGHT",-12,0); f.body:SetWidth(258); f.body:SetJustifyH("RIGHT"); f.body:SetWordWrap(true); f.body:SetTextColor(.65,.9,1)
    f.hint=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); f.hint:SetPoint("TOPLEFT",24,-360); f.hint:SetWidth(512); f.hint:SetJustifyH("LEFT"); f.hint:SetWordWrap(true); f.hint:SetText(self:Text("Right-click the minimap icon for quick controls and pause."))
    local settings=control(f,"Open settings",-402,function() B:Options() end); settings:SetSize(172,28); settings:ClearAllPoints(); settings:SetPoint("TOPLEFT",24,-402); f.settingsButton=settings
    local preview=control(f,"Preview reminder",-402,function() B:PreviewAppearance() end); preview:SetSize(172,28); preview:ClearAllPoints(); preview:SetPoint("TOPLEFT",206,-402); f.previewButton=preview
    local done=control(f,"Got it",-402,function() end); done:SetSize(144,28); done:ClearAllPoints(); done:SetPoint("TOPLEFT",392,-402); f.doneButton=done
  end
  self:HideOptionsPopups()
  if self.quickMenu then self.quickMenu:Hide() end
  if self.appearancePreview then self.appearancePreview:Hide() end
  local width,height=UIParent:GetSize()
  if A.Number(width) and A.Number(height) then self.welcome:SetScale(math.min(1,(width-32)/560,(height-32)/450)) end
  self.welcome.body:SetText(#self.db.keys>0 and table.concat(self.db.keys,", ") or self:Text("none — click the reminder"))
  self.welcome:ClearAllPoints(); self.welcome:SetPoint("CENTER",UIParent,"CENTER",0,0); self.welcome:Show(); self.welcome:Raise(); self.db.welcomeSeen=true
end
function B:ScheduleWelcome()
  if not self.db then return end
  -- The one-time setup comes first; it schedules the "How to buff" card for new players when it closes.
  if self.OnboardingPending and self:OnboardingPending() then self:StartTimer("welcome",3,function() B:ShowOnboarding() end); return end
  if self.db.welcomeSeen then return end
  self:StartTimer("welcome",2,function() B:ShowWelcome() end)
end
-- Edit Mode placeholders for the Nearby window and the camp reminder. They are plain
-- frames, so dragging never touches the secure Nearby window; the real frames follow the
-- saved position when Edit Mode closes.
local function editMover(key,caption,iconTexture)
  local f=window(nil,"",100,40); f.title:SetText(""); f.moverKey=key
  f:SetMovable(true); f:RegisterForDrag("LeftButton")
  if iconTexture then
    f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetPoint("TOPLEFT",4,-4); f.icon:SetPoint("BOTTOMRIGHT",-4,4); f.icon:SetTexture(iconTexture)
  else
    f.label=f:CreateFontString(nil,"OVERLAY","GameFontNormal"); f.label:SetPoint("CENTER"); f.label:SetText(B:Text("Nearby players"))
  end
  f.caption=f:CreateFontString(nil,"OVERLAY","GameFontNormal"); f.caption:SetPoint("TOP",f,"BOTTOM",0,-6); f.caption:SetText(B:Text(caption))
  f:SetScript("OnDragStart",function(s) if not A.Combat() then s.dragging=true; s:StartMoving() end end)
  local function savePosition(s)
    s:StopMovingOrSizing(); s.dragging=false
    if A.Combat() then return end
    local x,y=s:GetCenter(); local cx,cy=UIParent:GetCenter()
    if A.Number(x) and A.Number(y) and A.Number(cx) and A.Number(cy) then
      if key=="nearby" then
        local nx,ny=x-cx,y-cy
        if B.NearbyCenterOffset then nx,ny=B:NearbyCenterOffset(s) end
        if nx then B.db.nearbyX=nx; B.db.nearbyY=ny end
      else B.db.campX=x-cx; B.db.campY=y-cy end
    end
  end
  f.savePosition=savePosition; f:SetScript("OnDragStop",savePosition)
  f:SetScript("OnEvent",function(s) if s.dragging then s:StopMovingOrSizing(); s.dragging=false end; s:Hide() end)
  return f
end
function B:ShowEditMovers()
  local d=self.db
  if d.nearbyEnabled then
    self.editNearby=self.editNearby or editMover("nearby","BuffTap Nearby — drag to move")
    local f=self.editNearby; local width,rows,scale=240,5,1
    if self.NearbyLayout then width,rows,scale=self:NearbyLayout() end
    f:SetScale(A.Number(scale) and scale or 1); f:SetSize(width+24,29+rows*(self.NearbyRowHeight and self:NearbyRowHeight() or 21))
    local nx,ny=A.Number(d.nearbyX) and d.nearbyX or 240,A.Number(d.nearbyY) and d.nearbyY or 0
    if self.PlaceNearbyFrame then self:PlaceNearbyFrame(f,nx,ny) else f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",nx,ny) end; f:Show()
  elseif self.editNearby then self.editNearby:Hide() end
  if d.campReminder==true then
    self.editCamp=self.editCamp or editMover("camp","Camp reminder — drag to move",135805)
    local f=self.editCamp; local size=A.Number(d.campSize) and d.campSize or 40
    f:SetSize(size,size); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",A.Number(d.campX) and d.campX or 100,A.Number(d.campY) and d.campY or 0); f:Show()
  elseif self.editCamp then self.editCamp:Hide() end
end
function B:HideEditMovers()
  for _,f in ipairs({self.editNearby,self.editCamp}) do
    if f then
      if f.dragging and not A.Combat() then f.savePosition(f) end
      f:StopMovingOrSizing(); f.dragging=false; f:Hide()
    end
  end
  if not A.Combat() then
    if self.nearbyFrame and self.UpdateNearbyWindow then self:UpdateNearbyWindow() end
    if self.UpdateCamping then self:UpdateCamping() end
  end
end
-- Only an unprotected preview participates in editing. No Blizzard system registration,
-- protected frame hooks, layout mutation or assumptions about retail-only templates.
function B:SetEditModeActive(active)
  if active and A.Combat() then return end
  if self.editModeActive==active then return end
  self.editModeActive=active
  if active then
    if self.options then self.options:Hide() end
    if self.appearancePreview then self.appearancePreview:Hide() end
    if self.anchor then self.anchor:Hide() end
    if not self.editAnchor then
      local f=window(nil,"",100,100); self.editAnchor=f; f.title:SetText("")
      f:SetMovable(true); f:RegisterForDrag("LeftButton")
      f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetPoint("TOPLEFT",4,-4); f.icon:SetPoint("BOTTOMRIGHT",-4,4); f.icon:SetTexture(ICON)
      f.caption=f:CreateFontString(nil,"OVERLAY","GameFontNormal"); f.caption:SetPoint("TOP",f,"BOTTOM",0,-6); f.caption:SetText(B:Text("BuffTap — drag to move"))
      f:SetScript("OnDragStart",function(s) if not A.Combat() then s.dragging=true; s:StartMoving() end end)
      local function savePosition(s)
        s:StopMovingOrSizing(); s.dragging=false
        if A.Combat() then return end
        local x,y=s:GetCenter(); local cx,cy=UIParent:GetCenter()
        if A.Number(x) and A.Number(y) and A.Number(cx) and A.Number(cy) then B.db.x=x-cx; B.db.y=y-cy; B.appearance=nil end
      end
      f.savePosition=savePosition; f:SetScript("OnDragStop",savePosition)
      f:SetScript("OnEvent",function(s) s:StopMovingOrSizing(); s:Hide(); B.editModeActive=false; B.dirty=true end)
    end
    local f=self.editAnchor; f:SetSize(self.db.size,self.db.size); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y); f:Show()
    self:ShowEditMovers()
  elseif self.editAnchor then
    if self.editAnchor.dragging and not A.Combat() then self.editAnchor.savePosition(self.editAnchor) end
    self.editAnchor:StopMovingOrSizing(); self.editAnchor.dragging=false; self.editAnchor:Hide()
  end
  if not active then self:HideEditMovers() end
  if not A.Combat() then self:Refresh(false) else self.dirty=true end
end
function B:SyncEditMode()
  local manager=EditModeManagerFrame
  if not self.db or not manager or type(manager.HookScript)~="function" or self.editModeManager==manager then return end
  local ok=pcall(function()
    manager:HookScript("OnShow",function() B:SetEditModeActive(true) end)
    manager:HookScript("OnHide",function() B:SetEditModeActive(false) end)
  end)
  if ok then self.editModeManager=manager; if manager:IsShown() then self:SetEditModeActive(true) end end
end
