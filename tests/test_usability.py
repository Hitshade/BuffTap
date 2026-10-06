from test_blessings import test
from test_bufftap import ROOT, tests

for locale,close in [('esES','Cerrar'),('esMX','Cerrar'),('deDE','Schließen'),('frFR','Fermer'),('ptBR','Fechar')]:
    test(f'{locale}: automatic selection, localized controls and unchanged action',f'''
local oldAction=BuffTap.action
assert(BuffTap:Text('Close')=='{close}')
BuffTap:Options(); local f=BuffTap.options
assert(f.closeButton.text=='{close}' and #f.tabs==8 and BuffTap.action==oldAction)
assert(not f.languageSelector)
f.channelButton.scripts.OnClick(); assert(BuffTap.db.soundChannel=='SFX')
f.channelButton.scripts.OnClick(); assert(BuffTap.db.soundChannel=='Master')
assert(BuffTap:Enabled(BuffTap:FindBuff('motw')) and BuffTap.button.attrs.spell==5232)
''',locale=locale)

test('Unknown locale preserves English and normal buff selection',"assert(BuffTap:Text('Close')=='Close'); BuffTap:Options(); assert(BuffTap.options.tabs[5].text=='Weapons' and BuffTap.action.id==5232)",locale='itIT')
test('Missing translation and broken translated format fall back safely',"BuffTap.locale='deDE'; BuffTap.Locales.deDE={['Value %d']='Wert %q %q'}; assert(BuffTap:Text('Unknown phrase')=='Unknown phrase'); assert(BuffTap:Text('Value %d',3)=='Value 3')")

for locale in ['esES','deDE','frFR','ptBR']:
    test(f'{locale}: every translated format preserves argument types',r'''
local count=0
for key,value in pairs(BuffTap.Locales[BuffTap.locale]) do
 local original,translated={},{}
 for code in key:gmatch('%%([ds])') do original[#original+1]=code end
 for code in value:gmatch('%%([ds])') do translated[#translated+1]=code end
 assert(#original==#translated,key)
 local args={}
 for i,code in ipairs(original) do assert(translated[i]==code,key); args[i]=code=='d' and 7 or 'Tester' end
 assert(pcall(string.format,value,unpack(args)),key)
 assert(BuffTap:Text(key,unpack(args))~='',key)
 count=count+1
end
assert(count>=200)
''',locale=locale)

