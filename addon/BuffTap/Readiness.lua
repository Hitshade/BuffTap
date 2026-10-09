-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. See LICENSE-MPL-2.0.txt.
local _,B=...
local A=B.API

-- Independently checked against Forever 1.60.1.70009 client records.
-- Item IDs are possession checks only. No readiness action ever uses an item.
local demons={688,697,712,713,691}
local shardSpells={[697]=true,[712]=true,[713]=true,[691]=true,
  [6201]=true,[6202]=true,[5699]=true,[11729]=true,[11730]=true,
  [693]=true,[20752]=true,[20755]=true,[20756]=true,[20757]=true}
local stones={
  [5512]=6262,[19004]=23468,[19005]=23469,
  [5511]=6263,[19006]=23470,[19007]=23471,
  [5509]=5720,[19008]=23472,[19009]=23473,
  [5510]=5723,[19010]=23474,[19011]=23475,
  [9421]=11732,[19012]=23476,[19013]=23477,
}
local creation={{6201,5512},{6202,5511},{5699,5509},{11729,5510},{11730,9421}}
-- Soulstones (Forever 1.60.1.70124): item -> its use spell, which is also the
-- Soulstone Resurrection aura (3s cast, 30 yd). Highest rank first.
local soulstones={[16896]=20765,[16895]=20764,[16893]=20763,[16892]=20762,[5232]=20707}
local soulstoneOrder={16896,16895,16893,16892,5232}
local soulCreation={{693,5232},{20752,16892},{20755,16893},{20756,16895},{20757,16896}}
local soulAuras={[20707]=true,[20762]=true,[20763]=true,[20764]=true,[20765]=true}
local healerClasses={PRIEST=true,DRUID=true,SHAMAN=true,PALADIN=true}
local sacrifice={[18789]=true,[18790]=true,[18791]=true,[18792]=true}
local commonEvents={"UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_DELAYED",
  "UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_STOP","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE",
  "PLAYER_STARTED_MOVING","PLAYER_STOPPED_MOVING","PLAYER_UNGHOST"}
local petEvents={"UNIT_PET","UNIT_FLAGS","PET_INFO_UPDATE","PET_STABLE_UPDATE"}
local extraEvents={}
for _,events in ipairs({commonEvents,petEvents}) do for _,e in ipairs(events) do extraEvents[e]=true end end
local SETTLE=2 -- bounded transition allowance; validate this duration in the live client

function B:ReadinessClass()
  if self.readinessClassToken then return self.readinessClassToken end
  local ok,_,class=pcall(UnitClass,"player")
  if ok and A.Text(class) then self.readinessClassToken=class; return class end
  return nil
end
function B:ReadinessEnabled(key)
  local db=self.db
  if not db or not db.enabled then return false end
  if key=="pet" then
    if db.helperPet~=true then return false end
    local class=self:ReadinessClass()
    return class=="HUNTER" or class=="WARLOCK"
  elseif key=="healthstone" then
    if db.helperHealthstone~=true then return false end
    return self:ReadinessClass()=="WARLOCK"
  elseif key=="soulstone" then
    if db.helperSoulstone~=true then return false end
    return self:ReadinessClass()=="WARLOCK"
  end
  return false
end
function B:AnyReadinessEnabled()
  return self:ReadinessEnabled("pet") or self:ReadinessEnabled("healthstone") or self:ReadinessEnabled("soulstone")
