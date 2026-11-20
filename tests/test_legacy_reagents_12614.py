from test_bufftap import test

GROUP = r'''
local B=BuffTap
spell(21849,'Gift of the Wild',50)
UnitLevel=function() return 60 end
B.db.group=true
bags[17021]=0
local normalUsable=C_Spell.IsSpellUsable
'''

test('Reagent Economy style usable group spell ignores empty static reagent stock', GROUP+r'''
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return true,false end
  return normalUsable(id)
end
refresh()
assert(B.action and B.action.id==21849 and B.action.groupCast)
local offered=B.action
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(B.action==offered and B.action.groupCast and B.button.attrs.type1=='spell')
''')

test('Normal zero-reagent group spell still falls back to single target', GROUP+r'''
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return false,false end
  return normalUsable(id)
end
refresh()
assert(B.action and B.action.id==5232 and not B.action.groupCast)
''')

test('Mana failure takes precedence over reagent diagnosis', GROUP+r'''
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return false,true end
  return normalUsable(id)
end
local action={
  id=21849,key='gotw',target='player',targetGUID=UnitGUID('player'),
  known=true,secureType='spell',source='spell',groupCast=true,icon=12345
}
local ok,why=B:Validate(action)
assert(not ok and why=='not enough mana' and B.manaBlocked)
''')

test('Readable zero reagent explains an explicit non-power refusal', GROUP+r'''
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return false,false end
  return normalUsable(id)
end
local action={
  id=21849,key='gotw',target='player',targetGUID=UnitGUID('player'),
  known=true,secureType='spell',source='spell',groupCast=true,icon=12345
}
local ok,why=B:Validate(action)
assert(not ok and why=='group reagent unavailable')
''')

test('Unreadable reagent stock cannot block an explicitly usable group spell', GROUP+r'''
local normalCount=C_Item.GetItemCount
C_Item.GetItemCount=function(id,...)
  if id==17021 then return {secret=true} end
  return normalCount(id,...)
end
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return true,false end
  return normalUsable(id)
end
refresh()
assert(B.action and B.action.id==21849 and B.action.groupCast)
''')

test('Unknown group spell usability fails closed even with Reagent Economy spell known', GROUP+r'''
IsPlayerSpell=function(id) return id==1225503 end
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return nil,nil end
  return normalUsable(id)
end
refresh()
assert(not (B.action and B.action.id==21849 and B.action.groupCast))
''')

test('Known Reagent Economy spell never overrides an explicit client refusal', GROUP+r'''
IsPlayerSpell=function(id) return id==1225503 end
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return false,false end
  return normalUsable(id)
end
refresh()
assert(B.action and B.action.id==5232 and not B.action.groupCast)
''')

test('PreClick revokes a waived group cast if live usability changes before input', GROUP+r'''
local usable=true
C_Spell.IsSpellUsable=function(id)
  if id==21849 then return usable,false end
  return normalUsable(id)
end
refresh()
assert(B.action and B.action.id==21849 and B.action.groupCast)
usable=false
B.button.scripts.PreClick(nil,'LeftButton',true)
assert(not B.action and not B.button.attrs.type1)
''')

test('Permanence style extended class aura follows live duration and expiration', r'''
local B=BuffTap
B.db.buffs.thorns=false
aura('player',5232,'Mark of the Wild',400,3600)
refresh()
assert(not B.action)
auras.player[1].expirationTime=GetTime()+250
B:InvalidateAura('player')
refresh()
assert(B.action and B.action.id==5232)
''')

test('Gourmand style extended food aura follows live expiration', r'''
local B=BuffTap
stock(6888,1248377)
consumables('food')
aura('player',1248406,'Well Fed',600,3600)
refresh()
assert(not B.action)
auras.player[1].expirationTime=GetTime()+1
B:InvalidateAura('player')
refresh()
assert(B.action and B.action.itemID==6888)
''')
