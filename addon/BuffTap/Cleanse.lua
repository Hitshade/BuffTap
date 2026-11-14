-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Cleanse: offer the right removal spell for a poison, curse, disease or magic effect on you,
-- your group, your friendly target or (optionally) Nearby players. Out of combat only, like
-- buffs: BuffTap prepares the spell and the player still clicks or presses the key.
-- A due cleanse comes before buffs.
local _,B=...
local A=B.API
local L=function(...) return B:Text(...) end

B.CleanseTypes={"Magic","Curse","Poison","Disease"}
B.CleanseColors={Magic={.2,.6,1},Curse={.6,0,1},Poison={0,.6,0},Disease={.6,.4,0}}

-- Removal spells by class and type, best first. "abolish" entries remove over time.
local SPELLS={
  DRUID={Curse={{2782}},Poison={{2893,abolish=true},{8946}}},
  MAGE={Curse={{475}}},
  PRIEST={Magic={{988},{527}},Disease={{552,abolish=true},{528}}},
  PALADIN={Poison={{4987},{1152}},Disease={{4987},{1152}},Magic={{4987}}},
  SHAMAN={Poison={{526}},Disease={{2870}}},
}
local ABOLISH_AURAS={[2893]=true,[552]=true}
-- Debuffs never offered: removing them hurts, or they are part of an encounter.
B.CleanseBuiltInNever={
  [28169]={name="Mutating Injection",note="Built in: explodes when removed"},
}

local function known(id)
  return A.Known(id) or A.Call(IsPlayerSpell,id)==true
end
local function spellInfo(id)
  local name=A.Call(C_Spell and C_Spell.GetSpellName,id)
  if not A.Text(name) then local ok,n=pcall(GetSpellInfo,id); name=ok and A.Text(n) and n or nil end
  if not name then return nil end
  return name,A.Call(C_Spell and C_Spell.GetSpellTexture,id)
end

-- Which types this character can remove right now, with the spells for each.
function B:CleanseAbilities()
  local class=A.Class("player"); local out={}
  for type,list in pairs(SPELLS[class] or {}) do
    for _,spec in ipairs(list) do
      if known(spec[1]) then out[type]=out[type] or {}; out[type][#out[type]+1]=spec end
    end
  end
  return out
end
function B:CleanseClassSpells(type)
  return SPELLS[A.Class("player")] and SPELLS[A.Class("player")][type]
end
function B:CanCleanseAnything()
  return SPELLS[A.Class("player")]~=nil
end

-- Never-cleanse list shared by every character (account-wide).
function B:CleanseNeverList()
  local global=self.profileDB and self.profileDB.global
  if not global then self.cleanseNeverSession=self.cleanseNeverSession or {}; return self.cleanseNeverSession end
  if type(global.cleanseNever)~="table" then global.cleanseNever={} end
  return global.cleanseNever
end
function B:SetCleanseNever(name,blocked)
  if not A.Text(name) then return end
  name=name:match("^%s*(.-)%s*$"); if name=="" then return end
  self:CleanseNeverList()[name:lower()]=blocked and name or nil
  self:RequestRefresh("never cleanse changed",0)
end
local function neverOffer(self,debuff)
  if debuff.spellId and B.CleanseBuiltInNever[debuff.spellId] then return true end
  local list=self:CleanseNeverList()
  return debuff.name and list[debuff.name:lower()]~=nil
end

-- Debuffs on a unit, with dispel type, stacks and time left.
local function debuffs(unit)
  local out={}
  for i=1,40 do
    local name,icon,count,kind,duration,expires,spellId
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex)=="function" then
      local ok,data=pcall(C_UnitAuras.GetAuraDataByIndex,unit,i,"HARMFUL")
      if not ok or type(data)~="table" or not A.Public(data) then break end
      name,icon,count,kind,duration,expires,spellId=data.name,data.icon,data.applications,data.dispelName,data.duration,data.expirationTime,data.spellId
    elseif type(UnitDebuff)=="function" then
      local ok,n,ic,c,k,d,e,_,_,_,id=pcall(UnitDebuff,unit,i)
      if not ok or not n then break end
      name,icon,count,kind,duration,expires,spellId=n,ic,c,k,d,e,id
    else break end
    if not A.Text(name) then break end
    out[#out+1]={name=name,icon=icon,stacks=A.Number(count) and count or 0,type=A.Text(kind) and kind or nil,
      duration=A.Number(duration) and duration or 0,expires=A.Number(expires) and expires or 0,spellId=A.Number(spellId) and spellId or nil}
  end
  return out
