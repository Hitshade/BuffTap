from test_bufftap import test, tests
from test_nearby import setup

social=setup+"""
BuffTap.db.nearbyShowAll=true
invites={}
C_PartyInfo={InviteUnit=function(name) invites[#invites+1]=name end}
GetDisplayedInviteType=function() return 'INVITE' end
refresh()
"""

test('All-players view defaults off without changing ordinary nearby buffing',"assert(BuffTap.db.nearbyShowAll==false and BuffTap.db.nearbyBuffing==true and BuffTap.db.nearbyInvites==true)")
test('Buffed stranger remains in all-players view without cast payload',social+"aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); local r=BuffTap.nearbyFrame.rows[1]; assert(r.entry and not r.action and not r.attrs.type1 and r.idle.shown and r.invite.shown)")
test('Scan-only view never arms nearby buff actions',social+"BuffTap.db.nearbyBuffing=false; refresh(); assert(not BuffTap:SelectNearby()); local r=BuffTap.nearbyFrame.rows[1]; assert(r.entry and not r.action and r.invite.shown and not r.attrs.type1)")
test('All-player checkbox returns to buff-only view',social+"aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); BuffTap:SetNearbyView(false); assert(#BuffTap:NearbyPlayers()==0 and not BuffTap.nearbyFrame.rows[1].shown)")
test('Invites require deliberate click and preserve target',social+"assert(#invites==0); local r=BuffTap.nearbyFrame.rows[1]; r.invite.scripts.OnClick(); assert(#invites==1 and invites[1]=='Ally nameplate1'); assert(BuffTap.nearbyLastInvite=='INVITE: Ally nameplate1')")
test('Repeated invite clicks have bounded cooldown',social+"local e=BuffTap.nearbyFrame.rows[1].entry; assert(BuffTap:InviteNearby(e)); assert(not BuffTap:InviteNearby(e)); assert(#invites==1); advance(10.1); assert(BuffTap:InviteNearby(e)); assert(#invites==2)")
test('Changed nameplate identity cannot receive stale invite',social+"local e=BuffTap.nearbyFrame.rows[1].entry; local old=UnitGUID; UnitGUID=function(u) return u=='nameplate1' and 'Player-Recycled' or old(u) end; assert(not BuffTap:InviteNearby(e) and #invites==0)")
test('Invite uses realm-qualified name when available',social+"GetUnitName=function(u) return u=='nameplate1' and 'Ally-OtherRealm' or UnitName(u) end; assert(BuffTap:InviteNearby(BuffTap.nearbyFrame.rows[1].entry)); assert(invites[1]=='Ally-OtherRealm')")
test('Nonleader button requests the native suggestion action',social+"GetNumSubgroupMembers=function() return 2 end; UnitIsGroupLeader=function() return false end; GetDisplayedInviteType=function() return 'SUGGEST_INVITE' end; refresh(); local r=BuffTap.nearbyFrame.rows[1]; assert(r.invite.shown and r.invite.text.text=='>'); r.invite.scripts.OnClick(); assert(#invites==1 and BuffTap.nearbyLastInvite:find('SUGGEST_INVITE:',1,true))")
test('Native request-to-join action is never mislabeled as invite',social+"GetDisplayedInviteType=function() return 'REQUEST_INVITE' end; refresh(); assert(not BuffTap.nearbyFrame.rows[1].invite.shown)")
test('Full five-player party hides invites',social+"GetNumSubgroupMembers=function() return 4 end; refresh(); assert(not BuffTap.nearbyFrame.rows[1].invite.shown)")
test('Existing group members never receive invite requests',social+"UnitInParty=function(u) return u=='nameplate1' end; local e={unit='nameplate1',guid=UnitGUID('nameplate1')}; assert(not BuffTap:InviteNearby(e) and #invites==0)")
test('Invites can be disabled independently of persistent list',social+"BuffTap.db.nearbyInvites=false; refresh(); assert(BuffTap.nearbyFrame.rows[1].entry and not BuffTap.nearbyFrame.rows[1].invite.shown and BuffTap.nearbyFrame.width==264)")
test('Invite gutter is inside the clamped footprint with five fixed rows',social+"local f=BuffTap.nearbyFrame; assert(f.width==264 and f.height==134 and #f.rows==40 and not f.rows[6].shown); for i=2,50 do BuffTap:TrackNearby('nameplate'..i) end; refresh(); assert(#BuffTap:NearbyPlayers()==40 and f.scroll.shown and #f.rows==40 and not f.rows[6].shown)")
test('PvP player stays visible without becoming a buff candidate',social+"UnitIsPVP=function(u) return u=='nameplate1' end; refresh(); assert(#BuffTap:NearbyPlayers()==1 and not BuffTap.nearbyFrame.rows[1].action and not BuffTap:SelectNearby())")
test('Unreadable aura data never gains casting authority through all-player mode',social+"C_UnitAuras.GetAuraDataByIndex=function() error('restricted') end; refresh(); local r=BuffTap.nearbyFrame.rows[1]; assert(r.entry and not r.action and not r.attrs.type1)")
test('Combat prevents invites and protected window updates',social+"local e=BuffTap.nearbyFrame.rows[1].entry; combat=true; assert(not BuffTap:InviteNearby(e)); BuffTap:UpdateNearbyWindow(); assert(#invites==0)")
test('Missing invite API leaves buff rows operational',social+"C_PartyInfo={}; refresh(); local r=BuffTap.nearbyFrame.rows[1]; assert(not r.invite.shown and r.action and r.attrs.type1=='macro')")
test('Rejected invitation does not claim success',social+"C_PartyInfo.InviteUnit=function() error('restricted') end; assert(not BuffTap:InviteNearby(BuffTap.nearbyFrame.rows[1].entry)); assert(not next(BuffTap.nearbyInvited))")
test('All-player options follow shared profiles',social+"BuffTap.db.nearbyBuffing=false; BuffTap.db.nearbyInvites=false; assert(BuffTap:CreateSettingsProfile('Social copy',true)); assert(BuffTap.db.nearbyShowAll and not BuffTap.db.nearbyBuffing and not BuffTap.db.nearbyInvites); assert(BuffTap:CreateSettingsProfile('Clean',false)); assert(not BuffTap.db.nearbyShowAll and BuffTap.db.nearbyBuffing)")

