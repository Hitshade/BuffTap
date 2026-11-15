from test_bufftap import test, tests
import test_nearby
setup=test_nearby.setup
test('favor bumps a buffer above other needers, once',setup+"""local B=BuffTap; for i=2,4 do B:TrackNearby('nameplate'..i) end; refresh()
local list=B:NearbyCandidates(); assert(#list>=2,'need two candidates')
local last=list[#list]; local g=last.guid
assert(B:FavorActive(g)==false)
B:NoteFavor(g); assert(B:FavorActive(g),'favor noted')
B.nearbyNeedCache=nil; B.nearbySnapshot=nil
local again=B:NearbyCandidates()
if #last.actions>0 then assert(again[1].guid==g or again[1].actions[1].source=='cleanse','favor first') end
-- returned: cast succeeds on them, favor clears and their reply does not count
B.nearbyResult={state='pending',guid=g,at=GetTime(),id=1}; B:SetNearbyResult('ok')
assert(B:FavorActive(g)==false,'cleared after returning')
B.favorBumped[g]=nil; B:NoteFavor(g); assert(B:FavorActive(g)==false,'reply ignored')
-- cooldown
local h='Player-other'; B:NoteFavor(h); B.favors[h]=nil; B:NoteFavor(h); assert(B:FavorActive(h)==false,'cooldown')
B.db.nearbyReturnFavor=false; B.favors[g]=GetTime(); assert(B:FavorActive(g)==false,'switch off')""")
test('a new buff from another player is noticed as a favor',setup+"""local B=BuffTap; local mine={}
local old=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(u,i,f) if u=='player' then return mine[i] end return old(u,i,f) end
B:ScanFavors(); local g=UnitGUID('nameplate1')
mine[1]={auraInstanceID=7,expirationTime=GetTime()+3600,sourceUnit='nameplate1',name='Fortitude'}
B:ScanFavors(); assert(B:FavorActive(g),'favor from new aura')
B.favors[g]=nil; B:ScanFavors(); assert(not B:FavorActive(g),'same aura not counted twice')
mine[1]={auraInstanceID=8,expirationTime=GetTime()+3600,sourceUnit='player',name='Self'}; B:ScanFavors(); assert(not B:FavorActive(UnitGUID('player')))""")
test('guild members come before other needers',setup+"""local B=BuffTap; for i=2,4 do B:TrackNearby('nameplate'..i) end; refresh()
local list=B:NearbyCandidates(true); local last=list[#list].guid
B.NearbySocialKind=function(self,unit,guid) if guid==last then return 'guild' end end
B.nearbySnapshot=nil; local again=B:NearbyCandidates(true); assert(again[1].guid==last,'guild first')""")
test('long distance errors are shortened',setup+"""local B=BuffTap; B.nearbyClickAt=GetTime()
B.nearbyResult={state='pending',guid='x',at=GetTime(),id=1}
B.db.nearbyEnabled=true
local h=B.nearbyEvents:GetScript('OnEvent'); assert(h,'event handler')
h(B.nearbyEvents,'UI_ERROR_MESSAGE',0,'You must be closer to interact with that.')
assert(B.nearbyClickError=='Out of range','got '..tostring(B.nearbyClickError))""")
