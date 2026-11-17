-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ADDON,B=...
local A=B.API

-- Consumables are deliberately whitelist-driven. Unknown items are never turned
-- into secure actions, so beta database changes fail by omission rather than by
-- guessing from tooltip text.
local normCache,normCount={},0
local function norm(v)
  if not A.Text(v) then return "" end
  local cached=normCache[v]
  if cached then return cached end
  cached=v:lower():gsub("%s*%b()$", "")
  if normCount>=2000 then normCache,normCount={},0 end
  normCache[v]=cached; normCount=normCount+1
  return cached
end

local function safeItemCount(itemID)
  local fn=C_Item and C_Item.GetItemCount
  if type(fn)~="function" then return nil,"item count API unavailable" end
  local ok,value=pcall(fn,itemID,false,false,false,false)
  if not ok then return nil,"item count API failed" end
  if not A.Public(value) or type(value)~="number" then return nil,"item count unreadable" end
  return math.max(0,math.floor(value+0.5))
end

local function safeItemInfo(itemID)
  local fn=C_Item and C_Item.GetItemInfo
  if type(fn)~="function" then return nil,"item info API unavailable" end
  local ok,name,link,quality,itemLevel,minLevel,itemType,itemSubType,stackCount,equipLoc,texture=pcall(fn,itemID)
  if not ok then return nil,"item info API failed" end
  if not A.Public(name) then return nil,"item name restricted" end
  if not A.Public(minLevel) then return nil,"item level restricted" end
  if not A.Public(texture) then return nil,"item texture restricted" end
  return {name=A.Text(name) and name or nil,minLevel=A.Number(minLevel) and minLevel or nil,
    texture=(A.Number(texture) or A.Text(texture)) and texture or nil,loaded=A.Text(name)}
end

local function safeInstantIcon(itemID)
  local fn=C_Item and C_Item.GetItemInfoInstant
  if type(fn)~="function" then return nil end
  local ok,_,_,_,_,icon=pcall(fn,itemID)
  if ok and A.Public(icon) and (A.Number(icon) or A.Text(icon)) then return icon end
end

local function safeItemSpell(itemID)
  local fn=C_Item and C_Item.GetItemSpell
  if type(fn)~="function" then return nil,nil end
  local ok,name,spellID=pcall(fn,itemID)
  if not ok then return nil,nil end
  if not A.Public(name) then name=nil end
  if not A.Public(spellID) then spellID=nil end
  return A.Text(name) and name or nil,A.Number(spellID) and spellID or nil
end

local function safeUsable(itemID)
  local fn=C_Item and C_Item.IsUsableItem
  if type(fn)~="function" then return nil,"item usability API unavailable" end
  local ok,usable=pcall(fn,itemID)
  if not ok then return nil,"item usability API failed" end
  if not A.Public(usable) or type(usable)~="boolean" then return nil,"item usability unreadable" end
  return usable
end

local function safeCooldown(itemID)
  local fn=C_Item and C_Item.GetItemCooldown
  if type(fn)~="function" then return nil,nil,nil,"item cooldown API unavailable" end
  local ok,startTime,duration,enabled=pcall(fn,itemID)
  if not ok then return nil,nil,nil,"item cooldown API failed" end
  -- Some clients report the enabled flag as 1/0 instead of true/false.
  if enabled==1 then enabled=true elseif enabled==0 then enabled=false end
  if not A.Number(startTime) or not A.Number(duration) or not A.Public(enabled) or type(enabled)~="boolean" then
    return nil,nil,nil,"item cooldown unreadable"
  end
  return startTime,duration,enabled,nil
end

function B:ConsumableFamily(key)
  for _,family in ipairs(self.ConsumableFamilies or {}) do if family.key==key then return family end end
end

-- Ticked elixirs. Before anything is ticked, the old single Elixir choice (or Ferocity) counts.
function B:ElixirTicked(child,settings)
  local values=settings and settings.consumableFamilies or self:Preference("consumableFamilies") or {}
  local any=false
  local parent=child.parent
  for _,other in ipairs(parent.children or {}) do if values[other.key]~=nil then any=true; break end end
  if any then return values[child.key]==true end
  local chosen=self:ConsumableChoiceID(parent,settings)
  if not chosen and not parent.explicitChoice then
    -- Old "Auto" choice: the first supported item carried counts until something is ticked.
    for _,item in ipairs(parent.items or {}) do if self:ConsumableCount(item.id)>0 then chosen=item.id; break end end
  end
  return child.items[1].id==chosen
