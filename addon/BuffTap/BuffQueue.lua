-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Opt-in queue of further pending buff spells, shown as smaller clickable icons below the
-- reminder. Each icon is its own secure button: prepared out of combat only, cleared by the
-- secure state driver in combat, and revalidated (identity, eligibility, need) on every click.
-- Icons never receive key bindings; your BuffTap binding stays on the main reminder.
local _,B=...
local A=B.API
local MAX_ICONS=4
local MAX_PASSES=12
local GAP=4
B.BuffQueueLimit=MAX_ICONS

function B:BuffQueueEnabled() return self.db and self.db.enabled==true and self.db.buffQueue==true end
function B:BuffQueueIconSize() return math.max(16,math.floor((A.Number(self.db.size) and self.db.size or 64)*0.55+.5)) end

local function isBuffSpell(action)
  return action and not action.manual and not action.nearby and not action.groupCast and not action.bgSelf
    and (action.source==nil or action.source=="spell") and action.secureType=="spell" and A.Number(action.id)
    and A.Text(action.key) and B:FindBuff(action.key)~=nil
end

-- Select state that the extra passes must not leave behind for status text, wakes or diagnostics.
local SAVED={"nextWakeDelay","rangeBlocked","rangeBlockedActions","rangeBlockedKeys","powerBlocked","manaFloorBlocked","manaBlocked",
  "cooldownBlocked","dataPending","targetDataPending","buffDataUnavailable","ownershipUnavailable","pvpBlocked","deferredBlocked",
  "blessingClassList","diagnostics","captureDiagnostics"}

local function exclude(self,action)
  local def=self:FindBuff(action.key); if not def then return false end
  local root=self:RootKey(def)
  if action.groupCast then
    -- A group spell covers more players than its target; leave its whole family to the main button.
    self.queueExcludeFamily[root]=true
    if def.kind=="blessing" then self.queueNoBlessings=true end
    return true
  end
  local guid=action.target=="player" and A.Call(UnitGUID,"player") or action.targetGUID
  if not A.Text(guid) then return false end
  self.queueExclude[root..":"..guid]=true
  if def.kind=="blessing" then self.queueBlessingGUIDs[guid]=true end
  return true
end

-- Runs the buff-only selection again with everything already shown excluded. One icon per buff
-- family; its count is how many further players need that buff. Out of combat only.
function B:CollectBuffQueue(main)
  local out={}
  if A.Combat() or not self:BuffQueueEnabled() or not self.EngineSelect then return out end
  if self:ReminderPauseReason() or self:BGSelfMode() then return out end
  if main and main.nearby then return out end
  local saved={}; for _,k in ipairs(SAVED) do saved[k]=self[k] end
  self.queueExclude={}; self.queueExcludeFamily={}; self.queueBlessingGUIDs={}; self.queueNoBlessings=nil
  if main and main.key and self:FindBuff(main.key) and (main.source==nil or main.source=="spell") then exclude(self,main) end
  self.queuePass=true; self.captureDiagnostics=false
  local families={}; local passes=0
  local ok,err=pcall(function()
    for _=1,MAX_PASSES do
      passes=passes+1
      local action=self.EngineSelect(self)
      if not isBuffSpell(action) or not exclude(self,action) then break end
      local def=self:FindBuff(action.key); local root=self:RootKey(def)
      local entry=families[root]
      if entry then entry.count=entry.count+1
      elseif #out<MAX_ICONS then entry={action=action,count=1}; families[root]=entry; out[#out+1]=entry
      else break end
    end
  end)
  if passes>=MAX_PASSES then for _,entry in ipairs(out) do entry.atLeast=true end end
  self.queuePass=nil; self.queueExclude=nil; self.queueExcludeFamily=nil; self.queueBlessingGUIDs=nil; self.queueNoBlessings=nil
  for _,k in ipairs(SAVED) do self[k]=saved[k] end
  if not ok then self.buffQueueError=tostring(err); return {} end
  return out
end

local SAFETY=[[
  if newstate == "blocked" then
    self:SetAttribute("type1", nil)
    self:SetAttribute("spell", nil)
    self:SetAttribute("unit", nil)
    self:Hide()
  end
]]

local function clear(button)
  if not button or A.Combat() then return end
  button:Hide()
  button:SetAttribute("type1",nil); button:SetAttribute("spell",nil); button:SetAttribute("unit",nil)
  button.action=nil
end

function B:ClearBuffQueue()
  if A.Combat() then return end
  for _,button in ipairs(self.queueButtons or {}) do clear(button) end
  self.buffQueue=nil; self.buffQueueShown=0
end

-- Click-time check, mirroring the main reminder's spell path. Never swaps in another action.
function B:ValidateQueueClick(button)
  local action=button and button.action
  if A.Combat() or not action or not self:BuffQueueEnabled() then return false,"no queued action" end
  if self:SyncSituation() then return false,"setup changed before click" end
  local paused=self:ActionPauseReason(action); if paused then return false,paused end
  if self.HelperSuppressed and self:HelperSuppressed(action) then return false,"dismissed" end
  if button:GetAttribute("spell")~=action.id or button:GetAttribute("unit")~=action.target or button:GetAttribute("type1")~="spell" then return false,"secure payload changed" end
  if action.target~="player" and (not A.Text(action.targetGUID) or A.Call(UnitGUID,action.target)~=action.targetGUID) then return false,"target identity changed or unreadable" end
  local valid,why=self:Validate(action)
  if not valid then return false,why or "click validation failed" end
  local def=self:FindBuff(action.key)
  if not def or not self:Enabled(def) then return false,"buff disabled before click" end
  local auras=self:GetAuras(action.target,true,true)
  if not auras or not def then return false,"action no longer verifiable" end
  if not self:BlessingActionAllowed(action) then return false,"blessing ownership changed before click" end
  local missing=self:Missing(def,action,auras,action.quickTarget and self:TargetRebuffSeconds(def) or nil)
  if not missing then return false,"action no longer missing" end
  return true
