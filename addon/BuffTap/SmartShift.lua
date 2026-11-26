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
  self.smartShiftStatus=nil
end

function B:SmartShiftBegin(action)
  local allowed=classAllowed()
  local cleanse=action and action.source=="cleanse"
  if not allowed or not self.db or self.db.smartShift~=true or not action or action.source=="smartshift"
    or action.manual or (action.source and action.source~="spell" and not cleanse)
    or (not cleanse and action.target~="player") then return end
  if cleanse and (not self.ValidateCleanse or not self:ValidateCleanse(action)) then return end
  local form=self:CurrentSmartShiftForm()
  if not form then return end
  local guid=A.Call(UnitGUID,'player')
  if not A.Text(guid) or not A.Text(action.targetGUID) or A.Call(UnitGUID,action.target)~=action.targetGUID then return end
  local previous=self.smartShiftIntent
  if previous and not previous.exited and previous.spellID==form.spellID and previous.playerGUID==guid
    and GetTime()-previous.started<=4 then return end
  self.smartShiftIntent={spellID=form.spellID,icon=form.icon,buffID=action.id,playerGUID=guid,started=GetTime(),exited=false,verified=false}
end

function B:SmartShiftCastSucceeded(spellID)
  local intent=self.smartShiftIntent
  if not intent or not A.Number(spellID) or intent.buffID~=spellID or GetTime()-intent.started>4 then return end
  if not A.Text(intent.playerGUID) or A.Call(UnitGUID,'player')~=intent.playerGUID then return end
  intent.verified=true
  if not self:CurrentSmartShiftForm() then intent.exited=true end
end

function B:ValidateSmartShift(action,click)
  if action then action.gcdStart=nil; action.gcdDuration=nil end
  local intent=self.smartShiftIntent
  local allowed,class=classAllowed()
  if not allowed or not intent or not action or action.source~="smartshift" or action.id~=intent.spellID
    or not self.db or not self.db.enabled or self.db.smartShift~=true or not intent.verified or not intent.exited or A.Combat()
    or A.Call(IsMounted)==true or self:Stealthed() or A.Call(UnitIsDeadOrGhost,"player")~=false then return false end
  if self:ActionPauseReason(action) or not self:SituationActionCurrent(action) then return false end
  if action.target~="player" or not A.Text(action.targetGUID) or A.Call(UnitGUID,"player")~=action.targetGUID then return false end
  -- A failed form read is not evidence of caster form. Any active form blocks
  -- restoration even if its spell metadata is missing or not known to the addon.
  if A.Call(GetShapeshiftForm)~=0 then return false end
  local casting,castError=A.Call(UnitCastingInfo,"player")
  local channeling,channelError=A.Call(UnitChannelInfo,"player")
  if castError or channelError or casting~=nil or channeling~=nil then return false end
  if class=="SHAMAN" and action.id~=GHOST_WOLF then return false end
  if not A.Known(action.id) then return false end
  local usable,why=A.SpellUsable(action.id)
  if usable~=true then
    self.powerBlocked=true
    if why==true then self.manaBlocked=true; self.mainManaBlocked=true; self.manaWaitIcon=self.manaWaitIcon or action.icon end
    return false,why==true and "not enough mana for return form" or "return form not usable"
  end
  local cd=A.Call(C_Spell and C_Spell.GetSpellCooldown,action.id)
  if type(cd)~="table" or not A.Public(cd.isEnabled) or cd.isEnabled~=true then return false end
  if not A.Number(cd.startTime) or not A.Number(cd.duration) then return false end
  local start,duration=cd.startTime,cd.duration
  if not A.Public(cd.isActive) then return false end
  if (cd.isActive==true or (duration>0 and start+duration>GetTime())) and not self:OnlyGlobalCooldown(action,cd) then
    self.cooldownBlocked=true
    if duration>0 then self:ConsiderWake(start+duration-GetTime()+.03) end
    return false,"return form cooldown"
  end
  return true
end

function B:SmartShiftAction()
  local intent=self.smartShiftIntent
  if not intent then return nil end
  if not intent.verified or not intent.exited then self.smartShiftStatus=not intent.verified and "waiting for original buff confirmation" or "waiting for form exit"; return nil end
  local name=A.Call(C_Spell and C_Spell.GetSpellName,intent.spellID)
  local icon=A.Call(C_Spell and C_Spell.GetSpellTexture,intent.spellID) or intent.icon
  local action={source="smartshift",valid=true,key="smartshift:"..intent.spellID,id=intent.spellID,
    name=A.Text(name) and name or "Previous form",icon=icon or 134400,target="player",targetName="You",
    targetGUID=A.Call(UnitGUID,"player"),secureType="spell",reason="restore previous form",selectedAt=GetTime()}
  local valid,why=self:ValidateSmartShift(action,false)
  self.smartShiftStatus=valid and "return ready" or why or "waiting for safe return state"
  return valid and action or nil,why
end

function B:SmartShiftEvent(event,arg,castGUID,spellID)
  local intent=self.smartShiftIntent
  if not intent then return end
  if event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED" then
    -- A later repeated press can fail during the GCD after the original cast
    -- already succeeded. That failure cannot revoke confirmed restoration.
    if arg=="player" and A.Number(spellID) and spellID==intent.buffID and not intent.verified then self:ClearSmartShift("buff failed") end
  elseif event=="UNIT_SPELLCAST_SUCCEEDED" and arg=="player" and A.Number(spellID) then
    if spellID==intent.spellID and intent.verified then self:ClearSmartShift("form restored")
    else self:SmartShiftCastSucceeded(spellID) end
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
  local nearbyBuff=action and action.nearby and (not action.source or action.source=="spell")
  local optional=action and (nearbyBuff or action.source=="consumable" or action.source=="tracking"
    or action.source=="weapon-reminder" or action.source=="readiness")
  if action and not optional then return action,reason end
  local restore,waiting=self:SmartShiftAction()
  if restore then return restore,"SmartShift restore" end
  -- Keep the self-buff/return sequence ahead of optional reminders even
  -- when conservative cooldown checks need one more wake before restoration.
  if optional and waiting=="return form cooldown" then return nil,"waiting to restore previous form" end
  return action,reason
end

local baseValidate=B.Validate
function B:Validate(action)
  if action and action.source=="smartshift" then return self:ValidateSmartShift(action,false) end
  return baseValidate(self,action)
end
