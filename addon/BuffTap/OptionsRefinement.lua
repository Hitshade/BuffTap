-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local T=B.OptionsTheme
local function place(control,parent,x,y,width,height)
  control:SetParent(parent); control:ClearAllPoints(); control:SetPoint("TOPLEFT",x,y)
  -- A selector's menu must move with it: left on its old (hidden) page it can never show.
  if type(control.menu)=="table" and control.menu.SetParent then
    -- SetParent drops the menu back to the page's strata; keep it above every control on the page.
    local menu=control.menu; menu:SetParent(parent); menu:SetFrameStrata("TOOLTIP"); menu:SetToplevel(true)
    if parent.GetFrameLevel then menu:SetFrameLevel(parent:GetFrameLevel()+60) end
  end
  if control:GetObjectType()=="CheckButton" then
    control:SetSize(24,24)
  else
    if width then control:SetWidth(width) end; if height then control:SetHeight(height) end
  end
  control:Show(); return control
end
-- Page header switch, same on every page: label then switch, with the switch's right end
-- at the page's right edge (x 704), level with the title. Shortcut buttons sit below it.
local function headerSwitch(control,page)
  control.headerSwitch=true; place(control,page,672,-12)
  local text=control.Text
  if text then
    text:ClearAllPoints(); text:SetPoint("RIGHT",control,"LEFT",-10,0); text:SetJustifyH("RIGHT")
    local width=text:GetStringWidth(); if type(width)=="number" then control:SetHitRectInsets(-math.min(280,width+12),-8,0,0) end
  end
  return control
end
local function reparent(control,parent)
  local old=control:GetParent(); local points={}
  for i=1,(control:GetNumPoints() or 0) do points[i]={control:GetPoint(i)} end
  control:SetParent(parent)
  if #points>0 then control:ClearAllPoints(); for _,p in ipairs(points) do if p[2]==old then p[2]=parent end; control:SetPoint(unpack(p)) end end
end
local function section(ui,parent,title,x,y,w,h)
  local bg=ui.card(parent,x,y,w,h)
  local titleText=ui.label(parent,title,x+16,y-16,T.fonts.Section,w-32); T.SectionTitle(titleText)
  return bg
end
function B:VisualSetting(key,value)
  if A.Combat() then return end
  self.db[key]=value; self:NormalizeVisualOptions()
  if key:match("^camp") then self:NormalizeCamping(); self:UpdateCamping() end
  if key:match("^supply") and self.UpdateSupplyBadge then self:UpdateSupplyBadge() end
  self.appearance=nil; self:RequestRefresh("appearance preference",.05)
  -- Interface colour and scale: coalesce, so dragging the colour wheel or the scale slider
  -- does not rebuild the whole window on every tick.
  -- The window scale waits until the mouse is released: rescaling under the cursor mid-drag
  -- would move the slider and make its value jump.
  if key:match("^options") then
    local function apply()
      if A.Combat() then return end
      if key=="optionsScale" and type(IsMouseButtonDown)=="function" and IsMouseButtonDown("LeftButton") then B:StartTimer("options-visual",.15,apply); return end
      T.Refresh(); B:UpdateRefinedOptions()
    end
    self:StartTimer("options-visual",.08,apply)
  end
  if key:match("^nearby") and self.nearbyFrame then self:UpdateNearbyWindow() end
  self:UpdateOptionsPreviews()
end
function B:CreateOptionsPreview(parent,kind,ui)
  -- Right column order: Icon, Preview, Effect. The preview is compact and ends level with Effect's top.
  local holder=CreateFrame("Frame",nil,parent,"BackdropTemplate"); local campLike=kind=="camp" or kind=="supply"
  holder:SetSize(260,campLike and 328 or 248); holder:SetPoint("TOPLEFT",444,campLike and -104 or -186); T.Surface(holder,"card")
  -- The buff and camp editors share one page; without this the taller buff Icon card would inset the camp preview.
  holder.visualInsetX=444
  local heading=ui.label(holder,"PREVIEW",16,-16,T.fonts.Section,228); T.SectionTitle(heading)
  local icon=CreateFrame("Frame",nil,holder); icon:SetPoint("CENTER",holder,"CENTER",0,campLike and 0 or 24); icon:SetSize(64,64)
  icon.icon=icon:CreateTexture(nil,"ARTWORK"); icon.icon:SetAllPoints(); icon.icon:SetTexCoord(.07,.93,.07,.93)
  icon.glow=icon:CreateTexture(nil,"OVERLAY"); icon.glow:SetAllPoints(); icon.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight"); icon.glow:SetBlendMode("ADD")
  icon.pulseAnimation=icon.glow:CreateAnimationGroup(); local out=icon.pulseAnimation:CreateAnimation("Alpha"); out:SetFromAlpha(1); out:SetToAlpha(.3); out:SetDuration(.7); out:SetOrder(1)
  local back=icon.pulseAnimation:CreateAnimation("Alpha"); back:SetFromAlpha(.3); back:SetToAlpha(1); back:SetDuration(.7); back:SetOrder(2); icon.pulseAnimation:SetLooping("REPEAT")
  icon.nameLabel=ui.label(icon,"",0,0,"GameFontHighlightSmall",240); icon.nameLabel:SetJustifyH("CENTER")
  icon.recipient=ui.label(icon,"",0,0,"GameFontHighlightSmall",240); icon.recipient:SetJustifyH("CENTER")
  icon.timer=ui.label(icon,"4m 12s",2,-45,"GameFontHighlightSmall",68)
  icon.count=ui.label(icon,"3",0,0,"GameFontNormalSmall",24); icon.count:ClearAllPoints(); icon.count:SetPoint("TOPRIGHT",-2,-2)
  icon.time=ui.label(icon,"",0,0,"GameFontHighlightSmall",240); icon.time:SetJustifyH("CENTER")
  for _,fs in ipairs({icon.nameLabel,icon.recipient,icon.timer,icon.count,icon.time}) do T.Track(fs,"preview") end
  holder.hint=ui.label(holder,kind=="supply" and "What is running low" or kind=="camp" and "Camp timer and rest stacks" or "Hidden icon: binding stays active",14,-(holder:GetHeight()-27),"GameFontDisableSmall",232)
  holder.hint:SetJustifyH("CENTER")
  if not campLike then
    holder.hint:Hide()
    holder.manualCaption=ui.label(holder,"Consumables",14,-164,"GameFontDisableSmall",232)
    holder.manualCaption:SetJustifyH("CENTER")
    holder.manualSamples={}
    for i,spec in ipairs({{"INV_Misc_Food_33",20},{"INV_Potion_65",3},{"INV_Potion_93",0}}) do
      local sample=CreateFrame("Frame",nil,holder); sample:SetSize(22,22); sample:SetPoint("TOPLEFT",93+(i-1)*26,-182); sample:EnableMouse(false)
      sample.icon=sample:CreateTexture(nil,"ARTWORK"); sample.icon:SetAllPoints(); sample.icon:SetTexture("Interface\\Icons\\"..spec[1]); sample.icon:SetDesaturated(spec[2]==0)
      sample.count=sample:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); sample.count:SetPoint("BOTTOMRIGHT",1,-1); sample.count:SetText(tostring(spec[2]))
      sample.count:SetTextColor(1,spec[2]==0 and .3 or spec[2]<=3 and .7 or 1,spec[2]==0 and .3 or spec[2]<=3 and .1 or 1)
      holder.manualSamples[i]=sample
    end
  end
  holder.icon=icon; holder.kind=kind
  holder:HookScript("OnHide",function() B:StopIconEffect(icon) end)
  return holder
end
function B:StopOptionsPreviews()
  for _,preview in pairs(self.optionsPreviews or {}) do self:StopIconEffect(preview.icon) end
