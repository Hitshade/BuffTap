-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ADDON,B=...
local A=B.API
local TAB={Buffs=1,Groups=2,Target=3,Consumables=4,Weapons=5,Appearance=6,Diagnostics=7,Helpers=8}
local TAB_NAMES={"Buffs","Groups","Target","Consumables","Weapons","Appearance","Diagnostics","Helpers"}
local ICON_PATH="Interface\\AddOns\\BuffTap\\Media\\BuffTapIcon"

local function label(parent,text,x,y,font,width)
  local fs=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
  fs:SetPoint("TOPLEFT",x,y)
  if width then fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true) end
  fs:SetText(text)
  if font=="GameFontDisableSmall" then fs:SetTextColor(0.73,0.73,0.70) end
  return fs
end

local function line(parent,y)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t:SetColorTexture(0.55,0.44,0.23,0.45); t:SetPoint("TOPLEFT",18,y); t:SetPoint("TOPRIGHT",-18,y); t:SetHeight(1)
end

local function button(parent,text,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  b:SetBackdropColor(0.12,0.12,0.11,1); b:SetBackdropBorderColor(0.48,0.40,0.25,1)
  b:SetNormalFontObject("GameFontHighlightSmall"); b:SetHighlightFontObject("GameFontNormalSmall")
  b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local highlight=b:GetHighlightTexture(); if highlight then highlight:SetVertexColor(0.8,0.65,0.25,0.18) end
  b:SetSize(w or 110,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text); b:SetScript("OnClick",fn)
  return b
end

local function check(parent,text,x,y,fn)
  local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
  c:SetSize(24,24); c:SetPoint("TOPLEFT",x,y); c.Text:SetText(text); c:SetScript("OnClick",fn)
  return c
end

local function addHelp(frame,title,body)
  if not frame or type(frame.SetScript)~="function" then return end
  frame:SetScript("OnEnter",function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(title,1,0.82,0.1)
    if body and body~="" then GameTooltip:AddLine(body,0.85,0.85,0.85,true) end
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
  f:SetPoint("TOPLEFT",18,-98); f:SetPoint("BOTTOMRIGHT",-18,18)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  f:SetBackdropColor(0.055,0.055,0.055,0.98); f:SetBackdropBorderColor(0.44,0.36,0.20,0.8)
  return f
end

local function formatSeconds(value)
  value=math.floor((tonumber(value) or 0)+0.5)
  if value<60 then return value.." sec" end
  local m=math.floor(value/60); local s=value%60
  if s==0 then return m.." min" end
  return m.."m "..s.."s"
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
  s.minText:SetPoint("TOPLEFT",s,"BOTTOMLEFT",0,-2); s.minText:SetText("15 sec")
  s.maxText=parent:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
  s.maxText:SetPoint("TOPRIGHT",s,"BOTTOMRIGHT",0,-2); s.maxText:SetText("3 min")
  s.valueText=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  s.valueText:SetPoint("LEFT",s,"RIGHT",18,0); s.valueText:SetText("45 sec")
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

local function buffIcon(def)
  local action=B:Resolve(def,"player")
  return action and action.icon or 134400
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
      B.db.keys={key}; f:Hide(); B.appearance=nil; B:RequestRefresh("binding",0); B:Status(false)
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

local function pairedGroupName(b)
  if not b.groupKey then return nil end
  local g=B:FindBuff(b.groupKey)
  return g and g.name or nil
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
    if family.explicitChoice then return "Choose an item",134400 end
    local item=B.PreferredConsumableItem and B:PreferredConsumableItem(family)
    if item then
      local info=B.ConsumableItemInfo and B:ConsumableItemInfo(item.id,item)
      local name=(info and info.name) or item.name or ("Item "..tostring(item.id))
      return "Auto: "..name, (info and info.texture or item.icon or 134400)
    end
    return "Auto (none in bags)",134400
  end
  for _,item in ipairs(family.items or {}) do
    if item.id==id then
      local info=B.ConsumableItemInfo and B:ConsumableItemInfo(id,item)
      return (info and info.name or item.name), (info and info.texture or item.icon or 134400)
    end
  end
  return "Auto (none in bags)",134400
end

-- Helpers share the main window and tab lifecycle. Long discovery output lives
-- on Diagnostics so every helper setting remains visible without scrolling.
function B:BuildHelperPage(parent)
  local f=panel(parent); parent.pages[TAB.Helpers]=f; self.helperWindow=f
  label(f,"Everyday conveniences",18,-16,"GameFontNormalLarge")
  label(f,"Choose the extras you want. All start off; your existing buff settings are preserved.",18,-43,"GameFontDisableSmall",680)
  f.checks={}; f.descriptions={}; f.trackers={}
  local settings={
    {"helperDismiss","Dismiss a reminder for now","Right-click a buff or item reminder to skip it until you change zones. Restore reminders below brings it back sooner."},
    {"helperBounce","Stop repeated stronger-buff errors","If your BuffTap click fails because a stronger buff is active, hide that reminder until a zone change or manual restore."},
    {"helperQuick","Choose consumables from the icon","Hover a food, flask or elixir reminder to pick another supported item in your bags. Click the main icon to use your choice."},
    {"helperCoverage","Show missing party buffs","Shows buffs your five-player party may be missing and who might provide them. Information only: no casting or chat messages."},
    {"helperTracking","Remind me to enable tracking","Choose Herbs, Minerals or Fish below. When that tracker is off, BuffTap offers a one-tap reminder to turn it on."},
    {"helperThanks","Thank players who buff me solo","Thanks an identified solo buff provider. Never in groups, instances or combat. Limited to once a minute and once per player per 10 minutes."},
    {"helperDiscovery","Find unrecognized consumables","Lists bag consumables missing from BuffTap's supported list for review. It does not add or use them. View the report in Diagnostics."},
  }
  for i,spec in ipairs(settings) do
    local x=18+((i-1)%2)*346; local y=-67-math.floor((i-1)/2)*70
    local key=spec[1]
    f.checks[key]=check(f,spec[2],x,y,function(c)
      if A.Combat() then return end
      B.db[key]=c:GetChecked()==true
      if key=="helperThanks" then B.helperThankSeen=nil; B:ObserveSoloThanks(true) end
      if key=="helperDiscovery" then B.helperDiscoverDirty=true end
      if key=="helperDismiss" or key=="helperBounce" then B:RestoreHelpers() end
      B:RequestRefresh("helper setting",0); B:Options()
    end)
    f.descriptions[key]=label(f,spec[3],x+4,y-27,"GameFontDisableSmall",326)
    addHelp(f.checks[key],spec[2],spec[3])
  end
  button(f,"View discovery report",368,-287,204,function() B:ShowDiscoveryReport() end)
  line(f,-342)
  f.trackerHeading=label(f,"Preferred gathering tracker",18,-354,"GameFontNormal")
  f.emptyTracker=label(f,"No learned gathering tracker is available on this character.",18,-380,"GameFontDisableSmall",670)
  f.readiness=CreateFrame("Frame",nil,f); f.readiness:SetAllPoints(f)
  local r=f.readiness
  label(r,"Class readiness",18,-406,"GameFontNormal")
  f.petCheck=check(r,"Keep my pet ready",18,-426,function(c)
    if A.Combat() then return end
    B.db.helperPet=c:GetChecked()==true; B:SyncReadiness(); B:RequestRefresh("pet helper",0); B:Options()
  end)
  f.petDescription=label(r,"",22,-452,"GameFontDisableSmall",326)
  f.stoneCheck=check(r,"Prepare a personal Healthstone",364,-426,function(c)
    if A.Combat() then return end
    B.db.helperHealthstone=c:GetChecked()==true; B:SyncReadiness(); B:RequestRefresh("Healthstone helper",0); B:Options()
  end)
  f.stoneDescription=label(r,"Offers Create Healthstone when none is in your bags. Requires a Soul Shard and free space. Never uses the stone.",368,-452,"GameFontDisableSmall",326)
  f.demonChoice=button(r,"Choose preferred demon",18,-499,326,function()
    if A.Combat() then return end
    f.demonMenu:SetShown(not f.demonMenu:IsShown())
  end)
  f.demonChoice.icon=f.demonChoice:CreateTexture(nil,"ARTWORK")
  f.demonChoice.icon:SetSize(20,20); f.demonChoice.icon:SetPoint("LEFT",3,0)
  f.demonMenu=CreateFrame("Frame",nil,r,"BackdropTemplate")
  local menu=f.demonMenu; menu:SetSize(326,158); menu:SetPoint("BOTTOMLEFT",f.demonChoice,"TOPLEFT",0,2)
  menu:SetFrameStrata("DIALOG"); menu:EnableMouse(true)
  menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
  menu:SetBackdropColor(.04,.04,.04,1); menu.rows={}; menu:Hide()
  f:SetScript("OnHide",function() menu:Hide() end)
  button(f,"Restore reminders",18,-537,154,function() B:RestoreHelpers(); B:Options() end)
  label(f,"Brings back skipped reminders, including stronger-effect errors.",184,-543,"GameFontDisableSmall",500)
end

function B:UpdateHelperOptions()
  local f=self.helperWindow; if not f then return end
  local class=self:ReadinessClass(); local warlock=class=="WARLOCK"
  f.readiness:SetShown(warlock or class=="HUNTER"); f.demonMenu:Hide()
  f.petCheck:SetChecked(self.db.helperPet==true); f.stoneCheck:SetChecked(self.db.helperHealthstone==true)
  f.stoneCheck:SetShown(warlock); f.stoneDescription:SetShown(warlock); f.demonChoice:SetShown(warlock)
  f.petDescription:SetText(warlock and "Offers your chosen summon if no living pet is present. Respects Demonic Sacrifice; never replaces a living pet."
    or "Offers Revive for a visible dead pet. If your assigned pet is absent, reminds you to call or revive it manually.")
  addHelp(f.petCheck,"Pet readiness","Offers recovery only out of combat, while stationary and unmounted. Any living pet satisfies this reminder.")
  addHelp(f.stoneCheck,"Personal Healthstone","Creates one personal stone with a click. Any supported carried Healthstone satisfies the reminder, regardless of cooldown. Bank stock does not count.")
  local demons=self:ReadinessDemons(); local chosen
  for _,row in ipairs(f.demonMenu.rows) do row:Hide() end
  for i,entry in ipairs(demons) do
    local row=f.demonMenu.rows[i]
    if not row then
      row=button(f.demonMenu,"",6,-7-(i-1)*29,314,function(control)
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
  for key,c in pairs(f.checks) do c:SetChecked(self:HelperEnabled(key)) end
  for _,t in ipairs(f.trackers) do t:Hide() end
  local trackers=self:GatheringTrackers(); f.emptyTracker:SetShown(#trackers==0)
  local selected=false
  for _,entry in ipairs(trackers) do if entry.id==self.db.helperTracker then selected=true end end
  f.trackerHeading:SetText(selected and "Preferred gathering tracker" or "Preferred gathering tracker - choose one below")
  for i,entry in ipairs(trackers) do
    local t=f.trackers[i]
    if not t then
      t=button(f,"",18+(i-1)*226,-376,218,function(control)
        if A.Combat() then return end
        B.db.helperTracker=control.trackerID; B:RequestRefresh("tracking preference",0); B:Options()
      end)
      t.icon=t:CreateTexture(nil,"ARTWORK"); t.icon:SetSize(20,20); t.icon:SetPoint("LEFT",3,0)
      f.trackers[i]=t
    end
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
    f:SetSize(300,244); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12}); f:SetBackdropColor(.06,.06,.06,.98)
    label(f,"Choose, then use the main icon",12,-12,"GameFontNormalSmall")
    f.rows={}
    for i=1,6 do
      local row=button(f,"",12,-34-(i-1)*28,274,function(s)
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
    button(f,"Close",192,-210,94,function() f:Hide() end)
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
    button(f,"Close",550,-14,78,function() f:Hide() end)
    label(f,"Search",20,-59,"GameFontHighlightSmall")
    f.search=editbox(f,76,-54,300,false)
    f.bags=check(f,"In bags only",410,-54,function() f.offset=0; B:UpdateConsumablePicker() end)
    f.auto=button(f,"",20,-90,606,function()
      if A.Combat() then return end
      B:SetConsumableChoice(f.family,nil); B:InvalidateConsumables(); B:RequestRefresh("auto selected",0); B:Options(); B:UpdateConsumablePicker()
    end)
    label(f,"Item",66,-127,"GameFontNormalSmall"); label(f,"In bags",518,-127,"GameFontNormalSmall")
    f.rows={}
    for i=1,8 do
      local row=button(f,"",20,-147-(i-1)*34,580,function(btn)
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
    f.empty=label(f,"No matching items. Clear search or turn off In bags only.",40,-245,"GameFontHighlight",520)
    f.summary=label(f,"",20,-428,"GameFontNormal",590)
    f.hint=label(f,"",20,-452,"GameFontHighlightSmall",600)
    f.count=label(f,"",20,-515,"GameFontHighlightSmall",400)
    button(f,"Done",540,-508,86,function() f:Hide() end)
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
    if (not f.bags:GetChecked() or count>0) and (query=="" or item.name:lower():find(query,1,true) or tostring(item.id):find(query,1,true)) then
      list[#list+1]={id=item.id,name=item.name,count=count,note=item.note,icon=item.icon}
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
  f.title:SetText("Choose "..family.name:lower())
  f.auto:SetShown(not family.explicitChoice)
  f.auto:SetText((not selected and "(o) " or "( ) ").."Auto - first usable supported item")
  for i,row in ipairs(f.rows) do
    local item=list[f.offset+i]
    if item then
      row.itemID=item.id; row.mark:SetText(selected==item.id and "(o)" or "( )")
      row.name:SetText(item.name); row.stock:SetText(item.count>0 and ("|cff88dd88"..item.count.."|r") or "|cffffc466Out of stock|r")
      local info=self.ConsumableItemInfo and self:ConsumableItemInfo(item.id,item)
      row.icon:SetTexture((info and info.texture) or item.icon or 134400)
      row:SetBackdropColor(selected==item.id and 0.24 or 0.09,selected==item.id and 0.20 or 0.09,0.07,1)
      addHelp(row,item.name,item.note or "Supported item; availability is checked again before use."); row:Show()
    else row.itemID=nil; row:Hide() end
  end
  local choice=consumableChoiceLabel(family)
  f.summary:SetText("Selected: "..choice..(selected and ("  -  "..self:ConsumableCount(selected).." in bags") or ""))
  local note=family.protectPresent and "One elixir choice. Existing elixir buffs are preserved until expiry." or "One choice at a time. Your selection stays saved when out of stock."
  for _,item in ipairs(family.items or {}) do if item.id==selected and item.note then note=note.."\n"..item.note; break end end
  f.hint:SetText(note)
  f.count:SetText(#list.." matching items"..(f.maxOffset>0 and " - scroll for more" or ""))
end

function B:Options()
  if A.Combat() then return end
  local f=self.options
  if not f then
    f=CreateFrame("Frame","BuffTapOptions",UIParent,"BackdropTemplate"); self.options=f
    f:SetSize(760,680); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=14,insets={left=3,right=3,top=3,bottom=3}})
    f:SetBackdropColor(0.035,0.035,0.035,0.98); f:SetBackdropBorderColor(0.60,0.48,0.25,1)
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapOptions") end

    local logo=f:CreateTexture(nil,"OVERLAY"); logo:SetSize(44,44); logo:SetPoint("TOPRIGHT",-20,-14); logo:SetTexture(ICON_PATH)
    label(f,"BuffTap",24,-16,"GameFontNormalLarge")
    label(f,"One-tap buffing for WoW Forever",145,-18,"GameFontHighlightSmall",310)
    f.versionText=label(f,"v"..B.version,465,-20,"GameFontDisableSmall")
    button(f,"Close",600,-40,90,function() f:Hide() end)
    button(f,"Debug",502,-40,90,function() B:Status(true) end)
    f.enable=check(f,"Enable BuffTap",24,-40,function(c) setAndRefresh("enabled",c:GetChecked()==true) end)
    line(f,-68)

    f.tabs={}; f.pages={}
    local names=TAB_NAMES
    local function setTab(index)
      f.activeTab=index
      for i,p in ipairs(f.pages) do p:SetShown(i==index) end
      for i,t in ipairs(f.tabs) do
        if i==index then t:LockHighlight() else t:UnlockHighlight() end
      end
    end
    f.selectTab=setTab
    for i,name in ipairs(names) do
      local idx=i
      local t=button(f,name,24+(i-1)*86,-72,80,function() setTab(idx) end); f.tabs[i]=t
    end

    -- BUFFS PAGE
    local buffs=panel(f); f.pages[TAB.Buffs]=buffs
    label(buffs,"Buffs",18,-16,"GameFontNormalLarge")
    label(buffs,"Lower priority numbers are checked first. Timing inherits the default until customized.",18,-42,"GameFontDisableSmall",650)
    label(buffs,"Rebuff",334,-66,"GameFontDisableSmall",70)
    label(buffs,"Priority",590,-66,"GameFontDisableSmall",70)
    local scroll=CreateFrame("ScrollFrame",nil,buffs,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",14,-88); scroll:SetPoint("BOTTOMRIGHT",-34,126)
    local child=CreateFrame("Frame",nil,scroll); child:SetSize(660,1); scroll:SetScrollChild(child); f.buffChild=child; f.buffRows={}

    f.emptyBuffs=label(child,"No supported aura buffs for this class.",8,-12,"GameFontDisableSmall",610)
    local weapons=panel(f); f.pages[TAB.Weapons]=weapons
    f.weaponTitle=label(weapons,"Weapon buffs",18,-16,"GameFontNormalLarge")
    f.weaponHint=label(weapons,"Maintain a preferred buff on each weapon using your normal BuffTap binding.",18,-42,"GameFontDisableSmall",660)
    f.weaponEnable=check(weapons,"Enable weapon reminders",18,-72,function(c) setAndRefresh("weaponReminder",c:GetChecked()==true); B:Options() end)
    f.weaponApply=check(weapons,"Apply through scroll / click",330,-72,function(c) setAndRefresh("weaponApply",c:GetChecked()==true); B:Options() end)
    addHelp(f.weaponApply,"Weapon application","Choose your preferences below. Existing users start with manual alerts. Scroll application only works out of combat. Rogue poisons use carried supported items; Shamans use learned imbues.")
    f.weaponMain=check(weapons,"Main hand",18,-116,function(c) setAndRefresh("weaponMainHand",c:GetChecked()==true); B:Options() end)
    f.weaponOff=check(weapons,"Off hand",18,-166,function(c) setAndRefresh("weaponOffHand",c:GetChecked()==true); B:Options() end)
    f.weaponPickers={}
    for i,hand in ipairs({"main","off"}) do
      local key=hand
      local pick=button(weapons,"Choose preferred buff",180,-116-(i-1)*50,470,function(control)
        if A.Combat() then return end
        for _,other in pairs(f.weaponPickers) do if other~=control then other.menu:Hide() end end
        local menu=control.menu; menu:SetShown(not menu:IsShown())
      end)
      pick.icon=pick:CreateTexture(nil,"ARTWORK"); pick.icon:SetSize(22,22); pick.icon:SetPoint("LEFT",4,0)
      local menu=CreateFrame("Frame",nil,weapons,"BackdropTemplate"); pick.menu=menu
      menu:SetSize(470,190); menu:SetPoint("TOPLEFT",pick,"BOTTOMLEFT",0,-2); menu:SetFrameStrata("TOOLTIP")
      menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); menu:SetBackdropColor(0.06,0.06,0.06,1); menu:Hide(); menu.rows={}
      f.weaponPickers[key]=pick
    end
    f.weaponTimingLabel=label(weapons,"Refresh before expiry",18,-230,"GameFontNormal")
    f.weaponTiming=compactSlider(weapons,0,300,15,270,formatSeconds,function(v) setAndRefresh("weaponSeconds",v) end)
    f.weaponTiming:SetPoint("TOPLEFT",220,-230)
    f.weaponReplace=check(weapons,"Replace a different buff with my preference",18,-274,function(c) setAndRefresh("weaponReplace",c:GetChecked()==true) end)
    addHelp(f.weaponReplace,"Replacing an existing weapon buff","Off by default. Enable only if you want your preferred buff to replace another recognized buff. Unknown coating data always uses a manual fallback.")
    f.weaponPoisonHint=label(weapons,"Poison ranks: highest carried usable rank. Preferences stay saved when out of stock.",18,-320,"GameFontDisableSmall",660)
    f.weaponHandsHint=label(weapons,"Shamans maintain their main-hand imbue. Rogues choose each hand separately. Shields, held off-hand items, and fishing poles are excluded.",18,-352,"GameFontDisableSmall",660)
    f.weaponStatus=label(weapons,"",18,-416,"GameFontHighlightSmall",660)
    f.weaponUnavailable=label(weapons,"Weapon buffs are available to Rogues and Shamans.",18,-72,"GameFontDisableSmall",660)
    local timingLabel=buffs:CreateFontString(nil,"OVERLAY","GameFontNormal")
    timingLabel:SetPoint("BOTTOMLEFT",18,88); timingLabel:SetText("Default rebuff threshold")
    local timingHint=buffs:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    timingHint:SetPoint("LEFT",timingLabel,"RIGHT",12,0); timingHint:SetText("Used until a buff is customized.")
    f.rebuffSlider=rebuffSlider(buffs); f.rebuffSlider:SetPoint("BOTTOMLEFT",18,54)
    local resetBuffs=button(buffs,"Reset buffs",0,0,100,function()
      if not A.Combat() then B.db.buffs={}; B.db.priorities={}; B.db.buffSeconds={}; B:Refresh(); B:Options() end
    end)
    resetBuffs:ClearAllPoints(); resetBuffs:SetPoint("BOTTOMRIGHT",-18,14)

    -- GROUPS PAGE
    local groups=panel(f); f.pages[TAB.Groups]=groups
    label(groups,"Party & raid buffing",18,-16,"GameFontNormalLarge")
    label(groups,"Select groups and classes for each buff. Party members use G1.",18,-38,"GameFontDisableSmall",680)
    f.groupEnable=check(groups,"Enable party / raid",18,-58,function(s) setAndRefresh("group",s:GetChecked()==true); B:Options() end)
    f.smartGroup=check(groups,"Use group spells automatically",290,-58,function(s) setAndRefresh("smartGroup",s:GetChecked()==true); B:Options() end)
    local shared=CreateFrame("Frame",nil,groups); shared:SetPoint("TOPLEFT",0,-440); shared:SetSize(704,90); shared:Hide()
    f.sharedGroups=shared
    button(groups,"Default thresholds and shared settings",18,-408,686,function()
      shared:SetShown(not shared:IsShown())
    end)
    label(shared,"All buffs",18,-10,"GameFontNormal")
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
    label(shared,"Group threshold",18,-48,"GameFontHighlight",110)
    f.groupNeedSlider=compactSlider(shared,2,5,1,150,function(v) return tostring(v).."+" end,function(_,v)
      B.db.groupNeed=v; B:NormalizeGroupNeeds(); B:InitDB(); B:RequestRefresh("group threshold default",0.08)
    end)
    f.groupNeedSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
    f.groupNeedSlider:SetPoint("TOPLEFT",128,-45)
    label(shared,"Greater Blessings",362,-48,"GameFontHighlight",132)
    f.blessingNeedSlider=compactSlider(shared,2,5,1,120,function(v) return tostring(v).."+" end,function(_,v)
      B.db.blessingNeed=v; B:NormalizeGroupNeeds(); B:InitDB(); B:RequestRefresh("blessing threshold default",0.08)
    end)
    f.blessingNeedSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
    f.blessingNeedSlider:SetPoint("TOPLEFT",492,-45)
    label(groups,"Buff",18,-102,"GameFontNormal")
    local listScroll=CreateFrame("ScrollFrame",nil,groups,"UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT",18,-126); listScroll:SetSize(178,260)
    f.assignList=CreateFrame("Frame",nil,listScroll); f.assignList:SetSize(174,1); listScroll:SetScrollChild(f.assignList)
    f.assignButtons={}
    local assignChild=CreateFrame("Frame",nil,groups); assignChild:SetPoint("TOPLEFT",230,-100); assignChild:SetSize(474,296)
    f.assignChild=assignChild; f.assignRows={}
    f.assignEmpty=label(assignChild,"No party / raid buffs available for this class.",8,-12,"GameFontHighlight",440)

    -- FRIENDLY TARGET PAGE
    local target=panel(f); f.pages[TAB.Target]=target
    label(target,"Friendly target buffing",18,-16,"GameFontNormalLarge")
    label(target,"Click a friendly player and BuffTap can offer selected single-target buffs before returning to your normal queue.",18,-42,"GameFontDisableSmall",680)
    f.friendlyTarget=check(target,"Enable friendly target buffing",18,-76,function(s) setAndRefresh("friendlyTarget",s:GetChecked()==true); B:Options() end)
    addHelp(f.friendlyTarget,"Friendly target buffing","Only the player you explicitly target is inspected. No nearby-player or nameplate scanning is performed. Target mode uses single-target spell versions only and ignores party/raid group and class filters.")
    label(target,"Default target refresh",18,-116,"GameFontNormal")
    label(target,"Useful for passersby: a long buff can be refreshed much earlier here without changing party/raid timing.",18,-138,"GameFontDisableSmall",680)
    f.targetDefaultSlider=compactSlider(target,30,1800,30,300,formatSeconds,function(_,value)
      B.db.targetSeconds=value; B:InvalidateAura("target"); B:RequestRefresh("target refresh default",0.08)
    end)
    f.targetDefaultSlider:SetScript("OnMouseUp",function() if not A.Combat() then B:Options() end end)
    f.targetDefaultSlider:SetPoint("TOPLEFT",18,-164)
    addHelp(f.targetDefaultSlider,"Target refresh timing","Target mode may refresh much earlier than normal party/raid timing. BuffTap still caps the effective threshold at half of the aura's full duration, so a one-hour buff can be refreshed at 30 minutes but not earlier.")
    line(target,-204)
    label(target,"Target buffs",18,-222,"GameFontNormal")
    label(target,"Apply",18,-248,"GameFontDisableSmall",48)
    label(target,"Buff",82,-248,"GameFontDisableSmall",160)
    label(target,"Custom timing",276,-248,"GameFontDisableSmall",100)
    label(target,"Refresh when remaining",402,-248,"GameFontDisableSmall",180)
    local targetScroll=CreateFrame("ScrollFrame",nil,target,"UIPanelScrollFrameTemplate")
    targetScroll:SetPoint("TOPLEFT",14,-270); targetScroll:SetPoint("BOTTOMRIGHT",-34,54)
    local targetChild=CreateFrame("Frame",nil,targetScroll); targetChild:SetSize(660,1); targetScroll:SetScrollChild(targetChild)
    f.targetChild=targetChild; f.targetRows={}
    local resetTarget=button(target,"Reset target settings",0,0,132,function()
      if not A.Combat() then
        B.db.friendlyTarget=false; B.db.targetSeconds=300; B.db.targetBuffs={}; B.db.targetBuffSeconds={}
        B:InitDB(); B:InvalidateAura("target"); B:RequestRefresh("reset target settings",0); B:Options()
      end
    end)
    resetTarget:ClearAllPoints(); resetTarget:SetPoint("BOTTOMRIGHT",-18,14)

    -- CONSUMABLES PAGE
    local consume=panel(f); f.pages[TAB.Consumables]=consume
    label(consume,"Consumables",18,-16,"GameFontNormalLarge")
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
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.085,0.085,0.075,0.95)
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
      row.prev=button(row,"Choose",584,-8,86,function(btn) B:ChooseConsumable(btn:GetParent().family,btn) end)
      row.inventory=label(row,"",450,-11,"GameFontHighlightSmall",120)
      label(row,family.protectPresent and "Preserve active elixirs; remind after expiry" or "Rebuff at",42,-52,"GameFontDisableSmall",family.protectPresent and 390 or 62)
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

    -- APPEARANCE PAGE
    local app=panel(f); f.pages[TAB.Appearance]=app
    label(app,"Binding",18,-16,"GameFontNormalLarge")
    f.bindingText=label(app,"Current: —",18,-46,"GameFontHighlight",280)
    button(app,"Set binding",310,-42,116,function() B:CaptureBinding() end)
    button(app,"Clear",436,-42,82,function() if not A.Combat() then B.db.keys={}; B.appearance=nil; B:RequestRefresh("clear binding",0); B:Options() end end)
    label(app,"The override binding is active only while BuffTap has a valid buff action ready.",18,-73,"GameFontDisableSmall",650)
    line(app,-105)
    label(app,"Buff icon",18,-126,"GameFontNormalLarge")
    label(app,"Size",18,-160,"GameFontHighlight"); f.sizeEdit=editbox(app,62,-156,58,true); label(app,"px",126,-160,"GameFontDisableSmall")
    label(app,"Opacity",176,-160,"GameFontHighlight"); f.opacityEdit=editbox(app,238,-156,58,false)
    label(app,"X",326,-160,"GameFontHighlight"); f.xEdit=editbox(app,344,-156,64,false)
    label(app,"Y",430,-160,"GameFontHighlight"); f.yEdit=editbox(app,448,-156,64,false)
    button(app,"Apply",540,-156,72,function()
      if A.Combat() then return end
      local size,opacity,x,y=tonumber(f.sizeEdit:GetText()),tonumber(f.opacityEdit:GetText()),tonumber(f.xEdit:GetText()),tonumber(f.yEdit:GetText())
      if size then B.db.size=size end; if opacity then B.db.opacity=opacity end; if x then B.db.x=x end; if y then B.db.y=y end
      B:InitDB(); B.appearance=nil; B:RequestRefresh("appearance",0); B:Options()
    end)
    f.soundCheck=check(app,"Sound",18,-204,function(s) setAndRefresh("sound",s:GetChecked()==true) end)
    f.glowCheck=check(app,"Glow",122,-204,function(s) setAndRefresh("glow",s:GetChecked()==true) end)
    f.pulseCheck=check(app,"Pulse",220,-204,function(s) setAndRefresh("pulse",s:GetChecked()==true) end)
    f.buffNameCheck=check(app,"Show buff name",18,-238,function(s) setAndRefresh("showBuffName",s:GetChecked()==true) end)
    f.targetNameCheck=check(app,"Show buff recipient",178,-238,function(s) setAndRefresh("showTargetName",s:GetChecked()==true) end)
    addHelp(f.targetNameCheck,"Buff recipient","Shows the name of whoever BuffTap is about to buff, including you when the current action is a self buff.")
    f.timerCheck=check(app,"Remaining time",18,-272,function(s) setAndRefresh("showTimer",s:GetChecked()==true) end)
    f.groupBadgeCheck=check(app,"Group count",178,-272,function(s) setAndRefresh("showGroupBadge",s:GetChecked()==true) end)
    addHelp(f.timerCheck,"Remaining time","Shows a small countdown only when the selected buff is already inside its rebuff window.")
    addHelp(f.groupBadgeCheck,"Group count","Shows how many players need the buff when BuffTap selects a group-version spell.")
    button(app,"Move icon",18,-318,108,function() B:MoveAnchor() end)
    button(app,"Center",136,-318,90,function() if not A.Combat() then B.db.x=0; B.db.y=-180; B.appearance=nil; B:RequestRefresh("center icon",0); B:Options() end end)
    button(app,"Reset look",236,-318,100,function()
      if not A.Combat() then B.db.size=64; B.db.opacity=1; B.db.x=0; B.db.y=-180; B.db.glow=true; B.db.pulse=false; B.db.showBuffName=false; B.db.showTargetName=true; B.db.showTimer=false; B.db.showGroupBadge=true; B.appearance=nil; B:RequestRefresh("reset look",0); B:Options() end
    end)
    label(app,"Move icon opens a safe preview that cannot cast spells.",18,-354,"GameFontDisableSmall",500)
    line(app,-388)
    button(app,"Reset all settings",18,-414,132,function()
      if not A.Combat() then BuffTapDB=nil; B:InitDB(); B.helperDismissed={}; B.helperThankSeen=nil; B.bookDirty=true; B.resolveCache=nil; B.rankChoiceCache=nil; B.coverCache=nil; B:InvalidateRoster(); B:InvalidateAura(); B.appearance=nil; B:RequestRefresh("reset settings",0); B:Options() end
    end)

    -- DIAGNOSTICS PAGE
    local diag=panel(f); f.pages[TAB.Diagnostics]=diag
    label(diag,"Diagnostics & performance",18,-16,"GameFontNormalLarge")
    label(diag,"Core scanning is event-driven. Profiling is optional and lasts only for this game session.",18,-42,"GameFontDisableSmall",680)
    f.profileCheck=check(diag,"Measure refresh cost",18,-76,function(c)
      B.profileEnabled=c:GetChecked()==true; B.profileStats=nil
      if B.profileEnabled then B:ResetStats() else B.stats=nil end
      B:Options()
    end)
    addHelp(f.profileCheck,"Refresh profiler","Disabled by default. When enabled, BuffTap measures only its own refresh duration with debugprofilestop().")
    f.diagText=label(diag,"",18,-116,"GameFontHighlightSmall",680)
    button(diag,"Refresh diagnostics",18,-390,142,function()
      if not A.Combat() then f.discoveryScroll:Hide(); f.diagText:Show(); B:Refresh(true); B:Options() end
    end)
    button(diag,"Print to chat",170,-390,108,function() B:Status(true); B:Options() end)
    button(diag,"Reset metrics",288,-390,110,function()
      B.profileStats=nil; if B.profileEnabled then B:ResetStats() else B.stats=nil end; B:Options()
    end)

    local scroll=CreateFrame("ScrollFrame",nil,diag,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",18,-116); scroll:SetSize(654,258); scroll:Hide(); f.discoveryScroll=scroll
    local report=CreateFrame("EditBox",nil,scroll); report:SetMultiLine(true); report:SetAutoFocus(false)
    report:SetFontObject("GameFontHighlightSmall"); report:SetWidth(638); report:SetHeight(258)
    report:SetScript("OnEscapePressed",function(control) control:ClearFocus() end)
    scroll:SetScrollChild(report); f.discoveryReport=report
    button(diag,"Unknown items",410,-390,124,function() B:ShowDiscoveryReport() end)
    button(diag,"Rescan bags",546,-390,130,function()
      if A.Combat() then return end
      B:DiscoverConsumables(); B:ShowDiscoveryReport()
    end)
    label(diag,"Unknown items is a copyable report for improving item support, not a list of items BuffTap will use.",18,-430,"GameFontDisableSmall",672)
    self:BuildHelperPage(f)

    local function acceptEdit(e,key)
      e:SetScript("OnEnterPressed",function(s) local v=tonumber(s:GetText()); if v and not A.Combat() then setAndRefresh(key,v) end; s:ClearFocus(); B:Options() end)
      e:SetScript("OnEscapePressed",function(s) s:ClearFocus(); B:Options() end)
    end
    acceptEdit(f.sizeEdit,"size"); acceptEdit(f.opacityEdit,"opacity"); acceptEdit(f.xEdit,"x"); acceptEdit(f.yEdit,"y")

    f:SetScript("OnHide",function() if B.itemPicker then B.itemPicker:Hide() end end)
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
  if A.Number(width) and A.Number(height) then f:SetScale(math.min(1,(width-32)/760,(height-32)/680)) end
  self:UpdateHelperOptions()
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
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.085,0.085,0.075,0.95)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(32,32); row.icon:SetPoint("TOPLEFT",8,-4)
      row.name=label(row,"",48,-5,"GameFontNormalLarge",402)
      row.detail=label(row,"",48,-29,"GameFontDisableSmall",402)
      label(row,"Raid groups",8,-60,"GameFontNormal")
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
      row.need:SetPoint("TOPLEFT",165,-265)
      row.needLabel=label(row,"Group spell at",8,-265,"GameFontHighlightSmall",140)
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
      row.resetClasses=button(row,"Reset",374,-110,80,function()
        if row.def and not A.Combat() then B.db.buffClasses[B:RootKey(row.def)]=nil; B:RequestRefresh("reset classes",0); B:Options() end
      end)
      row.allClasses=button(row,"All classes",280,-110,86,function()
        if not row.def or A.Combat() then return end
        local map={}; for _,class in ipairs(B.RecipientClasses) do map[class]=true end
        B.db.buffClasses[B:RootKey(row.def)]=map; B:RequestRefresh("all classes",0); B:Options()
      end)
      f.assignRows[rowIndex]=row
    end
    row.def=b; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,0); row:SetShown(f.selectedAssignment==b.key); row.name:SetText(b.name); row.icon:SetTexture(buffIcon(b))
    local select=f.assignButtons[rowIndex]
    if not select then
      select=button(f.assignList,"",0,-(rowIndex-1)*42,174,function(btn) f.selectedAssignment=btn.def.key; B:Options() end)
      select:SetHeight(38)
      select.icon=select:CreateTexture(nil,"ARTWORK"); select.icon:SetSize(24,24); select.icon:SetPoint("TOPLEFT",6,-7)
      select.title=label(select,"",36,-6,"GameFontHighlightSmall",132)
      f.assignButtons[rowIndex]=select
    end
    select.def=b; select.title:SetText(b.name); select.icon:SetTexture(buffIcon(b)); select:Show()
    if f.selectedAssignment==b.key then select:LockHighlight() else select:UnlockHighlight() end
    local groupDef=b.groupKey and self:FindBuff(b.groupKey)
    row.detail:SetText(groupDef and ("Group: "..groupDef.name) or "Single-target only")
    for i=1,8 do row.checks[i]:SetChecked(self:GroupSelected(b,i)) end
    for class,c in pairs(row.classes) do c:SetChecked(self:GroupClassAllowed(b,class)) end
    if groupDef then
      row.needLabel:Show(); row.need:Show(); row.need.valueText:Show(); row.need.silent=true; row.need:SetValue(self:GroupNeed(groupDef)); row.need.valueText:SetText(tostring(self:GroupNeed(groupDef)).."+"); row.need.silent=false
      if self.db.group and self.db.smartGroup then row.need:Enable(); row.need:SetAlpha(1) else row.need:Disable(); row.need:SetAlpha(0.45) end
    else row.need:Hide(); row.need.valueText:Hide(); row.needLabel:Hide() end
  end
  f.assignList:SetHeight(math.max(1,#assignmentBuffs*42))

  for _,r in ipairs(f.targetRows) do r:Hide() end
  local targetBuffs=targetAssignableBuffs()
  for rowIndex,b in ipairs(targetBuffs) do
    local row=f.targetRows[rowIndex]
    if not row then
      row=CreateFrame("Frame",nil,f.targetChild,"BackdropTemplate"); row:SetSize(650,48)
      row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(0.085,0.085,0.075,0.95)
      row.enable=check(row,"",8,-12,function(s)
        local def=s:GetParent().def
        if def and not A.Combat() then B.db.targetBuffs[def.key]=s:GetChecked()==true; B:InvalidateAura("target"); B:RequestRefresh("target buff toggle",0); B:Options() end
      end)
      row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(32,32); row.icon:SetPoint("TOPLEFT",42,-8)
      row.name=label(row,"",82,-6,"GameFontHighlightSmall",180)
      row.detail=label(row,"",82,-24,"GameFontDisableSmall",180)
      row.custom=check(row,"Custom",270,-12,function(s)
        local def=s:GetParent().def
        if def and not A.Combat() then
          if s:GetChecked()==true then B.db.targetBuffSeconds[def.key]=B.db.targetSeconds else B.db.targetBuffSeconds[def.key]=nil end
          B:InvalidateAura("target"); B:RequestRefresh("target custom timing",0); B:Options()
        end
      end)
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
    row.enable:SetChecked(self:TargetBuffEnabled(b)); row.icon:SetTexture(buffIcon(b)); row.name:SetText(b.name)
    row.detail:SetText(self:Enabled(b) and "Single-target spell" or "Disabled on Buffs tab")
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
        row.prev:ClearAllPoints(); row.prev:SetPoint("TOPLEFT",584,-8); row.prev:SetSize(86,26); row.prev:SetText("Choose")
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

  f.bindingText:SetText("Current: "..(#self.db.keys>0 and table.concat(self.db.keys,", ") or "none"))
  f.sizeEdit:SetText(tostring(self.db.size)); f.opacityEdit:SetText(string.format("%.2f",self.db.opacity)); f.xEdit:SetText(tostring(math.floor(self.db.x+0.5))); f.yEdit:SetText(tostring(math.floor(self.db.y+0.5)))
  f.soundCheck:SetChecked(self.db.sound); f.glowCheck:SetChecked(self.db.glow); f.pulseCheck:SetChecked(self.db.pulse)
  f.buffNameCheck:SetChecked(self.db.showBuffName); f.targetNameCheck:SetChecked(self.db.showTargetName)
  f.timerCheck:SetChecked(self.db.showTimer); f.groupBadgeCheck:SetChecked(self.db.showGroupBadge)
  f.profileCheck:SetChecked(self.profileEnabled==true)
  f.rebuffSlider.silent=true; f.rebuffSlider:SetValue(self.db.seconds); f.rebuffSlider.valueText:SetText(formatSeconds(self.db.seconds)); f.rebuffSlider.silent=false

  local weaponClass=self.WeaponReminderClass and self:WeaponReminderClass()
  f.weaponUnavailable:SetShown(not weaponClass)
  f.weaponPoisonHint:SetShown(weaponClass=="ROGUE")
  for _,control in ipairs({f.weaponHint,f.weaponEnable,f.weaponApply,f.weaponMain,f.weaponOff,f.weaponTimingLabel,f.weaponTiming,f.weaponReplace,f.weaponStatus,f.weaponHandsHint}) do control:SetShown(weaponClass~=nil) end
  for _,pick in pairs(f.weaponPickers) do pick:SetShown(weaponClass~=nil); pick.menu:Hide() end
  if weaponClass then
    f.weaponEnable:SetChecked(self.db.weaponReminder==true); f.weaponApply:SetChecked(self.db.weaponApply==true)
    f.weaponMain:SetChecked(self.db.weaponMainHand~=false); f.weaponOff:SetChecked(self.db.weaponOffHand~=false)
    f.weaponReplace:SetChecked(self.db.weaponReplace==true)
    f.weaponOff:SetShown(weaponClass=="ROGUE")
    f.weaponTiming.silent=true; f.weaponTiming:SetValue(self.db.weaponSeconds); f.weaponTiming.valueText:SetText(formatSeconds(self.db.weaponSeconds)); f.weaponTiming.silent=false
    f.weaponStatus:SetText(self:WeaponReminderSummary())
    for hand,pick in pairs(f.weaponPickers) do
      pick:SetShown(hand=="main" or weaponClass=="ROGUE")
      local handKey=hand; local selected=self:WeaponPreference(hand)
      pick:SetText(selected and selected.name or "Choose preferred buff")
      local src=selected and self:WeaponChoiceSource(selected)
      local preferredIcon=selected and A.Call(C_Spell and C_Spell.GetSpellTexture,selected.ranks[#selected.ranks])
      pick.icon:SetTexture(src and src.icon or preferredIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
      for _,row in ipairs(pick.menu.rows) do row:Hide() end
      local choices={{name="None (manual missing-buff alert)"}}
      for _,choice in ipairs(self.WeaponChoices) do if choice.class==weaponClass then choices[#choices+1]=choice end end
      for i,choice in ipairs(choices) do
        local choiceKey=choice.key
        local row=pick.menu.rows[i]
        if not row then row=button(pick.menu,"",4,-4-(i-1)*28,462,function(control)
          if A.Combat() then return end
          B.db.weaponChoices[control.hand]=control.choice; B.weaponPending=nil; B:RequestRefresh("weapon preference",0); B:Options()
        end); row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(22,22); row.icon:SetPoint("LEFT",4,0); pick.menu.rows[i]=row end
        row.hand=handKey; row.choice=choiceKey
        local source,why=self:WeaponChoiceSource(choiceKey and choice or nil)
        local icon=source and source.icon or (choiceKey and A.Call(C_Spell and C_Spell.GetSpellTexture,choice.ranks[#choice.ranks]))
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row:SetText(choice.name..(choiceKey and (source and (source.count and " (in bags: "..source.count..")" or " (learned)") or " (unavailable)") or "")); row:Show()
        addHelp(row,choice.name,why or "Select this buff for this hand. Highest available rank is used.")
      end
      pick.menu:SetHeight(#choices*28+8)
    end
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
      row.default=button(row,"Default",486,-16,58,function(btn)
        local def=btn:GetParent().def
        if def and not A.Combat() then B.db.buffSeconds[def.key]=nil; B:RequestRefresh("rebuff default",0); B:Options() end
      end)
      row.order=editbox(row,590,-17,48,true)
      row.order:SetScript("OnEnterPressed",function(s)
        local def=s:GetParent().def; if def and not A.Combat() then B.db.priorities[def.key]=math.max(1,tonumber(s:GetText()) or def.order); B:RequestRefresh("priority",0) end; s:ClearFocus(); B:Options()
      end)
      row.order:SetScript("OnEscapePressed",function(s) s:ClearFocus(); B:Options() end)
      f.buffRows[visible]=row
    end
    row.def=b; row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(visible-1)*58); row:Show(); row.check:SetChecked(self:Enabled(b)); row.name:SetText(b.name); row.icon:SetTexture(buffIcon(b))
    local groupName=pairedGroupName(b)
    if b.groupKey then
      local groupDef=self:FindBuff(b.groupKey)
      row.groupIcon:SetTexture(groupDef and buffIcon(groupDef) or 134400); row.groupIcon:Show()
      row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",106,-28); row.detail:SetText((groupName or "Group version").."  •  group spell")
    else
      row.groupIcon:Hide(); row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT",84,-28)
      row.detail:SetText(b.kind=="self" and "Self buff" or "Single-target buff")
    end
    row.order:SetText(tostring(self.db.priorities[b.key] or b.order))
    local threshold=self:RebuffSeconds(b)
    row.rebuff.silent=true; row.rebuff:SetValue(threshold); row.rebuff.valueText:SetText(formatSeconds(threshold)); row.rebuff.silent=false
    if self.db.buffSeconds[b.key]~=nil then row.default:Enable(); row.default:SetAlpha(1) else row.default:Disable(); row.default:SetAlpha(0.45) end
  end
  f.emptyBuffs:SetShown(visible==0)
  f.buffChild:SetHeight(math.max(1,visible*58))
  if f.diagText then f.diagText:SetText(table.concat(self:DiagnosticsLines(),"\n\n")) end
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
    local txt=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); txt:SetPoint("CENTER"); txt:SetText("DRAG")
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
  label(p,"Open BuffTap to manage class buffs, group assignments, friendly-target buffing, consumable reminders, timing, and the reminder icon.",18,-124,"GameFontHighlight",620)
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