test('Sound choices exclude absent or restricted client constants',"SOUNDKIT={READY_CHECK=8960,RAID_WARNING={secret=true},IG_MAINMENU_OPTION_CHECKBOX_ON=856}; local list=BuffTap:SoundChoices(); assert(#list==3 and list[2].key=='ready' and list[3].key=='click')")
test('Alert settings sanitize invalid and non-finite saved values',"BuffTap.db.reminderSound='unknown'; BuffTap.db.supplySound='bad'; BuffTap.db.soundChannel='invalid'; BuffTap.db.soundInterval=0/0; BuffTap:InitDB(); assert(BuffTap.db.reminderSound=='default' and BuffTap.db.supplySound=='default' and BuffTap.db.soundChannel=='Master' and BuffTap.db.soundInterval==5)")
test('Sound preview works while disabled without consuming live cooldown',"local id,channel; PlaySound=function(i,c) id=i; channel=c; return true end; BuffTap.db.sound=false; assert(not BuffTap:PlayAlert('reminder')); assert(BuffTap:PlayAlert('reminder',true)); assert(id==12867 and channel=='Master' and not BuffTap.lastAlertSound)")
test('Reminder and supply selections route the requested sound and channel',"SOUNDKIT={READY_CHECK=8960,RAID_WARNING=8959}; local heard={}; PlaySound=function(i,c) heard[#heard+1]={i,c}; return true end; BuffTap.db.reminderSound='ready'; BuffTap.db.supplySound='raid'; BuffTap.db.soundChannel='SFX'; BuffTap:PlayAlert('reminder',true); BuffTap:PlayAlert('supply',true); assert(heard[1][1]==8960 and heard[2][1]==8959 and heard[2][2]=='SFX')")
test('Alerts share a bounded cooldown without repeating on identical actions',"local count=0; PlaySound=function() count=count+1; return true end; BuffTap.db.sound=true; BuffTap.db.suppliesSound=true; BuffTap.db.soundInterval=15; BuffTap:PlayAlert('reminder'); BuffTap:PlayAlert('supply'); assert(count==1); now=now+15; assert(BuffTap:PlayAlert('supply')); refresh(); refresh(); assert(count==2)")
test('Failed sound playback is contained and does not consume cooldown',"PlaySound=function() error('unavailable') end; assert(not BuffTap:PlayAlert('reminder',true)); BuffTap.db.sound=true; assert(not BuffTap:PlayAlert('reminder') and not BuffTap.lastAlertSound)")
test('Sound cycle preferences remain separate and unavailable choices recover',"SOUNDKIT={READY_CHECK=8960}; BuffTap:Options(); local f=BuffTap.options; f.reminderSoundButton.scripts.OnClick(); assert(BuffTap.db.reminderSound=='ready' and BuffTap.db.supplySound=='default'); SOUNDKIT=nil; BuffTap:InitDB(); assert(BuffTap.db.reminderSound=='default')")
test('Appearance preview never changes secure payload, action or bindings',"BuffTap:Options(); local action=BuffTap.action; local binding=bindings.MOUSEWHEELDOWN; local spell=BuffTap.button.attrs.spell; BuffTap:PreviewAppearance(); local p=BuffTap.appearancePreview; assert(p.shown and not p.protected and not p.attrs.type1); assert(BuffTap.action==action and BuffTap.button.attrs.spell==spell and bindings.MOUSEWHEELDOWN==binding)")
test('Appearance preview honors visibility and closes on combat or page change',"BuffTap:Options(); BuffTap.db.showBuffName=true; BuffTap.db.showTargetName=false; BuffTap.db.showTimer=true; BuffTap.db.showGroupBadge=false; BuffTap:PreviewAppearance(); local p=BuffTap.appearancePreview; assert(p.nameLabel.shown and not p.recipient.shown and p.timer.shown and not p.count.shown); p.scripts.OnEvent(p,'PLAYER_REGEN_DISABLED'); assert(not p.shown); BuffTap:PreviewAppearance(); BuffTap.options.selectTab(1); assert(not p.shown)")
test('Combat cannot create an appearance preview',"combat=true; BuffTap:PreviewAppearance(); assert(not BuffTap.appearancePreview)")
test('Reset needs confirmation, cancel and window close preserve settings',"BuffTap.db.size=90; BuffTap:Options(); local f=BuffTap.options; f.resetAllButton.scripts.OnClick(); assert(f.resetConfirm.shown and BuffTap.db.size==90); f:Hide(); assert(not f.resetConfirm.shown and BuffTap.db.size==90); BuffTap:Options(); f.resetAllButton.scripts.OnClick(); f.selectTab(1); assert(not f.resetConfirm.shown and BuffTap.db.size==90)")
test('Confirmed reset clears assignments and restores defaults',"BuffTap.db.size=90; BuffTap.blessingPlayers={test={choice='bom'}}; BuffTap:Options(); local f=BuffTap.options; f.resetAllButton.scripts.OnClick(); f.confirmResetButton.scripts.OnClick(); assert(BuffTap.db.size==64 and not BuffTap.blessingPlayers and not f.resetConfirm.shown)")
test('Confirmed reset remains blocked in combat',"BuffTap.db.size=90; BuffTap:Options(); combat=true; BuffTap.options.confirmResetButton.scripts.OnClick(); assert(BuffTap.db.size==90)")
test('Status explains real suspension states without guessing exclusion cause',"BuffTap.db.enabled=false; assert(BuffTap:FriendlyStatus()=='BuffTap is disabled.'); BuffTap.db.enabled=true; combat=true; assert(BuffTap:FriendlyStatus()=='Reminders pause during combat.'); combat=false; BuffTap.action=nil; BuffTap.reason='mounted'; assert(BuffTap:FriendlyStatus()=='Reminders pause while mounted.'); BuffTap.reason='nothing actionable'; assert(BuffTap:FriendlyStatus():find('may be covered or excluded',1,true))")
test('Client spell names are shown without modifying catalog names or IDs',"local original=C_Spell.GetSpellName; C_Spell.GetSpellName=function(id) local name=original(id); return name and 'Localized '..name end; BuffTap:Options(); assert(BuffTap.options.buffRows[1].name.text:find('Localized ',1,true),BuffTap.options.buffRows[1].name.text); assert(BuffTap:FindBuff('motw').name=='Mark of the Wild',BuffTap:FindBuff('motw').name)")

test('Localized item names are searchable without altering supported item IDs',"local family=BuffTap.ConsumableFamilies[1]; local id=family.items[1].id; bags[id]=5; items[id]={name='Localized Food',icon=134400}; BuffTap:Options(); BuffTap:ChooseConsumable(family); local f=BuffTap.itemPicker; f.search:SetText('localized food'); BuffTap:UpdateConsumablePicker(); assert(f.rows[1].itemID==id and f.rows[1].name.text=='Localized Food')",locale='deDE')
test('Translated tab text fits its allotted width using font metrics',r'''
local original=CreateFrame
CreateFrame=function(...)
 local f=original(...)
 f.Text.fontSize=12; f.GetFontString=function(self) return self.Text end
 f.Text.GetStringWidth=function(self) return #(f.text or '')*6*(self.fontSize or 12)/12 end
 f.Text.GetFont=function() return 'Fonts\\FRIZQT__.TTF',12,'' end
 f.Text.SetFont=function(self,_,size) self.fontSize=size end
 f.SetSize=function(self,w,h) self.width=w; self.height=h end
 return f
end
BuffTap:Options()
for _,tab in ipairs(BuffTap.options.tabs) do assert(tab.Text:GetStringWidth()<=tab.width-16) end
''',locale='deDE')
test('New Appearance controls and confirmation fit within the existing panel',r'''
local original=CreateFrame
CreateFrame=function(...)
 local f=original(...)
 f.SetSize=function(self,w,h) self.width=w; self.height=h end
 f.SetPoint=function(self,...) local p={...}; if p[1]=='TOPLEFT' then self.points=p end end
 return f
end
BuffTap:Options(); local f=BuffTap.options
for _,control in ipairs({f.resetConfirm,f.reminderSoundButton,f.supplySoundButton,f.channelButton,f.soundInterval}) do
 assert(-control.points[3]+control.height<=624 and control.points[2]+control.width<=724)
end
''')

print(f'ALL {len(tests)} SCENARIOS PASSED')
(ROOT/'tests/regression-usability-latest.txt').write_text('\n'.join('PASS '+name for name in tests)+f'\n\n{len(tests)} mocked Lua 5.1 scenarios passed. Client visuals, audio and native translation review pending.\n',encoding='utf-8')
