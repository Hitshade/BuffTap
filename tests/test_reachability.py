from test_bufftap import test

# Reachability across all nine classes. A moved control or a class-specific page can leave a setting with no way in
# (1.28.0 hid Tracking from Rogues). Each class is its own test because the mock cannot rebuild the window for another class.
CLASSES=['WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID']
# Explicit not-applicable lists: anything missing from the page is a decision recorded here, not a silent gap.
NO_TARGET_BUFFS={'WARRIOR','HUNTER','ROGUE'}      # no friendly-target buffs: the Target page shows its explanatory card
NO_PERSONAL_BUFFS={'ROGUE'}                         # no aura buffs: My buffs is the compact Tracking page

CODE="""
local cls='@@'
playerClass=cls; BuffTap:InitDB(); BuffTap:Options(); local f=BuffTap.options; local hp=BuffTap.helperWindow
local g=BuffTap.contextControls
-- 1. Every supported catalog buff for the class has a My buffs row (a group spell shares the row of its single).
local rows={}; for _,r in ipairs(f.buffRows or {}) do if r.def then rows[r.def.key]=true end end
for _,b in ipairs(BuffTap:ClassList()) do
  if BuffTap:Supported(b) then
    assert(rows[b.key] or (b.groupKey and rows[b.groupKey]) or (b.singleKey and rows[b.singleKey]),cls..' buff has no My buffs row: '..b.key)
    -- 2. And every one of those rows can follow the spec (the switch row exists for the class).
    assert(BuffTap:SpecRoutes('buffs','buffs',b.key),cls..' buff cannot follow the spec: '..b.key)
  end
end
-- 3. My buffs is never replaced by the empty card; Tracking is reachable (compact page, or the Class helpers tab).
assert(f.pages[1].classEmpty.shown~=true and f.pages[1].classHidden==nil,cls..' My buffs replaced')
assert(hp.helperSections.tracking:GetParent()==f.helpersPane,cls..' tracking controls not on the My buffs pane')
if BuffTap:MyBuffsCompact() then assert(BuffTap.buffsHelpersView==true,cls..' compact page must open on Tracking')
else assert(g.buffs.helpers.shown,cls..' has no Class helpers / Tracking tab') end
assert((BuffTap:MyBuffsCompact()==true)==(@@NOPERSONAL@@),cls..' compact page expectation')
-- 4. Target page: applicable unless the class is on the explicit list.
assert((f.pages[3].classEmpty.shown==true)==(@@NOTARGET@@),cls..' Target page expectation')
-- 5. Nearby always has its basic controls.
assert(f.nearbyAll and f.nearbyFullNames and f.nearbyInvites,cls..' Nearby controls')
-- 6. Dual spec switch on Weapons and Consumables for every class, and on My buffs unless it is the compact page.
assert(g.weapons.specCheck and g.weapons.specCheck.shown,cls..' no spec switch on Weapons')
assert(g.consumables.specCheck and g.consumables.specCheck.shown,cls..' no spec switch on Consumables')
assert((g.buffs.specCheck and g.buffs.specCheck.shown==true)==(not BuffTap:MyBuffsCompact()),cls..' spec switch on My buffs')
-- 7. Weapons: every class imbue is in its hand menu, and oils/stones can be chosen by every class.
assert(f.coatingPickers.main and f.coatingPickers.main.menu,cls..' no coating picker')
local menuKeys={}; for _,row in ipairs(f.weaponPickers.main.menu.rows) do if row.choice then menuKeys[row.choice]=true end end
for _,choice in ipairs(BuffTap.WeaponChoices) do if choice.class==cls then assert(menuKeys[choice.key],cls..' imbue missing from the menu: '..tostring(choice.key)) end end
-- 8. Consumables: one row for every visible family.
local want=0; for _,family in ipairs(BuffTap.ConsumableFamilies or {}) do if not family.hidden then want=want+1 end end
assert(#f.consumableRows==want and want>0,cls..' consumable rows '..#f.consumableRows..' of '..want)
"""
for c in CLASSES:
    test('Reachability '+c,CODE.replace('@@NOPERSONAL@@',str(c in NO_PERSONAL_BUFFS).lower()).replace('@@NOTARGET@@',str(c in NO_TARGET_BUFFS).lower()).replace('@@',c))
