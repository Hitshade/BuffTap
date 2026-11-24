-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.29.1",title="Dismiss means dismissed",items={
  "Right-clicking a greyed out-of-range reminder, such as a missing Blessing on a party member, now dismisses it. Before, the icon just stayed there. It only hides that notice: when they are back in range, the normal reminder still comes. Restore reminders on the Helpers page brings the notice back."}},
 {version="1.29.0",title="Two specs, two setups",items={
  "If your character has dual spec, My buffs, Weapons and Consumables can now keep a separate set of choices for each spec. Turn on Different settings per spec, then pick Spec 1 or Spec 2 to set that one up. BuffTap follows the spec you are in, in Solo, Party and Raid, and a green dot marks it. It covers which buffs to keep up, weapon imbues, oils and stones, and consumables, for every class. Timers for buffs and everything else stay shared.",
  "You do not need dual spec to prepare Spec 2. The switch is there from the start, so you can set it up before you learn dual spec. We could not test this on a character with two specs, so tell us how it goes.",
  "Solo thanks can now thank players who are not in your group. Turn on Thank players outside my group on the Helpers page. It works outdoors only, never in instances or combat, and your own party or raid members are never thanked. If it misses a stranger who buffed you while you were grouped, a report would help.",
  "Nearby gives up on a player sooner when a stronger buff is already on them. A cast that fails for that reason no longer leaves the row nagging you or trying again several times."}},
 {version="1.28.1",title="Rogues, your Tracking is back",items={
  "Since 1.28.0, a Rogue opening My buffs found only a note that the class has no buffs to remind, and the Tracking settings had no way in. My buffs now opens straight to Tracking for Rogues, and for any class with no personal buffs, without an empty buff list or Solo, Party and Raid buttons that do not apply.",
  "The Full check-up on Diagnostics has a new Talents and spec section. It only reads information and changes nothing. We are looking into settings that follow your talent spec, so a report from a character with two specs is welcome."}},
 {version="1.28.0",title="Class helpers move into My buffs",items={
  "My buffs has a new tab beside Solo, Party and Raid. It holds the settings that follow your class instead of one setup: pet, Healthstone and Soulstone for Warlocks, pet for Hunters, your assigned Oath for Paladins, and tracking reminders for everyone.",
  "The tab is named for what is inside it: Class helpers, Pet and tracking, or just Tracking. These settings apply in every setup, so Use Solo settings is hidden while you are on it.",
  "Helpers keeps a small card at the bottom where those settings used to be, with a button that takes you to the new tab. Nothing you already set up has changed.",
  "The Helpers page is roomier. Solo thanks now has a full-width card with a new picture, and Buff requests sits right below it, and the optional conveniences follow. Camping also has a redrawn camp scene. The Solo thanks picture changes with your faction."}},
 {version="1.27.1",title="Ghosts of Nearby players past",items={
  "Nearby no longer clings to players who have left. If you were sweeping your mouse around a crowded spot, the rows of people who had already walked off could linger for a moment, like a goodbye that went on too long. They now vanish when they should.",
  "Go ahead and spin your mouse like you are trying to start a campfire. Nearby lets go of a row the instant your mouse does, and the only thing left dizzy is you."}},
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
}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
