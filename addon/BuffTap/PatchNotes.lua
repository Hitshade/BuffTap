-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.26.1-beta4",title="Faster, smoother buffing",items={
  "Refreshing several class buffs feels more responsive: the next buff stays ready during the global cooldown, so you can keep pressing your usual binding instead of waiting for the reminder to come back.",
  "A cooldown sweep shows when your queued buff can cast. There is no second alert when the wait ends, and every cast still needs your input.",
  "Druids and Shamans: SmartShift prepares your return form promptly after buffing. Returning now takes priority over optional Nearby buffs, so helping a passing player does not hold up your return."},thanks="Thanks to Mechrite for suggesting smoother, more responsive buffing."},
 {version="1.26.1-beta1",title="Testing smoother buffing",items={
  "BuffTap can keep your next class buff ready while the global cooldown finishes, so repeated clicks or key presses can feel smoother.",
  "This beta needs in-game testing. Your clicks still cast each buff, and spells with their own cooldown still wait."},thanks="Thanks to Mechrite for suggesting smoother buffing."},
 {version="1.26.0",title="Manual consumables and clearer customization",items={
  "Consumables: choose Auto or Manual for Food, Flask, Elixirs and Utility. Manual shows separate clickable item icons; your normal binding and mouse wheel skip them.",
  "Labeled icons and stock counts stay centered, even with the main reminder hidden. Active effects disappear until they need refreshing; unavailable items stay dimmed.",
  "On Consumables, selected-item thumbnails sit below the labels, with Rebuff at on the right, so the icons no longer cover the selection text.",
  "Customization > Buff reminder: Detach consumables lets you position the group separately with Move reminders or Edit Mode. Switch it off to reattach. Cancel restores the move session's starting positions; Reset look & position restores defaults.",
  "Up to eight effects can be clicked here. Hover +N to see additional effects to use from your bags. Manual icons hide in combat and while you cannot safely use them.",
  "Review fixes: disabling BuffTap blocks prepared clicks immediately. SmartShift respects pauses and form cooldowns. Manual icons return on time at refresh thresholds. Appearance reset now restores all its visual choices.",
  "My buffs: the bottom panel explains default timings instead of showing another slider. Set each buff's timing in its row. Reset default timings restores timings for the selected setup without changing buff choices or priorities.",
  "Customization groups label visibility and position before text styling. Camping and Supplies have fuller layouts. Modern glow is rounded inside and square outside; timers are centered and group counts sit at the top right."},thanks="Thanks to Xprit44 for suggesting reminders without accidental mouse-wheel consumption."},
 {version="1.25.0",title="Smarter class setup, SmartShift and item choices",items={
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
}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
