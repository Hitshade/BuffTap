recorded={}
local function ref(v) if type(v)=='table' then return v.__draw and ('@'..v.__draw.id) or '@screen' end return v end
local function record(o,parent,kind,name)
 local n={id=#recorded+1,parent=parent and parent.__draw and parent.__draw.id,kind=kind,name=name,visible=true,points={},alpha=1}
 recorded[#recorded+1]=n; o.__draw=n
 local function hook(method,fn)
  local old=o[method]
  o[method]=function(self,...) fn(...); if old then return old(self,...) end end
 end
 hook('SetSize',function(w,h) n.w=w;n.h=h end)
 hook('SetWidth',function(w) n.w=w end);hook('SetHeight',function(h) n.h=h end)
 hook('SetPoint',function(...) local p={}; for i=1,select('#',...) do p[i]=ref(select(i,...)) end; n.points[#n.points+1]=p end)
 hook('ClearAllPoints',function() n.points={} end)
 hook('SetAllPoints',function(target) n.all=ref(target or parent) end)
 hook('SetText',function(t) n.text=tostring(t or '') end)
 hook('SetFont',function(font,size,flags) n.font=font;n.size=size end)
 hook('SetTextColor',function(r,g,b,a) n.color={r,g,b,a or 1} end)
 hook('SetColorTexture',function(r,g,b,a) n.fill={r,g,b,a or 1} end)
 hook('SetTexture',function(t) n.texture=t end)
 hook('SetTexCoord',function(...) n.texcoord={...} end)
 hook('SetAlpha',function(a) n.alpha=a end);hook('EnableMouse',function(v) n.mouse=v end);hook('EnableMouseWheel',function(v) n.wheel=v end)
 hook('SetJustifyH',function(j) n.justify=j end)
 hook('Show',function() n.visible=true end);hook('Hide',function() n.visible=false end);hook('SetShown',function(v) n.visible=not not v end)
 hook('SetMinMaxValues',function(lo,hi) n.lo=lo;n.hi=hi end)
 hook('SetValue',function(v) n.value=v end)
 hook('SetThumbTexture',function(t) t.__draw.thumb=true end)
 local tex,font=o.CreateTexture,o.CreateFontString
 o.CreateTexture=function(self,_,layer,...) local child=tex(self,nil,layer,...); record(child,self,'texture'); child.__draw.layer=layer; return child end
 o.CreateFontString=function(self,...) local child=font(self,...); record(child,self,'text'); return child end
 return o
end
local create=CreateFrame
CreateFrame=function(kind,name,parent,template) return record(create(kind,name,parent,template),parent,'frame',name) end
