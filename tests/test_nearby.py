from test_bufftap import test,tests

setup="""
GetNumSubgroupMembers=function() return 0 end
local oldExists=UnitExists
UnitExists=function(u) return u:match('^nameplate%d+$')~=nil or oldExists(u) end
local oldClass=UnitClass
UnitClass=function(u) if u:match('^nameplate%d+$') then return 'Warrior','WARRIOR' end return oldClass(u) end
local oldName=UnitName
UnitName=function(u) return u:match('^nameplate%d+$') and ('Ally '..u) or oldName(u) end
platesEnabled=true
C_CVar={GetCVarBool=function(name) if name=="nameplateShowFriendlyPlayers" then return platesEnabled end end}
C_NamePlate={GetNamePlates=function() return {{GetUnit=function() return 'nameplate1' end}} end}
aura('player',5232,'Mark of the Wild'); aura('player',467,'Thorns')
BuffTap.db.nearbyEnabled=true; refresh()
"""
test('Nearby is default off and adds no idle timer',"assert(BuffTap.db.nearbyEnabled==false and not BuffTap.nearbyRegistered); assert(not BuffTap.timerHandles or not BuffTap.timerHandles['nearby-range'])")
test('Friendly nameplates are mandatory without changing CVar',setup+"platesEnabled=false; refresh(); assert(not BuffTap.action and #BuffTap:NearbyCandidates()==0); assert(BuffTap.nearbyFrame.status.text:find('Shift+V',1,true))")
test('Unreadable nameplate setting cannot arm nearby casts',setup+"C_CVar.GetCVarBool=function() return {secret=true} end; refresh(); assert(not BuffTap.action)")
test('Enabling seeds existing plates using Blizzard GetUnit',setup+"assert(BuffTap.nearbyUnits.nameplate1 and BuffTap.action.nearby and BuffTap.action.target=='nameplate1')")
test('Nearby keeps nameplate help out of the active list',setup+"assert(BuffTap.nearbyFrame and BuffTap.nearbyFrame.rows[1].shown and not BuffTap.nearbyFrame.status.shown)")
test('Automatic nearby comes after personal buffs',setup+"auras.player={}; refresh(); assert(BuffTap.action.target=='player' and not BuffTap.action.nearby); assert(BuffTap.nearbyFrame.rows[1].entry)")
test('Nearby respects target family toggles',setup+"BuffTap.db.targetBuffs.motw=false; refresh(); assert(BuffTap.action.key=='thorns')")
test('Nearby respects spell rank and low target level',setup+"spell(9885,'Mark of the Wild',60); refresh(); assert(BuffTap.action.id==5232)")
test('PvP protection applies to nearby players',setup+"UnitIsPVP=function(u) return u=='nameplate1' end; refresh(); assert(not BuffTap.action and BuffTap.pvpBlocked)")
test('Hostile players never become nearby candidates',setup+"UnitCanAssist=function(_,u) return u~='nameplate1' end; refresh(); assert(not BuffTap.action)")
test('Nonplayers cannot become nearby candidates',setup+"UnitGUID=function(u) return 'Creature-'..u end; refresh(); assert(not BuffTap.action)")
test('Unreadable aura scan does not mean missing buffs',setup+"C_UnitAuras.GetAuraDataByIndex=function(u,i) if u=='nameplate1' then error('restricted') end return (auras[u] or {})[i] end; refresh(); assert(not BuffTap.action)")
test('Applying all buffs removes recipient',setup+"aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); assert(not BuffTap.action and #BuffTap:NearbyCandidates()==0)")
test('Each row displays actual missing buff icons',setup+"local row=BuffTap.nearbyFrame.rows[1]; assert(row.icons[1].shown and row.icons[2].shown and not row.icons[3].shown)")
test('Normal binding refuses recycled nameplate identity',setup+"local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Player-New' or old(u) end; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.action)")
test('Row click refuses recycled nameplate identity',setup+"local row=BuffTap.nearbyFrame.rows[1]; local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Player-New' or old(u) end; row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)")
test('Row click refuses buff applied since display',setup+"local row=BuffTap.nearbyFrame.rows[1]; aura('nameplate1',5232,'Mark of the Wild'); row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)")
test('Row click rechecks PvP flag',setup+"local row=BuffTap.nearbyFrame.rows[1]; UnitIsPVP=function(u) return u=='nameplate1' end; row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)")
test('Row click arms one-click target cast restore macro',setup+"local row=BuffTap.nearbyFrame.rows[1]; row.scripts.PreClick(row,'LeftButton',true); assert(row.attrs.type1=='macro' and row.attrs.unit==nil and row.attrs.spell==nil); assert(row.attrs.macrotext=='/cleartarget\\n/targetexact Ally nameplate1\\n/cast [help,nodead] Mark of the Wild(Rank 2)\\n/targetlasttarget')")
test('Removing plate invalidates row and normal binding',setup+"BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_REMOVED','nameplate1'); advance(.2); assert(not BuffTap.action and not BuffTap.nearbyUnits.nameplate1)")
test('Unit aura events refresh watched nearby players',setup+"aura('nameplate1',5232,'Mark of the Wild'); BuffTap.events.scripts.OnEvent(nil,'UNIT_AURA','nameplate1'); advance(.2); assert(BuffTap.action.key=='thorns')")
test('Duplicate GUIDs yield one recipient',setup+"local old=UnitGUID; UnitGUID=function(u) return u=='nameplate2' and old('nameplate1') or old(u) end; BuffTap:TrackNearby('nameplate2'); refresh(); assert(#BuffTap:NearbyCandidates()==1)")
test('Actual party members stay under group settings',setup+"UnitInParty=function(u) return u=='nameplate1' end; refresh(); assert(not BuffTap.action)")
test('Explicit target does not also appear in nearby list',setup+"BuffTap.db.friendlyTarget=true; UnitIsUnit=function(a,b) return a==b or a=='nameplate1' and b=='target' end; refresh(); assert(#BuffTap:NearbyCandidates()==0)")
test('Scrolling supports more than five stable rows',setup+"for i=2,12 do BuffTap:TrackNearby('nameplate'..i) end; refresh(); assert(#BuffTap:NearbyCandidates()==12 and #BuffTap.nearbyFrame.rows==5); local f=BuffTap.nearbyFrame; f.scroll:SetValue(1); assert(BuffTap.nearbyOffset==1 and f.rows[1].entry.unit=='nameplate2'); assert(f.count.text=='12' and f.scroll.shown)")
test('Nearby tracking stays bounded',setup+"for i=2,100 do BuffTap:TrackNearby('nameplate'..i) end; local n=0; for _ in pairs(BuffTap.nearbyUnits) do n=n+1 end; assert(n==40)")
test('Feature off clears scanning and action',setup+"BuffTap.db.nearbyEnabled=false; refresh(); assert(not next(BuffTap.nearbyUnits) and not BuffTap.action)")
test('Closing nearby window disables experiment',setup+"BuffTap.db.nearbyEnabled=false; refresh(); assert(not BuffTap.nearbyFrame.shown)")
test('Combat never updates protected nearby rows',setup+"combat=true; BuffTap.nearbyEvents.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); BuffTap:Refresh(); BuffTap:UpdateNearbyWindow(); assert(not BuffTap.action)")
test('Range change updates nearby list without aura event',setup+"local old=C_Spell.IsSpellInRange; C_Spell.IsSpellInRange=function(_,u) return u~='nameplate1' end; advance(1.3); assert(not BuffTap.action)")
test('Disabled feature ignores nameplate traffic',"local n=BuffTap.stats and BuffTap.stats.refreshes; BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate1'); assert(not next(BuffTap.nearbyUnits))")
test('Nearby preference follows shared profiles',setup+"assert(BuffTap:CreateSettingsProfile('Nearby copy',true)); assert(BuffTap.db.nearbyEnabled); assert(BuffTap:CreateSettingsProfile('Default',false)); assert(not BuffTap.db.nearbyEnabled)")
test('Buffs are not offered when reminder is paused',setup+"mounted=true; refresh(); assert(not BuffTap.action and #BuffTap:NearbyCandidates()==0)")
paladin=setup+"""
playerClass='PALADIN'; spells={}; book={}
spell(20217,'Blessing of Kings'); spell(19742,'Blessing of Wisdom')
BuffTap.db.targetClassBlessings=true; BuffTap.db.targetBlessingClasses.WARRIOR='priority'
BuffTap.db.targetBlessingPriorities.WARRIOR={'bok','bow'}; BuffTap.db.targetBlessingFallback=true
BuffTap.db.buffs.bok=true; BuffTap.db.buffs.bow=true
local oldExists=UnitExists; UnitExists=function(u) return u=='other' or oldExists(u) end
refresh()
"""
test('Paladin nearby preferences choose class priority',paladin+"assert(BuffTap:NearbyCandidates()[1].actions[1].key=='bok')")
test('Other caster Kings permits nearby Wisdom',paladin+"aura('nameplate1',20217,'Blessing of Kings'); auras.nameplate1[1].sourceUnit='other'; refresh(); assert(BuffTap:NearbyCandidates()[1].actions[1].key=='bow')")
test('Own nearby blessing cannot be replaced',paladin+"aura('nameplate1',19742,'Blessing of Wisdom'); auras.nameplate1[1].sourceUnit='player'; refresh(); assert(#BuffTap:NearbyCandidates()==0)")
test('Unknown nearby caster blocks fallback',paladin+"aura('nameplate1',20217,'Blessing of Kings'); refresh(); assert(#BuffTap:NearbyCandidates()==0)")
test('Class-aware disabled still preserves own nearby blessing',paladin+"BuffTap.db.targetClassBlessings=false; aura('nameplate1',19742,'Blessing of Wisdom'); auras.nameplate1[1].sourceUnit='player'; refresh(); assert(#BuffTap:NearbyCandidates()==0)")
test('Changed nearby ownership before row click cancels cast',paladin+"local row=BuffTap.nearbyFrame.rows[1]; aura('nameplate1',19742,'Blessing of Wisdom'); auras.nameplate1[1].sourceUnit='player'; row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)")
test('Turning off fallback does not choose another nearby blessing',paladin+"BuffTap.db.targetBlessingFallback=false; aura('nameplate1',20217,'Blessing of Kings'); auras.nameplate1[1].sourceUnit='other'; refresh(); assert(#BuffTap:NearbyCandidates()==0)")
test('Combat visibility registration failure leaves rows unusable',setup+"BuffTap.nearbyFrame=nil; BuffTap.nearbySetupError=nil; RegisterStateDriver=function() return false end; BuffTap:CreateNearbyWindow(); assert(BuffTap.nearbySetupError and not BuffTap.nearbyFrame.shown)")



