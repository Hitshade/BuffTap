-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local groups={solo=true,party=true,raid=true}
local keys={
  buffs={"buffs","priorities","buffSeconds","buffCharges","seconds"},
  weapons={"weaponReminder","weaponMainHand","weaponOffHand","weaponChoices","weaponCoatings","weaponSeconds"},
  consumables={"consumablesEnabled","consumableFamilies","consumableChoices","consumableSeconds","consumableModes","consumableLocations"},
}
local categoryFor={}; for category,list in pairs(keys) do for _,key in ipairs(list) do categoryFor[key]=category end end
local limits={seconds={15,180},weaponSeconds={0,300}}
local maps={buffs=true,priorities=true,buffSeconds=true,buffCharges=true,weaponChoices=true,weaponCoatings=true,consumableFamilies=true,consumableChoices=true,consumableSeconds=true,consumableModes=true,consumableLocations=true}
local function clone(value)
  if type(value)~="table" then return value end
  local copy={}; for key,v in pairs(value) do if type(key)=="string" and (type(v)=="boolean" or A.Text(v) or A.Number(v)) then copy[key]=v end end
  return copy
end
local function bounded(value,low,high) return A.Number(value) and math.max(low,math.min(high,math.floor(value))) or nil end

-- Dual spec. The game reports two spec groups once dual spec is learned; only the group number is reliable,
-- so per-spec choices are keyed to group 1 or 2 and the active group is read on every refresh.
function B:SpecGroup()
  if type(GetNumSpecGroups)~="function" then return nil end
  local count=A.Call(GetNumSpecGroups)
  if not A.Number(count) or count<1 then return nil end
  -- One spec group: you are in Spec 1, and Spec 2 can be prepared before dual spec is learned.
  if count<2 then return 1 end
  local info=C_SpecializationInfo
  if type(info)~="table" then return nil end
  local group=A.Call(info.GetActiveSpecGroup)
  if A.Number(group) and (group==1 or group==2) then return group end
  return nil
end

-- Every class can keep separate choices per spec (a tank, healer and damage dealer want different buffs, oils and stones).
-- Either-or buff families always carry the spec tag; other rows only say when the specs differ.
local specBuffFamilies={magearmor=true,seals=true,paladinaura=true,shields=true,aspects=true,demonarmor=true}
function B:SpecApplies(category)
  return category=="consumables" or category=="weapons" or category=="buffs"
end

function B:SpecRoutes(category,key,mapKey)
  if not self:SpecApplies(category) then return false end
  if category~="buffs" then return true end
  if type(mapKey)~="string" then return false end
  if key=="buffs" then return self:FindBuff(mapKey)~=nil end
  -- Shield charge refresh belongs to the shield row, so it follows the spec with it.
  return key=="buffCharges" and (mapKey=="lightning-shield" or mapKey=="water-shield")
end

function B:SpecRoot()
  local root=self.db and self.db.situationSettings
  return root and root.spec
end

function B:SpecEnabled()
  local root=self:SpecRoot()
  return root~=nil and root.enabled==true and self:SpecGroup()~=nil
end

function B:ActiveSpec() return self:SpecEnabled() and self:SpecGroup() or nil end

-- The spec being edited in Options: shared by every page, the active spec until the player picks the other.
function B:EditSpec()
  if not self:SpecEnabled() then return nil end
  if self.editSpec==1 or self.editSpec==2 then return self.editSpec end
  return self:SpecGroup()
end

function B:SpecValues(spec,category)
  local root=self:SpecRoot()
  return root and root[spec] and root[spec][category]
end

-- True when the two specs hold different choices for these map entries (a family and its children, say).
function B:SpecDiffers(category,names)
  local context=self:EditorContext(category)
  local one=self:SituationPreview(context,category,1); local two=self:SituationPreview(context,category,2)
  for _,key in ipairs(keys[category]) do
    if maps[key] then for _,name in ipairs(names) do if (one[key] or {})[name]~=(two[key] or {})[name] then return true end end end
  end
  return false
end

