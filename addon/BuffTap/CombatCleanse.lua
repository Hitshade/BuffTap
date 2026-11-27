-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Self-targeted secure click control with native aura indicators.
-- Invisible hit area is explicitly opt-in and persists during combat.
-- Blizzard owns warning visibility; no addon aura inspection in combat.
local _,B=...
local A=B.API
local ORDER={"Disease","Poison","Curse","Magic"} -- last slot draws above earlier slots
local BUTTONS={DRUID={Curse=1,Poison=2},PRIEST={Magic=1,Disease=2},
  MAGE={Curse=1},PALADIN={Magic=1,Poison=1,Disease=1},SHAMAN={Poison=1,Disease=2}}
local VISIBILITY="[combat,nodead] show; hide"
local function text(s,...) return B:Text(s,...) end
B.CombatCleanseSafetyText="Combat clicks follow current unit slots and bypass BuffTap's blacklist and PvP protection. Never cleanse exclusions are not guaranteed. Check the player and debuff before clicking."

function B:CombatCleansePlan()
  local out={}; local map=BUTTONS[A.Class("player")] or {}
  local abilities=self:CleanseAbilities()
  for _,kind in ipairs(ORDER) do
    local specs=abilities[kind]
    if map[kind] and specs and specs[1] and self.db.cleanseTypes[kind]~=false then
      local id=specs[1][1]
      local name=A.Call(C_Spell and C_Spell.GetSpellName,id)
      if A.Text(name) then out[#out+1]={kind=kind,id=id,button=map[kind],name=name} end
    end
  end
  return out
end

local function retire(self)
  local f=self.combatCleanseFrame
  if f then
    UnregisterStateDriver(f,"visibility")
    f:Hide()
    if f.container then f.container:SetEnabled(false) end
  end
  self.combatCleanseFrame=nil; self.combatCleanseSignature=nil
end

local function position(self,f,size)
  local d=self.db
  local x=A.Number(d.x) and d.x or 0
  local y=A.Number(d.y) and d.y or 0
  f:SetSize(size,size); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",x,y)
  f:SetAlpha(A.Number(d.opacity) and d.opacity or 1)
  f:SetFrameStrata(self:GameplayStrata("buff")); f:SetClampedToScreen(true)
end

-- GetAuraSlotFrame is used only out of combat. Keep cosmetic resources, never
-- aura data, visibility observations or a retained native button reference.
local function decorate(button,size,entry,priority,options,v)
  options=options or {}; v=v or {}
  button:ClearAllPoints(); button:SetAllPoints(button:GetParent())
  button:SetFrameLevel(button:GetParent():GetFrameLevel()+priority+2)
  if not v.icon then v.icon=button:CreateTexture(nil,"ARTWORK"); v.icon:SetAllPoints(); button:SetIcon(v.icon) end
  B:ApplyIconStyle(button,v.icon,options.style or B.db.iconStyle)
  button:ClearDispelTypeTextures()
  local colorMap
  if options.colors and type(CreateColor)=="function" then
    colorMap={}; for kind,c in pairs(options.colors) do colorMap[kind]=CreateColor(c[1],c[2],c[3],1) end
  end
  v.borders=v.borders or {}
  for i,edge in ipairs({{"TOPLEFT","TOPRIGHT"},{"BOTTOMLEFT","BOTTOMRIGHT"},{"TOPLEFT","BOTTOMLEFT"},{"TOPRIGHT","BOTTOMRIGHT"}}) do
    local border=v.borders[i]
    if not border then
      border=button:CreateTexture(nil,"OVERLAY"); border:SetPoint(edge[1],button,edge[1]); border:SetPoint(edge[2],button,edge[2])
      if i<=2 then border:SetHeight(2) else border:SetWidth(2) end
      border:SetColorTexture(1,1,1,1); v.borders[i]=border
    end
    button:AddDispelTypeTexture(border,{showWhenHarmful=true,showWhenHelpful=false,
      showWithoutDispelType=false,style=Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,customDispelColorMap=colorMap})
  end
  if options.compact then
    if not v.cue then
      v.cue=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); v.cue:SetPoint("BOTTOMRIGHT",-1,1)
      v.cue:SetShadowColor(0,0,0,1); v.cue:SetShadowOffset(1,-1)
    end
    v.cue:SetText(entry.button==1 and "L" or "R")
    local font,_,flags=v.cue:GetFont(); if font then v.cue:SetFont(font,math.max(8,math.min(12,size*.4)),flags) end
  else
    if not v.caption then
      v.backing=button:CreateTexture(nil,"OVERLAY",nil,2); v.backing:SetPoint("BOTTOMLEFT",2,2); v.backing:SetPoint("BOTTOMRIGHT",-2,2)
      v.backing:SetHeight(18); v.backing:SetColorTexture(0,0,0,.85)
      v.caption=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); v.caption:SetPoint("BOTTOM",0,5)
      v.kind=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); v.kind:SetPoint("TOP",0,-5)
      v.kind:SetShadowColor(0,0,0,1); v.kind:SetShadowOffset(1,-1)
    end
    v.caption:SetText(size<40 and (entry.button==1 and "L" or "R") or text(entry.button==1 and "Left click" or "Right click"))
    v.kind:SetText(text(entry.kind)); v.kind:SetShown(size>=48)
  end
  return v
