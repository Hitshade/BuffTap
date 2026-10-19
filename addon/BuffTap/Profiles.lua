-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
-- An explicit allowlist prevents new buff/class options from becoming shared by accident.
local shared={showReminder=true,keys=true,size=true,opacity=true,x=true,y=true,glow=true,pulse=true,
  showBuffName=true,showTargetName=true,showTimer=true,showGroupBadge=true,labelFont=true,labelColor=true,
  sound=true,reminderSound=true,supplySound=true,soundChannel=true,soundInterval=true,
  pauseResting=true,helperDismiss=true,helperBounce=true,helperThanks=true,helperThankEmote=true,
  helperQuick=true,helperDiscovery=true,minimap=true,brokerEnabled=true}
local classKeys={"seconds","rebuffVersion","buffs","priorities","buffSeconds","group","smartGroup","groupNeed","blessingNeed",
  "salvationVersion","salvationMigration","friendlyTarget","targetSeconds","targetClassBlessings","targetBlessingFallback","targetBlessingClasses","targetBlessingPriorities",
  "blessingGroupOverrides","blessingRaidDefaults","blessingPartyMode","blessingPartyUniform","blessingPartyExcluded","salvationGroup","groupBlessingPriorities","blessingAssignments","blessingClasses","buffGroups","buffClasses","buffGroupNeed","targetBuffs","targetBuffSeconds","raidGroups",
  "consumablesEnabled","consumableFamilies","consumableChoices","consumableSeconds","suppliesEnabled","suppliesChat","suppliesSound","suppliesReadyCheck","supplySettings",
  "weaponReminder","weaponMainHand","weaponOffHand","weaponApply","weaponReplace","weaponChoices","weaponCoatings","weaponSeconds",
  "helperTracking","helperTreasure","helperTracker","helperCoverage","helperPet","helperHealthstone","helperSoulstone","helperDemon","soulstoneParty","soulstoneRaid","soulstoneAssigned"}
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
  self:InitDB(); self.appearance=nil; self.rankChoiceCache=nil; self.resolveCache=nil; self.coverCache=nil
  self:InvalidateAura(); self:InvalidateRoster()
  -- Rebuild secure bindings immediately while these operations are out of combat.
  self:Refresh(); self:SaveClassSetup()
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
function B:DeleteSettingsProfile(name)
  if A.Combat() or not cleanName(name) or not self.profileDB.sv.profiles[name] or name==self.profileDB:GetCurrentProfile() or self:ProfileUsers(name)>0 then return false end
  self.profileDB:DeleteProfile(name)
  local setups=self.profileDB.global.characterSetups; if type(setups)=="table" then setups[name]=nil end
  return true
end
-- Reset-all stays local: detach this character instead of resetting a shared profile.
function B:ResetCharacterSettings()
  if A.Combat() then return false end
  self:SaveClassSetup(); BuffTapDB={}; self.blessingPlayers=nil
  self:InitDB(); self:FinishProfileChange(); return true
end
