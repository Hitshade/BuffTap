-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Nearby recipient source. The ordinary buff engine remains authoritative.
local _,B=...
local A=B.API
local MAX_UNITS,ROWS=40,5
local WIDTH,HEIGHT,ROW_HEIGHT=210,134,21
local targetChoice=B.TargetBlessingChoice
-- Forever's second UnitName return is the character's surname (not a realm).
function B:NearbySurname(unit)
  local ok,_,surname=pcall(UnitName,unit)
  if ok and type(surname)=="string" and surname~="" and not surname:find("[%c|]") then return surname end
end
-- Buff requests default to what helps your class: Intellect and Spirit for mana users, Might and Wisdom
-- for the classes their catalog entries target, everything else for everyone. A saved choice always wins.
local MANA_USERS={MAGE=true,WARLOCK=true,PRIEST=true,SHAMAN=true,DRUID=true,PALADIN=true,HUNTER=true}
function B:RequestUseful(def,class)
  if not def or not class then return false end
  if def.target then for _,c in ipairs(def.target) do if c==class then return true end end; return false end
  if def.key=="ai" or def.key=="spirit" then return MANA_USERS[class]==true end
  -- Situational protection (raid shadow damage) is opt-in, not an everyday request.
  if def.key=="sp" then return false end
  return true
end
function B:RequestEnabled(def)
  local saved=self.db.requestBuffs[def.key]
  if saved~=nil then return saved==true end
  return self:RequestUseful(def,A.Class("player"))
end
function B:NearbyDisplayName(entry)
  local name=entry.name
  if self.db.nearbyFullNames~=false and entry.surname then name=entry.name.." "..entry.surname end
  if self.db.nearbyShowLevel==true and entry.unit then
    local level=A.Call(UnitLevel,entry.unit)
    if A.Number(level) then name="("..(level>0 and tostring(level) or "??")..") "..name end
  end
  return name
