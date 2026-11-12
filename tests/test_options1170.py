from test_bufftap import test, tests, ADDON

toc=(ADDON/'BuffTap.toc').read_text(encoding='utf-8')
version=next(line.split(':',1)[1].strip() for line in toc.splitlines() if line.startswith('## Version:'))
test('Runtime version exactly matches the packaged TOC',"assert(BuffTap.version=="+repr(version)+")")

probe='''
local make=CreateFrame
CreateFrame=function(...)
 local f=make(...)
 f.SetPoint=function(s,...) local p={...}; if p[1]=='TOPLEFT' then s.position=p end end
 f.SetSize=function(s,w,h) s.w=w; s.h=h end
 f.SetBackdrop=function(s,v) s.backdrop=v end
 return f
end
'''
for cls in ['DRUID','PALADIN','MAGE','PRIEST','HUNTER','WARLOCK','SHAMAN','ROGUE','WARRIOR']:
 test('Sidebar and weapon layout stay aligned for '+cls,probe+"playerClass='"+cls+"'; "+'''
 BuffTap:Options(); local f=BuffTap.options
 -- 1.18 window: 900 tall with the banner header; sidebar items are 177 wide on a 38 px rhythm.
 assert(f.w==932 and f.h==900 and #f.tabs==12)
 assert(f.pages[1].position[2]==208 and f.pages[1].position[3]==-132)
 for i,t in ipairs(f.tabs) do assert(t.w==177 and t.h==34 and t.position[2]==10 and t.position[3]==-136-(i-1)*38); f.selectTab(i); assert(f.pages[i].shown) end
 local imbue=BuffTap:WeaponReminderClass()~=nil
 assert(f.weaponClassCard.shown==imbue and f.weaponSectionHeading.shown==imbue)
 for _,edge in ipairs(f.weaponClassCard.edges) do assert(edge.shown==imbue) end
 local y=imbue and -224 or -102
 assert(f.coatingPickers.main.position[3]==y-30 and f.coatingPickers.off.position[3]==y-78)
 if not imbue then assert(math.abs(f.weaponMain.position[3]-(y-30))<=1 and math.abs(f.weaponOff.position[3]-(y-78))<=1) end
 assert(f.closeButton.backdrop and f.closeButton.glyph,'1.18: themed Close button with a drawn glyph')
 ''')

test('Selectors receive opaque clamped mouse-enabled menus',probe+'''
 BuffTap:Options(); local c=BuffTap.options.weaponApply
 assert(c.menu.backdrop and c.menu.selectorStyled and c.visualSelector)
''')

test('Repeated options rendering reuses its frames', '''
 local make=CreateFrame; local count=0
 CreateFrame=function(...) count=count+1; return make(...) end
 BuffTap:Options(); local first=count
 for i=1,20 do BuffTap:Options() end
 assert(count==first,'options rendering must not allocate more frames')
''')

test('Visual options preserve current secure action and profile identity', '''
 local before=BuffTap.action; local id=before.id; local target=before.target; local profile=BuffTap.profileDB:GetCurrentProfile()
 BuffTap:Options(); for i=1,12 do BuffTap.options.selectTab(i) end
 assert(BuffTap.action.id==id and BuffTap.action.target==target)
 assert(BuffTap.profileDB:GetCurrentProfile()==profile)
''')

test('Profile create and rename fields receive focus treatments', '''
 BuffTap:Options(); local p=BuffTap.options.profiles
 assert(p.name.visualFocus and p.name.visualFocusable and p.renameName.visualFocus and p.renameName.visualFocusable)
''')

test('Card visibility includes its decorative edges', '''
 BuffTap:Options(); local T=BuffTap.OptionsTheme; local card=T.Card(BuffTap.options,0,0,100,40)
 T.CardShown(card,false); assert(not card.shown); for _,edge in ipairs(card.edges) do assert(not edge.shown) end
 T.CardShown(card,true); assert(card.shown); for _,edge in ipairs(card.edges) do assert(edge.shown) end
''')

test('Header version sits in the header band beside Close', '''
 local make=CreateFrame
 CreateFrame=function(...)
  local f=make(...); local font=f.CreateFontString
  f.CreateFontString=function(s,...) local text=font(s,...); text.visualParent=s; return text end
  return f
 end
 BuffTap:Options(); local f=BuffTap.options; assert(f.versionText.visualParent==f and f.versionText.text=='v'..BuffTap.version)
''')

print('OPTIONS 1.17.0 CHECKS',len(tests))
