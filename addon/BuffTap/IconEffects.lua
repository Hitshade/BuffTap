-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local colors={gold={1,.82,.12,1},cyan={.3,.85,1,1},green={.35,1,.5,1},red={1,.25,.2,1},white={1,1,1,1}}
function B:IconEffectStyle(settings)
  local d=settings or self.db or {}
  return d.effectStyle or (d.pulse and "pulse" or d.glow and "soft" or "none")
end
function B:StopIconEffect(frame)
  if not frame then return end
  local lib=LibStub and LibStub("LibCustomGlow-1.0",true)
  if frame.buffTapEffect and lib then
    local stop=({pixel="PixelGlow_Stop",autocast="AutoCastGlow_Stop",proc="ButtonGlow_Stop"})[frame.buffTapEffect]
    if stop then pcall(lib[stop],frame) end
  end
  frame.buffTapEffect=nil; frame.buffTapEffectKey=nil
  if frame.pulseAnimation then frame.pulseAnimation:Stop() end
  for _,part in ipairs({"btShine","btRipple","btBounce","btOrbit"}) do
    local fx=frame[part]
    if fx then if fx.group then pcall(fx.group.Stop,fx.group) end; if fx.region then fx.region:Hide() end end
  end
  if frame.glow then frame.glow:Hide(); frame.glow:SetAlpha(1) end
end

-- Built-in animated effects (game animations only): a light sweep, an expanding ring,
-- a small hop and a spark circling the icon. Each is created once per icon and reused.
local MEDIA="Interface\\AddOns\\BuffTap\\Media\\"
local function startShine(frame,color,speed)
  local fx=frame.btShine
  if not fx then
    local clip=CreateFrame("Frame",nil,frame); clip:SetAllPoints(frame)
    if type(clip.SetClipsChildren)=="function" then clip:SetClipsChildren(true) end
    clip:SetFrameLevel((frame:GetFrameLevel() or 1)+3)
    local t=clip:CreateTexture(nil,"OVERLAY"); t:SetTexture("Interface\\Buttons\\WHITE8X8"); t:SetBlendMode("ADD")
    if type(t.SetRotation)=="function" then pcall(t.SetRotation,t,math.rad(-25)) end
    local group=t:CreateAnimationGroup(); group:SetLooping("REPEAT")
    local move=group:CreateAnimation("Translation")
    fx={region=clip,texture=t,group=group,move=move}; frame.btShine=fx
  end
  local w,h=frame:GetWidth() or 40,frame:GetHeight() or 40
  fx.texture:SetSize(math.max(8,w*.22),h*2); fx.texture:ClearAllPoints(); fx.texture:SetPoint("CENTER",fx.region,"LEFT",-w*.3,0)
  fx.texture:SetVertexColor(color[1],color[2],color[3],.55)
  fx.move:SetOffset(w*1.6,0); fx.move:SetDuration(.55/speed); fx.move:SetEndDelay(2.2/speed)
  fx.region:Show(); fx.group:Play()
end
local function startRipple(frame,color,speed)
  local fx=frame.btRipple
  if not fx then
    local t=frame:CreateTexture(nil,"OVERLAY"); t:SetTexture(MEDIA.."UIRing4"); t:SetBlendMode("ADD"); t:SetAllPoints(frame)
    local group=t:CreateAnimationGroup(); group:SetLooping("REPEAT")
    local grow=group:CreateAnimation("Scale"); grow:SetScale(1.7,1.7); grow:SetOrigin("CENTER",0,0)
    local fade=group:CreateAnimation("Alpha"); fade:SetFromAlpha(.9); fade:SetToAlpha(0)
    fx={region=t,group=group,grow=grow,fade=fade}; frame.btRipple=fx
  end
  fx.region:SetVertexColor(color[1],color[2],color[3])
  for _,a in ipairs({fx.grow,fx.fade}) do a:SetDuration(1.1/speed); a:SetEndDelay(.9/speed) end
  fx.region:Show(); fx.group:Play()
end
local function startBounce(frame,speed)
  local icon=frame.icon; if not icon then return end
  local fx=frame.btBounce
  if not fx then
    local group=icon:CreateAnimationGroup(); group:SetLooping("REPEAT")
    local up=group:CreateAnimation("Translation"); up:SetOrder(1); up:SetSmoothing("OUT")
    local down=group:CreateAnimation("Translation"); down:SetOrder(2); down:SetSmoothing("IN")
    fx={group=group,up=up,down=down}; frame.btBounce=fx
  end
  local lift=math.max(3,(frame:GetHeight() or 40)*.08)
  fx.up:SetOffset(0,lift); fx.down:SetOffset(0,-lift)
  fx.up:SetDuration(.16/speed); fx.down:SetDuration(.16/speed); fx.down:SetEndDelay(1.6/speed)
  fx.group:Play()
