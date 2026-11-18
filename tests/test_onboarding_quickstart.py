from test_bufftap import test

FRESH="local B=BuffTap; B.db.onboardingVersion=nil; B.db.welcomeSeen=false; B:ShowOnboarding(); "
APPLY="assert(B:ApplyFirstRunSetup(B.onboarding.quickSelection)); "

test('Quick start enables only the intended extras in one action',FRESH+
     "local chime=B.db.reminderSound; local keys=table.concat(B.db.keys,','); "+APPLY+
     "assert(B.db.nearbyEnabled and B.db.nearbyIntroSeen and B.db.sound and B.db.pauseResting and B.db.helperBounce); assert(B.db.cleanseEnabled and B.db.reviveEnabled and B.db.cleanseFirst); assert(not B.db.helperThanks and not B.db.smartShift and not B.db.reviveRebirth and not B.db.nearbyRequests); assert(B.db.campSound and B.db.suppliesSound and B.db.cleanseSoundEnabled and B.db.socialSoundEnabled and B.db.reminderSound==chime and table.concat(B.db.keys,',')==keys); assert(not B.db.consumablesEnabled and not B.db.weaponApply and not B.db.helperPet and not B.db.helperSoulstone); assert(not B.onboarding.shown and not (B.nearbyIntro and B.nearbyIntro.shown) and not B:OnboardingPending())")
test('Welcome includes Get started and no mandatory second page',FRESH+
     "local found; for _,r in ipairs(B.onboarding.pageRegions) do if r.text=='Get started' then found=r end end; assert(found); found.scripts.OnClick(); assert(B.db.welcomeSeen and B.db.nearbyEnabled and not B.onboarding.shown)")
test('Customize Back stages choices without writing settings',FRESH+
     "B:OnboardingSettingsPage(); for _,v in ipairs(B.onboarding.choices) do if v.spec.key=='nearby' then v.check:SetChecked(false); v.check.scripts.OnClick(v.check); break end end; B:OnboardingWelcomePage(); assert(not B.db.nearbyEnabled and not B.db.sound and not B.db.welcomeSeen); assert(not B.onboarding.quickSelection.nearby)")
test('Customize applies explicit deselections and opt-in solo thanks',FRESH+
     "B:OnboardingSettingsPage(); for _,v in ipairs(B.onboarding.choices) do if v.spec.key=='nearby' or v.spec.key=='sounds' then v.check:SetChecked(false) elseif v.spec.key=='thanks' then v.check:SetChecked(true) end end; assert(B:ApplyOnboarding()); assert(not B.db.nearbyEnabled and not B.db.sound and B.db.helperThanks)")
test('Keep current settings and explicit X suppress all welcome cards',FRESH+
     "local keep; for _,r in ipairs(B.onboarding.pageRegions) do if r.text=='Keep current settings' then keep=r end end; assert(keep); keep.scripts.OnClick(); assert(not B.db.nearbyEnabled and not B.db.sound); B:ScheduleWelcome(); advance(4); assert(not B.onboarding.shown and not (B.welcome and B.welcome.shown))")
test('Escape dismisses without committing staged choices',FRESH+
     "B.onboarding.scripts.OnKeyDown(B.onboarding,'ESCAPE'); assert(B.db.welcomeSeen and not B.db.sound and not B.db.nearbyEnabled)")
test('Loading-screen hide does not finish first run',FRESH+
     "B.onboarding:Hide(); assert(B:OnboardingPending() and not B.db.welcomeSeen)")
test('Returning and completed legacy characters never replay setup',
     "local B=BuffTap; B.db.welcomeSeen=true; B.db.onboardingVersion=nil; assert(not B:OnboardingPending()); B:ScheduleWelcome(); advance(4); assert(not (B.onboarding and B.onboarding.shown)); B.db.welcomeSeen=nil; B.db.onboardingVersion=1; B:ScheduleWelcome(); advance(4); assert(not (B.welcome and B.welcome.shown))")
test('Manual review reflects current choices and preserves existing class plans',
     "local B=BuffTap; playerClass='DRUID'; B.db.welcomeSeen=true; B.db.smartShift=true; B.db.helperThanks=true; B.db.nearbyResting=false; B:ShowOnboarding(true); assert(not B.onboarding.quickSelection.sounds and B.onboarding.quickSelection.thanks); B.onboarding.quickSelection.sounds=true; "+APPLY+
     "assert(B.db.sound and B.db.helperThanks and B.db.smartShift and not B.db.nearbyResting)")
