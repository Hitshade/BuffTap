-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local T={
  window={.018,.025,.032,1}, panel={.025,.034,.043,1}, card={.043,.057,.070,.94},
  control={.046,.060,.073,1}, menu={.025,.035,.046,1}, border={.32,.29,.22,1},
  gold={1,.82,.27,1}, muted={.65,.70,.72,1}, accent={.38,.76,.82,1},
}
B.OptionsTheme=T
function T.Surface(frame,kind)
  if not frame then return end
  kind=kind or "panel"
  if frame.optionsSurface==kind then return end
  frame.optionsSurface=kind
  local color=T[kind] or T.panel
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  frame:SetBackdropColor(unpack(color)); frame:SetBackdropBorderColor(unpack(T.border))
end
function T.Card(parent,x,y,width,height)
  local bg=parent:CreateTexture(nil,"BACKGROUND"); bg:SetColorTexture(unpack(T.card)); bg:SetPoint("TOPLEFT",x,y); bg:SetSize(width,height)
  local edge=parent:CreateTexture(nil,"BACKGROUND"); edge:SetColorTexture(.65,.55,.32,.18); edge:SetPoint("TOPLEFT",bg,"TOPLEFT"); edge:SetPoint("TOPRIGHT",bg,"TOPRIGHT"); edge:SetHeight(1)
  local shade=parent:CreateTexture(nil,"BACKGROUND"); shade:SetColorTexture(0,0,0,.22); shade:SetPoint("BOTTOMLEFT",bg,"BOTTOMLEFT"); shade:SetPoint("BOTTOMRIGHT",bg,"BOTTOMRIGHT"); shade:SetHeight(1)
  bg.edges={edge,shade}
  return bg
end
function T.CardShown(card,shown)
  card:SetShown(shown)
  for _,edge in ipairs(card.edges or {}) do edge:SetShown(shown) end
end
function T.Selector(control)
  if not control then return end
  if not control.selectorWell then
    local well=control:CreateTexture(nil,"BACKGROUND"); control.selectorWell=well
    well:SetPoint("TOPRIGHT",-1,-1); well:SetPoint("BOTTOMRIGHT",-1,1); well:SetWidth(24); well:SetColorTexture(.19,.16,.095,.28)
    local seam=control:CreateTexture(nil,"BACKGROUND"); seam:SetPoint("TOPRIGHT",-25,-1); seam:SetPoint("BOTTOMRIGHT",-25,1); seam:SetWidth(1); seam:SetColorTexture(.65,.55,.32,.22)
  end
  local menu=control.menu
  if menu and not menu.selectorStyled then
    menu.selectorStyled=true; T.Surface(menu,"menu"); menu:SetClampedToScreen(true); menu:EnableMouse(true)
    menu:HookScript("OnShow",function() control:SetBackdropBorderColor(.76,.62,.30,1); control.selectorWell:SetColorTexture(.40,.29,.095,.50) end)
    menu:HookScript("OnHide",function() control:SetBackdropBorderColor(unpack(T.border)); control.selectorWell:SetColorTexture(.19,.16,.095,.28) end)
  end
end
function T.EditFocus(edit)
  if edit.visualFocus then return end
  local lines={}
  for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
    local edge=edit:CreateTexture(nil,"OVERLAY"); edge:SetColorTexture(unpack(T.accent)); edge:Hide(); lines[#lines+1]=edge
    if side=="TOP" or side=="BOTTOM" then edge:SetPoint(side.."LEFT",-2,0); edge:SetPoint(side.."RIGHT",2,0); edge:SetHeight(1)
    else edge:SetPoint("TOP"..side,side=="LEFT" and -2 or 2,0); edge:SetPoint("BOTTOM"..side,side=="LEFT" and -2 or 2,0); edge:SetWidth(1) end
  end
  edit.visualFocus=lines
  edit:HookScript("OnEditFocusGained",function() for _,edge in ipairs(lines) do edge:Show() end end)
  edit:HookScript("OnEditFocusLost",function() for _,edge in ipairs(lines) do edge:Hide() end end)
end
function T.Check(control)
  local text=control and control.Text
  if not text then return end
  text:SetTextColor(.93,.82,.46); text:SetWordWrap(false)
  local width=text:GetStringWidth()
  if type(width)=="number" then control:SetHitRectInsets(0,-math.min(264,width+8),0,0) end
end
function T.Navigation(button,selected)
  if not button.navAccent then
    button.navAccent=button:CreateTexture(nil,"OVERLAY"); button.navAccent:SetColorTexture(unpack(T.gold))
    button.navAccent:SetPoint("TOPLEFT",0,-4); button.navAccent:SetPoint("BOTTOMLEFT",0,4); button.navAccent:SetWidth(2)
  end
  button.navAccent:SetShown(selected)
  if selected then button:SetBackdropColor(.17,.135,.065,1); button:SetBackdropBorderColor(.46,.37,.19,.80)
  else button:SetBackdropColor(.035,.047,.059,.72); button:SetBackdropBorderColor(.20,.23,.24,.35) end
end
function B:PolishOptionsSurfaces()
  local f=self.options
  if not f then return end
  for _,control in ipairs({f.reminderSoundButton,f.supplySoundButton,f.channelButton,f.fontButton,f.colorButton,f.effectButton,f.effectColorButton,f.effectSpeedButton,f.labelSizeButton,f.labelOutlineButton,f.campingWarning,f.campingEffect,f.campingColor,f.campingSpeed,f.campingTextFont,f.campingTextSize,f.campingTextColor,f.campingTextOutline}) do T.Selector(control) end
  for _,control in pairs(f.weaponPickers or {}) do T.Selector(control) end
  for _,control in pairs(f.coatingPickers or {}) do T.Selector(control) end
  for _,row in ipairs(f.blessingRows or {}) do T.Selector(row.pick) end
  for _,control in ipairs(f.targetBlessingPicks or {}) do T.Selector(control) end
  for _,name in ipairs({"blessingMenu","blessingDetail","blessingCastingPanel","blessingFilters"}) do
    local surface=f[name]; if surface then T.Surface(surface,"menu") end
  end
end
