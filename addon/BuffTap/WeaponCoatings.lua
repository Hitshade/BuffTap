-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local _,B=...
local A=B.API

local HANDS={
  {slot=16,key="main",label="Main hand"},
  {slot=17,key="off",label="Off hand"},
}

local function playerClass()
  local ok,_,class=pcall(UnitClass,"player")
  return ok and A.Text(class) and class or nil
end

local function equippedWeapon(slot)
  local itemID=A.Call(GetInventoryItemID,"player",slot)
  if itemID==nil or itemID==0 then return false end
  if not A.Number(itemID) then return nil,"equipped item unreadable" end
  local getInfo=(C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if type(getInfo)~="function" then return nil,"item class API unavailable" end
  local ok,_,_,_,equipLoc,_,classID=pcall(getInfo,itemID)
  if not ok or not A.Public(equipLoc) or not A.Public(classID) then return nil,"item class unreadable" end
  if A.Number(classID) then return classID==2 end
  if A.Text(equipLoc) then
    return equipLoc=="INVTYPE_WEAPON" or equipLoc=="INVTYPE_2HWEAPON"
      or equipLoc=="INVTYPE_WEAPONMAINHAND" or equipLoc=="INVTYPE_WEAPONOFFHAND"
  end
  return nil,"item class unavailable"
end

local function paperDollEnchant(slot)
  local fn=C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo
  if type(fn)~="function" then return nil,"temporary enchant API unavailable" end
  local ok,info=pcall(fn,slot)
  if not ok or not A.Public(info) then return nil,"temporary enchant unreadable" end
  if info==nil then return {known=true,hasEnchant=false} end
  if type(info)~="table" then return nil,"unexpected temporary enchant data" end
  local id,remaining,charges,hasExpiration=info.enchantID,info.remainingTimeMs,info.chargesRemaining,info.hasExpirationTime
  if not A.Public(id) or not A.Public(remaining) or not A.Public(charges) or not A.Public(hasExpiration) then
    return nil,"restricted temporary enchant data"
  end
  local active=true
  if hasExpiration==true and A.Number(remaining) and remaining<=0 then active=false end
  return {known=true,hasEnchant=active,enchantID=A.Number(id) and id or nil,
    remaining=A.Number(remaining) and math.max(0,remaining/1000) or nil,
    charges=A.Number(charges) and charges or nil}
end

function B:WeaponReminderClass()
  local class=playerClass()
  if class=="ROGUE" or class=="SHAMAN" then return class end
end

function B:WeaponReminderAvailable()
  local class=self:WeaponReminderClass()
  if not class then return false end
  -- Do not warn characters that have not learned any supported poison/imbue.
  for _,def in ipairs(self.Buffs or {}) do
    if def.class==class and def.kind=="weapon" then
      for _,id in ipairs(def.ranks or {}) do if A.Known(id) then return true end end
    end
  end
  return false
end

function B:WeaponCoatingState(slot)
  local isWeapon,why=equippedWeapon(slot)
  if isWeapon~=true then return {known=isWeapon==false,weapon=false,reason=why} end
  local enchant,err=paperDollEnchant(slot)
  if not enchant then return {known=false,weapon=true,reason=err} end
  enchant.weapon=true
  enchant.slot=slot
  enchant.icon=A.Call(GetInventoryItemTexture,"player",slot)
  if self.stats then self.stats.weaponReads=(self.stats.weaponReads or 0)+1 end
  return enchant
end

function B:SelectWeaponReminder()
  if not (self.db and self.db.weaponReminder) then return nil,"weapon reminders disabled" end
  local class=self:WeaponReminderClass()
  if not class or not self:WeaponReminderAvailable() then return nil,"no learned coating ability" end
  local enabled={main=self.db.weaponMainHand~=false,off=self.db.weaponOffHand~=false}
  local unreadableReason
  for _,hand in ipairs(HANDS) do
    if enabled[hand.key] then
      local state=self:WeaponCoatingState(hand.slot)
      if state.known and state.weapon and not state.hasEnchant then
        local poison=class=="ROGUE"
        return {source="weapon-reminder",manual=true,valid=true,key="weapon-"..hand.key,
          name=poison and "Poison missing" or "Weapon coating missing",
          icon=(A.Number(state.icon) or A.Text(state.icon)) and state.icon or (poison and "Interface\\Icons\\Ability_Poisons" or 136026),
          target="manual",targetName=hand.label.." • manual",slot=hand.slot,needState="missing",
          reason="Apply a "..(poison and "poison" or "weapon coating").." manually to your "..hand.label:lower().."."}
      elseif not state.known and state.weapon then
        -- One restricted hand must not hide a definite missing coating on the
        -- other hand. Preserve the diagnostic and finish checking both slots.
        unreadableReason=unreadableReason or state.reason or "weapon enchant state unavailable"
      end
    end
  end
  return nil,unreadableReason or "weapon coatings present"
end

function B:ValidateWeaponReminder(action)
  if not (action and action.manual and action.source=="weapon-reminder" and action.slot) then return false end
  if not (self.db and self.db.weaponReminder and self:WeaponReminderAvailable()) then return false end
  if action.slot==16 and self.db.weaponMainHand==false then return false end
  if action.slot==17 and self.db.weaponOffHand==false then return false end
  local state=self:WeaponCoatingState(action.slot)
  return state.known and state.weapon and not state.hasEnchant
end

function B:WeaponReminderSummary()
  if not self:WeaponReminderClass() then return "not applicable" end
  if not (self.db and self.db.weaponReminder) then return "disabled" end
  if not self:WeaponReminderAvailable() then return "waiting for a learned poison or imbue" end
  local parts={}
  for _,hand in ipairs(HANDS) do
    local enabled=hand.key=="main" and self.db.weaponMainHand~=false or hand.key=="off" and self.db.weaponOffHand~=false
    if enabled then
      local state=self:WeaponCoatingState(hand.slot)
      if state.known and not state.weapon then parts[#parts+1]=hand.label..": no weapon"
      elseif state.known then parts[#parts+1]=hand.label..": "..(state.hasEnchant and "coated" or "missing")
      else parts[#parts+1]=hand.label..": unavailable" end
    end
  end
  return #parts>0 and table.concat(parts," | ") or "no hands selected"
end
