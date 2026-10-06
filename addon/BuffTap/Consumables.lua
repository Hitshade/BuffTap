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
  if not A.Number(startTime) or not A.Number(duration) or not A.Public(enabled) or type(enabled)~="boolean" then
    return nil,nil,nil,"item cooldown unreadable"
  end
  return startTime,duration,enabled,nil
end

function B:ConsumableFamily(key)
  for _,family in ipairs(self.ConsumableFamilies or {}) do if family.key==key then return family end end
end

function B:ConsumableFamilySelected(family)
  if not self.db or not family then return false end
  local value=self.db.consumableFamilies and self.db.consumableFamilies[family.key]
  if type(value)=="boolean" then return value end
  return family.defaultOn==true
end

function B:ConsumableFamilyEnabled(family)
  return self.db and self.db.consumablesEnabled==true and self:ConsumableFamilySelected(family)
end

function B:ConsumableThreshold(family)
  local value=family and self.db and self.db.consumableSeconds and self.db.consumableSeconds[family.key]
  if type(value)=="number" then return math.max(30,math.min(1800,value)) end
  return family and family.defaultSeconds or 300
end

function B:SetConsumableThreshold(family,value)
  if not family or not self.db then return end
  value=math.max(30,math.min(1800,math.floor((tonumber(value) or family.defaultSeconds or 300)/30+0.5)*30))
  if value==(family.defaultSeconds or 300) then self.db.consumableSeconds[family.key]=nil
  else self.db.consumableSeconds[family.key]=value end
end

function B:ConsumableChoiceID(family)
  if not family then return nil end
  local chosen=self.db and self.db.consumableChoices and self.db.consumableChoices[family.key]
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

function B:CycleConsumableChoice(family,delta)
  if not family then return end
  local choices={nil}
  -- Lua arrays cannot retain an initial nil, so index 1 is the Auto sentinel 0.
  choices[1]=0
  if family.explicitChoice then choices={} end
  local selected=self:ConsumableChoiceID(family)
  for _,item in ipairs(family.items or {}) do if self:ConsumableCount(item.id)>0 or selected==item.id then choices[#choices+1]=item.id end end
  if #choices==0 then return end
  local current=self:ConsumableChoiceID(family) or 0
  local index=1
  for i,id in ipairs(choices) do if id==current then index=i; break end end
  index=((index-1+(delta or 1)) % #choices)+1
  self:SetConsumableChoice(family,choices[index]~=0 and choices[index] or nil)
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

  if not info.loaded then self:RequestItemData(itemID) end
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

function B:PreferredConsumableItem(family)
  if not family then return nil,"unknown family" end
  local cache=self:RebuildConsumableCache(false)
  if cache and cache.error and not next(cache.counts or {}) then return nil,cache.error end
  local chosen=self:ConsumableChoiceID(family)
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
  if not action or action.source~="consumable" then return false,"not a consumable action" end
  local family=self:ConsumableFamily(action.familyKey)
  if not family or not self:ConsumableFamilyEnabled(family) then return false,"consumable family disabled" end

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
  local configured=self:ConsumableChoiceID(family)
  if configured and configured~=action.itemID then return false,"preferred item changed" end
  local count,why
  if forceInventory then count,why=safeItemCount(action.itemID)
  else count,why=self:ConsumableCount(action.itemID) end
  if count==nil then return false,why end
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

function B:ResolveConsumableItem(family,item)
  local info=self:ConsumableItemInfo(item.id,item)
  if not info or not info.loaded then return nil,"item metadata unavailable" end
  local level=A.Call(UnitLevel,"player")
  if A.Number(info.minLevel) and A.Number(level) and level<info.minLevel then return nil,"player below item level requirement" end

  local action={id=item.id,itemID=item.id,itemToken="item:"..tostring(item.id),name=info.name,icon=info.texture,
    key="consumable:"..family.key,familyKey=family.key,target="player",targetName=A.Call(UnitName,"player") or "player",
    targetGUID=A.Call(UnitGUID,"player"),source="consumable",secureType="item",valid=false,pendingSeconds=family.pendingSeconds or 2}
  local valid,reason=self:ValidateConsumable(action,false)
  if not valid then return nil,reason end
  return action
end

function B:ResolveConsumable(family)
  local chosen=self:ConsumableChoiceID(family)
  if family.explicitChoice and not chosen then return nil,"choose an item in options" end
  local reason="no supported item in bags"
  for _,item in ipairs(family.items or {}) do
    if not chosen or chosen==item.id then
      local count=self:ConsumableCount(item.id)
      if count>0 then
        local ok,action,why=pcall(self.ResolveConsumableItem,self,family,item)
        if ok and action and not (self.HelperSuppressed and self:HelperSuppressed(action)) then return action end
        reason=ok and why or "item provider unavailable"
        self:AddDiag("item "..item.id..": "..tostring(reason))
      end
    end
  end
  return nil,reason
end

function B:SelectConsumable()
  if not self.db or not self.db.consumablesEnabled then return nil,"consumables disabled" end
  if self.stats then self.stats.consumableSelects=(self.stats.consumableSelects or 0)+1 end
  self:RebuildConsumableCache(false)
  for _,family in ipairs(self.ConsumableFamilies or {}) do
    if self:ConsumableFamilyEnabled(family) then
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
  local old=self.itemAttempt
  if old and old.id==action.itemID and GetTime()-old.at<2 then return end
  local info=self.itemMeta and self.itemMeta[action.itemID]
  self.itemAttempt={id=action.itemID,count=count,at=GetTime(),family=action.familyKey,
    spellID=info and info.spellID,delay=action.pendingSeconds or 2}
end

function B:ObserveConsumableUse(spellID)
  local attempt=self.itemAttempt
  if not attempt then return end
  if GetTime()-attempt.at>3 then self.itemAttempt=nil; return end
  local count=safeItemCount(attempt.id)
  if (A.Number(spellID) and spellID==attempt.spellID) or (count and count<attempt.count) then
    self.consumablePending=self.consumablePending or {}
    self.consumablePending[attempt.family]=GetTime()+math.max(5,attempt.delay)
    self.confirmedItems=self.confirmedItems or {}; self.confirmedItems[attempt.family]=attempt.id
    if self.confirmedChecks then self.confirmedChecks[attempt.family]=nil end
    self.itemAttempt=nil
    self:InvalidateConsumables(); self:InvalidateAura("player")
    self:RequestRefresh("confirmed item use",0.05)
  end
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
