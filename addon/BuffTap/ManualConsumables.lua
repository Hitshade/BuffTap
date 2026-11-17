-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Independent explicit-click consumables. Never install a binding or use B.action.
local _,B=...
local A=B.API
local LIMIT,SIZE,GAP=8,22,4
B.ManualConsumableLimit=LIMIT
-- Anchor is the center of the first icon row, independent of row count.
function B:ManualConsumableAnchor()
  local d=self.db
  if d.manualConsumablesDetached then return d.manualConsumablesX or 0,d.manualConsumablesY or 0 end
  local labels=d.labelPosition=="above" and 0 or (d.showTargetName and 1 or 0)
  if d.labelPosition=="below" and d.showBuffName then labels=labels+1 end
  local height=labels>0 and labels*math.max(10,d.labelSize or 10)+(d.labelGap or 5)+(labels-1)*2 or 0
  return d.x,d.y-d.size/2-height-35
end
function B:SetManualConsumablesDetached(detached)
  if A.Combat() then return false end
  detached=detached==true
  if detached and not self.db.manualConsumablesDetached then
    self.db.manualConsumablesX,self.db.manualConsumablesY=self:ManualConsumableAnchor()
  end
  self.db.manualConsumablesDetached=detached
  self:Refresh(false)
  if self.editModeActive then self:ShowEditMovers() end
  return true
end
function B:ManualConsumableOffset(index,total)
  local row=math.floor((index-1)/4)
  local columns=math.min(4,total)
  local inRow=math.min(4,total-row*4)
  return (columns-inRow)*(SIZE+GAP)/2+((index-1)%4)*(SIZE+GAP),-row*(SIZE+GAP)
end
local safety=[[
  if newstate == "blocked" then
    self:SetAttribute("type1",nil)
    self:SetAttribute("item",nil)
    self:SetAttribute("unit",nil)
    self:Hide()
  end
  -- Ready does not restore an item. Lua must re-evaluate outside combat.
]]
local condition="[combat][@player,dead][mounted][vehicleui][petbattle][stealth] blocked; ready"

local function unsafe()
  return A.Combat() or A.Call(UnitIsDeadOrGhost,"player")~=false or A.Call(IsMounted)~=false
    or A.Call(UnitInVehicle,"player")~=false or B:Stealthed()
    or (C_PetBattles and A.Call(C_PetBattles.IsInBattle)~=false)
end

function B:DisarmManualButton(button,reason)
  if A.Combat() then return end
  button:SetAttribute("type1",nil); button:SetAttribute("item",nil); button:SetAttribute("unit",nil)
  button.action=nil; button.attemptAction=nil
  if reason then button.reason=reason end
end
function B:DisarmManualConsumables()
  if A.Combat() then return end
  for _,button in ipairs(self.manualConsumableButtons or {}) do self:DisarmManualButton(button); button:Hide() end
  if self.manualConsumableCaption then self.manualConsumableCaption:Hide() end
end