end

function B:CreateQueueButton(index)
  if A.Combat() then return nil end
  self.queueButtons=self.queueButtons or {}
  if self.queueButtons[index] then return self.queueButtons[index] end
  local ok,b=pcall(CreateFrame,"Button","BuffTapQueueButton"..index,UIParent,"SecureActionButtonTemplate,SecureHandlerStateTemplate")
  if not ok or not b then return nil end
  b:Hide(); self:SetGameplayLayer(b,"buff"); b:SetClampedToScreen(true)
  -- Up-only clicks need useOnKeyDown=false; otherwise the ActionButtonUseKeyDown CVar makes the
  -- secure template act on key-down only and the release click casts nothing.
  b:RegisterForClicks("LeftButtonUp"); b:SetAttribute("useOnKeyDown",false)
  b:SetAttribute("checkselfcast",false); b:SetAttribute("checkfocuscast",false); b:SetAttribute("checkmouseovercast",false)
  if not pcall(b.SetAttribute,b,"_onstate-safety",SAFETY) or not RegisterStateDriver
    or not pcall(RegisterStateDriver,b,"safety","[combat][@player,dead][mounted][vehicleui][petbattle] blocked; ready") then
    pcall(b.Hide,b); self.buffQueueError="queue secure driver unavailable"; return nil
  end
  b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetAllPoints()
  b.count=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); b.count:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  b:SetScript("OnEnter",function(s)
    local action=s.action
    if A.Combat() or not action or not GameTooltip then return end
    GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
    if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(action.id) else GameTooltip:SetText(action.name) end
    GameTooltip:AddLine(B:Text("Next: %s",action.targetName or action.target or "?"),0.4,1,0.8)
    if (s.queueCount or 1)>1 then GameTooltip:AddLine(B:Text(s.queueAtLeast and "At least %d players need this buff." or "%d players need this buff.",s.queueCount),0.85,0.85,0.85) end
    GameTooltip:AddLine(B:Text("Click to cast it now."),0.75,0.75,0.75,true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  b:SetScript("PreClick",function(s,button)
    if A.Combat() or (button and button~="LeftButton") then return end
    local okClick,valid,why=pcall(B.ValidateQueueClick,B,s)
    if not okClick or not valid then
      clear(s)
      B.buffQueueReason=okClick and why or "click validation unavailable"
      B:RequestRefresh("queue click changed",0.05)
    else
      B:BeginHelperAttempt(s.action)
    end
  end)
  b:SetScript("PostClick",function(s,button)
    if A.Combat() or (button and button~="LeftButton") then return end
    local action=s.action
    if action then B:InvalidateAura(action.target) end
    B.dirty=true; B:RequestRefresh("queue post-click",0.12)
  end)
  self.queueButtons[index]=b
  return b
end

-- Height of the reminder labels below the main icon (same rule as the manual consumables row).
function B:ReminderLabelsBelow()
  local d=self.db
  local labels=d.labelPosition=="above" and 0 or (d.showTargetName and 1 or 0)
  if d.labelPosition=="below" and d.showBuffName then labels=labels+1 end
  return labels>0 and labels*math.max(10,d.labelSize or 10)+(d.labelGap or 5)+(labels-1)*2 or 0
end
-- Extra height the queue row takes below the reminder, so the consumables row can move down.
function B:BuffQueueOffset()
  if not self.buffQueueShown or self.buffQueueShown<1 then return 0 end
  return self:BuffQueueIconSize()+GAP+2
end

function B:UpdateBuffQueue(main)
  if A.Combat() then return end
  local entries=self:CollectBuffQueue(main)
  local hidden=self.db.showReminder==false or not (self.button and self.button:IsShown())
  if hidden then entries={} end
  self.buffQueue=entries; self.buffQueueShown=0
  local size=self:BuffQueueIconSize()
  local total=#entries
  local width=total*size+(total-1)*GAP
  local y=self.db.y-self.db.size/2-self:ReminderLabelsBelow()-GAP-2-size/2
  for i=1,MAX_ICONS do
    local entry=entries[i]
    local b=(entry and self:CreateQueueButton(i)) or (self.queueButtons and self.queueButtons[i])
    if b then
      clear(b)
      if entry and b:GetAttribute("state-safety")~="blocked" then
        local action=entry.action
        b:SetAttribute("spell",action.id); b:SetAttribute("unit",action.target); b:SetAttribute("type1","spell")
        if b:GetAttribute("spell")==action.id and b:GetAttribute("unit")==action.target and b:GetAttribute("type1")=="spell" then
          b.action=action; b.queueCount=entry.count; b.queueAtLeast=entry.atLeast
          b:SetSize(size,size); b:ClearAllPoints()
          b:SetPoint("CENTER",UIParent,"CENTER",self.db.x-width/2+size/2+(i-1)*(size+GAP),y)
          b:SetAlpha(A.Number(self.db.opacity) and self.db.opacity or 1)
          b.icon:SetTexture(action.icon)
          self:ApplyIconStyle(b,b.icon,self.db.iconStyle)
          b.count:SetText((entry.count>1 or entry.atLeast) and (tostring(entry.count)..(entry.atLeast and "+" or "")) or "")
          b:Show(); self.buffQueueShown=self.buffQueueShown+1
        else clear(b) end
      end
    end
  end
end
