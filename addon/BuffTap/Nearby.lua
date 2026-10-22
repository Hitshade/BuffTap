-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Experimental recipient source. The ordinary buff engine remains authoritative.
local _,B=...
local A=B.API
local MAX_UNITS,ROWS=40,5
local WIDTH,HEIGHT,ROW_HEIGHT=210,134,21
local targetChoice=B.TargetBlessingChoice
function B:TargetBlessingChoice(entry)
  if A.Call(function() local _,class=UnitClass("player"); return class end)~="PALADIN" then return nil end
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
  if action then
    self.buffCastAttempt={id=action.id,unit=action.target,guid=action.targetGUID,at=GetTime()}
    self.buffAuraFresh={unit=action.target,guid=action.targetGUID,untilTime=GetTime()+3}
    -- Covers the two early target retries and the bounded late retry chain.
    self.nearbyQuietCast={recipient=action.targetGUID,previous=A.Call(UnitGUID,"target"),untilTime=GetTime()+5}
  end
  self.nearbyLastClick=action and (tostring(action.id).." -> "..action.target.." ("..(self:NearbyCastName(action) or "name unavailable")..")") or "cancelled: evidence changed"
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
function B:NearbyGroupMember(unit)
  if A.Call(UnitIsUnit,unit,"player")==true then return true end
  if A.Call(UnitInParty,unit)==true or A.Number(A.Call(UnitInRaid,unit)) then return true end
  local raid=A.Call(IsInRaid)==true
  local count=A.Call(raid and GetNumGroupMembers or GetNumSubgroupMembers)
  if not A.Number(count) then return true end
  for i=1,math.min(count,raid and 40 or 4) do
    local token=(raid and "raid" or "party")..i
    local same=A.Call(UnitIsUnit,unit,token)
    local guid,member=A.Call(UnitGUID,unit),A.Call(UnitGUID,token)
    if same==true or (A.Text(guid) and guid==member) then return true end
    if same~=false and (not A.Text(guid) or not A.Text(member)) then return true end
  end
  return false
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
function B:NearbyEntry(unit)
  if not self.db.nearbyEnabled or not platesOn() or A.Combat() then return nil end
  if not A.Text(unit) or not unit:match("^nameplate%d+$") then return nil end
  local guid=A.Call(UnitGUID,unit)
  if not self.nearbyUnits or self.nearbyUnits[unit]~=guid then return nil end
  if self:NearbyGroupMember(unit) or not self:NearbyRecipientSafe(unit) then return nil end
  -- Your explicitly selected player remains owned by normal Target mode.
  if self.db.friendlyTarget and A.Call(UnitIsUnit,unit,"target")==true then return nil end
  return self:FriendlyTargetEntry(unit,true)
end
local function fits(def,class)
  if (def.key=="ai" or def.key=="spirit") and (class=="WARRIOR" or class=="ROGUE") then return false end
  if not def.target then return true end
  for _,c in ipairs(def.target) do if c==class then return true end end
  return false
