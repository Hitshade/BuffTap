-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local function current(self,attempt)
  return attempt and self.groupAttempt==attempt and attempt.db==self.db and self.db.enabled
    and attempt.context==self:ActiveGroupContext() and not A.Combat()
end
function B:GroupFallbackBlocked(action)
  local pending=self.groupAttempt
  if pending and pending.db==self.db and pending.scope==action.groupFallbackScope and GetTime()-pending.at<4 then
    self:ConsiderWake(4-(GetTime()-pending.at)); self:AddDiag("Group outcome pending -> "..pending.scope); return true
  end
  local entry=self.groupFallbacks and self.groupFallbacks[action.groupFallbackScope]
  if not entry then return false end
  if entry.db~=self.db or entry.untilTime<=GetTime() then self.groupFallbacks[action.groupFallbackScope]=nil; return false end
  self:ConsiderWake(entry.untilTime-GetTime())
  self:AddDiag("Group fallback -> "..action.groupFallbackScope..": "..entry.reason)
  return true
end
function B:BeginGroupAttempt(action)
  if not action or not action.groupCast or not action.groupFallbackScope then return end
  self.groupAttempt=nil; self:CancelTimer("group-outcome")
  local recipients={}
  for _,a in ipairs(action.groupRecipients or {}) do
    recipients[#recipients+1]={unit=a.target,guid=a.targetGUID,id=a.id,key=a.key}
  end
  self.groupAttempt={id=action.id,scope=action.groupFallbackScope,at=GetTime(),db=self.db,
    context=self:ActiveGroupContext(),recipients=recipients}
  self.groupOutcome="attempted spell="..action.id.." scope="..action.groupFallbackScope
  local attempt=self.groupAttempt
  self:StartTimer("group-outcome",4,function()
    if B.groupAttempt==attempt then
      B.groupOutcome="unconfirmed spell="..attempt.id.."; no result event"; B.groupAttempt=nil
      if not A.Combat() then B:RequestRefresh("group outcome expired",0) end
    end
  end)
end
function B:UseGroupSingles(attempt,reason,duration)
  if not current(self,attempt) then return end
  self.groupFallbacks=self.groupFallbacks or {}
  self.groupFallbacks[attempt.scope]={untilTime=GetTime()+duration,reason=reason,db=self.db}
  self.groupOutcome="single-cast fallback: spell="..attempt.id.." scope="..attempt.scope.." | "..reason
  self.groupAttempt=nil; self:RequestRefresh("group fallback",0)
end
function B:CheckGroupOutcome(attempt)
  if not current(self,attempt) then return end
  self:InvalidateAura()
  local missing,checked,unknown=0,0,0
  local missingIDs={}
  for _,r in ipairs(attempt.recipients) do
    local action={id=r.id,key=r.key,target=r.unit,targetGUID=r.guid}
    if A.Text(r.guid) and A.Call(UnitGUID,r.unit)==r.guid and self:TargetEligible(action,false) then
      local auras=self:GetAuras(r.unit,false,true); local def=self:FindBuff(r.key)
      if auras and not auras.incomplete and def then
        checked=checked+1
        if self:Missing(def,action,auras) then missing=missing+1; missingIDs[r.guid]=true end
      else unknown=unknown+1 end
    else unknown=unknown+1 end
  end
  local outcome="successful spell="..attempt.id.." scope="..attempt.scope..
    " | checked="..checked.." still need="..missing.." unverifiable="..unknown
  self.groupOutcome=outcome
  if missing>0 and attempt.observation==nil then
    attempt.observation=missingIDs
    self:StartTimer("group-outcome",2,function() B:CheckGroupOutcome(attempt) end)
  elseif missing>0 then
    local stable=0
    for guid in pairs(missingIDs) do if attempt.observation[guid] then stable=stable+1 end end
    if stable>0 then self:UseGroupSingles(attempt,"coverage still incomplete after two settled reads; "..outcome,60)
    else self.groupOutcome=outcome.."; missing recipients changed, no fallback"; self.groupAttempt=nil end
  else self.groupAttempt=nil end
end
local transientErrors={"ERR_OUT_OF_MANA","SPELL_FAILED_NO_POWER","SPELL_FAILED_REAGENTS",
  "SPELL_FAILED_ITEM_NOT_READY","SPELL_FAILED_NOT_READY","SPELL_FAILED_OUT_OF_RANGE",
  "ERR_OUT_OF_RANGE","ERR_SPELL_OUT_OF_RANGE","SPELL_FAILED_LINE_OF_SIGHT",
  "SPELL_FAILED_SPELL_IN_PROGRESS","SPELL_FAILED_MOVING","ERR_SPELL_COOLDOWN","ERR_ABILITY_COOLDOWN",
  "SPELL_FAILED_SILENCED","SPELL_FAILED_STUNNED","SPELL_FAILED_CASTER_DEAD","SPELL_FAILED_INTERRUPTED"}
function B:GroupFallbackEvent(event,unit,message,spellID,extraSpellID)
  if event=="GROUP_ROSTER_UPDATE" or event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
    self.groupAttempt=nil; self.groupFallbacks={}; self:CancelTimer("group-outcome")
    self.groupOutcome="context changed; fallback cleared"; return
  elseif event=="PLAYER_REGEN_DISABLED" then
    if self.groupAttempt then self.groupOutcome="outcome unverifiable: combat began" end
    self.groupAttempt=nil; self:CancelTimer("group-outcome"); return
  end
  local attempt=self.groupAttempt
  if not current(self,attempt) or GetTime()-attempt.at>4 then return end
  if event=="UNIT_SPELLCAST_SENT" then
    if unit=="player" and A.Number(extraSpellID) and extraSpellID==attempt.id and A.Text(spellID) then attempt.castGUID=spellID end
    return
  end
  if event=="UI_ERROR_MESSAGE" and A.Text(message) then
    attempt.error=message; attempt.transient=false
    for _,key in ipairs(transientErrors) do
      if A.Text(_G[key]) and message==_G[key] then attempt.transient=true end
    end
    attempt.low=A.Text(SPELL_FAILED_LOWLEVEL) and message==SPELL_FAILED_LOWLEVEL
    return
  end
  if unit~="player" or not A.Number(spellID) or spellID~=attempt.id then return end
  if attempt.castGUID and (not A.Text(message) or message~=attempt.castGUID) then return end
  if attempt.terminal then return end
  attempt.terminal=event
  if event=="UNIT_SPELLCAST_INTERRUPTED" then
    self.groupOutcome="interrupted spell="..attempt.id.."; no fallback"
    self.groupAttempt=nil; self:CancelTimer("group-outcome")
  elseif event=="UNIT_SPELLCAST_FAILED" then
    self:StartTimer("group-outcome",1,function()
      if B.groupAttempt~=attempt then return end
      if attempt.transient then
        B.groupOutcome="failed spell="..attempt.id.." | "..tostring(attempt.error).."; no eligibility fallback"
        B.groupAttempt=nil
        B:RequestRefresh("group transient failure",0)
      else
        B:UseGroupSingles(attempt,"cast rejected: "..tostring(attempt.error or "reason unavailable"),attempt.low and 300 or 15)
      end
    end)
  elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
    self.groupOutcome="successful spell="..attempt.id.."; waiting for aura updates"
    self:StartTimer("group-outcome",2,function() B:CheckGroupOutcome(attempt) end)
  end
end
function B:GroupFallbackSummary()
  local active=0
  for _,entry in pairs(self.groupFallbacks or {}) do if entry.db==self.db and entry.untilTime>GetTime() then active=active+1 end end
  return "Group casts: "..tostring(self.groupOutcome or "not observed").." | active fallback scopes="..active
end