end
-- Orbit: a small comet (a bright head and two fading tail dots) travelling around the
-- icon's edge. Rotation animations do not move a region around an offset origin on every
-- client, so the position is set directly while the effect is shown; a hidden holder runs
-- no code at all.
local function startOrbit(frame,color,speed)
  local fx=frame.btOrbit
  if not fx then
    local holder=CreateFrame("Frame",nil,frame); holder:SetAllPoints(frame)
    holder:SetFrameLevel((frame:GetFrameLevel() or 1)+3)
    local dots={}
    for i=1,3 do
      local t=holder:CreateTexture(nil,"OVERLAY"); t:SetTexture(MEDIA.."UIKnob"); t:SetBlendMode("ADD")
      dots[i]=t
    end
    fx={region=holder,dots=dots,angle=0}; frame.btOrbit=fx
    holder:SetScript("OnUpdate",function(self,elapsed)
      local w,h=frame:GetWidth() or 40,frame:GetHeight() or 40
      fx.angle=(fx.angle-(elapsed or 0)*fx.rate)%(math.pi*2)
      local rx,ry=w*.5,h*.5
      for i,t in ipairs(fx.dots) do
        local a=fx.angle+(i-1)*.32
        t:ClearAllPoints(); t:SetPoint("CENTER",self,"CENTER",math.cos(a)*rx,math.sin(a)*ry)
      end
    end)
  end
  local h=frame:GetHeight() or 40
  local size=math.max(6,h*.18)
  for i,t in ipairs(fx.dots) do
    local s=size*(1-(i-1)*.25)
    t:SetSize(s,s); t:SetVertexColor(color[1],color[2],color[3],1-(i-1)*.35)
  end
  fx.rate=(math.pi*2)/(2.4/speed); fx.angle=math.pi*.5
  fx.region:Show()
end

-- Urgency colour: your colour while plenty of time is left, amber in the last half of the
-- refresh window, red once the buff is gone.
local amber,urgentRed={1,.6,.1,1},{1,.22,.18,1}
function B:EffectUrgency(frame,d)
  if frame~=self.button or not d.effectUrgency or not self.action then return nil end
  local a=self.action
  if a.needState=="missing" then return "red" end
  if a.needState=="expiring" and type(a.remaining)=="number" and type(a.threshold)=="number" and a.threshold>0 then
    local left=a.remaining-math.max(0,GetTime()-(a.selectedAt or GetTime()))
    if left<=a.threshold*.5 then return "amber" end
    self:StartTimer("effect-urgency",math.max(.5,left-a.threshold*.5),function() B:UpdatePulse() end)
  end
  return nil
end

function B:ApplyIconEffect(frame,enabled,settings)
  if not frame or not frame.glow or B.API.Combat() then return end
  local d=settings or self.db or {}; local style=enabled and self:IconEffectStyle(d) or "none"
  if self.db and self.db.optionsReduceMotion and style~="none" then style="soft" end
  local color=colors[d.effectColor] or colors.gold
  local speed=({slow=.5,normal=1,fast=1.5})[d.effectSpeed] or 1
  local urgency=style~="none" and self:EffectUrgency(frame,d) or nil
  if urgency=="amber" then color=amber elseif urgency=="red" then color=urgentRed end
  -- Flash once replays for each new reminder, so the reminder's identity is part of the key.
  local once=frame==self.button and d.effectOnce==true and style~="none" and style~="soft"
  local token=once and self.action and (tostring(self.action.id)..":"..tostring(self.action.target)) or ""
  local key=style..":"..tostring(d.effectColor)..":"..tostring(d.effectSpeed)..":"..tostring(urgency)..":"..token
  if frame.buffTapEffectKey==key then return end
  self:StopIconEffect(frame)
  frame.buffTapEffectKey=key
  if once then
    self:StartTimer("effect-once",3/speed,function()
      if frame.buffTapEffectKey~=key then return end
      B:StopIconEffect(frame); frame.buffTapEffectKey=key
      frame.glow:SetDesaturated(true); frame.glow:SetVertexColor(color[1],color[2],color[3]); frame.glow:Show()
    end)
  end
  if style=="shine" or style=="ripple" or style=="bounce" or style=="orbit" then
    -- These motion effects stand on their own: no soft glow underneath.
    frame.glow:Hide()
    local ok=pcall(function()
      if style=="shine" then startShine(frame,color,speed)
      elseif style=="ripple" then startRipple(frame,color,speed)
      elseif style=="bounce" then startBounce(frame,speed)
      else startOrbit(frame,color,speed) end
    end)
    if ok then frame.buffTapEffect=style end
    return
  end
  local lib=LibStub and LibStub("LibCustomGlow-1.0",true)
  local start=({pixel="PixelGlow_Start",autocast="AutoCastGlow_Start",proc="ButtonGlow_Start"})[style]
  if start and lib then
    local ok
    if style=="pixel" then ok=pcall(lib[start],frame,color,8,.25*speed,nil,2,2,2,false)
    elseif style=="autocast" then ok=pcall(lib[start],frame,color,4,.25*speed,1,1,1)
    else ok=pcall(lib[start],frame,color,.125*speed) end
    if ok then frame.buffTapEffect=style; return end
    pcall(lib[({pixel="PixelGlow_Stop",autocast="AutoCastGlow_Stop",proc="ButtonGlow_Stop"})[style]],frame)
  end
  if style~="none" then
    frame.glow:SetDesaturated(true)
    frame.glow:SetVertexColor(color[1],color[2],color[3]); frame.glow:Show()
    if style=="pulse" and frame.pulseAnimation then
      if type(frame.pulseAnimation.GetAnimations)=="function" then
        local ok,a,b=pcall(frame.pulseAnimation.GetAnimations,frame.pulseAnimation)
        if ok then for _,animation in pairs({a,b}) do if type(animation.SetDuration)=="function" then animation:SetDuration(.7/speed) end end end
      end
      frame.pulseAnimation:Play()
    end
  end
end
