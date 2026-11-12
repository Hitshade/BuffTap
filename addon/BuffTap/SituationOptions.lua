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
      B:Options()
    end)
    button:SetSize(78,26); group.buttons[context]=button
    ui.addHelp(button,names[context],context=="solo" and "Solo is the baseline. Party and Raid follow these preferences until you change individual choices in those setups." or (context=="party" and "Applied automatically when you join a party. Unchanged preferences follow Solo." or "Applied automatically while you are in a raid. Unchanged preferences follow Solo."))
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
    group.status:SetText(self:Text(context=="solo" and "Solo preferences. Party and Raid follow unchanged settings." or custom and (context=="party" and "Applied automatically in a party. Other settings still follow Solo." or "Applied automatically in a raid. Other settings still follow Solo.") or (context=="party" and "Following Solo settings. Change a setting to customize Party." or "Following Solo settings. Change a setting to customize Raid.")))
  end
end
