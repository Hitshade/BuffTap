from test_bufftap import test

# Models the documented container contract, not Blizzard's secure/forbidden engine.
# Native indicators must never own actions; live testing must establish parent casting.
NATIVE = r'''
local B=BuffTap
local create=CreateFrame
nativeContainers={}; nativeSlots={}; nativeWrites=0
Enum=Enum or {}; Enum.CustomAuraButtonDispelTypeTextureStyle={PreserveAsset=3}
CreateFrame=function(kind,name,parent,template)
  if kind~='AuraContainer' then
    local f=create(kind,name,parent,template)
    if template and template:find('SecureActionButtonTemplate,SecureHandlerStateTemplate',1,true) then
      f.SetPoint=function(s,...) assert(not combat); s.testPoint={...} end
      f.SetAlpha=function(s,v) s.testAlpha=v end
      f.SetAttribute=function(s,k,v) assert(not combat,'protected action changed in combat'); nativeWrites=nativeWrites+1; s.attrs[k]=v end
      f.EnableMouse=function(s,v) assert(not combat); s.mouse=v end
      f.HookScript=function(s,event,fn) assert(not combat); s.scripts[event]=fn end
    end
    return f
  end
  assert(not combat,'container creation in combat')
  local c=create('Frame',name,parent); nativeContainers[#nativeContainers+1]=c
  c.slots={}
  c.AddAuraSlot=function(self,key,filter,options)
    assert(not combat); assert(filter=='HARMFUL')
    assert(options.templateNames==nil,'native indicators must not inherit action handlers')
    local ab=create('Button',nil,self)
    ab:Hide(); ab.caption={}
    ab.SetIcon=function(s,t) s.nativeIcon=t end
    ab.ClearDispelTypeTextures=function() end
    ab.AddDispelTypeTexture=function(s,t,o) assert(o.showWhenHarmful and not o.showWhenHelpful); s.nativeBorder=o end
    ab.SetCancelAuraButtons=function(s,v) assert(v==nil) end
    ab.SetAttribute=function() error('native indicators must never own protected actions') end
    ab.EnableMouse=function(s,v) assert(not combat); s.mouse=v end
    options.initializeFrame(ab)
    self.slots[key]={button=ab,options=options}; nativeSlots[key]=self.slots[key]
  end
  c.SetUnit=function(self,u) assert(not combat and (u=='player' or u:match('^party[1-4]$') or u:match('^raid%d+$'))); self.unit=u end
  c.SetEnabled=function(self,v) assert(not combat); self.enabled=v end
  return c
end
local function nativeDisplay(kind)
  -- Simulate only native assignment, without calling an addon aura observer.
  for key,slot in pairs(nativeSlots) do
    slot.button.secure=true
    slot.button:SetShown(kind~=nil and slot.options.candidateFilters.includeDispelTypes[kind]==true)
    slot.button.secure=nil
  end
end
local function prepare(class,spells)
  playerClass=class
  for _,id in ipairs(spells) do spell(id,'Cleanse '..id) end
  B.db.cleanseEnabled=true; B.db.cleanseSelf=true; B.db.combatCleanse=true
  B:SyncCombatCleanse()
  assert(B.combatCleanseFrame and not B.combatCleanseError,B.combatCleanseErrorDetail)
end
'''

test('Combat cleanse is off by default and creates no native frame', NATIVE+'''
assert(B.db.combatCleanse==false); B:Refresh(); assert(#nativeContainers==0)
''')

for cls,ids,mapping in [
    ('PRIEST',[988,552],{'Magic':(1,988),'Disease':(2,552)}),
    ('DRUID',[2782,2893],{'Curse':(1,2782),'Poison':(2,2893)}),
    ('MAGE',[475],{'Curse':(1,475)}),
    ('SHAMAN',[526,2870],{'Poison':(1,526),'Disease':(2,2870)}),
    ('PALADIN',[4987],{'Magic':(1,4987),'Disease':(1,4987),'Poison':(1,4987)})]:
    assertions=[]
    for kind,(button,spell) in mapping.items():
        assertions.append(f"local a=B.combatCleanseFrame; local indicator=nativeSlots['BUFFTAP_SELF_{kind}'].button; assert(a.attrs.unit=='player' and a.attrs['*spell{button}']=={spell} and a.attrs['*type{button}']=='spell'); assert(a.mouse and not indicator.mouse and not indicator.shown)")
    test('Combat cleanse prepares self-only clicks for '+cls,NATIVE+f"prepare('{cls}',{{{','.join(map(str,ids))}}}); "+'; '.join(assertions))

for cls in ['ROGUE','WARRIOR','HUNTER','WARLOCK']:
    test('Combat cleanse creates no action for '+cls,NATIVE+f"playerClass='{cls}'; B.db.combatCleanse=true; B.db.cleanseEnabled=true; B:SyncCombatCleanse(); assert(not B.combatCleanseFrame and #nativeContainers==0)")

test('Combat cleanse hides native warnings but keeps the authorized independent click target',NATIVE+'''
prepare('PRIEST',{988,552})
assert(B.combatCleanseFrame.driver=='[combat,nodead] show; hide')
local a=nativeSlots.BUFFTAP_SELF_Magic.button
local writes=nativeWrites; combat=true
C_UnitAuras.GetAuraDataByIndex=function() error('addon must not inspect combat auras') end
nativeDisplay('Magic'); assert(a.shown)
B.combatCleanseEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); B:SyncCombatCleanse()
assert(nativeWrites==writes)
nativeDisplay(nil); assert(not a.shown and nativeWrites==writes)
assert(B.combatCleanseFrame.mouse and B.combatCleanseFrame.attrs.unit=='player')
''')

