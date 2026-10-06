-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
local _,B=...
local A=B.API
-- SoundKit IDs cross-checked against Forever 1.60.1.70009 SoundKit.csv.
-- Additional choices require the client's named constant; no guessed assets.
local definitions={
  {key="default",name="Default reminder",id=12867},
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
  local choices={}
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
  for _,name in ipairs(names) do choices[#choices+1]={key="lsm:"..name,name=name,source="SharedMedia"} end
  for _,field in ipairs({"reminderSound","supplySound"}) do
    local key=self.db and self.db[field]
    if type(key)=="string" and key:sub(1,4)=="lsm:" and (not media or not playable(media[key:sub(5)])) then
      local found=false; for _,choice in ipairs(choices) do if choice.key==key then found=true; break end end
      if not found then choices[#choices+1]={key=key,name=key:sub(5).." (unavailable; using default)",source="SharedMedia"} end
    end
  end
  return choices
end
function B:NormalizeAlerts()
  local valid={}; for _,definition in ipairs(definitions) do
    local id=definition.id or (type(SOUNDKIT)=="table" and SOUNDKIT[definition.constant])
    if A.Number(id) and id>0 then valid[definition.key]=true end
  end
  for _,key in ipairs({"reminderSound","supplySound"}) do
    local value=self.db[key]
    local shared=type(value)=="string" and value:sub(1,4)=="lsm:" and #value>4 and #value<=512
    if not valid[value] and not shared then self.db[key]="default" end
  end
  if self.db.soundChannel~="Master" and self.db.soundChannel~="SFX" then self.db.soundChannel="Master" end
  local interval=self.db.soundInterval
  if not A.Number(interval) then interval=5 end
  self.db.soundInterval=math.max(5,math.min(60,math.floor(interval)))
end
function B:PlayAlert(kind,preview)
  if not self.db then return false end
  if not preview and self.ReminderPauseReason and self:ReminderPauseReason() then return false end
  if not preview and not (kind=="supply" and self.db.suppliesSound or kind~="supply" and self.db.sound) then return false end
  local now=GetTime()
  if not preview and self.lastAlertSound and now-self.lastAlertSound<self.db.soundInterval then return false end
  local selected=self.db[kind=="supply" and "supplySound" or "reminderSound"]
  local player,value=PlaySound,12867
  if type(selected)=="string" and selected:sub(1,4)=="lsm:" then
    local media=mediaTable(); local sound=media and media[selected:sub(5)]
    if playable(sound) and type(PlaySoundFile)=="function" then player,value=PlaySoundFile,sound end
  else
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
  if not preview then self.lastAlertSound=now end
  return true
end
function B:FriendlyStatus()
  if not self.db or not self.db.enabled then return self:Text("BuffTap is disabled.") end
  if A.Combat() then return self:Text("Reminders pause during combat.") end
  if self.pauseUntil and GetTime()<self.pauseUntil then return self:Text("Reminders paused: %d min remaining",math.ceil((self.pauseUntil-GetTime())/60)) end
  if self.editModeActive then return self:Text("Editing reminder position.") end
  if self.action then
    local a=self.action
    if a.manual then return self:Text("Manual application: %s",a.name or "?") end
    return self:Text("Ready: %s - %s",a.name or "?",a.targetName or a.target or "?")
  end
  if self.reason=="resting" then return self:Text("Reminders pause in cities and inns.") end
  if self.reason=="mounted" then return self:Text("Reminders pause while mounted.") end
  if self.reason=="dead / ghost / player unavailable" then return self:Text("Player is dead, a ghost, or unavailable.") end
  if self.reason=="nothing actionable" then return self:Text("No action is currently eligible. Buffs may be covered or excluded; check Diagnostics for details.") end
  return self:Text("Status: %s",self.reason or "initializing")
end
