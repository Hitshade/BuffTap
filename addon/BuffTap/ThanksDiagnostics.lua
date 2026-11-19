-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Bounded session-only observations. No identities, targeting or action decisions are changed.
local _,B=...
local A=B.API
local function activity(fn)
  if type(fn)~="function" then return "API unavailable" end
  local value,err=A.Call(fn,"player")
  if err or not A.Public(value) then return "unreadable" end
  return A.Text(value) and "active" or "inactive"
end
function B:ThanksTrace(stage,detail)
  self.thanksTrace=self.thanksTrace or {}
  local list=self.thanksTrace; local last=list[#list]
  if last and last.stage==stage and last.detail==detail then last.at=GetTime(); last.count=last.count+1; return end
  list[#list+1]={at=GetTime(),stage=stage,detail=detail or "",count=1}
  if #list>12 then table.remove(list,1) end
end
function B:ThanksRecordStatus()
  local status=self.helperThankStatus
  if status~=self.thanksRecordedStatus then
    self.thanksRecordedStatus=status; self.thanksStatusAt=GetTime()
    local stage="status changed"
    if type(status)=="string" then
      if status:find("^Incoming buff caster unavailable") then stage="caster unresolved"
      elseif status:find("^Thank emote requested") then stage="emote requested"
      elseif status:find("^Paused:") then stage="paused"
      elseif status:find("^Client restricted") then stage="emote restricted"
      elseif status:find("^Emote call failed") then stage="emote call failed"
      elseif status:find("^Caster identity changed") then stage="identity changed"
      elseif status:find("^Baseline ready") then stage="baseline ready" end
    end
    self:ThanksTrace(stage)
  end
end
function B:SoloThanksDiagnostics()
  local out={}; local now=GetTime(); local d=self.db or {}
  local function age(at) return type(at)=="number" and string.format("%.1fs ago",math.max(0,now-at)) or "not recorded" end
  local profile=self.profileDB and A.Call(self.profileDB.GetCurrentProfile,self.profileDB)
  if A.Text(profile) and self.RememberReportName then self:RememberReportName(profile) end
  out[#out+1]="Thanks context: class="..tostring((A.Class("player"))).." | level="..tostring(A.Call(UnitLevel,"player")).." | profile="..(A.Text(profile) and profile or "unavailable")
  out[#out+1]="Thanks settings: enabled="..tostring(d.helperThanks==true).." | while resting="..tostring(d.helperThanksResting==true).." | emote="..tostring(self:SoloThankEmote()).." | delay="..tostring(d.helperThankDelay).." | resting="..tostring(A.Call(IsResting))
  out[#out+1]="Thanks now: block="..tostring(self:SoloThanksBlockReason() or "none").." | casting="..activity(UnitCastingInfo).." | channeling="..activity(UnitChannelInfo).." (observations, not extra gates)"
  out[#out+1]="Thanks status changed: "..age(self.thanksStatusAt).." | last observation: "..age(self.thanksObservedAt)
  local pending,oldest,known=0,0,0
  for _,v in pairs(self.helperThankPending or {}) do pending=pending+1; oldest=math.max(oldest,now-v.at); if A.Text(v.guid) then known=known+1 end end
  out[#out+1]=string.format("Thanks pending: %d | known caster IDs: %d | oldest: %.1fs | retries: %d | retry scheduled: %s | queued: %d",pending,known,oldest,self.helperThankRetries or 0,tostring(self.helperThankRetryPending==true),#(self.helperThankQueue or {}))
  local lookup=self.thanksLookup
  if lookup then out[#out+1]="Thanks caster lookup: "..age(lookup.at).." | spell="..tostring(lookup.spell or "unavailable").." | native="..lookup.native.." | checked="..lookup.checked.." | readable IDs="..lookup.readable.." | nameplates="..tostring(lookup.plates or "not checked").." | result="..lookup.result end
  local incoming=self.thanksIncoming
  if incoming then out[#out+1]="Thanks incoming buff: "..age(incoming.at).." | spell="..tostring(incoming.spell or "unavailable").." | instance="..tostring(incoming.instance or "unavailable").." | caster ID="..tostring(incoming.known).." | live recipient="..tostring(incoming.live) end
  for _,v in ipairs(self.thanksTrace or {}) do out[#out+1]="Thanks recent: "..age(v.at).." | "..v.stage..(v.detail~="" and (" | "..v.detail) or "")..(v.count>1 and (" | repeated "..v.count) or "") end
  return out
end
local observe=B.ObserveSoloThanks
function B:ObserveSoloThanks(...)
  self.thanksObservedAt=GetTime()
  local result=observe(self,...); self:ThanksRecordStatus(); return result
end
local dispatch=B.DispatchSoloThanks
function B:DispatchSoloThanks(...)
  local result=dispatch(self,...); self:ThanksRecordStatus(); return result
end

local event=B.HelperEvent
function B:HelperEvent(kind,...)
  if kind=="PLAYER_REGEN_DISABLED" or kind=="PLAYER_ENTERING_WORLD" or kind=="ZONE_CHANGED_NEW_AREA" or kind=="GROUP_ROSTER_UPDATE" then self:ThanksTrace("context reset",kind) end
  return event(self,kind,...)
end