end
local function hasAbolish(unit)
  for i=1,40 do
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex)=="function" then
      local ok,data=pcall(C_UnitAuras.GetAuraDataByIndex,unit,i,"HELPFUL")
      if not ok or type(data)~="table" or not A.Public(data) then return false end
      if A.Number(data.spellId) and ABOLISH_AURAS[data.spellId] then return true end
    elseif type(UnitBuff)=="function" then
      local ok,n,_,_,_,_,_,_,_,_,id=pcall(UnitBuff,unit,i)
      if not ok or not n then return false end
      if ABOLISH_AURAS[id] then return true end
    else return false end
  end
  return false
end
B.CleanseDebuffs=debuffs

local function pvpUnsafe(self,unit)
  if unit=="player" or not self.PvPGuardActive or not self:PvPGuardActive() then return false end
  local pvp,ffa=A.Call(UnitIsPVP,unit),A.Call(UnitIsPVPFreeForAll,unit)
  return pvp~=false or ffa~=false
end

-- Pick the spell for one debuff: Abolish when the effect has stacks, when several of that type
-- are on the player, or when it will last a while; a single short one gets the plain cure.
function B:CleanseSpellFor(debuff,sameType,abilities)
  local specs=abilities[debuff.type]; if not specs then return nil end
  local left=debuff.expires>0 and debuff.expires-GetTime() or math.huge
  local wantAbolish=self.db.cleansePreferAbolish~=false and (debuff.stacks>=2 or sameType>=2 or left>8)
  for _,spec in ipairs(specs) do
    if spec.abolish and wantAbolish then return spec[1],true end
  end
  for _,spec in ipairs(specs) do
    if not spec.abolish then return spec[1],false end
  end
  return specs[1][1],specs[1].abolish==true
end

local function usable(id)
  if A.SpellUsable(id)==false then return false end
  local cd=A.Call(C_Spell and C_Spell.GetSpellCooldown,id)
  if type(cd)=="table" and A.Number(cd.startTime) and A.Number(cd.duration) and cd.startTime>0 and cd.duration>1.6 then return false end
  return true
end

-- First thing to remove on one unit, or nil.
function B:CleanseNeed(unit,abilities)
  if A.Call(UnitExists,unit)~=true or A.Call(UnitIsDeadOrGhost,unit)~=false then return nil end
  local list=debuffs(unit)
  if #list==0 then return nil end
  local counts={}
  for _,d in ipairs(list) do if d.type then counts[d.type]=(counts[d.type] or 0)+1 end end
  local abolishRunning
  for _,d in ipairs(list) do
    local left=d.expires>0 and d.expires-GetTime() or math.huge
    if d.type and abilities[d.type] and self.db.cleanseTypes[d.type]~=false and left>3 and not neverOffer(self,d) then
      local id,abolish=self:CleanseSpellFor(d,counts[d.type],abilities)
      if id then
        -- Abolish already ticking on this player: let it work.
        if abolishRunning==nil then abolishRunning=hasAbolish(unit) end
        local abolishType=d.type=="Poison" or d.type=="Disease"
        if not (abolishRunning and abolishType and abilities[d.type][1].abolish) then
          return d,id,abolish
        end
      end
    end
  end
end

