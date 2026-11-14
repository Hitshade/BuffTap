-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.21.1",title="Who gets each buff, and Nearby feedback",items={
  "Each buff on the Target page has a Classes button: choose which classes can get it when they are your friendly target or a Nearby player. For example, Thorns for melee classes only.",
  "Arcane Intellect and Divine Spirit are no longer offered to Warriors and Rogues you target. Nearby already skipped them.",
  "Thorns now also goes to Rogues by default. Everything else works as before until you change it. Party and raid keep their own class choices on the Groups page.",
  "Nearby players who need a cleanse now show in the Nearby window, at the top, with the cleanse icon and a tint in the debuff's colour. Before, your binding could hold a Nearby cleanse you couldn't see.",
  "New on the Nearby page: Hold back short buffs. In cities and inns, buffs of ten minutes or less, like Thorns, are not offered to Nearby players. The page is also tidier: how and when you buff on the left, how the list looks on the right.",
  "The Nearby light in the sidebar turns red when friendly nameplates are off, because Nearby can't see anyone without them.",
  "Diagnostics has a Full check-up button (or /bt checkup) that gathers everything into one box to copy for a bug report.",
  "After you buff or cleanse a Nearby player, their row briefly shows whether it worked: green, or red with the reason, such as out of range. You can turn this off under Customization > Nearby window."}},
 {version="1.21.0",title="Cleansing",items={
  "New Cleanse page, right after My buffs: BuffTap can offer the right spell to remove poisons, curses, diseases and magic out of combat, before buffs. It is off until you turn it on.",
  "Choose what to remove and who to help: you, your group, your target and, if you like, Nearby players. Abolish Poison and Abolish Disease are used when the effect has stacks or will last a while.",
  "Cleanse reminders have their own new sound and a border in the debuff's colour. Right-click one to never be offered that debuff again; the list is shared by all your characters.",
  "Status lights in the sidebar show at a glance which features are on, and Blacklist moved down with the settings pages.",
  "Nearby can hide its title bar until the mouse is over the window, and keep the hairline if you like (Customization > Nearby window).",
  "In the all players view, friends and guild members are listed first once nobody needs a buff.",
  "Nearby can keep working while resting, so you can still buff, invite and answer requests in cities and inns.",
  "Fixed the Nearby mana reserve not noticing when your mana dropped below it, and camp text being cut off.",
  "The Nearby guide is redrawn to look like the real window, with numbered markers for every button, the people icon, the buff and dash, and the name tags.",
  "Font menus show each font name in its own font.",
  "The Nearby key can no longer cast after combat starts, and blacklisting from the Nearby menu now blocks only that player, not everyone with the same first name.",
  "Pets only get Arcane Intellect or Divine Spirit if they use mana, and a buffed or summoned pet is noticed sooner.",
  "Party and raid timing per buff now keeps values from When gone up to 10 minutes, like solo.",
  "Smoother settings: the window scale applies when you let go of the slider, and colour and bag changes no longer rebuild the window on every tick.",
  "Plenty of smaller fixes from a full code review."},thanks="Thank you for playing and for the feedback."},
 {version="1.20.0",title="Smarter buffing, everywhere",items={
  "Party and raid buffing is now on by default, and this update turns it on once for every character. Turn it off on the Groups page if you prefer.",
  "Fixed the reminder popping up right after login or a loading screen before your buffs had loaded.",
  "Smarter default timing: short buffs remind when they wear off, hour-long buffs 5 minutes early, and food and flasks no longer remind too soon.",
  "A new Blacklist page: never offer buffs or invites to chosen players, whole guilds, or anyone on your ignore list. Right-click a name in the Nearby window to whisper, invite, ignore or blacklist.",
  "Optional Nearby key under Customization: buff nearby players with a second key, so your main key covers only you and your group.",
  "Mana reserve: stop offering buffs to players outside your group while your mana is below a level you choose, from 0 to 50%.",
  "The Nearby window marks friends with a heart and guild members with a shield, and shows PvP flags and blacklisted players next to the name, so the buff icon always stays visible.",
  "Buffs top up at ready checks, and long buffs top up a little earlier in dungeons and raids.",
  "Consumable reminders can be limited to dungeons and raids, and a right-click dismiss can last 5, 15 or 30 minutes.",
  "Optional: buff pets, and a short delay before solo thanks. Unending Breath and Water Breathing remind only while underwater, and Druids can add an Aquatic Form reminder.",
  "Export and import settings on the Profiles page, even between classes. Diagnostics can capture debug output for you to copy into a bug report.",
  "New icon effects: Shine, Ripple, Bounce and Orbit, plus an optional urgency colour and a flash-once mode.",
  "A tidier settings window: page switches and shortcuts in the same place on every page, a Move BuffTap frames button, roomier Helpers, a taller Diagnostics box and smoother patch notes scrolling. Timing sliders now show the timing each buff really gets.",
  "Any profile except the one you are using can be deleted, with a warning when other characters use it.",
  "New smooth icons for the invite and request to join buttons.",
  "Nearby window looks moved to Customization > Nearby window, with a new font, text size and outline choice from the game's fonts or any SharedMedia font. The Nearby page now shows how the window works.",
  "New Show level option on the Nearby page puts each player's level before their name, like (28) Bob Loblaw."}},
 {version="1.19.3",title="Nearby window fixes",items={
  "Interface windows such as professions and bags now open on top of the Nearby window. Turn on Keep above other windows on the Nearby page for the old behaviour.",
  "Fixed the Nearby window jumping away from where you drop it when its scale is not 100%."}},
 {version="1.19.2",title="A guided setup and smarter defaults",items={
  "A one-time setup for each character: recommended settings, class presets (like a Paladin blessing plan or Shaman caster or healer), and copying settings from another character. Reopen it with /bufftap setup.",
  "Smarter defaults for every class, so situational buffs stay off and buff requests fit your class.",
  "A Nearby guide with a preview of the window, quick invite and request choices, and full player names.",
  "BuffTap's own sounds for supplies and camp, with a separate camp sound setting.",
  "Edit Mode now also moves the Nearby window and the camp reminder."}},
 {version="1.19.1",title="BuffTap's own sounds",items={
  "BuffTap's own alert sounds: Marimba rise (the new reminder default), Glass chime, Warm bell and Harp arpeggio.",
  "The sounds are shared with other addons through SharedMedia when it is installed.",
  "Fixed see-through dropdown menus on some settings pages."}},
 {version="1.19.0",title="Roles, requests and a modern icon",items={
  "Give party and raid buffs to tanks or healers only, and give a class's tank a different blessing.",
  "Nearby can ask a passing player for a buff you are missing, and request to join a player's group.",
  "A modern square icon style, label placement, a rebuff countdown sweep and greyed out-of-range buffs.",
  "Helpers fits on one page, with Solo thanks at the top. Solo thanks can continue while resting.",
  "Nearby's invite and request buttons can sit on the left or right. The camp tray has a new look."}},
 {version="1.18.0",title="A redesigned settings window",items={
  "A redesigned settings window with clearer controls, live reminder previews and your choice of accent colour.",
  "Optionally pause consumable and weapon reminders while resting. Buff reminders continue.",
  "Adjust Nearby's scale, width, background and visible rows.",
  "Sliders show their units, and more settings text is translated."},thanks="Thanks to waggz81 for the resting pause idea."},
 {version="1.17.1",title="Preferences for each group setup",items={
  "Choose different buffs, weapon buffs and consumables for Solo, Party and Raid.",
  "Party and Raid follow unchanged Solo preferences until you customize them.",
  "Groups now keeps five-player Party and Raid preferences separately.",
  "Matching-class profile copies include these preferences."},thanks="Thanks to Xprit44 for the separate party weapon-buff idea."},
 {version="1.17.0",title="Camping and reminder appearance",items={
  "Camping has its own reminder and setup tray, separate from ordinary buffing.",
  "Keep sleeping-bag stacks and remaining time visible together.",
  "Customize reminder effects and text, with a refreshed options sidebar."}},
}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
