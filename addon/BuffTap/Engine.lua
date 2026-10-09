-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local _, B = ...
_G.BuffTap = B
B.version = "1.13.2"
B.API = {}
local A = B.API

-- Never branch on, concatenate, compare, or index with a secret value.
function A.Public(v) return not (issecretvalue and issecretvalue(v)) end
function A.Call(fn, ...)
  if type(fn) ~= "function" then return nil, "API unavailable" end
  local ok, value = pcall(fn, ...)
  if not ok then return nil, "API call failed: " .. (A.Public(value) and type(value)=="string" and value or "unreadable error") end
  if not A.Public(value) then return nil, "restricted value" end
  return value
end
function A.Number(v) return A.Public(v) and type(v) == "number" and v==v and v>-math.huge and v<math.huge end
function A.Text(v) return A.Public(v) and type(v) == "string" and v ~= "" end
function A.Combat() return not InCombatLockdown or InCombatLockdown() end
local foldCache,foldCount={},0
local function fold(v)
  if not A.Text(v) then return "" end
  local cached=foldCache[v]
  if cached then return cached end
  cached=v:lower():gsub("%s*%b()$", "")
  if foldCount>=2000 then foldCache,foldCount={},0 end
  foldCache[v]=cached; foldCount=foldCount+1
  return cached
end

