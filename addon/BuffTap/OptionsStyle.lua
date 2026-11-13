-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
-- Options theme. Presentation only: no settings, callbacks or saved data are changed here.
-- Rounded shapes are assembled from small generated textures (corner quadrants, rings, pills),
-- so every control keeps its native frame, size and scripts.
local _,B=...
local WHITE="Interface\\Buttons\\WHITE8X8"
local MEDIA="Interface\\AddOns\\BuffTap\\Media\\"
local T={
  window={.047,.054,.066,1}, sidebar={.036,.042,.052,1}, panel={0,0,0,0}, card={.071,.081,.099,1},
  control={.105,.118,.140,1}, field={.040,.047,.058,1}, menu={.058,.066,.081,.99}, border={1,1,1,.10},
  row={.088,.100,.121,1}, rowAlt={.078,.089,.108,1},
  gold={.91,.71,.36,1}, muted={.55,.59,.64,1}, text={.86,.88,.91,1}, accent={.91,.71,.36,1},
}
T.frameBorder={1,1,1,.065}
T.rule={1,1,1,.07}
T.media=MEDIA
B.OptionsTheme=T

local tracked=setmetatable({}, {__mode="k"})
function T.Track(control,kind) tracked[control]=kind end
local function accent() return T.accent[1],T.accent[2],T.accent[3] end

-- Typography: Inter (SIL Open Font License, Media/Fonts/OFL-Inter.txt), with Arial Narrow as a fallback.
local FONT_DIR=MEDIA.."Fonts\\Inter-"
T.fonts={}
local function font(key,weight,size,color,justify,flat)
  local name="BuffTapOptionsFont"..key
  local object=CreateFont(name)
  object:SetFont(FONT_DIR..weight..".ttf",size,"")
  if not object:GetFont() then object:SetFont("Fonts\\ARIALN.TTF",size+1,"") end
  object:SetTextColor(color[1],color[2],color[3],color[4] or 1)
  -- Dark text on gold reads as blurred with a drop shadow, so "flat" fonts have none.
  if flat then object:SetShadowColor(0,0,0,0); object:SetShadowOffset(0,0) else object:SetShadowColor(0,0,0,.5); object:SetShadowOffset(1,-1) end
  object:SetJustifyH(justify or "LEFT")
  T.fonts[key]=name; return object
end
local WHITE_TEXT={1,1,1,1}; local IDLE={.68,.71,.76,1}; local DARK={.06,.065,.08,1}
-- Type scale. Page title 18, subheading 14, section label 11 caps, control label 13, body 12, caption 11.
font("Title","SemiBold",18,WHITE_TEXT); font("Sub","SemiBold",14,WHITE_TEXT); font("Heading","Medium",13,T.text)
font("Body","Medium",13,T.text); font("Small","Regular",12,T.text); font("Muted","Regular",11,T.muted)
font("Note","Regular",12,T.text)
font("Section","SemiBold",11,T.gold); font("Value","Medium",12,T.text,"CENTER")
font("Button","Medium",12,T.text,"CENTER"); font("ButtonHover","Medium",12,WHITE_TEXT,"CENTER"); font("ButtonDisabled","Medium",12,T.muted,"CENTER")
font("ButtonLeft","Medium",12,T.text,"LEFT"); font("ButtonLeftHover","Medium",12,WHITE_TEXT,"LEFT"); font("ButtonLeftDisabled","Medium",12,T.muted,"LEFT")
font("ButtonDark","Bold",12,DARK,"CENTER",true)
font("ButtonFit","Medium",11,T.text,"CENTER"); font("ButtonFitHover","Medium",11,WHITE_TEXT,"CENTER"); font("ButtonFitDisabled","Medium",11,T.muted,"CENTER")
font("Nav","Medium",13,IDLE); font("NavActive","SemiBold",13,WHITE_TEXT)
font("Tab","Medium",12,IDLE,"CENTER"); font("TabActive","SemiBold",12,WHITE_TEXT,"CENTER")
local FONT_NAMES={
  GameFontNormalLarge="Sub", GameFontHighlightLarge="Sub", GameFontNormalHuge="Title",
  GameFontNormal="Heading", GameFontHighlight="Body", ChatFontNormal="Body",
  GameFontNormalSmall="Small", GameFontHighlightSmall="Small",
  GameFontDisableSmall="Muted", GameFontDisable="Muted",
}
function T.FontName(name)
  local key=FONT_NAMES[name or "GameFontNormal"]
  return key and T.fonts[key] or name
end
local function fontObject(key) return _G[T.fonts[key]] end
local fontMap
local function mappedFont(object)
  if not object then return end
  if not fontMap then
    fontMap={}
    for name,key in pairs(FONT_NAMES) do local game=_G[name]; if game then fontMap[game]=fontObject(key) end end
  end
  return fontMap[object]
end

