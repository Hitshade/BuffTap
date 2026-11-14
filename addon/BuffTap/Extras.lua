-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
-- 1.20.0 additions: blacklist, mana floor, ready check and group top-ups, breath timer,
-- pause notes, the copyable report window and the export/import window.
local _,B=...
local A=B.API
local function L(key,...) return B:Text(key,...) end

-- Choice lists for the new selectors.
function B:DismissChoices() return {{key=0,name=L("Until zone change")},{key=5,name=L("%d min",5)},{key=10,name=L("%d min",10)},{key=15,name=L("%d min",15)},{key=30,name=L("%d min",30)}} end
function B:ThankDelayChoices() return {{key=0,name=L("No delay")},{key=2,name=L("1 to 3 sec")},{key=5,name=L("3 to 6 sec")}} end
function B:ChoiceName(list,key) for _,c in ipairs(list) do if c.key==key then return c.name end end; return list[1] and list[1].name or "" end

-- Blacklist ---------------------------------------------------------------
local function lower(text) return type(text)=="string" and text:match("^%s*(.-)%s*$"):lower() or "" end
-- Full name (on Forever: first name and surname), so one "Bob" is never mistaken for another.
function B:UnitFullName(unit)
  local name=type(GetUnitName)=="function" and A.Call(GetUnitName,unit,true) or nil
  if not A.Text(name) or name=="" then name=A.Call(UnitName,unit) end
  if A.Text(name) and name~="" then return name end
end
function B:BlockReason(unit)
  local d=self.db
  if not d or not A.Text(unit) then return nil end
  if d.blacklistInInstances==false and self:InGroupInstance() then return nil end
  local name=A.Call(UnitName,unit)
  if A.Text(name) and name~="" then
    -- A full-name entry matches that player only; a first-name-only entry (typed by hand) matches anyone with that first name.
    local full=self:UnitFullName(unit)
    if type(d.blockedPlayers)=="table" and ((full and d.blockedPlayers[full:lower()]) or d.blockedPlayers[name:lower()]) then return "blacklisted player" end
    if d.blockIgnored~=false then
      local ignored
      if C_FriendList and type(C_FriendList.IsIgnored)=="function" then ignored=A.Call(C_FriendList.IsIgnored,name)
      elseif type(IsIgnored)=="function" then ignored=A.Call(IsIgnored,name) end
      if ignored==true then return "on your ignore list" end
    end
  end
  if type(d.blockedGuilds)=="table" and next(d.blockedGuilds) then
    local guild=A.Call(GetGuildInfo,unit)
    if A.Text(guild) and guild~="" and d.blockedGuilds[guild:lower()] then return "blacklisted guild" end
  end
end
function B:SetBlocked(kind,name,blocked)
  if A.Combat() or not self.db then return false end
  local key=lower(name); if key=="" or key:find("[%c|]") or #key>64 then return false end
  local list=kind=="guild" and self.db.blockedGuilds or self.db.blockedPlayers
  list[key]=blocked and true or nil
  self:ApplyBlacklist(); return true
end
-- Drop newly blocked players from Nearby straight away.
function B:ApplyBlacklist()
  -- Blocked players stay listed (marked with a red crossed circle) but are never offered anything.
  self.nearbySnapshot=nil
  if self.nearbyFrame and self.UpdateNearbyWindow then self:UpdateNearbyWindow() end
  self:RequestRefresh("blacklist changed",0)
  if self.options and self.options:IsShown() and self.options.activeTab==13 then self:UpdateBlacklistPage() end
