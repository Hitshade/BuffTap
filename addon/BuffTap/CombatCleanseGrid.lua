-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Fixed player/party/raid unit buttons; native aura overlays never own clicks.
local _,B=...
local A=B.API
local function L(s,...) return B:Text(s,...) end
local KINDS={"Magic","Curse","Poison","Disease"}
local function number(v,fallback,lo,hi)
  return A.Number(v) and math.max(lo,math.min(hi,v)) or fallback
end
local function rgb(v,fallback)
  if type(v)~="table" then v=fallback end
  return {number(v[1],fallback[1],0,1),number(v[2],fallback[2],0,1),number(v[3],fallback[3],0,1)}
end

function B:CombatGridSettings()
  local d=self.db or {}; local raw=type(d.combatGrid)=="table" and d.combatGrid or {}
  local g={size=math.floor(number(raw.size,20,18,64)),gap=math.floor(number(raw.gap,3,0,12)),
    columns=math.floor(number(raw.columns,5,1,10)),groupGap=math.floor(number(raw.groupGap,6,0,16)),
    subgroup=raw.subgroup~=false,direction=raw.direction or "right-down",style=raw.style=="classic" and "classic" or "modern",
    idleOpacity=number(raw.idleOpacity,.35,.05,1),idleColor=rgb(raw.idleColor,{.25,.27,.29}),
    classColors=raw.classColors==true,follow=raw.follow==true,x=number(raw.x,240,-10000,10000),y=number(raw.y,-140,-10000,10000),colors={}}
  if g.direction~="right-down" and g.direction~="down-right" and g.direction~="left-down" and g.direction~="right-up" then g.direction="right-down" end
  for _,kind in ipairs(KINDS) do g.colors[kind]=rgb(type(raw.colors)=="table" and raw.colors[kind],self.CleanseColors[kind]) end
  if g.follow then g.x=(d.x or 0)-g.size/2; g.y=(d.y or 0)+g.size/2 end
  return g
end

-- The SAME coordinates and full bounds are used by live buttons, panel preview and Edit Mode.
function B:CombatGridLayout(count,g)
  g=g or self:CombatGridSettings(); count=math.floor(number(count,40,0,40))
  local out={slots={},minX=0,maxY=0,width=0,height=0}; local minY,maxX=0,0
  local line=g.subgroup and 5 or g.columns
  for i=1,count do
    local along=(i-1)%line; local across=math.floor((i-1)/line)
    local pitch=g.size+g.gap; local extra=g.subgroup and across*g.groupGap or 0
    local x,y=along*pitch,-across*pitch-extra
    if g.direction=="down-right" then x,y=across*pitch+extra,-along*pitch
    elseif g.direction=="left-down" then x=-x
    elseif g.direction=="right-up" then y=-y end
    out.slots[i]={x=x,y=y}; out.minX=math.min(out.minX,x); out.maxY=math.max(out.maxY,y)
    maxX=math.max(maxX,x+g.size); minY=math.min(minY,y-g.size)
  end
  out.width=maxX-out.minX; out.height=out.maxY-minY
  return out
end

-- Allocate every raid token a distinct prepared position, including absent tokens.
-- Existing subgroup placement is read OUT of combat; newly occupied slots never overlap.
function B:CombatGridRaidPositions(g)
  local positions,used,counts={},{},{}
  if g.subgroup and type(GetRaidRosterInfo)=="function" then
    for i=1,40 do
      if A.Call(UnitExists,"raid"..i)==true then
        local ok,_,_,subgroup=pcall(GetRaidRosterInfo,i)
        if ok and A.Number(subgroup) and subgroup>=1 and subgroup<=8 and subgroup==math.floor(subgroup) then
          local n=(counts[subgroup] or 0)+1; counts[subgroup]=n
          if n<=5 then local slot=(subgroup-1)*5+n; positions[i]=slot; used[slot]=true end
        end
      end
    end
  end
  local free=1
  for i=1,40 do
    if not positions[i] then
      while used[free] do free=free+1 end
      positions[i]=free; used[free]=true
    end
  end
  return positions
end

local function place(f,g,layout)
  f:SetSize(layout.width,layout.height); f:ClearAllPoints()
  f:SetPoint("TOPLEFT",UIParent,"CENTER",g.x+layout.minX,g.y+layout.maxY)
  f:SetClampedToScreen(true)
