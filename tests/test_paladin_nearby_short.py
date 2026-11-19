from test_beta3 import test,setup

PAL=setup+"local B=BuffTap; playerClass='PALADIN'; B.resolveCache={}; B.rankChoiceCache={}; B.db.buffs={}; B.db.nearbyWhileResting=true; B.db.nearbyHoldShort=true; B.db.targetClassBlessings=false; IsResting=function() return true end; "
for key,spell_id,name,unit_class in [('bok',20217,'Blessing of Kings','WARRIOR'),('bom',19740,'Blessing of Might','WARRIOR'),('bow',19742,'Blessing of Wisdom','PRIEST')]:
 test('Resting Nearby still offers '+name+' with short buffs held back',PAL+f"spell({spell_id},'{name}',1); B.db.buffs['{key}']=true; B.db.targetBuffs['{key}']=true; local old=UnitClass; UnitClass=function(u) if u=='nameplate1' then return 'Class','{unit_class}' end return old(u) end; B.nearbyNeedCache={{}}; B.nearbySnapshot=nil; refresh(); local list=B:NearbyCandidates(true); assert(list[1] and list[1].actions[1].key=='{key}','blessing missing'); assert(not B:FindBuff('{key}').short)")
