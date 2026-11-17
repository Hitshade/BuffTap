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
    if choice.class=="ROGUE" or B:ItemImbueClass(choice.class) then valid[(B:ItemImbueClass(choice.class) and "imbue:" or "poison:")..choice.key]=true end
  end
  for _,choice in ipairs(self.CoatingChoices or {}) do valid["coating:"..choice.key]=true end
  for _,family in ipairs(self.ConsumableFamilies or {}) do valid["consumable:"..family.key]=true end
  if type(db.supplyCustom)~="table" then db.supplyCustom={} end
  for i=#db.supplyCustom,1,-1 do if not A.Number(db.supplyCustom[i]) then table.remove(db.supplyCustom,i) end end
  for _,id in ipairs(db.supplyCustom) do valid["custom:"..id]=true end
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
  if self:Preference("weaponReminder") and (self:WeaponReminderClass()=="ROGUE" or self:ItemImbueClass(self:WeaponReminderClass())) then
    for _,hand in ipairs({"main","off"}) do
      local active=hand=="main" and self:Preference("weaponMainHand") or hand=="off" and self:Preference("weaponOffHand")
      if self:ItemImbueClass(self:WeaponReminderClass()) and hand=="off" then active=false end
      local choice=active and self:WeaponPreference(hand)
      local slot=hand=="main" and 16 or 17
      -- Use equipment identity only; stock checks need no enchant/aura scans.
      local weapon=self:EquippedBuffWeapon(slot)==true
      if choice and weapon and (not self:ItemImbueClass(choice.class) or self:CoatingWeaponMatches(slot,choice)==true) and not seen[choice.key] then
        local ids,effects={},{}; for _,pair in ipairs(choice.items) do ids[#ids+1]=pair[1]; effects[pair[1]]=pair[2] end
        entries[#entries+1]={key=(self:ItemImbueClass(choice.class) and "imbue:" or "poison:")..choice.key,name=choice.name,kind=self:ItemImbueClass(choice.class) and "imbue" or "poison",ids=ids,effects=effects,
          icon=(self:ItemImbueClass(choice.class) and A.Call(C_Spell and C_Spell.GetSpellTexture,choice.ranks[1])) or "Interface\\Icons\\Ability_Poisons",detail=choice.class=="WARLOCK" and "Selected Warlock stone stock for the compatible main-hand weapon." or choice.class=="MAGE" and "Selected Mage scroll stock for the compatible main-hand weapon." or "Usable ranks combined; the same poison selected for both hands is counted once."}
        seen[choice.key]=true
      end
    end
  end
  if self:Preference("weaponReminder") then
    for _,hand in ipairs({"main","off"}) do
      local choice=self:CoatingPreference(hand)
      local slot=hand=="main" and 16 or 17
      local active=self:Preference(hand=="main" and "weaponMainHand" or "weaponOffHand")~=false
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
    if not family.multi and self:ConsumableFamilyEnabled(family) then
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
            detail=family.parent and "Each ticked elixir is tracked on its own." or chosen and "Only your selected item counts. Its preference stays saved when out of stock." or
              "Auto: usable supported items in this family are combined. Explicit choices count only the chosen item."}
        end
      end
    end
  end
  for _,id in ipairs(self.db.supplyCustom or {}) do
    if not seen["custom:"..id] then
      seen["custom:"..id]=true
      local name=A.Call(C_Item and C_Item.GetItemNameByID,id)
      local icon=A.Call(C_Item and C_Item.GetItemIconByID,id)
      if not A.Text(name) then self:RequestItemData(id) end
      -- Your own items go first, so a newly added one is always in view.
      table.insert(entries,1,{key="custom:"..id,name=A.Text(name) and name or ("Item "..id),kind="custom",ids={id},effects={},
        icon=A.Number(icon) and icon or 134400,itemID=id,detail="Your own tracked item. Stock warning only; BuffTap never uses it."})
    end
  end
  return entries
end

