-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local function L(s) return B:Text(s) end
local function read(fn,...)
  if type(fn)~="function" then return nil end
  local ok,v=pcall(fn,...)
  if ok and A.Public(v) then return v end
end
local function clock(n)
  if not A.Number(n) then return "?" end
  n=math.max(0,math.ceil(n))
  return n>=60 and string.format("%dm %02ds",math.floor(n/60),n%60) or tostring(n).."s"
end
function B:NormalizeCamping()
  local d=self.db
  for _,k in ipairs({"campReminder","campAnywhere","campSound"}) do if type(d[k])~="boolean" then d[k]=false end end
  if d.campWarningVersion~=1 then d.campAnywhere=true; d.campWarningVersion=1 end
  for _,k in ipairs({"campTrackBenefits","campTrackBag"}) do if type(d[k])~="boolean" then d[k]=true end end
  for _,k in ipairs({"campShowCountdown","campShowStacks"}) do if type(d[k])~="boolean" then d[k]=true end end
  d.campTextFont=self:NormalizeTextFontKey(d.campTextFont)
  if not ({gold=true,cyan=true,green=true,red=true,white=true})[d.campTextColor] then d.campTextColor="white" end
  d.campTextSize=A.Number(d.campTextSize) and (d.campTextSize==0 and 0 or math.max(8,math.min(20,math.floor(d.campTextSize)))) or 0
  d.campTextGap=A.Number(d.campTextGap) and math.max(0,math.min(20,math.floor(d.campTextGap))) or 4
  if d.campTextOutline=="default" then d.campTextOutline=self:GameTextOutline() end
  if not ({none=true,outline=true,thick=true})[d.campTextOutline] then d.campTextOutline="outline" end
  d.campSize=A.Number(d.campSize) and math.max(24,math.min(96,d.campSize)) or 40
  d.campOpacity=A.Number(d.campOpacity) and math.max(.25,math.min(1,d.campOpacity)) or 1
  if not ({none=true,soft=true,pulse=true,pixel=true,autocast=true,proc=true})[d.campEffectStyle] then d.campEffectStyle="soft" end
  if not ({gold=true,cyan=true,green=true,red=true,white=true})[d.campEffectColor] then d.campEffectColor="gold" end
  if not ({slow=true,normal=true,fast=true})[d.campEffectSpeed] then d.campEffectSpeed="normal" end
  d.campWarning=A.Number(d.campWarning) and math.max(60,math.min(1800,d.campWarning)) or 300
  d.campX=A.Number(d.campX) and math.max(-4000,math.min(4000,d.campX)) or 100
  d.campY=A.Number(d.campY) and math.max(-4000,math.min(4000,d.campY)) or -180
end
local function aura(id)
  local fn=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
  if type(fn)~="function" then return nil,false end
  local ok,v=pcall(fn,id)
  if not ok or not A.Public(v) then return nil,false end
  if v==nil then return nil,true end
  if type(v)~="table" or not A.Public(v.expirationTime) or not A.Public(v.duration) then return nil,false end
  return v,true
end
function B:CampingState()
  if A.Combat() then return {unknown=true,globalUnknown=true} end
  if C_Secrets and C_Secrets.ShouldAurasBeSecret and read(C_Secrets.ShouldAurasBeSecret)~=false then return {unknown=true,globalUnknown=true} end
  local ids=self.CampingAuras
  local benefits,ok=aura(ids.benefits)
  local near,nearOK=aura(ids.near)
  local state={readAt=GetTime(),unknown=not ok or not nearOK,campUnknown=not ok,nearUnknown=not nearOK,near=near~=nil,active=benefits~=nil}
  if benefits and A.Number(benefits.expirationTime) and benefits.expirationTime>0 then state.remaining=math.max(0,benefits.expirationTime-GetTime()) end
  for _,id in ipairs(ids.waiting) do
    local waiting,known=aura(id)
    if not known then state.unknown=true end
    if waiting and A.Number(waiting.expirationTime) and waiting.expirationTime>GetTime() then
      state.waiting=waiting.expirationTime-GetTime(); state.waitDuration=A.Number(waiting.duration) and waiting.duration>0 and waiting.duration or nil
    end
  end
  local bag,bagOK=aura(self.SleepingBagAuras.benefits)
  local resting,restOK=aura(self.SleepingBagAuras.resting)
  state.bagUnknown=not bagOK
  state.bagActive=bag~=nil; state.bagResting=resting~=nil and restOK
  state.bagStacks=0
  if bag then
    if not A.Public(bag.applications) then state.bagUnknown=true
    else state.bagStacks=A.Number(bag.applications) and math.max(1,math.floor(bag.applications)) or 1 end
    if A.Number(bag.expirationTime) and bag.expirationTime>0 then state.bagRemaining=math.max(0,bag.expirationTime-GetTime()) end
  end
  state.bagNotNeeded=read(UnitXPMax,"player")==0
  return state
