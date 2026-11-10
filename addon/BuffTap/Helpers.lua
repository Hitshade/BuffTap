-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
local _, B = ...
local A = B.API

-- Optional conveniences and verified cast-failure tracking.
function B:HelperEnabled(key) return self.db and self.db[key]==true end
function B:HelperKey(action)
  if not action then return nil end
  local def=action.key and self:FindBuff(action.key)
  local family=def and self:RootKey(def) or action.familyKey or action.key or action.id
  return tostring(action.source or "spell")..":"..tostring(family)
    ..":"..tostring(action.targetGUID or action.target or "player")
end
local function retryKey(action)
  if not action or action.manual or action.target=="player" or not A.Text(action.targetGUID)
    or not A.Number(action.id) or (action.source and action.source~="spell") then return end
  return action.targetGUID..":"..tostring(action.id)
end
function B:CastRetryBlocked(action)
  local key=retryKey(action)
  local entry=key and self.castRetry and self.castRetry[key]
  if not entry then return false end
  local remaining=entry.untilTime-GetTime()
  if remaining<=0 then self.castRetry[key]=nil; return false end
  self.deferredBlocked=true
  self:ConsiderWake(remaining)
  self:AddDiag("Cast retry -> "..tostring(action.target)..": "..entry.reason.."; retry in "..math.ceil(remaining).." sec")
  return true
end
function B:CheckCastRetry()
  local attempt=self.castRetryAttempt
  if not attempt or A.Combat() or GetTime()-attempt.at>1 then self.castRetryAttempt=nil; return end
  if not attempt.failed or not attempt.reason then return end
  self.castRetryAttempt=nil
  if A.Call(UnitGUID,attempt.action.target)~=attempt.action.targetGUID then return end
  self.castRetry=self.castRetry or {}
  local count,oldest,expiry=0
  for key,entry in pairs(self.castRetry) do
    if entry.untilTime<=GetTime() then self.castRetry[key]=nil
    else
      count=count+1
      if not expiry or entry.untilTime<expiry then oldest,expiry=key,entry.untilTime end
    end
  end
  if count>=200 then self.castRetry[oldest]=nil end
  self.castRetry[attempt.key]={untilTime=GetTime()+10,reason=attempt.reason}
  self:RequestRefresh("recipient cast retry delay",0)
end
function B:CastRetryError(message)
  local attempt=self.castRetryAttempt
  if not attempt then return end
  if not A.Text(message) then self.castRetryAttempt=nil; return end
  for _,key in ipairs({"ERR_OUT_OF_RANGE","ERR_SPELL_OUT_OF_RANGE","SPELL_FAILED_OUT_OF_RANGE","SPELL_FAILED_LINE_OF_SIGHT"}) do
    local text=_G[key]
    if A.Text(text) and message==text then attempt.reason=key; self:CheckCastRetry(); return end
  end
  -- A caster-side or unrelated error must never penalize this recipient.
  self.castRetryAttempt=nil
end

function B:HelperSuppressed(action)
  if self:CastRetryBlocked(action) then return true end
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
  self.helperDismissed={}; self.helperAttempt=nil; self.castRetry={}; self.castRetryAttempt=nil
  self:RequestRefresh("restore reminders",0)
end
function B:BeginHelperAttempt(action)
  local key=retryKey(action)
  self.castRetryAttempt=key and {key=key,action=action,at=GetTime(),spellID=action.id} or nil
  self.buffCastAttempt=nil
  if action and not action.manual and (not action.source or action.source=="spell") and A.Number(action.id) and A.Text(action.targetGUID) then
    self.buffCastAttempt={id=action.id,unit=action.target,guid=action.targetGUID,at=GetTime()}
    self.buffAuraFresh={unit=action.target,guid=action.targetGUID,untilTime=GetTime()+3}
  end
  self.helperAttempt=nil
  if not action or action.manual or (not action.nearby and not self:HelperEnabled("helperBounce")) then return end
  local id=action.id
  if action.itemID then
    local info=self.itemMeta and self.itemMeta[action.itemID]
    id=info and info.spellID
  end
  if A.Number(id) and id>0 then self.helperAttempt={action=action,spellID=id,at=GetTime()} end
