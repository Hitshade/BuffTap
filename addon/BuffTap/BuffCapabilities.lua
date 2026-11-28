-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Product semantics belong here, independently of generated spell/rank evidence.
-- Unknown utility families never inherit pet or role eligibility.
local pets={motw=true,thorns=true,fort=true,sp=true,ai="mana",spirit="mana"}
local roles={thorns={tank=true},["fear-ward"]={tank=true,healer=true}}
local broadcasts={["battle-shout"]=true,trueshot=true}
local utility={["water-breathing"]=true,["water-walking"]=true,["unending-breath"]=true,["detect-invis"]=true}
local raidCasts={ab=true,gotw=true,pof=true,pos=true,posp=true}
function B:GroupCastScope(b)
  if not b then return nil end
  if raidCasts[b.key] then return "raid" end
  if b.singleKey and b.kind=="blessing" then return "class" end
end
-- The supported Forever long-duration group pairs are caster-centered raid effects.
function B:GroupCastRecipientReach(unit)
  if type(UnitDistanceSquared)=="function" then
    local ok,squared,checked=pcall(UnitDistanceSquared,unit)
    if ok and self.API.Public(checked) and checked==true and self.API.Number(squared) then return squared<=10000,"distance" end
  end
  return true,"visible roster; exact area distance unavailable"
end
function B:BuffGroupCapabilities(b)
  if type(b)~="table" then return {} end
  local key=b.singleKey or b.key
  local assignable=(b.kind=="single" or b.kind=="blessing" or b.singleKey~=nil) and not broadcasts[key]
  return {assignable=assignable, pair=assignable and (b.groupKey~=nil or b.singleKey~=nil),
    broadcast=broadcasts[key]==true,pet=pets[key],roles=roles[key],utility=utility[key]==true}
end
function B:IsBroadcastBuff(b) return self:BuffGroupCapabilities(b).broadcast end
function B:BuffSupportsRole(b,role)
  local c=self:BuffGroupCapabilities(b); return c.roles and c.roles[role]==true or false
end
function B:ClassGroupCapabilities()
  local class=self.API.Class("player"); local out={targeted=false,pairs=false,pets=false,roles=false,maintenance=false,broadcast=false}
  for _,b in ipairs(self.Buffs) do
    if b.class==class then
      local c=self:BuffGroupCapabilities(b)
      out.targeted=out.targeted or c.assignable
      out.pairs=out.pairs or c.pair
      out.pets=out.pets or c.pet~=nil
      out.roles=out.roles or c.roles~=nil
      out.maintenance=out.maintenance or (c.assignable and not c.utility)
      if c.broadcast then out.broadcast=b end
    end
  end
  return out
end
function B:HasTargetedGroupBuffs() return self:ClassGroupCapabilities().targeted end
function B:HasGroupSpellPairs() return self:ClassGroupCapabilities().pairs end
function B:HasPetEligibleBuffs() return self:ClassGroupCapabilities().pets end
function B:DefaultGroupEnabled() return self:ClassGroupCapabilities().maintenance==true end

function B:NearbyCapabilities()
  local out={buffs=self:HasTargetedGroupBuffs(),short=false,upgrades=false}
  for _,b in ipairs(self:TargetAssignableBuffs()) do
    out.short=out.short or b.short==true
    out.upgrades=out.upgrades or (self.BuffSupportsRankUpgrades and self:BuffSupportsRankUpgrades(b)) or false
  end
  out.actions=out.buffs or (self.CanCleanseAnything and self:CanCleanseAnything()) or false
  return out
end

function B:HasPersonalReminderBuffs()
  for _,b in ipairs(self:ClassList()) do if not b.singleKey and self:Supported(b) then return true end end
  return false
end