end

function B:CombatCleansePlanKey(plan)
  local parts={}
  for _,p in ipairs(plan) do parts[#parts+1]=p.kind..":"..p.id..":"..p.name end
  local exclusions={}
  for id in pairs(self.CleanseBuiltInNever) do if not self:CleanseBuiltInAllowed()[id] then exclusions[#exclusions+1]=id end end
  table.sort(exclusions); for _,id in ipairs(exclusions) do parts[#parts+1]=tostring(id) end
  return table.concat(parts,"|")
end

function B:ConfigureCombatCleanseButton(root,unit,plan,size,options)
  if A.Combat() then return end
  root:SetAttribute("unit",unit); root:SetAttribute("useOnKeyDown",false)
  root:SetAttribute("checkselfcast",false); root:SetAttribute("checkfocuscast",false); root:SetAttribute("checkmouseovercast",false)
  for i=1,2 do root:SetAttribute("*type"..i,nil); root:SetAttribute("*spell"..i,nil) end
  for _,action in ipairs(plan) do root:SetAttribute("*type"..action.button,"spell"); root:SetAttribute("*spell"..action.button,action.id) end
  root.cleansePlan=plan
  root:RegisterForClicks("LeftButtonUp","RightButtonUp")
  if not root.cleanseInputHooked then
    root.cleanseInputHooked=true
    root:HookScript("PostClick",function(_,button,down)
      if down then return end
      B.combatCleanseInputCount=(B.combatCleanseInputCount or 0)+1
      B.combatCleanseLastInput=A.Text(button) and button or "unreadable"; B.combatCleanseLastUnit=unit
    end)
  end
  local c=root.container
  if not c then
    c=CreateFrame("AuraContainer",nil,root,"CustomAuraContainerTemplate"); root.container=c
    c:SetAllPoints(root); c:EnableMouse(false); root.cleanseSlots={}; root.cleanseVisuals={}
  end
  assert(type(c.AddAuraSlot)=="function" and type(c.GetAuraSlotFrame)=="function" and type(c.SetAuraSlotEnabled)=="function" and type(c.SetAuraSlotCandidateFilters)=="function")
  local excluded,active={},{}
  for id in pairs(self.CleanseBuiltInNever) do if not self:CleanseBuiltInAllowed()[id] then excluded[id]=true end end
  for index,entry in ipairs(plan) do
    local prepared=entry; local key="BUFFTAP_SELF_"..entry.kind; active[entry.kind]=true
    local filters={includeDispelTypes={[entry.kind]=true},excludeSpellIDs=excluded}
    if not root.cleanseSlots[entry.kind] then
      c:AddAuraSlot(key,"HARMFUL",{sortMethod=0,sortDirection=0,candidateFilters=filters,
        initializeFrame=function(ab)
          if A.Combat() then
            B.combatCleanseLateInitialization=true; B.combatCleanseSignature=nil; B.combatGridSignature=nil; B.combatGridLayoutKey=nil
            return
          end
          root.cleanseVisuals[prepared.kind]=decorate(ab,size,prepared,index,options)
          ab:SetCancelAuraButtons(nil); ab:EnableMouse(false)
        end})
      root.cleanseSlots[entry.kind]=key
      assert(root.cleanseVisuals[entry.kind],"native cleanse initialization incomplete")
    else
      c:SetAuraSlotCandidateFilters(key,filters)
      local ab=c:GetAuraSlotFrame(key); assert(ab,"native cleanse slot unavailable")
      root.cleanseVisuals[entry.kind]=decorate(ab,size,prepared,index,options,root.cleanseVisuals[entry.kind])
      ab:SetCancelAuraButtons(nil); ab:EnableMouse(false)
    end
    c:SetAuraSlotEnabled(key,true)
  end
  for kind,key in pairs(root.cleanseSlots) do if not active[kind] then c:SetAuraSlotEnabled(key,false) end end
  c:SetUnit(unit); c:SetEnabled(true); c:Show()
end

function B:SyncCombatCleanse()
  if not self.db or A.Combat() then return end
  local d=self.db
  local preview=self.combatCleansePreview
  if preview and preview:IsShown() then
    position(self,preview,d.size or 64)
    self:ApplyIconStyle(preview,preview.icon,d.iconStyle)
  end
  if not d.enabled or d.combatCleanse~=true or d.cleanseEnabled~=true or d.cleanseSelf==false then
    retire(self); self.combatCleanseSignature=nil; self.combatCleanseError=nil; self.combatCleanseErrorDetail=nil; return
  end
  local plan=self:CombatCleansePlan()
  local size=A.Number(d.size) and d.size or 64
  local signature={tostring(size),tostring(d.x),tostring(d.y),tostring(d.opacity),tostring(d.iconStyle),self:GameplayStrata("buff")}
  signature[#signature+1]=self:CombatCleansePlanKey(plan)
  signature=table.concat(signature,"|")
  if self.combatCleanseSignature==signature then return end
  self.combatCleanseError=nil; self.combatCleanseErrorDetail=nil
  if #plan==0 then retire(self); self.combatCleanseError=text("No learned cleanse spell for the selected types."); return end
  local root
  local ok,setupError=pcall(function()
    assert(type(RegisterStateDriver)=="function" and type(UnregisterStateDriver)=="function")
    assert(Enum and Enum.CustomAuraButtonDispelTypeTextureStyle and Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset)
    root=self.combatCleansePool
    if not root then
      root=CreateFrame("Button",nil,UIParent,"SecureActionButtonTemplate,SecureHandlerStateTemplate"); self.combatCleansePool=root
    end
    root:Hide(); root:EnableMouse(true)
    position(self,root,size)
    local visualKey=tostring(size).."|"..tostring(d.iconStyle).."|"..self:CombatCleansePlanKey(plan)
    if root.cleanseVisualKey~=visualKey then
      self:ConfigureCombatCleanseButton(root,"player",plan,size); root.cleanseVisualKey=visualKey
    else root.container:SetEnabled(true) end
    RegisterStateDriver(root,"visibility",VISIBILITY)
    self.combatCleanseSignature=signature
  end)
  if not ok then
    if root then
      pcall(UnregisterStateDriver,root,"visibility"); pcall(root.Hide,root)
      if root.container then pcall(root.container.SetEnabled,root.container,false) end
    end
    self.combatCleanseFrame=nil; self.combatCleanseSignature=nil
    self.combatCleanseError=text("Combat cleanse setup unavailable on this client.")
    self.combatCleanseErrorDetail=A.Text(setupError) and setupError:sub(1,250) or "unreadable setup error"
    return
  end
  self.combatCleanseFrame=root
end

function B:PreviewCombatCleanse()
  if A.Combat() then return end
  self:SyncCombatCleanse()
  local f=self.combatCleansePreview
  if f and f:IsShown() then f:Hide(); return end
  if not f then
    f=CreateFrame("Frame",nil,UIParent); f:EnableMouse(false)
    f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetAllPoints(); f.icon:SetTexture("Interface\\Icons\\Spell_Holy_DispelMagic")
    f.caption=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f.caption:SetPoint("BOTTOM",0,5)
    f.kind=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.kind:SetPoint("TOP",0,-5)
    local label=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    label:SetPoint("TOP",f,"BOTTOM",0,-5); label:SetText(text("Preview: uses your buff icon position"))
    self.combatCleansePreview=f
  end
  local first=self:CombatCleansePlan()[1]
  f.caption:SetText(text(first and first.button==2 and "Right click" or "Left click"))
  f.kind:SetText(text(first and first.kind or "Preview"))
  position(self,f,self.db.size or 64); self:ApplyIconStyle(f,f.icon,self.db.iconStyle); f:Show()
end

local build=B.BuildCleansePage
function B:BuildCleansePage(ui,...)
  build(self,ui,...)
  local f=self.options; if not f or not f.cleanseBorder then return end
  local p=f.cleansePanes and f.cleansePanes.combat or f.cleanseBorder:GetParent()
  f.combatCleanse=ui.check(p,"Yourself (main icon)",28,-137,function(c)
    if A.Combat() then return end
    B.db.combatCleanse=c:GetChecked()==true; B:SyncCombatCleanse(); B:UpdateCleansePage()
  end)
  f.combatCleanse:HookScript("OnEnter",function(s)
    B.OptionsTheme.Tooltip(s,text("Combat cleansing: yourself"),text("Self-targeted combat cleansing, including while grouped. Enable cleansing and You. Follow the Left click or Right click label. The invisible click area stays active throughout combat, even without a warning. Uses your main buff icon settings; your normal binding is unchanged.").."\n\n"..text(B.CombatCleanseSafetyText),B.combatCleanseError or nil)
  end)
  f.combatCleanse:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.combatCleansePreviewButton=ui.button(p,"Self preview",550,-137,138,function() B:PreviewCombatCleanse() end)
  f.combatCleansePreviewButton:SetHeight(24)
  f.combatCleansePreviewButton:HookScript("OnEnter",function(s)
    B.OptionsTheme.Tooltip(s,text("Preview"),text("Uses your buff reminder position, size, opacity and icon style. Move or resize your usual buff icon to customize both. This preview cannot cast."),B.combatCleanseErrorDetail or B.combatCleanseError)
  end)
  f.combatCleansePreviewButton:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
local update=B.UpdateCleansePage
function B:UpdateCleansePage(...)
  update(self,...)
  local f=self.options
  if f and f.combatCleanse then
    f.combatCleanse:SetShown(self:CanCleanseAnything()); f.combatCleanse:SetChecked(self.db.combatCleanse==true)
    f.combatCleansePreviewButton:SetShown(self:CanCleanseAnything())
    if self.combatCleanseError then f.combatCleansePreviewButton:SetText(text("Setup unavailable"))
    else f.combatCleansePreviewButton:SetText(text("Self preview")) end
  end
end

local refresh=B.Refresh
function B:Refresh(...)
  local result=refresh(self,...)
  if self.db and not A.Combat() then self:SyncCombatCleanse() end
  return result
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","SPELLS_CHANGED","GROUP_ROSTER_UPDATE"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_REGEN_DISABLED" and B.combatCleansePreview then B.combatCleansePreview:StopMovingOrSizing(); B.combatCleansePreview:Hide() end
  if not A.Combat() then B:SyncCombatCleanse() end
end)
B.combatCleanseEvents=events

-- No aura lookup, slot access or protected writes: safe to include in Full check-up.
function B:CombatCleanseProbeLines()
  return {"Combat self-cleanse: enabled="..tostring(self.db and self.db.combatCleanse==true)..
    " | prepared="..tostring(self.combatCleanseFrame~=nil).." | invisible hit area during combat | self only",
    "Combat cleanse input: count="..tostring(self.combatCleanseInputCount or 0).." | last="..tostring(self.combatCleanseLastInput or "none"),
    "Native setup: late initialization="..tostring(self.combatCleanseLateInitialization==true).." | "..(self.combatCleanseErrorDetail or self.combatCleanseError or "no setup error recorded")}
end