end
local function idleColor(g,unit)
  local c=g.classColors and RAID_CLASS_COLORS and RAID_CLASS_COLORS[A.Class(unit) or ""]
  return c and {c.r,c.g,c.b} or g.idleColor
end
local function retire(self)
  local f=self.combatGridFrame
  if f then
    for _,b in ipairs(f.buttons) do UnregisterStateDriver(b,"visibility"); b:Hide(); if b.container then b.container:SetEnabled(false) end end
    f:Hide()
  end
  self.combatGridFrame=nil; self.combatGridSignature=nil; self.combatGridLayoutKey=nil
end
local function signature(g,plan)
  local parts={g.size,g.style}
  for _,kind in ipairs(KINDS) do for _,v in ipairs(g.colors[kind]) do parts[#parts+1]=v end end
  parts[#parts+1]=B:CombatCleansePlanKey(plan)
  return table.concat(parts,"|")
end

function B:ScheduleCombatGridSync()
  self.combatGridSyncPending=true
  self:StartTimer("combat-grid-setup",.15,function() B.combatGridSyncPending=nil; B:SyncCombatGrid() end)
end

function B:SyncCombatGrid()
  if not self.db or A.Combat() then return end
  local d=self.db
  if not d.enabled or not d.cleanseEnabled or d.combatCleanseGroup~=true then retire(self); self.combatGridError=nil; return end
  if self.combatGridSyncPending then return end
  local g=self:CombatGridSettings(); local plan=self:CombatCleansePlan()
  if #plan==0 then retire(self); self.combatGridError=L("No learned cleanse spell for the selected types."); return end
  local sig=signature(g,plan)
  local key={sig,self:GameplayStrata("buff"),tostring(self.combatGridRosterRevision or 0)}
  for _,name in ipairs({"gap","columns","groupGap","subgroup","direction","idleOpacity","classColors","follow","x","y"}) do key[#key+1]=tostring(g[name]) end
  for _,v in ipairs(g.idleColor) do key[#key+1]=tostring(v) end
  key=table.concat(key,"|")
  if self.combatGridFrame and self.combatGridLayoutKey==key then return end
  local layout=self:CombatGridLayout(40,g)
  if not self.combatGridFrame or self.combatGridSignature~=sig then
    local f=self.combatGridPool
    if not f then
      f=CreateFrame("Frame",nil,UIParent); f:Hide(); f:EnableMouse(false); f.buttons={}; self.combatGridPool=f
    end
    local ok,err=pcall(function()
      for i=1,45 do
        local unit=i<=40 and "raid"..i or i==41 and "player" or "party"..(i-41)
        local b=f.buttons[i]
        if not b then b=CreateFrame("Button",nil,f,"SecureActionButtonTemplate,SecureHandlerStateTemplate"); f.buttons[i]=b end
        b:Hide(); b.unitToken=unit; b.raidIndex=i<=40 and i or nil; b.partyIndex=i>40 and i-40 or nil
        b:SetSize(g.size,g.size); b:EnableMouse(true)
        self:ConfigureCombatCleanseButton(b,unit,plan,g.size,{compact=true,style=g.style,colors=g.colors})
        if not b.idle then
        b.idle=b:CreateTexture(nil,"BACKGROUND"); b.idle:SetAllPoints()
        for _,edge in ipairs({{"TOPLEFT","TOPRIGHT",g.size,1},{"BOTTOMLEFT","BOTTOMRIGHT",g.size,1},{"TOPLEFT","BOTTOMLEFT",1,g.size},{"TOPRIGHT","BOTTOMRIGHT",1,g.size}}) do
          local t=b:CreateTexture(nil,"BORDER"); t:SetPoint(edge[1],b,edge[1]); t:SetPoint(edge[2],b,edge[2]); if edge[3]==1 then t:SetWidth(1) else t:SetHeight(1) end; t:SetColorTexture(.1,.1,.1,.65)
        end
        end
        b:SetScript("OnEnter",function(s)
          if not GameTooltip then return end
          local name=self.FullUnitName and self.FullUnitName(s.unitToken)
          GameTooltip:SetOwner(s,"ANCHOR_RIGHT"); GameTooltip:SetText(A.Text(name) and name or s.unitToken)
          local seen={}
          for _,p in ipairs(s.cleansePlan or {}) do if not seen[p.button] then GameTooltip:AddLine(L(p.button==1 and "Left click" or "Right click")..": "..p.name,.85,.85,.85,true); seen[p.button]=true end end
          GameTooltip:AddLine(L(B.CombatCleanseSafetyText),1,.75,.35,true)
          GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        RegisterStateDriver(b,"visibility","[group:"..(i<=40 and "raid" or "party")..",@"..unit..",exists] show; hide")
      end
    end)
    if not ok then
      self.combatGridFrame=f; retire(self)
      self.combatGridError=A.Text(err) and err:sub(1,250) or L("Combat cleanse setup unavailable on this client.")
      return
    end
    self.combatGridFrame=f; self.combatGridSignature=sig; self.combatGridError=nil
  end
  local f=self.combatGridFrame; place(f,g,layout); f:SetFrameStrata(self:GameplayStrata("buff"))
  local raid=self:CombatGridRaidPositions(g)
  for _,b in ipairs(f.buttons) do
    local index=b.raidIndex and raid[b.raidIndex] or b.partyIndex
    local slot=layout.slots[index]; b.gridSlot=index
    b:ClearAllPoints(); b:SetPoint("TOPLEFT",f,"TOPLEFT",slot.x-layout.minX,slot.y-layout.maxY)
    local c=idleColor(g,b.unitToken); b.idle:SetColorTexture(c[1],c[2],c[3],g.idleOpacity)
  end
  f.layout=layout; f:Show(); self.combatGridLayoutKey=key
end

function B:SetCombatGridSetting(key,value)
  if A.Combat() then return false end
  local old=self:CombatGridSettings()
  if type(self.db.combatGrid)~="table" then self.db.combatGrid={} end
  if key=="follow" and value==false then self.db.combatGrid.x=old.x; self.db.combatGrid.y=old.y end
  self.db.combatGrid[key]=value
  self:ScheduleCombatGridSync(); self:UpdateCombatGridOptions()
  if self.editCombatGrid and self.editCombatGrid:IsShown() then self:ShowCombatGridEditPreview() end
  return true
end

-- Plain, non-casting 40-slot sample. Parent intercepts edit clicks; no secure payloads.
function B:RenderCombatGridPreview(f,g,layout)
  f.cells=f.cells or {}
  if not f.backing then
    f.backing=f:CreateTexture(nil,"BACKGROUND"); f.backing:SetPoint("TOPLEFT",-5,5); f.backing:SetPoint("BOTTOMRIGHT",5,-5)
    f.backing:SetColorTexture(.025,.03,.04,.88)
  end
  local samples={[4]={"Curse","Interface\\Icons\\Spell_Shadow_CurseOfTounges"},[12]={"Poison","Interface\\Icons\\Ability_Poisons"},
    [18]={"Magic","Interface\\Icons\\Spell_Frost_FrostNova"},[29]={"Disease","Interface\\Icons\\Spell_Shadow_AbominationExplosion"}}
  for i,slot in ipairs(layout.slots) do
    local b=f.cells[i]
    if not b then
      b=CreateFrame("Frame",nil,f); b:EnableMouse(false)
      b.fill=b:CreateTexture(nil,"BACKGROUND"); b.fill:SetAllPoints()
      b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("TOPLEFT",2,-2); b.icon:SetPoint("BOTTOMRIGHT",-2,2)
      b.number=b:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); b.number:SetPoint("CENTER"); b.number:SetText(tostring(i))
      b.edges={}
      for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
        local t=b:CreateTexture(nil,"BORDER")
        if side=="TOP" or side=="BOTTOM" then t:SetPoint(side.."LEFT"); t:SetPoint(side.."RIGHT"); t:SetHeight(2)
        else t:SetPoint("TOP"..side); t:SetPoint("BOTTOM"..side); t:SetWidth(2) end
        b.edges[#b.edges+1]=t
      end
      f.cells[i]=b
    end
    b:SetSize(g.size,g.size); b:ClearAllPoints(); b:SetPoint("TOPLEFT",f,"TOPLEFT",slot.x-layout.minX,slot.y-layout.maxY)
    local sample=samples[i]
    local classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
    local classColor=g.classColors and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classes[(i-1)%#classes+1]]
    local c=sample and g.colors[sample[1]] or classColor and {classColor.r,classColor.g,classColor.b} or g.idleColor
    b.fill:SetColorTexture(c[1],c[2],c[3],sample and 1 or g.idleOpacity)
    b.icon:SetShown(sample~=nil); b.number:SetShown(sample==nil)
    if sample then b.icon:SetTexture(sample[2]); self:ApplyIconStyle(b,b.icon,g.style) end
    local font,_,flags=b.number:GetFont(); if font then b.number:SetFont(font,math.max(7,math.min(10,g.size*.4)),flags) end
    for _,edge in ipairs(b.edges) do edge:SetColorTexture(c[1],c[2],c[3],sample and 1 or .4) end
    b:Show()
  end
  f:SetSize(layout.width,layout.height); f.layout=layout
end

function B:ShowCombatGridEditPreview()
  if A.Combat() or not self.db then return end
  local f=self.editCombatGrid
  if not f then
    f=CreateFrame("Frame",nil,UIParent); f:SetFrameStrata("DIALOG"); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    for _,side in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
      local t=f:CreateTexture(nil,"OVERLAY")
      if side=="TOP" or side=="BOTTOM" then t:SetPoint(side.."LEFT",-2,0); t:SetPoint(side.."RIGHT",2,0); t:SetHeight(2)
      else t:SetPoint("TOP"..side,0,2); t:SetPoint("BOTTOM"..side,0,-2); t:SetWidth(2) end
      t:SetColorTexture(1,.5,0,1)
    end
    f.caption=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); f.caption:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,6)
    f.caption:SetText(L("Combat cleanse: 40 slots (drag to move)"))
    local header=f:CreateTexture(nil,"BACKGROUND"); header:SetPoint("TOPLEFT",f.caption,"TOPLEFT",-5,4); header:SetPoint("BOTTOMRIGHT",f.caption,"BOTTOMRIGHT",5,-4); header:SetColorTexture(.025,.03,.04,.92)
    f:SetScript("OnDragStart",function(s) if not A.Combat() then s.dragging=true; s:StartMoving() end end)
    f.savePosition=function(s)
      s:StopMovingOrSizing(); s.dragging=false; if A.Combat() then return end
      local left,top=s:GetLeft(),s:GetTop(); local cx,cy=UIParent:GetCenter()
      if A.Number(left) and A.Number(top) and A.Number(cx) and A.Number(cy) then
        self.db.combatGrid=self.db.combatGrid or {}
        self.db.combatGrid.x=left-cx-s.layout.minX; self.db.combatGrid.y=top-cy-s.layout.maxY; self.db.combatGrid.follow=false
        self:ScheduleCombatGridSync(); self:UpdateCombatGridOptions()
      end
    end
    f:SetScript("OnDragStop",f.savePosition); f:SetScript("OnMouseUp",function() end)
    self.editCombatGrid=f
  end
  local g=self:CombatGridSettings(); local layout=self:CombatGridLayout(40,g)
  self:RenderCombatGridPreview(f,g,layout); place(f,g,layout); f:Show()
end
function B:HideCombatGridEditPreview()
  local f=self.editCombatGrid
  if f then if f.dragging and not A.Combat() then f.savePosition(f) end; f:StopMovingOrSizing(); f.dragging=false; f:Hide() end
end

local showMovers=B.ShowEditMovers
function B:ShowEditMovers(...) showMovers(self,...); if self:CanCleanseAnything() then self:ShowCombatGridEditPreview() end end
local hideMovers=B.HideEditMovers
function B:HideEditMovers(...) self:HideCombatGridEditPreview(); hideMovers(self,...) end
local refresh=B.Refresh
function B:Refresh(...) local result=refresh(self,...); if not A.Combat() then self:SyncCombatGrid() end; return result end
local events=CreateFrame("Frame")
for _,event in ipairs({"GROUP_ROSTER_UPDATE","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","PLAYER_ENTERING_WORLD","SPELLS_CHANGED","UNIT_NAME_UPDATE","UNIT_CONNECTION","UNIT_FACTION"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_REGEN_DISABLED" then B:HideCombatGridEditPreview()
  else
    B.combatGridRosterRevision=(B.combatGridRosterRevision or 0)+1
    if not A.Combat() then B:ScheduleCombatGridSync() end
  end
end)
B.combatGridEvents=events

function B:OpenCombatGridColor(kind)
  if A.Combat() or not ColorPickerFrame or type(ColorPickerFrame.SetupColorPickerAndShow)~="function" then return end
  local g=self:CombatGridSettings(); local original=kind=="idle" and g.idleColor or g.colors[kind]
  local function apply(c)
    if kind=="idle" then self:SetCombatGridSetting("idleColor",c)
    else local colors=self:CombatGridSettings().colors; colors[kind]=c; self:SetCombatGridSetting("colors",colors) end
  end
  ColorPickerFrame:SetupColorPickerAndShow({r=original[1],g=original[2],b=original[3],
    swatchFunc=function() if not A.Combat() then local r,g,b=ColorPickerFrame:GetColorRGB(); apply({r,g,b}) end end,
    cancelFunc=function() if not A.Combat() then apply(original) end end})
end

local function section(ui,p,title,x,y,w,h)
  ui.card(p,x,y,w,h); B.OptionsTheme.SectionTitle(ui.label(p,title,x+16,y-14,"GameFontNormalSmall",w-32))
end
local DIRECTIONS={{key="right-down",name="Right, then down"},{key="down-right",name="Down, then right"},
  {key="left-down",name="Left, then down"},{key="right-up",name="Right, then up"}}
local build=B.BuildCleansePage
function B:BuildCleansePage(ui,...)
  build(self,ui,...)
  local f=self.options; local p=f.cleansePanes and f.cleansePanes.combat
  if not p then return end
  f.combatGridUI={}
  local controls=f.combatGridUI
  section(ui,p,"Combat cleansing",12,-108,692,82)
  controls.enabled=ui.check(p,"Party and raid",250,-137,function(c)
    if A.Combat() then return end
    B.db.combatCleanseGroup=c:GetChecked()==true; B:SyncCombatGrid(); B:UpdateCombatGridOptions()
  end)
  ui.help(controls.enabled,"Party and raid",L("Prepared click-to-cleanse frames for current party or raid members, including you. Frames remain visible while grouped. No automatic casts or normal binding changes.").."\n\n"..L(B.CombatCleanseSafetyText))
  ui.label(p,"Main-icon and group warnings are independent. L = left click; R = right click.",28,-165,"GameFontDisableSmall",650)
  section(ui,p,"Layout",12,-198,410,204)
  local function slider(key,title,y,low,high,unit)
    controls[key.."Label"]=ui.label(p,title,28,y,"GameFontHighlightSmall",116)
    local s=ui.slider(p,low,high,1,246,function(v) return tostring(v)..(unit and " "..unit or "") end,
      function(_,v) B:SetCombatGridSetting(key,v) end)
    s:SetPoint("TOPLEFT",154,y+4); controls[key]=s
  end
  slider("size","Icon size",-241,18,64,"px")
  slider("gap","Spacing",-277,0,12,"px")
  slider("columns","Icons per line",-313,1,10)
  ui.help(controls.columns,"Icons per line","Raid subgroup layout uses five icons per line. Turn off Group by raid subgroup to choose another number; your previous choice is kept.")
  ui.label(p,"Grow",28,-350,"GameFontHighlightSmall",110)
  controls.direction=ui.selector(p,"",154,-343,246,function() return DIRECTIONS end,function(key) B:SetCombatGridSetting("direction",key) end)
  controls.subgroup=ui.check(p,"Group by raid subgroup (five per line)",28,-375,function(c) B:SetCombatGridSetting("subgroup",c:GetChecked()==true) end)
  section(ui,p,"Appearance",12,-416,410,222)
  ui.label(p,"Idle opacity",28,-465,"GameFontHighlightSmall",115)
  controls.idleOpacity=ui.slider(p,5,100,1,246,function(v) return tostring(v).." %" end,function(_,v) B:SetCombatGridSetting("idleOpacity",v/100) end)
  controls.idleOpacity:SetPoint("TOPLEFT",154,-461)
  ui.label(p,"Style",28,-503,"GameFontHighlightSmall",110)
  controls.style=ui.selector(p,"",154,-496,246,function() return {{key="modern",name="Modern square"},{key="classic",name="Classic"}} end,function(key) B:SetCombatGridSetting("style",key) end)
  controls.classColors=ui.check(p,"Class idle colors",220,-535,function(c) B:SetCombatGridSetting("classColors",c:GetChecked()==true) end)
  controls.colorButtons={}
  local function color(kind,title,x,y,width)
    local b=ui.button(p,title,x,y,width,function() B:OpenCombatGridColor(kind) end)
    b.swatch=b:CreateTexture(nil,"OVERLAY"); b.swatch:SetSize(12,12); b.swatch:SetPoint("LEFT",6,0)
    controls.colorButtons[kind]=b
  end
  color("idle","Idle color",28,-530,165)
  ui.label(p,"Debuff colors",28,-578,"GameFontHighlightSmall",110)
  color("Magic","Magic",154,-566,118); color("Curse","Curse",282,-566,118)
  color("Poison","Poison",154,-602,118); color("Disease","Disease",282,-602,118)
  section(ui,p,"Preview",438,-198,266,440)
  local host=CreateFrame("Frame",nil,p); host:SetPoint("TOPLEFT",450,-238); host:SetSize(242,340); host:EnableMouse(false)
  controls.preview=CreateFrame("Frame",nil,host); controls.preview:EnableMouse(false)
  controls.footprint=ui.label(p,"",452,-592,"GameFontDisableSmall",240)
  controls.status=ui.label(p,"Edit Mode shows all 40 at actual size.",452,-612,"GameFontDisableSmall",240)
  section(ui,p,"Position",12,-652,692,68)
  controls.follow=ui.check(p,"Follow my buff icon",28,-683,function(c) B:SetCombatGridSetting("follow",c:GetChecked()==true) end)
  controls.move=ui.button(p,"Move frames",378,-681,148,function()
    if A.Combat() then return end
    B:MoveAllFrames("cleanse-combat")
  end)
  controls.reset=ui.button(p,"Reset frames",538,-681,148,function()
    if A.Combat() then return end
    B.db.combatGrid={}; B:ScheduleCombatGridSync(); B:UpdateCombatGridOptions()
    if B.editCombatGrid and B.editCombatGrid:IsShown() then B:ShowCombatGridEditPreview() end
  end)
  self:UpdateCombatGridOptions()
end

function B:UpdateCombatGridOptions()
  local c=self.options and self.options.combatGridUI
  if not c then return end
  local g=self:CombatGridSettings(); c.enabled:SetChecked(self.db.combatCleanseGroup==true); c.enabled:SetEnabled(self:CanCleanseAnything())
  for _,key in ipairs({"size","gap","columns","idleOpacity"}) do
    local s=c[key]; s.silent=true; s:SetValue(key=="idleOpacity" and math.floor(g.idleOpacity*100+.5) or key=="columns" and g.subgroup and 5 or g[key]); s.silent=nil
  end
  c.columnsLabel:SetText(L(g.subgroup and "Per line: 5 (subgroups)" or "Icons per line"))
  c.columns:SetAlpha(g.subgroup and .4 or 1)
  c.columns:SetEnabled(not g.subgroup); c.subgroup:SetChecked(g.subgroup); c.classColors:SetChecked(g.classColors); c.follow:SetChecked(g.follow)
  c.style:SetText(L(g.style=="modern" and "Modern square" or "Classic"))
  for _,v in ipairs(DIRECTIONS) do if v.key==g.direction then c.direction:SetText(L(v.name)) end end
  for kind,b in pairs(c.colorButtons) do
    local color=kind=="idle" and g.idleColor or g.colors[kind]; b.swatch:SetColorTexture(color[1],color[2],color[3],1)
    b:SetEnabled(ColorPickerFrame and type(ColorPickerFrame.SetupColorPickerAndShow)=="function" or false)
  end
  local layout=self:CombatGridLayout(40,g); local f=c.preview
  self:RenderCombatGridPreview(f,g,layout)
  f:SetScale(math.min(1,242/layout.width,340/layout.height)); f:ClearAllPoints(); f:SetPoint("CENTER",f:GetParent(),"CENTER",0,0); f:Show()
  c.footprint:SetText(L("40 players: %d x %d px",layout.width,layout.height))
  local tooLarge=layout.width>UIParent:GetWidth() or layout.height>UIParent:GetHeight()
  c.status:SetText(self.combatGridError and L("Setup unavailable. See Full check-up.") or tooLarge and L("Too large for the screen. Reduce size or change layout.") or L("Edit Mode shows all 40 at actual size."))
end
local update=B.UpdateCleansePage
function B:UpdateCleansePage(...) update(self,...); self:UpdateCombatGridOptions() end

local probe=B.CombatCleanseProbeLines
function B:CombatCleanseProbeLines()
  local lines=probe(self)
  lines[#lines+1]="Group cleanse: enabled="..tostring(self.db and self.db.combatCleanseGroup==true).." | prepared slots="..tostring(self.combatGridFrame and #self.combatGridFrame.buttons or 0).." | layout changes after combat"
  lines[#lines+1]="Group cleanse setup: "..(self.combatGridError or "no setup error recorded")
  lines[#lines+1]="Last prepared click unit: "..tostring(self.combatCleanseLastUnit or "none")
  return lines
end