end
function B:CampingNeeds(state)
  if state.globalUnknown then return false,false end
  local d=self.db
  local camp=d.campTrackBenefits and not state.campUnknown and (not state.active or (state.remaining~=nil and state.remaining<=d.campWarning))
  local bag=d.campTrackBag and not state.bagUnknown and not state.bagNotNeeded and (not state.bagActive or state.bagStacks<self.SleepingBagAuras.maxStacks or (state.bagRemaining~=nil and state.bagRemaining<=d.campWarning))
  return camp==true,bag==true
end
function B:CampNeedsReminder(state)
  local d=self.db
  if not d or not d.enabled or not d.campReminder or state.globalUnknown or A.Combat() then return false end
  if self.campSnoozeSession or (self.campSnoozeUntil and self.campSnoozeUntil>GetTime()) then return false end
  if read(UnitIsDeadOrGhost,"player")==true or read(IsMounted)==true or read(IsInInstance)==true then return false end
  local camp,bag=self:CampingNeeds(state)
  return (d.campAnywhere or state.near or state.waiting~=nil or state.bagResting) and (camp or bag)
end
local function professionMap()
  local result={}
  if type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then return result end
  local ok,a,b,c,d,e,f=pcall(GetProfessions)
  if not ok then return result end
  for _,index in pairs({a,b,c,d,e,f}) do
    local good,_,_,skill,_,_,_,id=pcall(GetProfessionInfo,index)
    if good and A.Number(id) and A.Number(skill) then result[id]=skill end
  end
  return result
end
local function currentProfession()
  local api=C_TradeSkillUI
  if api then for _,key in ipairs({"IsTradeSkillLinked","IsTradeSkillGuild","IsTradeSkillNPCCrafting"}) do
    if type(api[key])=="function" and read(api[key])~=false then return nil end
  end end
  local info=read(C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo)
  return type(info)=="table" and A.Number(info.professionID) and info.professionID or nil
