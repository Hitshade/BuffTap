-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.25.0",title="Beta: smarter class setup, SmartShift and item choices",items={
  "This is a test build of 1.25.0. Please report anything that looks wrong or does not work as expected.",
  "Setup now keeps your ticked choices when moving between pages. Reviewing recommendations asks for confirmation and offers a profile backup before applying them. Hover a recommendation to compare the saved setting with its proposal.",
  "Druids and Shamans: turn on SmartShift under My buffs to offer your previous form after refreshing your own buffs. Returning takes another click and is always silent.",
  "Food and Elixirs: open the Category list in Choose to find items by their benefits. Your chosen items stay selected as you browse.",
  "Smarter class setup: open My buffs > Review class setup to see recommendations for your class. Opening the review changes nothing. Tick only the recommendations you want; your existing choices stay saved unless you choose to replace them.",
  "Paladins: the recommended party and raid blessing plan follows what you have learned. It prefers Kings when available, with Might for physical damage dealers and Wisdom for mana users as fallbacks. Known healer roles prefer Wisdom. You do not need to run setup again when you learn the next blessing, and your fixed manual choices still take priority.",
  "Druids can choose Thorns for tanks in party and raid. Priests can plan Fear Ward for tanks before learning it at level 20. Shaman caster and healer recommendations set your main-hand Flametongue preference; applying weapon buffs stays a separate option.",
  "Shaman setup now saves the actual main-hand preference. Rogue choices include Atrophic, Numbing, Sebacious and both ranks of Occult Poison.",
  "New character settings start with cleansing and resurrection reminders off. Existing choices are kept.",
  "Configure your class's cleansing and resurrection preferences before learning the spells, including Druid Rebirth and cleansing order. Unlearned spells cannot be offered for casting. Prefer Abolish is hidden for classes without an Abolish spell."}},
 {version="1.24.8",title="Cleansing and resurrection fixes",items={
  "Fixed: cleanse and resurrection reminders now update when you change target, or when a group member is poisoned or dies, even if Target buffs and group buffing are turned off.",
  "Cleanse and resurrection buttons now double-check the player, the debuff and your settings at the moment you click, so they cannot act on someone who changed in the meantime.",
  "Assigned Soulstones now wait for the player you chose, and player names stay hidden in shared reports. The Soulstone notice is now translated."}},
 {version="1.24.7",title="Soulstone fix and clearer status",items={
  "Soulstones set to an assigned player now wait for that person. If they are away, dead, offline or out of range, BuffTap shows a note and does not use the stone on someone else. It goes back to them as soon as they are available.",
  "Hover the Elixirs or Utility rows on the Consumables page to see which of your ticked effects are active, running low, missing or out of stock.",
  "A pet notice now shows before a weapon-coating notice, so one no longer hides the other.",
  "Fixed: the resurrection reminder could be offered for a player whose connection status the game would not confirm."}},
 {version="1.24.6",title="Fixes, and clearer reminders",items={
  "Fixed: the resurrection reminder could fail to show for a dead group member. It now appears as it should.",
  "New option on the Cleanse page: \"Cleanse before resurrection\", for classes that can do both. It is off by default, so resurrection still comes first unless you change it.",
  "Soulstone: choosing a player with \"Use current target\" now remembers that exact person, even if someone in your group has a similar name. If an older assignment stops working, choose the player again.",
  "Pet summons, Healthstones and Soulstones now come before optional food and flasks. A reminder you have to act on by hand no longer hides one you can click.",
  "Hover a food, flask or elixir row on the Consumables page to see why nothing is being offered. The food picker also tells you when a different food effect is active. BuffTap never replaces it for you.",
  "Hover the tracking choice under Helpers to see whether it is on, off or not learned yet.",
  "Battlegrounds: your chosen tracking can be reminded again when you are not in combat."}},
 {version="1.24.5",title="Fixes",items={
  "Fixed: a tracking choice other than Herbs, Minerals or Fish (such as Hunter tracking) was reset on every reload. It now stays.",
  "When you switch tracking in the minimap menu, BuffTap no longer briefly offers your old tracking before following the new one. Switches made in combat are followed once combat ends, and your choice is checked again after logging in.",
  "\"Skip when I have none\" now only covers oils, sharpening stones and Rogue poisons, as its help says. Mage scrolls and Warlock stones still remind you when you run out.",
  "Full check-up reports now also leave out your Oath of Light and Soulstone targets. Your own settings export still keeps them.",
  "Remembered players from an imported settings string are checked, so a damaged string cannot break the Groups page.",
  "Full check-up now shows the correct instance type in dungeons and raids."}},
 {version="1.24.4",title="Supplies gets its own page",items={
  "Supplies now has its own page in the sidebar, right under Consumables, with its own status light and a Customize look button. Your tracked items and settings are unchanged.",
  "A reminder that Supplies can track anything you carry: class reagents, ammo, seeds, profession materials, whatever you like. Drag an item from your bags onto the list, or add it by name, and BuffTap warns you when you run low.",
  "The Consumables light now follows only \"Enable consumable reminders\", so it no longer shows green when only supply warnings are on.",
  "The switches on the Supplies page now line up in neat columns."}},
 {version="1.24.3",title="Tracking for every class",items={
  "Tracking reminder now covers any tracking you know, not just herbs and minerals: Hunter tracking, Sense Undead and more. Pick one from the new dropdown under Helpers > Tracking, even before you learn it, and BuffTap reminds you when it is off, for example after you die. If you switch tracking in the minimap menu, BuffTap follows your new choice instead of switching you back.",
  "New \"Skip when I have none\" switch on the Weapons page: no reminder for an oil, sharpening stone or poison you have run out of, the same way buff food works.",
  "Buffs with no timer, such as Hunter aspects, Trueshot Aura and Paladin auras, no longer show a Rebuff slider that did nothing. They remind you when they are off.",
  "Fixed two lines overlapping in the Resurrection box for druids who have not learned a resurrection spell yet."},thanks="Thanks to waggz81 for the tracking idea and the Rebirth report, and a big shoutout to noci__, who has been with BuffTap since the beta, for the weapon idea."},
 {version="1.24.2",title="Fixes",items={
  "Personal consumables such as Juju Power and Crystal Force are now always used on yourself, even with someone else targeted.",
  "Paladins: a blessing exception set only for raids no longer overrides your tank and healer choices in a party, and the other way around.",
  "Remembered players can be reached and removed even when nobody of their class is in your group.",
  "Full check-up reports leave out remembered players. Your own settings export still keeps them.",
  "Blessing exceptions are no longer copied when you import settings onto a character of another class.",
  "Remember now reads a player's class directly, so it works even when the group list has not caught up yet."}},
 {version="1.24.1",title="Blessing exceptions you can keep",items={
  "Paladins: the blessing exception you set for yourself on the Groups page (for example Kings instead of Wisdom) is now saved and survives reloads and logouts.",
  "Exceptions for other players still last for the current session, unless you tick Remember on their row. Remembered players keep their blessing the next time you group, and show greyed out with a Remove button while they are away."},thanks="Thanks to Misketadam for the report."},
 {version="1.24.0",title="Special buffs",items={
  "The Utility checklist now has special buffs: Magical Awareness (Elemental Attractor or Arcane Censer), the three Zanzas, Jujus, the Blasted Lands buffs, Un'Goro crystals and the Dire Maul drinks.",
  "Magical Awareness is one buff: tick either item and BuffTap uses whichever you carry.",
  "Only one Zanza can be ticked, and any active Zanza counts.",
  "Short combat items such as Juju Flurry and Juju Escape are left out, since they are not worth keeping up.",
  "If a new item ever does not give the buff BuffTap expects, its reminder pauses and says so instead of using more.",
  "Supplies counts now update even with supply warnings off.",
  "Settings export now includes your tracked supplies and the Supplies reminder's look and position.",
  "The Supplies reminder's Pulse effect now animates in play, not just in the preview."},thanks="Thanks to Lufia_TM for the Elemental Attractor request."},
}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
