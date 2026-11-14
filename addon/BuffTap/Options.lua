-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ADDON,B=...
local A=B.API
local T=B.OptionsTheme
local function L(key,...) return B:Text(key,...) end
local TAB={Buffs=1,Groups=2,Target=3,Nearby=4,Consumables=5,Camping=6,Weapons=7,Appearance=8,Helpers=9,Profiles=10,Diagnostics=11,PatchNotes=12,Blacklist=13,Cleanse=14}
local TAB_NAMES={L("My buffs"),L("Groups"),L("Target"),L("Nearby"),L("Consumables"),L("Camping"),L("Weapons"),L("Customization"),L("Helpers"),L("Profiles"),L("Diagnostics"),L("Patch notes"),L("Blacklist"),L("Cleanse")}
local OPTIONS_WIDTH,OPTIONS_HEIGHT=932,900
-- Page area inside the window: right of the 196 px sidebar, below the 120 px header, above the footer.
B.OptionsPageLeft,B.OptionsPageTop,B.OptionsPageRight,B.OptionsPageBottom=208,-132,-12,40
local ICON_PATH="Interface\\AddOns\\BuffTap\\Media\\BuffTapIcon"

local function label(parent,text,x,y,font,width)
  local fs=parent:CreateFontString(nil,"OVERLAY",T.FontName(font or "GameFontNormal"))
  fs:SetPoint("TOPLEFT",x,y)
  if width then fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true) end
  fs:SetText(L(text)); fs.optionsLabel=true; fs.optionsTitle=font=="GameFontNormalLarge"; fs.optionsMuted=font=="GameFontDisableSmall"
  T.Track(fs,"label")
  if font=="GameFontDisableSmall" then fs:SetTextColor(unpack(T.muted)) end
  return fs
end

local function line(parent,y)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t.optionsDecoration=true; T.Track(t,"rule"); t:SetColorTexture(unpack(T.rule)); t:SetPoint("TOPLEFT",18,y); t:SetPoint("TOPRIGHT",-18,y); t:SetHeight(1)
  return t
end

local function card(parent,x,y,width,height)
  return T.Card(parent,x,y,width,height)
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
  b:SetBackdropColor(unpack(T.control)); b:SetBackdropBorderColor(unpack(T.border))
  T.Button(b)
  b:SetSize(w or 110,26); b:SetPoint("TOPLEFT",x,y); b:SetText(L(text)); b:SetScript("OnClick",fn)
  fitButtonText(b,w or 110)
  return b
end

-- Action controls share the same visual treatment as selectors and navigation.
local function button(parent,text,x,y,w,fn)
  local b=flatButton(parent,text,x,y,w,fn)
  b:SetSize(w or 110,26); b:SetPoint("TOPLEFT",x,y); b:SetText(L(text)); b:SetScript("OnClick",fn)
  fitButtonText(b,w or 110)
  return b
end
local function arrowButton(parent,text,x,y,w,fn)
  local b=flatButton(parent,text,x,y,w,fn); b:SetBackdropColor(1,1,1,.04); b:SetBackdropBorderColor(1,1,1,.08)
  return b
end