end
function B:UpdateOptionsPreviews()
  local f=self.options; if not f or not self.optionsPreviews then return end
  for kind,preview in pairs(self.optionsPreviews) do
    local icon=preview.icon; local active=f:IsShown() and f.activeTab==8 and f.appearanceView==kind
    if active and kind=="supply" then
      local d=self.db; self:NormalizeSupplyReminder()
      local shown=math.min(96,d.supplySize); icon:SetSize(shown,shown); icon:SetAlpha(d.supplyOpacity)
      -- Preview your own supplies: something low first, then the first item you track, else a plain bag.
      local sample=(self.supplyWarnings or {})[1]
      if not sample then local ok,list=pcall(self.SupplyDisplayEntries,self); sample=ok and list and list[1] or nil end
      sample=sample or {name=self:Text("Your item"),count=2,settings={target=8},icon="Interface\\Icons\\INV_Crate_01"}
      icon.icon:SetTexture(sample.icon or "Interface\\Icons\\INV_Crate_01")
      for _,fs in ipairs({icon.nameLabel,icon.recipient,icon.timer,icon.count}) do fs:Hide() end
      icon.time:Show(); self:StyleSupplyLabel(icon.time,icon)
      icon.time:SetText(self:SupplyLabelText(sample))
      self:ApplyIconStyle(icon,icon.icon,d.supplyIconStyle)
      self:ApplyIconEffect(icon,true,{effectStyle=d.supplyEffectStyle,effectColor=d.supplyEffectColor,effectSpeed=d.supplyEffectSpeed})
      preview.hint:SetText(self:Text("What is running low")); icon.icon:SetAlpha(1)
    elseif not active then self:StopIconEffect(icon) else
      local d=self.db; local camp=kind=="camp"
      local shown=math.min(camp and 96 or 64,camp and d.campSize or d.size); icon:SetSize(shown,shown); icon:SetAlpha(camp and d.campOpacity or d.opacity)
      if not camp then
        local size=math.max(10,d.labelSize or 10); local gap=d.labelGap or 5
        local names=(d.showBuffName and 1 or 0); local recipients=(d.showTargetName and 1 or 0)
        local upper=d.labelPosition=="below" and 0 or d.labelPosition=="above" and names+recipients or names
        local lower=d.labelPosition=="above" and 0 or d.labelPosition=="below" and names+recipients or recipients
        local top=upper>0 and upper*size+gap+(upper-1)*2 or 0
        local bottom=lower>0 and lower*size+gap+(lower-1)*2 or 0
        -- Center the entire display below the heading, including the smaller strip.
        local available=preview:GetHeight()-54; local strip=50
        shown=math.min(shown,math.max(24,available-strip-top-bottom)); icon:SetSize(shown,shown)
        local block=top+shown+bottom
        local start=42+math.max(0,(available-block-strip)/2)
        icon:ClearAllPoints(); icon:SetPoint("TOP",preview,"TOP",0,-start-top)
        for i,sample in ipairs(preview.manualSamples or {}) do
          sample:ClearAllPoints(); sample:SetPoint("TOPLEFT",preview,"TOPLEFT",93+(i-1)*26,-start-block-28); sample:SetAlpha(d.opacity)
        end
        if preview.manualCaption then
          preview.manualCaption:ClearAllPoints(); preview.manualCaption:SetPoint("TOP",preview,"TOP",0,-start-block-10)
          preview.manualCaption:SetAlpha(d.opacity)
        end
      end
      local sample
      if not camp then for _,def in ipairs(self.Buffs) do if def.class==A.Class("player") and def.kind~="group" then sample=def; break end end end
      icon.icon:SetTexture(camp and 135805 or sample and sample.icon or "Interface\\AddOns\\BuffTap\\Media\\BuffTapIcon")
      icon.nameLabel:SetShown(not camp and d.showBuffName); icon.recipient:SetShown(not camp and d.showTargetName)
      icon.nameLabel:SetText(sample and sample.name or self:Text("Buff reminder")); icon.recipient:SetText(A.Call(UnitName,"player") or "Player")
      icon.timer:ClearAllPoints(); icon.timer:SetPoint("BOTTOM",icon,"BOTTOM",0,3); icon.timer:SetShown(not camp and d.showTimer)
      icon.count:SetShown(not camp and d.showGroupBadge)
      if camp then
        icon.time:Show(); self:StyleCampLabel(icon)
        icon.time:SetText(self:CampLabelText({active=true,remaining=1800,bagStacks=2,bagRemaining=7199,bagActive=true},true))
        self:ApplyIconStyle(icon,icon.icon,d.campIconStyle)
      else icon.time:Hide(); self:ApplyReminderStyle(icon) end
      local effect=camp and {effectStyle=d.campEffectStyle,effectColor=d.campEffectColor,effectSpeed=d.campEffectSpeed} or d
      self:ApplyIconEffect(icon,true,effect)
      local hidden=not camp and d.showReminder==false
      preview.hint:SetText(self:Text(camp and "Camp timer and rest stacks" or hidden and "Icon hidden. Your binding stays active." or "Sample only. No buffs are cast."))
      icon.icon:SetAlpha(hidden and .18 or 1); if hidden then self:StopIconEffect(icon) end
    end
  end
