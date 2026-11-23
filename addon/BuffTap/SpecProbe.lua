-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
-- 1.28.1: read-only probe for dual talent specs. It changes nothing and only reports, in the Full
-- check-up, which talent calls and events this client has, so a per-spec feature (such as a weapon
-- imbue for each spec) can be judged on facts. Every call is guarded: a missing or failing call is
-- reported, never raised.
local _,B=...
local A=B.API

local PROBE_EVENTS={"ACTIVE_TALENT_GROUP_CHANGED","PLAYER_TALENT_UPDATE","CHARACTER_POINTS_CHANGED",
  "PLAYER_SPECIALIZATION_CHANGED","TALENT_GROUP_ROLE_CHANGED","ACTIVE_PLAYER_SPECIALIZATION_CHANGED","TRAIT_CONFIG_UPDATED"}
local seen={}      -- event -> {count=,last=}
local rejected={}  -- events the client refused to register
local frame=CreateFrame("Frame")
for _,event in ipairs(PROBE_EVENTS) do
  local ok,result=pcall(frame.RegisterEvent,frame,event)
  if not ok or result==false then rejected[#rejected+1]=event end
end
frame:SetScript("OnEvent",function(_,event)
  local e=seen[event] or {count=0}; e.count=e.count+1; e.last=type(GetTime)=="function" and GetTime() or 0; seen[event]=e
end)

local function show(...)
  local parts={}
  for i=1,select("#",...) do
    local v=select(i,...)
    if not A.Public(v) then parts[i]="(restricted)" else parts[i]=tostring(v) end
  end
  return table.concat(parts,", ")
end
-- "name = <values>" for a call, or "name = missing" when the client has no such function.
local function probe(name,fn,...)
  if type(fn)~="function" then return name.." = missing" end
  local result={pcall(fn,...)}
  if not result[1] then return name.." = error: "..show(result[2]) end
  return name.." = "..show(unpack(result,2,table.maxn(result)))
end
local function field(tbl,key) if type(tbl)=="table" then return tbl[key] end end

function B:SpecProbeLines()
  local out={}
  local function add(line) out[#out+1]=line end
  local SI=type(C_SpecializationInfo)=="table" and C_SpecializationInfo or {}
  local CT=type(C_ClassTalents)=="table" and C_ClassTalents or {}
  local TR=type(C_Traits)=="table" and C_Traits or {}
  add("Read-only probe: nothing here changes any setting.")
  add("Tables: C_SpecializationInfo = "..type(C_SpecializationInfo).." | C_ClassTalents = "..type(C_ClassTalents).." | C_Traits = "..type(C_Traits))
  add(probe("GetNumSpecGroups",GetNumSpecGroups))
  add(probe("C_SpecializationInfo.GetActiveSpecGroup",SI.GetActiveSpecGroup))
  add(probe("GetNumSpecializations",GetNumSpecializations))
  add(probe("C_SpecializationInfo.GetSpecialization (current)",SI.GetSpecialization))
  add(probe("C_SpecializationInfo.CanPlayerUseTalentSpecUI",SI.CanPlayerUseTalentSpecUI))
  add(probe("C_SpecializationInfo.CanPlayerUseTalentUI",SI.CanPlayerUseTalentUI))
  add(probe("C_SpecializationInfo.IsInitialized",SI.IsInitialized))
  add(probe("GetNumUnspentTalents",GetNumUnspentTalents))
  add(probe("C_ClassTalents.GetActiveConfigID",CT.GetActiveConfigID))
  -- Per spec group: which specialization it holds and which talent configuration belongs to it.
  local okGroups,groups=pcall(function() return type(GetNumSpecGroups)=="function" and GetNumSpecGroups() or 0 end)
  groups=math.max(2,okGroups and tonumber(groups) or 0)
  for group=1,math.min(groups,4) do
    local okIndex,index=pcall(function() return type(SI.GetSpecialization)=="function" and SI.GetSpecialization(false,false,group) end)
    local line="Group "..group..": spec index "..(okIndex and show(index) or "error")
    if okIndex and tonumber(index) and type(SI.GetSpecializationInfo)=="function" then
      local okInfo,id,name,_,_,role=pcall(SI.GetSpecializationInfo,tonumber(index),false,false,nil,nil,group)
      line=line.." = "..(okInfo and show(id,name,role) or "info error")
      if okInfo and type(CT.GetConfigIDsBySpecID)=="function" and A.Public(id) then
        local okIds,ids=pcall(CT.GetConfigIDsBySpecID,id)
        line=line.." | saved loadouts "..(okIds and type(ids)=="table" and #ids or "?")
      end
    end
    if type(SI.GetCombatConfigIDForSpecGroup)=="function" then
      local okConfig,config=pcall(SI.GetCombatConfigIDForSpecGroup,group)
      line=line.." | config "..(okConfig and show(config) or "error")
    end
    add(line)
  end
  add("Events refused by this client: "..(#rejected>0 and table.concat(rejected,", ") or "none"))
  if B.unsupportedEvents and #B.unsupportedEvents>0 then add("Events refused by the main frame: "..table.concat(B.unsupportedEvents,", ")) end
  local fired={}
  for _,event in ipairs(PROBE_EVENTS) do local e=seen[event]; if e then fired[#fired+1]=event.." x"..e.count end end
  add("Events seen this session: "..(#fired>0 and table.concat(fired,", ") or "none yet (switch talent spec, then run the check-up again)"))
  return out
end