group=social+"""
BuffTap.db.group=true; GetNumSubgroupMembers=function() return 1 end
local oldGUID=UnitGUID
UnitGUID=function(u) if u=='nameplate1' then return oldGUID('party1') end return oldGUID(u) end
UnitInParty=function(u) return u=='nameplate1' or u=='party1' end
BuffTap.nearbyUnits={}; BuffTap:TrackNearby('nameplate1'); BuffTap:InvalidateRoster(); refresh()
"""
test('Group member appears only while a group buff is queued',group+"local r=BuffTap.nearbyFrame.rows[1]; assert(r.entry and r.action and r.action.nearbyGroup and not r.invite.shown); aura('party1',5232,'Mark of the Wild'); aura('party1',467,'Thorns'); refresh(); assert(#BuffTap:NearbyPlayers()==0 and not r.shown)")
test('Group row uses roster target instead of stranger settings',group+"BuffTap.db.targetBuffs.motw=false; refresh(); local r=BuffTap.nearbyFrame.rows[1]; assert(r.action.key=='motw' and r.attrs.type1=='spell' and r.attrs.unit=='party1'); r.scripts.PreClick(r,'LeftButton',true); assert(r.attrs.spell==5232)")
test('Group row refuses stale missing-buff action',group+"local r=BuffTap.nearbyFrame.rows[1]; aura('party1',5232,'Mark of the Wild'); r.scripts.PreClick(r,'LeftButton',true); assert(not r.attrs.type1)")
test('Group member hidden in scan-only mode',group+"BuffTap.db.nearbyBuffing=false; refresh(); assert(#BuffTap:NearbyPlayers()==0)")
for cls in ['WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID']:
 test('Nearby tab builds controls for '+cls,social+"playerClass='"+cls+"'; BuffTap:Options(); local f=BuffTap.options; assert(f.nearbyEnable and f.nearbyAll and f.nearbyBuffing and f.nearbyInvites); BuffTap.db.targetClassBlessings=false; BuffTap:Options(); assert(not f.targetBlessingPicks[1].shown)")


from pathlib import Path
record=(Path(__file__).resolve().parent/'nearby_preview_record.lua').read_text(encoding='utf-8-sig')
test('Nearby header and player fills share width with invite gutter on the left',record+social+"local f=BuffTap.nearbyFrame; assert(f.content.__draw.w==240 and f.header.__draw.w==240 and f.rows[1].__draw.w==240); assert(f.content.__draw.points[1][2]==24 and f.width==264); local p=f.rows[1].invite.__draw.points[1]; assert(p[1]=='RIGHT' and p[3]=='LEFT' and p[4]==-4); assert(f.content.__draw.points[1][2]+p[4]-f.rows[1].invite.__draw.w==0); assert(f.rows[5].__draw.points[1][3]==-109 and f.rows[5].height==20)")
test('Buff-only view retains the same fixed gutter and footprint',record+setup+"local f=BuffTap.nearbyFrame; assert(f.width==264 and f.content.__draw.points[1][2]==24 and f.rows[1].width==240)")
test('Nearby options occupy their own main tab',social+"BuffTap:Options(); local f=BuffTap.options; assert(#f.pages==14 and f.tabs[4].text=='Nearby' and f.nearbyEnable:GetParent()==f.pages[4] and f.friendlyTarget:GetParent()==f.pages[3]); f.selectTab(4); assert(f.pages[4].shown and not f.pages[3].shown)")
test('Paladin unrestricted target list regains room for at least three rows',record+social+"playerClass='PALADIN'; BuffTap.db.targetClassBlessings=false; BuffTap:Options(); local f=BuffTap.options; local top=-f.targetScroll.__draw.points[1][3]; assert(top==342 and 728-54-top>=3*52); assert(f.targetBlessingPanel.__draw.points[1][3]==-168) -- 1.19: Target content starts under the header like other pages")


