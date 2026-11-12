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
  if frame.glow then frame.glow:Hide(); frame.glow:SetAlpha(1) end
end
function B:ApplyIconEffect(frame,enabled,settings)
  if not frame or not frame.glow or B.API.Combat() then return end
  local d=settings or self.db or {}; local style=enabled and self:IconEffectStyle(d) or "none"
  if self.db and self.db.optionsReduceMotion and style~="none" then style="soft" end
  local color=colors[d.effectColor] or colors.gold
  local speed=({slow=.5,normal=1,fast=1.5})[d.effectSpeed] or 1
  local key=style..":"..tostring(d.effectColor)..":"..tostring(d.effectSpeed)
  if frame.buffTapEffectKey==key then return end
  self:StopIconEffect(frame)
  frame.buffTapEffectKey=key
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
