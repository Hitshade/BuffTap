-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Experimental self-only secure click target with native aura indicators.
-- Invisible hit area is explicitly opt-in and persists during combat.
-- Blizzard owns warning visibility; no addon aura inspection in combat.
local _,B=...
local A=B.API
local ORDER={"Disease","Poison","Curse","Magic"} -- last slot draws above earlier slots
local BUTTONS={DRUID={Curse=1,Poison=2},PRIEST={Magic=1,Disease=2},
  MAGE={Curse=1},PALADIN={Magic=1,Poison=1,Disease=1},SHAMAN={Poison=1,Disease=2}}
local VISIBILITY="[combat,nodead] show; hide"
local function text(s,...) return B:Text(s,...) end

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
  self.combatCleanseFrame=nil
end

local function position(self,f,size)
  local d=self.db
  local x=A.Number(d.x) and d.x or 0
  local y=A.Number(d.y) and d.y or 0
  f:SetSize(size,size); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",x,y)
  f:SetAlpha(A.Number(d.opacity) and d.opacity or 1)
  f:SetFrameStrata(self:GameplayStrata("buff")); f:SetClampedToScreen(true)
end

local function decorate(button,size,entry,priority,options)
  options=options or {}
  button:SetSize(size,size); button:ClearAllPoints(); button:SetPoint("CENTER",button:GetParent(),"CENTER",0,0)
  button:SetFrameLevel(button:GetParent():GetFrameLevel()+priority+2)
  local icon=button:CreateTexture(nil,"ARTWORK"); icon:SetAllPoints()
  button:SetIcon(icon)
  if B.ApplyIconStyle then B:ApplyIconStyle(button,icon,options.style or B.db.iconStyle) end
  button:ClearDispelTypeTextures()
  local colorMap
  if options.colors and type(CreateColor)=="function" then
    colorMap={}; for kind,c in pairs(options.colors) do colorMap[kind]=CreateColor(c[1],c[2],c[3],1) end
  end
  for _,edge in ipairs({{"TOPLEFT","TOPRIGHT",size,2},{"BOTTOMLEFT","BOTTOMRIGHT",size,2},
    {"TOPLEFT","BOTTOMLEFT",2,size},{"TOPRIGHT","BOTTOMRIGHT",2,size}}) do
    local border=button:CreateTexture(nil,"OVERLAY")
    border:SetPoint(edge[1],button,edge[1]); border:SetPoint(edge[2],button,edge[2]); border:SetSize(edge[3],edge[4])
    border:SetColorTexture(1,1,1,1)
    button:AddDispelTypeTexture(border,{showWhenHarmful=true,showWhenHelpful=false,
      showWithoutDispelType=false,style=Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,customDispelColorMap=colorMap})
  end
  if options.compact then
    local cue=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    cue:SetPoint("BOTTOMRIGHT",-1,1); cue:SetText(entry.button==1 and "L" or "R")
    local font,_,flags=cue:GetFont(); if font then cue:SetFont(font,math.max(8,math.min(12,size*.4)),flags) end
    cue:SetShadowColor(0,0,0,1); cue:SetShadowOffset(1,-1)
    return
  end
  local backing=button:CreateTexture(nil,"OVERLAY",nil,2)
  backing:SetPoint("BOTTOMLEFT",2,2); backing:SetPoint("BOTTOMRIGHT",-2,2); backing:SetHeight(18); backing:SetColorTexture(0,0,0,.85)
  local caption=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  caption:SetPoint("BOTTOM",0,5); caption:SetText(size<40 and (entry.button==1 and "L" or "R") or text(entry.button==1 and "Left click" or "Right click"))
  local kind=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  kind:SetPoint("TOP",0,-5); kind:SetText(text(entry.kind)); kind:SetShown(size>=48); kind:SetShadowColor(0,0,0,1); kind:SetShadowOffset(1,-1)
end