test('Forever friendly player setting wins over old Classic setting',setup+"C_CVar.GetCVarBool=function(n) return n=='nameplateShowFriendlyPlayers' end; refresh(); assert(BuffTap.action and BuffTap.action.nearby)")
test('Old enabled setting cannot override Forever disabled setting',setup+"C_CVar.GetCVarBool=function(n) return n=='nameplateShowFriends' end; refresh(); assert(not BuffTap.action)")
test('Legacy client falls back when modern setting unavailable',setup+"C_CVar.GetCVarBool=function(n) if n=='nameplateShowFriends' then return true end end; refresh(); assert(BuffTap.action and BuffTap.action.nearby)")
test('Unknown setting is reported truthfully',setup+"C_CVar.GetCVarBool=function() return nil end; refresh(); assert(BuffTap.nearbyFrame.status.text:find('unavailable',1,true))")
test('Forever nameplate CVar update refreshes discovery',setup+"platesEnabled=false; refresh(); platesEnabled=true; BuffTap.nearbyEvents.scripts.OnEvent(nil,'CVAR_UPDATE','nameplateShowFriendlyPlayers'); advance(.3); assert(BuffTap.action and BuffTap.action.nearby)")
test('Refresh cannot move or resize a window during dragging',setup+"local f=BuffTap.nearbyFrame; local moves,resizes=0,0; f.ClearAllPoints=function() moves=moves+1 end; f.SetHeight=function() resizes=resizes+1 end; f.scripts.OnDragStart(f); refresh(); assert(BuffTap.nearbyDragging and moves==0 and resizes==0); f.scripts.OnDragStop(f); assert(not BuffTap.nearbyDragging and resizes==0)")
test('Locked nearby window cannot begin dragging',setup+"BuffTap.db.nearbyLocked=true; local f=BuffTap.nearbyFrame; f.scripts.OnDragStart(f); assert(not BuffTap.nearbyDragging)")


