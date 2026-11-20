from test_directed_thanks import test,solo
payload=solo+"""
local B=BuffTap
local oldExists,oldGUID,oldName=UnitExists,UnitGUID,UnitName
UnitExists=function(u) return u=='nameplate99' or oldExists(u) end
UnitGUID=function(u) if u=='nameplate99' then return 'Player-Driveby' end return oldGUID(u) end
UnitName=function(u) if u=='nameplate99' then return 'Giver','Surname' end return oldName(u) end
C_NamePlate={GetNamePlates=function() return {} end}
UnitTokenFromGUID=function() return nil end
C_UnitAuras.GetAuraCasterGUID=function() return 'Player-Driveby' end
aura('player',1459,'Arcane Intellect',600,600)
auras.player[#auras.player].auraInstanceID=88
auras.player[#auras.player].sourceUnit=nil
local added={spellId=1459,auraInstanceID=88,name='Arcane Intellect',isHelpful=true,sourceUnit='nameplate99'}
local function fire() B.events.scripts.OnEvent(nil,'UNIT_AURA','player',{isFullUpdate=false,addedAuras={added}}) end
"""
test('Payload captures live giver absent from subsequent scan through real dispatcher',payload+"fire(); assert(#emotes==1 and emotes[1][2]=='nameplate99'); fire(); assert(#emotes==1)")
test('Payload identity remains subject to delayed send validation',payload+"B.db.helperThankDelay=2; fire(); assert(#emotes==0 and #B.helperThankQueue==1); UnitGUID=function(u) return u=='nameplate99' and 'Player-Reused' or oldGUID(u) end; advance(4); assert(#emotes==0)")
for field,value in [('spellId','1243'),('auraInstanceID','99'),('isHelpful','false'),('sourceUnit',"{secret=true}")]:
 test('Payload rejects mismatched or unreadable '+field,payload+"added."+field+"="+value+"; fire(); assert(#emotes==0)")
test('Payload refuses contradictory current aura caster GUID',payload+"C_UnitAuras.GetAuraCasterGUID=function() return 'Player-Other' end; fire(); assert(#emotes==0)")
test('Payload never bypasses combat gate',payload+"combat=true; fire(); assert(#emotes==0)")
test('Payload never bypasses disabled thanks',payload+"B.db.helperThanks=false; fire(); assert(#emotes==0)")
test('Payload never bypasses ignore rule',payload+"C_FriendList={IsIgnoredByGuid=function() return true end}; fire(); assert(#emotes==0)")
test('Payload supports mounted thanks without arming a buff',payload+"mounted=true; B:Refresh(); fire(); assert(#emotes==1 and not B.action)")
test('Full secret payload remains safe',payload+"B.events.scripts.OnEvent(nil,'UNIT_AURA','player',{secret=true}); assert(#emotes==0)")
