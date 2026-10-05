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
  local ok,_,_,_,equipLoc,_,classID,subclassID=pcall(getInfo,itemID)
  if not ok or not A.Public(equipLoc) or not A.Public(classID) then return nil,"item class unreadable" end
  if not A.Public(subclassID) then return nil,"weapon subclass unreadable" end
  if subclassID==20 then return false end -- fishing poles are not combat weapons
  if A.Number(classID) then return classID==2 end
  if A.Text(equipLoc) then
    return equipLoc=="INVTYPE_WEAPON" or equipLoc=="INVTYPE_2HWEAPON"
      or equipLoc=="INVTYPE_WEAPONMAINHAND" or equipLoc=="INVTYPE_WEAPONOFFHAND"
  end
  return nil,"item class unavailable"
end

function B:EquippedBuffWeapon(slot) return equippedWeapon(slot) end

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

-- Generated facts from Forever client DB2 exports; independent of reference addon code.
B.WeaponChoices={
  {key="windfury",class="SHAMAN",name="Windfury Weapon",ranks={16362,10486,8235,8232},enchants={283,284,525,1669},items={}},
  {key="flametongue",class="SHAMAN",name="Flametongue Weapon",ranks={16342,16341,16339,8030,8027,8024},enchants={4,5,3,1665,1666,523},items={}},
  {key="frostbrand",class="SHAMAN",name="Frostbrand Weapon",ranks={16356,16355,10456,8038,8033},enchants={12,2,524,1668,1667},items={}},
  {key="rockbiter",class="SHAMAN",name="Rockbiter Weapon",ranks={16316,16315,16314,10399,8019,8018,8017},enchants={6,29,1,503,683,1663,1664},items={}},
  {key="instant-poison",class="ROGUE",name="Instant Poison",ranks={11340,11339,11338,8688,8686,8679},enchants={325,323,324,625,623,624},items={{8928,11340},{8927,11339},{8926,11338},{6950,8688},{6949,8686},{6947,8679}}},
  {key="deadly-poison",class="ROGUE",name="Deadly Poison",ranks={25351,11356,11355,2824,2823},enchants={7,8,627,626,2630},items={{20844,25351},{8985,11356},{8984,11355},{2893,2824},{2892,2823}}},
  {key="crippling-poison",class="ROGUE",name="Crippling Poison",ranks={3408},enchants={22},items={{3775,3408}}},
  {key="mind-poison",class="ROGUE",name="Mind-numbing Poison",ranks={11399,8693,5761},enchants={35,23,643},items={{9186,11399},{6951,8693},{5237,5761}}},
  {key="wound-poison",class="ROGUE",name="Wound Poison",ranks={13227,13226,13225,13219},enchants={704,705,706,703},items={{10922,13227},{10921,13226},{10920,13225},{10918,13219}}},
}