test('Combat cleanse respects type filters and master/self switches',NATIVE+'''
B.db.cleanseTypes.Curse=false; prepare('DRUID',{2782,2893})
assert(not nativeSlots.BUFFTAP_SELF_Curse and nativeSlots.BUFFTAP_SELF_Poison)
local old=B.combatCleanseFrame; B.db.cleanseSelf=false; B:SyncCombatCleanse()
assert(not B.combatCleanseFrame and not old.shown and not old.container.enabled)
B.db.cleanseSelf=true; B:SyncCombatCleanse(); assert(B.combatCleanseFrame)
old=B.combatCleanseFrame; B.db.enabled=false; B:SyncCombatCleanse(); assert(not B.combatCleanseFrame and not old.shown)
''')

test('Combat cleanse never changes the normal action or override bindings',NATIVE+'''
local action=B.action; local old=bindings.MOUSEWHEELDOWN
prepare('DRUID',{2782,2893})
assert(B.action==action and bindings.MOUSEWHEELDOWN==old)
''')

test('Combat cleanse refreshes learned rank only outside combat',NATIVE+'''
prepare('PRIEST',{527,528}); local old=B.combatCleanseFrame
assert(B.combatCleanseFrame.attrs['*spell1']==527)
combat=true; spell(988,'Dispel Magic rank 2'); B.combatCleanseEvents.scripts.OnEvent(nil,'SPELLS_CHANGED')
assert(B.combatCleanseFrame==old)
combat=false; B.combatCleanseEvents.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(B.combatCleanseFrame~=old and not old.shown)
assert(B.combatCleanseFrame.attrs['*spell1']==988)
''')

test('Combat cleanse failed native setup stays hidden and reports why',NATIVE+'''
CreateFrame=function(kind,...) if kind=='AuraContainer' then error('native template unavailable') end; return create(kind,...) end
playerClass='PRIEST'; spell(527,'Dispel Magic'); B.db.cleanseEnabled=true; B.db.combatCleanse=true
B:SyncCombatCleanse(); assert(not B.combatCleanseFrame and B.combatCleanseError)
assert(B.combatCleanseErrorDetail:find('native template unavailable',1,true))
local lines=B:CombatCleanseProbeLines(); assert(table.concat(lines,' '):find('native template unavailable',1,true))
''')

test('Combat cleanse configuration and preview do not alter native buttons in combat',NATIVE+'''
prepare('DRUID',{2782,2893}); B:Options(); local f=B.options
assert(f.combatCleanse and f.combatCleansePreviewButton)
f.combatCleansePreviewButton.scripts.OnClick(); assert(B.combatCleansePreview.shown)
local old=B.combatCleanseFrame; local writes=nativeWrites
combat=true; f.combatCleanse:SetChecked(false); f.combatCleanse.scripts.OnClick(f.combatCleanse)
B.combatCleanseEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED')
assert(B.db.combatCleanse and not B.combatCleansePreview.shown and B.combatCleanseFrame==old and nativeWrites==writes)
''')

test('Combat cleanse excludes built-in unsafe IDs where native filtering permits',NATIVE+'''
prepare('PRIEST',{527,528})
assert(nativeSlots.BUFFTAP_SELF_Disease.options.candidateFilters.excludeSpellIDs[28169])
''')


test('Combat cleanse follows main settings without parenting to the main button',NATIVE+"""
B.db.x=132; B.db.y=-217; B.db.size=48; B.db.opacity=.6; B.db.iconStyle='modern'
B.db.combatCleanseX=900; B.db.combatCleanseY=800
prepare('PRIEST',{527,528}); local f=B.combatCleanseFrame
assert(f.parent==UIParent and f.width==48 and f.height==48 and f.testAlpha==.6)
assert(f.testPoint[2]==UIParent and f.testPoint[4]==132 and f.testPoint[5]==-217)
assert(nativeSlots.BUFFTAP_SELF_Magic.button.buffTapIconStyle=='modern')
B.db.x=-80; B.db.y=40; B.db.size=80; B.db.opacity=.9; B:Refresh()
local moved=B.combatCleanseFrame
assert(moved~=f and not f.shown and moved.width==80 and moved.testAlpha==.9)
assert(moved.testPoint[4]==-80 and moved.testPoint[5]==40)
""")


test('Combat cleanse release clicks work with either global key-down preference',NATIVE+"""
prepare('PRIEST',{527,528})
for _,a in ipairs({B.combatCleanseFrame}) do
  assert(#a.clicks==2 and a.clicks[1]=='LeftButtonUp' and a.clicks[2]=='RightButtonUp')
  assert(a.attrs.useOnKeyDown==false,'release-only button must override global key-down preference')
  -- Model the upstream SecureActionButton_OnClick phase gate, not a real game cast.
  for _,globalPreference in ipairs({true,false}) do
    local useOnKeyDown=a.attrs.useOnKeyDown
    if useOnKeyDown==nil then useOnKeyDown=globalPreference end
    local down=false
    assert((down and useOnKeyDown) or (not down and not useOnKeyDown))
  end
end
""")


test('Combat cleanse input receipt observes parent clicks without combat writes',NATIVE+"""
prepare('PRIEST',{527,528}); local f=B.combatCleanseFrame
local writes=nativeWrites; combat=true
C_UnitAuras.GetAuraDataByIndex=function() error('no addon combat aura inspection') end
nativeDisplay(nil); f.scripts.PostClick(f,'LeftButton',false)
nativeDisplay('Disease'); f.scripts.PostClick(f,'RightButton',false)
assert(B.combatCleanseInputCount==2 and B.combatCleanseLastInput=='RightButton')
assert(nativeWrites==writes and not nativeSlots.BUFFTAP_SELF_Disease.button.mouse)
""")