test('Nearby binding arms a macro instead of a nameplate spell',setup+"local b=BuffTap.button; assert(b.attrs.type1=='macro' and b.attrs.spell==nil and b.attrs.unit==nil); assert(b.attrs.macrotext:find('/targetexact Ally nameplate1',1,true))")
test('Nearby reminder is invisible and silent while the binding remains armed',setup+"local alpha,mouse,sounds; sounds=0; BuffTap.button.SetAlpha=function(_,v) alpha=v end; BuffTap.button.EnableMouse=function(_,v) mouse=v end; BuffTap.PlayAlert=function() sounds=sounds+1 end; BuffTap.db.sound=true; BuffTap:Commit(nil,'test'); refresh(); assert(BuffTap.action.nearby and BuffTap.button.attrs.type1=='macro'); assert(alpha==0 and mouse==false and sounds==0)")
test('Ordinary reminders retain their appearance and sound',setup+"local alpha,mouse,sounds; sounds=0; BuffTap.button.SetAlpha=function(_,v) alpha=v end; BuffTap.button.EnableMouse=function(_,v) mouse=v end; BuffTap.PlayAlert=function() sounds=sounds+1 end; BuffTap.db.sound=true; BuffTap.lastSound=nil; auras.player={}; refresh(); assert(BuffTap.action.target=='player' and not BuffTap.action.nearby); assert(alpha==BuffTap.db.opacity and mouse==true and sounds==1)")
test('Macro pins the chosen lower rank',setup+"spell(9885,'Mark of the Wild',60); refresh(); assert(BuffTap.action.id==5232 and BuffTap.button.attrs.macrotext:find('Mark of the Wild(Rank 2)',1,true))")
test('Ambiguous rank text cannot silently use highest rank',setup+"local a=BuffTap.action; a.rank=''; assert(not BuffTap:NearbyMacro(a))")
test('Macro rejects spell text with command injection',setup+"local a=BuffTap.action; a.name='Mark\\n/say injected'; assert(not BuffTap:NearbyMacro(a))")
test('Rank resolver disagreement blocks macro preparation',setup+"C_Spell.GetSpellIDForSpellIdentifier=function() return 9885 end; refresh(); assert(not BuffTap.action and BuffTap.nearbyCastError)")
test('No previous target ends with clear instead of selecting historical target',setup+"local old=UnitExists; UnitExists=function(u) if u=='target' then return false end return old(u) end; refresh(); local m=BuffTap.button.attrs.macrotext; assert(m:sub(-12)=='/cleartarget' or m:sub(-12)=='\\n/cleartarget'); assert(not m:find('/targetlasttarget',1,true))")
test('Already selected recipient does not switch to historical target',setup+"UnitIsUnit=function(a,b) return a==b or a=='nameplate1' and b=='target' end; refresh(); local m=BuffTap.button.attrs.macrotext; assert(m:sub(1,5)=='/cast' and not m:find('/targetlasttarget',1,true))")
test('Current target identity unreadable blocks macro preparation',setup+"UnitIsUnit=function(a,b) if b=='target' and a=='nameplate1' then return nil end return a==b end; refresh(); assert(not BuffTap.action)")
test('Binding click rebuilds restoration for current target state',setup+"local old=UnitExists; UnitExists=function(u) if u=='target' then return false end return old(u) end; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(BuffTap.button.attrs.type1=='macro' and not BuffTap.button.attrs.macrotext:find('/targetlasttarget',1,true))")
test('Binding click cancels macro when recipient gains all buffs',setup+"aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.button.attrs.type1 and not BuffTap.button.attrs.macrotext)")
test('Combat safety clears the main macro payload',setup+"safety('blocked'); assert(not BuffTap.button.attrs.type1 and not BuffTap.button.attrs.macrotext)")
test('Compact window exactly matches the approved fixed footprint',setup+"local f=BuffTap.nearbyFrame; assert(f.width==210 and f.height==134); for i=2,20 do BuffTap:TrackNearby('nameplate'..i) end; refresh(); assert(f.width==210 and f.height==134 and #f.rows==5)")
test('Shift left minimap click toggles nearby without opening options',"IsShiftKeyDown=function() return true end; BuffTap:SyncBroker(); BuffTap.minimapObject.OnClick(nil,'LeftButton'); advance(.1); assert(BuffTap.db.nearbyEnabled and not (BuffTap.options and BuffTap.options.shown)); BuffTap.minimapObject.OnClick(nil,'LeftButton'); advance(.1); assert(not BuffTap.db.nearbyEnabled)")
test('Combat prevents minimap nearby toggle',"IsShiftKeyDown=function() return true end; BuffTap:SyncBroker(); combat=true; BuffTap.minimapObject.OnClick(nil,'LeftButton'); assert(not BuffTap.db.nearbyEnabled)")
test('Minimap tooltip explains nearby shortcut',"BuffTap:SyncBroker(); local lines={}; BuffTap.minimapObject.OnTooltipShow({AddLine=function(_,s) lines[#lines+1]=s end}); assert(table.concat(lines,' '):find('Shift-left-click',1,true))")