end
function B:TargetBlessingChoice(entry)
  if A.Class("player")~="PALADIN" then return nil end
  local choice=targetChoice(self,entry)
  if choice~=nil or not entry.nearby then return choice end
  local choices={}
  for _,def in ipairs(self:ClassList()) do
    if def.kind=="blessing" and not def.singleKey and self:Enabled(def) and self:TargetBuffEnabled(def) then choices[#choices+1]=def end
  end
  if not self.db.targetBlessingFallback then choices=choices[1] and {choices[1]} or {} end
  return self:PickBlessingPriority(entry,choices,true)
end
local function plateSetting()
  for _,name in ipairs({"nameplateShowFriendlyPlayers","nameplateShowFriends"}) do
    local value=A.Call(C_CVar and C_CVar.GetCVar,name)
    if value==nil then value=A.Call(GetCVar,name) end
    if value==nil then value=A.Call(C_CVar and C_CVar.GetCVarBool or GetCVarBool,name) end
    if value==true or value==1 or value=="1" then return true,name end
    if value==false or value==0 or value=="0" then return false,name end
  end
  return nil,"unavailable"
end
local function platesOn() return plateSetting()==true end
-- For the Nearby introduction: true/false and the client setting name, or nil when unknown.
function B:FriendlyPlatesState() return plateSetting() end
-- Discover and validate by nameplate GUID; the secure macro targets by exact name.
function B:NearbyCastName(action)
  if not action or A.Call(UnitGUID,action.target)~=action.targetGUID then return nil,"recipient identity changed" end
  local full=type(GetUnitName)=="function"
  local name=A.Call(full and GetUnitName or UnitName,action.target,true)
  if not A.Text(name) or name=="" or name:find("[%c%[%];/|]")
    or name:match("^%s") or name:match("%s$") then return nil,"recipient name unavailable or unsafe" end
  -- Without the full-name API, a same-named player from another realm is ambiguous.
  if not full then
    for unit,guid in pairs(self.nearbyUnits or {}) do
      if guid~=action.targetGUID and A.Call(UnitName,unit)==name then return nil,"recipient name ambiguous" end
    end
  end
  return name
end
function B:NearbyMacro(action)
  if action and not self:NearbyRecipientSafe(action.target) then return nil,self.nearbySafetyReason end
  if not action or not A.Text(action.target) or not action.target:match("^nameplate%d+$")
    or not A.Text(action.name) or not A.Public(action.rank) then return nil,"unreadable cast text" end
  local recipient,nameError=self:NearbyCastName(action)
  if not recipient then return nil,nameError end
  local rank=action.rank or ""
  local text=action.name..(rank~="" and ("("..rank..")") or "")
  if text:find("[%c%[%];/|]") then return nil,"unsafe cast text" end
  local def=self:FindBuff(action.key)
  if not def then return nil,"buff unavailable" end
  if rank=="" and #self:Candidates(def)>1 then return nil,"exact rank text unavailable" end
  local resolver=C_Spell and C_Spell.GetSpellIDForSpellIdentifier
  if type(resolver)=="function" then
    local id=A.Call(resolver,text)
    if not A.Number(id) or id~=action.id then return nil,"exact rank text not verified" end
  end
  local exists=A.Call(UnitExists,"target")
  if type(exists)~="boolean" then return nil,"current target unreadable" end
  local same=false
  if exists then same=A.Call(UnitIsUnit,action.target,"target") end
  if type(same)~="boolean" then return nil,"current target identity unreadable" end
  local cast="/cast [help,nodead] "..text
  if same then return #cast<=255 and cast or nil end
  local macro="/cleartarget\n/targetexact "..recipient.."\n"..cast
    ..(exists and "\n/targetlasttarget" or "\n/cleartarget")
  if #macro>255 then return nil,"cast text too long" end
  return macro
end
function B:PrepareNearbyCast(action)
  local macro,why=self:NearbyMacro(action)
  self.nearbyCastError=why
  if not macro then return false end
  action.secureType="macro"; action.macroText=macro
  return true
end
function B:NoteNearbyClick(action)
  self.nearbyClickAt=GetTime(); self.nearbyClickError=nil
  self:NoteNearbyResult(action)
  if action then
    self.buffCastAttempt={id=action.id,unit=action.target,guid=action.targetGUID,at=GetTime()}
    self.buffAuraFresh={unit=action.target,guid=action.targetGUID,untilTime=GetTime()+3}
    -- Covers the two early target retries and the bounded late retry chain.
    self.nearbyQuietCast={recipient=action.targetGUID,previous=A.Call(UnitGUID,"target"),untilTime=GetTime()+5}
  end
  self.nearbyLastClick=action and (tostring(action.id).." -> "..action.target.." ("..(self:NearbyCastName(action) or "name unavailable")..")") or "cancelled: evidence changed"
end
-- Cast result on the Nearby row (optional): green "done" or red with the game's reason for about
-- the global cooldown, then the row clears or comes back. Only a cast on that player in the next 2 seconds counts.
local GCD=1.5
-- When the global cooldown from this cast ends: the spell's own cooldown while it is the GCD, else 1.5s.
local function gcdEnds(id,at)
  local now=GetTime()
  local start,duration
  local info=A.Call(C_Spell and C_Spell.GetSpellCooldown,id)
  if type(info)=="table" then start,duration=info.startTime,info.duration
  else start,duration=A.Call(GetSpellCooldown,id) end
  if A.Number(start) and A.Number(duration) and duration>0 and duration<=GCD+.05 and start+duration>now then
    return math.max(start+duration,now+.6)
  end
  return math.max((at or now)+GCD,now+.6)
end
function B:NoteNearbyResult(action)
  self.nearbyResult=nil; self:CancelTimer("nearby-result")
  if not action or self.db.nearbyCastResult==false or not A.Text(action.targetGUID) then return end
  local cleanse=action.source=="cleanse"
  local spell=action.spellName or A.Call(GetSpellInfo,action.id)
  local label=cleanse and action.debuffName or tostring(action.name or spell or ""):gsub("%s*%(.-%)$","")
  self.nearbyResult={guid=action.targetGUID,id=action.id,spell=spell,label=label,cleanse=cleanse,at=GetTime(),state="pending"}
  self:StartTimer("nearby-result",2,function() local r=B.nearbyResult; if r and r.state=="pending" then B.nearbyResult=nil end end)
end
function B:SetNearbyResult(state,reason)
  local r=self.nearbyResult
  if not r or r.state~="pending" or GetTime()-r.at>2 then return end
  r.state=state; r.reason=reason; r.untilTime=state=="ok" and gcdEnds(r.id,r.at) or GetTime()+GCD
  self:CancelTimer("nearby-result")
  self:StartTimer("nearby-result",r.untilTime-GetTime()+.02,function()
    B.nearbyResult=nil; B.nearbySnapshot=nil; if not A.Combat() then B:UpdateNearbyWindow() end
  end)
  if not A.Combat() and self.nearbyFrame then self:UpdateNearbyWindow() end
end
function B:NearbyResultFor(guid)
  local r=self.nearbyResult
  if r and r.state~="pending" and r.guid==guid and r.untilTime and GetTime()<r.untilTime and self.db.nearbyCastResult~=false then return r end
end
function B:NearbyResultSpell(spellID)
  local r=self.nearbyResult
  if not r or r.state~="pending" or not A.Number(spellID) then return false end
  if spellID==r.id then return true end
  local name=A.Call(GetSpellInfo,spellID)
  return A.Text(name) and name==r.spell
end
-- Fit the result text to the row: full text, shorter text, a smaller size, then a trailing "...".
local function fitText(fs,avail,list,path,size,flags)
  for _,s in ipairs({size,math.max(8,size-1),math.max(8,size-2)}) do
    fs:SetFont(path,s,flags)
    for _,t in ipairs(list) do
      fs:SetText(t); local w=fs:GetStringWidth()
      if not A.Number(w) or w<=avail then return t end
    end
  end
  local t=list[#list]
  while #t>1 do
    t=t:gsub("[%z\1-\127\194-\244][\128-\191]*$","")
    fs:SetText(t.."..."); local w=fs:GetStringWidth()
    if not A.Number(w) or w<=avail then return t.."..." end
  end
  return fs:GetText()
end
B.NearbyFitText=fitText
function B:ShowNearbyRowResult(row,r)
  local o=row.result
  if not r then if o then o:Hide() end; return end
  if not o then
    o=CreateFrame("Frame",nil,row); o:SetAllPoints(); o:SetFrameLevel((row:GetFrameLevel() or 1)+5)
    if o.EnableMouse then o:EnableMouse(false) end
    o.bg=o:CreateTexture(nil,"BACKGROUND"); o.bg:SetAllPoints()
    o.bar=o:CreateTexture(nil,"BORDER"); o.bar:SetPoint("TOPLEFT",0,0); o.bar:SetPoint("BOTTOMLEFT",0,0); o.bar:SetWidth(2)
    o.mark=o:CreateTexture(nil,"ARTWORK"); o.mark:SetSize(14,14); o.mark:SetPoint("LEFT",6,0)
    o.text=o:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); o.text:SetPoint("LEFT",o.mark,"RIGHT",5,0)
    o.text:SetJustifyH("LEFT"); o.text:SetWordWrap(false); o.text:SetShadowColor(0,0,0,.95); o.text:SetShadowOffset(1,-1)
    row.result=o
  end
  local ok=r.state=="ok"; local c=ok and {.27,.78,.43} or {.90,.31,.27}
  o.bg:SetColorTexture(c[1]*.18+.07,c[2]*.18+.07,c[3]*.18+.07,1); o.bar:SetColorTexture(c[1],c[2],c[3],1)
  o.mark:SetTexture(ok and "Interface\\RaidFrame\\ReadyCheck-Ready" or "Interface\\RaidFrame\\ReadyCheck-NotReady")
  local list
  if ok and r.cleanse then list={self:Text("Cleansed: %s",r.label),self:Text("Cleansed")}
  elseif ok then list={self:Text("%s: done",r.label),r.label}
  else
    local reason=A.Text(r.reason) and r.reason:gsub("[%.。]+$","") or nil
    list=reason and {self:Text("Failed: %s",reason),reason} or {self:Text("Failed")}
  end
  local path,size,flags=row.name:GetFont()
  if not path then path,size,flags=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",11,"" end
  local width=row:GetWidth(); if not A.Number(width) then width=WIDTH end
  local avail=math.max(40,width-6-14-5-6)
  o.text:SetWidth(avail); fitText(o.text,avail,list,path,size or 11,flags or "")
  o:Show()
end
function B:ReminderSoundAllowed(action)
  if action and action.nearby then return false end
  local cast=self.nearbyQuietCast
  if not cast then return true end
  if GetTime()>=cast.untilTime then self.nearbyQuietCast=nil; return true end
  if action and action.quickTarget and action.target=="target" and A.Text(action.targetGUID)
    and (action.targetGUID==cast.recipient or action.targetGUID==cast.previous) then return false end
  return true
end
function B:NearbyCastSucceeded(unit,id)
  self:BuffCastSucceeded(unit,id)
end
local function nextAction(entry,readyOnly)
  if not entry then return end
  for _,action in ipairs(entry.actions) do if action.ready then return action end end
  if not readyOnly then return entry.actions[1] end
end
-- Group members' GUIDs, built once per frame: Nearby asks this several times per player per update.
local groupGuids,groupGuidsAt,groupGuidsUnsure={},-1,false
local function groupGuidSet()
  local now=GetTime()
  if groupGuidsAt==now then return groupGuids,groupGuidsUnsure end
  wipe(groupGuids); groupGuidsUnsure=false; groupGuidsAt=now
  local raid=A.Call(IsInRaid)==true
  local count=A.Call(raid and GetNumGroupMembers or GetNumSubgroupMembers)
  if not A.Number(count) then groupGuidsUnsure=true; return groupGuids,true end
  for i=1,math.min(count,raid and 40 or 4) do
    local member=A.Call(UnitGUID,(raid and "raid" or "party")..i)
    if A.Text(member) then groupGuids[member]=true else groupGuidsUnsure=true end
  end
  return groupGuids,groupGuidsUnsure
end
function B:NearbyGroupMember(unit)
  if A.Call(UnitIsUnit,unit,"player")==true then return true end
  if A.Call(UnitInParty,unit)==true or A.Number(A.Call(UnitInRaid,unit)) then return true end
  local set,unsure=groupGuidSet()
  local guid=A.Call(UnitGUID,unit)
  if not A.Text(guid) then return true end
  if set[guid] then return true end
  -- An unreadable roster entry could be this player: treat as group (safe side), as before.
  return unsure
end
function B:NearbyRecipientSafe(unit)
  if A.Call(UnitAffectingCombat,unit)~=false then
    self.nearbySafetyReason="Recipient in combat or combat state unavailable"
    self:AddDiag("Nearby protection -> "..tostring(unit)..": "..self.nearbySafetyReason)
    return false,self.nearbySafetyReason
  end
  if self.db.pvpProtection==true then
    local pvp,ffa=A.Call(UnitIsPVP,unit),A.Call(UnitIsPVPFreeForAll,unit)
    if pvp~=false or ffa~=false then
      self.pvpBlocked=true
      self.nearbySafetyReason="Recipient PvP flagged or flag state unavailable"
      self:AddDiag("Nearby protection -> "..tostring(unit)..": "..self.nearbySafetyReason)
      return false,self.nearbySafetyReason
    end
  end
  return true
end
function B:NearbyEntry(unit,checkOnly)
  if not self.db.nearbyEnabled or self.db.nearbyBuffing==false or not platesOn() or A.Combat() then return nil end
  if not A.Text(unit) or not unit:match("^nameplate%d+$") then return nil end
  local guid=A.Call(UnitGUID,unit)
  if not self.nearbyUnits or self.nearbyUnits[unit]~=guid then return nil end
  if self:NearbyGroupMember(unit) or not self:NearbyRecipientSafe(unit) then return nil end
  -- Your explicitly selected player remains owned by normal Target mode.
  if self.db.friendlyTarget and A.Call(UnitIsUnit,unit,"target")==true then return nil end
  return self:FriendlyTargetEntry(unit,true,checkOnly)
end
local function fits(def,class)
  if (def.key=="ai" or def.key=="spirit") and (class=="WARRIOR" or class=="ROGUE") then return false end
  if not def.target then return true end
  for _,c in ipairs(def.target) do if c==class then return true end end
  return false
end
-- Compare preferences without allocating a new signature every scan. The copy
-- changes only when preferences do; it is never written to SavedVariables.
local function sameSettings(current,previous,depth)
  if type(current)~="table" or type(previous)~="table" then return current==previous end
  if depth>8 then return false end
  for key,value in pairs(current) do if not sameSettings(value,previous[key],depth+1) then return false end end
  for key in pairs(previous) do if current[key]==nil then return false end end
  return true
end
local function copySettings(current,seen)
  if type(current)~="table" then return current end
  if seen[current] then return seen[current] end
  local out={}; seen[current]=out
  for key,value in pairs(current) do out[key]=copySettings(value,seen) end
  return out
end
function B:CheckNearbyNeedSettings()
  if self.nearbyNeedSettingsChecked then return end
  if self.nearbyNeedBook~=self.resolveCache or not sameSettings(self.db,self.nearbyNeedSettings,0) then
    self.nearbyNeedCache={}; self.nearbyNeedSettings=copySettings(self.db,{})
    self.nearbyNeedBook=self.resolveCache
  end
  if self.classListPassActive then self.nearbyNeedSettingsChecked=true end
end
function B:NearbyNeeds(entry,list)
  self:CheckNearbyNeedSettings()
  self.nearbyNeedCache=self.nearbyNeedCache or {}
  local now=GetTime()
  local guid,level=A.Call(UnitGUID,entry.unit),A.Call(UnitLevel,entry.unit)
  local auras=self:GetAuras(entry.unit,false,true)
  local reusable=auras and not auras.incomplete and not auras.timingRestricted
    and A.Text(guid) and A.Number(level) and level>0 and not self.captureDiagnostics
    and not self.bookIssue and not self.bookDirty
    and (not self.helperDismissed or not next(self.helperDismissed))
    and (not self.castRetry or not next(self.castRetry))
    and A.Call(UnitIsConnected,entry.unit)==true
    and (type(UnitIsVisible)~="function" or A.Call(UnitIsVisible,entry.unit)==true)
  local cached=self.nearbyNeedCache[entry.unit]
  if reusable and cached and cached.guid==guid and cached.class==entry.class and cached.level==level
    and cached.auras==auras and now<cached.untilTime then
    if cached.wakeAt then self:ConsiderWake(cached.wakeAt-now) end
    return cached.needs
  end
  local priorWake=self.nextWakeDelay; self.nextWakeDelay=nil
  local needs={}
  entry.targetBlessingChoice=self:TargetBlessingChoice(entry)
  local selected=self.db.targetClassBlessings and self.db.targetBlessingClasses[entry.class]
  local explicit=selected and selected~="skip"
  local scans,errors={},{}
  local holdShort=self:NearbyHoldsShort()
  for _,def in ipairs(list) do
    local enabled=self:Enabled(def) or (explicit and def.kind=="blessing") or (def.classWide and self:TargetBuffEnabled(def))
    if enabled and self:TargetBuffEnabled(def) and not def.singleKey and not (holdShort and def.short)
      and (def.kind=="single" or def.kind=="blessing") and self:Supported(def)
      and (explicit and def.kind=="blessing" or (def.kind=="blessing" and fits(def,entry.class)) or (def.kind~="blessing" and self:TargetClassAllowed(def,entry.class,true))) then
      local missing=self:ScanMissing(def,{entry},scans,errors,self:TargetRebuffSeconds(def))
      if missing[1] then needs[#needs+1]=missing[1] end
    end
  end
  local wake=self.nextWakeDelay
  if priorWake then self:ConsiderWake(priorWake) end
  if reusable and not self.ownershipUnavailable and not self.buffDataUnavailable and not self.dataPending then
    self.nearbyNeedCache[entry.unit]={guid=guid,class=entry.class,level=level,auras=auras,needs=needs,
      untilTime=now+math.min(.5,wake or .5),wakeAt=wake and now+wake}
  else self.nearbyNeedCache[entry.unit]=nil end
  return needs
end
function B:NearbyActions(entry)
  local actions={}
  local list=self:ClassList()
  self.blessingClassList=list
  for _,need in ipairs(self:NearbyNeeds(entry,list)) do
    local action=need.action
    action.quickTarget=true; action.nearby=true
    action.needState=need.reason; action.remaining=need.remaining; action.threshold=need.threshold
    action.reason="nearby player: "..need.reason
    -- Cached need decisions never bypass fresh recipient/range/power checks.
    local valid,why=self:Validate(action)
    action.ready=valid==true
    action.waiting=not valid and why=="cooldown / global cooldown"
    self.nearbyProbes=self.nearbyProbes or {}
    local probeKey=entry.unit..":"..tostring(action.id)
    local range=self:SpellRange(action)
    self.nearbyProbes[probeKey]={action=action,range=range==nil and "unknown" or range}
    if not self:HelperSuppressed(action) and (valid or action.waiting) and self:PrepareNearbyCast(action) then
      action.selectedAt=GetTime(); actions[#actions+1]=action
      if #actions==4 then break end
    end
  end
  return actions
end
local invalidateAura=B.InvalidateAura
function B:InvalidateAura(unit)
  if self.nearbyNeedCache then
    if unit then self.nearbyNeedCache[unit]=nil else self.nearbyNeedCache={} end
  end
  return invalidateAura(self,unit)
end
function B:NearbyCandidates(force)
  if not force and self.nearbySnapshot then return self.nearbySnapshot end
  local out,seen={},{}
  self.nearbyProbes={}; self.nearbyCastError=nil; self.nearbySafetyReason=nil
  if not self.db or not self.db.enabled or not self.db.nearbyEnabled or not platesOn()
    or A.Combat() or self:NearbyPauseReason() or A.Call(UnitIsDeadOrGhost,"player")~=false then return out end
  for unit,guid in pairs(self.nearbyUnits or {}) do
    local entry=self:NearbyEntry(unit)
    if entry and A.Text(guid) and not seen[guid] then
      seen[guid]=true
      local actions=self:NearbyActions(entry)
      local name=A.Call(UnitName,unit)
      if #actions>0 and A.Text(name) then
        out[#out+1]={unit=unit,guid=guid,name=name,surname=B:NearbySurname(unit),class=entry.class,actions=actions,order=self.nearbyOrder[guid] or 0}
      end
    end
  end
  -- Players who need a cleanse come first.
  table.sort(out,function(a,b)
    local ac,bc=a.actions[1].source=="cleanse",b.actions[1].source=="cleanse"
    if ac~=bc then return ac end
    if a.order==b.order then return a.guid<b.guid end return a.order<b.order
  end)
  self.nearbySnapshot=out
  return out
end
function B:NearbyGroupActions(unit)
  if self.db.nearbyBuffing==false or not self:GroupPreference("group") or not self:NearbyRecipientSafe(unit) then return {} end
  local entry
  local guid=A.Call(UnitGUID,unit)
  for _,member in ipairs(self:Roster()) do
    if member.unit~="player" and A.Call(UnitGUID,member.unit)==guid then entry=member; break end
  end
  if not entry then return {} end
  local actions,scans,errors={},{},{}
  local plan=self:BlessingAssignmentsActive()
  local blessingOwned=false
  for _,def in ipairs(self:ClassList()) do
    if not def.singleKey and (def.kind=="single" or def.kind=="blessing")
      and (self:Enabled(def) or (plan and def.kind=="blessing")) and self:Supported(def)
      and ((plan and def.kind=="blessing" and self:BlessingGroupAllowed(entry)) or self:GroupSelected(def,entry.group))
      and not (def.kind=="blessing" and self.db.blessingPartyExcluded and self:BlessingContext()=="Party")
      and not (def.kind=="blessing" and blessingOwned) then
      local missing=self:ScanMissing(def,{entry},scans,errors)
      if missing[1] then
        local need=missing[1]; local action=need.action
        action.blessingAssigned=plan and def.kind=="blessing" or nil
        local valid,why=self:Validate(action)
        action.ready=valid==true; action.waiting=why=="cooldown / global cooldown"
        if valid or action.waiting then
          action.nearbyGroup=true; action.needState=need.reason; action.remaining=need.remaining; action.threshold=need.threshold
          actions[#actions+1]=action
        end
        if def.kind=="blessing" then blessingOwned=true end
      elseif def.kind=="blessing" and scans[entry.unit] then
        local current=self:Resolve(def,entry.unit)
        if current and not self:Missing(def,current,scans[entry.unit]) then blessingOwned=true end
      end
      if #actions==4 then break end
    end
  end
  return actions
end
-- The display can retain players without turning them into eligible buff targets.
-- Status marker for a stranger: blacklisted, or PvP flagged while you are not (buffing them
-- would flag you). An unreadable flag only matters while PvP protection is on.
function B:NearbyMarker(unit)
  if self.BlockReason and self:BlockReason(unit) then return "blocked" end
  if A.Call(UnitIsPVP,"player")==true then return nil end
  local pvp,ffa=A.Call(UnitIsPVP,unit),A.Call(UnitIsPVPFreeForAll,unit)
  if pvp==true or ffa==true then return "pvp" end
  if self.db.pvpProtection==true and (pvp==nil or ffa==nil) then return "pvp-unknown" end
end
-- Friend (character or Battle.net) or member of your guild. Information only: it changes nothing about buffing.
function B:NearbySocial(unit,guid)
  if self.db.nearbyMarkSocial==false then return nil end
  if A.Text(guid) then
    if C_FriendList and A.Call(C_FriendList.IsFriend,guid)==true then return "friend" end
    if C_BattleNet and type(A.Call(C_BattleNet.GetAccountInfoByGUID,guid))=="table" then return "friend" end
  end
  if type(UnitIsInMyGuild)=="function" then
    if A.Call(UnitIsInMyGuild,unit)==true then return "guild" end
  else
    local mine,theirs=A.Call(GetGuildInfo,"player"),A.Call(GetGuildInfo,unit)
    if A.Text(mine) and mine~="" and mine==theirs then return "guild" end
  end
end
-- Name-field tags, right-aligned next to the buff column: {texture, r, g, b, alpha}.
local MARKERS={pvp={"UIPvPFlag",.9,.36,.32,1},["pvp-unknown"]={"UIPvPFlag",.6,.6,.6,.55},blocked={"NavBlacklist",.95,.25,.22,1},
  friend={"UIFriend",.42,.72,1,1},guild={"UIGuild",.35,.9,.42,1}}
B.NearbyTagStyles=MARKERS
-- All players view while resting or mounted: the list stays up for invites and requests,
-- while buffing itself stays paused (NearbyCandidates still returns nothing).
-- "Buff while resting": Nearby ignores the resting pause (other pauses still apply).
function B:NearbyPauseReason()
  local reason=self:ReminderPauseReason()
  if reason=="resting" and self.db and self.db.nearbyWhileResting==true then return nil end
  return reason
end
-- "Hold back short buffs": in cities and inns, Nearby does not offer buffs of ten minutes or
-- less (Thorns, single blessings); they would wear off before they mattered.
function B:NearbyHoldsShort()
  return self.db and self.db.nearbyHoldShort==true and A.Call(IsResting)==true
end
function B:NearbyBrowsePause()
  if not self.db or not self.db.nearbyShowAll then return nil end
  local reason=self:NearbyPauseReason()
  if reason=="resting" or reason=="mounted" then return reason end
end
function B:NearbyPlayers()
  local buffs=self:NearbyCandidates()
  local out,seen,byGUID={},{},{}
  self.nearbyCounts={need=0,total=0,flagged=0,blocked=0}
  for _,entry in ipairs(buffs) do byGUID[entry.guid]=entry end
  if not self.db.enabled or not self.db.nearbyEnabled or not platesOn() or A.Combat()
    or (self:NearbyPauseReason() and not self:NearbyBrowsePause()) then return out end
  for unit,guid in pairs(self.nearbyUnits or {}) do
    if A.Text(guid) and not seen[guid] and A.Call(UnitGUID,unit)==guid
      and A.Call(UnitExists,unit)==true and A.Call(UnitCanAssist,"player",unit)==true
      and A.Call(UnitIsUnit,unit,"player")==false then
      local name=A.Call(UnitName,unit)
      local class=A.Class(unit)
      if A.Text(name) and A.Text(class) then
        seen[guid]=true; self.nearbyCounts.total=self.nearbyCounts.total+1
        local grouped=self:NearbyGroupMember(unit)
        local groupActions=grouped and self:NearbyGroupActions(unit) or {}
        local entry=byGUID[guid] or {unit=unit,guid=guid,name=name,surname=B:NearbySurname(unit),class=class,actions=groupActions,order=self.nearbyOrder[guid] or 0}
        entry.surname=entry.surname or B:NearbySurname(unit)
        entry.marker=not grouped and self:NearbyMarker(unit) or nil
        entry.social=self:NearbySocial(unit,guid)
        if entry.marker=="blocked" then self.nearbyCounts.blocked=self.nearbyCounts.blocked+1
        elseif entry.marker and self.db.pvpProtection==true then self.nearbyCounts.flagged=self.nearbyCounts.flagged+1 end
        local needs=#entry.actions>0
        if needs then self.nearbyCounts.need=self.nearbyCounts.need+1 end
        if needs or (self.db.nearbyShowAll and not grouped) then out[#out+1]=entry end
      end
    end
  end
  -- Players with nothing needed: friends and guild members first, so they stay in the visible rows.
  -- Tiers: needs a cleanse, needs a buff, then friends and guild members, then everyone else.
  local function tier(e) return e.actions[1] and e.actions[1].source=="cleanse" and 0 or #e.actions>0 and 1 or e.social~=nil and 2 or 3 end
  table.sort(out,function(a,b)
    local at,bt=tier(a),tier(b)
    if at~=bt then return at<bt end
    if a.order==b.order then return a.guid<b.guid end return a.order<b.order
  end)
  return out
end
function B:SetNearbyView(showAll)
  if A.Combat() then return end
  if GameTooltip then GameTooltip:Hide() end
  self.db.nearbyShowAll=showAll==true
  self.nearbyDisplay=nil; self.nearbyHovered=nil; self.nearbyOffset=0
  self:UpdateNearbyWindow()
end
function B:NearbyInviteName(entry)
  if A.Combat() or not self.db.enabled or not self.db.nearbyEnabled 
    or self.db.nearbyInvites==false or not entry or not platesOn() then return nil end
  local unit=entry.unit
  if not self.nearbyUnits or self.nearbyUnits[unit]~=entry.guid or A.Call(UnitGUID,unit)~=entry.guid
    or A.Call(UnitExists,unit)~=true or A.Call(UnitCanAssist,"player",unit)~=true
    or self:NearbyGroupMember(unit) then return nil end
  -- Request to join: the client's own invite logic decides (the same check as its right-click menu).
  -- UnitInAnyGroup is not reliable for players outside your group, so it is not used for this case.
  local displayed=A.Call(GetDisplayedInviteType,entry.guid)
  if displayed=="REQUEST_INVITE" or ((displayed==nil or displayed=="INVITE") and A.Call(IsInGroup)~=true and A.Call(UnitInAnyGroup,unit)==true) then
    if A.Call(IsInGroup)==true or not self:RequestInviteAPI() then return nil end
    return self:NearbyCastName({target=unit,targetGUID=entry.guid}),"REQUEST_INVITE"
  end
  if A.Call(UnitInAnyGroup,unit)==true then return nil end
  local raid=A.Call(IsInRaid)==true
  local count=A.Call(raid and GetNumGroupMembers or GetNumSubgroupMembers)
  if not A.Number(count) or count>=(raid and 40 or 4) then return nil end
  local mode=A.Call(GetDisplayedInviteType,entry.guid)
  if not A.Text(mode) then mode=nil end
  if mode~="INVITE" and mode~="SUGGEST_INVITE" then
    if type(GetDisplayedInviteType)=="function" then return nil end
    if (raid or count>0) and A.Call(UnitIsGroupLeader,"player")~=true
      and A.Call(UnitIsGroupAssistant,"player")~=true then return nil end
    mode="INVITE"
  end
  if type(C_PartyInfo and C_PartyInfo.InviteUnit)~="function" then return nil end
  local name=self:NearbyCastName({target=unit,targetGUID=entry.guid})
  return name,mode
end
-- ---------- Buff requests ----------
-- Offers a whisper to a nearby player outside your group whose class can provide a class buff you are
-- missing. Never automatic: each whisper is one click, with a per-player cooldown.
local REQUEST_COOLDOWN=180
local blessingOrder={bok=1,bom=2,bow=3}
function B:RequestBuffChoices()
  local list={}
  for _,def in ipairs(self:CoverageDefinitions()) do list[#list+1]=def end
  return list
end
function B:RequestableBuffs(entry)
  if not self.db.nearbyRequests or not self.db.enabled or not self.db.nearbyEnabled or A.Combat() or not entry or not A.Text(entry.class) then return nil end
  if self:NearbyGroupMember(entry.unit) or A.Call(UnitIsUnit,entry.unit,"player")==true then return nil end
  local myClass=A.Class("player"); if not myClass or entry.class==myClass then return nil end
  local scan=self:GetAuras("player",false); if not scan then return nil end
  local list,blessing,hasBlessing={},nil,nil
  for _,def in ipairs(self:CoverageDefinitions()) do
    if def.class==entry.class and self:RequestEnabled(def) then
      local eligible=true
      if def.target and self.db.requestBuffs[def.key]~=true then eligible=false; for _,class in ipairs(def.target) do if class==myClass then eligible=true end end end
      if eligible then
        if def.kind=="blessing" then
          if hasBlessing==nil then
            hasBlessing=false
            for _,other in ipairs(self.Buffs) do
              if other.kind=="blessing" and not other.singleKey and not self:Missing(other,{id=other.ranks[#other.ranks],name=other.name},scan,0) then hasBlessing=true; break end
            end
          end
          -- One blessing per request: a paladin gives each player one of theirs.
          if not hasBlessing and (not blessing or (blessingOrder[def.key] or 9)<(blessingOrder[blessing.key] or 9)) then blessing=def end
        elseif self:Missing(def,{id=def.ranks[#def.ranks],name=def.name},scan,0) then list[#list+1]=def end
      end
    end
  end
  if blessing then list[#list+1]=blessing end
  return #list>0 and list or nil
end
function B:BuffRequestText(list)
  local names={}
  for _,def in ipairs(list) do names[#names+1]=A.Call(C_Spell and C_Spell.GetSpellName,def.ranks[#def.ranks]) or def.name end
  local joined=table.concat(names,", ")
  local template=A.Text(self.db.requestMessage) and self.db.requestMessage~="" and self.db.requestMessage or self:Text("Hi! Could I get %s, please? Thank you!")
  template=template:gsub("[|%c]","")
  local message
  if template:find("%%s") then message=template:gsub("%%s",function() return joined end,1) else message=template.." ("..joined..")" end
  return message:sub(1,250)
end
function B:RequestBuffFrom(entry)
  if A.Combat() or not entry then return false end
  local list=self:RequestableBuffs(entry); if not list then return false end
  self.nearbyRequested=self.nearbyRequested or {}
  local at=self.nearbyRequested[entry.guid]; if at and GetTime()-at<REQUEST_COOLDOWN then return false end
  if C_ChatInfo and type(C_ChatInfo.InChatMessagingLockdown)=="function" and A.Call(C_ChatInfo.InChatMessagingLockdown)==true then return false end
  local name=self:NearbyCastName({target=entry.unit,targetGUID=entry.guid})
  if not A.Text(name) or type(SendChatMessage)~="function" then return false end
  local ok=pcall(SendChatMessage,self:BuffRequestText(list),"WHISPER",nil,name)
  if not ok then return false end
  self.nearbyRequested[entry.guid]=GetTime()
  self:UpdateNearbyWindow()
  return true
end
function B:RequestCooling(entry)
  local at=entry and self.nearbyRequested and self.nearbyRequested[entry.guid]
  return at and GetTime()-at<REQUEST_COOLDOWN or false
end

function B:RequestInviteAPI()
  local fn=C_PartyInfo and C_PartyInfo.RequestInviteFromUnit
  if type(fn)~="function" then fn=RequestInviteFromUnit end
  return type(fn)=="function" and fn or nil
end
function B:InviteNearby(entry)
  local name,mode=self:NearbyInviteName(entry)
  if not name then return false end
  self.nearbyInvited=self.nearbyInvited or {}
  local at=self.nearbyInvited[entry.guid]
  if at and GetTime()-at<10 then return false end
  -- Only a deliberate button click calls these APIs; never scans or timers.
  local ok,result
  if mode=="REQUEST_INVITE" then ok,result=pcall(self:RequestInviteAPI(),name)
  else ok,result=pcall(C_PartyInfo.InviteUnit,name) end
  if not ok or result==false then self.Print("The group invitation could not be requested."); return false end
  self.nearbyInvited[entry.guid]=GetTime(); self.nearbyLastInvite=mode..": "..name
  self:UpdateNearbyWindow()
  return true
end
function B:SelectNearby()
  for _,entry in ipairs(self:NearbyCandidates()) do
    local action=nextAction(entry,true); if action then return action end
  end
end
function B:TrackNearby(unit)
  if not A.Text(unit) or not unit:match("^nameplate%d+$") then return end
  if A.Call(UnitCanAssist,"player",unit)~=true then return end
  local guid=A.Call(UnitGUID,unit)
  if not A.Text(guid) or not guid:match("^Player%-") then return end
  local count=0; for _ in pairs(self.nearbyUnits) do count=count+1 end
  if not self.nearbyUnits[unit] and count>=MAX_UNITS then return end
  self.nearbyUnits[unit]=guid
  if not self.nearbyOrder[guid] then
    local total,oldest,serial=0
    for key,value in pairs(self.nearbyOrder) do
      total=total+1
      local active=false; for _,current in pairs(self.nearbyUnits) do if current==key then active=true; break end end
      if not active and (not serial or value<serial) then oldest,serial=key,value end
    end
    if total>=128 and oldest then self.nearbyOrder[oldest]=nil end
    self.nearbySerial=(self.nearbySerial or 0)+1; self.nearbyOrder[guid]=self.nearbySerial
  end
end
function B:SyncNearby()
  local enabled=self.db and self.db.nearbyEnabled==true
  if enabled==self.nearbyRegistered then return end
  self.nearbyRegistered=enabled
  self.nearbyDisplay=nil; self.nearbyHovered=nil; self:CancelTimer("nearby-display")
  self.buffCastAttempt=nil; self.buffAuraFresh=nil
  for _,slot in ipairs({"buff-aura-early","buff-aura-settle","buff-aura-late"}) do self:CancelTimer(slot) end
  self.nearbyNeedCache={}; self.nearbyNeedSettings=nil
  self.nearbyUnits={}; self.nearbyOrder={}; self.nearbySnapshot=nil; self.nearbyOffset=0; self.nearbyInvited={}; self.nearbyCounts={need=0,total=0}
  self:CancelTimer("nearby-settle"); self:CancelTimer("nearby-late")
  for _,event in ipairs({"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","CVAR_UPDATE","UI_ERROR_MESSAGE","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_FAILED"}) do
    if enabled then pcall(self.nearbyEvents.RegisterEvent,self.nearbyEvents,event)
    else pcall(self.nearbyEvents.UnregisterEvent,self.nearbyEvents,event) end
  end
  if enabled and not A.Combat() then self:SeedNearby(); self:ScheduleNearbySettle() end
end
function B:ScheduleNearbySettle()
  if A.Combat() or not self.db.nearbyEnabled then return end
  for _,value in ipairs({{"nearby-settle",.25},{"nearby-late",.9}}) do
    self:StartTimer(value[1],value[2],function()
      if not B.db.nearbyEnabled or A.Combat() then return end
      B:SeedNearby(); B.nearbySnapshot=nil; B:RequestRefresh("nearby data settled",.03)
    end)
  end
end
function B:SeedNearby(skipUnit)
  if not self.db.nearbyEnabled then return end
  local plates=A.Call(C_NamePlate and C_NamePlate.GetNamePlates)
  if type(plates)=="table" then
    for _,plate in ipairs(plates) do
      local unit=plate.namePlateUnitToken or A.Call(function() return plate:GetUnit() end)
      if unit~=skipUnit then self:TrackNearby(unit) end
    end
  end
end
function B:ValidateNearby(action)
  if action and action.nearbyGroup then
    if A.Combat() or not self.db.enabled or not self.db.nearbyEnabled 
      or self.db.nearbyBuffing==false or not platesOn() or self:NearbyPauseReason() then return false end
    local unit
    for token,guid in pairs(self.nearbyUnits or {}) do if guid==action.targetGUID and A.Call(UnitGUID,token)==guid then unit=token; break end end
    if not unit or not self:NearbyGroupMember(unit) then return false end
    self:InvalidateAura(action.target)
    local fresh=nextAction({actions=self:NearbyGroupActions(unit)},true)
    return fresh and fresh.id==action.id and fresh.targetGUID==action.targetGUID and self:Validate(action)==true
  end
  if not action or A.Combat() or not self.db.enabled or not self.db.nearbyEnabled
    or not platesOn() or self:NearbyPauseReason() then return false end
  local entry=self:NearbyEntry(action.target)
  if not entry or A.Call(UnitGUID,action.target)~=action.targetGUID then return false end
  self:InvalidateAura(action.target)
  local fresh=nextAction({actions=self:NearbyActions(entry)},true)
  return fresh and fresh.id==action.id and fresh.targetGUID==action.targetGUID
    and not self:HelperSuppressed(action) and self:Validate(action)==true
end

local function label(parent,text,x,y,font)
  local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  f:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",11,"")
  f:SetShadowColor(0,0,0,.95); f:SetShadowOffset(1,-1)
  f:SetPoint("TOPLEFT",x,y); f:SetText(text); return f
end
local function wash(parent,layer,r,g,b,a)
  local t=parent:CreateTexture(nil,layer or "BACKGROUND")
  t:SetColorTexture(r,g,b,a); return t
end
local function hint(button,title,body)
  button:SetScript("OnEnter",function()
    GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetText(title())
    if body then GameTooltip:AddLine(body,.8,.8,.8,true) end; GameTooltip:Show()
  end)
  button:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
function B:NearbyDisplayList(list)
  local now,fresh,seen,out=GetTime(),{},{},{}
  for _,entry in ipairs(list) do fresh[entry.guid]=entry end
  local pending,safetyRemoved
  for _,old in ipairs(self.nearbyDisplay or {}) do
    local entry=fresh[old.entry.guid]
    local missing=not entry and (old.missingAt or now)
    local delayed=false
    if not entry and self.CastRetryBlocked then
      for _,action in ipairs(old.entry.actions) do if self:CastRetryBlocked(action) then delayed=true; break end end
    end
    local safe=A.Call(UnitGUID,old.entry.unit)==old.entry.guid and self.nearbyUnits[old.entry.unit]==old.entry.guid
      and A.Call(UnitCanAssist,"player",old.entry.unit)==true
      and (self.db.nearbyShowAll or (not delayed and self:NearbyRecipientSafe(old.entry.unit)))
      and not (self.db.nearbyShowAll and self:NearbyGroupMember(old.entry.unit) and not entry)
    if not safe then
      safetyRemoved=true
      if self.nearbyHovered==old.entry.guid then self.nearbyHovered=nil; if GameTooltip then GameTooltip:Hide() end end
    elseif entry or self.nearbyHovered or (missing and now-missing<.65) or self:NearbyResultFor(old.entry.guid) then
      out[#out+1]={entry=entry or old.entry,fresh=entry~=nil,missingAt=missing}
      seen[old.entry.guid]=true
      if missing and now-missing<.65 then pending=math.min(pending or .65,.65-(now-missing)) end
    end
  end
  if not self.nearbyHovered or safetyRemoved then
    for _,entry in ipairs(list) do
      if not seen[entry.guid] and #out<MAX_UNITS then out[#out+1]={entry=entry,fresh=true}; seen[entry.guid]=true end
    end
  end
  if not self.nearbyHovered and self.db.nearbyShowAll then
    table.sort(out,function(a,b)
      local an=a.fresh and #a.entry.actions>0 or false
      local bn=b.fresh and #b.entry.actions>0 or false
      if an~=bn then return an end
      local ac=an and a.entry.actions[1].source=="cleanse"
      local bc=bn and b.entry.actions[1].source=="cleanse"
      if ac~=bc then return ac end
      -- Among players with nothing needed, friends and guild members come first.
      if not an then
        local as,bs=a.entry.social~=nil,b.entry.social~=nil
        if as~=bs then return as end
      end
      if a.entry.order~=b.entry.order then return a.entry.order<b.entry.order end
      return a.entry.guid<b.entry.guid
    end)
  end
  self.nearbyDisplay=out
  self:CancelTimer("nearby-display")
  if pending then self:StartTimer("nearby-display",math.max(.03,pending+.02),function() if not A.Combat() then B:UpdateNearbyWindow() end end) end
  return out
end
function B:SetNearbyRowPayload(row,action)
  if action and action.situationRevision==nil then action.situationRevision=self.situationRevision or 0 end
  local ready=action and action.ready~=false
  local macro=ready and action.macroText or nil
  local spell=ready and action.nearbyGroup and action.id or nil
  local unit=spell and action.target or nil
  local kind=macro and "macro" or spell and "spell" or nil
  if row:GetAttribute("type1")==kind and row:GetAttribute("macrotext")==macro
    and row:GetAttribute("spell")==spell and row:GetAttribute("unit")==unit then return end
  row:SetAttribute("type1",nil); row:SetAttribute("macrotext",macro); row:SetAttribute("spell",spell); row:SetAttribute("unit",unit)
  if kind then row:SetAttribute("type1",kind) end
end
-- Nearby is scaled, so its GetCenter and SetPoint offsets are in its own units while
-- UIParent's centre is in UI units. Save the offset in UI units and convert when anchoring,
-- otherwise a scaled window jumps away from where it was dropped.
local function relativeScale(f)
  local fs=type(f.GetEffectiveScale)=="function" and f:GetEffectiveScale() or 1
  local us=type(UIParent.GetEffectiveScale)=="function" and UIParent:GetEffectiveScale() or 1
  if not A.Number(fs) or not A.Number(us) or fs<=0 or us<=0 then return 1,1 end
  return fs/us,us
end
function B:NearbyCenterOffset(f)
  local x,y=f:GetCenter(); local px,py=UIParent:GetCenter()
  if not (A.Number(x) and A.Number(y) and A.Number(px) and A.Number(py)) then return end
  local r=relativeScale(f)
  return x*r-px,y*r-py
end
function B:PlaceNearbyFrame(f,x,y)
  local r=relativeScale(f)
  f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",x/r,y/r)
end
function B:CreateNearbyWindow()
  if self.nearbyFrame or A.Combat() then return end
  if type(RegisterStateDriver)~="function" then self.nearbySetupError="Secure combat visibility is unavailable"; return end
  local f=CreateFrame("Frame","BuffTapNearbyWindow",UIParent,"SecureHandlerStateTemplate")
  self.nearbyFrame=f; f:SetSize(WIDTH+24,HEIGHT); f:SetFrameStrata("LOW"); f:SetClampedToScreen(true); f:SetFrameLevel(120)
  f:SetMovable(true); f:EnableMouse(false); f:RegisterForDrag("LeftButton")
  local c=CreateFrame("Frame",nil,f); f.content=c; c:SetSize(WIDTH,HEIGHT); c:SetPoint("TOPLEFT",24,0); c:EnableMouse(false)
  f.header=wash(c,"BACKGROUND",.055,.07,.09,.50); f.header:SetPoint("TOPLEFT"); f.header:SetWidth(WIDTH); f.header:SetHeight(21)
  f.line=wash(c,"BORDER",.72,.58,.25,.80); f.line:SetPoint("TOPLEFT",0,-21); f.line:SetWidth(WIDTH); f.line:SetHeight(1)
  f.title=label(c,"BuffTap",5,-5); f.title:SetTextColor(1,.82,0)
  f.count=label(c,"0/0",69,-5); f.count:SetWidth(75); f.count:SetJustifyH("RIGHT"); f.count:SetTextColor(.82,.82,.79)
  f.lock=CreateFrame("Button",nil,c); f.lock:SetSize(12,15); f.lock:SetPoint("TOPLEFT",176,-3)
  f.lock.body=wash(f.lock,"ARTWORK",.8,.8,.76,1); f.lock.body:SetSize(8,6); f.lock.body:SetPoint("BOTTOM",0,2)
  f.lock.key=wash(f.lock,"OVERLAY",.10,.12,.15,1); f.lock.key:SetSize(1,3); f.lock.key:SetPoint("BOTTOM",0,3)
  f.lock.shackle={}
  for i,point in ipairs({{-3,2,1,5},{3,2,1,5},{0,4.5,7,1}}) do
    local t=wash(f.lock,"ARTWORK",.8,.8,.76,1); t:SetSize(point[3],point[4]); t:SetPoint("CENTER",point[1],point[2]); f.lock.shackle[i]=t
  end
  f.lock:SetScript("OnClick",function() if not A.Combat() then self.db.nearbyLocked=not self.db.nearbyLocked; self:UpdateNearbyWindow() end end)
  hint(f.lock,function() return self.db.nearbyLocked and "Unlock position" or "Lock position" end,"Drag the header to move. Shift-left-click the minimap icon to toggle Nearby.")
  f.close=CreateFrame("Button",nil,c); f.close:SetSize(14,16); f.close:SetPoint("TOPLEFT",193,-3)
  f.close.text=label(f.close,"x",3,-1); f.close.text:SetTextColor(.78,.78,.75)
  f.close:SetScript("OnClick",function()
    if A.Combat() then return end
    self.db.nearbyEnabled=false; self.nearbyUserOpened=false; self:SyncNearby(); f:Hide(); self:RequestRefresh("nearby closed",0)
  end)
  hint(f.close,function() return "Disable Nearby" end,"Shift-left-click the minimap icon to enable it again.")
  f.countHelp=CreateFrame("Button",nil,c); f.countHelp:SetSize(79,18); f.countHelp:SetPoint("TOPLEFT",65,-2)
  f.countHelp:SetFrameLevel(f:GetFrameLevel()+3)
  hint(f.countHelp,function()
    local n=self.nearbyCounts or {need=0,total=0}
    return n.need.." players with buffs queued / "..n.total.." nearby"
  end,"Counts friendly players currently detected, up to 40. Buff candidates appear first. Group members with no queued buff stay hidden. Mouse wheel over this window scrolls the list.")
  f.allPlayers=CreateFrame("Button",nil,c)
  f.allPlayers:SetFrameLevel(f:GetFrameLevel()+3)
  f.allPlayers:SetSize(14,16); f.allPlayers:SetPoint("TOPLEFT",154,-3)
  f.allPlayers.parts={}
  -- Two round-headed figures, tinted grey (buff candidates only) or gold (all players).
  local people=f.allPlayers:CreateTexture(nil,"ARTWORK"); people:SetSize(15,15); people:SetPoint("CENTER",0,0)
  people:SetTexture("Interface\\AddOns\\BuffTap\\Media\\UIPeople"); people:SetVertexColor(.65,.65,.62,1)
  f.allPlayers.parts[1]=people
  f.allPlayers:SetScript("OnClick",function() self:SetNearbyView(not self.db.nearbyShowAll) end)
  hint(f.allPlayers,function() return self.db.nearbyShowAll and "Show only players needing buffs" or "Show all nearby players" end,"Grey: buff candidates only. Gold: all observed strangers. Invite buttons are available in either view.")
  f.status=label(c,"",6,-31); f.status:SetWidth(198); f.status:SetJustifyH("LEFT"); f.status:SetWordWrap(true)
  f.statusButton=CreateFrame("Button",nil,c); f.statusButton:SetPoint("TOPLEFT",4,-25); f.statusButton:SetSize(198,34)
  hint(f.statusButton,function() return "Nearby buffing" end,"Uses your Target preferences. Friendly player nameplates must be enabled (Shift+V). Shift-click the minimap icon to toggle. Players in combat are skipped; PvP protection skips flagged or unreadable players.")
  f.statusButton:SetScript("OnClick",function() if not self.db.nearbyEnabled then self:ToggleNearby() end end)
  local function dragStart() if not A.Combat() and not self.db.nearbyLocked then self.nearbyDragging=true; f:StartMoving() end end
  local function dragStop()
    if A.Combat() then return end
    f:StopMovingOrSizing(); self.nearbyDragging=false
    if type(f.SetUserPlaced)=="function" then f:SetUserPlaced(false) end
    local x,y=self:NearbyCenterOffset(f)
    if x then self.db.nearbyX=x; self.db.nearbyY=y end
    f.positionX=nil
    self:UpdateNearbyWindow()
  end
  f:SetScript("OnDragStart",dragStart); f:SetScript("OnDragStop",dragStop)
  f.dragHandle=CreateFrame("Frame",nil,c); f.dragHandle:SetSize(WIDTH-43,21); f.dragHandle:SetPoint("TOPLEFT")
  f.dragHandle:EnableMouse(true); f.dragHandle:RegisterForDrag("LeftButton")
  f.dragHandle:SetScript("OnDragStart",dragStart); f.dragHandle:SetScript("OnDragStop",dragStop)
  local function scrollPlayers(surface,delta)
    if A.Combat() or not A.Number(delta) or delta==0 then return end
    self.nearbyHovered=nil; GameTooltip:Hide()
    local step=delta>0 and math.ceil(delta) or math.floor(delta)
    self.nearbyOffset=math.max(0,math.min(math.max(0,#(self.nearbyDisplay or {})-ROWS),(self.nearbyOffset or 0)-step))
    self:UpdateNearbyWindow()
    if surface and surface.entry then self.nearbyHovered=surface.entry.guid end
  end
  local function wheelSurface(surface)
    surface:EnableMouseWheel(true); surface:SetScript("OnMouseWheel",scrollPlayers)
    if type(surface.SetPropagateMouseWheel)=="function" then surface:SetPropagateMouseWheel(false) end
  end
  wheelSurface(f)

  f.scroll=CreateFrame("Slider",nil,c); f.scroll:SetSize(4,103); f.scroll:SetPoint("TOPLEFT",205,-25)
  f.scroll:SetOrientation("VERTICAL"); f.scroll:SetValueStep(1); f.scroll:SetObeyStepOnDrag(true)
  f.scroll.track=wash(f.scroll,"BACKGROUND",.5,.51,.49,.16); f.scroll.track:SetAllPoints()
  f.scroll.thumb=wash(f.scroll,"ARTWORK",.67,.68,.65,.65); f.scroll.thumb:SetSize(4,22); f.scroll:SetThumbTexture(f.scroll.thumb)
  f.scroll:SetScript("OnValueChanged",function(_,value)
    if A.Combat() or not A.Number(value) then return end
    local offset=math.floor(value+.5)
    if self.nearbyOffset~=offset then self.nearbyOffset=offset; self:UpdateNearbyWindow() end
  end)
  f.rows={}
  for i=1,MAX_UNITS do
    local row=CreateFrame("Button","BuffTapNearbyRow"..i,c,"SecureActionButtonTemplate")
    f.rows[i]=row; row:SetSize(WIDTH,20); row:SetPoint("TOPLEFT",0,-25-(i-1)*ROW_HEIGHT)
    row:RegisterForClicks("AnyDown","AnyUp"); row:SetAttribute("useOnKeyDown",true)
    -- Combat safety: clear the row's cast the moment combat starts, so the Nearby key (an
    -- override binding that can click a hidden button) can never cast a stale buff in combat.
    row:SetAttribute("_onstate-nearbysafety",[[if newstate=="blocked" then self:SetAttribute("type1",nil); self:SetAttribute("macrotext",nil); self:SetAttribute("spell",nil); self:SetAttribute("unit",nil) end]])
    if type(RegisterStateDriver)=="function" then pcall(RegisterStateDriver,row,"nearbysafety","[combat] blocked; ready") end
    row.wash=wash(row,"BACKGROUND",.055,.075,.095,.34); row.wash:SetAllPoints()
    row.hover=wash(row,"HIGHLIGHT",.75,.60,.25,.17); row.hover:SetAllPoints()
    row.marker=wash(row,"BACKGROUND",.75,.60,.25,.075); row.marker:SetAllPoints()
    -- A player who needs a cleanse: faint tint and a bar on the left, in the debuff's colour.
    row.cleanseTint=wash(row,"BACKGROUND",.6,0,1,.15); row.cleanseTint:SetAllPoints(); row.cleanseTint:Hide()
    row.cleanseBar=wash(row,"BORDER",.6,0,1,1); row.cleanseBar:SetPoint("TOPLEFT",0,0); row.cleanseBar:SetPoint("BOTTOMLEFT",0,0); row.cleanseBar:SetWidth(2); row.cleanseBar:Hide()
    row.classEdge=wash(row,"BORDER",.55,.47,.30,.70); row.classEdge:SetSize(16,16); row.classEdge:SetPoint("LEFT",4,0)
    row.classIcon=row:CreateTexture(nil,"ARTWORK"); row.classIcon:SetSize(14,14); row.classIcon:SetPoint("LEFT",5,0)
    row.name=label(row,"",26,-4); row.name:SetWidth(132); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
    -- "Nothing needed" dash, centred in the first buff slot like the icons.
    row.idle=row:CreateTexture(nil,"ARTWORK"); row.idle:SetTexture("Interface\\AddOns\\BuffTap\\Media\\UIDash"); row.idle:SetSize(10,10); row.idle:SetVertexColor(.55,.62,.59); row.idle:Hide()
    row.invite=CreateFrame("Button",nil,row)
    row.invite:SetSize(20,20); row.invite:SetPoint("RIGHT",row,"LEFT",-4,0)
    row.invite.bg=wash(row.invite,"BACKGROUND",.055,.075,.095,.65); row.invite.bg:SetAllPoints()
    row.invite.hover=wash(row.invite,"HIGHLIGHT",.75,.60,.25,.25); row.invite.hover:SetAllPoints()
    row.invite.text=label(row.invite,"+",0,0); row.invite.text:ClearAllPoints(); row.invite.text:SetAllPoints(row.invite); row.invite.text:SetJustifyH("CENTER"); row.invite.text:SetJustifyV("MIDDLE"); row.invite.text:SetWordWrap(false); row.invite.text:SetTextColor(1,.82,0)
    -- Smooth icons (white art, tinted): a gold plus to invite and a blue arrow to ask to join.
    row.invite.plus=row.invite:CreateTexture(nil,"OVERLAY"); row.invite.plus:SetTexture("Interface\\AddOns\\BuffTap\\Media\\UIInvitePlus")
    row.invite.plus:SetSize(16,16); row.invite.plus:SetPoint("CENTER",row.invite,"CENTER",0,0); row.invite.plus:SetVertexColor(1,.82,0)
    row.invite.arrow=row.invite:CreateTexture(nil,"OVERLAY"); row.invite.arrow:SetTexture("Interface\\AddOns\\BuffTap\\Media\\UIJoinArrow")
    row.invite.arrow:SetSize(16,16); row.invite.arrow:SetPoint("CENTER",row.invite,"CENTER",0,0); row.invite.arrow:SetVertexColor(.35,.75,1)
    row.invite:RegisterForClicks("LeftButtonUp")
    row.invite:SetScript("OnClick",function() self:InviteNearby(row.entry) end)
    -- Buff request: shows the buff's own icon so it reads differently from the invite "+".
    row.request=CreateFrame("Button",nil,row); row.request:SetSize(20,20); row.request:Hide()
    row.request.bg=wash(row.request,"BACKGROUND",.40,.82,.90,.55); row.request.bg:SetAllPoints()
    row.request.icon=row.request:CreateTexture(nil,"ARTWORK"); row.request.icon:SetPoint("TOPLEFT",1,-1); row.request.icon:SetPoint("BOTTOMRIGHT",-1,1); row.request.icon:SetTexCoord(.08,.92,.08,.92)
    row.request.hover=wash(row.request,"HIGHLIGHT",1,1,1,.18); row.request.hover:SetAllPoints()
    row.request:RegisterForClicks("LeftButtonUp")
    row.request:SetScript("OnClick",function() self:RequestBuffFrom(row.entry) end)
    row.request:SetScript("OnEnter",function()
      if not row.entry then return end
      self.nearbyHovered=row.entry.guid
      local list=self:RequestableBuffs(row.entry)
      GameTooltip:SetOwner(row.request,"ANCHOR_RIGHT")
      GameTooltip:SetText(B:Text("Ask %s for a buff",row.entry.name),1,1,1)
      if list then GameTooltip:AddLine(self:BuffRequestText(list),.80,.82,.86,true) end
      GameTooltip:AddLine(self:RequestCooling(row.entry) and B:Text("Request sent. You can ask this player again in a few minutes.") or B:Text("Click to whisper this request. Nothing is sent automatically."),.55,.58,.64,true)
      GameTooltip:Show()
    end)
    row.request:SetScript("OnLeave",function()
      self.nearbyHovered=nil; GameTooltip:Hide()
      self:CancelTimer("nearby-display")
      self:StartTimer("nearby-display",.1,function() if not A.Combat() then B:UpdateNearbyWindow() end end)
    end)
    row.invite:SetScript("OnEnter",function()
      if not row.entry then return end
      self.nearbyHovered=row.entry.guid
      local _,mode=self:NearbyInviteName(row.entry)
      GameTooltip:SetOwner(row.invite,"ANCHOR_RIGHT")
      if mode=="REQUEST_INVITE" then
        GameTooltip:SetText(B:Text("Request to join %s's group",row.entry.name))
        GameTooltip:AddLine(B:Text("Click to ask to join this player's group. The group leader decides."),.80,.82,.86,true); GameTooltip:Show(); return
      end
      GameTooltip:SetText((mode=="SUGGEST_INVITE" and "Suggest party invite: " or "Send party invite to ")..row.entry.name)
      local at=self.nearbyInvited and self.nearbyInvited[row.entry.guid]
      GameTooltip:AddLine(at and GetTime()-at<10 and "Party invite or suggestion sent. Waiting briefly before allowing another." or "Click to "..(mode=="SUGGEST_INVITE" and "suggest this player to your group leader." or "send this player a party invite."),.8,.8,.8,true); GameTooltip:Show()
    end)
    row.invite:SetScript("OnLeave",function()
      self.nearbyHovered=nil; GameTooltip:Hide()
      self:CancelTimer("nearby-display")
      self:StartTimer("nearby-display",.1,function() if not A.Combat() then B:UpdateNearbyWindow() end end)
    end)
    -- Tags at the right end of the name field, next to the buffs: PvP flag or blacklist mark,
    -- then friend or guild. The buff column stays free for the buff itself.
    row.tags={}
    for j=1,2 do local tag=row:CreateTexture(nil,"ARTWORK"); tag:SetSize(12,12); tag:Hide(); row.tags[j]=tag end
    row.icons={}; row.iconEdges={}
    for j=1,4 do
      local icon=row:CreateTexture(nil,"ARTWORK"); icon:SetSize(14,14); icon:SetTexCoord(.07,.93,.07,.93); row.icons[j]=icon
      local edge=wash(row,"BORDER",.55,.47,.30,.70); edge:SetSize(16,16); row.iconEdges[j]=edge
    end
    row:SetScript("PreClick",function(button,mouse,down)
      if A.Combat() then return end
      local action=button.action; self:SetNearbyRowPayload(button,nil)
      if self:SyncSituation() then self:NoteNearbyClick(nil); self:RequestRefresh("setup changed before nearby click",0); return end
      local ok,valid=pcall(self.ValidateNearby,self,action)
      if ok and valid and mouse=="LeftButton" then
        if not action.nearbyGroup and not self:PrepareNearbyCast(action) then self:NoteNearbyClick(nil); return end
        self:NoteNearbyClick(action); self:SetNearbyRowPayload(button,action)
        if down~=false then self:BeginHelperAttempt(action) end
      else self:NoteNearbyClick(nil); self:RequestRefresh("nearby click changed",0) end
    end)
    row:SetScript("PostClick",function(_,mouse,down)
      if not A.Combat() and mouse=="LeftButton" and down~=false then self:InvalidateAura(); self:RequestRefresh("nearby cast",.15) end
      if not A.Combat() and mouse=="RightButton" and down==false and row.entry and self.ShowNearbyMenu then self:ShowNearbyMenu(row) end
    end)
    row:SetScript("OnEnter",function(button)
      if not button.entry then return end
      self.nearbyHovered=button.entry.guid
      GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetText(button.entry.name)
      if button.action then for _,action in ipairs(button.entry.actions) do GameTooltip:AddLine(action.name,1,1,1) end
      elseif not button.entry.marker then GameTooltip:AddLine("No buff queued. Buffs may be covered, excluded, or unavailable.",.7,.7,.7,true) end
      if button.entry.social=="friend" then GameTooltip:AddLine(self:Text("On your friends list."),.42,.72,1,true)
      elseif button.entry.social=="guild" then GameTooltip:AddLine(self:Text("In your guild."),.35,.9,.42,true) end
      if button.entry.marker=="pvp" and self.db.pvpProtection~=true then GameTooltip:AddLine(self:Text("PvP flagged. Buffing them will flag you too."),1,.45,.4,true)
      elseif button.entry.marker=="pvp" then GameTooltip:AddLine(self:Text("PvP flagged. Buffing them would flag you, so PvP protection skips them."),1,.45,.4,true)
      elseif button.entry.marker=="pvp-unknown" then GameTooltip:AddLine(self:Text("PvP status unknown, so PvP protection skips them."),.75,.75,.75,true)
      elseif button.entry.marker=="blocked" then GameTooltip:AddLine(self:Text("Blacklisted. BuffTap offers no buffs or invites."),1,.4,.35,true) end
      if button.action and not button.action.ready then GameTooltip:AddLine("Waiting for cooldown.",.8,.8,.7)
      elseif button.action and button.action.source=="cleanse" then GameTooltip:AddLine(self:Text("Click: cleanse %s",button.action.debuffName or ""),1,.82,0)
      elseif button.action then GameTooltip:AddLine("Click: next appropriate buff",1,.82,0) end
      GameTooltip:AddLine("Right-click: whisper, invite, ignore or blacklist",.7,.7,.7,true)
      GameTooltip:AddLine("Mouse wheel: scroll players",.7,.7,.7,true)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function()
      self.nearbyHovered=nil; GameTooltip:Hide()
      self:CancelTimer("nearby-display")
      self:StartTimer("nearby-display",.1,function() if not A.Combat() then B:UpdateNearbyWindow() end end)
    end)
  end
  -- Child buttons consume wheel input too, instead of casting or zooming behind the list.
  for _,surface in ipairs({c,f.dragHandle,f.statusButton,f.countHelp,f.allPlayers,f.lock,f.close,f.scroll}) do wheelSurface(surface) end
  for _,row in ipairs(f.rows) do wheelSurface(row); wheelSurface(row.invite); wheelSurface(row.request) end
  local ok,result=pcall(RegisterStateDriver,f,"visibility","[combat] hide")
  if not ok or result==false then self.nearbySetupError="Secure combat visibility failed"; f:Hide(); return end
  f:Hide()
end
-- Optional hidden title bar: the header fades out until the mouse is over the window, so it
-- can still be dragged and its buttons used. The hairline can stay. Polls the mouse only
-- while the option is on and the window is shown, ten times a second.
function B:NearbyHeaderParts(f)
  return {f.header,f.title,f.count,f.lock,f.close,f.allPlayers,f.countHelp}
end
function B:UpdateNearbyHeaderFade(force)
  local f=self.nearbyFrame; if not f then return end
  local hide=self.db.nearbyHideHeader==true
  local shown=not hide or f:IsMouseOver(4,-4,-4,4)
  if force or f.headerShown~=shown then
    f.headerShown=shown
    for _,part in ipairs(self:NearbyHeaderParts(f)) do if part then part:SetAlpha(shown and 1 or 0) end end
    if f.line then f.line:SetAlpha((shown or self.db.nearbyKeepLine~=false) and 1 or 0) end
  end
  if not f.headerWatch then
    f.headerWatch=CreateFrame("Frame",nil,f); f.headerWatch.elapsed=0
    f.headerWatch:SetScript("OnUpdate",function(w,elapsed)
      w.elapsed=w.elapsed+(elapsed or 0); if w.elapsed<.1 then return end; w.elapsed=0
      B:UpdateNearbyHeaderFade()
    end)
  end
  f.headerWatch:SetShown(hide)
end
function B:UpdateNearbyWindow()
  if A.Combat() or self.nearbyDragging then return end
  if not self.db.nearbyEnabled and not self.nearbyUserOpened then
    if self.nearbyFrame then self.nearbyFrame:Hide() end; return
  end
  ROW_HEIGHT=self:NearbyRowHeight()
  local width,rows,scale=self:NearbyLayout(); WIDTH,ROWS,HEIGHT=width,rows,29+rows*ROW_HEIGHT
  self:CreateNearbyWindow()
  local f=self.nearbyFrame; if not f or self.nearbySetupError then return end
  local right=self.db.nearbyButtonSide=="right"
  -- A glanceable list belongs under Blizzard's panels (professions, bags); players can keep it on top.
  local strata=self.db.nearbyOnTop==true and "DIALOG" or "LOW"
  if f.strata~=strata then f:SetFrameStrata(strata); f.strata=strata end
  local fontPath,fontSize,fontFlags=self:NearbyFont()
  local layoutKey=table.concat({WIDTH,ROWS,scale,self.db.nearbyOpacity,right and "R" or "L",fontPath,fontSize,fontFlags},":")
  if f.layoutKey~=layoutKey then
    f.layoutKey=layoutKey; f:SetSize(WIDTH+24,HEIGHT); f:SetScale(scale); f.content:SetSize(WIDTH,HEIGHT)
    -- Invite and request buttons sit in a 24px gutter on the chosen side of the list.
    f.content:ClearAllPoints(); f.content:SetPoint("TOPLEFT",right and 0 or 24,0)
    for _,row in ipairs(f.rows) do row.invite:ClearAllPoints(); if right then row.invite:SetPoint("LEFT",row,"RIGHT",4,0) else row.invite:SetPoint("RIGHT",row,"LEFT",-4,0) end end
    f.header:SetWidth(WIDTH); f.header:SetColorTexture(.055,.07,.09,self.db.nearbyOpacity)
    -- The title and counter share the list's font and outline; their size stops at 13 px to fit the header.
    for _,text in ipairs({f.title,f.count}) do
      local size=math.min(fontSize,13)
      if not text:SetFont(fontPath,size,fontFlags) then text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,fontFlags) end
    end
    f.line:SetWidth(WIDTH); f.dragHandle:SetWidth(WIDTH-43)
    f.lock:ClearAllPoints(); f.lock:SetPoint("TOPLEFT",WIDTH-34,-3)
    f.close:ClearAllPoints(); f.close:SetPoint("TOPLEFT",WIDTH-17,-3)
    f.allPlayers:ClearAllPoints(); f.allPlayers:SetPoint("TOPLEFT",WIDTH-56,-3)
    f.count:SetWidth(WIDTH-135); f.countHelp:SetWidth(WIDTH-131)
    f.status:SetWidth(WIDTH-12); f.statusButton:SetWidth(WIDTH-12)
    f.scroll:ClearAllPoints(); f.scroll:SetPoint("TOPLEFT",WIDTH-5,-25); f.scroll:SetHeight(ROWS*ROW_HEIGHT-2)
    for i,row in ipairs(f.rows) do
      row:SetSize(WIDTH,ROW_HEIGHT-1); row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-25-(i-1)*ROW_HEIGHT)
      row.wash:SetColorTexture(.055,.075,.095,self.db.nearbyOpacity*.68); row.idle:ClearAllPoints(); row.idle:SetPoint("CENTER",row,"RIGHT",-16,0); row.style=nil
      if not row.name:SetFont(fontPath,fontSize,fontFlags) then row.name:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",fontSize,fontFlags) end
      row.name:ClearAllPoints(); row.name:SetPoint("LEFT",26,0)
    end
  end
  -- The header hairline follows the accent colour chosen under Customization > Interface.
  if self.InterfaceAccent then local r,g,b=self:InterfaceAccent(); f.line:SetColorTexture(r,g,b,.80) end
  local list=self:NearbyPlayers()
  if not self.db.enabled or not self.db.nearbyEnabled or not platesOn() or (self:NearbyPauseReason() and not self:NearbyBrowsePause()) then self.nearbyDisplay=nil end
  local display=self:NearbyDisplayList(list)
  local x,y=self.db.nearbyX,self.db.nearbyY
  x=A.Number(x) and x or 240; y=A.Number(y) and y or 0
  if f.positionX~=x or f.positionY~=y or f.positionScale~=scale then self:PlaceNearbyFrame(f,x,y); f.positionX=x; f.positionY=y; f.positionScale=scale end
  local counts=self.nearbyCounts or {need=0,total=0}
  -- In the buff-only view, note players left out for PvP or the blacklist.
  local note=""
  if not self.db.nearbyShowAll then
    local media="Interface\\AddOns\\BuffTap\\Media\\"
    if (counts.flagged or 0)>0 then note=note.." |T"..media.."UIPvPFlag:12:12:0:0:64:64:0:64:0:64:230:92:82|t"..counts.flagged end
    if (counts.blocked or 0)>0 then note=note.." |T"..media.."NavBlacklist:12:12:0:0:64:64:0:64:0:64:242:64:56|t"..counts.blocked end
  end
  -- Browsing while resting or mounted: say why nothing is offered instead of a 0/N count.
  local browse=self:NearbyBrowsePause()
  if browse then f.count:SetText("|cffa0a8b0"..self:Text(browse=="resting" and "Paused: resting" or "Paused: mounted").."|r")
  else f.count:SetText(counts.need.."/"..counts.total..note) end
  if f.allPlayers.showAll~=self.db.nearbyShowAll then
    f.allPlayers.showAll=self.db.nearbyShowAll
    for _,t in ipairs(f.allPlayers.parts) do
      if self.db.nearbyShowAll then t:SetVertexColor(1,.82,0,1) else t:SetVertexColor(.65,.65,.62,1) end
    end
  end
  for guid,at in pairs(self.nearbyInvited or {}) do
    if GetTime()-at>=10 then self.nearbyInvited[guid]=nil end
  end
  for _,t in ipairs(f.lock.shackle) do t:SetAlpha(self.db.nearbyLocked and 1 or .4) end
  f.lock.body:SetAlpha(self.db.nearbyLocked and 1 or .55)
  f:EnableMouseWheel(true)
  self.nearbyOffset=math.max(0,math.min(self.nearbyOffset or 0,math.max(0,#display-ROWS)))
  f.scroll:SetMinMaxValues(0,math.max(0,#display-ROWS)); f.scroll:SetValue(self.nearbyOffset); f.scroll:SetShown(#display>ROWS)
  for i,row in ipairs(f.rows) do
    local item=i<=ROWS and display[i+self.nearbyOffset] or nil; local entry=item and item.entry
    row.entry=entry; row.action=item and item.fresh and nextAction(entry) or nil
    self:SetNearbyRowPayload(row,row.action)
    if entry then
      local parts={entry.guid,self:NearbyDisplayName(entry),entry.class,tostring(entry.marker),tostring(entry.social)}
      for _,action in ipairs(entry.actions) do parts[#parts+1]=tostring(action.id)..":"..tostring(action.icon)..":"..tostring(action.dispelType) end
      local style=table.concat(parts,"|")
      if row.style~=style then
        row.style=style; row.name:SetText(self:NearbyDisplayName(entry))
        local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[entry.class]
        row.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        if coords then row.classIcon:SetTexCoord(unpack(coords)); row.classIcon:Show() else row.classIcon:Hide() end
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
        if color then row.name:SetTextColor(color.r,color.g,color.b) else row.name:SetTextColor(1,1,1) end
        local count=math.min(4,#entry.actions); local slots=math.max(1,count)
        local tagged={}
        if MARKERS[entry.marker or ""] then tagged[#tagged+1]=MARKERS[entry.marker] end
        if MARKERS[entry.social or ""] then tagged[#tagged+1]=MARKERS[entry.social] end
        for j,tag in ipairs(row.tags) do
          local style=tagged[#tagged+1-j]
          tag:ClearAllPoints()
          if style then
            tag:SetPoint("RIGHT",row,"RIGHT",-8-slots*18-2-(j-1)*14,0)
            tag:SetTexture("Interface\\AddOns\\BuffTap\\Media\\"..style[1]); tag:SetVertexColor(style[2],style[3],style[4]); tag:SetAlpha(style[5]); tag:Show()
          else tag:Hide() end
        end
        row.name:SetWidth(WIDTH-26-12-slots*18-#tagged*14)
        for j,icon in ipairs(row.icons) do
          local action=entry.actions[j]; local edge=row.iconEdges[j]
          icon:ClearAllPoints(); edge:ClearAllPoints()
          local offset=-(count-j)*18-8
          edge:SetPoint("RIGHT",offset,0); icon:SetPoint("RIGHT",offset-1,0)
          icon:SetTexture(action and (action.icon or 134400)); icon:SetShown(action~=nil); edge:SetShown(action~=nil)
          local tint=action and action.source=="cleanse" and B.CleanseColors and B.CleanseColors[action.dispelType]
          if tint then edge:SetColorTexture(tint[1],tint[2],tint[3],1) else edge:SetColorTexture(.55,.47,.30,.70) end
        end
      end
      local first=item.fresh and entry.actions[1]
      local tint=first and first.source=="cleanse" and B.CleanseColors and B.CleanseColors[first.dispelType]
      if tint then
        row.cleanseTint:SetColorTexture(tint[1],tint[2],tint[3],.15); row.cleanseBar:SetColorTexture(tint[1],tint[2],tint[3],1)
      end
      row.cleanseTint:SetShown(tint and true or false); row.cleanseBar:SetShown(tint and true or false)
      row:SetAlpha(row.action and (row.action.ready and 1 or .72) or (self.db.nearbyShowAll and .60 or .40))
      row.idle:SetShown(self.db.nearbyShowAll and not row.action and #entry.actions==0)
      local invited=self.nearbyInvited and self.nearbyInvited[entry.guid]
      local inviteName,inviteMode=self:NearbyInviteName(entry)
      local request=inviteMode=="REQUEST_INVITE"
      row.invite.text:SetText(invited and "..." or inviteMode=="SUGGEST_INVITE" and ">" or "+")
      row.invite.text:SetTextColor(1,1,1)
      local plus=not invited and inviteMode~="SUGGEST_INVITE" and not request
      local join=request and not invited
      row.invite.plus:SetShown(plus); row.invite.arrow:SetShown(join); row.invite.text:SetShown(not plus and not join)
      row.invite:SetShown(item.fresh and inviteName~=nil and entry.marker~="blocked")
      local requests=item.fresh and entry.marker~="blocked" and self:RequestableBuffs(entry)
      row.request:ClearAllPoints()
      if right then
        if row.invite:IsShown() then row.request:SetPoint("LEFT",row.invite,"RIGHT",2,0) else row.request:SetPoint("LEFT",row,"RIGHT",4,0) end
      elseif row.invite:IsShown() then row.request:SetPoint("RIGHT",row.invite,"LEFT",-2,0) else row.request:SetPoint("RIGHT",row,"LEFT",-4,0) end
      if requests then row.request.icon:SetTexture(requests[1].icon); row.request:SetAlpha(self:RequestCooling(entry) and .45 or 1) end
      row.request:SetShown(type(requests)=="table")
      row.marker:SetShown(row.action and row.action.ready and self.action and self.action.nearby and self.action.targetGUID==entry.guid or false)
      self:ShowNearbyRowResult(row,self:NearbyResultFor(entry.guid))
      if not row:IsShown() then row:Show() end
    else row.style=nil; row.invite:Hide(); row.request:Hide(); row.idle:Hide(); row.cleanseTint:Hide(); row.cleanseBar:Hide(); if row.result then row.result:Hide() end; for _,tag in ipairs(row.tags) do tag:Hide() end; if row:IsShown() then row:Hide() end end
  end
  local status
  if not self.db.enabled then status="BuffTap is disabled."
  elseif not self.db.nearbyEnabled then status="Nearby is off. Click here to enable."
  elseif plateSetting()==nil then status="Friendly nameplate setting unavailable."
  elseif not platesOn() then status="Enable friendly nameplates (Shift+V)."
  elseif self:NearbyPauseReason() then status="Paused: "..self:NearbyPauseReason()
  elseif self.db.nearbyShowAll then status="No nearby players detected."
  elseif self.db.nearbyBuffing==false then status="Nearby buffing is off."
  elseif #self:TargetAssignableBuffs()==0 then status="No supported buffs for nearby players."
  elseif #list==0 and self.manaBlocked then status="Not enough mana to buff."
  elseif #list==0 and self.powerBlocked then status="Buff unavailable: check form, reagents or requirements."
  elseif #list==0 and self.nearbyCastError then status="Cast unavailable: "..self.nearbyCastError
  elseif #list==0 and self.nearbySafetyReason then status=self.nearbySafetyReason
  elseif #list==0 and (self.buffDataUnavailable or self.ownershipUnavailable) then status="Buff data unavailable."
  else status="No nearby buffs needed." end
  f.status:SetText(status); f.status:SetShown(#display==0); f.statusButton:SetShown(#display==0)
  if self.db.nearbyEnabled and not platesOn() then f.status:SetTextColor(1,.55,.25) else f.status:SetTextColor(.75,.75,.72) end
  self:UpdateNearbyHeaderFade(true)
  if not f:IsShown() then f:Show() end
end

function B:ToggleNearby()
  if A.Combat() then self.Print("Nearby mode can be changed after combat."); return end
  -- The first time Nearby is turned on, explain it and offer invites and requests first.
  if not self.db.nearbyEnabled and not self.db.nearbyIntroSeen and self.ShowNearbyIntro then self:ShowNearbyIntro(true); return end
  self.db.nearbyEnabled=not self.db.nearbyEnabled
  self.nearbyUserOpened=self.db.nearbyEnabled
  self:SyncNearby(); self.nearbySnapshot=nil; self:RequestRefresh("nearby shortcut",0)
  self:UpdateNearbyWindow()
end
function B:ShowNearbySetup()
  if A.Combat() then return end
  self.nearbyUserOpened=true; self:SyncNearby(); self.nearbySnapshot=nil; self:UpdateNearbyWindow()
end

local frame=CreateFrame("Frame")
B.nearbyEvents=frame
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"}) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent",function(_,event,unit,message,spellID)
  if not B.db then return end
  if event=="PLAYER_REGEN_DISABLED" then
    B.nearbySnapshot=nil
    for _,slot in ipairs({"nearby-range","nearby-settle","nearby-late","nearby-display","buff-aura-early","buff-aura-settle","buff-aura-late"}) do B:CancelTimer(slot) end
    return
  end
  B:SyncNearby()
  if not B.db.nearbyEnabled then return end
  if event=="UNIT_SPELLCAST_SUCCEEDED" then
    if unit=="player" and B:NearbyResultSpell(spellID) then B:SetNearbyResult("ok") end
    B:NearbyCastSucceeded(unit,spellID); return
  elseif event=="UNIT_SPELLCAST_FAILED" then
    -- The game's reason usually arrives as a UI error just before or after; wait a moment for it.
    if unit=="player" and B:NearbyResultSpell(spellID) then
      B:StartTimer("nearby-result-fail",.1,function() B:SetNearbyResult("fail",B.nearbyClickError) end)
    end
    return
  elseif event=="UI_ERROR_MESSAGE" then
    if B.nearbyClickAt and GetTime()-B.nearbyClickAt<1 and A.Text(message) then
      B.nearbyClickError=message
      if B.nearbyResult and B.nearbyResult.state=="pending" then B:SetNearbyResult("fail",message) end
    end
    return
  elseif event=="NAME_PLATE_UNIT_ADDED" then B:TrackNearby(unit); B:ScheduleNearbySettle()
  elseif event=="NAME_PLATE_UNIT_REMOVED" and A.Text(unit) then
    B.nearbyUnits[unit]=nil; B:InvalidateAura(unit)
    if not A.Combat() then B:SeedNearby(unit) end
    -- Preserve arrival order through short nameplate hide/show cycles.
  elseif event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED" then
    B.nearbyNeedCache={}; B.nearbyUnits={}; B.nearbyOrder={}; if not A.Combat() then B:SeedNearby() end
    B:ScheduleNearbySettle()
  elseif event=="CVAR_UPDATE" then
    if not A.Text(unit) or (unit:lower()~="nameplateshowfriends" and unit:lower()~="nameplateshowfriendlyplayers") then return end
    if not A.Combat() then B:SeedNearby(); B:ScheduleNearbySettle() end
    if B.options and B.UpdateNavStatus then B:UpdateNavStatus() end
  end
  B.nearbySnapshot=nil; B:RequestRefresh("nearby players changed",.12)
end)
function B:WatchNearbyRange()
  self:CancelTimer("nearby-range")
  if not self.db.nearbyEnabled or not self.db.enabled or not platesOn() or A.Combat()
    or self:NearbyPauseReason() or not next(self.nearbyUnits or {}) then return end
  local safety={}
  local function state(unit)
    return tostring(A.Call(UnitAffectingCombat,unit))..":"..tostring(A.Call(UnitIsPVP,unit))..":"..tostring(A.Call(UnitIsPVPFreeForAll,unit))
  end
  for unit in pairs(self.nearbyUnits) do safety[unit]=state(unit) end
  self:StartTimer("nearby-range",1,function()
    if A.Combat() or not B.db.nearbyEnabled then return end
    for unit,previous in pairs(safety) do
      if state(unit)~=previous then
        B.nearbySnapshot=nil; B:RequestRefresh("nearby recipient safety changed",.05); return
      end
    end
    for _,probe in pairs(B.nearbyProbes or {}) do
      local unit=probe.action.target
      local range=B:SpellRange(probe.action); range=range==nil and "unknown" or range
      if range~=probe.range or A.Call(UnitGUID,unit)~=probe.action.targetGUID then
        B.nearbySnapshot=nil; B:InvalidateAura(unit); B:RequestRefresh("nearby range changed",.05); return
      end
    end
    B:WatchNearbyRange()
  end)
end
local refresh=B.Refresh
function B:Refresh(...)
  if self.db then self:SyncNearby() end
  self.classListPassActive=true; self.refreshClassList=nil; self.nearbyNeedSettingsChecked=nil
  self.nearbySnapshot=nil
  local result=refresh(self,...)
  if self.db and not A.Combat() then
    local ok,err=pcall(self.UpdateNearbyWindow,self)
    if not ok then self.nearbySetupError="Nearby window unavailable"; self:AddDiag(self.nearbySetupError) end
    self:WatchNearbyRange()
    if self.db.nearbyEnabled and self.nextWakeDelay then self:ScheduleWake(self.nextWakeDelay+.03,"nearby threshold/retry") end
  end
  self.classListPassActive=nil; self.refreshClassList=nil; self.nearbyNeedSettingsChecked=nil
  return result
end
local validate=B.Validate
function B:Validate(action)
  if action and action.nearby and not self:NearbyEntry(action.target,true) then return false,"nearby player no longer eligible" end
  return validate(self,action)
end
local slash=SlashCmdList.BUFFTAP
SlashCmdList.BUFFTAP=function(text)
  if (text or ""):match("^%s*nearby%s*$") then B:ShowNearbySetup(); return end
  return slash(text)
end
function B:NearbyDiagnosticsLines()
  local tracked=0; local plates,setting=plateSetting()
  for _ in pairs(self.nearbyUnits or {}) do tracked=tracked+1 end
  local counts=self.nearbyCounts or {need=0,total=0}
  local out={
    "Nearby: "..(self.db.nearbyEnabled and "on" or "off").." | view: "..(self.db.nearbyShowAll and "all players" or "buffs only").." | buffing: "..(self.db.nearbyBuffing~=false and "on" or "off"),
    "Nearby players: "..counts.need.." queued / "..counts.total.." detected | tracked: "..tracked.."/40",
    "Nearby nameplates: "..tostring(plates).." ("..setting..")",
    "Nearby casting: exact-name/cast/restore | notifications: quiet",
  }
  if self.nearbyLastClick then out[#out+1]="Nearby last click: "..self.nearbyLastClick end
  if self.nearbyClickError then out[#out+1]="Nearby client error: "..self.nearbyClickError end
  if self.nearbyLastInvite then out[#out+1]="Nearby last invitation: "..self.nearbyLastInvite end
  if self.nearbyCastError then out[#out+1]="Nearby cast: "..self.nearbyCastError end
  if self.nearbySetupError then out[#out+1]=self.nearbySetupError end
  return out
end
local diagnostics=B.DiagnosticsLines
function B:DiagnosticsLines()
  local out=diagnostics(self)
  for _,line in ipairs(self:NearbyDiagnosticsLines()) do out[#out+1]=line end
  return out
end
local status=B.Status
function B:Status(verbose)
  status(self,verbose)
  if verbose and DEFAULT_CHAT_FRAME then
    for _,line in ipairs(self:NearbyDiagnosticsLines()) do if self.outputCapture then self.outputCapture[#self.outputCapture+1]=line else DEFAULT_CHAT_FRAME:AddMessage("BuffTap "..line) end end
  end
end
