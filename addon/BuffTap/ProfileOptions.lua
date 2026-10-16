-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local function L(s,...) return B:Text(s,...) end
function B:BuildProfileOptions(p,h)
  local f=self.options; local label,button,check,selector=h.label,h.button,h.check,h.selector
  f.profiles=p
  label(p,"Profiles",18,-16,"GameFontNormalLarge")
  label(p,"Share bindings, appearance, sounds and general preferences across your characters.",18,-44,"GameFontDisableSmall",680)
  label(p,"Active profile",18,-76)
  local function names(exclude,unused)
    local out={}; for _,name in ipairs(B:ProfileNames()) do
      if (not exclude or name~=B.profileDB:GetCurrentProfile()) and (not unused or B:ProfileUsers(name)==0) then out[#out+1]={key=name,name=name} end
    end; return out
  end
  p.active=selector(p,"",18,-98,420,function() return names() end,function(name)
    p.confirm:Hide(); p.renameDialog:Hide(); B:SelectSettingsProfile(name)
  end,"scroll")
  p.users=label(p,"",18,-136,"GameFontDisableSmall",680)
  label(p,"Create a new profile",18,-174)
  p.name=CreateFrame("EditBox",nil,p,"InputBoxTemplate"); p.name:SetSize(270,26); p.name:SetPoint("TOPLEFT",22,-198); p.name:SetAutoFocus(false); p.name:SetMaxLetters(50)
  p.name:SetScript("OnEscapePressed",function(e) e:ClearFocus() end)
  local function outcome(ok)
    p.pending=nil; p.confirm:Hide()
    p.message:SetText(L(ok and "Profile updated." or "Unable to change profile. Check the name and selection.")); if ok then p.name:SetText(""); p.renameDialog:Hide() end
    B:Options()
  end
  p.create=button(p,L("Create & switch"),304,-196,134,function()
    local name=p.name:GetText()
    if p.copyCurrent:GetChecked() then outcome(B:CreateSettingsProfile(name,true)); return end
    p.confirmText:SetText(L("Create a profile with default shared preferences and switch to it? Your current profile is kept unchanged."))
    p.pending=function() outcome(B:CreateSettingsProfile(name,false)) end; p.confirm:Show()
  end)
  p.copyCurrent=check(p,L("Start with current settings"),448,-197,function() p.pending=nil; p.confirm:Hide(); B:Options() end); p.copyCurrent:SetChecked(true)
  p.createHint=label(p,"",18,-232,"GameFontDisableSmall",680)
  label(p,"Copy from profile",18,-270)
  p.source=selector(p,L("Choose profile"),18,-292,420,function() return names(true) end,function(name)
    p.sourceName=name; p.classSource=nil; p.includeClass:SetChecked(false); p.confirm:Hide()
  end,"scroll")
  p.copy=button(p,L("Copy into current"),448,-292,200,function()
    local source=p.sourceName; local character=p.includeClass:GetChecked() and p.classSource or nil
    if not source or (p.includeClass:GetChecked() and not character) then outcome(false); return end
    p.confirmText:SetText(L("Replace the active profile's shared preferences? Characters using it will receive these changes.")..(character and "\n"..L("Also replace this character's buff and class settings.") or ""))
    p.pending=function() outcome(B:CopySettingsProfile(source,character)) end; p.confirm:Show()
  end)
  p.includeClass=check(p,L("Also copy buff and class settings"),18,-332,function(c)
    p.pending=nil; p.confirm:Hide()
    if c:GetChecked() then p.classSource=p.classSource or B:ClassCopySources(p.sourceName)[1] end
    B:Options()
  end)
  p.character=selector(p,L("Choose same-class character"),18,-364,420,function()
    local list={}; for _,name in ipairs(B:ClassCopySources(p.sourceName)) do list[#list+1]={key=name,name=name} end; return list
  end,function(name) p.classSource=name; p.pending=nil; p.confirm:Hide() end,"scroll")
  p.classHint=label(p,"Buff and class settings, including party and raid plans, stay on this character. Optional copying requires a same-class source.",18,-404,"GameFontDisableSmall",680)
  p.renameDialog=CreateFrame("Frame","BuffTapRenameProfile",p,"BackdropTemplate")
  local rename=p.renameDialog; rename:SetSize(686,126); rename:SetPoint("TOPLEFT",16,-158); rename:SetFrameLevel(p:GetFrameLevel()+20); rename:EnableMouse(true)
  rename:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  rename:SetBackdropColor(.04,.05,.06,1); rename:SetBackdropBorderColor(.6,.45,.2,1)
  label(rename,"Rename active profile",12,-10,"GameFontNormalLarge")
  p.renameName=CreateFrame("EditBox",nil,rename,"InputBoxTemplate"); p.renameName:SetSize(410,26); p.renameName:SetPoint("TOPLEFT",16,-42); p.renameName:SetAutoFocus(false); p.renameName:SetMaxLetters(50)
  p.renameName:SetScript("OnEscapePressed",function(e) e:ClearFocus(); rename:Hide() end)
  label(rename,"Changes only the name. All settings are preserved.",12,-88,"GameFontDisableSmall",420)
  p.renameSave=button(rename,L("Save name"),448,-40,220,function() outcome(B:RenameSettingsProfile(p.renameName:GetText())) end)
  button(rename,L("Cancel"),448,-82,220,function() rename:Hide() end)
  rename:Hide(); if UISpecialFrames then table.insert(UISpecialFrames,"BuffTapRenameProfile") end
  p.rename=button(p,L("Rename..."),448,-98,200,function()
    p.pending=nil; p.confirm:Hide(); p.renameName:SetText(B.profileDB:GetCurrentProfile()); rename:Show(); p.renameName:SetFocus(); p.renameName:HighlightText()
  end)
  p.reset=button(p,L("Reset profile"),18,-442,150,function()
    p.confirmText:SetText(L("Reset this profile's shared preferences? Buff and class settings will stay unchanged."))
    p.pending=function() outcome(B:ResetSettingsProfile()) end; p.confirm:Show()
  end)
  p.deletePick=selector(p,L("Choose unused profile"),18,-484,420,function() return names(true,true) end,function(name) p.deleteName=name; p.confirm:Hide() end,"scroll")
  p.delete=button(p,L("Delete unused"),448,-484,200,function()
    local name=p.deleteName
    p.confirmText:SetText(L("Delete unused profile: %s?",name or ""))
    p.pending=function() outcome(B:DeleteSettingsProfile(name)); p.deleteName=nil end; p.confirm:Show()
  end)
  p.confirm=CreateFrame("Frame",nil,p,"BackdropTemplate"); p.confirm:SetSize(686,80); p.confirm:SetPoint("TOPLEFT",16,-524)
  p.confirm:SetFrameLevel(p:GetFrameLevel()+15); p.confirm:EnableMouse(true)
  p.confirm:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  p.confirm:SetBackdropColor(.07,.04,.025,1); p.confirm:SetBackdropBorderColor(.6,.45,.2,1)
  p.confirmText=label(p.confirm,"",12,-8,"GameFontHighlightSmall",660)
  p.accept=button(p.confirm,L("Confirm"),448,-46,106,function() local pending=p.pending; p.pending=nil; p.confirm:Hide(); if pending and not A.Combat() then pending() end end)
  button(p.confirm,L("Cancel"),566,-46,106,function() p.pending=nil; p.confirm:Hide() end)
  p.confirm:Hide(); p.message=label(p,"",18,-610,"GameFontHighlightSmall",680)
  p:HookScript("OnHide",function() p.pending=nil; p.confirm:Hide(); p.renameDialog:Hide() end)
end
function B:UpdateProfileOptions()
  local p=self.options.profiles; if not p then return end
  local current=self.profileDB:GetCurrentProfile(); p.active:SetText(current)
  p.createHint:SetText(L(p.copyCurrent:GetChecked() and "Copies shared preferences into a new profile and switches to it. The original is kept." or "Starts with default shared preferences and switches to the new profile. The original is kept."))
  p.users:SetText(L("Changes save immediately. %d character(s) use this profile. Copying leaves the source unchanged.",self:ProfileUsers(current)))
  if p.sourceName==current or not self.profileDB.sv.profiles[p.sourceName] then p.sourceName=nil; p.includeClass:SetChecked(false); p.classSource=nil end
  p.source:SetText(p.sourceName or L("Choose profile")); p.copy:SetEnabled(p.sourceName~=nil)
  p.source:SetEnabled(#self:ProfileNames()>1)
  local choices=p.sourceName and self:ClassCopySources(p.sourceName) or {}
  p.includeClass:SetShown(#choices>0)
  if #choices==0 then p.includeClass:SetChecked(false); p.classSource=nil end
  local valid=false; for _,name in ipairs(choices) do if name==p.classSource then valid=true end end
  if not valid then p.classSource=choices[1] end
  p.character:SetText(p.classSource or L("Choose same-class character")); p.character:SetShown(#choices>0 and p.includeClass:GetChecked()==true)
  if not self.profileDB.sv.profiles[p.deleteName] or self:ProfileUsers(p.deleteName)>0 then p.deleteName=nil end
  p.deletePick:SetText(p.deleteName or L("Choose unused profile")); p.delete:SetEnabled(p.deleteName~=nil)
  local unused=false; for _,name in ipairs(self:ProfileNames()) do if self:ProfileUsers(name)==0 then unused=true end end
  p.deletePick:SetEnabled(unused)
end