test('Nearby debug includes attempted row cast and immediate client error',setup+"local row=BuffTap.nearbyFrame.rows[1]; row.scripts.PreClick(row,'LeftButton',true); BuffTap.nearbyEvents.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,'Target not in line of sight'); local text=table.concat(BuffTap:DiagnosticsLines(),' '); assert(text:find('5232 -> nameplate1',1,true) and text:find('Target not in line of sight',1,true))")
test('Nearby debug never records restricted client errors',setup+"BuffTap:NoteNearbyClick(BuffTap.action); BuffTap.nearbyEvents.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,{secret=true}); assert(not BuffTap.nearbyClickError)")
test('Unrelated later client errors are excluded from nearby debug',setup+"BuffTap:NoteNearbyClick(BuffTap.action); advance(2); BuffTap.nearbyEvents.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,'Unrelated error'); assert(not BuffTap.nearbyClickError)")


test('Exact target uses client full name without guessing realm or surname',setup+"GetUnitName=function() return 'Farbror-Camelot' end; refresh(); assert(BuffTap.button.attrs.macrotext:find('/targetexact Farbror-Camelot',1,true)); assert(not BuffTap.button.attrs.macrotext:find('@target',1,true))")
test('Unsafe recipient name cannot become macro commands',setup+"GetUnitName=function() return 'Farbror\\n/say injected' end; refresh(); assert(not BuffTap.action and BuffTap.nearbyCastError)")
test('Unreadable full name blocks casting rather than guessing a spelling',setup+"GetUnitName=function() return {secret=true} end; refresh(); assert(not BuffTap.action)")
test('Ambiguous short name blocks exact-name casting without full-name API',setup+"UnitName=function() return 'Ally' end; BuffTap:TrackNearby('nameplate2'); refresh(); assert(not BuffTap.action and BuffTap.nearbyCastError=='recipient name ambiguous')")
test('Druid nearby scans do not produce Paladin blessing diagnostics',setup+"BuffTap.captureDiagnostics=true; BuffTap.diagnostics={}; refresh(); assert(not table.concat(BuffTap.diagnostics,' '):find('blessings -> nameplate',1,true))")

