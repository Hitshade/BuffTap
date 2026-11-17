-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Opt-in combat expiry warning for your own buffs.
-- Forever hides aura data from addons in combat, so the warning is an ESTIMATE: it uses the
-- expiration times read during the last out-of-combat check and plain timers. It never casts,
-- never touches the secure reminder button and never reads auras in combat.
local _,B=...
local A=B.API
local LEAD=10        -- seconds before the estimated expiry
local MIN_DURATION=60 -- shorter buffs are left to the normal reminder
local SLOT="combat-expiry"
local PLANNED_KINDS={self=true,single=true,blessing=true}

function B:CombatExpiryEnabled() return self.db and self.db.enabled==true and self.db.combatExpiry==true end

-- Out of combat only: remember when each enabled own buff on you is expected to run out.
function B:PlanCombatExpiry()
  if A.Combat() then return end
  self.combatExpiryPlan=nil
  if not self:CombatExpiryEnabled() then return end
  local guid=A.Call(UnitGUID,"player")
  if not A.Text(guid) or A.Call(UnitIsDeadOrGhost,"player")~=false then return end
  local list=self:ClassList()
  if type(list)~="table" then return end
  local auras=self:GetAuras("player",false,true)
  if type(auras)~="table" or auras.incomplete then return end
  local now=GetTime(); local plan={guid=guid,at=now,entries={}}
  for _,b in ipairs(list) do
    if PLANNED_KINDS[b.kind] and not b.singleKey and not b.noTimer and not b.stance and self:Enabled(b) and self:Supported(b) and self:SelfRecipientAllowed(b) then
      local action=self:Resolve(b,"player")
      if action then
        local _,state,_,remaining=self:Missing(b,action,auras)
        local duration=self:BuffDuration(b)
        if (state=="present" or state=="expiring") and A.Number(remaining) and remaining>0
          and (not duration or duration>=MIN_DURATION) then
          -- Only true self buffs can be renewed from a cast in combat: their target is always you.
          local ids
          if b.kind=="self" and duration then ids={[action.id]=true}; for _,id in ipairs(b.ranks or {}) do ids[id]=true end end
          plan.entries[#plan.entries+1]={key=b.key,name=action.name,icon=action.icon,expiresAt=now+remaining,duration=duration,ids=ids}
        end
      end
    end
  end
  if #plan.entries>0 then self.combatExpiryPlan=plan end
end

function B:CancelCombatExpiry()
  for key in pairs(self.combatExpiryTimers or {}) do self:CancelTimer(SLOT..":"..key) end
  self.combatExpiryTimers=nil; self.combatExpiryActive=nil
  local f=self.combatExpiryFrame
  if f then f:SetScript("OnUpdate",nil); f:Hide() end
end

local function countdown(seconds)
  seconds=math.max(0,math.ceil(seconds))
  if seconds>=60 then return tostring(math.floor(seconds/60)).."m" end
  return tostring(seconds)
end

function B:CreateCombatExpiryFrame()
  if self.combatExpiryFrame then return self.combatExpiryFrame end
  -- Plain frame, no secure template and no anchor to the secure button: it can show and move in combat.
  local f=CreateFrame("Frame","BuffTapCombatExpiry",UIParent)
  f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true); f:EnableMouse(false); f:Hide()
  f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetAllPoints()
  f.timer=f:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge"); f.timer:SetPoint("CENTER",f,"CENTER",0,0)
  f.label=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.label:SetPoint("TOP",f,"BOTTOM",0,-4)
  f.more=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f.more:SetPoint("TOPRIGHT",f,"TOPRIGHT",-3,-3)
  self.combatExpiryFrame=f
  return f
end

