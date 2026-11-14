-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
-- An explicit allowlist prevents new buff/class options from becoming shared by accident.
local shared={iconStyle=true,campIconStyle=true,labelPosition=true,showSwipe=true,showOutOfRange=true,optionsPatchDot=true,optionsScale=true,optionsAccentMode=true,optionsAccentColor=true,optionsReduceMotion=true,nearbyScale=true,nearbyRows=true,nearbyWidth=true,nearbyNameVersion=true,nearbyFullNames=true,nearbyOpacity=true,labelSize=true,labelOutline=true,labelGap=true,campTextFont=true,campTextColor=true,campTextSize=true,campTextOutline=true,campTextGap=true,campShowCountdown=true,campShowStacks=true,effectStyle=true,effectColor=true,effectSpeed=true,effectUrgency=true,effectOnce=true,campReminder=true,campSize=true,campOpacity=true,campEffectStyle=true,campEffectColor=true,campEffectSpeed=true,campWarningVersion=true,campTrackBenefits=true,campTrackBag=true,campSound=true,campAnywhere=true,campWarning=true,campX=true,campY=true,nearbyEnabled=true,nearbyBuffing=true,nearbyShowAll=true,nearbyInvites=true,nearbyLocked=true,nearbyOnTop=true,nearbyFont=true,nearbyFontSize=true,nearbyFontOutline=true,nearbyShowLevel=true,nearbyMarkSocial=true,nearbyHideHeader=true,nearbyKeepLine=true,nearbyWhileResting=true,nearbyHoldShort=true,nearbyKeys=true,nearbyManaFloor=true,blockedPlayers=true,blockedGuilds=true,blockIgnored=true,blacklistTargets=true,blacklistInInstances=true,helperDismissMinutes=true,helperThankDelay=true,readyCheckTopUp=true,pauseNotes=true,nearbyX=true,nearbyY=true,showReminder=true,keys=true,size=true,opacity=true,x=true,y=true,glow=true,pulse=true,
  showBuffName=true,showTargetName=true,showTimer=true,showGroupBadge=true,labelFont=true,labelColor=true,
  sound=true,reminderSound=true,alertSoundVersion=true,campAlertSound=true,supplySound=true,soundChannel=true,soundInterval=true,
  pvpProtection=true,pauseResting=true,helperDismiss=true,helperBounce=true,helperThanks=true,helperThankEmote=true,helperThanksResting=true,nearbyRequests=true,nearbyButtonSide=true,requestMessage=true,requestBuffs=true,
  helperQuick=true,helperDiscovery=true,minimap=true,brokerEnabled=true}
local classKeys={"groupContextSettings","situationSettings","seconds","rebuffVersion","buffs","priorities","buffSeconds","group","smartGroup","groupNeed","blessingNeed",
  "salvationVersion","salvationMigration","friendlyTarget","targetSeconds","targetClassBlessings","targetBlessingFallback","targetBlessingClasses","targetBlessingPriorities",
  "blessingGroupOverrides","blessingRaidDefaults","blessingPartyMode","blessingPartyUniform","blessingPartyExcluded","groupBlessingPriorities","blessingAssignments","blessingClasses","buffGroups","buffClasses","buffGroupNeed","buffRoles","blessingRoleChoices","roleGuess","targetBuffs","targetBuffSeconds","targetClasses","raidGroups",
  "consumablesEnabled","consumableFamilies","consumableChoices","consumableSeconds","suppliesEnabled","suppliesChat","suppliesSound","suppliesReadyCheck","supplySettings",
  "weaponReminder","weaponMainHand","weaponOffHand","weaponApply","weaponReplace","weaponChoices","weaponCoatings","weaponSeconds","weaponsPauseResting","consumablesPauseResting","consumablesInstanceOnly","buffPets",
  "helperTracking","helperTreasure","helperTracker","helperCoverage","helperPet","helperHealthstone","helperSoulstone","helperOath","oathAssigned","helperDemon","soulstoneParty","soulstoneRaid","soulstoneAssigned"}