# Model command effects separately from the addon mock, including an unavailable
# exact-name lookup. This checks macro sequencing, not the game's secure executor.
macro_model="""
local function execute(m,world,current,last)
 local casts={}
 for line in m:gmatch('[^\\n]+') do
  if line=='/cleartarget' then
   if current then last=current end; current=nil
  elseif line:sub(1,13)=='/targetexact ' then
   local found=world[line:sub(14)]
   if found then if current then last=current end; current=found end
  elseif line=='/targetlasttarget' then current,last=last,current
  elseif line:sub(1,#'/cast [help,nodead] ')=='/cast [help,nodead] ' then
   if current and current.friendly and not current.dead then casts[#casts+1]={guid=current.guid,spell=line:sub(1+#'/cast [help,nodead] ')} end
  else error('Unsupported macro command: '..line) end
 end
 return casts,current
end
"""

test('Exact-name macro model casts the selected rank and restores old target',setup+macro_model+"local old={guid='Old',friendly=true}; local ally={guid='Wanted',friendly=true}; local casts,target=execute(BuffTap.action.macroText,{['Ally nameplate1']=ally},old); assert(#casts==1 and casts[1].guid=='Wanted' and casts[1].spell=='Mark of the Wild(Rank 2)' and target==old)")
test('Failed exact-name selection cannot buff an unrelated previous target',setup+macro_model+"local old={guid='Old',friendly=true}; local casts,target=execute(BuffTap.action.macroText,{},old); assert(#casts==0 and target==old)")
test('Exact-name lookup does not fall back to a matching name prefix',setup+macro_model+"GetUnitName=function() return 'Mort' end; refresh(); local old={guid='Old',friendly=true}; local casts,target=execute(BuffTap.action.macroText,{Mortimer={guid='Wrong',friendly=true}},old); assert(#casts==0 and target==old)")
test('Dead exact-name recipient is not cast on',setup+macro_model+"local ally={guid='Wanted',friendly=true,dead=true}; local casts=execute(BuffTap.action.macroText,{['Ally nameplate1']=ally},{guid='Old',friendly=true}); assert(#casts==0)")
test('Name macro with no current target does not select a historical target',setup+macro_model+"local oldExists=UnitExists; UnitExists=function(u) if u=='target' then return false end return oldExists(u) end; refresh(); local casts,target=execute(BuffTap.action.macroText,{['Ally nameplate1']={guid='Wanted',friendly=true}},nil,{guid='Historical',friendly=true}); assert(#casts==1 and target==nil)")


