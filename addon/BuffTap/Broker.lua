-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. https://mozilla.org/MPL/2.0/.
local _,B=...
local A=B.API
local function lib(name) return LibStub and LibStub:GetLibrary(name,true) end
local function click()
  if A.Combat() then B.Print(B:Text("Settings are available after combat.")); return end
  if B.options and B.options:IsShown() then B.options:Hide() else B:Options() end
end
local function tooltip(t)
  t:AddLine("BuffTap "..B.version)
  t:AddLine(B:FriendlyStatus(),1,1,1,true)
  t:AddLine(B:Text("Click to open settings. Drag the minimap button to move it."),.8,.8,.8,true)
end
function B:UpdateBroker()
  local obj=self.brokerObject
  if not obj then return end
  local text=self.db.brokerEnabled and self:FriendlyStatus() or self:Text("Broker disabled — reload UI")
  if obj.text~=text then obj.text=text end
end
function B:SyncBroker()
  local d=self.db
  if type(d.minimap)~="table" then d.minimap={} end
  if type(d.minimap.hide)~="boolean" then d.minimap.hide=false end
  if not A.Number(d.minimap.minimapPos) then d.minimap.minimapPos=225 end
  d.minimap.minimapPos=d.minimap.minimapPos%360
  d.minimap.showInCompartment=nil
  if type(d.brokerEnabled)~="boolean" then d.brokerEnabled=false end
  self.minimapObject=self.minimapObject or {icon="Interface\\AddOns\\BuffTap\\Media\\BuffTapIcon",OnClick=click,OnTooltipShow=tooltip}
  local icon=lib("LibDBIcon-1.0")
  if icon and Minimap then
    if not icon:IsRegistered("BuffTap") then icon:Register("BuffTap",self.minimapObject,d.minimap)
    elseif self.minimapDB~=d.minimap then icon:Refresh("BuffTap",d.minimap) end
    self.minimapDB=d.minimap
    if d.minimap.hide then icon:Hide("BuffTap") else icon:Show("BuffTap") end
  end
  local ldb=lib("LibDataBroker-1.1")
  -- Register only after explicit opt-in. LDB does not define unregistering.
  if d.brokerEnabled and ldb and not self.brokerObject then
    self.brokerObject=ldb:NewDataObject("BuffTap",{type="data source",label="BuffTap",text="BuffTap",icon=self.minimapObject.icon,OnClick=click,OnTooltipShow=tooltip})
  end
  self:UpdateBroker()
end