end

function B:ElixirFamilyFor(itemID)
  for _,child in ipairs(self.ChecklistChildren or {}) do if child.items[1].id==itemID then return child end end
end

-- Name of a ticked elixir from the same line, if any (those replace each other).
function B:ElixirLineTicked(child,settings)
  if not child or not child.line then return nil end
  settings=settings or self:EditorSettings("consumables")
  for _,other in ipairs(child.parent.children or {}) do
    if other~=child and other.line==child.line and self:ElixirTicked(other,settings) then
      local info=self:ConsumableItemInfo(other.items[1].id,other.items[1])
      return (info and info.name) or other.name
    end
  end
end

function B:ToggleElixir(itemID)
  local child=self:ElixirFamilyFor(itemID)
  if not child or A.Combat() then return end
  local settings=self:EditorSettings("consumables")
  local values=settings.consumableFamilies
  local on=not self:ElixirTicked(child,settings)
  if on then
    for _,other in ipairs(child.parent.children or {}) do
      if other.line and other.line==child.line then values[other.key]=false end
    end
    values[child.parent.key]=true
  end
  values[child.key]=on
  self:InvalidateConsumables(); if self.InvalidateSupplies then self:InvalidateSupplies(false) end
  self:RequestRefresh("elixir choice",0)
end

function B:ConsumableFamilySelected(family,settings)
  if not self.db or not family then return false end
  if family.parent then return self:ConsumableFamilySelected(family.parent,settings) and self:ElixirTicked(family,settings) end
  local values=settings and settings.consumableFamilies or self:Preference("consumableFamilies")
  local value=values and values[family.key]
  if type(value)=="boolean" then return value end
  return family.defaultOn==true
end

function B:ConsumableFamilyEnabled(family,settings)
  local enabled; if settings then enabled=settings.consumablesEnabled else enabled=self:Preference("consumablesEnabled") end
  return self.db and enabled==true and self:ConsumableFamilySelected(family,settings)
end

-- Mode belongs to the visible family; checklist children inherit it. Missing means legacy Auto.
function B:ConsumableMode(family,settings)
  local parent=family and (family.parent or family)
  local modes=settings and settings.consumableModes or self:Preference("consumableModes")
  return parent and type(modes)=="table" and modes[parent.key]=="manual" and "manual" or "auto"
end
function B:SetConsumableMode(family,mode)
  if A.Combat() or not family or family.hidden or (mode~="auto" and mode~="manual") then return false end
  self:EditorSettings("consumables").consumableModes[family.key]=mode
  self:InvalidateConsumables()
  -- Immediately revoke a main item before preparing any Manual buttons (and vice versa).
  self:Refresh(false)
  return true
end

function B:ConsumableThreshold(family,settings)
  local values=settings and settings.consumableSeconds or self:Preference("consumableSeconds")
  local value=family and values and values[family.thresholdKey or family.key]
  if type(value)=="number" then return math.max(30,math.min(1800,value)) end
  return family and family.defaultSeconds or 300
end

function B:SetConsumableThreshold(family,value)
  if not family or not self.db then return end
  value=math.max(30,math.min(1800,math.floor((tonumber(value) or family.defaultSeconds or 300)/30+0.5)*30))
  if value==(family.defaultSeconds or 300) then self.db.consumableSeconds[family.key]=nil
  else self.db.consumableSeconds[family.key]=value end
end

function B:ConsumableChoiceID(family,settings)
  if not family then return nil end
  local values=settings and settings.consumableChoices or self:Preference("consumableChoices")
  local chosen=values and values[family.key]
  if type(chosen)=="number" then
    for _,item in ipairs(family.items or {}) do if item.id==chosen then return chosen end end
  end
  if family.explicitChoice then return family.defaultChoice end
  return nil -- nil means Auto: first supported usable item currently in bags.
end

function B:SetConsumableChoice(family,itemID)
  if not family or not self.db then return end
  if self.InvalidateSupplies then self:InvalidateSupplies(false) end
  if itemID==nil then self.db.consumableChoices[family.key]=nil; return end
  itemID=tonumber(itemID)
  for _,item in ipairs(family.items or {}) do
    if item.id==itemID then self.db.consumableChoices[family.key]=itemID; return end
  end
  self.db.consumableChoices[family.key]=nil