local function clone(value,seen,depth)
  local t=type(value)
  if t=="string" or t=="boolean" or (t=="number" and A.Number(value)) then return value end
  if t~="table" or (depth or 0)>12 then return nil end
  seen=seen or {}; if seen[value] then return nil end; seen[value]=true
  local out={}; for k,v in pairs(value) do
    if type(k)=="string" or (type(k)=="number" and A.Number(k)) then out[k]=clone(v,seen,(depth or 0)+1) end
  end
  seen[value]=nil; return out
end
local classes={WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,SHAMAN=true,MAGE=true,WARLOCK=true,DRUID=true}
local function token()
  local c=A.Call(function() local _,value=UnitClass("player"); return value end)
  return A.Text(c) and classes[c] and c or nil
end
local function cleanName(name)
  if type(name)~="string" then return nil end
  name=name:match("^%s*(.-)%s*$")
  if name=="" or name:find("[%c|]") or strlenutf8(name)>50 then return nil end
  return name
end
-- A profile shown in its class colour with the class in brackets, when every character on it shares one class.
function B:ProfileLabel(name)
  if type(name)~="string" then return name end
  local setups=self.profileDB and type(self.profileDB.global.characterSetups)=="table" and self.profileDB.global.characterSetups[name]
  local class
  if type(setups)=="table" then
    for _,v in pairs(setups) do
      if type(v)=="table" and classes[v.class] then
        if class and class~=v.class then return name end
        class=v.class
      end
    end
  end
  if not class then return name end
  local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  local hex=color and (color.colorStr or (type(color.GenerateHexColor)=="function" and color:GenerateHexColor()))
  local className=LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class:sub(1,1)..class:sub(2):lower()
  return (type(hex)=="string" and ("|c"..hex..name.."|r") or name).." ("..className..")"
