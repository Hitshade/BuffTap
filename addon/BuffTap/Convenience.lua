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
  h.background=h:CreateTexture(nil,"BACKGROUND"); h.background:SetAllPoints(); h.background:SetColorTexture(.035,.045,.05,1)
  h.art=h:CreateTexture(nil,"ARTWORK"); h.art:SetPoint("TOPLEFT",8,0); h.art:SetSize(artWidth,height)
  h.artWidth=artWidth; h.artHeight=height
  h.art:SetTexture("Interface\\AddOns\\BuffTap\\Media\\BuffTapMiniBanner.tga")
  h.art:SetTexCoord(0,1,176/770,596/770)
  return h
end
local colors={default={1,1,1},gold={1,.82,.1},cyan={.4,.9,1},green={.45,1,.65}}
function B:ReminderFonts()
  local choices={{key="default",name="Default font"}}
  if type(UNIT_NAME_FONT)=="string" then choices[#choices+1]={key="names",name="Unit-name font"} end
  if type(DAMAGE_TEXT_FONT)=="string" then choices[#choices+1]={key="numbers",name="Combat-number font"} end
  if self.db and self.db.labelFont=="names" and type(UNIT_NAME_FONT)~="string" then choices[#choices+1]={key="names",name="Unit-name font (unavailable)"} end
  if self.db and self.db.labelFont=="numbers" and type(DAMAGE_TEXT_FONT)~="string" then choices[#choices+1]={key="numbers",name="Combat-number font (unavailable)"} end
  return choices
end
function B:ReminderColors()
  return {{key="default",name="Text: default"},{key="gold",name="Text: gold"},{key="cyan",name="Text: cyan"},{key="green",name="Text: green"}}
end
function B:NormalizeConvenience()
  local d=self.db
  if d.labelFont~="names" and d.labelFont~="numbers" then d.labelFont="default" end
  if not colors[d.labelColor] then d.labelColor="default" end
  if type(d.welcomeSeen)~="boolean" then d.welcomeSeen=false end
end
function B:ApplyReminderStyle(frame)
  local d=self.db
  local path=d.labelFont=="names" and UNIT_NAME_FONT or d.labelFont=="numbers" and DAMAGE_TEXT_FONT
  local col=colors[d.labelColor] or colors.default
  for _,entry in ipairs({{frame.nameLabel,"GameFontHighlightSmall"},{frame.label or frame.recipient,"GameFontHighlightSmall"},{frame.timerLabel or frame.timer,"GameFontHighlightSmall"},{frame.groupLabel or frame.count,"GameFontNormalSmall"}}) do
    local fs=entry[1]
    if fs then
      fs:SetFontObject(entry[2])
      if type(path)=="string" then
        local _,size,flags=fs:GetFont()
        if A.Number(size) then fs:SetFont(path,size,flags) end
      end
      if d.labelColor=="default" and (fs==frame.groupLabel or fs==frame.count) then fs:SetTextColor(1,.82,.1)
      else fs:SetTextColor(col[1],col[2],col[3]) end
    end
  end
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
  f:SetBackdropColor(.035,.045,.055,1)
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
    f.binding:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); f.binding:SetBackdropColor(.065,.11,.135,1); f.binding:SetBackdropBorderColor(.22,.35,.4,1)
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
  if not self.db or self.db.welcomeSeen then return end
  self:StartTimer("welcome",2,function() B:ShowWelcome() end)
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
  elseif self.editAnchor then
    if self.editAnchor.dragging and not A.Combat() then self.editAnchor.savePosition(self.editAnchor) end
    self.editAnchor:StopMovingOrSizing(); self.editAnchor.dragging=false; self.editAnchor:Hide()
  end
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