-- Small coloured note after a row name while the spec switch is on (empty otherwise).
function B:SpecTag(category,item)
  local spec=self:EditSpec(); if not spec then return "" end
  if category=="buffs" then
    if not self:SpecRoutes("buffs","buffs",item.key) then return "" end
    -- Either-or rows always say which spec you are editing; other rows only say when the specs differ.
    if item.coverageFamily~=nil and specBuffFamilies[item.coverageFamily]==true then return "  |cff9a8cff"..self:Text("Spec %d",spec).."|r" end
  end
  local names={item.key}
  for _,child in ipairs(item.children or {}) do names[#names+1]=child.key end
  if not self:SpecDiffers(category,names) then return "" end
  return "  |cff9a8cff"..self:Text("Differs from Spec %d",spec==1 and 2 or 1).."|r"
end

function B:SetSpecEnabled(on)
  if A.Combat() or not self:SpecRoot() then return false end
  self:SpecRoot().enabled=on==true; self.editSpec=nil
  return self:SituationChanged()
end

function B:SetEditSpec(spec)
  if spec~=1 and spec~=2 then return false end
  self.editSpec=spec
  if self.UpdateContextControls and self.options and self.options:IsShown() then self:UpdateContextControls() end
  if self.Options and self.options and self.options:IsShown() then self:Options() end
  return true
end

function B:CleanSituationCategory(category,source)
  local out={}; local class=A.Class("player")
  for _,key in ipairs(keys[category] or {}) do
    local value=source[key]
    if maps[key] and type(value)=="table" then
      local clean={}
      for name,v in pairs(value) do
        if type(name)=="string" then
          if key=="buffs" or key=="priorities" or key=="buffSeconds" or key=="buffCharges" then
            local def=self:FindBuff(name)
            if def and (not class or def.class==class) then
              if key=="buffs" and (type(v)=="boolean" or v=="default") then clean[name]=v
              elseif (key=="priorities" or key=="buffSeconds") and v==false then clean[name]=false
              elseif key=="priorities" then clean[name]=bounded(v,1,999)
              elseif key=="buffSeconds" then clean[name]=bounded(v,0,600)
              elseif key=="buffCharges" and (name=="lightning-shield" or name=="water-shield") then clean[name]=bounded(v,0,2) end
            end
          elseif key=="weaponChoices" or key=="weaponCoatings" then
            if (name=="main" or name=="off") and v==false then clean[name]=false
            elseif (name=="main" or name=="off") and A.Text(v) then
              local choice=key=="weaponChoices" and self:WeaponChoice(v) or self:CoatingChoice(v)
              if choice and (key=="weaponCoatings" or not class or choice.class==class) then clean[name]=v end
            end
          else
            local family=self:ConsumableFamily(name)
            if family then
              if v==false or (key=="consumableFamilies" and v=="default") then clean[name]=v
              elseif key=="consumableFamilies" and type(v)=="boolean" then clean[name]=v
              elseif key=="consumableLocations" and (v=="everywhere" or v=="instances") then clean[name]=v
              elseif key=="consumableModes" and not family.hidden and (v=="auto" or v=="manual") then clean[name]=v
              elseif key=="consumableSeconds" then clean[name]=bounded(v,30,1800)
              elseif key=="consumableChoices" and A.Number(v) then
                for _,item in ipairs(family.items or {}) do if item.id==v then clean[name]=v; break end end
              end
            end
          end
        end
      end
      if next(clean) then out[key]=clean end
    elseif limits[key] then out[key]=bounded(value,limits[key][1],limits[key][2])
    elseif type(value)=="boolean" then out[key]=value end
  end
  return out
end

function B:NormalizeSituations()
  local source=self.db.situationSettings; local class=A.Class("player")
  if type(source)~="table" or (class and A.Text(source.class) and source.class~=class) then source={} end
  local legacy=source.version==1
  if legacy then
    -- Preserve drafts from the internal beta without enabling an unused setup.
    self.db.situationLegacyBackup=source
    self.db.situationLegacySoloBackup={}
    for _,list in pairs(keys) do for _,key in ipairs(list) do self.db.situationLegacySoloBackup[key]=clone(self.db[key]) end end
    if source.enabled and type(source.solo)=="table" then
      for category,values in pairs(source.solo) do
        if keys[category] and type(values)=="table" then
          for key,value in pairs(self:CleanSituationCategory(category,values)) do self.db[key]=clone(value) end
        end
      end
    end
  end
  local out={version=2,class=class or source.class,party={},raid={},spec={enabled=false}}
  if type(source.spec)=="table" then
    out.spec.enabled=source.spec.enabled==true
    for group=1,2 do
      if type(source.spec[group])=="table" then
        for category in pairs(keys) do
          if type(source.spec[group][category])=="table" then
            local clean=self:CleanSituationCategory(category,source.spec[group][category])
            if next(clean) then out.spec[group]=out.spec[group] or {}; out.spec[group][category]=clean end
          end
        end
      end
    end
  end
  for _,context in ipairs({"party","raid"}) do
    if (not legacy or source.enabled) and type(source[context])=="table" then
      for category,list in pairs(keys) do
        local values=source[context][category]
        if type(values)=="table" then
          local clean=self:CleanSituationCategory(category,values)
          if legacy then
            for _,key in ipairs(list) do
              if maps[key] then
                local patch={}; local base=self.db[key] or {}
                for k,v in pairs(clean[key] or {}) do if v~=base[k] then patch[k]=v end end
                for k in pairs(base) do if not clean[key] or clean[key][k]==nil then patch[k]=(key=="buffs" or key=="consumableFamilies") and "default" or false end end
                clean[key]=next(patch) and patch or nil
              elseif clean[key]==self.db[key] then clean[key]=nil end
            end
          end
          if next(clean) then out[context][category]=clean end
        end
      end
    end
  end
  self.db.situationSettings=out; self.situationDirty=true
end

function B:DetectSituation()
  if type(IsInInstance)=="function" then
    local ok,inside,kind=pcall(IsInInstance)
    if not ok or not A.Public(inside) or not A.Public(kind) then return "unknown" end
    if inside==true and (kind=="pvp" or kind=="arena") then return "pvp" end
  end
  local raid=A.Call(IsInRaid)
  if raid==true then return "raid" end
  if raid~=false then return "unknown" end
  if type(IsInGroup)=="function" then
    local group=A.Call(IsInGroup)
    if group==true then return "party" elseif group==false then return "solo" end
    return "unknown"
  end
  local count=A.Call(GetNumSubgroupMembers)
  if A.Number(count) then return count>0 and "party" or "solo" end
  return "unknown"
end

function B:Preference(key)
  local category=categoryFor[key]
  local live=category and self.situationLive and self.situationLive[category]
  local value=live and live[key]
  if value~=nil then return value end
  return self.db and self.db[key]
end

function B:InvalidateSituationState()
  self.situationRevision=(self.situationRevision or 0)+1
  self.rankChoiceCache=nil; self.resolveCache=nil; self.coverCache=nil
  self.refreshClassList=nil; self.weaponPending=nil
  if self.InvalidateRoster then self:InvalidateRoster() end
  self.nearbyNeedCache={}; self.nearbyNeedSettings=nil
  if self.InvalidateAura then self:InvalidateAura() end
  if self.InvalidateConsumables then self:InvalidateConsumables() end
  if self.InvalidateSupplies then self:InvalidateSupplies(false) end
end

function B:SyncSituation()
  if not self.db then return false end
  local context=self:DetectSituation()
  local spec=self:ActiveSpec() or false
  if A.Combat() then
    self.situationDeferred=context~=self.situationCurrent or self.situationDirty or spec~=self.specCurrent
    self:UpdateSituationStatus(); return false
  end
  local changed=self.situationCurrent~=context or self.situationDirty or spec~=self.specCurrent
  self.situationDeferred=nil
  if changed then
    self.situationCurrent=context; self.specCurrent=spec; self.situationLive={}
    if context=="party" or context=="raid" or spec then
      for category in pairs(keys) do self.situationLive[category]=self:SituationPreview(context,category,spec) end
    end
    self.situationDirty=nil
    if self.situationInitialized then self:InvalidateSituationState() end
    self.situationInitialized=true
  end
  self:UpdateSituationStatus(); return changed and true or false
end

function B:SituationValues(context,category)
  local root=self.db and self.db.situationSettings
  return root and root[context] and root[context][category]
end

-- spec: a group number, false for none, or nil for the spec being edited in Options (if the switch is on).
function B:SituationPreview(context,category,spec)
  if spec==nil then spec=self:EditSpec() end
  local values=self:SituationValues(context,category)
  local patch=(spec and self:SpecValues(spec,category)) or nil
  if not values and not patch then return self.db end
  local out={}
  for _,key in ipairs(keys[category]) do
    local base=self.db[key]; local value=values and values[key]; local layer=patch and patch[key]
    if maps[key] then
      local merged=clone(base) or {}
      for k,v in pairs(value or {}) do if v=="default" then merged[k]=nil else merged[k]=v end end
      -- The spec layer sits on top of the situation: "default" falls back to what the situation gave.
      local below=layer and clone(merged)
      for k,v in pairs(layer or {}) do if v=="default" then merged[k]=below[k] else merged[k]=v end end
      out[key]=merged
    else
      out[key]=value; if value==nil then out[key]=base end
      if layer~=nil then out[key]=layer end
    end
  end
  return out
end

function B:UpdateSituationStatus()
  local f=self.options; if not f or not f:IsShown() then return end
  if f.setupBadge then f.setupBadge:SetText(self:SituationBadge()) end
  for _,group in pairs(self.contextControls or {}) do group.active:SetText(self:SituationBadge()) end
end

function B:SituationActionCurrent(action)
  return not action or action.situationRevision==nil or action.situationRevision==(self.situationRevision or 0)
end

function B:SituationChanged(context)
  if A.Combat() then return false end
  self.situationDirty=true
  self:SyncSituation()
  if self.SaveClassSetup then self:SaveClassSetup() end
  if self.UpdateContextControls and self.options and self.options:IsShown() then self:UpdateContextControls() end
  self:RequestRefresh("context preferences changed",0)
  return true
end

function B:CustomizeSituation(context,category,custom)
  if A.Combat() or (context~="party" and context~="raid") or not keys[category] then return false end
  if not custom then self.db.situationSettings[context][category]=nil end
  return self:SituationChanged(context)
end

function B:SetSpecValue(spec,category,key,value,mapKey)
  if A.Combat() or (spec~=1 and spec~=2) or not self:SpecRoot() or categoryFor[key]~=category then return false end
  local root=self:SpecRoot()
  root[spec]=root[spec] or {}
  local values=root[spec][category] or {}; root[spec][category]=values
  if mapKey~=nil then
    if not maps[key] or type(mapKey)~="string" then return false end
    values[key]=values[key] or {}
    if value==nil then values[key][mapKey]=(key=="buffs" or key=="consumableFamilies") and "default" or false else values[key][mapKey]=value end
    if not next(values[key]) then values[key]=nil end
  elseif maps[key] and type(value)=="table" then
    local copy=clone(value); values[key]=next(copy) and copy or nil
  else values[key]=value end
  root[spec][category]=self:CleanSituationCategory(category,values)
  if not next(root[spec][category]) then root[spec][category]=nil end
  if not next(root[spec]) then root[spec]=nil end
  return self:SituationChanged()
end

function B:SetSituationValue(context,category,key,value,mapKey)
  if A.Combat() or not groups[context] or categoryFor[key]~=category then return false end
  local spec=self:EditSpec()
  if spec and self:SpecRoutes(category,key,mapKey) then return self:SetSpecValue(spec,category,key,value,mapKey) end
  if context=="solo" then
    if mapKey~=nil then self.db[key][mapKey]=value else self.db[key]=value end
  else
    local root=self.db.situationSettings[context]
    local values=root[category] or {}; root[category]=values
    if mapKey~=nil then
      if not maps[key] or type(mapKey)~="string" then return false end
      values[key]=values[key] or {}
      local base=self.db[key] and self.db[key][mapKey]
      if value==base then values[key][mapKey]=nil elseif value==nil then values[key][mapKey]=(key=="buffs" or key=="consumableFamilies") and "default" or false else values[key][mapKey]=value end
      if not next(values[key]) then values[key]=nil end
    else
      if maps[key] and type(value)=="table" then
        local patch={}; local base=self.db[key] or {}
        for k,v in pairs(value) do if v~=base[k] then patch[k]=v end end
        for k in pairs(base) do if value[k]==nil then patch[k]=(key=="buffs" or key=="consumableFamilies") and "default" or false end end
        values[key]=next(patch) and patch or nil
      else if value==self.db[key] then values[key]=nil else values[key]=value end end
    end
    root[category]=self:CleanSituationCategory(category,values)
    if not next(root[category]) then root[category]=nil end
  end
  return self:SituationChanged(context)
end

function B:EditorContext(category)
  self.editContexts=self.editContexts or {}
  return self.editContexts[category] or "solo"
end

function B:EditorSettings(category)
  self.contextEditors=self.contextEditors or {}
  if self.contextEditors[category] then return self.contextEditors[category] end
  local owner=self; local nested={}
  local proxy=setmetatable({}, {
    __index=function(_,key)
      if categoryFor[key]~=category then return owner.db[key] end
      if maps[key] then
        if not nested[key] then nested[key]=setmetatable({}, {
          __index=function(_,k) return owner:SituationPreview(owner:EditorContext(category),category)[key][k] end,
          __newindex=function(_,k,v) owner:SetSituationValue(owner:EditorContext(category),category,key,v,k) end
        }) end
        return nested[key]
      end
      return owner:SituationPreview(owner:EditorContext(category),category)[key]
    end,
    __newindex=function(_,key,value)
      if categoryFor[key]==category then owner:SetSituationValue(owner:EditorContext(category),category,key,value)
      else owner.db[key]=value end
    end
  })
  self.contextEditors[category]=proxy; return proxy
end

function B:SetEditorPreference(key,value)
  if self:IsGroupPreference(key) then self:GroupEditorSettings()[key]=value; return true end
  local category=categoryFor[key]
  if not category then return false end
  self:SetSituationValue(self:EditorContext(category),category,key,value); return true
end

function B:SituationSummary()
  if self.situationDeferred then return self:Text("Setup change waits until combat ends") end
  return self:SituationBadge()
end

function B:SituationBadge()
  return self:Text("Active setup: %s",self:Text(({party="Party",raid="Raid"})[self.situationCurrent] or "Solo"))
end




