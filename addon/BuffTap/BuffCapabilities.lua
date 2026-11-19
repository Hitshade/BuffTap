-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Product semantics belong here, independently of generated spell/rank evidence.
-- Unknown utility families never inherit pet or role eligibility.
local pets={motw=true,thorns=true,fort=true,sp=true,ai="mana",spirit="mana"}
local roles={thorns={tank=true},["fear-ward"]={tank=true,healer=true}}
local broadcasts={["battle-shout"]=true,trueshot=true}
local utility={["water-breathing"]=true,["water-walking"]=true,["unending-breath"]=true,["detect-invis"]=true}
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