end
B.EffectChoices={{key="none",name="Effect: None"},{key="soft",name="Effect: Soft glow"},{key="pulse",name="Effect: Pulse"},{key="pixel",name="Effect: Pixel border"},{key="autocast",name="Effect: Sparkles"},{key="proc",name="Effect: Spell glow"},{key="shine",name="Effect: Shine"},{key="ripple",name="Effect: Ripple"},{key="bounce",name="Effect: Bounce"},{key="orbit",name="Effect: Orbit"}}
B.EffectColorChoices={{key="gold",name="Gold"},{key="cyan",name="Cyan"},{key="green",name="Green"},{key="red",name="Red"},{key="white",name="White"}}
B.EffectSpeedChoices={{key="slow",name="Slow"},{key="normal",name="Normal"},{key="fast",name="Fast"}}
function B:BuildReminderEditor(parent,kind,ui)
  local f=self.options; local d=self.db
  -- The Supplies reminder uses the camping layout with its own settings.
  local sup=kind=="supply"
  if sup then
    self:NormalizeSupplyReminder()
    local function sel(key,width,choices) return ui.selector(parent,"",0,0,width,choices,function(v) B:VisualSetting(key,v) end) end
    f.supplyTextFont=sel("supplyTextFont",228,function() return B:ReminderFonts(B.db.supplyTextFont) end)
    f.supplyTextColor=sel("supplyTextColor",228,function() return B:ReminderColors(true) end)
    f.supplyTextOutline=sel("supplyTextOutline",228,function() return B:TextOutlineChoices() end)
    f.supplyEffect=sel("supplyEffectStyle",232,function() return B.EffectChoices end)
    f.supplyColor=sel("supplyEffectColor",232,function() return B.EffectColorChoices end)
    f.supplySpeed=sel("supplyEffectSpeed",232,function() return B.EffectSpeedChoices end)
    f.supplyShowName=ui.check(parent,"Item name",0,0,function(c) B:VisualSetting("supplyShowName",c:GetChecked()==true) end)
    f.supplyShowCount=ui.check(parent,"Count / want",0,0,function(c) B:VisualSetting("supplyShowCount",c:GetChecked()==true) end)
  end
  local camp=kind=="camp" or sup
  local function K(campKey) return sup and (campKey:gsub("^camp","supply")) or campKey end
  section(ui,parent,"Layout",12,-12,416,100)
  local textShift=camp and 88 or 158
  section(ui,parent,"Text",12,-130-textShift,416,camp and 316 or 248)
  -- Buff reminder: Icon card (with Show icon as its first row), Preview, then Effect.
  -- Icon, Preview and Effect must end above the status bar (about -630).
  local ey=camp and 0 or 2
  section(ui,parent,"Effect",444,-448,260,170)
  local function change(key,value) self:VisualSetting(key,value) end
  local function slider(key,title,x,y,min,max,step,width,multiplier)
    -- "Icon size (px)" becomes the label "Icon size" with "px" shown inside the value field.
    local plain,unit=title:match("^(.-)%s*%((.-)%)$"); title=plain or title
    ui.label(parent,title,x,y-3,"GameFontHighlightSmall",120)
    local s=ui.slider(parent,min,max,step,width or 228,function(v) return tostring(v) end,function(_,v) change(key,multiplier and v/multiplier or v) end)
    s:SetPoint("TOPLEFT",x+126,y); s.visualKey=key; s.visualMultiplier=multiplier; if unit then s:SetUnit(unit) end
    f.refinedSliders[#f.refinedSliders+1]=s; return s
  end
  local size=slider(camp and K("campSize") or "size","Icon size (px)",26,-48,24,camp and 96 or 160,1,228)
  local opacity=slider(camp and K("campOpacity") or "opacity","Opacity (%)",26,-84,camp and 25 or 0,100,1,228,100)
  if not camp then f.sizeEdit=size.valueEdit; f.opacityEdit=opacity.valueEdit end
  local font=sup and f.supplyTextFont or camp and f.campingTextFont or f.fontButton
  ui.label(parent,"Font",26,-169-textShift,"GameFontHighlightSmall",110); place(font,parent,152,-164-textShift,228,26)
  slider(camp and K("campTextSize") or "labelSize","Text size (px)",26,camp and -312 or -210-textShift,8,20,1,228)
  slider(camp and K("campTextGap") or "labelGap","Text spacing (px)",26,camp and -372 or -250-textShift,0,20,1,228)
  local outline=sup and f.supplyTextOutline or camp and f.campingTextOutline or f.labelOutlineButton
  local color=sup and f.supplyTextColor or camp and f.campingTextColor or f.colorButton
  ui.label(parent,"Outline",26,camp and -438 or -292-textShift,"GameFontHighlightSmall",110); place(outline,parent,152,camp and -432 or -286-textShift,228,26)
  ui.label(parent,"Text colour",26,camp and -498 or -330-textShift,"GameFontHighlightSmall",110); place(color,parent,152,camp and -492 or -324-textShift,228,26)
  local effect=sup and f.supplyEffect or camp and f.campingEffect or f.effectButton
  local effectColor=sup and f.supplyColor or camp and f.campingColor or f.effectColorButton
  local speed=sup and f.supplySpeed or camp and f.campingSpeed or f.effectSpeedButton
  place(effect,parent,458,-480,232,26); place(effectColor,parent,458,camp and -526 or -510,232,26); place(speed,parent,458,camp and -572 or -540,232,26)
  if not camp then place(f.effectUrgency,parent,458,-570); place(f.effectOnce,parent,458,-594) end
  section(ui,parent,"Visible labels",12,-130,416,camp and 70 or 140)
  if sup then
    place(f.supplyShowName,parent,26,-162); place(f.supplyShowCount,parent,208,-162)
  elseif camp then
    place(f.campingCountdown,parent,26,-162); place(f.campingStacks,parent,208,-162)
  else
    place(f.buffNameCheck,parent,26,-162); place(f.targetNameCheck,parent,208,-162)
    place(f.timerCheck,parent,26,-192); place(f.groupBadgeCheck,parent,208,-192)
    place(f.showReminderCheck,parent,458,-46,184,24); f.showReminderCheck.Text:SetText(self:Text("Show icon"))
  end
  local actionY=-592
  local move=ui.button(parent,"Move reminders",26,actionY,184,function() B:MoveAllFrames(sup and "supply" or camp and "camp" or "buff") end)
  if not camp then f.moveReminders=move; place(f.resetLookButton,parent,230,actionY,184,26); f.resetLookButton:SetText(self:Text("Reset look & position")) end
  if sup then T.Confirm(ui.button(parent,"Reset look & position",230,actionY,184,function()
    for _,k in ipairs({"supplySize","supplyOpacity","supplyEffectStyle","supplyEffectColor","supplyEffectSpeed","supplyTextFont","supplyTextSize","supplyTextColor","supplyTextOutline","supplyTextGap","supplyShowName","supplyShowCount","supplyIconStyle","supplyX","supplyY"}) do B.db[k]=nil end
    B:NormalizeSupplyReminder(); B:UpdateSupplyBadge(); B:Options()
  end))
  elseif camp then T.Confirm(ui.button(parent,"Reset look & position",230,actionY,184,function()
    for k,v in pairs({campX=100,campY=0,campSize=40,campOpacity=1,campIconStyle="classic",campEffectStyle="soft",campEffectColor="gold",campEffectSpeed="normal",campTextFont="default",campTextSize=0,campTextColor="white",campTextOutline="outline",campTextGap=4,campShowCountdown=true,campShowStacks=true}) do B.db[k]=v end
    B:NormalizeCamping(); B:UpdateCamping(); B:Options()
  end)) end
  if camp then ui.label(parent,"The preview does not move or activate your live reminder.",26,-554,"GameFontDisableSmall",404) end
  if not camp then
    f.detachConsumables=ui.check(parent,"Detach consumables",26,-554,function(c)
      if B:SetManualConsumablesDetached(c:GetChecked()==true) then B:UpdateRefinedOptions() end
    end)
    f.detachConsumables:HookScript("OnEnter",function(s)
      T.Tooltip(s,B:Text("Detach consumables"),B:Text("Detached consumables can be positioned separately with Move reminders or Edit Mode."))
    end)
  end
  -- Icon: style for both reminders; label placement, countdown sweep and out-of-range display for the buff reminder.
  section(ui,parent,"Icon",444,-12,260,camp and 76 or 160)
  local sy=camp and 0 or -32
  ui.label(parent,"Style",458,-54+sy,"GameFontHighlightSmall",76)
  local styleKey=camp and K("campIconStyle") or "iconStyle"
  local style=ui.selector(parent,"",540,-48+sy,150,function() return B:IconStyleChoices() end,function(v) change(styleKey,v) end)
  if sup then f.supplyIconStyleButton=style elseif camp then f.campIconStyleButton=style else
    f.iconStyleButton=style
    ui.label(parent,"Position",26,-234,"GameFontHighlightSmall",110)
    f.labelPositionButton=ui.selector(parent,"",152,-228,228,function() return {{key="split",name="Split"},{key="above",name="Above icon"},{key="below",name="Below icon"}} end,function(v) change("labelPosition",v) end)
    f.swipeCheck=ui.check(parent,"Rebuff countdown sweep",458,-116,function(c) change("showSwipe",c:GetChecked()==true) end)
    f.rangeCheck=ui.check(parent,"Grey out-of-range buffs",458,-144,function(c) change("showOutOfRange",c:GetChecked()==true) end)
  end
  self.optionsPreviews[kind]=self:CreateOptionsPreview(parent,kind,ui)
end
function B:BuildRefinedOptions(ui,tabs)
  local f=self.options; self.refinedUI=ui; f.refinedSliders={}; self.optionsPreviews={}
  -- Hide the old appearance composition, then reuse its existing controls and callbacks.
  local app=f.pages[tabs.Appearance]
  for _,child in ipairs({app:GetChildren()}) do if child~=app.NineSlice then child:Hide() end end
  for _,region in ipairs({app:GetRegions()}) do if region.optionsLabel or region.optionsDecoration then region:Hide() end end
  f.appearancePanes={}; f.appearanceTabs={}; f.appearanceView="buff"
  for i,entry in ipairs({{"buff","Buff reminder"},{"camp","Camping"},{"supply","Supplies"},{"nearby","Nearby window"},{"binding","Binding & sound"},{"interface","Interface"}}) do
    local key=entry[1]; local pane=CreateFrame("Frame",nil,app); pane:SetPoint("TOPLEFT",0,-104); pane:SetPoint("BOTTOMRIGHT",0,0); pane:Hide(); f.appearancePanes[key]=pane
    f.appearanceTabs[key]=ui.flatButton(app,entry[2],18+(i-1)*115,-68,110,function() B:SetAppearanceView(key) end)
    f.appearanceTabs[key].navStyle="underline"
  end
  T.Rule(app,12,-95,692)
  self:BuildReminderEditor(f.appearancePanes.buff,"buff",ui); self:BuildReminderEditor(f.appearancePanes.camp,"camp",ui)
  self:BuildSupplyAppearance(f.appearancePanes.supply,ui)
  local binding=f.appearancePanes.binding
  section(ui,binding,"Binding",12,-12,692,140); place(f.bindingText,binding,26,-52,340)
  T.Variant(ui.button(binding,"Set binding",398,-46,134,function() B:CaptureBinding() end),"primary")
  T.Confirm(ui.button(binding,"Clear",546,-46,142,function() B.db.keys={}; B.appearance=nil; B:RequestRefresh("clear binding",0); B:Options() end))
  -- Optional second key for Nearby: when set, the main key only covers you and your group.
  f.nearbyBindingText=ui.label(binding,"",26,-88,"GameFontHighlight",360)
  ui.button(binding,"Set Nearby key",398,-82,134,function() B:CaptureBinding("nearby") end)
  T.Confirm(ui.button(binding,"Clear",546,-82,142,function() B.db.nearbyKeys={}; if B.nearbyFrame then B:UpdateNearbyWindow() end; B:RequestRefresh("clear nearby binding",0); B:Options() end))
  ui.label(binding,"Keys work only when a buff is ready. With a Nearby key set, your main key covers only you and your group.",26,-124,"GameFontDisableSmall",650)
  section(ui,binding,"Sounds",12,-172,692,320)
  for i,entry in ipairs({{f.reminderSoundButton,"Reminder sound","reminder"},{f.supplySoundButton,"Supply sound","supply"},{f.campSoundButton,"Camp sound","camp"},{f.cleanseSoundButton,"Cleanse sound","cleanse"},{f.socialSoundButton,"Friend sound","social"}}) do
    local y=-208-(i-1)*36; ui.label(binding,entry[2],26,y-5,"GameFontHighlightSmall",130); place(entry[1],binding,166,y,330,26)
    local kind=entry[3]; ui.button(binding,"Preview",510,y,178,function() B:PlayAlert(kind,true) end)
  end
  -- Friend sound: when a friend or guild member first shows up in Nearby (off by default).
  f.socialAlert=ui.check(binding,"Alert me when a friend or guildmate appears in Nearby",26,-390,function(c)
    B.db.nearbySocialAlert=c:GetChecked()==true; if B.db.nearbySocialAlert then B:SettleSocialAlerts(3) end; B:Options()
  end)
  f.socialAlert:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Friend and guildmate alert"),B:Text("Plays the friend sound and briefly highlights their row the first time a friend or guild member shows up in the Nearby list. At most once per player an hour, never in combat or instances, and not for people in your group.")) end)
  f.socialAlert:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.socialFriends=ui.check(binding,"Friends",470,-390,function(c) B.db.nearbySocialFriends=c:GetChecked()==true end)
  f.socialGuild=ui.check(binding,"Guild",580,-390,function(c) B.db.nearbySocialGuild=c:GetChecked()==true end)
  ui.label(binding,"Audio channel",26,-430,"GameFontHighlightSmall",130); place(f.channelButton,binding,166,-424,196,26)
  ui.label(binding,"Minimum interval",380,-430,"GameFontHighlightSmall",130); place(f.soundInterval,binding,510,-424,178,24)
  place(f.soundCheck,binding,26,-462)
  -- Quick access and the buff reminder position share one card: icons and reset on the first row, coordinates on the second.
  section(ui,binding,"Quick access",12,-506,692,118); place(f.minimapCheck,binding,26,-546); place(f.brokerCheck,binding,360,-546)
  place(f.resetAllButton,binding,510,-542,178,26); reparent(f.resetConfirm,binding); f.resetConfirm:ClearAllPoints(); f.resetConfirm:SetPoint("TOPLEFT",16,-546); f.resetConfirm:Hide()
  local interface=f.appearancePanes.interface
  section(ui,interface,"Interface",12,-12,692,278)
  ui.label(interface,"Accent colour",26,-62,"GameFontHighlightSmall",180)
  f.accentMode=ui.selector(interface,"",226,-56,462,function() return {{key="gold",name="BuffTap gold"},{key="class",name="My class"},{key="custom",name="Custom colour"}} end,function(v) B:VisualSetting("optionsAccentMode",v) end)
  ui.label(interface,"Custom colour (hex)",26,-106,"GameFontHighlightSmall",180)
  -- The input box draws its frame 5 px left of its anchor; offset it so its left edge lines up with the rows above and below.
  f.accentHex=ui.editbox(interface,231,-100,107,false); f.accentHex:SetHeight(26)
  f.accentHex:SetScript("OnEnterPressed",function(s) local value=(s:GetText() or ""):gsub("#",""); if value:match("^%x%x%x%x%x%x$") then B:VisualSetting("optionsAccentColor",value); B:VisualSetting("optionsAccentMode","custom") end; s:ClearFocus(); B:Options() end)
  f.accentHex:SetScript("OnEscapePressed",function(s) s:ClearFocus(); B:Options() end)
  f.accentPick=ui.button(interface,"Pick colour",354,-100,158,function() B:OpenAccentPicker() end)
  -- Swatch: the accent colour currently in use.
  f.accentSwatch=CreateFrame("Frame",nil,interface,"BackdropTemplate"); f.accentSwatch:SetSize(40,26); f.accentSwatch:SetPoint("TOPLEFT",526,-100)
  f.accentSwatch:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); T.Round(f.accentSwatch,5,"surface"); T.LockBorder(f.accentSwatch,1,1,1,.25)
  f.accentSwatchText=ui.label(interface,"",576,-106,"GameFontDisableSmall",112); f.accentSwatchText:SetJustifyH("RIGHT")
  ui.label(interface,"Window scale",26,-154,"GameFontHighlightSmall",180)
  f.optionsScaleSlider=ui.slider(interface,65,125,5,462,tostring,function(_,v) B:VisualSetting("optionsScale",v/100) end); f.optionsScaleSlider:SetPoint("TOPLEFT",226,-150); f.optionsScaleSlider:SetUnit("%"); f.optionsScaleSlider.visualKey="optionsScale"; f.optionsScaleSlider.visualMultiplier=100; f.refinedSliders[#f.refinedSliders+1]=f.optionsScaleSlider
  f.reduceMotion=ui.check(interface,"Reduce animation",26,-198,function(c) B:VisualSetting("optionsReduceMotion",c:GetChecked()==true) end)
  ui.label(interface,"Accent colours are adjusted when necessary to stay readable. Warning and player-class colours stay distinct.",26,-242,"GameFontDisableSmall",650)
  local restoreInterface=ui.button(interface,"Restore interface defaults",462,-320,230,function() B.db.optionsAccentMode="gold"; B.db.optionsAccentColor="75c8da"; B.db.optionsScale=1; B.db.optionsReduceMotion=false; B:Options() end)
  T.Variant(restoreInterface,"danger")
  -- Keep the sidebar status lights in step with each page switch.
  for _,control in ipairs({f.friendlyTarget,f.weaponEnable,f.consumablesEnable,f.supplyEnable,f.campingEnable,f.nearbyEnable,f.groupEnable,f.blessingGroupEnable}) do
    if control then control:HookScript("OnClick",function() B:UpdateNavStatus() end) end
  end
  self:RefineCampingPage(ui,tabs); self:RefineNearbyPage(ui,tabs); self:BuildPatchNotesPage(ui,tabs); self:BuildCleansePage(ui,tabs,headerSwitch,section); self:StandardizeOptionsPages(ui,tabs)
  f:HookScript("OnShow",function() B:UpdateOptionsPreviews() end); f:HookScript("OnHide",function() B:StopOptionsPreviews() end)
  self:SetAppearanceView("buff")
end
function B:SetAppearanceView(view)
  local f=self.options; self:StopOptionsPreviews(); f.appearanceView=view
  for key,pane in pairs(f.appearancePanes) do pane:SetShown(key==view); T.Navigation(f.appearanceTabs[key],key==view) end
  self:UpdateRefinedOptions(); self:UpdateOptionsPreviews()
  if self.UpdateSupplyBadge then self:UpdateSupplyBadge() end
end
-- Customization > Supplies: the camping layout, with the Supplies reminder's own settings.
function B:BuildSupplyAppearance(parent,ui)
  self:BuildReminderEditor(parent,"supply",ui)
  parent:HookScript("OnShow",function() B:UpdateSupplyBadge() end)
  parent:HookScript("OnHide",function() if not A.Combat() then B:UpdateSupplyBadge() end end)
end
function B:SupplyOptionsShown()
  local f=self.options
  return f and f.appearancePanes and f.appearancePanes.supply and f.appearancePanes.supply:IsVisible() or false
end
local function clearPage(page)
  for _,child in ipairs({page:GetChildren()}) do if child~=page.NineSlice then child:Hide() end end
  for _,region in ipairs({page:GetRegions()}) do if region.optionsLabel or region.optionsDecoration then region:Hide() end end
end
function B:RefineCampingPage(ui,tabs)
  local f=self.options; local p=f.pages[tabs.Camping]; clearPage(p)
  section(ui,p,"Current benefits",12,-72,692,84)
  place(f.campingStatus,p,26,-112,310); place(f.sleepingStatus,p,374,-112,310)
  section(ui,p,"Reminders",12,-174,692,208)
  headerSwitch(f.campingEnable,p); place(f.campingAnywhere,p,374,-264)
  place(f.campingTrack,p,26,-216); place(f.sleepingTrack,p,374,-216)
  place(f.campingSound,p,26,-264); place(f.campingWarning,p,374,-300,310,26)
  ui.label(p,"Warn before expiry",26,-308,"GameFontHighlightSmall",220)
  ui.label(p,"Outdoors, missing or expiring benefits can show a separate reminder. Right-click that icon to snooze it.",26,-344,"GameFontDisableSmall",650)
  section(ui,p,"Setup & appearance",12,-400,692,170)
  T.Variant(ui.button(p,"Open setup tray",26,-448,202,function() B:ToggleCampTray() end),"primary")
  place(f.campingResume,p,466,-448,218,26); place(f.campingPause,p,26,-494,650)
  ui.label(p,"Use camp items and your sleeping bag from the setup tray. Food preferences stay under Consumables.",26,-536,"GameFontDisableSmall",650)
end
function B:RefineNearbyPage(ui,tabs)
  local f=self.options; local p=f.pages[tabs.Nearby]; clearPage(p)
  headerSwitch(f.nearbyEnable,p)
  section(ui,p,"Player list",12,-72,692,216)
  -- Left column: who and when you buff. Right column: how the list looks.
  place(f.nearbyBuffing,p,26,-112); place(f.nearbyAll,p,374,-112)
  f.nearbyFullNames=ui.check(p,"Show full names",374,-146,function(c)
    if A.Combat() then return end
    B.db.nearbyFullNames=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyWindow() end
  end)
  f.nearbyFullNames:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Show full names"),B:Text("Show each player's first name and surname.")) end)
  f.nearbyFullNames:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.nearbyShowLevel=ui.check(p,"Show level",540,-146,function(c)
    if A.Combat() then return end
    B.db.nearbyShowLevel=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyWindow() end
  end)
  f.nearbyWhileResting=ui.check(p,"Buff while resting",26,-146,function(c)
    if A.Combat() then return end
    B.db.nearbyWhileResting=c:GetChecked()==true; B.nearbySnapshot=nil; B:RequestRefresh("nearby resting",0); if B.nearbyFrame then B:UpdateNearbyWindow() end
    B:UpdateRefinedOptions()
  end)
  f.nearbyHoldShort=ui.check(p,"Hold back short buffs, like Thorns",50,-180,function(c)
    if A.Combat() then return end
    B.db.nearbyHoldShort=c:GetChecked()==true; B.nearbyNeedCache={}; B.nearbySnapshot=nil; B:RequestRefresh("nearby short buffs",0); if B.nearbyFrame then B:UpdateNearbyWindow() end
  end)
  f.nearbyHoldShort:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Hold back short buffs"),B:Text("In cities and inns, don't offer Nearby players buffs that last ten minutes or less, such as Thorns or a single blessing. They would wear off before they mattered. Longer buffs like Mark of the Wild are still offered.")) end)
  f.nearbyHoldShort:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.nearbyRankUpgrades=ui.check(p,"Offer higher rank buffs",374,-180,function(c)
    if A.Combat() then return end
    B.db.nearbyRankUpgrades=c:GetChecked()==true; B.nearbyNeedCache=nil; B.nearbySnapshot=nil
    B:RequestRefresh("nearby rank upgrades",0)
  end)
  f.nearbyRankUpgrades:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Offer higher rank buffs"),B:Text("Offer a known higher rank when a Nearby player has a clearly identified lower rank and their level allows the upgrade. Unknown effects and group equivalents are left alone. Compares ranks, not talent bonuses. Each cast still needs your input.")) end)
  f.nearbyRankUpgrades:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.nearbyWhileResting:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Buff while resting"),B:Text("Buff nearby players in cities and inns. When off, Nearby pauses there. Also the zZ button on the Nearby window. Your own reminders follow the Helpers resting pause.")) end)
  f.nearbyWhileResting:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  place(f.nearbyInvites,p,26,-214)
  f.nearbyMarkSocial=ui.check(p,"Mark friends and guild members",374,-180,function(c)
    if A.Combat() then return end
    B.db.nearbyMarkSocial=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyWindow() end
  end)
  f.nearbyMarkSocial:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Mark friends and guild members"),B:Text("A heart marks friends and a shield marks guild members, next to their buffs. It does not change who gets buffed. A sound when they show up can be turned on under Customization > Binding & sound.")) end)
  f.nearbyMarkSocial:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  -- Mana reserve: 0% is off.
  ui.label(p,"Mana reserve",374,-219,"GameFontHighlightSmall",110)
  f.nearbyManaFloor=ui.slider(p,0,50,5,190,function(v) return tostring(v).."%" end,function(_,v) B.db.nearbyManaFloor=v; B:RequestRefresh("mana floor",.2) end)
  f.nearbyManaFloor:SetPoint("TOPLEFT",484,-216); f.nearbyManaFloor.visualKey="nearbyManaFloor"; f.refinedSliders[#f.refinedSliders+1]=f.nearbyManaFloor
  f.nearbyManaFloor:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Mana reserve"),B:Text("Stop offering buffs and cleanses to players outside your group when your mana is below this, until it is a little above it again. Your own buffs and your group's are not affected. If the game hides your exact mana, BuffTap judges it from which of your spells you can afford, so it stops close to this value. Set it to 0 to turn it off.")) end)
  f.nearbyManaFloor:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  -- The same setting as Helpers > Conveniences, where Nearby users don't look for it.
  f.nearbyPvp=ui.check(p,"Prevent accidental PvP flagging",26,-248,function(c)
    if A.Combat() then return end
    B.db.pvpProtection=c:GetChecked()==true; B.nearbySnapshot=nil; B:Refresh(false); B:Options()
  end)
  f.nearbyPvp:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Prevent accidental PvP flagging"),B:Text("Skip flagged or unreadable recipients while unflagged or leaving PvP. Includes group spells. Battlegrounds and arenas are exempt.").."\n"..B:Text("Only while you are unflagged. Same switch as on Helpers.")) end)
  f.nearbyPvp:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.nearbyFavor=ui.check(p,"Return the favor",374,-248,function(c)
    B.db.nearbyReturnFavor=c:GetChecked()==true; B.nearbySnapshot=nil; B.nearbyNeedCache=nil; B:Refresh(false)
  end)
  f.nearbyFavor:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Return the favor"),B:Text("Someone who buffed you in the last five minutes moves to the top of the list, below cleanses, when they need your buff or theirs is a quarter gone. A buff that answers one of yours does not count, and each player moves up at most once per half hour.")) end)
  f.nearbyFavor:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  -- How it works: the same drawn guide as the first-time introduction.
  section(ui,p,"How Nearby works",12,-306,692,418)
  local guide=CreateFrame("Frame",nil,p); guide:SetPoint("TOPLEFT",26,-346); guide:SetSize(664,366)
  self:DrawNearbyGuide(guide,664)
  self:BuildNearbyAppearance(ui,f.appearancePanes.nearby)
end
-- Customization > Nearby window: size, rows, text, button side and position.
function B:BuildNearbyAppearance(ui,p)
  local f=self.options
  section(ui,p,"Window appearance",12,-12,692,306)
  for i,spec in ipairs({{"nearbyScale","Scale",70,150,5,100,"%"},{"nearbyRows","Visible rows",2,40,1},{"nearbyWidth","Width",180,360,5,nil,"px"},{"nearbyOpacity","Background",0,100,5,100,"%"}}) do
    local key=spec[1]; local y=-56-(i-1)*44
    ui.label(p,spec[2],26,y-3,"GameFontHighlightSmall",182)
    local s=ui.slider(p,spec[3],spec[4],spec[5],462,tostring,function(_,v) B:VisualSetting(key,spec[6] and v/spec[6] or v) end)
    s:SetPoint("TOPLEFT",226,y); s.visualKey=key; s.visualMultiplier=spec[6]; if spec[7] then s:SetUnit(spec[7]) end; s:SetFieldWidth(80); f.refinedSliders[#f.refinedSliders+1]=s
  end
  -- Button side sits in the slider column as a fifth row, split evenly across the slider width.
  ui.label(p,"Invite and request buttons",26,-235,"GameFontHighlightSmall",190)
  f.nearbySide={}
  for i,spec in ipairs({{"left","Left side"},{"right","Right side"}}) do
    local side=spec[1]
    local b=ui.flatButton(p,spec[2],226+(i-1)*235,-230,227,function()
      if A.Combat() then return end
      B.db.nearbyButtonSide=side; if B.nearbyFrame then B:UpdateNearbyWindow() end; B:Options()
    end)
    b:SetHeight(24); b.navStyle="segment"; b.side=side; f.nearbySide[i]=b
  end
  -- Text: font, size and outline for the player list, in the slider column as a sixth row.
  ui.label(p,"List text",26,-277,"GameFontHighlightSmall",190)
  f.nearbyFontButton=ui.selector(p,"",226,-272,176,function() return B:NearbyFonts() end,function(v) B:VisualSetting("nearbyFont",v); B:Options() end,true)
  f.nearbyFontSizeButton=ui.selector(p,"",410,-272,110,function() return B:NearbyTextSizes() end,function(v) B:VisualSetting("nearbyFontSize",v); B:Options() end,"scroll")
  f.nearbyFontOutlineButton=ui.selector(p,"",528,-272,160,function() return B:TextOutlineChoices() end,function(v) B:VisualSetting("nearbyFontOutline",v); B:Options() end)
  section(ui,p,"Position",12,-336,692,124)
  section(ui,p,"Title bar and rows",12,-476,692,118)
  f.nearbyHideHeader=ui.check(p,"Hide the title bar until the mouse is over the window",26,-518,function(c)
    B.db.nearbyHideHeader=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyHeaderFade(true) end; B:Options()
  end)
  f.nearbyKeepLine=ui.check(p,"Keep the hairline",480,-518,function(c)
    B.db.nearbyKeepLine=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyHeaderFade(true) end
  end)
  f.nearbyAnimate=ui.check(p,"Animated list",480,-552,function(c)
    B.db.nearbyAnimate=c:GetChecked()==true; B.nearbyRowSlots=nil
  end)
  f.nearbyAnimate:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Animated list"),B:Text("Players glide to their new place when the list reorders, and new players fade in. Off when Reduce animation is on.")) end)
  f.nearbyAnimate:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.nearbyCastResult=ui.check(p,"Show whether each cast worked",26,-552,function(c)
    B.db.nearbyCastResult=c:GetChecked()==true; if not B.db.nearbyCastResult then B.nearbyResult=nil end; if B.nearbyFrame then B:UpdateNearbyWindow() end
  end)
  f.nearbyCastResult:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Show whether each cast worked"),B:Text("After you buff or cleanse a Nearby player, their row briefly turns green with a tick, or red with the game's reason, such as out of range.")) end)
  f.nearbyCastResult:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  f.nearbyLock=ui.check(p,"Lock window position",26,-378,function(c) B.db.nearbyLocked=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyWindow() end end)
  f.nearbyOnTop=ui.check(p,"Keep above other windows",226,-378,function(c)
    if A.Combat() then return end
    B.db.nearbyOnTop=c:GetChecked()==true; if B.nearbyFrame then B:UpdateNearbyWindow() end
  end)
  f.nearbyOnTop:SetScript("OnEnter",function(s) T.Tooltip(s,B:Text("Keep above other windows"),B:Text("Off: interface windows such as professions and bags open on top of Nearby. On: Nearby stays above them.")) end)
  f.nearbyOnTop:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  ui.button(p,"Move BuffTap frames",26,-416,190,function() B:MoveAllFrames("nearby") end)
  T.Confirm(ui.button(p,"Restore window defaults",450,-416,234,function()
    B.db.nearbyScale=1; B.db.nearbyRows=5; B.db.nearbyWidth=240; B.db.nearbyOpacity=.5; B.db.nearbyX=240; B.db.nearbyY=0; B.db.nearbyButtonSide="left"; B.db.nearbyFont="default"; B.db.nearbyFontSize=0; B.db.nearbyFontOutline="none"
    if B.nearbyFrame then B.nearbyFrame.positionX=nil; B.nearbyFrame.positionY=nil; B:UpdateNearbyWindow() end; B:Options()
  end))
  ui.label(p,"Drag the title bar to move the window. A hidden title bar comes back while the mouse is over it.",26,-610,"GameFontDisableSmall",650)
end

function B:BuildPatchNotesPage(ui,tabs)
  local f=self.options; local p=CreateFrame("Frame",nil,f,"BackdropTemplate"); p:Hide(); p:SetPoint("TOPLEFT",B.OptionsPageLeft,B.OptionsPageTop); p:SetPoint("BOTTOMRIGHT",B.OptionsPageRight,B.OptionsPageBottom); T.Surface(p,"panel"); f.pages[tabs.PatchNotes]=p
  f.patchDot=f.tabs[tabs.PatchNotes]:CreateTexture(nil,"OVERLAY"); f.patchDot:SetTexture(T.media.."UICornerFill"); f.patchDot:SetSize(7,7); f.patchDot:SetPoint("CENTER",f.tabs[tabs.PatchNotes],"RIGHT",-14,0); T.Track(f.patchDot,"accentIcon")
  f.patchUnread=ui.check(p,"Mark new patch notes",18,-74,function(c) B.db.optionsPatchDot=c:GetChecked()==true; B:UpdateRefinedOptions() end)
  local scroll=CreateFrame("ScrollFrame",nil,p,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",18,-116); scroll:SetPoint("BOTTOMRIGHT",-34,122)
  -- Smaller wheel steps: the template scrolls half a page per notch, too far with every release open.
  scroll:SetScript("OnMouseWheel",function(s,delta)
    local range=s:GetVerticalScrollRange() or 0; local now=s:GetVerticalScroll() or 0
    s:SetVerticalScroll(math.max(0,math.min(range,now-delta*48)))
  end)
  local child=CreateFrame("Frame",nil,scroll); child:SetSize(660,1); scroll:SetScrollChild(child)
  -- Accordion: the newest release starts open; older releases are one line each until clicked.
  local entries={}; f.patchOpen=f.patchOpen or {[1]=true}
  local function measure(fs,fallback) local h=fs:GetStringHeight(); return (type(h)=="number" and h>0) and h or fallback end
  local function relayout()
    local y=0
    for index,item in ipairs(entries) do
      local open=f.patchOpen[index]==true
      item.header:ClearAllPoints(); item.header:SetPoint("TOPLEFT",0,-y); item.header:SetPoint("RIGHT",child,"RIGHT",-6,0)
      T.Glyph(item.chevron,open and "up" or "down",12)
      y=y+36
      item.body:SetShown(open)
      if open then
        local by=10
        for _,line in ipairs(item.lines) do line:ClearAllPoints(); line:SetPoint("TOPLEFT",item.body,"TOPLEFT",30,-by); by=by+measure(line,16)+6 end
        for _,dot in ipairs(item.dots) do dot:ClearAllPoints() end
        for i,dot in ipairs(item.dots) do dot:SetPoint("TOPRIGHT",item.lines[i],"TOPLEFT",-8,0) end
        if item.thanks then item.thanks:ClearAllPoints(); item.thanks:SetPoint("TOPLEFT",item.body,"TOPLEFT",30,-(by+2)); by=by+measure(item.thanks,14)+8 end
        item.body:ClearAllPoints(); item.body:SetPoint("TOPLEFT",0,-y); item.body:SetPoint("RIGHT",child,"RIGHT",-6,0); item.body:SetHeight(by+6)
        y=y+by+6
      end
      y=y+6
    end
    child:SetHeight(math.max(1,y))
  end
  for index,entry in ipairs(self.PatchNotes) do
    local item={lines={},dots={}}
    local header=CreateFrame("Button",nil,child,"BackdropTemplate"); header:SetHeight(36); item.header=header
    header:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); header:SetBackdropColor(unpack(T.row)); T.Row(header,8)
    local version=header:CreateFontString(nil,"OVERLAY"); version:SetFontObject(T.fonts.Section); version:SetPoint("LEFT",16,0); version:SetText(entry.version)
    version.optionsSection=true; T.Track(version,"label")
    local title=header:CreateFontString(nil,"OVERLAY"); title:SetFontObject(T.fonts.Body); title:SetPoint("LEFT",96,0); title:SetPoint("RIGHT",-40,0); title:SetJustifyH("LEFT"); title:SetWordWrap(false); title:SetText(B:Text(entry.title))
    item.chevron=header:CreateTexture(nil,"ARTWORK"); item.chevron:SetPoint("RIGHT",-14,0)
    header:SetScript("OnClick",function() f.patchOpen[index]=not f.patchOpen[index] or nil; relayout() end)
    local body=CreateFrame("Frame",nil,child); item.body=body
    for _,text in ipairs(entry.items) do
      local line=body:CreateFontString(nil,"OVERLAY"); line:SetFontObject(T.fonts.Note); line:SetWidth(590); line:SetJustifyH("LEFT"); line:SetWordWrap(true); line:SetText(B:Text(text))
      local dot=body:CreateFontString(nil,"OVERLAY"); dot:SetFontObject(T.fonts.Muted); dot:SetText("•")
      item.lines[#item.lines+1]=line; item.dots[#item.dots+1]=dot
    end
    if entry.thanks then item.thanks=body:CreateFontString(nil,"OVERLAY"); item.thanks:SetFontObject(T.fonts.Muted); item.thanks:SetWidth(590); item.thanks:SetJustifyH("LEFT"); item.thanks:SetText(B:Text(entry.thanks)) end
    entries[index]=item
  end
  relayout(); p:HookScript("OnShow",relayout)
  ui.label(p,"Recent updates only. The complete history is available on GitHub.",26,-618,"GameFontDisableSmall",670)
  local link=ui.editbox(p,26,-650,664,false); link:SetFontObject("GameFontHighlightSmall"); link:SetJustifyH("LEFT"); link:SetTextInsets(8,8,0,0); link:SetText("https://github.com/Hitshade/BuffTap/releases"); link:SetScript("OnEditFocusGained",function(s) s:HighlightText() end); link:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)
  link:SetScript("OnEnterPressed",function(s) s:ClearFocus() end)
  link:SetScript("OnTextChanged",function(s,user) if user then s:SetText("https://github.com/Hitshade/BuffTap/releases"); s:HighlightText() end end)
end
function B:StandardizeOptionsPages(ui,tabs)
  local f=self.options; f.pageHeaders={}
  local titles={"My buffs","Party & raid buffing","Friendly target buffing","Nearby buffing & players","Consumables","Camping & sleeping bag","Weapon buffs","Customization","Helpers","Profiles","Diagnostics & performance","Patch notes","Blacklist","Cleanse & revive","Supplies"}
  local descriptions={"Your class buffs: what to cast, when to refresh, and in what order.","Independent preferences for your five-player party and raid.","Offer selected single-target buffs to the friendly player you target.","Buff players around you, invite someone new, or browse the list.","Maintain your chosen food, flask, elixirs and special buffs.","Separate camp and sleeping-bag reminders, without blocking buffing.","Maintain your preferred weapon buffs with your normal binding.","Make your reminders and interface feel right for you.","Optional conveniences. Enable only the ones you find useful.","Save, switch and copy named setups between your characters.","Check what BuffTap is doing and collect information for a report.","A short, plain-language history of recent changes.","Players and guilds that BuffTap never offers buffs or invites to.","Remove poisons, curses, diseases and magic, and bring fallen players back, out of combat.","Track anything you carry and get a warning when you run low."}
  local contextPages={[1]=true,[2]=true,[5]=true,[7]=true}
  for index,page in ipairs(f.pages) do
    local function hideHead(container)
      for _,region in ipairs({container:GetRegions()}) do
        if region.optionsLabel then
          local _,_,_,x,y=region:GetPoint(1)
          if type(x)=="number" and type(y)=="number" and x<=30 and y>=-60 and y<=0 then region:Hide() end
        end
      end
    end
    hideHead(page)
    if contextPages[index] then
      local children={page:GetChildren()}; local regions={page:GetRegions()}
      local canvas=CreateFrame("Frame",nil,page); canvas:SetPoint("TOPLEFT",0,-64); canvas:SetPoint("BOTTOMRIGHT",0,0); page.refinedCanvas=canvas
      for _,child in ipairs(children) do if child~=page.NineSlice then reparent(child,canvas); hideHead(child) end end
      for _,region in ipairs(regions) do if region.optionsLabel or region.optionsDecoration then reparent(region,canvas) end end
      if index==1 or index==7 then
        local body=index==1 and f.buffContent or f.weaponContent; body:ClearAllPoints(); body:SetPoint("TOPLEFT",0,0); body:SetPoint("BOTTOMRIGHT",0,0)
      elseif index==5 then
        -- The consumable subpages retain their own fixed-height content below a shared setup toolbar.
        for _,child in ipairs({f.consumableBody:GetChildren()}) do
          if child~=nil and child:GetObjectType()=="Frame" then hideHead(child) end
        end
        for _,group in pairs(self.contextControls or {}) do if group.category=="consumables" then
          for _,control in pairs(group.buttons) do reparent(control,canvas) end
          reparent(group.active,canvas); reparent(group.reset,canvas); reparent(group.status,canvas)
        end end
        -- 1.24.4: the Buff items / Supplies tabs are gone, so the content moves up into their row.
        f.consumableBody:ClearAllPoints(); f.consumableBody:SetPoint("TOPLEFT",0,-36); f.consumableBody:SetPoint("BOTTOMRIGHT",0,0)
        for _,child in ipairs({f.consumableBody:GetChildren()}) do child:ClearAllPoints(); child:SetPoint("TOPLEFT",0,0); child:SetPoint("BOTTOMRIGHT",0,0); hideHead(child) end
        f.supplyBody:ClearAllPoints(); f.supplyBody:SetPoint("TOPLEFT",0,-72); f.supplyBody:SetPoint("BOTTOMRIGHT",0,0); hideHead(f.supplyBody)
        for _,child in ipairs(children) do if child~=f.consumableBody and child~=f.supplyBody and child:GetObjectType()=="Button" then local _,_,_,x=child:GetPoint(); place(child,canvas,x or 18,-68,104,26) end end
      end
    end
    -- Open header: accent icon, large title, muted description and a hairline, without a boxed card.
    T.Rule(page,12,-63,692)
    local icon=page:CreateTexture(nil,"ARTWORK"); icon:SetSize(22,22); icon:SetPoint("TOPLEFT",14,-14)
    icon:SetTexture(T.media.."Nav"..(f.navIcons and f.navIcons[index] or "Buffs")); T.Track(icon,"accentIcon"); page.headerIcon=icon
    -- Header right column, same on every page: the page switch on top (x 480, y -14),
    -- shortcuts such as Customize look below it, right-aligned (y -38). Text stays left of it.
    local title=ui.label(page,titles[index],46,-13,T.fonts.Title,420); title.optionsTitle=true
    local description=ui.label(page,descriptions[index],46,-41,"GameFontDisableSmall",(index==tabs.PatchNotes or index==tabs.Profiles) and 640 or 420)
    -- Shortcut to the reminder's look from pages whose reminders use it (Camping has its own).
    if index==tabs.Helpers then description:SetWidth(346) end
    if index==1 or index==5 or index==6 or index==7 or index==15 then
      -- Header line, top right. Consumables and Weapons keep their switch at the right edge, so the button sits just left of it.
      -- (The Solo / Party / Raid row needs its right end for "Use Solo settings".)
      title:SetWordWrap(false)
      page.customizeLook=ui.button(page,"Customize look",566,-35,138,function() f.selectTab(tabs.Appearance); B:SetAppearanceView(index==6 and "camp" or index==15 and "supply" or "buff") end); page.customizeLook:SetHeight(20)
    end
    if index==tabs.Nearby then
      -- Buff requests live on Helpers but are offered from the Nearby window, so link them here.
      page.requestsShortcut=ui.button(page,"Buff requests",566,-35,138,function() f.selectTab(tabs.Helpers) end); page.requestsShortcut:SetHeight(20)
      page.openWindow=ui.button(page,"Open window",420,-35,138,function() B:ShowNearbySetup() end); page.openWindow:SetHeight(20)
      description:SetWidth(366)
    end
    f.pageHeaders[index]={title=title,description=description}
  end
  for _,category in ipairs({"buffs","weapons"}) do
    local group=self.contextControls[category]; local page=f.pages[category=="buffs" and 1 or 7]
    for _,control in pairs(group.buttons) do reparent(control,page.refinedCanvas) end
    reparent(group.active,page.refinedCanvas); reparent(group.reset,page.refinedCanvas); reparent(group.status,page.refinedCanvas)
  end
  local groupPage=f.pages[2]; local party=f.partyView or f.groupParty; local raid=f.raidView or f.groupRaid
  place(party,groupPage.refinedCanvas,18,-8,78,26); place(raid,groupPage.refinedCanvas,102,-8,78,26)
  ui.label(groupPage.refinedCanvas,"Applies automatically when you join a party or raid.",198,-15,"GameFontDisableSmall",488)
  local master=f.blessingGroupEnable or f.groupEnable
  if master then headerSwitch(master,groupPage) end
  headerSwitch(f.friendlyTarget,f.pages[3])
  headerSwitch(f.weaponEnable,f.pages[7])
  place(f.weaponRetry,f.weaponApply:GetParent(),528,-548,154,26)
  place(f.weaponApply,f.weaponApply:GetParent(),180,-64,502,26)
  ui.label(f.weaponApply:GetParent(),"Application mode",26,-70,"GameFontHighlightSmall",150)
  headerSwitch(f.consumablesEnable,f.pages[5])
  headerSwitch(f.supplyEnable,f.pages[15])
  -- Supplies has no Solo / Party / Raid row, so its body starts right under the page header.
  f.supplyBody:ClearAllPoints(); f.supplyBody:SetPoint("TOPLEFT",0,-8); f.supplyBody:SetPoint("BOTTOMRIGHT",0,0)
  -- Keep exact coordinates available without crowding the appearance editors.
  local binding=f.appearancePanes.binding
  ui.label(binding,"Buff reminder position",26,-588,"GameFontHighlightSmall",150)
  ui.label(binding,"X",186,-588,"GameFontHighlightSmall",20); place(f.xEdit,binding,204,-582,80,24)
  ui.label(binding,"Y",300,-588,"GameFontHighlightSmall",20); place(f.yEdit,binding,318,-582,80,24)
  for _,edit in ipairs({f.xEdit,f.yEdit}) do
    edit:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Buff reminder position"),B:Text("Press Enter to save each coordinate.")) end)
    edit:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  end
  T.Variant(ui.button(binding,"Move BuffTap frames",510,-582,178,function() B:MoveAllFrames("binding") end),"primary")
  -- The page area is 34 px taller than before; the list grows and the footer follows its bottom-anchored controls.
  ui.card(f.buffContent,12,-64,692,418)
  local setupFooter=ui.card(f.buffContent,12,-494,692,50)
  place(f.smartShift,f.buffContent,28,-506,340,24)
  place(f.classSetup,f.buffContent,522,-504,166,28)
  local rebuffFooter=ui.card(f.buffContent,12,-556,692,96)
  f.timingLabel:ClearAllPoints(); f.timingLabel:SetPoint("TOPLEFT",f.buffContent,"TOPLEFT",28,-568)
  f.timingLabel:SetFontObject(T.fonts.Section); T.SectionTitle(f.timingLabel); T.Track(f.timingLabel,"label")
  f.timingHint:ClearAllPoints(); f.timingHint:SetPoint("TOPLEFT",f.buffContent,"TOPLEFT",28,-590)
  f.resetBuffsButton:ClearAllPoints(); f.resetBuffsButton:SetPoint("BOTTOMRIGHT",rebuffFooter,"BOTTOMRIGHT",-14,14)
  ui.card(f.pages[3],12,-174,692,498)
  f.weaponHint:Hide()
end
-- Sidebar status lights: a green light when a page's feature is on, a hollow ring when it is off.
-- Pages with nothing to switch on have no light.
function B:NavStatus(index)
  local f,d=self.options,self.db
  if index==1 then return d.enabled==true
  elseif index==14 then return d.cleanseEnabled==true
  elseif index==2 then local c=f.blessingGroupEnable or f.groupEnable; if c then return c:GetChecked()==true end; return d.group==true
  elseif index==3 then return d.friendlyTarget==true
  elseif index==4 then return d.nearbyEnabled==true
  elseif index==5 then return d.consumablesEnabled==true
  elseif index==15 then return d.suppliesEnabled==true
  elseif index==6 then return d.campReminder==true
  elseif index==7 then return d.weaponReminder==true end
end
function B:UpdateNavStatus()
  local f=self.options; if not f or not f.tabs then return end
  local T=B.OptionsTheme
  for i,tab in ipairs(f.tabs) do
    local on=self:NavStatus(i)
    if on~=nil then
      local light=tab.statusLight
      if not light then
        light=tab:CreateTexture(nil,"OVERLAY"); light:SetSize(8,8); light:SetPoint("CENTER",tab,"RIGHT",-16,0); tab.statusLight=light
        tab:HookScript("OnEnter",function(s)
          if s.statusOn==nil then return end
          if s.statusWarning then T.Tooltip(s,s:GetText() or "",B:Text(s.statusWarning)); return end
          T.Tooltip(s,s:GetText() or "",B:Text(s.statusOn and "Turned on" or "Turned off"))
        end)
        tab:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
      end
      tab.statusOn=on
      -- Nearby on but friendly nameplates off: it can't see anyone, so the light turns red.
      local warn=i==4 and on and self.FriendlyPlatesState and self:FriendlyPlatesState()==false
      tab.statusWarning=warn and "Turned on, but friendly nameplates are off, so Nearby can't see other players. Press Shift+V to show them." or nil
      light:SetTexture(T.media..(on and "UIStatusOn" or "UIStatusOff"))
      if warn then light:SetVertexColor(.93,.30,.26,1)
      elseif on then light:SetVertexColor(.35,.77,.43,1) else light:SetVertexColor(.45,.48,.53,1) end
      light:Show()
    end
  end
end
function B:UpdateRefinedOptions()
  if self.options and self.options.nearbyRankUpgrades then
    local class=A.Class("player")
    self.options.nearbyRankUpgrades:SetShown(class=="DRUID" or class=="MAGE" or class=="PRIEST" or class=="PALADIN")
    self.options.nearbyRankUpgrades:SetChecked(self.db.nearbyRankUpgrades==true)
  end
  if self.options and self.options.detachConsumables then
    self.options.detachConsumables:SetChecked(self.db.manualConsumablesDetached==true)
  end
  if self.UpdateCleansePage then self:UpdateCleansePage() end
  self:UpdateNavStatus()
  local f=self.options; if not f or not f.appearancePanes then return end
  self:NormalizeVisualOptions()
  local width,height=A.Call(UIParent.GetWidth,UIParent),A.Call(UIParent.GetHeight,UIParent)
  if A.Number(width) and A.Number(height) then f:SetScale(math.min(self.db.optionsScale,(width-32)/932,(height-32)/900)) end
  for _,s in ipairs(f.refinedSliders) do
    local value=self.db[s.visualKey]
    if (s.visualKey=="labelSize" or s.visualKey=="campTextSize" or s.visualKey=="supplyTextSize") and (not value or value==0) then local _,size=self:BaseTextFont("GameFontHighlightSmall"); value=A.Number(size) and size or 12 end
    if type(value)=="number" then s.silent=true; s:SetValue(value*(s.visualMultiplier or 1)); s.silent=false end
  end
  f.accentPick:SetEnabled(ColorPickerFrame and type(ColorPickerFrame.SetupColorPickerAndShow)=="function" or false)
  f.accentMode:SetText(self:Text(({gold="BuffTap gold",class="My class",custom="Custom colour"})[self.db.optionsAccentMode]))
  if not f.accentHex:HasFocus() then f.accentHex:SetText(self.db.optionsAccentColor) end
  do local a=T.accent; f.accentSwatch:SetBackdropColor(a[1],a[2],a[3],1); f.accentSwatchText:SetText(string.format("#%02X%02X%02X",math.floor(a[1]*255+.5),math.floor(a[2]*255+.5),math.floor(a[3]*255+.5))) end
  local styles={classic="Classic",modern="Modern square"}; local positions={split="Split",above="Above icon",below="Below icon"}
  if f.iconStyleButton then f.iconStyleButton:SetText(self:Text(styles[self.db.iconStyle] or "Classic")) end
  if f.campIconStyleButton then f.campIconStyleButton:SetText(self:Text(styles[self.db.campIconStyle] or "Classic")) end
  if f.supplyIconStyleButton then
    self:NormalizeSupplyReminder(); local d=self.db
    f.supplyIconStyleButton:SetText(self:Text(styles[d.supplyIconStyle] or "Classic"))
    local function pick(button,list,value) for _,v in ipairs(list) do if v.key==value then button:SetText(self:Text(v.name)) end end end
    pick(f.supplyTextFont,self:ReminderFonts(d.supplyTextFont),self:NormalizeTextFontKey(d.supplyTextFont))
    pick(f.supplyTextColor,self:ReminderColors(true),d.supplyTextColor)
    pick(f.supplyTextOutline,self:TextOutlineChoices(),d.supplyTextOutline)
    pick(f.supplyEffect,B.EffectChoices,d.supplyEffectStyle); pick(f.supplyColor,B.EffectColorChoices,d.supplyEffectColor); pick(f.supplySpeed,B.EffectSpeedChoices,d.supplyEffectSpeed)
    f.supplyShowName:SetChecked(d.supplyShowName); f.supplyShowCount:SetChecked(d.supplyShowCount)
  end
  if f.labelPositionButton then f.labelPositionButton:SetText(self:Text(positions[self.db.labelPosition] or "Split")) end
  if f.swipeCheck then f.swipeCheck:SetChecked(self.db.showSwipe==true) end
  if f.rangeCheck then f.rangeCheck:SetChecked(self.db.showOutOfRange==true) end
  f.reduceMotion:SetChecked(self.db.optionsReduceMotion); f.nearbyLock:SetChecked(self.db.nearbyLocked==true); if f.nearbyAnimate then f.nearbyAnimate:SetChecked(self.db.nearbyAnimate==true) end; if f.nearbyFavor then f.nearbyFavor:SetChecked(self.db.nearbyReturnFavor~=false) end; if f.nearbyPvp then f.nearbyPvp:SetChecked(self.db.pvpProtection==true) end; if f.nearbyOnTop then f.nearbyOnTop:SetChecked(self.db.nearbyOnTop==true) end; if f.nearbyShowLevel then f.nearbyShowLevel:SetChecked(self.db.nearbyShowLevel==true) end; if f.nearbyMarkSocial then f.nearbyMarkSocial:SetChecked(self.db.nearbyMarkSocial~=false) end; if f.nearbyWhileResting then f.nearbyWhileResting:SetChecked(self.db.nearbyWhileResting==true) end; if f.nearbyCastResult then f.nearbyCastResult:SetChecked(self.db.nearbyCastResult~=false) end; if f.socialAlert then f.socialAlert:SetChecked(self.db.nearbySocialAlert==true); f.socialFriends:SetChecked(self.db.nearbySocialFriends~=false); f.socialGuild:SetChecked(self.db.nearbySocialGuild~=false); f.socialFriends:SetEnabled(self.db.nearbySocialAlert==true); f.socialGuild:SetEnabled(self.db.nearbySocialAlert==true) end; if f.nearbyHoldShort then f.nearbyHoldShort:SetChecked(self.db.nearbyHoldShort==true); f.nearbyHoldShort:SetEnabled(not (self.db.pauseResting and self.db.nearbyWhileResting~=true)) end; if f.nearbyHideHeader then f.nearbyHideHeader:SetChecked(self.db.nearbyHideHeader==true); f.nearbyKeepLine:SetChecked(self.db.nearbyKeepLine~=false); f.nearbyKeepLine:SetEnabled(self.db.nearbyHideHeader==true) end; if f.nearbyFullNames then f.nearbyFullNames:SetChecked(self.db.nearbyFullNames~=false) end
  if f.nearbyFontButton then
    for _,v in ipairs(self:NearbyFonts()) do if v.key==self.db.nearbyFont then f.nearbyFontButton:SetText(self:Text(v.name)) end end
    for _,v in ipairs(self:NearbyTextSizes()) do if v.key==self.db.nearbyFontSize then f.nearbyFontSizeButton:SetText(v.name) end end
    for _,v in ipairs(self:TextOutlineChoices()) do if v.key==self.db.nearbyFontOutline then f.nearbyFontOutlineButton:SetText(self:Text(v.name)) end end
  end
  for _,b in ipairs(f.nearbySide or {}) do T.Navigation(b,b.side==(self.db.nearbyButtonSide=="right" and "right" or "left")) end
  f.patchUnread:SetChecked(self.db.optionsPatchDot~=false); f.patchDot:SetShown(self:PatchNotesUnread() and true or false)
  if f.weaponHint then f.weaponHint:Hide() end
  T.Polish(f)
  for _,page in ipairs(f.pages or {}) do T.InsetCards(page) end
  T.Refresh()
  -- Font boxes show the chosen font in that font (after the theme refresh, which resets fonts).
  if f.nearbyFontButton then self:PreviewChoiceFont(f.nearbyFontButton,self:FontPathForKey(self.db.nearbyFont)) end
  local function reminderFont(key) key=self:NormalizeTextFontKey(key); if key=="names" then return UNIT_NAME_FONT elseif key=="numbers" then return DAMAGE_TEXT_FONT end; return self:BaseTextFont("GameFontHighlightSmall") or STANDARD_TEXT_FONT end
  if f.fontButton then self:PreviewChoiceFont(f.fontButton,reminderFont(self.db.labelFont)) end
  if f.campingTextFont then self:PreviewChoiceFont(f.campingTextFont,reminderFont(self.db.campTextFont)) end
end
function B:OpenAccentPicker()
  if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then return end
  self.options.accentHex:ClearFocus()
  local original=self.db.optionsAccentColor; local mode=self.db.optionsAccentMode
  local function change()
    local r,g,b=ColorPickerFrame:GetColorRGB()
    B:VisualSetting("optionsAccentColor",string.format("%02x%02x%02x",math.floor(r*255+.5),math.floor(g*255+.5),math.floor(b*255+.5)))
    B:VisualSetting("optionsAccentMode","custom")
  end
  ColorPickerFrame:SetupColorPickerAndShow({r=tonumber(original:sub(1,2),16)/255,g=tonumber(original:sub(3,4),16)/255,b=tonumber(original:sub(5,6),16)/255,swatchFunc=change,cancelFunc=function() B:VisualSetting("optionsAccentColor",original); B:VisualSetting("optionsAccentMode",mode) end})
end