end
function B:CampingEntries()
  if self.campEntries then return self.campEntries end
  local profs=professionMap(); local best={}; local order={}; local learned=self.campLearned or {}; self.campLearned=learned
  local faction=read(UnitFactionGroup,"player")
  for _,entry in ipairs(self.CampingItems) do
    if not entry.faction or entry.faction==faction then
      local count=read(C_Item and C_Item.GetItemCount,entry.item,false,false,false,false)
      count=A.Number(count) and count or 0
      local skill=profs[entry.profession]
      if currentProfession()==entry.profession then
        local info=read(C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo,entry.recipe)
        if type(info)=="table" and A.Public(info.learned) and type(info.learned)=="boolean" then learned[entry.recipe]=info.learned end
      end
      local known=learned[entry.recipe]
      if count>0 or (skill and skill>=entry.skill and known~=false) then
        local usable=count>0 and read(C_Item and C_Item.IsUsableItem,entry.item)==true
        local score=count>0 and (usable and 20000 or 10000)+entry.skill or known and 5000+entry.skill or 1000-entry.skill
        local old=best[entry.family]
        if not old then order[#order+1]=entry.family end
        if not old or score>old.score then best[entry.family]={data=entry,count=count,learned=known,score=score} end
      end
    end
  end
  local bagItem=self.SleepingBag
  local bagCount=read(C_Item and C_Item.GetItemCount,bagItem.item,false,false,false,false)
  if A.Number(bagCount) and bagCount>0 then
    best[bagItem.family]={data=bagItem,count=bagCount,score=30000}; table.insert(order,1,bagItem.family)
  end
  local list={}
  for index,family in ipairs(order) do best[family].order=index; list[#list+1]=best[family] end
  table.sort(list,function(a,b) if (a.count>0)~=(b.count>0) then return a.count>0 end; return a.order<b.order end)
  self.campEntries=list
  return list
end
function B:CampBagSlot(id)
  if not C_Container or type(C_Container.GetContainerItemInfo)~="function" then return nil end
  for bag=0,(NUM_BAG_SLOTS or 4) do
    local count=read(C_Container.GetContainerNumSlots,bag)
    if A.Number(count) then for slot=1,count do
      local info=read(C_Container.GetContainerItemInfo,bag,slot)
      if type(info)=="table" and A.Public(info.itemID) and info.itemID==id and A.Public(info.isLocked) and not info.isLocked then
        return bag,slot
      end
    end end
  end
end
function B:CampItemReady(entry)
  if A.Combat() or read(UnitIsDeadOrGhost,"player")==true or read(IsMounted)==true then return nil end
  local state=self:CampingState()
  if state.globalUnknown then return nil end
  if entry.family~="sleeping-bag" and (state.campUnknown or state.nearUnknown or (entry.family~="feuer" and not state.near)) then return nil end
  if read(C_Item and C_Item.IsUsableItem,entry.item)~=true then return nil end
  if not C_Item or type(C_Item.GetItemSpell)~="function" then return nil end
  local spellOK,_,spellID=pcall(C_Item.GetItemSpell,entry.item)
  if not spellOK or not A.Number(spellID) or spellID~=entry.use then return nil end
  local bag,slot=self:CampBagSlot(entry.item)
  if not bag then return nil end
  local fn=C_Container and C_Container.GetContainerItemCooldown
  if type(fn)~="function" then return nil end
  local ok,start,duration,enabled=pcall(fn,bag,slot)
  if not ok or not A.Number(start) or not A.Number(duration) or not A.Public(enabled) or enabled==0 or enabled==false then return nil end
  if start>0 and start+duration>GetTime() then return nil,start+duration-GetTime() end
  return tostring(bag).." "..tostring(slot)
end
function B:CraftCampEntry(entry)
  if A.Combat() or not self.db or not self.db.enabled then return false end
  local api=C_TradeSkillUI
  if not api then return false end
  if currentProfession()~=entry.profession then
    if api.OpenTradeSkill then pcall(api.OpenTradeSkill,entry.profession) end
    self.Print("Profession opened. Click the recipe again to craft one item.")
    return false
  end
  if api.IsTradeSkillReady and read(api.IsTradeSkillReady)~=true then return false end
  local info=read(api.GetRecipeInfo,entry.recipe)
  if type(info)~="table" or not A.Public(info.learned) or info.learned~=true then self.Print("This camp recipe is not learned."); return false end
  if A.Number(info.numAvailable) and info.numAvailable<1 then self.Print("Missing materials for this camp recipe."); return false end
  if type(api.CraftRecipe)~="function" then return false end
  return pcall(api.CraftRecipe,entry.recipe,1)
end
function B:PrepareCampButton(row)
  if A.Combat() then return end
  row:SetAttribute("type1",nil); row:SetAttribute("item",nil)
  row.campCraftClick=nil
  local choice=row.choice
  if not choice or not self.db or not self.db.enabled then return end
  local entry=choice.data
  local bag=self:CampBagSlot(entry.item)
  if bag then
    local slot=self:CampItemReady(entry)
    if slot then row:SetAttribute("item",slot); row:SetAttribute("type1","item") end
  elseif choice.count==0 and read(C_Item and C_Item.GetItemCount,entry.item,false,false,false,false)==0 then row.campCraftClick=true end
end
-- The camp tray shares the settings window's theme: Inter type, rounded surfaces and themed buttons.
local THEME_FONTS={GameFontNormalLarge="Sub",GameFontHighlightSmall="Small",GameFontDisableSmall="Muted",GameFontNormalSmall="Heading"}
local function text(parent,value,x,y,font,width)
  local T=B.OptionsTheme; local key=THEME_FONTS[font or "GameFontHighlightSmall"]
  local fs=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  if T and T.fonts and key and T.fonts[key] then fs:SetFontObject(T.fonts[key]) end
  fs:SetPoint("TOPLEFT",x,y); fs:SetText(L(value))
  if width then fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true) end
  return fs
end
local function action(parent,label,x,y,width,fn)
  local T=B.OptionsTheme
  local btn=CreateFrame("Button",nil,parent,"BackdropTemplate")
  btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  btn:SetBackdropColor(unpack(T.control)); btn:SetBackdropBorderColor(unpack(T.border))
  T.Button(btn)
  btn:SetPoint("TOPLEFT",x,y); btn:SetSize(width,26); btn:SetText(L(label)); btn:SetScript("OnClick",fn)
  return btn
end
local function surface(frame,radius)
  local T=B.OptionsTheme
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); frame:SetBackdropColor(unpack(T.window))
  T.Round(frame,radius or 10,"surface"); T.LockBorder(frame,1,1,1,.08)
end
local function backdrop(frame)
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  frame:SetBackdropColor(unpack(B.OptionsTheme.menu)); frame:SetBackdropBorderColor(.50,.42,.26,1)
end
function B:SnoozeCamping(seconds)
  self.campPreviewUntil=nil
  self.campSnoozeSession=seconds==0; self.campSnoozeUntil=seconds>0 and GetTime()+seconds or nil
  if self.campSnoozeMenu then self.campSnoozeMenu:Hide() end
  self:UpdateCamping()
end
local function labelClock(value)
  value=math.max(0,math.ceil(value))
  if value>=3600 then return string.format("%dh %02dm",math.floor(value/3600),math.floor(value%3600/60)) end
  return clock(value)