test('Nearby always skips flagged players even when the caster is flagged',setup+"UnitIsPVP=function() return true end; refresh(); assert(not BuffTap.action and BuffTap.pvpBlocked)")
test('Nearby skips a recipient already fighting',setup+"UnitAffectingCombat=function(u) return u=='nameplate1' end; refresh(); assert(not BuffTap.action and BuffTap.nearbySafetyReason)")
test('Unreadable combat state cannot arm a nearby action',setup+"UnitAffectingCombat=function() return {secret=true} end; refresh(); assert(not BuffTap.action)")
test('Missing combat API cannot arm a nearby action',setup+"UnitAffectingCombat=nil; refresh(); assert(not BuffTap.action)")
test('Explicit PvP opt out still permits peaceful flagged recipients',setup+"BuffTap.db.pvpProtection=false; UnitIsPVP=function() return true end; refresh(); assert(BuffTap.action and BuffTap.action.nearby)")
test('Opting out of PvP protection does not permit combat assistance',setup+"BuffTap.db.pvpProtection=false; UnitAffectingCombat=function(u) return u=='nameplate1' end; refresh(); assert(not BuffTap.action)")
test('Nearby PvP guard applies inside battlegrounds too',setup+"IsInInstance=function() return true,'pvp' end; UnitIsPVP=function(u) return u=='nameplate1' end; refresh(); assert(not BuffTap.action)")
test('Row click cancels a newly fighting recipient',setup+"local row=BuffTap.nearbyFrame.rows[1]; UnitAffectingCombat=function(u) return u=='nameplate1' end; row.scripts.PreClick(row,'LeftButton',true); assert(not row.attrs.type1)")
test('Binding cancels a new flag even when the caster is flagged',setup+"UnitIsPVP=function() return true end; BuffTap.button.scripts.PreClick(nil,'LeftButton',true); assert(not BuffTap.button.attrs.type1)")
test('Nearby window stays visible and fixed when the list empties',setup+"local f=BuffTap.nearbyFrame; BuffTap.nearbyUserOpened=false; aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); advance(.8); assert(f.shown and f.width==210 and f.height==134 and f.status.shown)")
test('Routine refresh does not repeatedly reanchor the window',setup+"local n=0; BuffTap.nearbyFrame.ClearAllPoints=function() n=n+1 end; for i=1,5 do refresh() end; assert(n==0)")
test('Hover keeps player names in their slots and disarms stale entries',setup+"BuffTap:TrackNearby('nameplate2'); refresh(); local f=BuffTap.nearbyFrame; local first=f.rows[1].entry.guid; f.rows[1].scripts.OnEnter(f.rows[1]); aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); advance(1); assert(f.rows[1].entry.guid==first and f.rows[1].action==nil and not f.rows[1].attrs.type1 and f.rows[2].entry.unit=='nameplate2'); f.rows[1].scripts.OnLeave(f.rows[1]); advance(.2); assert(f.rows[1].entry.unit=='nameplate2')")
test('Brief missing evidence does not instantly collapse row positions',setup+"BuffTap:TrackNearby('nameplate2'); refresh(); local old=C_UnitAuras.GetAuraDataByIndex; C_UnitAuras.GetAuraDataByIndex=function(u,i) if u=='nameplate1' then error('not ready') end return old(u,i) end; refresh(); assert(BuffTap.nearbyFrame.rows[1].entry.unit=='nameplate1' and BuffTap.nearbyFrame.rows[1].action==nil); C_UnitAuras.GetAuraDataByIndex=old; refresh(); assert(BuffTap.nearbyFrame.rows[1].entry.unit=='nameplate1' and BuffTap.nearbyFrame.rows[1].action)")
test('Nameplate hide and show preserves arrival order',setup+"BuffTap:TrackNearby('nameplate2'); refresh(); BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_REMOVED','nameplate1'); BuffTap.nearbyEvents.scripts.OnEvent(nil,'NAME_PLATE_UNIT_ADDED','nameplate1'); advance(.3); assert(BuffTap:NearbyCandidates()[1].unit=='nameplate1')")
test('Remembered arrival order stays bounded across a busy city',setup+"for i=2,400 do BuffTap.nearbyUnits={}; BuffTap:TrackNearby('nameplate'..i) end; local n=0; for _ in pairs(BuffTap.nearbyOrder) do n=n+1 end; assert(n<=128)")
test('Configured wheel binding is not consumed by list scrolling',setup+"for i=2,12 do BuffTap:TrackNearby('nameplate'..i) end; refresh(); local f=BuffTap.nearbyFrame; f.scripts.OnMouseWheel(f,-1); assert(BuffTap.nearbyOffset==0); f.scroll:SetValue(2); assert(BuffTap.nearbyOffset==2 and f.rows[1].entry.unit=='nameplate3')")
test('Unbound wheel still scrolls the list',setup+"BuffTap.db.keys={'F8'}; for i=2,12 do BuffTap:TrackNearby('nameplate'..i) end; refresh(); BuffTap.nearbyFrame.scripts.OnMouseWheel(nil,-1); assert(BuffTap.nearbyOffset==1)")
test('No action payload is rewritten on unchanged display refresh',setup+"local row=BuffTap.nearbyFrame.rows[1]; local set=row.SetAttribute; local n=0; row.SetAttribute=function(self,k,v) n=n+1; set(self,k,v) end; refresh(); assert(n==0)")


test('Header drag handle moves the fixed frame',setup+"local f=BuffTap.nearbyFrame; f.dragHandle.scripts.OnDragStart(f.dragHandle); assert(BuffTap.nearbyDragging); f.dragHandle.scripts.OnDragStop(f.dragHandle); assert(not BuffTap.nearbyDragging)")


# Drive the same target-change events the secure nearby macro generates.
sound_switch=setup+"""
local sounds=0; PlaySound=function() sounds=sounds+1; return true end
BuffTap.db.sound=true; BuffTap.lastSound=nil; BuffTap.lastAlertSound=nil
local originalGUID=UnitGUID; local current='Player-original'
UnitGUID=function(u) return u=='target' and current or originalGUID(u) end
UnitIsUnit=function(a,b) return a==b or UnitGUID(a)==UnitGUID(b) end
BuffTap.db.friendlyTarget=true
local nearby=BuffTap:NearbyCandidates()[1].actions[1]
BuffTap:NoteNearbyClick(nearby)
"""

