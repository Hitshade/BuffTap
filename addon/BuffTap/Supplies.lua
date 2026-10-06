-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. See LICENSE-MPL-2.0.txt.
local _,B=...
local A=B.API
local function L(key,...) return B:Text(key,...) end

-- Informational only. This module never prepares casts, changes bindings,
-- buys items, or reads bank/alt stock. Counts are refreshed on inventory events.
local function enabled(B)
  return B.db and B.db.enabled and B.db.suppliesEnabled
end

function B:InitSupplies()
  local db=self.db
  local valid={}
  for _,choice in ipairs(self.WeaponChoices or {}) do
    if choice.class=="ROGUE" or choice.class=="MAGE" then valid[(choice.class=="MAGE" and "imbue:" or "poison:")..choice.key]=true end
  end
  for _,choice in ipairs(self.CoatingChoices or {}) do valid["coating:"..choice.key]=true end
  for _,family in ipairs(self.ConsumableFamilies or {}) do valid["consumable:"..family.key]=true end
  for key,settings in pairs(db.supplySettings) do
    if not valid[key] or type(settings)~="table" then db.supplySettings[key]=nil
    else
      if type(settings.enabled)~="boolean" then settings.enabled=true end
      if not A.Number(settings.minimum) then settings.minimum=2 end
      if not A.Number(settings.target) then settings.target=5 end
      settings.minimum=math.max(1,math.min(999,math.floor(settings.minimum)))
      settings.target=math.max(settings.minimum,math.min(999,math.floor(settings.target)))
    end
  end
  self:InvalidateSupplies(true)
  if not enabled(self) then
    self.supplyWarnings={}; self.supplyEpisodes={}; self.supplySnoozeUntil=nil
    self:CancelTimer("supplies-settle"); self:CancelTimer("supplies-update"); self:CancelTimer("supplies-snooze")
    self.supplySettling=false; self.supplyInventoryReady=false
    if self.supplyBadge then self.supplyBadge:Hide() end
  elseif not self.supplyInventoryReady and not self.supplySettling then self:SettleSupplyInventory() end
  if self.events then
    if enabled(self) and db.suppliesReadyCheck then pcall(self.events.RegisterEvent,self.events,"READY_CHECK")
    else pcall(self.events.UnregisterEvent,self.events,"READY_CHECK"); self.supplyReadyCheckAt=nil end
  end
end

function B:InvalidateSupplies(inventory)
  self.supplyDirty=true
  if inventory then self.supplyCounts={} end
end

function B:SettleSupplyInventory()
  if not enabled(self) then return end
  self.supplyInventoryReady=false; self.supplySettling=true
  self.supplyEntries=nil; self.supplyWarnings={}; self:UpdateSupplyBadge()
  self:StartTimer("supplies-settle",2,function()
    B.supplySettling=false
    if not enabled(B) then return end
    local slots=A.Call(C_Container and C_Container.GetContainerNumSlots,0)
    B.supplyInventoryReady=A.Number(slots) and slots>0
    B:InvalidateSupplies(true)
    B:SyncSupplies()
    if B.options and B.options:IsShown() and not A.Combat() then B:UpdateSupplyOptions() end
  end)
end

function B:SupplySettings(entry)
  local settings=self.db.supplySettings[entry.key]
  if not settings then
    local minimum=entry.kind=="poison" and 5 or (entry.family and entry.family.key=="food" and 5 or 2)
    settings={enabled=true,minimum=minimum,target=minimum*4}
    self.db.supplySettings[entry.key]=settings
  end
  return settings
end