local function groupUnits()
  local units={}
  if A.Call(IsInRaid)==true then
    local n=A.Call(GetNumGroupMembers) or 0
    for i=1,math.min(n,40) do local u="raid"..i; if A.Call(UnitIsUnit,u,"player")~=true then units[#units+1]=u end end
  else
    local n=A.Call(GetNumSubgroupMembers) or 0
    for i=1,math.min(n,4) do units[#units+1]="party"..i end
  end
  return units
end

function B:BuildCleanseAction(unit,debuff,id,abolish,nearby)
  local name,icon=spellInfo(id)
  if not name then return nil end
  local action={id=id,spellName=name,icon=icon or debuff.icon,target=unit,known=true,secureType="spell",valid=true,
    source="cleanse",cleanse=true,dispelType=debuff.type,debuffName=debuff.name,debuffID=debuff.spellId,stacks=debuff.stacks,abolish=abolish,
    key="cleanse:"..debuff.type..":"..tostring(debuff.spellId or debuff.name)}
  action.name=L("Cleanse: %s",debuff.name)..(debuff.stacks>=2 and " ("..debuff.stacks..")" or "")
  action.targetName=A.Call(UnitName,unit) or unit
  action.targetGUID=A.Call(UnitGUID,unit)
  action.reason="cleanse: "..debuff.type.." on "..tostring(unit)
  if nearby then action.nearby=true; action.quickTarget=true end
  return action
end

local function tryUnit(self,unit,abilities,nearby)
  local debuff,id,abolish=self:CleanseNeed(unit,abilities)
  if not debuff then return nil end
  if not usable(id) then return nil end
  local action=self:BuildCleanseAction(unit,debuff,id,abolish,nearby)
  if not action then return nil end
  local inRange=self:SpellRange(action)
  if inRange==false then return nil end
  if nearby and not self:PrepareNearbyCast(action) then return nil end
  return action
end

function B:SelectCleanse()
  local d=self.db
  if not d or not d.enabled or d.cleanseEnabled~=true or A.Combat() then return nil,"cleanse off" end
  if A.Call(UnitIsDeadOrGhost,"player")~=false then return nil,"dead" end
  if self:ReminderPauseReason() then return nil,"paused" end
  if A.Call(UnitCastingInfo,"player")~=nil or A.Call(UnitChannelInfo,"player")~=nil then return nil,"casting" end
  local abilities=self:CleanseAbilities()
  if not next(abilities) then return nil,"no cleanse spells" end
  local action
  if d.cleanseSelf~=false then action=tryUnit(self,"player",abilities) end
  if not action and d.cleanseGroup~=false then
    for _,unit in ipairs(groupUnits()) do
      if not pvpUnsafe(self,unit) then action=tryUnit(self,unit,abilities); if action then break end end
    end
  end
  if not action and d.cleanseTarget~=false and A.Call(UnitExists,"target")==true
    and A.Call(UnitIsUnit,"target","player")~=true and A.Call(UnitIsPlayer,"target")==true
    and A.Call(UnitCanAssist,"player","target")==true and A.Call(UnitInParty,"target")~=true and not A.Number(A.Call(UnitInRaid,"target"))
    and not pvpUnsafe(self,"target") and not (self.BlockReason and d.blacklistTargets~=false and self:BlockReason("target")) then
    action=tryUnit(self,"target",abilities)
  end
  if not action and d.cleanseNearby==true and d.nearbyEnabled and self.nearbyUnits then
    for unit,guid in pairs(self.nearbyUnits) do
      if A.Call(UnitGUID,unit)==guid and A.Call(UnitIsPlayer,unit)==true and A.Call(UnitCanAssist,"player",unit)==true
        and not self:NearbyGroupMember(unit) and self:NearbyRecipientSafe(unit) and not (self.BlockReason and self:BlockReason(unit))
        and not pvpUnsafe(self,unit) then
        action=tryUnit(self,unit,abilities,true); if action then break end
      end
    end
  end
  if action then action.selectedAt=GetTime(); return action,"cleanse" end
  return nil,"nothing to cleanse"
end

-- Click-time check: same player, the debuff is still there, spell still usable and in range.
function B:ValidateCleanse(action)
  if not action or A.Combat() or self.db.cleanseEnabled~=true then return false end
  if A.Call(UnitGUID,action.target)~=action.targetGUID then return false end
  local abilities=self:CleanseAbilities()
  local found=false
  for _,d in ipairs(debuffs(action.target)) do
    if d.type==action.dispelType and (d.spellId==action.debuffID or d.name==action.debuffName) then found=true; break end
  end
  if not found or not abilities[action.dispelType] or not usable(action.id) then return false end
  if self:SpellRange(action)==false then return false end
  return true
end

-- Cleanses come before buffs.
local baseSelect=B.Select
function B:Select()
  local ok,action=pcall(self.SelectCleanse,self)
  if ok and action then
    -- Clear what the buff pass would have reported, so status text doesn't show stale reasons.
    self.rangeBlocked=false; self.rangeBlockedActions={}; self.rangeBlockedKeys={}
    self.powerBlocked=false; self.manaFloorBlocked=nil; self.manaBlocked=false; self.cooldownBlocked=false
    self.dataPending=false; self.targetDataPending=false; self.pvpBlocked=false; self.nextWakeDelay=nil
    return action,"cleanse"
  end
  return baseSelect(self)
end
-- Nearby players are cast on by a short targeting macro, as for buffs. Cleanse spells have one rank.
local basePrepare=B.PrepareNearbyCast
function B:PrepareNearbyCast(action)
  if not action or action.source~="cleanse" then return basePrepare(self,action) end
  self.nearbyCastError=nil
  if not self:NearbyRecipientSafe(action.target) then self.nearbyCastError=self.nearbySafetyReason; return false end
  if not A.Text(action.target) or not action.target:match("^nameplate%d+$") or not A.Text(action.spellName) then return false end
  if action.spellName:find("[%c%[%];/|]") then return false end
  local recipient=self:NearbyCastName(action)
  if not recipient then return false end
  local exists=A.Call(UnitExists,"target")
  if type(exists)~="boolean" then return false end
  local same=exists and A.Call(UnitIsUnit,action.target,"target")==true
  local cast="/cast [help,nodead] "..action.spellName
  local macro=same and cast or "/cleartarget\n/targetexact "..recipient.."\n"..cast..(exists and "\n/targetlasttarget" or "\n/cleartarget")
  if #macro>255 then return false end
  action.secureType="macro"; action.macroText=macro
  return true
end
local baseValidate=B.Validate
function B:Validate(action)
  if action and action.source=="cleanse" then return self:ValidateCleanse(action) end
  return baseValidate(self,action)
end
-- A cleanse plays its own sound.
local basePlay=B.PlayAlert
function B:PlayAlert(kind,preview)
  if kind=="reminder" and not preview and self.action and self.action.source=="cleanse" then kind="cleanse" end
  return basePlay(self,kind,preview)
end
-- Border in the debuff type's colour around a cleanse reminder.
local baseOverlay=B.UpdateOverlay
function B:UpdateOverlay(...)
  local result=baseOverlay(self,...)
  local b=self.button
  if b then
    local a=self.action
    local color=a and a.source=="cleanse" and self.db.cleanseBorder~=false and B.CleanseColors[a.dispelType]
    if color then
      if not b.cleanseEdge then
        b.cleanseEdge=b:CreateTexture(nil,"BACKGROUND",nil,-7)
        b.cleanseEdge:SetPoint("TOPLEFT",-3,3); b.cleanseEdge:SetPoint("BOTTOMRIGHT",3,-3)
      end
      b.cleanseEdge:SetColorTexture(color[1],color[2],color[3],1); b.cleanseEdge:Show()
    elseif b.cleanseEdge then b.cleanseEdge:Hide() end
  end
  return result
end

-- Options: the Cleanse page (after My buffs). Built from the shared options helpers.
local TYPE_ORDER={"Poison","Curse","Disease","Magic"}
function B:BuildCleansePage(ui,tabs,headerSwitch,section)
  local f=self.options; local T=B.OptionsTheme; local p=f.pages[tabs.Cleanse]
  if not p then return end
  f.cleanseEnable=ui.check(p,"Enable cleansing",0,0,function(c)
    if A.Combat() then return end
    B.db.cleanseEnabled=c:GetChecked()==true; B:RequestRefresh("cleanse toggled",0); B:UpdateCleansePage()
  end)
  headerSwitch(f.cleanseEnable,p)
  section(ui,p,"What to remove",12,-76,692,196)
  f.cleanseRows={}
  for i,kind in ipairs(TYPE_ORDER) do
    local y=-112-(i-1)*30
    local swatch=p:CreateTexture(nil,"ARTWORK"); swatch:SetSize(10,10); swatch:SetPoint("TOPLEFT",30,y-9)
    local c=B.CleanseColors[kind]; swatch:SetColorTexture(c[1],c[2],c[3],1)
    local row={kind=kind,swatch=swatch}
    row.check=ui.check(p,kind,48,y,function(s)
      if A.Combat() then return end
      B.db.cleanseTypes[kind]=s:GetChecked()==true; B:RequestRefresh("cleanse types",0)
    end)
    row.spell=ui.label(p,"",260,y-8,"GameFontDisableSmall",420)
    f.cleanseRows[i]=row
  end
  f.cleansePreferAbolish=ui.check(p,"Prefer Abolish when the debuff has stacks or will last a while",48,-236,function(c)
    if A.Combat() then return end
    B.db.cleansePreferAbolish=c:GetChecked()==true; B:RequestRefresh("cleanse abolish",0)
  end)
  f.cleansePreferAbolish:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Prefer Abolish"),B:Text("Abolish keeps removing the effect as it ticks, so it handles stacks and several poisons or diseases at once. A single short one gets the plain cure.")) end)
  f.cleansePreferAbolish:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  section(ui,p,"Who",12,-286,692,84)
  local who={{"cleanseSelf","You",26},{"cleanseGroup","Your group",196},{"cleanseTarget","Your target",366},{"cleanseNearby","Nearby players",536}}
  f.cleanseWho={}
  for _,entry in ipairs(who) do
    local key=entry[1]
    f.cleanseWho[key]=ui.check(p,entry[2],entry[3],-326,function(c)
      if A.Combat() then return end
      B.db[key]=c:GetChecked()==true; B:RequestRefresh("cleanse who",0)
    end)
  end
  f.cleanseWho.cleanseNearby:HookScript("OnEnter",function(s) T.Tooltip(s,B:Text("Nearby players"),B:Text("Also offer to cleanse players in the Nearby list. Uses the same safety rules as Nearby buffing.")) end)
  f.cleanseWho.cleanseNearby:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  section(ui,p,"Alert",12,-384,692,84)
  ui.label(p,"Cleanse sound",26,-429,"GameFontHighlightSmall",110)
  f.cleanseSoundButton=ui.selector(p,"",138,-424,200,function() return B:SoundChoices() end,function(v) B.db.cleanseSound=v; B:UpdateCleansePage() end,true)
  ui.button(p,"Play",346,-424,80,function() if not B:PlayAlert("cleanse",true) then B.Print(B:Text("Sound preview unavailable.")) end end)
  f.cleanseBorder=ui.check(p,"Border colour by type",480,-426,function(c)
    B.db.cleanseBorder=c:GetChecked()==true; B:UpdateOverlay()
  end)
  section(ui,p,"Never cleanse (shared by all your characters)",12,-482,692,236)
  f.cleanseInput=ui.editbox(p,26,-522,260,false); f.cleanseInput:SetMaxLetters(80)
  local function add()
    local text=f.cleanseInput:GetText()
    if A.Text(text) then B:SetCleanseNever(text,true); f.cleanseInput:SetText(""); f.cleanseInput:ClearFocus(); B:UpdateCleansePage() end
  end
  f.cleanseInput:SetScript("OnEnterPressed",add)
  f.cleanseInput:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)
  ui.button(p,"Add",298,-520,90,add)
  ui.label(p,"Type the debuff's name, or right-click a cleanse reminder to add it.",400,-526,"GameFontDisableSmall",290)
  f.cleanseScroll=CreateFrame("ScrollFrame",nil,p,"UIPanelScrollFrameTemplate")
  f.cleanseScroll:SetPoint("TOPLEFT",26,-558); f.cleanseScroll:SetSize(640,150)
  f.cleanseList=CreateFrame("Frame",nil,f.cleanseScroll); f.cleanseList:SetSize(640,150); f.cleanseScroll:SetScrollChild(f.cleanseList)
  f.cleanseListRows={}
  function f.cleanseRow(index)
    local row=f.cleanseListRows[index]; if row then return row end
    row=CreateFrame("Frame",nil,f.cleanseList); row:SetSize(640,28); row:SetPoint("TOPLEFT",0,-(index-1)*30)
    row.text=ui.label(row,"",6,-7,"GameFontHighlight",360)
    row.note=ui.label(row,"",370,-8,"GameFontDisableSmall",260)
    row.remove=ui.button(row,"Remove",540,-2,96,function()
      if row.name and not A.Combat() then B:SetCleanseNever(row.name,false); B:UpdateCleansePage() end
    end)
    f.cleanseListRows[index]=row; return row
  end
end

local function knownNames(self,kind)
  local names={}
  for _,spec in ipairs(self:CleanseClassSpells(kind) or {}) do
    if known(spec[1]) then local name=spellInfo(spec[1]); if name then names[#names+1]=name end end
  end
  return names
end
function B:UpdateCleansePage()
  local f=self.options
  if not f or not f.cleanseEnable then return end
  local d=self.db
  f.cleanseEnable:SetChecked(d.cleanseEnabled==true)
  for _,row in ipairs(f.cleanseRows) do
    local classCan=self:CleanseClassSpells(row.kind)~=nil
    local names=classCan and knownNames(self,row.kind) or {}
    row.check:SetChecked(classCan and d.cleanseTypes[row.kind]~=false)
    row.check:SetEnabled(classCan and #names>0)
    row.swatch:SetAlpha(classCan and 1 or .3)
    row.spell:SetText(not classCan and self:Text("Your class can't remove this") or #names==0 and self:Text("Not learned yet") or table.concat(names,", "))
  end
  local abolish=(self:CleanseClassSpells("Poison") or self:CleanseClassSpells("Disease")) and true or false
  local hasAbolish=false
  for _,kind in ipairs({"Poison","Disease"}) do
    for _,spec in ipairs(self:CleanseClassSpells(kind) or {}) do if spec.abolish then hasAbolish=true end end
  end
  f.cleansePreferAbolish:SetChecked(d.cleansePreferAbolish~=false); f.cleansePreferAbolish:SetEnabled(abolish and hasAbolish)
  for key,check in pairs(f.cleanseWho) do check:SetChecked(key=="cleanseNearby" and d[key]==true or key~="cleanseNearby" and d[key]~=false) end
  f.cleanseBorder:SetChecked(d.cleanseBorder~=false)
  for _,choice in ipairs(self:SoundChoices()) do if choice.key==d.cleanseSound then f.cleanseSoundButton:SetText(self:Text(choice.name)) end end
  -- Never list: built-in entries first (locked), then the shared list, by name.
  local entries={}
  for id,entry in pairs(B.CleanseBuiltInNever) do entries[#entries+1]={name=entry.name,note=self:Text(entry.note),locked=true,sort="0"..entry.name:lower()} end
  for key,name in pairs(self:CleanseNeverList()) do entries[#entries+1]={name=type(name)=="string" and name or key,note="",sort="1"..key} end
  table.sort(entries,function(a,b) return a.sort<b.sort end)
  for i,entry in ipairs(entries) do
    local row=f.cleanseRow(i); row.name=entry.name
    row.text:SetText(entry.name); row.note:SetText(entry.note); row.remove:SetShown(not entry.locked); row:Show()
  end
  for i=#entries+1,#f.cleanseListRows do f.cleanseListRows[i]:Hide() end
  f.cleanseList:SetHeight(math.max(150,#entries*30))
end
