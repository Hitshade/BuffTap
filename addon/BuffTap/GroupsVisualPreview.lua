-- Disposable Groups-only visual study. Remove this TOC entry to restore the shipped UI.
-- Presentation only: no saved preferences, layout coordinates or action callbacks.
local _,B=...
local T=B.OptionsTheme
local WHITE="Interface\\Buttons\\WHITE8X8"
local SERIF="Fonts\\FRIZQT__.TTF"
local function heading(text,size)
  if not text then return end
  text:SetFont(SERIF,size,"")
  text:SetTextColor(.94,.95,1,1)
  text:SetShadowColor(0,0,0,.8); text:SetShadowOffset(1,-1)
end
local function wash(owner,anchor,key,top,bottom)
  local texture=owner[key]
  if not texture then
    texture=owner:CreateTexture(nil,"BACKGROUND",nil,-5)
    texture:SetPoint("TOPLEFT",anchor,"TOPLEFT",8,-8)
    texture:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",-8,8)
    texture:SetTexture(WHITE); texture:SetBlendMode("ADD")
    owner[key]=texture
  end
  texture:SetGradient("VERTICAL",CreateColor(unpack(bottom)),CreateColor(unpack(top)))
  return texture
end
local function card(anchor,r,g,b)
  if not anchor or not anchor.box then return end
  anchor.box:SetFill(.035,.045,.078,1)
  anchor.box:SetBorder(r*.65+.15,g*.65+.15,b*.65+.15,.44)
  local owner=anchor:GetParent()
  if not anchor.studyWash then
    local texture=owner:CreateTexture(nil,"BACKGROUND",nil,-5)
    texture:SetPoint("TOPLEFT",anchor,"TOPLEFT",8,-8)
    texture:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",-8,8)
    texture:SetTexture(WHITE); texture:SetBlendMode("ADD"); anchor.studyWash=texture
    -- The original visibility helper owns these decorations too.
    anchor.edges[#anchor.edges+1]=texture
    local line=owner:CreateTexture(nil,"BORDER")
    line:SetPoint("TOPLEFT",anchor,"TOPLEFT",12,-1); line:SetPoint("TOPRIGHT",anchor,"TOPRIGHT",-12,-1)
    line:SetHeight(1); anchor.studyLine=line; anchor.edges[#anchor.edges+1]=line
  end
  anchor.studyWash:SetGradient("VERTICAL",CreateColor(.03,.04,.08,0),CreateColor(r*.16+.04,g*.16+.04,b*.16+.08,.30))
  anchor.studyLine:SetColorTexture(r,g,b,.33)
  anchor.studyWash:SetShown(anchor:IsShown()); anchor.studyLine:SetShown(anchor:IsShown())
end
local function control(frame,r,g,b)
  if not frame or not frame.visualRound then return end
  local selected=frame.navSelected
  if selected then
    frame:SetBackdropColor(r*.16+.045,g*.16+.05,b*.16+.09,1)
    frame:SetBackdropBorderColor(r,g,b,.88)
  else
    frame:SetBackdropColor(.055,.068,.10,1)
    frame:SetBackdropBorderColor(.38,.44,.60,.32)
  end
end
function B:ApplyGroupsVisualPreview()
  local f=self.options; local page=f and f.pages and f.pages[2]
  if not page then return end
  local r,g,b=self:InterfaceAccent()
  if not page.groupsStudyReady then
    page.groupsStudyReady=true
    page:SetBackdropColor(.018,.025,.047,1)
    page:SetBackdropBorderColor(.16,.20,.31,.35)
    wash(page,page,"groupsStudyAtmosphere",{.08,.10,.20,.46},{.015,.022,.04,0})
    page:HookScript("OnShow",function() B:ApplyGroupsVisualPreview() end)
  end
  local h=f.pageHeaders and f.pageHeaders[2]
  if h then
    heading(h.title,22)
    h.description:SetTextColor(.64,.70,.82,1)
  end
  if page.headerRule then page.headerRule:SetColorTexture(r,g,b,.26) end
  if f.groupContextHint then f.groupContextHint:SetTextColor(.62,.68,.80,1) end
  card(f.groupSharedCard,r,g,b); card(f.assignmentListCard,r,g,b)
  card(f.assignmentDetailCard,r,g,b); card(f.groupInfoCard,r,g,b)
  if f.groupSharedTitle then heading(f.groupSharedTitle,13); f.groupSharedTitle:SetTextColor(r,g,b,1) end
  heading(f.perBuffHeading,17)
  if f.assignmentListTitle then heading(f.assignmentListTitle,13) end
  if f.groupInstructions then f.groupInstructions:SetTextColor(.60,.67,.79,1) end
  for _,button in ipairs({f.partyView or f.groupParty,f.raidView or f.groupRaid}) do control(button,r,g,b) end
  for _,button in ipairs(f.assignButtons or {}) do control(button,r,g,b) end
  for _,row in ipairs(f.assignRows or {}) do
    heading(row.name,16)
    if row.detail then row.detail:SetTextColor(.57,.65,.80,1) end
    heading(row.groupHeading,13)
    -- A restrained line separates the spell identity from its controls.
    if not row.groupsStudyRule then
      local line=row:CreateTexture(nil,"BORDER"); line:SetPoint("TOPLEFT",8,-49)
      line:SetPoint("TOPRIGHT",-8,-49); line:SetHeight(1); row.groupsStudyRule=line
    end
    row.groupsStudyRule:SetColorTexture(.42,.49,.67,.25)
    control(row.sound,r,g,b)
  end
end
-- Keep existing navigation, theme updates and callbacks in charge; recolour afterward.
hooksecurefunc(B,"Options",function() B:ApplyGroupsVisualPreview() end)
hooksecurefunc(T,"Refresh",function() B:ApplyGroupsVisualPreview() end)
