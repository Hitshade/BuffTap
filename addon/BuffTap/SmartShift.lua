-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Opt-in, click-to-restore form handling for Druids and Shaman Ghost Wolf.
local _,B=...
local A=B.API
local GHOST_WOLF=2645

local function classAllowed()
  local class=A.Class("player")
  return class=="DRUID" or class=="SHAMAN",class
end

local function formInfo(index)
  if type(GetShapeshiftFormInfo)~="function" or not A.Number(index) or index<1 then return nil end
  local ok,icon,active,castable,spellID=pcall(GetShapeshiftFormInfo,index)
  if not ok or not A.Public(icon) or not A.Public(active) or not A.Public(castable) or not A.Public(spellID) then return nil end
  if active~=true and active~=1 then return nil end
  if not A.Number(spellID) or spellID<=0 then return nil end
  return {index=index,spellID=spellID,icon=icon,castable=castable==true or castable==1}
end

function B:CurrentSmartShiftForm()
  local allowed,class=classAllowed()
  if not allowed or type(GetShapeshiftForm)~="function" then return nil end
  local index=A.Call(GetShapeshiftForm)
  local info=formInfo(index)
  if not info or (class=="SHAMAN" and info.spellID~=GHOST_WOLF) then return nil end
  if not A.Known(info.spellID) then return nil end
  return info
end

function B:ClearSmartShift(reason)
  self.smartShiftIntent=nil
  self.smartShiftReason=reason
end

function B:SmartShiftBegin(action)
  local allowed=classAllowed()
  if not allowed or not self.db or self.db.smartShift~=true or not action or action.source=="smartshift"
    or action.manual or (action.source and action.source~="spell") or action.target~="player" then return end
  local form=self:CurrentSmartShiftForm()
  if not form then return end
  self.smartShiftIntent={spellID=form.spellID,icon=form.icon,buffID=action.id,started=GetTime(),exited=false,verified=false}
end

function B:SmartShiftCastSucceeded(spellID)
  local intent=self.smartShiftIntent
  if not intent or intent.buffID~=spellID or GetTime()-intent.started>4 then return end
  intent.verified=true
  if not self:CurrentSmartShiftForm() then intent.exited=true end
end

function B:ValidateSmartShift(action,click)
  local intent=self.smartShiftIntent
  local allowed,class=classAllowed()
  if not allowed or not intent or not action or action.source~="smartshift" or action.id~=intent.spellID
    or not self.db or self.db.smartShift~=true or not intent.verified or not intent.exited or A.Combat()
    or A.Call(IsMounted)==true or self:Stealthed() or A.Call(UnitIsDeadOrGhost,"player")~=false then return false end
  local active=self:CurrentSmartShiftForm()
  if active then return false end -- never toggle any active form off
  if class=="SHAMAN" and action.id~=GHOST_WOLF then return false end
  if not A.Known(action.id) then return false end
  local usable,why=A.SpellUsable(action.id)
  if usable~=true then return false,why end
  local cd=A.Call(C_Spell and C_Spell.GetSpellCooldown,action.id)
  if type(cd)~="table" or cd.isEnabled==false then return false end
  local start=tonumber(cd.startTime) or 0; local duration=tonumber(cd.duration) or 0
  if start>0 and duration>0 and start+duration>GetTime() then return false end
  return true
end

function B:SmartShiftAction()
  local intent=self.smartShiftIntent
  if not intent or not intent.verified or not intent.exited then return nil end
  local name=A.Call(C_Spell and C_Spell.GetSpellName,intent.spellID)
  local icon=A.Call(C_Spell and C_Spell.GetSpellTexture,intent.spellID) or intent.icon
  local action={source="smartshift",valid=true,key="smartshift:"..intent.spellID,id=intent.spellID,
    name=A.Text(name) and name or "Previous form",icon=icon or 134400,target="player",targetName="You",
    targetGUID=A.Call(UnitGUID,"player"),secureType="spell",reason="restore previous form",selectedAt=GetTime()}
  return self:ValidateSmartShift(action,false) and action or nil
end

function B:SmartShiftEvent(event,arg,castGUID,spellID)
  local intent=self.smartShiftIntent
  if not intent then return end
  if event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED" then
    if arg=="player" and spellID==intent.buffID then self:ClearSmartShift("buff failed") end
  elseif event=="UNIT_SPELLCAST_SUCCEEDED" and arg=="player" and spellID==intent.spellID and intent.verified then
    self:ClearSmartShift("form restored")
  elseif event=="UPDATE_SHAPESHIFT_FORM" then
    local active=self:CurrentSmartShiftForm()
    if not active then intent.exited=true
    elseif active.spellID~=intent.spellID then self:ClearSmartShift("another form chosen")
    elseif intent.exited then self:ClearSmartShift("form already restored") end
  elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA"
    or event=="PLAYER_MOUNT_DISPLAY_CHANGED" or event=="UPDATE_STEALTH" then
    self:ClearSmartShift("unsafe state changed")
  end
end

local baseSelect=B.Select
function B:Select()
  local action,reason=baseSelect(self)
  if action then return action,reason end
  local restore=self:SmartShiftAction()
  if restore then return restore,"SmartShift restore" end
  return nil,reason
end

local baseValidate=B.Validate
function B:Validate(action)
  if action and action.source=="smartshift" then return self:ValidateSmartShift(action,false) end
  return baseValidate(self,action)
end
