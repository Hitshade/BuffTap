-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.22.7",title="Return the favor",items={
  "New: Return the favor. When someone buffs you, they move to the top of your Nearby list (below cleanses) if they need one of your buffs, or theirs is a quarter gone. Their row shows a small gold arrow.",
  "It never loops: a buff that answers one of yours does not count, and each player moves up at most once per half hour. You still click or press your binding every time.",
  "On by default. Find the switch on the Nearby page.",
  "Friends and guild members who need a buff now come before other players in the Nearby list, and your binding buffs them first."}},
 {version="1.22.6",title="A livelier Nearby window",items={
  "The animated Nearby list is now on for everyone: rows glide down to make room and newcomers fade in. You can switch it off under Customization > Nearby window.",
  "New title-bar icons: rising z's for buffing in cities and inns, and a padlock that turns gold when the window is locked.",
  "When your mana reserve stops Nearby buffing, the window now says so: \"Paused: saving mana\". Players stay listed for invites."}},
 {version="1.22.5",title="Nearby in town, and a livelier list",items={
  "Nearby's \"Buff while resting\" now works on its own, and the new zZ button in the Nearby title bar switches it: gold buffs players in cities and inns, grey pauses there. Characters that were buffing in towns keep doing so.",
  "In the all-players view, players who just came into range now appear near the top, under those who need a buff and your friends.",
  "Optional \"Animated list\" (Customization > Nearby window): rows glide down to make room and newcomers fade in.",
  "The Resurrection switches line up with the Who switches on the Cleanse & revive page."}},
 {version="1.22.4",title="Buff while resting fixed",items={
  "Nearby \"Buff while resting\" now works when \"Pause reminders while resting\" is also on. Before, it only worked once that pause was turned off. Your own buffs still pause in cities and inns.",
  "The friend and guildmate alert now plays when their row actually appears, with a brighter, pulsing glow. It also works while you are mounted, stealthed or resting.",
  "New players now join the Nearby list even while your mouse is over it."}},
 {version="1.22.3",title="Buffs just for others",items={
  "New \"Also on me\" switch for each buff on the Groups page. Turn it off and, in a party or raid, BuffTap casts that buff on others but not on you. Perfect for Thorns on your tank. Solo, you still get it."},thanks="Thanks to Lufia_TM for the report."},
 {version="1.22.2",title="PvP realms and stealth",items={
  "Nearby now follows the same PvP rule as your group and target: flagged players are only skipped while you are unflagged. On PvP realms, Nearby works again in contested zones.",
  "The PvP protection switch is now also on the Nearby page.",
  "BuffTap holds back while you are in Stealth, Prowl or Shadowmeld, so a buff never breaks it.",
  "While Nearby is paused (stealthed, mounted or resting), its first row says so and the players below stay listed for invites."},thanks="Thanks to bruinsfan825 and user_vvl9721yymgwdslx85417 for the reports."},
 {version="1.22.1",title="Nearby dash restored",items={
  "Players with nothing to cast show the small grey dash in the Nearby window again. It was removed by mistake in 1.22.0."}},
 {version="1.22.0",title="Resurrection, and know when friends are near",items={
  "New: BuffTap offers your resurrection spell to dead group members and to a dead player you target, out of combat. Druids can also allow Rebirth. Find it on the Cleanse & revive page.",
  "New, off by default: a sound and a short highlight when a friend or guild member shows up in your Nearby list. Turn it on under Customization > Binding & sound, with separate switches for friends and guild.",
  "It plays at most once per player an hour, never in combat or instances, and stays quiet right after a loading screen. Three new sounds come with it: Happy hello, Twin bells and Playful marimba.",
  "The cleanse sound now sits with the other sounds under Customization > Binding & sound, and cleansing alerts now use Warm bell."}},
 {version="1.21.2",title="A mana reserve that works on Forever",items={
  "The Nearby mana reserve now works when the game hides your exact mana, as WoW Forever does: BuffTap judges it from which of your spells you can afford, so it stops close to your reserve. Once it is saving mana it waits until you are a little above the reserve again.",
  "Nearby cleanses respect the mana reserve too."}},
 {version="1.21.1",title="Who gets each buff, and Nearby feedback",items={
  "Each buff on the Target page has a Classes button: choose which classes can get it when they are your friendly target or a Nearby player. For example, Thorns for melee classes only.",
  "Arcane Intellect and Divine Spirit are no longer offered to Warriors and Rogues you target. Nearby already skipped them.",
  "Thorns now also goes to Rogues by default. Everything else works as before until you change it. Party and raid keep their own class choices on the Groups page.",
  "Nearby players who need a cleanse now show in the Nearby window, at the top, with the cleanse icon and a tint in the debuff's colour. Before, your binding could hold a Nearby cleanse you couldn't see.",
  "New on the Nearby page: Hold back short buffs. In cities and inns, buffs of ten minutes or less, like Thorns, are not offered to Nearby players. The page is also tidier: how and when you buff on the left, how the list looks on the right.",
  "The Nearby light in the sidebar turns red when friendly nameplates are off, because Nearby can't see anyone without them.",
  "Diagnostics has a Full check-up button (or /bt checkup) that gathers everything into one box to copy for a bug report.",
  "After you buff or cleanse a Nearby player, their row briefly shows whether it worked: green, or red with the reason, such as out of range. You can turn this off under Customization > Nearby window."}},
}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
