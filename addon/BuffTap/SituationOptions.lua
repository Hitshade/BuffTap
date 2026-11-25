-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local names={solo="Solo",party="Party",raid="Raid"}

function B:BuildContextControls(parent,category,ui)
  self.contextControls=self.contextControls or {}
  local group={buttons={},category=category}; self.contextControls[category]=group
  for i,context in ipairs({"solo","party","raid"}) do
    local selected=context
    local button=ui.flatButton(parent,names[context],18+(i-1)*84,-8,78,function()
      if A.Combat() then return end
      -- Discard unfinished input before a context change; never save it into another setup.
      local f=B.options
      for _,row in ipairs(f.buffRows or {}) do if row.order and row.order.ClearFocus then row.order:ClearFocus() end end
      if f.activeSelector then f.activeSelector:Hide() end
      for _,map in ipairs({f.weaponPickers or {},f.coatingPickers or {}}) do for _,pick in pairs(map) do pick.menu:Hide() end end
      if B.itemPicker then B.itemPicker:Hide() end
      B.editContexts=B.editContexts or {}; B.editContexts[category]=selected
      if category=="buffs" then B.buffsHelpersView=nil end -- back from Class helpers to the buff list
      B:Options()
    end)
    button:SetSize(78,26); group.buttons[context]=button
    ui.addHelp(button,names[context],context=="solo" and "Solo is the baseline. Party and Raid follow these preferences until you change individual choices in those setups." or (context=="party" and "Applied automatically when you join a party. Unchanged preferences follow Solo." or "Applied automatically while you are in a raid. Unchanged preferences follow Solo."))
  end
  group.active=ui.label(parent,"",298,-15,"GameFontDisableSmall",220); group.active:Hide() -- the window header already shows the active setup
  group.reset=ui.button(parent,"Use Solo settings",540,-8,160,function()
    B:CustomizeSituation(B:EditorContext(category),category,false); B:Options()
  end)
  group.status=ui.label(parent,"",18,-40,"GameFontDisableSmall",680)
  -- Dual spec: one switch per character, shared by every page. Shown for every character so Spec 2 can be prepared early.
  if ui.check then
    group.specCheck=ui.check(parent,"Different settings per spec",18,-36,function(c)
      if A.Combat() or not B:SetSpecEnabled(c:GetChecked()==true) then c:SetChecked(B:SpecEnabled()) return end
      B:Options()
    end)
    -- The Class helpers pane keeps a card behind this row; mark the controls as already placed so the card inset leaves them alone.
    group.specCheck.visualInsetX=18
    -- Long translations must not run into the status text that starts at x 232.
    if group.specCheck.Text and type(group.specCheck.Text.SetWidth)=="function" then group.specCheck.Text:SetWidth(184); group.specCheck.Text:SetWordWrap(false) end
    ui.addHelp(group.specCheck,"Different settings per spec","Keep separate choices for your two specs. Which buffs, weapon buffs and consumables to keep up, and their weapon and consumable timers, follow the spec you are in. Buff timers and everything else are shared. You can set up Spec 2 before you learn dual spec.")
    group.specLabel=ui.label(parent,"Editing",470,-43,"GameFontDisableSmall",64); group.specLabel:SetJustifyH("RIGHT")
    group.specButtons={}
    for i=1,2 do
      local spec=i
      local button=ui.flatButton(parent,"Spec "..i,540+(i-1)*82,-38,78,function()
        if A.Combat() then return end
        -- Discard unfinished input before the spec changes; never save it into the other spec.
        local f=B.options
        for _,row in ipairs(f.buffRows or {}) do if row.order and row.order.ClearFocus then row.order:ClearFocus() end end
        if f.activeSelector then f.activeSelector:Hide() end
        for _,map in ipairs({f.weaponPickers or {},f.coatingPickers or {}}) do for _,pick in pairs(map) do pick.menu:Hide() end end
        if B.itemPicker then B.itemPicker:Hide() end
        B:SetEditSpec(spec)
      end)
      button:SetSize(78,22); group.specButtons[i]=button
      button.visualInsetX=540+(i-1)*82
      -- Green dot: the spec you are in now.
      button.activeDot=button:CreateTexture(nil,"OVERLAY"); button.activeDot:SetSize(7,7); button.activeDot:SetPoint("RIGHT",-8,0)
      button.activeDot:SetColorTexture(.35,.85,.45,1); button.activeDot:Hide()
      ui.addHelp(button,"Spec "..i,"Choose which spec you are editing. The green dot marks the spec you are in now.")
    end
  end
  if category=="buffs" then
    -- Class helpers sit beside Solo / Party / Raid but are not a setup: pet, Healthstone, Soulstone, Oath and tracking apply everywhere.
    group.helpers=ui.flatButton(parent,"Class helpers",306,-8,172,function()
      if A.Combat() then return end
      local f=B.options
      if f then
        if f.activeSelector then f.activeSelector:Hide() end
        for _,row in ipairs(f.buffRows or {}) do if row.order and row.order.ClearFocus then row.order:ClearFocus() end end
      end
      B.buffsHelpersView=true; B:Options()
    end)
    group.helpers:SetSize(172,26)
    -- Same wand as the Helpers page in the sidebar; Navigation tints it with the tab.
    local theme=B.OptionsTheme
    group.helpers.icon=group.helpers:CreateTexture(nil,"ARTWORK"); group.helpers.icon:SetSize(16,16); group.helpers.icon:SetPoint("LEFT",14,0)
    if theme and theme.media then group.helpers.icon:SetTexture(theme.media.."NavHelpers") end
    local text=group.helpers.GetFontString and group.helpers:GetFontString()
    if text then text:ClearAllPoints(); text:SetPoint("LEFT",36,0); text:SetPoint("RIGHT",-10,0); text:SetJustifyH("CENTER") end
    -- The rule sits midway between Raid and the tab.
    group.helpersRule=group.helpers:CreateTexture(nil,"ARTWORK"); group.helpersRule:SetColorTexture(.30,.33,.40,1)
    group.helpersRule:SetSize(1,22); group.helpersRule:SetPoint("RIGHT",group.helpers,"LEFT",-21,0)
    ui.addHelp(group.helpers,"Class helpers","Settings for your class and for tracking. They apply in every setup, so Solo, Party and Raid never change them.")
  end
