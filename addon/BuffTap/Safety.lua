-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API

local function flag(unit)
  local pvp=A.Call(UnitIsPVP,unit)
  local ffa=A.Call(UnitIsPVPFreeForAll,unit)
  if pvp==true or ffa==true then return true end
  if pvp==false and ffa==false then return false end
end

function B:PvPGuardActive()
  if not self.db or self.db.pvpProtection~=true then return false end
  local inside=A.Call(IsInInstance)
  local kind=A.Call(function() local _,value=IsInInstance(); return value end)
  if inside==true and (kind=="pvp" or kind=="arena") then return false end
  local mine=flag("player")
  -- Missing countdown support must not authorize extending a flag.
  local countdown=A.Call(IsPVPTimerRunning)
  return mine~=true or countdown~=false
end

function B:PvPActionAllowed(action)
  if not self:PvPGuardActive() then return true end
  local def=action.key and self:FindBuff(action.key)
  local area=def and (def.kind=="group" or def.singleKey~=nil or def.kind=="aura"
    or def.key=="trueshot" or def.key=="aspect-pack" or def.key=="aspect-wild")
  local function safe(unit)
    if A.Call(UnitIsUnit,unit,"player")==true or unit=="player" then return true end
    if A.Call(UnitIsDeadOrGhost,unit)==true then return true end
    local state=flag(unit)
    if state==false then return true end
    self.pvpBlocked=true
    local why=state==true and "recipient PvP flagged" or "recipient PvP status unavailable"
    self:AddDiag("PvP protection -> "..unit..": "..why)
    return false,"PvP protection: "..why
  end
  if not area then return safe(action.target or "player") end
  -- Enumerate actual membership, independent of watched/assigned raid groups.
  -- Even covered or excluded players can receive an area spell.
  local raid=A.Call(IsInRaid)==true
  local members={{unit="player",group=1}}
  if raid then
    local count=A.Call(GetNumGroupMembers)
    if not A.Number(count) then self.pvpBlocked=true; return false,"PvP protection: roster unavailable" end
    members={}
    for i=1,math.min(count,40) do
      local unit="raid"..i
      if A.Call(UnitExists,unit)==true then
        local group=A.Call(function() local _,_,value=GetRaidRosterInfo(i); return value end)
        members[#members+1]={unit=unit,group=A.Number(group) and group or nil}
      else self.pvpBlocked=true; return false,"PvP protection: roster unavailable" end
    end
  else
    local count=A.Call(GetNumSubgroupMembers)
    if not A.Number(count) then self.pvpBlocked=true; return false,"PvP protection: roster unavailable" end
    for i=1,math.min(count,4) do
      local unit="party"..i
      if A.Call(UnitExists,unit)==true then members[#members+1]={unit=unit,group=1} end
    end
  end
  local targetGroup=raid and nil or 1
  for _,entry in ipairs(members) do
    if entry.unit==action.target or A.Call(UnitIsUnit,entry.unit,action.target)==true then targetGroup=entry.group end
  end
  local targetClass=A.Call(function() local _,value=UnitClass(action.target); return value end)
  local classWide=def.classWide or def.kind=="blessing"
  if (classWide and not A.Text(targetClass)) or (not classWide and not targetGroup) then
    self.pvpBlocked=true; return false,"PvP protection: affected recipients unavailable"
  end
  for _,entry in ipairs(members) do
    local class=A.Call(function() local _,value=UnitClass(entry.unit); return value end)
    local affected=classWide and (not A.Text(class) or class==targetClass)
      or (not classWide and (not entry.group or entry.group==targetGroup))
    if affected then
      local ok,why=safe(entry.unit)
      if not ok then return false,why end
    end
  end
  return true
end

local suppressed=B.HelperSuppressed
function B:HelperSuppressed(action)
  local key=action and action.targetGUID
  local untilTime=key and self.failedRecipients and self.failedRecipients[key]
  if untilTime then
    if untilTime>GetTime() then
      self.deferredBlocked=true; self:ConsiderWake(untilTime-GetTime())
      self:AddDiag("Temporary cast failure -> "..tostring(action.target)..": retry in "..math.ceil(untilTime-GetTime()).."s")
      return true
    end
    self.failedRecipients[key]=nil
  end
  return suppressed(self,action)
end

local begin=B.BeginHelperAttempt
function B:BeginHelperAttempt(action)
  self.failedAttempt=nil
  -- Only automated spell buffs on another recipient. Items and manual casts
  -- have separate providers and must not be blamed for an unrelated error.
  if action and not action.manual and (not action.source or action.source=="spell")
    and action.target~="player" and A.Number(action.id) then
    self.failedAttempt={action=action,id=action.id,at=GetTime()}
  end
  begin(self,action)
end

function B:SafetyEvent(event,unit,arg2,spellID)
  if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" or event=="GROUP_ROSTER_UPDATE" then
    self.failedRecipients=nil; self.failedAttempt=nil; return
  end
  if event=="PLAYER_REGEN_DISABLED" then self.failedAttempt=nil; return end
  local attempt=self.failedAttempt
  if not attempt then return end
  if A.Combat() or GetTime()-attempt.at>1 then self.failedAttempt=nil; return end
  if event=="UI_ERROR_MESSAGE" then
    if not A.Text(arg2) then return end
    local los=A.Text(SPELL_FAILED_LINE_OF_SIGHT) and arg2==SPELL_FAILED_LINE_OF_SIGHT
    local range=A.Text(SPELL_FAILED_OUT_OF_RANGE) and arg2==SPELL_FAILED_OUT_OF_RANGE
    if los or range then attempt.temporary=true else self.failedAttempt=nil; return end
  elseif event=="UNIT_SPELLCAST_FAILED" and unit=="player" then
    if not A.Number(spellID) or spellID~=attempt.id then self.failedAttempt=nil; return end
    attempt.failed=true
  elseif (event=="UNIT_SPELLCAST_SUCCEEDED" or event=="UNIT_SPELLCAST_INTERRUPTED") and unit=="player" then
    self.failedAttempt=nil; return
  end
  if attempt.failed and attempt.temporary then
    self.failedRecipients=self.failedRecipients or {}
    if not A.Text(attempt.action.targetGUID) then self.failedAttempt=nil; return end
    for guid,expiry in pairs(self.failedRecipients) do if expiry<=GetTime() then self.failedRecipients[guid]=nil end end
    self.failedRecipients[attempt.action.targetGUID]=GetTime()+10
    self.failedAttempt=nil
    self:RequestRefresh("temporary recipient failure",0)
  end
end