test('Combat and malformed staged selections cannot apply or finish',FRESH+
     "assert(not B:ApplyFirstRunSetup({weaponApply=true})); combat=true; assert(not B:ApplyFirstRunSetup(B.onboarding.quickSelection)); assert(not B.db.sound and not B.db.welcomeSeen); combat=false; assert(not B:ApplyFirstRunSetup({sounds='yes'}))")
test('Failed normalization restores character and shared profile settings',FRESH+
     "local camp=B.db.campSound; B.NormalizeAlerts=function() error('test failure') end; assert(not B:ApplyFirstRunSetup(B.onboarding.quickSelection)); assert(not B.db.sound and not B.db.nearbyEnabled and not B.db.welcomeSeen and B.db.campSound==camp and B:OnboardingPending())")
test('Quick start respects existing optional modules and suboptions',FRESH+
     "B.db.consumablesEnabled=true; B.db.weaponApply=true; B.db.helperPet=true; B.db.smartShift=true; B.db.nearbyRequests=true; B.db.nearbyBuffing=false; "+APPLY+
     "assert(B.db.consumablesEnabled and B.db.weaponApply and B.db.helperPet and B.db.smartShift and B.db.nearbyRequests and not B.db.nearbyBuffing)")
test('Quick start never writes game CVars',FRESH+
     "local writes=0; C_CVar={GetCVar=function() return '0' end,SetCVar=function() writes=writes+1 end}; "+APPLY+"assert(writes==0)")

CVARS="local B=BuffTap; local values={nameplateShowFriendlyPlayers='0',nameplateShowOnlyNameForFriendlyPlayerUnits='0'}; local writes={}; C_CVar={GetCVar=function(k) return values[k] end,SetCVar=function(k,v) writes[#writes+1]=k; values[k]=v end}; GetCVar=nil; GetCVarBool=nil; "
test('Explicit names-only action probes writes and verifies both friendly settings',CVARS+
     "assert(B:CanEnableFriendlyNamesOnly()); assert(B:EnableFriendlyNamesOnly()); assert(values.nameplateShowFriendlyPlayers=='1' and values.nameplateShowOnlyNameForFriendlyPlayerUnits=='1'); assert(#writes==2 and writes[1]=='nameplateShowOnlyNameForFriendlyPlayerUnits')")
test('Unsupported names-only CVar does not change friendly visibility',CVARS+
     "values.nameplateShowOnlyNameForFriendlyPlayerUnits=nil; assert(not B:CanEnableFriendlyNamesOnly() and not B:EnableFriendlyNamesOnly() and #writes==0)")
test('Unreadable names-only CVar does not claim support',CVARS+
     "values.nameplateShowOnlyNameForFriendlyPlayerUnits={secret=true}; assert(not B:EnableFriendlyNamesOnly() and #writes==0)")
test('Failed names-only readback cannot enable full bars',CVARS+
     "C_CVar.SetCVar=function(k,v) writes[#writes+1]=k end; assert(not B:EnableFriendlyNamesOnly()); assert(values.nameplateShowFriendlyPlayers=='0'); for _,k in ipairs(writes) do assert(k~='nameplateShowFriendlyPlayers') end")
test('Failed friendly visibility readback restores original names presentation',CVARS+
     "C_CVar.SetCVar=function(k,v) if k~='nameplateShowFriendlyPlayers' then values[k]=v end end; assert(not B:EnableFriendlyNamesOnly()); assert(values.nameplateShowOnlyNameForFriendlyPlayerUnits=='0' and values.nameplateShowFriendlyPlayers=='0')")
test('Combat blocks all names-only writes',CVARS+
     "combat=true; assert(not B:EnableFriendlyNamesOnly() and #writes==0)")
test('Fallback friendly visibility key is honored without touching enemies',CVARS+
     "values.nameplateShowFriendlyPlayers=nil; values.nameplateShowFriends='0'; assert(B:EnableFriendlyNamesOnly()); assert(values.nameplateShowFriends=='1'); for _,k in ipairs(writes) do assert(not k:find('Enemy')) end")
