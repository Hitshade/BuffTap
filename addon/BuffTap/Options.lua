-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ADDON,B=...
local A=B.API
local function L(key,...) return B:Text(key,...) end
local TAB={Buffs=1,Groups=2,Target=3,Consumables=4,Weapons=5,Appearance=6,Helpers=7,Diagnostics=8}
local TAB_NAMES={L("Buffs"),L("Groups"),L("Target"),L("Consumables"),L("Weapons"),L("Customization"),L("Helpers"),L("Diagnostics")}
local TAB_WIDTHS={62,66,66,108,80,116,74,94}
local OPTIONS_WIDTH,OPTIONS_HEIGHT=760,868
local ICON_PATH="Interface\\AddOns\\BuffTap\\Media\\BuffTapIcon"

local function label(parent,text,x,y,font,width)
  local fs=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
  fs:SetPoint("TOPLEFT",x,y)
  if width then fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true) end
  fs:SetText(L(text))
  if font=="GameFontDisableSmall" then fs:SetTextColor(0.73,0.73,0.70) end
  return fs
end

local function line(parent,y)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t:SetColorTexture(0.55,0.44,0.23,0.45); t:SetPoint("TOPLEFT",18,y); t:SetPoint("TOPRIGHT",-18,y); t:SetHeight(1)
  return t
end

local function card(parent,x,y,width,height)
  local t=parent:CreateTexture(nil,"BACKGROUND")
  t:SetColorTexture(0.065,0.085,0.10,0.65); t:SetPoint("TOPLEFT",x,y); t:SetSize(width,height)
  return t
end

local function fitButtonText(control,width)
  local text=control:GetFontString()
  if not text or not text.GetStringWidth or not text.GetFont then return end
  local measured=text:GetStringWidth()
  local font,size,flags=text:GetFont()
  if type(measured)=="number" and measured>width-16 and type(size)=="number" then
    text:SetFont(font,math.max(8,size*(width-16)/measured),flags)
  end
  text:SetWordWrap(false)
end

