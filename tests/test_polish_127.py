from test_bufftap import test
from test_nearby_invites import social

# Nearby in combat: on by default, migrated once.
test('Existing 1.26.15 setting is switched on once',"BuffTap.db.nearbyInCombat=false; BuffTap.db.nearbyInCombatRule=nil; BuffTap:InitDB(); assert(BuffTap.db.nearbyInCombat==true and BuffTap.db.nearbyInCombatRule==1)")
test('A later choice to turn it off sticks',"BuffTap.db.nearbyInCombat=false; BuffTap.db.nearbyInCombatRule=1; BuffTap:InitDB(); assert(BuffTap.db.nearbyInCombat==false)")
test('Restore defaults turns Nearby in combat back on',social+"BuffTap.db.nearbyInCombat=false; BuffTap:Options(); local o=BuffTap.options; local reset=o.nearbyResetLook; assert(reset and reset.visualConfirm); reset.scripts.OnClick(reset); assert(BuffTap.db.nearbyInCombat==false); reset.scripts.OnClick(reset); assert(BuffTap.db.nearbyInCombat==true and BuffTap.nearbyFrame.keepsCombat==true)")

# Scrollbars only show when there is something to scroll.
sc="local T=BuffTap.OptionsTheme; local function make(range) local s=CreateFrame('ScrollFrame'); s.hooks={}; s.HookScript=function(self,k,fn) self.hooks[k]=fn end; local bar=CreateFrame('Slider'); bar.SetAlpha=function(self,a) self.alpha=a end; s.ScrollBar=bar; s.range=range; s.GetVerticalScrollRange=function(self) return self.range end; T.ScrollBar(s); return s end; "
test('Scrollbar hides when the content fits',sc+"local s=make(0); assert(s.ScrollBar.alpha==0)")
test('Scrollbar shows when the content overflows',sc+"local s=make(120); assert(s.ScrollBar.alpha==1)")
test('Scrollbar follows range changes',sc+"local s=make(0); s.range=80; s.hooks.OnScrollRangeChanged(s,0,80); assert(s.ScrollBar.alpha==1); s.range=0; s.hooks.OnScrollRangeChanged(s,0,0); assert(s.ScrollBar.alpha==0)")
test('Scrollbar gets its own quiet thumb',sc+"local s=make(50); assert(s.ScrollBar.visualThumb)")

# Preview always plays, even when the category or the buff's own sound is muted.
for kind,field in [('reminder','sound'),('supply','suppliesSound'),('camp','campSound'),('cleanse','cleanseSoundEnabled'),('social','socialSoundEnabled')]:
    test('Preview plays while %s sound is muted'%kind,"BuffTap.db.%s=false; assert(BuffTap:PlayAlert('%s',true)==true)"%(field,kind))
    test('Automatic %s sound stays silent while muted'%kind,"BuffTap.db.%s=false; BuffTap.db.pauseResting=false; BuffTap.lastAlertSound=nil; assert(BuffTap:PlayAlert('%s',false)==false)"%(field,kind))

# Camping page: benefit tiles show the live state.
camp="BuffTap:Options(); local f=BuffTap.options; assert(f.campTiles and #f.campTiles==2); "
test('Camping tiles show time left and stacks',camp+"BuffTap:UpdateCampingOptions({active=true,remaining=7101,bagActive=true,bagStacks=2,bagRemaining=3600}); assert(f.campTiles[1].value:GetText()=='118m 21s'); assert(f.campTiles[2].value:GetText()=='60 min'); assert(f.campTiles[2].note:GetText()=='2 of 3 stacks')")
test('Camping tiles say Missing when nothing is active',camp+"BuffTap:UpdateCampingOptions({active=false,bagActive=false}); assert(f.campTiles[1].value:GetText()=='Missing' and f.campTiles[2].value:GetText()=='Missing')")
test('Camping tiles say Unavailable when the state is unknown',camp+"BuffTap:UpdateCampingOptions({globalUnknown=true}); assert(f.campTiles[1].value:GetText()=='Unavailable' and f.campTiles[2].value:GetText()=='Unavailable')")
test('Camping tiles repaint as time passes',camp+"BuffTap:PaintCampingTiles({active=true,remaining=100}); assert(f.campTiles[1].value:GetText()=='1m 40s'); BuffTap:PaintCampingTiles({active=true,remaining=99}); assert(f.campTiles[1].value:GetText()=='1m 39s')")
test('Camping switches keep working inside their tiles',camp+"f.campingTrack:SetChecked(true); f.campingTrack:GetScript('OnClick')(f.campingTrack); assert(BuffTap.db.campTrackBenefits==true)")

