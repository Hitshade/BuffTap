-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.27.0",title="A fresh coat of paint",items={
  "The settings window has a new look. Every page shares one darker background and opens with a larger title, and section headings carry a small icon with a fine line beside them.",
  "Tidier pages: the boxes inside boxes are gone, and controls are lined up with even spacing. Weapons, Consumables, Supplies, Cleanse, My buffs, Target, Blacklist and Groups were all reworked.",
  "Supplies has roomier item rows. Weapons shows the Off hand row only for classes that can dual wield. Camping shows its benefits with new icons. Party and Raid get a small emblem and a short note under each setting.",
  "Nearby now stays open in combat by default, so inviting players and asking to join a group work whatever your class. Prefer the old behaviour? Turn off Keep open in combat under Customization > Nearby window. The How Nearby works guide starts folded away: press Show to open it.",
  "Scrollbars appear only when a list actually scrolls, and the thumb is quieter. Customization tabs are evenly spaced, and the Effect card has room to breathe."}},
 {version="1.26.15",title="Invites, even mid-fight",items={
  "Keep Nearby open in combat. Inviting players and asking to join a group still work while you fight. Turn on Keep open in combat under Customization > Nearby window. It starts off.",
  "In combat the list keeps showing players as they come and go, under a Paused: in combat banner. Buffing waits until the fight ends, then your usual buff list returns.",
  "Bitte, de nada, de rien, de nada. Newer settings and help text now read in German, Spanish, French and Brazilian Portuguese.",
  "Less busywork: BuffTap does less behind the scenes during busy raids, and short buff lists on Groups no longer show an empty scrollbar."}},
 {version="1.26.14",title="Group buffs without the reagent",items={
  "Group buffs now respect Forever effects that remove their normal vendor reagent cost. When the game allows the cast, BuffTap offers the group buff instead of unnecessarily switching to individual buffs."}},
 {version="1.26.13",title="Catch a brief chance to say thanks",items={
  "Solo Thanks now captures the buff giver as the buff arrives, helping when their details disappear from the next buff check. The usual identity checks still apply."},thanks="Thanks to waggz81 for continuing to help investigate missed thanks."},
 {version="1.26.12",title="Thanks, even on horseback",items={
  "Say thanks from the saddle. Automatic thank-you emotes and the optional whisper backup now work while mounted. Buff actions still pause while riding, and Keep thanking while resting still applies in town.",
  "Really, really don't want to miss a thank-you? Helpers > Solo Thanks has a very optional whisper backup. It starts off and only offers THANK when automatic thanks has not fired and the buff giver's full name is known. Nothing is whispered automatically.",
  "Use your regular BuffTap binding or click THANK to whisper; right-click to dismiss this thank-you. The offer lasts 15 seconds, waits behind ready buffs and follows Keep thanking while resting.",
  "Make the message your own in Solo Thanks. It starts as Thank you for %s! and combines buffs from the same giver."}},
 {version="1.26.11",title="Reminders that make room",items={
  "Reminders now sit below ordinary game windows by default. Under Customization, Buff reminder, Camping and Supplies each offer Keep above other windows. Nearby keeps its own switch.",
  "The main reminder's choice also covers queue icons, consumable icons and combat expiry warnings. Settings and popup menus stay easy to reach."},thanks="Thanks to WareWolf44 for the layering feedback."},
 {version="1.26.10",title="A quieter Warrior reminder",items={
  "Battle Shout stays out of sight when you lack rage. Its normal reminder returns when you can cast it. Mana reminders are unchanged."},thanks="Thanks to ichkruchka for the Warrior feedback."},
 {version="1.26.9",title="Useful choices, shared blacklists",items={
  "Keep one blacklist across your characters. Turn on Share across all characters under Blacklist, or choose another profile and Add entries. Existing entries are kept; sharing starts off. Newly blocked targets are skipped immediately.",
  "Less clutter, more relevant choices. Groups hides pet, role and group-spell options your class or selected buff cannot use, so you only see the controls that make sense.",
  "Nearby keeps useful browsing and invitation controls together, without casting options your class cannot use. Empty My buffs and Target pages explain where to go instead, including for Hunters and Warriors.",
  "Weapon reminders stay quiet for items you cannot use at your level, unusable carried items or unknown level requirements. Your saved choices are kept for later.",
  "Battle Shout and Trueshot Aura stay under My buffs. Their Groups page explains how they affect nearby group members automatically. Rogues get a shortcut to Weapons.",
  "Pet buffs use an approved list, with mana-only buffs reserved for mana-using pets. Utility spells no longer become pet-maintenance jobs.",
  "Role choices fit each buff: Thorns offers Tanks, and Fear Ward offers Tanks or Healers. Other buffs keep their class choices. Hidden old preferences stay saved.",
  "Use Solo settings stays available in Party and Raid outside combat. You can undo changes immediately, and Paladins can plan target blessings while Target and Nearby are off.",
  "New Warlocks and Shamans start with party utility buffing off. Existing Party and Raid choices are kept, and setup does not repeat."}},
 {version="1.26.8",title="Your next buff, at a glance",items={
  "Pick your next buff. An optional row of smaller, clickable icons shows what else is due. Turn on Show next buffs below under Customization > Buff reminder. Your usual binding stays on the main icon.",
  "Find a helping hand. Helpers > Buff requests now offers optional provider sorting for buffs you are missing. Your existing priorities come first, and every request still needs your click.",
  "An early heads-up in combat. My buffs > Combat expiry warning can remind you when a buff may be running out. It is an estimate: dispels and another player's refresh can make it inaccurate. It starts off.",
  "A little more time to say thanks. Solo Thanks waits longer for a briefly unavailable caster. If it still misses someone, capture Diagnostics > Full check-up soon afterward to help us investigate.",
  "Paladins: Kings, Might and Wisdom are welcome in town again. Nearby no longer holds them back with short buffs such as Thorns.",
  "Small icons, same style. Consumable and queue icons now follow your Classic or Modern choice, without reminder glows. Reminders also sit below more interface windows.",
  "German translations have been expanded."},thanks="Thank you to tinect for the queue, combat warnings, window improvements and German translations, and to waggz81 for helping investigate Solo Thanks."},
 {version="1.26.7",title="Choose which reminders you hear",items={
  "Give each buff a voice, or a little peace and quiet. Left-click its speaker to mute it; right-click to choose a sound. Personal, Party and Raid choices stay separate, and Use default follows your usual Reminder sound.",
  "Find personal speakers in My buffs and group speakers under Groups. Paladins can open Buff sounds beside the Party and Raid tabs. Muting a buff leaves its icon and binding available.",
  "Customization > Binding & sound now lets you switch Reminder, Supply, Camp, Cleanse and Friend sounds on or off separately. Preview lets you listen even while muted.",
  "Ten new fantasy sounds are ready to try, including Crystal chime, Elven harp and Holy light. Sound lists open at your current choice and scroll more smoothly; Reduce animation keeps scrolling immediate.",
  "Choosing alert sounds during first-time setup allows all sound categories. Optional features still have their own switches, and SmartShift returns and active buffing sequences stay quiet.",
  "Druids and Priests get a simpler cleanse choice: learned Abolish replaces Cure at the same base mana cost. Cure remains the fallback before Abolish is learned."},thanks="Thanks to jimbo1111 for pointing out the equal-cost Cure and Abolish choice."},

}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