-- Any item the player chooses to watch (crafting materials, reagents, ammo...). Stock warning only.
function B:SupplyItemID(text)
  if A.Number(text) then return math.floor(text) end
  if not A.Text(text) then return nil end
  text=text:gsub("^%s+",""):gsub("%s+$","")
  local id=tonumber(text:match("item:(%d+)") or text:match("^(%d+)$"))
  if id then return id end
  if text=="" then return nil end
  local getInfo=(C_Item and C_Item.GetItemInfo) or GetItemInfo
  local ok,_,link=pcall(getInfo or error,text)
  if not ok then return nil end
  return A.Text(link) and tonumber(link:match("item:(%d+)")) or nil
end

function B:AddSupplyItem(text)
  local id=self:SupplyItemID(text)
  if not id then return false,L("Item not found. Shift-click or drag it from your bags.") end
  local list=self.db.supplyCustom
  for _,existing in ipairs(list) do if existing==id then return false,L("Already tracked.") end end
  list[#list+1]=id
  self.db.supplySettings["custom:"..id]=nil
  self:InitSupplies(); self:InvalidateSupplies(true)
  return true
end

function B:RemoveSupplyItem(id)
  local list=self.db.supplyCustom or {}
  for i=#list,1,-1 do if list[i]==id then table.remove(list,i) end end
  self.db.supplySettings["custom:"..id]=nil
  self:InvalidateSupplies(true)
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
      if entry.kind=="custom" then entry.count=entry.count+count
      elseif count>0 then
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

-- The Supplies list is always shown, even with warnings off, so tracked items can be seen and removed.
function B:SupplyDisplayEntries()
  if enabled(self) then return self:SyncSupplies() end
  if not (self.db and self.db.enabled) then return {} end
  local slots=A.Call(C_Container and C_Container.GetContainerNumSlots,0)
  local ready=self.supplyInventoryReady
  self.supplyInventoryReady=A.Number(slots) and slots>0
  local entries=self:SupplyDefinitions()
  for _,entry in ipairs(entries) do entry.settings=self:SupplySettings(entry); self:SupplyEntryState(entry) end
  self.supplyInventoryReady=ready
  return entries
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

-- Supplies reminder: a companion icon styled like the buff reminder, moved and customized on its own.
-- By default it only shows while resting (city or inn), where you can restock.
function B:NormalizeSupplyReminder()
  local d=self.db
  if type(d.supplyReminder)~="boolean" then d.supplyReminder=true end
  if type(d.supplyAnywhere)~="boolean" then d.supplyAnywhere=false end
  for _,k in ipairs({"supplyShowName","supplyShowCount"}) do if type(d[k])~="boolean" then d[k]=true end end
  d.supplySize=A.Number(d.supplySize) and math.max(24,math.min(96,math.floor(d.supplySize))) or 40
  d.supplyOpacity=A.Number(d.supplyOpacity) and math.max(.25,math.min(1,d.supplyOpacity)) or 1
  d.supplyTextSize=A.Number(d.supplyTextSize) and (d.supplyTextSize==0 and 0 or math.max(8,math.min(20,math.floor(d.supplyTextSize)))) or 0
  d.supplyTextGap=A.Number(d.supplyTextGap) and math.max(0,math.min(20,math.floor(d.supplyTextGap))) or 4
  d.supplyTextFont=self.NormalizeTextFontKey and self:NormalizeTextFontKey(d.supplyTextFont) or d.supplyTextFont or "default"
  if not ({gold=true,cyan=true,green=true,red=true,white=true})[d.supplyTextColor] then d.supplyTextColor="white" end
  if d.supplyTextOutline=="default" and self.GameTextOutline then d.supplyTextOutline=self:GameTextOutline() end
  if not ({none=true,outline=true,thick=true})[d.supplyTextOutline] then d.supplyTextOutline="outline" end
  if not ({none=true,soft=true,pulse=true,pixel=true,autocast=true,proc=true,shine=true,ripple=true,bounce=true,orbit=true})[d.supplyEffectStyle] then d.supplyEffectStyle="soft" end
  if not ({gold=true,cyan=true,green=true,red=true,white=true})[d.supplyEffectColor] then d.supplyEffectColor="gold" end
  if not ({slow=true,normal=true,fast=true})[d.supplyEffectSpeed] then d.supplyEffectSpeed="normal" end
  if d.supplyIconStyle~="modern" then d.supplyIconStyle="classic" end
  if not A.Number(d.supplyX) or not A.Number(d.supplyY) then
    d.supplyX=(A.Number(d.x) and d.x or 0)+(A.Number(d.size) and d.size or 48)/2+44
    d.supplyY=A.Number(d.y) and d.y or 0
  end
  d.supplyX=math.max(-4000,math.min(4000,d.supplyX)); d.supplyY=math.max(-4000,math.min(4000,d.supplyY))
end

function B:SupplyLabelText(preview)
  local d=self.db; local first=preview or (self.supplyWarnings or {})[1]
  if not first then return "" end
  local lines={}
  if d.supplyShowName then lines[#lines+1]=L(first.name or "") end
  if d.supplyShowCount then
    local count=first.count~=nil and tostring(first.count) or "?"
    local want=first.settings and first.settings.target
    lines[#lines+1]=want and (count.." / "..want) or count
  end
  local more=#(self.supplyWarnings or {})-1
  if not preview and more>0 then lines[#lines+1]="+"..more end
  return table.concat(lines,"\n")
end

function B:CreateSupplyBadge()
  if self.supplyBadge or A.Combat() then return end
  local f=CreateFrame("Button","BuffTapSupplyReminder",UIParent,"BackdropTemplate")
  self.supplyBadge=f
  f:SetSize(40,40); f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true); f:SetMovable(true)
  f:RegisterForDrag("LeftButton"); f:RegisterForClicks("LeftButtonUp","RightButtonUp")
  f.icon=f:CreateTexture(nil,"ARTWORK"); f.art=f.icon
  f.glow=f:CreateTexture(nil,"OVERLAY"); f.glow:SetAllPoints(); f.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight"); f.glow:SetBlendMode("ADD")
  -- Same pulse as the camping reminder, so the Pulse effect animates on the live icon too.
  if type(f.glow.CreateAnimationGroup)=="function" then
    local ag=f.glow:CreateAnimationGroup()
    if ag then
      local first=ag:CreateAnimation("Alpha"); first:SetFromAlpha(1); first:SetToAlpha(.45); first:SetDuration(.7); first:SetOrder(1)
      local second=ag:CreateAnimation("Alpha"); second:SetFromAlpha(.45); second:SetToAlpha(1); second:SetDuration(.7); second:SetOrder(2)
      ag:SetLooping("REPEAT"); f.pulseAnimation=ag
    end
  end
  f.time=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.count=f.time
  f:SetScript("OnHide",function(s) if B.StopIconEffect then B:StopIconEffect(s) end end)
  f:SetScript("OnDragStart",function(s) if not A.Combat() then s.dragged=true; s.dragging=true; s:StartMoving() end end)
  f:SetScript("OnDragStop",function(s)
    s:StopMovingOrSizing(); s.dragging=nil
    local x,y=s:GetCenter(); local px,py=UIParent:GetCenter()
    if A.Number(x) and A.Number(y) and A.Number(px) and A.Number(py) then B.db.supplyX=x-px; B.db.supplyY=y-py end
    B:UpdateSupplyBadge()
  end)
  f:SetScript("OnClick",function(s,button)
    if s.dragged then s.dragged=nil; return end
    if A.Combat() then return end
    if button=="RightButton" then B:SnoozeSupplies() else B:ShowSuppliesOptions() end
  end)
  f:SetScript("OnEnter",function(s)
    if A.Combat() or not GameTooltip then return end
    GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:SetText(L("Low supplies"),1,0.82,0.1)
    for _,entry in ipairs(B.supplyWarnings or {}) do GameTooltip:AddLine(B:SupplyWarningText(entry),1,0.8,0.4,true) end
    GameTooltip:AddLine(L("Left-click: Supplies options. Right-click: snooze for 10 minutes. Drag to move."),0.8,0.8,0.8,true)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f:Hide()
end

function B:StyleSupplyLabel(fs,frame)
  local d=self.db
  self.supplyTextSettings=self.supplyTextSettings or {}
  local t=self.supplyTextSettings
  t.labelFont=d.supplyTextFont; t.labelColor=d.supplyTextColor; t.labelOutline=d.supplyTextOutline; t.labelSize=d.supplyTextSize
  if self.ApplyLabelStyle then self:ApplyLabelStyle(fs,t,"GameFontHighlightSmall") end
  fs:ClearAllPoints(); fs:SetPoint("TOP",frame,"BOTTOM",0,-d.supplyTextGap)
  fs:SetWidth(180); fs:SetJustifyH("CENTER"); fs:SetWordWrap(true)
end

function B:StyleSupplyBadge(f)
  local d=self.db
  -- Its own frame style, text and glow, set under Customization > Supplies.
  local style=d.supplyIconStyle=="modern" and "modern" or "classic"
  f.icon:ClearAllPoints()
  -- Use the same art bounds and shared border/glow styling as Buff and previews.
  f:SetBackdrop(nil); f.icon:SetAllPoints(f)
  if self.ApplyIconStyle then self:ApplyIconStyle(f,f.icon,style) end
  self:StyleSupplyLabel(f.time,f)
end

function B:SupplyPreviewing()
  return self.supplyPreviewUntil and self.supplyPreviewUntil>GetTime() or false
end

function B:UpdateSupplyBadge()
  if not self.db then return end
  self:NormalizeSupplyReminder()
  local d=self.db
  local f=self.supplyBadge
  if f and f.dragging then return end
  local warnings=self.supplyWarnings or {}
  local preview=not A.Combat() and self:SupplyPreviewing()
  local where=d.supplyAnywhere or A.Call(IsResting)==true
  -- Mounted or stealthed pauses still hide it; the resting pause does not, since towns are where it belongs.
  local pause=self.ReminderPauseReason and self:ReminderPauseReason()
  if pause=="resting" then pause=nil end
  local show=preview or (enabled(self) and d.supplyReminder and where and not pause and not A.Combat() and not self:SupplySnoozed() and
    A.Call(UnitIsDeadOrGhost,"player")==false and #warnings>0)
  if not show then if f then f:Hide() end; return end
  self:CreateSupplyBadge(); f=self.supplyBadge
  if not f then return end
  local sample=not warnings[1] and {name=L("Your item"),count=2,settings={target=8},icon="Interface\\Icons\\INV_Crate_01"} or nil
  self:StyleSupplyBadge(f)
  f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",d.supplyX,d.supplyY)
  f:SetSize(d.supplySize,d.supplySize); f:SetAlpha(d.supplyOpacity)
  f.icon:SetTexture((warnings[1] and warnings[1].icon) or (sample and sample.icon) or 134400)
  local text=self:SupplyLabelText(sample)
  f.time:SetText(text); f.time:SetShown(text~="")
  if self.ApplyIconEffect then
    self.supplyEffectSettings=self.supplyEffectSettings or {}
    local e=self.supplyEffectSettings; e.effectStyle=d.supplyEffectStyle; e.effectColor=d.supplyEffectColor; e.effectSpeed=d.supplyEffectSpeed
    self:ApplyIconEffect(f,true,e)
  end
  f:Show()
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
  if not enabled(self) then
    -- Warnings off: no alert work, but keep the visible Supplies list's counts fresh.
    if event=="BAG_UPDATE_DELAYED" or event=="ITEM_DATA_LOAD_RESULT" then
      self:InvalidateSupplies(true)
      if not A.Combat() and self.options and self.options:IsShown() then
        self:StartTimer("supplies-update",0.25,function() if B.options and B.options:IsShown() and not A.Combat() then B:UpdateSupplyOptions() end end)
      end
    end
    return false
  end
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
  elseif event=="PLAYER_DEAD" or event=="PLAYER_UPDATE_RESTING" then self:UpdateSupplyBadge() end
  return false
end
