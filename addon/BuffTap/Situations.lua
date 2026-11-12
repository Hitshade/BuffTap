-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local groups={solo=true,party=true,raid=true}
local keys={
  buffs={"buffs","priorities","buffSeconds","seconds"},
  weapons={"weaponReminder","weaponMainHand","weaponOffHand","weaponChoices","weaponCoatings","weaponSeconds"},
  consumables={"consumablesEnabled","consumableFamilies","consumableChoices","consumableSeconds"},
}
local categoryFor={}; for category,list in pairs(keys) do for _,key in ipairs(list) do categoryFor[key]=category end end
local limits={seconds={15,180},weaponSeconds={0,300}}
local maps={buffs=true,priorities=true,buffSeconds=true,weaponChoices=true,weaponCoatings=true,consumableFamilies=true,consumableChoices=true,consumableSeconds=true}
local function clone(value)
  if type(value)~="table" then return value end
  local copy={}; for key,v in pairs(value) do if type(key)=="string" and (type(v)=="boolean" or A.Text(v) or A.Number(v)) then copy[key]=v end end
  return copy
end
local function bounded(value,low,high) return A.Number(value) and math.max(low,math.min(high,math.floor(value))) or nil end

function B:CleanSituationCategory(category,source)
  local out={}; local class=A.Class("player")
  for _,key in ipairs(keys[category] or {}) do
    local value=source[key]
    if maps[key] and type(value)=="table" then
      local clean={}
      for name,v in pairs(value) do
        if type(name)=="string" then
          if key=="buffs" or key=="priorities" or key=="buffSeconds" then
            local def=self:FindBuff(name)
            if def and (not class or def.class==class) then
              if key=="buffs" and (type(v)=="boolean" or v=="default") then clean[name]=v
              elseif (key=="priorities" or key=="buffSeconds") and v==false then clean[name]=false
              elseif key=="priorities" then clean[name]=bounded(v,1,999)
              elseif key=="buffSeconds" then clean[name]=bounded(v,15,180) end
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
  local out={version=2,class=class or source.class,party={},raid={}}
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
  if A.Combat() then
    self.situationDeferred=context~=self.situationCurrent or self.situationDirty
    self:UpdateSituationStatus(); return false
  end
  local changed=self.situationCurrent~=context or self.situationDirty
  self.situationDeferred=nil
  if changed then
    self.situationCurrent=context; self.situationLive={}
    if context=="party" or context=="raid" then
      for category in pairs(keys) do self.situationLive[category]=self:SituationPreview(context,category) end
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

function B:SituationPreview(context,category)
  local values=self:SituationValues(context,category)
  if not values then return self.db end
  local out={}
  for _,key in ipairs(keys[category]) do
    local base=self.db[key]; local value=values[key]
    if maps[key] then
      local merged=clone(base) or {}
      for k,v in pairs(value or {}) do if v=="default" then merged[k]=nil else merged[k]=v end end
      out[key]=merged
    else out[key]=value; if value==nil then out[key]=base end end
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
  self:RequestRefresh("context preferences changed",0)
  return true
end

function B:CustomizeSituation(context,category,custom)
  if A.Combat() or (context~="party" and context~="raid") or not keys[category] then return false end
  if not custom then self.db.situationSettings[context][category]=nil end
  return self:SituationChanged(context)
end

function B:SetSituationValue(context,category,key,value,mapKey)
  if A.Combat() or not groups[context] or categoryFor[key]~=category then return false end
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