end

function B:InvalidateConsumables(itemID)
  self.consumableDirty=true
  self.consumableCoverage=nil
  if self.InvalidateSupplies then self:InvalidateSupplies(false) end
  if A.Number(itemID) and self.itemMeta then self.itemMeta[itemID]=nil end
end

-- Bounded retries handle native failures and requests that never return a result.
function B:RequestItemData(itemID)
  if A.Combat() or not A.Number(itemID) or not (C_Item and type(C_Item.RequestLoadItemDataByID)=="function") then return end
  self.itemRequests=self.itemRequests or {}; self.itemRequestState=self.itemRequestState or {}
  local now=GetTime(); local state=self.itemRequestState[itemID]
  if not state then state={attempts=0,nextAt=0}; self.itemRequestState[itemID]=state end
  if state.attempts>=3 or now<state.nextAt then return end
  state.attempts=state.attempts+1
  state.nextAt=now+({10,30,60})[state.attempts]
  self.itemRequests[itemID]=now
  local ok=pcall(C_Item.RequestLoadItemDataByID,itemID)
  if not ok then self.itemRequests[itemID]=nil end
  if ok and self.stats then self.stats.itemInfoLoads=(self.stats.itemInfoLoads or 0)+1 end
  if self.itemRequestState[itemID]~=state then return end
  if self.StartTimer then self:StartTimer("item-data:"..itemID,state.nextAt-now,function()
    if B.itemRequestState and B.itemRequestState[itemID]==state and not A.Combat() then
      B:RequestItemData(itemID)
    end
  end) end
end
function B:ItemDataResult(itemID,success)
  if A.Public(success) and success==true then
    if self.itemRequests then self.itemRequests[itemID]=nil end
    if self.itemRequestState then self.itemRequestState[itemID]=nil end
    self:CancelTimer("item-data:"..itemID)
  elseif self.itemRequestState and self.itemRequestState[itemID] and self.itemRequestState[itemID].attempts>=3 then
    self:CancelTimer("item-data:"..itemID)
  end
end
function B:SuspendItemDataRetries()
  for id in pairs(self.itemRequestState or {}) do self:CancelTimer("item-data:"..id) end
end
function B:ResumeItemDataRetries()
  if A.Combat() then return end
  for id,state in pairs(self.itemRequestState or {}) do
    if state.attempts<3 then
      local itemID,pending=id,state
      self:StartTimer("item-data:"..itemID,math.max(0.05,pending.nextAt-GetTime()),function()
        if B.itemRequestState and B.itemRequestState[itemID]==pending and not A.Combat() then
          B:RequestItemData(itemID)
    
        end
      end)
    end
  end
end
function B:RetryConsumableReminders()
  if A.Combat() then return end
  self.effectPauses={}; self.confirmedItems={}; self.confirmedChecks={}
  for id in pairs(self.itemRequestState or {}) do
    self:CancelTimer("item-data:"..id)
    if self.itemMeta then self.itemMeta[id]=nil end
  end
  self.itemRequestState={}; self.itemRequests={}
  self:InvalidateConsumables(); self:InvalidateAura("player")
  self:RequestRefresh("retry consumable reminders",0)
end

function B:ConsumableItemInfo(itemID,static)
  self.itemMeta=self.itemMeta or {}
  local cached=self.itemMeta[itemID]
  if cached then return cached end

  local info=safeItemInfo(itemID) or {}
  info.id=itemID
  info.name=info.name or (static and static.name) or ("Item "..tostring(itemID))
  info.texture=info.texture or safeInstantIcon(itemID) or (static and static.icon) or 134400
  local spellName,spellID=safeItemSpell(itemID)
  info.spellName,info.spellID=spellName,spellID
  self.itemMeta[itemID]=info

  -- Item spell data can arrive after the item itself; ask again so the cache entry is refreshed.
  if not info.loaded or not info.spellID then self:RequestItemData(itemID) end
  return info
end

function B:RebuildConsumableCache(force)
  if not force and not self.consumableDirty and self.consumableCache then return self.consumableCache end
  local cache={counts={},at=GetTime(),error=nil}
  local seen={}
  for _,family in ipairs(self.ConsumableFamilies or {}) do
    for _,item in ipairs(family.items or {}) do
      if not seen[item.id] then
        seen[item.id]=true
        local count,err=safeItemCount(item.id)
        if count==nil then cache.error=cache.error or err else cache.counts[item.id]=count end
        if count and count>0 then self:ConsumableItemInfo(item.id,item) end
      end
    end
  end
  self.consumableCache=cache
  self.consumableDirty=false
  if self.stats then self.stats.itemCountRefreshes=(self.stats.itemCountRefreshes or 0)+1 end
  return cache