-- One selector convention: explicit choices, a visible arrow and toggle-to-close.
local function selector(parent,text,x,y,width,choices,onSelect,searchable)
  local scrollable=searchable==true or searchable=="scroll"
  searchable=searchable==true
  local control,menu,render
  -- Scrolling lists follow their box's width; searchable lists keep room for the search field.
  local menuWidth=searchable and 340 or scrollable and math.max(width,160) or width
  local visibleRows=searchable and 7 or 5
  control=flatButton(parent,text,x,y,width,function()
    if A.Combat() then return end
    if menu:IsShown() then menu:Hide(); return end
    if B.options and B.options.activeSelector and B.options.activeSelector~=menu and B.options.activeSelector~=control.ownerPanel then B.options.activeSelector:Hide() end
    if B.options then B.options.activeSelector=control.ownerPanel or menu end
    render(); menu:Show()
  end)
  control.arrow=control:CreateTexture(nil,"OVERLAY"); control.arrow:SetSize(16,16); control.arrow:SetPoint("RIGHT",-4,0)
  control.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  local textRegion=control:GetFontString()
  if textRegion then textRegion:ClearAllPoints(); textRegion:SetPoint("LEFT",10,0); textRegion:SetPoint("RIGHT",-26,0) end
  menu=CreateFrame("Frame",nil,parent,"BackdropTemplate"); control.menu=menu
  menu:SetPoint("TOPLEFT",control,"BOTTOMLEFT",0,-2); menu:SetFrameStrata("TOOLTIP"); menu:SetClampedToScreen(true)
  menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  menu:SetBackdropColor(unpack(T.menu)); menu:SetBackdropBorderColor(unpack(T.border)); menu.rows={}; menu:Hide()
  render=function()
    local all=choices(); local entries={}
    local query=searchable and string.lower(menu.search:GetText() or "") or ""
    for _,entry in ipairs(all) do if query=="" or string.find(string.lower(entry.name),query,1,true) then entries[#entries+1]=entry end end
    local count=#entries
    local top=searchable and 34 or 4
    menu:SetSize(menuWidth,top+(scrollable and math.max(28,math.min(visibleRows,count)*28) or count*28)+4)
    if scrollable then
      menu.content:SetHeight(math.max(1,count*28)); menu.scroll:SetVerticalScroll(0)
      menu.empty:SetShown(count==0)
    end
    for _,row in ipairs(menu.rows) do row:Hide() end
    for i=1,count do
      local entry=entries[i]; local row=menu.rows[i]
      if not row then row=flatButton(scrollable and menu.content or menu,"",4,-(scrollable and 0 or top)-(i-1)*28,(scrollable and menuWidth-28 or width)-8,function(btn)
        if A.Combat() then return end
        onSelect(btn.choice); menu:Hide(); B:Options()
      end); menu.rows[i]=row
        local fs=row:GetFontString(); if fs then fs:ClearAllPoints(); fs:SetPoint("LEFT",8,0); fs:SetPoint("RIGHT",-6,0); fs:SetJustifyH("LEFT") end
      end
      row.choice=entry.key; row:SetText((searchable and entry.source and L(entry.source)..": " or "")..L(entry.name))
      B:PreviewChoiceFont(row,entry.font)
      local selected=control:GetText()==row:GetText() or (searchable and control:GetText()==L(entry.name))
      local r,g,b=T.accent[1],T.accent[2],T.accent[3]
      if selected then row:SetBackdropColor(r*.16+.04,g*.16+.046,b*.16+.056,1); row:SetBackdropBorderColor(r,g,b,.55)
      else row:SetBackdropColor(0,0,0,0); row:SetBackdropBorderColor(0,0,0,0) end
      row:Show()
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
    menu.content=CreateFrame("Frame",nil,menu.scroll); menu.content:SetSize(menuWidth-32,1); menu.scroll:SetScrollChild(menu.content)
    menu.empty=label(menu.content,L("No matches"),8,-6,"GameFontDisableSmall"); menu.empty:Hide()
  end
  parent:HookScript("OnHide",function() menu:Hide() end)
  T.Selector(control)
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
  c:SetSize(24,24); c:SetPoint("TOPLEFT",x,y); c.Text:SetText(L(text)); c:SetScript("OnClick",fn); T.Check(c)
  return c
end

local function addHelp(frame,title,body)
  if not frame or type(frame.SetScript)~="function" then return end
  frame:SetScript("OnEnter",function(self)
    if not GameTooltip then return end
    T.Tooltip(self,L(title),body and body~="" and L(body) or nil)
  end)
  frame:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

local function markTargetRole()
  local role,name=B:CycleTargetRoleMark()
  if role==false or role==nil then B.Print(L("Select a friendly player first.")); return end
  B.Print(role=="none" and L("%s: role mark cleared.",name or "") or L("%s marked as %s.",name or "",L(role=="TANK" and "Tank" or "Healer")))
  B:Options()
end
local roleHelp="Roles come from, in order: your mark, the group role (role check or the player's own setting), the raid Main Tank assignment, then optionally a tanking stance or form. Click to cycle your target: Tank, Healer, no mark."
local function editbox(parent,x,y,w,numeric)
  local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
  e:SetSize(w or 64,22); e:SetPoint("TOPLEFT",x,y); e:SetAutoFocus(false); if numeric then e:SetNumeric(true) end
  e:SetJustifyH("CENTER"); T.EditFocus(e)
  return e
end

local function panel(parent)
  local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
  f:SetPoint("TOPLEFT",B.OptionsPageLeft,B.OptionsPageTop); f:SetPoint("BOTTOMRIGHT",B.OptionsPageRight,B.OptionsPageBottom)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  f:SetBackdropColor(0,0,0,0); f:SetBackdropBorderColor(0,0,0,0)
  f:Hide()
  return f
end

local function formatSeconds(value)
  value=math.floor((tonumber(value) or 0)+0.5)
  if value<=0 then return L("When gone") end
  if value<60 then return L("%d sec",value) end
  local m=math.floor(value/60); local s=value%60
  if s==0 then return L("%d min",m) end
  return L("%dm %ds",m,s)
end

local function setAndRefresh(key,value)
  if A.Combat() then return end
  if B:SetEditorPreference(key,value) then return end
  B.db[key]=value; B:InitDB(); B.appearance=nil; B:RequestRefresh("setting",0)
  if B.UpdateOptionsPreviews then B:UpdateOptionsPreviews() end
end

local function rebuffSlider(parent)
  local s=CreateFrame("Slider",nil,parent,"OptionsSliderTemplate")
  s:SetSize(320,18); s:SetMinMaxValues(15,180); s:SetValueStep(5)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  if s.Low then s.Low:Hide() end
  if s.High then s.High:Hide() end
  if s.Text then s.Text:Hide() end

  s.valueText=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  s.valueText:SetPoint("LEFT",s,"RIGHT",18,0); s.valueText:SetText(L("%d sec",45))
  s:SetScript("OnValueChanged",function(self,value)
    value=math.floor(value/5+0.5)*5
    self.valueText:SetText(formatSeconds(value))
    if self.silent or A.Combat() then return end
    B:EditorSettings("buffs").seconds=value; B:InitDB(); B:RequestRefresh("global rebuff threshold",0.08)
  end)
  s.visualFormatter=formatSeconds; T.StyleSlider(s,15,180,5,function(_,v) B:EditorSettings("buffs").seconds=v; B:InitDB(); B:RequestRefresh("global rebuff threshold",.08) end); s:SetUnit("sec"); return s
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
  s.visualFormatter=formatter; T.StyleSlider(s,minValue,maxValue,step,onChange)
  -- Name the unit the slider changes; the field keeps plain numbers so typing stays simple.
  local unit
  if formatter==formatSeconds then unit="sec"
  else
    local sample=formatter(maxValue)
    if type(sample)=="string" then
      if sample:match("px$") then unit="px" elseif sample:match("%%$") then unit="%" elseif sample:match("%+$") then unit="players" end
    end
  end
  if unit then s:SetUnit(unit) end
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
-- Match the group's legacy fallback, rather than target-only class suitability.
local function groupDefaultOrder(class,scope)
  local order={}
  local settings=B:SituationPreview(B:EditingGroupContext()=="Raid" and "raid" or "party","buffs")
  for _,def in ipairs(B:ClassList(settings)) do
    if def.kind=="blessing" and not def.singleKey and B:Enabled(def,settings) and B:GroupClassAllowed(def,class,B:EditingGroupContext())
      and (not scope or scope==0 or B:GroupSelected(def,scope,B:EditingGroupContext())) then order[#order+1]=def.key end
  end
  return order
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
  menu.priorityAutomatic:SetText(L(control.scope and control.scope()>0 and "Use raid defaults" or control.priorityTarget and "Automatic" or "Use Buffs settings"))
  for _,t in ipairs(menu.separators or {}) do t:Hide() end
  menu.priorityTitle:Show(); menu.priorityHelp:Show(); menu.priorityAutomatic:Show(); menu.prioritySkip:Show(); menu.priorityDone:Show()
  local mode=control.getChoice()
  local order={}
  local source
  if mode=="priority" then source=control.getOrder() or {}
  elseif mode=="skip" then source={}
  elseif mode then source={mode}
  else
    local scope=control.scope and control.scope() or 0
    local choice,inherited
    if scope>0 then choice,inherited=B:GroupBlessingSettings(control.priorityClass,0,true) end
    source=choice=="priority" and (inherited or {}) or choice=="skip" and {} or choice and {choice} or (control.priorityTarget and B:DefaultBlessingOrder(control.priorityClass,true) or groupDefaultOrder(control.priorityClass,scope))
  end
  for i,key in ipairs(source or {}) do order[i]=key end
  control.editorOrder=order
  if mode~="priority" then
    local name=mode=="skip" and L("Skip class") or mode and L("Fixed: %s",blessingName(mode)) or L(control.priorityTarget and "Automatic" or "Buff settings")
    menu.priorityHelp:SetText(name..". "..L(mode and "Edit checks or arrows to customize." or "Uses enabled Buffs in order, filtered for this class. Edit below to customize."))
  end
  if control.scope and control.scope()>0 then
    menu.priorityTitle:SetText(menu.priorityTitle:GetText().." - G"..control.scope())
    if mode==nil then menu.priorityHelp:SetText(L("Inherits raid defaults. Changes apply to this raid group only.")) end
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
        local texture=arrow:CreateTexture(nil,"ARTWORK"); texture:SetPoint("CENTER"); T.Glyph(texture,delta<0 and "up" or "down",12)
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
    if not B:BlessingLearned(key) then note=(not index and L("Not included").." - " or "")..unlearnedText() end
    row.note:SetText(note)
    row.up.index=index; row.down.index=index
    row.up:SetEnabled(index~=nil and index>1); row.down:SetEnabled(index~=nil and index<#order)
    row:Show()
  end
  control.saveOrder=save
  addHelp(control,"Blessing priority order",prioritySummary(order).."\nOne blessing from you per player. Your own blessing is maintained. Unknown ownership stops fallback. Player exceptions apply in By class mode.")
end

local function blessingPick(parent,x,y,width,getChoice,setChoice,player)
  local pick=flatButton(parent,"",x,y,width,function(control)
    if A.Combat() or control.disabled then return end
    local f=B.options
    if not f.blessingMenu then
      f.blessingMenu=CreateFrame("Frame","BuffTapBlessingMenu",f,"BackdropTemplate")
      if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapBlessingMenu") end
      f.blessingMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
      f.blessingMenu:SetBackdropColor(unpack(T.menu)); f.blessingMenu:SetBackdropBorderColor(unpack(T.border))
      f.blessingMenu.separators={}
      for _,y in ipairs({-32,-172}) do
        local separator=f.blessingMenu:CreateTexture(nil,"ARTWORK"); separator:SetColorTexture(unpack(T.rule)); separator:SetPoint("TOPLEFT",8,y); separator:SetSize(254,1); f.blessingMenu.separators[#f.blessingMenu.separators+1]=separator
      end
      f.blessingMenu:SetFrameStrata("TOOLTIP"); f.blessingMenu:SetClampedToScreen(true); f.blessingMenu:EnableMouse(true); f.blessingMenu.rows={}; f.blessingMenu:Hide()
    end
    local menu=f.blessingMenu
    if f.activeSelector and f.activeSelector~=menu then f.activeSelector:Hide() end
    f.activeSelector=menu
    if menu:IsShown() and menu.owner==control then menu:Hide(); return end
    menu.owner=control; menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",control,"BOTTOMLEFT",0,-2)
    if control.getOrder then showBlessingPriorityMenu(menu,control); menu:Show(); return end
    for _,row in ipairs(menu.priorityRows or {}) do row:Hide() end
    for _,name in ipairs({"priorityTitle","priorityHelp","priorityAutomatic","prioritySkip","priorityDone"}) do if menu[name] then menu[name]:Hide() end end
    for _,t in ipairs(menu.separators or {}) do t:Show() end
    menu:SetSize(270,176)
    local choices=control.uniform and {"bok","bom","bow"} or {"inherit","bok","bom","bow","skip"}
    menu:SetHeight(#choices*28+8)
    for _,t in ipairs(menu.separators or {}) do t:Hide() end
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
  pick.divider=pick:CreateTexture(nil,"ARTWORK"); pick.divider:SetColorTexture(1,1,1,.08); pick.divider:SetSize(1,22); pick.divider:SetPoint("RIGHT",-27,0)
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
  f.blessingContext=self:BlessingContext(); f.blessingScope=0; f.blessingScopeButtons={}
  f.blessingTitle=label(p,"Party buffing",18,-16,"GameFontNormalLarge")
  f.blessingIntro=label(p,"",18,-41,"GameFontDisableSmall",680)
  f.partyView=flatButton(p,"Party",510,-13,92,function()
    if A.Combat() then return end
    f.blessingContext="Party"; f.blessingScope=0; f.expandedBlessing=nil; B:Options()
  end)
  f.raidView=flatButton(p,"Raid",610,-13,92,function()
    if A.Combat() then return end
    f.blessingContext="Raid"; f.blessingScope=0; f.expandedBlessing=nil; B:Options()
  end)
  f.blessingGroupEnable=check(p,"Enable party / raid",18,-59,function(c)
    if A.Combat() then return end
    if f.blessingContext=="Party" then B.db.blessingPartyExcluded=c:GetChecked()~=true end
    setAndRefresh("group",c:GetChecked()==true); B:Options()
  end)
  f.blessingSmart=check(p,"Use Greater Blessings",330,-59,function(c) setAndRefresh("smartGroup",c:GetChecked()==true); B:Options() end)
  f.blessingCasting=button(p,"Casting...",593,-59,110,function()
    if A.Combat() then return end
    local d=f.blessingCastingPanel
    if f.activeSelector and f.activeSelector~=d then f.activeSelector:Hide() end
    f.activeSelector=d; d:SetShown(not d:IsShown())
  end)
  local casting=CreateFrame("Frame","BuffTapBlessingCasting",p,"BackdropTemplate"); f.blessingCastingPanel=casting
  casting:SetSize(460,154); casting:SetPoint("CENTER"); casting:SetFrameStrata("DIALOG"); casting:SetFrameLevel(p:GetFrameLevel()+60)
  casting:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  casting:SetBackdropColor(unpack(T.menu)); casting:SetBackdropBorderColor(unpack(T.border)); casting:EnableMouse(true); casting:SetClampedToScreen(true)
  label(casting,"Greater Blessings",18,-16,"GameFontNormalLarge")
  label(casting,"Use a Greater Blessing when this many recipients need it.",18,-43,"GameFontDisableSmall",424)
  f.blessingThreshold=compactSlider(casting,2,5,1,180,function(v) return tostring(v).."+" end,function(_,v)
    B:GroupEditorSettings().blessingNeed=v; B:NormalizeGroupNeeds(B:EditingGroupContext()); B:RequestRefresh("blessing threshold",0.08)
  end); f.blessingThreshold:SetPoint("TOPLEFT",22,-72)
  label(casting,"Same-class assignments must agree across the full group.",18,-100,"GameFontDisableSmall",424)
  button(casting,"Done",332,-119,110,function() casting:Hide() end); casting:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapBlessingCasting") end
  for i=0,8 do
    local scope=i
    local x=i==0 and 18 or 18+((i-1)%4)*174
    local y=i==0 and -170 or -91-math.floor((i-1)/4)*38
    local c=flatButton(p,i==0 and "Raid defaults" or "G"..i,x,y,i==0 and 145 or 164,function()
      if A.Combat() then return end
      f.blessingScope=scope; f.expandedBlessing=nil; B:Options()
    end)
    c:SetHeight(i==0 and 26 or 34); c.icons={}
    if i>0 then
      local text=c:GetFontString(); if text then text:ClearAllPoints(); text:SetPoint("TOPLEFT",8,-4); text:SetJustifyH("LEFT") end
      c.note=label(c,"",8,-21,"GameFontDisableSmall",150)
      for j=1,4 do local icon=c:CreateTexture(nil,"ARTWORK"); icon:SetSize(19,19); icon:SetPoint("TOPRIGHT",-6-(4-j)*20,-3); c.icons[j]=icon end
    end
    f.blessingScopeButtons[i+1]=c
  end
  f.blessingSelected=check(p,"Buff this group",180,-170,function(c)
    if A.Combat() then return end
    B:SetRaidGroupColumn(f.blessingScope,c:GetChecked()==true,B:EditingGroupContext()); B:InvalidateAura(); B:RequestRefresh("raid responsibility",0); B:Options()
  end)
  f.blessingInherit=button(p,"Use raid defaults",549,-171,154,function()
    if B:ResetBlessingScope(f.blessingScope) then f.expandedBlessing=nil; B:Options() end
  end)
  f.blessingAssignmentTitle=label(p,"Party blessings",18,-112,"GameFontNormal")
  f.blessingByClass=flatButton(p,"By class",280,-106,120,function()
    if B:SetBlessingPlanMode(f.blessingContext,f.blessingScope,"class") then f.expandedBlessing=nil; B:Options() end
  end)
  f.blessingSame=flatButton(p,"Same blessing for everyone",408,-106,295,function()
    if B:SetBlessingPlanMode(f.blessingContext,f.blessingScope,"same") then f.expandedBlessing=nil; B:Options() end
  end)
  f.blessingUniform=blessingPick(p,210,-151,360,function() return B:BlessingPlan(f.blessingContext,f.blessingScope).blessing end,function(key)
    if key and key~="skip" then B:SetBlessingPlanMode(f.blessingContext,f.blessingScope,"same",key) end
  end)
  f.blessingUniform.uniform=true
  f.blessingUniformLabel=label(p,"Blessing for everyone",24,-159,"GameFontNormal",174)
  f.blessingUniformHelp=label(p,"",24,-196,"GameFontDisableSmall",670)
  f.blessingHeaders={label(p,"Class",24,-144,"GameFontDisableSmall",112),label(p,"Blessing / priority order",224,-144,"GameFontDisableSmall",270),label(p,"Player exceptions",546,-144,"GameFontDisableSmall",140)}
  f.blessingRows={}
  for index,class in ipairs(self.RecipientClasses) do
    local token=class; local row=CreateFrame("Frame",nil,p,"BackdropTemplate"); row:SetSize(686,25)
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(unpack(index%2==0 and T.rowAlt or T.row)); T.Row(row,4)
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(21,21); row.icon:SetPoint("TOPLEFT",6,-2)
    row.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    local coords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]; if coords then row.icon:SetTexCoord(unpack(coords)) end
    local name=(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token:sub(1,1)..token:sub(2):lower()
    label(row,name,36,-8,"GameFontHighlightSmall",114)
    row.pick=blessingPick(row,206,0,286,function() return B:GroupBlessingSettings(token,f.blessingScope,false,f.blessingContext) end,function(key) B:SetGroupBlessingSettings(token,f.blessingScope,key,nil,false,f.blessingContext) end)
    row.pick.scope=function() return f.blessingContext=="Raid" and f.blessingScope or 0 end
    local update=row.pick.Update
    row.pick.Update=function(control)
      update(control)
      if control.getChoice()==nil then
        local chosen,order=B:GroupBlessingSettings(token,f.blessingScope,true,f.blessingContext)
        if not chosen then order=groupDefaultOrder(token,f.blessingContext=="Raid" and f.blessingScope or 1); chosen=order and order[1] end
        local first=chosen=="priority" and order and order[1] or chosen
        control:SetText((chosen=="priority" and prioritySummary(order) or blessingName(first or "skip"))..(f.blessingContext=="Raid" and f.blessingScope>0 and " |cffbbb6a8("..L("default")..")|r" or " |cffbbb6a8("..L("Buffs")..")|r"))
        control.icon:SetTexture(first and first~="skip" and blessingIcon(first) or "Interface\\Buttons\\UI-GroupLoot-Pass-Up")
      end
    end
    row.pick.priorityClass=token; row.pick.priorityTarget=false
    row.pick.getOrder=function() local _,order=B:GroupBlessingSettings(token,f.blessingScope,false,f.blessingContext); return order end
    row.pick.setOrder=function(order) B:SetGroupBlessingSettings(token,f.blessingScope,nil,order,true,f.blessingContext) end
    row.players=flatButton(row,"",548,-2,132,function()
      if A.Combat() or B:BlessingPlan(f.blessingContext,f.blessingScope).mode=="same" then return end
      if f.expandedBlessing==token then f.expandedBlessing=nil else f.expandedBlessing=token end
      f.blessingPlayerOffset=0; B:Options()
    end)
    row.players:SetBackdropBorderColor(0,0,0,0); row.players:SetBackdropColor(0,0,0,0)
    row.players.arrow=row.players:CreateTexture(nil,"ARTWORK"); row.players.arrow:SetSize(18,18); row.players.arrow:SetPoint("LEFT",3,0)
    row.class=token; f.blessingRows[index]=row
  end
  local detail=CreateFrame("Frame","BuffTapPlayerExceptions",p,"BackdropTemplate"); detail:SetSize(668,202); f.blessingDetail=detail
  detail:SetFrameStrata("DIALOG"); detail:SetFrameLevel(p:GetFrameLevel()+30); detail:EnableMouse(true); detail:EnableMouseWheel(true); detail:SetClampedToScreen(true)
  detail:SetScript("OnMouseWheel",function(_,delta)
    f.blessingPlayerOffset=math.max(0,math.min(f.blessingPlayerMaxOffset or 0,(f.blessingPlayerOffset or 0)-delta*3)); B:Options()
  end)
  detail:SetScript("OnHide",function() if not f.updatingBlessingDetail then f.expandedBlessing=nil; if f.blessingMenu then f.blessingMenu:Hide() end end end)
  if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapPlayerExceptions") end
  detail:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  detail:SetBackdropColor(unpack(T.menu)); detail:SetBackdropBorderColor(unpack(T.border))
  f.blessingDetailTitle=label(detail,"Player exceptions",12,-6,"GameFontNormalSmall",560)
  f.blessingCollapse=arrowButton(detail,"",634,-2,26,function() f.expandedBlessing=nil; B:Options() end)
  local collapse=f.blessingCollapse:CreateTexture(nil,"ARTWORK"); collapse:SetPoint("CENTER"); T.Glyph(collapse,"up",12)
  f.blessingPlayerRows={}
  for i=1,5 do
    local row=CreateFrame("Frame",nil,detail); row:SetSize(626,26); row:SetPoint("TOPLEFT",4,-26-(i-1)*27)
    row.name=label(row,"",8,-7,"GameFontHighlightSmall",190)
    row.pick=blessingPick(row,210,0,190,function()
      local v=B:GetBlessingPlayer(row.guid,f.blessingContext); return v and v.choice
    end,function(key)
      if row.entry and A.Call(UnitGUID,row.entry.unit)==row.guid then
        B:SetBlessingPlayer(row.entry,key,f.blessingContext)
      end
    end,true)
    local updatePlayer=row.pick.Update
    row.pick.Update=function(control)
      updatePlayer(control)
      if not control.getChoice() and row.entry then
        local key,order=B:GroupBlessingSettings(row.entry.class,row.entry.group,true,f.blessingContext)
        if not key then order=groupDefaultOrder(row.entry.class,row.entry.group); key=order[1] end
        local first=key=="priority" and order and order[1] or key
        control:SetText((key=="priority" and L("Priority list") or blessingName(first or "skip")).." ("..L("class")..")")
        control.icon:SetTexture(first and first~="skip" and blessingIcon(first) or "Interface\\Buttons\\UI-GroupLoot-Pass-Up")
      end
    end
    f.blessingPlayerRows[i]=row
  end
  -- Role choices for this class: a tank or healer of the class gets this blessing instead of the class choice.
  f.blessingRoleRows={}
  for i,role in ipairs({"TANK","HEALER"}) do
    local row=CreateFrame("Frame",nil,detail); row:SetSize(626,26); row:SetPoint("TOPLEFT",4,-166-(i-1)*28)
    row.name=label(row,L(role=="TANK" and "Tanks in this class" or "Healers in this class"),8,-7,"GameFontNormalSmall",190)
    row.pick=blessingPick(row,210,0,190,function()
      local ctx=f.blessingContext=="Raid" and "Raid" or "Party"; local map=B.db.blessingRoleChoices[ctx]; map=map and map[role]
      return map and f.blessingDetailClass and map[f.blessingDetailClass]
    end,function(key) if f.blessingDetailClass then B:SetBlessingRoleChoice(role,f.blessingDetailClass,key,f.blessingContext) end end,true)
    addHelp(row.pick,role=="TANK" and "Tanks in this class" or "Healers in this class","Gives players of this class with this role a different blessing. Player exceptions still take precedence. When a class has mixed choices, single blessings are used for that class instead of a Greater Blessing.")
    f.blessingRoleRows[i]=row
  end
  f.blessingRoleMark=button(detail,L("Mark target role"),414,-166,150,markTargetRole)
  addHelp(f.blessingRoleMark,"Mark target role",roleHelp)
  f.blessingRoleGuess=check(detail,L("Guess tanks from stance"),414,-196,function(c) if not A.Combat() then B.db.roleGuess=c:GetChecked()==true; B.roleCache=nil; B:InvalidateAura(); B:RequestRefresh("role guess",0) end end)
  addHelp(f.blessingRoleGuess,"Guess tanks from stance","Counts a visible Defensive Stance, Bear or Dire Bear Form, or Righteous Fury as a tank when no role is set. Off by default.")
  f.blessingPageText=label(detail,"",12,-235,"GameFontDisableSmall",440)
  f.blessingScroll=CreateFrame("Slider",nil,detail,"OptionsSliderTemplate"); local scroll=f.blessingScroll
  scroll:SetOrientation("VERTICAL"); scroll:SetSize(16,128); scroll:SetPoint("TOPLEFT",642,-28); scroll:SetMinMaxValues(0,1); scroll:SetValueStep(1)
  if scroll.SetObeyStepOnDrag then scroll:SetObeyStepOnDrag(true) end
  if scroll.Text then scroll.Text:Hide() end; if scroll.Low then scroll.Low:Hide() end; if scroll.High then scroll.High:Hide() end
  scroll:SetScript("OnValueChanged",function(self,value)
    if self.silent then return end
    f.blessingPlayerOffset=math.floor(value+0.5); B:Options()
  end)
  button(detail,L("Done"),548,-228,98,function() f.expandedBlessing=nil; B:Options() end)
  line(p,-505)
  f.blessingFooter=label(p,"",18,-604,"GameFontDisableSmall",686)
  f.followBuffSettings=button(p,"Use Buffs settings",18,-574,164,function()
    if A.Combat() then return end
    B:GroupEditorSettings().blessingAssignments=false; f.expandedBlessing=nil; B:InvalidateAura(); B:RequestRefresh("follow Buffs settings",0); B:Options()
  end)
  addHelp(f.followBuffSettings,"Use Buffs settings","Stop explicit party and raid blessing assignments. Existing plans stay saved. Group blessings follow enabled Buffs, priorities and recipient filters instead.")
  f.blessingFilterButton=button(p,"Buffs recipient filters",190,-574,188,function() B:ToggleBlessingFilters() end)
  f.copyPartyBlessings=button(p,"Copy party assignments",500,-574,203,function()
    if B:CopyPartyBlessingsToRaid() then f.blessingScope=0; f.expandedBlessing=nil; B:Options() end
  end)

end
-- The fallback still honors older per-buff filters; keep those editable without
-- rebuilding the former assignment page or duplicating explicit class plans.
function B:ToggleBlessingFilters()
  if A.Combat() then return end
  local f=self.options; local p=f.blessingFilters
  if p then p:Sync(); p:SetShown(not p:IsShown()); f.activeSelector=p; return end
  p=CreateFrame("Frame","BuffTapBlessingFilters",f,"BackdropTemplate"); f.blessingFilters=p
  p:SetSize(620,338); p:SetPoint("CENTER"); p:SetFrameStrata("DIALOG"); p:SetFrameLevel(f:GetFrameLevel()+100)
  p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  p:SetBackdropColor(unpack(T.menu)); p:SetBackdropBorderColor(unpack(T.border)); p:EnableMouse(true); p:SetClampedToScreen(true)
  if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapBlessingFilters") end
  label(p,"Buffs recipient filters",18,-16,"GameFontNormalLarge")
  label(p,"Only affects blessings inherited from Buffs settings. Explicit assignments override these filters.",18,-43,"GameFontDisableSmall",580)
  p.key="bok"
  p.pick=selector(p,"",18,-77,365,function()
    local choices={}; for _,key in ipairs(B.BlessingFamilies) do choices[#choices+1]={key=key,name=blessingName(key)} end; return choices
  end,function(key) p.key=key; p:Sync() end)
  p.pick.ownerPanel=p
  p.icon=p:CreateTexture(nil,"ARTWORK"); p.icon:SetSize(24,24); p.icon:SetPoint("TOPLEFT",402,-78)
  p.groupHeading=label(p,"Recipient groups",18,-117,"GameFontNormal")
  p.groups={}; p.classes={}
  for i=1,8 do
    local group=i
    p.groups[i]=check(p,"G"..i,18+(i-1)*73,-137,function(c)
      if A.Combat() then return end
      local def=B:FindBuff(p.key); B:EnsureBuffGroups(def,B:EditingGroupContext())[group]=c:GetChecked()==true
      B:NormalizeBuffGroups(def,B:EditingGroupContext()); B:InvalidateAura(); B:RequestRefresh("blessing recipient group",0)
    end)
  end
  label(p,"Recipient classes",18,-181,"GameFontNormal")
  for i,class in ipairs(B.RecipientClasses) do
    local token=class
    p.classes[token]=check(p,(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token:sub(1,1)..token:sub(2):lower(),18+((i-1)%3)*195,-204-math.floor((i-1)/3)*25,function(c)
      if A.Combat() then return end
      B:GroupEditorSettings().buffClasses[p.key]=B:GroupEditorSettings().buffClasses[p.key] or {}; B:GroupEditorSettings().buffClasses[p.key][token]=c:GetChecked()==true
      B:InvalidateAura(); B:RequestRefresh("blessing recipient class",0)
    end)
  end
  p.Sync=function(self)
    local def=B:FindBuff(self.key); self.pick:SetText(blessingName(self.key)); self.icon:SetTexture(blessingIcon(self.key))
    local raid=B:EditingGroupContext()=="Raid"
    self.groupHeading:SetText(L(raid and "Raid groups" or "Party recipients"))
    for group,c in ipairs(self.groups) do c:SetShown(raid or group==1); c.Text:SetText(raid and "G"..group or L("Include party")); c:SetChecked(B:GroupSelected(def,group,B:EditingGroupContext())) end
    for class,c in pairs(self.classes) do c:SetChecked(B:GroupClassAllowed(def,class,B:EditingGroupContext())) end
  end
  button(p,"Reset this blessing",18,-296,170,function()
    if A.Combat() then return end
    B:GroupEditorSettings().buffGroups[p.key]=nil; B:GroupEditorSettings().buffClasses[p.key]=nil; p:Sync(); B:InvalidateAura(); B:RequestRefresh("reset blessing filters",0)
  end)
  button(p,"Done",480,-296,120,function() p:Hide(); B:Options() end)
  p:SetScript("OnHide",function() p.pick.menu:Hide() end)
  if f.activeSelector then f.activeSelector:Hide() end
  f.activeSelector=p; p:Sync(); p:Show()
end

function B:ClearAppearanceEdits()
  local f=self.options
  if not f then return end
  for _,slider in ipairs(f.refinedSliders or {}) do local e=slider.valueEdit; if e then e.unsaved=nil; e:ClearFocus() end end
  if f.accentHex then f.accentHex:ClearFocus() end
  for _,field in ipairs({"sizeEdit","opacityEdit","xEdit","yEdit"}) do
    local e=f[field]; if e then e.unsaved=nil; e:ClearFocus() end
  end
end

-- Bag and item-data events come in bursts: coalesce them, and don't rebuild under an open dropdown.
function B:RefreshInventoryWindows()
  if A.Combat() then return end
  self:StartTimer("inventory-windows",.3,function()
    if A.Combat() then return end
    local f=B.options
    if f and f:IsShown() and (f.activeTab==TAB.Consumables or f.activeTab==TAB.Weapons or f.activeTab==TAB.Diagnostics)
      and not (f.activeSelector and f.activeSelector:IsShown()) then B:Options() end
    if B.itemPicker and B.itemPicker:IsShown() then B:UpdateConsumablePicker() end
  end)
end

function B:UpdateGroupRosterOptions()
  local f=self.options
  if A.Combat() or not f or not f:IsShown() or f.activeTab~=TAB.Groups then return end
  self:UpdateBlessingOptions()
end

local function updateBlessingPlayers(self,f,entries,title,editable)
  if #entries==0 then return end
      local maxOffset=math.max(0,#entries-5); local offset=math.max(0,math.min(f.blessingPlayerOffset or 0,maxOffset)); f.blessingPlayerOffset=offset; f.blessingPlayerMaxOffset=maxOffset
      f.blessingDetail:ClearAllPoints(); f.blessingDetail:SetPoint("TOPLEFT",36,-242); f.blessingDetail:Show(); f.blessingDetailTitle:SetText(L("Player exceptions")..": "..title)
      for i,r in ipairs(f.blessingPlayerRows) do
        local entry=entries[offset+i]
        if entry then
          r.entry=entry; r.guid=A.Call(UnitGUID,entry.unit); r.name:SetText(A.Call(UnitName,entry.unit) or entry.unit)
          r.pick:Show(); r.pick:Update(); r.pick:SetAvailable(editable); r:Show()
        end
      end
      f.blessingPageText:SetText("Players "..(offset+1).."-"..math.min(offset+5,#entries).." / "..#entries.." - "..L("Player exceptions take precedence."))
      f.blessingScroll.silent=true; f.blessingScroll:SetMinMaxValues(0,math.max(1,maxOffset)); f.blessingScroll:SetValue(offset); f.blessingScroll:SetShown(maxOffset>0); f.blessingScroll.silent=false
      f.blessingDetail:SetHeight(262)
      for _,r in ipairs(f.blessingRoleRows or {}) do r.pick:Update(); r.pick:SetAvailable(editable) end
      f.blessingRoleGuess:SetChecked(self.db.roleGuess==true)

end
function B:UpdateBlessingOptions()
  local f=self.options; local class=A.Call(function() local _,token=UnitClass("player"); return token end); local paladin=class=="PALADIN"
  f.blessingPanel:SetShown(paladin); f.legacyGroups:SetShown(not paladin)
  if f.blessingMenu then f.blessingMenu:Hide() end
  if not paladin then return end
  self:EnsureBlessingPlans()
  local raid=f.blessingContext=="Raid"; local scope=raid and f.blessingScope or 0
  local plan=self:BlessingPlan(f.blessingContext,scope); local same=plan.mode=="same"
  local editable=self:GroupEditorSettings().blessingAssignments and not A.Combat()
  f.blessingTitle:SetText(L(raid and "Raid buffing" or "Party buffing"))
  f.blessingIntro:SetText(L(not raid and self.db.blessingPartyExcluded and "Party excluded by your previous setup. Enable party / raid here to include it." or not self:GroupEditorSettings().blessingAssignments and "Using Buffs settings. Choose a mode below to set group assignments." or raid and "Set raid defaults, then customize individual groups where needed." or "Set blessings by class for a five-player party. You can prepare this while solo."))
  for _,pair in ipairs({{f.partyView,not raid},{f.raidView,raid},{f.blessingByClass,not same and self:GroupEditorSettings().blessingAssignments},{f.blessingSame,same and self:GroupEditorSettings().blessingAssignments}}) do
    pair[1]:SetBackdropColor(pair[2] and .20 or .075,pair[2] and .18 or .095,pair[2] and .08 or .11,1)
  end
  f.blessingGroupEnable.Text:SetText(L(raid and "Enable raid buffing" or "Enable party buffing"))
  f.blessingGroupEnable:SetChecked(self:GroupEditorSettings().group and (raid or not self.db.blessingPartyExcluded)); f.blessingSmart:SetChecked(self:GroupEditorSettings().smartGroup)
  f.blessingThreshold.silent=true; f.blessingThreshold:SetValue(self:GroupEditorSettings().blessingNeed); f.blessingThreshold.valueText:SetText(self:GroupEditorSettings().blessingNeed.."+"); f.blessingThreshold.silent=false
  local roster=self:Roster(); local active=self:BlessingAssignmentsActive(); self.blessingClassList=self:ClassList()
  for i,c in ipairs(f.blessingScopeButtons) do
    local group=i-1; c:SetShown(raid)
    local selected=scope==group
    c:SetBackdropColor(selected and .20 or .075,selected and .18 or .095,selected and .08 or .11,1)
    if group>0 then
      local excluded=not self:GroupEditorSettings().raidGroups[group]; local effective=self:BlessingPlan("Raid",group)
      c:SetText((excluded and "X " or "").."G"..group)
      c:SetAlpha(excluded and .55 or 1)
      local summary=effective.mode=="same" and blessingName(effective.blessing) or L("By class")
      c.note:SetText(excluded and L("Not buffing") or summary..(not self.db.blessingGroupOverrides[group] and " - "..L("default") or ""))
      local keys,seen={},{}
      if effective.mode=="same" then keys[1]=effective.blessing
      else for _,token in ipairs(self.RecipientClasses) do
        local choice,order=self:GroupBlessingSettings(token,group,true,"Raid")
        if not choice then order=groupDefaultOrder(token,group); choice="priority" end
        local values=choice=="priority" and (order or {}) or {choice}
        for _,key in ipairs(values) do if key~="skip" and not seen[key] and #keys<4 then keys[#keys+1]=key; seen[key]=true end end
      end end
      for j,icon in ipairs(c.icons) do icon:SetShown(not excluded and keys[j]~=nil); if keys[j] then icon:SetTexture(blessingIcon(keys[j])) end end
      addHelp(c,"Raid group "..group,excluded and "Not buffing this group. Its assignments remain saved." or summary..". "..(self.db.blessingGroupOverrides[group] and "Custom group assignments." or "Inherited from raid defaults.").." Click to inspect or edit.")
    end
  end
  f.blessingSelected:SetShown(raid and scope>0); f.blessingSelected:SetChecked(scope>0 and self:GroupEditorSettings().raidGroups[scope] or false)
  f.blessingInherit:SetShown(raid and scope>0 and self.db.blessingGroupOverrides[scope]~=nil)
  f.copyPartyBlessings:SetShown(raid)
  local modeY=raid and -208 or -111
  f.blessingAssignmentTitle:ClearAllPoints(); f.blessingAssignmentTitle:SetPoint("TOPLEFT",18,modeY-5)
  f.blessingAssignmentTitle:SetText(L(raid and (scope>0 and "Group "..scope or "Raid defaults") or "Party blessings"))
  f.blessingByClass:ClearAllPoints(); f.blessingByClass:SetPoint("TOPLEFT",280,modeY)
  f.blessingSame:ClearAllPoints(); f.blessingSame:SetPoint("TOPLEFT",408,modeY)
  local headerY=modeY-39; local y=headerY-20
  for _,h in ipairs(f.blessingHeaders) do h:Hide() end
  if not same then
    for i,h in ipairs(f.blessingHeaders) do h:ClearAllPoints(); h:SetPoint("TOPLEFT",({24,224,546})[i],headerY); h:Show() end
  end
  f.blessingUniform:SetShown(same); f.blessingUniformLabel:SetShown(same); f.blessingUniformHelp:SetShown(same)
  f.blessingUniform:ClearAllPoints(); f.blessingUniform:SetPoint("TOPLEFT",236,modeY-54); f.blessingUniform:Update(); f.blessingUniform:SetAvailable(not A.Combat())
  f.blessingUniformLabel:ClearAllPoints(); f.blessingUniformLabel:SetPoint("TOPLEFT",24,modeY-61)
  f.blessingUniformHelp:ClearAllPoints(); f.blessingUniformHelp:SetPoint("TOPLEFT",24,modeY-98)
  f.blessingUniformHelp:SetText(L("This blessing applies to everyone. Saved class and player choices are inactive in this mode."))
  f.followBuffSettings:SetShown(self:GroupEditorSettings().blessingAssignments)
  f.blessingFilterButton:SetShown(not same or not self:GroupEditorSettings().blessingAssignments)
  f.blessingFilterButton:ClearAllPoints(); f.blessingFilterButton:SetPoint("TOPLEFT",self:GroupEditorSettings().blessingAssignments and 190 or 18,-574)
  if f.blessingFilters then f.blessingFilters:Sync() end
  local mixed=false
  if active and self:GroupEditorSettings().smartGroup and f.blessingContext==self:BlessingContext() then
    for _,entry in ipairs(roster) do
      local key=self:BlessingChoice(entry)
      if key and key~="skip" and not self:BlessingGreaterSafe(key,entry.class,roster) then mixed=true; break end
    end
  end
  f.blessingFooter:SetText(L(mixed and "Individual blessings: same-class assignments differ or include an excluded player." or same and "Switch to By class to use your saved class and player assignments." or "Player exceptions override class choices. Party and raid plans are separate."))
  if same then f.expandedBlessing=nil end
  f.updatingBlessingDetail=true; f.blessingDetail:Hide()
  for _,r in ipairs(f.blessingPlayerRows) do r:Hide(); r.entry=nil; r.guid=nil end
  for _,row in ipairs(f.blessingRows) do
    row:SetShown(not same); row:ClearAllPoints(); row:SetPoint("TOPLEFT",18,y); row.pick:Update()
    row.pick:SetAvailable(editable)
    local entries={}; for _,entry in ipairs(roster) do if entry.class==row.class and f.blessingContext==self:BlessingContext() and (not raid or scope==0 or entry.group==scope) then entries[#entries+1]=entry end end
    local exceptions=0
    for _,entry in ipairs(entries) do local value=self:GetBlessingPlayer(A.Call(UnitGUID,entry.unit),f.blessingContext); if value and value.choice then exceptions=exceptions+1 end end
    row.players:SetText(exceptions>0 and L(exceptions==1 and "%d exception" or "%d exceptions",exceptions) or L("Players"))
    row.players:SetBackdropColor(exceptions>0 and .16 or 0,exceptions>0 and .14 or 0,exceptions>0 and .06 or 0,exceptions>0 and 1 or 0)
    row.players:SetEnabled(#entries>0 and not A.Combat()); row.players:SetAlpha(#entries>0 and 1 or 0.4)
    T.Glyph(row.players.arrow,f.expandedBlessing==row.class and "up" or "down",12)
    local chosen=self:GroupBlessingSettings(row.class,scope,true,f.blessingContext); local status="Current settings"
    if self:GroupEditorSettings().blessingAssignments then
      status=#entries==0 and "No group players" or "Individual"
      if not active then status="Party / raid inactive"
      elseif chosen=="skip" then status="Skipped"
      elseif #entries>0 then
        local first=self:BlessingChoice(entries[1]); local def=self:FindBuff(first)
        if first=="skip" then status="Skipped / excluded"
        elseif not def or not self:Resolve(def,entries[1].unit) then status="Not learned / target level"
        elseif not self:BlessingGreaterSafe(first,row.class,roster) then status="Individual: mixed / excluded"
        elseif not self:GroupEditorSettings().smartGroup then status="Individual: Greater off"
        elseif #entries>=self:BlessingGroupNeed(self:FindBuff(def.groupKey)) then status="|cff88dd88Greater allowed|r"
        else status="Individual: below threshold" end
      end
    end
    addHelp(row.players,"Player exceptions",L(status).."\n"..L("Click to expand or collapse individual player choices.")); y=y-26
    if f.expandedBlessing==row.class then f.blessingDetailClass=row.class; updateBlessingPlayers(self,f,entries,L(row.class:sub(1,1)..row.class:sub(2):lower()),editable) end
  end
  f.updatingBlessingDetail=false
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
    row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(unpack(T.row)); T.Row(row,8)
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

function B:CaptureBinding(target)
  if A.Combat() then return end
  if not self.capture then
    local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); self.capture=f
    f:SetAllPoints(); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:EnableKeyboard(true); f:EnableMouse(true); f:EnableMouseWheel(true); f:SetPropagateKeyboardInput(false)
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.01,0.02,0.04,0.90)
    local logo=f:CreateTexture(nil,"ARTWORK"); logo:SetSize(88,88); logo:SetPoint("CENTER",0,78); logo:SetTexture(ICON_PATH)
    local hint=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); hint:SetPoint("CENTER",0,-8); hint:SetJustifyH("CENTER")
    hint:SetText(L("Set BuffTap binding").."\n\n"..L("Press a key, middle/side mouse button, or scroll wheel").."\n"..L("Left/right click requires Shift, Ctrl, or Alt").."\n|cff8aa5b8"..L("Escape cancels").."|r")
    f.hint=hint; f.hintRest=(hint:GetText() or ""):match("^[^\n]*(.*)$") or ""
    local function bind(key)
      if A.Combat() then f:Hide(); return end
      if IsShiftKeyDown() then key="SHIFT-"..key end
      if IsControlKeyDown() then key="CTRL-"..key end
      if IsAltKeyDown() then key="ALT-"..key end
      local keys=B:NormalizeBindings({key})
      if #keys==0 then return end
      -- One key cannot drive both buttons: the newest choice wins and is removed from the other list.
      local other=f.target=="nearby" and B.db.keys or B.db.nearbyKeys or {}
      for i=#other,1,-1 do if other[i]==keys[1] then table.remove(other,i) end end
      if f.target=="nearby" then B.db.nearbyKeys=keys else B.db.keys=keys end
      -- Either list may have changed: rebind the Nearby key now so one key never drives both buttons.
      if B.nearbyFrame then B:UpdateNearbyWindow() end
      if B.ApplyNearbyBinding then B:ApplyNearbyBinding() end
      f:Hide(); B.appearance=nil; B:RequestRefresh("binding",0); B:Status(false)
      if B.options and B.options:IsShown() then B:Options() end
      if B.onboarding and B.onboarding:IsShown() and B.OnboardingFeaturesPage then B:OnboardingFeaturesPage() end
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
  self.capture.target=target
  self.capture:Show()
end

local function logicalBuffs()
  local out={}
  for _,b in ipairs(B:ClassList(B:EditorSettings("buffs"))) do
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
  for i,def in ipairs(list) do self:EditorSettings("buffs").priorities[def.key]=i end
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

-- The family's own item icon when nothing usable is carried, instead of a question mark.
local function familyIcon(family)
  for _,item in ipairs(family.items or {}) do
    local info=B.ConsumableItemInfo and B:ConsumableItemInfo(item.id,item)
    local icon=info and info.texture or item.icon
    if icon and icon~=134400 then return icon end
  end
  return 134400
end
local function consumableChoiceLabel(family,settings)
  settings=settings or B:EditorSettings("consumables")
  local id=B.ConsumableChoiceID and B:ConsumableChoiceID(family,settings)
  if not id then
    if family.explicitChoice then return L("Choose an item"),familyIcon(family) end
    local item=B.PreferredConsumableItem and B:PreferredConsumableItem(family,settings)
    if item then
      local info=B.ConsumableItemInfo and B:ConsumableItemInfo(item.id,item)
      local name=(info and info.name) or item.name or ("Item "..tostring(item.id))
      return L("Auto: %s",name), (info and info.texture or item.icon or 134400)
    end
    return L("Auto (none in bags)"),familyIcon(family)
  end
  for _,item in ipairs(family.items or {}) do
    if item.id==id then
      local info=B.ConsumableItemInfo and B:ConsumableItemInfo(id,item)
      return (info and info.name or item.name), (info and info.texture or item.icon or 134400)
    end
  end
  return L("Auto (none in bags)"),familyIcon(family)
end

-- Helpers share the main window and tab lifecycle. Compact descriptions keep
-- the separated sections visible together; detailed help stays in tooltips.
function B:BuildHelperPage(parent)
  local f=panel(parent); parent.pages[TAB.Helpers]=f; self.helperWindow=f
  label(f,L("Everyday conveniences"),18,-16,"GameFontNormalLarge")
  label(f,L("Optional conveniences, separate from your buff choices. PvP protection starts on."),18,-43,"GameFontDisableSmall",680)
  f.checks={}; f.descriptions={}; f.trackers={}
  -- Fixed layout, no scrolling. Row A: Solo thanks (left) and Conveniences (right). Row B: Buff requests.
  -- Row C: Tracking. Class readiness fills the space below for Warlocks, Hunters and Paladins.
  -- Longer explanations live in each control's tooltip so everything fits on one page.
  local function section() local s=CreateFrame("Frame",nil,f); s:SetPoint("TOPLEFT",0,0); s:SetSize(712,1); return s end
  local th,gr,tr,q=section(),section(),section(),section()
  f.helperSections={thanks=th,grid=gr,tracking=tr,requests=q}
  local settings={
    {"helperDismiss",L("Dismiss a reminder for now"),L("Right-click a buff or item reminder to skip it until you change zones. Restore reminders above brings it back sooner.")},
    {"helperBounce",L("Stop repeated stronger-buff errors"),L("If your BuffTap click fails because a stronger buff is active, hide that reminder until a zone change or manual restore.")},
    {"helperQuick",L("Choose consumables from the icon"),L("Hover a food, flask or elixir reminder to pick another supported item in your bags. Click the main icon to use your choice.")},
    {"helperCoverage",L("Show missing party buffs"),L("Shows buffs your five-player party may be missing and who might provide them. Information only: no casting or chat messages.")},
    {"helperDiscovery",L("Find unrecognized consumables"),L("Lists bag consumables missing from BuffTap's supported list for review. It does not add or use them. View the report in Diagnostics.")},
  }
  card(gr,364,-74,340,252)
  T.SectionTitle(label(gr,L("Conveniences"),380,-88,T.fonts.Section))
  for i,spec in ipairs(settings) do
    local key=spec[1]
    f.checks[key]=check(gr,spec[2],378,-108-(i-1)*25,function(c)
      if A.Combat() then return end
      B.db[key]=c:GetChecked()==true
      if key=="helperDiscovery" then B.helperDiscoverDirty=true end
      if key=="helperDismiss" or key=="helperBounce" then B:RestoreHelpers() end
      B:RequestRefresh("helper setting",0); B:Options()
    end)
    addHelp(f.checks[key],spec[2],spec[3])
  end
  label(gr,L("Dismiss lasts"),380,-292,"GameFontHighlightSmall",130)
  f.dismissMinutes=selector(gr,"",520,-286,170,function() return B:DismissChoices() end,function(v) B.db.helperDismissMinutes=v; B:Options() end)
  addHelp(f.dismissMinutes,L("Dismiss a reminder for now"),L("How long a right-click dismiss lasts. Restore reminders brings everything back sooner."))
  parent.pauseResting=check(gr,"Pause reminders while resting",378,-233,function(c)
    if A.Combat() then return end
    setAndRefresh("pauseResting",c:GetChecked()==true); B:InvalidateSupplies(false); B:Refresh(false); B:Options()
  end)
  addHelp(parent.pauseResting,"Pause reminders while resting","Hide buff reminders and quiet automatic stock alerts in cities and inns. Settings remain accessible.")
  parent.pvpProtection=check(gr,"Prevent accidental PvP flagging",378,-258,function(c)
    if A.Combat() then return end
    setAndRefresh("pvpProtection",c:GetChecked()==true); B:Refresh(false); B:Options()
  end)
  addHelp(parent.pvpProtection,"Prevent accidental PvP flagging","Skip flagged or unreadable recipients while unflagged or leaving PvP. Includes group spells. Battlegrounds and arenas are exempt.")
  card(th,12,-74,340,252)
  T.SectionTitle(label(th,L("Solo thanks"),28,-88,T.fonts.Section))
  label(th,L("Say thanks when another player buffs you while you play solo."),28,-108,T.fonts.Sub,308)
  f.checks.helperThanks=check(th,L("Thank players who buff me solo"),28,-150,function(c)
    if A.Combat() then return end
    B.db.helperThanks=c:GetChecked()==true; B.helperThankSeen=nil; B:ObserveSoloThanks(true)
    B:RequestRefresh("solo thanks",0); B:Options()
  end)
  addHelp(f.checks.helperThanks,L("Solo thanks"),L("Thanks identified solo buff providers. Never in groups, instances or combat. Emotes are spaced one second apart, with a one-minute cooldown per player."))
  f.thanksResting=check(th,L("Keep thanking while resting"),28,-176,function(c)
    if A.Combat() then return end
    B.db.helperThanksResting=c:GetChecked()==true; B.helperThankSeen=nil; B:ObserveSoloThanks(true); B:Options()
  end)
  addHelp(f.thanksResting,L("Keep thanking while resting"),L("Thanks continue in cities and inns even when Pause reminders while resting is on."))
  label(th,L("Solo response emote"),30,-246,"GameFontNormal",200)
  label(th,L("Delay"),240,-246,"GameFontNormal",98)
  f.thankDelay=selector(th,"",238,-266,100,function() return B:ThankDelayChoices() end,function(v) B.db.helperThankDelay=v; B:Options() end)
  addHelp(f.thankDelay,L("Delay"),L("Wait a moment before thanking, so it feels less automatic."))
  f.thankEmote=selector(th,"",28,-266,202,function() return B:SoloThankEmotes() end,function(choice)
    B.db.helperThankEmote=choice
    -- Configuration only: never sends an emote or resets cooldowns.
  end,"scroll")
  addHelp(f.thankEmote,L("Solo response emote"),L("Directed reactions only. No sitting, sleeping or looping animations. Changing this never sends an emote."))
  -- Class readiness keeps its authored coordinates; the frame is moved up as one block below Tracking.
  f.readiness=CreateFrame("Frame",nil,f); f.readiness:SetSize(712,1); f.readiness:SetPoint("TOPLEFT",0,-216)
  -- The top two cards are 40 px taller than before; the sections below move down with them.
  q:ClearAllPoints(); q:SetPoint("TOPLEFT",0,-40); tr:ClearAllPoints(); tr:SetPoint("TOPLEFT",0,-40)
  -- Buff requests (Nearby): whisper a nearby player for a class buff you are missing. Off by default.
  f.requests=q
  card(q,12,-298,692,148)
  T.SectionTitle(label(q,L("Buff requests"),28,-312,T.fonts.Section))
  f.requestEnable=check(q,L("Offer buff requests in Nearby"),28,-332,function(c)
    if A.Combat() then return end
    B.db.nearbyRequests=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyWindow() end; B:Options()
  end)
  addHelp(f.requestEnable,L("Offer buff requests in Nearby"),L("When a player outside your group can cast a class buff you are missing, Nearby shows a button with that buff's icon. Clicking it whispers your request. Nothing is sent automatically.").."\n"..L("Each request is one whisper you click to send. You can ask the same player again after three minutes."))
  label(q,L("Message"),330,-337,"GameFontHighlightSmall",64)
  f.requestMessage=editbox(q,396,-331,294,false); f.requestMessage:SetFontObject(T.fonts.Small); f.requestMessage:SetJustifyH("LEFT"); f.requestMessage:SetMaxLetters(200)
  f.requestMessage:SetScript("OnEnterPressed",function(s)
    local text=(s:GetText() or ""):gsub("[|%c]","")
    B.db.requestMessage=(text==B:Text("Hi! Could I get %s, please? Thank you!")) and "" or text; s:ClearFocus(); B:Options()
  end)
  f.requestMessage:SetScript("OnEscapePressed",function(s) s:ClearFocus(); B:Options() end)
  addHelp(f.requestMessage,L("Message"),L("%s is replaced with the buff names. Clear the box and press Enter to restore the default."))
  f.requestChecks={}
  for i,def in ipairs(B:CoverageDefinitions()) do
    local key=def.key
    local c=check(q,def.name,28+((i-1)%3)*228,-362-math.floor((i-1)/3)*26,function(s) if not A.Combat() then B.db.requestBuffs[key]=s:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyWindow() end end end)
    f.requestChecks[key]=c
  end
  local r=f.readiness
  card(r,12,-374,692,144)
  line(r,-369)
  f.readinessIcon=r:CreateTexture(nil,"ARTWORK")
  f.readinessIcon:SetSize(24,24); f.readinessIcon:SetPoint("TOPLEFT",18,-378)
  f.readinessIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
  T.SectionTitle(label(r,L("Class readiness"),52,-386,T.fonts.Section))
  f.oathCheck=check(r,L("Maintain assigned Oath"),18,-414,function(c)
    if A.Combat() then return end
    B.db.helperOath=c:GetChecked()==true; B:SyncReadiness(); B:RequestRefresh("Oath helper",0); B:Options()
  end)
  f.oathDescription=label(r,L("Oath of Light: one assigned recipient, out of combat. Assign yourself or a party/raid member below."),22,-442,"GameFontDisableSmall",650)
  f.oathAssigned=label(r,"",22,-482,"GameFontHighlightSmall",320)
  f.oathAssign=button(r,L("Use current target"),364,-474,190,function()
    if A.Combat() then return end
    local ok=B:SetOathAssignedFromTarget()
    f.oathFeedback:SetText(L(ok and "Assignment saved." or "Select a friendly player first.")); B:Options()
  end)
  f.oathClear=button(r,L("Clear"),568,-474,110,function()
    if A.Combat() then return end
    B.db.oathAssigned={}; B.readinessPending=nil; B:InvalidateAura(); B:RequestRefresh("Oath assignment cleared",0); B:Options()
  end)
  f.oathFeedback=label(r,"",22,-505,"GameFontDisableSmall",650)
  addHelp(f.oathCheck,L("Maintain assigned Oath"),L("Maintains Oath of Light on exactly one saved player. No automatic tank or healer choice. Existing Oaths from other paladins are preserved. Each cast requires your binding or click."))
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
  sm:SetBackdropColor(unpack(T.menu)); sm:SetBackdropBorderColor(unpack(T.border)); T.Surface(sm,"menu"); sm:Hide()
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
  menu:SetBackdropColor(.04,.04,.04,1); T.Surface(menu,"menu"); menu.rows={}; menu:Hide()
  f:SetScript("OnHide",function() menu:Hide(); f.soulMenu:Hide() end)
  f.trackerCard=card(tr,12,-516,692,82)
  f.trackerLine=line(tr,-516)
  f.trackerHeading=label(tr,L("Tracking"),18,-529,T.fonts.Section)
  f.checks.helperTracking=check(tr,L("Remind me to enable tracking"),18,-557,function(c)
    if A.Combat() then return end
    B.db.helperTracking=c:GetChecked()==true; B:RequestRefresh("tracking reminder",0); B:Options()
  end)
  addHelp(f.checks.helperTracking,L("Remind me to enable tracking"),L("Choose Herbs, Minerals or Fish below. When that tracker is off, BuffTap offers a one-tap reminder to turn it on."))
  f.treasure=check(tr,L("Keep Find Treasure active"),490,-529,function(c)
    if A.Combat() then return end
    B.db.helperTreasure=c:GetChecked()==true; B:RequestRefresh("treasure tracking",0); B:Options()
  end)
  addHelp(f.treasure,L("Keep Find Treasure active"),L("Restore Dwarf treasure tracking through your normal binding. Independent of your gathering tracker."))
  f.emptyTracker=label(tr,L("No learned gathering tracker is available on this character."),254,-565,"GameFontDisableSmall",440)
  -- Page actions sit in the header, beside the description, so the body never needs to scroll.
  f.restoreButton=button(f,L("Restore reminders"),402,-38,146,function() B:RestoreHelpers(); B:Options() end)
  f.reportButton=button(f,L("View discovery report"),556,-38,148,function() B:ShowDiscoveryReport() end)
  f.restoreButton:SetHeight(24); f.reportButton:SetHeight(24)
end

function B:UpdateHelperOptions()
  local f=self.helperWindow; if not f then return end
  local class=self:ReadinessClass(); local warlock=class=="WARLOCK"; local paladin=class=="PALADIN"
  f.readiness:SetShown(warlock or class=="HUNTER" or paladin); f.demonMenu:Hide()
  f.requestEnable:SetChecked(self.db.nearbyRequests==true)
  if not f.requestMessage:HasFocus() then f.requestMessage:SetText(self.db.requestMessage~="" and self.db.requestMessage or self:Text("Hi! Could I get %s, please? Thank you!")) end
  for key,c in pairs(f.requestChecks) do c:SetChecked(self:RequestEnabled(self:FindBuff(key) or {key=key})); c:SetEnabled(self.db.nearbyRequests==true) end
  f.thanksResting:SetChecked(self.db.helperThanksResting==true)
  f.thankDelay:SetText(self:ChoiceName(self:ThankDelayChoices(),self.db.helperThankDelay or 0))
  f.dismissMinutes:SetText(self:ChoiceName(self:DismissChoices(),self.db.helperDismissMinutes or 0)); f.dismissMinutes:SetEnabled(self.db.helperDismiss==true)
  local classCoords=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    or (warlock and {.75,1,.25,.5} or paladin and {0,.25,.5,.75} or class=="HUNTER" and {0,.25,.25,.5})
  if classCoords then f.readinessIcon:SetTexCoord(unpack(classCoords)) end
  f.petCheck:SetShown(not paladin); f.petDescription:SetShown(not paladin)
  for _,control in ipairs({f.oathCheck,f.oathDescription,f.oathAssigned,f.oathAssign,f.oathClear,f.oathFeedback}) do control:SetShown(paladin) end
  f.oathCheck:SetChecked(self.db.helperOath==true)
  local oath=self.db.oathAssigned
  f.oathAssigned:SetText(L("Assigned player: ")..(type(oath)=="table" and oath.name or L("none")))
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
  f.demonChoice:SetText(chosen and ("    "..chosen.name) or L(#demons>0 and "Choose preferred demon" or "No learned summon available"))
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
  f.trackerHeading:SetText(L("Tracking")); T.SectionTitle(f.trackerHeading)
  f.treasure:SetShown(A.Known(2481)); f.treasure:SetChecked(self:HelperEnabled("helperTreasure"))
  local trackerY=-468
  f.trackerCard:ClearAllPoints(); f.trackerCard:SetPoint("TOPLEFT",12,trackerY+10)
  f.trackerLine:Hide()
  f.treasure:ClearAllPoints(); f.treasure:SetPoint("TOPLEFT",490,trackerY+2)
  f.trackerLine:ClearAllPoints(); f.trackerLine:SetPoint("TOPLEFT",18,trackerY+13); f.trackerLine:SetPoint("TOPRIGHT",-18,trackerY+13)
  f.trackerHeading:ClearAllPoints(); f.trackerHeading:SetPoint("TOPLEFT",26,trackerY-4)
  f.checks.helperTracking:ClearAllPoints(); f.checks.helperTracking:SetPoint("TOPLEFT",26,trackerY-28)
  f.emptyTracker:ClearAllPoints(); f.emptyTracker:SetPoint("TOPLEFT",254,trackerY-36)
  for i,entry in ipairs(trackers) do
    local t=f.trackers[i]
    if not t then
      t=flatButton(f.helperSections.tracking,"",254+(i-1)*148,trackerY-26,140,function(control)
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
  f.resizeDiscoveryReport(); f.discoveryScroll:SetVerticalScroll(0)
  f.diagText:Hide(); f.diagScroll:Hide(); f.discoveryScroll:Show()
end

function B:ShowQuickChoices(action,page)
  if A.Combat() or not self:HelperEnabled("helperQuick") or not action or action.source~="consumable" then return end
  local family=self:ConsumableFamily(action.familyKey)
  if not family then return end
  local f=self.quickChoices
  if not f then
    f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); self.quickChoices=f
    f:SetSize(300,244); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetClampedToScreen(true); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12}); f:SetBackdropColor(unpack(T.menu))
    label(f,"Choose, then use the main icon",12,-12,"GameFontNormalSmall")
    f.rows={}
    for i=1,6 do
      local row=flatButton(f,"",12,-34-(i-1)*28,274,function(s)
        if A.Combat() or not s.itemID then return end
        if f.situation then B:SetSituationValue(f.situation,"consumables","consumableChoices",s.itemID,f.family.key)
        else B:SetConsumableChoice(f.family,s.itemID) end
        f:Hide(); B:RequestRefresh("quick item choice",0)
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",2,0)
      row.itemName=label(row,"",30,-5,"GameFontHighlightSmall",202); row.itemName:SetWordWrap(false)
      row.stock=label(row,"",236,-5,"GameFontHighlightSmall",34)
      f.rows[i]=row
    end
    button(f,"<",12,-210,34,function() B:ShowQuickChoices(B.action,(f.page or 1)-1) end)
    button(f,">",52,-210,34,function() B:ShowQuickChoices(B.action,(f.page or 1)+1) end)
    button(f,"All items",92,-210,92,function() f:Hide(); B:ChooseConsumable(f.family,nil,f.situation) end)
    button(f,L("Close"),192,-210,94,function() f:Hide() end)
  end
  local choices={}
  for _,item in ipairs(family.items or {}) do if self:ConsumableCount(item.id)>0 then choices[#choices+1]=item end end
  if #choices==0 then f:Hide(); return end
  f.family=family; f.situation=self:SituationValues(self.situationCurrent,"consumables") and self.situationCurrent or nil
  f.page=math.max(1,math.min(page or 1,math.ceil(#choices/6)))
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
function B:ChooseConsumable(family,anchor,situation)
  if A.Combat() then return end
  local f=self.itemPicker
  if not f then
    f=CreateFrame("Frame","BuffTapItemPicker",self.options,"BackdropTemplate"); self.itemPicker=f
    f:SetSize(650,550); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetClampedToScreen(true); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(unpack(T.window)); f:SetBackdropBorderColor(unpack(T.border))
    f.title=label(f,"Choose item",20,-18,"GameFontNormalLarge")
    button(f,L("Close"),550,-14,78,function() f:Hide() end)
    label(f,L("Search"),20,-59,"GameFontHighlightSmall")
    f.search=editbox(f,76,-54,300,false)
    f.bags=check(f,L("In bags only"),410,-54,function() f.offset=0; B:UpdateConsumablePicker() end)
    f.auto=flatButton(f,"",20,-90,606,function()
      if A.Combat() then return end
      if f.situation then B:SetSituationValue(f.situation,"consumables","consumableChoices",nil,f.family.key) else B:SetConsumableChoice(f.family,nil); B:InvalidateConsumables(); B:RequestRefresh("auto selected",0) end; B:Options(); B:UpdateConsumablePicker()
    end)
    label(f,L("Item"),66,-127,"GameFontNormalSmall"); label(f,L("In bags"),518,-127,"GameFontNormalSmall")
    f.rows={}
    for i=1,8 do
      local row=flatButton(f,"",20,-147-(i-1)*34,580,function(btn)
        if A.Combat() then return end
        if f.situation then B:SetSituationValue(f.situation,"consumables","consumableChoices",btn.itemID,f.family.key) else B:SetConsumableChoice(f.family,btn.itemID); B:InvalidateConsumables(); B:RequestRefresh("item selected",0) end
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
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:SetScript("OnEvent",function(_,event)
      if event=="PLAYER_REGEN_DISABLED" then f:Hide()
      end
    end)
    if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapItemPicker") end
  end
  f:ClearAllPoints(); f:SetPoint("CENTER",self.options,"CENTER")
  f.family=family; f.situation=situation; f.offset=0; f.bags:SetChecked(true); f.search:SetText("")
  self:UpdateConsumablePicker(); f:Show()
end

function B:UpdateConsumablePicker()
  local f=self.itemPicker
  if not f or not f.family or A.Combat() then return end
  local family=f.family; local list={}; local query=(f.search:GetText() or ""):lower()
  local selected=self:ConsumableChoiceID(family,f.situation and self:SituationPreview(f.situation,"consumables") or self.db)
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
  f.title:SetText(L("Choose %s",L(family.name))..(f.situation and " - "..L(({solo="Solo",party="Party",raid="Raid"})[f.situation]) or ""))
  f.auto:SetShown(not family.explicitChoice)
  f.auto:SetText((not selected and "(o) " or "( ) ")..L("Auto - first usable supported item"))
  for i,row in ipairs(f.rows) do
    local item=list[f.offset+i]
    if item then
      row.itemID=item.id; row.mark:SetText(selected==item.id and "(o)" or "( )")
      local info=self.ConsumableItemInfo and self:ConsumableItemInfo(item.id,item)
      row.name:SetText((info and info.name) or item.name); row.stock:SetText(item.count>0 and ("|cff88dd88"..item.count.."|r") or ("|cffffc466"..L("Out of stock").."|r"))
      row.icon:SetTexture((info and info.texture) or item.icon or 134400)
      row:SetBackdropColor(selected==item.id and 0.16 or 0.065,selected==item.id and 0.15 or 0.085,selected==item.id and 0.09 or 0.10,1)
      addHelp(row,item.name,item.note or "Supported item; availability is checked again before use."); row:Show()
    else row.itemID=nil; row:Hide() end
  end
  local choice=consumableChoiceLabel(family,f.situation and self:SituationPreview(f.situation,"consumables") or self.db)
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
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    -- Window shell: rounded body with a soft shadow. Header (0-120), sidebar (196 px), pages, footer (last 32 px).
    T.Round(f,10,"surface"); f:SetBackdropColor(unpack(T.window)); f:SetBackdropBorderColor(1,1,1,.12); T.Shadow(f,30,.7)
    f.headerGlow=f:CreateTexture(nil,"BACKGROUND",nil,-5); f.headerGlow:SetTexture(T.media.."UIGradient"); f.headerGlow:SetVertexColor(1,1,1,0) -- off: its 10 px side insets showed as faint vertical seams; the keyed banner needs a flat header
    f.headerGlow:SetPoint("TOPLEFT",10,-1); f.headerGlow:SetPoint("TOPRIGHT",-10,-1); f.headerGlow:SetHeight(119)
    f.headerRule=f:CreateTexture(nil,"BORDER"); f.headerRule:SetColorTexture(unpack(T.rule)); f.headerRule:SetPoint("TOPLEFT",1,-120); f.headerRule:SetPoint("TOPRIGHT",-1,-120); f.headerRule:SetHeight(1)
    f.sidebarFill=f:CreateTexture(nil,"BACKGROUND",nil,-5); f.sidebarFill:SetColorTexture(unpack(T.sidebar)); f.sidebarFill:SetPoint("TOPLEFT",1,-121); f.sidebarFill:SetPoint("BOTTOMLEFT",1,33); f.sidebarFill:SetWidth(195)
    f.sidebarRule=f:CreateTexture(nil,"BORDER"); f.sidebarRule:SetColorTexture(unpack(T.rule)); f.sidebarRule:SetPoint("TOPLEFT",196,-121); f.sidebarRule:SetPoint("BOTTOMLEFT",196,33); f.sidebarRule:SetWidth(1)
    f.footerRule=f:CreateTexture(nil,"BORDER"); f.footerRule:SetColorTexture(unpack(T.rule)); f.footerRule:SetPoint("BOTTOMLEFT",1,32); f.footerRule:SetPoint("BOTTOMRIGHT",-1,32); f.footerRule:SetHeight(1)
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapOptions") end

    -- The full BuffTap banner artwork, sized to the header.
    f.banner=B:AddMiniBanner(f,OPTIONS_WIDTH)
    f.banner.background:SetColorTexture(0,0,0,0)
    f.banner:ClearAllPoints(); f.banner:SetPoint("TOPLEFT",8,-8); f.banner:SetSize(520,104)
    f.banner.art:ClearAllPoints(); f.banner.art:SetPoint("TOPLEFT",6,-2); f.banner.art:SetSize(486,486*420/2043)
    f.closeButton=flatButton(f,"",0,0,30,function() f:Hide() end)
    f.closeButton:SetSize(30,30); f.closeButton:ClearAllPoints(); f.closeButton:SetPoint("TOPRIGHT",-14,-14); T.Variant(f.closeButton,"danger")
    f.closeButton.glyph=f.closeButton:CreateTexture(nil,"ARTWORK"); f.closeButton.glyph:SetPoint("CENTER"); T.Glyph(f.closeButton.glyph,"close",16,.80,.82,.86)
    addHelp(f.closeButton,L("Close"),"")
    f.versionText=label(f,"v"..B.version,0,0,"GameFontDisableSmall",180)
    f.versionText:ClearAllPoints(); f.versionText:SetPoint("TOPRIGHT",-54,-23); f.versionText:SetJustifyH("RIGHT")
    f.enable=check(f,L("Enable BuffTap"),0,0,function(c) setAndRefresh("enabled",c:GetChecked()==true) end)
    local enableWidth=f.enable.Text and f.enable.Text:GetStringWidth(); if type(enableWidth)~="number" then enableWidth=100 end
    f.enable:ClearAllPoints(); f.enable:SetPoint("TOPRIGHT",-(18+14+enableWidth),-52)
    -- The live status sits in the footer bar, where it has the full window width.
    f.statusText=label(f,"",0,0,"GameFontHighlightSmall",860); f.statusText:SetWordWrap(false); f.statusText:SetJustifyH("CENTER")
    f.statusText:ClearAllPoints(); f.statusText:SetPoint("TOP",f,"TOPLEFT",466,-879)

    f.tabs={}; f.pages={}
    local names=TAB_NAMES
    local function setTab(index)
      f.activeTab=index
      if B.StopOptionsPreviews then B:StopOptionsPreviews() end
      if f.activeSelector then f.activeSelector:Hide() end
      if f.resetConfirm then f.resetConfirm:Hide() end
      if B.appearancePreview then B.appearancePreview:Hide() end
      if f.blessingMenu then f.blessingMenu:Hide() end
      for i,p in ipairs(f.pages) do p:SetShown(i==index) end
      for i,t in ipairs(f.tabs) do
        T.Navigation(t,i==index)
        fitButtonText(t,135)
      end
      if index==TAB.PatchNotes then B:MarkPatchNotesRead(); if f.patchDot then f.patchDot:Hide() end end
      if index==TAB.Camping or B.campOptionsWasOpen then B.campOptionsWasOpen=index==TAB.Camping; B:UpdateCamping() end
      if index==TAB.Appearance and B.UpdateOptionsPreviews then B:UpdateOptionsPreviews() end
      if index==TAB.Profiles and f.profiles then B:SaveClassSetup(); B:UpdateProfileOptions() end
      if index==TAB.Blacklist then B:UpdateBlacklistPage() end
      if index==TAB.Cleanse then B:UpdateCleansePage() end
    end
    f.selectTab=setTab
    f.navBackground=f.sidebarFill
    local navIcons={"Buffs","Groups","Target","Nearby","Consumables","Camping","Weapons","Customization","Helpers","Profiles","Diagnostics","PatchNotes","Blacklist","Cleanse"}
    f.navIcons=navIcons
    -- Sidebar order: pages you switch on (with a status light) first, then settings-only pages.
    -- Cleanse (14) follows My buffs and is left out for classes that cannot remove anything.
    local order={TAB.Buffs,TAB.Cleanse,TAB.Groups,TAB.Target,TAB.Nearby,TAB.Consumables,TAB.Camping,TAB.Weapons,TAB.Blacklist,TAB.Appearance,TAB.Helpers,TAB.Profiles,TAB.Diagnostics,TAB.PatchNotes}
    local slots={}; local nextSlot=1
    for _,index in ipairs(order) do
      if index~=TAB.Cleanse or B:CanCleanseAnything() then slots[index]=nextSlot; nextSlot=nextSlot+1 end
    end
    for i,name in ipairs(names) do
      local idx=i
      local t=flatButton(f,name,10,-136-((slots[i] or 1)-1)*38,177,function() setTab(idx) end)
      if not slots[i] then t:Hide(); t.navHidden=true end
      t:SetSize(177,34); t.navStyle="sidebar"; f.tabs[i]=t
      t.icon=t:CreateTexture(nil,"ARTWORK"); t.icon:SetSize(18,18); t.icon:SetPoint("LEFT",14,0); t.icon:SetTexture(T.media.."Nav"..navIcons[i])
      T.Navigation(t,false)
      local fs=t:GetFontString()
      if fs then fs:ClearAllPoints(); fs:SetPoint("LEFT",42,0); fs:SetPoint("RIGHT",-10,0); fs:SetJustifyH("LEFT") end
      fitButtonText(t,135)
    end
    local navRule=f:CreateTexture(nil,"BORDER"); navRule:SetColorTexture(unpack(T.rule)); navRule:SetPoint("BOTTOMLEFT",20,118); navRule:SetSize(156,1)
    f.navNote=label(f,"Every cast still needs your click or binding.",0,0,"GameFontDisableSmall",156)
    f.navNote:ClearAllPoints(); f.navNote:SetPoint("BOTTOMLEFT",20,82)
    f.navHelp=button(f,L("How to buff"),0,0,164,function() B:ShowWelcome(true) end)
    f.navHelp:ClearAllPoints(); f.navHelp:SetPoint("BOTTOMLEFT",16,44); f.navHelp:SetHeight(28)

    f.setupBadge=label(f,"",0,0,"GameFontDisableSmall",420); f.setupBadge:SetJustifyH("RIGHT")
    f.setupBadge:ClearAllPoints(); f.setupBadge:SetPoint("TOPRIGHT",-18,-84)
    -- BUFFS PAGE
    local buffs=panel(f); f.pages[TAB.Buffs]=buffs
    local buffsPage=buffs; buffs=CreateFrame("Frame",nil,buffsPage); f.buffContent=buffs; buffs:SetPoint("TOPLEFT",0,-60); buffs:SetPoint("BOTTOMRIGHT",0,0)
    label(buffs,L("Buffs"),18,-16,"GameFontNormalLarge")
    f.buffInstruction=label(buffs,L("Choose your buffs. Move the most important ones to the top."),18,-42,"GameFontDisableSmall",650)
    -- Column headers line up with the controls in each row (rows start at x=28: rebuff field at 284, arrows at 556).
    f.buffRebuffHeader=label(buffs,L("Rebuff"),28+284,-70,"GameFontDisableSmall",90)
    f.buffPriorityHeader=label(buffs,L("Priority"),28+556,-70,"GameFontDisableSmall",90)
    local scroll=CreateFrame("ScrollFrame",nil,buffs,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",28,-90); scroll:SetPoint("BOTTOMRIGHT",-40,126)
    local child=CreateFrame("Frame",nil,scroll); child:SetSize(644,1); scroll:SetScrollChild(child); f.buffChild=child; f.buffRows={}

    f.emptyBuffs=label(child,"No supported aura buffs for this class.",8,-12,"GameFontDisableSmall",610)
    self:BuildContextControls(buffsPage,"buffs",{label=label,flatButton=flatButton,button=button,addHelp=addHelp})
    local weapons=panel(f); f.pages[TAB.Weapons]=weapons
    local weaponsPage=weapons; weapons=CreateFrame("Frame",nil,weaponsPage); f.weaponContent=weapons; weapons:SetPoint("TOPLEFT",0,-60); weapons:SetPoint("BOTTOMRIGHT",0,0)
    f.weaponClassCard=card(weapons,12,-98,698,110); f.coatingCard=card(weapons,12,-220,698,120); f.weaponTimingCard=card(weapons,12,-358,698,110)
    f.weaponTitle=label(weapons,L("Weapon buffs"),18,-16,"GameFontNormalLarge")
    f.weaponHint=label(weapons,L("Maintain a preferred buff on each weapon using your normal BuffTap binding."),18,-42,"GameFontDisableSmall",660)
    f.weaponRetry=button(weapons,L("Retry reminders"),528,-16,154,function() B:RetryConsumableReminders(); B:Options() end)
    addHelp(f.weaponRetry,L("Retry reminders"),L("Restarts item loading and paused consumable reminders. Changed item effects remain blocked."))
    f.weaponEnable=check(weapons,L("Enable weapon reminders"),18,-72,function(c) setAndRefresh("weaponReminder",c:GetChecked()==true); B:Options() end)
    f.weaponApply=selector(weapons,"",180,-72,502,function() return {{key=false,name="Remind only"},{key=true,name="Remind and apply"}} end,function(value) setAndRefresh("weaponApply",value) end)
    addHelp(f.weaponApply,"Weapon mode","Remind only shows missing weapon buffs without preparing an application. Remind and apply prepares your selected spell or item for your next scroll or click, out of combat. Every application still requires your input.")
    f.weaponSectionHeading=label(weapons,L("Poisons / class imbues"),26,-110,T.fonts.Section); f.weaponSectionHeading.optionsSection=true; T.SectionTitle(f.weaponSectionHeading)
    f.weaponMain=check(weapons,L("Main hand"),18,-116,function(c) setAndRefresh("weaponMainHand",c:GetChecked()==true); B:Options() end)
    f.weaponOff=check(weapons,L("Off hand"),18,-164,function(c) setAndRefresh("weaponOffHand",c:GetChecked()==true); B:Options() end)
    f.weaponPickers={}
    for i,hand in ipairs({"main","off"}) do
      local key=hand
      local pick=flatButton(weapons,L("Choose preferred buff"),180,-132-(i-1)*38,502,function(control)
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
    f.coatingHeading=label(weapons,L("Oils and stones"),26,-234,T.fonts.Section); f.coatingHeading.optionsSection=true; T.SectionTitle(f.coatingHeading)
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
    f.weaponTiming=compactSlider(weapons,0,300,15,270,formatSeconds,function(_,v) setAndRefresh("weaponSeconds",v) end)
    f.weaponTiming:SetPoint("TOPLEFT",220,-368)
    f.weaponReplace=check(weapons,"Replace a different buff with my preference",18,-412,function(c) setAndRefresh("weaponReplace",c:GetChecked()==true) end)
    f.weaponRestPause=check(weapons,L("Pause while resting"),380,-412,function(c) if not A.Combat() then B.db.weaponsPauseResting=c:GetChecked()==true; B:RequestRefresh("weapon resting pause",0) end end)
    addHelp(f.weaponRestPause,"Pause while resting","Skip weapon buff reminders in cities and inns. Buff reminders continue as usual.")
    addHelp(f.weaponReplace,"Replacing an existing weapon buff","Off by default. Enable only if you want your preferred buff to replace another recognized buff. Unknown coating data always uses a manual fallback.")
    f.weaponPoisonHint=label(weapons,"Poison ranks: highest carried usable rank. Preferences stay saved when out of stock.",18,-472,"GameFontDisableSmall",660)
    f.weaponHandsHint=label(weapons,"Oils and stones use a separate temporary-enchant slot. Only compatible melee weapons are eligible; shields, held items, ranged weapons and fishing poles are excluded.",18,-500,"GameFontDisableSmall",660)
    f.weaponModeHint=label(weapons,"",18,-530,"GameFontDisableSmall",660)
    -- Width stops short of the Retry reminders button to its right.
    f.weaponStatus=label(weapons,"",18,-550,"GameFontHighlightSmall",500)
    f.weaponUnavailable=label(weapons,"Class imbues are available to Rogues, Shamans and Mages.",18,-72,"GameFontDisableSmall",660)
    self:BuildContextControls(weaponsPage,"weapons",{label=label,flatButton=flatButton,button=button,addHelp=addHelp})
    local timingLabel=buffs:CreateFontString(nil,"OVERLAY","GameFontNormal")
    timingLabel:SetPoint("BOTTOMLEFT",28,88); timingLabel:SetText(L("Default rebuff threshold"))
    local timingHint=buffs:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    timingHint:SetPoint("LEFT",timingLabel,"RIGHT",12,0); timingHint:SetText(L("Used until a buff is customized. Hour-long buffs refresh 5 minutes early; buffs under 2 minutes remind when they wear off.")); timingHint:SetWidth(470); timingHint:SetJustifyH("LEFT")
    f.rebuffSlider=rebuffSlider(buffs); f.rebuffSlider:SetPoint("BOTTOMLEFT",28,54)
    local resetBuffs=button(buffs,L("Reset buffs"),0,0,100,function()
      if not A.Combat() then B:EditorSettings("buffs").buffs={}; B:EditorSettings("buffs").priorities={}; B:EditorSettings("buffs").buffSeconds={}; B:Refresh(); B:Options() end
    end)
    f.resetBuffsButton=resetBuffs; T.Variant(resetBuffs,"danger"); T.Confirm(resetBuffs); resetBuffs:ClearAllPoints(); resetBuffs:SetPoint("BOTTOMRIGHT",-34,26)

    -- GROUPS PAGE
    local groupPage=panel(f); f.pages[TAB.Groups]=groupPage
    local groups=CreateFrame("Frame",nil,groupPage); groups:SetAllPoints(); f.legacyGroups=groups
    if A.Call(function() local _,class=UnitClass("player"); return class end)=="PALADIN" then
      self:BuildBlessingOptions(groupPage)
    else
      f.blessingPanel=CreateFrame("Frame",nil,groupPage); f.blessingPanel:SetAllPoints()

      f.groupTitle=label(groups,L("Party & raid buffing"),18,-16,"GameFontNormalLarge")
      f.groupContext=B:ActiveGroupContext()
      f.groupParty=flatButton(groups,"Party",510,-13,92,function() if not A.Combat() then f.groupContext="Party"; B:Options() end end)
      f.groupRaid=flatButton(groups,"Raid",610,-13,92,function() if not A.Combat() then f.groupContext="Raid"; B:Options() end end)
      f.groupIntro=label(groups,"",18,-38,"GameFontDisableSmall",680)
      f.groupEnable=check(groups,L("Enable party / raid"),18,-58,function(s) setAndRefresh("group",s:GetChecked()==true); B:Options() end)
      f.smartGroup=check(groups,L("Use group spells automatically"),290,-58,function(s) setAndRefresh("smartGroup",s:GetChecked()==true); B:Options() end)
      f.buffPets=check(groups,L("Buff pets"),540,-58,function(s) if not A.Combat() then B.db.buffPets=s:GetChecked()==true; B:InvalidateRoster(); B:RequestRefresh("buff pets",0) end end)
      addHelp(f.buffPets,"Buff pets","Offer single-target buffs such as Mark of the Wild to your pet and your group's pets. Blessings and group spells stay with players.")
      f.readyTopUp=check(groups,L("Top up at ready checks"),0,0,function(s) if not A.Combat() then B.db.readyCheckTopUp=s:GetChecked()==true end end)
      -- Shared group settings card, three rows: All buffs; Group threshold with group spells; pets and ready checks.
      f.smartGroup:ClearAllPoints(); f.smartGroup:SetPoint("TOPLEFT",groups,"TOPLEFT",480,-115)
      f.buffPets:ClearAllPoints(); f.buffPets:SetPoint("TOPLEFT",groups,"TOPLEFT",18,-152)
      f.readyTopUp:ClearAllPoints(); f.readyTopUp:SetPoint("TOPLEFT",groups,"TOPLEFT",480,-152)
      addHelp(f.readyTopUp,"Top up at ready checks","When a ready check starts, buffs with less than half their time left count as missing, so you can refresh them before the pull.")
      local shared=CreateFrame("Frame",nil,groups); shared:SetPoint("TOPLEFT",0,-72); shared:SetSize(704,80); shared:Show()
      f.sharedGroups=shared
      card(groups,12,-46,698,146)
      T.SectionTitle(label(groups,L("Shared group settings"),26,-58,T.fonts.Section))
      line(groups,-204)
      f.perBuffHeading=label(groups,L("Per-buff customization"),18,-218,"GameFontNormalLarge")
      f.roleGuess=check(groups,L("Guess tanks from stance"),300,-213,function(c) if not A.Combat() then B.db.roleGuess=c:GetChecked()==true; B.roleCache=nil; B:InvalidateAura(); B:RequestRefresh("role guess",0) end end)
      addHelp(f.roleGuess,"Guess tanks from stance","Counts a visible Defensive Stance, Bear or Dire Bear Form, or Righteous Fury as a tank when no role is set. Off by default.")
      f.roleMark=button(groups,L("Mark target role"),560,-212,144,markTargetRole)
      addHelp(f.roleMark,"Mark target role",roleHelp)
      label(groups,L("Select a buff below to customize its party/raid groups, recipient classes and group-spell threshold."),18,-242,"GameFontDisableSmall",686)
      label(groups,L("These filters apply only to party/raid buffing. Personal and open-world target buffs stay separate."),18,-596,"GameFontDisableSmall",686)
      f.groupAllLabel=label(shared,L("All buffs"),18,-10,"GameFontNormal")
      f.groupChecks={}
      for i=1,8 do
        local idx=i
        local c=check(shared,"G"..i,108+(i-1)*68,-5,function(s)
          if A.Combat() then return end
          B:SetRaidGroupColumn(idx,s:GetChecked()==true,B:EditingGroupContext())
          B:RequestRefresh("raid group master",0)
          B:Options()
        end)
        local dash=c:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        dash:SetPoint("CENTER",c,"CENTER",0,1); dash:SetText("-"); dash:SetTextColor(1,0.82,0.1); dash:Hide(); c.mixedDash=dash
        addHelp(c,"Raid Group "..i,"Checked or unchecked applies to every buff. A gold dash means this group has mixed per-buff assignments.")
        f.groupChecks[i]=c
      end
      label(shared,L("Group threshold"),18,-48,"GameFontHighlight",110)
      f.groupNeedSlider=compactSlider(shared,2,5,1,190,function(v) return tostring(v).."+" end,function(_,v)
        B:GroupEditorSettings().groupNeed=v; B:NormalizeGroupNeeds(B:EditingGroupContext()); B:InitDB(); B:RequestRefresh("group threshold default",0.08)
      end)
      f.groupNeedSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
      f.groupNeedSlider:SetPoint("TOPLEFT",146,-45)
      card(groups,12,-270,194,300)
      T.SectionTitle(label(groups,L("Select a buff"),24,-282,T.fonts.Section))
      local listScroll=CreateFrame("ScrollFrame",nil,groups,"UIPanelScrollFrameTemplate")
      listScroll:SetPoint("TOPLEFT",18,-298); listScroll:SetSize(178,274)
      f.assignScroll=listScroll
      f.assignList=CreateFrame("Frame",nil,listScroll); f.assignList:SetSize(174,1); listScroll:SetScrollChild(f.assignList)
      f.assignButtons={}
      local assignChild=CreateFrame("Frame",nil,groups); assignChild:SetPoint("TOPLEFT",230,-270); assignChild:SetSize(474,300); card(assignChild,0,0,474,300)
      f.assignChild=assignChild; f.assignRows={}
      f.assignEmpty=label(assignChild,"No party / raid buffs available for this class.",8,-12,"GameFontHighlight",440)

    end

    -- FRIENDLY TARGET PAGE
    local target=panel(f); f.pages[TAB.Target]=target
    label(target,L("Friendly target buffing"),18,-16,"GameFontNormalLarge")

    label(target,"Target a friendly player to offer your selected buffs, then return to your normal queue.",18,-42,"GameFontDisableSmall",680)
    f.friendlyTarget=check(target,L("Enable friendly target buffing"),18,-76,function(s) setAndRefresh("friendlyTarget",s:GetChecked()==true); B:Options() end)
    addHelp(f.friendlyTarget,L("Friendly target buffing"),"This toggle inspects only the player you explicitly target. Nearby buffing is enabled separately and requires friendly nameplates. Target mode uses single-target versions. Grouped Paladin targets follow enabled blessing assignments; ungrouped targets use their independent target settings.")
    local nearby=panel(f); f.pages[TAB.Nearby]=nearby
    label(nearby,"Nearby buffing & players",18,-16,"GameFontNormalLarge")
    button(nearby,"Open nearby window",506,-12,176,function() B:ShowNearbySetup() end)
    label(nearby,"Buff nearby players, invite someone new, or use the player list on its own.",18,-48,"GameFontDisableSmall",680)
    card(nearby,12,-76,698,88)
    f.nearbyEnable=check(nearby,"Enable nearby window",18,-92,function(c)
      if (c:GetChecked()==true)~=B.db.nearbyEnabled then B:ToggleNearby() end
      B:Options()
    end)
    f.nearbyAll=check(nearby,"Show all nearby players",364,-92,function(c) B:SetNearbyView(c:GetChecked()==true); B:Options() end)
    f.nearbyBuffing=check(nearby,"Offer nearby buffs",18,-128,function(c) setAndRefresh("nearbyBuffing",c:GetChecked()==true); B:Options() end)
    f.nearbyInvites=check(nearby,"Show invite / suggest buttons",364,-128,function(c) setAndRefresh("nearbyInvites",c:GetChecked()==true); B:Options() end)
    addHelp(f.nearbyEnable,"Nearby window","Requires friendly player nameplates (normally Shift+V). Tracks up to 40 observed players, with configurable visible rows and a scrollbar. Shift-left-click the minimap icon toggles the window. Hidden during combat.")
    addHelp(f.nearbyAll,"Show all nearby players","Keep observed players listed after buffing. Group members appear only while a buff is queued. Use the small people icon in the window header to switch views.")
    addHelp(f.nearbyBuffing,"Offer nearby buffs","Uses your Target preferences for strangers and group settings for current group members. Every cast requires a click or binding, out of combat. Disable to use the all-players view for invites only.")
    addHelp(f.nearbyInvites,"Invite / suggest","Small buttons beside player rows: + invites, > suggests an invite to your leader. Each requires your click. Already-grouped players and full groups have no invite button. Available in either view.")
    label(nearby,"Friendly player nameplates required. Five visible rows; scroll up to 40 players.",18,-176,"GameFontDisableSmall",680)
    line(nearby,-210)
    label(nearby,"Using the nearby window",18,-232,"GameFontNormalLarge")
    card(nearby,12,-264,336,118); card(nearby,364,-264,346,118)
    label(nearby,"Buffs first",24,-276,"GameFontNormal")
    label(nearby,"Buff offers use your Target preferences for strangers and Groups settings for party or raid members. PvP protection still applies.",24,-304,"GameFontHighlightSmall",308)
    label(nearby,"Invite / suggest",376,-276,"GameFontNormal")
    label(nearby,"Buff candidates appear first. The left-side + button invites. A > button suggests an invitation to your leader. Each action requires your click.",376,-304,"GameFontHighlightSmall",316)
    card(nearby,12,-394,698,94)
    label(nearby,"Show all nearby players",24,-406,"GameFontNormal")
    label(nearby,"The all-players view keeps observed strangers listed after buffing. Group members appear only while an eligible group buff is queued.",24,-434,"GameFontHighlightSmall",660)
    label(nearby,"Five visible rows keep the window compact. Scroll over Nearby to browse players; use your buff binding after moving the pointer away.",18,-510,"GameFontHighlightSmall",660)
    label(nearby,"Shift-left-click the minimap icon to toggle the window. Drag its header when unlocked. The window hides during combat.",18,-562,"GameFontDisableSmall",660)
    card(target,12,-72,698,90)
    T.SectionTitle(label(target,"Default target refresh",26,-86,T.fonts.Section))
    label(target,"Refresh passing players earlier. Buffs under 2 minutes still wait until they wear off.",26,-104,"GameFontDisableSmall",660)
    f.targetDefaultSlider=compactSlider(target,30,1800,30,300,formatSeconds,function(_,value)
      B.db.targetSeconds=value; B:InvalidateAura("target"); B:RequestRefresh("target refresh default",0.08)
    end)
    f.targetDefaultSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
    f.targetDefaultSlider:SetPoint("TOPLEFT",26,-126)
    addHelp(f.targetDefaultSlider,"Target refresh timing","Target mode may refresh much earlier than normal party/raid timing. BuffTap still caps the effective threshold at half of the aura's full duration, so a one-hour buff can be refreshed at 30 minutes but not earlier.")
    f.targetBlessingPanel=CreateFrame("Frame",nil,target)
    f.targetBlessingPanel:SetPoint("TOPLEFT",12,-168); f.targetBlessingPanel:SetSize(698,188)
    f.targetClassAware=check(f.targetBlessingPanel,"Class-aware target blessings",6,0,function(c) setAndRefresh("targetClassBlessings",c:GetChecked()==true); B:Options() end)
    addHelp(f.targetClassAware,"Class-aware target blessings","Automatic follows enabled priorities and class suitability. Class choices apply to friendly targets; group assignments take precedence for group members. Disable to use unrestricted target priorities.")
    f.targetBlessingFallback=check(f.targetBlessingPanel,"Allow fallback to the next blessing",6,-128,function(c) setAndRefresh("targetBlessingFallback",c:GetChecked()==true); B:Options() end)
    addHelp(f.targetBlessingFallback,"Target blessing priorities","Checking a blessing enables it for that class list. All class choices use the default target refresh above. Automatic follows Buffs priorities and enabled spells. Uncheck fallback to offer only the first eligible choice. Your own blessing is maintained; unknown ownership stops fallback. Group assignments remain authoritative.")
    f.targetBlessingPicks={}
    for i,class in ipairs(B.RecipientClasses) do
      local token=class; local x=((i-1)%3)*230; local y=-32-math.floor((i-1)/3)*32
      local classLabel=label(f.targetBlessingPanel,(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token:sub(1,1)..token:sub(2):lower(),x+6,y-7,"GameFontHighlightSmall",80)
      f.targetBlessingPicks[i]=blessingPick(f.targetBlessingPanel,x+89,y,136,function() return B.db.targetBlessingClasses[token] end,function(key) B.db.targetBlessingClasses[token]=key end,"target")
      local pick=f.targetBlessingPicks[i]; pick.classLabel=classLabel; pick.priorityClass=token; pick.priorityTarget=true
      pick.getOrder=function() return B.db.targetBlessingPriorities[token] end
      pick.setOrder=function(order) B.db.targetBlessingPriorities[token]=order end
    end
    f.targetBlessingInstruction=label(f.targetBlessingPanel,"",6,-160,"GameFontDisableSmall",686)
    f.targetHeaders=CreateFrame("Frame",nil,target); f.targetHeaders:SetPoint("TOPLEFT",0,-168); f.targetHeaders:SetSize(698,78)
    local header=f.targetHeaders
    line(header,0)
    header.title=label(header,"Spell availability & refresh timing",26,-22,T.fonts.Section); T.SectionTitle(header.title)
    header:EnableMouse(true)
    addHelp(header,"Spell availability & refresh timing","Allow controls which spells unrestricted friendly-target mode may offer. Refresh timing applies to that spell across recipient classes. Custom priorities choose the order; this section does not add another blessing assignment. Leaving custom timing off uses the default target refresh above.")
    header.help=label(header,"Choose allowed spells and optional refresh overrides for friendly targets.",26,-38,"GameFontDisableSmall",660)
    label(header,L("Allow"),18,-56,"GameFontDisableSmall",48)
    label(header,L("Buff"),82,-56,"GameFontDisableSmall",160)
    label(header,L("Override timing"),276,-56,"GameFontDisableSmall",100)
    label(header,L("Refresh when remaining"),402,-56,"GameFontDisableSmall",180)
    local targetScroll=CreateFrame("ScrollFrame",nil,target,"UIPanelScrollFrameTemplate")
    targetScroll:SetPoint("TOPLEFT",14,-246); targetScroll:SetPoint("BOTTOMRIGHT",-34,54)
    local targetChild=CreateFrame("Frame",nil,targetScroll); targetChild:SetSize(660,1); targetScroll:SetScrollChild(targetChild)
    f.targetChild=targetChild; f.targetRows={}; f.targetScroll=targetScroll
    local resetTarget; resetTarget=button(target,L("Reset target settings"),0,0,132,function()
      if not A.Combat() then
        B.db.friendlyTarget=false; B.db.targetSeconds=300; B.db.targetBuffs={}; B.db.targetBuffSeconds={}; B.db.targetClasses={}; B.db.targetClassBlessings=true; B.db.targetBlessingFallback=true; B.db.targetBlessingClasses={}; B.db.targetBlessingPriorities={}
        B:InitDB(); B:InvalidateAura("target"); B:RequestRefresh("reset target settings",0); B:Options()
      end
    end)
    T.Confirm(resetTarget)
    T.Variant(resetTarget,"danger"); resetTarget:ClearAllPoints(); resetTarget:SetPoint("BOTTOMRIGHT",-20,14)

    -- CONSUMABLES PAGE
    local consumePanel=panel(f); f.pages[TAB.Consumables]=consumePanel
    local consume=CreateFrame("Frame",nil,consumePanel); consume:SetPoint("TOPLEFT",0,-36); consume:SetPoint("BOTTOMRIGHT",0,0)
    f.consumableBody=consume
    local consumePage=consume; consume=CreateFrame("Frame",nil,consumePage); consume:SetPoint("TOPLEFT",0,-60); consume:SetPoint("BOTTOMRIGHT",0,0)
    self:BuildSupplyOptions(consumePanel)
    local buffView=flatButton(consumePanel,"Buff items",18,-8,104,function() f.selectConsumableView(false) end)
    local supplyView=flatButton(consumePanel,L("Supplies"),132,-8,104,function() f.selectConsumableView(true) end)
    f.consumableViewButtons={buffView,supplyView}
    f.selectConsumableView=function(supplies)
      f.consumableBody:SetShown(not supplies); f.supplyBody:SetShown(supplies)
      T.Navigation(buffView,not supplies); T.Navigation(supplyView,supplies)
      if supplies then B:UpdateSupplyOptions() end
      if B.itemPicker then B.itemPicker:Hide() end
    end
    f.selectConsumableView(false)
    label(consume,L("Consumables"),18,-16,"GameFontNormalLarge")
    label(consume,"Choose food, a flask, an elixir and an optional utility consumable.",18,-42,"GameFontDisableSmall",680)
    f.consumablesEnable=check(consume,"Enable consumable reminders",18,-72,function(c)
      if not A.Combat() then B:EditorSettings("consumables").consumablesEnabled=c:GetChecked()==true; if B.InvalidateConsumables then B:InvalidateConsumables() end; B:RequestRefresh("consumables master",0); B:Options() end
    end)
    f.consumeBuild=label(consume,"Data: -",410,-77,"GameFontDisableSmall",260)
    f.consumableRestPause=check(consume,L("Pause while resting"),18,-58,function(c) if not A.Combat() then B.db.consumablesPauseResting=c:GetChecked()==true; B:RequestRefresh("consumable resting pause",0) end end)
    f.consumableInstanceOnly=check(consume,L("Only in dungeons and raids"),0,0,function(c) if not A.Combat() then B.db.consumablesInstanceOnly=c:GetChecked()==true; B:RequestRefresh("consumable instance only",0) end end)
    f.consumableInstanceOnly:ClearAllPoints(); f.consumableInstanceOnly:SetPoint("TOPLEFT",f.consumableRestPause,"TOPLEFT",200,0)
    addHelp(f.consumableInstanceOnly,"Only in dungeons and raids","Skip food, flask, elixir and utility reminders outside dungeons and raids. Buff reminders continue everywhere.")
    addHelp(f.consumableRestPause,"Pause while resting","Skip food, flask, elixir and utility reminders in cities and inns, so you do not use them while resting. Buff reminders continue as usual.")
    line(consume,-108)
    f.consumableRows={}
    for index,family in ipairs(B.ConsumableFamilies or {}) do
      local row=CreateFrame("Frame",nil,consume,"BackdropTemplate")
      row:SetSize(686,76); row:SetPoint("TOPLEFT",10,-116-(index-1)*80)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(unpack(T.row)); T.Row(row,8)
      row.family=family
      row.enable=check(row,"",8,-8,function(c)
        local fam=c:GetParent().family
        if fam and not A.Combat() then
          B:EditorSettings("consumables").consumableFamilies[fam.key]=c:GetChecked()==true
          if B.InvalidateConsumables then B:InvalidateConsumables() end
          B:RequestRefresh("consumable family",0); B:Options()
        end
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(30,30); row.icon:SetPoint("TOPLEFT",42,-8); row.icon:SetTexture(134400)
      row.name=label(row,family.name,82,-8,"GameFontHighlight",210)
      row.choice=label(row,"Auto",82,-29,"GameFontHighlightSmall",420)
      row.prev=button(row,L("Choose"),584,-8,86,function(btn) B:ChooseConsumable(btn:GetParent().family,btn,B:EditorContext("consumables")) end)
      row.inventory=label(row,"",450,-11,"GameFontHighlightSmall",120)
      label(row,family.protectPresent and (family.key=="utility" and "Preserve active utility; remind after expiry" or "Preserve active elixirs; remind after expiry") or "Rebuff at",42,-52,"GameFontDisableSmall",family.protectPresent and 390 or 62)
      addHelp(row.enable,"Maintain this consumable buff","Enable this family to maintain its selected item. Utility maintains one choice; recognized active utility effects are preserved until expiry. Enable consumable reminders above too. Preferences stay saved when supplies run out.")
      row.threshold=compactSlider(row,30,1800,30,230,formatSeconds,function(slider,value)
        local fam=slider:GetParent().family
        if fam then B:SetSituationValue(B:EditorContext("consumables"),"consumables","consumableSeconds",value,fam.key); B:InvalidateAura("player"); B:RequestRefresh("consumable threshold",0.08) end
      end)
      row.threshold:SetPoint("TOPLEFT",108,-54)
      f.consumableRows[index]=row
    end
    local consumeFooterY=-116-(#(B.ConsumableFamilies or {}))*80-4

    f.consumeRetry=button(consume,L("Retry reminders"),528,consumeFooterY-48,154,function() B:RetryConsumableReminders(); B:Options() end)
    addHelp(f.consumeRetry,L("Retry reminders"),L("Restarts item loading and paused consumable reminders. Changed item effects remain blocked."))
    f.consumePauseStatus=label(consume,"",186,consumeFooterY-53,"GameFontHighlightSmall",496)

    self:BuildContextControls(consumePage,"consumables",{label=label,flatButton=flatButton,button=button,addHelp=addHelp})

    -- CAMPING PAGE
    local camping=panel(f); f.pages[TAB.Camping]=camping; f.campingPage=camping; f.campingTab=TAB.Camping
    local function campChange(key,value)
      if A.Combat() then return end
      B.db[key]=value; B:NormalizeCamping(); B:UpdateCamping(); B:UpdateCampingOptions(); B:UpdateOptionsPreviews()
    end
    label(camping,"Camping & sleeping bag",18,-16,"GameFontNormalLarge")
    label(camping,"Independent camp and experience reminders. Your regular buff binding stays unchanged.",18,-42,"GameFontDisableSmall",660)
    button(camping,"Open setup tray",520,-12,162,function() B:ToggleCampTray() end)
    card(camping,12,-64,698,46)
    f.campingStatus=label(camping,"",28,-75,"GameFontHighlightSmall",318)
    f.sleepingStatus=label(camping,"",364,-75,"GameFontHighlightSmall",318)
    card(camping,12,-116,698,98); card(camping,12,-232,698,110); card(camping,12,-350,698,126)
    f.campingEnable=check(camping,"Separate camp reminder",18,-122,function(c) campChange("campReminder",c:GetChecked()==true) end)
    f.campingSound=check(camping,"Sound",18,-182,function(c) campChange("campSound",c:GetChecked()==true) end)
    f.campingAnywhere=check(camping,"Warn away from camp",364,-122,function(c) campChange("campAnywhere",c:GetChecked()==true) end)
    addHelp(f.campingAnywhere,"Warn away from camp","Show the reminder outdoors when a tracked camp or sleeping bag benefit is missing or expiring, even with no camp nearby.")
    f.campingTrack=check(camping,"Camp benefits",18,-152,function(c) campChange("campTrackBenefits",c:GetChecked()==true) end)
    f.sleepingTrack=check(camping,"Sleeping bag XP",364,-152,function(c) campChange("campTrackBag",c:GetChecked()==true) end)
    addHelp(f.sleepingTrack,"Sleeping bag XP","Tracks all three Well-Rested stacks and their remaining duration. Food reminders remain under Consumables.")
    f.campingWarning=selector(camping,"",364,-181,318,function() return {{key=60,name="Warn: 1 minute"},{key=300,name="Warn: 5 minutes"},{key=600,name="Warn: 10 minutes"}} end,function(v) campChange("campWarning",v) end)
    line(camping,-224)
    label(camping,"Camp reminder appearance",18,-238,"GameFontNormalLarge")
    label(camping,"Size",18,-275,"GameFontHighlightSmall")
    f.campingSize=compactSlider(camping,24,96,4,160,function(v) return tostring(v).." px" end,function(_,v) campChange("campSize",v) end); f.campingSize:SetPoint("TOPLEFT",110,-274)
    label(camping,"Opacity",364,-275,"GameFontHighlightSmall")
    f.campingOpacity=compactSlider(camping,25,100,5,160,function(v) return tostring(v).."%" end,function(_,v) campChange("campOpacity",v/100) end); f.campingOpacity:SetPoint("TOPLEFT",456,-274)
    f.campingEffect=selector(camping,"",18,-310,240,function() return {{key="none",name="Effect: None"},{key="soft",name="Effect: Soft glow"},{key="pulse",name="Effect: Pulse"},{key="pixel",name="Effect: Pixel border"},{key="autocast",name="Effect: Sparkles"},{key="proc",name="Effect: Spell glow"},{key="shine",name="Effect: Shine"},{key="ripple",name="Effect: Ripple"},{key="bounce",name="Effect: Bounce"},{key="orbit",name="Effect: Orbit"}} end,function(v) campChange("campEffectStyle",v) end)
    f.campingColor=selector(camping,"",274,-310,196,function() return {{key="gold",name="Gold"},{key="cyan",name="Cyan"},{key="green",name="Green"},{key="red",name="Red"},{key="white",name="White"}} end,function(v) campChange("campEffectColor",v) end)
    f.campingSpeed=selector(camping,"",486,-310,196,function() return {{key="slow",name="Slow"},{key="normal",name="Normal"},{key="fast",name="Fast"}} end,function(v) campChange("campEffectSpeed",v) end)
    addHelp(f.campingColor,"Effect color","Changes only the camp reminder effect, not the regular buff icon.")
    addHelp(f.campingSpeed,"Effect speed","Changes only the camp reminder animation speed.")
    label(camping,"Reminder text",18,-350,"GameFontNormal")
    f.campingCountdown=check(camping,"Show countdown",18,-374,function(v) campChange("campShowCountdown",v:GetChecked()==true) end)
    f.campingStacks=check(camping,"Show sleeping bag stacks",364,-374,function(v) campChange("campShowStacks",v:GetChecked()==true) end)
    f.campingTextFont=selector(camping,"",18,-412,176,function() return B:ReminderFonts(B.db.campTextFont) end,function(v) campChange("campTextFont",v) end)
    f.campingTextSize=selector(camping,"",206,-412,96,function() return B:TextSizeChoices() end,function(v) campChange("campTextSize",v) end,"scroll")
    f.campingTextColor=selector(camping,"",314,-412,176,function() return B:ReminderColors(true) end,function(v) campChange("campTextColor",v) end)
    f.campingTextOutline=selector(camping,"",502,-412,180,function() return B:TextOutlineChoices() end,function(v) campChange("campTextOutline",v) end)
    addHelp(f.campingTextFont,"Label font","Changes only the camp reminder text.")
    addHelp(f.campingTextSize,"Text size","Game size restores the original game font size.")
    addHelp(f.campingTextOutline,"Text outline","Choose an outline to keep text readable against the game world.")
    label(camping,"Text spacing",18,-456,"GameFontHighlightSmall")
    f.campingTextGap=compactSlider(camping,0,20,1,170,function(v) return tostring(v).." px" end,function(_,v) campChange("campTextGap",v) end); f.campingTextGap:SetPoint("TOPLEFT",110,-452)
    button(camping,"Preview / move",18,-492,176,function() B:PreviewCampReminder() end)
    button(camping,"Center",210,-492,98,function() B.db.campX=0; B.db.campY=0; B:PreviewCampReminder() end)
    T.Confirm(button(camping,"Reset camp look",324,-492,170,function()
      if A.Combat() then return end
      B.db.campSize=40; B.db.campOpacity=1; B.db.campX=100; B.db.campY=-180; B.db.campEffectStyle="soft"; B.db.campEffectColor="gold"; B.db.campEffectSpeed="normal"; B.db.campTextFont="default"; B.db.campTextSize=0; B.db.campTextColor="white"; B.db.campTextOutline="outline"; B.db.campTextGap=4; B.db.campShowCountdown=true; B.db.campShowStacks=true; B:PreviewCampReminder(); B:UpdateCampingOptions()
    end))
    label(camping,"Preview lasts 12 seconds. Drag the camp icon to position it.",18,-532,"GameFontDisableSmall",660)
    f.campingPause=label(camping,"",18,-562,"GameFontHighlightSmall",470)
    f.campingResume=button(camping,"Resume reminder",510,-492,172,function() B.campSnoozeSession=nil; B.campSnoozeUntil=nil; B:UpdateCamping(); B:UpdateCampingOptions() end)
    label(camping,"Right-click the camp icon to snooze. Camp items and the sleeping bag are used from the setup tray; food stays under Consumables.",18,-588,"GameFontDisableSmall",660)

    -- APPEARANCE PAGE
    local app=panel(f); f.pages[TAB.Appearance]=app
    card(app,12,-10,698,88); card(app,12,-118,698,286); card(app,12,-414,698,128); card(app,12,-552,698,62)
    label(app,L("Binding"),18,-16,"GameFontNormalLarge")
    f.bindingText=label(app,"Current: -",18,-46,"GameFontHighlight",280)
    button(app,L("Set binding"),310,-42,116,function() B:CaptureBinding() end)
    f.clearBindingButton=T.Confirm(button(app,L("Clear"),436,-42,82,function() if not A.Combat() then B.db.keys={}; B.appearance=nil; B:RequestRefresh("clear binding",0); B:Options() end end))
    label(app,"The override binding is active only while BuffTap has a valid buff action ready.",18,-73,"GameFontDisableSmall",650)
    line(app,-105)
    label(app,L("Reminder appearance"),18,-126,"GameFontNormalLarge")
    f.showReminderCheck=check(app,L("Show reminder button"),440,-122,function(s) setAndRefresh("showReminder",s:GetChecked()==true) end)
    addHelp(f.showReminderCheck,L("Show reminder button"),L("Hide the button and its labels while keeping your binding and optional sounds active. Hidden reminders cannot be clicked or right-clicked. Manual-only reminders need a visible display. Preview remains available."))
    label(app,L("Size"),18,-160,"GameFontHighlight"); f.sizeEdit=editbox(app,62,-156,58,true); label(app,"px",126,-160,"GameFontDisableSmall")
    label(app,L("Opacity"),176,-160,"GameFontHighlight"); f.opacityEdit=editbox(app,238,-156,58,true); label(app,"%",300,-160,"GameFontDisableSmall")
    label(app,"X",326,-160,"GameFontHighlight"); f.xEdit=editbox(app,344,-156,64,false)
    label(app,"Y",430,-160,"GameFontHighlight"); f.yEdit=editbox(app,448,-156,64,false)
    button(app,L("Apply"),540,-156,72,function()
      if A.Combat() then return end
      local size,opacity,x,y=tonumber(f.sizeEdit:GetText()),tonumber(f.opacityEdit:GetText()),tonumber(f.xEdit:GetText()),tonumber(f.yEdit:GetText())
      if size then B.db.size=size end; if opacity then B.db.opacity=math.max(0,math.min(100,opacity))/100 end; if x then B.db.x=x end; if y then B.db.y=y end
      for _,e in ipairs({f.sizeEdit,f.opacityEdit,f.xEdit,f.yEdit}) do e.unsaved=nil; e:ClearFocus() end
      B:InitDB(); B.appearance=nil; B:RequestRefresh("appearance",0); B:Options()
    end)
    f.soundCheck=check(app,L("Enable reminder sound"),18,-510,function(s) setAndRefresh("sound",s:GetChecked()==true) end)
    f.effectButton=selector(app,"",18,-200,240,function() return {{key="none",name="Effect: None"},{key="soft",name="Effect: Soft glow"},{key="pulse",name="Effect: Pulse"},{key="pixel",name="Effect: Pixel border"},{key="autocast",name="Effect: Sparkles"},{key="proc",name="Effect: Spell glow"},{key="shine",name="Effect: Shine"},{key="ripple",name="Effect: Ripple"},{key="bounce",name="Effect: Bounce"},{key="orbit",name="Effect: Orbit"}} end,function(v) setAndRefresh("effectStyle",v) end)
    f.effectColorButton=selector(app,"",274,-200,196,function() return {{key="gold",name="Gold"},{key="cyan",name="Cyan"},{key="green",name="Green"},{key="red",name="Red"},{key="white",name="White"}} end,function(v) setAndRefresh("effectColor",v) end)
    f.effectSpeedButton=selector(app,"",486,-200,196,function() return {{key="slow",name="Slow"},{key="normal",name="Normal"},{key="fast",name="Fast"}} end,function(v) setAndRefresh("effectSpeed",v) end)
    addHelp(f.effectButton,"Icon effect","Choose a border or glow. Effects stop when the reminder is hidden. Unsupported effects use a soft glow.")
    addHelp(f.effectColorButton,"Effect color","Changes the icon effect color.")
    addHelp(f.effectSpeedButton,"Effect speed","Changes the animation speed.")
    f.effectUrgency=check(app,L("Urgency colour"),18,-600,function(c) setAndRefresh("effectUrgency",c:GetChecked()==true) end)
    addHelp(f.effectUrgency,"Urgency colour","The effect turns amber in the last half of the refresh window and red once the buff is gone.")
    f.effectOnce=check(app,L("Flash once, then settle"),18,-630,function(c) setAndRefresh("effectOnce",c:GetChecked()==true) end)
    addHelp(f.effectOnce,"Flash once, then settle","Plays the effect for a few seconds when a reminder appears, then keeps a calm glow. Good if constant motion is distracting.")
    f.buffNameCheck=check(app,L("Show buff name"),18,-236,function(s) setAndRefresh("showBuffName",s:GetChecked()==true) end)
    f.targetNameCheck=check(app,L("Show buff recipient"),364,-236,function(s) setAndRefresh("showTargetName",s:GetChecked()==true) end)
    addHelp(f.targetNameCheck,"Buff recipient","Shows the name of whoever BuffTap is about to buff, including you when the current action is a self buff.")
    f.timerCheck=check(app,L("Remaining time"),18,-266,function(s) setAndRefresh("showTimer",s:GetChecked()==true) end)
    f.groupBadgeCheck=check(app,L("Group count"),364,-266,function(s) setAndRefresh("showGroupBadge",s:GetChecked()==true) end)
    addHelp(f.timerCheck,L("Remaining time"),"Shows a small countdown only when the selected buff is already inside its rebuff window.")
    addHelp(f.groupBadgeCheck,L("Group count"),"Shows how many players need the buff when BuffTap selects a group-version spell.")
    button(app,L("Move icon"),18,-366,108,function() B:MoveAnchor() end)
    button(app,L("Center"),136,-366,90,function() if not A.Combat() then B.db.x=0; B.db.y=-180; B.appearance=nil; B:RequestRefresh("center icon",0); B:Options() end end)
    f.resetLookButton=button(app,L("Reset look"),236,-366,100,function()
      if not A.Combat() then B.db.showReminder=true; B.db.size=64; B.db.opacity=1; B.db.x=0; B.db.y=-180; B.db.glow=true; B.db.pulse=false; B.db.effectStyle=nil; B.db.effectColor="gold"; B.db.effectSpeed="normal"; B.db.showBuffName=false; B.db.showTargetName=true; B.db.showTimer=false; B.db.showGroupBadge=true; B.db.labelFont="default"; B.db.labelColor="default"; B.db.labelSize=0; B.db.labelOutline=B:GameTextOutline(); B.db.labelGap=5; B.appearance=nil; B:RequestRefresh("reset look",0); B:Options() end
    end)
    T.Confirm(f.resetLookButton)
    local function textChange(key,value)
      setAndRefresh(key,value)
      if B.appearancePreview and B.appearancePreview:IsShown() then B:PreviewAppearance() end
    end
    f.fontButton=selector(app,"",18,-298,176,function() return B:ReminderFonts() end,function(v) textChange("labelFont",v) end)
    f.labelSizeButton=selector(app,"",206,-298,96,function() return B:TextSizeChoices() end,function(v) textChange("labelSize",v) end,"scroll")
    f.colorButton=selector(app,"",314,-298,176,function() return B:ReminderColors() end,function(v) textChange("labelColor",v) end)
    f.labelOutlineButton=selector(app,"",502,-298,180,function() return B:TextOutlineChoices() end,function(v) textChange("labelOutline",v) end)
    label(app,"Text spacing",18,-337,"GameFontHighlightSmall")
    f.labelGap=compactSlider(app,0,20,1,170,function(v) return tostring(v).." px" end,function(_,v) textChange("labelGap",v) end); f.labelGap:SetPoint("TOPLEFT",110,-333)
    addHelp(f.labelSizeButton,"Text size","Game size restores the original game font size.")
    addHelp(f.labelOutlineButton,"Text outline","Choose an outline to keep text readable against the game world.")
    addHelp(f.fontButton,L("Label font"),L("Choose a built-in game font for reminder labels. Settings text stays unchanged."))
    addHelp(f.colorButton,L("Label color"),L("Choose the color of reminder labels. White + gold count keeps the group count gold."))
    button(app,L("How to buff"),536,-366,146,function() B:ShowWelcome(true) end)
    button(app,L("Preview appearance"),348,-366,150,function() B:PreviewAppearance() end)
    line(app,-406)
    label(app,L("Sounds"),18,-420,"GameFontNormal")
    local function soundControl(kind,y)
      label(app,kind=="supply" and L("Supply sound") or kind=="camp" and L("Camp sound") or L("Reminder sound"),18,y-5,"GameFontHighlightSmall",112)
      local key=kind=="supply" and "supplySound" or kind=="camp" and "campAlertSound" or "reminderSound"
      local choice=selector(app,"",138,y,180,function() return B:SoundChoices() end,function(value) B.db[key]=value end,true)
      button(app,L("Preview"),326,y,90,function() if not B:PlayAlert(kind,true) then B.Print(L("Sound preview unavailable.")) end end)
      addHelp(choice,L("Sound"),L("Open the list to choose a sound.").."\n"..L("Game sounds and installed SharedMedia sounds are available. Search or scroll the list; Preview ignores the alert toggle. Missing media uses the default sound without forgetting your choice."))
      return choice
    end
    f.reminderSoundButton=soundControl("reminder",-440)
    f.supplySoundButton=soundControl("supply",-474)
    f.campSoundButton=soundControl("camp",-508)
    label(app,L("Audio channel"),436,-445,"GameFontHighlightSmall",116)
    f.channelButton=selector(app,"",550,-440,132,function() return {{key="Master",name="Master"},{key="SFX",name="Sound effects"}} end,function(value) B.db.soundChannel=value end)
    addHelp(f.channelButton,L("Audio channel"),L("Choose a sound and preview it. Master follows master volume; Sound effects follows effects volume."))
    label(app,L("Minimum interval"),436,-479,"GameFontHighlightSmall",116)
    f.soundInterval=compactSlider(app,5,60,5,80,formatSeconds,function(_,value) setAndRefresh("soundInterval",value) end)
    f.soundInterval:SetPoint("TOPLEFT",550,-478)
    label(app,L("Quick access"),200,-558,"GameFontNormal")
    f.minimapCheck=check(app,L("Minimap button"),200,-582,function(s) B.db.minimap.hide=not s:GetChecked(); B:SyncBroker() end)
    f.brokerCheck=check(app,L("Broker display"),440,-582,function(s) B.db.brokerEnabled=s:GetChecked()==true; B:SyncBroker(); B:Options() end)
    addHelp(f.brokerCheck,L("Broker display"),L("Requires a broker bar addon. Shows the next reminder, not a total missing-buff count. Disable takes effect after reloading the UI."))
    f.resetAllButton=button(app,L("Reset all settings"),18,-572,156,function() f.resetConfirm:Show() end); T.Variant(f.resetAllButton,"danger")
    f.resetConfirm=CreateFrame("Frame",nil,app,"BackdropTemplate"); f.resetConfirm:SetSize(686,76); f.resetConfirm:SetPoint("TOPLEFT",16,-528)
    f.resetConfirm:SetFrameLevel(app:GetFrameLevel()+10)
    f.resetConfirm:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f.resetConfirm:SetBackdropColor(0.08,0.04,0.04,1); f.resetConfirm:SetBackdropBorderColor(0.65,0.4,0.2,1)
    label(f.resetConfirm,L("Reset all settings? This removes your saved preferences and assignments."),10,-6,"GameFontHighlightSmall",660)
    button(f.resetConfirm,L("Cancel"),488,-40,90,function() f.resetConfirm:Hide() end)
    f.confirmResetButton=button(f.resetConfirm,L("Confirm reset"),340,-40,140,function()
      if not A.Combat() then f.resetConfirm:Hide(); B:ResetEverything(); B:RequestRefresh("reset settings",0); B:Options() end
    end)
    T.Variant(f.confirmResetButton,"danger")
    f.resetConfirm:Hide()

    local profiles=panel(f); f.pages[TAB.Profiles]=profiles
    self:BuildProfileOptions(profiles,{label=label,button=button,check=check,selector=selector})

    -- BLACKLIST PAGE: players and guilds BuffTap never offers buffs or invites to.
    local black=panel(f); f.pages[TAB.Blacklist]=black
    f.pages[TAB.Cleanse]=panel(f)
    label(black,L("Blacklist"),18,-16,"GameFontNormalLarge")
    label(black,"BuffTap never offers buffs or invites to these players or guilds. Your own group is not affected.",18,-42,"GameFontDisableSmall",680)
    card(black,12,-74,692,118)
    T.SectionTitle(label(black,L("Add to blacklist"),28,-88,T.fonts.Section))
    f.blackInput=editbox(black,30,-114,240,false); f.blackInput:SetMaxLetters(64)
    local function addTyped(kind) if B:SetBlocked(kind,f.blackInput:GetText(),true) then f.blackInput:SetText(""); f.blackInput:ClearFocus() end end
    f.blackInput:SetScript("OnEnterPressed",function() addTyped("player") end)
    f.blackInput:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)
    local addPlayer=button(black,L("Add player"),284,-112,130,function() addTyped("player") end)
    addHelp(addPlayer,"Add player","Type a character's first name. Capitals do not matter.")
    local addGuild=button(black,L("Add guild"),422,-112,130,function() addTyped("guild") end)
    addHelp(addGuild,"Add guild","Type the guild name exactly as the game shows it, including spaces, accents and special characters. Capitals do not matter. Block target's guild copies the name for you.")
    f.blackTarget=button(black,L("Block target"),284,-148,130,function()
      local name=A.Call(UnitName,"target")
      if A.Call(UnitIsPlayer,"target")==true and A.Text(name) then B:SetBlocked("player",name,true) end
    end)
    f.blackTargetGuild=button(black,L("Block target's guild"),422,-148,268,function()
      local guild=A.Call(GetGuildInfo,"target")
      if A.Text(guild) and guild~="" then B:SetBlocked("guild",guild,true) end
    end)
    card(black,12,-206,692,104)
    T.SectionTitle(label(black,L("Rules"),28,-220,T.fonts.Section))
    f.blackIgnored=check(black,L("Also skip players on my ignore list"),28,-244,function(c)
      if A.Combat() then return end
      B.db.blockIgnored=c:GetChecked()==true; B:ApplyBlacklist()
    end)
    addHelp(f.blackIgnored,"Also skip players on my ignore list","Players on your game ignore list are treated as blacklisted. They are not added to the lists below.")
    f.blackTargets=check(black,L("Apply to players I target myself"),28,-274,function(c)
      if A.Combat() then return end
      B.db.blacklistTargets=c:GetChecked()==true; B:ApplyBlacklist()
    end)
    addHelp(f.blackTargets,"Apply to players I target myself","On: friendly target buffing skips blacklisted players too. Off: the blacklist only affects the Nearby window.")
    f.blackInstances=check(black,L("Ignore the blacklist in dungeons and raids"),374,-244,function(c)
      if A.Combat() then return end
      B.db.blacklistInInstances=c:GetChecked()~=true; B:ApplyBlacklist()
    end)
    addHelp(f.blackInstances,"Ignore the blacklist in dungeons and raids","Useful when a blacklisted player ends up in your dungeon or raid. Your own group is never affected either way.")
    label(black,"Your own party and raid are never affected.",400,-280,"GameFontDisableSmall",290)
    f.blackLists={}
    for i,kind in ipairs({"player","guild"}) do
      local x=i==1 and 12 or 364
      card(black,x,-324,340,330)
      local list={kind=kind,rows={}}
      list.title=label(black,"",x+16,-338,T.fonts.Section); T.SectionTitle(list.title)
      list.scroll=CreateFrame("ScrollFrame",nil,black,"UIPanelScrollFrameTemplate")
      list.scroll:SetPoint("TOPLEFT",x+12,-362); list.scroll:SetSize(296,280); list.scroll:Show()
      list.child=CreateFrame("Frame",nil,list.scroll); list.child:SetSize(296,280); list.scroll:SetScrollChild(list.child)
      list.empty=label(black,kind=="player" and L("No players blacklisted.") or L("No guilds blacklisted."),x+18,-368,"GameFontDisable",300)
      f.blackLists[i]=list
    end
    function f.blackRow(list,index)
      local row=list.rows[index]
      if row then return row end
      row=CreateFrame("Frame",nil,list.child); row:SetSize(296,30); row:SetPoint("TOPLEFT",0,-(index-1)*32)
      row.text=label(row,"",8,-8,"GameFontHighlight",190)
      row.remove=button(row,L("Remove"),200,-3,90,function()
        if row.name and not A.Combat() then B:SetBlocked(list.kind,row.name,false) end
      end)
      list.rows[index]=row; return row
    end

    local diag=panel(f); f.pages[TAB.Diagnostics]=diag
    label(diag,L("Diagnostics & performance"),18,-16,"GameFontNormalLarge")
    f.diagVersion=label(diag,"",550,-20,"GameFontHighlightSmall",144)
    f.diagVersion:SetJustifyH("RIGHT")
    -- Run a debug command and show its output in the copyable box instead of chat.
    label(diag,L("Capture"),268,-82,"GameFontHighlightSmall",70)
    for i,spec in ipairs({{"debug","Debug"},{"status","Status"},{"nearby","Nearby"},{"supplies","Supplies"}}) do
      button(diag,L(spec[2]),330+(i-1)*94,-76,86,function() if not A.Combat() then B:ShowDiagnosticsReport(spec[1]) end end)
    end
    T.Variant(button(diag,L("Copy for a report"),18,-684,180,function() if not A.Combat() then B:ShowDiagnosticsReport("diagnostics") end end),"primary")
    f.diagHideNames=check(diag,L("Hide player names"),218,-686,function(c) B.reportHideNames=c:GetChecked()==true end)
    addHelp(f.diagHideNames,"Hide player names","Replaces the names BuffTap can see with Player1, Player2 and so on in captured text.")
    f.diagPauseNotes=check(diag,L("Explain pauses in chat"),440,-686,function(c) B.db.pauseNotes=c:GetChecked()==true end)
    addHelp(f.diagPauseNotes,"Explain pauses in chat","When reminders stop because the game is not sharing buff information, say so once per zone.")
    label(diag,"Core scanning is event-driven. Profiling is optional and lasts only for this game session.",18,-42,"GameFontDisableSmall",680)
    f.profileCheck=check(diag,L("Measure refresh cost"),18,-76,function(c)
      B.profileEnabled=c:GetChecked()==true; B.profileStats=nil
      if B.profileEnabled then B:ResetStats() else B.stats=nil end
      B:Options()
    end)
    addHelp(f.profileCheck,"Refresh profiler","Disabled by default. When enabled, BuffTap measures only its own refresh duration with debugprofilestop().")
    card(diag,12,-108,698,484)
    f.diagScroll=CreateFrame("ScrollFrame",nil,diag,"UIPanelScrollFrameTemplate")
    f.diagScroll:SetPoint("TOPLEFT",18,-116); f.diagScroll:SetSize(654,468); f.diagScroll:Show()
    f.diagContent=CreateFrame("Frame",nil,f.diagScroll); f.diagContent:SetSize(638,468)
    f.diagScroll:SetScrollChild(f.diagContent)
    f.diagText=label(f.diagContent,"",0,0,"GameFontHighlightSmall",638); f.diagText:SetSpacing(3); f.diagText:Show()
    button(diag,L("Refresh diagnostics"),18,-604,142,function()
      if not A.Combat() then f.discoveryScroll:Hide(); f.diagScroll:Show(); f.diagText:Show(); f.diagScroll:SetVerticalScroll(0); B:Refresh(true); B:Options() end
    end)
    button(diag,L("Print to chat"),170,-604,108,function() B:Status(true); B:Options() end)
    button(diag,L("Reset metrics"),288,-604,110,function()
      B.profileStats=nil; if B.profileEnabled then B:ResetStats() else B.stats=nil end; B:Options()
    end)

    local scroll=CreateFrame("ScrollFrame",nil,diag,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",18,-116); scroll:SetSize(654,468); scroll:Hide(); f.discoveryScroll=scroll
    local report=CreateFrame("EditBox",nil,scroll); report:SetMultiLine(true); report:SetAutoFocus(false)
    report:SetFontObject("GameFontHighlightSmall"); report:SetWidth(638); report:SetHeight(468)
    report:SetScript("OnEscapePressed",function(control) control:ClearFocus() end)
    scroll:SetScrollChild(report); f.discoveryReport=report
    f.reportMeasure=label(diag,"",0,0,"GameFontHighlightSmall",638); f.reportMeasure:Hide()
    f.resizeDiscoveryReport=function()
      local text=report:GetText() or ""; f.reportMeasure:SetText(text)
      local height=f.reportMeasure:GetStringHeight()
      if type(height)~="number" then local _,lines=text:gsub("\n",""); height=(lines+1)*14 end
      report:SetHeight(math.max(468,height+12))
    end
    report:SetScript("OnTextChanged",f.resizeDiscoveryReport)
    button(diag,L("Unknown items"),410,-604,124,function() B:ShowDiscoveryReport() end)
    button(diag,L("Rescan bags"),546,-604,130,function()
      if A.Combat() then return end
      B:DiscoverConsumables(); B:ShowDiscoveryReport()
    end)
    label(diag,"Unknown items is a copyable report for improving item support, not a list of items BuffTap will use.",18,-644,"GameFontDisableSmall",672)
    self:BuildHelperPage(f)

    local function acceptEdit(e,key)
      e:SetScript("OnTextChanged",function(s,userInput) if userInput then s.unsaved=true end end)
      e:SetScript("OnEnterPressed",function(s) local v=tonumber(s:GetText()); if v and not A.Combat() then if key=="opacity" then v=math.max(0,math.min(100,v))/100 end; setAndRefresh(key,v) end; s.unsaved=nil; s:ClearFocus(); B:Options() end)
      e:SetScript("OnEscapePressed",function(s) s.unsaved=nil; s:ClearFocus(); B:Options() end)
    end
    acceptEdit(f.sizeEdit,"size"); acceptEdit(f.opacityEdit,"opacity"); acceptEdit(f.xEdit,"x"); acceptEdit(f.yEdit,"y")

    -- SetScript replaces earlier hooks, so the camping update that used to be hooked lives here.
    f:SetScript("OnHide",function()
      if not A.Combat() then B:UpdateCamping() end
      if f.activeSelector then f.activeSelector:Hide() end
      if B.itemPicker then B.itemPicker:Hide() end
      if f.blessingMenu then f.blessingMenu:Hide() end
      if f.resetConfirm then f.resetConfirm:Hide() end
      if B.appearancePreview then B.appearancePreview:Hide() end
    end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:SetScript("OnEvent",function(_,event)
      if event=="PLAYER_REGEN_DISABLED" then f:StopMovingOrSizing(); f:Hide()
      end
    end)
    self:BuildRefinedOptions({label=label,button=button,flatButton=flatButton,check=check,selector=selector,card=card,editbox=editbox,slider=compactSlider,help=addHelp},TAB)
    setTab(1)
  end

  local width,height=UIParent:GetWidth(),UIParent:GetHeight()
  if A.Number(width) and A.Number(height) then f:SetScale(math.min(self.db.optionsScale or 1,(width-32)/OPTIONS_WIDTH,(height-32)/OPTIONS_HEIGHT)) end
  self:UpdateHelperOptions()
  self:UpdateProfileOptions()
  self:UpdateContextControls(); f.setupBadge:SetText(self:SituationBadge())
  self:UpdateSupplyOptions()
  local paladin=A.Call(function() local _,token=UnitClass("player"); return token end)=="PALADIN"
  f.buffInstruction:SetText(L("Choose your buffs. Move the most important ones to the top."))
  f.targetBlessingPanel:SetShown(paladin); f.targetClassAware:SetChecked(self.db.targetClassBlessings)
  f.targetBlessingFallback:SetChecked(self.db.targetBlessingFallback)
  for _,pick in ipairs(f.targetBlessingPicks) do pick:SetShown(self.db.targetClassBlessings); pick.classLabel:SetShown(self.db.targetClassBlessings); pick:Update(); pick:SetAvailable(self.db.targetClassBlessings and (self.db.friendlyTarget or self.db.nearbyEnabled)) end
  f.targetBlessingInstruction:SetText(L(not (self.db.friendlyTarget or self.db.nearbyEnabled) and "Enable friendly target buffing to use these class choices." or not self.db.targetClassBlessings and "Enable class-aware target blessings to customize each class." or "Open a class to check and order blessings. All use the refresh above. Automatic uses enabled Buffs and their order, filtered for this class."))
  f.targetBlessingFallback:ClearAllPoints(); f.targetBlessingFallback:SetPoint("TOPLEFT",6,self.db.targetClassBlessings and -128 or -28)
  f.targetBlessingInstruction:ClearAllPoints(); f.targetBlessingInstruction:SetPoint("TOPLEFT",6,self.db.targetClassBlessings and -160 or -60)
  local simplePal=paladin and self.db.targetClassBlessings
  f.targetHeaders.title:SetText(L(simplePal and "Independent target buffs" or "Spell availability & refresh timing")); T.SectionTitle(f.targetHeaders.title)
  f.targetHeaders.help:SetText(L("Choose allowed spells and optional refresh overrides for friendly targets."))
  f.targetHeaders:SetShown(not simplePal); f.targetScroll:SetShown(not simplePal)
  f.targetHeaders:ClearAllPoints(); f.targetHeaders:SetPoint("TOPLEFT",0,paladin and -264 or -168)
  f.targetScroll:ClearAllPoints(); f.targetScroll:SetPoint("TOPLEFT",14,paladin and -342 or -246); f.targetScroll:SetPoint("BOTTOMRIGHT",-34,54)
  f.pauseResting:SetChecked(self.db.pauseResting)
  self:PolishOptionsSurfaces()
  f.enable:SetChecked(self.db.enabled)
  f.versionText:SetText("v"..self.version)
  f.friendlyTarget:SetChecked(self.db.friendlyTarget)
  f.nearbyEnable:SetChecked(self.db.nearbyEnabled==true)
  f.nearbyAll:SetChecked(self.db.nearbyShowAll==true)
  f.nearbyBuffing:SetChecked(self.db.nearbyBuffing~=false)
  f.nearbyInvites:SetChecked(self.db.nearbyInvites~=false)
  f.targetDefaultSlider.silent=true; f.targetDefaultSlider:SetValue(self.db.targetSeconds); f.targetDefaultSlider.valueText:SetText(formatSeconds(self.db.targetSeconds)); f.targetDefaultSlider.silent=false
  if not paladin then
    local raid=B:EditingGroupContext()=="Raid"
    T.Navigation(f.groupParty,not raid); T.Navigation(f.groupRaid,raid)
    f.groupTitle:SetText(L(raid and "Raid buffing" or "Party buffing"))
    f.groupIntro:SetText(L(raid and "Choose raid groups, recipient classes and group-spell thresholds." or "Preferences for your five-player party. Raid settings are separate."))
    f.groupEnable.Text:SetText(L(raid and "Enable raid buffing" or "Enable party buffing"))
    f.groupEnable:SetChecked(self:GroupEditorSettings().group); f.smartGroup:SetChecked(self:GroupEditorSettings().smartGroup)
    if f.buffPets then f.buffPets:SetChecked(self.db.buffPets==true); f.readyTopUp:SetChecked(self.db.readyCheckTopUp~=false) end
    for i=1,8 do
      local state=self:GroupColumnState(i,B:EditingGroupContext())
      local c=f.groupChecks[i]
      c:SetShown(raid or i==1); c.Text:SetText(raid and "G"..i or L("Include party"))
      c:SetChecked(state=="on")
      if c.mixedDash then c.mixedDash:SetShown(state=="mixed") end
    end
    f.groupNeedSlider.silent=true; f.groupNeedSlider:SetValue(self:GroupEditorSettings().groupNeed); f.groupNeedSlider.valueText:SetText(tostring(self:GroupEditorSettings().groupNeed).."+"); f.groupNeedSlider.silent=false
    local smartAlpha=(self:GroupEditorSettings().group and self:GroupEditorSettings().smartGroup) and 1 or 0.45
    if self:GroupEditorSettings().group and self:GroupEditorSettings().smartGroup then f.groupNeedSlider:Enable() else f.groupNeedSlider:Disable() end
    f.groupNeedSlider:SetAlpha(smartAlpha)

    for _,r in ipairs(f.assignRows) do r:Hide() end
    for _,btn in ipairs(f.assignButtons) do btn:Hide() end
    local assignmentBuffs=groupAssignableBuffs()
    local found=false; for _,b in ipairs(assignmentBuffs) do if b.key==f.selectedAssignment then found=true end end
    if not found then f.selectedAssignment=assignmentBuffs[1] and assignmentBuffs[1].key end
    f.assignEmpty:SetShown(#assignmentBuffs==0)
    for rowIndex,b in ipairs(assignmentBuffs) do
      local row=f.assignRows[rowIndex]
      if not row then
        row=CreateFrame("Frame",nil,f.assignChild); row:SetSize(458,288); row.visualInsetX=8 -- the surrounding card is the only surface
        row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(32,32); row.icon:SetPoint("TOPLEFT",8,-4)
        row.name=label(row,"",48,-5,"GameFontNormalLarge",402)
        row.detail=label(row,"",48,-29,"GameFontDisableSmall",402)
        row.groupHeading=label(row,L("Raid groups"),8,-60,"GameFontNormal")
        row.checks={}
        for i=1,8 do
          local idx=i
          local c=check(row,tostring(i),8+(i-1)*54,-78,function(s)
            local parent=s:GetParent(); local def=parent.def
            if def and not A.Combat() then
              local map=B:EnsureBuffGroups(def,B:EditingGroupContext()); map[idx]=s:GetChecked()==true
              B:NormalizeBuffGroups(def,B:EditingGroupContext()); B:ReconcileRaidGroupColumn(idx,B:EditingGroupContext())
              B:RequestRefresh("buff group assignment",0); B:Options()
            end
          end)
          c:SetSize(20,20); row.checks[i]=c
        end
        row.need=compactSlider(row,2,5,1,168,function(v) return tostring(v).."+" end,function(slider,value)
          local def=slider:GetParent().def
          if def then B:SetGroupNeed(def,value,B:EditingGroupContext()); B:RequestRefresh("group threshold",0) end
        end)
        row.need:SetPoint("TOPLEFT",104,-263)
        row.needLabel=label(row,"Group spell at",8,-263,"GameFontHighlightSmall",140)
        -- Who gets this buff: by class (the checkboxes below), or every tank / every healer whatever the class.
        label(row,"Who gets this buff",8,-116,"GameFontNormal")
        row.roleButtons={}
        for i,spec in ipairs({{"class","By class"},{"tank","Tanks"},{"healer","Healers"}}) do
          local mode=spec[1]
          local b=flatButton(row,spec[2],176+(i-1)*94,-110,90,function()
            local def=row.def; if not def or A.Combat() then return end
            B:GroupEditorSettings().buffRoles[B:RootKey(def)]=(mode~="class") and mode or nil
            B.roleCache=nil; B:InvalidateAura(); B:RequestRefresh("buff role",0); B:Options()
          end)
          b:SetHeight(24); b.navStyle="segment"; b.roleMode=mode; row.roleButtons[i]=b
          addHelp(b,spec[2],mode=="class" and "The class checkboxes below decide who gets this buff." or mode=="tank" and "Every tank in your group gets this buff, whatever their class. Class choices below are not used. Mark target role sets a role yourself." or "Every healer in your group gets this buff, whatever their class. Class choices below are not used. Mark target role sets a role yourself.")
        end
        row.filterHint=label(row,"",8,-221,"GameFontDisableSmall",450)
        row.classes={}
        for i,class in ipairs(B.RecipientClasses) do
          local token=class
          local className=(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or (token:sub(1,1)..token:sub(2):lower())
            local c=check(row,className,8+((i-1)%3)*152,-138-math.floor((i-1)/3)*25,function(s)
            local def=row.def
            if not def or A.Combat() then return end
            local key=B:RootKey(def)
            B:GroupEditorSettings().buffClasses[key]=B:GroupEditorSettings().buffClasses[key] or {}
            B:GroupEditorSettings().buffClasses[key][token]=s:GetChecked()==true
            B:RequestRefresh("buff class assignment",0); B:Options()
          end)
          c:SetSize(20,20)
          addHelp(c,className,"Party/raid recipients must match both the selected group and class. Personal buffs and explicit friendly targets ignore these filters. Class does not identify the tank role.")
          row.classes[token]=c
        end
        row.resetClasses=button(row,L("Reset"),374,-258,80,function()
          if row.def and not A.Combat() then B:GroupEditorSettings().buffClasses[B:RootKey(row.def)]=nil; B:RequestRefresh("reset classes",0); B:Options() end
        end)
        row.allClasses=button(row,"All classes",280,-258,86,function()
          if not row.def or A.Combat() then return end
          local map={}; for _,class in ipairs(B.RecipientClasses) do map[class]=true end
          B:GroupEditorSettings().buffClasses[B:RootKey(row.def)]=map; B:RequestRefresh("all classes",0); B:Options()
        end)
        f.assignRows[rowIndex]=row
      end
      row.def=b; row:ClearAllPoints(); row:SetPoint("TOPLEFT",8,-6); row:SetShown(f.selectedAssignment==b.key); row.name:SetText(spellLabel(b)); row.icon:SetTexture(buffIcon(b))
      local select=f.assignButtons[rowIndex]
      if not select then
        select=flatButton(f.assignList,"",0,-(rowIndex-1)*42,174,function(btn) f.selectedAssignment=btn.def.key; B:Options() end)
        select:SetHeight(38)
        select.icon=select:CreateTexture(nil,"ARTWORK"); select.icon:SetSize(24,24); select.icon:SetPoint("TOPLEFT",6,-7)
        select.title=label(select,"",36,-6,"GameFontHighlightSmall",132)
        f.assignButtons[rowIndex]=select
      end
      select.def=b; select.title:SetText(spellLabel(b)); select.icon:SetTexture(buffIcon(b)); select:Show()
      select.navStyle="list"; T.Navigation(select,f.selectedAssignment==b.key)
      local groupDef=b.groupKey and self:FindBuff(b.groupKey)
      row.detail:SetText(groupDef and (L("Group")..": "..spellLabel(groupDef)) or L("Single-target only"))
      row.groupHeading:SetText(L(raid and "Raid groups" or "Party recipients"))
      row.filterHint:SetText(L(raid and "Recipients must match group AND class. Personal buffs and open-world targets ignore these filters." or "Choose which classes in your party receive this buff. Personal buffs and open-world targets ignore these filters."))
      for i=1,8 do row.checks[i]:SetShown(raid or i==1); row.checks[i].Text:SetText(raid and tostring(i) or L("Include party")); row.checks[i]:SetChecked(self:GroupSelected(b,i,B:EditingGroupContext())) end
      for class,c in pairs(row.classes) do c:SetChecked(self:GroupClassAllowed(b,class,B:EditingGroupContext())) end
      local roleMode=self:BuffRoleMode(b,B:EditingGroupContext())
      for _,rb in ipairs(row.roleButtons) do T.Navigation(rb,rb.roleMode==roleMode) end
      for _,c in pairs(row.classes) do c:SetEnabled(roleMode=="class"); c:SetAlpha(roleMode=="class" and 1 or .35) end
      row.allClasses:SetShown(roleMode=="class"); row.resetClasses:SetShown(roleMode=="class")
      if roleMode~="class" then
        row.filterHint:SetText(L(roleMode=="tank" and "Every tank in your group gets this buff, whatever their class. Class choices below are not used." or "Every healer in your group gets this buff, whatever their class. Class choices below are not used."))
      end
      if f.roleGuess then f.roleGuess:SetChecked(self.db.roleGuess==true) end
      if groupDef then
        row.needLabel:Show(); row.need:Show(); row.need.valueText:Show(); row.need.silent=true; row.need:SetValue(self:GroupNeed(groupDef,B:EditingGroupContext())); row.need.valueText:SetText(tostring(self:GroupNeed(groupDef,B:EditingGroupContext())).."+"); row.need.silent=false
        if self:GroupEditorSettings().group and self:GroupEditorSettings().smartGroup then row.need:Enable(); row.need:SetAlpha(1) else row.need:Disable(); row.need:SetAlpha(0.45) end
      else row.need:Hide(); row.need.valueText:Hide(); row.needLabel:Hide() end
    end
    f.assignList:SetHeight(math.max(1,#assignmentBuffs*42))
    f.assignScroll:SetHeight(math.min(252,math.max(42,#assignmentBuffs*42)))
  end
  self:UpdateBlessingOptions()

  for _,r in ipairs(f.targetRows) do r:Hide() end
  local targetBuffs=targetAssignableBuffs()
  if simplePal then local independent={}; for _,b in ipairs(targetBuffs) do if b.kind~="blessing" then independent[#independent+1]=b end end; targetBuffs=independent end
  for rowIndex,b in ipairs(targetBuffs) do
    local row=f.targetRows[rowIndex]
    if not row then
      row=CreateFrame("Frame",nil,f.targetChild,"BackdropTemplate"); row:SetSize(650,48)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(unpack(T.row)); T.Row(row,8)
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
      row.threshold=compactSlider(row,0,1800,30,210,formatSeconds,function(slider,value)
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
    row.detail:SetText(not learnedSpell(b) and unlearnedText() or b.classWide and L("Party/raid member only") or self:Enabled(b) and L("Single-target spell") or L("Disabled on Buffs tab"))
    local custom=self.db.targetBuffSeconds[b.key]~=nil
    row.custom:SetChecked(custom)
    local seconds=self:TargetRebuffSeconds(b)
    -- Short buffs on targets wait until they wear off unless given their own timing (see B:Missing).
    if not custom then local duration=self:BuffDuration(b); if b.noTimer or (duration and duration<120) then seconds=0 end end
    row.threshold.silent=true; row.threshold:SetValue(seconds); row.threshold.valueText:SetText(formatSeconds(seconds)); row.threshold.silent=false
    if custom then row.threshold:Enable(); row.threshold:SetAlpha(1) else row.threshold:Disable(); row.threshold:SetAlpha(0.45) end
  end
  f.targetChild:SetHeight(math.max(1,#targetBuffs*52))

  if f.consumablesEnable then
    f.consumablesEnable:SetChecked(self:EditorSettings("consumables").consumablesEnabled==true); f.consumableRestPause:SetChecked(self.db.consumablesPauseResting==true); f.consumableInstanceOnly:SetChecked(self.db.consumablesInstanceOnly==true)
    f.consumeBuild:Hide()
    if self.RebuildConsumableCache then self:RebuildConsumableCache(false) end
    for index,family in ipairs(self.ConsumableFamilies or {}) do
      local row=f.consumableRows[index]
      if row then
        row.enable:SetChecked(self.ConsumableFamilySelected and self:ConsumableFamilySelected(family,self:EditorSettings("consumables")) or false)
        local choice,icon=consumableChoiceLabel(family)
        row.choice:SetText(choice)
        row.icon:SetTexture(icon or 134400)
        local preferred=self.PreferredConsumableItem and self:PreferredConsumableItem(family,self:EditorSettings("consumables"))
        local current=preferred and self:ConsumableCount(preferred.id) or 0
        row.inventory:SetText(current>0 and ("|cff88dd88"..current.." in bags|r") or "No usable stock")
        addHelp(row,"Supported items in bags",self:ConsumableInventorySummary(family,20))
        local active=self:ConsumableFamilyEnabled(family,self:EditorSettings("consumables"))
        if active then row.threshold:Enable(); row.threshold:SetAlpha(1) else row.threshold:Disable(); row.threshold:SetAlpha(0.45) end
        local threshold=self:ConsumableThreshold(family,self:EditorSettings("consumables"))
        row.threshold.silent=true; row.threshold:SetValue(threshold); row.threshold.valueText:SetText(formatSeconds(threshold)); row.threshold.silent=false
        row.prev:ClearAllPoints(); row.prev:SetPoint("TOPLEFT",584,-8); row.prev:SetSize(86,26); row.prev:SetText(L("Choose"))
        row.prev:SetScript("OnClick",function() B:ChooseConsumable(family,row.prev,B:EditorContext("consumables")) end)
        row.prev:Show()
        if family.protectPresent then row.threshold:Hide(); row.threshold.valueText:Hide() end
        local chosen=self:ConsumableChoiceID(family,self:EditorSettings("consumables"))
        if chosen then
          local count=self:ConsumableCount(chosen)
          row.inventory:SetText(count>0 and ("|cff88dd88"..count.." in bags|r") or "|cffffbb44Out of stock|r")
        elseif family.explicitChoice then row.choice:SetText(L("Choose an item to track")); row.inventory:SetText(L("Not selected")) end
      end
    end
    local paused=false; for _ in pairs(self.effectPauses or {}) do paused=true; break end
    f.consumePauseStatus:SetText(paused and L("An effect was not observed. Its reminder is paused until you retry.") or "")

  end

  for _,choice in ipairs(self:ReminderFonts()) do if choice.key==self:NormalizeTextFontKey(self.db.labelFont) then f.fontButton:SetText(L(choice.name)) end end
  for _,choice in ipairs(self:ReminderColors()) do if choice.key==self.db.labelColor then f.colorButton:SetText(L(choice.name)) end end
  f.labelSizeButton:SetText(self:TextSizeLabel(self.db.labelSize))
  for _,v in ipairs(self:TextOutlineChoices()) do if v.key==self.db.labelOutline then f.labelOutlineButton:SetText(L(v.name)) end end
  f.labelGap.silent=true; f.labelGap:SetValue(self.db.labelGap); f.labelGap.silent=false
  f.bindingText:SetText(L("Current: %s",#self.db.keys>0 and table.concat(self.db.keys,", ") or L("none")))
  if f.nearbyBindingText then f.nearbyBindingText:SetText(#(self.db.nearbyKeys or {})>0 and L("Nearby key: %s",table.concat(self.db.nearbyKeys,", ")) or L("Nearby key: none, Nearby uses your main binding")) end
  for _,pair in ipairs({{f.sizeEdit,self.db.size},{f.opacityEdit,math.floor(self.db.opacity*100+0.5)},{f.xEdit,math.floor(self.db.x+0.5)},{f.yEdit,math.floor(self.db.y+0.5)}}) do
    if not pair[1].unsaved and pair[1]:HasFocus()~=true then pair[1]:SetText(tostring(pair[2])) end
  end
  for _,choice in ipairs(self:SoundChoices()) do
    if choice.key==self.db.reminderSound then f.reminderSoundButton:SetText(L(choice.name)) end
    if choice.key==self.db.supplySound then f.supplySoundButton:SetText(L(choice.name)) end
    if f.campSoundButton and choice.key==self.db.campAlertSound then f.campSoundButton:SetText(L(choice.name)) end
  end
  f.channelButton:SetText(L(self.db.soundChannel=="Master" and L("Master") or L("Sound effects")))
  f.minimapCheck:SetChecked(not self.db.minimap.hide)
  f.brokerCheck:SetChecked(self.db.brokerEnabled)
  f.soundInterval.silent=true; f.soundInterval:SetValue(self.db.soundInterval); f.soundInterval.silent=false
  f.statusText:SetText(self:FriendlyStatus())
  if self.action then f.statusText:SetTextColor(.56,.88,.72) else f.statusText:SetTextColor(unpack(T.muted)) end
  if self.appearancePreview and self.appearancePreview:IsShown() then self:PreviewAppearance() end
  self:UpdateCampingOptions()
  f.showReminderCheck:SetChecked(self.db.showReminder); f.soundCheck:SetChecked(self.db.sound); f.effectButton:SetText(L(({none="Effect: None",soft="Effect: Soft glow",pulse="Effect: Pulse",pixel="Effect: Pixel border",autocast="Effect: Sparkles",proc="Effect: Spell glow",shine="Effect: Shine",ripple="Effect: Ripple",bounce="Effect: Bounce",orbit="Effect: Orbit"})[self:IconEffectStyle()] or "Effect: Soft glow")); f.effectColorButton:SetText(L(({gold="Gold",cyan="Cyan",green="Green",red="Red",white="White"})[self.db.effectColor] or "Gold")); f.effectSpeedButton:SetText(L(({slow="Slow",normal="Normal",fast="Fast"})[self.db.effectSpeed] or "Normal"))
  f.buffNameCheck:SetChecked(self.db.showBuffName); f.targetNameCheck:SetChecked(self.db.showTargetName)
  f.timerCheck:SetChecked(self.db.showTimer); f.groupBadgeCheck:SetChecked(self.db.showGroupBadge)
  if f.effectUrgency then f.effectUrgency:SetChecked(self.db.effectUrgency==true); f.effectOnce:SetChecked(self.db.effectOnce==true) end
  f.profileCheck:SetChecked(self.profileEnabled==true)
  f.rebuffSlider.silent=true; f.rebuffSlider:SetValue(self:EditorSettings("buffs").seconds); f.rebuffSlider.valueText:SetText(formatSeconds(self:EditorSettings("buffs").seconds)); f.rebuffSlider.silent=false

  local weaponClass=self.WeaponReminderClass and self:WeaponReminderClass()
  f.weaponUnavailable:Hide()
  f.weaponSectionHeading:SetText(L(weaponClass and "Poisons / class imbues" or "Hands to maintain")); T.SectionTitle(f.weaponSectionHeading)
  -- Classes without imbues choose their hands directly beside the coating rows.
  local function place(control,x,y) control:ClearAllPoints(); control:SetPoint("TOPLEFT",x,y) end
  local coatingY=weaponClass and -220 or -98
  place(f.coatingCard,12,coatingY); place(f.coatingHeading,26,coatingY-14)
  T.CardShown(f.weaponClassCard,weaponClass~=nil)
  f.weaponSectionHeading:SetShown(weaponClass~=nil)
  for i,hand in ipairs({"main","off"}) do
    place(f.coatingPickers[hand],180,coatingY-34-(i-1)*48)
    place(f.coatingHandLabels[hand],28,coatingY-40-(i-1)*48)
    f.coatingHandLabels[hand]:SetShown(weaponClass~=nil)
  end
  place(f.weaponMain,26,weaponClass and -133 or coatingY-35)
  place(f.weaponOff,26,weaponClass and -171 or coatingY-83)
  local timingY=weaponClass and -358 or -236
  place(f.weaponTimingCard,12,timingY); place(f.weaponTimingLabel,26,timingY-18)
  place(f.weaponTiming,220,timingY-14); place(f.weaponReplace,26,timingY-58); place(f.weaponRestPause,400,timingY-58)
  place(f.weaponHandsHint,14,weaponClass and -500 or -376)
  place(f.weaponModeHint,14,weaponClass and -530 or -420)
  place(f.weaponStatus,14,weaponClass and -556 or -458)
  f.weaponPoisonHint:SetShown(weaponClass=="ROGUE")
  for _,control in ipairs({f.weaponHint,f.weaponEnable,f.weaponApply,f.weaponMain,f.weaponOff,f.weaponTimingLabel,f.weaponTiming,f.weaponReplace,f.weaponStatus,f.weaponHandsHint}) do control:Show() end
  for _,pick in pairs(f.weaponPickers) do pick:SetShown(weaponClass~=nil); pick.menu:Hide() end
  f.weaponEnable:SetChecked(self:EditorSettings("weapons").weaponReminder==true); f.weaponApply:SetText(L(self.db.weaponApply and "Remind and apply" or "Remind only"))
  f.weaponModeHint:SetText(L(self.db.weaponApply and "Your scroll or click applies the selected weapon buff, out of combat." or "Alerts only: apply weapon buffs manually. Your preferences remain saved."))
  f.weaponMain:SetChecked(self:EditorSettings("weapons").weaponMainHand~=false); f.weaponOff:SetChecked(self:EditorSettings("weapons").weaponOffHand~=false)
  f.weaponReplace:SetChecked(self.db.weaponReplace==true); f.weaponRestPause:SetChecked(self.db.weaponsPauseResting==true)
  f.weaponOff:SetShown(weaponClass=="ROGUE" or not weaponClass)
  f.weaponTiming.silent=true; f.weaponTiming:SetValue(self:EditorSettings("weapons").weaponSeconds); f.weaponTiming.valueText:SetText(formatSeconds(self:EditorSettings("weapons").weaponSeconds)); f.weaponTiming.silent=false
  local status=self:WeaponReminderSummary()
  f.weaponStatus:SetText(status)
  for hand,pick in pairs(f.weaponPickers) do
    pick:SetShown(weaponClass~=nil and (hand=="main" or weaponClass=="ROGUE"))
    local handKey=hand; local selected=self:WeaponPreference(hand,self:EditorSettings("weapons"))
    pick:SetText(selected and selected.name or L("Choose preferred buff"))
    local src=selected and self:WeaponChoiceSource(selected)
    local preferredIcon=selected and self:WeaponChoiceIcon(selected)
    pick.icon:SetTexture(src and src.icon or preferredIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    for _,row in ipairs(pick.menu.rows) do row:Hide() end
    local choices={{name=B:ItemImbueClass(weaponClass) and L("None") or "None (manual missing-buff alert)"}}
    for _,choice in ipairs(self.WeaponChoices) do if choice.class==weaponClass then choices[#choices+1]=choice end end
    for i,choice in ipairs(choices) do
      local choiceKey=choice.key
      local row=pick.menu.rows[i]
      if not row then row=flatButton(pick.menu.child,"",0,-(i-1)*28,466,function(control)
        if A.Combat() then return end
        B:EditorSettings("weapons").weaponChoices[control.hand]=control.choice; B.weaponPending=nil; B:InvalidateSupplies(false); B:RequestRefresh("weapon preference",0); B:Options()
      end); row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",4,0); pick.menu.rows[i]=row end
      row.hand=handKey; row.choice=choiceKey
      local source,why=self:WeaponChoiceSource(choiceKey and choice or nil)
      local icon=source and source.icon or (choiceKey and self:WeaponChoiceIcon(choice))
      row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      local incompatible=choiceKey and B:ItemImbueClass(choice.class) and B:CoatingWeaponMatches(16,choice)~=true
      row:SetText(choice.name..(choiceKey and (incompatible and " (incompatible weapon)" or source and (source.count and " (in bags: "..source.count..")" or " (learned)") or " (unavailable)") or "")); fitButtonText(row,420); row:Show()
      addHelp(row,choice.name,why or "Select this buff for this hand. Highest available rank is used.")
    end
    pick.menu.child:SetHeight(#choices*28)
  end

  for hand,pick in pairs(f.coatingPickers) do
    pick.menu:Hide()
    local selected=self:CoatingPreference(hand,self:EditorSettings("weapons"))
    local src=selected and self:WeaponChoiceSource(selected)
    pick:SetText(selected and selected.name or L("None")); fitButtonText(pick,420)
    pick.icon:SetShown(selected~=nil)
    pick.icon:SetTexture(src and src.icon or (selected and self:WeaponChoiceIcon(selected)) or "Interface\\Icons\\INV_Misc_QuestionMark")
    local choices={{name=L("None")}}
    for _,choice in ipairs(self.CoatingChoices) do choices[#choices+1]=choice end
    for i,choice in ipairs(choices) do
      local row=pick.menu.rows[i]
      if not row then
        row=flatButton(pick.menu.child,"",0,-(i-1)*28,466,function(control)
          if A.Combat() then return end
          B:EditorSettings("weapons").weaponCoatings[control.hand]=control.choice; B.weaponPending=nil; B:InvalidateSupplies(false); B:RequestRefresh("coating preference",0); B:Options()
        end)
        row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",4,0); pick.menu.rows[i]=row
      end
      row.hand=hand; row.choice=choice.key
      local source,why
      if choice.key then source,why=self:WeaponChoiceSource(choice) end
      local matches=choice.key and self:CoatingWeaponMatches(hand=="main" and 16 or 17,choice)
      local status=choice.key and (matches~=true and " (incompatible weapon)" or source and " (uses: "..source.count..")" or " (unavailable)") or ""
      row:SetText(choice.name..status); fitButtonText(row,420)
      row.icon:SetTexture(source and source.icon or (choice.key and self:WeaponChoiceIcon(choice)) or "Interface\\Icons\\INV_Misc_QuestionMark")
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
      row=CreateFrame("Frame",nil,f.buffChild,"BackdropTemplate"); row:SetSize(644,54)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(unpack(T.row)); T.Row(row,8)
      row.check=check(row,"",14,-15,function(s)
        local parent=s:GetParent(); local def=parent.def
        if def and not A.Combat() then B:EditorSettings("buffs").buffs[def.key]=s:GetChecked()==true; B:RequestRefresh("buff toggle",0) end
        if parent.applyDim then parent.applyDim(s:GetChecked()==true) end
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(34,34); row.icon:SetPoint("TOPLEFT",46,-10)
      row.name=label(row,"",90,-9,"GameFontHighlight",186)
      row.groupIcon=row:CreateTexture(nil,"ARTWORK"); row.groupIcon:SetSize(16,16); row.groupIcon:SetPoint("TOPLEFT",90,-30)
      row.detail=label(row,"",112,-29,"GameFontDisableSmall",164)
      row.rebuff=compactSlider(row,0,600,5,196,formatSeconds,function(slider,value)
        local parent=slider:GetParent(); local def=parent.def
        if def then
          B:EditorSettings("buffs").buffSeconds[def.key]=value
          if parent.default then parent.default:Show() end
          B:RequestRefresh("buff rebuff threshold",0.08)
        end
      end)
      row.rebuff:SetPoint("TOPLEFT",284,-19)
      row.default=button(row,L("Default"),488,-14,62,function(btn)
        local def=btn:GetParent().def
        if def and not A.Combat() then B:EditorSettings("buffs").buffSeconds[def.key]=nil; B:RequestRefresh("rebuff default",0); B:Options() end
      end)
      addHelp(row.default,"Use default timing","Remove this buff's custom refresh timing and use the default rebuff threshold below. This does not reset its priority or enable setting.")
      for _,direction in ipairs({-1,1}) do
        local delta=direction
        local arrow=arrowButton(row,"",delta<0 and 556 or 582,-15,24,function(btn)
          if A.Combat() then return end
          local current=btn:GetParent().def; local list=logicalBuffs()
          for i,def in ipairs(list) do if current and def.key==current.key and list[i+delta] then B:MoveBuffPriority(def.key,list[i+delta].key); return end end
        end)
        local t=arrow:CreateTexture(nil,"ARTWORK"); t:SetPoint("CENTER"); T.Glyph(t,delta<0 and "up" or "down",12)
        addHelp(arrow,delta<0 and "Move earlier" or "Move later","Move this buff earlier or later in the list. Priority numbers update automatically.")
        if delta<0 then row.up=arrow else row.down=arrow end
      end
      -- Rank badge: read-only. The arrows are the one way to reorder.
      row.order=CreateFrame("Frame",nil,row,"BackdropTemplate"); row.order:SetSize(28,24); row.order:SetPoint("TOPLEFT",612,-15)
      row.order:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row.order:SetBackdropColor(1,1,1,.05); T.Round(row.order,5,"surface"); T.LockBorder(row.order,0,0,0,0)
      row.order:EnableMouse(true)
      row.order.text=row.order:CreateFontString(nil,"OVERLAY"); row.order.text:SetFontObject(T.fonts.Value); row.order.text:SetPoint("CENTER",0,0)
      addHelp(row.order,"Buff priority","Lower numbers are checked first. Use the arrows to move a buff earlier or later.")
      row.applyDim=function(on)
        local alpha=on and 1 or .5
        for _,part in ipairs({row.icon,row.name,row.detail,row.groupIcon,row.rebuff,row.default,row.up,row.down,row.order}) do if part then part:SetAlpha(alpha) end end
      end
      f.buffRows[visible]=row
    end
    row.def=b; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(visible-1)*60); row:Show(); row.check:SetChecked(self:Enabled(b,self:EditorSettings("buffs"))); row.name:SetText(spellLabel(b)); row.icon:SetTexture(buffIcon(b))
    local groupName=pairedGroupName(b)
    if b.groupKey then
      local groupDef=self:FindBuff(b.groupKey)
      row.groupIcon:SetTexture(groupDef and buffIcon(groupDef) or 134400); row.groupIcon:Show()
      row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",112,-29); row.detail:SetText((groupName or "Group version").."  -  "..L("group spell"))
    else
      row.groupIcon:Hide(); row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",90,-29)
      row.detail:SetText(b.underwater and L("Reminds when underwater") or b.noTimer and L("Reminds when it wears off") or b.kind=="self" and L("Self buff") or L("Single-target buff"))
    end
    if not learnedSpell(b) then
      row.groupIcon:Hide(); row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",90,-29); row.detail:SetText(unlearnedText())
    elseif b.groupKey and not learnedSpell(self:FindBuff(b.groupKey)) then
      local groupDef=self:FindBuff(b.groupKey)
      row.detail:SetText((groupName or (groupDef and spellLabel(groupDef)) or L("group spell"))..": "..unlearnedText())
    end
    row.up:SetEnabled(visible>1); row.down:SetEnabled(visible<#list)
    row.order.text:SetText(tostring(visible))
    -- Without its own timing, show what the buff really gets: its length decides (see DefaultRebuffSeconds).
    local settings=self:EditorSettings("buffs"); local own=type(settings.buffSeconds[b.key])=="number"
    local threshold=own and self:RebuffSeconds(b,settings) or self:DefaultRebuffSeconds(b,settings.seconds)
    row.rebuff.silent=true; row.rebuff:SetValue(threshold); row.rebuff.valueText:SetText(formatSeconds(threshold)); row.rebuff.silent=false
    -- Stances such as Aquatic Form have no duration, so there is nothing to time.
    row.rebuff:SetShown(not (b.stance or b.noTimer))
    -- Default only appears when this buff has its own timing.
    row.default:SetShown(not (b.stance or b.noTimer) and type(self:EditorSettings("buffs").buffSeconds[b.key])=="number")
    row.applyDim(row.check:GetChecked()==true)
  end
  f.emptyBuffs:SetShown(visible==0)
  f.buffChild:SetHeight(math.max(1,visible*60))
  if f.diagVersion then f.diagVersion:SetText("BuffTap v"..tostring(self.version or "unknown")) end
  if f.pvpProtection then f.pvpProtection:SetChecked(self.db.pvpProtection==true) end
  if f.diagHideNames then f.diagHideNames:SetChecked(self.reportHideNames~=false); f.diagPauseNotes:SetChecked(self.db.pauseNotes~=false) end
  if f.diagText then
    local text=table.concat(self:DiagnosticsLines(),"\n")
    f.diagText:SetText(text)
    local height=f.diagText:GetStringHeight()
    if type(height)~="number" then local _,lines=text:gsub("\n",""); height=(lines+1)*14 end
    f.diagContent:SetHeight(math.max(468,height+12))
  end
  self:UpdateRefinedOptions(); f:Show(); f:Raise(); self:UpdateOptionsPreviews()
end


function B:UpdateCampingOptions(state)
  local f=self.options
  if not f or not f.campingPage then return end
  state=state or self:CampingState()
  local camp=state.globalUnknown or state.campUnknown
  local bag=state.globalUnknown or state.bagUnknown
  f.campingStatus:SetText(L("Camp benefits").."\n"..(camp and L("Unavailable") or state.active and (state.remaining and formatSeconds(state.remaining) or L("active")) or L("missing")))
  f.sleepingStatus:SetText(L("Sleeping bag XP").."\n"..(bag and L("Unavailable") or state.bagNotNeeded and L("not needed") or state.bagActive and (tostring(state.bagStacks).."/3"..(state.bagRemaining and " - "..formatSeconds(state.bagRemaining) or "")) or L("missing")))
  f.campingEnable:SetChecked(self.db.campReminder); f.campingSound:SetChecked(self.db.campSound); f.campingAnywhere:SetChecked(self.db.campAnywhere); f.campingTrack:SetChecked(self.db.campTrackBenefits); f.sleepingTrack:SetChecked(self.db.campTrackBag)
  f.campingWarning:SetText(L(self.db.campWarning==60 and "Warn: 1 minute" or self.db.campWarning==600 and "Warn: 10 minutes" or "Warn: 5 minutes"))
  for _,entry in ipairs({{f.campingSize,self.db.campSize},{f.campingOpacity,math.floor(self.db.campOpacity*100+.5)}}) do entry[1].silent=true; entry[1]:SetValue(entry[2]); entry[1].silent=false end
  f.campingEffect:SetText(L(({none="Effect: None",soft="Effect: Soft glow",pulse="Effect: Pulse",pixel="Effect: Pixel border",autocast="Effect: Sparkles",proc="Effect: Spell glow",shine="Effect: Shine",ripple="Effect: Ripple",bounce="Effect: Bounce",orbit="Effect: Orbit"})[self.db.campEffectStyle] or "Effect: Soft glow"))
  f.campingColor:SetText(L(({gold="Gold",cyan="Cyan",green="Green",red="Red",white="White"})[self.db.campEffectColor] or "Gold"))
  f.campingSpeed:SetText(L(({slow="Slow",normal="Normal",fast="Fast"})[self.db.campEffectSpeed] or "Normal"))
  f.campingCountdown:SetChecked(self.db.campShowCountdown); f.campingStacks:SetChecked(self.db.campShowStacks)
  for _,v in ipairs(self:ReminderFonts(self.db.campTextFont)) do if v.key==self:NormalizeTextFontKey(self.db.campTextFont) then f.campingTextFont:SetText(L(v.name)) end end
  for _,v in ipairs(self:ReminderColors(true)) do if v.key==self.db.campTextColor then f.campingTextColor:SetText(L(v.name)) end end
  f.campingTextSize:SetText(self:TextSizeLabel(self.db.campTextSize))
  for _,v in ipairs(self:TextOutlineChoices()) do if v.key==self.db.campTextOutline then f.campingTextOutline:SetText(L(v.name)) end end
  f.campingTextGap.silent=true; f.campingTextGap:SetValue(self.db.campTextGap); f.campingTextGap.silent=false
  local paused=self.campSnoozeSession or (self.campSnoozeUntil and self.campSnoozeUntil>GetTime())
  f.campingPause:SetText(L(paused and "Camp reminder snoozed" or "Camp reminder ready")); f.campingResume:SetShown(paused or false)
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
    f:SetScript("OnHide",function() B:StopIconEffect(f) end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED"); f:SetScript("OnEvent",function() f:Hide() end)
    addHelp(f,L("Preview appearance"),L("Move icon opens a safe preview that cannot cast spells."))
  end
  f:SetSize(self.db.size,self.db.size); f:SetAlpha(self.db.opacity); f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",self.db.x,self.db.y)
  f.nameLabel:SetShown(self.db.showBuffName); f.recipient:SetShown(self.db.showTargetName)
  f.recipient:ClearAllPoints(); f.recipient:SetPoint("TOP",f,"BOTTOM",0,-5)
  f.timer:SetText(L("%d sec",30)); f.timer:SetShown(self.db.showTimer)
  f.count:ClearAllPoints(); f.count:SetPoint("TOPLEFT",f,"TOPLEFT",4,-3); f.count:SetShown(self.db.showGroupBadge)
  self:ApplyIconEffect(f,true)
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





