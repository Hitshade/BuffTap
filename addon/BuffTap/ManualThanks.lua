-- User-triggered whisper fallback. A captured GUID must resolve to the same full name at send time.
local _,B=...
local A=B.API
local DEFAULT="Thank you for %s!"
local ICON="Interface\\Icons\\Achievement_Reputation_01"
function B:ManualThanksAllowed()
  if not (self.db and self.db.manualThanks==true) or not self:SoloThanksAllowed() then return false end
  if self.db.helperThanksResting~=true and A.Call(IsResting)~=false then return false end
  return true
end
function B:ManualThanksName(guid)
  if not A.Text(guid) or not guid:match("^Player%-") or type(UnitNameFromGUID)~="function" then return end
  local ok,first,last=pcall(UnitNameFromGUID,guid)
  if not ok or not A.Text(first) or not A.Public(last) then return end
  first=first:match("^%s*(.-)%s*$")
  local name
  if A.Text(last) then name=first.." "..last:match("^%s*(.-)%s*$")
  elseif first:find("%S+%s+%S+") then name=first end
  if not name or #name>96 or name:find("[%c|]") or not name:match("%S+%s+%S+") then return end
  if C_FriendList and (A.Call(C_FriendList.IsIgnoredByGuid,guid)==true or A.Call(C_FriendList.IsIgnored,name)==true) then return end
  return name
end
function B:ManualThanksTemplate()
  local text=self.db.thankMessage
  if text=="Thank you for [buff]!" then return DEFAULT end
  return A.Text(text) and text or DEFAULT
end
function B:SetManualThanksMessage(text)
  if A.Combat() or type(text)~="string" then return false end
  text=text:gsub("[%c|]",""):match("^%s*(.-)%s*$")
  if #text>180 then return false,self:Text("Please keep the thank-you message under 180 bytes.") end
  self.db.thankMessage=text~="" and text or DEFAULT
  return true
