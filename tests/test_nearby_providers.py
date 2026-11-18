from test_bufftap import test
from test_nearby import setup

# Optional Nearby rows for players who could buff you, in the buffs-only view.
MAGE=setup+"""
local B=BuffTap
local baseClass=UnitClass
UnitClass=function(u) if u=='nameplate1' then return 'Mage','MAGE' end return baseClass(u) end
aura('nameplate1',5232,'Mark of the Wild')
B.db.nearbyShowAll=false; B.nearbyNeedCache={}; B.nearbySnapshot=nil
local function listed() for _,e in ipairs(B:NearbyPlayers()) do if e.unit=='nameplate1' then return e end end end
"""

test('Players who can buff me are off by default and not listed',MAGE+"assert(B.db.nearbyShowProviders==false); refresh(); assert(listed()==nil)")
test('A Mage who could give me Arcane Intellect is listed with the option on',MAGE+"B.db.nearbyShowProviders=true; refresh(); local e=listed(); assert(e and e.provider and #e.actions==0,'not listed'); local found; for _,d in ipairs(e.provider) do if d.key=='ai' then found=true end end; assert(found)")
test('A provider is not listed once I already have that buff',MAGE+"B.db.nearbyShowProviders=true; aura('player',1459,'Arcane Intellect'); refresh(); assert(listed()==nil)")
test('Providers in combat, grouped or blacklisted are not listed',MAGE+"B.db.nearbyShowProviders=true; local oldCombat=UnitAffectingCombat; UnitAffectingCombat=function(u) return u=='nameplate1' or oldCombat(u) end; refresh(); assert(listed()==nil); UnitAffectingCombat=oldCombat; B.BlockReason=function(_,u) return u=='nameplate1' and 'test' or nil end; refresh(); assert(listed()==nil); B.BlockReason=nil; UnitInParty=function(u) return u=='nameplate1' end; refresh(); assert(listed()==nil)")
test('Players who can buff me do not need buff requests turned on',MAGE+"B.db.nearbyShowProviders=true; B.db.nearbyRequests=false; refresh(); assert(listed() and B:RequestableBuffs(listed())==nil)")
test('Show all view is unchanged by the provider option',MAGE+"B.db.nearbyShowProviders=true; B.db.nearbyShowAll=true; refresh(); local e=listed(); assert(e and e.provider==nil)")
test('Provider rows sort below players who need my buffs',MAGE+"B.db.nearbyShowProviders=true; C_NamePlate.GetNamePlates=function() return {{GetUnit=function() return 'nameplate1' end},{GetUnit=function() return 'nameplate2' end}} end; B:TrackNearby('nameplate2'); refresh(); local list=B:NearbyPlayers(); assert(#list==2,tostring(#list)); assert(list[1].unit=='nameplate2' and #list[1].actions>0 and list[2].provider)")
test('Provider row tooltip names the buff it could give',MAGE+"B.db.nearbyShowProviders=true; refresh(); B:UpdateNearbyWindow(); local row; for _,r in ipairs(B.nearbyFrame.rows) do if r.entry and r.entry.unit=='nameplate1' then row=r end end; assert(row,'no row'); local lines={}; GameTooltip.AddLine=function(_,t) lines[#lines+1]=t end; row.scripts.OnEnter(row); local ok; for _,t in ipairs(lines) do if tostring(t):find('Can buff you',1,true) then ok=true end end; assert(ok)")
test('Provider option checkbox saves',"local B=BuffTap; B:Options(); local c=B.options.nearbyProviders; c:SetChecked(true); c.scripts.OnClick(c); assert(B.db.nearbyShowProviders==true)")
