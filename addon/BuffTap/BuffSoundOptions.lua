-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local T=B.OptionsTheme
local function scopeName(context)
  return B:Text(context=="party" and "Party" or context=="raid" and "Raid" or "Personal")
end
local function buffName(def)
  for _,id in ipairs(def.ranks or {}) do
    local name=A.Call(C_Spell and C_Spell.GetSpellName,id)
    if A.Text(name) then return name end
  end
  return def.name or def.key
end
function B:RenderBuffSoundEditor(focusSelection)
  local p=self.buffSoundEditor; if not p or not p.context or not self.db then return end
  local ui=self.refinedUI
  p.title:SetText(self:Text("%s - %s",buffName(self:FindBuff(p.key)),scopeName(p.context)))
  p.enabled:SetChecked(self:BuffAlertEnabled(p.context,p.key))
  p.summary:SetText(self:Text("Changes save immediately. Muting keeps your chosen sound. Preview does not change settings."))
  local choices={{key=false,name=self:Text("Use default: %s",self:SoundChoiceName(self.db.reminderSound))}}
  local query=string.lower(p.search:GetText() or "")
  for _,choice in ipairs(self:SoundChoices()) do
    if query=="" or string.find(string.lower(self:Text(choice.name).." "..self:Text(choice.source or "")),query,1,true) then choices[#choices+1]=choice end
  end
  for _,row in ipairs(p.rows) do row.select:Hide(); row.preview:Hide() end
  local selected=self:BuffAlertSound(p.context,p.key); local selectedIndex=1
  for i,choice in ipairs(choices) do
    local row=p.rows[i]
    if not row then
      row={}
      row.select=ui.flatButton(p.content,"",0,-(i-1)*34,404,function(btn)
        if A.Combat() or not B:SetBuffAlertSound(p.context,p.key,btn.soundKey or nil) then return end
        p.feedback:SetText(""); B:RenderBuffSoundEditor(false)
      end)
      local fs=row.select:GetFontString(); if fs then fs:ClearAllPoints(); fs:SetPoint("LEFT",10,0); fs:SetPoint("RIGHT",-10,0); fs:SetJustifyH("LEFT") end
      row.preview=ui.button(p.content,"Preview",416,-(i-1)*34,116,function(btn)
        if A.Combat() then return end
        local ok=B:PlayAlert("reminder",true,btn.soundKey or B.db.reminderSound)
        p.feedback:SetText(ok and B:Text("Preview only; your selection is unchanged.") or B:Text("Sound preview unavailable."))
      end)
      p.rows[i]=row
    end
    row.select.soundKey=choice.key; row.preview.soundKey=choice.key
    row.select:SetText(self:Text(choice.name)); row.select:Show(); row.preview:Show()
    local active=(choice.key or nil)==selected
    T.Navigation(row.select,active)
    if active then selectedIndex=i end
  end
  p.content:SetHeight(math.max(1,#choices*34)); p.scroll.optionsScrollRange=math.max(0,#choices*34-238)
  if focusSelection then T.ScrollTo(p.scroll,math.max(0,(selectedIndex-4)*34),true)
  else T.ScrollTo(p.scroll,p.scroll:GetVerticalScroll(),true) end
  p.empty:SetShown(query~="" and #choices==1)
end
function B:OpenBuffSoundEditor(context,def)
  if A.Combat() or not self.options or not self.refinedUI or (context~="personal" and context~="party" and context~="raid") then return false end
  local key=self:BuffAlertKey(def); local buff=key and self:FindBuff(key)
  if not buff or buff.class~=A.Class("player") then return false end
  local ui=self.refinedUI; local p=self.buffSoundEditor
  if not p then
    p=CreateFrame("Frame","BuffTapBuffSoundEditor",self.options,"BackdropTemplate"); self.buffSoundEditor=p
    p:SetSize(588,454); p:SetPoint("CENTER"); p:SetFrameStrata("DIALOG"); p:SetFrameLevel(self.options:GetFrameLevel()+80); p:SetClampedToScreen(true); p:EnableMouse(true)
    p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    p:SetBackdropColor(unpack(T.menu)); p:SetBackdropBorderColor(unpack(T.border)); T.Surface(p,"menu")
    p.title=ui.label(p,"",18,-18,"GameFontNormalLarge",550)
    p.enabled=ui.check(p,"Play reminder sound",18,-53,function(c)
      if B:SetBuffAlertEnabled(p.context,p.key,c:GetChecked()==true) then B:RenderBuffSoundEditor(false) end
    end)
    p.summary=ui.label(p,"",18,-85,"GameFontDisableSmall",550)
    ui.label(p,"Search",18,-125,"GameFontHighlightSmall",58)
    p.search=ui.editbox(p,80,-119,484,false); p.search:SetHeight(24)
    p.search:SetScript("OnTextChanged",function() if p.context and not p.loading then B:RenderBuffSoundEditor(true) end end)
    p.search:SetScript("OnEscapePressed",function(s) s:ClearFocus(); p:Hide() end)
    p.scroll=CreateFrame("ScrollFrame",nil,p,"UIPanelScrollFrameTemplate"); p.scroll:SetPoint("TOPLEFT",18,-155); p.scroll:SetSize(534,238)
    p.content=CreateFrame("Frame",nil,p.scroll); p.content:SetSize(534,1); p.scroll:SetScrollChild(p.content); T.SmoothWheel(p.scroll,20); T.ScrollBar(p.scroll)
    p.rows={}; p.empty=ui.label(p,"No matching sounds. Default is still available.",18,-398,"GameFontDisableSmall",400); p.empty:Hide()
    p.feedback=ui.label(p,"",18,-428,"GameFontDisableSmall",410)
    ui.button(p,"Done",454,-416,116,function() p:Hide(); if B.options and B.options:IsShown() then B:Options() end end)
    p:EnableKeyboard(true); p:SetPropagateKeyboardInput(true)
    p:SetScript("OnKeyDown",function(_,pressed) p:SetPropagateKeyboardInput(pressed~="ESCAPE"); if pressed=="ESCAPE" then p:Hide() end end)
    p:RegisterEvent("PLAYER_REGEN_DISABLED"); p:SetScript("OnEvent",function() p:Hide() end)
    p:SetScript("OnHide",function() p.search:ClearFocus(); p.scroll.optionsScrollTarget=nil; if p.scroll.optionsScrollAnimator then p.scroll.optionsScrollAnimator:SetScript("OnUpdate",nil); p.scroll.optionsScrollAnimator:Hide() end end)
    self.options:HookScript("OnHide",function() p:Hide() end)
    if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapBuffSoundEditor") end
  end
  if self.options.activeSelector and self.options.activeSelector~=p then self.options.activeSelector:Hide() end
  self.options.activeSelector=p
  p.context=context; p.key=key; p.loading=true; p.search:SetText(""); p.loading=nil; p.feedback:SetText("")
  p:Show(); self:RenderBuffSoundEditor(true)
  return true
end