end

-- The tab's name says what is inside for this class.
function B:ClassHelpersLabel()
  local class=self.ReadinessClass and self:ReadinessClass()
  if class=="WARLOCK" or class=="PALADIN" then return "Class helpers" end
  if class=="HUNTER" then return "Pet and tracking" end
  return "Tracking"
end

-- A class with no supported aura buffs opens My buffs directly on its Tracking controls.
function B:MyBuffsCompact()
  return self.HasPersonalReminderBuffs~=nil and not self:HasPersonalReminderBuffs()
end

function B:ClassHelpersSummary()
  local class=self.ReadinessClass and self:ReadinessClass()
  if self:MyBuffsCompact() then return "This class has no aura buffs to remind. Tracking is below." end
  if class=="WARLOCK" then return "Pet, Healthstone, Soulstone and tracking. These apply in every setup." end
  if class=="PALADIN" then return "Oath and tracking. These apply in every setup." end
  if class=="HUNTER" then return "Pet and tracking. These apply in every setup." end
  return "Tracking reminders. These apply in every setup."
end

-- Swaps My buffs between the buff list and the Class helpers pane.
function B:ApplyClassHelpersView()
  local f=self.options; if not f or not f.helpersPane then return end
  local view=self.buffsHelpersView==true
  f.helpersPane:SetShown(view)
  if f.buffContent then f.buffContent:SetShown(not view) end
  local header=f.pageHeaders and f.pageHeaders[1]
  if header and header.description then
    if header.baseDescription==nil then header.baseDescription=header.description:GetText() or "" end
    header.description:SetText(view and self:Text(self:ClassHelpersSummary()) or header.baseDescription)
  end
  local hp=self.helperWindow
  if not view and hp then
    if hp.soulMenu then hp.soulMenu:Hide() end
    if hp.demonMenu then hp.demonMenu:Hide() end
  end
end

function B:UpdateContextControls()
  for category,group in pairs(self.contextControls or {}) do
    local context=self:EditorContext(category)
    local compact=category=="buffs" and self:MyBuffsCompact()
    if compact then self.buffsHelpersView=true end
    local helpers=category=="buffs" and group.helpers~=nil and self.buffsHelpersView==true
    for key,button in pairs(group.buttons) do B.OptionsTheme.Navigation(button,key==context and not helpers) end
    if group.helpers then
      group.helpers:SetText(self:Text(self:ClassHelpersLabel()))
      B.OptionsTheme.Navigation(group.helpers,helpers)
    end
    local custom=self:SituationValues(context,category)
    group.active:SetText(self:SituationBadge())
    group.reset:SetShown(context~="solo" and not helpers); group.reset:SetEnabled(context~="solo" and not A.Combat())
    if compact then
      -- Nothing to switch between: no Solo / Party / Raid, no tab strip. The Tracking controls fill the page.
      for _,button in pairs(group.buttons) do button:Hide() end
      group.helpers:Hide(); group.active:Hide(); group.reset:Hide(); group.status:SetText("")
    elseif category=="buffs" then
      for _,button in pairs(group.buttons) do button:Show() end
      if group.helpers then group.helpers:Show() end
    end
    -- The spec bar also lets single-spec characters prepare Spec 2; never on Class helpers.
    local showBar=group.specCheck~=nil and not compact and not helpers and self:SpecApplies(category)
    local specOn=showBar and self:SpecEnabled()
    if group.specCheck then
      group.specCheck:SetShown(showBar==true); group.specCheck:SetChecked(specOn==true)
      group.specLabel:SetShown(specOn==true)
      for i,button in ipairs(group.specButtons) do
        button:SetShown(specOn==true)
        B.OptionsTheme.Navigation(button,specOn==true and self:EditSpec()==i)
        button.activeDot:SetShown(specOn==true and self:SpecGroup()==i)
      end
      local parentFrame=group.status:GetParent()
      group.status:ClearAllPoints(); group.status:SetPoint("TOPLEFT",parentFrame,"TOPLEFT",showBar and 232 or 18,-40)
      group.status:SetWidth(specOn and 230 or (showBar and 468 or 680)); group.status:SetWordWrap(false)
    end
    -- Weapons and Consumables start right under the status row, so they step down to make room for the bar.
    local f=self.options
    local body=f and (category=="weapons" and f.weaponContent or category=="consumables" and f.consumableBody)
    if body then
      body:ClearAllPoints(); body:SetPoint("TOPLEFT",0,showBar and -20 or (category=="consumables" and 4 or 0)); body:SetPoint("BOTTOMRIGHT",0,0)
    end
    if specOn then group.status:SetText(self:Text("Editing Spec %d. Used in every setup.",self:EditSpec()))
    elseif compact then elseif helpers then group.status:SetText("") else group.status:SetText(self:Text(context=="solo" and "Solo preferences. Party and Raid follow unchanged settings." or custom and (context=="party" and "Applied automatically in a party. Other settings still follow Solo." or "Applied automatically in a raid. Other settings still follow Solo.") or (context=="party" and "Following Solo settings. Change a setting to customize Party." or "Following Solo settings. Change a setting to customize Raid."))) end
  end
  self:ApplyClassHelpersView()
end