-- Shows the soonest warned buff. Display only.
function B:UpdateCombatExpiryFrame()
  local active=self.combatExpiryActive
  local f=self.combatExpiryFrame
  if not active or #active==0 or not self:CombatExpiryEnabled() or self.db.showReminder==false then
    if f then f:SetScript("OnUpdate",nil); f:Hide() end
    return
  end
  f=f or self:CreateCombatExpiryFrame()
  table.sort(active,function(a,b) return a.expiresAt<b.expiresAt end)
  local first=active[1]; local now=GetTime()
  local size=A.Number(self.db.size) and self.db.size or 64
  f:SetSize(size,size); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",self.db.x or 0,self.db.y or -180)
  f:SetAlpha(A.Number(self.db.opacity) and self.db.opacity or 1)
  f.icon:SetTexture(first.icon)
  local left=first.expiresAt-now
  if left>0 then
    f.timer:SetText(countdown(left)); f.icon:SetDesaturated(false)
    f.label:SetText(self:Text("%s expires soon (estimate)",first.name or "?"))
  else
    f.timer:SetText(""); f.icon:SetDesaturated(true)
    f.label:SetText(self:Text("%s may have expired (estimate)",first.name or "?"))
  end
  f.more:SetText(#active>1 and ("+"..tostring(#active-1)) or "")
  f:Show()
  if not f:GetScript("OnUpdate") then
    f.elapsed=0
    f:SetScript("OnUpdate",function(s,dt) s.elapsed=(s.elapsed or 0)+(dt or 0); if s.elapsed>=.25 then s.elapsed=0; B:UpdateCombatExpiryFrame() end end)
  end
end

function B:FireCombatExpiry(entry)
  if self.combatExpiryTimers then self.combatExpiryTimers[entry.key]=nil end
  if not A.Combat() or not self:CombatExpiryEnabled() then return end
  self.combatExpiryActive=self.combatExpiryActive or {}
  table.insert(self.combatExpiryActive,entry)
  self:UpdateCombatExpiryFrame()
  if self.db.sound then self:PlayAlert("reminder") end
end

function B:StartCombatExpiry()
  self:CancelCombatExpiry()
  local plan=self.combatExpiryPlan
  if not plan or not self:CombatExpiryEnabled() then return end
  -- A plan made for another character or before a death is never reused.
  if plan.guid~=A.Call(UnitGUID,"player") or A.Call(UnitIsDeadOrGhost,"player")~=false then self.combatExpiryPlan=nil; return end
  local now=GetTime()
  self.combatExpiryTimers={}
  for _,planned in ipairs(plan.entries) do
    if planned.expiresAt>now then
      self:ScheduleCombatExpiry({key=planned.key,name=planned.name,icon=planned.icon,expiresAt=planned.expiresAt})
    end
  end
end

function B:ScheduleCombatExpiry(entry)
  self.combatExpiryTimers=self.combatExpiryTimers or {}
  self.combatExpiryTimers[entry.key]=true
  self:StartTimer(SLOT..":"..entry.key,math.max(0,entry.expiresAt-LEAD-GetTime()),function() B:FireCombatExpiry(entry) end)
end

-- You recast one of your self buffs in combat (for example from an action bar): restart its estimate.
-- A hidden or unknown spell ID changes nothing.
function B:CombatExpiryCast(spellID)
  local plan=self.combatExpiryPlan
  if not A.Combat() or not plan or not self.combatExpiryTimers or not A.Number(spellID) then return end
  for _,planned in ipairs(plan.entries) do
    if planned.ids and planned.ids[spellID] and A.Number(planned.duration) then
      local active=self.combatExpiryActive
      for i=#(active or {}),1,-1 do if active[i].key==planned.key then table.remove(active,i) end end
      self:ScheduleCombatExpiry({key=planned.key,name=planned.name,icon=planned.icon,expiresAt=GetTime()+planned.duration})
      self:UpdateCombatExpiryFrame()
      return true
    end
  end
end

-- Own events, independent of the reminder's event handler and of other toggles.
local events=CreateFrame("Frame")
B.combatExpiryEvents=events
for _,event in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_DEAD","PLAYER_ENTERING_WORLD"}) do pcall(events.RegisterEvent,events,event) end
if events.RegisterUnitEvent then pcall(events.RegisterUnitEvent,events,"UNIT_SPELLCAST_SUCCEEDED","player") else pcall(events.RegisterEvent,events,"UNIT_SPELLCAST_SUCCEEDED") end
events:SetScript("OnEvent",function(_,event,unit,_,spellID)
  if not B.db then return end
  if event=="UNIT_SPELLCAST_SUCCEEDED" then if unit=="player" then B:CombatExpiryCast(spellID) end; return end
  if event=="PLAYER_REGEN_DISABLED" then B:StartCombatExpiry()
  else
    B:CancelCombatExpiry()
    -- The plan is rebuilt by the next out-of-combat refresh.
    if event~="PLAYER_REGEN_ENABLED" then B.combatExpiryPlan=nil end
  end
end)

-- Every completed out-of-combat refresh renews the plan from the auras it just read.
local baseRefresh=B.Refresh
function B:Refresh(...)
  local result=baseRefresh(self,...)
  if self.db and not A.Combat() then
    local ok,err=pcall(self.PlanCombatExpiry,self)
    if not ok then self.combatExpiryPlan=nil; self.combatExpiryError=tostring(err) end
  end
  return result
end