-- Rounded box: four corner quadrants and three bands for the fill, plus a 1 px ring drawn on top.
local CORNERS={"TL","TR","BL","BR"}
local QUAD={TL={0,.5,0,.5},TR={.5,1,0,.5},BL={0,.5,.5,1},BR={.5,1,.5,1}}
local Box={}; Box.__index=Box
local function newBox(owner,layer,sub,radius)
  local box=setmetatable({fill={},ring={},all={},radius=radius},Box)
  local function texture(file,level)
    local t=owner:CreateTexture(nil,layer,nil,level); t:SetTexture(file); box.all[#box.all+1]=t; return t
  end
  for _,c in ipairs(CORNERS) do local t=texture(MEDIA.."UICornerFill",sub); t:SetTexCoord(unpack(QUAD[c])); t:SetSize(radius,radius); box.fill[c]=t end
  for _,k in ipairs({"top","mid","bottom"}) do box.fill[k]=texture(WHITE,sub) end
  for _,c in ipairs(CORNERS) do local t=texture(MEDIA.."UIRing"..radius,sub+1); t:SetTexCoord(unpack(QUAD[c])); t:SetSize(radius,radius); box.ring[c]=t end
  for _,k in ipairs({"top","bottom","left","right"}) do box.ring[k]=texture(WHITE,sub+1) end
  return box
end
function Box:Place(anchor,x1,y1,x2,y2)
  x1,y1,x2,y2=x1 or 0,y1 or 0,x2 or 0,y2 or 0
  for _,set in ipairs({self.fill,self.ring}) do
    set.TL:ClearAllPoints(); set.TL:SetPoint("TOPLEFT",anchor,"TOPLEFT",x1,y1)
    set.TR:ClearAllPoints(); set.TR:SetPoint("TOPRIGHT",anchor,"TOPRIGHT",x2,y1)
    set.BL:ClearAllPoints(); set.BL:SetPoint("BOTTOMLEFT",anchor,"BOTTOMLEFT",x1,y2)
    set.BR:ClearAllPoints(); set.BR:SetPoint("BOTTOMRIGHT",anchor,"BOTTOMRIGHT",x2,y2)
  end
  local f,g=self.fill,self.ring
  f.top:ClearAllPoints(); f.top:SetPoint("TOPLEFT",f.TL,"TOPRIGHT"); f.top:SetPoint("BOTTOMRIGHT",f.TR,"BOTTOMLEFT")
  f.mid:ClearAllPoints(); f.mid:SetPoint("TOPLEFT",f.TL,"BOTTOMLEFT"); f.mid:SetPoint("BOTTOMRIGHT",f.BR,"TOPRIGHT")
  f.bottom:ClearAllPoints(); f.bottom:SetPoint("TOPLEFT",f.BL,"TOPRIGHT"); f.bottom:SetPoint("BOTTOMRIGHT",f.BR,"BOTTOMLEFT")
  g.top:ClearAllPoints(); g.top:SetPoint("TOPLEFT",g.TL,"TOPRIGHT"); g.top:SetPoint("TOPRIGHT",g.TR,"TOPLEFT"); g.top:SetHeight(1)
  g.bottom:ClearAllPoints(); g.bottom:SetPoint("BOTTOMLEFT",g.BL,"BOTTOMRIGHT"); g.bottom:SetPoint("BOTTOMRIGHT",g.BR,"BOTTOMLEFT"); g.bottom:SetHeight(1)
  g.left:ClearAllPoints(); g.left:SetPoint("TOPLEFT",g.TL,"BOTTOMLEFT"); g.left:SetPoint("BOTTOMLEFT",g.BL,"TOPLEFT"); g.left:SetWidth(1)
  g.right:ClearAllPoints(); g.right:SetPoint("TOPRIGHT",g.TR,"BOTTOMRIGHT"); g.right:SetPoint("BOTTOMRIGHT",g.BR,"TOPRIGHT"); g.right:SetWidth(1)
end
function Box:SetFill(r,g,b,a) for _,k in ipairs({"TL","TR","BL","BR","top","mid","bottom"}) do self.fill[k]:SetVertexColor(r,g,b,a or 1) end end
function Box:SetBorder(r,g,b,a) for _,k in ipairs({"TL","TR","BL","BR","top","bottom","left","right"}) do self.ring[k]:SetVertexColor(r,g,b,a or 1) end end
function Box:SetShown(shown) for _,t in ipairs(self.all) do t:SetShown(shown) end end
T.NewBox=newBox

-- Horizontal pill in three slices, so the end caps stay round at any width.
local function newPill(owner,layer,sub)
  local pill={parts={}}
  for _,k in ipairs({"l","m","r"}) do local t=owner:CreateTexture(nil,layer,nil,sub); t:SetTexture(MEDIA.."UIPill"); pill[k]=t; pill.parts[#pill.parts+1]=t end
  pill.l:SetTexCoord(0,.25,0,1); pill.m:SetTexCoord(.25,.75,0,1); pill.r:SetTexCoord(.75,1,0,1)
  function pill.Set(self,anchor,x,y,w,h)
    local cap=h/2; w=math.max(w,h)
    self.l:ClearAllPoints(); self.l:SetPoint("LEFT",anchor,"LEFT",x,y); self.l:SetSize(cap,h)
    self.r:ClearAllPoints(); self.r:SetPoint("LEFT",anchor,"LEFT",x+w-cap,y); self.r:SetSize(cap,h)
    self.m:ClearAllPoints(); self.m:SetPoint("TOPLEFT",self.l,"TOPRIGHT"); self.m:SetPoint("BOTTOMRIGHT",self.r,"BOTTOMLEFT")
  end
  function pill.Color(self,r,g,b,a) for _,t in ipairs(self.parts) do t:SetVertexColor(r,g,b,a or 1) end end
  function pill.Shown(self,shown) for _,t in ipairs(self.parts) do t:SetShown(shown) end end
  return pill
end
T.NewPill=newPill

-- Soft drop shadow drawn outside a frame's rectangle, beneath its own fill.
function T.Shadow(frame,spread,alpha)
  if not frame or frame.visualShadow then return end
  spread=spread or 20; alpha=alpha or .6
  local parts={}
  local function piece(l,r,t,b) local tex=frame:CreateTexture(nil,"BACKGROUND",nil,-8); tex:SetTexture(MEDIA.."UIShadow"); tex:SetTexCoord(l,r,t,b); tex:SetVertexColor(0,0,0,alpha); parts[#parts+1]=tex; return tex end
  local tl,tr,bl,br=piece(0,.25,0,.25),piece(.75,1,0,.25),piece(0,.25,.75,1),piece(.75,1,.75,1)
  local dy=-4
  tl:SetSize(spread,spread); tl:SetPoint("BOTTOMRIGHT",frame,"TOPLEFT",0,dy)
  tr:SetSize(spread,spread); tr:SetPoint("BOTTOMLEFT",frame,"TOPRIGHT",0,dy)
  -- The bottom row starts at the frame's edge (stretched by the drop offset) so no light gap shows under the window.
  bl:SetSize(spread,spread-dy); bl:SetPoint("TOPRIGHT",frame,"BOTTOMLEFT",0,0)
  br:SetSize(spread,spread-dy); br:SetPoint("TOPLEFT",frame,"BOTTOMRIGHT",0,0)
  local top=piece(.25,.75,0,.25); top:SetPoint("BOTTOMLEFT",tl,"BOTTOMRIGHT"); top:SetPoint("TOPRIGHT",tr,"TOPLEFT")
  local bottom=piece(.25,.75,.75,1); bottom:SetPoint("TOPLEFT",bl,"TOPRIGHT"); bottom:SetPoint("BOTTOMRIGHT",br,"BOTTOMLEFT")
  local left=piece(0,.25,.25,.75); left:SetPoint("TOPRIGHT",tl,"BOTTOMRIGHT"); left:SetPoint("BOTTOMLEFT",bl,"TOPLEFT")
  local right=piece(.75,1,.25,.75); right:SetPoint("TOPLEFT",tr,"BOTTOMLEFT"); right:SetPoint("BOTTOMRIGHT",br,"TOPRIGHT")
  frame.visualShadow=parts
end

-- Glyph textures: "up", "down", "close", "check", "dash".
function T.Glyph(texture,kind,size,r,g,b,a)
  if not texture then return end
  local file=(kind=="up" or kind=="down") and "UIChevron" or kind=="close" and "UIClose" or kind=="dash" and "UIDash" or "UICheck"
  texture:SetTexture(MEDIA..file)
  if kind=="up" then texture:SetTexCoord(0,1,1,0) else texture:SetTexCoord(0,1,0,1) end
  if size then texture:SetSize(size,size) end
  texture:SetVertexColor(r or .70,g or .73,b or .78,a or 1)
end

-- Painting for rounded frames: hover, pressed, focused and disabled states.
local function paint(frame)
  local box=frame and frame.visualRound; if not box then return end
  if box.hidden then box:SetShown(false); return end
  box:SetShown(true)
  local base,edge=box.base.fill,box.base.border
  local fr,fg,fb,fa=base[1],base[2],base[3],base[4] or 1
  local er,eg,eb,ea=edge[1],edge[2],edge[3],edge[4] or 1
  local enabled=true
  if type(frame.IsEnabled)=="function" then enabled=frame:IsEnabled() and true or false end
  local ar,ag,ab=accent()
  if frame.visualInteractive and enabled and not frame.navSelected then
    if frame.visualDown then fr,fg,fb=fr*.82,fg*.82,fb*.82
    elseif frame.visualHover then
      if fa<.3 then fr,fg,fb,fa=1,1,1,.05
      elseif frame.visualVariant=="primary" then fr,fg,fb=math.min(1,fr*1.1+.02),math.min(1,fg*1.1+.02),math.min(1,fb*1.1+.02)
      else fr,fg,fb=fr+.03,fg+.032,fb+.036 end
      if frame.visualStyle~="sidebar" and frame.visualStyle~="underline" then
        if frame.visualVariant=="danger" then er,eg,eb,ea=.92,.38,.34,.85 elseif frame.visualVariant~="primary" then er,eg,eb,ea=ar,ag,ab,.7 end
      end
    end
  end
  if frame.visualFocusable and type(frame.HasFocus)=="function" and frame:HasFocus() then er,eg,eb,ea=ar,ag,ab,1 end
  if not enabled then fa=fa*.55; ea=ea*.45 end
  box:SetFill(fr,fg,fb,fa); box:SetBorder(er,eg,eb,ea)
end
T.Paint=paint

local function interactive(frame)
  if frame.visualInteractive then return end
  frame.visualInteractive=true
  local highlight=type(frame.GetHighlightTexture)=="function" and frame:GetHighlightTexture()
  if highlight then highlight:SetAlpha(0) end
  local hooks={
    OnEnter=function() frame.visualHover=true; paint(frame) end,
    OnLeave=function() frame.visualHover=false; frame.visualDown=false; paint(frame) end,
    OnMouseDown=function() frame.visualDown=true; paint(frame) end,
    OnMouseUp=function() frame.visualDown=false; paint(frame) end,
  }
  for event,fn in pairs(hooks) do frame:HookScript(event,fn) end
  -- Some controls replace OnEnter/OnLeave later (tooltips); re-attach the visual hooks when that happens.
  local setScript=frame.SetScript
  frame.SetScript=function(self,event,handler,...)
    setScript(self,event,handler,...)
    local hook=hooks[event]; if hook then self:HookScript(event,hook) end
  end
  for _,method in ipairs({"Enable","Disable","SetEnabled"}) do
    if type(frame[method])=="function" then hooksecurefunc(frame,method,paint) end
  end
end

-- Converts a frame to a rounded surface. Existing SetBackdropColor/SetBackdropBorderColor calls keep working.
local ROUNDED={}
function T.Round(frame,radius,role)
  if not frame then return end
  if frame.visualRound then return frame.visualRound end
  local fill,border,hidden
  if type(frame.GetBackdrop)=="function" then
    local info=frame:GetBackdrop()
    if info then
      if type(frame.GetBackdropColor)=="function" then fill={frame:GetBackdropColor()} end
      -- Only a backdrop that really draws an edge keeps its border colour; fill-only rows stay borderless.
      local hasEdge=info.edgeFile and type(info.edgeSize)=="number" and info.edgeSize>0
      if hasEdge and type(frame.GetBackdropBorderColor)=="function" then border={frame:GetBackdropBorderColor()} else border={0,0,0,0} end
      frame:SetBackdrop(nil)
    elseif role~="button" then hidden=true end
  end
  local box=newBox(frame,"BACKGROUND",-7,radius or 5); box:Place(frame)
  box.base={fill=(fill and fill[1]) and fill or {unpack(T.control)},border=(border and border[1]) and border or {unpack(T.border)}}
  box.hidden=hidden
  frame.visualRound=box
  frame.SetBackdropColor=function(self,r,g,b,a) box.base.fill={r,g,b,a or 1}; paint(self) end
  frame.SetBackdropBorderColor=function(self,r,g,b,a) box.base.border={r,g,b,a or 1}; paint(self) end
  frame.SetBackdrop=function(self,info) box.hidden=info==nil; paint(self) end
  frame.GetBackdrop=function() if box.hidden then return nil end return ROUNDED end
  frame.GetBackdropColor=function() return unpack(box.base.fill) end
  frame.GetBackdropBorderColor=function() return unpack(box.base.border) end
  if role=="button" then interactive(frame) end
  paint(frame); return box
end

-- Longer translations: a label that does not fit steps down one size instead of overflowing.
local function fitButton(button)
  if button.visualVariant=="primary" or button.visualFitting then return end
  local current=type(button.GetNormalFontObject)=="function" and button:GetNormalFontObject()
  if current~=_G[T.fonts.Button] and current~=_G[T.fonts.ButtonFit] then return end
  local text=button:GetFontString(); local width=button:GetWidth()
  if not text or type(width)~="number" or width<=0 then return end
  button.visualFitting=true
  button:SetNormalFontObject(T.fonts.Button); button:SetHighlightFontObject(T.fonts.ButtonHover); button:SetDisabledFontObject(T.fonts.ButtonDisabled)
  local measured=text:GetStringWidth()
  if type(measured)=="number" and measured>width-14 then
    button:SetNormalFontObject(T.fonts.ButtonFit); button:SetHighlightFontObject(T.fonts.ButtonFitHover); button:SetDisabledFontObject(T.fonts.ButtonFitDisabled)
  end
  text:SetWordWrap(false); button.visualFitting=nil
end
T.FitButton=fitButton
-- Standard button: rounded, centred text, hover and pressed states.
function T.Button(button)
  if not button then return end
  T.Round(button,5,"button")
  button:SetNormalFontObject(T.fonts.Button); button:SetHighlightFontObject(T.fonts.ButtonHover); button:SetDisabledFontObject(T.fonts.ButtonDisabled)
  if not button.visualFitHooked then
    button.visualFitHooked=true
    hooksecurefunc(button,"SetText",fitButton); button:HookScript("OnSizeChanged",fitButton)
  end
  fitButton(button)
  T.Track(button,"button")
end
-- Variants: "primary" (accent fill) and "danger" (red outline on hover).
function T.Variant(button,variant)
  if not button then return end
  T.Button(button); button.visualVariant=variant
  if variant=="primary" then
    local r,g,b=accent(); button:SetBackdropColor(r,g,b,1); button:SetBackdropBorderColor(r,g,b,1)
    button:SetNormalFontObject(T.fonts.ButtonDark); button:SetHighlightFontObject(T.fonts.ButtonDark)
    T.Track(button,"primary")
  end
end

local SURFACE_RADIUS={control=5,menu=6,panel=8,card=8,window=10,field=5}
function T.Surface(frame,kind)
  if not frame then return end
  kind=kind or "panel"
  if frame.optionsSurface==kind then return end
  frame.optionsSurface=kind
  if type(frame.SetBackdrop)=="function" and not frame.visualRound then
    frame:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
  end
  T.Round(frame,SURFACE_RADIUS[kind] or 6,"surface")
  local color=T[kind] or T.panel
  frame:SetBackdropColor(unpack(color))
  frame:SetBackdropBorderColor(unpack((kind=="panel" or kind=="card") and T.frameBorder or T.border))
  if kind=="menu" then T.Shadow(frame,14,.5) end
end

-- Section boxes. Returns an invisible anchor texture; the rounded box follows it.
function T.Card(parent,x,y,width,height)
  if x==12 and width==698 then width=692 end
  local anchor=parent:CreateTexture(nil,"BACKGROUND",nil,-8); anchor:SetColorTexture(0,0,0,0)
  anchor:SetPoint("TOPLEFT",x,y); anchor:SetSize(width,height); anchor.optionsDecoration=true
  local box=newBox(parent,"BACKGROUND",-6,8); box:Place(anchor); box:SetFill(unpack(T.card)); box:SetBorder(unpack(T.frameBorder))
  for _,t in ipairs(box.all) do t.optionsDecoration=true end
  anchor.edges=box.all; anchor.box=box; anchor.visualCard=true
  return anchor
end
function T.CardShown(card,shown)
  card:SetShown(shown)
  for _,edge in ipairs(card.edges or {}) do edge:SetShown(shown) end
end
-- One tooltip style everywhere: white title, wrapped body, optional muted note.
function T.Tooltip(owner,title,body,note)
  if not GameTooltip or not owner then return end
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
  GameTooltip:SetText(title or "",1,1,1)
  if body and body~="" then GameTooltip:AddLine(body,.80,.82,.86,true) end
  if note and note~="" then GameTooltip:AddLine(note,.55,.58,.64,true) end
  GameTooltip:Show()
end

-- List rows: soft fill, faint outline, brighter outline on hover. Hover is polled only while the pointer is over the row,
-- so child controls (checkboxes, sliders) keep the row highlighted.
local ROW_EDGE={1,1,1,.06}
-- The outline belongs to the theme: later backdrop calls (for example a template resetting its border to white) are ignored.
function T.LockBorder(frame,r,g,b,a)
  if not frame or not frame.visualRound then return end
  if not frame.visualSetBorder then frame.visualSetBorder=frame.SetBackdropBorderColor; frame.SetBackdropBorderColor=function() end end
  frame.visualSetBorder(frame,r,g,b,a)
end
function T.Row(row,radius)
  if not row then return end
  if not row.visualRound then T.Round(row,radius or 6,"surface") end
  T.LockBorder(row,unpack(ROW_EDGE))
  if row.visualRowHooked then return end
  row.visualRowHooked=true
  if type(row.EnableMouse)=="function" and not row:IsMouseEnabled() then row:EnableMouse(true) end
  local function leave(self) self.visualRowHover=nil; self:SetScript("OnUpdate",nil); T.LockBorder(self,unpack(ROW_EDGE)) end
  row:HookScript("OnEnter",function(self)
    if self.visualRowHover then return end
    self.visualRowHover=true; local r,g,b=accent(); T.LockBorder(self,r,g,b,.35)
    self:SetScript("OnUpdate",function(s) if not s:IsMouseOver() then leave(s) end end)
  end)
  row:HookScript("OnHide",leave)
end

-- Spacing: content inside a card starts at least 16 px from the card's left edge. Works on absolute TOPLEFT layouts:
-- cards and controls are compared in the page's coordinates, and anything closer than 16 px moves right.
-- Update code that re-places a control is handled: a control is only moved again when its offset changed.
local CARD_PAD=16
local function topLeft(object)
  if type(object.GetNumPoints)~="function" or object:GetNumPoints()<1 then return end
  local point,relative,relativePoint,x,y=object:GetPoint(1)
  if point~="TOPLEFT" or relativePoint~="TOPLEFT" or type(x)~="number" or type(y)~="number" then return end
  if relative and relative~=object:GetParent() then return end
  return x,y
end
local CONTROL_TYPES={Button=true,CheckButton=true,EditBox=true,Slider=true,StatusBar=true}
function T.InsetCards(root)
  if not root then return end
  local cards,items={},{}
  local function walk(frame,ox,oy,depth)
    for _,region in ipairs({frame:GetRegions()}) do
      local x,y=topLeft(region)
      if x then
        if region.visualCard then
          local w,h=region:GetSize(); cards[#cards+1]={x=ox+x,y=oy+y,w=w or 0,h=h or 0}
        elseif not region.optionsDecoration and region:GetObjectType()=="FontString" then
          items[#items+1]={object=region,x=x,y=y,ax=ox+x,ay=oy+y}
        end
      end
    end
    if depth>6 then return end
    for _,child in ipairs({frame:GetChildren()}) do
      local kind=child:GetObjectType(); local x,y=topLeft(child)
      if kind=="ScrollFrame" then
        -- Scrolling lists manage their own padding.
      elseif CONTROL_TYPES[kind] or child.visualRound or (type(child.GetBackdrop)=="function" and child:GetBackdrop()) then
        if x then items[#items+1]={object=child,x=x,y=y,ax=ox+x,ay=oy+y} end
      elseif x then walk(child,ox+x,oy+y,depth+1)
      end
    end
  end
  walk(root,0,0,0)
  if #cards==0 then return end
  for _,item in ipairs(items) do
    local object=item.object
    -- GetPoint can return 443.9999 for 444, so compare with a tolerance rather than exact equality.
    if not object.visualInsetX or math.abs(object.visualInsetX-item.x)>.5 then
      for _,card in ipairs(cards) do
        if item.ax>=card.x and item.ax<card.x+CARD_PAD and item.ay<=card.y and item.ay>card.y-card.h then
          local shift=card.x+CARD_PAD-item.ax
          local point,relative,relativePoint=object:GetPoint(1)
          object:ClearAllPoints(); object:SetPoint(point,relative,relativePoint,item.x+shift,item.y)
          object.visualInsetX=item.x+shift
          if object:GetObjectType()=="FontString" then
            local width=object:GetWidth(); local limit=card.x+card.w-CARD_PAD-(item.ax+shift)
            if type(width)=="number" and width>limit and limit>40 then object:SetWidth(limit) end
          end
          break
        end
      end
    end
  end
end

-- Two-step confirmation for destructive buttons: the first click arms ("Click again to confirm"),
-- a second click within four seconds runs the action. Moving away or waiting disarms it.
function T.Confirm(control)
  if not control or control.visualConfirm or type(control.GetScript)~="function" then return control end
  local action=control:GetScript("OnClick"); if not action then return control end
  control.visualConfirm=true
  local function disarm()
    if not control.confirmArmed then return end
    if control.confirmTimer and control.confirmTimer.Cancel then control.confirmTimer:Cancel() end
    control.confirmArmed=nil; control:SetText(control.confirmLabel or ""); control.confirmTimer=nil
  end
  control:SetScript("OnClick",function(self,...)
    if self.confirmArmed then
      if self.confirmTimer and self.confirmTimer.Cancel then self.confirmTimer:Cancel() end
      disarm(); return action(self,...)
    end
    self.confirmArmed=true; self.confirmLabel=self:GetText(); self:SetText(B:Text("Click again to confirm"))
    if C_Timer and C_Timer.NewTimer then self.confirmTimer=C_Timer.NewTimer(4,disarm) end
  end)
  control:HookScript("OnHide",disarm)
  return control
end
function T.Rule(parent,x,y,width)
  local rule=parent:CreateTexture(nil,"BORDER"); rule:SetColorTexture(unpack(T.rule)); rule:SetPoint("TOPLEFT",x,y); rule:SetSize(width,1)
  rule.optionsDecoration=true; T.Track(rule,"rule"); return rule
end

-- Text fields: inset dark field with an accent outline while focused.
function T.EditFocus(edit)
  if not edit or edit.visualFocus then return end
  edit.visualFocus=true; edit.visualFocusable=true; T.Track(edit,"edit")
  if type(edit.SetBackdrop)=="function" then
    T.Round(edit,5,"surface"); edit:SetBackdropColor(unpack(T.field)); edit:SetBackdropBorderColor(unpack(T.border))
  else
    for _,key in ipairs({"Left","Middle","Mid","Right"}) do local art=edit[key]; if art and art.SetAlpha then art:SetAlpha(0) end end
    for _,region in ipairs({edit:GetRegions()}) do
      if region:GetObjectType()=="Texture" and region:GetDrawLayer()=="BACKGROUND" and not region.optionsDecoration then region:SetAlpha(0) end
    end
    local box=newBox(edit,"BACKGROUND",-7,5); box:Place(edit,-6,0,2,0)
    box.base={fill={unpack(T.field)},border={unpack(T.border)}}; edit.visualRound=box
  end
  local object=mappedFont(edit:GetFontObject()); if object then edit:SetFontObject(object) end
  edit:SetTextColor(unpack(T.text))
  edit:HookScript("OnEditFocusGained",paint); edit:HookScript("OnEditFocusLost",paint)
  paint(edit)
end

-- Dropdown-style controls: field look, left text, chevron, accent outline while open.
local function ensureText(control)
  local text=control:GetFontString()
  if not text and type(control.SetFontString)=="function" then
    text=control:CreateFontString(nil,"OVERLAY"); control:SetFontString(text)
  end
  return text
end
function T.Selector(control)
  if not control then return end
  if not control.visualSelector then
    control.visualSelector=true
    T.Button(control); control:SetBackdropColor(unpack(T.field))
    control:SetNormalFontObject(T.fonts.ButtonLeft); control:SetHighlightFontObject(T.fonts.ButtonLeftHover); control:SetDisabledFontObject(T.fonts.ButtonLeftDisabled)
    local text=ensureText(control)
    if text then
      local left=control.icon and 32 or 10
      text:ClearAllPoints(); text:SetPoint("LEFT",left,0); text:SetPoint("RIGHT",-28,0); text:SetJustifyH("LEFT"); text:SetWordWrap(false)
    end
    local arrow=control.arrow
    if arrow then arrow:ClearAllPoints(); arrow:SetPoint("RIGHT",-9,0); T.Glyph(arrow,"down",12,.62,.66,.71) end
    if control.divider then control.divider:Hide() end
  end
  local menu=control.menu
  if menu and not menu.selectorStyled then
    menu.selectorStyled=true; T.Surface(menu,"menu"); menu:SetClampedToScreen(true); menu:EnableMouse(true)
    menu:HookScript("OnShow",function()
      local r,g,b=accent(); control:SetBackdropBorderColor(r,g,b,.9); if control.arrow then T.Glyph(control.arrow,"up",12,r,g,b) end; T.Polish(menu)
    end)
    menu:HookScript("OnHide",function()
      control:SetBackdropBorderColor(unpack(T.border)); if control.arrow then T.Glyph(control.arrow,"down",12,.62,.66,.71) end
    end)
  end
end

-- Check controls. Labelled settings become switches; list and grid markers stay compact boxes.
local function compactCheck(control)
  local text=control.Text and control.Text:GetText()
  return text==nil or text=="" or text:match("^G%d+$")~=nil or text:match("^%d+$")~=nil or control.visualCompact==true
end
local function syncCheck(control)
  local v=control and control.visualCheck; if not v then return end
  local on=control:GetChecked() and true or false
  local enabled=control:IsEnabled() and true or false
  local r,g,b=accent(); local alpha=enabled and 1 or .4
  if v.toggle then
    if on then v.track:Color(r,g,b,alpha) else v.track:Color(1,1,1,enabled and .16 or .07) end
    v.knob:ClearAllPoints(); v.knob:SetPoint("LEFT",control,"LEFT",on and 16 or 2,0)
    if on then v.knob:SetVertexColor(1,1,1,alpha) else v.knob:SetVertexColor(.80,.82,.86,enabled and (control.visualHover and 1 or .9) or .45) end
  else
    if on then v.box:SetFill(r,g,b,alpha); v.box:SetBorder(r,g,b,alpha)
    else v.box:SetFill(T.field[1],T.field[2],T.field[3],enabled and 1 or .5); v.box:SetBorder(1,1,1,enabled and (control.visualHover and .4 or .24) or .1) end
    v.mark:SetShown(on); v.mark:SetVertexColor(.05,.06,.075,alpha)
  end
  if control.Text and not control.visualKeepTextColor then
    if enabled then control.Text:SetTextColor(unpack(T.text)) else control.Text:SetTextColor(unpack(T.muted)) end
  end
end
T.SyncCheck=syncCheck
function T.Check(control)
  if not control then return end
  T.Track(control,"check")
  if control.visualCheck then syncCheck(control); return end
  for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetDisabledTexture","GetHighlightTexture","GetCheckedTexture","GetDisabledCheckedTexture"}) do
    local texture=type(control[getter])=="function" and control[getter](control)
    if texture then texture:SetAlpha(0) end
  end
  local v={toggle=not compactCheck(control)}
  local text=control.Text
  if text then
    local object=mappedFont(text:GetFontObject()); if object then text:SetFontObject(object) end
    text:SetTextColor(unpack(T.text)); text:SetWordWrap(false)
    local width=text:GetStringWidth()
    if control.headerSwitch then
      -- Page header switch: label on the left, switch at the right edge of the page.
      text:ClearAllPoints(); text:SetPoint("RIGHT",control,"LEFT",-10,0); text:SetJustifyH("RIGHT")
      if type(width)=="number" then control:SetHitRectInsets(-math.min(280,width+12),-8,0,0) end
    else
      text:ClearAllPoints(); text:SetPoint("LEFT",control,"RIGHT",v.toggle and 14 or 6,0)
      if type(width)=="number" then control:SetHitRectInsets(0,-math.min(280,width+(v.toggle and 18 or 10)),0,0) end
    end
  end
  if v.toggle then
    v.track=newPill(control,"BACKGROUND",0); v.track:Set(control,0,0,32,18)
    v.knob=control:CreateTexture(nil,"ARTWORK"); v.knob:SetTexture(MEDIA.."UIKnob"); v.knob:SetSize(14,14)
  else
    v.box=newBox(control,"BACKGROUND",0,4)
    local holder=control:CreateTexture(nil,"BACKGROUND",nil,-8); holder:SetColorTexture(0,0,0,0); holder:SetSize(16,16); holder:SetPoint("CENTER")
    v.box:Place(holder)
    v.mark=control:CreateTexture(nil,"ARTWORK"); v.mark:SetTexture(MEDIA.."UICheck"); v.mark:SetSize(14,14); v.mark:SetPoint("CENTER",holder,"CENTER")
  end
  control.visualCheck=v
  hooksecurefunc(control,"SetChecked",syncCheck)
  for _,method in ipairs({"Enable","Disable","SetEnabled"}) do if type(control[method])=="function" then hooksecurefunc(control,method,syncCheck) end end
  local hooks={
    OnClick=syncCheck, OnShow=syncCheck,
    OnEnter=function() control.visualHover=true; syncCheck(control) end,
    OnLeave=function() control.visualHover=false; syncCheck(control) end,
  }
  for event,fn in pairs(hooks) do control:HookScript(event,fn) end
  local setScript=control.SetScript
  control.SetScript=function(self,event,handler,...)
    setScript(self,event,handler,...)
    local hook=hooks[event]; if hook then self:HookScript(event,hook) end
  end
  syncCheck(control)
end

-- Navigation: "sidebar" (left list), "underline" (sub-tabs) and "segment" (Solo/Party/Raid switches).
function T.Navigation(button,selected)
  if not button then return end
  T.Track(button,"navigation")
  local style=button.navStyle or "segment"
  if not button.visualRound then T.Round(button,style=="sidebar" and 6 or 5,"button") end
  button.navSelected=selected and true or false; button.visualStyle=style
  local r,g,b=accent()
  local mark=button.navAccent
  if not mark then mark=button:CreateTexture(nil,"OVERLAY"); mark:SetTexture(WHITE); button.navAccent=mark end
  mark:ClearAllPoints(); mark:SetVertexColor(r,g,b,1)
  if style=="sidebar" then
    mark:SetPoint("LEFT",0,0); mark:SetSize(3,18)
    if selected then button:SetBackdropColor(r,g,b,.13) else button:SetBackdropColor(0,0,0,0) end
    button:SetBackdropBorderColor(0,0,0,0)
    if button.icon then
      button.icon:SetDesaturated(false)
      if selected then button.icon:SetVertexColor(r,g,b,1) else button.icon:SetVertexColor(.56,.60,.66,1) end
    end
    button:SetNormalFontObject(selected and T.fonts.NavActive or T.fonts.Nav); button:SetHighlightFontObject(T.fonts.NavActive)
  elseif style=="list" then
    -- Selectable list rows: same selection language as the sidebar, but icons keep their own colours.
    mark:SetPoint("LEFT",0,0); mark:SetSize(3,22)
    if selected then button:SetBackdropColor(r,g,b,.14); button:SetBackdropBorderColor(r,g,b,.35)
    else button:SetBackdropColor(unpack(T.row)); button:SetBackdropBorderColor(1,1,1,.05) end
  elseif style=="underline" then
    mark:SetPoint("BOTTOMLEFT",12,0); mark:SetPoint("BOTTOMRIGHT",-12,0); mark:SetHeight(2)
    button:SetBackdropColor(0,0,0,0); button:SetBackdropBorderColor(0,0,0,0)
    button:SetNormalFontObject(selected and T.fonts.TabActive or T.fonts.Tab); button:SetHighlightFontObject(T.fonts.TabActive)
  else
    mark:SetPoint("BOTTOMLEFT",6,1); mark:SetPoint("BOTTOMRIGHT",-6,1); mark:SetHeight(2)
    if selected then button:SetBackdropColor(r*.18+.06,g*.18+.065,b*.18+.08,1); button:SetBackdropBorderColor(r,g,b,.55)
    else button:SetBackdropColor(unpack(T.control)); button:SetBackdropBorderColor(unpack(T.border)) end
    button:SetNormalFontObject(selected and T.fonts.TabActive or T.fonts.Tab); button:SetHighlightFontObject(T.fonts.TabActive)
  end
  mark:SetShown(selected and style~="segment" and true or false)
  paint(button)
end

-- Thin scrollbars: faint rail and a slim thumb. Mouse wheel and thumb dragging are unchanged.
local function thinVertical(bar)
  if not bar or bar.visualThin or type(bar.GetThumbTexture)~="function" then return end
  bar.visualThin=true
  if type(bar.SetBackdrop)=="function" and bar.GetBackdrop and bar:GetBackdrop() then bar:SetBackdrop(nil) end
  if bar.NineSlice then bar.NineSlice:SetAlpha(0) end
  local thumb=bar:GetThumbTexture()
  for _,region in ipairs({bar:GetRegions()}) do if region~=thumb and region:GetObjectType()=="Texture" then region:SetAlpha(0) end end
  for _,key in ipairs({"ScrollUpButton","ScrollDownButton"}) do local button=bar[key]; if button then button:SetAlpha(0); button:EnableMouse(false) end end
  for _,child in ipairs({bar:GetChildren()}) do if child:GetObjectType()=="Button" then child:SetAlpha(0); child:EnableMouse(false) end end
  local rail=bar:CreateTexture(nil,"BACKGROUND"); rail:SetColorTexture(1,1,1,.04); rail:SetPoint("TOP",0,0); rail:SetPoint("BOTTOM",0,0); rail:SetWidth(4); bar.visualRail=rail
  if thumb then thumb:SetTexture(WHITE); thumb:SetVertexColor(1,1,1,.22); thumb:SetSize(4,40); thumb:SetAlpha(1) end
end
function T.ScrollBar(scroll)
  if not scroll or scroll.visualScroll then return end
  local bar=scroll.ScrollBar
  if not bar then for _,child in ipairs({scroll:GetChildren()}) do if child:GetObjectType()=="Slider" then bar=child; break end end end
  if not bar then return end
  scroll.visualScroll=true; thinVertical(bar)
  bar:ClearAllPoints(); bar:SetPoint("TOPLEFT",scroll,"TOPRIGHT",8,-2); bar:SetPoint("BOTTOMLEFT",scroll,"BOTTOMRIGHT",8,2)
end

-- Applies typography, rounded surfaces, fields and scrollbars below a frame. Handled objects are skipped,
-- so a pass after each refresh only touches controls created since the previous one.
local donePass=setmetatable({}, {__mode="k"})
local function retintFont(fs)
  if donePass[fs] then return end
  donePass[fs]=true
  if tracked[fs]=="preview" then return end
  local old=fs:GetFontObject(); local new=mappedFont(old)
  if not new then return end
  -- Keep visibility and any custom colour: changing the font object resets both.
  local alpha=fs:GetAlpha(); local shown=fs:IsShown()
  local r,g,b,a=fs:GetTextColor(); local dr,dg,db,da=old:GetTextColor()
  fs:SetFontObject(new)
  if r and dr and (math.abs(r-dr)>.02 or math.abs(g-dg)>.02 or math.abs(b-db)>.02 or math.abs((a or 1)-(da or 1))>.02) then fs:SetTextColor(r,g,b,a or 1) end
  fs:SetAlpha(alpha); fs:SetShown(shown)
end
local function retintButton(button)
  if button.visualRound then return end
  local normal=type(button.GetNormalFontObject)=="function" and mappedFont(button:GetNormalFontObject())
  if normal then button:SetNormalFontObject(T.fonts.Button); button:SetHighlightFontObject(T.fonts.ButtonHover); button:SetDisabledFontObject(T.fonts.ButtonDisabled) end
end
function T.Polish(root)
  if not root or type(root.GetChildren)~="function" then return end
  local stack={root}
  while #stack>0 do
    local frame=table.remove(stack)
    if not donePass[frame] then
      donePass[frame]=true
      local kind=frame:GetObjectType()
      if kind=="EditBox" then T.EditFocus(frame)
      elseif kind=="ScrollFrame" then T.ScrollBar(frame)
      elseif kind=="Button" then
        if not frame.visualRound and type(frame.GetBackdrop)=="function" and frame:GetBackdrop() then T.Button(frame) else retintButton(frame) end
      elseif kind=="CheckButton" then if not frame.visualCheck then T.Check(frame) end
      elseif kind=="Slider" then
        if not frame.visualTrack and frame.GetOrientation and frame:GetOrientation()=="VERTICAL" then thinVertical(frame) end
      elseif kind=="Frame" then
        if not frame.visualRound and type(frame.GetBackdrop)=="function" and frame:GetBackdrop() then T.Round(frame,6,"surface") end
      end
    end
    for _,region in ipairs({frame:GetRegions()}) do if region:GetObjectType()=="FontString" then retintFont(region) end end
    for _,child in ipairs({frame:GetChildren()}) do stack[#stack+1]=child end
  end
end

function T.Refresh()
  local r,g,b=B:InterfaceAccent(); T.accent={r,g,b,1}; T.gold=T.accent
  if B.nearbyFrame and B.nearbyFrame.line then B.nearbyFrame.line:SetColorTexture(r,g,b,.80) end
  for control,kind in pairs(tracked) do
    if kind=="label" then
      if control.optionsSection then control:SetTextColor(r,g,b)
      elseif control.optionsTitle then control:SetTextColor(1,1,1,1)
      elseif control.optionsMuted then control:SetTextColor(unpack(T.muted)) else control:SetTextColor(unpack(T.text)) end
    elseif kind=="navigation" then T.Navigation(control,control.navSelected)
    elseif kind=="check" then syncCheck(control)
    elseif kind=="edit" or kind=="button" then paint(control)
    elseif kind=="primary" then control:SetBackdropColor(r,g,b,1); control:SetBackdropBorderColor(r,g,b,1)
    elseif kind=="slider" then if control.visualRepaint then control.visualRepaint() end
    elseif kind=="accentIcon" then control:SetVertexColor(r,g,b,1)
    elseif kind=="rule" then control:SetColorTexture(unpack(T.rule))
    end
  end
end

-- Sliders: editable value on the left, rounded rail, accent fill and a round thumb.
local THUMB=14
function T.StyleSlider(s,low,high,step,onChange)
  if type(s.SetBackdrop)=="function" then s:SetBackdrop(nil) end
  local nativeThumb=s:GetThumbTexture(); if nativeThumb then nativeThumb:Hide() end
  if s.NineSlice then s.NineSlice:Hide() end
  for _,region in ipairs({s:GetRegions()}) do region:Hide() end
  -- The old value label stays hidden; the field on the left shows the value.
  if s.valueText then s.valueText:SetAlpha(0); donePass[s.valueText]=true end
  s:SetWidth(math.max(100,s:GetWidth() or 100)); s:EnableMouse(false)
  local edit=CreateFrame("EditBox",nil,s,"BackdropTemplate"); s.valueEdit=edit
  edit:SetSize(48,24); edit:SetPoint("LEFT",0,0); edit:SetAutoFocus(false); edit:SetFontObject(T.fonts.Value); edit:SetJustifyH("CENTER"); edit:SetNumeric(false)
  edit:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1}); T.EditFocus(edit)
  local track=CreateFrame("Slider",nil,s); s.visualTrack=track
  track:SetPoint("LEFT",62,0); track:SetPoint("RIGHT",-2,0); track:SetHeight(18); track:SetOrientation("HORIZONTAL")
  -- Unit shown inside the value field (sec, px, %), so every slider says what it measures.
  local unitText=edit:CreateFontString(nil,"OVERLAY"); unitText:SetFontObject(T.fonts.Muted); unitText:SetPoint("RIGHT",-8,0); unitText:Hide(); s.visualUnitText=unitText
  local function layout()
    local unit=s.visualUnit; local reserve=0
    if unit then
      unitText:SetText(B:Text(unit)); unitText:Show()
      local w=unitText:GetStringWidth(); reserve=(type(w)=="number" and w or 18)+6
    else unitText:Hide() end
    -- Size the field for the largest value it can hold (1800 sec must not clip to "00").
    local probe=s.visualProbe or edit:CreateFontString(nil,"BACKGROUND"); s.visualProbe=probe
    probe:SetFontObject(T.fonts.Value); probe:SetText(tostring(math.floor(high))); probe:Hide()
    local digits=probe:GetStringWidth(); digits=(type(digits)=="number" and digits>0) and digits or #tostring(math.floor(high))*8
    local width=math.max(unit and 58 or 48,math.ceil(digits+reserve+(unit and 22 or 18)),s.visualFieldWidth or 0)
    edit:SetWidth(width)
    if unit then edit:SetJustifyH("RIGHT"); edit:SetTextInsets(6,reserve+8,0,0) else edit:SetJustifyH("CENTER"); edit:SetTextInsets(0,0,0,0) end
    track:ClearAllPoints(); track:SetPoint("LEFT",width+12,0); track:SetPoint("RIGHT",-2,0)
  end
  s.SetUnit=function(self,unit) self.visualUnit=unit; layout() end
  -- A shared field width lines up the tracks of stacked sliders.
  s.SetFieldWidth=function(self,width) self.visualFieldWidth=width; layout() end
  track:SetMinMaxValues(low,high); track:SetValueStep(step); if track.SetObeyStepOnDrag then track:SetObeyStepOnDrag(true) end
  local rail=newPill(track,"BACKGROUND",0); local fill=newPill(track,"ARTWORK",0)
  local thumb=track:CreateTexture(nil,"OVERLAY"); thumb:SetTexture(MEDIA.."UIThumb"); thumb:SetSize(THUMB,THUMB); track:SetThumbTexture(thumb); s.visualThumb=thumb
  local function update(_,value)
    value=value or s:GetValue() or low
    if not B.API.Number(value) then return end
    if not edit.unsaved and not edit:HasFocus() then edit:SetText(tostring(value)) end
    track.syncing=true; track:SetValue(value); track.syncing=nil
    local width=track:GetWidth(); width=type(width)=="number" and math.max(THUMB,width) or 40
    rail:Set(track,0,0,width,4); rail:Color(1,1,1,.10)
    -- The fill ends at the thumb centre, which travels from THUMB/2 to width-THUMB/2.
    fill:Set(track,0,0,THUMB/2+(width-THUMB)*math.max(0,math.min(1,(value-low)/math.max(1,high-low))),4)
    local r,g,b=B:InterfaceAccent(); fill:Color(r,g,b,1); thumb:SetVertexColor(r,g,b,1)
  end
  s.visualRepaint=function() update(s,s:GetValue() or low) end
  local function enter()
    local fn=s:GetScript("OnEnter")
    if fn then fn(s) else
      local formatter=s.visualFormatter or tostring
      T.Tooltip(edit,formatter(s:GetValue() or low),B:Text("Drag the slider or type a value. Enter saves; Escape cancels."),B:Text("Range: %s to %s",formatter(low),formatter(high)))
    end
  end
  for _,control in ipairs({edit,track}) do control:SetScript("OnEnter",enter); control:SetScript("OnLeave",function() GameTooltip:Hide() end) end
  s:HookScript("OnValueChanged",update)
  track:SetScript("OnSizeChanged",function() update(s,s:GetValue() or low) end)
  track:SetScript("OnValueChanged",function(_,value) if not track.syncing then s:SetValue(value) end end)
  local function commit()
    if B.API.Combat() then edit:ClearFocus(); return end
    local value=tonumber(edit:GetText())
    if B.API.Number(value) then value=math.max(low,math.min(high,math.floor(value/step+.5)*step)); s:SetValue(value) end
    edit.unsaved=nil; edit:ClearFocus(); update(s,s:GetValue() or low)
  end
  edit:SetScript("OnTextChanged",function(_,user) if user then edit.unsaved=true end end)
  edit:SetScript("OnEnterPressed",commit)
  edit:SetScript("OnEscapePressed",function() edit.unsaved=nil; edit:ClearFocus(); update(s,s:GetValue() or low) end)
  track:SetScript("OnMouseUp",function() local callback=s:GetScript("OnMouseUp"); if callback then callback(s) end end)
  local enable,disable=s.Enable,s.Disable
  s.Enable=function(self) enable(self); track:Enable(); edit:Enable(); track:SetAlpha(1); edit:SetAlpha(1) end
  s.Disable=function(self) disable(self); track:Disable(); edit:Disable(); track:SetAlpha(.4); edit:SetAlpha(.55) end
  T.Track(s,"slider")
end

function B:PolishOptionsSurfaces()
  local f=self.options
  if not f then return end
  for _,control in ipairs({f.reminderSoundButton,f.supplySoundButton,f.channelButton,f.fontButton,f.colorButton,f.effectButton,f.effectColorButton,f.effectSpeedButton,f.labelSizeButton,f.labelOutlineButton,f.campingWarning,f.campingEffect,f.campingColor,f.campingSpeed,f.campingTextFont,f.campingTextSize,f.campingTextColor,f.campingTextOutline}) do T.Selector(control) end
  for _,control in pairs(f.weaponPickers or {}) do T.Selector(control) end
  for _,control in pairs(f.coatingPickers or {}) do T.Selector(control) end
  for _,row in ipairs(f.blessingRows or {}) do T.Selector(row.pick) end
  for _,control in ipairs(f.targetBlessingPicks or {}) do T.Selector(control) end
  local helpers=self.helperWindow
  if helpers then T.Selector(helpers.soulTarget); T.Selector(helpers.demonChoice) end
  for _,name in ipairs({"blessingMenu","blessingDetail","blessingCastingPanel","blessingFilters"}) do
    local surface=f[name]; if surface then T.Surface(surface,"menu") end
  end
end
-- Section titles use small capitals; text with non-ASCII letters keeps its case so accents stay correct.
function T.SectionTitle(fs)
  if not fs then return end
  local text=fs:GetText()
  if type(text)=="string" and not text:find("[\128-\255]") then fs:SetText(text:upper()) end
  fs.optionsSection=true
end