end
function B:NearbyActions(entry)
  local actions={}
  local list=self:ClassList()
  self.blessingClassList=list
  entry.targetBlessingChoice=self:TargetBlessingChoice(entry)
  local selected=self.db.targetClassBlessings and self.db.targetBlessingClasses[entry.class]
  local explicit=selected and selected~="skip"
  local scans,errors={},{}
  for _,def in ipairs(list) do
    local enabled=self:Enabled(def) or (explicit and def.kind=="blessing") or (def.classWide and self:TargetBuffEnabled(def))
    if enabled and self:TargetBuffEnabled(def) and not def.singleKey
      and (def.kind=="single" or def.kind=="blessing") and self:Supported(def)
      and (explicit and def.kind=="blessing" or fits(def,entry.class)) then
      local missing=self:ScanMissing(def,{entry},scans,errors,self:TargetRebuffSeconds(def))
      if missing[1] then
        local need=missing[1]; local action=need.action
        action.quickTarget=true; action.nearby=true
        action.needState=need.reason; action.remaining=need.remaining; action.threshold=need.threshold
        action.reason="nearby player: "..need.reason
        local valid,why=self:Validate(action)
        action.ready=valid==true
        action.waiting=not valid and why=="cooldown / global cooldown"
        self.nearbyProbes=self.nearbyProbes or {}
        local probeKey=entry.unit..":"..tostring(action.id)
        local range=self:SpellRange(action)
        self.nearbyProbes[probeKey]={action=action,range=range==nil and "unknown" or range}
        if (valid or action.waiting) and self:PrepareNearbyCast(action) then
          action.selectedAt=GetTime(); actions[#actions+1]=action
          if #actions==4 then break end
        end
      end
    end
  end
  return actions
end
function B:NearbyCandidates(force)
  if not force and self.nearbySnapshot then return self.nearbySnapshot end
  local out,seen={},{}
  self.nearbyProbes={}; self.nearbyCastError=nil; self.nearbySafetyReason=nil
  if not self.db or not self.db.enabled or not self.db.nearbyEnabled or not platesOn()
    or A.Combat() or self:ReminderPauseReason() or A.Call(UnitIsDeadOrGhost,"player")~=false then return out end
  for unit,guid in pairs(self.nearbyUnits or {}) do
    local entry=self:NearbyEntry(unit)
    if entry and A.Text(guid) and not seen[guid] then
      seen[guid]=true
      local actions=self:NearbyActions(entry)
      local name=A.Call(UnitName,unit)
      if #actions>0 and A.Text(name) then
        out[#out+1]={unit=unit,guid=guid,name=name,class=entry.class,actions=actions,order=self.nearbyOrder[guid] or 0}
      end
    end
  end
  table.sort(out,function(a,b) if a.order==b.order then return a.guid<b.guid end return a.order<b.order end)
  self.nearbySnapshot=out
  return out
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
  self.nearbyDisplay=nil; self.nearbyHovered=nil; self.nearbyDisplayCount=nil; self:CancelTimer("nearby-display")
  self.buffCastAttempt=nil; self.buffAuraFresh=nil
  for _,slot in ipairs({"buff-aura-early","buff-aura-settle","buff-aura-late"}) do self:CancelTimer(slot) end
  self.nearbyUnits={}; self.nearbyOrder={}; self.nearbySnapshot=nil; self.nearbyOffset=0
  self:CancelTimer("nearby-settle"); self:CancelTimer("nearby-late")
  for _,event in ipairs({"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","CVAR_UPDATE","UI_ERROR_MESSAGE","UNIT_SPELLCAST_SUCCEEDED"}) do
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
function B:SeedNearby()
  if not self.db.nearbyEnabled then return end
  local plates=A.Call(C_NamePlate and C_NamePlate.GetNamePlates)
  if type(plates)=="table" then
    for _,plate in ipairs(plates) do
      local unit=A.Call(function() return plate:GetUnit() end)
      self:TrackNearby(unit)
    end
  end
end
function B:ValidateNearby(action)
  if not action or A.Combat() or not self.db.enabled or not self.db.nearbyEnabled
    or not platesOn() or self:ReminderPauseReason() then return false end
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
function B:NearbyWheelBound()
  for _,key in ipairs(self.db.keys or {}) do
    if type(key)=="string" and (key:find("MOUSEWHEELUP",1,true) or key:find("MOUSEWHEELDOWN",1,true)) then return true end
  end
  return false
end
function B:NearbyDisplayList(list)
  local now,fresh,seen,out=GetTime(),{},{},{}
  for _,entry in ipairs(list) do fresh[entry.guid]=entry end
  local pending
  for _,old in ipairs(self.nearbyDisplay or {}) do
    local entry=fresh[old.entry.guid]
    local missing=not entry and (old.missingAt or now)
    if entry or self.nearbyHovered or (missing and now-missing<.65) then
      out[#out+1]={entry=entry or old.entry,fresh=entry~=nil,missingAt=missing}
      seen[old.entry.guid]=true
      if missing and now-missing<.65 then pending=math.min(pending or .65,.65-(now-missing)) end
    end
  end
  if not self.nearbyHovered then
    for _,entry in ipairs(list) do
      if not seen[entry.guid] and #out<MAX_UNITS then out[#out+1]={entry=entry,fresh=true}; seen[entry.guid]=true end
    end
  end
  self.nearbyDisplay=out
  self:CancelTimer("nearby-display")
  if pending then self:StartTimer("nearby-display",math.max(.03,pending+.02),function() if not A.Combat() then B:UpdateNearbyWindow() end end) end
  return out
end
function B:SetNearbyRowPayload(row,action)
  local macro=action and action.ready~=false and action.macroText or nil
  if row:GetAttribute("type1")== (macro and "macro" or nil) and row:GetAttribute("macrotext")==macro then return end
  row:SetAttribute("type1",nil); row:SetAttribute("macrotext",nil); row:SetAttribute("spell",nil); row:SetAttribute("unit",nil)
  if macro then row:SetAttribute("macrotext",macro); row:SetAttribute("type1","macro") end
end
function B:CreateNearbyWindow()
  if self.nearbyFrame or A.Combat() then return end
  if type(RegisterStateDriver)~="function" then self.nearbySetupError="Secure combat visibility is unavailable"; return end
  local f=CreateFrame("Frame","BuffTapNearbyWindow",UIParent,"SecureHandlerStateTemplate")
  self.nearbyFrame=f; f:SetSize(WIDTH,HEIGHT); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true); f:SetFrameLevel(120)
  f:SetMovable(true); f:EnableMouse(false); f:RegisterForDrag("LeftButton")
  f.header=wash(f,"BACKGROUND",.055,.07,.09,.50); f.header:SetPoint("TOPLEFT"); f.header:SetPoint("TOPRIGHT"); f.header:SetHeight(21)
  f.line=wash(f,"BORDER",.72,.58,.25,.80); f.line:SetPoint("TOPLEFT",0,-21); f.line:SetPoint("TOPRIGHT",0,-21); f.line:SetHeight(1)
  f.title=label(f,"BuffTap",5,-5); f.title:SetTextColor(1,.82,0)
  f.subtitle=label(f,"Nearby",53,-5); f.subtitle:SetTextColor(.76,.76,.72)
  f.count=label(f,"",135,-5); f.count:SetWidth(31); f.count:SetJustifyH("RIGHT"); f.count:SetTextColor(.82,.82,.79)
  f.lock=CreateFrame("Button",nil,f); f.lock:SetSize(12,15); f.lock:SetPoint("TOPRIGHT",-22,-3)
  f.lock.body=wash(f.lock,"ARTWORK",.8,.8,.76,1); f.lock.body:SetSize(8,6); f.lock.body:SetPoint("BOTTOM",0,2)
  f.lock.key=wash(f.lock,"OVERLAY",.10,.12,.15,1); f.lock.key:SetSize(1,3); f.lock.key:SetPoint("BOTTOM",0,3)
  f.lock.shackle={}
  for i,point in ipairs({{-3,2,1,5},{3,2,1,5},{0,4.5,7,1}}) do
    local t=wash(f.lock,"ARTWORK",.8,.8,.76,1); t:SetSize(point[3],point[4]); t:SetPoint("CENTER",point[1],point[2]); f.lock.shackle[i]=t
  end
  f.lock:SetScript("OnClick",function() if not A.Combat() then self.db.nearbyLocked=not self.db.nearbyLocked; self:UpdateNearbyWindow() end end)
  hint(f.lock,function() return self.db.nearbyLocked and "Unlock position" or "Lock position" end,"Drag the header to move. Shift-left-click the minimap icon to toggle Nearby.")
  f.close=CreateFrame("Button",nil,f); f.close:SetSize(14,16); f.close:SetPoint("TOPRIGHT",-3,-3)
  f.close.text=label(f.close,"x",3,-1); f.close.text:SetTextColor(.78,.78,.75)
  f.close:SetScript("OnClick",function()
    if A.Combat() then return end
    self.db.nearbyEnabled=false; self.nearbyUserOpened=false; self:SyncNearby(); f:Hide(); self:RequestRefresh("nearby closed",0)
  end)
  hint(f.close,function() return "Disable Nearby" end,"Shift-left-click the minimap icon to enable it again.")
  f.status=label(f,"",6,-31); f.status:SetWidth(198); f.status:SetJustifyH("LEFT"); f.status:SetWordWrap(true)
  f.statusButton=CreateFrame("Button",nil,f); f.statusButton:SetPoint("TOPLEFT",4,-25); f.statusButton:SetSize(198,34)
  hint(f.statusButton,function() return "Nearby buffing" end,"Uses your Target preferences. Friendly player nameplates must be enabled (Shift+V). Shift-click the minimap icon to toggle. Players in combat are skipped; PvP protection skips flagged or unreadable players.")
  f.statusButton:SetScript("OnClick",function() if not self.db.nearbyEnabled then self:ToggleNearby() end end)
  local function dragStart() if not A.Combat() and not self.db.nearbyLocked then self.nearbyDragging=true; f:StartMoving() end end
  local function dragStop()
    if A.Combat() then return end
    f:StopMovingOrSizing(); self.nearbyDragging=false
    local x,y=f:GetCenter(); local px,py=UIParent:GetCenter()
    if A.Number(x) and A.Number(y) and A.Number(px) and A.Number(py) then self.db.nearbyX=x-px; self.db.nearbyY=y-py end
    self:UpdateNearbyWindow()
  end
  f:SetScript("OnDragStart",dragStart); f:SetScript("OnDragStop",dragStop)
  f.dragHandle=CreateFrame("Frame",nil,f); f.dragHandle:SetSize(WIDTH-43,21); f.dragHandle:SetPoint("TOPLEFT")
  f.dragHandle:EnableMouse(true); f.dragHandle:RegisterForDrag("LeftButton")
  f.dragHandle:SetScript("OnDragStart",dragStart); f.dragHandle:SetScript("OnDragStop",dragStop)
  f:SetScript("OnMouseWheel",function(_,delta)
    if A.Combat() or not A.Number(delta) or self:NearbyWheelBound() then return end
    self.nearbyOffset=math.max(0,math.min(math.max(0,#(self.nearbyDisplay or {})-ROWS),(self.nearbyOffset or 0)-(delta>0 and 1 or -1)))
    self:UpdateNearbyWindow()
  end)
  f.scroll=CreateFrame("Slider",nil,f); f.scroll:SetSize(4,103); f.scroll:SetPoint("TOPRIGHT",-1,-25)
  f.scroll:SetOrientation("VERTICAL"); f.scroll:SetValueStep(1); f.scroll:SetObeyStepOnDrag(true)
  f.scroll.track=wash(f.scroll,"BACKGROUND",.5,.51,.49,.16); f.scroll.track:SetAllPoints()
  f.scroll.thumb=wash(f.scroll,"ARTWORK",.67,.68,.65,.65); f.scroll.thumb:SetSize(4,22); f.scroll:SetThumbTexture(f.scroll.thumb)
  f.scroll:SetScript("OnValueChanged",function(_,value)
    if A.Combat() or not A.Number(value) then return end
    local offset=math.floor(value+.5)
    if self.nearbyOffset~=offset then self.nearbyOffset=offset; self:UpdateNearbyWindow() end
  end)
  f.rows={}
  for i=1,ROWS do
    local row=CreateFrame("Button",nil,f,"SecureActionButtonTemplate")
    f.rows[i]=row; row:SetSize(198,20); row:SetPoint("TOPLEFT",4,-25-(i-1)*ROW_HEIGHT)
    row:RegisterForClicks("AnyDown","AnyUp"); row:SetAttribute("useOnKeyDown",true)
    row.wash=wash(row,"BACKGROUND",.055,.075,.095,.34); row.wash:SetAllPoints()
    row.hover=wash(row,"HIGHLIGHT",.75,.60,.25,.17); row.hover:SetAllPoints()
    row.marker=wash(row,"BACKGROUND",.75,.60,.25,.075); row.marker:SetAllPoints()
    row.classEdge=wash(row,"BORDER",.55,.47,.30,.70); row.classEdge:SetSize(16,16); row.classEdge:SetPoint("LEFT",1,0)
    row.classIcon=row:CreateTexture(nil,"ARTWORK"); row.classIcon:SetSize(14,14); row.classIcon:SetPoint("LEFT",2,0)
    row.name=label(row,"",23,-4); row.name:SetWidth(132); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
    row.icons={}; row.iconEdges={}
    for j=1,4 do
      local icon=row:CreateTexture(nil,"ARTWORK"); icon:SetSize(14,14); icon:SetTexCoord(.07,.93,.07,.93); row.icons[j]=icon
      local edge=wash(row,"BORDER",.55,.47,.30,.70); edge:SetSize(16,16); row.iconEdges[j]=edge
    end
    row:SetScript("PreClick",function(button,mouse,down)
      if A.Combat() then return end
      local action=button.action; self:SetNearbyRowPayload(button,nil)
      local ok,valid=pcall(self.ValidateNearby,self,action)
      if ok and valid and mouse=="LeftButton" then
        if not self:PrepareNearbyCast(action) then self:NoteNearbyClick(nil); return end
        self:NoteNearbyClick(action); self:SetNearbyRowPayload(button,action)
        if down~=false then self:BeginHelperAttempt(action) end
      else self:NoteNearbyClick(nil); self:RequestRefresh("nearby click changed",0) end
    end)
    row:SetScript("PostClick",function(_,mouse,down)
      if not A.Combat() and mouse=="LeftButton" and down~=false then self:InvalidateAura(); self:RequestRefresh("nearby cast",.15) end
    end)
    row:SetScript("OnEnter",function(button)
      if not button.entry then return end
      self.nearbyHovered=button.entry.guid
      GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetText(button.entry.name)
      if button.action then for _,action in ipairs(button.entry.actions) do GameTooltip:AddLine(action.name,1,1,1) end
      else GameTooltip:AddLine("Updating recipient; casting is unavailable.",.7,.7,.7,true) end
      if button.action and not button.action.ready then GameTooltip:AddLine("Waiting for cooldown.",.8,.8,.7)
      else GameTooltip:AddLine("Click: next appropriate buff",1,.82,0) end
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function()
      self.nearbyHovered=nil; GameTooltip:Hide()
      self:CancelTimer("nearby-display")
      self:StartTimer("nearby-display",.1,function() if not A.Combat() then B:UpdateNearbyWindow() end end)
    end)
  end
  local ok,result=pcall(RegisterStateDriver,f,"visibility","[combat] hide; show")
  if not ok or result==false then self.nearbySetupError="Secure combat visibility failed"; f:Hide(); return end
  f:Hide()
end
function B:UpdateNearbyWindow()
  if A.Combat() or self.nearbyDragging then return end
  if not self.db.nearbyEnabled and not self.nearbyUserOpened then
    if self.nearbyFrame then self.nearbyFrame:Hide() end; return
  end
  self:CreateNearbyWindow()
  local f=self.nearbyFrame; if not f or self.nearbySetupError then return end
  local list=self:NearbyCandidates()
  if not self.db.enabled or not self.db.nearbyEnabled or not platesOn() or self:ReminderPauseReason() then self.nearbyDisplay=nil end
  local display=self:NearbyDisplayList(list)
  local x,y=self.db.nearbyX,self.db.nearbyY
  x=A.Number(x) and x or 240; y=A.Number(y) and y or 0
  if f.positionX~=x or f.positionY~=y then f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",x,y); f.positionX=x; f.positionY=y end
  f.count:SetText(#display>0 and tostring(#display) or "")
  for _,t in ipairs(f.lock.shackle) do t:SetAlpha(self.db.nearbyLocked and 1 or .4) end
  f.lock.body:SetAlpha(self.db.nearbyLocked and 1 or .55)
  f:EnableMouseWheel(not self:NearbyWheelBound())
  self.nearbyOffset=math.max(0,math.min(self.nearbyOffset or 0,math.max(0,#display-ROWS)))
  f.scroll:SetMinMaxValues(0,math.max(0,#display-ROWS)); f.scroll:SetValue(self.nearbyOffset); f.scroll:SetShown(#display>ROWS)
  for i,row in ipairs(f.rows) do
    local item=display[i+self.nearbyOffset]; local entry=item and item.entry
    row.entry=entry; row.action=item and item.fresh and nextAction(entry) or nil
    self:SetNearbyRowPayload(row,row.action)
    if entry then
      local parts={entry.guid,entry.name,entry.class}
      for _,action in ipairs(entry.actions) do parts[#parts+1]=tostring(action.id)..":"..tostring(action.icon) end
      local style=table.concat(parts,"|")
      if row.style~=style then
        row.style=style; row.name:SetText(entry.name)
        local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[entry.class]
        row.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        if coords then row.classIcon:SetTexCoord(unpack(coords)); row.classIcon:Show() else row.classIcon:Hide() end
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
        if color then row.name:SetTextColor(color.r,color.g,color.b) else row.name:SetTextColor(1,1,1) end
        local count=math.min(4,#entry.actions); row.name:SetWidth(198-23-8-count*18)
        for j,icon in ipairs(row.icons) do
          local action=entry.actions[j]; local edge=row.iconEdges[j]
          icon:ClearAllPoints(); edge:ClearAllPoints()
          local offset=-(count-j)*18-3
          edge:SetPoint("RIGHT",offset,0); icon:SetPoint("RIGHT",offset-1,0)
          icon:SetTexture(action and (action.icon or 134400)); icon:SetShown(action~=nil); edge:SetShown(action~=nil)
        end
      end
      row:SetAlpha(row.action and (row.action.ready and 1 or .72) or .40)
      row.marker:SetShown(row.action and row.action.ready and self.action and self.action.nearby and self.action.targetGUID==entry.guid or false)
      if not row:IsShown() then row:Show() end
    else row.style=nil; if row:IsShown() then row:Hide() end end
  end
  local status
  if not self.db.enabled then status="BuffTap is disabled."
  elseif not self.db.nearbyEnabled then status="Nearby is off. Click here to enable."
  elseif plateSetting()==nil then status="Friendly nameplate setting unavailable."
  elseif not platesOn() then status="Enable friendly nameplates (Shift+V)."
  elseif self:ReminderPauseReason() then status="Paused: "..self:ReminderPauseReason()
  elseif #self:TargetAssignableBuffs()==0 then status="No supported buffs for nearby players."
  elseif #list==0 and self.manaBlocked then status="Not enough mana to buff."
  elseif #list==0 and self.powerBlocked then status="Buff unavailable: check form, reagents or requirements."
  elseif #list==0 and self.nearbyCastError then status="Cast unavailable: "..self.nearbyCastError
  elseif #list==0 and self.nearbySafetyReason then status=self.nearbySafetyReason
  elseif #list==0 and (self.buffDataUnavailable or self.ownershipUnavailable) then status="Buff data unavailable."
  else status="No nearby buffs needed." end
  f.status:SetText(status); f.status:SetShown(#display==0); f.statusButton:SetShown(#display==0)
  if self.db.nearbyEnabled and not platesOn() then f.status:SetTextColor(1,.55,.25) else f.status:SetTextColor(.75,.75,.72) end
  if not f:IsShown() then f:Show() end
end

function B:ToggleNearby()
  if A.Combat() then self.Print("Nearby mode can be changed after combat."); return end
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
  if event=="UNIT_SPELLCAST_SUCCEEDED" then B:NearbyCastSucceeded(unit,spellID); return
  elseif event=="UI_ERROR_MESSAGE" then
    if B.nearbyClickAt and GetTime()-B.nearbyClickAt<1 and A.Text(message) then B.nearbyClickError=message end
    return
  elseif event=="NAME_PLATE_UNIT_ADDED" then B:TrackNearby(unit); B:ScheduleNearbySettle()
  elseif event=="NAME_PLATE_UNIT_REMOVED" and A.Text(unit) then
    local guid=B.nearbyUnits[unit]; B.nearbyUnits[unit]=nil; B:InvalidateAura(unit)
    -- Preserve arrival order through short nameplate hide/show cycles.
  elseif event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED" then
    B.nearbyUnits={}; B.nearbyOrder={}; if not A.Combat() then B:SeedNearby() end
    B:ScheduleNearbySettle()
  elseif event=="CVAR_UPDATE" then
    if not A.Text(unit) or (unit:lower()~="nameplateshowfriends" and unit:lower()~="nameplateshowfriendlyplayers") then return end
    if not A.Combat() then B:SeedNearby(); B:ScheduleNearbySettle() end
  end
  B.nearbySnapshot=nil; B:RequestRefresh("nearby players changed",.12)
end)
function B:WatchNearbyRange()
  self:CancelTimer("nearby-range")
  if not self.db.nearbyEnabled or not self.db.enabled or not platesOn() or A.Combat()
    or self:ReminderPauseReason() or not next(self.nearbyProbes or {}) then return end
  self:StartTimer("nearby-range",1,function()
    if A.Combat() or not B.db.nearbyEnabled then return end
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
  self.nearbySnapshot=nil
  local result=refresh(self,...)
  if self.db and not A.Combat() then
    local ok,err=pcall(self.UpdateNearbyWindow,self)
    if not ok then self.nearbySetupError="Nearby window unavailable"; self:AddDiag(self.nearbySetupError) end
    self:WatchNearbyRange()
    if self.db.nearbyEnabled and self.nextWakeDelay then self:ScheduleWake(self.nextWakeDelay+.03,"nearby threshold/retry") end
  end
  return result
end
local validate=B.Validate
function B:Validate(action)
  if action and action.nearby and not self:NearbyEntry(action.target) then return false,"nearby player no longer eligible" end
  return validate(self,action)
end
local slash=SlashCmdList.BUFFTAP
SlashCmdList.BUFFTAP=function(text)
  if (text or ""):match("^%s*nearby%s*$") then B:ShowNearbySetup(); return end
  return slash(text)
end
local diagnostics=B.DiagnosticsLines
function B:DiagnosticsLines()
  local out=diagnostics(self); local tracked=0
  local plates,setting=plateSetting()
  for _ in pairs(self.nearbyUnits or {}) do tracked=tracked+1 end
  out[#out+1]="Nearby experiment: "..tostring(self.db.nearbyEnabled==true).." | friendly nameplates: "..tostring(plates).." ("..setting..")"
    .." | tracked: "..tracked.."/40 | eligible: "..#(self.nearbySnapshot or {})
  out[#out]=out[#out].." | cast: exact-name/cast/restore | notifications: quiet"
  if self.nearbyLastClick then out[#out]=out[#out].." | last click: "..self.nearbyLastClick end
  if self.nearbyClickError then out[#out]=out[#out].." | client error: "..self.nearbyClickError end
  if self.nearbyCastError then out[#out+1]="Nearby cast: "..self.nearbyCastError end
  if self.nearbySetupError then out[#out+1]=self.nearbySetupError end
  return out
end
local status=B.Status
function B:Status(verbose)
  status(self,verbose)
  if verbose and DEFAULT_CHAT_FRAME then
    local lines=self:DiagnosticsLines()
    DEFAULT_CHAT_FRAME:AddMessage("BuffTap "..lines[#lines])
  end
end