end
function B:CheckHelperBounce()
  local attempt=self.helperAttempt
  if A.Combat() or not attempt or (not attempt.action.nearby and not self:HelperEnabled("helperBounce")) or GetTime()-attempt.at>0.5 then
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
  self:CastRetryError(message)
  if not A.Text(message) or not A.Text(SPELL_FAILED_AURA_BOUNCED) or message~=SPELL_FAILED_AURA_BOUNCED then
    self.helperAttempt=nil; return
  end
  if self.helperAttempt then self.helperAttempt.bounced=true end
  self:CheckHelperBounce()
end
function B:HandleHelperFailure(spellID)
  local retry=self.castRetryAttempt
  if retry then
    if A.Number(spellID) and spellID==retry.spellID then retry.failed=true; self:CheckCastRetry()
    else self.castRetryAttempt=nil end
  end
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

function B:SoloThanksBlockReason()
  if not self:HelperEnabled("helperThanks") or not self.db.enabled then return "disabled" end
  if A.Combat() then return "combat" end
  if self:ReminderPauseReason() then return self:ReminderPauseReason() end
  if A.Call(IsInGroup)~=false or A.Call(IsInRaid)~=false or A.Call(IsInInstance)~=false then return "solo outdoor play required" end
  if A.Call(UnitIsDeadOrGhost,"player")~=false then return "player dead or unavailable" end
  if type(IsStealthed)=="function" and A.Call(IsStealthed)~=false then return "stealthed or hiding state unavailable" end
  if type(UnitIsFeignDeath)=="function" and A.Call(UnitIsFeignDeath,"player")~=false then return "Feign Death or state unavailable" end
  if C_ChatInfo and type(C_ChatInfo.InChatMessagingLockdown)=="function" and A.Call(C_ChatInfo.InChatMessagingLockdown)~=false then return "chat is restricted" end
  local kind=Enum and Enum.AddOnRestrictionType and Enum.AddOnRestrictionType.Chat
  local inactive=Enum and Enum.AddOnRestrictionState and Enum.AddOnRestrictionState.Inactive
  if A.Number(kind) and A.Number(inactive) and C_RestrictedActions and type(C_RestrictedActions.GetAddOnRestrictionState)=="function"
    and A.Call(C_RestrictedActions.GetAddOnRestrictionState,kind)~=inactive then return "chat is restricted" end
end
function B:SoloThanksAllowed() return self:SoloThanksBlockReason()==nil end
function B:ScheduleThanksSettle()
  if self.helperThankRetryPending or (self.helperThankRetries or 0)>=10 then return end
  self.helperThankRetries=(self.helperThankRetries or 0)+1
  self.helperThankRetryPending=true
  self:StartTimer("thanks-settle",.2,function()
    B.helperThankRetryPending=nil
    if B:SoloThanksAllowed() then B:ObserveSoloThanks() end
  end)
end
local function thankName(unit)
  local ok,name,second=pcall(UnitName,unit)
  if ok and A.Text(name) and name~="" and name~=(_G.UNKNOWNOBJECT or "Unknown") and A.Public(second) then
    if A.Text(second) and second~="" then
      local version=A.Call(GetBuildInfo)
      name=name..(A.Text(version) and version:match("^1%.60%.") and " " or "-")..second
    end
    return name
  end
  local full=A.Call(GetUnitName,unit,true)
  if A.Text(full) and full~="" and full~=(_G.UNKNOWNOBJECT or "Unknown") then return full end
end
local function ignoredProvider(unit,guid,name)
  local friends=C_FriendList
  if not friends then return false end
  if A.Text(guid) and A.Call(friends.IsIgnoredByGuid,guid)==true then return true end
  return (A.Text(unit) and A.Call(friends.IsIgnored,unit)==true)
    or (A.Text(name) and A.Call(friends.IsIgnored,name)==true) or false
