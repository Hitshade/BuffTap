from test_bufftap import test, tests
from test_nearby import setup
from test_cleanse import S

N0=setup+S+("local B=BuffTap; B.db.cleanseNearby=true; B.db.sound=true; "
 "played=nil; PlaySoundFile=function(f) played=f; return true end; PlaySound=function(k) played=k; return true end; ")
N=N0+"aura('nameplate1',5232,'Mark of the Wild'); aura('nameplate1',467,'Thorns'); "

test('A Nearby cleanse shows in the Nearby window with its spell icon',N+"debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh(); local r=B.nearbyFrame.rows[1]; assert(r.shown and r.action and r.action.source=='cleanse' and r.action.id==2782); assert(r.icons[1].shown and r.icons[1].texture==r.action.icon); assert(r.attrs.type1=='macro' and r.attrs.macrotext:find('Remove Curse',1,true))")
test('Nearby cleanses are silent and keep the main icon hidden',N+"debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh(); assert(B.action and B.action.source=='cleanse' and B.action.nearby); assert(B.nearbyQuietAction==true and played==nil)")
test('The keybind cleanse is marked on its Nearby row',N+"debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh(); assert(B.nearbyFrame.rows[1].marker.shown)")
test('The cleanse icon edge uses the debuff colour',N+"local e=B.nearbyFrame.rows[1].iconEdges[1]; local col; e.SetColorTexture=function(_,r,g,b) col={r,g,b} end; debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh(); local c=B.CleanseColors.Curse; assert(col and col[1]==c[1] and col[2]==c[2] and col[3]==c[3])")
test("A cleanse comes before that player's buffs",N0+"debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh(); local acts=B.nearbyFrame.rows[1].entry.actions; assert(acts[1].source=='cleanse' and acts[2] and acts[2].source~='cleanse')")
test('Nearby cleanse stays off unless turned on',N+"B.db.cleanseNearby=false; debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh(); assert(not (B.action and B.action.source=='cleanse')); assert(#B:NearbyCandidates(true)==0)")
test('Row click cleanses and refuses a cleansed debuff',N+"debuff('nameplate1',8552,'Curse of Weakness','Curse',60); refresh(); local r=B.nearbyFrame.rows[1]; assert(B:ValidateNearby(r.action)); debuffs.nameplate1={}; B:InvalidateAura('nameplate1'); assert(not B:ValidateNearby(r.action))")