test('People toggle leaves size and saved position unchanged',social+"local f=BuffTap.nearbyFrame; local w,h=f.width,f.height; local x,y=BuffTap.db.nearbyX,BuffTap.db.nearbyY; f.allPlayers.scripts.OnClick(); assert(not BuffTap.db.nearbyShowAll and f.width==w and f.height==h); f.allPlayers.scripts.OnClick(); assert(BuffTap.db.nearbyShowAll and f.width==w and f.height==h and BuffTap.db.nearbyX==x and BuffTap.db.nearbyY==y)")
test('Header people control is icon-only and matches compact controls',social+"local f=BuffTap.nearbyFrame; assert(f.allPlayers.width==14 and f.allPlayers.height==16 and #f.allPlayers.parts==1 and not rawget(f.allPlayers.Text,'text'))")
test('Count shows buff candidates against all detected players in either view',social+"BuffTap:TrackNearby('nameplate2'); aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); local f=BuffTap.nearbyFrame; assert(f.count.text=='1/2'); BuffTap:SetNearbyView(false); assert(f.count.text=='1/2' and #BuffTap:NearbyPlayers()==1)")
test('Candidates precede fully buffed strangers in stable arrival order',social+"for i=2,4 do BuffTap:TrackNearby('nameplate'..i) end; aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); aura('nameplate3',5232,'Mark of the Wild'); aura('nameplate3',467,'Thorns'); refresh(); local f=BuffTap.nearbyFrame; assert(f.rows[1].entry.unit=='nameplate2' and f.rows[2].entry.unit=='nameplate4' and f.rows[3].entry.unit=='nameplate1' and f.rows[4].entry.unit=='nameplate3')")
test('Completed candidate moves below remaining buff candidates',social+"BuffTap:TrackNearby('nameplate2'); refresh(); aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); assert(BuffTap.nearbyFrame.rows[1].entry.unit=='nameplate2' and BuffTap.nearbyFrame.rows[2].entry.unit=='nameplate1')")
test('Hovered row does not jump during buff-first sorting',social+"BuffTap:TrackNearby('nameplate2'); refresh(); local f=BuffTap.nearbyFrame; f.rows[1].scripts.OnEnter(f.rows[1]); aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); refresh(); assert(f.rows[1].entry.unit=='nameplate1' and not f.rows[1].action); f.rows[1].scripts.OnLeave(f.rows[1]); advance(.2); assert(f.rows[1].entry.unit=='nameplate2')")
test('Invite is available for buff candidates without showing all players',social+"BuffTap:SetNearbyView(false); local r=BuffTap.nearbyFrame.rows[1]; assert(r.invite.shown); r.invite.scripts.OnClick(); assert(#invites==1)")
test('Group rows remain clickable in buff-only view',group+"BuffTap:SetNearbyView(false); local r=BuffTap.nearbyFrame.rows[1]; assert(r.action and r.action.nearbyGroup); r.scripts.PreClick(r,'LeftButton',true); assert(r.attrs.spell==5232 and r.attrs.unit=='party1')")


test('Nearby invite plus is a centred smooth icon independent of font metrics',"local create=CreateFrame; CreateFrame=function(...) local f=create(...); local texture=f.CreateTexture; f.CreateTexture=function(self,...) local t=texture(self,...); t.SetPoint=function(self,...) self.point={...} end; t.SetSize=function(self,w,h) self.w=w; self.h=h end; t.SetTexture=function(self,v) self.file=v end; return t end; return f end; "+social+"local r=BuffTap.nearbyFrame.rows[1]; local p=r.invite.plus; assert(p.point[1]=='CENTER' and p.point[2]==r.invite and p.point[4]==0 and p.point[5]==0 and p.w==16 and p.h==16 and p.file:find('UIInvitePlus') and p.shown and not r.invite.arrow.shown and not r.invite.text.shown)")