function B:SupplyDefinitions()
  local entries,seen={},{}
  if self.db.weaponReminder and (self:WeaponReminderClass()=="ROGUE" or self:WeaponReminderClass()=="MAGE") then
    for _,hand in ipairs({"main","off"}) do
      local active=hand=="main" and self.db.weaponMainHand or hand=="off" and self.db.weaponOffHand
      if self:WeaponReminderClass()=="MAGE" and hand=="off" then active=false end
      local choice=active and self:WeaponPreference(hand)
      local slot=hand=="main" and 16 or 17
      -- Use equipment identity only; stock checks need no enchant/aura scans.
      local weapon=self:EquippedBuffWeapon(slot)==true
      if choice and weapon and (choice.class~="MAGE" or self:CoatingWeaponMatches(slot,choice)==true) and not seen[choice.key] then
        local ids,effects={},{}; for _,pair in ipairs(choice.items) do ids[#ids+1]=pair[1]; effects[pair[1]]=pair[2] end
        entries[#entries+1]={key=(choice.class=="MAGE" and "imbue:" or "poison:")..choice.key,name=choice.name,kind=choice.class=="MAGE" and "imbue" or "poison",ids=ids,effects=effects,
          icon=(choice.class=="MAGE" and A.Call(C_Spell and C_Spell.GetSpellTexture,choice.ranks[1])) or "Interface\\Icons\\Ability_Poisons",detail=choice.class=="MAGE" and "Selected Mage scroll stock for the compatible main-hand weapon." or "Usable ranks combined; the same poison selected for both hands is counted once."}
        seen[choice.key]=true
      end
    end
  end
  if self.db.weaponReminder then
    for _,hand in ipairs({"main","off"}) do
      local choice=self:CoatingPreference(hand)
      local slot=hand=="main" and 16 or 17
      local active=self.db[hand=="main" and "weaponMainHand" or "weaponOffHand"]~=false
      if active and choice and self:CoatingWeaponMatches(slot,choice)==true and not seen[choice.key] then
        local ids,effects={},{}
        for _,pair in ipairs(choice.items) do ids[#ids+1]=pair[1]; effects[pair[1]]=pair[2] end
        entries[#entries+1]={key="coating:"..choice.key,name=choice.name,kind="coating",ids=ids,effects=effects,uses=choice.uses,
          detail="Remaining applications; shared hand choices count once. Compatible carried ranks are combined."}
        seen[choice.key]=true
      end
    end
  end
  for _,family in ipairs(self.ConsumableFamilies or {}) do
    if self:ConsumableFamilyEnabled(family) then
      local chosen=self:ConsumableChoiceID(family)
      if chosen or not family.explicitChoice then
        local ids,effects={},{}; local name=family.name; local icon
        for _,item in ipairs(family.items or {}) do
          if not chosen or chosen==item.id then
            ids[#ids+1]=item.id
            effects[item.id]=item.useSpell
            if chosen then name=item.name or name; icon=item.icon end
          end
        end
        if #ids>0 then
          local info=self:ConsumableItemInfo(chosen or ids[1])
          if info and info.texture then icon=info.texture end
          if chosen and info and info.loaded then name=info.name end
          entries[#entries+1]={key="consumable:"..family.key,name=name,kind="consumable",family=family,
            ids=ids,effects=effects,icon=icon or family.icon or 134400,
            detail=chosen and "Only your selected item counts. Its preference stays saved when out of stock." or
              "Auto: usable supported items in this family are combined. Explicit choices count only the chosen item."}
        end
      end
    end
  end
  return entries
end

function B:SupplyCount(itemID,uses)
  self.supplyCounts=self.supplyCounts or {}
  local cacheKey=uses and "uses:"..itemID or itemID
  local cached=self.supplyCounts[cacheKey]
  if cached~=nil then return cached~=false and cached or nil end
  local count
  local cache=self.consumableCache
  if not uses and cache and not self.consumableDirty and cache.counts then count=cache.counts[itemID] end
  if not A.Number(count) then count=A.Call(C_Item and C_Item.GetItemCount,itemID,false,uses==true,false,false) end
  if not A.Number(count) or count<0 then self.supplyCounts[cacheKey]=false; return nil end
  count=math.floor(count)
  self.supplyCounts[cacheKey]=count
  return count
end

function B:SupplyEntryState(entry)
  entry.count=0; entry.carried=0
  local unknown,unknownCount=false,false
  if not self.supplyInventoryReady then entry.state="loading"; entry.count=nil; entry.carried=nil; return end
  for _,itemID in ipairs(entry.ids) do
    local count=self:SupplyCount(itemID,entry.uses)
    if count==nil then unknown=true; unknownCount=true
    else
      entry.carried=entry.carried+count
      if count>0 then
        local info=self:ConsumableItemInfo(itemID)
        local usable=A.Call(C_Item and C_Item.IsUsableItem,itemID)
        if not info or not info.loaded or not A.Number(info.spellID) then
          unknown=true; self:RequestItemData(itemID)
        elseif info.spellID~=entry.effects[itemID] then entry.mappingMismatch=true
        elseif usable==true then entry.count=entry.count+count
        elseif usable~=false then unknown=true end
        if info and info.texture then entry.icon=info.texture end
        if #entry.ids==1 and info and info.loaded then entry.name=info.name end
      end
    end
  end
  -- Partial or restricted results cannot certify an empty or low inventory.
  if unknown then entry.state="unknown"; entry.count=nil; if unknownCount then entry.carried=nil end; return end
  if entry.carried==0 then entry.state="empty"
  elseif entry.count==0 then entry.state="unusable"
  elseif entry.count<entry.settings.minimum then entry.state="low"
  else entry.state="ok" end
  entry.shortfall=math.max(0,entry.settings.target-entry.count)
end

function B:SupplyWarningText(entry)
  if entry.state=="unusable" then return L("%s: %d carried, none usable",L(entry.name),entry.carried) end
  return L(entry.name)..": "..tostring(entry.count).."/"..entry.settings.target
end

function B:SupplySnoozed()
  return self.supplySnoozeUntil and self.supplySnoozeUntil>GetTime()
end

function B:SyncSupplies(silent)
  if not enabled(self) then
    if self.supplyBadge then self.supplyBadge:Hide() end
    return {}
  end
  if A.Combat() then self.supplyDirty=true; return self.supplyEntries or {} end
  if not self.supplyDirty and self.supplyEntries then self:UpdateSupplyBadge(); return self.supplyEntries end
  local entries=self:SupplyDefinitions()
  self.supplyTrackedIDs={}
  for _,entry in ipairs(entries) do for _,id in ipairs(entry.ids) do self.supplyTrackedIDs[id]=true end end
  local warnings,newWarnings,retained={},{},{}
  self.supplyEpisodes=self.supplyEpisodes or {}
  for _,entry in ipairs(entries) do
    entry.settings=self:SupplySettings(entry)
    self:SupplyEntryState(entry)
    local low=entry.state=="empty" or entry.state=="unusable" or entry.state=="low"
    if entry.settings.enabled and low then
      warnings[#warnings+1]=entry
      retained[entry.key]=self.supplyEpisodes[entry.key] or false
      if not retained[entry.key] and not self:SupplySnoozed() and not self:ReminderPauseReason() then
        newWarnings[#newWarnings+1]=entry
        retained[entry.key]=true
      end
    elseif entry.settings.enabled and (entry.state=="loading" or entry.state=="unknown") then
      retained[entry.key]=self.supplyEpisodes[entry.key]
    end
  end
  self.supplyEpisodes=retained; self.supplyEntries=entries; self.supplyWarnings=warnings; self.supplyDirty=false
  if #newWarnings>0 and not silent then
    if self.db.suppliesChat then
      local parts={}; for _,entry in ipairs(newWarnings) do parts[#parts+1]=self:SupplyWarningText(entry) end
      self.Print(self:Text(L("Low supplies: %s"),table.concat(parts,"; ")))
    end
    if self.db.suppliesSound then self:PlayAlert("supply") end
  end
  self:UpdateSupplyBadge()
  return entries
end

function B:CreateSupplyBadge()
  if self.supplyBadge or A.Combat() then return end
  -- A separate, nonsecure indicator remains useful when the cast queue is empty.
  local f=CreateFrame("Button","BuffTapSupplyBadge",UIParent,"BackdropTemplate")
  self.supplyBadge=f
  f:SetSize(26,26); f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  f:SetBackdropColor(0.1,0.06,0.01,0.95); f:SetBackdropBorderColor(1,0.65,0.1,1)
  f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetAllPoints()
  f.count=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f.count:SetPoint("BOTTOMRIGHT",-1,1)
  f:RegisterForClicks("LeftButtonUp","RightButtonUp")
  f:SetScript("OnClick",function(_,button)
    if A.Combat() then return end
    if button=="RightButton" then B:SnoozeSupplies() else B:ShowSuppliesOptions() end
  end)
  f:SetScript("OnEnter",function()
    if A.Combat() or not GameTooltip then return end
    GameTooltip:SetOwner(f,"ANCHOR_RIGHT"); GameTooltip:SetText(L("Low supplies"),1,0.82,0.1)
    for _,entry in ipairs(B.supplyWarnings or {}) do GameTooltip:AddLine(B:SupplyWarningText(entry),1,0.8,0.4,true) end
    GameTooltip:AddLine(L("Left-click: Supplies options. Right-click: snooze for 10 minutes."),0.8,0.8,0.8,true)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f:Hide()
end

function B:UpdateSupplyBadge()
  local show=enabled(self) and not A.Combat() and not self:ReminderPauseReason() and not self:SupplySnoozed() and
    A.Call(UnitIsDeadOrGhost,"player")==false and #(self.supplyWarnings or {})>0
  if not show then if self.supplyBadge then self.supplyBadge:Hide() end; return end
  self:CreateSupplyBadge()
  local f=self.supplyBadge
  if not f then return end
  f:ClearAllPoints()
  f:SetPoint("CENTER",UIParent,"CENTER",self.db.x+self.db.size/2+16,self.db.y+self.db.size/2-13)
  f.icon:SetTexture(self.supplyWarnings[1].icon or 134400)
  f.count:SetText(tostring(#self.supplyWarnings)); f:SetAlpha(self.db.opacity); f:Show()
end

function B:SnoozeSupplies()
  if A.Combat() or not enabled(self) then return end
  self.supplySnoozeUntil=GetTime()+600; self:UpdateSupplyBadge()
  self:StartTimer("supplies-snooze",600,function()
    B.supplySnoozeUntil=nil; B:InvalidateSupplies(false); B:SyncSupplies()
  end)
  if self.options and self.options:IsShown() then self:UpdateSupplyOptions() end
end

function B:RestoreSupplies()
  self.supplySnoozeUntil=nil; self:CancelTimer("supplies-snooze")
  self:InvalidateSupplies(false); self:SyncSupplies()
  if self.options and self.options:IsShown() and not A.Combat() then self:UpdateSupplyOptions() end
end

function B:ReportSupplies()
  if not enabled(self) then self.Print("Enable supply warnings in Consumables > Supplies first."); return end
  if A.Combat() then self.supplyReadyCheckAt=GetTime(); return end
  if not self.supplyInventoryReady and not self.supplySettling then self:SettleSupplyInventory() end
  self:InvalidateSupplies(true)
  local entries=self:SyncSupplies(true); local parts={}; local unknown=false; local tracked=0
  for _,entry in ipairs(entries) do
    if entry.settings.enabled then
      tracked=tracked+1
      if entry.state=="loading" or entry.state=="unknown" then unknown=true
      elseif entry.state~="ok" then parts[#parts+1]=self:SupplyWarningText(entry) end
    end
  end
  if #parts>0 then self.Print("Supply check: "..table.concat(parts,"; ")..(unknown and "; other stock is not readable yet" or ""))
  elseif unknown then self.Print("Supply check: inventory is not ready or readable yet.")
  elseif tracked==0 then self.Print("Supply check: no enabled poisons or buff consumables selected.")
  else self.Print("Supply check: tracked supplies meet their warning minimums.") end
end

function B:SuppliesEvent(event,itemID)
  if event=="READY_CHECK" then
    if enabled(self) and self.db.suppliesReadyCheck and not self:ReminderPauseReason() then self:ReportSupplies() end
    return true
  end
  if not enabled(self) then return false end
  if event=="ITEM_DATA_LOAD_RESULT" and not (A.Number(itemID) and self.supplyTrackedIDs and self.supplyTrackedIDs[itemID]) then return false end
  if event=="PLAYER_REGEN_DISABLED" then
    self:CancelTimer("supplies-update"); if self.supplyBadge then self.supplyBadge:Hide() end
    return false
  elseif event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_LOGIN" then
    self:InvalidateSupplies(true); self:SettleSupplyInventory(); return false
  elseif event=="PLAYER_REGEN_ENABLED" then
    self:InvalidateSupplies(true)
    local pending=self.supplyReadyCheckAt; self.supplyReadyCheckAt=nil
    if pending and GetTime()-pending<=30 and not self:ReminderPauseReason() then self:ReportSupplies() else self:SyncSupplies() end
    return false
  end
  local inventory=event=="BAG_UPDATE_DELAYED" or event=="ITEM_DATA_LOAD_RESULT"
  if inventory or event=="SPELLS_CHANGED" or event=="PLAYER_LEVEL_UP" or event=="PLAYER_EQUIPMENT_CHANGED" or event=="PLAYER_ALIVE" then
    self:InvalidateSupplies(inventory or event=="PLAYER_LEVEL_UP")
    if event=="BAG_UPDATE_DELAYED" and not self.supplyInventoryReady and not self.supplySettling then self:SettleSupplyInventory() end
    if not A.Combat() then
      self:StartTimer("supplies-update",0.25,function()
        B:SyncSupplies()
        if B.options and B.options:IsShown() and not A.Combat() then B:UpdateSupplyOptions() end
      end)
    end
  elseif event=="PLAYER_DEAD" then self:UpdateSupplyBadge() end
  return false
end