test('No friendly names action when friendly plates already work',CVARS+
     "values.nameplateShowFriendlyPlayers='1'; B.db.onboardingVersion=nil; B.db.welcomeSeen=false; B:ShowOnboarding(); for _,r in ipairs(B.onboarding.pageRegions) do assert(r.text~='Enable friendly names only') end; assert(#writes==0)")
test('Nearby waiting warning remains after setup and Thanks has no hard plate gate',CVARS+
     "B.db.onboardingVersion=nil; B.db.welcomeSeen=false; B:ShowOnboarding(); local warning; for _,r in ipairs(B.onboarding.pageRegions) do if r.text and r.text:find('waiting for friendly nameplates',1,true) then warning=true end end; assert(warning); B.onboarding.quickSelection.thanks=true; "+APPLY+
     "assert(B.db.helperThanks and B.db.nearbyEnabled and #writes==0); assert(B:FriendlyPlatesState()==false)")

for cls in ('MAGE','PALADIN','DRUID','SHAMAN','WARLOCK','WARRIOR','PRIEST','HUNTER','ROGUE'):
 test('Quick-start class spot check '+cls,FRESH+"playerClass='"+cls+"'; B:NormalizeGroupContexts(); B.onboarding.quickSelection=nil; B:OnboardingWelcomePage(); "+APPLY+
      "assert(not B.db.weaponApply and not B.db.helperPet and not B.db.helperHealthstone and not B.db.helperSoulstone and not B.db.helperOath and not B.db.smartShift and not B.db.helperThanks and not B.db.nearbyRequests and not B.db.reviveRebirth); assert(B.db.cleanseEnabled==(B:CanCleanseAnything() and true or false)); assert(B.db.reviveEnabled==(B:CanConfigureRevive() and true or false))")
test('Fresh Paladin reuses adaptive plan without replacing configured blessings',FRESH+
     "playerClass='PALADIN'; B.db.blessingClasses={WARRIOR='bow'}; B:NormalizeGroupContexts(); B.onboarding.quickSelection=nil; B:OnboardingWelcomePage(); "+APPLY+"assert(B.db.blessingClasses.WARRIOR=='bow')")
COPY_BUTTON=FRESH+"local current=B.profileDB:GetCurrentProfile(); assert(B:CreateSettingsProfile('Copy source',false)); B.db.sound=false; B:SaveClassSetup(); B:SelectSettingsProfile(current); B:ShowOnboarding(); local original=CreateFrame; local buttons={}; CreateFrame=function(...) local f=original(...); buttons[#buttons+1]=f; return f end; B:OnboardingCopyPage(); CreateFrame=original; local choice; for _,f in ipairs(buttons) do if f.text=='Copy source' then choice=f end end; assert(choice); "
test('Copied profile closes directly without enabling quick-start extras',COPY_BUTTON+
     "choice.scripts.OnClick(choice); assert(not B.db.sound and not B.db.nearbyEnabled and B.db.welcomeSeen and not B.onboarding.shown)")
test('Copy failure keeps the dialog open and never falls back to quick start',COPY_BUTTON+
     "B.CopySettingsProfile=function() return false end; choice.scripts.OnClick(choice); assert(B.onboarding.shown and not B.db.sound and not B.db.welcomeSeen)")
test('Fresh Paladin role-only preferences are never replaced',FRESH+
     "playerClass='PALADIN'; B.db.blessingRolePriorities.Party={HEALER={PRIEST={'bom'}}}; B:NormalizeGroupContexts(); B.onboarding.quickSelection=nil; B:OnboardingWelcomePage(); "+APPLY+"assert(B.db.blessingRolePriorities.Party.HEALER.PRIEST[1]=='bom')")
test('Explicit close button keeps all staged changes unapplied',
     "local B=BuffTap; B.db.onboardingVersion=nil; B.db.welcomeSeen=false; local original=CreateFrame; local buttons={}; CreateFrame=function(...) local f=original(...); buttons[#buttons+1]=f; return f end; B:ShowOnboarding(); CreateFrame=original; local close; for _,f in ipairs(buttons) do if f.glyph then close=f end end; assert(close); close.scripts.OnClick(close); assert(B.db.welcomeSeen and not B.db.sound and not B.db.nearbyEnabled)")
test('Quick-start completion persists after database normalization',FRESH+APPLY+
     "B:InitDB(); B:ScheduleWelcome(); advance(4); assert(B.db.sound and B.db.nearbyEnabled and not B:OnboardingPending() and not B.onboarding.shown)")