test('Temporary nearby target selection does not produce a normal reminder ding',sound_switch+"current=nearby.targetGUID; BuffTap.events.scripts.OnEvent(nil,'PLAYER_TARGET_CHANGED'); assert(BuffTap.action.quickTarget and not BuffTap.action.nearby and sounds==0)")
test('Restoring the previous target stays quiet through early target retries',sound_switch+"current=nearby.targetGUID; BuffTap.events.scripts.OnEvent(nil,'PLAYER_TARGET_CHANGED'); current='Player-original'; BuffTap.events.scripts.OnEvent(nil,'PLAYER_TARGET_CHANGED'); advance(.8); assert(sounds==0 and BuffTap.lastSound==nil and BuffTap.lastAlertSound==nil)")
test('Late target retries for the same nearby transaction remain quiet',sound_switch+"current='Player-original'; BuffTap.events.scripts.OnEvent(nil,'PLAYER_TARGET_CHANGED'); advance(2); BuffTap:Commit(nil,'late target data'); refresh(); assert(sounds==0)")
test('An unrelated manually selected player retains normal reminder sound',sound_switch+"current='Player-manual'; BuffTap.events.scripts.OnEvent(nil,'PLAYER_TARGET_CHANGED'); assert(sounds==1)")
test('Personal buff reminders are not muted by a nearby cast',sound_switch+"BuffTap.db.friendlyTarget=false; auras.player={}; refresh(); assert(BuffTap.action.target=='player' and sounds==1)")
test('Sound preview remains available during nearby target settling',sound_switch+"assert(BuffTap:PlayAlert('reminder',true)); assert(sounds==1)")
test('Supply alerts are not muted by nearby target settling',sound_switch+"BuffTap.db.suppliesSound=true; assert(BuffTap:PlayAlert('supply')); assert(sounds==1)")
test('Scoped target silence expires without changing saved sound preferences',sound_switch+"advance(5.1); current='Player-original'; BuffTap.events.scripts.OnEvent(nil,'PLAYER_TARGET_CHANGED'); assert(sounds==1 and BuffTap.db.sound==true and BuffTap.nearbyQuietCast==nil)")
test('Merely opening the nearby window does not mute a normal target reminder',setup+"local sounds=0; PlaySound=function() sounds=sounds+1; return true end; BuffTap.db.sound=true; BuffTap.db.friendlyTarget=true; BuffTap.lastSound=nil; BuffTap.lastAlertSound=nil; BuffTap.events.scripts.OnEvent(nil,'PLAYER_TARGET_CHANGED'); assert(sounds==1)")

test('Cooldown keeps nearby rows visible but disarmed',setup+"local start=now; C_Spell.GetSpellCooldown=function() return {startTime=start,duration=1.5,isEnabled=true} end; BuffTap:Refresh(); advance(.9); local row=BuffTap.nearbyFrame.rows[1]; assert(row.shown and row.entry and row.action and row.action.ready==false); assert(not row.attrs.type1 and not BuffTap.action); advance(.8); assert(BuffTap.action and row.attrs.type1=='macro')")
test('Nearby successful cast catches delayed aura without UNIT_AURA',setup+"local action=BuffTap.action; BuffTap:NoteNearbyClick(action); BuffTap:NearbyCastSucceeded('player',action.id); advance(.2); auras.nameplate1={{spellId=5232,name='Mark of the Wild',duration=1800,expirationTime=now+1800}}; advance(.4); assert(BuffTap.action and BuffTap.action.key=='thorns'); assert(#BuffTap:NearbyCandidates()[1].actions==1)")
test('Normal self buff catches delayed aura without UNIT_AURA',"local action=BuffTap.action; assert(action.target=='player'); BuffTap:BeginHelperAttempt(action); BuffTap:BuffCastSucceeded('player',action.id); advance(.2); auras.player={{spellId=5232,name='Mark of the Wild',duration=1800,expirationTime=now+1800}}; advance(.4); assert(BuffTap.action and BuffTap.action.key=='thorns')")
test('Normal freshness expires instead of permanently disabling cache',"local action=BuffTap.action; BuffTap:BeginHelperAttempt(action); advance(3.1); BuffTap:GetAuras('player'); local cache=BuffTap.auraCache.player; BuffTap:GetAuras('player'); assert(BuffTap.auraCache.player==cache)")
test('Unrelated spell success never schedules buff aura retries',"BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:BuffCastSucceeded('player',999); assert(not BuffTap.timers['buff-aura-early']); BuffTap:BuffCastSucceeded('party1',5232); assert(not BuffTap.timers['buff-aura-early'])")
test('Recycled normal recipient cannot refresh former cast identity',"local action=BuffTap.action; BuffTap:BeginHelperAttempt(action); local old=UnitGUID; UnitGUID=function(u) return u=='player' and 'Player-New' or old(u) end; BuffTap:BuffCastSucceeded('player',action.id); assert(not BuffTap.timers['buff-aura-early'])")
test('Combat cancels normal buff aura retries',"BuffTap:BeginHelperAttempt(BuffTap.action); BuffTap:BuffCastSucceeded('player',5232); combat=true; BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); assert(not BuffTap.timers['buff-aura-early'] and not BuffTap.timers['buff-aura-settle'] and not BuffTap.timers['buff-aura-late']); assert(not BuffTap.buffAuraFresh)")