end
function B:ManualThanksText(entry)
  local names={}; for _,name in pairs(entry.buffs or {}) do names[#names+1]=name end; table.sort(names)
  if #names==0 then return end
  local template=self:ManualThanksTemplate()
  local replacement=table.concat(names,", "); local pieces={}; local at=1
  while at<=#template do
    local first,last=template:find("%%s",at); local oldFirst,oldLast=template:find("%[buff%]",at)
    if oldFirst and (not first or oldFirst<first) then first,last=oldFirst,oldLast end
    if not first then pieces[#pieces+1]=template:sub(at); break end
    pieces[#pieces+1]=template:sub(at,first-1); pieces[#pieces+1]=replacement; at=last+1
  end
  local text=table.concat(pieces)
  if #text>255 or text:find("[%c|]") or text:match("^%s*$") then return end
  return text
end
function B:DropManualThanks(guid)
  if self.manualThanksQueue then self.manualThanksQueue[guid]=nil end
  self:UpdateManualThanks()
  self:RequestRefresh("manual thanks changed",0)
end
function B:OfferManualThanks(aura)
  if not self:ManualThanksAllowed() or not A.Text(aura.casterGUID) then return end
  local guid=aura.casterGUID
  if self:ThanksInGroup(guid)~=false then return end -- grouped: only casters confirmed outside the group
  if (self.manualThanksDismissed or {})[guid] and self.manualThanksDismissed[guid]>GetTime() then return end
  local name=self:ManualThanksName(guid)
  local buff=A.Text(aura.name) and aura.name or A.Call(C_Spell and C_Spell.GetSpellName,aura.spellId)
  if not name or not A.Text(buff) or buff:find("[%c|]") then return end
  local cooldown=self.helperThankCooldowns or {}; local now=GetTime()
  if now-(cooldown["guid:"..guid] or -1000)<60 or now-(cooldown["name:"..name] or -1000)<60 then return end
  self.manualThanksQueue=self.manualThanksQueue or {}
  local queue=self.manualThanksQueue; local entry=queue[guid]
  if entry and (entry.name~=name or now-entry.at>=15) then queue[guid]=nil; entry=nil end
  if not entry then
    local count=0; for _ in pairs(queue) do count=count+1 end; if count>=8 then return end
    entry={guid=guid,name=name,at=now,buffs={}}; queue[guid]=entry
  end
  entry.buffs[aura.spellId]=buff
  self:UpdateManualThanks()
end
function B:SendManualThanks(entry)
  if not entry or not self:ManualThanksAllowed() or self.action then return false end
  if not self.manualThanksQueue or self.manualThanksQueue[entry.guid]~=entry or GetTime()-entry.at>=15 then return false end
  if self:ThanksInGroup(entry.guid)~=false then self:DropManualThanks(entry.guid); return false end -- invited into the group since the offer
  if self:ManualThanksName(entry.guid)~=entry.name then self:DropManualThanks(entry.guid); return false end
  local text=self:ManualThanksText(entry); local send=C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  if not text or type(send)~="function" then return false end
  local cooldown=self.helperThankCooldowns or {}; self.helperThankCooldowns=cooldown
  if GetTime()-(cooldown["guid:"..entry.guid] or -1000)<60 or GetTime()-(cooldown["name:"..entry.name] or -1000)<60 then self:DropManualThanks(entry.guid); return false end
  local ok=pcall(send,text,"WHISPER",nil,entry.name)
  if not ok then self:ThanksTrace("manual whisper call failed"); return false end
  cooldown["guid:"..entry.guid]=GetTime(); cooldown["name:"..entry.name]=GetTime()
  -- Winning manual action cancels the automatic route for this provider.
  for key,pending in pairs(self.helperThankPending or {}) do if pending.guid==entry.guid then self.helperThankPending[key]=nil end end
  for i=#(self.helperThankQueue or {}),1,-1 do if self.helperThankQueue[i].guid==entry.guid then table.remove(self.helperThankQueue,i) end end
  self:ThanksTrace("manual whisper requested")
  self:DropManualThanks(entry.guid)
  return true
end
function B:ClearManualThanksBinding()
  -- In combat the safety driver clears the keys; forget the key list so they are rebound afterwards.
  if A.Combat() then self.manualThanksBindKey=nil; return end
  if self.manualThanksBound and self.manualThanksBindingOwner and type(ClearOverrideBindings)=="function" then pcall(ClearOverrideBindings,self.manualThanksBindingOwner) end
  self.manualThanksBound=nil; self.manualThanksBindKey=nil
end
-- Thanks has a separate safety owner because mounting must still block spells,
-- while allowing a user-triggered whisper. Commit restores ordinary buff bindings first.
local commit=B.Commit
function B:Commit(action,...)
  -- Only a real action takes the keys back. Commit(nil) leaves an on-screen THANK bound,
  -- so ordinary refreshes do not clear and re-set its bindings over and over.
  if action then self:ClearManualThanksBinding() end
  return commit(self,action,...)
end
function B:CreateManualThanksButton()
  if self.manualThanksButton or A.Combat() then return end
  local f=CreateFrame("Button","BuffTapManualThanks",UIParent,"BackdropTemplate")
  f:RegisterForClicks("AnyDown","AnyUp"); f:SetClampedToScreen(true)
  f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetAllPoints(); f.icon:SetTexture(ICON)
  f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f.title:SetPoint("BOTTOM",f,"BOTTOM",0,4)
  f.title:SetText("THANK"); f.title:SetTextColor(1,1,1); f.title:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE")
  f:SetScript("OnClick",function(_,button,down)
    if down or not f:IsShown() then return end
    local entry=f.entry
    if button=="RightButton" and entry then
      B.manualThanksDismissed=B.manualThanksDismissed or {}; B.manualThanksDismissed[entry.guid]=GetTime()+15
      B:DropManualThanks(entry.guid)
    elseif button=="LeftButton" then B:SendManualThanks(entry) end
  end)
  f:SetScript("OnEnter",function()
    if f.entry and GameTooltip then
      GameTooltip:SetOwner(f,"ANCHOR_RIGHT"); GameTooltip:SetText(B:Text("Thank %s",f.entry.name))
      GameTooltip:AddLine(B:ManualThanksText(f.entry) or B:Text("Message is too long."),1,1,1,true)
      GameTooltip:AddLine(B:Text("Use your regular BuffTap binding or click to whisper. Right-click to dismiss this thank-you."),.65,.7,.8,true); GameTooltip:Show()
    end
  end)
  f:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f:Hide(); self.manualThanksButton=f
  local owner=CreateFrame("Frame",nil,UIParent,"SecureHandlerStateTemplate")
  owner:SetAttribute("_onstate-safety",[[if newstate == "blocked" then self:ClearBindings() end]])
  if type(RegisterStateDriver)=="function" then
    local ok=pcall(RegisterStateDriver,owner,"safety","[combat][@player,dead][vehicleui][petbattle] blocked; ready")
    if ok then self.manualThanksBindingOwner=owner end
  end
end
-- Runs after every refresh and helper event (including every UNIT_AURA), so it only
-- does work when something changed: no new tables, timers or bindings on idle calls.
function B:HideManualThanks()
  self:ClearManualThanksBinding()
  local f=self.manualThanksButton
  if f and (f.entry or f:IsShown()) then f.entry=nil; f.layoutKey=nil; f:Hide() end
end
function B:UpdateManualThanks()
  local f=self.manualThanksButton
  if not self:ManualThanksAllowed() then
    self:ClearManualThanksBinding()
    if self.manualThanksQueue and next(self.manualThanksQueue) then self.manualThanksQueue={} end
    if self.manualThanksExpiry then self.manualThanksExpiry=nil; self:CancelTimer("manual-thanks-expire") end
    if f and (f.entry or f:IsShown()) then f.entry=nil; f.layoutKey=nil; f:Hide() end
    return
  end
  local entry,expiry; local now=GetTime()
  for guid,untilTime in pairs(self.manualThanksDismissed or {}) do if untilTime<=now then self.manualThanksDismissed[guid]=nil end end
  for guid,candidate in pairs(self.manualThanksQueue or {}) do
    if now-candidate.at>=15 then self.manualThanksQueue[guid]=nil
    else
      expiry=math.min(expiry or candidate.at+15,candidate.at+15)
      if not entry or candidate.at<entry.at then entry=candidate end
    end
  end
  -- Restart the expiry timer only when the earliest expiry actually changes.
  if expiry~=self.manualThanksExpiry then
    self.manualThanksExpiry=expiry
    self:CancelTimer("manual-thanks-expire")
    if expiry then self:StartTimer("manual-thanks-expire",math.max(.01,expiry-now),function() B.manualThanksExpiry=nil; B:UpdateManualThanks(); B:RequestRefresh("manual thanks expiry",0) end) end
  end
  if A.Combat() then
    -- The secure safety driver has already cleared the bindings; rebind fully after combat.
    self.manualThanksBindKey=nil
    if f and (f.entry or f:IsShown()) then f.entry=nil; f.layoutKey=nil; f:Hide() end
    return
  end
  if not entry or self.action or self.db.showReminder==false then self:HideManualThanks(); return end
  self:CreateManualThanksButton(); f=self.manualThanksButton; if not f then return end
  local layoutKey=table.concat({tostring(self.db.size),tostring(self.db.opacity),tostring(self.db.x),tostring(self.db.y),tostring(self.db.iconStyle),tostring(self:GameplayStrata("buff"))},"|")
  if f.layoutKey~=layoutKey or not f:IsShown() then
    f.layoutKey=layoutKey
    self:SetGameplayLayer(f,"buff"); f:SetSize(self.db.size,self.db.size); f:SetAlpha(self.db.opacity)
    f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
    if self.ApplyIconStyle then self:ApplyIconStyle(f,f.icon,self.db.iconStyle) end
  end
  f.entry=entry
  if self.button and self.button:IsShown() then self.button:Hide(); self.manaWaitVisible=nil end
  if not f:IsShown() then f:Show() end
  -- Rebinding fires UPDATE_BINDINGS for every addon, so only rebind when the keys change or after a clear.
  local bindKey=table.concat(self.db.keys or {},",")
  if (not self.manualThanksBound or self.manualThanksBindKey~=bindKey)
    and self.manualThanksBindingOwner and self.manualThanksBindingOwner:GetAttribute("state-safety")~="blocked" and type(SetOverrideBindingClick)=="function" and type(ClearOverrideBindings)=="function" then
    self:ClearManualThanksBinding()
    local cleared=pcall(ClearOverrideBindings,self.manualThanksBindingOwner)
    if cleared then
      self.manualThanksBound=true; self.manualThanksBindKey=bindKey
      for _,key in ipairs(self.db.keys or {}) do
        if type(key)=="string" and key~="" then pcall(SetOverrideBindingClick,self.manualThanksBindingOwner,true,key,"BuffTapManualThanks","LeftButton") end
      end
    end
  end
end
local refresh=B.Refresh
function B:Refresh(...)
  local result=refresh(self,...); self:UpdateManualThanks(); return result
end
local event=B.HelperEvent
function B:HelperEvent(kind,...)
  local result=event(self,kind,...)
  if kind=="PLAYER_REGEN_DISABLED" or kind=="PLAYER_ENTERING_WORLD" or kind=="ZONE_CHANGED_NEW_AREA" or kind=="GROUP_ROSTER_UPDATE" then self.manualThanksQueue={} end
  self:UpdateManualThanks(); return result
end

local diagnostics=B.SoloThanksDiagnostics
function B:SoloThanksDiagnostics(...)
  local out=diagnostics(self,...); local count=0
  for _ in pairs(self.manualThanksQueue or {}) do count=count+1 end
  out[#out+1]="Manual thanks: enabled="..tostring(self.db and self.db.manualThanks==true).." | queued="..count.." | visible="..tostring(self.manualThanksButton and self.manualThanksButton:IsShown() or false)
  return out
end
