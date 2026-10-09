-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
local _, B = ...
local A = B.API

-- Helpers are opt-in. No timers or inventory work are added while disabled.
function B:HelperEnabled(key) return self.db and self.db[key]==true end
function B:HelperKey(action)
  if not action then return nil end
  local def=action.key and self:FindBuff(action.key)
  local family=def and self:RootKey(def) or action.familyKey or action.key or action.id
  return tostring(action.source or "spell")..":"..tostring(family)
    ..":"..tostring(action.targetGUID or action.target or "player")
end
function B:HelperSuppressed(action)
  local dismissed=self.helperDismissed
  if not dismissed or next(dismissed)==nil then return false end
  local key=self:HelperKey(action)
  return key and dismissed[key]~=nil
end
function B:DismissHelper(action,reason)
  if A.Combat() or not action then return end
  self.helperDismissed=self.helperDismissed or {}
  self.helperDismissed[self:HelperKey(action)]=reason or "dismissed"
  self:RequestRefresh("reminder dismissed",0)
end
function B:RestoreHelpers()
  self.helperDismissed={}; self.helperAttempt=nil
  self:RequestRefresh("restore reminders",0)
end
function B:BeginHelperAttempt(action)
  self.helperAttempt=nil
  if not self:HelperEnabled("helperBounce") or not action or action.manual then return end
  local id=action.id
  if action.itemID then
    local info=self.itemMeta and self.itemMeta[action.itemID]
    id=info and info.spellID
  end
  if A.Number(id) and id>0 then self.helperAttempt={action=action,spellID=id,at=GetTime()} end
end
function B:CheckHelperBounce()
  local attempt=self.helperAttempt
  if not self:HelperEnabled("helperBounce") or A.Combat() or not attempt or GetTime()-attempt.at>0.5 then
    self.helperAttempt=nil; return
  end
  -- FAILED supplies the spell identity; UI_ERROR_MESSAGE supplies the reason.
  -- Neither event alone is enough. Accept either order, without polling.
  if attempt.failed and attempt.bounced then
    self.helperAttempt=nil
    self:DismissHelper(attempt.action,"stronger effect rejected this action")
  end
end
function B:HandleHelperError(message)
  if not A.Text(message) or not A.Text(SPELL_FAILED_AURA_BOUNCED) or message~=SPELL_FAILED_AURA_BOUNCED then
    self.helperAttempt=nil; return
  end
  if self.helperAttempt then self.helperAttempt.bounced=true end
  self:CheckHelperBounce()
end
function B:HandleHelperFailure(spellID)
  local attempt=self.helperAttempt
  if not attempt or not A.Number(spellID) or spellID~=attempt.spellID then
    self.helperAttempt=nil; return
  end
  attempt.failed=true
  self:CheckHelperBounce()
end

-- Only known, spell-backed gathering trackers are candidates. One explicit
-- preference prevents Herbs and Minerals from repeatedly replacing each other.
function B:GatheringTrackers(includeTreasure)
  local out={}
  local api=C_Minimap or {}
  local count=A.Call(api.GetNumTrackingTypes or GetNumTrackingTypes)
  if not A.Number(count) then return out end
  local getter=api.GetTrackingInfo or GetTrackingInfo
  if type(getter)~="function" then return out end
  for index=1,math.min(64,count) do
    local ok,info,texture,active,kind,_,spellID=pcall(getter,index)
    if ok and A.Public(info) then
      if type(info)~="table" then info={name=info,texture=texture,active=active,type=kind,spellID=spellID} end
      local id=info.spellID
      if A.Number(id) and (id==2383 or id==2580 or id==43308 or (includeTreasure and id==2481)) and A.Text(info.name)
        and A.Public(info.active) and A.Public(info.type) and info.type=="spell" and A.Known(id) then
        out[#out+1]={id=id,name=info.name,icon=A.Number(info.texture) and info.texture or 134400,
          active=info.active==true or info.active==1}
      end
    end
  end
  return out
