-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- See LICENSE-MPL-2.0.txt.
local _,B=...
local A=B.API
local definitions={
  {key="default",name="Default reminder",id=12867},
  {key="ready",name="Ready check",constant="READY_CHECK"},
  {key="raid",name="Raid warning",constant="RAID_WARNING"},
  {key="click",name="Interface click",constant="IG_MAINMENU_OPTION_CHECKBOX_ON"},
}
function B:SoundChoices()
  local choices={}
  for _,definition in ipairs(definitions) do
    local id=definition.id or (type(SOUNDKIT)=="table" and SOUNDKIT[definition.constant])
    if A.Number(id) and id>0 then choices[#choices+1]={key=definition.key,name=definition.name,id=id} end
  end
  return choices
end
function B:NormalizeAlerts()
  local valid={}; for _,choice in ipairs(self:SoundChoices()) do valid[choice.key]=true end
  for _,key in ipairs({"reminderSound","supplySound"}) do if not valid[self.db[key]] then self.db[key]="default" end end
  if self.db.soundChannel~="Master" and self.db.soundChannel~="SFX" then self.db.soundChannel="Master" end
  local interval=self.db.soundInterval
  if not A.Number(interval) then interval=5 end
  self.db.soundInterval=math.max(5,math.min(60,math.floor(interval)))
end
function B:PlayAlert(kind,preview)
  if not self.db or type(PlaySound)~="function" then return false end
  if not preview and self.ReminderPauseReason and self:ReminderPauseReason() then return false end
  if not preview and not (kind=="supply" and self.db.suppliesSound or kind~="supply" and self.db.sound) then return false end
  local selected=self.db[kind=="supply" and "supplySound" or "reminderSound"]
  local id=12867
  for _,choice in ipairs(self:SoundChoices()) do if choice.key==selected then id=choice.id; break end end
  -- Previews do not consume the reminder or supply notification cooldown.
  local now=GetTime()
  if not preview and self.lastAlertSound and now-self.lastAlertSound<self.db.soundInterval then return false end
  local ok,result=pcall(PlaySound,id,self.db.soundChannel)
  if not ok or result==false then return false end
  if not preview then self.lastAlertSound=now end
  return true
end
function B:FriendlyStatus()
  if not self.db or not self.db.enabled then return self:Text("BuffTap is disabled.") end
  if A.Combat() then return self:Text("Reminders pause during combat.") end
  if self.action then
    local a=self.action
    if a.manual then return self:Text("Manual application: %s",a.name or "?") end
    return self:Text("Ready: %s → %s",a.name or "?",a.targetName or a.target or "?")
  end
  if self.reason=="resting" then return self:Text("Reminders pause in cities and inns.") end
  if self.reason=="mounted" then return self:Text("Reminders pause while mounted.") end
  if self.reason=="dead / ghost / player unavailable" then return self:Text("Player is dead, a ghost, or unavailable.") end
  if self.reason=="nothing actionable" then return self:Text("No action is currently eligible. Buffs may be covered or excluded; check Diagnostics for details.") end
  return self:Text("Status: %s",self.reason or "initializing")
end
