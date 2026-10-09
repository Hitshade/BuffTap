-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ADDON,B = ...
local A = B.API
local function L(key,...) return B:Text(key,...) end
local function say(s) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff59d6b2BuffTap|r " .. L(s)) end end
B.Print = say

local function publicError(err)
  return A.Public(err) and type(err)=="string" and err or "unreadable error"
end

local function guarded(label,fn)
  local ok,err=pcall(fn)
  if not ok then
    B.lastError=tostring(label)..": "..publicError(err)
    B.dirty=true
  end
  return ok
end

function B:CancelTimer(slot)
  self.timers=self.timers or {}
  local timer=self.timers[slot]
  if timer and type(timer.Cancel)=="function" then pcall(timer.Cancel,timer) end
  self.timers[slot]=nil
end

function B:StartTimer(slot,delay,callback)
  self:CancelTimer(slot)
  if C_Timer and type(C_Timer.NewTimer)=="function" then
    local timer=C_Timer.NewTimer(delay,function() self.timers[slot]=nil; callback() end)
    self.timers[slot]=timer
  elseif C_Timer and type(C_Timer.After)=="function" then C_Timer.After(delay,callback)
  else error("timer API unavailable") end
end

local function shortTime(seconds)
  seconds=math.max(0,math.floor((tonumber(seconds) or 0)+0.5))
  if seconds<60 then return tostring(seconds).."s" end
  local m=math.floor(seconds/60); local s=seconds%60
  return s>0 and (tostring(m).."m"..tostring(s).."s") or (tostring(m).."m")
end

function B:UpdatePulse()
  local b=self.button
  if not b or not b.glow then return end
  b.glow:SetShown(self.db and (self.db.glow or self.db.pulse) or false)
  local ag=b.pulseAnimation
  if ag then
    local playing=false
    if type(ag.IsPlaying)=="function" then
      local ok,value=pcall(ag.IsPlaying,ag); playing=ok and value==true
    end
    if self.db and self.db.pulse and self.action then
      if not playing and type(ag.Play)=="function" then pcall(ag.Play,ag) end
    elseif playing and type(ag.Stop)=="function" then
      pcall(ag.Stop,ag)
      if b.glow.SetAlpha then b.glow:SetAlpha(1) end
    end
  elseif b.glow.SetAlpha then
    b.glow:SetAlpha(1)
  end
end

function B:CancelOverlayTimer()
  self:CancelTimer("overlay")
  self.overlayToken=(self.overlayToken or 0)+1
end

function B:UpdateOverlay()
  if self.UpdateBroker then self:UpdateBroker() end
  local b=self.button
  if not b then return end
  self:CancelOverlayTimer()
  local action=self.action
  if not action then
    if b.nameLabel then b.nameLabel:SetText("") end
    if b.label then b.label:SetText("") end
    if b.timerLabel then b.timerLabel:SetText("") end
    if b.groupLabel then b.groupLabel:SetText("") end
    return
  end
  if b.nameLabel then b.nameLabel:SetText(self.db.showBuffName and action.name or "") end
  if b.label then b.label:SetText(self.db.showTargetName and action.targetName or "") end
  if b.groupLabel then
    if action.manual then b.groupLabel:SetText("!")
    else b.groupLabel:SetText(self.db.showGroupBadge and action.groupCast and (action.groupCount and ("×"..tostring(action.groupCount)) or "G") or "") end
  end
  if b.timerLabel then
    if self.db.showTimer and action.needState=="expiring" and type(action.remaining)=="number" then
      local elapsed=math.max(0,GetTime()-(action.selectedAt or GetTime()))
      b.timerLabel:SetText(shortTime(math.max(0,action.remaining-elapsed)))
      local token=self.overlayToken
      if C_Timer and type(C_Timer.After)=="function" then
        pcall(B.StartTimer,B,"overlay",1,function()
          guarded("overlay timer",function()
            if token==B.overlayToken and B.action==action and not A.Combat() then B:UpdateOverlay() end
          end)
        end)
      end
    else b.timerLabel:SetText("") end
  end
end

