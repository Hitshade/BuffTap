from test_bufftap import test, tests
from test_blessings import setup

test("Retired blessings never resolve and saved fixed assignments become Skip",setup+"""
BuffTap.db.blessingClasses.WARRIOR='bol'
BuffTap.db.targetBlessingClasses.PRIEST='bos'
BuffTap.db.groupBlessingPriorities.PALADIN={'bok','bol','bow'}
BuffTap:InitDB()
assert(BuffTap.db.blessingClasses.WARRIOR=='skip')
assert(BuffTap.db.targetBlessingClasses.PRIEST=='skip')
assert(table.concat(BuffTap.db.groupBlessingPriorities.PALADIN,',')=='bok,bow')
for _,key in ipairs({'bos','gbos','bol','gbol'}) do assert(not BuffTap:FindBuff(key)) end
BuffTap:Options()
assert(not BuffTap.options.salvationRecipients)
""")