end
function B:TrackingAction()
  if not self:HelperEnabled("helperTracking") and not self:HelperEnabled("helperTreasure") then return end
  for _,entry in ipairs(self:GatheringTrackers(true)) do
    local wanted=entry.id==2481 and self:HelperEnabled("helperTreasure") or (entry.id~=2481 and self:HelperEnabled("helperTracking") and entry.id==self.db.helperTracker)
    if wanted and not entry.active then
      local action={source="tracking",id=entry.id,key="gathering-"..entry.id,name=entry.name,icon=entry.icon,
        target="player",targetGUID=A.Call(UnitGUID,"player"),targetName="Tracking",rank="",reason="selected tracker is off",secureType="spell"}
      if not self:HelperSuppressed(action) and self:Validate(action) then return action end
    end
  end
end
function B:TrackingStillNeeded(action)
  if action.id==2481 then
    if not self:HelperEnabled("helperTreasure") then return false end
  elseif not self:HelperEnabled("helperTracking") or self.db.helperTracker~=action.id then return false end
  for _,entry in ipairs(self:GatheringTrackers(true)) do if entry.id==action.id then return not entry.active end end
  return false
end

local coverageKeys={motw=true,ai=true,fort=true,spirit=true,sp=true,bom=true,bow=true,bok=true}
function B:CoverageDefinitions()
  local result={}
  for _,def in ipairs(self.Buffs) do if coverageKeys[def.key] then result[#result+1]=def end end
  return result
end
function B:CoverageLines()
  local lines={}
  if not self:HelperEnabled("helperCoverage") or A.Combat() then return lines end
  local raid=A.Call(IsInRaid)
  if raid~=false then return lines end -- initial scope is five-player parties
  local count=A.Call(GetNumSubgroupMembers)
  if not A.Number(count) or count<1 then return lines end
  local units={"player"}; local providers={}; local scans={}
  for i=1,math.min(count,4) do units[#units+1]="party"..i end
  for _,unit in ipairs(units) do
    if A.Call(UnitIsConnected,unit)==true and A.Call(UnitIsDeadOrGhost,unit)==false then
      scans[unit]=self:GetAuras(unit,false)
      if unit~="player" and type(UnitClass)=="function" then
        local ok,_,class=pcall(UnitClass,unit)
        if ok and A.Text(class) then providers[class]=A.Call(UnitName,unit) end
      end
    end
  end
  for _,def in ipairs(self:CoverageDefinitions()) do
    local provider=providers[def.class]
    if A.Text(provider) then
      local missing=0
      local probe={id=def.ranks[#def.ranks],name=A.Call(C_Spell and C_Spell.GetSpellName,def.ranks[#def.ranks]) or def.name}
      for _,unit in ipairs(units) do
        local eligible=true
        if def.target and type(UnitClass)=="function" then
          local ok,_,class=pcall(UnitClass,unit); eligible=false
          if ok and A.Text(class) then for _,allowed in ipairs(def.target) do if allowed==class then eligible=true end end end
        end
        local hasBlessing=false
        if def.kind=="blessing" and scans[unit] then
          for _,other in ipairs(self.Buffs) do
            if other.kind=="blessing" and not other.singleKey then
              if not self:Missing(other,{id=other.ranks[#other.ranks],name=other.name},scans[unit],0) then hasBlessing=true; break end
            end
          end
        end
        if eligible and not hasBlessing and scans[unit] and self:Missing(def,probe,scans[unit],0) then missing=missing+1 end
      end
      if missing>0 then lines[#lines+1]=def.name..": "..missing.." missing; possible provider: "..provider end
    end
  end
  return lines
end

-- Inventory discovery only reports unknown consumables. It never adds actions,
-- infers effect strength, or changes the verified item catalog.
function B:DiscoverConsumables()
  self.helperDiscoverDirty=false
  self.helperDiscoveries={}
  if not self:HelperEnabled("helperDiscovery") or A.Combat() then return end
  local container=C_Container
  if not container or type(container.GetContainerNumSlots)~="function" or type(container.GetContainerItemID)~="function" then
    self.helperDiscoveryStatus="Bag discovery API unavailable"; return
  end
  local known={}; for _,family in ipairs(self.ConsumableFamilies) do for _,item in ipairs(family.items or {}) do known[item.id]=true end end
  local seen={}; local pending=0
  local getter=C_Item and C_Item.GetItemInfo or GetItemInfo
  if type(getter)~="function" then self.helperDiscoveryStatus="Item information API unavailable"; return end
  for bag=0,math.min(5,tonumber(NUM_BAG_SLOTS) or 4) do
    local slots=A.Call(container.GetContainerNumSlots,bag)
    for slot=1,A.Number(slots) and math.min(slots,200) or 0 do
      local id=A.Call(container.GetContainerItemID,bag,slot)
      if A.Number(id) and id>0 and not known[id] and not seen[id] then
        seen[id]=true
        local ok,name,_,_,_,_,itemType,_,_,_,_,_,classID=pcall(getter,id)
        if ok and A.Public(name) and type(name)=="table" then
          classID=name.classID; itemType=name.itemType; name=name.itemName or name.name
        end
        if ok and A.Text(name) then
          if (A.Number(classID) and classID==0) or (A.Text(itemType) and itemType==ITEM_CLASS_CONSUMABLE) then
            self.helperDiscoveries[#self.helperDiscoveries+1]={id=id,name=name}
          end
        else
          pending=pending+1
          self.helperDiscoveryPending=self.helperDiscoveryPending or {}
          if not self.helperDiscoveryPending[id] then
            self.helperDiscoveryPending[id]=true; self:ConsumableItemInfo(id)
          end
        end
      end
    end
  end
  table.sort(self.helperDiscoveries,function(a,b) return a.name<b.name end)
  self.helperDiscoveryStatus=#self.helperDiscoveries.." unknown consumables; "..pending.." awaiting item data. Informational only."
end

-- Directed reactions only; no persistent posture or looping animation commands.
local soloEmotes={
  {key="THANK",name="Thank"},{key="BOW",name="Bow"},{key="SALUTE",name="Salute"},
  {key="WAVE",name="Wave"},{key="CHEER",name="Cheer"},{key="APPLAUD",name="Applaud"},
  {key="SMILE",name="Smile"},{key="GRIN",name="Grin"},{key="HUG",name="Hug"},{key="KISS",name="Kiss"},
  {key="FART",name="Fart"},{key="BURP",name="Burp"},{key="RUDE",name="Rude"},{key="RASP",name="Rasp"},{key="MOCK",name="Mock"},{key="TAUNT",name="Taunt"},{key="TEASE",name="Tease"},{key="BONK",name="Bonk"},{key="POKE",name="Poke"},{key="TICKLE",name="Tickle"},{key="WINK",name="Wink"},{key="NOD",name="Nod"},{key="WELCOME",name="Welcome"},{key="CONGRATULATE",name="Congratulate"},{key="FLIRT",name="Flirt"},{key="LAUGH",name="Laugh"},{key="CHUCKLE",name="Chuckle"},{key="GIGGLE",name="Giggle"},{key="CACKLE",name="Cackle"},{key="GREET",name="Greet"},
}
function B:SoloThankEmotes()
  local localized={}
  local count=A.Number(MAXEMOTEINDEX) and math.min(MAXEMOTEINDEX,1000) or 0
  for i=1,count do
    local token,command=_G["EMOTE"..i.."_TOKEN"],_G["EMOTE"..i.."_CMD1"]
    if A.Text(token) and A.Text(command) then localized[token]=command:gsub("^/","") end
  end
  local out={}
  for _,entry in ipairs(soloEmotes) do
    out[#out+1]={key=entry.key,name=localized[entry.key] or self:Text(entry.name)}
  end
  return out
end
function B:SoloThankEmote()
  local choice=self.db and self.db.helperThankEmote
  for _,entry in ipairs(soloEmotes) do if choice==entry.key then return entry.key end end
  return "THANK"
end

function B:SoloThanksAllowed()
  return self:HelperEnabled("helperThanks") and self.db.enabled and not A.Combat() and not self:ReminderPauseReason()
    and A.Call(IsInGroup)==false and A.Call(IsInRaid)==false and A.Call(IsInInstance)==false
    and A.Call(UnitIsDeadOrGhost,"player")==false
end
function B:ObserveSoloThanks(baseline)
  if not self:SoloThanksAllowed() then self.helperThankSeen=nil; return end
  local auras=self:GetAuras("player",false)
  if not auras then self.helperThankSeen=nil; return end
  local old=self.helperThankSeen; local current={}
  local recognized={}
  for _,def in ipairs(self.Buffs) do
    if def.kind=="single" or def.kind=="group" or def.kind=="blessing" then
      for _,id in ipairs(def.ranks or {}) do recognized[id]=true end
    end
  end
  local candidate
  for _,aura in ipairs(auras) do
    if A.Number(aura.spellId) then
      current[aura.spellId]=true
      local unit=aura.sourceUnit
      if not baseline and old and not old[aura.spellId] and recognized[aura.spellId]
        and A.Number(aura.duration) and aura.duration>=60 and A.Text(unit)
        and A.Call(UnitIsPlayer,unit)==true and A.Call(UnitIsUnit,unit,"player")==false
        and A.Call(UnitCanAssist,"player",unit)==true then
        local guid=A.Call(UnitGUID,unit)
        if A.Text(guid) then candidate={unit=unit,guid=guid} end
      end
    end
  end
  self.helperThankSeen=current
  local emote=C_ChatInfo and C_ChatInfo.PerformEmote or DoEmote
  if not candidate or type(emote)~="function" then return end
  local now=GetTime(); self.helperThankCooldowns=self.helperThankCooldowns or {}
  for guid,at in pairs(self.helperThankCooldowns) do if now-at>=600 then self.helperThankCooldowns[guid]=nil end end
  if now-(self.helperLastThank or -1000)<60 or self.helperThankCooldowns[candidate.guid] then return end
  if A.Call(UnitGUID,candidate.unit)~=candidate.guid or not self:SoloThanksAllowed() then return end
  local name=A.Call(GetUnitName,candidate.unit,true)
  if not A.Text(name) and type(UnitName)=="function" then
    local ok,short,realm=pcall(UnitName,candidate.unit)
    if ok and A.Text(short) and A.Public(realm) then name=short..(A.Text(realm) and ("-"..realm) or "") end
  end
  if not A.Text(name) then return end
  self.helperLastThank=now; self.helperThankCooldowns[candidate.guid]=now
  local ok,result=pcall(emote,self:SoloThankEmote(),name)
  self.helperThankStatus=ok and A.Public(result) and result~=false and "Thank emote requested" or "Emote unavailable or restricted; no retry"
end

function B:HelperEvent(event,arg,arg2,spellID)
  if event=="PLAYER_REGEN_DISABLED" then
    self.helperAttempt=nil; self.helperThankSeen=nil
    if self.helperWindow then self.helperWindow:Hide() end
    if self.quickChoices then self.quickChoices:Hide() end
    if self.coverageFrame then self.coverageFrame:Hide() end
  elseif event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
    self.helperDismissed={}; self.helperAttempt=nil; self.helperThankSeen=nil; self.helperDiscoverDirty=true
  elseif event=="GROUP_ROSTER_UPDATE" then self.helperThankSeen=nil
  elseif event=="UI_ERROR_MESSAGE" then self:HandleHelperError(arg2)
  elseif event=="UNIT_SPELLCAST_FAILED" and arg=="player" then self:HandleHelperFailure(spellID)
  elseif (event=="UNIT_SPELLCAST_SUCCEEDED" or event=="UNIT_SPELLCAST_INTERRUPTED") and arg=="player" then self.helperAttempt=nil
  elseif event=="BAG_UPDATE_DELAYED" or (event=="ITEM_DATA_LOAD_RESULT" and A.Number(arg) and self.helperDiscoveryPending and self.helperDiscoveryPending[arg]) then
    if event=="BAG_UPDATE_DELAYED" then self.helperDiscoveryPending={} end
    self.helperDiscoverDirty=true
    if self:HelperEnabled("helperDiscovery") and not A.Combat() then self:RequestRefresh("discovery inventory changed",0.15) end
  end
end

local originalRefresh=B.Refresh
function B:Refresh(...)
  originalRefresh(self,...)
  if A.Combat() or not self.db or not self.db.enabled then
    self.helperThankSeen=nil
    if self.coverageFrame then self.coverageFrame:Hide() end
    return
  end
  if self:HelperEnabled("helperDiscovery") and self.helperDiscoverDirty then self:DiscoverConsumables() end
  if self:HelperEnabled("helperThanks") then self:ObserveSoloThanks() end
  if self.UpdateCoverageDisplay then self:UpdateCoverageDisplay() end
end
