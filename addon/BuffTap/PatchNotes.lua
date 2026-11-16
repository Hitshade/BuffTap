-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
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
 {version="1.23.0",title="Elixirs, utility and your own supplies",items={
  "Elixirs stack on Forever, so the Elixirs row on the Consumables page is now a checklist. Click Choose and tick every elixir you want kept up.",
  "Each ticked elixir gets its own reminder, and BuffTap offers whichever one is missing or running low.",
  "Elixirs of the same line replace each other (for example Mongoose and Greater Agility), so only one of them can be ticked, and either one counts.",
  "Utility works the same way: tick Firewater, Dragonbreath Chili and Gift of Arthas together.",
  "Both rows show an icon for each ticked item. Hover one for its name and how many you carry. Choose has a Clear all button and remembers In bags only.",
  "Track any item on the Supplies page: drag it from your bags onto the list, or type its name in Add by name. Great for reagents and crafting materials. BuffTap only warns about stock.",
  "The Supplies list now scrolls, so every tracked item fits, and it shows even with supply warnings off.",
  "New Supplies reminder icon that shows what is running low. By default it only appears while resting in a city or inn; turn on Outside towns on the Supplies page to see it everywhere. Change its look and position under Customization > Supplies.",
  "The Choose window uses BuffTap's orange check boxes.",
  "Your current elixir and utility choices carry over."},thanks="Thanks to Drusangus for the suggestion."},
 {version="1.22.7",title="Return the favor",items={
  "New: Return the favor. When someone buffs you, they move to the top of your Nearby list (below cleanses) if they need one of your buffs, or theirs is a quarter gone. Their row shows a small gold arrow.",
  "It never loops: a buff that answers one of yours does not count, and each player moves up at most once per half hour. You still click or press your binding every time.",
  "On by default. Find the switch on the Nearby page.",
  "Friends and guild members who need a buff now come before other players in the Nearby list, and your binding buffs them first.",
  "A Nearby cast that fails because the player is too far away now just says \"Out of range\" instead of the game's long, cut-off message."}}
}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