local function flatButton(parent,text,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  b:SetBackdropColor(0.075,0.095,0.11,1); b:SetBackdropBorderColor(0.48,0.40,0.25,1)
  b:SetNormalFontObject("GameFontHighlightSmall"); b:SetHighlightFontObject("GameFontNormalSmall")
  b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local highlight=b:GetHighlightTexture(); if highlight then highlight:SetVertexColor(0.8,0.65,0.25,0.18) end
  b:SetSize(w or 110,26); b:SetPoint("TOPLEFT",x,y); b:SetText(L(text)); b:SetScript("OnClick",fn)
  fitButtonText(b,w or 110)
  return b
end

-- Native action buttons supply their own border and disabled/pressed artwork.
local function button(parent,text,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w or 110,26); b:SetPoint("TOPLEFT",x,y); b:SetText(L(text)); b:SetScript("OnClick",fn)
  b:SetNormalFontObject("GameFontNormalSmall"); b:SetDisabledFontObject("GameFontDisableSmall")
  fitButtonText(b,w or 110)
  return b
end
local function arrowButton(parent,text,x,y,w,fn)
  local b=flatButton(parent,text,x,y,w,fn); b:SetBackdrop(nil)
  return b
end

-- One selector convention: explicit choices, a visible arrow and toggle-to-close.
local function selector(parent,text,x,y,width,choices,onSelect,searchable)
  local scrollable=searchable==true or searchable=="scroll"
  searchable=searchable==true
  local control,menu,render
  control=flatButton(parent,text,x,y,width,function()
    if A.Combat() then return end
    if menu:IsShown() then menu:Hide(); return end
    if B.options and B.options.activeSelector and B.options.activeSelector~=menu then B.options.activeSelector:Hide() end
    if B.options then B.options.activeSelector=menu end
    render(); menu:Show()
  end)
  control.arrow=control:CreateTexture(nil,"OVERLAY"); control.arrow:SetSize(16,16); control.arrow:SetPoint("RIGHT",-4,0)
  control.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  local textRegion=control:GetFontString()
  if textRegion then textRegion:ClearAllPoints(); textRegion:SetPoint("LEFT",10,0); textRegion:SetPoint("RIGHT",-26,0) end
  menu=CreateFrame("Frame",nil,parent,"BackdropTemplate"); control.menu=menu
  menu:SetPoint("TOPLEFT",control,"BOTTOMLEFT",0,-2); menu:SetFrameStrata("TOOLTIP"); menu:SetClampedToScreen(true)
  menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  menu:SetBackdropColor(.04,.05,.06,1); menu:SetBackdropBorderColor(.48,.40,.25,1); menu.rows={}; menu:Hide()
  render=function()
    local all=choices(); local entries={}
    local query=searchable and string.lower(menu.search:GetText() or "") or ""
    for _,entry in ipairs(all) do if query=="" or string.find(string.lower(entry.name),query,1,true) then entries[#entries+1]=entry end end
    local count=#entries
    local top=searchable and 34 or 4
    menu:SetSize(scrollable and 340 or width,top+(scrollable and math.max(28,math.min(7,count)*28) or count*28)+4)
    if scrollable then
      menu.content:SetHeight(math.max(1,count*28)); menu.scroll:SetVerticalScroll(0)
      menu.empty:SetShown(count==0)
    end
    for _,row in ipairs(menu.rows) do row:Hide() end
    for i=1,count do
      local entry=entries[i]; local row=menu.rows[i]
      if not row then row=flatButton(scrollable and menu.content or menu,"",4,-(scrollable and 0 or top)-(i-1)*28,(scrollable and 312 or width)-8,function(btn)
        if A.Combat() then return end
        onSelect(btn.choice); menu:Hide(); B:Options()
      end); menu.rows[i]=row end
      row.choice=entry.key; row:SetText((searchable and entry.source and L(entry.source)..": " or "")..L(entry.name)); row:Show()
    end
  end
  if searchable then
    label(menu,L("Search"),8,-10,"GameFontHighlightSmall")
    menu.search=CreateFrame("EditBox",nil,menu,"InputBoxTemplate"); menu.search:SetSize(256,22); menu.search:SetPoint("TOPLEFT",68,-5); menu.search:SetAutoFocus(false)
    menu.search:SetScript("OnTextChanged",function() render() end)
    menu.search:SetScript("OnEscapePressed",function(box) box:ClearFocus(); menu:Hide() end)
  end
  if scrollable then
    menu.scroll=CreateFrame("ScrollFrame",nil,menu,"UIPanelScrollFrameTemplate")
    menu.scroll:SetPoint("TOPLEFT",4,searchable and -34 or -4); menu.scroll:SetPoint("BOTTOMRIGHT",-28,4)
    menu.content=CreateFrame("Frame",nil,menu.scroll); menu.content:SetSize(308,1); menu.scroll:SetScrollChild(menu.content)
    menu.empty=label(menu.content,L("No matches"),8,-6,"GameFontDisableSmall"); menu.empty:Hide()
  end
  parent:HookScript("OnHide",function() menu:Hide() end)
  return control
end
local function selectorArrow(control)
  local arrow=control:CreateTexture(nil,"OVERLAY"); arrow:SetSize(16,16); arrow:SetPoint("RIGHT",-4,0)
  arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up"); control.arrow=arrow
  local textRegion=control:GetFontString()
  if textRegion then textRegion:ClearAllPoints(); textRegion:SetPoint("LEFT",30,0); textRegion:SetPoint("RIGHT",-26,0) end
end

local function check(parent,text,x,y,fn)
  local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
  c:SetSize(24,24); c:SetPoint("TOPLEFT",x,y); c.Text:SetText(L(text)); c:SetScript("OnClick",fn)
  return c
end

local function addHelp(frame,title,body)
  if not frame or type(frame.SetScript)~="function" then return end
  frame:SetScript("OnEnter",function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(L(title),1,0.82,0.1)
    if body and body~="" then GameTooltip:AddLine(L(body),0.85,0.85,0.85,true) end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

local function editbox(parent,x,y,w,numeric)
  local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
  e:SetSize(w or 64,22); e:SetPoint("TOPLEFT",x,y); e:SetAutoFocus(false); if numeric then e:SetNumeric(true) end
  return e
end

local function panel(parent)
  local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
  f:SetPoint("TOPLEFT",18,-206); f:SetPoint("BOTTOMRIGHT",-18,32)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  f:SetBackdropColor(0.035,0.045,0.05,0.98); f:SetBackdropBorderColor(0.44,0.36,0.20,0.8)
  return f
end

local function formatSeconds(value)
  value=math.floor((tonumber(value) or 0)+0.5)
  if value<60 then return L("%d sec",value) end
  local m=math.floor(value/60); local s=value%60
  if s==0 then return L("%d min",m) end
  return L("%dm %ds",m,s)
end

local function setAndRefresh(key,value)
  if A.Combat() then return end
  B.db[key]=value; B:InitDB(); B.appearance=nil; B:RequestRefresh("setting",0)
end

local function rebuffSlider(parent)
  local s=CreateFrame("Slider",nil,parent,"OptionsSliderTemplate")
  s:SetSize(320,18); s:SetMinMaxValues(15,180); s:SetValueStep(5)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  if s.Low then s.Low:Hide() end
  if s.High then s.High:Hide() end
  if s.Text then s.Text:Hide() end

  s.minText=parent:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
  s.minText:SetPoint("TOPLEFT",s,"BOTTOMLEFT",0,-2); s.minText:SetText(L("%d sec",15))
  s.maxText=parent:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
  s.maxText:SetPoint("TOPRIGHT",s,"BOTTOMRIGHT",0,-2); s.maxText:SetText(L("%d min",3))
  s.valueText=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  s.valueText:SetPoint("LEFT",s,"RIGHT",18,0); s.valueText:SetText(L("%d sec",45))
  s:SetScript("OnValueChanged",function(self,value)
    value=math.floor(value/5+0.5)*5
    self.valueText:SetText(formatSeconds(value))
    if self.silent or A.Combat() then return end
    B.db.seconds=value; B:InitDB(); B:RequestRefresh("global rebuff threshold",0.08)
  end)
  return s
end

local function compactSlider(parent,minValue,maxValue,step,width,formatter,onChange)
  local s=CreateFrame("Slider",nil,parent,"OptionsSliderTemplate")
  s:SetSize(width or 110,16); s:SetMinMaxValues(minValue,maxValue); s:SetValueStep(step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  if s.Low then s.Low:Hide() end
  if s.High then s.High:Hide() end
  if s.Text then s.Text:Hide() end
  s.valueText=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  s.valueText:SetWidth(52); s.valueText:SetJustifyH("CENTER"); s.valueText:SetPoint("LEFT",s,"RIGHT",8,0)
  s:SetScript("OnValueChanged",function(self,value)
    value=math.floor(value/step+0.5)*step
    self.valueText:SetText(formatter(value))
    if self.silent or A.Combat() then return end
    onChange(self,value)
  end)
  return s
end

local function spellLabel(def)
  if not def then return L("Unavailable") end
  for _,id in ipairs(def.ranks or {}) do
    local name=A.Call(C_Spell and C_Spell.GetSpellName,id)
    if A.Text(name) then return name end
    local info=A.Call(C_Spell and C_Spell.GetSpellInfo,id)
    if A.Public(info) and type(info)=="table" and A.Text(info.name) then return info.name end
  end
  return def.name
end

local function validIcon(icon)
  return (A.Number(icon) and icon>0 and icon~=134400)
    or (A.Text(icon) and not icon:lower():find("inv_misc_questionmark",1,true))
end
local function learnedSpell(def)
  for _,id in ipairs(def and def.ranks or {}) do if A.Known(id) then return true end end
  return false
end
local function unlearnedText()
  return "|cffff6666"..L("not learned").."|r"
end
local function buffIcon(def)
  if not def then return 134400 end
  -- Display metadata does not require the character to know or cast the spell.
  for _,id in ipairs(def.ranks or {}) do
    local icon=A.Call(C_Spell and C_Spell.GetSpellTexture,id)
    if validIcon(icon) then return icon end
    local info=A.Call(C_Spell and C_Spell.GetSpellInfo,id)
    if A.Public(info) and type(info)=="table" and validIcon(info.iconID) then return info.iconID end
  end
  return validIcon(def.icon) and def.icon or 134400
end


local function blessingName(key)
  if not key or key=="inherit" then return L("Follow buff settings") end
  if key=="skip" then return L("Skip this class") end
  local def=B:FindBuff(key)
  return def and spellLabel(def):gsub("Blessing of ","") or L("Unavailable")
end
local function blessingIcon(key)
  local def=B:FindBuff(key)
  if not def then return 134400 end
  return buffIcon(def)
end
local function prioritySummary(order)
  local names={}
  for i,key in ipairs(order or {}) do names[#names+1]=i.." "..blessingName(key) end
  return #names>0 and table.concat(names," > ") or L("No blessings selected")
end
local function showBlessingPriorityMenu(menu,control)
  menu.owner=control
  for _,row in ipairs(menu.rows) do row:Hide() end
  menu:SetSize(380,280)
  menu.priorityRows=menu.priorityRows or {}
  if not menu.priorityTitle then
    menu.priorityTitle=label(menu,"",10,-10,"GameFontNormal",360)
    menu.priorityHelp=label(menu,"",10,-30,"GameFontDisableSmall",360)
    menu.priorityAutomatic=button(menu,"Automatic",8,-242,116,function()
      if A.Combat() or not menu.owner or menu.owner.disabled then return end
      menu.owner.setChoice(nil); menu:Hide(); B:InvalidateAura(); B:RequestRefresh("blessing automatic",0); B:Options()
    end)
    menu.prioritySkip=button(menu,"Skip class",130,-242,116,function()
      if A.Combat() or not menu.owner or menu.owner.disabled then return end
      menu.owner.setChoice("skip"); menu:Hide(); B:InvalidateAura(); B:RequestRefresh("blessing skip",0); B:Options()
    end)
    menu.priorityDone=button(menu,"Done",252,-242,116,function() menu:Hide() end)
  end
  menu.priorityTitle:SetText(L("Blessing priorities: %s",((LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[control.priorityClass]) or control.priorityClass:sub(1,1)..control.priorityClass:sub(2):lower())))
  menu.priorityHelp:SetText(L("Only checked blessings are used. Use arrows to order; 1 is first."))
  menu.priorityAutomatic:SetText(L(control.priorityTarget and "Automatic" or "Buff settings"))
  for _,t in ipairs(menu.separators or {}) do t:Hide() end
  menu.priorityTitle:Show(); menu.priorityHelp:Show(); menu.priorityAutomatic:Show(); menu.prioritySkip:Show(); menu.priorityDone:Show()
  local mode=control.getChoice()
  local order={}
  local source
  if mode=="priority" then source=control.getOrder() or {}
  elseif mode=="skip" then source={}
  elseif mode then source={mode}
  else source=B:DefaultBlessingOrder(control.priorityClass,control.priorityTarget) end
  for i,key in ipairs(source or {}) do order[i]=key end
  control.editorOrder=order
  if mode~="priority" then
    local name=mode=="skip" and L("Skip class") or mode and L("Fixed: %s",blessingName(mode)) or L(control.priorityTarget and "Automatic" or "Buff settings")
    menu.priorityHelp:SetText(name..". "..L(mode and "Edit checks or arrows to customize." or "Uses enabled Buffs in order, filtered for this class. Edit below to customize."))
  end
  local keys,seen={},{}
  for _,key in ipairs(order) do keys[#keys+1]=key; seen[key]=true end
  for _,key in ipairs(B.BlessingFamilies) do if not seen[key] then keys[#keys+1]=key end end
  local function save(nextOrder)
    if A.Combat() or control.disabled or menu.owner~=control then return end
    control.setOrder(nextOrder); control.setChoice("priority")
    B:InvalidateAura(); B:RequestRefresh("blessing priority order",0); B:Options()
    showBlessingPriorityMenu(menu,control); menu:Show()
  end
  for i,key in ipairs(keys) do
    local row=menu.priorityRows[i]
    if not row then
      row=CreateFrame("Frame",nil,menu); row:SetSize(364,30); row:SetPoint("TOPLEFT",8,-74-(i-1)*32)
      row.toggle=check(row,"",0,0,function(c)
        local owner=menu.owner
        if A.Combat() or not owner or owner.disabled then return end
        local nextOrder={}; local present=false
        for _,v in ipairs(owner.editorOrder or {}) do if v==c.key then present=true else nextOrder[#nextOrder+1]=v end end
        if not present then nextOrder[#nextOrder+1]=c.key end
        owner.saveOrder(nextOrder)
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",27,0)
      row.name=label(row,"",56,-3,"GameFontHighlightSmall",235); row.name:SetWordWrap(false)
      row.note=label(row,"",56,-18,"GameFontDisableSmall",235); row.note:SetWordWrap(false)
      for _,direction in ipairs({-1,1}) do
        local delta=direction
        local arrow=arrowButton(row,"",delta<0 and 292 or 328,-2,34,function(btn)
          local owner=menu.owner
          if A.Combat() or not owner or owner.disabled then return end
          local nextOrder={}; for j,v in ipairs(owner.editorOrder or {}) do nextOrder[j]=v end
          local index=btn.index; local dest=index and index+delta
          if dest and dest>=1 and dest<=#nextOrder then nextOrder[index],nextOrder[dest]=nextOrder[dest],nextOrder[index]; owner.saveOrder(nextOrder) end
        end)
        local texture=arrow:CreateTexture(nil,"ARTWORK"); texture:SetSize(22,22); texture:SetPoint("CENTER")
        texture:SetTexture(delta<0 and "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up" or "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        addHelp(arrow,delta<0 and "Move earlier" or "Move later","Lower numbers are tried first. Only included blessings can be reordered.")
        if delta<0 then row.up=arrow else row.down=arrow end
      end
      menu.priorityRows[i]=row
    end
    local index
    for j,v in ipairs(order) do if v==key then index=j; break end end
    row.toggle.key=key; row.toggle:SetChecked(index~=nil)
    row.icon:SetTexture(blessingIcon(key)); row.name:SetText((index and tostring(index)..". " or "")..blessingName(key))
    local note=not index and L("Not included") or L("Use arrows to reorder")
    if not B:BlessingLearned(key) then note=(not index and L("Not included").." · " or "")..unlearnedText() end
    row.note:SetText(note)
    row.up.index=index; row.down.index=index
    row.up:SetEnabled(index~=nil and index>1); row.down:SetEnabled(index~=nil and index<#order)
    row:Show()
  end
  control.saveOrder=save
  addHelp(control,"Blessing priority order",prioritySummary(order).."\nOne blessing from you per player. Your own blessing is maintained. Unknown ownership stops fallback. Explicit player exceptions override group priorities.")
end

local function blessingPick(parent,x,y,width,getChoice,setChoice,player)
  local pick=flatButton(parent,"",x,y,width,function(control)
    if A.Combat() or control.disabled then return end
    local f=B.options
    if not f.blessingMenu then
      f.blessingMenu=CreateFrame("Frame",nil,f,"BackdropTemplate")
      f.blessingMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f.blessingMenu:SetBackdropColor(0.025,0.035,0.045,1); f.blessingMenu:SetBackdropBorderColor(0.55,0.44,0.23,1)
      f.blessingMenu.separators={}
      for _,y in ipairs({-32,-172}) do
        local separator=f.blessingMenu:CreateTexture(nil,"ARTWORK"); separator:SetColorTexture(0.48,0.40,0.25,0.65); separator:SetPoint("TOPLEFT",8,y); separator:SetSize(254,1); f.blessingMenu.separators[#f.blessingMenu.separators+1]=separator
      end
      f.blessingMenu:SetFrameStrata("TOOLTIP"); f.blessingMenu:SetClampedToScreen(true); f.blessingMenu:EnableMouse(true); f.blessingMenu.rows={}; f.blessingMenu:Hide()
    end
    local menu=f.blessingMenu
    if menu:IsShown() and menu.owner==control then menu:Hide(); return end
    menu.owner=control; menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",control,"BOTTOMLEFT",0,-2)
    if control.getOrder then showBlessingPriorityMenu(menu,control); menu:Show(); return end
    for _,row in ipairs(menu.priorityRows or {}) do row:Hide() end
    for _,name in ipairs({"priorityTitle","priorityHelp","priorityAutomatic","prioritySkip","priorityDone"}) do if menu[name] then menu[name]:Hide() end end
    for _,t in ipairs(menu.separators or {}) do t:Show() end
    menu:SetSize(270,204)
    local choices={"inherit","bok","bom","bow","bos","bol","skip"}
    for _,row in ipairs(menu.rows) do row:Hide() end
    for i,key in ipairs(choices) do
      local option=menu.rows[i]
      if not option then
        option=flatButton(menu,"",4,-4-(i-1)*28,262,function(btn)
          if A.Combat() or not menu.owner or menu.owner.disabled then return end
          local owner=menu.owner; if owner then local key=btn.key; if key=="inherit" then key=nil end; owner.setChoice(key) end
          menu:Hide(); B:InvalidateAura(); B:RequestRefresh("blessing assignment",0); B:Options()
        end)
        option.icon=option:CreateTexture(nil,"ARTWORK"); option.icon:SetSize(20,20); option.icon:SetPoint("LEFT",23,0)
        option.selected=option:CreateTexture(nil,"OVERLAY"); option.selected:SetSize(18,18); option.selected:SetPoint("LEFT",3,0); option.selected:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        local text=option:GetFontString(); if text then text:ClearAllPoints(); text:SetPoint("LEFT",48,0); text:SetPoint("RIGHT",-5,0); text:SetJustifyH("LEFT") end
        menu.rows[i]=option
      end
      option:Show(); option.key=key
      local name=key=="inherit" and (player=="target" and L("Automatic: class + priority") or (player and L("Inherit class") or L("Follow buff settings"))) or (key=="skip" and player==true and L("Skip this player") or blessingName(key))
      local def=B:FindBuff(key); local learned=not def or B:BlessingLearned(key)
      option:SetText(name..(learned and "" or (" ("..unlearnedText()..")")))
      option.icon:SetTexture(def and blessingIcon(key) or (key=="skip" and "Interface\\Buttons\\UI-GroupLoot-Pass-Up" or "Interface\\Buttons\\UI-OptionsButton")); option.icon:Show()
      option.selected:SetShown((control.getChoice() or "inherit")==key); fitButtonText(option,262)
      addHelp(option,name,player=="target" and "Choose a blessing for this target class. Automatic follows enabled target priorities and class suitability. A selected first choice is enabled for targets independently of personal buffs. Unlearned choices fall back to Automatic; Skip offers no blessing. Group assignments take precedence for group members." or learned and "Sets the blessing this Paladin maintains. Each application still needs your input." or "This choice stays saved, but BuffTap cannot apply it until you learn it. No silent substitution.")
    end
    menu:Show()
  end)
  pick.getChoice=getChoice; pick.setChoice=setChoice
  pick.arrow=pick:CreateTexture(nil,"ARTWORK"); pick.arrow:SetSize(22,22); pick.arrow:SetPoint("RIGHT",-2,0)
  pick.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  pick.divider=pick:CreateTexture(nil,"ARTWORK"); pick.divider:SetColorTexture(0.48,0.40,0.25,0.8); pick.divider:SetSize(1,22); pick.divider:SetPoint("RIGHT",-27,0)
  local text=pick:GetFontString(); if text then text:ClearAllPoints(); text:SetPoint("LEFT",30,0); text:SetPoint("RIGHT",-30,0); text:SetJustifyH("LEFT"); text:SetWordWrap(false) end
  pick.SetAvailable=function(self,enabled)
    self.disabled=not enabled; self:SetEnabled(enabled); self:SetAlpha(enabled and 1 or 0.4)
    if self.disabled and B.options.blessingMenu and B.options.blessingMenu.owner==self then B.options.blessingMenu:Hide() end
  end
  pick.icon=pick:CreateTexture(nil,"ARTWORK"); pick.icon:SetSize(21,21); pick.icon:SetPoint("LEFT",5,0)
  pick.Update=function(self)
    local key=self.getChoice(); self:SetText(not key and player=="target" and L("Automatic") or (player and not key and L("Inherit class") or (key=="skip" and player==true and L("Skip this player") or blessingName(key))))
    if key=="priority" and self.getOrder then
      local order=self.getOrder() or {}
      local shown={}; local limit=width<200 and 1 or 2
      for i=1,math.min(limit,#order) do shown[#shown+1]=i.." "..blessingName(order[i]) end
      local summary=#shown>0 and table.concat(shown," > ") or L("None selected")
      if #order>limit then summary=summary.." +"..(#order-limit) end
      self:SetText(summary)
      addHelp(self,"Custom blessing priorities",prioritySummary(self.getOrder()).."\nClick to include and reorder blessings. Unlearned entries are skipped. Checked blessings are enabled for this list independently of personal buffs; your own blessing is maintained. Unknown ownership stops fallback.")
    end
    fitButtonText(self,width-44)
    self.icon:SetTexture(key=="skip" and "Interface\\Buttons\\UI-GroupLoot-Pass-Up" or (key=="priority" and self.getOrder and (self.getOrder() or {})[1] and blessingIcon((self.getOrder() or {})[1]) or key and key~="priority" and blessingIcon(key) or "Interface\\Buttons\\UI-OptionsButton")); self.icon:Show()
  end
  return pick
end
function B:BuildBlessingOptions(parent)
  local f=self.options; local p=CreateFrame("Frame",nil,parent); p:SetAllPoints(); f.blessingPanel=p
  label(p,L("Party & raid buffing"),18,-16,"GameFontNormalLarge")
  label(p,"Choose a fixed blessing or an ordered list for each class. Expand for player exceptions.",18,-39,"GameFontDisableSmall",680)
  f.blessingGroupEnable=check(p,L("Enable party / raid"),18,-57,function(c) setAndRefresh("group",c:GetChecked()==true); B:Options() end)
  f.blessingSmart=check(p,"Use Greater Blessings",280,-57,function(c) setAndRefresh("smartGroup",c:GetChecked()==true); B:Options() end)
  label(p,L("Raid groups"),18,-91,"GameFontHighlightSmall",85)
  f.blessingGroups={}
  for i=1,8 do
    local group=i
    f.blessingGroups[i]=check(p,"G"..i,108+(i-1)*68,-85,function(c)
      if A.Combat() then return end
      B:SetRaidGroupColumn(group,c:GetChecked()==true); B:RequestRefresh("blessing groups",0); B:Options()
    end)
    addHelp(f.blessingGroups[i],"Raid group "..i,"Sets the shared raid group selection. Party members use G1. A Greater Blessing cannot safely bypass an excluded member of the same class.")
  end
  label(p,"Greater at",18,-144,"GameFontHighlightSmall",100)
  f.blessingThreshold=compactSlider(p,2,5,1,150,function(v) return tostring(v).."+" end,function(_,v)
    B.db.blessingNeed=v; B:NormalizeGroupNeeds(); B:RequestRefresh("blessing threshold",0.08)
  end); f.blessingThreshold:SetPoint("TOPLEFT",120,-121)
  label(p,"Only when class choices agree.",345,-124,"GameFontDisableSmall",340)
  line(p,-150)
  label(p,"Blessing assignments",18,-164,"GameFontNormalLarge")
  f.blessingEnable=check(p,"Enable class assignments",345,-158,function(c) setAndRefresh("blessingAssignments",c:GetChecked()==true); B:Options() end)
  button(p,"Restore defaults",565,-159,140,function()
    if A.Combat() then return end
    B.db.blessingAssignments=false; B.db.blessingClasses={}; B.db.groupBlessingPriorities={}; B.blessingPlayers=nil; B:RequestRefresh("restore blessings",0); B:Options()
  end)
  f.blessingInstruction=label(p,"",18,-190,"GameFontDisableSmall",686)
  label(p,L("Class"),24,-214,"GameFontDisableSmall",112); label(p,"Blessing / priority order",224,-214,"GameFontDisableSmall",270)
  label(p,"Player exceptions",546,-214,"GameFontDisableSmall",140)
  f.blessingRows={}
  for index,class in ipairs(self.RecipientClasses) do
    local token=class; local row=CreateFrame("Frame",nil,p,"BackdropTemplate"); row:SetSize(686,25)
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(index%2==0 and 0.035 or 0.065,0.075,0.09,1)
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(21,21); row.icon:SetPoint("TOPLEFT",6,-2)
    row.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]; if coords then row.icon:SetTexCoord(unpack(coords)) end
    local name=(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token:sub(1,1)..token:sub(2):lower()
    label(row,name,36,-8,"GameFontHighlightSmall",114)
    row.pick=blessingPick(row,206,0,286,function() return B.db.blessingClasses[token] end,function(key) B.db.blessingClasses[token]=key end)
    row.pick.priorityClass=token; row.pick.priorityTarget=false
    row.pick.getOrder=function() return B.db.groupBlessingPriorities[token] end
    row.pick.setOrder=function(order) B.db.groupBlessingPriorities[token]=order end
    row.status=label(row,"",0,0,"GameFontDisableSmall",190); row.status:Hide()
    row.players=flatButton(row,"",548,-2,132,function()
      if A.Combat() or not B.db.blessingAssignments or not B.db.group then return end
      if f.expandedBlessing==token then f.expandedBlessing=nil else f.expandedBlessing=token end
      f.blessingPlayerOffset=0; B:Options()
    end)
    row.players:SetBackdropBorderColor(0,0,0,0); row.players:SetBackdropColor(0,0,0,0)
    row.players.arrow=row.players:CreateTexture(nil,"ARTWORK"); row.players.arrow:SetSize(18,18); row.players.arrow:SetPoint("LEFT",3,0)
    row.class=token; f.blessingRows[index]=row
  end
  local detail=CreateFrame("Frame",nil,p,"BackdropTemplate"); detail:SetSize(668,106); f.blessingDetail=detail
  detail:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  detail:SetBackdropColor(0.065,0.085,0.10,1); detail:SetBackdropBorderColor(0.22,0.32,0.38,1)
  label(detail,"Player exceptions",12,-6,"GameFontNormalSmall")
  f.blessingCollapse=arrowButton(detail,"",634,-2,26,function() f.expandedBlessing=nil; B:Options() end)
  local collapse=f.blessingCollapse:CreateTexture(nil,"ARTWORK"); collapse:SetAllPoints(); collapse:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
  f.blessingPlayerRows={}
  for i=1,2 do
    local row=CreateFrame("Frame",nil,detail); row:SetSize(660,26); row:SetPoint("TOPLEFT",4,-26-(i-1)*27)
    row.name=label(row,"",8,-7,"GameFontHighlightSmall",190)
    row.pick=blessingPick(row,210,0,190,function()
      local v=B.blessingPlayers and B.blessingPlayers[row.guid]; return v and v.choice
    end,function(key)
      if row.entry and A.Call(UnitGUID,row.entry.unit)==row.guid then
        local v=B.blessingPlayers and B.blessingPlayers[row.guid]; B:SetBlessingPlayer(row.entry,key,v and v.neverSalvation)
      end
    end,true)
    row.protect=check(row,L("Never Salvation"),430,-1,function(c)
      if row.entry and A.Call(UnitGUID,row.entry.unit)==row.guid then
        local v=B.blessingPlayers and B.blessingPlayers[row.guid]; B:SetBlessingPlayer(row.entry,v and v.choice,c:GetChecked()==true); B:Options()
      end
    end)
    addHelp(row.protect,L("Never Salvation"),"Blocks Salvation for this player and any Greater Salvation that would affect them. Choose another individual blessing if needed. No role or spec guessing.")
    f.blessingPlayerRows[i]=row
  end
  f.blessingPageText=label(detail,"",12,-85,"GameFontDisableSmall",380)
  f.blessingPrevious=button(detail,L("Previous"),444,-80,98,function() f.blessingPlayerOffset=math.max(0,(f.blessingPlayerOffset or 0)-2); B:Options() end)
  f.blessingNext=button(detail,L("Next"),548,-80,98,function() f.blessingPlayerOffset=(f.blessingPlayerOffset or 0)+2; B:Options() end)
  f.blessingFooter=label(p,"Mixed choices use individual blessings. Player exceptions last for this group session.",18,-602,"GameFontDisableSmall",686)
  button(p,"Existing buff filters",18,-574,160,function() f.blessingLegacy=true; B:Options() end)
  label(p,"Follow buff settings uses your enabled buffs, priorities and filters.",192,-581,"GameFontDisableSmall",510)
end
function B:UpdateBlessingOptions()
  local f=self.options; local class=A.Call(function() local _,token=UnitClass("player"); return token end); local paladin=class=="PALADIN"
  f.blessingPanel:SetShown(paladin and not f.blessingLegacy); f.legacyGroups:SetShown(not paladin or f.blessingLegacy)
  f.backBlessings:SetShown(paladin)
  if f.blessingMenu then f.blessingMenu:Hide() end
  if not paladin then return end
  f.blessingEnable:SetChecked(self.db.blessingAssignments); f.blessingGroupEnable:SetChecked(self.db.group); f.blessingSmart:SetChecked(self.db.smartGroup)
  for i,c in ipairs(f.blessingGroups) do c:SetChecked(self.db.raidGroups[i]) end
  f.blessingThreshold.silent=true; f.blessingThreshold:SetValue(self.db.blessingNeed); f.blessingThreshold.valueText:SetText(self.db.blessingNeed.."+"); f.blessingThreshold.silent=false
  local roster=self:Roster(); local active=self:BlessingAssignmentsActive(); self.blessingClassList=self:ClassList(); local y=-230
  local editable=self.db.blessingAssignments and self.db.group
  f.blessingInstruction:SetText(L(not self.db.blessingAssignments and "Enable class assignments to choose a blessing for each class." or not self.db.group and "Enable party / raid to use these class assignments." or "Open a class to select and order blessings. Player exceptions take precedence."))
  if not editable then f.expandedBlessing=nil end
  f.blessingDetail:Hide()
  for _,r in ipairs(f.blessingPlayerRows) do r:Hide(); r.entry=nil; r.guid=nil end
  for _,row in ipairs(f.blessingRows) do
    row:ClearAllPoints(); row:SetPoint("TOPLEFT",18,y); row.pick:Update()
    row.pick:SetAvailable(editable)
    local entries={}; for _,entry in ipairs(roster) do if entry.class==row.class then entries[#entries+1]=entry end end
    row.players:SetText(L(#entries==1 and "%d player" or "%d players",#entries))
    row.players:SetEnabled(editable and #entries>0); row.players:SetAlpha(editable and #entries>0 and 1 or 0.4)
    row.players.arrow:SetTexture(f.expandedBlessing==row.class and "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up" or "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    local chosen=self.db.blessingClasses[row.class]; local status="Current settings"
    if self.db.blessingAssignments then
      status=#entries==0 and "No group players" or "Individual"
      if not active then status="Party / raid inactive"
      elseif chosen=="skip" then status="Skipped"
      elseif #entries>0 then
        local first=self:BlessingChoice(entries[1]); local def=self:FindBuff(first)
        if first=="skip" then status="Skipped / excluded"
        elseif not def or not self:Resolve(def,entries[1].unit) then status="Not learned / target level"
        elseif not self:BlessingGreaterSafe(first,row.class,roster) then status="Individual: mixed / excluded"
        elseif not self.db.smartGroup then status="Individual: Greater off"
        elseif #entries>=self:BlessingGroupNeed(self:FindBuff(def.groupKey)) then status="|cff88dd88Greater allowed|r"
        else status="Individual: below threshold" end
      end
    end
    row.status:SetText(status); addHelp(row.players,"Player exceptions",L(status).."\n"..L("Click to expand or collapse individual player choices.")); y=y-26
    if f.expandedBlessing==row.class and #entries>0 then
      local offset=math.min(f.blessingPlayerOffset or 0,math.floor((#entries-1)/2)*2); f.blessingPlayerOffset=offset
      f.blessingDetail:ClearAllPoints(); f.blessingDetail:SetPoint("TOPLEFT",36,y); f.blessingDetail:Show()
      for i,r in ipairs(f.blessingPlayerRows) do
        local entry=entries[offset+i]
        if entry then
          r.entry=entry; r.guid=A.Call(UnitGUID,entry.unit); r.name:SetText(A.Call(UnitName,entry.unit) or entry.unit)
          r.pick:Update(); r.pick:SetAvailable(editable)
          local v=self.blessingPlayers and self.blessingPlayers[r.guid]; r.protect:SetChecked(v and v.neverSalvation or false); r.protect:SetEnabled(self.db.blessingAssignments); r:Show()
        end
      end
      f.blessingPageText:SetText("Players "..(offset+1).."–"..math.min(offset+2,#entries).." / "..#entries.." · choices override class")
      local paged=#entries>2; f.blessingPrevious:SetShown(paged); f.blessingNext:SetShown(paged)
      f.blessingPrevious:SetEnabled(offset>0); f.blessingNext:SetEnabled(offset+2<#entries)
      local height=paged and 106 or (#entries==1 and 78 or 106)
      f.blessingDetail:SetHeight(height)
      f.blessingPageText:ClearAllPoints(); f.blessingPageText:SetPoint("TOPLEFT",12,height==78 and -59 or -85)
      y=y-height-2
    end
  end
end

function B:BuildSupplyOptions(parent)
  local f=self.options
  local p=CreateFrame("Frame",nil,parent)
  p:SetPoint("TOPLEFT",0,-36); p:SetPoint("BOTTOMRIGHT",0,0); f.supplyBody=p
  label(p,L("Supplies"),18,-16,"GameFontNormalLarge")
  label(p,L("Optional bag-stock warnings for selected weapon consumables and buff items."),18,-42,"GameFontDisableSmall",670)
  f.supplyEnable=check(p,L("Enable supply warnings"),18,-70,function(c) setAndRefresh("suppliesEnabled",c:GetChecked()==true); B:UpdateSupplyOptions() end)
  addHelp(f.supplyEnable,"Supply warnings","Shows a small stock indicator beside BuffTap. Counts carried usable items only. No purchases, bank tracking, or changes to casting priorities.")
  f.supplyChat=check(p,L("Private chat alerts"),18,-102,function(c) setAndRefresh("suppliesChat",c:GetChecked()==true) end)
  f.supplySound=check(p,L("Alert sound"),230,-102,function(c) setAndRefresh("suppliesSound",c:GetChecked()==true) end)
  f.supplyReady=check(p,L("Private ready-check summary"),410,-102,function(c) setAndRefresh("suppliesReadyCheck",c:GetChecked()==true) end)
  addHelp(f.supplyChat,"Private stock alerts","One message when an enabled supply becomes low or empty. Restocking above its minimum resets the warning. Nothing is sent to other players.")
  addHelp(f.supplyReady,"Ready-check supply summary","Reports enabled supply shortages to you when a ready check starts. This checks stock, not raid buffs, cooldowns, or whether you are ready to fight. In combat, reports wait for combat to end, for up to 30 seconds.")
  line(p,-140)
  label(p,L("Track / supply"),18,-158,"GameFontDisableSmall",250)
  label(p,L("Usable"),298,-158,"GameFontDisableSmall",60)
  label(p,"Warn below",365,-158,"GameFontDisableSmall",75)
  label(p,"Want",462,-158,"GameFontDisableSmall",55)
  label(p,"Missing",550,-158,"GameFontDisableSmall",70)
  f.supplyRows={}
  for i=1,5 do
    local row=CreateFrame("Frame",nil,p,"BackdropTemplate")
    row:SetSize(676,43); row:SetPoint("TOPLEFT",12,-180-(i-1)*47)
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.065,0.085,0.10,0.95)
    row.enable=check(row,"",0,-7,function(c)
      if A.Combat() then return end
      local entry=c:GetParent().entry
      if entry then entry.settings.enabled=c:GetChecked()==true; B:InvalidateSupplies(false); B:UpdateSupplyOptions() end
    end)
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(26,26); row.icon:SetPoint("TOPLEFT",27,-8)
    row.name=label(row,"",62,-6,"GameFontHighlightSmall",214)
    row.name:SetWordWrap(false); row.name:SetHeight(16)
    row.state=label(row,"",62,-23,"GameFontDisableSmall",214)
    row.count=label(row,"",288,-13,"GameFontHighlightSmall",52)
    row.minimum=editbox(row,366,-10,44,true)
    row.target=editbox(row,452,-10,44,true)
    row.shortfall=label(row,"",545,-13,"GameFontHighlightSmall",74)
    for _,field in ipairs({"minimum","target"}) do
      local key=field
      row[field]:SetScript("OnEnterPressed",function(e)
        if A.Combat() then return end
        local entry=e:GetParent().entry; local value=tonumber(e:GetText())
        if entry and A.Number(value) then
          entry.settings[key]=math.max(1,math.min(999,math.floor(value)))
          entry.settings.target=math.max(entry.settings.minimum,entry.settings.target)
          B:InvalidateSupplies(false)
        end
        e:ClearFocus(); B:UpdateSupplyOptions()
      end)
      row[field]:SetScript("OnEscapePressed",function(e) e:ClearFocus(); B:UpdateSupplyOptions() end)
    end
    addHelp(row.minimum,"Warn below","Alert when usable stock falls below this number. Zero stock always warns. Press Enter to save.")
    addHelp(row.target,L("Desired stock"),"Your personal target quantity. Missing shows how many more usable items would reach it. BuffTap does not buy them. Press Enter to save.")
    f.supplyRows[i]=row
    label(row,L("Enter to save"),366,-31,"GameFontDisableSmall",144)
  end
  f.supplyEmpty=label(p,"",18,-190,"GameFontHighlightSmall",665)
  f.supplySnooze=button(p,L("Snooze 10 min"),18,-468,122,function() B:SnoozeSupplies() end)
  button(p,L("Restore alerts"),150,-468,118,function() B:RestoreSupplies() end)
  button(p,L("Check supplies"),554,-468,126,function() B:ReportSupplies() end)
  f.supplyHint=label(p,"Warnings do not block your buff queue. Shared weapon consumable choices count once.",18,-434,"GameFontDisableSmall",660)
end

function B:UpdateSupplyOptions()
  local f=self.options
  if not f or not f.supplyBody or A.Combat() then return end
  local entries=self:SyncSupplies()
  f.supplyEnable:SetChecked(self.db.suppliesEnabled)
  f.supplyChat:SetChecked(self.db.suppliesChat); f.supplySound:SetChecked(self.db.suppliesSound); f.supplyReady:SetChecked(self.db.suppliesReadyCheck)
  for i,row in ipairs(f.supplyRows) do
    local entry=entries[i]
    if row.entry and (not entry or row.entry.key~=entry.key) then row.minimum:ClearFocus(); row.target:ClearFocus() end
    row.entry=entry; row:SetShown(entry~=nil)
    if entry then
      row.enable:SetChecked(entry.settings.enabled); row.icon:SetTexture(entry.icon); row.name:SetText(entry.name)
      local states={loading="Inventory settling",unknown="Stock or item data unavailable",empty=L("Out of stock"),unusable="Carried, none usable",low="Low stock",ok="Stock ready"}
      row.state:SetText(states[entry.state] or "Unknown")
      row.count:SetText(entry.count~=nil and tostring(entry.count) or "?")
      if not row.minimum:HasFocus() then row.minimum:SetText(tostring(entry.settings.minimum)) end
      if not row.target:HasFocus() then row.target:SetText(tostring(entry.settings.target)) end
      row.shortfall:SetText(entry.shortfall~=nil and tostring(entry.shortfall) or "?")
      addHelp(row,entry.name,entry.detail.."\nCarried: "..tostring(entry.carried or "?")..". Unreadable counts never trigger a shortage warning."..
        (entry.mappingMismatch and "\nAn item effect differs from BuffTap's supported catalog and is excluded." or ""))
    end
  end
  f.supplyEmpty:SetShown(#entries==0)
  f.supplyEmpty:SetText(not self.db.enabled and "Enable BuffTap to resume supply tracking." or not self.db.suppliesEnabled and "Enable supply warnings to configure stock thresholds." or
    "Enable a buff consumable reminder, or select a poison, oil or stone for an equipped weapon.")
  f.supplyHint:SetText(self:SupplySnoozed() and "Stock alerts are snoozed for 10 minutes; ready-check summaries remain available." or
    "Warnings do not block your buff queue. Shared weapon consumable choices count once.")
end

function B:ShowSuppliesOptions()
  if A.Combat() then return end
  self:Options(); self.options.selectTab(TAB.Consumables); self.options.selectConsumableView(true)
end

function B:CaptureBinding()
  if A.Combat() then return end
  if not self.capture then
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); self.capture=f
    f:SetAllPoints(); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:EnableKeyboard(true); f:EnableMouse(true); f:EnableMouseWheel(true); f:SetPropagateKeyboardInput(false)
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.01,0.02,0.04,0.90)
    local logo=f:CreateTexture(nil,"ARTWORK"); logo:SetSize(88,88); logo:SetPoint("CENTER",0,78); logo:SetTexture(ICON_PATH)
    local hint=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); hint:SetPoint("CENTER",0,-8); hint:SetJustifyH("CENTER")
    hint:SetText("Set BuffTap binding\n\nPress a key, middle/side mouse button, or scroll wheel\nLeft/right click requires Shift, Ctrl, or Alt\n|cff8aa5b8Escape cancels|r")
    local function bind(key)
      if A.Combat() then f:Hide(); return end
      if IsShiftKeyDown() then key="SHIFT-"..key end
      if IsControlKeyDown() then key="CTRL-"..key end
      if IsAltKeyDown() then key="ALT-"..key end
      local keys=B:NormalizeBindings({key})
      if #keys==0 then return end
      B.db.keys=keys; f:Hide(); B.appearance=nil; B:RequestRefresh("binding",0); B:Status(false)
      if B.options and B.options:IsShown() then B:Options() end
    end
    f:SetScript("OnKeyDown",function(_,key)
      if key=="ESCAPE" then f:Hide(); return end
      if key:find("SHIFT") or key:find("CTRL") or key:find("ALT") or key:find("META") then return end
      bind(key)
    end)
    f:SetScript("OnMouseDown",function(_,btn)
      if (btn=="LeftButton" or btn=="RightButton") and not (IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown()) then return end
      if btn=="LeftButton" then bind("BUTTON1")
      elseif btn=="RightButton" then bind("BUTTON2")
      elseif btn=="MiddleButton" then bind("BUTTON3")
      elseif type(btn)=="string" and btn:match("^Button%d+$") then bind(btn:upper()) end
    end)
    f:SetScript("OnMouseWheel",function(_,delta) bind(delta>0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:SetScript("OnEvent",function() f:Hide() end)
  end
  self.capture:Show()
end

local function logicalBuffs()
  local out={}
  for _,b in ipairs(B:ClassList()) do
    local supported=B:Supported(b)
    if supported and not b.singleKey then out[#out+1]=b end
  end
  return out
end

function B:MoveBuffPriority(key,destination)
  if A.Combat() then return false end
  local list=logicalBuffs(); local from,to
  for i,def in ipairs(list) do if def.key==key then from=i end; if def.key==destination then to=i end end
  if not from or not to or from==to then return false end
  table.insert(list,to,table.remove(list,from))
  for i,def in ipairs(list) do self.db.priorities[def.key]=i end
  self.blessingClassList=nil; self:InvalidateAura(); self:RequestRefresh("buff order",0); self:Options()
  return true
end

local function pairedGroupName(b)
  if not b.groupKey then return nil end
  local g=B:FindBuff(b.groupKey)
  return g and spellLabel(g) or nil
end

local function groupAssignableBuffs()
  return B:GroupAssignableBuffs()
end

local function targetAssignableBuffs()
  return B:TargetAssignableBuffs()
end

local function consumableChoiceLabel(family)
  local id=B.ConsumableChoiceID and B:ConsumableChoiceID(family)
  if not id then
    if family.explicitChoice then return L("Choose an item"),134400 end
    local item=B.PreferredConsumableItem and B:PreferredConsumableItem(family)
    if item then
      local info=B.ConsumableItemInfo and B:ConsumableItemInfo(item.id,item)
      local name=(info and info.name) or item.name or ("Item "..tostring(item.id))
      return L("Auto: %s",name), (info and info.texture or item.icon or 134400)
    end
    return L("Auto (none in bags)"),134400
  end
  for _,item in ipairs(family.items or {}) do
    if item.id==id then
      local info=B.ConsumableItemInfo and B:ConsumableItemInfo(id,item)
      return (info and info.name or item.name), (info and info.texture or item.icon or 134400)
    end
  end
  return L("Auto (none in bags)"),134400
end

-- Helpers share the main window and tab lifecycle. Compact descriptions keep
-- the separated sections visible together; detailed help stays in tooltips.
function B:BuildHelperPage(parent)
  local f=panel(parent); parent.pages[TAB.Helpers]=f; self.helperWindow=f
  label(f,L("Everyday conveniences"),18,-16,"GameFontNormalLarge")
  label(f,L("Choose the extras you want. All start off; your existing buff settings are preserved."),18,-43,"GameFontDisableSmall",680)
  f.checks={}; f.descriptions={}; f.trackers={}
  local settings={
    {"helperDismiss",L("Dismiss a reminder for now"),L("Right-click a buff or item reminder to skip it until you change zones. Restore reminders below brings it back sooner.")},
    {"helperBounce",L("Stop repeated stronger-buff errors"),L("If your BuffTap click fails because a stronger buff is active, hide that reminder until a zone change or manual restore.")},
    {"helperQuick",L("Choose consumables from the icon"),L("Hover a food, flask or elixir reminder to pick another supported item in your bags. Click the main icon to use your choice.")},
    {"helperCoverage",L("Show missing party buffs"),L("Shows buffs your five-player party may be missing and who might provide them. Information only: no casting or chat messages.")},
    {"helperDiscovery",L("Find unrecognized consumables"),L("Lists bag consumables missing from BuffTap's supported list for review. It does not add or use them. View the report in Diagnostics.")},
  }
  local descriptions={
    L("Skip until a zone change, or restore the reminder below."),
    L("Hide reminders after a stronger-buff error until a zone change or manual restore."),
    L("Choose supported food, flasks or elixirs from the reminder icon."),
    L("Shows missing party buffs. Information only; no casting or chat."),
    L("Lists unsupported bag consumables in Diagnostics. Never uses them."),
  }
  for i,spec in ipairs(settings) do
    local x=18+((i-1)%2)*346; local y=-67-math.floor((i-1)/2)*62
    card(f,x-4,y+2,336,58)
    local key=spec[1]
    f.checks[key]=check(f,spec[2],x,y,function(c)
      if A.Combat() then return end
      B.db[key]=c:GetChecked()==true
      if key=="helperThanks" then B.helperThankSeen=nil; B:ObserveSoloThanks(true) end
      if key=="helperDiscovery" then B.helperDiscoverDirty=true end
      if key=="helperDismiss" or key=="helperBounce" then B:RestoreHelpers() end
      B:RequestRefresh("helper setting",0); B:Options()
    end)
    f.descriptions[key]=label(f,descriptions[i],x+4,y-27,"GameFontDisableSmall",326)
    addHelp(f.checks[key],spec[2],spec[3])
  end
  card(f,364,-189,336,58)
  parent.pauseResting=check(f,"Pause reminders while resting",368,-191,function(c)
    if A.Combat() then return end
    setAndRefresh("pauseResting",c:GetChecked()==true); B:InvalidateSupplies(false); B:Refresh(false); B:Options()
  end)
  label(f,L("Pause reminders and stock alerts in cities and inns."),372,-218,"GameFontDisableSmall",320)
  addHelp(parent.pauseResting,"Pause reminders while resting","Hide buff reminders and quiet automatic stock alerts in cities and inns. Settings remain accessible.")
  line(f,-262)
  label(f,L("Solo thanks"),18,-275,"GameFontNormalLarge")
  f.checks.helperThanks=check(f,L("Thank players who buff me solo"),18,-305,function(c)
    if A.Combat() then return end
    B.db.helperThanks=c:GetChecked()==true; B.helperThankSeen=nil; B:ObserveSoloThanks(true)
    B:RequestRefresh("solo thanks",0); B:Options()
  end)
  addHelp(f.checks.helperThanks,L("Solo thanks"),L("Thanks an identified solo buff provider. Never in groups, instances or combat. Limited to once a minute and once per player per 10 minutes."))
  f.descriptions.helperThanks=label(f,L("Thanks solo buff providers, at most once a minute. Never in groups, instances or combat."),22,-333,"GameFontDisableSmall",326)
  label(f,L("Solo response emote"),368,-279,"GameFontNormal",320)
  f.thankEmote=selector(f,"",364,-303,324,function() return B:SoloThankEmotes() end,function(choice)
    B.db.helperThankEmote=choice
    -- Configuration only: never sends an emote or resets cooldowns.
  end,"scroll")
  addHelp(f.thankEmote,L("Solo response emote"),L("Directed reactions only. No sitting, sleeping or looping animations. Changing this never sends an emote."))
  f.readiness=CreateFrame("Frame",nil,f); f.readiness:SetAllPoints(f)
  local r=f.readiness
  line(r,-369)
  f.readinessIcon=r:CreateTexture(nil,"ARTWORK")
  f.readinessIcon:SetSize(24,24); f.readinessIcon:SetPoint("TOPLEFT",18,-378)
  f.readinessIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
  label(r,L("Class readiness"),52,-382,"GameFontNormalLarge")
  f.petCheck=check(r,L("Keep my pet ready"),18,-414,function(c)
    if A.Combat() then return end
    B.db.helperPet=c:GetChecked()==true; B:SyncReadiness(); B:RequestRefresh("pet helper",0); B:Options()
  end)
  f.petDescription=label(r,"",22,-440,"GameFontDisableSmall",326)
  f.stoneCheck=check(r,L("Prepare a personal Healthstone"),364,-414,function(c)
    if A.Combat() then return end
    B.db.helperHealthstone=c:GetChecked()==true; B:SyncReadiness(); B:RequestRefresh("Healthstone helper",0); B:Options()
  end)
  f.stoneDescription=label(r,L("Creates a missing Healthstone. Requires a Soul Shard and free bag space."),368,-440,"GameFontDisableSmall",326)
  f.soulCheck=check(r,L("Keep a Soulstone up"),364,-480,function(c)
    if A.Combat() then return end
    B.db.helperSoulstone=c:GetChecked()==true; B:SyncReadiness(); B:RequestRefresh("Soulstone helper",0); B:Options()
  end)
  f.soulTarget=flatButton(r,"Target",560,-480,128,function()
    if A.Combat() then return end
    local menu=f.soulMenu
    f.demonMenu:Hide(); f.thankEmote.menu:Hide()
    menu.feedback:SetText(L("Target a friendly player in-game, then click Use current target. This enables Assigned player for your current party or raid."))
    menu.feedback:SetTextColor(.73,.73,.70)
    menu:SetShown(not menu:IsShown())
    if menu:IsShown() then menu:Raise() end
  end)
  selectorArrow(f.soulTarget)
  f.soulMenu=CreateFrame("Frame",nil,f,"BackdropTemplate")
  local sm=f.soulMenu; sm:SetSize(400,394); sm:SetPoint("BOTTOMRIGHT",f.soulTarget,"TOPRIGHT",0,2)
  sm:SetFrameStrata("FULLSCREEN_DIALOG"); sm:SetFrameLevel(f:GetFrameLevel()+20); sm:SetClampedToScreen(true); sm:EnableMouse(true)
  sm:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  sm:SetBackdropColor(.04,.04,.04,1); sm:Hide()
  sm:EnableKeyboard(true); sm:SetPropagateKeyboardInput(true)
  sm:SetScript("OnKeyDown",function(control,key)
    control:SetPropagateKeyboardInput(key~="ESCAPE")
    if key=="ESCAPE" then control:Hide() end
  end)
  sm:HookScript("OnShow",function() sm:SetPropagateKeyboardInput(true) end)
  local function setSoul(field,value)
    if A.Combat() then return end
    B.db[field]=value; B.readinessPending=nil; B:RequestRefresh("Soulstone target",0); B:Options()
    if value=="assigned" and B.db.soulstoneAssigned=="" then
      sm.feedback:SetText(L("Use current target below to save a friendly player."))
      sm.feedback:SetTextColor(1,.82,.1)
    end
  end
  label(sm,L("Soulstone target"),16,-14,"GameFontNormalLarge")
  label(sm,L("Solo: always yourself"),16,-36,"GameFontDisableSmall",368)
  label(sm,L("In a party"),16,-58,"GameFontNormal")
  sm.party={
    healer=check(sm,L("Healer role"),16,-72,function() setSoul("soulstoneParty","healer") end),
    self=check(sm,L("Me"),16,-100,function() setSoul("soulstoneParty","self") end),
    assigned=check(sm,L("Assigned player"),16,-128,function() setSoul("soulstoneParty","assigned") end),
  }
  line(sm,-162)
  label(sm,L("In a raid"),16,-176,"GameFontNormal")
  sm.raid={
    remind=check(sm,L("Remind only"),16,-200,function() setSoul("soulstoneRaid","remind") end),
    assigned=check(sm,L("Assigned player"),16,-228,function() setSoul("soulstoneRaid","assigned") end),
  }
  line(sm,-262)
  sm.assignedLabel=label(sm,"",16,-276,"GameFontHighlightSmall",368)
  sm.feedback=label(sm,L("Target a friendly player in-game, then click Use current target. This enables Assigned player for your current party or raid."),16,-300,"GameFontDisableSmall",368)
  sm.useTarget=button(sm,"Use current target",16,-356,172,function()
    if A.Combat() then return end
    local raid=A.Call(IsInRaid)
    local saved=(raid==true or raid==false) and B:SetSoulstoneAssignedFromTarget()
    if saved then
      B.db[raid and "soulstoneRaid" or "soulstoneParty"]="assigned"
      B.readinessPending=nil; B:RequestRefresh("Soulstone assignment",0)
      sm.feedback:SetText(L(raid and "Saved for your raid." or "Saved for your party."))
      sm.feedback:SetTextColor(.4,1,.6)
    else
      sm.feedback:SetText(L("Select a friendly player other than yourself, then try again."))
      sm.feedback:SetTextColor(1,.35,.3)
    end
    B:Options()
  end)
  sm.clear=button(sm,"Clear",196,-356,84,function()
    if A.Combat() then return end
    B.db.soulstoneAssigned=""
    if B.db.soulstoneParty=="assigned" then B.db.soulstoneParty="healer" end
    if B.db.soulstoneRaid=="assigned" then B.db.soulstoneRaid="remind" end
    B.readinessPending=nil; B:RequestRefresh("Soulstone assignment",0); B:Options()
    sm.feedback:SetText(L("Assignment cleared.")); sm.feedback:SetTextColor(.73,.73,.70)
  end)
  sm.done=button(sm,"Done",288,-356,96,function() sm:Hide() end)
  f.demonChoice=flatButton(r,"Choose preferred demon",18,-480,326,function()
    if A.Combat() then return end
    f.demonMenu:SetShown(not f.demonMenu:IsShown())
  end)
  selectorArrow(f.demonChoice)
  f.demonChoice.icon=f.demonChoice:CreateTexture(nil,"ARTWORK")
  f.demonChoice.icon:SetSize(20,20); f.demonChoice.icon:SetPoint("LEFT",3,0)
  f.demonMenu=CreateFrame("Frame",nil,f,"BackdropTemplate")
  local menu=f.demonMenu; menu:SetSize(326,158); menu:SetPoint("BOTTOMLEFT",f.demonChoice,"TOPLEFT",0,2)
  menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetFrameLevel(f:GetFrameLevel()+20); menu:SetClampedToScreen(true); menu:EnableMouse(true)
  menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  menu:SetBackdropColor(.04,.04,.04,1); menu.rows={}; menu:Hide()
  f:SetScript("OnHide",function() menu:Hide(); f.soulMenu:Hide() end)
  f.trackerLine=line(f,-516)
  f.trackerHeading=label(f,L("Gathering tracker"),18,-529,"GameFontNormalLarge")
  f.checks.helperTracking=check(f,L("Remind me to enable tracking"),18,-557,function(c)
    if A.Combat() then return end
    B.db.helperTracking=c:GetChecked()==true; B:RequestRefresh("tracking reminder",0); B:Options()
  end)
  addHelp(f.checks.helperTracking,L("Remind me to enable tracking"),L("Choose Herbs, Minerals or Fish below. When that tracker is off, BuffTap offers a one-tap reminder to turn it on."))
  f.emptyTracker=label(f,L("No learned gathering tracker is available on this character."),254,-565,"GameFontDisableSmall",440)
  button(f,L("Restore reminders"),24,-590,154,function() B:RestoreHelpers(); B:Options() end)
  button(f,L("View discovery report"),490,-590,204,function() B:ShowDiscoveryReport() end)
end

function B:UpdateHelperOptions()
  local f=self.helperWindow; if not f then return end
  local class=self:ReadinessClass(); local warlock=class=="WARLOCK"
  f.readiness:SetShown(warlock or class=="HUNTER"); f.demonMenu:Hide()
  local classCoords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    or (warlock and {.75,1,.25,.5} or class=="HUNTER" and {0,.25,.25,.5})
  if classCoords then f.readinessIcon:SetTexCoord(unpack(classCoords)) end
  f.petCheck:SetChecked(self.db.helperPet==true); f.stoneCheck:SetChecked(self.db.helperHealthstone==true)
  f.soulCheck:SetChecked(self.db.helperSoulstone==true)
  f.soulTarget:SetShown(warlock)
  if not warlock then f.soulMenu:Hide() end
  local sm=f.soulMenu
  for key,c in pairs(sm.party) do c:SetChecked(self.db.soulstoneParty==key) end
  for key,c in pairs(sm.raid) do c:SetChecked(self.db.soulstoneRaid==key) end
  sm.assignedLabel:SetText(L("Assigned player: ")..(self.db.soulstoneAssigned~="" and self.db.soulstoneAssigned or L("none")))
  sm.assignedLabel:SetTextColor(self.db.soulstoneAssigned~="" and .4 or 1,self.db.soulstoneAssigned~="" and 1 or .65,self.db.soulstoneAssigned~="" and .6 or .35)
  addHelp(f.soulTarget,L("Soulstone target"),L("Party: the member with the Healer group role, yourself, or an assigned player (falls back to the Healer role, then you). Raid: remind only, or place it on your assigned player. Target a friendly player and press Use current target to assign them."))
  f.stoneCheck:SetShown(warlock); f.stoneDescription:SetShown(warlock); f.soulCheck:SetShown(warlock); f.demonChoice:SetShown(warlock)
  f.petDescription:SetText(warlock and L("Summons your chosen demon when no pet is alive. Respects Demonic Sacrifice.")
    or L("Revives a dead pet, or reminds you to call an absent pet manually."))
  addHelp(f.petCheck,L("Pet readiness"),"Offers recovery only out of combat, while stationary and unmounted. Any living pet satisfies this reminder.")
  addHelp(f.soulCheck,L("Keep a Soulstone up"),L("When nobody in your party has Soulstone Resurrection (in a raid: none of yours), places a carried Soulstone on the target chosen under Target. With no stone in your bags it offers Create Soulstone first (Soul Shard and free space)."))
  addHelp(f.stoneCheck,"Personal Healthstone","Creates one personal stone with a click. Any supported carried Healthstone satisfies the reminder, regardless of cooldown. Bank stock does not count.")
  local demons=self:ReadinessDemons(); local chosen
  for _,row in ipairs(f.demonMenu.rows) do row:Hide() end
  for i,entry in ipairs(demons) do
    local row=f.demonMenu.rows[i]
    if not row then
      row=flatButton(f.demonMenu,"",6,-7-(i-1)*29,314,function(control)
        if A.Combat() then return end
        B.db.helperDemon=control.spellID; B.readinessPending=nil; B:ExpireReadiness()
        B:RequestRefresh("preferred demon",0); B:Options()
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",3,0)
      f.demonMenu.rows[i]=row
    end
    row.spellID=entry.id; row:SetText("    "..entry.name); row.icon:SetTexture(entry.icon); row:Show()
    if entry.id==self.db.helperDemon then chosen=entry end
  end
  f.demonMenu:SetHeight(math.max(1,#demons)*29+13)
  f.demonChoice:SetText(chosen and ("    "..chosen.name.."  v") or (#demons>0 and "Choose preferred demon  v" or "No learned summon available"))
  f.demonChoice.icon:SetTexture(chosen and chosen.icon or nil)
  if #demons>0 then f.demonChoice:Enable() else f.demonChoice:Disable() end
  local emote=self:SoloThankEmote()
  for _,entry in ipairs(self:SoloThankEmotes()) do if entry.key==emote then f.thankEmote:SetText(entry.name); break end end
  -- Players may configure a response before enabling automatic solo thanks.
  f.thankEmote:Enable()
  for key,c in pairs(f.checks) do c:SetChecked(self:HelperEnabled(key)) end
  for _,t in ipairs(f.trackers) do t:Hide() end
  local trackers=self:GatheringTrackers(); f.emptyTracker:SetShown(#trackers==0)
  local selected=false
  for _,entry in ipairs(trackers) do if entry.id==self.db.helperTracker then selected=true end end
  f.trackerHeading:SetText(L("Gathering tracker"))
  local trackerY=(warlock or class=="HUNTER") and -529 or -382
  f.trackerLine:ClearAllPoints(); f.trackerLine:SetPoint("TOPLEFT",18,trackerY+13); f.trackerLine:SetPoint("TOPRIGHT",-18,trackerY+13)
  f.trackerHeading:ClearAllPoints(); f.trackerHeading:SetPoint("TOPLEFT",18,trackerY)
  f.checks.helperTracking:ClearAllPoints(); f.checks.helperTracking:SetPoint("TOPLEFT",18,trackerY-28)
  f.emptyTracker:ClearAllPoints(); f.emptyTracker:SetPoint("TOPLEFT",254,trackerY-36)
  for i,entry in ipairs(trackers) do
    local t=f.trackers[i]
    if not t then
      t=flatButton(f,"",254+(i-1)*148,trackerY-26,140,function(control)
        if A.Combat() then return end
        B.db.helperTracker=control.trackerID; B:RequestRefresh("tracking preference",0); B:Options()
      end)
      t.icon=t:CreateTexture(nil,"ARTWORK"); t.icon:SetSize(20,20); t.icon:SetPoint("LEFT",3,0)
      f.trackers[i]=t
    end
    t:ClearAllPoints(); t:SetPoint("TOPLEFT",254+(i-1)*148,trackerY-26)
    t.trackerID=entry.id; t.icon:SetTexture(entry.icon)
    t:SetText((self.db.helperTracker==entry.id and "    > " or "    ")..entry.name)
    if self:HelperEnabled("helperTracking") then t:Enable(); t:SetAlpha(1) else t:Disable(); t:SetAlpha(.45) end
    addHelp(t,entry.name,"Select this tracker as your preference. Enable the tracking reminder above to receive prompts.")
    t:Show()
  end
end

function B:HelperOptions()
  if A.Combat() then return end
  self:Options(); self.options.selectTab(TAB.Helpers)
end

function B:ShowDiscoveryReport()
  if A.Combat() then return end
  self:Options()
  local f=self.options; f.selectTab(TAB.Diagnostics)
  if self:HelperEnabled("helperDiscovery") and self.helperDiscoverDirty then self:DiscoverConsumables() end
  local report={"Unknown consumables - review only", "These items are not automatically added or used.", ""}
  if self:HelperEnabled("helperDiscovery") then
    report[#report+1]=self.helperDiscoveryStatus or "No scan yet. Choose Rescan bags below."
    for _,item in ipairs(self.helperDiscoveries or {}) do
      local info=self:ConsumableItemInfo(item.id)
      report[#report+1]=item.name.." | item "..item.id.." | use spell "..tostring(info.spellID or "unavailable")
    end
  else report[#report+1]="Enable Find unrecognized consumables on the Helpers tab to scan your bags." end
  f.discoveryReport:SetText(table.concat(report,"\n")); f.discoveryReport:SetCursorPosition(0)
  f.diagText:Hide(); f.discoveryScroll:Show()
end

function B:ShowQuickChoices(action,page)
  if A.Combat() or not self:HelperEnabled("helperQuick") or not action or action.source~="consumable" then return end
  local family=self:ConsumableFamily(action.familyKey)
  if not family then return end
  local f=self.quickChoices
  if not f then
    f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); self.quickChoices=f
    f:SetSize(300,244); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetClampedToScreen(true); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12}); f:SetBackdropColor(.06,.06,.06,.98)
    label(f,"Choose, then use the main icon",12,-12,"GameFontNormalSmall")
    f.rows={}
    for i=1,6 do
      local row=flatButton(f,"",12,-34-(i-1)*28,274,function(s)
        if A.Combat() or not s.itemID then return end
        B:SetConsumableChoice(f.family,s.itemID); f:Hide(); B:RequestRefresh("quick item choice",0)
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",2,0)
      row.itemName=label(row,"",30,-5,"GameFontHighlightSmall",202); row.itemName:SetWordWrap(false)
      row.stock=label(row,"",236,-5,"GameFontHighlightSmall",34)
      f.rows[i]=row
    end
    button(f,"<",12,-210,34,function() B:ShowQuickChoices(B.action,(f.page or 1)-1) end)
    button(f,">",52,-210,34,function() B:ShowQuickChoices(B.action,(f.page or 1)+1) end)
    button(f,"All items",92,-210,92,function() f:Hide(); B:ChooseConsumable(f.family) end)
    button(f,L("Close"),192,-210,94,function() f:Hide() end)
  end
  local choices={}
  for _,item in ipairs(family.items or {}) do if self:ConsumableCount(item.id)>0 then choices[#choices+1]=item end end
  if #choices==0 then f:Hide(); return end
  f.family=family; f.page=math.max(1,math.min(page or 1,math.ceil(#choices/6)))
  f:ClearAllPoints(); f:SetPoint("TOPLEFT",self.button,"TOPRIGHT",8,0)
  for i,row in ipairs(f.rows) do
    local item=choices[(f.page-1)*6+i]
    if item then
      local info=self:ConsumableItemInfo(item.id,item)
      row.itemID=item.id; row:SetText(""); row.itemName:SetText(info.name); row.stock:SetText(tostring(self:ConsumableCount(item.id)))
      row.icon:SetTexture(info.texture); addHelp(row,info.name,"Select preference only. Use the main icon to apply; all normal validation still applies."); row:Show()
    else row.itemID=nil; row:Hide() end
  end
  f:Show()
end

function B:UpdateCoverageDisplay()
  local lines=self:CoverageLines()
  if #lines==0 or not self.db.enabled then if self.coverageFrame then self.coverageFrame:Hide() end; return end
  local f=self.coverageFrame
  if not f then
    f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); self.coverageFrame=f
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); f:SetBackdropColor(.04,.04,.04,.85); f:SetClampedToScreen(true)
    f.text=label(f,"",8,-8,"GameFontHighlightSmall",350)
  end
  f:SetSize(366,42+#lines*28); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y-100-#lines*14)
  f.text:SetText("|cffffcc66Party coverage - informational|r\n"..table.concat(lines,"\n")); f:Show()
end

-- Fixed visible row pool: catalog scrolling never creates hundreds of widgets.
function B:ChooseConsumable(family,anchor)
  if A.Combat() then return end
  local f=self.itemPicker
  if not f then
    f=CreateFrame("Frame","BuffTapItemPicker",self.options,"BackdropTemplate"); self.itemPicker=f
    f:SetSize(650,550); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetClampedToScreen(true); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14})
    f:SetBackdropColor(0.045,0.045,0.04,1); f:SetBackdropBorderColor(0.60,0.48,0.25,1)
    f.title=label(f,"Choose item",20,-18,"GameFontNormalLarge")
    button(f,L("Close"),550,-14,78,function() f:Hide() end)
    label(f,L("Search"),20,-59,"GameFontHighlightSmall")
    f.search=editbox(f,76,-54,300,false)
    f.bags=check(f,L("In bags only"),410,-54,function() f.offset=0; B:UpdateConsumablePicker() end)
    f.auto=flatButton(f,"",20,-90,606,function()
      if A.Combat() then return end
      B:SetConsumableChoice(f.family,nil); B:InvalidateConsumables(); B:RequestRefresh("auto selected",0); B:Options(); B:UpdateConsumablePicker()
    end)
    label(f,L("Item"),66,-127,"GameFontNormalSmall"); label(f,L("In bags"),518,-127,"GameFontNormalSmall")
    f.rows={}
    for i=1,8 do
      local row=flatButton(f,"",20,-147-(i-1)*34,580,function(btn)
        if A.Combat() then return end
        B:SetConsumableChoice(f.family,btn.itemID); B:InvalidateConsumables(); B:RequestRefresh("item selected",0)
        B:Options(); B:UpdateConsumablePicker()
      end)
      row:SetHeight(32)
      row.mark=label(row,"",6,-9,"GameFontNormalSmall",20)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(24,24); row.icon:SetPoint("TOPLEFT",25,-4)
      row.name=label(row,"",56,-9,"GameFontHighlightSmall",380)
      row.stock=label(row,"",448,-9,"GameFontHighlightSmall",124)
      f.rows[i]=row
    end
    f.scroll=CreateFrame("Slider",nil,f,"OptionsSliderTemplate"); f.scroll:SetOrientation("VERTICAL")
    f.scroll:SetSize(16,268); f.scroll:SetPoint("TOPLEFT",610,-147); f.scroll:SetMinMaxValues(0,1); f.scroll:SetValueStep(1)
    if f.scroll.SetObeyStepOnDrag then f.scroll:SetObeyStepOnDrag(true) end
    if f.scroll.Text then f.scroll.Text:Hide() end
    if f.scroll.Low then f.scroll.Low:Hide() end; if f.scroll.High then f.scroll.High:Hide() end
    f.scroll:SetScript("OnValueChanged",function(self,value)
      if self.silent then return end
      f.offset=math.floor(value+0.5); B:UpdateConsumablePicker()
    end)
    f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function(_,delta)
      f.offset=math.max(0,math.min(f.maxOffset or 0,(f.offset or 0)-delta*3)); B:UpdateConsumablePicker()
    end)
    f.empty=label(f,L("No matching items. Clear search or turn off In bags only."),40,-245,"GameFontHighlight",520)
    f.summary=label(f,"",20,-428,"GameFontNormal",590)
    f.hint=label(f,"",20,-452,"GameFontHighlightSmall",600)
    f.count=label(f,"",20,-515,"GameFontHighlightSmall",400)
    button(f,L("Done"),540,-508,86,function() f:Hide() end)
    f.search:SetScript("OnTextChanged",function() f.offset=0; B:UpdateConsumablePicker() end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:RegisterEvent("BAG_UPDATE_DELAYED"); f:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    f:SetScript("OnEvent",function(_,event,itemID)
      if event=="PLAYER_REGEN_DISABLED" then f:Hide()
      elseif f:IsShown() then B:InvalidateConsumables(event=="ITEM_DATA_LOAD_RESULT" and itemID or nil); B:UpdateConsumablePicker() end
    end)
    if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapItemPicker") end
  end
  f:ClearAllPoints(); f:SetPoint("CENTER",self.options,"CENTER")
  f.family=family; f.offset=0; f.bags:SetChecked(true); f.search:SetText("")
  self:UpdateConsumablePicker(); f:Show()
end

function B:UpdateConsumablePicker()
  local f=self.itemPicker
  if not f or not f.family or A.Combat() then return end
  local family=f.family; local list={}; local query=(f.search:GetText() or ""):lower()
  local selected=self:ConsumableChoiceID(family)
  for _,item in ipairs(family.items or {}) do
    local count=self:ConsumableCount(item.id)
    if not f.bags:GetChecked() or count>0 then
      local info=self.ConsumableItemInfo and self:ConsumableItemInfo(item.id,item)
      local name=(info and info.name) or item.name
      if query=="" or name:lower():find(query,1,true) or item.name:lower():find(query,1,true) or tostring(item.id):find(query,1,true) then
        list[#list+1]={id=item.id,name=name,count=count,note=item.note,icon=item.icon}
      end
    end
  end
  table.sort(list,function(a,b)
    if (a.count>0)~=(b.count>0) then return a.count>0 end
    if a.name==b.name then return a.id<b.id end
    return a.name<b.name
  end)
  f.maxOffset=math.max(0,#list-8); f.offset=math.max(0,math.min(f.offset or 0,f.maxOffset))
  f.scroll.silent=true; f.scroll:SetMinMaxValues(0,math.max(1,f.maxOffset)); f.scroll:SetValue(f.offset); f.scroll.silent=false
  f.scroll:SetShown(f.maxOffset>0); f.empty:SetShown(#list==0)
  f.title:SetText(L("Choose %s",L(family.name)))
  f.auto:SetShown(not family.explicitChoice)
  f.auto:SetText((not selected and "(o) " or "( ) ")..L("Auto - first usable supported item"))
  for i,row in ipairs(f.rows) do
    local item=list[f.offset+i]
    if item then
      row.itemID=item.id; row.mark:SetText(selected==item.id and "(o)" or "( )")
      local info=self.ConsumableItemInfo and self:ConsumableItemInfo(item.id,item)
      row.name:SetText((info and info.name) or item.name); row.stock:SetText(item.count>0 and ("|cff88dd88"..item.count.."|r") or ("|cffffc466"..L("Out of stock").."|r"))
      local info=self.ConsumableItemInfo and self:ConsumableItemInfo(item.id,item)
      row.icon:SetTexture((info and info.texture) or item.icon or 134400)
      row:SetBackdropColor(selected==item.id and 0.16 or 0.065,selected==item.id and 0.15 or 0.085,selected==item.id and 0.09 or 0.10,1)
      addHelp(row,item.name,item.note or "Supported item; availability is checked again before use."); row:Show()
    else row.itemID=nil; row:Hide() end
  end
  local choice=consumableChoiceLabel(family)
  f.summary:SetText(L("Selected: %s",choice)..(selected and ("  -  "..L("%d in bags",self:ConsumableCount(selected))) or ""))
  local note=family.protectPresent and L("One elixir choice. Existing elixir buffs are preserved until expiry.") or L("One choice at a time. Your selection stays saved when out of stock.")
  for _,item in ipairs(family.items or {}) do if item.id==selected and item.note then note=note.."\n"..item.note; break end end
  f.hint:SetText(note)
  f.count:SetText(L("%d matching items",#list)..(f.maxOffset>0 and (" - "..L("scroll for more")) or ""))
end

function B:Options()
  if A.Combat() then return end
  local f=self.options
  if not f then
    f=CreateFrame("Frame","BuffTapOptions",UIParent,"BackdropTemplate"); self.options=f
    f:SetSize(OPTIONS_WIDTH,OPTIONS_HEIGHT); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetToplevel(true); f:SetClampedToScreen(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=14,insets={left=3,right=3,top=3,bottom=3}})
    f:SetBackdropColor(0.035,0.035,0.035,1); f:SetBackdropBorderColor(0.60,0.48,0.25,1)
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapOptions") end

    -- Share the actual banner artwork with onboarding.
    f.banner=B:AddMiniBanner(f,OPTIONS_WIDTH)
    f.versionText=label(f,"v"..B.version,550,-22,"GameFontDisableSmall",70)
    f.versionText:SetJustifyH("RIGHT")
    f.closeButton=button(f,L("Close"),636,-16,100,function() f:Hide() end)
    -- Keep explicit header artwork for Forever clients whose template leaves
    -- this control without visible button textures.
    f.closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    f.closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    f.closeButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
    for _,texture in ipairs({f.closeButton:GetNormalTexture(),f.closeButton:GetPushedTexture(),f.closeButton:GetDisabledTexture()}) do
      if texture then texture:SetTexCoord(0,0.625,0,0.6875) end
    end
    f.closeButton:SetSize(100,28)
    f.statusText=label(f,"",200,-144,"GameFontHighlightSmall",536); f.statusText:SetWordWrap(false); f.statusText:SetJustifyH("RIGHT")
    f.saveHint=label(f,L("Checkboxes, lists and sliders save immediately. Numeric fields: Enter to save; Escape to cancel."),18,-848,"GameFontDisableSmall",706)
    f.enable=check(f,L("Enable BuffTap"),24,-138,function(c) setAndRefresh("enabled",c:GetChecked()==true) end)
    line(f,-162)

    f.tabs={}; f.pages={}
    local names=TAB_NAMES
    local function setTab(index)
      f.activeTab=index
      if f.activeSelector then f.activeSelector:Hide() end
      if f.resetConfirm then f.resetConfirm:Hide() end
      if B.appearancePreview then B.appearancePreview:Hide() end
      if f.blessingMenu then f.blessingMenu:Hide() end
      for i,p in ipairs(f.pages) do p:SetShown(i==index) end
      for i,t in ipairs(f.tabs) do
        if i==index then t:LockHighlight() else t:UnlockHighlight() end
      end
    end
    f.selectTab=setTab
    local tabX=24
    for i,name in ipairs(names) do
      local idx=i
      local width=TAB_WIDTHS[i]
      local t=flatButton(f,name,tabX,-166,width,function() setTab(idx) end)
      t:SetSize(width,30); f.tabs[i]=t
      tabX=tabX+width+6
    end

    -- BUFFS PAGE
    local buffs=panel(f); f.pages[TAB.Buffs]=buffs
    label(buffs,L("Buffs"),18,-16,"GameFontNormalLarge")
    label(buffs,L("Use arrows to reorder. Buffs at the top are checked first."),18,-42,"GameFontDisableSmall",650)
    label(buffs,L("Rebuff"),334,-66,"GameFontDisableSmall",70)
    label(buffs,L("Priority"),590,-66,"GameFontDisableSmall",70)
    local scroll=CreateFrame("ScrollFrame",nil,buffs,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",14,-88); scroll:SetPoint("BOTTOMRIGHT",-34,126)
    local child=CreateFrame("Frame",nil,scroll); child:SetSize(660,1); scroll:SetScrollChild(child); f.buffChild=child; f.buffRows={}

    f.emptyBuffs=label(child,"No supported aura buffs for this class.",8,-12,"GameFontDisableSmall",610)
    local weapons=panel(f); f.pages[TAB.Weapons]=weapons
    card(weapons,12,-98,698,110); f.coatingCard=card(weapons,12,-220,698,120); f.weaponTimingCard=card(weapons,12,-358,698,110)
    f.weaponTitle=label(weapons,L("Weapon buffs"),18,-16,"GameFontNormalLarge")
    f.weaponHint=label(weapons,L("Maintain a preferred buff on each weapon using your normal BuffTap binding."),18,-42,"GameFontDisableSmall",660)
    f.weaponRetry=button(weapons,L("Retry reminders"),528,-16,154,function() B:RetryConsumableReminders(); B:Options() end)
    addHelp(f.weaponRetry,L("Retry reminders"),L("Restarts item loading and paused consumable reminders. Changed item effects remain blocked."))
    f.weaponEnable=check(weapons,L("Enable weapon reminders"),18,-72,function(c) setAndRefresh("weaponReminder",c:GetChecked()==true); B:Options() end)
    f.weaponApply=selector(weapons,"",180,-72,502,function() return {{key=false,name="Remind only"},{key=true,name="Remind and apply"}} end,function(value) setAndRefresh("weaponApply",value) end)
    addHelp(f.weaponApply,"Weapon mode","Remind only shows missing weapon buffs without preparing an application. Remind and apply prepares your selected spell or item for your next scroll or click, out of combat. Every application still requires your input.")
    f.weaponSectionHeading=label(weapons,L("Poisons / class imbues"),18,-100,"GameFontNormalSmall")
    f.weaponMain=check(weapons,L("Main hand"),18,-116,function(c) setAndRefresh("weaponMainHand",c:GetChecked()==true); B:Options() end)
    f.weaponOff=check(weapons,L("Off hand"),18,-164,function(c) setAndRefresh("weaponOffHand",c:GetChecked()==true); B:Options() end)
    f.weaponPickers={}
    for i,hand in ipairs({"main","off"}) do
      local key=hand
      local pick=flatButton(weapons,L("Choose preferred buff"),180,-116-(i-1)*48,502,function(control)
        if A.Combat() then return end
        for _,other in pairs(f.weaponPickers) do if other~=control then other.menu:Hide() end end
        for _,other in pairs(f.coatingPickers or {}) do other.menu:Hide() end
        local menu=control.menu; menu:SetShown(not menu:IsShown())
      end)
      selectorArrow(pick)
      pick.icon=pick:CreateTexture(nil,"ARTWORK"); pick.icon:SetSize(22,22); pick.icon:SetPoint("LEFT",4,0)
      local menu=CreateFrame("Frame",nil,weapons,"BackdropTemplate"); pick.menu=menu
      menu:SetSize(502,242); menu:SetPoint("TOPLEFT",pick,"BOTTOMLEFT",0,-2); menu:SetFrameStrata("TOOLTIP")
      menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); menu:SetBackdropColor(0.06,0.06,0.06,1); menu:Hide(); menu.rows={}
      local scroll=CreateFrame("ScrollFrame",nil,menu,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",4,-4); scroll:SetPoint("BOTTOMRIGHT",-28,4)
      local child=CreateFrame("Frame",nil,scroll); child:SetSize(466,1); scroll:SetScrollChild(child); menu.child=child
      f.weaponPickers[key]=pick
    end
    f.coatingHeading=label(weapons,L("Oils and stones"),18,-224,"GameFontNormal")
    f.coatingPickers={}; f.coatingHandLabels={}
    for i,hand in ipairs({"main","off"}) do
      local handKey=hand
      f.coatingHandLabels[hand]=label(weapons,L(i==1 and "Main hand" or "Off hand"),18,-256-(i-1)*48,"GameFontHighlightSmall",130)
      local pick=flatButton(weapons,"None",180,-250-(i-1)*48,502,function(control)
        if A.Combat() then return end
        for _,other in pairs(f.weaponPickers) do other.menu:Hide() end
        for _,other in pairs(f.coatingPickers) do if other~=control then other.menu:Hide() end end
        control.menu:SetShown(not control.menu:IsShown())
      end)
      selectorArrow(pick)
      pick.icon=pick:CreateTexture(nil,"ARTWORK"); pick.icon:SetSize(22,22); pick.icon:SetPoint("LEFT",4,0)
      local menu=CreateFrame("Frame",nil,weapons,"BackdropTemplate"); pick.menu=menu
      menu:SetSize(502,242); menu:SetPoint("TOPLEFT",pick,"BOTTOMLEFT",0,-2); menu:SetFrameStrata("TOOLTIP")
      menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); menu:SetBackdropColor(.06,.06,.06,1)
      local scroll=CreateFrame("ScrollFrame",nil,menu,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",4,-4); scroll:SetPoint("BOTTOMRIGHT",-28,4)
      local child=CreateFrame("Frame",nil,scroll); child:SetSize(466,1); scroll:SetScrollChild(child); menu.child=child; menu.rows={}; menu:Hide()
      f.coatingPickers[handKey]=pick
    end
    f.weaponTimingLabel=label(weapons,L("Refresh before expiry"),18,-368,"GameFontNormal")
    f.weaponTiming=compactSlider(weapons,0,300,15,270,formatSeconds,function(v) setAndRefresh("weaponSeconds",v) end)
    f.weaponTiming:SetPoint("TOPLEFT",220,-368)
    f.weaponReplace=check(weapons,"Replace a different buff with my preference",18,-412,function(c) setAndRefresh("weaponReplace",c:GetChecked()==true) end)
    addHelp(f.weaponReplace,"Replacing an existing weapon buff","Off by default. Enable only if you want your preferred buff to replace another recognized buff. Unknown coating data always uses a manual fallback.")
    f.weaponPoisonHint=label(weapons,"Poison ranks: highest carried usable rank. Preferences stay saved when out of stock.",18,-486,"GameFontDisableSmall",660)
    f.weaponHandsHint=label(weapons,"Oils and stones use a separate temporary-enchant slot. Only compatible melee weapons are eligible; shields, held items, ranged weapons and fishing poles are excluded.",18,-520,"GameFontDisableSmall",660)
    f.weaponModeHint=label(weapons,"",18,-552,"GameFontDisableSmall",660)
    f.weaponStatus=label(weapons,"",18,-578,"GameFontHighlightSmall",660)
    f.weaponUnavailable=label(weapons,"Class imbues are available to Rogues, Shamans and Mages.",18,-72,"GameFontDisableSmall",660)
    local timingLabel=buffs:CreateFontString(nil,"OVERLAY","GameFontNormal")
    timingLabel:SetPoint("BOTTOMLEFT",18,88); timingLabel:SetText(L("Default rebuff threshold"))
    local timingHint=buffs:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    timingHint:SetPoint("LEFT",timingLabel,"RIGHT",12,0); timingHint:SetText(L("Used until a buff is customized."))
    f.rebuffSlider=rebuffSlider(buffs); f.rebuffSlider:SetPoint("BOTTOMLEFT",18,54)
    local resetBuffs=button(buffs,L("Reset buffs"),0,0,100,function()
      if not A.Combat() then B.db.buffs={}; B.db.priorities={}; B.db.buffSeconds={}; B:Refresh(); B:Options() end
    end)
    resetBuffs:ClearAllPoints(); resetBuffs:SetPoint("BOTTOMRIGHT",-18,14)

    -- GROUPS PAGE
    local groupPage=panel(f); f.pages[TAB.Groups]=groupPage
    local groups=CreateFrame("Frame",nil,groupPage); groups:SetAllPoints(); f.legacyGroups=groups
    self:BuildBlessingOptions(groupPage)
    f.backBlessings=button(groups,"Blessing assignments",490,-16,200,function() f.blessingLegacy=false; B:Options() end)
    label(groups,L("Party & raid buffing"),18,-16,"GameFontNormalLarge")
    label(groups,L("Manage shared settings, then customize each buff below. Party members use G1."),18,-38,"GameFontDisableSmall",680)
    f.groupEnable=check(groups,L("Enable party / raid"),18,-58,function(s) setAndRefresh("group",s:GetChecked()==true); B:Options() end)
    f.smartGroup=check(groups,L("Use group spells automatically"),290,-58,function(s) setAndRefresh("smartGroup",s:GetChecked()==true); B:Options() end)
    local shared=CreateFrame("Frame",nil,groups); shared:SetPoint("TOPLEFT",0,-112); shared:SetSize(704,80); shared:Show()
    f.sharedGroups=shared
    card(groups,12,-86,698,106)
    label(groups,L("Shared group settings"),18,-92,"GameFontNormal")
    line(groups,-204)
    f.perBuffHeading=label(groups,L("Per-buff customization"),18,-218,"GameFontNormalLarge")
    label(groups,L("Select a buff below to customize its party/raid groups, recipient classes and group-spell threshold."),18,-242,"GameFontDisableSmall",686)
    label(groups,L("These filters apply only to party/raid buffing. Personal and open-world target buffs stay separate."),18,-596,"GameFontDisableSmall",686)
    label(shared,L("All buffs"),18,-10,"GameFontNormal")
    f.groupChecks={}; f.groupMixed={}
    for i=1,8 do
      local idx=i
      local c=check(shared,"G"..i,108+(i-1)*68,-5,function(s)
        if A.Combat() then return end
        B:SetRaidGroupColumn(idx,s:GetChecked()==true)
        B:RequestRefresh("raid group master",0)
        B:Options()
      end)
      local dash=c:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      dash:SetPoint("CENTER",c,"CENTER",0,1); dash:SetText("—"); dash:SetTextColor(1,0.82,0.1); dash:Hide(); c.mixedDash=dash
      addHelp(c,"Raid Group "..i,"Checked or unchecked applies to every buff. A gold dash means this group has mixed per-buff assignments.")
      f.groupChecks[i]=c
    end
    label(shared,L("Group threshold"),18,-48,"GameFontHighlight",110)
    f.groupNeedSlider=compactSlider(shared,2,5,1,150,function(v) return tostring(v).."+" end,function(_,v)
      B.db.groupNeed=v; B:NormalizeGroupNeeds(); B:InitDB(); B:RequestRefresh("group threshold default",0.08)
    end)
    f.groupNeedSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
    f.groupNeedSlider:SetPoint("TOPLEFT",128,-45)
    f.blessingNeedLabel=label(shared,L("Greater Blessings"),362,-48,"GameFontHighlight",132)
    f.blessingNeedSlider=compactSlider(shared,2,5,1,120,function(v) return tostring(v).."+" end,function(_,v)
      B.db.blessingNeed=v; B:NormalizeGroupNeeds(); B:InitDB(); B:RequestRefresh("blessing threshold default",0.08)
    end)
    f.blessingNeedSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
    f.blessingNeedSlider:SetPoint("TOPLEFT",492,-45)
    card(groups,12,-270,194,300)
    label(groups,L("Select a buff"),18,-274,"GameFontNormal")
    local listScroll=CreateFrame("ScrollFrame",nil,groups,"UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT",18,-298); listScroll:SetSize(178,274)
    f.assignScroll=listScroll
    f.assignList=CreateFrame("Frame",nil,listScroll); f.assignList:SetSize(174,1); listScroll:SetScrollChild(f.assignList)
    f.assignButtons={}
    local assignChild=CreateFrame("Frame",nil,groups); assignChild:SetPoint("TOPLEFT",230,-270); assignChild:SetSize(474,296)
    f.assignChild=assignChild; f.assignRows={}
    f.assignEmpty=label(assignChild,"No party / raid buffs available for this class.",8,-12,"GameFontHighlight",440)

    -- FRIENDLY TARGET PAGE
    local target=panel(f); f.pages[TAB.Target]=target
    label(target,L("Friendly target buffing"),18,-16,"GameFontNormalLarge")
    label(target,"Click a friendly player and BuffTap can offer selected single-target buffs before returning to your normal queue.",18,-42,"GameFontDisableSmall",680)
    f.friendlyTarget=check(target,L("Enable friendly target buffing"),18,-76,function(s) setAndRefresh("friendlyTarget",s:GetChecked()==true); B:Options() end)
    addHelp(f.friendlyTarget,L("Friendly target buffing"),"Only the player you explicitly target is inspected. No nearby-player or nameplate scanning is performed. Target mode uses single-target versions. Grouped Paladin targets follow enabled blessing assignments; ungrouped targets use their independent target settings.")
    card(target,12,-108,698,84)
    label(target,"Default target refresh",18,-116,"GameFontNormal")
    label(target,"Useful for passersby: a long buff can be refreshed much earlier here without changing party/raid timing.",18,-138,"GameFontDisableSmall",680)
    f.targetDefaultSlider=compactSlider(target,30,1800,30,300,formatSeconds,function(_,value)
      B.db.targetSeconds=value; B:InvalidateAura("target"); B:RequestRefresh("target refresh default",0.08)
    end)
    f.targetDefaultSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
    f.targetDefaultSlider:SetPoint("TOPLEFT",18,-164)
    addHelp(f.targetDefaultSlider,"Target refresh timing","Target mode may refresh much earlier than normal party/raid timing. BuffTap still caps the effective threshold at half of the aura's full duration, so a one-hour buff can be refreshed at 30 minutes but not earlier.")
    f.targetBlessingPanel=CreateFrame("Frame",nil,target)
    f.targetBlessingPanel:SetPoint("TOPLEFT",12,-204); f.targetBlessingPanel:SetSize(698,188)
    f.targetClassAware=check(f.targetBlessingPanel,"Class-aware target blessings",6,0,function(c) setAndRefresh("targetClassBlessings",c:GetChecked()==true); B:Options() end)
    addHelp(f.targetClassAware,"Class-aware target blessings","Automatic follows enabled priorities and class suitability. Class choices apply to friendly targets; group assignments take precedence for group members. Disable to use unrestricted target priorities.")
    f.targetBlessingFallback=check(f.targetBlessingPanel,"Allow fallback to the next blessing",6,-128,function(c) setAndRefresh("targetBlessingFallback",c:GetChecked()==true); B:Options() end)
    addHelp(f.targetBlessingFallback,"Target blessing priorities","Checking a blessing enables it for that class list. All class choices use the default target refresh above. Automatic follows Buffs priorities and enabled spells. Uncheck fallback to offer only the first eligible choice. Your own blessing is maintained; unknown ownership stops fallback. Group assignments remain authoritative.")
    f.targetBlessingPicks={}
    for i,class in ipairs(B.RecipientClasses) do
      local token=class; local x=((i-1)%3)*230; local y=-32-math.floor((i-1)/3)*32
      label(f.targetBlessingPanel,(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token:sub(1,1)..token:sub(2):lower(),x+6,y-7,"GameFontHighlightSmall",80)
      f.targetBlessingPicks[i]=blessingPick(f.targetBlessingPanel,x+89,y,136,function() return B.db.targetBlessingClasses[token] end,function(key) B.db.targetBlessingClasses[token]=key end,"target")
      local pick=f.targetBlessingPicks[i]; pick.priorityClass=token; pick.priorityTarget=true
      pick.getOrder=function() return B.db.targetBlessingPriorities[token] end
      pick.setOrder=function(order) B.db.targetBlessingPriorities[token]=order end
    end
    f.targetBlessingInstruction=label(f.targetBlessingPanel,"",6,-160,"GameFontDisableSmall",686)
    f.targetHeaders=CreateFrame("Frame",nil,target); f.targetHeaders:SetPoint("TOPLEFT",0,-204); f.targetHeaders:SetSize(698,78)
    local header=f.targetHeaders
    line(header,0)
    label(header,"Spell availability & refresh timing",18,-18,"GameFontNormal")
    header:EnableMouse(true)
    addHelp(header,"Spell availability & refresh timing","Allow controls which spells unrestricted friendly-target mode may offer. Refresh timing applies to that spell across recipient classes. Custom priorities choose the order; this section does not add another blessing assignment. Leaving custom timing off uses the default target refresh above.")
    label(header,"Choose allowed spells and optional refresh overrides for friendly targets.",18,-34,"GameFontDisableSmall",680)
    label(header,L("Allow"),18,-56,"GameFontDisableSmall",48)
    label(header,L("Buff"),82,-56,"GameFontDisableSmall",160)
    label(header,L("Override timing"),276,-56,"GameFontDisableSmall",100)
    label(header,L("Refresh when remaining"),402,-56,"GameFontDisableSmall",180)
    local targetScroll=CreateFrame("ScrollFrame",nil,target,"UIPanelScrollFrameTemplate")
    targetScroll:SetPoint("TOPLEFT",14,-282); targetScroll:SetPoint("BOTTOMRIGHT",-34,54)
    local targetChild=CreateFrame("Frame",nil,targetScroll); targetChild:SetSize(660,1); targetScroll:SetScrollChild(targetChild)
    f.targetChild=targetChild; f.targetRows={}; f.targetScroll=targetScroll
    local resetTarget=button(target,L("Reset target settings"),0,0,132,function()
      if not A.Combat() then
        B.db.friendlyTarget=false; B.db.targetSeconds=300; B.db.targetBuffs={}; B.db.targetBuffSeconds={}; B.db.targetClassBlessings=true; B.db.targetBlessingFallback=true; B.db.targetBlessingClasses={}; B.db.targetBlessingPriorities={}
        B:InitDB(); B:InvalidateAura("target"); B:RequestRefresh("reset target settings",0); B:Options()
      end
    end)
    resetTarget:ClearAllPoints(); resetTarget:SetPoint("BOTTOMRIGHT",-18,14)

    -- CONSUMABLES PAGE
    local consumePanel=panel(f); f.pages[TAB.Consumables]=consumePanel
    local consume=CreateFrame("Frame",nil,consumePanel); consume:SetPoint("TOPLEFT",0,-36); consume:SetPoint("BOTTOMRIGHT",0,0)
    f.consumableBody=consume
    self:BuildSupplyOptions(consumePanel)
    local buffView=flatButton(consumePanel,"Buff items",18,-8,104,function() f.selectConsumableView(false) end)
    local supplyView=flatButton(consumePanel,L("Supplies"),132,-8,104,function() f.selectConsumableView(true) end)
    f.selectConsumableView=function(supplies)
      f.consumableBody:SetShown(not supplies); f.supplyBody:SetShown(supplies)
      if supplies then buffView:UnlockHighlight(); supplyView:LockHighlight(); B:UpdateSupplyOptions()
      else supplyView:UnlockHighlight(); buffView:LockHighlight() end
      if B.itemPicker then B.itemPicker:Hide() end
    end
    f.selectConsumableView(false)
    label(consume,L("Consumables"),18,-16,"GameFontNormalLarge")
    label(consume,"Choose the food, flask and elixir buffs you want to maintain.",18,-42,"GameFontDisableSmall",680)
    f.consumablesEnable=check(consume,"Enable consumable reminders",18,-72,function(c)
      if not A.Combat() then B.db.consumablesEnabled=c:GetChecked()==true; if B.InvalidateConsumables then B:InvalidateConsumables() end; B:RequestRefresh("consumables master",0); B:Options() end
    end)
    f.consumeBuild=label(consume,"Data: —",410,-77,"GameFontDisableSmall",260)
    line(consume,-108)
    f.consumableRows={}
    for index,family in ipairs(B.ConsumableFamilies or {}) do
      local row=CreateFrame("Frame",nil,consume,"BackdropTemplate")
      row:SetSize(686,76); row:SetPoint("TOPLEFT",10,-116-(index-1)*80)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.065,0.085,0.10,0.95)
      row.family=family
      row.enable=check(row,"",8,-8,function(c)
        local fam=c:GetParent().family
        if fam and not A.Combat() then
          B.db.consumableFamilies[fam.key]=c:GetChecked()==true
          if B.InvalidateConsumables then B:InvalidateConsumables() end
          B:RequestRefresh("consumable family",0); B:Options()
        end
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(30,30); row.icon:SetPoint("TOPLEFT",42,-8); row.icon:SetTexture(134400)
      row.name=label(row,family.name,82,-8,"GameFontHighlight",210)
      row.choice=label(row,"Auto",82,-29,"GameFontHighlightSmall",420)
      row.prev=button(row,L("Choose"),584,-8,86,function(btn) B:ChooseConsumable(btn:GetParent().family,btn) end)
      row.inventory=label(row,"",450,-11,"GameFontHighlightSmall",120)
      label(row,family.protectPresent and "Preserve active elixirs; remind after expiry" or "Rebuff at",42,-52,"GameFontDisableSmall",family.protectPresent and 390 or 62)
      addHelp(row.enable,"Maintain this consumable buff","Enable this family to receive reminders for your selected food, flask or elixir. Enable consumable reminders above too. Preferences remain saved when supplies run out.")
      row.threshold=compactSlider(row,30,1800,30,230,formatSeconds,function(slider,value)
        local fam=slider:GetParent().family
        if fam then B:SetConsumableThreshold(fam,value); B:InvalidateAura("player"); B:RequestRefresh("consumable threshold",0.08) end
      end)
      row.threshold:SetPoint("TOPLEFT",108,-54)
      f.consumableRows[index]=row
    end
    local campY=-116-(#(B.ConsumableFamilies or {}))*80-4
    line(consume,campY)
    label(consume,"Camp Benefits",18,campY-22,"GameFontNormal")
    f.campStatus=label(consume,"Status: —",132,campY-22,"GameFontHighlightSmall",260)
    label(consume,"Recognition only in this build; BuffTap will not guess individual camp effects or interact with camp objects.",18,campY-44,"GameFontDisableSmall",660)

    f.consumeRetry=button(consume,L("Retry reminders"),18,-450,154,function() B:RetryConsumableReminders(); B:Options() end)
    addHelp(f.consumeRetry,L("Retry reminders"),L("Restarts item loading and paused consumable reminders. Changed item effects remain blocked."))
    f.consumePauseStatus=label(consume,"",186,-455,"GameFontHighlightSmall",496)

    -- APPEARANCE PAGE
    local app=panel(f); f.pages[TAB.Appearance]=app
    card(app,12,-10,698,88); card(app,12,-118,698,256); card(app,12,-390,698,128); card(app,12,-528,698,78)
    label(app,L("Binding"),18,-16,"GameFontNormalLarge")
    f.bindingText=label(app,"Current: —",18,-46,"GameFontHighlight",280)
    button(app,L("Set binding"),310,-42,116,function() B:CaptureBinding() end)
    button(app,L("Clear"),436,-42,82,function() if not A.Combat() then B.db.keys={}; B.appearance=nil; B:RequestRefresh("clear binding",0); B:Options() end end)
    label(app,"The override binding is active only while BuffTap has a valid buff action ready.",18,-73,"GameFontDisableSmall",650)
    line(app,-105)
    label(app,L("Reminder appearance"),18,-126,"GameFontNormalLarge")
    label(app,L("Size"),18,-160,"GameFontHighlight"); f.sizeEdit=editbox(app,62,-156,58,true); label(app,"px",126,-160,"GameFontDisableSmall")
    label(app,L("Opacity"),176,-160,"GameFontHighlight"); f.opacityEdit=editbox(app,238,-156,58,true); label(app,"%",300,-160,"GameFontDisableSmall")
    label(app,"X",326,-160,"GameFontHighlight"); f.xEdit=editbox(app,344,-156,64,false)
    label(app,"Y",430,-160,"GameFontHighlight"); f.yEdit=editbox(app,448,-156,64,false)
    button(app,L("Apply"),540,-156,72,function()
      if A.Combat() then return end
      local size,opacity,x,y=tonumber(f.sizeEdit:GetText()),tonumber(f.opacityEdit:GetText()),tonumber(f.xEdit:GetText()),tonumber(f.yEdit:GetText())
      if size then B.db.size=size end; if opacity then B.db.opacity=math.max(0,math.min(100,opacity))/100 end; if x then B.db.x=x end; if y then B.db.y=y end
      B:InitDB(); B.appearance=nil; B:RequestRefresh("appearance",0); B:Options()
    end)
    f.soundCheck=check(app,L("Enable reminder sound"),18,-488,function(s) setAndRefresh("sound",s:GetChecked()==true) end)
    f.glowCheck=check(app,L("Glow"),18,-204,function(s) setAndRefresh("glow",s:GetChecked()==true) end)
    f.pulseCheck=check(app,L("Pulse"),170,-204,function(s) setAndRefresh("pulse",s:GetChecked()==true) end)
    f.buffNameCheck=check(app,L("Show buff name"),18,-238,function(s) setAndRefresh("showBuffName",s:GetChecked()==true) end)
    f.targetNameCheck=check(app,L("Show buff recipient"),326,-238,function(s) setAndRefresh("showTargetName",s:GetChecked()==true) end)
    addHelp(f.targetNameCheck,"Buff recipient","Shows the name of whoever BuffTap is about to buff, including you when the current action is a self buff.")
    f.timerCheck=check(app,L("Remaining time"),18,-272,function(s) setAndRefresh("showTimer",s:GetChecked()==true) end)
    f.groupBadgeCheck=check(app,L("Group count"),326,-272,function(s) setAndRefresh("showGroupBadge",s:GetChecked()==true) end)
    addHelp(f.timerCheck,L("Remaining time"),"Shows a small countdown only when the selected buff is already inside its rebuff window.")
    addHelp(f.groupBadgeCheck,L("Group count"),"Shows how many players need the buff when BuffTap selects a group-version spell.")
    button(app,L("Move icon"),18,-318,108,function() B:MoveAnchor() end)
    button(app,L("Center"),136,-318,90,function() if not A.Combat() then B.db.x=0; B.db.y=-180; B.appearance=nil; B:RequestRefresh("center icon",0); B:Options() end end)
    f.resetLookButton=button(app,L("Reset look"),236,-318,100,function()
      if not A.Combat() then B.db.size=64; B.db.opacity=1; B.db.x=0; B.db.y=-180; B.db.glow=true; B.db.pulse=false; B.db.showBuffName=false; B.db.showTargetName=true; B.db.showTimer=false; B.db.showGroupBadge=true; B.db.labelFont="default"; B.db.labelColor="default"; B.appearance=nil; B:RequestRefresh("reset look",0); B:Options() end
    end)
    label(app,L("Enter saves fields. Move here or in Blizzard Edit Mode."),18,-354,"GameFontDisableSmall",380)
    label(app,L("Label font"),350,-206,"GameFontHighlightSmall")
    f.fontButton=selector(app,"",440,-200,242,function() return B:ReminderFonts() end,function(value) B.db.labelFont=value; B.appearance=nil; B:RequestRefresh("label font",0) end)
    f.colorButton=selector(app,"",522,-318,160,function() return B:ReminderColors() end,function(value) B.db.labelColor=value; B.appearance=nil; B:RequestRefresh("label color",0) end)
    addHelp(f.fontButton,L("Label font"),L("Choose a built-in game font for reminder labels. Settings text stays unchanged."))
    addHelp(f.colorButton,L("Label color"),L("Choose the color of reminder labels. Default keeps the group count gold."))
    button(app,L("How to buff"),536,-350,146,function() B:ShowWelcome(true) end)
    button(app,L("Preview appearance"),348,-318,150,function() B:PreviewAppearance() end)
    line(app,-382)
    label(app,L("Sounds"),18,-392,"GameFontNormal")
    local function soundControl(kind,y)
      label(app,kind=="supply" and L("Supply sound") or L("Reminder sound"),18,y-5,"GameFontHighlightSmall",112)
      local key=kind=="supply" and "supplySound" or "reminderSound"
      local choice=selector(app,"",138,y,180,function() return B:SoundChoices() end,function(value) B.db[key]=value end,true)
      button(app,L("Preview"),326,y,90,function() if not B:PlayAlert(kind,true) then B.Print(L("Sound preview unavailable.")) end end)
      addHelp(choice,L("Sound"),L("Open the list to choose a sound.").."\n"..L("Game sounds and installed SharedMedia sounds are available. Search or scroll the list; Preview ignores the alert toggle. Missing media uses the default sound without forgetting your choice."))
      return choice
    end
    f.reminderSoundButton=soundControl("reminder",-416)
    f.supplySoundButton=soundControl("supply",-450)
    label(app,L("Audio channel"),436,-420,"GameFontHighlightSmall",116)
    f.channelButton=selector(app,"",550,-416,132,function() return {{key="Master",name="Master"},{key="SFX",name="Sound effects"}} end,function(value) B.db.soundChannel=value end)
    addHelp(f.channelButton,L("Audio channel"),L("Choose a sound and preview it. Master follows master volume; Sound effects follows effects volume."))
    label(app,L("Minimum interval"),436,-454,"GameFontHighlightSmall",116)
    f.soundInterval=compactSlider(app,5,60,5,80,formatSeconds,function(_,value) setAndRefresh("soundInterval",value) end)
    f.soundInterval:SetPoint("TOPLEFT",550,-453)
    label(app,L("Quick access"),200,-538,"GameFontNormal")
    f.minimapCheck=check(app,L("Minimap button"),200,-564,function(s) B.db.minimap.hide=not s:GetChecked(); B:SyncBroker() end)
    f.brokerCheck=check(app,L("Broker display"),440,-564,function(s) B.db.brokerEnabled=s:GetChecked()==true; B:SyncBroker(); B:Options() end)
    addHelp(f.brokerCheck,L("Broker display"),L("Requires a broker bar addon. Shows the next reminder, not a total missing-buff count. Disable takes effect after reloading the UI."))
    f.resetAllButton=button(app,L("Reset all settings"),18,-540,156,function() f.resetConfirm:Show() end)
    f.resetConfirm=CreateFrame("Frame",nil,app,"BackdropTemplate"); f.resetConfirm:SetSize(686,76); f.resetConfirm:SetPoint("TOPLEFT",16,-528)
    f.resetConfirm:SetFrameLevel(app:GetFrameLevel()+10)
    f.resetConfirm:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f.resetConfirm:SetBackdropColor(0.08,0.04,0.04,1); f.resetConfirm:SetBackdropBorderColor(0.65,0.4,0.2,1)
    label(f.resetConfirm,L("Reset all settings? This removes your saved preferences and assignments."),10,-6,"GameFontHighlightSmall",660)
    button(f.resetConfirm,L("Cancel"),488,-40,90,function() f.resetConfirm:Hide() end)
    f.confirmResetButton=button(f.resetConfirm,L("Confirm reset"),340,-40,140,function()
      if not A.Combat() then f.resetConfirm:Hide(); BuffTapDB=nil; B.blessingPlayers=nil; B:InitDB(); B.helperDismissed={}; B.helperThankSeen=nil; B.bookDirty=true; B.resolveCache=nil; B.rankChoiceCache=nil; B.coverCache=nil; B:InvalidateRoster(); B:InvalidateAura(); B.appearance=nil; B:RequestRefresh("reset settings",0); B:Options() end
    end)
    f.resetConfirm:Hide()

    -- DIAGNOSTICS PAGE
    local diag=panel(f); f.pages[TAB.Diagnostics]=diag
    label(diag,L("Diagnostics & performance"),18,-16,"GameFontNormalLarge")
    f.diagVersion=label(diag,"",550,-20,"GameFontHighlightSmall",144)
    f.diagVersion:SetJustifyH("RIGHT")
    f.friendlyStatus=label(diag,"",18,-468,"GameFontHighlightSmall",670)
    button(diag,L("Check now"),18,-530,116,function() if not A.Combat() then B:Refresh(true); B:Options() end end)
    label(diag,"Core scanning is event-driven. Profiling is optional and lasts only for this game session.",18,-42,"GameFontDisableSmall",680)
    f.profileCheck=check(diag,L("Measure refresh cost"),18,-76,function(c)
      B.profileEnabled=c:GetChecked()==true; B.profileStats=nil
      if B.profileEnabled then B:ResetStats() else B.stats=nil end
      B:Options()
    end)
    addHelp(f.profileCheck,"Refresh profiler","Disabled by default. When enabled, BuffTap measures only its own refresh duration with debugprofilestop().")
    card(diag,12,-108,698,268)
    f.diagText=label(diag,"",18,-116,"GameFontHighlightSmall",680)
    button(diag,L("Refresh diagnostics"),18,-390,142,function()
      if not A.Combat() then f.discoveryScroll:Hide(); f.diagText:Show(); B:Refresh(true); B:Options() end
    end)
    button(diag,L("Print to chat"),170,-390,108,function() B:Status(true); B:Options() end)
    button(diag,L("Reset metrics"),288,-390,110,function()
      B.profileStats=nil; if B.profileEnabled then B:ResetStats() else B.stats=nil end; B:Options()
    end)

    local scroll=CreateFrame("ScrollFrame",nil,diag,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",18,-116); scroll:SetSize(654,258); scroll:Hide(); f.discoveryScroll=scroll
    local report=CreateFrame("EditBox",nil,scroll); report:SetMultiLine(true); report:SetAutoFocus(false)
    report:SetFontObject("GameFontHighlightSmall"); report:SetWidth(638); report:SetHeight(258)
    report:SetScript("OnEscapePressed",function(control) control:ClearFocus() end)
    scroll:SetScrollChild(report); f.discoveryReport=report
    button(diag,L("Unknown items"),410,-390,124,function() B:ShowDiscoveryReport() end)
    button(diag,L("Rescan bags"),546,-390,130,function()
      if A.Combat() then return end
      B:DiscoverConsumables(); B:ShowDiscoveryReport()
    end)
    label(diag,"Unknown items is a copyable report for improving item support, not a list of items BuffTap will use.",18,-430,"GameFontDisableSmall",672)
    self:BuildHelperPage(f)

    local function acceptEdit(e,key)
      e:SetScript("OnEnterPressed",function(s) local v=tonumber(s:GetText()); if v and not A.Combat() then if key=="opacity" then v=math.max(0,math.min(100,v))/100 end; setAndRefresh(key,v) end; s:ClearFocus(); B:Options() end)
      e:SetScript("OnEscapePressed",function(s) s:ClearFocus(); B:Options() end)
    end
    acceptEdit(f.sizeEdit,"size"); acceptEdit(f.opacityEdit,"opacity"); acceptEdit(f.xEdit,"x"); acceptEdit(f.yEdit,"y")

    f:SetScript("OnHide",function()
      if f.activeSelector then f.activeSelector:Hide() end
      if B.itemPicker then B.itemPicker:Hide() end
      if f.blessingMenu then f.blessingMenu:Hide() end
      if f.resetConfirm then f.resetConfirm:Hide() end
      if B.appearancePreview then B.appearancePreview:Hide() end
    end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:RegisterEvent("BAG_UPDATE_DELAYED"); f:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    f:SetScript("OnEvent",function(_,event,itemID)
      if event=="PLAYER_REGEN_DISABLED" then f:StopMovingOrSizing(); f:Hide()
      elseif f:IsShown() and not A.Combat() then
        B:InvalidateConsumables(event=="ITEM_DATA_LOAD_RESULT" and itemID or nil); B:Options()
      end
    end)
    setTab(1)
  end

  local width,height=UIParent:GetWidth(),UIParent:GetHeight()
  if A.Number(width) and A.Number(height) then f:SetScale(math.min(1,(width-32)/OPTIONS_WIDTH,(height-32)/OPTIONS_HEIGHT)) end
  self:UpdateHelperOptions()
  self:UpdateSupplyOptions()
  local paladin=A.Call(function() local _,token=UnitClass("player"); return token end)=="PALADIN"
  f.targetBlessingPanel:SetShown(paladin); f.targetClassAware:SetChecked(self.db.targetClassBlessings)
  f.targetBlessingFallback:SetChecked(self.db.targetBlessingFallback)
  for _,pick in ipairs(f.targetBlessingPicks) do pick:Update(); pick:SetAvailable(self.db.targetClassBlessings and self.db.friendlyTarget) end
  f.targetBlessingInstruction:SetText(L(not self.db.friendlyTarget and "Enable friendly target buffing to use these class choices." or not self.db.targetClassBlessings and "Enable class-aware target blessings to customize each class." or "Open a class to check and order blessings. All use the refresh above. Automatic uses enabled Buffs and their order, filtered for this class."))
  local simplePal=paladin and self.db.targetClassBlessings
  f.targetHeaders:SetShown(not simplePal); f.targetScroll:SetShown(not simplePal)
  f.targetHeaders:ClearAllPoints(); f.targetHeaders:SetPoint("TOPLEFT",0,paladin and -396 or -204)
  f.targetScroll:ClearAllPoints(); f.targetScroll:SetPoint("TOPLEFT",14,paladin and -474 or -282); f.targetScroll:SetPoint("BOTTOMRIGHT",-34,54)
  f.pauseResting:SetChecked(self.db.pauseResting)
  f.enable:SetChecked(self.db.enabled)
  f.versionText:SetText("v"..self.version)
  f.groupEnable:SetChecked(self.db.group); f.smartGroup:SetChecked(self.db.smartGroup); f.friendlyTarget:SetChecked(self.db.friendlyTarget)
  f.targetDefaultSlider.silent=true; f.targetDefaultSlider:SetValue(self.db.targetSeconds); f.targetDefaultSlider.valueText:SetText(formatSeconds(self.db.targetSeconds)); f.targetDefaultSlider.silent=false
  for i=1,8 do
    local state=self:GroupColumnState(i)
    local c=f.groupChecks[i]
    c:SetChecked(state=="on")
    if c.mixedDash then c.mixedDash:SetShown(state=="mixed") end
  end
  f.groupNeedSlider.silent=true; f.groupNeedSlider:SetValue(self.db.groupNeed); f.groupNeedSlider.valueText:SetText(tostring(self.db.groupNeed).."+"); f.groupNeedSlider.silent=false
  f.blessingNeedSlider.silent=true; f.blessingNeedSlider:SetValue(self.db.blessingNeed); f.blessingNeedSlider.valueText:SetText(tostring(self.db.blessingNeed).."+"); f.blessingNeedSlider.silent=false
  local smartAlpha=(self.db.group and self.db.smartGroup) and 1 or 0.45
  if self.db.group and self.db.smartGroup then f.groupNeedSlider:Enable(); f.blessingNeedSlider:Enable() else f.groupNeedSlider:Disable(); f.blessingNeedSlider:Disable() end
  f.groupNeedSlider:SetAlpha(smartAlpha); f.blessingNeedSlider:SetAlpha(smartAlpha)

  for _,r in ipairs(f.assignRows) do r:Hide() end
  for _,btn in ipairs(f.assignButtons) do btn:Hide() end
  local assignmentBuffs=groupAssignableBuffs()
  local found=false; for _,b in ipairs(assignmentBuffs) do if b.key==f.selectedAssignment then found=true end end
  if not found then f.selectedAssignment=assignmentBuffs[1] and assignmentBuffs[1].key end
  f.assignEmpty:SetShown(#assignmentBuffs==0)
  for rowIndex,b in ipairs(assignmentBuffs) do
    local row=f.assignRows[rowIndex]
    if not row then
      row=CreateFrame("Frame",nil,f.assignChild,"BackdropTemplate"); row:SetSize(474,296)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.065,0.085,0.10,0.95)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(32,32); row.icon:SetPoint("TOPLEFT",8,-4)
      row.name=label(row,"",48,-5,"GameFontNormalLarge",402)
      row.detail=label(row,"",48,-29,"GameFontDisableSmall",402)
      label(row,L("Raid groups"),8,-60,"GameFontNormal")
      row.checks={}
      for i=1,8 do
        local idx=i
        local c=check(row,tostring(i),8+(i-1)*54,-78,function(s)
          local parent=s:GetParent(); local def=parent.def
          if def and not A.Combat() then
            local map=B:EnsureBuffGroups(def); map[idx]=s:GetChecked()==true
            B:NormalizeBuffGroups(def); B:ReconcileRaidGroupColumn(idx)
            B:RequestRefresh("buff group assignment",0); B:Options()
          end
        end)
        c:SetSize(20,20); row.checks[i]=c
      end
      row.need=compactSlider(row,2,5,1,62,function(v) return tostring(v).."+" end,function(slider,value)
        local def=slider:GetParent().def
        if def then B:SetGroupNeed(def,value); B:RequestRefresh("group threshold",0) end
      end)
      row.need:SetPoint("TOPLEFT",165,-263)
      row.needLabel=label(row,"Group spell at",8,-263,"GameFontHighlightSmall",140)
      label(row,"Recipient classes",8,-116,"GameFontNormal")
      label(row,"Recipients must match group AND class. Party uses group 1.\nPersonal buffs and open-world targets ignore these filters.",8,-221,"GameFontDisableSmall",450)
      row.classes={}
      for i,class in ipairs(B.RecipientClasses) do
        local token=class
        local className=(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or (token:sub(1,1)..token:sub(2):lower())
          local c=check(row,className,8+((i-1)%3)*152,-138-math.floor((i-1)/3)*25,function(s)
          local def=row.def
          if not def or A.Combat() then return end
          local key=B:RootKey(def)
          B.db.buffClasses[key]=B.db.buffClasses[key] or {}
          B.db.buffClasses[key][token]=s:GetChecked()==true
          B:RequestRefresh("buff class assignment",0); B:Options()
        end)
        c:SetSize(20,20)
        addHelp(c,className,"Party/raid recipients must match both the selected group and class. Personal buffs and explicit friendly targets ignore these filters. Class does not identify the tank role.")
        row.classes[token]=c
      end
      row.resetClasses=button(row,L("Reset"),374,-258,80,function()
        if row.def and not A.Combat() then B.db.buffClasses[B:RootKey(row.def)]=nil; B:RequestRefresh("reset classes",0); B:Options() end
      end)
      row.allClasses=button(row,"All classes",280,-258,86,function()
        if not row.def or A.Combat() then return end
        local map={}; for _,class in ipairs(B.RecipientClasses) do map[class]=true end
        B.db.buffClasses[B:RootKey(row.def)]=map; B:RequestRefresh("all classes",0); B:Options()
      end)
      f.assignRows[rowIndex]=row
    end
    row.def=b; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,0); row:SetShown(f.selectedAssignment==b.key); row.name:SetText(spellLabel(b)); row.icon:SetTexture(buffIcon(b))
    local select=f.assignButtons[rowIndex]
    if not select then
      select=flatButton(f.assignList,"",0,-(rowIndex-1)*42,174,function(btn) f.selectedAssignment=btn.def.key; B:Options() end)
      select:SetHeight(38)
      select.icon=select:CreateTexture(nil,"ARTWORK"); select.icon:SetSize(24,24); select.icon:SetPoint("TOPLEFT",6,-7)
      select.title=label(select,"",36,-6,"GameFontHighlightSmall",132)
      f.assignButtons[rowIndex]=select
    end
    select.def=b; select.title:SetText(spellLabel(b)); select.icon:SetTexture(buffIcon(b)); select:Show()
    if f.selectedAssignment==b.key then select:LockHighlight() else select:UnlockHighlight() end
    local groupDef=b.groupKey and self:FindBuff(b.groupKey)
    row.detail:SetText(groupDef and (L("Group")..": "..spellLabel(groupDef)) or L("Single-target only"))
    for i=1,8 do row.checks[i]:SetChecked(self:GroupSelected(b,i)) end
    for class,c in pairs(row.classes) do c:SetChecked(self:GroupClassAllowed(b,class)) end
    if groupDef then
      row.needLabel:Show(); row.need:Show(); row.need.valueText:Show(); row.need.silent=true; row.need:SetValue(self:GroupNeed(groupDef)); row.need.valueText:SetText(tostring(self:GroupNeed(groupDef)).."+"); row.need.silent=false
      if self.db.group and self.db.smartGroup then row.need:Enable(); row.need:SetAlpha(1) else row.need:Disable(); row.need:SetAlpha(0.45) end
    else row.need:Hide(); row.need.valueText:Hide(); row.needLabel:Hide() end
  end
  f.assignList:SetHeight(math.max(1,#assignmentBuffs*42))
  f.assignScroll:SetHeight(math.min(252,math.max(42,#assignmentBuffs*42)))
  f.blessingNeedLabel:SetShown(paladin)
  f.blessingNeedSlider:SetShown(paladin)
  f.blessingNeedSlider.valueText:SetShown(paladin)
  self:UpdateBlessingOptions()

  for _,r in ipairs(f.targetRows) do r:Hide() end
  local targetBuffs=simplePal and {} or targetAssignableBuffs()
  for rowIndex,b in ipairs(targetBuffs) do
    local row=f.targetRows[rowIndex]
    if not row then
      row=CreateFrame("Frame",nil,f.targetChild,"BackdropTemplate"); row:SetSize(650,48)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.065,0.085,0.10,0.95)
      row.enable=check(row,"",8,-12,function(s)
        local def=s:GetParent().def
        if def and not A.Combat() then B.db.targetBuffs[def.key]=s:GetChecked()==true; B:InvalidateAura("target"); B:RequestRefresh("target buff toggle",0); B:Options() end
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(32,32); row.icon:SetPoint("TOPLEFT",42,-8)
      row.name=label(row,"",82,-6,"GameFontHighlightSmall",180)
      row.detail=label(row,"",82,-24,"GameFontDisableSmall",180)
      row.custom=check(row,"Override",270,-12,function(s)
        local def=s:GetParent().def
        if def and not A.Combat() then
          if s:GetChecked()==true then B.db.targetBuffSeconds[def.key]=B.db.targetSeconds else B.db.targetBuffSeconds[def.key]=nil end
          B:InvalidateAura("target"); B:RequestRefresh("target custom timing",0); B:Options()
        end
      end)
      addHelp(row.enable,"Allow on friendly targets","Offer this spell to friendly targets when it is also enabled on Buffs. This filter is separate from personal buffing.")
      addHelp(row.custom,"Override target refresh timing","Use a different refresh threshold for this spell. Leave unchecked to use the default target refresh above.")
      row.threshold=compactSlider(row,30,1800,30,150,formatSeconds,function(slider,value)
        local def=slider:GetParent().def
        if def and B.db.targetBuffSeconds[def.key]~=nil then
          B.db.targetBuffSeconds[def.key]=value; B:InvalidateAura("target"); B:RequestRefresh("target rebuff threshold",0.08)
        end
      end)
      row.threshold:SetPoint("TOPLEFT",402,-18)
      f.targetRows[rowIndex]=row
    end
    row.def=b; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(rowIndex-1)*52); row:Show()
    row.enable:SetChecked(self:TargetBuffEnabled(b)); row.icon:SetTexture(buffIcon(b)); row.name:SetText(spellLabel(b))
    row.detail:SetText(not learnedSpell(b) and unlearnedText() or self:Enabled(b) and L("Single-target spell") or L("Disabled on Buffs tab"))
    local custom=self.db.targetBuffSeconds[b.key]~=nil
    row.custom:SetChecked(custom)
    local seconds=self:TargetRebuffSeconds(b)
    row.threshold.silent=true; row.threshold:SetValue(seconds); row.threshold.valueText:SetText(formatSeconds(seconds)); row.threshold.silent=false
    if custom then row.threshold:Enable(); row.threshold:SetAlpha(1) else row.threshold:Disable(); row.threshold:SetAlpha(0.45) end
  end
  f.targetChild:SetHeight(math.max(1,#targetBuffs*52))

  if f.consumablesEnable then
    f.consumablesEnable:SetChecked(self.db.consumablesEnabled==true)
    f.consumeBuild:Hide()
    if self.RebuildConsumableCache then self:RebuildConsumableCache(false) end
    for index,family in ipairs(self.ConsumableFamilies or {}) do
      local row=f.consumableRows[index]
      if row then
        row.enable:SetChecked(self.ConsumableFamilySelected and self:ConsumableFamilySelected(family) or false)
        local choice,icon=consumableChoiceLabel(family)
        row.choice:SetText(choice)
        row.icon:SetTexture(icon or 134400)
        local preferred=self.PreferredConsumableItem and self:PreferredConsumableItem(family)
        local current=preferred and self:ConsumableCount(preferred.id) or 0
        row.inventory:SetText(current>0 and ("|cff88dd88"..current.." in bags|r") or "No usable stock")
        addHelp(row,"Supported items in bags",self:ConsumableInventorySummary(family,20))
        local active=self:ConsumableFamilyEnabled(family)
        if active then row.threshold:Enable(); row.threshold:SetAlpha(1) else row.threshold:Disable(); row.threshold:SetAlpha(0.45) end
        local threshold=self:ConsumableThreshold(family)
        row.threshold.silent=true; row.threshold:SetValue(threshold); row.threshold.valueText:SetText(formatSeconds(threshold)); row.threshold.silent=false
        row.prev:ClearAllPoints(); row.prev:SetPoint("TOPLEFT",584,-8); row.prev:SetSize(86,26); row.prev:SetText(L("Choose"))
        row.prev:SetScript("OnClick",function() B:ChooseConsumable(family,row.prev) end)
        row.prev:Show()
        if family.protectPresent then row.threshold:Hide(); row.threshold.valueText:Hide() end
        local chosen=self:ConsumableChoiceID(family)
        if chosen then
          local count=self:ConsumableCount(chosen)
          row.inventory:SetText(count>0 and ("|cff88dd88"..count.." in bags|r") or "|cffffbb44Out of stock|r")
        elseif family.explicitChoice then row.choice:SetText("Choose an item to track"); row.inventory:SetText("Not selected") end
      end
    end
    local paused=false; for _ in pairs(self.effectPauses or {}) do paused=true; break end
    f.consumePauseStatus:SetText(paused and L("An effect was not observed. Its reminder is paused until you retry.") or "")
    if f.campStatus and self.CampState then
      local camp=self:CampState()
      local text
      if camp.unknown then text="Status: unavailable"
      elseif camp.active then
        text="Status: active"..(camp.remaining and (" • "..formatSeconds(camp.remaining).." remaining") or "")
        if camp.benefits and #camp.benefits>0 then
          local names={}; for _,benefit in ipairs(camp.benefits) do names[#names+1]=benefit.name end
          text=text.."\nGranted: "..table.concat(names,", ")
        end
      else text="Status: not active" end
      f.campStatus:SetText(text)
    end
  end

  for _,choice in ipairs(self:ReminderFonts()) do if choice.key==self.db.labelFont then f.fontButton:SetText(L(choice.name)) end end
  for _,choice in ipairs(self:ReminderColors()) do if choice.key==self.db.labelColor then f.colorButton:SetText(L(choice.name)) end end
  f.bindingText:SetText("Current: "..(#self.db.keys>0 and table.concat(self.db.keys,", ") or "none"))
  f.sizeEdit:SetText(tostring(self.db.size)); f.opacityEdit:SetText(tostring(math.floor(self.db.opacity*100+0.5))); f.xEdit:SetText(tostring(math.floor(self.db.x+0.5))); f.yEdit:SetText(tostring(math.floor(self.db.y+0.5)))
  for _,choice in ipairs(self:SoundChoices()) do
    if choice.key==self.db.reminderSound then f.reminderSoundButton:SetText(L(choice.name)) end
    if choice.key==self.db.supplySound then f.supplySoundButton:SetText(L(choice.name)) end
  end
  f.channelButton:SetText(L(self.db.soundChannel=="Master" and L("Master") or L("Sound effects")))
  f.minimapCheck:SetChecked(not self.db.minimap.hide)
  f.brokerCheck:SetChecked(self.db.brokerEnabled)
  f.soundInterval.silent=true; f.soundInterval:SetValue(self.db.soundInterval); f.soundInterval.silent=false
  f.friendlyStatus:SetText(self:FriendlyStatus()); f.statusText:SetText(self:FriendlyStatus())
  if self.appearancePreview and self.appearancePreview:IsShown() then self:PreviewAppearance() end
  f.soundCheck:SetChecked(self.db.sound); f.glowCheck:SetChecked(self.db.glow); f.pulseCheck:SetChecked(self.db.pulse)
  f.buffNameCheck:SetChecked(self.db.showBuffName); f.targetNameCheck:SetChecked(self.db.showTargetName)
  f.timerCheck:SetChecked(self.db.showTimer); f.groupBadgeCheck:SetChecked(self.db.showGroupBadge)
  f.profileCheck:SetChecked(self.profileEnabled==true)
  f.rebuffSlider.silent=true; f.rebuffSlider:SetValue(self.db.seconds); f.rebuffSlider.valueText:SetText(formatSeconds(self.db.seconds)); f.rebuffSlider.silent=false

  local weaponClass=self.WeaponReminderClass and self:WeaponReminderClass()
  f.weaponUnavailable:Hide()
  f.weaponSectionHeading:SetText(L(weaponClass and "Poisons / class imbues" or "Hands to maintain"))
  f.weaponPoisonHint:SetShown(weaponClass=="ROGUE")
  for _,control in ipairs({f.weaponHint,f.weaponEnable,f.weaponApply,f.weaponMain,f.weaponOff,f.weaponTimingLabel,f.weaponTiming,f.weaponReplace,f.weaponStatus,f.weaponHandsHint}) do control:Show() end
  for _,pick in pairs(f.weaponPickers) do pick:SetShown(weaponClass~=nil); pick.menu:Hide() end
  if true then
    f.weaponEnable:SetChecked(self.db.weaponReminder==true); f.weaponApply:SetText(L(self.db.weaponApply and "Remind and apply" or "Remind only"))
    f.weaponModeHint:SetText(L(self.db.weaponApply and "Your scroll or click applies the selected weapon buff, out of combat." or "Alerts only: apply weapon buffs manually. Your preferences remain saved."))
    f.weaponMain:SetChecked(self.db.weaponMainHand~=false); f.weaponOff:SetChecked(self.db.weaponOffHand~=false)
    f.weaponReplace:SetChecked(self.db.weaponReplace==true)
    f.weaponOff:SetShown(weaponClass=="ROGUE" or not weaponClass)
    f.weaponTiming.silent=true; f.weaponTiming:SetValue(self.db.weaponSeconds); f.weaponTiming.valueText:SetText(formatSeconds(self.db.weaponSeconds)); f.weaponTiming.silent=false
    local status=self:WeaponReminderSummary()
    f.weaponStatus:SetText(status)
    for hand,pick in pairs(f.weaponPickers) do
      pick:SetShown(weaponClass~=nil and (hand=="main" or weaponClass=="ROGUE"))
      local handKey=hand; local selected=self:WeaponPreference(hand)
      pick:SetText(selected and selected.name or L("Choose preferred buff"))
      local src=selected and self:WeaponChoiceSource(selected)
      local preferredIcon=selected and A.Call(C_Spell and C_Spell.GetSpellTexture,selected.ranks[#selected.ranks])
      pick.icon:SetTexture(src and src.icon or preferredIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      for _,row in ipairs(pick.menu.rows) do row:Hide() end
      local choices={{name=B:ItemImbueClass(weaponClass) and L("None") or "None (manual missing-buff alert)"}}
      for _,choice in ipairs(self.WeaponChoices) do if choice.class==weaponClass then choices[#choices+1]=choice end end
      for i,choice in ipairs(choices) do
        local choiceKey=choice.key
        local row=pick.menu.rows[i]
        if not row then row=flatButton(pick.menu.child,"",0,-(i-1)*28,466,function(control)
          if A.Combat() then return end
          B.db.weaponChoices[control.hand]=control.choice; B.weaponPending=nil; B:InvalidateSupplies(false); B:RequestRefresh("weapon preference",0); B:Options()
        end); row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",4,0); pick.menu.rows[i]=row end
        row.hand=handKey; row.choice=choiceKey
        local source,why=self:WeaponChoiceSource(choiceKey and choice or nil)
        local icon=source and source.icon or (choiceKey and A.Call(C_Spell and C_Spell.GetSpellTexture,choice.ranks[#choice.ranks]))
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local incompatible=choiceKey and B:ItemImbueClass(choice.class) and B:CoatingWeaponMatches(16,choice)~=true
        row:SetText(choice.name..(choiceKey and (incompatible and " (incompatible weapon)" or source and (source.count and " (in bags: "..source.count..")" or " (learned)") or " (unavailable)") or "")); fitButtonText(row,420); row:Show()
        addHelp(row,choice.name,why or "Select this buff for this hand. Highest available rank is used.")
      end
      pick.menu.child:SetHeight(#choices*28)
    end
  end

  for hand,pick in pairs(f.coatingPickers) do
    pick.menu:Hide()
    local selected=self:CoatingPreference(hand)
    local src=selected and self:WeaponChoiceSource(selected)
    pick:SetText(selected and selected.name or L("None")); fitButtonText(pick,420)
    pick.icon:SetShown(selected~=nil)
    pick.icon:SetTexture(src and src.icon or (selected and A.Call(C_Spell and C_Spell.GetSpellTexture,selected.ranks[1])) or "Interface\\Icons\\INV_Misc_QuestionMark")
    local choices={{name=L("None")}}
    for _,choice in ipairs(self.CoatingChoices) do choices[#choices+1]=choice end
    for i,choice in ipairs(choices) do
      local row=pick.menu.rows[i]
      if not row then
        row=flatButton(pick.menu.child,"",0,-(i-1)*28,466,function(control)
          if A.Combat() then return end
          B.db.weaponCoatings[control.hand]=control.choice; B.weaponPending=nil; B:InvalidateSupplies(false); B:RequestRefresh("coating preference",0); B:Options()
        end)
        row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",4,0); pick.menu.rows[i]=row
      end
      row.hand=hand; row.choice=choice.key
      local source,why
      if choice.key then source,why=self:WeaponChoiceSource(choice) end
      local matches=choice.key and self:CoatingWeaponMatches(hand=="main" and 16 or 17,choice)
      local status=choice.key and (matches~=true and " (incompatible weapon)" or source and " (uses: "..source.count..")" or " (unavailable)") or ""
      row:SetText(choice.name..status); fitButtonText(row,420)
      row.icon:SetTexture(source and source.icon or (choice.key and A.Call(C_Spell and C_Spell.GetSpellTexture,choice.ranks[1])) or "Interface\\Icons\\INV_Misc_QuestionMark")
      addHelp(row,choice.name,why or "Choose this temporary coating. Highest carried usable stone rank is selected. Other enchant categories are preserved.")
    end
    pick.menu.child:SetHeight(#choices*28)
  end
  for _,r in ipairs(f.buffRows) do r:Hide() end
  local list=logicalBuffs(); local visible=0
  for _,b in ipairs(list) do
    visible=visible+1
    local row=f.buffRows[visible]
    if not row then
      row=CreateFrame("Frame",nil,f.buffChild,"BackdropTemplate"); row:SetSize(650,54)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.04,0.075,0.11,0.82)
      row.check=check(row,"",8,-15,function(s)
        local def=s:GetParent().def; if def and not A.Combat() then B.db.buffs[def.key]=s:GetChecked()==true; B:RequestRefresh("buff toggle",0) end
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(34,34); row.icon:SetPoint("TOPLEFT",42,-10)
      row.name=label(row,"",84,-8,"GameFontHighlight",220)
      row.groupIcon=row:CreateTexture(nil,"ARTWORK"); row.groupIcon:SetSize(16,16); row.groupIcon:SetPoint("TOPLEFT",84,-30)
      row.detail=label(row,"",106,-28,"GameFontDisableSmall",198)
      row.rebuff=compactSlider(row,15,180,5,104,formatSeconds,function(slider,value)
        local parent=slider:GetParent(); local def=parent.def
        if def then
          B.db.buffSeconds[def.key]=value
          if parent.default then parent.default:Enable(); parent.default:SetAlpha(1) end
          B:RequestRefresh("buff rebuff threshold",0.08)
        end
      end)
      row.rebuff:SetPoint("TOPLEFT",322,-20)
      row.default=button(row,L("Default"),486,-16,58,function(btn)
        local def=btn:GetParent().def
        if def and not A.Combat() then B.db.buffSeconds[def.key]=nil; B:RequestRefresh("rebuff default",0); B:Options() end
      end)
      addHelp(row.default,"Use default timing","Remove this buff’s custom refresh timing and use the default rebuff threshold below. This does not reset its priority or enable setting.")
      for _,direction in ipairs({-1,1}) do
        local delta=direction
        local arrow=arrowButton(row,"",delta<0 and 550 or 576,-16,24,function(btn)
          if A.Combat() then return end
          local current=btn:GetParent().def; local list=logicalBuffs()
          for i,def in ipairs(list) do if current and def.key==current.key and list[i+delta] then B:MoveBuffPriority(def.key,list[i+delta].key); return end end
        end)
        local t=arrow:CreateTexture(nil,"ARTWORK"); t:SetSize(20,20); t:SetPoint("CENTER")
        t:SetTexture(delta<0 and "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up" or "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        addHelp(arrow,delta<0 and "Move earlier" or "Move later","Move this buff earlier or later in the list. Priority numbers update automatically.")
        if delta<0 then row.up=arrow else row.down=arrow end
      end
      row.order=editbox(row,610,-17,28,true)
      row.order:SetScript("OnEnterPressed",function(s)
        local def=s:GetParent().def; if def and not A.Combat() then B.db.priorities[def.key]=math.max(1,tonumber(s:GetText()) or def.order); B:RequestRefresh("priority",0) end; s:ClearFocus(); B:Options()
      end)
      row.order:SetScript("OnEscapePressed",function(s) s:ClearFocus(); B:Options() end)
      addHelp(row.order,"Buff priority","Lower numbers are checked first. Set the same priority for equal ordering; your enabled buffs determine what can be offered.")
      f.buffRows[visible]=row
    end
    row.def=b; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(visible-1)*58); row:Show(); row.check:SetChecked(self:Enabled(b)); row.name:SetText(spellLabel(b)); row.icon:SetTexture(buffIcon(b))
    local groupName=pairedGroupName(b)
    if b.groupKey then
      local groupDef=self:FindBuff(b.groupKey)
      row.groupIcon:SetTexture(groupDef and buffIcon(groupDef) or 134400); row.groupIcon:Show()
      row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",106,-28); row.detail:SetText((groupName or "Group version").."  •  "..L("group spell"))
    else
      row.groupIcon:Hide(); row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",84,-28)
      row.detail:SetText(b.kind=="self" and L("Self buff") or L("Single-target buff"))
    end
    if not learnedSpell(b) then
      row.groupIcon:Hide(); row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",84,-28); row.detail:SetText(unlearnedText())
    elseif b.groupKey and not learnedSpell(self:FindBuff(b.groupKey)) then
      row.detail:SetText(L("group spell").." · "..unlearnedText())
    end
    row.up:SetEnabled(visible>1); row.down:SetEnabled(visible<#list)
    row.order:SetText(tostring(self.db.priorities[b.key] or b.order))
    local threshold=self:RebuffSeconds(b)
    row.rebuff.silent=true; row.rebuff:SetValue(threshold); row.rebuff.valueText:SetText(formatSeconds(threshold)); row.rebuff.silent=false
    if self.db.buffSeconds[b.key]~=nil then row.default:Enable(); row.default:SetAlpha(1) else row.default:Disable(); row.default:SetAlpha(0.45) end
  end
  f.emptyBuffs:SetShown(visible==0)
  f.buffChild:SetHeight(math.max(1,visible*58))
  if f.diagVersion then f.diagVersion:SetText("BuffTap v"..tostring(self.version or "unknown")) end
  if f.diagText then f.diagText:SetText(table.concat(self:DiagnosticsLines(),"\n\n")) end
  f:Show(); f:Raise()
end


function B:PreviewAppearance()
  if A.Combat() then return end
  local f=self.appearancePreview
  if not f then
    f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); self.appearancePreview=f
    f:SetFrameStrata("FULLSCREEN_DIALOG"); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
    f:SetBackdropColor(0.03,0.04,0.05,1)
    f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetPoint("TOPLEFT",4,-4); f.icon:SetPoint("BOTTOMRIGHT",-4,4); f.icon:SetTexture(ICON_PATH)
    f.glow=f:CreateTexture(nil,"OVERLAY"); f.glow:SetAllPoints(); f.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight"); f.glow:SetBlendMode("ADD")
    f.pulseAnimation=f.glow:CreateAnimationGroup()
    if f.pulseAnimation then
      local animation=f.pulseAnimation:CreateAnimation("Alpha")
      animation:SetFromAlpha(1); animation:SetToAlpha(0.45); animation:SetDuration(0.7); animation:SetOrder(1)
      local second=f.pulseAnimation:CreateAnimation("Alpha")
      second:SetFromAlpha(0.45); second:SetToAlpha(1); second:SetDuration(0.7); second:SetOrder(2)
      f.pulseAnimation:SetLooping("REPEAT")
    end
    f.nameLabel=label(f,L("Reminder"),0,18,"GameFontHighlightSmall"); f.nameLabel:ClearAllPoints(); f.nameLabel:SetPoint("BOTTOM",f,"TOP",0,5)
    f.recipient=label(f,L("Recipient"),0,-self.db.size-6,"GameFontHighlightSmall")
    f.timer=label(f,"",4,-4,"GameFontHighlightSmall"); f.timer:ClearAllPoints(); f.timer:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-3,3); f.timer:SetJustifyH("RIGHT")
    f.count=label(f,"3+",4,-self.db.size+16,"GameFontHighlightSmall")
    f:SetScript("OnMouseDown",function() f:Hide() end)
    f:SetScript("OnHide",function() if f.pulseAnimation then f.pulseAnimation:Stop() end end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:SetScript("OnEvent",function() f:Hide() end)
    addHelp(f,L("Preview appearance"),L("Move icon opens a safe preview that cannot cast spells."))
  end
  f:SetSize(self.db.size,self.db.size); f:SetAlpha(self.db.opacity); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
  f.nameLabel:SetShown(self.db.showBuffName); f.recipient:SetShown(self.db.showTargetName)
  f.recipient:ClearAllPoints(); f.recipient:SetPoint("TOP",f,"BOTTOM",0,-5)
  f.timer:SetText(L("%d sec",30)); f.timer:SetShown(self.db.showTimer)
  f.count:ClearAllPoints(); f.count:SetPoint("TOPLEFT",f,"TOPLEFT",4,-3); f.count:SetShown(self.db.showGroupBadge)
  f.glow:SetShown(self.db.glow or self.db.pulse)
  if f.pulseAnimation then if self.db.pulse then f.pulseAnimation:Play() else f.pulseAnimation:Stop() end end
  if self.ApplyReminderStyle then self:ApplyReminderStyle(f) end
  f:Show()
end

function B:MoveAnchor()
  if A.Combat() then return end
  if not self.anchor then
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); self.anchor=f
    f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12}); f:SetBackdropColor(0.02,0.08,0.14,0.88)
    local icon=f:CreateTexture(nil,"ARTWORK"); icon:SetPoint("TOPLEFT",4,-4); icon:SetPoint("BOTTOMRIGHT",-4,4); icon:SetTexture(ICON_PATH)
    local shade=f:CreateTexture(nil,"OVERLAY"); shade:SetAllPoints(); shade:SetColorTexture(0,0,0,0.22)
    local txt=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); txt:SetPoint("CENTER"); txt:SetText(L("DRAG"))
    f:SetScript("OnDragStart",f.StartMoving)
    f:SetScript("OnDragStop",function(s)
      s:StopMovingOrSizing(); if not A.Combat() then local x,y=s:GetCenter(); local cx,cy=UIParent:GetCenter(); B.db.x=x-cx; B.db.y=y-cy; B.appearance=nil; B:RequestRefresh("move icon",0) end
      s:Hide(); B:Options()
    end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:SetScript("OnEvent",function(s) s:StopMovingOrSizing(); s:Hide() end)
  end
  if self.options then self.options:Hide() end
  self.anchor:SetSize(self.db.size,self.db.size); self.anchor:ClearAllPoints(); self.anchor:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y); self.anchor:Show()
end

local function hideSettingsPanel()
  if SettingsPanel and SettingsPanel.IsShown and SettingsPanel:IsShown() then
    if HideUIPanel then HideUIPanel(SettingsPanel) else SettingsPanel:Hide() end
  end
  if InterfaceOptionsFrame and InterfaceOptionsFrame.IsShown and InterfaceOptionsFrame:IsShown() then
    if HideUIPanel then HideUIPanel(InterfaceOptionsFrame) else InterfaceOptionsFrame:Hide() end
  end
end

function B:RegisterOptionsCategory()
  if self.optionsCategoryRegistered then return end
  local p=CreateFrame("Frame",nil,UIParent); p.name="BuffTap"
  local logo=p:CreateTexture(nil,"ARTWORK"); logo:SetSize(82,82); logo:SetPoint("TOPLEFT",16,-16); logo:SetTexture(ICON_PATH)
  local title=label(p,"BuffTap",116,-24,"GameFontNormalLarge")
  label(p,"One-tap buff maintenance for WoW Forever.",116,-52,"GameFontHighlightSmall",500)
  label(p,"Open BuffTap to manage class buffs, group assignments, friendly-target buffing, consumable reminders, timing, and the reminder icon.",18,-144,"GameFontHighlight",620)
  local open=button(p,"Open BuffTap",18,-184,132,function()
    if A.Combat() then if B.Print then B.Print("Settings are available after combat.") end; return end
    hideSettingsPanel(); B:Options()
  end)
  label(p,"You can also open it at any time with /bt.",18,-220,"GameFontDisableSmall",500)

  if Settings and type(Settings.RegisterCanvasLayoutCategory)=="function" and type(Settings.RegisterAddOnCategory)=="function" then
    local ok,category=pcall(Settings.RegisterCanvasLayoutCategory,p,"BuffTap")
    if ok and category then
      local registered=pcall(Settings.RegisterAddOnCategory,category)
      if registered then self.settingsCategory=category; self.optionsCategoryRegistered=true; return end
    end
  end
  if type(InterfaceOptions_AddCategory)=="function" then
    local ok=pcall(InterfaceOptions_AddCategory,p)
    if ok then self.legacyOptionsPanel=p; self.optionsCategoryRegistered=true end
  end
end

function B:OpenOptionsCategory()
  self:RegisterOptionsCategory()
  if self.settingsCategory and Settings and type(Settings.OpenToCategory)=="function" then
    local id=self.settingsCategory.GetID and self.settingsCategory:GetID() or self.settingsCategory.ID
    if id then local ok=pcall(Settings.OpenToCategory,id); if ok then return end end
  end
  if self.legacyOptionsPanel and type(InterfaceOptionsFrame_OpenToCategory)=="function" then
    if type(InterfaceAddOnsList_Update)=="function" then pcall(InterfaceAddOnsList_Update) end
    pcall(InterfaceOptionsFrame_OpenToCategory,self.legacyOptionsPanel)
    return
  end
  self:Options()
end
