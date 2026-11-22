-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
-- First run has one decision, with an optional compact customization screen.
-- Settings and global game CVars only change through their explicit apply actions.
local _,B=...
local A=B.API
local T=B.OptionsTheme
local ONBOARDING_VERSION=1
local WIDTH,HEIGHT=560,600
local GIVERS={MAGE=true,PRIEST=true,DRUID=true,PALADIN=true}
local function freshSetup(self)
  return self.db.welcomeSeen~=true and self.db.onboardingVersion~=ONBOARDING_VERSION
end
local function configured(value)
  if type(value)~="table" then return value~=nil and value~=false end
  for _,v in pairs(value) do if configured(v) then return true end end
  return false
end
local function describe(value)
  if type(value)~="table" then return value==nil and B:Text("Default") or type(value)=="boolean" and B:Text(value and "On" or "Off") or tostring(value) end
  local keys={}; for key in pairs(value) do keys[#keys+1]=key end; table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
  local parts={}; for _,key in ipairs(keys) do parts[#parts+1]=tostring(key)..": "..describe(value[key]) end
  return #parts>0 and table.concat(parts,", ") or B:Text("Default")
end

-- Each recommendation knows the old default, so a value still at its default counts as untouched
-- and is pre-selected. A value the player changed is listed but left unselected.
local function recommendations(self)
  local d=self.db; local list={}
  local fields={sounds={"sound","campSound"},chime={"reminderSound","supplySound","campAlertSound"},modern={"iconStyle"},glow={"glow"},thanks={"helperThanks"},resting={"pauseResting"},party={"group"},dismiss={"helperDismiss","helperDismissMinutes"},pvp={"pvpProtection"},bounce={"helperBounce"},accent={"optionsAccentMode"},shamanCaster={"weaponChoices","weaponApply"},shamanHealer={"weaponChoices","weaponApply","buffs"}}
  local function add(spec)
    if spec.current==spec.target then return end
    local previous={}
    for _,key in ipairs(fields[spec.key] or {spec.key}) do
      local value=d[key]
      if key=="weaponChoices" then value=value and value.main elseif key=="buffs" then value=value and value["water-shield"] end
      previous[#previous+1]=describe(value)
    end
    spec.previous=table.concat(previous,"; ")
    if spec.group then
      local old={}
      for _,context in ipairs({"Party","Raid"}) do
        local settings=self:GroupSettings(context)
        old[#old+1]=context..": "..describe(spec.key=="blessings" and {classes=settings.blessingClasses,roles=d.blessingRoleChoices and d.blessingRoleChoices[context],priorities=settings.groupBlessingPriorities} or settings.buffRoles)
      end
      spec.previous=table.concat(old,"\n")
    end
    list[#list+1]=spec
  end
  local soundsOn=d.sound==true and d.campSound==true
  add({key="sounds",label="Alert sounds for reminders and camp",current=soundsOn,target=true,untouched=d.sound==false and d.campSound==false,
    apply=function() d.sound=true; d.campSound=true end})
  add({key="chime",label="BuffTap sounds for reminder, supply and camp alerts",current=d.reminderSound=="marimba" and d.supplySound=="glass" and d.campAlertSound=="bell",target=true,
    untouched=false,
    apply=function() d.reminderSound="marimba"; d.supplySound="glass"; d.campAlertSound="bell" end})
  add({key="modern",label="Modern square reminder icon instead of Classic",current=false,target=true,untouched=false,optional=true,
    apply=function() d.iconStyle="modern" end})
  if d.iconStyle=="modern" then list[#list]=nil end
  add({key="glow",label="Glow on the reminder icon",current=d.glow==true,target=true,untouched=false,apply=function() d.glow=true end})
  add({key="thanks",label="Solo thanks: thank players who buff you",current=d.helperThanks==true,target=true,untouched=d.helperThanks==false,
    apply=function() d.helperThanks=true end})
  add({key="resting",label="Pause reminders while resting",current=d.pauseResting==true,target=true,untouched=d.pauseResting==false,
    apply=function() d.pauseResting=true end})
  if self:DefaultGroupEnabled() then add({key="party",label="Buff my party and raid",current=d.group==true,target=true,untouched=false,apply=function()
    d.group=true; local root=d.groupContextSettings
    if type(root)=="table" then for _,c in ipairs({"Party","Raid"}) do if type(root[c])=="table" then root[c].group=true end end end
  end}) end
  add({key="dismiss",label="Right-click a reminder to dismiss it for 10 minutes",current=d.helperDismiss==true,target=true,untouched=false,
    apply=function() d.helperDismiss=true; if (tonumber(d.helperDismissMinutes) or 0)==0 then d.helperDismissMinutes=10 end end})
  add({key="pvp",label="Prevent accidental PvP flagging",current=d.pvpProtection==true,target=true,untouched=false,apply=function() d.pvpProtection=true end})
  add({key="bounce",label="Stop repeated stronger-buff errors",current=d.helperBounce==true,target=true,untouched=d.helperBounce==false,
    apply=function() d.helperBounce=true end})
  add({key="accent",label="Highlight colour: your class colour",current=d.optionsAccentMode=="class",target=true,untouched=d.optionsAccentMode=="gold",
    apply=function() d.optionsAccentMode="class" end})
  -- Class setups for party and raid. Only offered while the buff has no group preference yet.
  local class=A.Class("player")
  local function groupPreset(spec)
    local def=self:FindBuff(spec.buff); local root=def and self:RootKey(def)
    if not root then return end
    local untouched=true
    for _,context in ipairs({"Party","Raid"}) do
      local settings=self:GroupSettings(context)
      local map=settings and settings[spec.field]
      if type(map)=="table" and map[root]~=nil then untouched=false end
    end
    if untouched or (self.onboarding and self.onboarding.reviewMode) then
      add({key=spec.buff,label=spec.label,current=false,target=true,untouched=untouched,group=true,apply=function()
        for _,context in ipairs({"Party","Raid"}) do
          local settings=self:GroupSettings(context,true)
          settings[spec.field]=settings[spec.field] or {}
          settings[spec.field][root]=spec.value()
        end
      end})
    end
  end
  -- Class setups follow claude/BUFF-BASELINE.md. Each is offered only when the player has not set it up.
  local function known(key) local def=self:FindBuff(key); return def and self:Resolve(def,"player") and true or false end
  local function unset(key) return d.buffs[key]==nil end
  local tank=function() return "tank" end
  local before=#list
  if class=="DRUID" then groupPreset({buff="thorns",field="buffRoles",value=tank,label="Thorns on tanks in party and raid"}) end
  if class=="PRIEST" then
    -- Forever grants Fear Ward to every Priest at level 20; setup may be chosen before it is learned.
    if unset("fear-ward") then
      groupPreset({buff="fear-ward",field="buffRoles",value=tank,label="Fear Ward on tanks in party and raid"})
      -- Situational (fear-heavy fights), so it is listed but not preselected.
      local last=list[#list]; if last and last.key=="fear-ward" then local apply=last.apply; last.untouched=false; last.optional=true; last.apply=function() d.buffs["fear-ward"]=true; apply() end end
    end
  end
  if class=="PALADIN" then
    local untouched=not self:GroupPreference("blessingAssignments","Party") and not self:GroupPreference("blessingAssignments","Raid") and next(d.blessingClasses or {})==nil
    if configured(d.groupBlessingPriorities) or configured(d.blessingRoleChoices)
      or configured(d.blessingRolePriorities) or configured(d.blessingGroupOverrides)
      or configured(d.blessingRaidDefaults and d.blessingRaidDefaults.classes)
      or d.blessingPartyMode=="same" then untouched=false end
    if untouched or (self.onboarding and self.onboarding.reviewMode) then
      local plan={
        WARRIOR={"bok","bom"},ROGUE={"bok","bom"},HUNTER={"bok","bom"},
        MAGE={"bok","bow"},WARLOCK={"bok","bow"},PRIEST={"bok","bow"},DRUID={"bok","bow"},SHAMAN={"bok","bow"},
        PALADIN={"bok","bom","bow"},
      }
      add({key="blessings",untouched=untouched,current=false,target=true,group=true,
        label="Adaptive blessing plan: Kings first when learned, with Might or Wisdom fallbacks",
        apply=function()
          for _,key in ipairs({"bok","bom","bow"}) do if d.buffs[key]==nil then d.buffs[key]=true end end
          d.smartPreset=d.smartPreset or {version=1,managed={}}
          for _,context in ipairs({"Party","Raid"}) do
            self:SetBlessingPlanMode(context,0,"class")
            for cls,order in pairs(plan) do
              self:SetGroupBlessingSettings(cls,nil,"priority",nil,false,context)
              self:SetGroupBlessingSettings(cls,nil,nil,order,true,context)
              d.smartPreset.managed[context..":blessing:"..cls]=true
            end
            for _,cls in ipairs({"WARRIOR","PALADIN","DRUID"}) do self:SetBlessingRolePriority("TANK",cls,{"bok","bom"},context) end
            for _,cls in ipairs({"PRIEST","PALADIN","DRUID","SHAMAN"}) do self:SetBlessingRolePriority("HEALER",cls,{"bow","bok"},context) end
          end
        end})
    end
  end
  -- Class readiness (Helpers page) for the classes that can use it.
  local function readiness(field,label) add({key=field,label=label,current=d[field]==true,target=true,untouched=d[field]~=true,apply=function() d[field]=true end}) end
  if class=="HUNTER" or class=="WARLOCK" then readiness("helperPet","Class readiness: keep my pet ready") end
  if class=="WARLOCK" then
    readiness("helperHealthstone","Class readiness: prepare a personal Healthstone")
    readiness("helperSoulstone","Class readiness: keep a Soulstone up")
  end
  if class=="PALADIN" then readiness("helperOath","Class readiness: maintain your assigned Oath") end
  if class=="SHAMAN" then
    -- Spec can't be read, so casters and healers pick here; melee keeps Windfury and Lightning Shield.
    add({key="shamanCaster",exclusive="shaman",optional=true,untouched=false,current=false,target=true,label="I play a caster Shaman: Flametongue Weapon",
      apply=function() d.weaponChoices.main="flametongue"; d.smartPreset=d.smartPreset or {version=1,managed={}}; d.smartPreset.managed["weapon:main"]=true end})
    add({key="shamanHealer",exclusive="shaman",optional=true,untouched=false,current=false,target=true,label="I play a healing Shaman: Flametongue Weapon and Water Shield",
      apply=function() d.weaponChoices.main="flametongue"; d.buffs["water-shield"]=true; d.smartPreset=d.smartPreset or {version=1,managed={}}; d.smartPreset.managed["weapon:main"]=true end})
  end
  -- New-character recommendations, never gated on learning or player level.
  -- Existing characters can opt in explicitly without replacing their choices.
  local fresh=d.welcomeSeen~=true
  local function classReminder(field,label)
    add({key=field,label=label,current=d[field]==true,target=true,untouched=fresh,optional=not fresh,classReminder=true,
      apply=function() d[field]=true end})
  end
  local cleanse=self:CanCleanseAnything()
  local revive=self:CanConfigureRevive()
  if cleanse then classReminder("cleanseEnabled","Cleanse reminders (outside combat)") end
  if revive then classReminder("reviveEnabled","Resurrection reminders") end
  if cleanse and revive then classReminder("cleanseFirst","Cleanse before resurrection") end
  if class=="DRUID" or class=="SHAMAN" then classReminder("smartShift","SmartShift: offer my previous form") end
  list.classCovered=#list==before
  -- Put the class choices on the first review page, before appearance extras.
  local ordered={}
  local function classChoice(spec)
    return spec.classReminder or spec.group or spec.exclusive=="shaman"
      or spec.key=="helperPet" or spec.key=="helperHealthstone" or spec.key=="helperSoulstone" or spec.key=="helperOath"
  end
  for _,spec in ipairs(list) do if classChoice(spec) then ordered[#ordered+1]=spec end end
  for _,spec in ipairs(list) do if not classChoice(spec) then ordered[#ordered+1]=spec end end
  ordered.classCovered=list.classCovered
  return ordered
end

local function text(parent,font,x,y,width,value)
  local fs=parent:CreateFontString(nil,"OVERLAY",font)
  fs:SetPoint("TOPLEFT",x,y); fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
  fs:SetText(value and B:Text(value) or ""); return fs
end
local function button(parent,label,x,y,width,variant,onClick)
  local b=CreateFrame("Button",nil,parent,"BackdropTemplate"); b:SetSize(width,30); b:SetPoint("TOPLEFT",x,y)
  b:SetText(B:Text(label)); T.Variant(b,variant)
  b:SetScript("OnClick",function() if not A.Combat() then onClick() end end)
  return b
end

function B:OnboardingPending()
  return self.db and self.db.welcomeSeen~=true and self.db.onboardingVersion~=ONBOARDING_VERSION
end
function B:FinishOnboarding()
  self.db.onboardingVersion=ONBOARDING_VERSION
  -- Explicit dismissal also suppresses the legacy welcome card.
  self.db.welcomeSeen=true
  if self.onboarding then self.onboarding:Hide() end
end

local function clearPage(f)
  for _,region in ipairs(f.pageRegions or {}) do region:Hide() end
  f.pageRegions={}
end
local function track(f,...) for _,r in ipairs({...}) do f.pageRegions[#f.pageRegions+1]=r end end

-- Keep the policy separate from the older advanced recommendation catalog.
local QUICK_FIELDS={nearby="nearbyEnabled",sounds="sound",resting="pauseResting",bounce="helperBounce",
  cleanseEnabled="cleanseEnabled",reviveEnabled="reviveEnabled",thanks="helperThanks"}
function B:FirstRunChoices()
  local fresh=freshSetup(self)
  local list={}
  local function add(key,label,recommended)
    local field=QUICK_FIELDS[key]
    list[#list+1]={key=key,label=label,selected=fresh and recommended or self.db[field]==true}
  end
  add("nearby",GIVERS[A.Class("player")] and "Nearby player buffing" or "Nearby players and party assistance",true)
  add("sounds","Reminder sounds",true)
  add("resting","Pause reminders while resting",true)
  add("bounce","Stronger-buff error protection",true)
  if self:CanCleanseAnything() then add("cleanseEnabled","Cleanse reminders",true) end
  if self:CanConfigureRevive() then add("reviveEnabled","Resurrection reminders",true) end
  add("thanks","Automatically thank players who buff me",false)
  return list
end
local function copy(value)
  if type(value)~="table" then return value end
  local out={}; for k,v in pairs(value) do out[k]=copy(v) end; return out
end
local function restore(target,values)
  for key in pairs(target) do target[key]=nil end
  for key,value in pairs(values) do target[key]=copy(value) end
end
function B:ApplyFirstRunSetup(selections)
  local f=self.onboarding
  if A.Combat() or not f or not f:IsShown() or not self.db or type(selections)~="table" then return false end
  if self.db.welcomeSeen and not f.reviewMode then return false end
  local staged={}; local allowed={}
  for _,spec in ipairs(self:FirstRunChoices()) do allowed[spec.key]=true end
  for key in pairs(allowed) do if type(selections[key])~="boolean" then return false end end
  for key,value in pairs(selections) do
    if not allowed[key] or type(value)~="boolean" then return false end
    staged[key]=value
  end
  -- Capture both the per-character table and the shared-profile backing table.
  -- Never replace the facade or finish onboarding after a failed apply/refresh.
  local d=self.db; local old=copy(d); local profile=self.profileDB and self.profileDB.profile
  local oldProfile=profile and copy(profile)
  local oldOpened=self.nearbyUserOpened
  local fresh=freshSetup(self)
  local ok=pcall(function()
    if fresh then
      for _,spec in ipairs(recommendations(self)) do
        if (spec.key=="thorns" or spec.key=="blessings") and spec.untouched then spec.apply() end
      end
    end
    for key,value in pairs(staged) do d[QUICK_FIELDS[key]]=value end
    if fresh then
      for _,key in ipairs({"cleanseSoundEnabled","suppliesSound","campSound","socialSoundEnabled"}) do d[key]=staged.sounds end
    end
    if fresh and staged.cleanseEnabled and staged.reviveEnabled then d.cleanseFirst=true end
    if staged.nearby then
      -- Do not call ToggleNearby: its first-use guide is voluntary help.
      -- Existing invites, whispers, resting policy and safety preferences stay intact.
      d.nearbyIntroSeen=true; self.nearbyUserOpened=true
    end
    self:NormalizeVisualOptions()
    if self.NormalizeAlerts then self:NormalizeAlerts() end
    if self.NormalizeGroupContexts then self:NormalizeGroupContexts() end
    self.situationDirty=true; self.appearance=nil; self.nearbySnapshot=nil
    self:SyncNearby(); self:UpdateNearbyWindow()
    if T.Refresh then T.Refresh() end
    self:RequestRefresh("quick start",0)
    if self.options and self.options:IsShown() then self:Options() end
  end)
  if not ok then
    restore(d,old); if profile then restore(profile,oldProfile) end
    self.nearbyUserOpened=oldOpened
    self.nearbySnapshot=nil
    pcall(function() self:SyncNearby(); self:UpdateNearbyWindow(); self:RequestRefresh("setup cancelled",0) end)
    self.Print(self:Text("Setup could not be applied. Your settings were restored. Please try again."))
    return false
  end
  self:FinishOnboarding(); return true
end

-- Probe a readable 0/1 string, never infer support from a missing CVarBool.
local NAMES_ONLY="nameplateShowOnlyNameForFriendlyPlayerUnits"
local function readCVar(name)
  local value=A.Call(C_CVar and C_CVar.GetCVar,name)
  if value==nil then value=A.Call(GetCVar,name) end
  if not A.Public(value) then return end
  if value=="0" or value==0 then return "0" end
  if value=="1" or value==1 then return "1" end
end
function B:CanEnableFriendlyNamesOnly()
  local state,key=self:FriendlyPlatesState()
  return state~=nil and key~="unavailable" and readCVar(key)~=nil and readCVar(NAMES_ONLY)~=nil
end
function B:EnableFriendlyNamesOnly()
  if A.Combat() or not self:CanEnableFriendlyNamesOnly() then return false end
  local _,key=self:FriendlyPlatesState()
  local setter=C_CVar and C_CVar.SetCVar or SetCVar
  if type(setter)~="function" then return false end
  local oldNames,oldVisible=readCVar(NAMES_ONLY),readCVar(key)
  -- Establish names-only presentation first, so failure cannot expose full bars.
  local ok=pcall(setter,NAMES_ONLY,"1")
  if not ok or readCVar(NAMES_ONLY)~="1" then
    pcall(setter,NAMES_ONLY,oldNames); return false
  end
  ok=pcall(setter,key,"1")
  if not ok or readCVar(key)~="1" or readCVar(NAMES_ONLY)~="1" then
    pcall(setter,key,oldVisible); pcall(setter,NAMES_ONLY,oldNames); return false
  end
  self.nearbySnapshot=nil; self:UpdateNearbyWindow()
  return true
end
function B:OnboardingPlateRow(y)
  local f=self.onboarding
  local nearby=f.quickSelection and f.quickSelection.nearby
  local thanks=f.quickSelection and f.quickSelection.thanks
  local state=self:FriendlyPlatesState()
  if not nearby and not thanks then return end
  local note
  if nearby and state~=true then
    note="Nearby is waiting for friendly nameplates. Use Shift+V or your game's nameplate settings."
  elseif thanks and state~=true then
    note="Solo thanks works outdoors and can find some buff casters without nameplates."
  end
  if not note then return end
  track(f,text(f,T.fonts.Muted,24,y,WIDTH-48,note))
  if self:CanEnableFriendlyNamesOnly() then
    track(f,button(f,"Enable friendly names only",24,y-42,WIDTH-48,nil,function()
      if not B:EnableFriendlyNamesOnly() then
        B.Print(B:Text("Friendly names could not be enabled. Check your game's nameplate settings."))
      end
      if f.quickCustomize then B:OnboardingSettingsPage() else B:OnboardingWelcomePage() end
    end))
  else
    track(f,text(f,T.fonts.Muted,24,y-42,WIDTH-48,"Names-only support could not be confirmed. Choose your preferred friendly nameplate appearance in the game settings."))
  end
end
function B:OnboardingWelcomePage()
  local f=self.onboarding; clearPage(f); f.quickCustomize=false
  f:SetHeight(600)
  if not f.quickSelection then
    f.quickSelection={}; for _,spec in ipairs(self:FirstRunChoices()) do f.quickSelection[spec.key]=spec.selected end
  end
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,f.reviewMode and "Review recommended settings" or "Welcome to BuffTap"))
  track(f,text(f,T.fonts.Note,24,-156,WIDTH-48,f.reviewMode
    and "Review your choices before applying changes."
    or "Your class buffs are ready. Choose a few recommended extras, or keep BuffTap's current defaults."))
  track(f,text(f,T.fonts.Body,24,-214,WIDTH-48,"Class and group buffs: ready"))
  track(f,text(f,T.fonts.Body,24,-246,WIDTH-48,GIVERS[A.Class("player")]
    and "Nearby buffing: included with recommended setup" or "Nearby party assistance: included with recommended setup"))
  track(f,text(f,T.fonts.Body,24,-278,WIDTH-48,"Reminders and safeguards: sensible defaults"))
  self:OnboardingPlateRow(-316)
  track(f,button(f,f.reviewMode and "Review choices" or "Get started",24,-422,250,"primary",function()
    if f.reviewMode then B:OnboardingSettingsPage() else B:ApplyFirstRunSetup(f.quickSelection) end
  end))
  track(f,button(f,"Customize first",286,-422,250,nil,function() B:OnboardingSettingsPage() end))
  track(f,button(f,"Keep current settings",24,-462,WIDTH-48,nil,function() B:FinishOnboarding() end))
  if #self:OnboardingCopySources()>0 then
    track(f,button(f,"Copy settings from another character",24,-502,WIDTH-48,nil,function() B:OnboardingCopyPage() end))
  end
  track(f,text(f,T.fonts.Muted,24,-552,WIDTH-48,"Keep current settings preserves your choices. Change anything later in Settings."))
end
function B:OnboardingCopySources()
  local list={}; local current=self.profileDB and self.profileDB:GetCurrentProfile()
  for _,name in ipairs(self.ProfileNames and self:ProfileNames() or {}) do
    if name~=current and self.profileDB and type(self.profileDB.sv.profiles[name])=="table" then list[#list+1]=name end
  end
  return list
end
function B:OnboardingCopyPage()
  local f=self.onboarding; clearPage(f)
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,"Copy settings from"))
  track(f,text(f,T.fonts.Muted,24,-150,WIDTH-48,"Copies profile preferences and matching class settings. Recommended extras are not added."))
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",24,-198); scroll:SetSize(WIDTH-68,300); track(f,scroll)
  local names=self:OnboardingCopySources()
  local body=CreateFrame("Frame",nil,scroll); body:SetSize(WIDTH-88,math.max(300,#names*38)); scroll:SetScrollChild(body)
  for i,name in ipairs(names) do
    button(body,name,0,-(i-1)*38,WIDTH-88,nil,function()
      local source=B.ClassCopySources and B:ClassCopySources(name)[1] or nil
      if B:CopySettingsProfile(name,source) then B:FinishOnboarding()
      else B.Print(B:Text("Settings could not be copied. Choose another source or go back.")) end
    end)
  end
  track(f,button(f,"Back",24,-540,250,nil,function() B:OnboardingWelcomePage() end))
end
function B:OnboardingSettingsPage()
  local f=self.onboarding; clearPage(f); f.quickCustomize=true; f.choices={}
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,"Recommended settings"))
  track(f,text(f,T.fonts.Muted,24,-152,WIDTH-48,"Choose your extras. Nothing changes until Apply & finish."))
  local y=-190
  for _,spec in ipairs(self:FirstRunChoices()) do
    local c=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate")
    c:SetSize(24,24); c:SetPoint("TOPLEFT",22,y)
    c.Text:SetFontObject(T.fonts.Body); c.Text:SetText(self:Text(spec.label)); c.Text:SetWidth(WIDTH-96); c.Text:SetJustifyH("LEFT")
    c:SetChecked(f.quickSelection[spec.key]==true); T.Check(c)
    c:SetScript("OnClick",function(check)
      f.quickSelection[spec.key]=check:GetChecked()==true
      if spec.key=="nearby" or spec.key=="thanks" then B:OnboardingSettingsPage() end
    end)
    f.choices[#f.choices+1]={spec=spec,check=c}; track(f,c); y=y-30
  end
  track(f,text(f,T.fonts.Muted,24,y,WIDTH-48,"Solo thanks is for solo outdoor play. Nearby also offers social and party assistance for classes without buffs for others."))
  self:OnboardingPlateRow(y-42)
  track(f,button(f,"Apply & finish",24,-540,250,"primary",function() B:ApplyOnboarding() end))
  track(f,button(f,"Back",286,-540,250,nil,function() B:OnboardingWelcomePage() end))
end
function B:ApplyOnboarding()
  if A.Combat() or not self.onboarding then return false end
  local f=self.onboarding
  for _,choice in ipairs(f.choices or {}) do f.quickSelection[choice.spec.key]=choice.check:GetChecked()==true end
  return self:ApplyFirstRunSetup(f.quickSelection)
end

function B:OnboardingSupplyHint(class)
  if class=="HUNTER" then return "Supplies: add the arrows or bullets you use from your bags, then choose a low-stock minimum. When you change ammunition, update the tracked item. BuffTap only warns; it never buys or uses ammo." end
  if class=="WARLOCK" then return "Supplies: add Soul Shards from your bags and choose a low-stock minimum. You can also track your chosen consumables. Stock warnings do not create or use shards." end
  if class=="MAGE" or class=="PRIEST" or class=="DRUID" or class=="PALADIN" then return "Supplies: add your group-buff reagents from your bags and choose a low-stock minimum. Your chosen consumables and compatible weapon supplies can be tracked too." end
  return "Supplies: track chosen consumables, weapon supplies or any item from your bags. Choose your own low-stock minimums. These are stock warnings, not automatic item use."
end

function B:OnboardingFeaturesPage()
  local f=self.onboarding; clearPage(f)
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,"Worth knowing"))
  -- The binding is the heart of BuffTap, so it can be changed right here.
  track(f,button(f,"Change binding",24,-156,160,nil,function() B:CaptureBinding() end))
  -- Reminder look: icon style, size, text, glow and effects all live in Customization.
  track(f,button(f,"Customize reminders",200,-156,160,nil,function()
    B:Options(); if B.options and B.options.selectTab then B.options.selectTab(8) end
    if B.SetAppearanceView then B:SetAppearanceView("buff") end
  end))
  track(f,button(f,"Set up supplies",376,-156,160,nil,function()
    B:FinishOnboarding(); B:ShowSuppliesOptions()
  end))
  -- Keep the final guide within its pane as class-specific tips are added.
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",24,-198); scroll:SetSize(WIDTH-68,258)
  local body=CreateFrame("Frame",nil,scroll); body:SetSize(WIDTH-88,258); scroll:SetScrollChild(body)
  f.featureScroll=scroll; track(f,scroll)
  local y=0
  local class=A.Class("player")
  local binding=#self.db.keys>0 and table.concat(self.db.keys,", ") or self:Text("none: click the reminder")
  local lines={
    self:Text("How to buff: when a reminder appears, press your binding (%s) or click the icon.",binding),
    "Nearby: buff players passing by, invite them, or whisper for a buff you are missing. Right-click a name to blacklist a player or guild. A separate Nearby key and a Mana reserve are optional.",
    "Groups: buffs top up at ready checks, and roles can send a buff to tanks or healers only, like Thorns on the tank.",
    "Right-click a reminder to dismiss it for a while. Right-click the minimap icon for quick controls and pause.",
    "Camp tray sets up a campfire and sleeping bag. Customize look changes the icon, labels and countdown.",
    "Profiles: export your settings and import them on another character or account.",
    self:OnboardingSupplyHint(class),
  }
  if class=="WARLOCK" or class=="SHAMAN" or class=="DRUID" then
    table.insert(lines,#lines,"Underwater buffs are smart: Unending Breath, Water Breathing and Aquatic Form only remind while you are underwater. A player you target can still get a breathing buff any time.")
  end
  if class=="HUNTER" or class=="WARLOCK" or class=="PALADIN" then
    table.insert(lines,#lines,"Class helpers (My buffs): pet, Healthstone, Soulstone or Oath reminders for your class.")
  end
  for _,line in ipairs(lines) do
    local fs=text(body,T.fonts.Note,16,y,WIDTH-112,line); track(f,fs)
    local dot=text(body,T.fonts.Note,0,y,12,"•"); track(f,dot)
    y=y-(fs:GetStringHeight() or 16)-9
  end
  body:SetHeight(math.max(258,-y))
  if not self.db.nearbyEnabled then
    track(f,text(f,T.fonts.Note,24,-480,WIDTH-48,B:NearbyPitch(class)))
    track(f,button(f,"See how Nearby works",24,-540,250,"primary",function()
      B:FinishOnboarding(); B:ShowNearbyIntro(true)
    end))
    track(f,button(f,"Done",286,-540,250,nil,function() B:FinishOnboarding() end))
  else
    track(f,button(f,"Done",24,-540,250,"primary",function() B:FinishOnboarding() end))
  end
end

function B:ShowOnboarding(force)
  if A.Combat() or not self.db or (not force and not self:OnboardingPending()) then return end
  -- Wait out loading screens and the new-character cinematic (UIParent is hidden then).
  if not force and UIParent and UIParent.IsVisible and UIParent:IsVisible()==false then
    self:StartTimer("welcome",3,function() B:ShowOnboarding() end); return
  end
  if not self.onboarding then
    local f=CreateFrame("Frame","BuffTapOnboarding",UIParent,"BackdropTemplate")
    f:SetSize(WIDTH,HEIGHT); f:SetFrameStrata("DIALOG"); f:SetToplevel(true); f:EnableMouse(true); f:SetMovable(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    T.Surface(f,"window"); T.Shadow(f,18,.55)
    if self.AddMiniBanner then self:AddMiniBanner(f,WIDTH) end
    -- Only an explicit choice finishes the setup. Hiding alone does not: a new character's intro
    -- cinematic hides the whole UI, and that must not count as "Leave me alone".
    local close=CreateFrame("Button",nil,f,"BackdropTemplate"); close:SetSize(26,26); close:SetPoint("TOPRIGHT",-10,-10)
    T.Variant(close,"danger"); close.glyph=close:CreateTexture(nil,"ARTWORK"); close.glyph:SetPoint("CENTER"); T.Glyph(close.glyph,"close",14,.80,.82,.86); close:SetScript("OnClick",function() if not A.Combat() then B:FinishOnboarding() end end)
    close:SetScript("OnEnter",function(s) T.Tooltip(s,B:Text("Keep current settings"),B:Text("Keep current settings preserves your choices. Change anything later in Settings.")) end)
    close:SetScript("OnLeave",function() GameTooltip:Hide() end)
    f:EnableKeyboard(true)
    f:SetPropagateKeyboardInput(true)
    f:SetScript("OnKeyDown",function(frame,key)
      local dismiss=key=="ESCAPE" and not A.Combat()
      frame:SetPropagateKeyboardInput(not dismiss)
      if dismiss then B:FinishOnboarding() end
    end)
    self.onboarding=f; f.pageRegions={}
  end
  self.onboarding.reviewMode=force==true
  self.onboarding.quickSelection=nil
  self.onboarding.selection={}; self.onboarding.choices={}; self.onboarding.recommendations=nil; self.onboarding.backup=false
  if self.HideOptionsPopups then self:HideOptionsPopups() end
  local width,height=UIParent:GetSize()
  if A.Number(width) and A.Number(height) then self.onboarding:SetScale(math.min(1,(width-32)/WIDTH,(height-32)/HEIGHT)) end
  self.onboarding:ClearAllPoints(); self.onboarding:SetPoint("CENTER",UIParent,"CENTER",0,40)
  self:OnboardingWelcomePage(); self.onboarding:Show(); self.onboarding:Raise()
end

-- Nearby introduction: a drawn mock of the window with callouts, then three quick choices.
-- Shown the first time Nearby is turned on (from anywhere) and from the Nearby page's "How it works".
local INTRO_W,INTRO_H=720,770
local CLASS_ICONS="Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local MEDIA="Interface\\AddOns\\BuffTap\\Media\\"
local function swatch(parent,layer,r,g,b,a) local t=parent:CreateTexture(nil,layer); t:SetColorTexture(r,g,b,a); return t end
local drawGlyph
-- Name tags as the real window draws them (Nearby.lua): right end of the name field.
local TAGS={pvp={"UIPvPFlag",.9,.36,.32},friend={"UIFriend",.42,.72,1},guild={"UIGuild",.35,.9,.42},blocked={"NavBlacklist",.95,.25,.22}}
local function inlineTag(key)
  local t=TAGS[key]
  return "|T"..MEDIA..t[1]..":12:12:0:0:64:64:0:64:0:64:"..math.floor(t[2]*255)..":"..math.floor(t[3]*255)..":"..math.floor(t[4]*255).."|t"
end
-- The gutter tiles exactly as the real window draws them: gold +, blue arrow, buff icon tile.
function drawGlyph(tile,gutter)
  swatch(tile,"BACKGROUND",.11,.13,.14,.95):SetAllPoints()
  if gutter=="invite" or gutter=="join" then
    local t=tile:CreateTexture(nil,"OVERLAY"); t:SetSize(16,16); t:SetPoint("CENTER")
    t:SetTexture(MEDIA..(gutter=="invite" and "UIInvitePlus" or "UIJoinArrow"))
    if gutter=="invite" then t:SetVertexColor(1,.82,0) else t:SetVertexColor(.35,.75,1) end
  elseif gutter=="request" then
    swatch(tile,"BORDER",.40,.82,.90,.55):SetAllPoints()
    local t=tile:CreateTexture(nil,"ARTWORK"); t:SetPoint("TOPLEFT",1,-1); t:SetPoint("BOTTOMRIGHT",-1,1); t:SetTexture(135932); t:SetTexCoord(.08,.92,.08,.92)
  end
end
-- Gold-edged icon, like the class and buff icons in the real window.
local function edgedIcon(parent,size,texture,coords)
  local edge=swatch(parent,"BORDER",.55,.47,.30,.85); edge:SetSize(size+2,size+2)
  local icon=parent:CreateTexture(nil,"ARTWORK"); icon:SetSize(size,size); icon:SetPoint("CENTER",edge,"CENTER")
  icon:SetTexture(texture); if coords then icon:SetTexCoord(unpack(coords)) else icon:SetTexCoord(.08,.92,.08,.92) end
  return edge
end
-- Numbered marker: a gold disc with a dark number.
local function badge(parent,n)
  local holder=CreateFrame("Frame",nil,parent); holder:SetSize(16,16)
  local disc=holder:CreateTexture(nil,"ARTWORK"); disc:SetAllPoints(); disc:SetTexture(MEDIA.."UICornerFill"); disc:SetVertexColor(1,.75,.16)
  local text=holder:CreateFontString(nil,"OVERLAY",T.fonts.Small); text:SetPoint("CENTER",0,0); text:SetText(tostring(n)); text:SetTextColor(.08,.06,.03); text:SetShadowOffset(0,0)
  return holder
end
local function leader(parent,x1,x2,y,vertical)
  local line=swatch(parent,"ARTWORK",1,.75,.16,.9)
  if vertical then line:SetSize(1,math.abs(x2-x1)); line:SetPoint("TOPLEFT",y,-math.min(x1,x2))
  else line:SetSize(math.abs(x2-x1),1); line:SetPoint("TOPLEFT",math.min(x1,x2),-y) end
  return line
end
-- The drawn Nearby guide: a picture of the window with numbered markers, and a numbered key
-- on the right in two groups. Used by the introduction and the Nearby page.
-- Pretend players (names from the developer).
local WIN_X,WIN_W,ROW_H,TOP=56,240,26,28
function B:DrawNearbyGuide(g,width)
  -- Layout: the numbered key (1-6) on the left, the drawn window with its name tags (7) on the
  -- right. PX shifts the whole picture to the right column. TOP leaves room for marker 4.
  local PX=width-332
  local win=CreateFrame("Frame",nil,g); win:SetPoint("TOPLEFT",PX+WIN_X,-TOP); win:SetSize(WIN_W,27+5*ROW_H)
  local shadow=win:CreateTexture(nil,"BACKGROUND",nil,-8); shadow:SetTexture(MEDIA.."UIShadow"); shadow:SetPoint("TOPLEFT",-40,10); shadow:SetPoint("BOTTOMRIGHT",14,-14); shadow:SetVertexColor(0,0,0,.8)
  local head=swatch(win,"BORDER",.19,.235,.25,1); head:SetPoint("TOPLEFT"); head:SetSize(WIN_W,24)
  local title=win:CreateFontString(nil,"OVERLAY",T.fonts.Body); title:SetPoint("LEFT",head,"LEFT",8,0); title:SetText("BuffTap"); title:SetTextColor(1,.82,0)
  local count=win:CreateFontString(nil,"OVERLAY",T.fonts.Body); count:SetPoint("RIGHT",head,"RIGHT",-70,0); count:SetText("1/5")
  local people=win:CreateTexture(nil,"OVERLAY"); people:SetSize(15,15); people:SetPoint("RIGHT",head,"RIGHT",-48,0); people:SetTexture(MEDIA.."UIPeople"); people:SetVertexColor(1,.78,.16)
  local lockBody=swatch(win,"OVERLAY",.8,.8,.76,1); lockBody:SetSize(8,6); lockBody:SetPoint("RIGHT",head,"RIGHT",-28,-2)
  for _,pt in ipairs({{-3,5,1,5},{3,5,1,5},{0,7.5,7,1}}) do local t=swatch(win,"OVERLAY",.8,.8,.76,1); t:SetSize(pt[3],pt[4]); t:SetPoint("CENTER",lockBody,"CENTER",pt[1],pt[2]) end
  local close=win:CreateFontString(nil,"OVERLAY",T.fonts.Body); close:SetPoint("RIGHT",head,"RIGHT",-8,0); close:SetText("x")
  local line=swatch(win,"OVERLAY",1,.49,.04,1); line:SetPoint("TOPLEFT",0,-24); line:SetSize(WIN_W,1)
  local rows={
    {"WARRIOR","(60) Dontstop Bleedin","invite",136078,"friend"},
    {"PALADIN","(58) Everybuff Youtake","join",nil,"guild"},
    {"MAGE","(52) Poursome Manaonme","request",nil,nil},
    {"HUNTER","(47) Gland Downunder","invite",nil,nil},
    {"ROGUE","(55) Smooth Criminelf","invite",nil,"pvp"},
  }
  local function rowY(i) return 27+(i-1)*ROW_H end
  for i,spec in ipairs(rows) do
    local y=rowY(i)
    -- The first row is the one your binding buffs next, tinted like the real window.
    local bg=i==1 and swatch(win,"BORDER",.30,.28,.22,1) or swatch(win,"BORDER",.205,.245,.25,1); bg:SetPoint("TOPLEFT",0,-y); bg:SetSize(WIN_W,ROW_H-3)
    local tile=CreateFrame("Frame",nil,g); tile:SetSize(22,ROW_H-3); tile:SetPoint("TOPLEFT",PX+WIN_X-26,-(TOP+y)); drawGlyph(tile,spec[3])
    local c=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[spec[1]]
    local cls=edgedIcon(win,16,CLASS_ICONS,c and {c[1],c[2],c[3],c[4]}); cls:SetPoint("TOPLEFT",4,-(y+2))
    local name=win:CreateFontString(nil,"OVERLAY",T.fonts.Body); name:SetPoint("TOPLEFT",28,-(y+4)); name:SetText(spec[2])
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[spec[1]]; if color then name:SetTextColor(color.r,color.g,color.b) end
    if spec[4] then local buff=edgedIcon(win,18,spec[4]); buff:SetPoint("TOPRIGHT",-5,-(y+1))
    else local dash=win:CreateTexture(nil,"ARTWORK"); dash:SetSize(10,10); dash:SetPoint("CENTER",win,"TOPRIGHT",-15,-(y+11)); dash:SetTexture(MEDIA.."UIDash"); dash:SetVertexColor(.6,.65,.64) end
    if spec[5] then local t=TAGS[spec[5]]; local mark=win:CreateTexture(nil,"ARTWORK"); mark:SetSize(12,12); mark:SetPoint("CENTER",win,"TOPRIGHT",-35,-(y+11)); mark:SetTexture(MEDIA..t[1]); mark:SetVertexColor(t[2],t[3],t[4]) end
  end
  -- Markers: 1-3 left of the buttons, 4 above the people icon, 5 and 6 right of the buff icon
  -- and a dash, 7 under the tag column.
  for n=1,3 do
    local y=TOP+rowY(n)+11
    leader(g,PX+12,PX+WIN_X-28,y); local m=badge(g,n); m:SetPoint("CENTER",g,"TOPLEFT",PX+8,-y)
  end
  local peopleX=PX+WIN_X+WIN_W-55
  leader(g,8,TOP+4,peopleX,true); local four=badge(g,4); four:SetPoint("CENTER",g,"TOPLEFT",peopleX,-8)
  for _,spec in ipairs({{5,1},{6,3}}) do
    local y=TOP+rowY(spec[2])+11
    leader(g,PX+WIN_X+WIN_W+2,PX+WIN_X+WIN_W+20,y); local m=badge(g,spec[1]); m:SetPoint("CENTER",g,"TOPLEFT",PX+WIN_X+WIN_W+26,-y)
  end
  local bottom=TOP+27+5*ROW_H; local tagX=PX+WIN_X+WIN_W-35
  leader(g,bottom-2,bottom+12,tagX,true); local seven=badge(g,7); seven:SetPoint("CENTER",g,"TOPLEFT",tagX,-(bottom+19))
  -- Name tags under the window: a two-by-two grid of tag and meaning, then the PvP note.
  local tagsTitle=g:CreateFontString(nil,"OVERLAY",T.fonts.Body); tagsTitle:SetPoint("TOPLEFT",g,"TOPLEFT",PX+WIN_X-26,-(bottom+38)); tagsTitle:SetText(self:Text("Name tags"))
  local tagsBadge=badge(g,7); tagsBadge:SetPoint("RIGHT",tagsTitle,"LEFT",-6,0)
  local col=136
  for i,spec in ipairs({{"pvp","PvP flagged"},{"blocked","Blacklisted"},{"friend","Friend"},{"guild","Guild member"}}) do
    local t=TAGS[spec[1]]; local x=((i-1)%2)*col; local y=-6-math.floor((i-1)/2)*18
    local icon=g:CreateTexture(nil,"ARTWORK"); icon:SetSize(12,12); icon:SetPoint("TOPLEFT",tagsTitle,"BOTTOMLEFT",x,y-1); icon:SetTexture(MEDIA..t[1]); icon:SetVertexColor(t[2],t[3],t[4])
    local label=g:CreateFontString(nil,"OVERLAY",T.fonts.Muted); label:SetPoint("LEFT",icon,"RIGHT",6,0); label:SetText(self:Text(spec[2]))
  end
  local note=g:CreateFontString(nil,"OVERLAY",T.fonts.Muted); note:SetWidth(290); note:SetJustifyH("LEFT"); note:SetWordWrap(true)
  note:SetPoint("TOPLEFT",tagsTitle,"BOTTOMLEFT",0,-46); note:SetText(self:Text("With PvP protection on, flagged players are skipped."))
  -- The numbered key, left of the picture.
  local rx=0; local cw=PX-20; local last
  local function heading(label,gap)
    local h=g:CreateFontString(nil,"OVERLAY",T.fonts.Section); h:SetWidth(cw); h:SetJustifyH("LEFT"); h:SetText(self:Text(label)); T.SectionTitle(h); T.Track(h,"label")
    if last then h:SetPoint("TOPLEFT",last,"BOTTOMLEFT",-24,-(gap or 14)) else h:SetPoint("TOPLEFT",g,"TOPLEFT",rx,0) end
    last=h; last.indented=false
  end
  local function item(n,label,body,gap)
    local t=g:CreateFontString(nil,"OVERLAY",T.fonts.Body); t:SetWidth(cw-24); t:SetJustifyH("LEFT"); t:SetText(self:Text(label))
    t:SetPoint("TOPLEFT",last,"BOTTOMLEFT",last.indented and 0 or 24,-(gap or (last.indented and 10 or 8)))
    t.indented=true; last=t
    local m=badge(g,n); m:SetPoint("RIGHT",t,"LEFT",-6,0)
    local b=g:CreateFontString(nil,"OVERLAY",T.fonts.Muted); b:SetWidth(cw-24); b:SetJustifyH("LEFT"); b:SetWordWrap(true); b:SetText(body)
    b:SetPoint("TOPLEFT",t,"BOTTOMLEFT",0,-3); b.indented=true; last=b
  end
  heading("Buttons")
  item(1,"Invite to your party",self:Text("Shown when you can invite: you are solo or lead a party with room."))
  item(2,"Ask to join their group",self:Text("Shown when the game offers it, for players already in a group."))
  item(3,"Ask for a buff",self:Text("Whispers a polite request for a class buff you are missing. Three-minute cooldown per player."))
  item(4,"All players view",self:Text("The people icon switches between players who need your buff and everyone nearby. Gold shows everyone, which invites and requests need."))
  heading("On each row")
  if self:HasTargetedGroupBuffs() then
    item(5,"Needs your buff",self:Text("Click the row or press your BuffTap binding to cast it. The gold row is the one your binding buffs next. Want a separate key for Nearby? Set one under Customization > Binding & sound."))
  else
    item(5,"Buff offers on other classes",self:Text("Your class has no buffs to offer here. Use Nearby to browse players, invite them or request a buff instead."))
  end
  item(6,"Nothing needed",self:Text("A dash means that player already has what you can give."))
  local plates=g:CreateFontString(nil,"OVERLAY",T.fonts.Muted); plates:SetWidth(290); plates:SetJustifyH("LEFT"); plates:SetWordWrap(true)
  plates:SetPoint("TOPLEFT",note,"BOTTOMLEFT",0,-12); plates:SetText(self:Text("Nearby needs friendly nameplates (normally Shift+V). Window size, text and position: Customization > Nearby window."))
  local combat=g:CreateFontString(nil,"OVERLAY",T.fonts.Muted); combat:SetWidth(290); combat:SetJustifyH("LEFT"); combat:SetWordWrap(true)
  combat:SetPoint("TOPLEFT",plates,"BOTTOMLEFT",0,-8); combat:SetText(self:Text("Nearby stays open in combat, so invitations still work. You can change this under Customization > Nearby window."))
end
-- Why Nearby helps, worded for the player's class. Classes without a buff for others still get
-- one-click invites and polite buff requests to Mages, Priests, Druids and Paladins around them.
function B:NearbyPitch(class)
  if GIVERS[class] then
    return self:Text("Nearby lists friendly players around you who are missing your buff: one click or your binding buffs them as they pass. You can also invite them or join their group in one click. Every action needs your click.")
  end
  return self:Text("Even without a buff for others, Nearby helps: invite nearby players to your party in one click, ask to join their group, and politely ask a nearby Mage, Priest, Druid or Paladin for the buff you are missing. Every action needs your click.")
end
function B:ShowNearbyIntro(enableOnApply)
  if A.Combat() then self.Print(self:Text("Nearby mode can be changed after combat.")); return end
  if not self.nearbyIntro then
    local f=CreateFrame("Frame","BuffTapNearbyIntro",UIParent,"BackdropTemplate")
    f:SetSize(INTRO_W,INTRO_H); f:SetFrameStrata("DIALOG"); f:SetToplevel(true); f:EnableMouse(true); f:SetMovable(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    T.Surface(f,"window"); T.Shadow(f,18,.55)
    text(f,T.fonts.Title,24,-22,INTRO_W-48,"Nearby, at a glance")
    f.pitch=text(f,T.fonts.Muted,24,-48,INTRO_W-48,"")
    local guide=CreateFrame("Frame",nil,f); guide:SetPoint("TOPLEFT",24,-84); guide:SetSize(INTRO_W-48,400)
    self:DrawNearbyGuide(guide,INTRO_W-48)
    f.choiceTitle=text(f,T.fonts.Sub,24,-512,INTRO_W-48,"Turn on with")
    f.checks={}
    local specs={
      {"nearbyInvites","Quick party invites (+ and blue arrow)"},
      {"nearbyRequests","Buff request buttons"},
      {"nearbyShowAll","Show all nearby players (invites and requests need this)"},
    }
    for i,spec in ipairs(specs) do
      local c=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate"); c:SetSize(24,24); c:SetPoint("TOPLEFT",22,-542-(i-1)*34)
      if c.Text then c.Text:SetFontObject(T.fonts.Body); c.Text:SetText(B:Text(spec[2])); c.Text:SetWidth(INTRO_W-100); c.Text:SetJustifyH("LEFT") end
      c.key=spec[1]; T.Check(c); f.checks[i]=c
    end
    f.plateNote=text(f,T.fonts.Muted,24,-652,INTRO_W-48,"Nearby uses friendly nameplates (normally Shift+V). Change any of this later on the Nearby page.")
    f.plates=button(f,"Turn on friendly nameplates",484,-648,212,nil,function()
      local _,name=B:FriendlyPlatesState()
      if not A.Combat() and name~="unavailable" then
        if C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar,name,"1") elseif type(SetCVar)=="function" then pcall(SetCVar,name,"1") end
      end
      f.plates:Hide(); f.plateNote:SetWidth(INTRO_W-48)
    end)
    f.apply=button(f,"Turn on Nearby",24,-706,330,"primary",function() B:ApplyNearbyIntro() end)
    f.later=button(f,"Not now",366,-706,330,nil,function() B.db.nearbyIntroSeen=true; f:Hide() end)
    self.nearbyIntro=f
  end
  local f=self.nearbyIntro
  f.enableOnApply=enableOnApply
  f.apply:SetText(self:Text(enableOnApply and "Turn on Nearby" or "Save"))
  f.pitch:SetText(self:NearbyPitch(A.Class("player")))
  -- First time turning Nearby on: everything on except buff requests (they whisper strangers).
  -- Opened later from settings, the boxes show the current settings.
  for _,c in ipairs(f.checks) do
    if enableOnApply then c:SetChecked(c.key~="nearbyRequests") else c:SetChecked(self.db[c.key]==true) end
    T.Check(c)
  end
  -- Offer to switch on friendly nameplates when they are off; Nearby cannot see players without them.
  local off=self:FriendlyPlatesState()==false
  f.plates:SetShown(off); f.plateNote:SetWidth(off and 440 or INTRO_W-48)
  local width,height=UIParent:GetSize()
  if A.Number(width) and A.Number(height) then f:SetScale(math.min(1,(width-32)/INTRO_W,(height-32)/INTRO_H)) end
  f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",0,40); f:Show(); f:Raise()
end
function B:ApplyNearbyIntro()
  if A.Combat() then return end
  local f=self.nearbyIntro
  for _,c in ipairs(f.checks) do self.db[c.key]=c:GetChecked()==true end
  self.db.nearbyIntroSeen=true; f:Hide()
  if f.enableOnApply and not self.db.nearbyEnabled then self:ToggleNearby()
  elseif self.UpdateNearbyWindow then self.nearbySnapshot=nil; self:UpdateNearbyWindow() end
  if self.options and self.options:IsShown() then self:Options() end
end
