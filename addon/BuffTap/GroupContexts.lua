-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
local A=B.API
local fields={group=true,smartGroup=true,groupNeed=true,blessingNeed=true,blessingAssignments=true,raidGroups=true,buffGroups=true,buffClasses=true,buffGroupNeed=true}
local classes={WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,SHAMAN=true,MAGE=true,WARLOCK=true,DRUID=true}
local proxySources=setmetatable({}, {__mode="k"})
local function clone(value)
  if proxySources[value] then value=proxySources[value]() end
  if type(value)~="table" then return value end
  local out={}; for k,v in pairs(value) do out[k]=clone(v) end; return out
end
local function clean(owner,values)
  local out={}
  for key in pairs(fields) do
    local value=values[key]; local base=owner.db[key]
    if key=="groupNeed" or key=="blessingNeed" then out[key]=A.Number(value) and math.max(2,math.min(5,math.floor(value+.5))) or base
    elseif key=="group" or key=="smartGroup" or key=="blessingAssignments" then out[key]=type(value)=="boolean" and value; if type(value)~="boolean" then out[key]=base end
    elseif key=="raidGroups" then
      out[key]={}; for i=1,8 do local v=type(value)=="table" and value[i]; if type(v)~="boolean" then v=base[i] end; out[key][i]=v end
    else
      out[key]={}
      for name,v in pairs(type(value)=="table" and value or {}) do
        local def=type(name)=="string" and owner:FindBuff(name)
        if def then
          if key=="buffGroupNeed" then if A.Number(v) then out[key][name]=math.max(2,math.min(5,math.floor(v+.5))) end
          elseif type(v)=="table" then
            local map={}; out[key][name]=map
            if key=="buffGroups" then for i=1,8 do if type(v[i])=="boolean" then map[i]=v[i] end end
            else for token,allowed in pairs(v) do if classes[token] and type(allowed)=="boolean" then map[token]=allowed end end end
          end
        end
      end
    end
  end
  return out
end
function B:NormalizeGroupContexts()
  local root=self.db.groupContextSettings; local class=A.Class("player")
  if type(root)~="table" or root.version~=1 or (class and root.class and root.class~=class) then root={version=1,class=class} end
  for _,context in ipairs({"Party","Raid"}) do if type(root[context])=="table" then root[context]=clean(self,root[context]) end end
  self.db.groupContextSettings=root
end
function B:ActiveGroupContext() return self.situationCurrent=="raid" and "Raid" or "Party" end
function B:EditingGroupContext()
  local f=self.options
  return f and (f.blessingContext or f.groupContext) or self:ActiveGroupContext()
end
function B:IsGroupPreference(key) return fields[key]==true end
function B:GroupSettings(context,write)
  context=context or self:ActiveGroupContext()
  local root=self.db.groupContextSettings
  if write then
    -- Snapshot both legacy configurations together on the first edit. Neither inherits Solo.
    for _,name in ipairs({"Party","Raid"}) do if not root[name] then root[name]=clean(self,self.db) end end
    self.situationDirty=true
  end
  return root and root[context] or self.db
end
function B:GroupPreference(key,context) return self:GroupSettings(context)[key] end
function B:GroupEditorSettings()
  if self.groupEditor then return self.groupEditor end
  local owner=self
  local function proxy(path)
    local children={}
    local function at(write)
      local value=owner:GroupSettings(owner:EditingGroupContext(),write)
      for _,key in ipairs(path) do value=value[key] end
      return value
    end
    local result=setmetatable({}, {
      __index=function(_,key)
        local value=at(false)[key]
        if type(value)~="table" then return value end
        if not children[key] then local nextPath={unpack(path)}; nextPath[#nextPath+1]=key; children[key]=proxy(nextPath) end
        return children[key]
      end,
      __newindex=function(_,key,value)
        if A.Combat() then return end
        if #path==0 and not fields[key] then return end
        at(true)[key]=clone(value)
        owner:RequestRefresh("group setup preference",0)
      end
    })
    proxySources[result]=function() return at(false) end
    return result
  end
  self.groupEditor=proxy({}); return self.groupEditor
end