-- Read all weapon-enchant categories. Inventory slots (16/17) are NOT the
-- WeaponSlot enum values (0/1). Permanent enchants never satisfy a reminder.
local function modernEnchant(slot)
  if not (C_Item and type(C_Item.GetWeaponEnchantInfo)=="function") then return nil end
  local enums=Enum and Enum.WeaponSlot
  local weaponSlot=enums and (slot==16 and enums.MainHand or enums.OffHand)
  if not A.Number(weaponSlot) then return {known=false,reason="weapon slot enum unavailable"} end
  local list,why=A.Call(C_Item.GetWeaponEnchantInfo,weaponSlot)
  if type(list)~="table" then return {known=false,reason=why or "weapon enchant list unavailable"} end
  local types=Enum and Enum.ItemEnchantType
  if not types or not A.Number(types.Imbue) or not A.Number(types.Temporary) then
    return {known=false,reason="weapon enchant types unavailable"}
  end
  local class=playerClass()
  local state={known=true,hasEnchant=false,modern=true,entries={}}
  for _,info in pairs(list) do
    if not A.Public(info) or type(info)~="table" or not A.Public(info.hasEnchant) or not A.Public(info.enchantType) then
      return {known=false,reason="restricted weapon enchant data"}
    end
    local relevant=info.enchantType==types.Imbue or (class=="ROGUE" and info.enchantType==types.Temporary)
    if relevant and info.hasEnchant==true then
      if not A.Number(info.enchantID) or not A.Number(info.timeLeft) then
        return {known=false,reason="weapon enchant identity or timer unreadable"}
      end
      if info.timeLeft>0 then
        local key
        for _,choice in ipairs(B.WeaponChoices) do
          if choice.class==class then
            for _,id in ipairs(choice.enchants) do if id==info.enchantID then key=choice.key; break end end
          end
          if key then break end
        end
        -- Rogue oils/stones are a different family; unknown temporary effects
        -- are retained conservatively, while recognized poisons are actionable.
        if class=="SHAMAN" or key then
          if class=="SHAMAN" and not key then state.unknownImbue=true end
          local entry={key=key,id=info.enchantID,remaining=info.timeLeft/1000}
          state.entries[#state.entries+1]=entry
          state.hasEnchant=true; state.enchantID=entry.id
          state.remaining=state.remaining and math.min(state.remaining,entry.remaining) or entry.remaining
        elseif class=="ROGUE" then
          state.unknownTemporary=true
        end
      end
    end
  end
  return state
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
  local enchant=modernEnchant(slot)
  local err
  if not enchant then enchant,err=paperDollEnchant(slot) end
  if not enchant then return {known=false,weapon=true,reason=err} end
  if enchant.remaining and enchant.remaining>0 then
    local threshold=self.db.weaponApply and self.db.weaponSeconds or 0
    self:ConsiderWake(enchant.remaining>threshold and enchant.remaining-threshold or enchant.remaining)
  end
  enchant.weapon=true
  enchant.slot=slot
  enchant.icon=A.Call(GetInventoryItemTexture,"player",slot)
  if self.stats then self.stats.weaponReads=(self.stats.weaponReads or 0)+1 end
  return enchant
end

local function selectManualReminder(self)
  if not (self.db and self.db.weaponReminder) then return nil,"weapon reminders disabled" end
  local class=self:WeaponReminderClass()
  if not class or not self:WeaponReminderAvailable() then return nil,"no learned coating ability" end
  local enabled={main=self.db.weaponMainHand~=false,off=class=="ROGUE" and self.db.weaponOffHand~=false}
  local unreadableReason
  for _,hand in ipairs(HANDS) do
    if enabled[hand.key] then
      local state=self:WeaponCoatingState(hand.slot)
      if state.known and state.weapon and not state.hasEnchant then
        local poison=class=="ROGUE"
        local action={source="weapon-reminder",manual=true,valid=true,key="weapon-"..hand.key,
          name=poison and "Poison missing" or "Weapon coating missing",
          icon=(A.Number(state.icon) or A.Text(state.icon)) and state.icon or (poison and "Interface\\Icons\\Ability_Poisons" or 136026),
          target="manual",targetName=hand.label.." • manual",slot=hand.slot,needState="missing",
          reason="Apply a "..(poison and "poison" or "weapon coating").." manually to your "..hand.label:lower().."."}
        if not (self.HelperSuppressed and self:HelperSuppressed(action)) then return action end
      elseif not state.known and state.weapon then
        -- One restricted hand must not hide a definite missing coating on the
        -- other hand. Preserve the diagnostic and finish checking both slots.
        unreadableReason=unreadableReason or state.reason or "weapon enchant state unavailable"
      end
    end
  end
  return nil,unreadableReason or "weapon coatings present"
end

local function validateManualReminder(self,action)
  if not (action and action.manual and action.source=="weapon-reminder" and action.slot) then return false end
  if not (self.db and self.db.weaponReminder and self:WeaponReminderAvailable()) then return false end
  if action.slot==17 and self:WeaponReminderClass()~="ROGUE" then return false end
  if action.slot==16 and self.db.weaponMainHand==false then return false end
  if action.slot==17 and self.db.weaponOffHand==false then return false end
  local state=self:WeaponCoatingState(action.slot)
  return state.known and state.weapon and not state.hasEnchant
end

function B:WeaponReminderSummary()
  if not self:WeaponReminderClass() then return "not applicable" end
  if not (self.db and self.db.weaponReminder) then return "disabled" end
  if not self.db.weaponApply and not self:WeaponReminderAvailable() then return "waiting for a learned poison or imbue" end
  local parts={}
  for _,hand in ipairs(HANDS) do
    local enabled=hand.key=="main" and self.db.weaponMainHand~=false or hand.key=="off" and self:WeaponReminderClass()=="ROGUE" and self.db.weaponOffHand~=false
    if enabled then
      local state=self:WeaponCoatingState(hand.slot)
      if state.known and not state.weapon then parts[#parts+1]=hand.label..": no weapon"
      elseif state.known then parts[#parts+1]=hand.label..": "..(state.hasEnchant and "coated" or "missing")
      else parts[#parts+1]=hand.label..": unavailable" end
    end
  end
  return #parts>0 and table.concat(parts," | ") or "no hands selected"
end

function B:WeaponChoice(key)
  local class=self:WeaponReminderClass()
  for _,choice in ipairs(self.WeaponChoices) do if choice.key==key and choice.class==class then return choice end end
end

function B:WeaponPreference(hand)
  return self:WeaponChoice(self.db.weaponChoices[hand])
end

function B:WeaponChoiceSource(choice)
  if not choice then return nil,"Choose a weapon buff in Weapons options." end
  if choice.class=="SHAMAN" then
    for _,id in ipairs(choice.ranks) do
      if A.Known(id) then
        local name=A.Call(C_Spell and C_Spell.GetSpellName,id)
        local icon=A.Call(C_Spell and C_Spell.GetSpellTexture,id)
        if A.Text(name) then
          return {id=id,name=name,icon=(A.Number(icon) or A.Text(icon)) and icon or 136026,secureType="spell"}
        end
      end
    end
    return nil,"Preferred imbue not learned."
  end
  -- Only supported consumable poison IDs can become item actions. Highest
  -- carried usable rank wins; preferences remain saved when stock runs out.
  local carried,unknown=0,false
  for _,pair in ipairs(choice.items) do
    local id=pair[1]
    local count=A.Call(C_Item and C_Item.GetItemCount,id,false,false,false,false)
    if A.Number(count) then carried=carried+math.max(0,count) else unknown=true end
    local usable=count and A.Number(count) and count>0 and A.Call(C_Item and C_Item.IsUsableItem,id)
    if A.Number(count) and count>0 and usable~=true and usable~=false then unknown=true end
    if A.Number(count) and count>0 and usable==true then
      local spellFn=C_Item and C_Item.GetItemSpell
      if type(spellFn)~="function" then return nil,"Poison item spell API unavailable." end
      local spellOK,spellName,spellID=pcall(spellFn,id)
      if spellOK and spellID==nil and spellName==nil then
        self:RequestItemData(id)
        return nil,"Preferred poison item data is loading."
      end
      if not spellOK or not A.Number(spellID) or spellID~=pair[2] then
        return nil,"Poison item effect differs from the supported catalog."
      end
      local fn=C_Item and C_Item.GetItemInfo
      if type(fn)=="function" then
        local ok,name,link,quality,itemLevel,minLevel,itemType,itemSubType,stackCount,equipLoc,icon=pcall(fn,id)
        if ok and A.Text(name) and (A.Text(icon) or A.Number(icon)) and icon~=0 and icon~=134400 then
          return {id=pair[2],itemID=id,itemToken="item:"..id,name=name,icon=icon,count=count,secureType="item"}
        end
        self:RequestItemData(id)
        return nil,"Preferred poison item data is loading."
      end
    end
  end
  if unknown then return nil,"Preferred poison inventory or usability data is unavailable." end
  if carried>0 then return nil,"Preferred poison is carried, but no carried rank is usable." end
  return nil,"Preferred poison is out of stock."
end

function B:WeaponNeed(state,choice)
  if not state.known or not state.weapon then return false end
  local threshold=self.db.weaponSeconds or 60
  if state.remaining and state.remaining>threshold then self:ConsiderWake(state.remaining-threshold) end
  if not state.hasEnchant then return true,"missing" end
  if not choice or not state.modern then return false end
  for _,entry in ipairs(state.entries or {}) do
    if entry.key==choice.key then
      return entry.remaining<=threshold,"expiring",entry.remaining
    end
  end
  -- A different effect is only replaced after explicit permission in options.
  return self.db.weaponReplace==true,"different"
end

function B:WeaponActionFor(hand)
  local state=self:WeaponCoatingState(hand.slot)
  local choice=self:WeaponPreference(hand.key)
  local needed,need,remaining=self:WeaponNeed(state,choice)
  if not needed then return nil,state.reason end
  local source,why=self:WeaponChoiceSource(choice)
  local action={source="weapon-reminder",valid=true,key="weapon-"..hand.key,slot=hand.slot,
    target="player",targetName=hand.label,name=choice and choice.name or "Weapon buff missing",
    icon=state.icon or 136026,needState=need,remaining=remaining,preference=choice and choice.key,
    weaponID=A.Call(GetInventoryItemID,"player",hand.slot),selectedAt=GetTime()}
  if source then for k,v in pairs(source) do action[k]=v end end
  -- Effect 360 imbues are assigned by the client. Do not pretend target-slot
  -- can force a dual-wield Shaman hand or silently swap the player's weapons.
  if source and choice.class=="SHAMAN" and equippedWeapon(17)==true then
    why="Shaman dual wield: apply this hand manually; the client chooses the imbue hand."
  elseif source and not state.modern then
    why="Weapon effect category cannot be verified on this client."
  elseif source and state.unknownTemporary and choice.class=="ROGUE" then
    why="An unrecognized coating is active; apply poison manually to avoid overwriting it."
  elseif source and state.unknownImbue then
    why="An unrecognized imbue is active; apply your preference manually."
  end
  if self.weaponPending and self.weaponPending.untilTime>GetTime() then
    self:ConsiderWake(self.weaponPending.untilTime-GetTime()); return nil,"weapon application settling"
  end
  if source and not why then
    action.manual=false
    if source.secureType=="spell" then
      if not self:Validate(action) then return nil,"imbue not ready" end
    else
      local fn=C_Item and C_Item.GetItemCooldown
      if type(fn)~="function" then action.manual=true; why="Poison cooldown API unavailable."
      else
        local ok,start,duration,enabled=pcall(fn,source.itemID)
        if not ok or not A.Number(start) or not A.Number(duration) or not A.Public(enabled) or (enabled~=true and enabled~=1) then
          action.manual=true; why="Poison cooldown unavailable."
        elseif duration>0 and start+duration>GetTime() then self:ConsiderWake(start+duration-GetTime()+0.03); return nil,"poison cooldown" end
      end
    end
  else action.manual=true end
  action.reason=why or (need=="different" and "Replace the different weapon buff you chose to replace." or "Apply your preferred weapon buff.")
  return action
end

function B:SelectWeaponReminder()
  if not self.db.weaponApply then return selectManualReminder(self) end
  if not self.db.weaponReminder or not self:WeaponReminderClass() then return nil,"weapon reminders disabled" end
  local fallback,why
  for _,hand in ipairs(HANDS) do
    if (hand.key=="main" or self:WeaponReminderClass()=="ROGUE") and self.db[hand.key=="main" and "weaponMainHand" or "weaponOffHand"]~=false then
      local action,err=self:WeaponActionFor(hand)
      if action and not (self.HelperSuppressed and self:HelperSuppressed(action)) then
        if not action.manual then return action end
        fallback=fallback or action
      end
      why=why or err
    end
  end
  return fallback,why or "weapon coatings present"
end

function B:ValidateWeaponReminder(action)
  if not self.db.weaponApply then return action.manual and validateManualReminder(self,action) end
  if not self.db.weaponReminder then return false end
  local hand=action.slot==16 and HANDS[1] or action.slot==17 and HANDS[2]
  if action.slot==17 and self:WeaponReminderClass()~="ROGUE" then return false end
  if not hand or self.db[hand.key=="main" and "weaponMainHand" or "weaponOffHand"]==false then return false end
  local fresh=self:WeaponActionFor(hand)
  return fresh~=nil and fresh.manual==action.manual and fresh.preference==action.preference
    and fresh.weaponID==action.weaponID and fresh.itemID==action.itemID and fresh.id==action.id
end

function B:AfterWeaponClick(action,down)
  if not action or action.manual or down==false or A.Combat() then return end
  self.weaponPending={untilTime=GetTime()+5}
  self:ConsiderWake(5)
end
