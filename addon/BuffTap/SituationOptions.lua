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
      for _,row in ipairs(f.buffRows or {}) do if row.order then row.order:ClearFocus() end end
      if f.activeSelector then f.activeSelector:Hide() end
      for _,map in ipairs({f.weaponPickers or {},f.coatingPickers or {}}) do for _,pick in pairs(map) do pick.menu:Hide() end end
      if B.itemPicker then B.itemPicker:Hide() end
      B.editContexts=B.editContexts or {}; B.editContexts[category]=selected
      B:Options()
    end)
    button:SetSize(78,26); group.buttons[context]=button
    ui.addHelp(button,names[context],context=="solo" and "Solo is the baseline. Party and Raid follow these preferences until you change individual choices in those setups." or "Edit this setup without activating it. Unchanged choices continue to follow Solo. Raid and Party inherit independently.")
  end
  group.active=ui.label(parent,"",298,-15,"GameFontDisableSmall",220)
  group.reset=ui.button(parent,"Use Solo settings",540,-8,160,function()
    B:CustomizeSituation(B:EditorContext(category),category,false); B:Options()
  end)
  group.status=ui.label(parent,"",18,-40,"GameFontDisableSmall",680)
end

function B:UpdateContextControls()
  for category,group in pairs(self.contextControls or {}) do
    local context=self:EditorContext(category)
    for key,button in pairs(group.buttons) do B.OptionsTheme.Navigation(button,key==context) end
    local custom=self:SituationValues(context,category)
    group.active:SetText(self:SituationBadge())
    group.reset:SetShown(context~="solo"); group.reset:SetEnabled(custom~=nil and not A.Combat())
    group.status:SetText(self:Text(context=="solo" and "Baseline preferences. Party and Raid inherit unchanged choices." or custom and "Custom choices. Unchanged preferences still follow Solo." or "Following Solo. Change a preference below to customize this setup."))
  end
end
