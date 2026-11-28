-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.30.3",title="Group buffs, even for one",items={
  "Group spell thresholds can now go down to one player for every class, including Greater Blessings. Choose one under Groups to prefer group spells even when only one eligible player needs the buff. Existing defaults are unchanged. Thanks to Pepperybacon for suggesting this for Legacy builds."}},
 {version="1.30.2",title="A better fit for your group",items={
  "Group buffs now count across the raid. Classes and pets that do not benefit from a buff no longer hold up a useful group cast. Your explicit exclusions and different blessing assignments still matter.",
  "Mixed-level groups use the same ten-level rank allowance as ordinary buffs. Raid-wide spells are prepared on you, so they do not depend on another player's direct casting range.",
  "Rejected or persistently incomplete group casts can temporarily offer single buffs instead. PvP protection no longer holds up buffing inside dungeons or raids. Thanks to the player whose Arcane Brilliance report prompted this review."}},
 {version="1.30.1",title="A lighter touch",items={
  "Combat cleansing reuses its existing controls when you change their look or learn new spells, keeping repeated adjustments lighter. Unchanged group frames no longer get laid out again on every update.",
  "Elixirs and Utility now explain their Everywhere or Dungeons and raids choice correctly. Combat cleansing controls are translated into German, Spanish, French and Brazilian Portuguese, with clearer click-safety guidance.",
  "Direct combat clicks use the player currently in each slot and bypass BuffTap's blacklist and PvP protection. Never cleanse exclusions are not guaranteed in combat. Check the player and debuff before clicking."}},
 {version="1.30.0",title="A helping hand, mid-fight",items={
  "Combat cleansing is here, by popular request! Open Cleanse > Combat cleansing to enable a personal warning, a party and raid grid, or both. Click the indicated L or R mouse button to cleanse. Your usual buff binding stays unchanged, and combat warnings stay silent.",
  "Make the grid your own with 18–64 px icons, spacing, growth, subgroup layout and colors. Move frames shows all 40 positions at actual size, even while solo. Only present members appear during play; layout changes wait until combat ends.",
  "The personal combat option follows your main icon and has an invisible click area throughout combat, even without a warning. Never cleanse filters cannot be guaranteed in combat, so choose whether removal is safe before clicking. Both combat options start off.",
  "Cleansing has faction artwork, tidier controls and a roomier Never cleanse list. Classes without resurrection get that space back too. Thanks to everyone who asked for combat cleansing and helped shape it.",
  "Nearby keeps its low-mana notice visible alongside the player list, without lighting your main reminder."}},
 {version="1.29.4",title="Mana waits in the right place",items={
  "Nearby saving mana no longer lights up the main reminder when your buffs are already up. The main icon still shows Waiting for mana when a needed main action cannot be cast. Nearby keeps its own pause notice."}},
 {version="1.29.3",title="Food for the road, buffs for the group",items={
  "Consumables now lets you choose Everywhere or Dungeons and raids for each category. Keep food reminders on while leveling without being asked to use your flask. Your previous location choices are preserved.",
  "Helpers > Buff requests now has an optional Party and raid switch. Party and raid members now use the request icons in the Nearby list, just like other nearby players. Click an icon to ask for buffs you are missing. Uses your existing message and buff choices; nothing is sent automatically. Groups has a shortcut too.",
  "Extra equipped bag slots are now included when checking camp items, discovering consumables and checking space for class items. Two more versions of Tender Wolf Steak and Grilled Squid are recognized."}},
 {version="1.29.2",title="A few loose ends, tied up",items={
  "Resurrection reminders now keep their spell ready when you use your binding or click. Cleansing and resurrection wait when the game cannot confirm the spell is ready.",
  "Out-of-range Nearby players no longer appear on your main reminder. With greyed reminders enabled, a missing cleanse on your group or friendly target can now show there, and returns to a normal reminder when they are in range.",
  "Thanking players outside your group waits for reliable group information, so a temporarily incomplete roster is not mistaken for a stranger.",
  "Clearer wording and more translated labels, with some cleanup behind the scenes. Your settings are kept."}},
 {version="1.29.1",title="Dismiss means dismissed",items={
  "Right-click a greyed out-of-range reminder to dismiss that notice. When the player returns to range and still needs the buff, the normal reminder returns. Helpers > Restore reminders brings the notice back sooner."}},
 {version="1.29.0",title="Two specs, two setups",items={
  "My buffs, Weapons and Consumables can now keep separate choices for each spec, for every class. Turn on Different settings per spec, then choose Spec 1 or Spec 2 to edit it. BuffTap follows your active spec in Solo, Party and Raid; the green dot shows which spec is active. Buff timers and other settings stay shared.",
  "You can prepare Spec 2 before learning dual spec. This has not yet been tested on a character with two specs, so feedback is welcome.",
  "Want to thank strangers while grouped? Enable Thank players outside my group on Helpers. It works outdoors, never in instances or combat, and skips your own party and raid members.",
  "Nearby stops retrying sooner when a cast fails because a stronger buff is already active."}},
 {version="1.28.1",title="Rogues, your Tracking is back",items={
  "Rogues can reach Tracking again. My buffs now opens straight to those controls when your class has no personal buffs, without an empty buff list or setup buttons that do not apply.",
  "Diagnostics > Full check-up now includes Talents and spec. It only reads information and changes nothing. Reports from characters with two specs are especially helpful."}},



}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