end

function B:ConsumableCount(itemID)
  local cache=self:RebuildConsumableCache(false)
  local count=cache and cache.counts and cache.counts[itemID]
  return type(count)=="number" and count or 0,cache and cache.error
end

function B:ConsumableInventorySummary(family,maxItems)
  local parts={}; maxItems=maxItems or 3
  local cache=self:RebuildConsumableCache(false)
  for _,item in ipairs(family and family.items or {}) do
    local count=cache and cache.counts[item.id] or 0
    if type(count)=="number" and count>0 then
      local info=self:ConsumableItemInfo(item.id,item)
      parts[#parts+1]=(info and info.name or item.name).." ×"..tostring(count)
      if #parts>=maxItems then break end
    end
  end
  return #parts>0 and table.concat(parts,", ") or "none in bags"
end

local function familyCoverage(B,family)
  B.consumableCoverage=B.consumableCoverage or {}
  local cached=B.consumableCoverage[family.key]
  if cached then return cached.names,cached.ids end
  local names,ids={},{}
  for _,name in ipairs(family.auraNames or {}) do names[norm(name)]=true end
  for _,id in ipairs(family.auraSpellIDs or {}) do ids[id]=true end
  for _,spellID in ipairs(family.localizedAuraSpellIDs or {}) do
    local name=A.Call(C_Spell and C_Spell.GetSpellName,spellID)
    if A.Text(name) then names[norm(name)]=true end
    ids[spellID]=true
  end
  for _,item in ipairs(family.items or {}) do
    for _,id in ipairs(item.auraIDs or {}) do ids[id]=true end
  end
  B.consumableCoverage[family.key]={names=names,ids=ids}
  return names,ids
end

-- Informational ONLY: never an eligibility gate. An effect ID names a food category, not the exact meal
-- or its strength, so the wording never claims more than that.
function B:FoodPreferenceStatus(settings)
  local family=self:ConsumableFamily("food")
  if not family or not self.db then return "unknown",self:Text("Food status unavailable.") end
  if A.Combat() then return "unknown",self:Text("Food buffs will be checked after combat.") end
  if not self:ConsumableFamilyEnabled(family,settings) then return "disabled",self:Text("Food reminders are turned off.") end
  local chosen=self:ConsumableChoiceID(family,settings)
  if not chosen then return "auto",self:Text("First usable food is selected; BuffTap does not choose the best stats.") end
  local preferredIDs,knownIDs,genericIDs,genericNames={},{},{},{}
  for _,item in ipairs(family.items or {}) do
    for _,id in ipairs(item.auraIDs or {}) do
      if A.Number(id) then knownIDs[id]=true; if item.id==chosen then preferredIDs[id]=true end end
    end
  end
  for _,id in ipairs(family.auraSpellIDs or {}) do if A.Number(id) and not knownIDs[id] then genericIDs[id]=true end end
  for _,id in ipairs(family.localizedAuraSpellIDs or {}) do
    if A.Number(id) and not knownIDs[id] then genericIDs[id]=true end
  end
  for _,name in ipairs(family.auraNames or {}) do if A.Text(name) then genericNames[norm(name)]=true end end
  if not next(preferredIDs) then return "ambiguous",self:Text("The selected food has no verified effect identity yet.") end
  local auras=self:GetAuras("player",false)
  if not auras then return "unknown",self:Text("Buff information is unavailable right now; BuffTap won't guess.") end
  local preferred,other,generic=false,false,false
  for _,aura in ipairs(auras) do
    local id=A.Number(aura.spellId) and aura.spellId or nil
    if id and preferredIDs[id] then preferred=true
    elseif id and knownIDs[id] then other=true
    elseif (id and genericIDs[id]) or (A.Text(aura.name) and genericNames[norm(aura.name)]) then generic=true end
  end
  if preferred and not other and not generic then return "compatible",self:Text("A compatible food effect is active. BuffTap cannot verify the exact meal.") end
  if other and not preferred and not generic then return "different",self:Text("A different food effect is active. BuffTap won't replace it automatically.") end
  if preferred or other or generic then return "ambiguous",self:Text("A food buff is active, but its exact effect cannot be confirmed.") end
  return "missing",self:Text("No recognized food buff is active.")
end

-- One short reason for a single (non-checklist) consumable family. Read when a tooltip opens, never on a timer.
function B:ConsumableExplanation(family,settings)
  if not self.db or not family or family.multi then return "" end
  if A.Combat() then return self:Text("Buffs will be checked after combat.") end
  if not self:ConsumableFamilyEnabled(family,settings) then return self:Text("This reminder is turned off.") end
  local paused=self:CategoryRestingPause("consumables")
  if paused then
    return paused:find("outside",1,true) and self:Text("Consumable reminders are paused outside dungeons and raids.") or self:Text("Consumable reminders are paused while resting.")
  end
  if family.key=="food" then local _,text=self:FoodPreferenceStatus(settings); return text end
  if self.effectPauses then
    for _,item in ipairs(family.items or {}) do
      if self.effectPauses[item.id] then return self:Text("The expected effect was not detected. Use Retry reminders on this page.") end
    end
  end
  local chosen=self:ConsumableChoiceID(family,settings)
  if chosen and self:ConsumableCount(chosen)<1 then return self:Text("Your selected item is not in your bags.") end
  local auras=self:GetAuras("player",false)
  if not auras then return self:Text("The game isn't sharing enough buff information right now.") end
  local missing,state=self:ConsumableFamilyState(family,auras)
  if missing==false then return self:Text("A matching buff is already active.") end
  if state=="expiring" then return self:Text("The buff is nearly due for a refresh.") end
  if not self:PreferredConsumableItem(family,settings) then return self:Text("No supported item is available in your bags.") end
  return self:Text("Ready when the item is usable and its cooldown is clear.")
end

-- On-demand explanation for the multi-item Elixirs / Utility rows. Read-only: it
-- never changes reminders, selection, item actions or aura eligibility.
function B:ConsumableChecklistExplanation(parent,settings)
  if not self.db or not parent or not parent.multi then return "" end
  if A.Combat() then return self:Text("Buffs will be checked after combat.") end
  if not self:ConsumableFamilyEnabled(parent,settings) then return self:Text("This reminder is turned off.") end
  local paused=self:CategoryRestingPause("consumables")
  if paused then
    return paused:find("outside",1,true) and self:Text("Consumable reminders are paused outside dungeons and raids.") or self:Text("Consumable reminders are paused while resting.")
  end
  local selected={}
  for _,child in ipairs(parent.children or {}) do
    if self:ConsumableFamilySelected(child,settings) then selected[#selected+1]=child end
  end
  if #selected==0 then return self:Text("No effects selected.") end
  local auras=self:GetAuras("player",false)
  if not auras then return self:Text("The game isn't sharing enough buff information right now.") end
  local counts={active=0,expiring=0,missing=0,empty=0,paused=0,unknown=0}
  local details={}
  for _,child in ipairs(selected) do
    local stock,unknownStock,effectPaused=false,false,false
    for _,item in ipairs(child.items or {}) do
      local n,err=self:ConsumableCount(item.id)
      if n>0 then stock=true end
      if err then unknownStock=true end
      if self.effectPauses and self.effectPauses[item.id] then effectPaused=true end
    end
    local missing,state=self:ConsumableFamilyState(child,auras)
    local category,label
    if missing==nil then category,label="unknown",self:Text("buff state unknown")
    elseif missing==false then category,label="active",self:Text("active")
    elseif effectPaused then category,label="paused",self:Text("effect not detected; use Retry reminders")
    elseif not stock and unknownStock then category,label="unknown",self:Text("bag count unavailable")
    elseif not stock then category,label="empty",self:Text("out of stock")
    elseif state=="expiring" then category,label="expiring",self:Text("expiring; refresh due")
    else category,label="missing",self:Text("missing; item available") end
    counts[category]=counts[category]+1
    if #details<7 then
      local info=child.items and child.items[1] and self:ConsumableItemInfo(child.items[1].id,child.items[1])
      details[#details+1]=tostring((info and info.name) or child.name or child.key)..": "..label
    end
  end
  local summary=self:Text("Selected: %d · Active: %d · Expiring: %d · Missing: %d",#selected,counts.active,counts.expiring,counts.missing)
  if counts.empty>0 then summary=summary.." · "..self:Text("Out of stock: %d",counts.empty) end
  if counts.paused>0 then summary=summary.." · "..self:Text("Paused: %d",counts.paused) end
  if counts.unknown>0 then summary=summary.." · "..self:Text("Unknown: %d",counts.unknown) end
  if #selected>#details then details[#details+1]=self:Text("+%d more selected",#selected-#details) end
  return summary.."\n"..table.concat(details,"\n")
end

function B:ConsumableFamilyState(family,auras)
  if not family or type(auras)~="table" then return nil,"aura state unavailable" end
  local names,ids=familyCoverage(self,family)
  local now=GetTime(); local matched=false; local anySafe=false
  local shownThreshold=0; local bestRemaining=nil; local latestCrossing=nil
  local configured=self:ConsumableThreshold(family)
  for _,aura in ipairs(auras) do
    if ids[aura.spellId] or names[norm(aura.name)] then
      if family.protectPresent then return false,"present",0,nil,nil end
      matched=true
      if not A.Number(aura.expirationTime) or aura.expirationTime==0 then return false,"present",0,nil,nil end
      if not A.Number(aura.duration) or aura.duration<=0 then return false,"present",0,nil,nil end
      local threshold=math.min(aura.duration*0.5,configured)
      local remaining=math.max(0,aura.expirationTime-now)
      shownThreshold=math.max(shownThreshold,threshold)
      bestRemaining=math.max(bestRemaining or 0,remaining)
      if remaining>threshold then
        anySafe=true
        latestCrossing=math.max(latestCrossing or 0,remaining-threshold)
      end
    end
  end
  if anySafe then return false,"present",shownThreshold,bestRemaining,latestCrossing end
  if matched then return true,"expiring",shownThreshold,bestRemaining,0 end
  return true,"missing",0,nil,nil
end

function B:PreferredConsumableItem(family,settings)
  if not family then return nil,"unknown family" end
  local cache=self:RebuildConsumableCache(false)
  if cache and cache.error and not next(cache.counts or {}) then return nil,cache.error end
  local chosen=self:ConsumableChoiceID(family,settings)
  if chosen then
    for _,item in ipairs(family.items or {}) do
      if item.id==chosen then
        if (cache.counts[chosen] or 0)>0 then return item end
        return nil,"preferred item not in bags"
      end
    end
    return nil,"preferred item no longer supported"
  end
  for _,item in ipairs(family.items or {}) do if (cache.counts[item.id] or 0)>0 then return item end end
  return nil,"no supported item in bags"
end

function B:ValidateConsumable(action,forceAura,forceInventory)
  if not self:SituationActionCurrent(action) then return false,"setup changed before item validation" end
  if not action or action.source~="consumable" then return false,"not a consumable action" end
  local resting=self:CategoryRestingPause("consumables"); if resting then return false,"consumables "..resting end
  local family=self:ConsumableFamily(action.familyKey)
  if not family or not self:ConsumableFamilyEnabled(family) then return false,"consumable family disabled" end
  if (self:ConsumableMode(family)=="manual")~=(action.manualConsumable==true) then return false,"consumable mode changed" end

  local static
  for _,item in ipairs(family.items or {}) do if item.id==action.itemID then static=item; break end end
  if not static then return false,"item not whitelisted" end
  self.itemQuarantine=self.itemQuarantine or {}
  if self.itemQuarantine[action.itemID] then return false,self.itemQuarantine[action.itemID] end
  -- Pause the whole family, including Auto alternatives, until an explicit retry.
  -- Otherwise an unobserved flask could silently advance to another carried flask.
  for _,candidate in ipairs(family.items or {}) do
    if self.effectPauses and self.effectPauses[candidate.id] then return false,"effect not observed; use Retry reminders in Consumables" end
  end
  local info=self:ConsumableItemInfo(action.itemID,static)
  if not info or not info.loaded or not info.spellID or not info.texture or info.texture==134400 then
    return false,"item metadata loading or unavailable"
  end
  if info.spellID~=static.useSpell then
    self.itemQuarantine[action.itemID]="item mapping changed; disabled until reload"
    return false,self.itemQuarantine[action.itemID]
  end
  local level=A.Call(UnitLevel,"player")
  if not A.Number(info.minLevel) or not A.Number(level) or level<info.minLevel then return false,"item level unavailable or not met" end
  local configured=self:ConsumableChoiceID(family)
  if configured and configured~=action.itemID then return false,"preferred item changed" end
  local count,why
  if forceInventory then count,why=safeItemCount(action.itemID)
  else count,why=self:ConsumableCount(action.itemID) end
  if count==nil then return false,why end
  action.stock=count
  if count<1 then return false,"item no longer in bags" end

  local pending=self.consumablePending and self.consumablePending[family.key]
  if pending and pending>GetTime() then
    self:ConsiderWake(pending-GetTime()+0.03)
    return false,"recent item use settling"
  end

  local auras,err=self:GetAuras("player",forceAura==true)
  if not auras then return false,err or "player auras unavailable" end
  if family.key=="food" then
    for _,aura in ipairs(auras) do
      if self.EatingSpellIDs and self.EatingSpellIDs[aura.spellId] then
        self:ConsiderWake(A.Number(aura.expirationTime) and aura.expirationTime-GetTime()+0.1 or nil)
        return false,"already eating"
      end
    end
  end
  local missing,state,threshold,remaining,wake=self:ConsumableFamilyState(family,auras)
  local used=self.confirmedItems and self.confirmedItems[family.key]
  if used then
    if missing==true and family.key~="food" then
      self.confirmedChecks=self.confirmedChecks or {}
      local at=self.confirmedChecks[family.key]
      if not at then at=GetTime()+5; self.confirmedChecks[family.key]=at end
      if GetTime()<at then self:ConsiderWake(at-GetTime()+0.03); return false,"waiting for a second effect check" end
      self.effectPauses=self.effectPauses or {}; self.effectPauses[used]=true
      self.confirmedItems[family.key]=nil; self.confirmedChecks[family.key]=nil
      self.Print(self:Text("Consumable reminder paused: effect not observed. Use Retry reminders in Consumables to try again."))
      return false,"effect not observed; reminder paused"
    else
      self.confirmedItems[family.key]=nil
      if self.confirmedChecks then self.confirmedChecks[family.key]=nil end
    end
  end
  self:ConsiderWake(wake)
  if missing~=true then return false,"effect already "..tostring(state) end

  local usable,usableWhy=safeUsable(action.itemID)
  if usable~=true then return false,usableWhy or "item not usable" end
  local startTime,duration,enabled,cdWhy=safeCooldown(action.itemID)
  if not startTime then return false,cdWhy end
  if enabled==false then return false,"item cooldown disabled" end
  if duration>0 and startTime+duration>GetTime() then
    self.cooldownBlocked=true
    self:ConsiderWake(startTime+duration-GetTime()+0.03)
    return false,"item cooldown"
  end

  action.needState=state; action.threshold=threshold; action.remaining=remaining
  action.valid=true
  return true
end

function B:ResolveConsumableItem(family,item,manual)
  local info=self:ConsumableItemInfo(item.id,item)
  if not info or not info.loaded then return nil,"item metadata unavailable" end
  local level=A.Call(UnitLevel,"player")
  if A.Number(info.minLevel) and A.Number(level) and level<info.minLevel then return nil,"player below item level requirement" end

  local action={id=item.id,itemID=item.id,itemToken="item:"..tostring(item.id),name=info.name,icon=info.texture,
    key="consumable:"..family.key,familyKey=family.key,target="player",targetName=A.Call(UnitName,"player") or "player",
    targetGUID=A.Call(UnitGUID,"player"),source="consumable",secureType="item",valid=false,pendingSeconds=family.pendingSeconds or 2,
    manualConsumable=manual==true,situationRevision=self.situationRevision or 0}
  local valid,reason=self:ValidateConsumable(action,false)
  if not valid then return nil,reason end
  return action
end

function B:ResolveConsumable(family,manual)
  local chosen=self:ConsumableChoiceID(family)
  if family.explicitChoice and not chosen then return nil,"choose an item in options" end
  local reason="no supported item in bags"
  for _,item in ipairs(family.items or {}) do
    if not chosen or chosen==item.id then
      local count=self:ConsumableCount(item.id)
      if count>0 then
        local ok,action,why=pcall(self.ResolveConsumableItem,self,family,item,manual)
        if ok and action and not (self.HelperSuppressed and self:HelperSuppressed(action)) then return action end
        reason=ok and why or "item provider unavailable"
        self:AddDiag("item "..item.id..": "..tostring(reason))
      end
    end
  end
  return nil,reason
end

function B:SelectConsumable()
  if not self.db or not self:Preference("consumablesEnabled") then return nil,"consumables disabled" end
  local resting=self:CategoryRestingPause("consumables"); if resting then return nil,"consumables "..resting end
  if self.stats then self.stats.consumableSelects=(self.stats.consumableSelects or 0)+1 end
  self:RebuildConsumableCache(false)
  for _,family in ipairs(self.ConsumableFamilies or {}) do
    if not family.multi and self:ConsumableFamilyEnabled(family) and self:ConsumableMode(family)=="auto" then
      local action,why=self:ResolveConsumable(family)
      if action then
        action.reason="consumable: "..tostring(action.needState or "missing")
        action.selectedAt=GetTime()
        return action,"ready"
      end
      self:AddDiag("consumable "..family.key..": "..tostring(why))
    end
  end
  return nil,"no consumable action"
end

-- Pre/PostClick run for both input phases; neither proves an item was used.
-- A short, bounded attempt record is confirmed by bag loss or our use spell.
function B:BeforeConsumableClick(action)
  local count=safeItemCount(action.itemID)
  if not count then return end
  self.itemAttempts=self.itemAttempts or {}
  local old=self.itemAttempts[action.itemID]
  if old and old.id==action.itemID and GetTime()-old.at<2 then return end
  local info=self.itemMeta and self.itemMeta[action.itemID]
  self.itemAttempt={id=action.itemID,count=count,at=GetTime(),family=action.familyKey,
    spellID=info and info.spellID,delay=action.pendingSeconds or 2}
  self.itemAttempts[action.itemID]=self.itemAttempt
end

function B:ObserveConsumableUse(spellID)
  local attempts=self.itemAttempts or {}
  if self.itemAttempt then attempts[self.itemAttempt.id]=self.itemAttempt end
  local matches=0
  for _,attempt in pairs(attempts) do
    if GetTime()-attempt.at<=3 and A.Number(spellID) and spellID==attempt.spellID then matches=matches+1 end
  end
  for id,attempt in pairs(attempts) do
    local count=safeItemCount(attempt.id)
    if GetTime()-attempt.at>3 then
      attempts[id]=nil; if self.itemAttempt==attempt then self.itemAttempt=nil end
    elseif (count and count<attempt.count) or (matches==1 and spellID==attempt.spellID) then
    self.consumablePending=self.consumablePending or {}
    self.consumablePending[attempt.family]=GetTime()+math.max(5,attempt.delay)
    self.confirmedItems=self.confirmedItems or {}; self.confirmedItems[attempt.family]=attempt.id
    if self.confirmedChecks then self.confirmedChecks[attempt.family]=nil end
    attempts[id]=nil; if self.itemAttempt==attempt then self.itemAttempt=nil end
    self:InvalidateConsumables(); self:InvalidateAura("player")
    self:RequestRefresh("confirmed item use",0.05)
    end
  end
  self.itemAttempts=next(attempts) and attempts or nil
end

function B:AfterConsumableClick(action)
  if action and action.source=="consumable" then self:ObserveConsumableUse() end
end

function B:CampState(auras)
  local spellID=self.CampBenefitsSpellID or 1229741
  local localized=A.Call(C_Spell and C_Spell.GetSpellName,spellID)
  auras=auras or self:GetAuras("player",false)
  if type(auras)~="table" then return {active=false,unknown=true,spellID=spellID} end
  local now=GetTime()
  for _,aura in ipairs(auras) do
    if aura.spellId==spellID or (A.Text(localized) and norm(aura.name)==norm(localized)) or norm(aura.name)==norm("Camp Benefits") then
      local remaining=A.Number(aura.expirationTime) and aura.expirationTime>0 and math.max(0,aura.expirationTime-now) or nil
      local benefits={}
      local getter=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
      if type(getter)=="function" then
        for _,addition in ipairs(self.CampAdditions or {}) do
          local ok,record=pcall(getter,addition.auraID)
          if ok and A.Public(record) and record~=nil then
            benefits[#benefits+1]={key=addition.key,name=addition.name,auraID=addition.auraID}
          end
        end
      end
      return {active=true,remaining=remaining,duration=aura.duration,spellID=spellID,benefits=benefits}
    end
  end
  return {active=false,spellID=spellID}
end