function B:CreateButton()
  if self.button or A.Combat() then return end
  local okCreate,b=pcall(CreateFrame,"Button","BuffTapActionButton",UIParent,"SecureActionButtonTemplate,SecureHandlerStateTemplate")
  if not okCreate or not b then self.setupError="secure action button creation failed"; return end
  self.button=b
  b:Hide()
  b:SetFrameStrata("HIGH")
  b:SetClampedToScreen(true)
  b:RegisterForClicks("AnyDown","AnyUp")
  b:SetAttribute("useOnKeyDown",true)
  b:SetAttribute("checkselfcast",false)
  b:SetAttribute("checkfocuscast",false)
  b:SetAttribute("checkmouseovercast",false)
  local snippet=[[
    if newstate == "blocked" then
      self:SetAttribute("type1", nil)
      self:SetAttribute("spell", nil)
      self:SetAttribute("item", nil)
      self:SetAttribute("unit", nil)
      self:SetAttribute("target-slot", nil)
      self:ClearBindings()
      self:Hide()
    end
    -- No stale action is restored when combat ends. Lua must revalidate it.
  ]]
  if not pcall(b.SetAttribute,b,"_onstate-safety",snippet) then self.setupError="secure safety snippet unavailable"; return end
  if not RegisterStateDriver then self.setupError="secure state driver unavailable"; return end
  local ok = pcall(RegisterStateDriver,b,"safety","[combat][@player,dead][mounted][vehicleui][petbattle] blocked; ready")
  if not ok then self.setupError="secure state registration failed"; return end
  self.setupError=nil

  b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetAllPoints()
  b.glow=b:CreateTexture(nil,"OVERLAY"); b.glow:SetAllPoints()
  b.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight"); b.glow:SetBlendMode("ADD")
  b.nameLabel=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  b.nameLabel:SetPoint("BOTTOM",b,"TOP",0,5)
  b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  b.label:SetPoint("TOP",b,"BOTTOM",0,-5)
  b.timerLabel=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  b.timerLabel:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-3,3); b.timerLabel:SetJustifyH("RIGHT")
  b.groupLabel=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  b.groupLabel:SetPoint("TOPLEFT",b,"TOPLEFT",4,-3); b.groupLabel:SetTextColor(1,0.82,0.1)
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

  -- Pulse is a native UI animation when available: no Lua OnUpdate work.
  if b.glow and type(b.glow.CreateAnimationGroup)=="function" then
    local agOk,ag=pcall(b.glow.CreateAnimationGroup,b.glow)
    if agOk and ag and type(ag.CreateAnimation)=="function" then
      local ok1,a1=pcall(ag.CreateAnimation,ag,"Alpha")
      local ok2,a2=pcall(ag.CreateAnimation,ag,"Alpha")
      if ok1 and ok2 and a1 and a2 then
        pcall(a1.SetFromAlpha,a1,1); pcall(a1.SetToAlpha,a1,0.45); pcall(a1.SetDuration,a1,0.7); pcall(a1.SetOrder,a1,1)
        pcall(a2.SetFromAlpha,a2,0.45); pcall(a2.SetToAlpha,a2,1); pcall(a2.SetDuration,a2,0.7); pcall(a2.SetOrder,a2,2)
        if type(ag.SetLooping)=="function" then pcall(ag.SetLooping,ag,"REPEAT") end
        b.pulseAnimation=ag
      end
    end
  end

  b:SetScript("OnEnter",function()
    local action=B.action
    if A.Combat() or B:ReminderPauseReason() or not action or not action.valid or not GameTooltip then return end
    GameTooltip:SetOwner(b,"ANCHOR_RIGHT")
    if action.source=="weapon-reminder" then
      GameTooltip:SetText(action.name,1,0.82,0.1)
      GameTooltip:AddLine(action.targetName,0.4,1,0.8)
      GameTooltip:AddLine(L(action.reason),0.85,0.85,0.85,true)
      GameTooltip:AddLine(action.manual and L("Manual reminder only; no binding is installed.") or L("Scroll or click to apply your preferred weapon buff."),0.75,0.75,0.75,true)
    elseif action.source=="readiness" then
      if action.secureType=="item" and GameTooltip.SetItemByID then GameTooltip:SetItemByID(action.itemID); GameTooltip:AddLine(action.targetName,0.4,1,0.8)
      elseif not action.manual and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(action.id)
      else GameTooltip:SetText(action.name,1,0.82,0.1) end
      GameTooltip:AddLine(L(action.reason),0.85,0.85,0.85,true)
      GameTooltip:AddLine(action.manual and L("Manual reminder only; no click action or key binding.") or action.secureType=="item" and L("Click or use your BuffTap binding to use it.") or L("Click or use your BuffTap binding to cast."),0.4,1,0.8,true)
    elseif action.source=="consumable" then
      GameTooltip:SetText(action.name,1,0.82,0.1)
      GameTooltip:AddLine("Personal consumable | item "..tostring(action.itemID),0.4,1,0.8)
      GameTooltip:AddLine("Reason: "..tostring(action.reason or action.needState or "missing"),0.85,0.85,0.85)
    else
      if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(action.id) else GameTooltip:SetText(action.name) end
      GameTooltip:AddLine("Target: " .. action.targetName .. " (" .. action.target .. ") | " .. action.reason,0.4,1,0.8)
      GameTooltip:AddLine("Rank: " .. (action.rank~="" and action.rank or "not exposed") .. " | ID " .. action.id,1,1,1)
      if action.rangeSource then GameTooltip:AddLine("Range check: "..action.rangeSource,0.75,0.75,0.75) end
    end
    if B:HelperEnabled("helperDismiss") then GameTooltip:AddLine(L("Right-click: dismiss until zone change (restore in Helpers)."),0.8,0.8,0.8,true) end
    if B:HelperEnabled("helperQuick") and action.source=="consumable" then B:ShowQuickChoices(action) end
    GameTooltip:AddLine(table.concat(B.db.keys,", "),0.8,0.8,0.8)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)

  -- Never select a different action during PreClick. The displayed action is the action clicked.
  b:SetScript("PreClick",function(_,button)
    if button and button~="LeftButton" then return end
    local ok=guarded("click validation",function()
    if A.Combat() then return end
    local action=B.action
    local paused=B:ReminderPauseReason(); if paused then B:Commit(nil,paused); return end
    if not action then return end
    if B:HelperSuppressed(action) then B:Commit(nil,"dismissed"); return end
    if action.source=="readiness" then
      if action.key=="healthstone" or action.key=="soulstone" or action.key=="weaponstone" then B.readinessInventory=nil end -- explicit click: recheck carried stock/capacity
      if action.key=="soulstone" then B:InvalidateAura() end -- and fresh Soulstone coverage
      if not B:Validate(action) then B:Commit(nil,"readiness changed before click") end
      return
    end
    if action.source=="tracking" then
      if not B:TrackingStillNeeded(action) or not B:Validate(action) then B:Commit(nil,"tracking changed") end
      return
    end
    if action.source=="weapon-reminder" then
      if not B:ValidateWeaponReminder(action) then B:Commit(nil,"weapon reminder no longer needed") end
      return
    end
    if action.source=="consumable" then
      local valid=B:ValidateConsumable(action,true,true)
      if not valid then B:Commit(nil,"item click validation failed")
      else B:BeforeConsumableClick(action) end
      return
    end
    local valid=B:Validate(action)
    if not valid then B:Commit(nil,"click validation failed"); return end
    if action.groupCast and B.GroupReagents and B.GroupReagents[action.id] then
      if not B:RevalidateGroupAction(action) then
        B:Commit(nil,"group no longer needs this cast"); B:RequestRefresh("group click changed",0.05)
      end
      return
    end
    local def=B:FindBuff(action.key)
    local auras=B:GetAuras(action.target,true)
    if not auras or not def then B:Commit(nil,"action no longer verifiable"); return end
    if not B:BlessingActionAllowed(action) then B:Commit(nil,"blessing ownership changed before click"); return end
    local missing=B:Missing(def,action,auras,action.quickTarget and B:TargetRebuffSeconds(def) or nil)
    if not missing then B:Commit(nil,"action no longer missing") end
    end)
    if not ok and not A.Combat() then B:Commit(nil,"click validation unavailable") end
    if ok and not A.Combat() then B:BeginHelperAttempt(B.action) end
  end)
  b:SetScript("PostClick",function(_,button,down)
    if not A.Combat() and button=="RightButton" and not down and B:HelperEnabled("helperDismiss") then B:DismissHelper(B.action); return end
    if A.Combat() or (button and button~="LeftButton") then return end
    local action=B.action
    local paused=B:ReminderPauseReason(); if paused then B:Commit(nil,paused); return end
    if action then
      if action.source=="weapon-reminder" then B:AfterWeaponClick(action,down)
      elseif action.source=="readiness" then B:AfterReadinessClick(action,down)
      elseif action.source=="consumable" and B.AfterConsumableClick then B:AfterConsumableClick(action)
      elseif action.source~="weapon-reminder" then B:InvalidateAura(action.target) end
    end
    B.dirty=true
    B:RequestRefresh("post-click",action and action.source=="consumable" and 0.20 or 0.12)
  end)
end