end
function B:ReadinessDemons()
  local result={}
  if self:ReadinessClass()~="WARLOCK" then return result end
  for _,id in ipairs(demons) do
    if A.Known(id) then
      local name=A.Call(C_Spell and C_Spell.GetSpellName,id)
      local icon=A.Call(C_Spell and C_Spell.GetSpellTexture,id)
      if A.Text(name) then result[#result+1]={id=id,name=name,icon=icon or 136218} end
    end
  end
  return result
end

function B:CancelReadinessWake()
  self:CancelTimer("readiness")
  self.readinessWakeToken=(self.readinessWakeToken or 0)+1
  self.readinessWakeAt=nil
end
function B:ScheduleReadinessWake()
  local due=self.readinessSettleUntil
  local pending=self.readinessPending
  if pending and (not due or pending.untilAt<due) then due=pending.untilAt end
  if not due then self:CancelReadinessWake(); return end
  if A.Combat() then self:CancelReadinessWake(); return end
  if self.readinessWakeAt==due then return end
  self:CancelReadinessWake()
  local token=self.readinessWakeToken; self.readinessWakeAt=due
  local ok=pcall(self.StartTimer,self,"readiness",math.max(.05,due-GetTime()+.02),function()
    if token~=self.readinessWakeToken then return end
    self.readinessWakeAt=nil
    if self:AnyReadinessEnabled() then
      self:ExpireReadiness(); self:RequestRefresh("readiness transition",0)
    end
  end)
  if not ok then self.readinessWakeAt=nil end
end
function B:ExpireReadiness()
  local now=GetTime()
  if self.readinessSettleUntil and now>=self.readinessSettleUntil then self.readinessSettleUntil=nil end
  if self.readinessPending and now>=self.readinessPending.untilAt then self.readinessPending=nil end
  self:ScheduleReadinessWake()
end
function B:SyncReadiness()
  local pets=self:ReadinessEnabled("pet"); local hs=self:ReadinessEnabled("healthstone") or self:ReadinessEnabled("soulstone")
  local state=tostring(pets)..":"..tostring(self:ReadinessEnabled("healthstone"))..":"..tostring(self:ReadinessEnabled("soulstone"))
  if state==self.readinessRegistration then return end
  self.readinessRegistration=state
  local wanted={}
  if pets or hs then for _,e in ipairs(commonEvents) do wanted[e]=true end end
  if pets then for _,e in ipairs(petEvents) do wanted[e]=true end end
  self.readinessEvents=self.readinessEvents or {}
  for e in pairs(extraEvents) do
    if wanted[e] and not self.readinessEvents[e] then
      local registered=false
      if e:sub(1,5)=="UNIT_" and type(self.events.RegisterUnitEvent)=="function" then
        local ok,result=pcall(self.events.RegisterUnitEvent,self.events,e,e=="UNIT_FLAGS" and "pet" or "player")
        registered=ok and result~=false
      end
      if not registered then
        local ok,result=pcall(self.events.RegisterEvent,self.events,e)
        registered=ok and result~=false
      end
      self.readinessEvents[e]=registered or nil
    elseif not wanted[e] and self.readinessEvents[e] then
      pcall(self.events.UnregisterEvent,self.events,e); self.readinessEvents[e]=nil
    end
  end
  self.readinessInventory=nil
  if not pets then self.readinessSettleUntil=nil end
  if self.readinessPending and not self:ReadinessEnabled(self.readinessPending.key) then self.readinessPending=nil end
  if not pets and not hs then
    self.readinessStatus=nil; self.readinessPending=nil; self.readinessMounted=nil
    self:CancelReadinessWake()
  else
    self.readinessMounted=A.Call(IsMounted)
    self:ExpireReadiness()
  end
end

function B:ReadinessContext()
  if not self.db.enabled or A.Combat() then return false,"disabled / combat" end
  if A.Call(UnitIsDeadOrGhost,"player")~=false then return false,"player dead or unreadable" end
  if A.Call(IsMounted)~=false or A.Call(UnitInVehicle,"player")~=false then return false,"mounted, vehicle or state unreadable" end
  local cast,err=A.Call(UnitCastingInfo,"player"); local channel,cerr=A.Call(UnitChannelInfo,"player")
  if err or cerr or cast~=nil or channel~=nil then return false,"casting / channeling or state unreadable" end
  if self.db.consumablesEnabled and self.db.consumableFamilies.food then
    local auras=self:GetAuras("player",false)
    if not auras then return false,"eating state unreadable" end
    for _,aura in ipairs(auras) do if self.EatingSpellIDs[aura.spellId] then return false,"eating" end end
  end
  return true
end
local function action(key,id,name,icon,reason,manual)
  return {source="readiness",key=key,id=id or 0,name=name,icon=icon or 134400,
    target="player",targetGUID=A.Call(UnitGUID,"player"),targetName=manual and "Manual recovery" or "Class readiness",
    reason=reason,manual=manual or nil,valid=manual or nil,secureType=not manual and "spell" or nil,rank=""}
end
function B:ReadinessSpell(key,id,reason)
  if not A.Known(id) then return nil,"recovery spell not learned" end
  local name=A.Call(C_Spell and C_Spell.GetSpellName,id)
  local icon=A.Call(C_Spell and C_Spell.GetSpellTexture,id)
  if not A.Text(name) then return nil,"recovery spell data unavailable" end
  return action(key,id,name,icon,reason)
end
function B:PetReadinessCandidate()
  if not self:ReadinessEnabled("pet") then return nil,"pet helper off" end
  if self.readinessSettleUntil then return nil,"waiting for pet transition" end
  local exists=A.Call(UnitExists,"pet")
  if type(exists)~="boolean" then return nil,"pet presence unreadable" end
  local dead
  if exists then
    dead=A.Call(UnitIsDeadOrGhost,"pet")
    if type(dead)~="boolean" then return nil,"pet life state unreadable" end
    if not dead then return nil,"living pet present" end
  end
  if self:ReadinessClass()=="HUNTER" then
    if exists and dead then
      local guid=A.Call(UnitGUID,"pet")
      if not A.Text(guid) then return nil,"dead pet identity unreadable" end
      local result,why=self:ReadinessSpell("pet",982,"revive your dead pet")
      if result then result.petGUID=guid end
      return result,why
    end
    -- Stable records establish an assigned pet, not its absent life state.
    -- Never infer Call versus Revive from UnitExists(false) or a stale pet record.
    local assigned=A.Call(C_StableInfo and C_StableInfo.GetStablePetInfo,1)
    if type(assigned)~="table" or not A.Number(assigned.petNumber) or assigned.petNumber<=0 then
      return nil,"no verified current Hunter pet; call/revive manually"
    end
    if not A.Known(883) and not A.Known(982) then return nil,"pet recovery not learned" end
    return action("pet",0,"Pet missing",A.Call(C_Spell and C_Spell.GetSpellTexture,883),
      "Call or revive your pet manually; its absent life state is not verifiable.",true)
  end
  local auras=self:GetAuras("player",false)
  if not auras then return nil,"intentional petless state unreadable" end
  for _,aura in ipairs(auras) do
    if A.Number(aura.spellId) and sacrifice[aura.spellId] then
      if A.Number(aura.expirationTime) and aura.expirationTime>GetTime() then self:ConsiderWake(aura.expirationTime-GetTime()+.1) end
      return nil,"Demonic Sacrifice active"
    end
  end
  local id=self.db.helperDemon
  for _,entry in ipairs(self:ReadinessDemons()) do
    if entry.id==id then return self:ReadinessSpell("pet",id,"summon your preferred demon while no living pet is present") end
  end
  return action("pet",0,"Choose a demon",136218,
    "Select a learned summon in Helpers. Any living demon satisfies this reminder.",true)
end

-- Counts do not depend on item names, cooldowns, bank stock or use charges.
-- Cache once per inventory event; recheck once more on an explicit click.
-- cache.itemID is the first carried entry of order (or of the container scan).
local function stoneInventory(self,family,set,order,label)
  self.readinessInventory=self.readinessInventory or {}
  if self.readinessInventory[family] then return self.readinessInventory[family] end
  local cache={}; self.readinessInventory[family]=cache
  if self.stats then self.stats.readinessBagScans=(self.stats.readinessBagScans or 0)+1 end
  local unknown=false
  for _,id in ipairs(order) do
    local count=A.Call(C_Item and C_Item.GetItemCount,id,false,false,false,false)
    if not A.Number(count) or count<0 then unknown=true
    elseif count>0 then cache.hasStone=true; cache.itemID=id; return cache end
  end
  if unknown then cache.reason=label.." counts unreadable"; return cache end
  local C=C_Container
  if not C or type(C.GetContainerNumSlots)~="function" or type(C.GetContainerItemID)~="function"
    or type(C.GetContainerItemInfo)~="function" or type(C.GetContainerNumFreeSlots)~="function" then
    cache.reason="bag readiness API unavailable"; return cache
  end
  local last=NUM_BAG_SLOTS
  if not A.Number(last) or last<0 or last>5 then cache.reason="carried bag layout unavailable"; return cache end
  local capacity=false; local capacityUnknown=false
  for bag=0,last do
    local slots=A.Call(C.GetContainerNumSlots,bag)
    if not A.Number(slots) or slots<0 or slots>200 or (bag==0 and slots==0) then
      cache.reason="bag contents not ready"; return cache
    end
    if slots>0 then
      local ok,free,family=pcall(C.GetContainerNumFreeSlots,bag)
      if not ok or not A.Number(free) or free<0 or not A.Number(family) then capacityUnknown=true
      elseif family==0 and free>0 then capacity=true end
    end
    for slot=1,slots do
      local id,ierr=A.Call(C.GetContainerItemID,bag,slot)
      local info,err=A.Call(C.GetContainerItemInfo,bag,slot)
      if ierr or err or (id~=nil and not A.Number(id)) or (info~=nil and type(info)~="table") then
        cache.reason="carried item data unreadable"; return cache
      end
      if id~=nil or info~=nil then
        if not A.Number(id) or not info or not A.Number(info.itemID) or info.itemID~=id
          or not A.Number(info.stackCount) or info.stackCount<1 then
          cache.reason="waiting for carried item data"; return cache
        end
        if set[id] then cache.hasStone=true; cache.itemID=id; return cache end
      end
    end
  end
  cache.hasStone=false
  if capacity then cache.capacity=true
  elseif not capacityUnknown then cache.capacity=false end
  cache.reason=capacity and "no carried "..label or (capacityUnknown and "bag capacity unreadable" or "no free general-bag slot")
  return cache
end
local stoneOrder={}
for id in pairs(stones) do stoneOrder[#stoneOrder+1]=id end
table.sort(stoneOrder)
function B:HealthstoneInventory() return stoneInventory(self,"healthstone",stones,stoneOrder,"Healthstone") end
function B:SoulstoneInventory() return stoneInventory(self,"soulstone",soulstones,soulstoneOrder,"Soulstone") end
function B:HealthstoneCandidate()
  if not self:ReadinessEnabled("healthstone") then return nil,"Healthstone helper off" end
  local inventory=self:HealthstoneInventory()
  if inventory.hasStone~=false then return nil,inventory.hasStone and "Healthstone already carried" or inventory.reason end
  if inventory.capacity~=true then return nil,inventory.reason end
  for i=#creation,1,-1 do
    local entry=creation[i]
    if A.Known(entry[1]) then
      local info=self:ConsumableItemInfo(entry[2])
      if not info.loaded or info.spellID~=stones[entry[2]] then return nil,"Healthstone output metadata unavailable or changed" end
      return self:ReadinessSpell("healthstone",entry[1],"create a personal Healthstone; this button never consumes one")
    end
  end
  return nil,"Create Healthstone not learned"
end

-- Units checked for an existing Soulstone: you, then party or raid members.
local function soulstoneUnits()
  local units={"player"}
  if A.Call(IsInRaid)==true then
    local n=A.Call(GetNumGroupMembers)
    for i=1,(A.Number(n) and math.min(n,40) or 0) do
      local unit="raid"..i
      if A.Call(UnitExists,unit)==true and A.Call(UnitIsUnit,unit,"player")~=true then units[#units+1]=unit end
    end
  else
    local n=A.Call(GetNumSubgroupMembers)
    for i=1,(A.Number(n) and math.min(n,4) or 0) do
      local unit="party"..i
      if A.Call(UnitExists,unit)==true then units[#units+1]=unit end
    end
  end
  return units
end
local function unitClass(unit)
  local class=A.Call(function() local _,c=UnitClass(unit); return c end)
  return A.Text(class) and class or nil
end
local function itemInRange(itemID,unit)
  local fn=(C_Item and C_Item.IsItemInRange) or IsItemInRange
  local value=A.Call(fn,itemID,unit)
  if value==true or value==1 then return true end
  if value==false or value==0 then return false end
  return nil
end
-- Healer first (group order), else yourself. Only verified, visible, in-range
-- living players qualify; anything unreadable falls back to you.
function B:SoulstoneTarget(itemID,units)
  for _,unit in ipairs(units) do
    if unit~="player" and healerClasses[unitClass(unit) or ""]
      and A.Call(UnitIsPlayer,unit)==true and A.Call(UnitIsConnected,unit)==true
      and A.Call(UnitIsDeadOrGhost,unit)==false and A.Call(UnitCanAssist,"player",unit)==true
      and (type(UnitIsVisible)~="function" or A.Call(UnitIsVisible,unit)==true)
      and itemInRange(itemID,unit)==true then
      return unit
    end
  end
  return "player"
end
function B:SoulstoneCoverage(units)
  for _,unit in ipairs(units) do
    local auras=self:GetAuras(unit,false)
    if not auras then return nil,(unit=="player" and "your" or unit).." auras unreadable" end
    for _,aura in ipairs(auras) do
      if A.Number(aura.spellId) and soulAuras[aura.spellId] then
        if A.Number(aura.expirationTime) and aura.expirationTime>GetTime() then self:ConsiderWake(aura.expirationTime-GetTime()+.1) end
        return true,"Soulstone active on "..(A.Call(UnitName,unit) or unit)
      end
    end
  end
  return false
end
function B:SoulstoneCandidate()
  if not self:ReadinessEnabled("soulstone") then return nil,"Soulstone helper off" end
  local units=soulstoneUnits()
  local covered,why=self:SoulstoneCoverage(units)
  if covered~=false then return nil,why end
  local inventory=self:SoulstoneInventory()
  if inventory.hasStone==nil then return nil,inventory.reason end
  if inventory.hasStone==false then
    if inventory.capacity~=true then return nil,inventory.reason end
    for i=#soulCreation,1,-1 do
      local entry=soulCreation[i]
      if A.Known(entry[1]) then
        local info=self:ConsumableItemInfo(entry[2])
        if not info.loaded or info.spellID~=soulstones[entry[2]] then return nil,"Soulstone output metadata unavailable or changed" end
        return self:ReadinessSpell("soulstone",entry[1],"create a Soulstone; BuffTap then offers to place it")
      end
    end
    return nil,"Create Soulstone not learned"
  end
  local itemID=inventory.itemID
  local info=self:ConsumableItemInfo(itemID)
  if not info.loaded or info.spellID~=soulstones[itemID] then return nil,"Soulstone item metadata unavailable or changed" end
  local fn=C_Item and C_Item.GetItemCooldown
  if type(fn)~="function" then return nil,"Soulstone cooldown API unavailable" end
  local ok,start,duration,enabled=pcall(fn,itemID)
  if not ok or not A.Number(start) or not A.Number(duration) or not A.Public(enabled) or (enabled~=true and enabled~=1) then return nil,"Soulstone cooldown unreadable" end
  if duration>0 and start+duration>GetTime() then self:ConsiderWake(start+duration-GetTime()+.05); return nil,"Soulstone on cooldown" end
  if A.Call(C_Item and C_Item.IsUsableItem,itemID)~=true then return nil,"Soulstone not usable" end
  local target=self:SoulstoneTarget(itemID,units)
  local name=A.Call(UnitName,target) or target
  local result=action("soulstone",soulstones[itemID],info.name,info.texture,"place a Soulstone on "..(target=="player" and "yourself" or name))
  result.secureType="item"; result.itemID=itemID; result.itemToken="item:"..itemID
  result.target=target; result.targetGUID=A.Call(UnitGUID,target)
  result.targetName=target=="player" and "Soulstone • self" or "Soulstone • "..name
  return result
end
function B:ReadinessCandidate(key)
  if not self:ReadinessEnabled(key) then return nil,"helper off" end
  self:ExpireReadiness()
  local allowed,why=self:ReadinessContext()
  if not allowed then return nil,why end
  if self.readinessPending and self.readinessPending.key==key then return nil,"waiting for readiness cast/inventory update" end
  if key=="pet" then return self:PetReadinessCandidate() end
  if key=="healthstone" then return self:HealthstoneCandidate() end
  if key=="soulstone" then return self:SoulstoneCandidate() end
  return nil,"unknown readiness family"
end
function B:ReadinessStillNeeded(previous)
  local current,why=self:ReadinessCandidate(previous.key)
  if not current then return false,why end
  if current.id~=previous.id or current.manual~=previous.manual or current.petGUID~=previous.petGUID
    or current.itemID~=previous.itemID or current.target~=previous.target or current.targetGUID~=previous.targetGUID then return false,"readiness choice changed" end
  if self:HelperSuppressed(previous) then return false,"readiness dismissed" end
  if current.manual then return true end
  -- All supported recovery/creation spells are cast-time spells. Never arm them
  -- while moving or when movement/resource state cannot be checked.
  local speed=A.Call(GetUnitSpeed,"player")
  if not A.Number(speed) or speed~=0 then return false,"moving or movement unreadable" end
  if shardSpells[current.id] then
    local shards=A.Call(C_Item and C_Item.GetItemCount,6265,false,false,false,false)
    if not A.Number(shards) or shards<1 then self.powerBlocked=true; return false,"Soul Shard unavailable" end
  end
  return true
end
function B:SelectReadiness()
  local manual
  for _,key in ipairs({"pet","healthstone","soulstone"}) do
    if self:ReadinessEnabled(key) then
      local ok,result,why=pcall(function()
        local candidate,reason=self:ReadinessCandidate(key)
        if candidate and not self:HelperSuppressed(candidate) then
          local valid,fail=self:Validate(candidate)
          if valid then return candidate end
          reason=fail
        end
        return nil,reason
      end)
      if not ok then result=nil; why="readiness API unavailable" end
      self.readinessStatus=key..": "..(why or (result and result.reason) or "dismissed")
      self:AddDiag(self.readinessStatus)
      if result then
        result.selectedAt=GetTime()
        if not result.manual then return result end
        manual=manual or result
      end
    end
  end
  return manual
end

function B:AfterReadinessClick(action,down)
  if down==false or action.manual or not self:ReadinessEnabled(action.key) then return end
  if self.readinessPending then return end
  self.readinessPending={key=action.key,id=action.id,untilAt=GetTime()+1}
  self:ScheduleReadinessWake()
end
function B:ReadinessEvent(event,unit,castGUID,spellID)
  local pets=self:ReadinessEnabled("pet"); local hs=self:ReadinessEnabled("healthstone") or self:ReadinessEnabled("soulstone")
  if not pets and not hs then return extraEvents[event] end
  if event=="PLAYER_REGEN_DISABLED" then self.readinessPending=nil; self:CancelReadinessWake(); return end
  if event=="PLAYER_REGEN_ENABLED" then self:ExpireReadiness() end
  if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
    self.readinessInventory=nil; self.readinessPending=nil
    if pets and not self.readinessSettleUntil then self.readinessSettleUntil=GetTime()+SETTLE end
    self.readinessMounted=A.Call(IsMounted); self:ScheduleReadinessWake()
  elseif event=="PLAYER_MOUNT_DISPLAY_CHANGED" then
    local mounted=A.Call(IsMounted)
    if pets and mounted==false and self.readinessMounted==true then self.readinessSettleUntil=GetTime()+SETTLE end
    self.readinessMounted=mounted; self:ScheduleReadinessWake()
  elseif event=="BAG_UPDATE_DELAYED" then
    self.readinessInventory=nil
    if not A.Combat() then self:RequestRefresh("readiness inventory",.15) end
  elseif event=="ITEM_DATA_LOAD_RESULT" then
    if hs and A.Number(unit) and (stones[unit] or soulstones[unit]) and self.itemRequests and self.itemRequests[unit] then
      self.readinessInventory=nil
      if not A.Combat() then self:RequestRefresh("readiness item metadata",.15) end
    end
  end
  if event=="UNIT_PET" and unit~="player" then return true end
  if event=="UNIT_FLAGS" and unit~="pet" then return true end
  if (event=="UNIT_ENTERED_VEHICLE" or event=="UNIT_EXITED_VEHICLE") and unit~="player" then return true end
  if event=="UNIT_EXITED_VEHICLE" or event=="PLAYER_UNGHOST" then
    if pets then self.readinessSettleUntil=GetTime()+SETTLE; self:ScheduleReadinessWake() end
  end
  local castEvent=event:match("^UNIT_SPELLCAST_")
  if castEvent and unit~="player" then return extraEvents[event] end
  local pending=self.readinessPending
  if castEvent and pending and A.Number(spellID) and spellID==pending.id then
    local same=not pending.castGUID or (A.Text(castGUID) and castGUID==pending.castGUID)
    if same then
      if event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_DELAYED" then
        if A.Text(castGUID) then pending.castGUID=castGUID end
        -- A bounded fallback covers the verified 3s creation / 10s summon cast.
        pending.untilAt=GetTime()+15
      elseif event=="UNIT_SPELLCAST_SUCCEEDED" then
        pending.untilAt=GetTime()+SETTLE; pending.succeeded=true; self.readinessInventory=nil
      elseif event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED" then self.readinessPending=nil end
      self:ScheduleReadinessWake()
    end
  end
  if extraEvents[event] then
    if not A.Combat() then
      -- Clear stale prepared spells immediately for start/movement/pet events.
      if self.action and self.action.source=="readiness" then self:Commit(nil,"readiness state changed") end
      self:RequestRefresh("class readiness event",.05)
    end
    return true
  end
end
function B:ReadinessSummary()
  if not self:AnyReadinessEnabled() then return "Class readiness: off" end
  return "Class readiness: "..(self.readinessStatus or "enabled; ordinary buffs take priority")
end