end
function B:ProfileNames()
  local out={}; if not self.profileDB then return out end
  for _,name in ipairs(self.profileDB:GetProfiles()) do if cleanName(name) then out[#out+1]=name end end
  table.sort(out); return out
end
function B:ProfileUsers(name)
  local n=0; for _,v in pairs(self.profileDB.sv.profileKeys) do if v==name then n=n+1 end end; return n
end
function B:ProfileSettings(legacy)
  if not self.profileDB then
    if type(BuffTapProfiles)~="table" then BuffTapProfiles={} end
    local sv=BuffTapProfiles
    for _,key in ipairs({"profiles","profileKeys","global"}) do if type(sv[key])~="table" then sv[key]={} end end
    for name,values in pairs(sv.profiles) do if not cleanName(name) or type(values)~="table" then sv.profiles[name]=nil end end
    for char,name in pairs(sv.profileKeys) do if type(char)~="string" or not cleanName(name) then sv.profileKeys[char]=nil end end
    local existing={}; for name in pairs(sv.profiles) do existing[name]=true end
    self.profileDB=LibStub("AceDB-3.0"):New("BuffTapProfiles")
    self.profileDB.RegisterCallback(self,"OnDatabaseShutdown","SaveClassSetup")
    self.profileNeedsRecovery=not existing[self.profileDB:GetCurrentProfile()]
  end
  local db=self.profileDB
  if self.profileLegacy~=legacy then
    local backup=rawget(legacy,"profileMigrationBackup")
    if rawget(legacy,"profilesMigrated")==1 and self.profileNeedsRecovery and type(backup)=="table" then
      for key in pairs(shared) do db.profile[key]=clone(backup[key]) end
    end
    self.profileNeedsRecovery=nil
    if rawget(legacy,"profilesMigrated")~=1 then
      -- A newly visited character keeps an independent profile on upgrade.
      local own=db.keys.char
      local name=cleanName(own) or "Character settings"
      if db:GetCurrentProfile()~=name or self:ProfileUsers(name)>1 or next(db.profile) then
        local base=name; local i=2
        while db.sv.profiles[name] do name=base:sub(1,40).." ("..i..")"; i=i+1 end
      end
      db:SetProfile(name)
      backup={}; for key in pairs(shared) do backup[key]=clone(rawget(legacy,key)); db.profile[key]=clone(rawget(legacy,key)) end
      -- Retain old overlay migration support before Engine applies its defaults.
      if backup.showTimer==nil then db.profile.showTimer=clone(rawget(legacy,"showRemaining")) end
      if backup.showGroupBadge==nil then db.profile.showGroupBadge=clone(rawget(legacy,"showGroupIndicator")) end
      rawset(legacy,"profileMigrationBackup",backup); rawset(legacy,"profilesMigrated",1)
    end
    -- Remove shared raw fields so every subsequent write reaches AceDB.
    for key in pairs(shared) do rawset(legacy,key,nil) end
    setmetatable(legacy,{__index=function(_,key) if shared[key] then return db.profile[key] end end,
      __newindex=function(t,key,value) if shared[key] then db.profile[key]=value else rawset(t,key,value) end end})
    self.profileLegacy=legacy
  end
  return legacy
end
function B:SaveClassSetup()
  if not self.profileDB or not self.db or not A.Text(token()) then return end
  local global=self.profileDB.global
  if type(global.characterSetups)~="table" then global.characterSetups={} end
  local values={}; for _,key in ipairs(classKeys) do values[key]=clone(self.db[key]) end
  local profile=self.profileDB:GetCurrentProfile()
  if type(global.characterSetups[profile])~="table" then global.characterSetups[profile]={} end
  global.characterSetups[profile][self.profileDB.keys.char]={class=token(),profile=profile,settings=values}
end
function B:ClassCopySources(profile)
  local list={}; local class=token(); if not self.profileDB or not class then return list end
  local all=self.profileDB.global.characterSetups
  local setups=type(all)=="table" and all[profile]
  if type(setups)=="table" then for name,v in pairs(setups) do
    if type(name)=="string" and type(v)=="table" and v.class==class and v.profile==profile and type(v.settings)=="table" then list[#list+1]=name end
  end end
  table.sort(list); return list
end
function B:FinishProfileChange()
  self.campPreviewUntil=nil
  if self.ClearAppearanceEdits then self:ClearAppearanceEdits() end
  self.helperThankSeen=nil; self.helperThankBaseline=nil; self.helperThankPending=nil; self.helperThankQueue={}
  self.helperThankRetries=0; self.helperThankRetryPending=nil; self:CancelTimer("thanks-send"); self:CancelTimer("thanks-settle")
  self:InitDB(); self.appearance=nil; self.rankChoiceCache=nil; self.resolveCache=nil; self.coverCache=nil
  self:InvalidateAura(); self:InvalidateRoster()
  -- Rebuild secure bindings immediately while these operations are out of combat.
  self:Refresh(); self:SaveClassSetup()
  if self.UpdateCamping then self:UpdateCamping() end
end
function B:SelectSettingsProfile(name)
  if A.Combat() or not cleanName(name) or not self.profileDB.sv.profiles[name] then return false end
  self:SaveClassSetup(); self.profileDB:SetProfile(name); self:FinishProfileChange(); return true
end
function B:CreateSettingsProfile(name,copyCurrent)
  name=cleanName(name)
  if A.Combat() or not name or self.profileDB.sv.profiles[name] then return false end
  self:SaveClassSetup(); local previous=self.profileDB:GetCurrentProfile()
  self.profileDB:SetProfile(name)
  if copyCurrent then self.profileDB:CopyProfile(previous) end
  self:FinishProfileChange(); return true
end
function B:CopySettingsProfile(source,character)
  if A.Combat() or not cleanName(source) or source==self.profileDB:GetCurrentProfile() or type(self.profileDB.sv.profiles[source])~="table" then return false end
  local values
  if character then
    local class=token(); if not class then return false end
    local all=self.profileDB.global.characterSetups
    local setups=type(all)=="table" and all[source]
    local entry=type(setups)=="table" and setups[character]
    -- Check again here, not just in the options UI. No cross-class imports.
    if type(entry)~="table" or entry.class~=class or entry.profile~=source or type(entry.settings)~="table" then return false end
    values=entry.settings
  end
  self.profileDB:CopyProfile(source)
  if values then for _,key in ipairs(classKeys) do self.db[key]=clone(values[key]) end end
  self:FinishProfileChange(); return true
end
function B:ResetSettingsProfile()
  if A.Combat() then return false end
  self.profileDB:ResetProfile(); self:FinishProfileChange(); return true
end
function B:RenameSettingsProfile(name)
  name=cleanName(name)
  if A.Combat() or not name or self.profileDB.sv.profiles[name] then return false end
  local db=self.profileDB; local old=db:GetCurrentProfile(); self:SaveClassSetup()
  db.sv.profiles[name]=clone(db.profile)
  for char,profile in pairs(db.sv.profileKeys) do if profile==old then db.sv.profileKeys[char]=name end end
  local setups=db.global.characterSetups
  if type(setups)=="table" and type(setups[old])=="table" then
    setups[name]=setups[old]; setups[old]=nil
    for _,entry in pairs(setups[name]) do if type(entry)=="table" then entry.profile=name end end
  end
  db:SetProfile(name); db:DeleteProfile(old); self:FinishProfileChange(); return true
end
-- Any profile except the active one can be deleted. Characters still pointing at it (including
-- deleted characters) are released and go back to their own character profile at their next login.
function B:DeleteSettingsProfile(name)
  if A.Combat() or not cleanName(name) or not self.profileDB.sv.profiles[name] or name==self.profileDB:GetCurrentProfile() then return false end
  local keys=self.profileDB.sv.profileKeys
  for char,profile in pairs(keys) do if profile==name then keys[char]=nil end end
  self.profileDB:DeleteProfile(name,true)
  local setups=self.profileDB.global.characterSetups; if type(setups)=="table" then setups[name]=nil end
  return true
end
-- Reset-all stays local: detach this character instead of resetting a shared profile.
function B:ResetCharacterSettings()
  if A.Combat() then return false end
  self:SaveClassSetup(); BuffTapDB={}; self.blessingPlayers=nil
  self:InitDB(); self:FinishProfileChange(); return true
end

-- Export and import: a plain text string with the shared settings and this class's setup.
-- Import parses the text itself (never loadstring) and accepts only strings, numbers, booleans and tables.
local function encode(value,out,depth)
  local t=type(value)
  if t=="string" then out[#out+1]='"'..value:gsub('[%c"\\]',function(c) return string.format("\\%03d",c:byte()) end)..'"'
  elseif t=="number" then out[#out+1]=string.format("%.10g",value)
  elseif t=="boolean" then out[#out+1]=value and "T" or "F"
  elseif t=="table" and depth<12 then
    out[#out+1]="{"
    local keys={}; for k in pairs(value) do if type(k)=="string" or type(k)=="number" then keys[#keys+1]=k end end
    table.sort(keys,function(a,b) if type(a)~=type(b) then return type(a)=="number" end; return a<b end)
    for _,k in ipairs(keys) do encode(k,out,depth+1); out[#out+1]="="; encode(value[k],out,depth+1); out[#out+1]=";" end
    out[#out+1]="}"
  else out[#out+1]="F" end
end
local function decode(text)
  local pos=1
  local value
  local function fail() error("bad",0) end
  function value(depth)
    if depth>12 then fail() end
    local c=text:sub(pos,pos)
    if c=='"' then
      local close=pos+1; local parts={}
      while true do
        local ch=text:sub(close,close)
        if ch=="" then fail() elseif ch=='"' then break
        elseif ch=="\\" then local code=tonumber(text:sub(close+1,close+3)); if not code or code>255 then fail() end; parts[#parts+1]=string.char(code); close=close+4
        else parts[#parts+1]=ch; close=close+1 end
      end
      pos=close+1; return table.concat(parts)
    elseif c=="T" then pos=pos+1; return true
    elseif c=="F" then pos=pos+1; return false
    elseif c=="{" then
      pos=pos+1; local t={}; local count=0
      while text:sub(pos,pos)~="}" do
        local k=value(depth+1); if type(k)~="string" and type(k)~="number" then fail() end
        if text:sub(pos,pos)~="=" then fail() end; pos=pos+1
        t[k]=value(depth+1)
        if text:sub(pos,pos)~=";" then fail() end; pos=pos+1
        count=count+1; if count>2000 then fail() end
      end
      pos=pos+1; return t
    else
      local num=text:match("^%-?[%d%.]+[eE]?[%-+]?%d*",pos); local n=num and tonumber(num)
      if not n or n~=n or n==math.huge or n==-math.huge then fail() end
      pos=pos+#num; return n
    end
  end
  local ok,result=pcall(value,0)
  if not ok or pos<=#text then return nil end
  return result
end
function B:ExportSettings()
  local data={shared={},class={}}
  for key in pairs(shared) do data.shared[key]=clone(self.db[key]) end
  for _,key in ipairs(classKeys) do data.class[key]=clone(self.db[key]) end
  local out={}; encode(data,out,0)
  return "BuffTap1:"..tostring(token() or "NONE")..":"..table.concat(out)
end
-- Settings tied to one class's spells. Everything else in the class setup applies to any class.
local classSpellKeys={buffs=true,priorities=true,buffSeconds=true,salvationVersion=true,salvationMigration=true,targetClassBlessings=true,
  targetBlessingFallback=true,targetBlessingClasses=true,targetBlessingPriorities=true,blessingGroupOverrides=true,blessingRaidDefaults=true,
  blessingPartyMode=true,blessingPartyUniform=true,blessingPartyExcluded=true,groupBlessingPriorities=true,blessingAssignments=true,
  blessingClasses=true,buffGroups=true,buffClasses=true,buffGroupNeed=true,buffRoles=true,blessingRoleChoices=true,targetBuffs=true,
  targetBuffSeconds=true,targetClasses=true,groupContextSettings=true,situationSettings=true,weaponChoices=true,weaponCoatings=true,helperPet=true,
  helperHealthstone=true,helperSoulstone=true,helperOath=true,oathAssigned=true,helperDemon=true,soulstoneParty=true,soulstoneRaid=true,soulstoneAssigned=true}
function B:ImportSettings(text)
  if A.Combat() or not self.db then return false,self:Text("Not available in combat.") end
  text=type(text)=="string" and text:gsub("[\r\n]",""):match("^%s*(.-)%s*$") or ""
  local class,body=text:match("^BuffTap1:(%u+):(.+)$")
  local data=body and decode(body)
  if type(data)~="table" or type(data.shared)~="table" then return false,self:Text("This is not a BuffTap settings string.") end
  for key in pairs(shared) do if data.shared[key]~=nil then self.db[key]=clone(data.shared[key]) end end
  local sameClass=class==token()
  if type(data.class)=="table" then
    for _,key in ipairs(classKeys) do
      if data.class[key]~=nil and (sameClass or not classSpellKeys[key]) then
        if key=="supplySettings" and not sameClass and type(data.class[key])=="table" then
          -- Supplies mix class items (poisons, stones) with shared ones: from another class,
          -- only food, drink and coatings come over; this class's own entries stay.
          if type(self.db.supplySettings)~="table" then self.db.supplySettings={} end
          for k,v in pairs(data.class[key]) do
            if type(k)=="string" and (k:match("^consumable:") or k:match("^coating:")) then self.db.supplySettings[k]=clone(v) end
          end
        else self.db[key]=clone(data.class[key]) end
      end
    end
  end
  self:FinishProfileChange()
  if sameClass then return true,self:Text("Imported settings.") end
  local name=LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class
  return true,self:Text("Imported settings from a %s. Buff choices, blessings and class tools were skipped because they belong to that class's spells.",name)
end
