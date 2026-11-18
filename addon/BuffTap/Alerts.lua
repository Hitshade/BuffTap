-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
local _,B=...
local A=B.API
-- SoundKit IDs cross-checked against Forever 1.60.1.70009 SoundKit.csv.
-- Additional choices require the client's named constant; no guessed assets.
local SOUNDS="Interface\\AddOns\\BuffTap\\Media\\Sounds\\"
-- BuffTap's own alert sounds: original recordings shipped with the addon (MPL-2.0 like the rest of BuffTap).
local bundled={
  {key="marimba",name="Marimba rise",file=SOUNDS.."BuffTapMarimba.ogg"},
  {key="glass",name="Glass chime",file=SOUNDS.."BuffTapGlass.ogg"},
  {key="bell",name="Warm bell",file=SOUNDS.."BuffTapBell.ogg"},
  {key="harp",name="Harp arpeggio",file=SOUNDS.."BuffTapHarp.ogg"},
  {key="cleanse",name="Cleansing wash",file=SOUNDS.."BuffTapCleanse.ogg"},
  {key="hello",name="Happy hello",file=SOUNDS.."BuffTapHello.ogg"},
  {key="twinbells",name="Twin bells",file=SOUNDS.."BuffTapTwinBells.ogg"},
  {key="playful",name="Playful marimba",file=SOUNDS.."BuffTapPlayful.ogg"},
  {key="crystalchime",name="Crystal chime",file=SOUNDS.."BuffTapCrystalChime.ogg"},
  {key="elvenharp",name="Elven harp",file=SOUNDS.."BuffTapElvenHarp.ogg"},
  {key="holylight",name="Holy light",file=SOUNDS.."BuffTapHolyLight.ogg"},
  {key="fairyping",name="Fairy ping",file=SOUNDS.."BuffTapFairyPing.ogg"},
  {key="celestiallift",name="Celestial lift",file=SOUNDS.."BuffTapCelestialLift.ogg"},
  {key="softglow",name="Soft glow",file=SOUNDS.."BuffTapSoftGlow.ogg"},
  {key="moonlitbells",name="Moonlit bells",file=SOUNDS.."BuffTapMoonlitBells.ogg"},
  {key="gentleharp",name="Gentle harp",file=SOUNDS.."BuffTapGentleHarp.ogg"},
  {key="warmwelcome",name="Warm welcome",file=SOUNDS.."BuffTapWarmWelcome.ogg"},
  {key="lullabyping",name="Lullaby ping",file=SOUNDS.."BuffTapLullabyPing.ogg"},
}
-- Internal beta3 choices were replaced by the owner's recordings.
local retiredBetaSounds={softpluck="gentleharp",amber="crystalchime",ripple="holylight",wood="elvenharp",silver="moonlitbells"}
local definitions={
  {key="default",name="Ding (game)",id=12867},
  {key="ready",name="Ready check",constant="READY_CHECK"},
  {key="raid",name="Raid warning",constant="RAID_WARNING"},
  {key="click",name="Interface click",constant="IG_MAINMENU_OPTION_CHECKBOX_ON"},
  {key="whisper",name="Whisper ping",constant="TELL_MESSAGE"},
  {key="alarm1",name="Alarm clock 1",constant="ALARM_CLOCK_WARNING_1"},
  {key="alarm3",name="Alarm clock 3",constant="ALARM_CLOCK_WARNING_3"},
  {key="quest",name="Quest complete",constant="IG_QUEST_LIST_COMPLETE"},
}
local function sharedMedia()
  if not LibStub then return end
  local ok,lib=pcall(function() return LibStub("LibSharedMedia-3.0",true) end)
  if ok and type(lib)=="table" and type(lib.HashTable)=="function" then return lib end
end
-- Offer BuffTap's sounds to every addon that uses SharedMedia (only when another addon has loaded the library).
function B:RegisterSharedSounds()
  local lib=sharedMedia(); if not lib or self.sharedSoundsRegistered or type(lib.Register)~="function" then return end
  for _,sound in ipairs(bundled) do pcall(lib.Register,lib,"sound","BuffTap: "..sound.name,sound.file) end
  self.sharedSoundsRegistered=true