-- Binding strings are literal API inputs. Preserve printable punctuation
-- from key capture while rejecting whitespace and control characters.
function B:NormalizeBindings(values)
  local keys,seen={},{}
  for i=1,8 do
    local key=values[i]
    if type(key)=="string" and #key>0 and #key<=64 and key:match("^[%w%p]+$") then
      key=key:upper()
      if not seen[key] then keys[#keys+1]=key; seen[key]=true end
    end
  end
  return keys
end

function B:InitDB()
  if type(BuffTapDB) ~= "table" then BuffTapDB = {} end
  self.db = BuffTapDB
  local hadSeconds = type(self.db.seconds) == "number"
  local hadRebuffVersion = type(self.db.rebuffVersion) == "number"
  -- Migrate the short-lived 0.5.x overlay key names before defaults are applied.
  if type(self.db.showTimer)~="boolean" and type(self.db.showRemaining)=="boolean" then self.db.showTimer=self.db.showRemaining end
  if type(self.db.showGroupBadge)~="boolean" and type(self.db.showGroupIndicator)=="boolean" then self.db.showGroupBadge=self.db.showGroupIndicator end
  self.db.showRemaining=nil; self.db.showGroupIndicator=nil
  local defaults = {enabled=true, size=64, opacity=1, x=0, y=-180,
    seconds=45, rebuffVersion=1, sound=false, reminderSound="default", supplySound="default", soundChannel="Master", soundInterval=5, glow=true, pulse=false, group=false, smartGroup=true,
    groupNeed=3, blessingNeed=2, friendlyTarget=false, targetSeconds=300, keys={"MOUSEWHEELDOWN"}, buffs={}, priorities={}, buffSeconds={},
    pauseResting=false, targetClassBlessings=true, targetBlessingFallback=true, targetBlessingClasses={}, targetBlessingPriorities={}, groupBlessingPriorities={}, blessingAssignments=false, blessingClasses={}, buffGroups={}, buffClasses={}, buffGroupNeed={}, targetBuffs={}, targetBuffSeconds={}, showBuffName=false, showTargetName=true, showTimer=false, showGroupBadge=true,
    consumablesEnabled=false, consumableFamilies={}, consumableChoices={}, consumableSeconds={},
    suppliesEnabled=false, suppliesChat=false, suppliesSound=false, suppliesReadyCheck=false, supplySettings={},
    weaponReminder=true, weaponMainHand=true, weaponOffHand=true,
    weaponApply=false, weaponReplace=false, weaponChoices={}, weaponCoatings={}, weaponSeconds=60,
    helperDismiss=false, helperBounce=false, helperTracking=false, helperCoverage=false,
    helperDiscovery=false, helperThanks=false, helperThankEmote="THANK", helperQuick=false, helperTracker=0, helperPet=false, helperHealthstone=false, helperSoulstone=false, soulstoneParty="healer", soulstoneRaid="remind", soulstoneAssigned="", helperDemon=0,
    raidGroups={true,true,true,true,true,true,true,true}}
  for k,v in pairs(defaults) do
    if type(self.db[k]) ~= type(v) then self.db[k] = v end
  end
  if not A.Number(self.db.helperTracker) or (self.db.helperTracker~=2383 and self.db.helperTracker~=2580 and self.db.helperTracker~=43308) then self.db.helperTracker=0 end
  if self.db.soulstoneParty~="healer" and self.db.soulstoneParty~="self" and self.db.soulstoneParty~="assigned" then self.db.soulstoneParty="healer" end
  if self.db.soulstoneRaid~="remind" and self.db.soulstoneRaid~="assigned" then self.db.soulstoneRaid="remind" end
  if #self.db.soulstoneAssigned>64 then self.db.soulstoneAssigned="" end
  if not A.Number(self.db.helperDemon) or (self.db.helperDemon~=688 and self.db.helperDemon~=697 and self.db.helperDemon~=712 and self.db.helperDemon~=713 and self.db.helperDemon~=691) then self.db.helperDemon=0 end
  if self.NormalizeConvenience then self:NormalizeConvenience() end
  if self.NormalizeAlerts then self:NormalizeAlerts() end
  if self.NormalizeCoatings then self:NormalizeCoatings() end
  if self.SyncBroker then self:SyncBroker() end
  if self.NormalizeBlessingAssignments then self:NormalizeBlessingAssignments() end
  if self.SyncReadiness then self:SyncReadiness() end
  -- Validate catalog keys without deleting preferences while class data is loading.
  local class=self.WeaponReminderClass and self:WeaponReminderClass()
  local rawClass=A.Call(function() local _,token=UnitClass("player"); return token end)
  for hand,key in pairs(self.db.weaponChoices) do
    local valid=false
    if (hand=="main" or hand=="off") and A.Text(key) then
      for _,choice in ipairs(self.WeaponChoices or {}) do
        if choice.key==key and (not A.Text(rawClass) or choice.class==class) then valid=true; break end
      end
    end
    if not valid then self.db.weaponChoices[hand]=nil end
  end
  if not A.Number(self.db.weaponSeconds) then self.db.weaponSeconds=60 end
  self.db.weaponSeconds=math.max(0,math.min(300,self.db.weaponSeconds))
  -- 0.3.0 carried an internal 8-second value but exposed no timing control.
  -- Move untouched installs to the new, more useful 45-second default.
  if not hadRebuffVersion then
    if not hadSeconds or self.db.seconds == 8 then self.db.seconds = 45 end
    self.db.rebuffVersion = 1
  end
  if type(self.db.raidGroups) ~= "table" then self.db.raidGroups = {true,true,true,true,true,true,true,true} end
  for i=1,8 do if type(self.db.raidGroups[i]) ~= "boolean" then self.db.raidGroups[i] = true end end
  for k,limits in pairs({size={24,160}, opacity={0,1}, x={-4000,4000}, y={-4000,4000}, seconds={15,180}, targetSeconds={30,1800}, groupNeed={2,5}, blessingNeed={2,5}}) do
    local v = self.db[k]
    if v ~= v then v = defaults[k] end
    self.db[k] = math.max(limits[1], math.min(limits[2], v))
  end
  if type(self.db.buffSeconds) ~= "table" then self.db.buffSeconds = {} end
  if type(self.db.buffGroups) ~= "table" then self.db.buffGroups = {} end
  if type(self.db.buffGroupNeed) ~= "table" then self.db.buffGroupNeed = {} end
  if type(self.db.targetBuffs) ~= "table" then self.db.targetBuffs = {} end
  if type(self.db.targetBuffSeconds) ~= "table" then self.db.targetBuffSeconds = {} end
  if type(self.db.consumableFamilies) ~= "table" then self.db.consumableFamilies = {} end
  if type(self.db.consumableChoices) ~= "table" then self.db.consumableChoices = {} end
  if type(self.db.consumableSeconds) ~= "table" then self.db.consumableSeconds = {} end
  -- Removed in 1.0.0: inventory-only potion tracking. Preserve other choices.
  self.db.consumableFamilies["potion-stock"]=nil
  self.db.consumableChoices["potion-stock"]=nil
  self.db.consumableSeconds["potion-stock"]=nil
  for key,value in pairs(self.db.consumableFamilies) do if type(value)~="boolean" then self.db.consumableFamilies[key]=nil end end
  for key,value in pairs(self.db.consumableChoices) do if type(value)~="number" then self.db.consumableChoices[key]=nil end end
  for key,value in pairs(self.db.consumableSeconds) do
    if type(value)~="number" or value~=value then self.db.consumableSeconds[key]=nil
    else self.db.consumableSeconds[key]=math.max(30,math.min(1800,math.floor(value/30+0.5)*30)) end
  end
  self.consumableDirty=true
  for key,value in pairs(self.db.buffSeconds) do
    if type(value) ~= "number" or value ~= value then self.db.buffSeconds[key] = nil
    else self.db.buffSeconds[key] = math.max(15, math.min(180, value)) end
  end
  for key,value in pairs(self.db.buffGroupNeed) do
    if type(value) ~= "number" or value ~= value then self.db.buffGroupNeed[key] = nil
    else self.db.buffGroupNeed[key] = math.max(2, math.min(5, math.floor(value + 0.5))) end
  end
  for key,value in pairs(self.db.targetBuffs) do
    if type(value) ~= "boolean" then self.db.targetBuffs[key] = nil end
  end
  for key,value in pairs(self.db.targetBuffSeconds) do
    if type(value) ~= "number" or value ~= value then self.db.targetBuffSeconds[key] = nil
    else self.db.targetBuffSeconds[key] = math.max(30, math.min(1800, math.floor(value/30 + 0.5)*30)) end
  end
  self.db.keys=self:NormalizeBindings(self.db.keys)
  for key,value in pairs(self.db.priorities) do
    if not A.Number(value) then self.db.priorities[key]=nil
    else self.db.priorities[key]=math.max(1,math.min(999,math.floor(value))) end
  end
  for key,map in pairs(self.db.buffGroups) do
    if type(map)~="table" then self.db.buffGroups[key]=nil
    else for i=1,8 do if type(map[i])~="boolean" then map[i]=self.db.raidGroups[i] end end end
  end
  for key,map in pairs(self.db.buffClasses) do
    if type(map)~="table" then self.db.buffClasses[key]=nil
    else for class,value in pairs(map) do if type(value)~="boolean" then map[class]=nil end end end
  end
  self.auraCache=self.auraCache or {}
  if self.InitSupplies then self:InitSupplies() end
end

function B:ResetStats()
  self.stats={refreshes=0,selects=0,auraScans=0,auraHits=0,rosterBuilds=0,rosterHits=0,
    resolveBuilds=0,resolveHits=0,rangeChecks=0,targetRetries=0,itemCountRefreshes=0,itemInfoLoads=0,consumableSelects=0,weaponReads=0,readinessBagScans=0}
end

function B:Supported(b)
  if b.kind == "weapon" or b.kind == "consumable" or b.kind == "tracking" or b.kind == "pet" then
    return false, b.kind .. " actions are not supported yet"
  end
  return true
end
function B:ClassList()
  local ok,_,class = pcall(UnitClass, "player")
  if not ok or not A.Text(class) then return {}, "class unavailable" end
  local list = {}
  local logicalOrder = {}
  local nextOrder = 0
  for i,b in ipairs(self.Buffs) do
    if b.class == class then
      -- Group/single versions are one logical buff in the UI and share one priority.
      -- Number visible buff families from 1 instead of exposing their catalog index.
      local root = b.singleKey or b.key
      if not logicalOrder[root] then
        nextOrder = nextOrder + 1
        logicalOrder[root] = nextOrder
      end
      b.order = logicalOrder[root]
      b.catalogOrder = i
      list[#list+1] = b
    end
  end
  table.sort(list, function(a,b)
    local ax=a.singleKey or a.key; local bx=b.singleKey or b.key
    local x,y = self.db.priorities[ax], self.db.priorities[bx]
    x = type(x)=="number" and x or a.order
    y = type(y)=="number" and y or b.order
    if x == y then return (a.catalogOrder or 0) < (b.catalogOrder or 0) end
    return x < y
  end)
  return list
end
function B:FindBuff(key)
  for _,v in ipairs(self.Buffs) do if v.key==key then return v end end
end
function B:RebuffSeconds(b)
  local key=b and (b.singleKey or b.key)
  local value=key and self.db.buffSeconds and self.db.buffSeconds[key]
  if type(value)=="number" then return math.max(15,math.min(180,value)) end
  return self.db.seconds
end

-- Read native state on demand; events drive updates, with no location polling.
function B:ReminderPauseReason()
  if self.pauseUntil and GetTime()<self.pauseUntil then return "temporary pause" end
  if self.editModeActive then return "editing reminder" end
  if A.Call(IsMounted)==true then return "mounted" end
  if self.db and self.db.pauseResting and A.Call(IsResting)==true then return "resting" end
end

function B:TargetBlessingChoice(entry)
  if not self.db.targetClassBlessings then return nil end
  local selected=self.db.targetBlessingClasses[entry.class]
  if selected=="skip" then return "skip" end
  if selected=="priority" then return self:OrderedBlessingChoice(entry,self.db.targetBlessingPriorities[entry.class],true) end
  local function eligible(def,automatic)
    if not def or def.kind~="blessing" or def.singleKey then return false end
    if automatic and (not self:Enabled(def) or not self:TargetBuffEnabled(def)) then return false end
    if automatic and def.target then
      local matched=false
      for _,class in ipairs(def.target) do if class==entry.class then matched=true; break end end
      if not matched then return false end
    end
    return self:Supported(def)==true and self:Resolve(def,entry.unit)~=nil
  end
  -- Explicit preference comes first; remaining choices follow enabled priorities.
  local choices,seen={},{}
  local function add(def,automatic)
    if eligible(def,automatic) and not seen[def.key] then
      choices[#choices+1]=def; seen[def.key]=true
    end
  end
  if selected then add(self:FindBuff(selected),false) end
  if not entry.class then return "skip" end
  for _,def in ipairs(self.blessingClassList or self:ClassList()) do add(def,true) end
  if not self.db.targetBlessingFallback then return choices[1] and choices[1].key or "skip" end
  return self:PickBlessingPriority(entry,choices,true)
end

-- Static ID lookup avoids a catalog walk for every aura, recipient and choice.
function B:BlessingAuraFamily(aura)
  if not self.blessingAuraIDs then
    -- Ownership-only IDs verified in the Forever spell-name export. These are
    -- never offered for casting by the maintenance catalog.
    local ids={[1022]="tactical",[5599]="tactical",[10278]="tactical",[442948]="tactical",
      [1044]="tactical",[6940]="tactical",[20729]="tactical"}
    for _,def in ipairs(self.Buffs) do
      if def.kind=="blessing" then for _,id in ipairs(def.ranks or {}) do ids[id]=def.singleKey or def.key end end
    end
    self.blessingAuraIDs=ids
  end
  local family=A.Number(aura.spellId) and self.blessingAuraIDs[aura.spellId]
  if family then return family end
  if not A.Number(aura.spellId) and A.Text(aura.name) then
    for _,id in ipairs({1022,5599,10278,442948,1044,6940,20729}) do
      if fold(aura.name)==fold(A.Call(C_Spell and C_Spell.GetSpellName,id)) then return "tactical" end
    end
    for _,def in ipairs(self.Buffs) do
      if def.kind=="blessing" then
        if fold(aura.name)==fold(def.name) then return def.singleKey or def.key end
        for _,id in ipairs(def.ranks or {}) do
          if fold(aura.name)==fold(A.Call(C_Spell and C_Spell.GetSpellName,id)) then return def.singleKey or def.key end
        end
      end
    end
  end
end

function B:PickBlessingPriority(entry,choices,target)
  local auras=self:GetAuras(entry.unit,false)
  if not auras then return "skip" end
  local own,unknown=false,false
  for _,aura in ipairs(auras) do
    local family=self:BlessingAuraFamily(aura)
    if family then
      local source=aura.sourceUnit
      local isOwn=source=="player" and true or (source and A.Call(UnitIsUnit,source,"player"))
      if isOwn==true then
        if own and own~=family then return "skip" end
        own=family
      elseif isOwn~=false or A.Call(UnitExists,source)~=true then unknown=true end
    end
  end
  -- Never guess that a nil, restricted or unresolved caster is another Paladin.
  if unknown then return "skip" end
  if own then
    for _,def in ipairs(choices) do if def.key==own then return own end end
    return "skip"
  end
  for _,def in ipairs(choices) do
    local action=self:Resolve(def,entry.unit)
    local missing,_,_,_,wake=self:Missing(def,action,auras,target and self:TargetRebuffSeconds(def) or nil)
    self:ConsiderWake(wake)
    if missing then return def.key end
  end
  return "skip"
end

function B:OrderedBlessingChoice(entry,order,target,neverSalvation)
  if type(order)~="table" then return "skip" end
  local choices={}
  for _,key in ipairs(order) do
    local def=self:FindBuff(key)
    if def and def.kind=="blessing" and not def.singleKey
      and not (key=="bos" and neverSalvation)
      and self:Supported(def)==true and self:Resolve(def,entry.unit) then
      choices[#choices+1]=def
    end
  end
  if target and not self.db.targetBlessingFallback then choices=choices[1] and {choices[1]} or {} end
  return self:PickBlessingPriority(entry,choices,target)
end

function B:DefaultBlessingOrder(class,target,first)
  local order,seen={},{}
  if self:FindBuff(first) then order[1]=first; seen[first]=true end
  for _,def in ipairs(self.blessingClassList or self:ClassList()) do
    if def.kind=="blessing" and not def.singleKey and self:Enabled(def) and not seen[def.key]
      and (not target or self:TargetBuffEnabled(def)) then
      local allowed=not def.target
      for _,c in ipairs(def.target or {}) do if c==class then allowed=true end end
      if allowed then order[#order+1]=def.key; seen[def.key]=true end
    end
  end
  return order
end

function B:TargetBuffEnabled(b)
  if b and b.kind=="blessing" and self.db.targetClassBlessings then return true end
  local key=self:RootKey(b)
  if not key then return false end
  local value=self.db.targetBuffs and self.db.targetBuffs[key]
  if type(value)=="boolean" then return value end
  return true
end

function B:TargetRebuffSeconds(b)
  if b and b.kind=="blessing" and self.db.targetClassBlessings then return self.db.targetSeconds or 300 end
  local key=self:RootKey(b)
  local value=key and self.db.targetBuffSeconds and self.db.targetBuffSeconds[key]
  if type(value)=="number" then return math.max(30,math.min(1800,value)) end
  return self.db.targetSeconds or 300
end

function B:TargetAssignableBuffs()
  local out={}
  for _,b in ipairs(self:ClassList()) do
    local supported=self:Supported(b)
    if supported and not b.singleKey and (b.kind=="single" or b.kind=="blessing") then out[#out+1]=b end
  end
  return out
end

function B:GroupNeed(b)
  local key=self:RootKey(b)
  local value=key and self.db.buffGroupNeed and self.db.buffGroupNeed[key]
  if type(value)=="number" then return math.max(2,math.min(5,math.floor(value+0.5))) end
  if b and b.kind=="blessing" then return self.db.blessingNeed or b.minNeed or 2 end
  return self.db.groupNeed or (b and b.minNeed) or 3
end

function B:SetGroupNeed(b,value)
  local key=self:RootKey(b)
  if not key then return end
  local pair=b and b.groupKey and self:FindBuff(b.groupKey) or b
  local fallback=(pair and pair.kind=="blessing") and self.db.blessingNeed or self.db.groupNeed
  value=math.max(2,math.min(5,math.floor((tonumber(value) or fallback or 3)+0.5)))
  if value==(fallback or 3) then self.db.buffGroupNeed[key]=nil else self.db.buffGroupNeed[key]=value end
end

function B:NormalizeGroupNeeds()
  for key,value in pairs(self.db.buffGroupNeed or {}) do
    local b=self:FindBuff(key)
    local pair=b and b.groupKey and self:FindBuff(b.groupKey) or b
    local fallback=(pair and pair.kind=="blessing") and self.db.blessingNeed or self.db.groupNeed
    if not b or value==(fallback or 3) then self.db.buffGroupNeed[key]=nil end
  end
end

function B:RootKey(b)
  return b and (b.singleKey or b.key) or nil
end

function B:GroupSelected(b, group)
  group=tonumber(group)
  if not group or group<1 or group>8 then return false end
  local key=self:RootKey(b)
  local map=key and self.db.buffGroups and self.db.buffGroups[key]
  if type(map)=="table" and type(map[group])=="boolean" then return map[group] end
  return self.db.raidGroups and self.db.raidGroups[group]==true
end

function B:EnsureBuffGroups(b)
  local key=self:RootKey(b)
  if not key then return nil end
  if type(self.db.buffGroups[key])~="table" then
    local map={}
    for i=1,8 do map[i]=self.db.raidGroups[i]==true end
    self.db.buffGroups[key]=map
  end
  return self.db.buffGroups[key]
end

function B:BuffGroupsDifferFromDefault(b)
  local key=self:RootKey(b)
  local map=key and self.db.buffGroups and self.db.buffGroups[key]
  if type(map)~="table" then return false end
  for i=1,8 do
    if (map[i]==true) ~= (self.db.raidGroups[i]==true) then return true end
  end
  return false
end

function B:NormalizeBuffGroups(b)
  local key=self:RootKey(b)
  if not key or not self.db.buffGroups then return false end
  if type(self.db.buffGroups[key])=="table" and not self:BuffGroupsDifferFromDefault(b) then
    self.db.buffGroups[key]=nil
    return true
  end
  return false
end

function B:GroupAssignableBuffs()
  local out={}
  for _,b in ipairs(self:ClassList()) do
    local supported=self:Supported(b)
    if supported and not b.singleKey and (b.kind=="single" or b.kind=="blessing") then
      out[#out+1]=b
    end
  end
  return out
end

function B:NormalizeAllBuffGroups()
  for _,b in ipairs(self:GroupAssignableBuffs()) do self:NormalizeBuffGroups(b) end
end

function B:ReconcileRaidGroupColumn(group)
  group=tonumber(group)
  if not group or group<1 or group>8 then return end
  local buffs=self:GroupAssignableBuffs()
  if #buffs==0 then return end

  local first=self:GroupSelected(buffs[1],group)
  for i=2,#buffs do
    if self:GroupSelected(buffs[i],group) ~= first then
      return -- Mixed assignments: keep the current default unchanged.
    end
  end

  -- If every per-buff row now agrees, promote that common value to the default.
  self.db.raidGroups[group]=first==true
  self:NormalizeAllBuffGroups()
end

function B:GroupColumnState(group)
  local buffs=self:GroupAssignableBuffs()
  if #buffs==0 then return self.db.raidGroups[group] and "on" or "off" end
  local first=self:GroupSelected(buffs[1],group)
  for i=2,#buffs do
    if self:GroupSelected(buffs[i],group) ~= first then return "mixed" end
  end
  return first and "on" or "off"
end

function B:SetRaidGroupColumn(group,value)
  group=tonumber(group)
  if not group or group<1 or group>8 then return end
  value=value==true
  self.db.raidGroups[group]=value
  for _,b in ipairs(self:GroupAssignableBuffs()) do
    local key=self:RootKey(b)
    local map=key and self.db.buffGroups[key]
    if type(map)=="table" then map[group]=value end
    self:NormalizeBuffGroups(b)
  end
end

function B:Enabled(b)
  -- Group versions inherit the single-buff toggle so users manage one logical buff.
  if b.singleKey then
    local single=self:FindBuff(b.singleKey)
    if single then return self:Enabled(single) end
  end
  local v = self.db.buffs[b.key]
  if v ~= nil then return v == true end
  -- One blessing family at a time by default.
  if b.kind == "blessing" then return b.key == "bok" end
  if b.key=="ice-armor" or b.key=="frost-armor" or b.key=="demon-skin" then return true end
  return b.defaultOn == true
end

function A.Known(id)
  return A.Call(C_SpellBook and C_SpellBook.IsSpellKnown, id,
    Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) == true
end
function B:ScanBook()
  self.consumableCoverage=nil
  self.book = {}
  self.coverCache = {}
  self.resolveCache = {}
  self.rankChoiceCache = {}
  self.dataPending = false
  local S = C_SpellBook
  local n,err = A.Call(S and S.GetNumSpellBookSkillLines)
  if not A.Number(n) or n < 1 then self.bookIssue = err or "spellbook not ready"; return end
  local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  if bank == nil then self.bookIssue = "Player spell bank unavailable"; return end
  self.bookIssue = nil
  for line=1,n do
    local info = A.Call(S.GetSpellBookSkillLineInfo, line)
    if type(info)=="table" and A.Number(info.itemIndexOffset) and A.Number(info.numSpellBookItems) then
      for slot=info.itemIndexOffset+1, info.itemIndexOffset+info.numSpellBookItems do
        local item = A.Call(S.GetSpellBookItemInfo, slot, bank)
        if type(item)=="table" and A.Number(item.spellID) and A.Known(item.spellID)
          and A.Public(item.isPassive) and not item.isPassive
          and A.Public(item.isOffSpec) and not item.isOffSpec then
          local name = A.Call(C_Spell and C_Spell.GetSpellName, item.spellID)
          if A.Text(name) then
            self.book[#self.book+1] = {id=item.spellID, name=name, slot=slot,
              rank=A.Text(item.subName) and item.subName or "",
              level=A.Call(S.GetSpellBookItemLevelLearned,slot,bank)}
          end
        end
      end
    else self.bookIssue = "incomplete spellbook scan" end
  end
end

-- Spell resolution is intentionally split in two: expensive spellbook/name/rank
-- discovery is cached until the book changes; per-target resolution only picks
-- the highest verified rank that target can receive.
function B:Candidates(b)
  self.resolveCache = self.resolveCache or {}
  local cached = self.resolveCache[b.key]
  if cached then return cached.list,cached.reason end

  local candidates,seen,names,ids = {},{},{[fold(b.name)]=true},{}
  local pending=false
  for order,id in ipairs(b.ranks or {}) do
    ids[id] = order
    local name = A.Call(C_Spell and C_Spell.GetSpellName,id)
    if A.Text(name) then names[fold(name)] = true end
  end
  local function add(id, entry)
    if seen[id] or not A.Known(id) then return end
    seen[id] = true
    local name = A.Call(C_Spell and C_Spell.GetSpellName,id)
    local icon = A.Call(C_Spell and C_Spell.GetSpellTexture,id)
    local iconValid=(A.Number(icon) and icon>0 and icon~=134400)
      or (A.Text(icon) and not icon:lower():find("inv_misc_questionmark",1,true))
    if not A.Text(name) or not iconValid then
      pending=true; self.dataPending=true
      self.requested=self.requested or {}
      if not self.requested[id] or GetTime()-self.requested[id]>5 then
        self.requested[id]=GetTime()
        A.Call(C_Spell and C_Spell.RequestLoadSpellData,id)
      end
      return
    end
    local passive = A.Call(C_Spell and C_Spell.IsSpellPassive,id)
    if passive ~= false then return end
    local level = entry and entry.level or A.Call(C_Spell and C_Spell.GetSpellLevelLearned,id)
    if not A.Number(level) or level < 1 then level = self.RankLevel[id] end
    local rank = entry and entry.rank or A.Call(C_Spell and C_Spell.GetSpellSubtext,id)
    candidates[#candidates+1] = {id=id, name=name, icon=icon, level=level,
      rank=A.Text(rank) and rank or "", slot=entry and entry.slot, order=ids[id]}
  end
  for _,entry in ipairs(self.book or {}) do
    if ids[entry.id] or names[fold(entry.name)] then add(entry.id,entry) end
  end
  for _,id in ipairs(b.ranks or {}) do add(id) end
  table.sort(candidates,function(a,c)
    local al,cl = a.level or 0,c.level or 0
    if al ~= cl then return al > cl end
    if a.order and c.order then return a.order < c.order end
    local ar,cr = tonumber(a.rank:match("(%d+)")),tonumber(c.rank:match("(%d+)"))
    if ar and cr and ar ~= cr then return ar > cr end
    return a.id < c.id
  end)
  local reason = #candidates==0 and "no known active spell with name and icon (or spell data not ready)" or nil
  -- Never cache an unresolved result while spell data is still loading; the
  -- scheduled retry must be able to see newly available name/icon data.
  if not pending then self.resolveCache[b.key]={list=candidates,reason=reason} end
  return candidates,reason
end

function B:Resolve(b, unit)
  local candidates,reason=self:Candidates(b)
  if not candidates or #candidates==0 then return nil,reason end
  self.rankChoiceCache=self.rankChoiceCache or {}
  local targetLevel=A.Call(UnitLevel,unit)
  local levelKey=unit=="player" and "player" or (A.Number(targetLevel) and tostring(targetLevel) or "unknown")
  local cacheKey=b.key..":"..levelKey
  local chosen=self.rankChoiceCache[cacheKey]
  if chosen==false then return nil,"no verified rank appropriate for target level" end
  if chosen then
    if self.stats then self.stats.resolveHits=(self.stats.resolveHits or 0)+1 end
  else
    if self.stats then self.stats.resolveBuilds=(self.stats.resolveBuilds or 0)+1 end
    for _,c in ipairs(candidates) do
      if unit=="player" or (A.Number(targetLevel) and A.Number(c.level) and targetLevel>=c.level) then
        if #candidates>1 and not A.Number(c.level) and not c.order then
          return nil,"ambiguous rank ordering for remapped spell"
        end
        chosen=c; break
      end
    end
    if not chosen then self.rankChoiceCache[cacheKey]=false; return nil,"no verified rank appropriate for target level" end
    self.rankChoiceCache[cacheKey]=chosen
  end
  local action={id=chosen.id,name=chosen.name,icon=chosen.icon,level=chosen.level,rank=chosen.rank,slot=chosen.slot,order=chosen.order,
    key=b.key,target=unit,known=true,secureType="spell",valid=false}
  action.targetName=A.Call(UnitName,unit) or unit
  action.targetGUID=A.Call(UnitGUID,unit)
  return action
end

local function compactAura(data)
  if not A.Public(data) then return nil,"restricted aura record" end
  if type(data)~="table" then return nil,"unexpected aura shape" end
  local name,spellId,duration,expirationTime=data.name,data.spellId,data.duration,data.expirationTime
  if not A.Public(name) or not A.Public(spellId) or not A.Public(duration) or not A.Public(expirationTime) then
    return nil,"restricted aura value"
  end
  if not A.Text(name) and not A.Number(spellId) then return nil,"aura identity unreadable" end
  return {sourceUnit=A.Text(data.sourceUnit) and data.sourceUnit or nil, name=A.Text(name) and name or nil,spellId=A.Number(spellId) and spellId or nil,
    duration=A.Number(duration) and duration or nil,expirationTime=A.Number(expirationTime) and expirationTime or nil}
end

-- A successful empty table is an EMPTY scan, never an error/unknown scan.
-- Prefer the batch API on Forever 1.60.1; fall back to indexed reads only if needed.
function A.Auras(unit)
  if A.Combat() then return nil,"combat: aura reading suspended" end
  if C_Secrets and C_Secrets.ShouldAurasBeSecret then
    local restricted,err=A.Call(C_Secrets.ShouldAurasBeSecret)
    if err or restricted~=false then return nil,"aura secrecy active or unreadable" end
  end
  if A.Call(UnitExists,unit) ~= true then return nil,"unit unavailable" end

  local U=C_UnitAuras
  if U and type(U.GetUnitAuras)=="function" then
    local data,err=A.Call(U.GetUnitAuras,unit,"HELPFUL",255)
    if err then return nil,err end
    if type(data)=="table" then
      if #data>=255 then return nil,"aura batch may be truncated" end
      local result={}
      for i=1,#data do
        local aura,why=compactAura(data[i]); if not aura then return nil,why end
        result[#result+1]=aura
      end
      return result
    elseif data~=nil then return nil,"unexpected aura batch shape" end
  end

  local result={}
  for i=1,255 do
    local data,err=A.Call(U and U.GetAuraDataByIndex,unit,i,"HELPFUL")
    if err then return nil,err end
    if data==nil then return result end
    local aura,why=compactAura(data); if not aura then return nil,why end
    result[#result+1]=aura
  end
  return nil,"aura scan did not terminate"
end

function B:InvalidateAura(unit)
  self.auraCache=self.auraCache or {}
  if unit then self.auraCache[unit]=nil else self.auraCache={} end
end

function B:GetAuras(unit,force)
  self.auraCache=self.auraCache or {}
  local guid=A.Call(UnitGUID,unit)
  local now=GetTime()
  local cached=not force and self.auraCache[unit] or nil
  local ttl=unit=="target" and 2 or 10
  if cached and A.Text(guid) and cached.guid==guid and now-(cached.at or 0)<=ttl then
    if self.stats then self.stats.auraHits=(self.stats.auraHits or 0)+1 end
    return cached.auras,cached.error
  end
  if self.stats then self.stats.auraScans=(self.stats.auraScans or 0)+1 end
  local auras,err=A.Auras(unit)
  -- Cache successful scans only. Errors/restrictions are retried after the normal scheduler delay.
  if auras and A.Text(guid) then self.auraCache[unit]={guid=guid,at=now,auras=auras} end
  return auras,err
end

function B:Missing(b,action,auras,rebuffSeconds)
  self.coverCache=self.coverCache or {}
  local cacheKey=b.key .. ":" .. action.id
  local cached=self.coverCache[cacheKey]
  local ids,names
  if cached then ids,names=cached.ids,cached.names else
    ids,names = {[action.id]=true},{[fold(action.name)]=true}
    for _,id in ipairs(b.ranks or {}) do ids[id]=true end
    for _,name in ipairs(b.covers or {}) do names[fold(name)]=true end
    -- Localized coverage names are obtained from the catalog's related IDs.
    for _,other in ipairs(self.Buffs) do
      if names[fold(other.name)] then
        for _,id in ipairs(other.ranks or {}) do
          ids[id]=true
          local n = A.Call(C_Spell and C_Spell.GetSpellName,id)
          if A.Text(n) then names[fold(n)]=true end
        end
      end
    end
    self.coverCache[cacheKey]={ids=ids,names=names}
  end

  local now=GetTime()
  local matched=false
  local anySafe=false
  local latestCrossing=nil
  local bestRemaining=nil
  local shownThreshold=0
  for _,a in ipairs(auras) do
    if ids[a.spellId] or names[fold(a.name)] then
      matched=true
      if not A.Number(a.expirationTime) or a.expirationTime==0 then
        return false,"present (no expiration)",0,nil,nil
      end
      if not A.Number(a.duration) or a.duration<=0 then
        return false,"present (duration unknown)",0,nil,nil
      end
      local configured=type(rebuffSeconds)=="number" and rebuffSeconds or self:RebuffSeconds(b)
      local threshold=math.min(a.duration*0.5,configured)
      local remaining=math.max(0,a.expirationTime-now)
      shownThreshold=math.max(shownThreshold,threshold)
      bestRemaining=math.max(bestRemaining or 0,remaining)
      if remaining>threshold then
        anySafe=true
        local crossing=remaining-threshold
        -- Coverage is still safe while ANY equivalent matching aura remains above threshold.
        latestCrossing=math.max(latestCrossing or 0,crossing)
      end
    end
  end
  if anySafe then return false,"present",shownThreshold,bestRemaining,latestCrossing end
  if matched then return true,"expiring",shownThreshold,bestRemaining,0 end
  return true,"missing",0,nil,nil
end

function B:AddDiag(text)
  if not self.captureDiagnostics then return end
  self.diagnostics=self.diagnostics or {}
  if #self.diagnostics<80 then self.diagnostics[#self.diagnostics+1]=text end
end

function B:ConsiderWake(delay)
  if not A.Number(delay) or delay<=0 then return end
  delay=math.max(0.05,delay)
  if not self.nextWakeDelay or delay<self.nextWakeDelay then self.nextWakeDelay=delay end
end

-- Exact spell range is preferred. The spellbook form is a safe fallback for
-- clients/builds where spell-ID range returns nil. Nil means unknown, not false.
function B:SpellRange(action)
  if not action or action.target=="player" then return true,"self" end
  if self.stats then self.stats.rangeChecks=(self.stats.rangeChecks or 0)+1 end
  local value=A.Call(C_Spell and C_Spell.IsSpellInRange,action.id,action.target)
  if type(value)=="boolean" then return value,"spell" end
  local S=C_SpellBook
  local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
  if action.slot and bank~=nil and S and type(S.IsSpellBookItemInRange)=="function" then
    value=A.Call(S.IsSpellBookItemInRange,action.slot,bank,action.target)
    if type(value)=="boolean" then return value,"spellbook" end
  end
  return nil,"unknown"
end

function B:TargetEligible(action,checkRange)
  if not action then return false,"no action" end
  if A.Call(UnitExists,action.target) ~= true then return false,"target unavailable" end
  if A.Call(UnitIsDeadOrGhost,action.target) ~= false then return false,"target dead or unreadable" end
  if action.target~="player" then
    if not A.Text(action.targetGUID) or A.Call(UnitGUID,action.target)~=action.targetGUID then return false,"target identity changed or unreadable" end
    if A.Call(UnitIsConnected,action.target) ~= true then return false,"target disconnected" end
    if type(UnitIsVisible)=="function" and A.Call(UnitIsVisible,action.target) ~= true then return false,"target not visible" end
    if A.Call(UnitCanAssist,"player",action.target) ~= true then return false,"target not friendly" end
    if checkRange~=false then
      local inRange,source=self:SpellRange(action)
      action.rangeSource=source
      if inRange==false then return false,"target out of range" end
      if inRange~=true then return false,"target range unknown" end
    end
  end
  return true
end

function B:AddRangeBlocked(action)
  self.rangeBlocked=true
  if not action then return end
  self.rangeBlockedActions=self.rangeBlockedActions or {}
  self.rangeBlockedKeys=self.rangeBlockedKeys or {}
  if #self.rangeBlockedActions>=48 then return end
  local key=tostring(action.id)..":"..tostring(action.target)
  if not self.rangeBlockedKeys[key] then
    self.rangeBlockedKeys[key]=true
    self.rangeBlockedActions[#self.rangeBlockedActions+1]=action
  end
end

function B:Validate(action)
  local paused=self:ReminderPauseReason(); if paused then return false,paused end
  if action and action.source=="readiness" then
    local needed,why=self:ReadinessStillNeeded(action)
    if not needed then return false,why end
    if action.manual then action.valid=true; return true end
    -- Readiness items (Soulstone) are revalidated by the candidate itself:
    -- stock, item spell, cooldown, usability and target. Check the unit again.
    if action.secureType=="item" then
      local eligible,why=self:TargetEligible(action,false)
      if not eligible then return false,why end
      action.valid=true; return true
    end
  end
  if action and action.source=="consumable" then
    if type(self.ValidateConsumable)~="function" then return false,"consumable provider unavailable" end
    return self:ValidateConsumable(action,false)
  end
  if not action then return false,"no action" end
  if not self:BlessingActionAllowed(action) then return false,"blessing assignment changed" end
  if not A.Known(action.id) then return false,"spell no longer known" end
  local eligible,why=self:TargetEligible(action,true)
  if not eligible then
    if why=="target out of range" or why=="target range unknown" then self:AddRangeBlocked(action) end
    return false,why
  end
  for _,reagent in ipairs(self.GroupReagents and self.GroupReagents[action.id] or {}) do
    local count=A.Call(C_Item and C_Item.GetItemCount,reagent[1],false,false,false,false)
    if not A.Number(count) or count<reagent[2] then return false,"group reagent unavailable" end
  end
  local usable,err = A.Call(C_Spell and C_Spell.IsSpellUsable,action.id)
  action.usable = usable==true
  if not action.usable then
    self.powerBlocked=true
    return false,err or "spell not usable (power, form, reagent or requirements)"
  end
  local cd,cdwhy = A.Call(C_Spell and C_Spell.GetSpellCooldown,action.id)
  if type(cd)~="table" then return false,cdwhy or "cooldown data unavailable" end
  if not A.Number(cd.startTime) or not A.Number(cd.duration) or not A.Public(cd.isEnabled) then return false,"restricted cooldown" end
  if cd.isEnabled == false then return false,"cooldown disabled" end
  if cd.duration>0 and cd.startTime+cd.duration>GetTime() then
    self.cooldownBlocked=true
    self:ConsiderWake(cd.startTime+cd.duration-GetTime()+0.03)
    return false,"cooldown / global cooldown"
  end
  action.valid=true
  return true
end

function B:InvalidateRoster()
  self.rosterCache=nil
end

function B:Roster()
  local now=GetTime()
  if self.db.group and self.rosterCache and now-(self.rosterCache.at or 0)<=5 then
    if self.stats then self.stats.rosterHits=(self.stats.rosterHits or 0)+1 end
    return self.rosterCache.list
  end
  if self.stats then self.stats.rosterBuilds=(self.stats.rosterBuilds or 0)+1 end
  local playerClass=A.Call(function() local _,c=UnitClass("player"); return c end)
  local roster={{unit="player",group=1,class=A.Text(playerClass) and playerClass or nil,selected=true,rosterOrder=0}}
  if not self.db.group then return roster end
  local raid=A.Call(IsInRaid)==true
  if raid then
    local n=A.Call(GetNumGroupMembers) or 0
    if A.Number(n) then
      for i=1,math.min(n,40) do
        local unit="raid"..i
        if A.Call(UnitExists,unit)==true then
          local subgroup=0
          local info={pcall(GetRaidRosterInfo,i)}
          if info[1] and A.Number(info[4]) and info[4]>=1 and info[4]<=8 then subgroup=info[4] end
          if A.Call(UnitIsUnit,unit,"player")==true then
            roster[1].group=subgroup
          else
            local class=A.Call(function() local _,c=UnitClass(unit); return c end)
            roster[#roster+1]={unit=unit,group=subgroup,class=A.Text(class) and class or nil,selected=true,rosterOrder=i}
          end
        end
      end
    end
  else
    local n=A.Call(GetNumSubgroupMembers) or 0
    if A.Number(n) then
      for i=1,math.min(n,4) do
        local unit="party"..i
        if A.Call(UnitExists,unit)==true then
          local class=A.Call(function() local _,c=UnitClass(unit); return c end)
          roster[#roster+1]={unit=unit,group=1,class=A.Text(class) and class or nil,selected=true,rosterOrder=i}
        end
      end
    end
  end
  self.rosterCache={at=now,list=roster}
  return roster
end

function B:FriendlyTargetEntry()
  if not (self.db and self.db.friendlyTarget) then return nil,"disabled" end
  if A.Call(UnitExists,"target") ~= true then return nil,"no target" end
  if A.Call(UnitIsUnit,"target","player") == true then return nil,"self target" end
  if A.Call(UnitCanAssist,"player","target") ~= true then return nil,"target not friendly" end
  if A.Call(UnitIsDeadOrGhost,"target") ~= false then return nil,"target dead or unreadable" end

  -- Prefer UnitIsPlayer when the client exposes it. Fall back to the stable
  -- Player- GUID prefix so this mode never starts buffing friendly NPCs/pets.
  local isPlayer
  if type(UnitIsPlayer)=="function" then isPlayer=A.Call(UnitIsPlayer,"target") end
  if isPlayer ~= true then
    local guid=A.Call(UnitGUID,"target")
    if not A.Text(guid) or not guid:match("^Player%-") then return nil,"target is not a player" end
  end

  local class=A.Call(function() local _,c=UnitClass("target"); return c end)
  if not A.Text(class) then return nil,"target class unavailable" end
  return {unit="target",group=0,class=class,selected=true,rosterOrder=-1,quickTarget=true}
end


-- Explicit assignments resolve BEFORE aura coverage; family priority never changes
-- a player's chosen blessing. Player exceptions belong to this session/group only.
B.BlessingFamilies={"bok","bom","bow","bos","bol"}
function B:NormalizeBlessingAssignments()
  local valid={skip=true,priority=true}; for _,key in ipairs(self.BlessingFamilies) do valid[key]=true end
  local classes={WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,SHAMAN=true,MAGE=true,WARLOCK=true,DRUID=true}
  local families={}; for _,key in ipairs(self.BlessingFamilies) do families[key]=true end
  for _,map in ipairs({self.db.targetBlessingPriorities,self.db.groupBlessingPriorities}) do
    for class,order in pairs(map) do
      if not classes[class] or type(order)~="table" then map[class]=nil
      else
        local clean,seen={},{}
        for i=1,#self.BlessingFamilies do
          local key=order[i]
          if type(key)=="string" and families[key] and not seen[key] then clean[#clean+1]=key; seen[key]=true end
        end
        map[class]=clean
      end
    end
  end
  for _,map in ipairs({self.db.blessingClasses,self.db.targetBlessingClasses}) do
    for class,key in pairs(map) do
      if not classes[class] or type(key)~="string" or not valid[key] then map[class]=nil end
    end
  end
end
function B:BlessingGroupNeed(def)
  if def and def.kind=="blessing" and self:BlessingAssignmentsActive() then return self.db.blessingNeed end
  return self:GroupNeed(def)
end
function B:BlessingLearned(key)
  local def=self:FindBuff(key)
  if def then for _,id in ipairs(def.ranks or {}) do if A.Known(id) then return true end end end
  return false
end
function B:BlessingAssignmentsActive()
  if not (self.db and self.db.blessingAssignments and self.db.group) then return false end
  local class=A.Call(function() local _,token=UnitClass("player"); return token end)
  if class~="PALADIN" then return false end
  local count=A.Call(GetNumSubgroupMembers)
  return A.Call(IsInRaid)==true or (A.Number(count) and count>0) or false
end
function B:BlessingGroupAllowed(entry)
  return entry and A.Number(entry.group) and self.db.raidGroups[entry.group]==true
end
function B:BlessingChoice(entry)
  if not self:BlessingAssignmentsActive() then return nil end
  if not self:BlessingGroupAllowed(entry) then return "skip" end
  local guid=A.Call(UnitGUID,entry.unit)
  local override=A.Text(guid) and self.blessingPlayers and self.blessingPlayers[guid]
  local key=override and override.choice or self.db.blessingClasses[entry.class]
  if key=="priority" then
    return self:OrderedBlessingChoice(entry,self.db.groupBlessingPriorities[entry.class],false,override and override.neverSalvation)
  end
  if not key then
    -- Legacy fallback is deterministic: first enabled, class-allowed family.
    for _,def in ipairs(self.blessingClassList or self:ClassList()) do
      if def.kind=="blessing" and not def.singleKey and self:Enabled(def) and self:Resolve(def,entry.unit) and
        (entry.unit=="player" or (self:GroupSelected(def,entry.group) and self:GroupClassAllowed(def,entry.class))) then
        key=def.key; break
      end
    end
    key=key or "skip"
  end
  if key=="bos" and override and override.neverSalvation then return "skip" end
  return key
end
function B:SetBlessingPlayer(entry,key,neverSalvation)
  if A.Combat() then return end
  local guid=entry and A.Call(UnitGUID,entry.unit)
  if not A.Text(guid) then return end
  if key=="priority" then return end
  self.blessingPlayers=self.blessingPlayers or {}
  if key==nil and not neverSalvation then self.blessingPlayers[guid]=nil
  else self.blessingPlayers[guid]={choice=key,neverSalvation=neverSalvation==true} end
  self:InvalidateAura(); self:RequestRefresh("blessing player choice",0)
end
function B:BlessingGreaterSafe(key,class,roster)
  for _,entry in ipairs(roster) do
    -- Unknown class cannot establish the full affected set safely.
    if not entry.class then return false end
    if entry.class==class and self:BlessingChoice(entry)~=key then return false end
  end
  return true
end
function B:BlessingActionAllowed(action)
  local def=action and self:FindBuff(action.key)
  if not def or def.kind~="blessing" then return true end
  if action.quickTarget and not action.blessingAssigned then
    if not self.db.friendlyTarget then return false end
    local entry=self:FriendlyTargetEntry()
    if not entry then return false end
    local selected=self.db.targetClassBlessings and self.db.targetBlessingClasses[entry.class]
    local explicit=selected and selected~="skip"
    if not explicit and (not self:TargetBuffEnabled(def) or not self:Enabled(def)) then return false end
    -- If a group assignment became active after preparation, force a fresh scan.
    if self:BlessingAssignmentsActive() then
      for _,member in ipairs(self:Roster()) do
        local guid=A.Call(UnitGUID,entry.unit)
        if A.Call(UnitIsUnit,member.unit,entry.unit)==true or (A.Text(guid) and A.Call(UnitGUID,member.unit)==guid) then return false end
      end
    end
    local choice=self:TargetBlessingChoice(entry)
    return choice==nil or choice==(def.singleKey or def.key)
  end
  if not self:BlessingAssignmentsActive() then return not action.blessingAssigned end
  local roster=self:Roster(); local target
  for _,entry in ipairs(roster) do
    if A.Call(UnitIsUnit,entry.unit,action.target)==true or A.Call(UnitGUID,entry.unit)==action.targetGUID then target=entry; break end
  end
  if not target then return not action.blessingAssigned end
  local key=def.singleKey or def.key
  if self:BlessingChoice(target)~=key then return false end
  return not action.groupCast or self:BlessingGreaterSafe(key,target.class,roster)
end

B.RecipientClasses={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
function B:GroupClassAllowed(b,class)
  local root=self:FindBuff(self:RootKey(b)) or b
  local map=self.db.buffClasses[self:RootKey(b)]
  if type(map)=="table" and type(map[class])=="boolean" then return map[class] end
  if not root.target then return true end
  for _,c in ipairs(root.target) do if c==class then return true end end
  return false
end

function B:RecipientAllowed(b,entry)
  -- Explicit targets and personal maintenance are independent of group assignments.
  if b.kind=="blessing" and self:BlessingAssignmentsActive() and (not entry.quickTarget or entry.blessingAssigned) then
    return self:BlessingChoice(entry)==(b.singleKey or b.key)
  end
  if entry.quickTarget and b.kind=="blessing" then
    local choice=entry.targetBlessingChoice
    if choice==nil then choice=self:TargetBlessingChoice(entry) end
    return choice==nil or choice==(b.singleKey or b.key)
  end
  return entry.quickTarget or entry.unit=="player" or self:GroupClassAllowed(b,entry.class)
end

local function needSort(a,b)
  local am=a.reason=="missing" and 0 or 1
  local bm=b.reason=="missing" and 0 or 1
  if am~=bm then return am<bm end
  if am==1 then
    local ar=a.remaining or math.huge
    local br=b.remaining or math.huge
    if ar~=br then return ar<br end
  end
  return (a.entry.rosterOrder or 999)<(b.entry.rosterOrder or 999)
end

function B:ScanMissing(b,entries,scans,scanErrors,rebuffSeconds)
  local missing={}
  for _,entry in ipairs(entries) do
    if self:RecipientAllowed(b,entry) then
      local action,reason=self:Resolve(b,entry.unit)
      if action then
        -- Do cheap/static eligibility first. Exact spell range is checked only for
        -- actions that are actually missing/expiring, avoiding N-buffs x N-units range calls.
        local eligible,eligibleWhy=self:TargetEligible(action,false)
        if eligible then
          if not scans[entry.unit] and not scanErrors[entry.unit] then
            scans[entry.unit],scanErrors[entry.unit]=self:GetAuras(entry.unit,false)
          end
          if scans[entry.unit] then
            local isMissing,source,threshold,remaining,wake=self:Missing(b,action,scans[entry.unit],rebuffSeconds)
            self:ConsiderWake(wake)
            if isMissing and not (self.HelperSuppressed and self:HelperSuppressed(action)) then
              action.needState=source; action.remaining=remaining; action.threshold=threshold
              missing[#missing+1]={entry=entry,action=action,reason=source,threshold=threshold,remaining=remaining}
            end
          else
            if self.captureDiagnostics then self:AddDiag(b.key .. " -> " .. entry.unit .. ": " .. tostring(scanErrors[entry.unit])) end
          end
        else
          if self.captureDiagnostics then self:AddDiag(b.key .. " -> " .. entry.unit .. ": " .. (eligibleWhy or "ineligible")) end
        end
      else
        if self.captureDiagnostics then self:AddDiag(b.key .. " -> " .. entry.unit .. ": " .. (reason or "unresolved")) end
      end
    end
  end
  table.sort(missing,needSort)
  return missing
end

function B:Select()
  if self.stats then self.stats.selects=(self.stats.selects or 0)+1 end
  self.nextWakeDelay=nil
  self.rangeBlocked=false
  self.rangeBlockedActions={}
  self.rangeBlockedKeys={}
  self.powerBlocked=false
  self.cooldownBlocked=false
  self.dataPending=false
  if self.captureDiagnostics then self.diagnostics={} end
  if not self.db.enabled then return nil,"disabled" end
  if A.Call(UnitIsDeadOrGhost,"player") ~= false then return nil,"dead / ghost / player unavailable" end
  local paused=self:ReminderPauseReason(); if paused then return nil,paused end
  local casting,castError=A.Call(UnitCastingInfo,"player")
  local channeling,channelError=A.Call(UnitChannelInfo,"player")
  if castError or channelError then return nil,"cast/channel state unreadable" end
  if casting ~= nil or channeling ~= nil then return nil,"casting / channeling" end

  if self.db.consumablesEnabled and self.db.consumableFamilies.food then
    local eatingAuras=self:GetAuras("player",false)
    for _,aura in ipairs(eatingAuras or {}) do
      if self.EatingSpellIDs and self.EatingSpellIDs[aura.spellId] then
        if A.Number(aura.expirationTime) and aura.expirationTime>GetTime() then self:ConsiderWake(aura.expirationTime-GetTime()+0.1) end
        return nil,"eating"
      end
    end
  end
  local list,err=self:ClassList()
  if err then return nil,err end
  self.blessingClassList=list
  local roster=self:Roster()
  local blessingPlan=self:BlessingAssignmentsActive()
  local groupCount=A.Call(GetNumSubgroupMembers)
  if A.Call(IsInRaid)==false and A.Number(groupCount) and groupCount==0 then self.blessingPlayers=nil end
  local scans,scanErrors={},{}

  -- Optional quick-target pass. This intentionally uses only single-target buff
  -- families: clicking a friendly passerby should never fire a party/raid-wide
  -- spell or alter raid assignment behavior. The current target takes priority
  -- while this option is enabled, then normal self/group selection resumes.
  local quick=self:FriendlyTargetEntry()
  if quick and blessingPlan then
    local guid=A.Call(UnitGUID,quick.unit)
    for _,entry in ipairs(roster) do
      if A.Text(guid) and A.Call(UnitGUID,entry.unit)==guid then
        quick.group=entry.group; quick.blessingAssigned=true; break
      end
    end
  end
  if quick then
    if not quick.blessingAssigned then quick.targetBlessingChoice=self:TargetBlessingChoice(quick) end
    local chosen=self.db.targetClassBlessings and self.db.targetBlessingClasses[quick.class]
    local explicitTarget=not quick.blessingAssigned and chosen and chosen~="skip"
    local blessingOwned=false
    for _,b in ipairs(list) do
      local supported,why=self:Supported(b)
      if (self:Enabled(b) or (explicitTarget and b.kind=="blessing") or (blessingPlan and quick.blessingAssigned and b.kind=="blessing")) and (self:TargetBuffEnabled(b) or (blessingPlan and quick.blessingAssigned and b.kind=="blessing")) and supported and not b.singleKey and (b.kind=="single" or b.kind=="blessing")
        and not (b.kind=="blessing" and blessingOwned) and self:RecipientAllowed(b,quick) then
        local targetThreshold=self:TargetRebuffSeconds(b)
        local missing=self:ScanMissing(b,{quick},scans,scanErrors,targetThreshold)
        if #missing>0 then
          if b.kind=="blessing" then blessingOwned=true end
          local need=missing[1]
          local action=need.action
          action.blessingAssigned=quick.blessingAssigned and b.kind=="blessing" or nil
          action.reason="friendly target: "..tostring(need.reason)
          action.threshold=need.threshold; action.needState=need.reason; action.remaining=need.remaining
          action.quickTarget=true
          local valid,fail=self:Validate(action)
          if valid then action.selectedAt=GetTime(); return action,"ready" end
          self:AddDiag(b.key .. " -> target: " .. (fail or "not valid"))
        elseif b.kind=="blessing" then
          -- Match the normal blessing pass: only a VERIFIED present higher-priority
          -- blessing owns this caster's blessing slot. An unreadable aura/resolve
          -- state must not silently suppress lower-priority choices.
          local current=self:Resolve(b,quick.unit)
          if current and scans[quick.unit] then
            local isMissing=self:Missing(b,current,scans[quick.unit],self:TargetRebuffSeconds(b))
            if not isMissing then blessingOwned=true end
          end
        end
      elseif self:Enabled(b) and not supported and b.kind~="weapon" then
        self:AddDiag(b.key .. ": " .. why)
      end
    end
  end

  -- Single-target/self pass. Buff priority remains primary; within a buff a
  -- truly missing target outranks one that is only inside its rebuff window.
  local exclusive={}
  for _,b in ipairs(list) do
    local supported,why=self:Supported(b)
    if (self:Enabled(b) or (blessingPlan and b.kind=="blessing")) and supported and not b.singleKey then
      local entries
      if b.kind=="single" or b.kind=="blessing" then entries=roster else entries={roster[1]} end

      local candidates={}
      for _,entry in ipairs(entries) do
        local assigned = (blessingPlan and b.kind=="blessing" and self:BlessingGroupAllowed(entry)) or entry.unit=="player" or self:GroupSelected(b,entry.group or 1)
        local group=b.kind=="blessing" and ("blessing:" .. entry.unit) or nil
        if assigned and self:RecipientAllowed(b,entry) and (not group or not exclusive[group]) then
          candidates[#candidates+1]=entry
        end
      end
      local missing=self:ScanMissing(b,candidates,scans,scanErrors)
      -- Count only verified, in-range group-rank recipients. Restrict Greater
      -- Blessings to a class whose assigned members all belong to this family.
      local groupDef=b.groupKey and self:FindBuff(b.groupKey)
      if self.db.group and self.db.smartGroup and groupDef and (self:Enabled(groupDef) or (blessingPlan and b.kind=="blessing")) then
        local buckets={}
        for _,need in ipairs(missing) do
          local entry=need.entry
          if (blessingPlan and b.kind=="blessing" and self:BlessingChoice(entry)==b.key) or (not (blessingPlan and b.kind=="blessing") and self:GroupSelected(b,entry.group) and self:GroupClassAllowed(b,entry.class)) then
            local ga=self:Resolve(groupDef,entry.unit)
            if ga then
              local eligible,why=self:TargetEligible(ga,true)
              if eligible then
                local key=b.kind=="blessing" and entry.class or entry.group
                if key then
                  buckets[key]=buckets[key] or {}; buckets[key][#buckets[key]+1]={need=need,action=ga}
                end
              elseif why=="target out of range" or why=="target range unknown" then self:AddRangeBlocked(ga) end
            end
          end
        end
        local keys={}; for key in pairs(buckets) do keys[#keys+1]=key end; table.sort(keys)
        for _,key in ipairs(keys) do
          local bucket=buckets[key]; local safe=true
          -- A group cast would also hit recipients whose reminder was dismissed.
          for _,entry in ipairs(roster) do
            local affected=b.kind=="blessing" and entry.class==key or b.kind~="blessing" and entry.group==key
            if affected and self.HelperSuppressed and self:HelperSuppressed({key=b.key,target=entry.unit,targetGUID=A.Call(UnitGUID,entry.unit)}) then safe=false end
          end
          if blessingPlan and b.kind=="blessing" and not self:BlessingGreaterSafe(b.key,key,roster) then safe=false end
          if b.kind=="blessing" then
            for _,entry in ipairs(roster) do
              if entry.class==key and (exclusive["blessing:"..entry.unit] or (not blessingPlan and (not self:GroupSelected(b,entry.group) or not self:GroupClassAllowed(b,entry.class)))) then safe=false end
            end
          end
          if b.kind~="blessing" then
            for _,entry in ipairs(roster) do
              if entry.group==key and not self:GroupClassAllowed(b,entry.class) then safe=false end
            end
          end
          if safe and #bucket>=self:BlessingGroupNeed(groupDef) then
            local rankCounts={}
            for _,candidate in ipairs(bucket) do rankCounts[candidate.action.id]=(rankCounts[candidate.action.id] or 0)+1 end
            for _,candidate in ipairs(bucket) do
              local ga,need=candidate.action,candidate.need
              -- Different target levels can resolve different group ranks. Only
              -- recipients verified for this exact rank justify its reagent cost.
              local verified=rankCounts[ga.id] or 0
              if verified>=self:BlessingGroupNeed(groupDef) and self:Validate(ga) then
                ga.reason=tostring(verified).." verified recipients need "..b.name
                ga.needState=need.reason; ga.remaining=need.remaining; ga.groupCast=true; ga.blessingAssigned=blessingPlan and b.kind=="blessing" or nil; ga.groupCount=verified
                ga.selectedAt=GetTime(); return ga,"ready"
              end
            end
          end
        end
      end
      for _,need in ipairs(missing) do
        local group=b.kind=="blessing" and ("blessing:" .. need.entry.unit) or nil
        if not group or not exclusive[group] then
          if group then exclusive[group]=true end
          local action=need.action
          action.blessingAssigned=blessingPlan and b.kind=="blessing" or nil
          action.reason,action.threshold=need.reason,need.threshold
          action.needState,action.remaining=need.reason,need.remaining
          local valid,fail=self:Validate(action)
          if valid then action.selectedAt=GetTime(); return action,"ready" end
          self:AddDiag(b.key .. " -> " .. need.entry.unit .. ": " .. (fail or "not valid"))
        end
      end

      -- A present higher-priority blessing still owns the blessing slot for that
      -- target; do not replace it with a lower-priority blessing family.
      if b.kind=="blessing" then
        for _,entry in ipairs(candidates) do
          local group="blessing:" .. entry.unit
          if not exclusive[group] then
            local action=self:Resolve(b,entry.unit)
            if action and scans[entry.unit] then
              local isMissing=self:Missing(b,action,scans[entry.unit])
              if not isMissing then exclusive[group]=true end
            end
          end
        end
      end
    elseif self:Enabled(b) and not supported and b.kind~="weapon" then self:AddDiag(b.key .. ": " .. why) end
  end

  -- Personal consumables are intentionally evaluated after class/group/target
  -- spell maintenance so food/flasks never block a more immediate class buff.
  if type(self.SelectConsumable)=="function" then
    local ok,action,why=pcall(self.SelectConsumable,self)
    if not ok then self.lastError="consumable provider failed"; return nil,"consumable provider unavailable" end
    if action then return action,"ready" end
    if self.db.consumablesEnabled and why and why~="consumables disabled" then self:AddDiag("consumables: "..tostring(why)) end
  end

  if self.TrackingAction then
    local tracking=self:TrackingAction()
    if tracking then tracking.selectedAt=GetTime(); return tracking,"tracking reminder" end
  end

  if self.SelectReadiness then
    local readiness=self:SelectReadiness()
    if readiness then return readiness,readiness.manual and "manual pet recovery" or "class readiness" end
  end

  -- Weapon coatings are informational reminders. Evaluate them only after all
  -- valid castable spell and item actions so a manual alert cannot block the
  -- one-tap workflow.
  if type(self.SelectWeaponReminder)=="function" then
    local ok,action,why=pcall(self.SelectWeaponReminder,self)
    if not ok then self.lastError="weapon reminder provider failed"; return nil,"weapon reminder unavailable" end
    if action and not (self.HelperSuppressed and self:HelperSuppressed(action)) then action.selectedAt=GetTime(); return action,action.manual and "manual application required" or "weapon application ready" end
    if self.db.weaponReminder and why and why~="weapon coatings present" and why~="no learned coating ability" then
      self:AddDiag("weapon reminder: "..tostring(why))
    end
  end
  return nil,"nothing actionable"
end

-- A group reminder can become stale between display and the click (another
-- player buffs, a member dies/leaves, or assignment/threshold/range changes).
-- Re-run selection with fresh roster/auras only at the explicit group click.
-- Never swap in a different cast on that click: cancel, then refresh normally.
function B:RevalidateGroupAction(action)
  if A.Combat() or not action or not action.groupCast then return false end
  self:InvalidateRoster(); self:InvalidateAura()
  local fresh=self:Select()
  local valid=fresh and fresh.groupCast and fresh.id==action.id and fresh.key==action.key and
    fresh.target==action.target and fresh.targetGUID==action.targetGUID
  if valid then action.groupCount=fresh.groupCount; action.reason=fresh.reason end
  return valid==true
end