end
function B:BlockedList()
  local out={}
  for name in pairs(self.db.blockedPlayers or {}) do out[#out+1]={kind="player",name=name} end
  for name in pairs(self.db.blockedGuilds or {}) do out[#out+1]={kind="guild",name=name} end
  table.sort(out,function(a,b) if a.kind~=b.kind then return a.kind=="player" end; return a.name<b.name end)
  return out
end

-- Mana floor: buffing players outside your group waits until mana is back above the floor.
function B:ManaFloorReached()
  local floor=self.db and tonumber(self.db.nearbyManaFloor) or 0
  if floor<=0 then return false end
  local power,max=A.Call(UnitPower,"player",0),A.Call(UnitPowerMax,"player",0)
  if not A.Number(power) or not A.Number(max) or max<=0 then return false end
  return power/max*100<floor
end

-- Ready checks and long buffs in dungeons top up earlier.
function B:EarlyTopUpSeconds(configured,duration)
  if not A.Number(duration) or duration<=0 then return configured end
  if self.readyCheckUntil and self.db.readyCheckTopUp~=false and GetTime()<self.readyCheckUntil then
    configured=math.max(configured,math.min(300,duration*0.5))
  end
  if duration>=1200 and self:InGroupInstance() then configured=math.max(configured,math.min(300,duration*0.1)) end
  return configured
end

-- Events: ready check, breath timer, zone changes for pause notes.
local events=CreateFrame("Frame")
for _,event in ipairs({"READY_CHECK","READY_CHECK_FINISHED","MIRROR_TIMER_START","MIRROR_TIMER_STOP","ZONE_CHANGED_NEW_AREA","PLAYER_ENTERING_WORLD"}) do pcall(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function(_,event,timer)
  if not B.db then return end
  if event=="READY_CHECK" then
    if B.db.readyCheckTopUp==false then return end
    B.readyCheckUntil=GetTime()+40; B:InvalidateAura(); B:RequestRefresh("ready check",0)
    B:StartTimer("ready-check-topup",40.1,function() B.readyCheckUntil=nil; B:RequestRefresh("ready check ended",0) end)
  elseif event=="READY_CHECK_FINISHED" then
    if B.readyCheckUntil then B.readyCheckUntil=GetTime()+5; B:StartTimer("ready-check-topup",5.1,function() B.readyCheckUntil=nil; B:RequestRefresh("ready check ended",0) end) end
  elseif event=="MIRROR_TIMER_START" or event=="MIRROR_TIMER_STOP" then
    if timer=="BREATH" then B.underwater=event=="MIRROR_TIMER_START"; B:RequestRefresh("breath timer",0) end
  elseif event=="ZONE_CHANGED_NEW_AREA" then B.pauseNoteShown=nil
  elseif event=="PLAYER_ENTERING_WORLD" then
    -- After a /reload while underwater no START event comes: read the running timers instead.
    local under=false
    for i=1,(MIRRORTIMER_NUMTIMERS or 3) do
      local name=A.Call(GetMirrorTimerInfo,i)
      if name=="BREATH" then under=true end
    end
    B.underwater=under
  end
end)

-- Pause notes: say once per zone why reminders went quiet when it is not obvious.
local refresh=B.Refresh
function B:Refresh(...)
  local a,b,c=refresh(self,...)
  if self.db and self.db.pauseNotes~=false and self.db.enabled and self.buffDataUnavailable and not self.pauseNoteShown and not A.Combat() then
    self.pauseNoteShown=true
    self.Print(L("Reminders are paused here because the game is not sharing buff information. They resume when it does. Turn this note off under Diagnostics."))
  end
  return a,b,c
end

-- Shared text window --------------------------------------------------------
local T=B.OptionsTheme
local function textWindow(name,title)
  local f=CreateFrame("Frame",name,UIParent,"BackdropTemplate")
  f:SetSize(560,420); f:SetPoint("CENTER"); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetToplevel(true); f:SetClampedToScreen(true)
  f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function(s) s:StartMoving() end); f:SetScript("OnDragStop",function(s) s:StopMovingOrSizing() end)
  -- Same window, title, close glyph, card and scroll bar styling as the settings window.
  T.Surface(f,"window"); T.Shadow(f,18,.55)
  f.title=f:CreateFontString(nil,"OVERLAY"); f.title:SetFontObject(T.fonts and T.fonts.Title or GameFontNormalLarge); f.title:SetPoint("TOPLEFT",18,-16); f.title:SetText(L(title))
  local close=CreateFrame("Button",nil,f,"BackdropTemplate"); close:SetSize(26,26); close:SetPoint("TOPRIGHT",-10,-10)
  T.Variant(close,"danger"); close.glyph=close:CreateTexture(nil,"ARTWORK"); close.glyph:SetPoint("CENTER"); T.Glyph(close.glyph,"close",14,.80,.82,.86)
  close:SetScript("OnClick",function() f:Hide() end)
  local card=CreateFrame("Frame",nil,f,"BackdropTemplate"); card:SetPoint("TOPLEFT",14,-72); card:SetPoint("BOTTOMRIGHT",-14,52); T.Surface(card,"card")
  local scroll=CreateFrame("ScrollFrame",nil,card,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",10,-8); scroll:SetPoint("BOTTOMRIGHT",-30,8)
  if T.ScrollBar then T.ScrollBar(scroll) end
  local box=CreateFrame("EditBox",nil,scroll); box:SetMultiLine(true); box:SetAutoFocus(false); box:SetFontObject(GameFontHighlightSmall)
  box:SetWidth(480); box:SetMaxLetters(0); box:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)
  scroll:SetScrollChild(box); f.box=box; f.scroll=scroll
  f:SetScript("OnEvent",function(s) s:Hide() end); f:RegisterEvent("PLAYER_REGEN_DISABLED")
  if name then UISpecialFrames[#UISpecialFrames+1]=name end
  return f
end
local function button(parent,text,x,y,width,onClick,anchor,variant)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate"); b:SetSize(width,28); b:SetPoint(anchor or "TOPLEFT",x,y); b:SetText(L(text))
  T.Variant(b,variant)
  b:SetScript("OnClick",function() if not A.Combat() then onClick() end end)
  return b
end
local function setText(f,text) f.box:SetText(text or ""); f.box:HighlightText(); f.box:SetFocus(); if f.scroll.SetVerticalScroll then f.scroll:SetVerticalScroll(0) end end

-- Report window: runs the debug commands and collects their output for copying.
local function names()
  local found={}
  -- First names and surnames (Forever), so "Hide player names" also hides surnames.
  local function add(unit)
    local ok,n,surname=pcall(UnitName,unit)
    if ok and A.Text(n) and #n>1 then found[n]=true end
    if ok and A.Text(surname) and #surname>1 then found[surname]=true end
  end
  add("player"); add("target"); add("pet")
  for i=1,4 do add("party"..i) end
  for i=1,40 do add("raid"..i); add("nameplate"..i) end
  local list={}; for n in pairs(found) do list[#list+1]=n end
  table.sort(list,function(a,b) return #a>#b end)
  return list
end
function B:CaptureOutput(run)
  self.outputCapture={}
  local ok,err=pcall(run)
  local lines=self.outputCapture; self.outputCapture=nil
  if not ok then lines[#lines+1]="Error: "..tostring(err) end
  return lines
end
-- Full check-up: every report BuffTap has, in one box, so a bug report needs one copy.
function B:CheckupLines()
  local out={}
  local function add(title,lines)
    out[#out+1]=""; out[#out+1]="== "..title.." =="
    for _,line in ipairs(lines or {}) do out[#out+1]=tostring(line) end
  end
  local build,_,_,interface=A.Call(GetBuildInfo)
  local _,class=A.Call(UnitClass,"player")
  local inInstance,instanceType=A.Call(IsInInstance)
  local group=A.Call(IsInRaid)==true and "raid" or A.Call(IsInGroup)==true and "party" or "solo"
  add("Game",{"Client "..tostring(build).." ("..tostring(interface)..") | locale "..tostring(A.Call(GetLocale)),
    "Class "..tostring(class).." | level "..tostring(A.Call(UnitLevel,"player")).." | "..group
      .." | instance "..tostring(inInstance==true and instanceType or "none").." | resting "..tostring(A.Call(IsResting)==true)
      .." | combat "..tostring(A.Combat()==true),
    "Friendly nameplates "..tostring(self.FriendlyPlatesState and self:FriendlyPlatesState())})
  local function safe(fn) local ok,lines=pcall(fn); if ok then return lines end; return {"(unavailable: "..tostring(lines)..")"} end
  if not A.Combat() then pcall(self.Refresh,self,true) end
  add("Diagnostics",safe(function() return self:DiagnosticsLines() end))
  add("Debug",safe(function() return self:CaptureOutput(function() B:Status(true) end) end))
  add("Nearby",safe(function() return self:NearbyDiagnosticsLines() end))
  add("Supplies",safe(function() return self:CaptureOutput(function() B:ReportSupplies() end) end))
  add("Settings (import string, without your blacklist)",safe(function()
    local count=function(t) local n=0; for _ in pairs(t or {}) do n=n+1 end; return n end
    return {"Blacklist: "..count(self.db.blockedPlayers).." players, "..count(self.db.blockedGuilds).." guilds (names left out)",self:ExportSettings(true)}
  end))
  return out
end
function B:ReportText(kind,hideNames)
  local lines
  if kind=="checkup" then lines=self:CheckupLines()
  elseif kind=="status" then lines=self:CaptureOutput(function() B:Status(false) end)
  elseif kind=="debug" then lines=self:CaptureOutput(function() B:Status(true) end)
  elseif kind=="supplies" then lines=self:CaptureOutput(function() B:ReportSupplies() end)
  elseif kind=="nearby" then lines=self:NearbyDiagnosticsLines()
  else
    if not A.Combat() then self:Refresh(true) end
    lines=self:DiagnosticsLines()
  end
  local text="BuffTap "..tostring(self.version).." | "..L(kind=="checkup" and "Full check-up" or kind=="status" and "Status" or kind=="debug" and "Debug" or kind=="supplies" and "Supplies" or kind=="nearby" and "Nearby" or "Diagnostics").."\n"..table.concat(lines or {},"\n")
  text=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  if hideNames then
    -- Whole words only, so a short name like "Bo" does not rewrite "Boss".
    for i,n in ipairs(names()) do text=text:gsub("%f[%w]"..n:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]","%%%0").."%f[%W]","Player"..i) end
  end
  return text
end
function B:ShowReport(kind)
  if A.Combat() then self.Print(L("Settings are available after combat.")); return end
  self:Options(); if self.options and self.options.selectTab then self.options.selectTab(11) end
  self:ShowDiagnosticsReport(kind or "diagnostics")
end
-- Diagnostics page: show captured output in the page's copyable box, selected for Ctrl+C.
function B:ShowDiagnosticsReport(kind)
  local f=self.options; if A.Combat() or not f or not f.discoveryReport then return end
  local text=self:ReportText(kind,self.reportHideNames~=false)
  f.discoveryReport:SetText(text.."\n\n"..L("Press Ctrl+C to copy."))
  if f.resizeDiscoveryReport then f.resizeDiscoveryReport() end
  f.diagText:Hide(); f.diagScroll:Hide(); f.discoveryScroll:Show(); f.discoveryScroll:SetVerticalScroll(0)
  f.discoveryReport:SetFocus(); f.discoveryReport:HighlightText()
end

-- Export and import window.
function B:ShowSettingsTransfer(mode)
  if A.Combat() then self.Print(L("Settings are available after combat.")); return end
  if not self.transferWindow then
    local f=textWindow("BuffTapTransfer","Export settings"); self.transferWindow=f
    f.hint=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); f.hint:SetPoint("TOPLEFT",18,-46); f.hint:SetWidth(520); f.hint:SetJustifyH("LEFT")
    f.status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.status:SetPoint("BOTTOMLEFT",18,22); f.status:SetWidth(330); f.status:SetJustifyH("LEFT")
    f.import=button(f,"Import",-126,14,110,function()
      local ok,msg=B:ImportSettings(f.box:GetText())
      f.status:SetText(msg); if ok then B.Print(msg); if B.options and B.options:IsShown() then B:Options() end end
    end,"BOTTOMRIGHT")
    button(f,"Close",-16,14,90,function() f:Hide() end,"BOTTOMRIGHT")
  end
  local f=self.transferWindow
  self:HideOptionsPopups(); f.status:SetText("")
  if mode=="import" then
    f.title:SetText(L("Import settings")); f.hint:SetText(L("Paste a BuffTap settings string, then press Import. Buff settings only import onto the same class."))
    f.import:Show(); f:Show(); f:Raise(); f.box:SetText(""); f.box:SetFocus()
  else
    f.title:SetText(L("Export settings")); f.hint:SetText(L("Press Ctrl+C to copy. The string holds this profile's settings and this class's buff setup."))
    f.import:Hide(); f:Show(); f:Raise(); setText(f,self:ExportSettings())
  end
end

-- Move BuffTap frames: the same movers Blizzard's Edit Mode shows, without opening Edit Mode
-- (an addon opening Edit Mode can cause blocked-action errors later), plus a Done bar.
function B:MoveAllFrames(returnView)
  if A.Combat() then self.Print(L("Settings are available after combat.")); return end
  local bar=self.moveDoneBar
  if not bar then
    bar=CreateFrame("Frame","BuffTapMoveDone",UIParent,"BackdropTemplate"); self.moveDoneBar=bar
    bar:SetSize(340,72); bar:SetPoint("TOP",UIParent,"TOP",0,-120); bar:SetFrameStrata("FULLSCREEN_DIALOG")
    T.Surface(bar,"window"); T.Shadow(bar,14,.5)
    local text=bar:CreateFontString(nil,"OVERLAY","GameFontHighlight"); text:SetPoint("TOP",0,-12); text:SetText(L("Drag BuffTap's frames, then press Done."))
    local done=CreateFrame("Button",nil,bar,"BackdropTemplate"); done:SetSize(140,28); done:SetPoint("BOTTOM",0,10); done:SetText(L("Done")); T.Variant(done,"primary")
    done:SetScript("OnClick",function() B:FinishMovingFrames() end)
    bar:SetScript("OnEvent",function() B:FinishMovingFrames() end); bar:RegisterEvent("PLAYER_REGEN_DISABLED")
  end
  self.moveReturnView=returnView or "binding"
  self.movingFrames=true; self:SetEditModeActive(true); bar:Show()
end
function B:FinishMovingFrames()
  if self.moveDoneBar then self.moveDoneBar:Hide() end
  if not self.movingFrames then return end
  self.movingFrames=nil; self:SetEditModeActive(false)
  if not A.Combat() then self:Options(); if self.options and self.options.selectTab then self.options.selectTab(8) end; if self.SetAppearanceView then self:SetAppearanceView(self.moveReturnView or "binding") end end
end

-- Optional Nearby key: bound to the row holding the first ready buff, so it uses the row's own checks.
function B:ApplyNearbyBinding()
  if A.Combat() or type(ClearOverrideBindings)~="function" then return end
  local owner=self.nearbyBindingOwner
  if not owner then owner=CreateFrame("Frame"); self.nearbyBindingOwner=owner end
  local keys=self.db and self.db.nearbyKeys or {}
  local f=self.nearbyFrame; local target
  if #keys>0 and f and f:IsShown() then
    for _,row in ipairs(f.rows or {}) do if row:IsShown() and row.entry and row.action and row.action.ready~=false then target=row; break end end
  end
  local signature=target and (target:GetName() or "").."|"..table.concat(keys,",") or ""
  if signature==(self.nearbyBindingSignature or "") then return end
  self.nearbyBindingSignature=signature; self.nearbyBoundRow=target
  pcall(ClearOverrideBindings,owner)
  if target and target:GetName() then
    for _,key in ipairs(keys) do pcall(SetOverrideBindingClick,owner,true,key,target:GetName(),"LeftButton") end
  end
end
local updateNearby=B.UpdateNearbyWindow
function B:UpdateNearbyWindow(...)
  local a,b,c=updateNearby(self,...)
  self:ApplyNearbyBinding()
  return a,b,c
end

-- Right-click menu on a Nearby name.
local function whisper(name) if type(ChatFrame_SendTell)=="function" then pcall(ChatFrame_SendTell,name) end end
local function invite(name)
  if C_PartyInfo and type(C_PartyInfo.InviteUnit)=="function" then pcall(C_PartyInfo.InviteUnit,name)
  elseif type(InviteUnit)=="function" then pcall(InviteUnit,name) end
end
local function ignore(name)
  if C_FriendList and type(C_FriendList.AddIgnore)=="function" then pcall(C_FriendList.AddIgnore,name)
  elseif type(AddIgnore)=="function" then pcall(AddIgnore,name) end
end
function B:ShowNearbyMenu(row)
  local entry=row and row.entry; if A.Combat() or not entry or not A.Text(entry.name) then return end
  local name=(entry.unit and A.Call(UnitGUID,entry.unit)==entry.guid and self:UnitFullName(entry.unit)) or entry.name
  local guild=entry.unit and A.Call(GetGuildInfo,entry.unit)
  if not A.Text(guild) or guild=="" then guild=nil end
  local m=self.nearbyMenu
  if not m then
    m=CreateFrame("Frame","BuffTapNearbyMenu",UIParent,"BackdropTemplate"); self.nearbyMenu=m
    m:SetFrameStrata("FULLSCREEN_DIALOG"); m:SetClampedToScreen(true); m:EnableMouse(true); m:SetWidth(190)
    T.Surface(m,"menu")
    m.title=m:CreateFontString(nil,"OVERLAY","GameFontNormal"); m.title:SetPoint("TOPLEFT",10,-8); m.title:SetWidth(170); m.title:SetJustifyH("LEFT"); m.title:SetWordWrap(false)
    m.items={}
    m:SetScript("OnEvent",function(s) s:Hide() end); m:RegisterEvent("PLAYER_REGEN_DISABLED")
    UISpecialFrames[#UISpecialFrames+1]="BuffTapNearbyMenu"
  end
  local items={
    {L("Whisper"),function() whisper(name) end},
    {L("Invite to group"),function() invite(name) end},
    {L("Add to ignore list"),function() ignore(name); B:ApplyBlacklist() end},
  }
  -- Already listed: offer the way back instead.
  local listedKey=B.db.blockedPlayers and ((B.db.blockedPlayers[name:lower()] and name) or (B.db.blockedPlayers[entry.name:lower()] and entry.name))
  items[#items+1]=listedKey and {L("Remove from blacklist"),function() B:SetBlocked("player",listedKey,false) end} or {L("Blacklist player"),function() B:SetBlocked("player",name,true) end}
  if guild then
    local guildListed=B.db.blockedGuilds and B.db.blockedGuilds[guild:lower()]
    items[#items+1]=guildListed and {L("Remove guild from blacklist: %s",guild),function() B:SetBlocked("guild",guild,false) end} or {L("Blacklist guild: %s",guild),function() B:SetBlocked("guild",guild,true) end}
  end
  items[#items+1]={L("Cancel"),function() end}
  for i,spec in ipairs(items) do
    local b=m.items[i]
    if not b then
      b=CreateFrame("Button",nil,m); b:SetSize(178,22); b:SetPoint("TOPLEFT",6,-28-(i-1)*22); m.items[i]=b
      b.hl=b:CreateTexture(nil,"HIGHLIGHT"); b.hl:SetAllPoints(); b.hl:SetColorTexture(.75,.60,.25,.18)
      b.text=b:CreateFontString(nil,"OVERLAY","GameFontHighlight"); b.text:SetPoint("LEFT",6,0); b.text:SetWidth(166); b.text:SetJustifyH("LEFT"); b.text:SetWordWrap(false)
    end
    b.text:SetText(spec[1]); b:SetScript("OnClick",function() m:Hide(); if not A.Combat() then spec[2]() end end); b:Show()
  end
  for i=#items+1,#m.items do m.items[i]:Hide() end
  m.title:SetText(name); m:SetHeight(34+#items*22)
  m:ClearAllPoints()
  local x,y; if type(GetCursorPosition)=="function" then x,y=GetCursorPosition() end
  local scale=UIParent:GetEffectiveScale()
  if A.Number(x) and A.Number(y) and A.Number(scale) and scale>0 then m:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale) else m:SetPoint("CENTER") end
  m:Show(); m:Raise()
end

-- Blacklist page in the options window.
function B:UpdateBlacklistPage()
  local f=self.options; if not f or not f.blackLists then return end
  f.blackIgnored:SetChecked(self.db.blockIgnored~=false); f.blackTargets:SetChecked(self.db.blacklistTargets~=false); f.blackInstances:SetChecked(self.db.blacklistInInstances==false)
  for _,list in ipairs(f.blackLists) do
    local names={}
    for name in pairs(list.kind=="guild" and self.db.blockedGuilds or self.db.blockedPlayers) do names[#names+1]=name end
    table.sort(names)
    list.title:SetText(L(list.kind=="guild" and "Guilds (%d)" or "Players (%d)",#names))
    for i,name in ipairs(names) do local row=f.blackRow(list,i); row.name=name; row.text:SetText(name); row:Show() end
    for i=#names+1,#list.rows do list.rows[i].name=nil; list.rows[i]:Hide() end
    list.child:SetHeight(math.max(280,#names*32)); list.empty:SetShown(#names==0)
  end
end
function B:ShowBlacklist()
  if A.Combat() then self.Print(L("Settings are available after combat.")); return end
  self:Options(); if self.options and self.options.selectTab then self.options.selectTab(13) end
end