end
function B:CampLabelText(state,preview)
  local d=self.db; local lines={}
  local elapsed=math.max(0,GetTime()-(state.readAt or GetTime()))
  local function remaining(value) return A.Number(value) and math.max(0,value-elapsed) or nil end
  if d.campShowCountdown and d.campTrackBenefits then
    local value=preview and 45 or remaining(state.waiting or state.remaining)
    local label=(state.globalUnknown or state.campUnknown) and "?" or value and labelClock(value) or state.active and L("active") or L("missing")
    lines[#lines+1]=L("Camp:").." "..label
  end
  if d.campTrackBag and (not state.bagNotNeeded or preview) and (d.campShowStacks or d.campShowCountdown) then
    local label
    if state.globalUnknown or state.bagUnknown then label="?"
    else
      local stacks=preview and 2 or state.bagStacks or 0
      local value=preview and 7199 or remaining(state.bagRemaining)
      local count=d.campShowStacks and tostring(stacks).."/3" or nil
      local timer=d.campShowCountdown and value and labelClock(value) or nil
      label=count and timer and count.." - "..timer or count or timer or (state.bagActive and L("active") or L("missing"))
    end
    lines[#lines+1]=L("Bag:").." "..label
  end
  return table.concat(lines,"\n")
end
function B:StyleCampLabel(icon)
  local d=self.db
  local key=table.concat({d.campTextFont,d.campTextColor,d.campTextSize,d.campTextOutline,d.campTextGap,tostring(UNIT_NAME_FONT),tostring(DAMAGE_TEXT_FONT)},":")
  if icon.campLabelStyle==key then return end
  icon.campLabelStyle=key
  self.campTextSettings=self.campTextSettings or {}
  local style=self.campTextSettings
  style.labelFont=d.campTextFont; style.labelColor=d.campTextColor; style.labelSize=d.campTextSize; style.labelOutline=d.campTextOutline
  self:ApplyLabelStyle(icon.time,style,"GameFontHighlightSmall")
  icon.time:ClearAllPoints(); icon.time:SetPoint("TOP",icon,"BOTTOM",0,-d.campTextGap)
  icon.time:SetWidth(math.max(160,(d.campTextSize>0 and d.campTextSize or 12)*20)); icon.time:SetJustifyH("CENTER"); icon.time:SetJustifyV("TOP"); icon.time:SetWordWrap(false)
end
function B:StyleCampIcon(icon)
  if not icon or not icon.art then return end
  local style=self.db.campIconStyle=="modern" and "modern" or "classic"
  if icon.campIconStyleApplied==style then return end
  icon.campIconStyleApplied=style; icon.art:ClearAllPoints()
  if style=="modern" then icon:SetBackdrop(nil); icon.art:SetPoint("TOPLEFT",1,-1); icon.art:SetPoint("BOTTOMRIGHT",-1,1)
  else backdrop(icon); icon.art:SetPoint("TOPLEFT",4,-4); icon.art:SetPoint("BOTTOMRIGHT",-4,4) end
  self:ApplyIconStyle(icon,icon.art,style)
end
function B:UpdateCampLabel(icon,state,preview)
  if not icon then return end
  self:StyleCampIcon(icon)
  local text=self:CampLabelText(state,preview)
  self:StyleCampLabel(icon); icon.time:SetText(text); icon.time:SetShown(text~="")
end
function B:ScheduleCampLabel(state,preview)
  self:CancelTimer("camp-text")
  local icon=self.campReminderIcon
  if A.Combat() or not icon or not icon:IsShown() or preview or state.waiting or not self.db.campShowCountdown then return end
  local timed=(self.db.campTrackBenefits and A.Number(state.remaining) and state.remaining>0) or (self.db.campTrackBag and not state.bagNotNeeded and A.Number(state.bagRemaining) and state.bagRemaining>0)
  if not timed then return end
  self:StartTimer("camp-text",1,function()
    if A.Combat() or not icon:IsShown() then return end
    self:UpdateCampLabel(icon,state,false)
    self:ScheduleCampLabel(state,false)
  end)
end
function B:CreateCampReminder()
  if self.campReminderIcon or A.Combat() then return end
  local icon=CreateFrame("Button","BuffTapCampReminder",UIParent,"BackdropTemplate")
  self.campReminderIcon=icon; icon:SetSize(40,40); icon:SetClampedToScreen(true); icon:SetMovable(true); icon:RegisterForDrag("LeftButton"); icon:RegisterForClicks("LeftButtonUp","RightButtonUp")
  backdrop(icon)
  icon.art=icon:CreateTexture(nil,"ARTWORK"); icon.art:SetPoint("TOPLEFT",4,-4); icon.art:SetPoint("BOTTOMRIGHT",-4,4)
  icon.art:SetTexture(read(C_Item and C_Item.GetItemIconByID,279981) or 135805)
  icon.glow=icon:CreateTexture(nil,"OVERLAY"); icon.glow:SetAllPoints(); icon.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight"); icon.glow:SetBlendMode("ADD")
  if type(icon.glow.CreateAnimationGroup)=="function" then
    local ag=icon.glow:CreateAnimationGroup()
    if ag then
      local first=ag:CreateAnimation("Alpha"); first:SetFromAlpha(1); first:SetToAlpha(.45); first:SetDuration(.7); first:SetOrder(1)
      local second=ag:CreateAnimation("Alpha"); second:SetFromAlpha(.45); second:SetToAlpha(1); second:SetDuration(.7); second:SetOrder(2)
      ag:SetLooping("REPEAT"); icon.pulseAnimation=ag
    end
  end
  icon:SetScript("OnHide",function(s) B:StopIconEffect(s); B:CancelTimer("camp-text") end)
  icon.time=icon:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); self:StyleCampLabel(icon)
  icon:SetScript("OnDragStart",function(s) s.dragged=true; s.dragging=true; s:StartMoving() end)
  icon:SetScript("OnDragStop",function(s)
    s:StopMovingOrSizing(); s.dragging=nil
    local x,y=s:GetCenter(); local px,py=UIParent:GetCenter()
    if A.Number(x) and A.Number(y) and A.Number(px) and A.Number(py) then B.db.campX=x-px; B.db.campY=y-py end
    B:UpdateCamping()
  end)
  icon:SetScript("OnClick",function(s,button)
    if s.dragged then s.dragged=nil; return end
    if button=="RightButton" then
      if not B.campSnoozeMenu then
        local menu=CreateFrame("Frame","BuffTapCampSnooze",UIParent,"BackdropTemplate"); B.campSnoozeMenu=menu
        menu:SetSize(176,108); menu:SetFrameStrata("DIALOG"); menu:SetClampedToScreen(true); surface(menu,8)
        action(menu,"Snooze 10 minutes",10,-10,156,function() B:SnoozeCamping(600) end)
        action(menu,"Snooze 30 minutes",10,-40,156,function() B:SnoozeCamping(1800) end)
        action(menu,"Hide until reload",10,-70,156,function() B:SnoozeCamping(0) end)
        UISpecialFrames=UISpecialFrames or {}; UISpecialFrames[#UISpecialFrames+1]="BuffTapCampSnooze"; menu:Hide()
      end
      local menu=B.campSnoozeMenu; menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",s,"TOPRIGHT",6,0); menu:SetShown(not menu:IsShown())
    else B:ToggleCampTray() end
  end)
  icon:SetScript("OnEnter",function(s)
    GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:SetText(L("Camp setup"))
    GameTooltip:AddLine(L("Left-click: camp items and recipes. Right-click: snooze. Drag to move."),1,1,1,true)
    local state=B:CampingState()
    if B.db.campTrackBag then
      local bagText=(state.globalUnknown or state.bagUnknown) and "?" or state.bagActive and tostring(state.bagStacks).."/3" or L("missing")
      GameTooltip:AddLine(L("Sleeping bag:").." "..bagText,1,1,1,true)
    end
    local camp=B:CampState()
    for _,benefit in ipairs(camp.benefits or {}) do GameTooltip:AddLine(L(benefit.name),.5,1,.7) end
    GameTooltip:Show()
  end)
  icon:SetScript("OnLeave",function() GameTooltip:Hide() end)
  icon:Hide()
end
function B:CreateCampTray()
  if self.campTray or A.Combat() then return end
  local frame=CreateFrame("Frame","BuffTapCampSetup",UIParent,"BackdropTemplate,SecureHandlerStateTemplate")
  self.campTray=frame; frame:SetSize(420,360); frame:SetPoint("CENTER",UIParent,"CENTER",0,0); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetToplevel(true); frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:SetMovable(true)
  frame:SetAttribute("_onstate-campsafety",[[if newstate=="blocked" then self:Hide() end]])
  if not RegisterStateDriver or not pcall(RegisterStateDriver,frame,"campsafety","[combat] blocked; ready") then frame:Hide(); self.campTrayError="Camp secure driver unavailable"; return end
  surface(frame,10); B.OptionsTheme.Shadow(frame,24,.55)
  local header=CreateFrame("Frame",nil,frame); header:SetPoint("TOPLEFT",8,-4); header:SetPoint("TOPRIGHT",-92,-4); header:SetHeight(32); header:EnableMouse(true); header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart",function() if not A.Combat() then frame:StartMoving() end end); header:SetScript("OnDragStop",function() if not A.Combat() then frame:StopMovingOrSizing() end end)
  text(frame,"Camp setup",16,-14,"GameFontNormalLarge")
  B.OptionsTheme.Variant(action(frame,"Close",336,-9,68,function() if not A.Combat() then frame:Hide() end end),"danger")
  B.OptionsTheme.Rule(frame,16,-74,388)
  frame.status=text(frame,"",16,-43,"GameFontHighlightSmall",388)
  local statusTip=CreateFrame("Frame",nil,frame); statusTip:SetPoint("TOPLEFT",12,-38); statusTip:SetSize(394,28); statusTip:EnableMouse(true)
  statusTip:SetScript("OnEnter",function(s)
    GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:SetText(L("Camp Benefits"))
    local state=B:CampingState()
    if B.db.campTrackBag then
      local bagText=(state.globalUnknown or state.bagUnknown) and "?" or state.bagActive and tostring(state.bagStacks).."/3" or L("missing")
      GameTooltip:AddLine(L("Sleeping bag:").." "..bagText,1,1,1,true)
    end
    local camp=B:CampState()
    for _,benefit in ipairs(camp.benefits or {}) do GameTooltip:AddLine(L(benefit.name),.5,1,.7) end
    GameTooltip:AddLine(L("Only confirmed benefits are listed."),1,1,1,true); GameTooltip:Show()
  end)
  statusTip:SetScript("OnLeave",function() GameTooltip:Hide() end)
  frame.progress=CreateFrame("StatusBar",nil,frame); frame.progress:SetSize(388,4); frame.progress:SetPoint("TOPLEFT",16,-65); frame.progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  do local a=B.OptionsTheme.accent; frame.progress:SetStatusBarColor(a[1],a[2],a[3]) end
  frame.progress.track=frame.progress:CreateTexture(nil,"BACKGROUND"); frame.progress.track:SetAllPoints(); frame.progress.track:SetColorTexture(1,1,1,.08)
  action(frame,"Settings",248,-9,80,function() if not A.Combat() then frame:Hide(); B:ShowCampingOptions() end end)
  frame.resume=action(frame,"Resume reminder",272,-200,132,function() B.campSnoozeSession=nil; B.campSnoozeUntil=nil; B:UpdateCamping() end)
  text(frame,"Your camp items and recipes",16,-83,"GameFontDisableSmall",388)
  frame.empty=text(frame,"No camp items found. Open a learned profession to check its camp recipes.",16,-119,"GameFontDisableSmall",388)
  frame.rows={}
  frame.footer=text(frame,"",16,-313,"GameFontDisableSmall",246)
  frame:SetScript("OnHide",function() self.campTrayOpen=false; if not A.Combat() then self:UpdateCamping() end end)
  UISpecialFrames=UISpecialFrames or {}; UISpecialFrames[#UISpecialFrames+1]="BuffTapCampSetup"
  frame:Hide()
end
function B:RenderCampTray(state)
  local frame=self.campTray
  if not frame or not frame:IsShown() or A.Combat() then return end
  local entries=self:CampingEntries()
  frame.resume:SetShown(self.campSnoozeSession or (self.campSnoozeUntil and self.campSnoozeUntil>GetTime()) or false)
  local campText=state.campUnknown and "?" or state.active and (state.remaining and clock(state.remaining) or L("active")) or L("missing")
  local bagText=state.bagUnknown and "?" or state.bagNotNeeded and L("not needed") or state.bagActive and (tostring(state.bagStacks).."/3"..(state.bagRemaining and " "..clock(state.bagRemaining) or "")) or L("missing")
  local status=state.globalUnknown and L("Camp information unavailable") or state.waiting and (L("Collecting benefits:").." "..clock(state.waiting)) or L("Camp:").." "..campText.."  |  "..L("Sleeping bag:").." "..bagText
  if state.bagResting and not state.waiting then status=status.." ("..L("resting")..")" end
  frame.status:SetText(status); frame.progress:SetShown(state.waiting~=nil)
  if state.waiting and state.waitDuration then frame.progress:SetMinMaxValues(0,state.waitDuration); frame.progress:SetValue(math.max(0,state.waitDuration-state.waiting)) end
  frame.empty:SetShown(#entries==0)
  for _,row in ipairs(frame.rows) do row:Hide(); row:SetAttribute("type1",nil); row:SetAttribute("item",nil); row.choice=nil end
  for i,choice in ipairs(entries) do
    local row=frame.rows[i]
    if not row then
      row=CreateFrame("Button",nil,frame,"SecureActionButtonTemplate,SecureHandlerStateTemplate,BackdropTemplate")
      frame.rows[i]=row; row:SetSize(190,52); row:RegisterForClicks("LeftButtonUp"); row:SetAttribute("useOnKeyDown",false)
      row:SetAttribute("_onstate-campsafety",[[if newstate=="blocked" then self:SetAttribute("type1",nil); self:SetAttribute("item",nil); self:Hide() end]])
      local safe=RegisterStateDriver and pcall(RegisterStateDriver,row,"campsafety","[combat] blocked; ready")
      row.campSecureReady=safe==true
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(unpack(B.OptionsTheme.row))
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(30,30); row.icon:SetPoint("TOPLEFT",8,-10)
      row.title=text(row,"",46,-8,"GameFontNormalSmall",136); row.detail=text(row,"",46,-30,"GameFontHighlightSmall",136)
      row:SetScript("PreClick",function(s,button,down) if button=="LeftButton" and not down and s.campSecureReady then B:PrepareCampButton(s) end end)
      row:SetScript("PostClick",function(s,button,down)
        if A.Combat() or button~="LeftButton" or down or not s.choice or not s.campSecureReady then return end
        if s.campCraftClick then s.campCraftClick=nil; B:CraftCampEntry(s.choice.data) end
      end)
      row:SetScript("OnEnter",function(s)
        local choice=s.choice; if not choice then return end
        GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
        if choice.count>0 and GameTooltip.SetItemByID then GameTooltip:SetItemByID(choice.data.item)
        else GameTooltip:SetText(choice.data.name); GameTooltip:AddLine(L("Open the profession first, then click again to craft one. Placement may require a ground click."),1,1,1,true) end
        GameTooltip:Show()
      end)
      row:SetScript("OnLeave",function() GameTooltip:Hide() end)
      -- Secure rows: themed outline without hover scripts (a native highlight texture shows hover).
      B.OptionsTheme.Round(row,8,"surface"); B.OptionsTheme.LockBorder(row,1,1,1,.06)
      row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8"); local hl=row:GetHighlightTexture()
      if hl then local a=B.OptionsTheme.accent; hl:SetVertexColor(a[1],a[2],a[3],.10); hl:ClearAllPoints(); hl:SetPoint("TOPLEFT",2,-2); hl:SetPoint("BOTTOMRIGHT",-2,2) end
    end
    row.choice=choice; row:ClearAllPoints(); row:SetPoint("TOPLEFT",16+((i-1)%2)*198,-108-math.floor((i-1)/2)*60)
    local entry=choice.data
    local itemName=read(C_Item and C_Item.GetItemNameByID,entry.item)
    if not itemName and C_Item and type(C_Item.RequestLoadItemDataByID)=="function" then
      self.campRequestedItems=self.campRequestedItems or {}
      if not self.campRequestedItems[entry.item] then self.campRequestedItems[entry.item]=true; pcall(C_Item.RequestLoadItemDataByID,entry.item) end
    end
    row.title:SetText(itemName or entry.name)
    row.icon:SetTexture(read(C_Item and C_Item.GetItemIconByID,entry.item) or read(C_Spell and C_Spell.GetSpellTexture,entry.recipe) or 134400)
    local slot,cooldown=self:CampItemReady(entry)
    row.detail:SetText(choice.count>0 and (slot and L(entry.family=="sleeping-bag" and "Unroll" or "Place").." ("..choice.count..")" or cooldown and clock(cooldown) or L("Needs camp / unavailable")) or choice.learned and L("Craft one") or L("Open profession"))
    row.icon:SetDesaturated(choice.count>0 and not slot)
    if row.campSecureReady then self:PrepareCampButton(row) end
    row:Show()
  end
  local footerY=108+math.max(1,math.ceil(#entries/2))*60+8
  frame.footer:ClearAllPoints(); frame.footer:SetPoint("TOPLEFT",16,-footerY)
  frame.footer:SetText(L("Each click crafts or places one item. Camp actions never use your buff binding."))
  frame.resume:ClearAllPoints(); frame.resume:SetPoint("TOPLEFT",272,-footerY)
  local height=footerY+54
  frame:SetHeight(height)
  local screen=UIParent:GetHeight()
  if A.Number(screen) and screen>100 then frame:SetScale(math.min(1,(screen-40)/height)) end
end
function B:ToggleCampTray()
  if A.Combat() then self.Print("Camp setup is available out of combat."); return end
  if not self.db then self:InitDB() end
  self:CreateCampTray()
  if self.campTrayError then self.Print(self.campTrayError); return end
  local frame=self.campTray
  self.campTrayOpen=not frame:IsShown()
  if self.campTrayOpen then self.campEntries=nil; frame:Show(); frame:Raise() else frame:Hide() end
  self:UpdateCamping()
end
function B:CampingOptionsShown()
  return self.options and self.options:IsShown() and self.options.campingPage and self.options.campingPage:IsShown()
end
function B:PreviewCampReminder()
  if A.Combat() then return end
  self.campPreviewUntil=GetTime()+12
  self:UpdateCamping()
end
function B:ShowCampingOptions()
  if A.Combat() then return end
  self:Options(); self.options.selectTab(self.options.campingTab)
end
function B:UpdateCamping()
  self:CancelTimer("camp"); self:CancelTimer("camp-text")
  if not self.db then return end
  if A.Combat() then
    if self.campReminderIcon then self.campReminderIcon:Hide() end
    if self.campSnoozeMenu then self.campSnoozeMenu:Hide() end
    return
  end
  local preview=self.campPreviewUntil and self.campPreviewUntil>GetTime()
  local dragging=self.campReminderIcon and self.campReminderIcon.dragging
  if not self.db.campReminder and not self.campTrayOpen and not self:CampingOptionsShown() and not preview and not dragging then
    if self.campReminderIcon then self.campReminderIcon:Hide() end
    return
  end
  local state=self:CampingState()
  local needed=(self:CampNeedsReminder(state) and not self.campTrayOpen) or preview or dragging
  local needsCamp,needsBag=self:CampingNeeds(state)
  if not state.globalUnknown and (not self.db.campTrackBenefits or not state.campUnknown) and (not self.db.campTrackBag or not state.bagUnknown) and not needsCamp and not needsBag then self.campAlerted=false end
  if needed and not preview and not dragging and not self.campAlerted then
    self.campAlerted=true
    if self.db.campSound then self:PlayAlert("reminder",true) end
  end
  if not needed and self.campSnoozeMenu then self.campSnoozeMenu:Hide() end
  if needed then self:CreateCampReminder() end
  local icon=self.campReminderIcon
  if icon then
    if not icon.dragging then icon:ClearAllPoints(); icon:SetPoint("CENTER",UIParent,"CENTER",self.db.campX,self.db.campY) end
    local item=needsBag and not needsCamp and self.SleepingBag.item or 279981
    icon.art:SetTexture(read(C_Item and C_Item.GetItemIconByID,item) or (item==211527 and 133662 or 135805))
    icon:SetSize(self.db.campSize,self.db.campSize); icon:SetAlpha(self.db.campOpacity)
    self.campEffectSettings=self.campEffectSettings or {}
    local effect=self.campEffectSettings; effect.effectStyle=self.db.campEffectStyle; effect.effectColor=self.db.campEffectColor; effect.effectSpeed=self.db.campEffectSpeed
    self:ApplyIconEffect(icon,needed,effect)
    self:UpdateCampLabel(icon,state,preview)
    icon:SetShown(needed)
    self:ScheduleCampLabel(state,preview)
  end
  self:RenderCampTray(state)
  if self.UpdateCampingOptions and self:CampingOptionsShown() then self:UpdateCampingOptions(state) end
  local delay
  local function wakeAt(value) if A.Number(value) and value>0 and (not delay or value<delay) then delay=value end end
  if state.waiting then wakeAt(1)
  elseif self.campTrayOpen or self:CampingOptionsShown() then wakeAt(5) end
  if preview then wakeAt(self.campPreviewUntil-GetTime()) end
  if dragging then wakeAt(1) end
  if self.campSnoozeUntil and self.campSnoozeUntil>GetTime() then wakeAt(self.campSnoozeUntil-GetTime()) end
  for _,value in ipairs({self.db.campTrackBenefits and state.remaining or false,self.db.campTrackBag and not state.bagNotNeeded and state.bagRemaining or false}) do
    if A.Number(value) and value>0 then wakeAt(value>self.db.campWarning and value-self.db.campWarning+.05 or value+.05) end
  end
  if delay then self:StartTimer("camp",math.max(.1,delay),function() self:UpdateCamping() end) end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","UNIT_AURA","BAG_UPDATE_DELAYED","TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_SHOW","TRADE_SKILL_CLOSE","SKILL_LINES_CHANGED","SPELL_UPDATE_COOLDOWN","BAG_UPDATE_COOLDOWN","ITEM_DATA_LOAD_RESULT","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_MOUNT_DISPLAY_CHANGED","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,unit)
  if not B.db or (event=="UNIT_AURA" and unit~="player") then return end
  if event=="ITEM_DATA_LOAD_RESULT" and (not B.campRequestedItems or not B.campRequestedItems[unit]) then return end
  if event=="BAG_UPDATE_DELAYED" or event=="TRADE_SKILL_LIST_UPDATE" or event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_CLOSE" or event=="SKILL_LINES_CHANGED" then B.campEntries=nil end
  if not B.db.campReminder and not B.campTrayOpen and not B:CampingOptionsShown() and not (B.campPreviewUntil and B.campPreviewUntil>GetTime()) and event~="PLAYER_REGEN_DISABLED" then return end
  if event=="PLAYER_REGEN_DISABLED" then B:UpdateCamping(); return end
  B:StartTimer("camp",.1,function() B:UpdateCamping() end)
end)
B.campingEvents=events
SLASH_BUFFTAPCAMP1="/btcamp"
SlashCmdList.BUFFTAPCAMP=function() B:ToggleCampTray() end