# Groups: raid group choices are pills inside the shared-settings tiles.
test('Raid group choices are pill chips',"BuffTap:Options(); local f=BuffTap.options; assert(f.groupChecks and f.groupChecks[1].visualCheck and f.groupChecks[1].visualCheck.chip==true and not f.groupChecks[1].visualCheck.toggle)")
test('Groups shared card has five tiles',"BuffTap:Options(); assert(#BuffTap.options.groupTiles==5)")

# Tanks / Healers mode: the class choices go away instead of sitting dimmed.
tankG="local B=BuffTap; playerClass='DRUID'; B.db.group=true; spell(467,'Thorns'); B.db.buffs.thorns=true; B:GroupSettings(nil,true).buffRoles={thorns='tank'}; B:Options(); local f=B.options; local row; for _,r in ipairs(f.assignRows) do if r.def and r.def.key=='thorns' then row=r end end; assert(row and row.classes); "
test('Tank mode hides the class choices',tankG+"for _,c in pairs(row.classes) do assert(c.shown==false) end")
test('By class mode shows the class choices',"local B=BuffTap; playerClass='DRUID'; B.db.group=true; spell(467,'Thorns'); B.db.buffs.thorns=true; B:GroupSettings(nil,true).buffRoles={}; B:Options(); local row=B.options.assignRows[1]; local n=0; for _,c in pairs(row.classes) do n=n+1; assert(c.shown~=false) end; assert(n>0)")

# Blacklist: the current target is shown and the Block buttons follow it.
bt="local B=BuffTap; B:Options(); local f=B.options; "
test('Blacklist shows the targeted player and guild',bt+"UnitName=function() return 'Thrall' end; UnitIsPlayer=function() return true end; GetGuildInfo=function() return 'Horde Elite' end; B:UpdateBlacklistTarget(); assert(f.blackTargetLabel.text=='Thrall  <Horde Elite>'); assert(f.blackTarget.enabled and f.blackTargetGuild.enabled)")
test('Blacklist with no target disables both Block buttons',bt+"UnitName=function() return nil end; UnitIsPlayer=function() return false end; GetGuildInfo=function() return nil end; B:UpdateBlacklistTarget(); assert(f.blackTargetLabel.text=='No target selected'); assert(not f.blackTarget.enabled and not f.blackTargetGuild.enabled)")
test('Blacklist with a non-player target blocks nothing',bt+"UnitName=function() return 'Wolf' end; UnitIsPlayer=function() return false end; GetGuildInfo=function() return nil end; B:UpdateBlacklistTarget(); assert(f.blackTargetLabel.text=='Wolf is not a player'); assert(not f.blackTarget.enabled)")

# Weapons: the Off hand oil row only appears for classes that can dual-wield (or with an off-hand weapon).
offrow="local B=BuffTap; B.db.weaponReminder=true; "
test('Paladin has no Off hand oil row',offrow+"playerClass='PALADIN'; B:Options(); assert(B.options.coatingPickers.off.shown==false)")
test('Rogue keeps the Off hand oil row',offrow+"playerClass='ROGUE'; B:Options(); assert(B.options.coatingPickers.off.shown==true)")