end
local function thankRecipient(source)
  if not A.Text(source) or source=="" then return nil,"source unit missing or restricted",true end
  if source=="player" or A.Call(UnitIsUnit,source,"player")==true then return nil,nil,false end
  if A.Call(UnitExists,source)~=true then return nil,"caster unit unavailable: "..source,true end
  local player=A.Call(UnitIsPlayer,source)
  if player==false then return nil,nil,false end
  if player~=true then return nil,"caster player identity unavailable: "..source,true end
  local guid=A.Call(UnitGUID,source); guid=A.Text(guid) and guid or nil
  local own=A.Call(UnitGUID,"player")
  if guid and A.Text(own) and guid==own then return nil,nil,false end
  local name=thankName(source)
  if not name then return nil,"caster name unavailable: "..source,true end
  if name==thankName("player") then return nil,nil,false end
  if ignoredProvider(source,guid,name) then return nil,"provider is ignored",false end
  return {unit=source,guid=guid,name=name,key=guid and ("guid:"..guid) or ("name:"..name),nameKey="name:"..name,identity="source unit"}
end
local function guidName(guid)
  if type(UnitNameFromGUID)~="function" then return nil end
  local ok,name,realm=pcall(UnitNameFromGUID,guid)
  if not ok or not A.Text(name) or name==(_G.UNKNOWNOBJECT or "Unknown") or not A.Public(realm) then return nil end
  if name:find("[%c|]") or name:match("^%s") or name:match("%s$") then return nil end
  -- UnitNameFromGUID returns the character name and SERVER, unlike UnitName's
  -- surname return on Forever. Preserve the name and qualify the server.
  local character=name
  if A.Text(realm) and realm~="" then name=name.."-"..realm:gsub("%s","") end
  return name,character