function B:Commit(action,reason)
  if A.Combat() then self.dirty=true; return end
  local b=self.button
  if not b then return end
  if action and action.source=="consumable" and not self:ValidateConsumable(action,false,true) then action=nil; reason="item changed before preparation" end
  if action and action.source=="weapon-reminder" and not self:ValidateWeaponReminder(action) then action=nil; reason="weapon reminder changed before display" end
  if action and action.source=="readiness" and not self:Validate(action) then action=nil; reason="readiness changed before preparation" end
  if self.ApplyReminderStyle then self:ApplyReminderStyle(b) end
  local previous=self.action
  if self.quickChoices then self.quickChoices:Hide() end
  local appearance=table.concat({self.db.size,self.db.opacity,self.db.x,self.db.y,tostring(self.db.glow),tostring(self.db.pulse),
    tostring(self.db.showBuffName),tostring(self.db.showTargetName),tostring(self.db.showTimer),tostring(self.db.showGroupBadge),table.concat(self.db.keys,",")},"|")
  local secureMatches=false
  if action and previous and action.id==previous.id and action.source==previous.source and action.target==previous.target and action.targetGUID==previous.targetGUID and action.slot==previous.slot then
    if action.manual then
      secureMatches=action.key==previous.key and action.slot==previous.slot
        and b:GetAttribute("type1")==nil and b:GetAttribute("spell")==nil
        and b:GetAttribute("item")==nil and b:GetAttribute("unit")==nil
    elseif action.source=="readiness" and action.secureType=="item" then
      secureMatches=b:GetAttribute("type1")=="item" and b:GetAttribute("item")==action.itemToken and b:GetAttribute("unit")==action.target
    elseif action.source=="consumable" or (action.source=="weapon-reminder" and action.secureType=="item") then
      secureMatches=b:GetAttribute("type1")=="item" and b:GetAttribute("item")==action.itemToken
    else
      secureMatches=b:GetAttribute("type1")=="spell" and b:GetAttribute("spell")==action.id and b:GetAttribute("unit")==action.target
    end
  end
  if action and action.source=="weapon-reminder" and not action.manual then secureMatches=secureMatches and b:GetAttribute("target-slot")==action.slot end
  if secureMatches and self.appearance==appearance and b:GetAttribute("state-safety")~="blocked" then
    self.action=action; self.reason=reason
    self:UpdateOverlay(); self:UpdatePulse()
    return
  end

  self.appearance=appearance
  self:CancelOverlayTimer()
  self:CancelRangeTimer()
  -- Clear the secure payload before doing anything else. Even if the binding API
  -- unexpectedly disappears/fails on a beta build, the stale click has no action.
  b:Hide()
  b:SetAttribute("type1",nil); b:SetAttribute("spell",nil); b:SetAttribute("item",nil); b:SetAttribute("unit",nil); b:SetAttribute("target-slot",nil)
  self.action=nil; self.reason=reason
  if self.UpdateBroker then self:UpdateBroker() end
  if type(ClearOverrideBindings)~="function" then self.setupError="override binding API unavailable"; return end
  local cleared=pcall(ClearOverrideBindings,b)
  if not cleared then self.setupError="could not clear override bindings"; return end
  if b.timerLabel then b.timerLabel:SetText("") end
  if b.groupLabel then b.groupLabel:SetText("") end
  self:UpdatePulse()
  if not action or not action.valid or self.setupError then return end
  if b:GetAttribute("state-safety")=="blocked" then self.reason="secure safety state blocked"; return end

  -- Manual alerts deliberately have no protected action and install no
  -- override bindings. Clicking the icon only revalidates the warning.
  if action.manual then
    b:SetSize(self.db.size,self.db.size)
    b:ClearAllPoints(); b:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
    b:SetAlpha(self.db.opacity); b.icon:SetTexture(action.icon)
    b.nameLabel:SetText(self.db.showBuffName and action.name or "")
    b.label:SetText(self.db.showTargetName and action.targetName or "")
    self.action=action; self.reason=reason; b:Show()
    self:UpdateOverlay(); self:UpdatePulse()
    if self.db.sound and (not previous or previous.key~=action.key) and GetTime()-(self.lastSound or -100)>=(self.db.soundInterval or 5) then
      self:PlayAlert("reminder")
      self.lastSound=GetTime()
    end
    return
  end

  if action.source=="weapon-reminder" then b:SetAttribute("target-slot",action.slot) end
  if action.source=="readiness" and action.secureType=="item" then
    -- Item used on an explicit unit (Soulstone). Never relies on the current target.
    b:SetAttribute("item",action.itemToken)
    b:SetAttribute("unit",action.target)
    b:SetAttribute("type1","item")
    if b:GetAttribute("item")~=action.itemToken or b:GetAttribute("unit")~=action.target or b:GetAttribute("type1")~="item" then
      b:SetAttribute("type1",nil); b:SetAttribute("item",nil); b:SetAttribute("unit",nil); self.reason="secure item attribute verification failed"; return
    end
  elseif action.source=="consumable" or (action.source=="weapon-reminder" and action.secureType=="item") then
    b:SetAttribute("item",action.itemToken)
    b:SetAttribute("type1","item")
    if b:GetAttribute("item")~=action.itemToken or b:GetAttribute("type1")~="item" then
      b:SetAttribute("type1",nil); b:SetAttribute("item",nil); self.reason="secure item attribute verification failed"; return
    end
  else
    b:SetAttribute("spell",action.id)
    b:SetAttribute("unit",action.target)
    b:SetAttribute("type1",action.secureType)
    if b:GetAttribute("spell")~=action.id or b:GetAttribute("unit")~=action.target or b:GetAttribute("type1")~="spell" then
      b:SetAttribute("type1",nil); self.reason="secure spell attribute verification failed"; return
    end
  end
  self.bindingErrors={}
  for _,key in ipairs(self.db.keys) do
    if type(key)=="string" and key~="" then
      local ok=pcall(SetOverrideBindingClick,b,true,key,"BuffTapActionButton","LeftButton")
      if not ok then self.bindingErrors[#self.bindingErrors+1]=key end
    end
  end
  b:SetSize(self.db.size,self.db.size)
  b:ClearAllPoints(); b:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
  b:SetAlpha(self.db.opacity)
  b.icon:SetTexture(action.icon)
  b.nameLabel:SetText(self.db.showBuffName and action.name or "")
  b.label:SetText(self.db.showTargetName and action.targetName or "")
  self.action=action
  b:Show()
  self:UpdateOverlay(); self:UpdatePulse()
  if self.db.sound and (not previous or previous.key~=action.key or previous.target~=action.target)
    and GetTime()-(self.lastSound or -100)>=(self.db.soundInterval or 5) then
    self:PlayAlert("reminder")
    self.lastSound=GetTime()
  end
end

-- ---------- Event-driven scheduling ----------
-- Forever timers are cancelled by purpose; tokens also guard older After-only clients.
function B:CancelRefreshTimer()
  self:CancelTimer("refresh")
  self.refreshToken=(self.refreshToken or 0)+1
  self.refreshDue=nil; self.refreshReason=nil; self.fallbackRefresh=nil
end

function B:ScheduleRefresh(delay,reason)
  if not self.db then return end
  if A.Combat() then self.dirty=true; self.pendingReason=reason or self.pendingReason; return end
  delay=math.max(0.03,tonumber(delay) or 0.05)
  local now=GetTime(); local due=now+delay
  if self.refreshDue and self.refreshDue<=due+0.02 then return end
  self:CancelRefreshTimer()
  local token=self.refreshToken
  self.refreshDue=due; self.refreshReason=reason
  if C_Timer and type(C_Timer.After)=="function" then
    local ok=pcall(B.StartTimer,B,"refresh",delay,function()
      guarded("refresh timer",function()
        if token~=B.refreshToken then return end
        B.refreshDue=nil; B.refreshReason=nil
        B:Refresh(false)
      end)
    end)
    if ok then return end
  end
  -- Compatibility fallback only. WoW Forever 1.60.1 has C_Timer.After.
  self.fallbackRefresh={token=token,remaining=delay}
end

function B:RequestRefresh(reason,delay)
  if not self.db then return end
  if A.Combat() then self.dirty=true; self.pendingReason=reason or self.pendingReason; return end
  self:ScheduleRefresh(delay or 0.05,reason)
end

-- Keep long threshold/cooldown wake-ups separate from short event debounces.
-- This prevents routine UNIT_AURA/roster events from abandoning and recreating
-- long C_Timer.After callbacks over and over.
function B:CancelWakeTimer()
  self:CancelTimer("wake")
  self.wakeToken=(self.wakeToken or 0)+1
  self.wakeDue=nil; self.wakeReason=nil
end

function B:ScheduleWake(delay,reason)
  if not self.db then return end
  if self.SyncReadiness then self:SyncReadiness() end
  if A.Combat() then self.dirty=true; return end
  delay=math.max(0.05,tonumber(delay) or 0.05)
  if not (C_Timer and type(C_Timer.After)=="function") then
    return self:ScheduleRefresh(delay,reason)
  end
  local due=GetTime()+delay
  -- An existing earlier wake is safe and cheaper to keep. If state changes,
  -- that earlier callback simply revalidates and schedules the next exact wake.
  if self.wakeDue and self.wakeDue<=due+0.05 then return end
  self.wakeToken=(self.wakeToken or 0)+1
  local token=self.wakeToken
  self.wakeDue=due; self.wakeReason=reason
  pcall(B.StartTimer,B,"wake",delay,function()
    guarded("wake timer",function()
      if token~=B.wakeToken then return end
      B.wakeDue=nil; B.wakeReason=nil
      if A.Combat() then B.dirty=true; return end
      B:Refresh(false)
    end)
  end)
end

-- Target unit metadata/auras can settle a fraction after PLAYER_TARGET_CHANGED on
-- beta/live service conditions. Recheck twice with one-shot timers only when the
-- optional friendly-target mode is enabled. Every target change invalidates the
-- generation, so a callback can never apply to a later target.
function B:ScheduleTargetSettling()
  self:CancelTimer("target0.18"); self:CancelTimer("target0.65")
  self.targetSettleToken=(self.targetSettleToken or 0)+1
  local token=self.targetSettleToken
  if not (self.db and self.db.friendlyTarget) or A.Combat() or not (C_Timer and type(C_Timer.After)=="function") then return end
  for _,delay in ipairs({0.18,0.65}) do
    pcall(B.StartTimer,B,"target"..delay,delay,function()
      guarded("target settle",function()
        if token~=B.targetSettleToken or A.Combat() or not (B.db and B.db.friendlyTarget) then return end
        if B.stats then B.stats.targetRetries=(B.stats.targetRetries or 0)+1 end
        B:InvalidateAura("target")
        B:Refresh(false)
      end)
    end)
  end
end

function B:CancelRangeTimer()
  self:CancelTimer("range")
  self.rangeToken=(self.rangeToken or 0)+1
end

-- Range is the only relevant state without a dependable event. Keep it cheap:
-- one 1 Hz range/identity pass, never a full raid aura scan.
function B:ScheduleRangeHeartbeat(action)
  self:CancelRangeTimer()
  if A.Combat() or not (C_Timer and type(C_Timer.After)=="function") then return end
  local blocked = not action and self.rangeBlockedActions or nil
  if action and action.target=="player" then return end
  if not action and (type(blocked)~="table" or #blocked==0) then return end
  local token=self.rangeToken
  local ok=pcall(B.StartTimer,B,"range",1,function()
    guarded("range timer",function()
      if token~=B.rangeToken or A.Combat() then return end
      if action then
        if B.action~=action then return end
        local eligible,why=B:TargetEligible(action,true)
        if not eligible then B:RequestRefresh(why or "range/target changed",0.03); return end
        B:ScheduleRangeHeartbeat(action)
        return
      end
      local current=B.rangeBlockedActions or blocked
      for _,candidate in ipairs(current) do
        local eligible=B:TargetEligible(candidate,true)
        if eligible then B:RequestRefresh("out-of-range target returned",0.03); return end
      end
      B:ScheduleRangeHeartbeat(nil)
    end)
  end)
  if not ok then self:ScheduleRefresh(1,"range timer fallback") end
end

function B:ProfileRecord(startMs)
  if not startMs or not self.profileEnabled or type(debugprofilestop)~="function" then return end
  local ok,finish=pcall(debugprofilestop)
  if not ok or type(finish)~="number" then return end
  local ms=math.max(0,finish-startMs)
  local p=self.profileStats or {count=0,total=0,max=0,last=0}
  p.count=p.count+1; p.total=p.total+ms; p.last=ms; if ms>p.max then p.max=ms end
  self.profileStats=p
end

function B:Refresh(captureDiagnostics)
  if not self.db then return end
  if self.SyncReadiness then self:SyncReadiness() end
  if A.Combat() then self.dirty=true; return end
  if self.stats then self.stats.refreshes=(self.stats.refreshes or 0)+1 end
  self:CancelRefreshTimer()
  local profileStart
  if self.profileEnabled and type(debugprofilestop)=="function" then
    local ok,value=pcall(debugprofilestop); if ok and type(value)=="number" then profileStart=value end
  end

  local createOK,createErr=pcall(self.CreateButton,self)
  if not createOK then self.setupError="button setup: "..publicError(createErr) end
  if self.setupError then self.reason=self.setupError; self:ProfileRecord(profileStart); return end
  if self.bookDirty or not self.book then
    local bookOK,bookErr=pcall(self.ScanBook,self)
    if not bookOK then
      self.bookIssue="spellbook scan: "..publicError(bookErr); self.bookDirty=true
    else
      -- Keep retrying a partial/not-ready book until it completes.
      self.bookDirty=self.bookIssue~=nil
    end
  end
  self.captureDiagnostics=captureDiagnostics==true
  if self.captureDiagnostics then self.diagnostics={} end
  local ok,action,reason=pcall(self.Select,self)
  self.captureDiagnostics=false
  if not ok then
    self.lastError=publicError(action)
    action=nil; reason="selection error (see debug)"
  else self.lastError=nil end
  local commitOK,commitErr=pcall(self.Commit,self,action,reason)
  if not commitOK then
    self.lastError="commit: "..publicError(commitErr)
    self.reason="secure update error (see diagnostics)"
    self.action=nil
    if self.button and not A.Combat() then
      pcall(self.button.Hide,self.button)
      pcall(self.button.SetAttribute,self.button,"type1",nil)
      pcall(self.button.SetAttribute,self.button,"spell",nil)
      pcall(self.button.SetAttribute,self.button,"item",nil)
      pcall(self.button.SetAttribute,self.button,"unit",nil)
      pcall(self.button.SetAttribute,self.button,"target-slot",nil)
      if type(ClearOverrideBindings)=="function" then pcall(ClearOverrideBindings,self.button) end
    end
  end
  self.dirty=false; self.pendingReason=nil
  if self.SyncSupplies then self:SyncSupplies() end

  -- Exact wake-up for the next aura crossing a rebuff threshold or cooldown end.
  -- Long wakes live on their own timer channel so short event debounces do not churn them.
  if self.nextWakeDelay then self:ScheduleWake(self.nextWakeDelay+0.03,"scheduled threshold/cooldown")
  else self:CancelWakeTimer() end
  if self.bookIssue or self.dataPending then
    self.dataRetries=(self.dataRetries or 0)+1
    if self.dataRetries<=5 then self:ScheduleRefresh(math.min(16,2^(self.dataRetries-1)),"spell data/book retry") end
  else self.dataRetries=0 end
  if action and not action.manual then self:ScheduleRangeHeartbeat(action)
  elseif self.rangeBlocked then
    if C_Timer and type(C_Timer.After)=="function" then self:ScheduleRangeHeartbeat(nil)
    else self:ScheduleRefresh(1,"out-of-range recheck") end
  end
  self:ProfileRecord(profileStart)
end

function B:IsWatchedUnit(unit)
  if not A.Public(unit) or type(unit)~="string" then return false end
  if unit=="player" then return true end
  if self.db and (self.db.group or (self.ReadinessEnabled and self:ReadinessEnabled("soulstone"))) and (unit:match("^party%d+$") or unit:match("^raid%d+$")) then return true end
  if unit=="target" and self.db and self.db.friendlyTarget then
    return A.Call(UnitExists,"target")==true and A.Call(UnitCanAssist,"player","target")==true
  end
  return false
end

function B:DiagnosticsLines()
  local out={}
  out[#out+1]="State: " .. (A.Combat() and "combat / secure suspension" or (self.reason or "initializing"))
  local a=self.action
  if a then
    out[#out+1]="Next: "..tostring(a.name or "Unknown action").." -> "..tostring(a.targetName or a.target or "Unknown target").." ["..tostring(a.target or "unknown").."]"
    out[#out+1]="Reason: "..tostring(a.reason).." | range: "..tostring(a.rangeSource or "not checked")
  else out[#out+1]="Next: none" end
  if self.refreshDue then out[#out+1]="Next event scan: "..string.format("%.1fs",math.max(0,self.refreshDue-GetTime())).." ("..tostring(self.refreshReason or "scheduled")..")" end
  if self.wakeDue then out[#out+1]="Next exact wake: "..string.format("%.1fs",math.max(0,self.wakeDue-GetTime())).." ("..tostring(self.wakeReason or "threshold/cooldown")..")" end
  out[#out+1]="C_Timer.After: "..tostring(C_Timer and type(C_Timer.After)=="function").." | spell range: "..tostring(C_Spell and type(C_Spell.IsSpellInRange)=="function")
  out[#out+1]="Consumables: "..(self.db and self.db.consumablesEnabled and "on" or "off").." | item count: "..tostring(C_Item and type(C_Item.GetItemCount)=="function").." | secure item provider: "..tostring(type(self.SelectConsumable)=="function")
  if self.WeaponReminderClass then out[#out+1]="Weapon reminder: "..self:WeaponReminderSummary()..(self.db.weaponApply and " | scroll application enabled" or " | manual alerts") end
  if self.db and self.CampState then
    local camp=self:CampState()
    out[#out+1]="Camp Benefits: "..(camp.active and (camp.remaining and ("active ("..shortTime(camp.remaining)..")") or "active") or (camp.unknown and "unreadable" or "not active"))
    if camp.benefits and #camp.benefits>0 then
      local names={}; for _,benefit in ipairs(camp.benefits) do names[#names+1]=benefit.name end
      out[#out+1]="Camp additions granted: "..table.concat(names,", ")
    end
  end
  if self.ReadinessSummary then out[#out+1]=self:ReadinessSummary() end
  if self.lastError then out[#out+1]="Last protected error: "..self.lastError end
  if self.stats then
    local x=self.stats
    out[#out+1]=string.format("Work: refresh %d | select %d | aura API %d (cache %d) | roster %d (cache %d)",
      x.refreshes or 0,x.selects or 0,x.auraScans or 0,x.auraHits or 0,x.rosterBuilds or 0,x.rosterHits or 0)
    out[#out+1]=string.format("Spell work: rank builds %d | rank cache %d | range checks %d | target settle %d",
      x.resolveBuilds or 0,x.resolveHits or 0,x.rangeChecks or 0,x.targetRetries or 0)
    out[#out+1]=string.format("Item work: inventory rebuild %d | metadata requests %d | consumable selects %d | weapon reads %d",
      x.itemCountRefreshes or 0,x.itemInfoLoads or 0,x.consumableSelects or 0,x.weaponReads or 0)
  else
    out[#out+1]="Work counters: off"
  end
  if self.profileStats then
    local p=self.profileStats; local avg=p.count>0 and p.total/p.count or 0
    out[#out+1]=string.format("Profiler: %d scans | last %.3f ms | avg %.3f ms | max %.3f ms",p.count,p.last,avg,p.max)
  else out[#out+1]="Profiler: off" end
  return out
end

function B:Status(verbose)
  if verbose and self.db and not A.Combat() then self:Refresh(true) end
  say("v" .. self.version .. " | " .. (A.Combat() and "combat: disabled; refresh on exit" or self.reason or "initializing"))
  say("Binding: " .. (#self.db.keys>0 and table.concat(self.db.keys,", ") or "none"))
  say("Rebuff default: " .. tostring(self.db.seconds) .. " seconds")
  say("Friendly target buffing: " .. (self.db.friendlyTarget and "on" or "off") .. " | default target refresh: " .. tostring(self.db.targetSeconds or 300) .. " seconds")
  say("Consumables: " .. (self.db.consumablesEnabled and "on" or "off") .. " | curated data build " .. tostring(self.ForeverDataBuild or "unknown"))
  if self.db.group then
    local groups={}
    for i=1,8 do
      local state=self.GroupColumnState and self:GroupColumnState(i) or (self.db.raidGroups[i] and "on" or "off")
      if state=="on" then groups[#groups+1]=tostring(i) elseif state=="mixed" then groups[#groups+1]=tostring(i).."*" end
    end
    say("Group buffing: on | groups: " .. (#groups>0 and table.concat(groups,",") or "none") .. " | * = mixed assignment")
  else say("Group buffing: off") end
  local a=self.action
  if a and not A.Combat() then
    say("Next: " .. a.name .. " -> " .. a.targetName .. " | " .. a.reason .. " | range="..tostring(a.rangeSource or "n/a"))
  end
  if verbose then
    local version,build,_,toc=GetBuildInfo()
    say("Client: " .. tostring(version) .. " build " .. tostring(build) .. " interface " .. tostring(toc))
    say("APIs: book=" .. tostring(C_SpellBook and type(C_SpellBook.IsSpellKnown)=="function")
      .. ", auras=" .. tostring(C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex)=="function")
      .. ", spellRange=" .. tostring(C_Spell and type(C_Spell.IsSpellInRange)=="function")
      .. ", bookRange=" .. tostring(C_SpellBook and type(C_SpellBook.IsSpellBookItemInRange)=="function")
      .. ", timer=" .. tostring(C_Timer and type(C_Timer.After)=="function")
      .. ", itemCount=" .. tostring(C_Item and type(C_Item.GetItemCount)=="function")
      .. ", itemUse=" .. tostring(C_Item and type(C_Item.IsUsableItem)=="function")
      .. ", secureDriver=" .. tostring(type(RegisterStateDriver)=="function"))
    if self.bookIssue then say("Book: " .. self.bookIssue) end
    if self.lastError then say("Last error: "..self.lastError) end
    for _,line in ipairs(self.diagnostics or {}) do say(line) end
    for _,key in ipairs(self.bindingErrors or {}) do say("Binding failed: " .. key) end
    for _,key in ipairs(self.db.keys) do
      local actual=A.Call(GetBindingAction,key,false)
      say("Base binding " .. key .. ": " .. (A.Text(actual) and actual or "unavailable / unbound"))
      local failed=false
      for _,bad in ipairs(self.bindingErrors or {}) do if bad==key then failed=true; break end end
      if self.action and not self.action.manual and not failed then say("BuffTap secure override " .. key .. ": assigned (may be overridden by another addon)")
      elseif failed then say("BuffTap secure override " .. key .. ": failed")
      else say("BuffTap secure override " .. key .. ": inactive (no buff action)") end
    end
    for _,event in ipairs(self.unsupportedEvents or {}) do say("Unsupported event: " .. event) end
    if self.stats then
      local x=self.stats
      say(string.format("Work: refresh=%d select=%d auraAPI=%d auraCache=%d rosterBuild=%d rosterCache=%d rankBuild=%d rankCache=%d range=%d targetSettle=%d",
        x.refreshes or 0,x.selects or 0,x.auraScans or 0,x.auraHits or 0,x.rosterBuilds or 0,x.rosterHits or 0,x.resolveBuilds or 0,x.resolveHits or 0,x.rangeChecks or 0,x.targetRetries or 0))
      say(string.format("Item work: inventory=%d metadata=%d selections=%d weapon=%d readiness=%d",x.itemCountRefreshes or 0,x.itemInfoLoads or 0,x.consumableSelects or 0,x.weaponReads or 0,x.readinessBagScans or 0))
    end
    if self.profileStats then
      local p=self.profileStats; local avg=p.count>0 and p.total/p.count or 0
      say(string.format("Profiler: %d scans | last %.3f ms | avg %.3f ms | max %.3f ms",p.count,p.last,avg,p.max))
    end
  end
end

-- ---------- Events ----------
local f=CreateFrame("Frame")
B.events=f
B.unsupportedEvents={}
local events={"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED",
  "PLAYER_DEAD","PLAYER_ALIVE","PLAYER_TARGET_CHANGED","UNIT_AURA","SPELLS_CHANGED",
  "PLAYER_TALENT_UPDATE","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_SPECIALIZATION_CHANGED","GROUP_ROSTER_UPDATE",
  "ZONE_CHANGED_NEW_AREA","PLAYER_LEVEL_UP","SPELL_DATA_LOAD_RESULT","SPELL_TEXT_UPDATE","UNIT_SPELLCAST_SUCCEEDED",
  "UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","SPELL_UPDATE_COOLDOWN","UNIT_POWER_UPDATE",
  "PLAYER_EQUIPMENT_CHANGED","WEAPON_ENCHANT_CHANGED","WEAPON_SLOT_CHANGED","PLAYER_MOUNT_DISPLAY_CHANGED","PLAYER_UPDATE_RESTING","UPDATE_SHAPESHIFT_FORM","UPDATE_BINDINGS",
  "BAG_UPDATE_DELAYED","ITEM_DATA_LOAD_RESULT","UI_ERROR_MESSAGE","MINIMAP_UPDATE_TRACKING","UNIT_CONNECTION",
  "ADDON_RESTRICTION_STATE_CHANGED","UNIT_AURA_BLOCKED","UNIT_AURA_BLOCK_LIST_CLEARED"}
local playerOnlyEvents={UNIT_POWER_UPDATE=true,UNIT_SPELLCAST_SUCCEEDED=true,UNIT_SPELLCAST_FAILED=true,UNIT_SPELLCAST_INTERRUPTED=true}
for _,event in ipairs(events) do
  local registered=false
  if playerOnlyEvents[event] and type(f.RegisterUnitEvent)=="function" then
    local ok,result=pcall(f.RegisterUnitEvent,f,event,"player")
    registered=ok and result~=false
  end
  if not registered then
    local ok,result=pcall(f.RegisterEvent,f,event)
    registered=ok and result~=false
  end
  if not registered then B.unsupportedEvents[#B.unsupportedEvents+1]=event end
end

local bookEvents={SPELLS_CHANGED=true,PLAYER_LOGIN=true,PLAYER_ENTERING_WORLD=true,PLAYER_TALENT_UPDATE=true,
  SPELL_DATA_LOAD_RESULT=true,SPELL_TEXT_UPDATE=true,PLAYER_SPECIALIZATION_CHANGED=true,ACTIVE_TALENT_GROUP_CHANGED=true,PLAYER_LEVEL_UP=true}
local castEvents={UNIT_SPELLCAST_SUCCEEDED=true,UNIT_SPELLCAST_FAILED=true,UNIT_SPELLCAST_INTERRUPTED=true}

local function handleEvent(_,event,arg,castGUID,spellID)
  if event=="ADDON_LOADED" then if arg==ADDON then B:InitDB() end; if B.SyncEditMode then B:SyncEditMode() end; return end
  if not B.db then return end
    if event=="PLAYER_REGEN_DISABLED" and B.SuspendItemDataRetries then B:SuspendItemDataRetries() end
  if event=="PLAYER_REGEN_ENABLED" and B.ResumeItemDataRetries then B:ResumeItemDataRetries() end
local itemRequested=event=="ITEM_DATA_LOAD_RESULT" and A.Number(arg) and ((B.itemRequests and B.itemRequests[arg]) or (B.itemRequestState and B.itemRequestState[arg]))
  if itemRequested and B.ItemDataResult then
    B:ItemDataResult(arg,castGUID)
    B.readinessInventory=nil -- Item completion also releases cached Healthstone metadata.
  end
  if B.SuppliesEvent and B:SuppliesEvent(event,arg) then return end
  if B.ReadinessEvent then
    local ok,handled=pcall(B.ReadinessEvent,B,event,arg,castGUID,spellID)
    if not ok then B.readinessStatus="Class readiness event unavailable"
    elseif handled then return end
  end
  if event=="PLAYER_MOUNT_DISPLAY_CHANGED" or event=="PLAYER_UPDATE_RESTING" then
    if B.InvalidateSupplies then B:InvalidateSupplies(false) end
    if B.UpdateSupplyBadge then B:UpdateSupplyBadge() end
    if A.Combat() then B.dirty=true else B:Refresh(false) end
    return
  end
  if B.HelperEvent then B:HelperEvent(event,arg,castGUID,spellID) end
  if event=="UI_ERROR_MESSAGE" then return end
  if event=="MINIMAP_UPDATE_TRACKING" and not B:HelperEnabled("helperTracking") and not B:HelperEnabled("helperTreasure") then return end

  if event=="PLAYER_TARGET_CHANGED" then
    B:InvalidateAura("target")
    if not B.db.friendlyTarget then return end
    -- Clear the old target's secure action first. Then do an immediate scan for
    -- responsiveness and two tiny one-shot settling retries for beta/server lag.
    if not A.Combat() then
      B:Commit(nil,"target changed")
      B:Refresh(false)
      B:ScheduleTargetSettling()
    else
      B.targetSettleToken=(B.targetSettleToken or 0)+1
      B.dirty=true
    end
    return
  elseif event=="BAG_UPDATE_DELAYED" then
    if B.ObserveConsumableUse then B:ObserveConsumableUse() end
    if B.InvalidateConsumables then B:InvalidateConsumables() end
    if not A.Combat() then
      if B.options and B.options:IsShown() then B:Options() end
      if B.itemPicker and B.itemPicker:IsShown() then B:UpdateConsumablePicker() end
    end
    if not B.db.consumablesEnabled and not B.db.group and not B.powerBlocked and not (B.WeaponInventoryRelevant and B:WeaponInventoryRelevant()) then return end
  elseif event=="ITEM_DATA_LOAD_RESULT" then
    if not itemRequested then return end
    if B.InvalidateConsumables then B:InvalidateConsumables(arg) end
  elseif event=="UNIT_AURA" then
    if not B:IsWatchedUnit(arg) and not (B:HelperEnabled("helperCoverage") and A.Text(arg) and arg:match("^party[1-4]$")) then return end
    B:InvalidateAura(arg)
  elseif event=="UNIT_CONNECTION" then
    if A.Text(arg) then B:InvalidateAura(arg) end
  elseif event=="GROUP_ROSTER_UPDATE" then
    local n=A.Call(GetNumSubgroupMembers)
    if A.Call(IsInRaid)==false and A.Number(n) and n==0 then B.blessingPlayers=nil end
    B:InvalidateRoster(); B:InvalidateAura()
  elseif event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
    B:InvalidateRoster(); B:InvalidateAura(); if B.InvalidateConsumables then B:InvalidateConsumables() end
  elseif event=="PLAYER_REGEN_ENABLED" then
    -- Auras may have changed while ordinary Lua scanning was suspended in combat.
    B:InvalidateAura()
  elseif event=="ADDON_RESTRICTION_STATE_CHANGED" or event=="UNIT_AURA_BLOCKED" or event=="UNIT_AURA_BLOCK_LIST_CLEARED" then
    -- Never reuse pre-restriction aura snapshots after the client's secrecy state changes.
    B:InvalidateAura()
  end
  if event=="SPELL_DATA_LOAD_RESULT" and (not A.Number(arg) or not (B.requested and B.requested[arg])) then return end
  if event=="UNIT_POWER_UPDATE" and (arg~="player" or not B.powerBlocked) then return end
  if event=="SPELL_UPDATE_COOLDOWN" and not B.cooldownBlocked then return end
  if castEvents[event] and arg~="player" then return end
  if event=="UNIT_SPELLCAST_SUCCEEDED" and B.ObserveConsumableUse then B:ObserveConsumableUse(spellID) end

  if event=="PLAYER_REGEN_DISABLED" then
    B.dirty=true; B.pendingReason="combat"
    B:CancelRefreshTimer(); B:CancelWakeTimer(); B:CancelRangeTimer(); B:CancelOverlayTimer(); B.targetSettleToken=(B.targetSettleToken or 0)+1
    B:CancelTimer("target0.18"); B:CancelTimer("target0.65")
    B.action=nil; B.reason="combat: suspended"
    if B.UpdateBroker then B:UpdateBroker() end
    if GameTooltip then GameTooltip:Hide() end
    return
  end

  if bookEvents[event] then B.dataRetries=0; B.bookDirty=true; B.rankChoiceCache={}; B.coverCache={} end
  if event=="UPDATE_BINDINGS" then B.appearance=nil end
  if event=="PLAYER_LOGIN" or event=="PLAYER_ENTERING_WORLD" then
    if B.RegisterOptionsCategory then B:RegisterOptionsCategory() end
    B:Refresh(false)
    if B.SyncEditMode then B:SyncEditMode() end
    if B.ScheduleWelcome then B:ScheduleWelcome() end
    return
  end
  if event=="PLAYER_REGEN_ENABLED" then B:Refresh(false); if B.ScheduleWelcome then B:ScheduleWelcome() end; return end
  B.dirty=true
  B:RequestRefresh(event,0.05)
end

f:SetScript("OnEvent",function(...)
  local ok,err=pcall(handleEvent,...)
  if not ok then
    B.lastError="event handler: "..publicError(err)
    B.dirty=true
    if B.db and not A.Combat() then pcall(B.ScheduleRefresh,B,0.25,"event error recovery") end
  end
end)

-- Only installed on builds missing C_Timer.After. Forever 1.60.1 does not use it.
if not (C_Timer and type(C_Timer.After)=="function") then
  f:SetScript("OnUpdate",function(_,dt)
    local pending=B.fallbackRefresh
    if not pending or A.Combat() then return end
    pending.remaining=pending.remaining-dt
    if pending.remaining<=0 then
      B.fallbackRefresh=nil
      if pending.token==B.refreshToken then B.refreshDue=nil; B.refreshReason=nil; B:Refresh(false) end
    end
  end)
end

-- ---------- Slash commands ----------
SLASH_BUFFTAP1="/bufftap"
SLASH_BUFFTAP2="/bt"
SlashCmdList.BUFFTAP=function(text)
  if not B.db then B:InitDB() end
  local cmd,arg=(text or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd=cmd:lower()
  if cmd=="debug" or cmd=="status" then B:Status(cmd=="debug"); return end
  if cmd=="profile" then
    local v=arg:lower()
    if v=="on" then B.profileEnabled=true; B.profileStats=nil; B:ResetStats(); say("Refresh profiler enabled for this session.")
    elseif v=="off" then B.profileEnabled=false; B.profileStats=nil; B.stats=nil; say("Refresh profiler disabled.")
    elseif v=="reset" then B.profileStats=nil; if B.profileEnabled then B:ResetStats() else B.stats=nil end; say("Refresh profiler reset.")
    else say("Usage: /bt profile on | off | reset") end
    return
  end
  if A.Combat() then say("Settings and refresh are available after combat."); return end
  if cmd=="" or cmd=="config" then B:Options(); return
  elseif cmd=="helpers" then B:HelperOptions(); return
  elseif cmd=="supplies" then B:ShowSuppliesOptions(); return
  elseif cmd=="supplycheck" then B:ReportSupplies(); return
  elseif cmd=="restore" then B:RestoreHelpers(); return
  elseif cmd=="settings" and B.OpenOptionsCategory then B:OpenOptionsCategory(); return
  elseif cmd=="bind" then
    if arg=="" then B:CaptureBinding(); return end
    local keys={}; for key in arg:upper():gmatch("[^,%s]+") do keys[#keys+1]=key end; B.db.keys=B:NormalizeBindings(keys)
  elseif cmd=="unbind" then B.db.keys={}
  elseif cmd=="reset" then BuffTapDB=nil; B:InitDB(); B.helperDismissed={}; B.helperThankSeen=nil; B.bookDirty=true; B.resolveCache=nil; B.rankChoiceCache=nil; B.coverCache=nil; B:InvalidateRoster(); B:InvalidateAura(); if B.options then B.options:Hide() end
  elseif cmd=="toggle" then B.db.enabled=not B.db.enabled
  elseif cmd=="refresh" then B.bookDirty=true
  elseif cmd=="enable" or cmd=="disable" then
    local found=false
    for _,b in ipairs(B:ClassList()) do if b.key==arg then B.db.buffs[arg]=cmd=="enable"; found=true end end
    if not found then say("Unknown buff key; /bt config lists available buffs."); return end
  elseif cmd=="priority" then
    local key,n=arg:match("^(%S+)%s+(%d+)$")
    if not key then say("Usage: /bt priority motw 1"); return end
    B.db.priorities[key]=math.max(1,tonumber(n) or 1)
  elseif cmd=="position" then
    local x,y=arg:match("^([%-%.%d]+)%s+([%-%.%d]+)$")
    if not tonumber(x) or not tonumber(y) then say("Usage: /bt position 0 -180"); return end
    B.db.x,B.db.y=tonumber(x),tonumber(y); B:InitDB()
  elseif cmd=="rebuff" then
    local buffKey,value=arg:match("^(%S+)%s+(%d+)$")
    if buffKey then
      value=tonumber(value); local def=B:FindBuff(buffKey)
      if not def or def.singleKey then say("Usage: /bt rebuff 45 OR /bt rebuff motw 60"); return end
      B.db.buffSeconds[buffKey]=math.max(15,math.min(180,value)); B:InitDB()
    elseif tonumber(arg) then B.db.seconds=tonumber(arg); B:InitDB()
    else say("Usage: /bt rebuff 45 OR /bt rebuff motw 60"); return end
  elseif cmd=="size" or cmd=="opacity" or cmd=="seconds" then
    if not tonumber(arg) then say("Specify a number."); return end
    B.db[cmd]=tonumber(arg); B:InitDB()
  elseif cmd=="groupneed" then
    local buffKey,value=arg:match("^(%S+)%s+(%d+)$")
    if buffKey then
      local def=B:FindBuff(buffKey); value=tonumber(value)
      if not def or not value then say("Usage: /bt groupneed 3 OR /bt groupneed motw 4"); return end
      B:SetGroupNeed(def,value)
    else
      local value=tonumber(arg); if not value then say("Specify 2 through 5 players."); return end
      B.db.groupNeed=math.max(2,math.min(5,math.floor(value+0.5))); B:NormalizeGroupNeeds(); B:InitDB()
    end
  elseif cmd=="blessingneed" then
    local value=tonumber(arg); if not value then say("Specify 2 through 5 players."); return end
    B.db.blessingNeed=math.max(2,math.min(5,math.floor(value+0.5))); B:NormalizeGroupNeeds(); B:InitDB()
  elseif cmd=="targetrebuff" then
    local buffKey,value=arg:match("^(%S+)%s+(%d+)$")
    if buffKey then
      local def=B:FindBuff(buffKey); value=tonumber(value)
      if not def or def.singleKey or not value then say("Usage: /bt targetrebuff 300 OR /bt targetrebuff motw 1800"); return end
      B.db.targetBuffSeconds[buffKey]=math.max(30,math.min(1800,math.floor(value/30+0.5)*30))
    else
      local value=tonumber(arg); if not value then say("Usage: /bt targetrebuff 300 OR /bt targetrebuff motw 1800"); return end
      B.db.targetSeconds=math.max(30,math.min(1800,math.floor(value/30+0.5)*30))
    end
    B:InitDB()
  elseif cmd=="groups" then
    local chosen={}
    if arg=="all" then for i=1,8 do chosen[i]=true end
    elseif arg=="none" then for i=1,8 do chosen[i]=false end
    else
      for n in arg:gmatch("%d+") do local i=tonumber(n); if i and i>=1 and i<=8 then chosen[i]=true end end
      if next(chosen)==nil then say("Usage: /bt groups 1,2,3 | all | none"); return end
      for i=1,8 do if chosen[i]==nil then chosen[i]=false end end
    end
    for i=1,8 do B:SetRaidGroupColumn(i,chosen[i]==true) end
  elseif cmd=="sound" or cmd=="glow" or cmd=="pulse" or cmd=="group" or cmd=="smartgroup" or cmd=="target" or cmd=="consumables" then
    if arg~="on" and arg~="off" then say("Use on or off."); return end
    local key=cmd=="smartgroup" and "smartGroup" or (cmd=="target" and "friendlyTarget" or (cmd=="consumables" and "consumablesEnabled" or cmd)); B.db[key]=arg=="on"
    if cmd=="consumables" and B.InvalidateConsumables then B:InvalidateConsumables() end
  else
    say("/bt config | bind | rebuff | target | targetrebuff | group | groups | groupneed | consumables | status | debug | profile | refresh | reset")
    return
  end
  B.appearance=nil
  B:Refresh(false); B:Status(false)
end