function B:ConfigureCombatCleanseButton(root,unit,plan,size,options)
  local initialized=0
    root:SetAttribute("unit",unit)
    root:SetAttribute("useOnKeyDown",false)
    root:SetAttribute("checkselfcast",false); root:SetAttribute("checkfocuscast",false); root:SetAttribute("checkmouseovercast",false)
    for _,action in ipairs(plan) do
      root:SetAttribute("*type"..action.button,"spell")
      root:SetAttribute("*spell"..action.button,action.id)
    end
    root:RegisterForClicks("LeftButtonUp","RightButtonUp")
    -- Observe input only; no protected writes, aura reads or cast decisions here.
    root:HookScript("PostClick",function(_,button,down)
      if down then return end
      B.combatCleanseInputCount=(B.combatCleanseInputCount or 0)+1
      B.combatCleanseLastInput=A.Text(button) and button or "unreadable"
      B.combatCleanseLastUnit=unit
    end)
    local c=CreateFrame("AuraContainer",nil,root,"CustomAuraContainerTemplate")
    assert(type(c.AddAuraSlot)=="function" and type(c.SetUnit)=="function" and type(c.SetEnabled)=="function")
    root.container=c; c:SetAllPoints(root); c:EnableMouse(false)
    local excluded={}
    for id in pairs(self.CleanseBuiltInNever) do if not self:CleanseBuiltInAllowed()[id] then excluded[id]=true end end
    for index,entry in ipairs(plan) do
      local prepared=entry
      c:AddAuraSlot("BUFFTAP_SELF_"..prepared.kind,"HARMFUL",{
        sortMethod=0,sortDirection=0,
        candidateFilters={includeDispelTypes={[prepared.kind]=true},excludeSpellIDs=excluded},
        initializeFrame=function(ab)
          assert(not A.Combat(),"native cleanse button initialized during combat")
          -- Never retain or inspect ab after this callback: it becomes forbidden.
          assert(type(ab.SetIcon)=="function" and type(ab.AddDispelTypeTexture)=="function")
          decorate(ab,size,prepared,index,options)
          ab:SetCancelAuraButtons(nil)
          -- These native frames are indicators only. Their forbidden script/input
          -- restrictions must not own the cast. Input passes to the secure parent.
          ab:EnableMouse(false)
          initialized=initialized+1
        end,
      })
    end
    assert(initialized==#plan,"native cleanse initialization incomplete")
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
  for _,entry in ipairs(plan) do signature[#signature+1]=entry.kind..":"..entry.id end
  signature=table.concat(signature,"|")
  if self.combatCleanseSignature==signature then return end
  retire(self); self.combatCleanseSignature=signature; self.combatCleanseError=nil; self.combatCleanseErrorDetail=nil
  if #plan==0 then self.combatCleanseError=text("No learned cleanse spell for the selected types."); return end
  local root
  local ok,setupError=pcall(function()
    assert(type(RegisterStateDriver)=="function" and type(UnregisterStateDriver)=="function")
    assert(Enum and Enum.CustomAuraButtonDispelTypeTextureStyle and Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset)
    root=CreateFrame("Button",nil,UIParent,"SecureActionButtonTemplate,SecureHandlerStateTemplate")
    root:Hide(); root:EnableMouse(true)
    position(self,root,size)
    self:ConfigureCombatCleanseButton(root,"player",plan,size)
    RegisterStateDriver(root,"visibility",VISIBILITY)
  end)
  if not ok then
    if root then
      pcall(UnregisterStateDriver,root,"visibility"); pcall(root.Hide,root)
      if root.container then pcall(root.container.SetEnabled,root.container,false) end
    end
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
    B.OptionsTheme.Tooltip(s,text("Combat: yourself (beta)"),text("Optional self-targeted combat button, including while grouped. Enable cleansing and You. Follow its Left click or Right click label. The warning appears for selected, learned removal types. An invisible click area stays active at this position throughout combat, even without a warning; clicking it can still attempt a self-cleanse. Never cleanse filters cannot be guaranteed for hidden combat debuffs; choose whether to cleanse. Follows your buff icon position and appearance. Your normal binding is unchanged."),B.combatCleanseError or nil)
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
    "Native setup: "..(self.combatCleanseErrorDetail or self.combatCleanseError or "no setup error recorded")}
end
