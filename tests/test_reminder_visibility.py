from test_profiles import test

probe="""
local b=BuffTap.button
b.SetAlpha=function(s,v) s.testAlpha=v end
b.EnableMouse=function(s,v) s.testMouse=v end
"""
test('Reminder visible by default',probe+"assert(BuffTap.db.showReminder); BuffTap.appearance=nil; refresh(); assert(b.testAlpha==1 and b.testMouse and b.shown)")
test('Hidden reminder retains binding and click validation',probe+"BuffTap.db.showReminder=false; refresh(); assert(b.testAlpha==0 and not b.testMouse and b.shown and bindings.MOUSEWHEELDOWN); b.scripts.PreClick(b,'LeftButton',true); assert(b.attrs.spell==5232); aura('player',5232,'Mark of the Wild'); refresh(); assert(BuffTap.action.id==467 and b.testAlpha==0); aura('player',467,'Thorns'); refresh(); assert(not next(bindings) and not BuffTap.action)")
test('Hidden reminder combat safety',probe+"BuffTap.db.showReminder=false; refresh(); combat=true; safety('blocked'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED'); assert(not next(bindings) and not b.attrs.type1); combat=false; safety('ready'); BuffTap.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED'); assert(bindings.MOUSEWHEELDOWN and b.testAlpha==0 and not b.testMouse)")
test('Visibility restores opacity and mouse interaction',probe+"BuffTap.db.opacity=.65; BuffTap.db.showReminder=false; refresh(); BuffTap.db.showReminder=true; refresh(); assert(b.testAlpha==.65 and b.testMouse)")
test('Visibility is shared profile preference',"BuffTap.db.showReminder=false; local original=BuffTap.profileDB:GetCurrentProfile(); assert(BuffTap:CreateSettingsProfile('Hidden clone',true)); assert(not BuffTap.db.showReminder); assert(BuffTap:CreateSettingsProfile('Visible defaults',false)); assert(BuffTap.db.showReminder); assert(BuffTap:SelectSettingsProfile(original)); assert(not BuffTap.db.showReminder)")
test('Visibility option and reset look',"BuffTap:Options(); local f=BuffTap.options; assert(f.showReminderCheck); f.showReminderCheck.GetChecked=function() return false end; f.showReminderCheck.scripts.OnClick(f.showReminderCheck); advance(.1); assert(not BuffTap.db.showReminder and bindings.MOUSEWHEELDOWN); f.resetLookButton.scripts.OnClick(); advance(.1); assert(BuffTap.db.showReminder)")
test('Preview remains available while hidden',"BuffTap.db.showReminder=false; refresh(); BuffTap:PreviewAppearance(); assert(BuffTap.appearancePreview.shown and bindings.MOUSEWHEELDOWN)")