end
function B:FindCasterUnit(guid)
  local seen={}
  local function match(unit)
    if not A.Text(unit) or seen[unit] then return end
    seen[unit]=true
    if A.Call(UnitExists,unit)==true and A.Call(UnitGUID,unit)==guid then return unit end
  end
  for _,unit in ipairs({"player","target","mouseover","focus"}) do local found=match(unit); if found then return found end end
  local raid=A.Call(IsInRaid)==true
  local count=A.Call(raid and GetNumGroupMembers or GetNumSubgroupMembers)
  if A.Number(count) then
    for i=1,math.min(count,raid and 40 or 4) do
      local found=match((raid and "raid" or "party")..i); if found then return found end
    end
  end
  for unit in pairs(self.nearbyUnits or {}) do local found=match(unit); if found then return found end end
  local plates=A.Call(C_NamePlate and C_NamePlate.GetNamePlates)
  if type(plates)=="table" then
    for i=1,math.min(40,#plates) do
      local unit=A.Call(function() return plates[i]:GetUnit() end)
      local found=match(unit); if found then return found end
    end
  end
end
function B:ThanksAuraRecipient(aura,cache)
  local recipient,why,retry=thankRecipient(aura.sourceUnit)
  if recipient or not retry then return recipient,why,retry end
  local guid,err=self:AuraCasterGUID("player",aura)
  if not A.Text(guid) then
    return nil,why.."; "..tostring(err or "caster GUID unavailable"),true
  end
  local own=A.Call(UnitGUID,"player")
  if not A.Text(own) then return nil,"player GUID unavailable",true end
  if guid==own or not guid:match("^Player%-") then return nil,nil,false end
  if ignoredProvider(nil,guid) then return nil,"provider is ignored",false end
  local found=cache[guid]
  if found==nil then found=self:FindCasterUnit(guid) or false; cache[guid]=found end
  if found then
    local candidate,reason,again=thankRecipient(found)
    if candidate then candidate.identity="aura GUID / live unit" end
    return candidate,reason,again
  end
  local name,character=guidName(guid)
  if not name then return nil,"caster GUID readable; full name unavailable",true end
  if ignoredProvider(nil,guid,name) then return nil,"provider is ignored",false end
  local nameKey=A.Call(RegionalUniqueNamesEnabled)==true and character or name
  return {guid=guid,name=name,key="guid:"..guid,nameKey="name:"..nameKey,identity="aura GUID / name"}
end
-- Read fresh helpful auras and capture the caster beside each slot. Casting
-- keeps its separate, stricter aura reader/cache and all existing safeguards.
function B:ReadSoloThanksAuras()
  local read=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
  if type(read)~="function" then return nil,"helpful aura API unavailable" end
  local out,empty,refused,casters={},false,0,{}
  for i=1,255 do
    local raw,err=A.Call(read,"player",i,"HELPFUL")
    if err or not A.Public(raw) then out.incomplete=true; refused=refused+1
    elseif raw==nil then
      empty=true
      if i>=40 then break end
    elseif type(raw)~="table" then out.incomplete=true
    else
      if empty then out.incomplete=true end
      local id=A.Number(raw.spellId) and raw.spellId or nil
      local instance=A.Number(raw.auraInstanceID) and raw.auraInstanceID or nil
      if id or instance then
        local recipient,why,retry=self:ThanksAuraRecipient(raw,casters)
        out[#out+1]={spellId=id,auraInstanceID=instance,expirationTime=A.Number(raw.expirationTime) and raw.expirationTime or nil,
          recipient=recipient,casterReason=why,casterRetry=retry}
      else out.incomplete=true end
    end
    if i==255 then out.incomplete=true end
  end
  if #out==0 and refused>=40 then return nil,"helpful aura reads restricted" end
  return out
end
function B:DispatchSoloThanks()
  self:CancelTimer("thanks-send")
  local blocked=self:SoloThanksBlockReason()
  if blocked then self.helperThankQueue={}; self.helperThankStatus="Paused: "..blocked; return end
  local now=GetTime()
  self.helperThankCooldowns=self.helperThankCooldowns or {}
  for guid,at in pairs(self.helperThankCooldowns) do if now-at>=60 then self.helperThankCooldowns[guid]=nil end end
  local queue=self.helperThankQueue or {}
  while #queue>0 do
    local candidate=queue[1]
    if now-candidate.at>10 or (self.helperThankCooldowns[candidate.key] or self.helperThankCooldowns[candidate.nameKey]) then table.remove(queue,1)
    else
      local wait=1-(now-(self.helperLastThank or -1000))
      if wait>0 then self:StartTimer("thanks-send",wait,function() B:DispatchSoloThanks() end); return end
      table.remove(queue,1)
      local held
      if candidate.unit then
        held=A.Call(UnitExists,candidate.unit)==true and A.Call(UnitIsPlayer,candidate.unit)==true
          and thankName(candidate.unit)==candidate.name
          and (not candidate.guid or A.Call(UnitGUID,candidate.unit)==candidate.guid)
      else
        held=A.Text(candidate.guid) and candidate.guid:match("^Player%-") and guidName(candidate.guid)==candidate.name
          and A.Text(A.Call(UnitGUID,"player")) and candidate.guid~=A.Call(UnitGUID,"player")
      end
      if ignoredProvider(candidate.unit,candidate.guid,candidate.name) then
        self.helperThankStatus="Skipped thanks: provider is ignored"
      elseif held then
        local emote=C_ChatInfo and C_ChatInfo.PerformEmote or DoEmote
        if type(emote)~="function" then self.helperThankStatus="Emote API unavailable"; self.helperThankQueue={}; return end
        self.helperLastThank=now
        local ok,result=pcall(emote,self:SoloThankEmote(),candidate.unit or candidate.name)
        if ok then
          self.helperThankCooldowns[candidate.key]=now; self.helperThankCooldowns[candidate.nameKey]=now
          -- Blizzard's chat parser treats true as restricted, despite the
          -- generated API documentation naming this return value success.
          if not A.Public(result) then self.helperThankStatus="Emote result restricted or unreadable; no retry"
          elseif result==true then self.helperThankStatus="Client restricted the emote; no retry"
          else self.helperThankStatus="Thank emote requested for "..candidate.name.." ("..candidate.identity..")" end
        else self.helperThankStatus="Emote call failed; no retry" end
        if #queue>0 then self:StartTimer("thanks-send",1,function() B:DispatchSoloThanks() end) end
        return
      else self.helperThankStatus="Caster identity changed; no emote sent" end
    end
  end
end

function B:ObserveSoloThanks(baseline)
  if not self:SoloThanksAllowed() then
    self.helperThankSeen=nil; self.helperThankBaseline=nil; self.helperThankPending=nil; self.helperThankRetries=0
    self.helperThankRetryPending=nil; self.helperThankQueue={}; self:CancelTimer("thanks-send"); self:CancelTimer("thanks-settle")
    self.helperThankStatus="Paused: "..tostring(self:SoloThanksBlockReason() or "unavailable"); return
  end
  -- Gratitude needs readable identity, not the strict timing required for casting.
  local auras,scanError=self:ReadSoloThanksAuras()
  if not auras then
    self.helperThankStatus="Aura scan unavailable: "..tostring(scanError).."; previous baseline preserved"
    self:ScheduleThanksSettle(); return
  end
  local old=self.helperThankSeen
  local current,candidates={},{}
  self.helperThankPending=self.helperThankPending or {}
  local unidentified,skipped=false,nil
  local pendingCaster=false
  for _,aura in ipairs(auras) do
    if A.Number(aura.spellId) or A.Number(aura.auraInstanceID) then
      local recipient=aura.recipient
      local key=A.Number(aura.auraInstanceID) and ("instance:"..aura.auraInstanceID) or ("spell:"..aura.spellId)
      local record={id=aura.spellId,guid=recipient and recipient.guid,name=recipient and recipient.name,expires=aura.expirationTime}
      current[key]=record
      local previous=old and old[key]
      if not previous and old and A.Number(aura.auraInstanceID) and A.Number(aura.spellId) then previous=old["spell:"..aura.spellId] end
      local changed=old and (not previous or previous.id~=record.id
        or (previous.guid and record.guid and previous.guid~=record.guid)
        or (previous.name and record.name and previous.name~=record.name)
        or (A.Number(previous.expires) and A.Number(record.expires) and previous.expires>0 and record.expires>previous.expires+1))
      local pending=self.helperThankPending[key]
      if pending and (pending.id~=record.id or GetTime()-pending.at>2) then self.helperThankPending[key]=nil; pending=nil end
      if changed or pending then
        if recipient then
          candidates[#candidates+1]=recipient; self.helperThankPending[key]=nil
        else
          if aura.casterReason and not aura.casterRetry then skipped=aura.casterReason end
          if aura.casterReason and aura.casterRetry then
            unidentified=aura.casterReason.." (spell "..tostring(aura.spellId or "unreadable")..", instance "..tostring(aura.auraInstanceID or "unavailable")..")"
          end
          if aura.casterRetry then
            self.helperThankPending[key]=pending or {id=record.id,at=GetTime()}; pendingCaster=true
          end
        end
      end
    end
  end
  if not old and auras.incomplete then self.helperThankStatus="Initial aura identities incomplete; settling"; self:ScheduleThanksSettle(); return end
  if not old and not baseline then
    local prior=self.helperThankBaseline
    local same=prior~=nil
    for key,value in pairs(current) do if not prior or not prior[key] or prior[key].id~=value.id or prior[key].expires~=value.expires then same=false end end
    for key in pairs(prior or {}) do if not current[key] then same=false end end
    self.helperThankBaseline=current
    if not same then self.helperThankStatus="Settling initial buff baseline"; self:ScheduleThanksSettle(); return end
  end
  -- Unreadable unrelated auras must not erase identities already observed.
  if auras.incomplete then for key,value in pairs(old or {}) do if not current[key] then current[key]=value end end end
  for key in pairs(self.helperThankPending) do if not current[key] then self.helperThankPending[key]=nil end end
  self.helperThankSeen=current; self.helperThankBaseline=nil
  if pendingCaster then self:ScheduleThanksSettle()
  else self.helperThankRetries=0; self.helperThankRetryPending=nil; self:CancelTimer("thanks-settle") end
  if baseline or not old then self.helperThankStatus="Baseline ready; waiting for an incoming buff"; return end
  if #candidates==0 then
    if unidentified then self.helperThankStatus="Incoming buff caster unavailable: "..unidentified
    elseif skipped then self.helperThankStatus="Skipped thanks: "..skipped end
    return
  end
  self.helperThankQueue=self.helperThankQueue or {}
  self.helperThankCooldowns=self.helperThankCooldowns or {}
  for index=#self.helperThankQueue,1,-1 do if GetTime()-self.helperThankQueue[index].at>10 then table.remove(self.helperThankQueue,index) end end
  for _,candidate in ipairs(candidates) do
    local queued=false
    for _,other in ipairs(self.helperThankQueue) do if other.key==candidate.key or other.name==candidate.name then queued=true; break end end
    local last=(self.helperThankCooldowns[candidate.key] or self.helperThankCooldowns[candidate.nameKey])
    if not queued and (not last or GetTime()-last>=60) and #self.helperThankQueue<20 then
      candidate.at=GetTime(); self.helperThankQueue[#self.helperThankQueue+1]=candidate
    end
  end
  self:DispatchSoloThanks()
end

function B:HelperEvent(event,arg,arg2,spellID)
  if event=="UNIT_AURA" and A.Text(arg) and arg=="player" and self:HelperEnabled("helperThanks") then
    self:ObserveSoloThanks()
  elseif event=="PLAYER_REGEN_DISABLED" then
    self.helperThankQueue={}; self:CancelTimer("thanks-send")
    self.helperAttempt=nil; self.castRetryAttempt=nil; self.helperThankSeen=nil
    self.helperThankBaseline=nil; self.helperThankRetries=0; self.helperThankRetryPending=nil; self:CancelTimer("thanks-settle")
    if self.helperWindow then self.helperWindow:Hide() end
    if self.quickChoices then self.quickChoices:Hide() end
    if self.coverageFrame then self.coverageFrame:Hide() end
  elseif event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
    self.helperThankQueue={}; self:CancelTimer("thanks-send")
    self.helperThankBaseline=nil; self.helperThankPending=nil; self.helperThankRetries=0; self.helperThankRetryPending=nil; self:CancelTimer("thanks-settle")
    self.helperDismissed={}; self.helperAttempt=nil; self.castRetry={}; self.castRetryAttempt=nil; self.helperThankSeen=nil; self.helperDiscoverDirty=true
  elseif event=="GROUP_ROSTER_UPDATE" then self.castRetry={}; self.castRetryAttempt=nil; self.helperThankSeen=nil; self.helperThankBaseline=nil; self.helperThankPending=nil; self.helperThankQueue={}; self:CancelTimer("thanks-send")
  elseif event=="UI_ERROR_MESSAGE" then self:HandleHelperError(arg2)
  elseif event=="UNIT_SPELLCAST_FAILED" and arg=="player" then self:HandleHelperFailure(spellID)
  elseif (event=="UNIT_SPELLCAST_SUCCEEDED" or event=="UNIT_SPELLCAST_INTERRUPTED") and arg=="player" then self.helperAttempt=nil; self.castRetryAttempt=nil
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
  if self:HelperEnabled("helperThanks") and not self.helperThankSeen then self:ObserveSoloThanks() end
  if self.UpdateCoverageDisplay then self:UpdateCoverageDisplay() end
end

function B:RefreshBuffCastAuras(attempt)
  if A.Combat() or not self.db.enabled or not attempt or A.Call(UnitGUID,attempt.unit)~=attempt.guid then return end
  self:InvalidateAura(attempt.unit)
  self:RequestRefresh("buff cast aura update",.03)
end
function B:BuffCastSucceeded(unit,id)
  local attempt=self.buffCastAttempt
  if unit~="player" or not A.Number(id) or not attempt or id~=attempt.id or GetTime()-attempt.at>3 then return end
  if A.Call(UnitGUID,attempt.unit)~=attempt.guid then return end
  self.buffCastAttempt=nil
  self.buffAuraFresh={unit=attempt.unit,guid=attempt.guid,untilTime=GetTime()+3}
  self:RefreshBuffCastAuras(attempt)
  for _,value in ipairs({{"buff-aura-early",.12},{"buff-aura-settle",.45},{"buff-aura-late",1.6}}) do
    self:StartTimer(value[1],value[2],function() B:RefreshBuffCastAuras(attempt) end)
  end
end