test('Secondary spell range change is detected while first spell stays in range',setup+"local close=false; C_Spell.IsSpellInRange=function(id,u) return id~=467 or close end; BuffTap:Refresh(); assert(#BuffTap:NearbyCandidates()[1].actions==1); BuffTap:CancelTimer('nearby-settle'); BuffTap:CancelTimer('nearby-late'); close=true; advance(1.3); assert(#BuffTap:NearbyCandidates()[1].actions==2)")

test('Nearby distinguishes low mana from fully buffed recipients',setup+"C_Spell.IsSpellUsable=function() return false,true end; BuffTap:Refresh(); assert(not BuffTap.action and BuffTap.manaBlocked); assert(BuffTap.nearbyFrame.status.text=='Not enough mana to buff.'); C_Spell.IsSpellUsable=function() return true,false end; BuffTap.events.scripts.OnEvent(nil,'UNIT_POWER_UPDATE','player'); advance(.2); assert(BuffTap.action and not BuffTap.manaBlocked)")
test('Other unusable spells are not labelled low mana',setup+"C_Spell.IsSpellUsable=function() return false,false end; BuffTap:Refresh(); assert(not BuffTap.manaBlocked); assert(BuffTap.nearbyFrame.status.text:find('requirements',1,true))")

test('Nearby stronger rejection advances to another missing buff with helper off',setup+"assert(not BuffTap.db.helperBounce); SPELL_FAILED_AURA_BOUNCED='Stronger effect'; local action=BuffTap.action; BuffTap:BeginHelperAttempt(action); BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',action.id); BuffTap.events.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,SPELL_FAILED_AURA_BOUNCED); advance(.2); assert(BuffTap:HelperSuppressed(action)); assert(BuffTap.action and BuffTap.action.key=='thorns')")
test('Nearby row rejection skips fully blocked player for next recipient',setup+"BuffTap:TrackNearby('nameplate2'); aura('nameplate1',467,'Thorns'); refresh(); local row=BuffTap.nearbyFrame.rows[1]; assert(row.action.target=='nameplate1'); row.scripts.PreClick(row,'LeftButton',true); local id=row.action.id; SPELL_FAILED_AURA_BOUNCED='Stronger effect'; BuffTap.events.scripts.OnEvent(nil,'UI_ERROR_MESSAGE',1,SPELL_FAILED_AURA_BOUNCED); BuffTap.events.scripts.OnEvent(nil,'UNIT_SPELLCAST_FAILED','player','cast',id); advance(.2); assert(BuffTap.action and BuffTap.action.target=='nameplate2')")
test('Nearby stronger error alone does not suppress',setup+"local action=BuffTap.action; BuffTap:BeginHelperAttempt(action); SPELL_FAILED_AURA_BOUNCED='Stronger effect'; BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(not BuffTap:HelperSuppressed(action))")
test('Nearby unrelated failed spell cannot suppress recipient',setup+"local action=BuffTap.action; BuffTap:BeginHelperAttempt(action); SPELL_FAILED_AURA_BOUNCED='Stronger effect'; BuffTap:HandleHelperFailure(999); BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(not BuffTap:HelperSuppressed(action))")
test('Normal buff bounce remains opt in',"assert(not BuffTap.db.helperBounce); local action=BuffTap.action; BuffTap:BeginHelperAttempt(action); SPELL_FAILED_AURA_BOUNCED='Stronger effect'; BuffTap:HandleHelperFailure(action.id); BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(not BuffTap:HelperSuppressed(action))")
test('Restore reminders restores nearby stronger buff suppression',setup+"local action=BuffTap.action; BuffTap:BeginHelperAttempt(action); SPELL_FAILED_AURA_BOUNCED='Stronger effect'; BuffTap:HandleHelperFailure(action.id); BuffTap:HandleHelperError(SPELL_FAILED_AURA_BOUNCED); assert(BuffTap:HelperSuppressed(action)); BuffTap:RestoreHelpers(); assert(not BuffTap:HelperSuppressed(action))")

test('Target options directly toggle Nearby and follow profile state',"BuffTap:Options(); local c=BuffTap.options.nearbyEnable; assert(c and not c:GetChecked()); c:SetChecked(true); c.scripts.OnClick(c); assert(BuffTap.db.nearbyEnabled and c:GetChecked()); c:SetChecked(false); c.scripts.OnClick(c); assert(not BuffTap.db.nearbyEnabled and not c:GetChecked())")