end
local function mediaTable()
  local lib=sharedMedia()
  if not lib then return end
  -- HashTable uses the explicit selection, unlike Fetch which honors global overrides.
  local ok,media=pcall(lib.HashTable,lib,"sound")
  if ok and type(media)=="table" then return media end
end
local function playable(value)
  return (type(value)=="string" and value~="") or (A.Number(value) and value>0)
end
function B:SoundChoices()
  self:RegisterSharedSounds()
  local choices={}
  for _,sound in ipairs(bundled) do choices[#choices+1]={key=sound.key,name=sound.name,file=sound.file,source="BuffTap sounds"} end
  for _,definition in ipairs(definitions) do
    local id=definition.id or (type(SOUNDKIT)=="table" and SOUNDKIT[definition.constant])
    if A.Number(id) and id>0 then choices[#choices+1]={key=definition.key,name=definition.name,id=id,source="Game sounds"} end
  end
  local media=mediaTable()
  local names={}
  if media then for name,value in pairs(media) do
    if type(name)=="string" and name~="None" and playable(value) then names[#names+1]=name end
  end end
  table.sort(names)
  -- BuffTap's own sounds are listed once, above; skip their SharedMedia copies.
  local own={}; for _,sound in ipairs(bundled) do own["BuffTap: "..sound.name]=true end
  for _,name in ipairs(names) do if not own[name] then choices[#choices+1]={key="lsm:"..name,name=name,source="SharedMedia"} end end
  local preserved={}
  for _,field in ipairs({"reminderSound","supplySound","campAlertSound","cleanseSound","socialSound"}) do preserved[#preserved+1]=self.db and self.db[field] end
  local settings=self.db and self.db.buffAlerts
  for _,context in ipairs({"personal","party","raid"}) do
    local map=type(settings)=="table" and settings[context]
    for _,record in pairs(type(map)=="table" and map or {}) do
      if type(record)=="table" and type(record.sound)=="string" then preserved[#preserved+1]=record.sound end
    end
  end
  for _,key in ipairs(preserved) do
    if type(key)=="string" and key:sub(1,4)=="lsm:" and #key>4 and #key<=512 then
      local found=false; for _,choice in ipairs(choices) do if choice.key==key then found=true; break end end
      if not found then
        local unavailable=not media or not playable(media[key:sub(5)])
        choices[#choices+1]={key=key,name=key:sub(5)..(unavailable and " (unavailable; using default)" or ""),source="SharedMedia"}
      end
    end
  end
  return choices
end
function B:NormalizeAlerts()
  -- 1.19.1: the BuffTap marimba becomes the reminder default; the old default (Ding) stays available.
  local version=A.Number(self.db.alertSoundVersion) and self.db.alertSoundVersion or 0
  if version<1 then
    if self.db.reminderSound==nil or self.db.reminderSound=="default" then self.db.reminderSound="marimba" end
  end
  -- 1.19.2: supply and camp alerts also default to BuffTap sounds (Glass chime and Warm bell).
  if version<2 then
    if self.db.supplySound==nil or self.db.supplySound=="default" then self.db.supplySound="glass" end
    if self.db.campAlertSound==nil or self.db.campAlertSound=="default" then self.db.campAlertSound="bell" end
  end
  -- 1.21.0: cleansing gets its own new sound; early beta builds defaulted to Harp.
  if version<3 and (self.db.cleanseSound==nil or self.db.cleanseSound=="harp") then self.db.cleanseSound="cleanse" end
  -- 1.22.0: the cleanse alert becomes Warm bell for everyone, once; later choices are kept.
  if version<4 then self.db.cleanseSound="bell" end
  self.db.alertSoundVersion=4
  self:RegisterSharedSounds()
  local valid={}; for _,sound in ipairs(bundled) do valid[sound.key]=true end
  for _,definition in ipairs(definitions) do
    local id=definition.id or (type(SOUNDKIT)=="table" and SOUNDKIT[definition.constant])
    if A.Number(id) and id>0 then valid[definition.key]=true end
  end
  for _,key in ipairs({"reminderSound","supplySound","campAlertSound","cleanseSound","socialSound"}) do
    local value=self.db[key]
    if retiredBetaSounds[value] then value=retiredBetaSounds[value]; self.db[key]=value end
    local shared=type(value)=="string" and value:sub(1,4)=="lsm:" and #value>4 and #value<=512
    -- Unknown or retired choices fall back to the BuffTap default for that alert.
    -- 1.22.0 defaults (new characters): Cleansing wash, Glass chime, Harp arpeggio, Warm bell, Happy hello.
    if not valid[value] and not shared then self.db[key]=key=="campAlertSound" and "harp" or key=="cleanseSound" and "bell" or key=="socialSound" and "hello" or key=="supplySound" and "glass" or "cleanse" end
  end
  if self.db.soundChannel~="Master" and self.db.soundChannel~="SFX" then self.db.soundChannel="Master" end
  local interval=self.db.soundInterval
  if not A.Number(interval) then interval=5 end
  self.db.soundInterval=math.max(5,math.min(60,math.floor(interval)))
  if type(self.db.cleanseSoundEnabled)~="boolean" then self.db.cleanseSoundEnabled=self.db.sound==true end
  if type(self.db.socialSoundEnabled)~="boolean" then self.db.socialSoundEnabled=true end
  self:NormalizeBuffAlerts()
end
-- Character/class settings. Missing records inherit the normal reminder sound.
-- Optional per-buff sounds inherit the category default when unset.
function B:NormalizeBuffAlerts()
  local source=type(self.db.buffAlerts)=="table" and self.db.buffAlerts or {}
  local out={version=1,personal={},party={},raid={}}
  local sounds={}; for _,choice in ipairs(self:SoundChoices()) do sounds[choice.key]=true end
  local class=A.Class("player")
  for _,context in ipairs({"personal","party","raid"}) do
    for key,value in pairs(type(source[context])=="table" and source[context] or {}) do
      local def=type(key)=="string" and self:FindBuff(key)
      if def and (not class or def.class==class) and not def.singleKey and type(value)=="table" then
        local record={}
        if type(value.enabled)=="boolean" then record.enabled=value.enabled end
        local sound=value.sound
        sound=retiredBetaSounds[sound] or sound
        if type(sound)=="string" and #sound<=512 and (sounds[sound] or (sound:sub(1,4)=="lsm:" and #sound>4 and not sound:find("[%c|]"))) then record.sound=sound end
        if next(record) then out[context][key]=record end
      end
    end
  end
  self.db.buffAlerts=out
end
function B:BuffAlertKey(def)
  if type(def)=="string" then def=self:FindBuff(def) end
  return def and (def.singleKey or def.key)
end
function B:BuffAlertEnabled(context,def)
  local key=self:BuffAlertKey(def)
  local root=self.db and self.db.buffAlerts
  local record=root and root[context] and root[context][key]
  return not (type(record)=="table" and record.enabled==false)
end
function B:SetBuffAlertEnabled(context,def,enabled)
  if A.Combat() or not self.db or (context~="personal" and context~="party" and context~="raid") or type(enabled)~="boolean" then return false end
  local key=self:BuffAlertKey(def); local buff=key and self:FindBuff(key)
  if not buff or buff.class~=A.Class("player") then return false end
  self:NormalizeBuffAlerts()
  local map=self.db.buffAlerts[context]; local record=map[key] or {}
  record.enabled=enabled; map[key]=record
  return true
end
function B:SetBuffAlertSound(context,def,sound)
  if A.Combat() or not self.db or (context~="personal" and context~="party" and context~="raid") then return false end
  local key=self:BuffAlertKey(def); local buff=key and self:FindBuff(key)
  if not buff or buff.class~=A.Class("player") then return false end
  if sound~=nil then
    local found=false; for _,choice in ipairs(self:SoundChoices()) do if choice.key==sound then found=true; break end end
    if not found then return false end
  end
  self:NormalizeBuffAlerts()
  local map=self.db.buffAlerts[context]; local record=map[key] or {}; record.sound=sound
  map[key]=next(record) and record or nil
  return true
end
function B:BuffAlertSound(context,def)
  local key=self:BuffAlertKey(def); local root=self.db and self.db.buffAlerts
  local record=root and root[context] and root[context][key]
  return type(record)=="table" and record.sound or nil
end
function B:SoundChoiceName(key)
  for _,choice in ipairs(self:SoundChoices()) do if choice.key==key then return self:Text(choice.name) end end
  return self:Text("Unavailable sound")
end
function B:BuffAlertContext(action)
  if not action or (action.source and action.source~="spell") or action.nearby or action.quickTarget then return end
  if not self:FindBuff(action.key) then return end
  if action.groupCast then return self:ActiveGroupContext()=="Raid" and "raid" or "party" end
  if action.target=="player" or action.target=="pet" then return "personal" end
  if type(action.target)=="string" and (action.target:match("^party") or action.target:match("^raid")) then
    return self:ActiveGroupContext()=="Raid" and "raid" or "party"
  end
end
function B:BuffAlertAllowed(action)
  local context=self:BuffAlertContext(action)
  return not context or self:BuffAlertEnabled(context,action.key)
end
function B:BuffAlertTooltip(context,def)
  local scope=self:Text(context=="party" and "party" or context=="raid" and "raid" or "personal")
  local state=self:BuffAlertEnabled(context,def) and self:Text("Sound enabled for this buff.") or self:Text("Sound muted for this buff.")
  if not self.db.sound then state=state.."\n"..self:Text("The Reminder sound category is off.") end
  local detail=context=="personal" and self:Text("Controls your personal reminder for this buff. Party and Raid buffing have separate sound switches.") or self:Text("Controls %s buffing reminders for this buff and its group version.",scope)
  return state.."\n"..detail.."\n"..self:Text("Visual reminders and bindings remain active.")
    .."\n"..(self:BuffAlertSound(context,def) and self:Text("Sound: %s",self:SoundChoiceName(self:BuffAlertSound(context,def))) or self:Text("Default: %s",self:SoundChoiceName(self.db.reminderSound)))
    .."\n"..self:Text("Left-click to mute or unmute. Right-click for sound settings. Resting pauses and silent buffing queues still apply.")
end
function B:BuffAlertMuteReason(action)
  local context=self:BuffAlertContext(action)
  if context and not self:BuffAlertEnabled(context,action.key) then return self:Text("Sound muted for this buff's %s reminders.",self:Text(context)) end
  if action and action.source=="smartshift" then return self:Text("SmartShift returns are always silent.") end
  if not self:ActionAlertEnabled(action) then return self:Text("This reminder sound category is turned off.") end
end
local categorySoundFields={reminder="sound",supply="suppliesSound",camp="campSound",cleanse="cleanseSoundEnabled",social="socialSoundEnabled"}
function B:AlertCategoryEnabled(kind)
  local key=categorySoundFields[kind or "reminder"] or "sound"
  return self.db and self.db[key]==true
end
function B:SetAlertCategoryEnabled(kind,enabled)
  local key=categorySoundFields[kind]
  if A.Combat() or not self.db or not key or type(enabled)~="boolean" then return false end
  self.db[key]=enabled; return true
end
function B:ActionAlertEnabled(action)
  return self:AlertCategoryEnabled(action and action.source=="cleanse" and "cleanse" or "reminder")
end
function B:PlayAlert(kind,preview,previewSound)
  if not self.db then return false end
  -- The friend/guild alert has its own switch and pacing (Nearby), and plays in cities and inns.
  if kind=="reminder" and not preview and not self:BuffAlertAllowed(self.action) then return false end
  local social=kind=="social"
  if not preview and not social and self.ReminderPauseReason and self:ReminderPauseReason() then return false end
  -- A temporarily unavailable resting read must not let an automatic sound
  -- escape an enabled pause. Explicit previews and opt-in social alerts differ.
  if not preview and not social and self.db.pauseResting and A.Call(IsResting)~=false then return false end
  if not preview and not self:AlertCategoryEnabled(kind) then return false end
  local now=GetTime()
  if not preview and not social and self.lastAlertSound and now-self.lastAlertSound<self.db.soundInterval then return false end
  local selected=self.db[kind=="supply" and "supplySound" or kind=="camp" and "campAlertSound" or kind=="cleanse" and "cleanseSound" or social and "socialSound" or "reminderSound"]
  if preview and previewSound then selected=previewSound
  elseif kind=="reminder" and not preview then
    local context=self:BuffAlertContext(self.action)
    if context then selected=self:BuffAlertSound(context,self.action.key) or selected end
  end
  local player,value=PlaySound,12867
  if type(selected)=="string" and selected:sub(1,4)=="lsm:" then
    local media=mediaTable(); local sound=media and media[selected:sub(5)]
    if playable(sound) and type(PlaySoundFile)=="function" then player,value=PlaySoundFile,sound end
  else
    for _,sound in ipairs(bundled) do if sound.key==selected and type(PlaySoundFile)=="function" then player,value=PlaySoundFile,sound.file end end
    for _,definition in ipairs(definitions) do if definition.key==selected then
      local id=definition.id or (type(SOUNDKIT)=="table" and SOUNDKIT[definition.constant])
      if A.Number(id) and id>0 then value=id end
      break
    end end
  end
  if type(player)~="function" then return false end
  local ok,result=pcall(player,value,self.db.soundChannel)
  if (not ok or result==false) and player~=PlaySound and type(PlaySound)=="function" then
    ok,result=pcall(PlaySound,12867,self.db.soundChannel)
  end
  if not ok or result==false then return false end
  self.lastAlertInfo={kind=kind,preview=preview==true,at=now,
    resting=A.Call(IsResting),pauseResting=self.db.pauseResting==true}
  if not preview and not social then self.lastAlertSound=now end
  return true
end
function B:FriendlyStatus()
  if not self.db or not self.db.enabled then return self:Text("BuffTap is disabled.") end
  if A.Combat() then return self:Text("Reminders pause during combat.") end
  if self.pauseUntil and GetTime()<self.pauseUntil then return self:Text("Reminders paused: %d min remaining",math.ceil((self.pauseUntil-GetTime())/60)) end
  if self.editModeActive then return self:Text("Editing reminder position.") end
  if self.loadingUntil and GetTime()<self.loadingUntil then return self:Text("Waiting a moment after loading.") end
  if self.action then
    local a=self.action
    if a.manual then return self:Text("Manual application: %s",a.name or "?") end
    return self:Text("Ready: %s - %s",a.name or "?",a.targetName or a.target or "?")
  end
  if self.reason=="resting" then return self:Text("Reminders pause in cities and inns.") end
  if self.reason=="mounted" then return self:Text("Reminders pause while mounted.") end
  if self.reason=="dead / ghost / player unavailable" then return self:Text("Player is dead, a ghost, or unavailable.") end
  if self.reason=="not enough mana" then
    local class=A.Class("player")
    return self:Text((class=="WARRIOR" or class=="ROGUE") and "Not enough power to buff." or "Not enough mana to buff.")
  end
  if self.reason=="waiting for cooldown" then return self:Text("Waiting for a spell cooldown.") end
  if self.reason=="spell unavailable: form, reagents or requirements" then return self:Text("Buff unavailable: check form, reagents or requirements.") end
  if self.manaFloorBlocked then return self:Text("Saving mana: buffing other players resumes above %d%% mana.",self.db.nearbyManaFloor or 0) end
  if self.pvpBlocked then return self:Text("PvP protection: flagged recipient or unknown PvP status. Check Diagnostics.") end
  if self.ownershipUnavailable then return self:Text("Blessing ownership is unknown; replacement is blocked for safety.") end
  if self.buffDataUnavailable then return self:Text("Buff information is unavailable or incomplete. Check Diagnostics.") end
  if self.targetDataPending then return self:Text("Waiting for readable target information.") end
  if self.deferredBlocked then return self:Text("Recipient temporarily skipped after a failed cast; retrying automatically.") end
  if self.reason=="nothing actionable" then
    -- Uses what the last check already found; no extra scanning.
    if self.rangeBlocked then return self:Text("A buff is due, but that player is out of range.") end
    local counts=self.db.nearbyEnabled and self.nearbyFrame and self.nearbyFrame:IsShown() and self.nearbyCounts
    if counts and counts.total==0 then return self:Text("All your buffs are up. No players nearby.") end
    if counts and counts.need==0 then return self:Text("All your buffs are up. Nearby players have what you can give.") end
    return self:Text("All your buffs are up.")
  end
  return self:Text("Status: %s",self.reason or "initializing")
end
