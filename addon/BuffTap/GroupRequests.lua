-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API

-- Nearby rows retain their nameplate token; prove current group membership by matching the roster GUID.
function B:GroupRequestRecipient(entry)
  if not entry or not A.Text(entry.guid) or not A.Text(entry.unit)
    or A.Call(UnitGUID,entry.unit)~=entry.guid or A.Class(entry.unit)~=entry.class then return false end
  local raid=A.Call(IsInRaid)
  if raid~=true and raid~=false or A.Call(IsInGroup)~=true then return false end
  local count=A.Call(raid and GetNumGroupMembers or GetNumSubgroupMembers)
  if not A.Number(count) or count%1~=0 or count<1 or count>(raid and 40 or 4) then return false end
  for i=1,count do
    local unit=(raid and "raid" or "party")..i
    if A.Call(UnitExists,unit)==true and A.Call(UnitGUID,unit)==entry.guid then
      return A.Class(unit)==entry.class and A.Call(UnitIsUnit,unit,"player")==false
        and A.Call(UnitIsConnected,unit)==true and A.Call(UnitIsDeadOrGhost,unit)==false
    end
  end
  return false
end

function B:OpenNearbyForRequests()
  if A.Combat() then return end
  self.db.nearbyEnabled=true
  self:ShowNearbySetup()
end