-- Projection reads effect state and existing stock/metadata only. It never validates,
-- confirms uses, starts retries, quarantines items, or installs protected payloads.
function B:ManualConsumableProjection(auras,cache)
  local entries,seen={},{}
  local nextWake
  if not self.db or not self.db.enabled or not self:Preference("consumablesEnabled") then return entries end
  for _,family in ipairs(self.ConsumableFamilies or {}) do
    if not family.multi and self:ConsumableMode(family)=="manual" and self:ConsumableFamilyEnabled(family) then
      local missing,state,_,_,wake=self:ConsumableFamilyState(family,auras)
      if A.Number(wake) and wake>0 then nextWake=math.min(nextWake or wake,wake) end
      if missing~=false then
        local chosen=self:ConsumableChoiceID(family)
        local item,unknown
        for _,candidate in ipairs(family.items or {}) do
          if not chosen or chosen==candidate.id then
            item=item or candidate
            local count=cache and cache.counts and cache.counts[candidate.id]
            if count==nil then unknown=true end
            if type(count)=="number" and count>0 then item=candidate; unknown=false; break end
          end
        end
        if item then
          local ids={}; for _,id in ipairs(family.auraSpellIDs or {}) do ids[#ids+1]=id end; table.sort(ids)
          local effect=(family.parent and family.parent.key or family.key)..":"..(family.line or table.concat(ids,","))
          if not seen[effect] then
            seen[effect]=true
            local meta=self.itemMeta and self.itemMeta[item.id]
            local count=cache and cache.counts and cache.counts[item.id]
            if unknown then count=nil end
            entries[#entries+1]={family=family,item=item,count=count,
              name=meta and meta.name or item.name,icon=meta and meta.texture or item.icon or 134400,
              state=missing==nil and "Buff state unknown" or state,wake=wake,unknown=missing==nil}
          end
        end
      end
    end
  end
  return entries,nextWake
end

function B:ValidateManualConsumable(button)
  local action=button.action
  if unsafe() or button:GetAttribute("state-safety")~="ready" then return false,"Unavailable in this state" end
  if self:SyncSituation() then return false,"setup changed before item validation" end
  if not action or not action.manualConsumable or not self.db.enabled then return false,"This reminder is turned off." end
  if button.profile~=(self.profileDB and self.profileDB:GetCurrentProfile()) or button.db~=self.db then return false,"setup changed before item validation" end
  if not A.Text(action.targetGUID) or A.Call(UnitGUID,"player")~=action.targetGUID then return false,"Player identity unavailable" end
  if button:GetAttribute("type1")~="item" or button:GetAttribute("item")~=action.itemToken or button:GetAttribute("unit")~="player" then return false,"Item changed before click" end
  local pause=self:ActionPauseReason(action); if pause then return false,pause end
  local attempt=self.itemAttempts and self.itemAttempts[action.itemID]
  if attempt and GetTime()-attempt.at<=3 then return false,"Waiting for item use" end
  -- Explicit clicks request fresh metadata, stock and auras for the stored item only.
  if self.itemMeta then self.itemMeta[action.itemID]=nil end
  return self:ValidateConsumable(action,true,true)
end

local function newButton(index,holder)
  local button=CreateFrame("Button","BuffTapManualItem"..index,holder,"SecureActionButtonTemplate,SecureHandlerStateTemplate")
  button:Hide(); button:SetSize(SIZE,SIZE); button:SetClampedToScreen(true)
  button:RegisterForClicks("LeftButtonUp"); button:SetAttribute("useOnKeyDown",false)
  for _,key in ipairs({"checkselfcast","checkfocuscast","checkmouseovercast"}) do button:SetAttribute(key,false) end
  button:SetAttribute("_onstate-safety",safety)
  if type(RegisterStateDriver)~="function" or not pcall(RegisterStateDriver,button,"safety",condition) then
    button.driverFailed=true; return button
  end
  button.icon=button:CreateTexture(nil,"ARTWORK"); button.icon:SetAllPoints(); button.icon:SetTexCoord(.07,.93,.07,.93)
  button.count=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); button.count:SetPoint("BOTTOMRIGHT",1,-1)
  button.count:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE")
  button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  button:SetScript("OnEnter",function(s)
    if not GameTooltip or A.Combat() then return end
    GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:SetText(s.title or B:Text("Manual consumables"))
    if s.entry then
      GameTooltip:AddLine(B:Text(s.entry.family.name),.75,.75,.75)
      GameTooltip:AddLine(s.entry.count==nil and B:Text("Stock unknown") or B:Text("%d in bags",s.entry.count),1,1,1)
      GameTooltip:AddLine(B:Text(s.action and "Click to use" or (s.reason or "Unavailable in this state")),1,.8,.3,true)
    elseif s.overflow then GameTooltip:AddLine(s.overflow,.85,.85,.85,true) end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  button:SetScript("PreClick",function(s,mouse,down)
    s.attemptAction=nil
    if mouse~="LeftButton" or down==true or A.Combat() then return end
    local ok,valid,reason=pcall(B.ValidateManualConsumable,B,s)
    if not ok or not valid then
      B:DisarmManualButton(s,ok and reason or "Item validation unavailable")
      B:InvalidateConsumables(); B:InvalidateAura("player")
      B:RequestRefresh("manual click rejected",.05); return
    end
    s.attemptAction=s.action; B:BeforeConsumableClick(s.attemptAction)
  end)
  button:SetScript("PostClick",function(s,mouse,down)
    if mouse~="LeftButton" or down==true or A.Combat() then return end
    local action=s.attemptAction
    B:DisarmManualButton(s,"Waiting for item use")
    if action then B:AfterConsumableClick(action) end
    B:RequestRefresh("manual item click",.05)
  end)
  return button
end

function B:UpdateManualConsumables()
  if A.Combat() then return end -- the secure drivers disarm/hide; never mutate protected frames here
  local any=false
  if self.db and self.db.enabled and self:Preference("consumablesEnabled") then
    for key,mode in pairs(self:Preference("consumableModes") or {}) do
      local family=mode=="manual" and self:ConsumableFamily(key)
      if family and not family.hidden and self:ConsumableFamilyEnabled(family) then any=true; break end
    end
  end
  if not any or unsafe() or self.editModeActive then self:DisarmManualConsumables(); return end
  local entries,nextWake=self:ManualConsumableProjection(self:GetAuras("player",false),self:RebuildConsumableCache(false))
  self:ConsiderWake(nextWake)
  self.manualConsumableEntries=entries
  if #entries==0 then self:DisarmManualConsumables(); return end
  if not self.manualConsumableHolder then
    local holder=CreateFrame("Frame",nil,UIParent); holder:SetFrameStrata("HIGH"); holder:SetClampedToScreen(true)
    holder:EnableMouse(false); self.manualConsumableHolder=holder; self.manualConsumableButtons={}
    local caption=CreateFrame("Frame",nil,holder,"SecureHandlerStateTemplate")
    caption:SetSize(160,12); caption:SetPoint("BOTTOM",holder,"TOP",0,4); caption:EnableMouse(false); caption:Hide()
    caption.text=caption:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    caption.text:SetAllPoints(); caption.text:SetJustifyH("CENTER"); caption.text:SetText(self:Text("Consumables"))
    caption.text:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE"); caption.text:SetTextColor(.6,.63,.67)
    caption:SetAttribute("_onstate-safety",safety)
    caption.driverFailed=type(RegisterStateDriver)~="function" or not pcall(RegisterStateDriver,caption,"safety",condition)
    self.manualConsumableCaption=caption
  end
  local holder=self.manualConsumableHolder
  local shown=math.min(#entries,LIMIT); local total=shown+(#entries>LIMIT and 1 or 0)
  holder:SetSize(math.min(4,total)*(SIZE+GAP)-GAP,math.ceil(total/4)*(SIZE+GAP)-GAP)
  holder:ClearAllPoints()
  local anchorX,anchorY=self:ManualConsumableAnchor()
  holder:SetPoint("TOP",UIParent,"CENTER",anchorX,anchorY+SIZE/2)
  holder:SetAlpha(self.db.opacity); holder:Show()
  local caption=self.manualConsumableCaption
  caption:SetShown(not caption.driverFailed and caption:GetAttribute("state-safety")=="ready")
  for i=1,LIMIT+1 do
    local button=self.manualConsumableButtons[i]
    if not button and i<=total then button=newButton(i,holder); self.manualConsumableButtons[i]=button end
    if button then
      self:DisarmManualButton(button); button.entry=nil; button.overflow=nil
      local entry=entries[i]
      if i<=shown and entry and not button.driverFailed then
        local family=entry.family; local action,why
        if not entry.unknown then
          local pause=self:ActionPauseReason({source="consumable"}) or self:CategoryRestingPause("consumables")
          if not pause then action,why=self:ResolveConsumable(family,true) else why=pause end
        else why="Buff state unknown" end
        if action then
          local valid,reason=self:ValidateConsumable(action,false,true)
          if action.stock~=nil then entry.count=action.stock end
          if not valid then action=nil; why=reason end
        end
        if action then
          local attempt=self.itemAttempts and self.itemAttempts[action.itemID]
          if attempt and GetTime()-attempt.at<=3 then
            self:ConsiderWake(attempt.at+3.05-GetTime()); action=nil; why="Waiting for item use"
          end
        end
        if action then
          entry.item={id=action.itemID}; entry.name=action.name; entry.icon=action.icon
          entry.count=action.stock
          if entry.count==nil then action=nil; why="Stock unknown" end
        end
        button.entry=entry; button.title=entry.name; button.reason=why
        button.icon:SetTexture(entry.icon); button.icon:SetDesaturated(not action)
        button.count:SetText(entry.count==nil and "?" or tostring(entry.count))
        if entry.count==nil or entry.unknown then button.count:SetTextColor(.7,.7,.7)
        elseif entry.count==0 then button.count:SetTextColor(1,.3,.3)
        elseif entry.count<=3 then button.count:SetTextColor(1,.7,.1)
        else button.count:SetTextColor(1,1,1) end
        if entry.unknown then button.count:SetText("?") end
        button.icon:SetAlpha(action and 1 or .45)
        if action and button:GetAttribute("state-safety")=="ready" then
          button.action=action; button.db=self.db; button.profile=self.profileDB and self.profileDB:GetCurrentProfile()
          button:SetAttribute("item",action.itemToken); button:SetAttribute("unit","player"); button:SetAttribute("type1","item")
        end
        self:ConsiderWake(entry.wake)
        local x,y=self:ManualConsumableOffset(i,total)
        button:ClearAllPoints(); button:SetPoint("TOPLEFT",holder,"TOPLEFT",x,y); button:Show()
      elseif i==total and #entries>LIMIT and not button.driverFailed then
        local names={self:Text("Additional effects: use their items from your bags.")}
        for j=LIMIT+1,#entries do names[#names+1]=entries[j].name end
        button.overflow=table.concat(names,"\n"); button.title=self:Text("Manual consumables")
        button.icon:SetTexture("Interface\\Buttons\\UI-Quickslot2"); button.icon:SetDesaturated(false); button.icon:SetAlpha(.6)
        button.count:SetText("+"..(#entries-LIMIT)); button.count:SetTextColor(.8,.8,.8)
        local x,y=self:ManualConsumableOffset(i,total)
        button:ClearAllPoints(); button:SetPoint("TOPLEFT",holder,"TOPLEFT",x,y); button:Show()
      else button:Hide() end
    end
  end
end
