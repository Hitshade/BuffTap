-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
-- One-time onboarding: a fresh setup for new players and a single pop-up for existing ones.
-- Nothing changes until the player chooses "Set me up" and applies; "Leave me alone" changes nothing.
local _,B=...
local A=B.API
local T=B.OptionsTheme
local ONBOARDING_VERSION=1
local WIDTH,HEIGHT=560,600

-- Each recommendation knows the old default, so a value still at its default counts as untouched
-- and is pre-selected. A value the player changed is listed but left unselected.
local function recommendations(self)
  local d=self.db; local list={}
  local function add(spec) if spec.current~=spec.target then list[#list+1]=spec end end
  local soundsOn=d.sound==true and d.campSound==true
  add({key="sounds",label="Alert sounds for reminders and camp",current=soundsOn,target=true,untouched=d.sound==false and d.campSound==false,
    apply=function() d.sound=true; d.campSound=true end})
  add({key="chime",label="BuffTap sounds for reminder, supply and camp alerts",current=d.reminderSound=="marimba" and d.supplySound=="glass" and d.campAlertSound=="bell",target=true,
    untouched=(d.reminderSound=="default" or d.reminderSound=="marimba") and (d.supplySound=="default" or d.supplySound=="glass") and (d.campAlertSound=="default" or d.campAlertSound=="bell"),
    apply=function() d.reminderSound="marimba"; d.supplySound="glass"; d.campAlertSound="bell" end})
  add({key="modern",label="Modern square reminder icon instead of Classic",current=false,target=true,untouched=false,optional=true,
    apply=function() d.iconStyle="modern" end})
  if d.iconStyle=="modern" then list[#list]=nil end
  add({key="glow",label="Glow on the reminder icon",current=d.glow==true,target=true,untouched=false,apply=function() d.glow=true end})
  add({key="thanks",label="Solo thanks: thank players who buff you",current=d.helperThanks==true,target=true,untouched=d.helperThanks==false,
    apply=function() d.helperThanks=true end})
  add({key="resting",label="Pause reminders while resting",current=d.pauseResting==true,target=true,untouched=d.pauseResting==false,
    apply=function() d.pauseResting=true end})
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
    if untouched then
      add({key=spec.buff,label=spec.label,current=false,target=true,untouched=true,group=true,apply=function()
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
    -- Fear Ward is a Dwarf priest spell; only offered when it is actually known.
    if known("fear-ward") and unset("fear-ward") then
      groupPreset({buff="fear-ward",field="buffRoles",value=tank,label="Fear Ward on tanks in party and raid"})
      -- Situational (fear-heavy fights), so it is listed but not preselected.
      local last=list[#list]; if last and last.key=="fear-ward" then local apply=last.apply; last.untouched=false; last.optional=true; last.apply=function() d.buffs["fear-ward"]=true; apply() end end
    end
  end
  if class=="PALADIN" then
    local untouched=not self:GroupPreference("blessingAssignments","Party") and not self:GroupPreference("blessingAssignments","Raid") and next(d.blessingClasses or {})==nil
    if untouched then
      local kings=known("bok")
      -- Kings first once it is learned (level 20): it helps every class and scales with gear.
      -- Wisdom stays on the mana-hungry healing classes. Before Kings, Might for physical, Wisdom for mana.
      local plan=kings and {WARRIOR="bok",ROGUE="bok",HUNTER="bok",MAGE="bok",WARLOCK="bok",PALADIN="bok",PRIEST="bow",DRUID="bow",SHAMAN="bow"}
        or {WARRIOR="bom",ROGUE="bom",HUNTER="bom",MAGE="bow",WARLOCK="bow",PRIEST="bow",DRUID="bow",SHAMAN="bow",PALADIN="bow"}
      add({key="blessings",untouched=true,current=false,target=true,group=true,
        label=kings and "Blessing plan: Kings for most classes and tanks; Wisdom for Priests, Druids, Shamans and healers"
          or "Blessing plan: Might for Warriors, Rogues and Hunters and tanks; Wisdom for casters and healers",
        apply=function()
          for _,key in ipairs({"bom","bow"}) do if d.buffs[key]==nil then d.buffs[key]=true end end
          if kings and d.buffs.bok==nil then d.buffs.bok=true end
          for _,context in ipairs({"Party","Raid"}) do
            self:SetBlessingPlanMode(context,0,"class")
            for cls,key in pairs(plan) do self:SetGroupBlessingSettings(cls,nil,key,nil,false,context) end
            for _,cls in ipairs({"WARRIOR","PALADIN","DRUID"}) do self:SetBlessingRoleChoice("TANK",cls,kings and "bok" or "bom",context) end
            for _,cls in ipairs({"PRIEST","PALADIN","DRUID","SHAMAN"}) do self:SetBlessingRoleChoice("HEALER",cls,"bow",context) end
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
      apply=function() d.buffs.flametongue=true; d.buffs.windfury=false end})
    add({key="shamanHealer",exclusive="shaman",optional=true,untouched=false,current=false,target=true,label="I play a healing Shaman: Flametongue Weapon and Water Shield",
      apply=function() d.buffs.flametongue=true; d.buffs.windfury=false; d.buffs["water-shield"]=true end})
  end
  list.classCovered=#list==before
  return list
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
  return self.db and self.db.onboardingVersion~=ONBOARDING_VERSION
end
function B:FinishOnboarding()
  self.db.onboardingVersion=ONBOARDING_VERSION
  -- The setup replaces the old first-use card; its binding tip is on the last page.
  self.db.welcomeSeen=true
  if self.onboarding then self.onboarding:Hide() end
end

local function clearPage(f)
  for _,region in ipairs(f.pageRegions or {}) do region:Hide() end
  f.pageRegions={}
end
local function track(f,...) for _,r in ipairs({...}) do f.pageRegions[#f.pageRegions+1]=r end end

function B:OnboardingWelcomePage()
  local f=self.onboarding; clearPage(f)
  local returning=self.db.welcomeSeen
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,returning and "BuffTap has a few new tricks" or "Welcome to BuffTap"))
  track(f,text(f,T.fonts.Note,24,-152,WIDTH-48,returning
    and "This appears once. BuffTap can switch on a set of recommended settings and point out a few features you may have missed. You will see every change before it applies."
    or "BuffTap reminds you when a buff is missing and gets the cast ready for one click or key press. Let it switch on sensible settings for your class, or leave everything as it is."))
  track(f,button(f,"Set me up (recommended)",24,-240,250,"primary",function() B:OnboardingSettingsPage() end))
  track(f,button(f,"Leave me alone",286,-240,250,nil,function() B:FinishOnboarding() end))
  local others={}
  local current=self.profileDB and self.profileDB:GetCurrentProfile()
  for _,name in ipairs(self.ProfileNames and self:ProfileNames() or {}) do if name~=current then others[#others+1]=name end end
  local y=-286
  if #others>0 then
    track(f,button(f,"Copy settings from another character",24,-282,512,nil,function() B:OnboardingCopyPage() end))
    y=-332
  end
  track(f,text(f,T.fonts.Muted,24,y,WIDTH-48,"Leave me alone changes nothing and will not ask again. Everything stays available in Settings."))
end

-- Alts: copy an existing profile (and, for the same class, its buff and class settings).
function B:OnboardingCopyPage()
  local f=self.onboarding; clearPage(f)
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,"Copy settings from"))
  track(f,text(f,T.fonts.Muted,24,-148,WIDTH-48,"Copies that profile's preferences into this character's profile. Buff and class settings come along when the source is the same class."))
  local current=self.profileDB and self.profileDB:GetCurrentProfile(); local y=-186; local n=0
  for _,name in ipairs(self:ProfileNames()) do
    if name~=current and n<8 then
      n=n+1
      track(f,button(f,name,24,y,512,nil,function()
        local sameClass=B.ClassCopySources and B:ClassCopySources(name)[1] or nil
        if B:CopySettingsProfile(name,sameClass) then B.Print(B:Text("Copied settings from %s.",name)) end
        B:OnboardingFeaturesPage()
      end))
      y=y-38
    end
  end
  track(f,button(f,"Back",24,-540,250,nil,function() B:OnboardingWelcomePage() end))
end

function B:OnboardingSettingsPage()
  local f=self.onboarding; clearPage(f)
  local list=recommendations(self)
  if #list==0 then return self:OnboardingFeaturesPage(true) end
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,"Recommended settings"))
  track(f,text(f,T.fonts.Muted,24,-148,WIDTH-48,"Selected items will change. Settings you changed yourself are listed but not selected."))
  f.choices={}
  local y=-176
  for i,spec in ipairs(list) do
    if i>11 then break end
    local c=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate"); c:SetSize(24,24); c:SetPoint("TOPLEFT",22,y)
    -- The template's own label turns the check into a themed switch.
    local label=B:Text(spec.label)
    if spec.optional then label=label.."  |cff8a8f99"..B:Text("(optional)").."|r"
    elseif not spec.untouched then label=label.."  |cff8a8f99"..B:Text("(you changed this)").."|r" end
    if c.Text then c.Text:SetFontObject(T.fonts.Body); c.Text:SetText(label); c.Text:SetWidth(WIDTH-100); c.Text:SetJustifyH("LEFT") end
    c:SetChecked(spec.untouched==true); T.Check(c)
    -- Exclusive rows (Shaman spec) behave like a radio group.
    if spec.exclusive then c:HookScript("OnClick",function(self)
      if not self:GetChecked() then return end
      for _,other in ipairs(f.choices) do if other.check~=self and other.spec.exclusive==spec.exclusive then other.check:SetChecked(false); T.Check(other.check) end end
    end) end
    track(f,c); f.choices[#f.choices+1]={check=c,spec=spec}
    y=y-30
  end
  if list.classCovered then track(f,text(f,T.fonts.Muted,24,y-6,WIDTH-48,"Your class buffs already match the recommended setup.")) end
  track(f,button(f,"Apply selected",24,-540,250,"primary",function() B:ApplyOnboarding() end))
  track(f,button(f,"Skip",286,-540,250,nil,function() B:OnboardingFeaturesPage() end))
end

function B:ApplyOnboarding()
  if A.Combat() then return end
  local applied=0
  for _,choice in ipairs(self.onboarding.choices or {}) do
    if choice.check:GetChecked() then choice.spec.apply(); applied=applied+1 end
  end
  if applied>0 then
    self:NormalizeVisualOptions(); if self.NormalizeAlerts then self:NormalizeAlerts() end
    if self.NormalizeGroupContexts then self:NormalizeGroupContexts() end
    self.situationDirty=true; self.appearance=nil
    if T.Refresh then T.Refresh() end
    self:RequestRefresh("onboarding",0)
    if self.options and self.options:IsShown() then self:Options() end
    self.Print(self:Text("Applied %d recommended settings to profile %s.",applied,self.profileDB and self.profileDB:GetCurrentProfile() or "?"))
  end
  self:OnboardingFeaturesPage()
end

function B:OnboardingFeaturesPage()
  local f=self.onboarding; clearPage(f)
  track(f,text(f,T.fonts.Title,24,-120,WIDTH-48,"Worth knowing"))
  -- The binding is the heart of BuffTap, so it can be changed right here.
  track(f,button(f,"Change binding",396,-118,140,nil,function() B:CaptureBinding() end))
  -- Reminder look: icon style, size, text, glow and effects all live in Customization.
  track(f,button(f,"Customize reminders",250,-118,140,nil,function()
    B:Options(); if B.options and B.options.selectTab then B.options.selectTab(8) end
    if B.SetAppearanceView then B:SetAppearanceView("buff") end
  end))
  local y=-156
  local class=A.Class("player")
  local binding=#self.db.keys>0 and table.concat(self.db.keys,", ") or self:Text("none — click the reminder")
  local lines={
    self:Text("How to buff: when a reminder appears, press your binding (%s) or click the icon.",binding),
    "Nearby: buff players passing by, invite them, request to join their group, or whisper for a buff you are missing.",
    "Roles: give a buff to tanks or healers only, like Thorns on the tank. BuffTap reads group roles; use Mark target role or Guess tanks from stance on the Groups page.",
    "Camp tray: set up a campfire and sleeping bag in one place.",
    "Customize look: Classic or Modern square icon, label placement and a rebuff countdown.",
    "Right-click the minimap icon for quick controls and pause.",
  }
  if class=="HUNTER" or class=="WARLOCK" or class=="PALADIN" then
    table.insert(lines,#lines,"Class readiness (Helpers page): pet, Healthstone, Soulstone or Oath reminders for your class.")
  end
  for _,line in ipairs(lines) do
    local fs=text(f,T.fonts.Note,40,y,WIDTH-64,line); track(f,fs)
    local dot=text(f,T.fonts.Note,24,y,12,"•"); track(f,dot)
    y=y-(fs:GetStringHeight() or 16)-12
  end
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
    T.Variant(close,"danger"); close.glyph=close:CreateTexture(nil,"ARTWORK"); close.glyph:SetPoint("CENTER"); T.Glyph(close.glyph,"close",14,.80,.82,.86); close:SetScript("OnClick",function() B:FinishOnboarding() end)
    close:SetScript("OnEnter",function(s) T.Tooltip(s,B:Text("Leave me alone"),B:Text("Leave me alone changes nothing and will not ask again. Everything stays available in Settings.")) end)
    close:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.onboarding=f; f.pageRegions={}
  end
  if self.HideOptionsPopups then self:HideOptionsPopups() end
  local width,height=UIParent:GetSize()
  if A.Number(width) and A.Number(height) then self.onboarding:SetScale(math.min(1,(width-32)/WIDTH,(height-32)/HEIGHT)) end
  self.onboarding:ClearAllPoints(); self.onboarding:SetPoint("CENTER",UIParent,"CENTER",0,40)
  self:OnboardingWelcomePage(); self.onboarding:Show(); self.onboarding:Raise()
end

-- Nearby introduction: a drawn mock of the window with callouts, then three quick choices.
-- Shown the first time Nearby is turned on (from anywhere) and from the Nearby page's "How it works".
local INTRO_W,INTRO_H=600,560
local CLASS_ICONS="Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local function swatch(parent,layer,r,g,b,a) local t=parent:CreateTexture(nil,layer); t:SetColorTexture(r,g,b,a); return t end
local drawGlyph
local function mockRow(parent,y,class,name,gutter,buffIcon)
  local row=CreateFrame("Frame",nil,parent); row:SetSize(232,20); row:SetPoint("TOPLEFT",34,y)
  swatch(row,"BACKGROUND",.055,.075,.095,.6):SetAllPoints()
  local icon=row:CreateTexture(nil,"ARTWORK"); icon:SetSize(14,14); icon:SetPoint("LEFT",5,0); icon:SetTexture(CLASS_ICONS)
  local c=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]; if c then icon:SetTexCoord(c[1],c[2],c[3],c[4]) end
  local text=row:CreateFontString(nil,"OVERLAY",T.fonts.Small); text:SetPoint("LEFT",24,0); text:SetText(name)
  local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]; if color then text:SetTextColor(color.r,color.g,color.b) end
  -- Like the real window: a buff icon when that player needs your buff, otherwise a dash.
  if buffIcon then local b=row:CreateTexture(nil,"ARTWORK"); b:SetSize(16,16); b:SetPoint("RIGHT",-4,0); b:SetTexture(buffIcon); b:SetTexCoord(.08,.92,.08,.92)
  else local dash=row:CreateFontString(nil,"OVERLAY",T.fonts.Small); dash:SetPoint("RIGHT",-8,0); dash:SetText("-"); dash:SetTextColor(.55,.62,.59) end
  local tile=CreateFrame("Frame",nil,parent); tile:SetSize(20,20); tile:SetPoint("RIGHT",row,"LEFT",-4,0)
  drawGlyph(tile,gutter)
  return row,tile
end
-- The gutter tiles exactly as the real window draws them: gold +, blue arrow, buff icon tile.
function drawGlyph(tile,gutter)
  swatch(tile,"BACKGROUND",.055,.075,.095,.85):SetAllPoints()
  if gutter=="invite" then
    local h=swatch(tile,"OVERLAY",1,.82,0,1); h:SetSize(8,2); h:SetPoint("CENTER")
    local v=swatch(tile,"OVERLAY",1,.82,0,1); v:SetSize(2,8); v:SetPoint("CENTER")
  elseif gutter=="join" then
    for _,p in ipairs({{-3,0,8,3},{2,0,2,10},{4,0,2,6},{6,0,2,2}}) do local t=swatch(tile,"OVERLAY",.35,.75,1,1); t:SetSize(p[3],p[4]); t:SetPoint("CENTER",p[1],p[2]) end
  elseif gutter=="request" then
    swatch(tile,"BORDER",.40,.82,.90,.55):SetAllPoints()
    local t=tile:CreateTexture(nil,"ARTWORK"); t:SetPoint("TOPLEFT",1,-1); t:SetPoint("BOTTOMRIGHT",-1,1); t:SetTexture(135932); t:SetTexCoord(.08,.92,.08,.92)
  end
end
local function callout(parent,anchor,y,glyph,title,body)
  local line=swatch(parent,"ARTWORK",1,1,1,.18); line:SetHeight(1)
  line:SetPoint("LEFT",anchor,"RIGHT",4,0); line:SetPoint("RIGHT",parent,"TOPLEFT",318,y-8)
  local g=CreateFrame("Frame",nil,parent); g:SetSize(20,20); g:SetPoint("TOPLEFT",324,y+3); drawGlyph(g,glyph)
  local t=parent:CreateFontString(nil,"OVERLAY",T.fonts.Body); t:SetPoint("TOPLEFT",350,y); t:SetWidth(INTRO_W-374); t:SetJustifyH("LEFT"); t:SetText(B:Text(title))
  local b=parent:CreateFontString(nil,"OVERLAY",T.fonts.Muted); b:SetPoint("TOPLEFT",t,"BOTTOMLEFT",0,-2); b:SetWidth(INTRO_W-374); b:SetJustifyH("LEFT"); b:SetWordWrap(true); b:SetText(B:Text(body))
end
-- Why Nearby helps, worded for the player's class. Classes without a buff for others still get
-- one-click invites and polite buff requests to Mages, Priests, Druids and Paladins around them.
local GIVERS={MAGE=true,PRIEST=true,DRUID=true,PALADIN=true}
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
    -- The mock window.
    -- Pretend players (names from the developer), drawn like the real window: header with count, gutter tiles, class rows.
    local mock=CreateFrame("Frame",nil,f,"BackdropTemplate"); mock:SetSize(276,166); mock:SetPoint("TOPLEFT",24,-84); T.Surface(mock,"card")
    local headBar=swatch(mock,"BORDER",.20,.14,.10,.85); headBar:SetPoint("TOPLEFT",34,-6); headBar:SetPoint("TOPRIGHT",-8,-6); headBar:SetHeight(20)
    local head=mock:CreateFontString(nil,"OVERLAY",T.fonts.Small); head:SetPoint("LEFT",headBar,"LEFT",6,0); head:SetText("BuffTap"); head:SetTextColor(1,.82,0)
    local count=mock:CreateFontString(nil,"OVERLAY",T.fonts.Small); count:SetPoint("RIGHT",headBar,"RIGHT",-6,0); count:SetText("1/5")
    local _,t1=mockRow(mock,-30,"WARRIOR","Dontstop Bleedin","invite",136078)
    local _,t2=mockRow(mock,-56,"PALADIN","Everybuff Youtake","join",nil)
    local _,t3=mockRow(mock,-82,"MAGE","Poursome Manaonme","request",nil)
    mockRow(mock,-108,"HUNTER","Gland Downunder","invite",nil)
    mockRow(mock,-134,"ROGUE","Smooth Criminelf","invite",nil)
    callout(f,t1,-92,"invite","Invite to your party","Shown when you can invite: you are solo or lead a party with room.")
    callout(f,t2,-150,"join","Ask to join their group","Shown when the game offers it, for players already in a group.")
    callout(f,t3,-208,"request","Ask for a buff","Whispers a polite request for a class buff you are missing. Three-minute cooldown per player.")
    text(f,T.fonts.Muted,24,-262,INTRO_W-48,"A buff icon at the end of a row (like Mark of the Wild above) means that player needs your buff: click the row or press your binding to cast. A dash means nothing is needed.")
    f.choiceTitle=text(f,T.fonts.Sub,24,-312,INTRO_W-48,"Turn on with")
    f.checks={}
    local specs={
      {"nearbyInvites","Quick party invites (+ and blue arrow)"},
      {"nearbyRequests","Buff request buttons"},
      {"nearbyShowAll","Show all nearby players, not only those who need a buff (invites and requests need this)"},
    }
    for i,spec in ipairs(specs) do
      local c=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate"); c:SetSize(24,24); c:SetPoint("TOPLEFT",22,-342-(i-1)*34)
      if c.Text then c.Text:SetFontObject(T.fonts.Body); c.Text:SetText(B:Text(spec[2])); c.Text:SetWidth(INTRO_W-100); c.Text:SetJustifyH("LEFT") end
      c.key=spec[1]; T.Check(c); f.checks[i]=c
    end
    f.plateNote=text(f,T.fonts.Muted,24,-452,INTRO_W-48,"Nearby uses friendly nameplates (normally Shift+V). Change any of this later on the Nearby page.")
    f.plates=button(f,"Turn on friendly nameplates",364,-448,212,nil,function()
      local _,name=B:FriendlyPlatesState()
      if not A.Combat() and name~="unavailable" then
        if C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar,name,"1") elseif type(SetCVar)=="function" then pcall(SetCVar,name,"1") end
      end
      f.plates:Hide(); f.plateNote:SetWidth(INTRO_W-48)
    end)
    f.apply=button(f,"Turn on Nearby",24,-506,270,"primary",function() B:ApplyNearbyIntro() end)
    f.later=button(f,"Not now",306,-506,270,nil,function() B.db.nearbyIntroSeen=true; f:Hide() end)
    self.nearbyIntro=f
  end
  local f=self.nearbyIntro
  f.enableOnApply=enableOnApply
  f.apply:SetText(self:Text(enableOnApply and "Turn on Nearby" or "Save"))
  f.pitch:SetText(self:NearbyPitch(A.Class("player")))
  for _,c in ipairs(f.checks) do c:SetChecked(enableOnApply and true or self.db[c.key]==true); T.Check(c) end
  -- Offer to switch on friendly nameplates when they are off; Nearby cannot see players without them.
  local off=self:FriendlyPlatesState()==false
  f.plates:SetShown(off); f.plateNote:SetWidth(off and 320 or INTRO_W-48)
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
