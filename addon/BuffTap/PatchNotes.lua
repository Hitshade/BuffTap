-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
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
 {version="1.28.0",title="Class helpers move into My buffs",items={
  "My buffs has a new tab beside Solo, Party and Raid for class helpers: Warlock pets and stones, Hunter pets, Paladin Oaths, and tracking reminders.",
  "The tab is named for its contents: Class helpers, Pet and tracking, or Tracking. These choices apply in every setup, so Use Solo settings is hidden there.",
  "Helpers now has a shortcut to the new tab. Your existing choices are kept.",
  "Helpers has roomier full-width cards for Solo thanks, Buff requests and Conveniences. Solo thanks has a faction-themed picture, and Camping has a new camp scene."}},
 {version="1.27.1",title="Ghosts of Nearby players past",items={
  "Nearby now lets go of players who have left, even after moving your mouse through a busy list. Rows no longer linger after their players have gone."}},
 {version="1.27.0",title="A fresh coat of paint",items={
  "The settings window has a new look, with a shared dark background, larger page titles, and small section icons beside fine separator lines.",
  "Tidier pages, fewer nested boxes, and more consistent spacing across Weapons, Consumables, Supplies, Cleanse, My buffs, Target, Blacklist and Groups.",
  "Supplies has roomier item rows. Weapons only shows Off hand for classes that can use it. Camping has benefit icons, and Party and Raid have a small emblem and short setting descriptions.",
  "Nearby stays open in combat by default for invitations and requests to join a group. Prefer it hidden? Turn off Keep open in combat under Customization > Nearby window. Press Show to open the folded How Nearby works guide.",
  "Scrollbars appear only when needed. Customization tabs are evenly spaced, and the Effect card has more room."}},
 {version="1.26.15",title="Invites, even mid-fight",items={
  "Keep Nearby open during combat for invitations and requests to join a group. Enable Keep open in combat under Customization > Nearby window. It starts off in this version.",
  "The list keeps showing players as they arrive and leave, with a Paused: in combat banner. Buffing resumes when the fight ends.",
  "More settings and help text now appear in German, Spanish, French and Brazilian Portuguese.",
  "Less work behind the scenes in busy raids, and no empty scrollbar on short Groups buff lists."}},
 {version="1.26.14",title="Group buffs without the reagent",items={
  "Group buffs now respect Forever effects that remove their normal vendor reagent cost. When the game allows the cast, BuffTap offers the group buff instead of unnecessarily switching to individual buffs."}},

}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