from test_bufftap import ROOT
RECORD_PT=(ROOT/'tests/nearby_preview_record.lua').read_text(encoding='utf-8-sig')
# Nearby: the how-it-works tutorial starts folded and remembers the choice.
ng="local B=BuffTap; playerClass='DRUID'; "
test('Nearby guide starts collapsed',ng+"B:Options(); local f=B.options; B:UpdateClassAwarePages(); assert(f.nearbyGuide.shown==false); assert(f.nearbyGuideCard.height==52)")
test('Nearby guide opens and closes from the toggle',ng+"B.db.nearbyGuideOpen=true; B:Options(); local f=B.options; B:UpdateClassAwarePages(); assert(f.nearbyGuide.shown~=false); assert(f.nearbyGuideCard.height==424); B.db.nearbyGuideOpen=false; B:UpdateClassAwarePages(); assert(f.nearbyGuide.shown==false)")

# Nearby guide: the combat note is translated in every language file.
cn="Nearby stays open in combat, so invitations still work. You can change this under Customization > Nearby window."
for loc in ('deDE','esES','frFR','ptBR'):
    txt=open(ROOT/('addon/BuffTap/Locales/'+loc+'.lua'),encoding='utf-8').read()
    assert 'B.Locales.'+loc+'["'+cn+'"]=' in txt, loc
test('Paladin hides the Off hand switch too',offrow+"playerClass='PALADIN'; B:Options(); assert(B.options.weaponOff.shown==false)")
test('Rogue shows the Off hand switch',offrow+"playerClass='ROGUE'; B:Options(); assert(B.options.weaponOff.shown~=false)")
test('Blacklist list rules stop inside their cards',"local B=BuffTap; B:Options(); local f=B.options; for i,l in ipairs(f.blackLists) do local x=(i==1) and 12 or 364; assert(l.title.sectionRight==x+324); if type(l.title.width)=='number' then assert(l.title.width<=x+324-(x+16+22)+0.5,tostring(l.title.width)) end end")
for cls,want in (('PALADIN',-478),('DRUID',-510)):
    test('Combat expiry position '+cls,RECORD_PT+"playerClass='"+cls+"'; local B=BuffTap; B:Options(); local p=B.options.combatExpiry.__draw.points[1]; assert(p[5]==%d,tostring(p[5]))"%want)
test('Section icons also appear for translated titles',"local B=BuffTap; B.locale='deDE'; B.Locales.deDE={['How Nearby works']='So funktioniert Umgebung'}; assert(B.OptionsTheme.SectionIconFor({},'so funktioniert umgebung')=='Nearby'); assert(B.OptionsTheme.SectionIconFor({},'how nearby works')=='Nearby'); assert(B.OptionsTheme.SectionIconFor({sectionKey='guilds'},'gilden (0)')=='Groups')")
gem="local B=BuffTap; playerClass='DRUID'; B.db.group=true; B:Options(); local f=B.options; "
test('Groups card has an emblem tile',gem+"assert(f.groupEmblem and f.groupEmblemTile); assert(f.groupEmblem.texture and tostring(f.groupEmblem.texture):find('GroupParty'),tostring(f.groupEmblem.texture))")
test('Raid context swaps the emblem',gem+"f.groupContext='Raid'; B:Options(); assert(tostring(B.options.groupEmblem.texture):find('GroupRaid'),tostring(B.options.groupEmblem.texture))")
for loc in ('deDE','esES','frFR','ptBR'):
    txt=open(ROOT/('addon/BuffTap/Locales/'+loc+'.lua'),encoding='utf-8').read()
    for k in ("One group spell instead of several singles.","Also buff your pet and your group's pets.","Players needed before a group spell is used.","Refresh low buffs at ready checks."):
        assert 'B.Locales.'+loc+'["'+k+'"]=' in txt, (loc,k)
test('Groups card helper lines show for a class with group spells',gem+"assert(f.groupNotes.smart.shown~=false and f.groupNotes.need.shown~=false); assert(f.groupSharedCard.height==162,tostring(f.groupSharedCard.height))")

