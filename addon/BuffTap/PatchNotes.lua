-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.26.10-beta1",title="A quieter Warrior reminder",items={
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
 {version="1.26.6",title="Quieter pauses, tidier reminders",items={
  "Camping takes a proper break during temporary pauses, the city/inn pause, stealth and Edit Mode. Its alerts follow its own sound switch.",
  "Manual consumable icons tuck away during their pauses and outside your chosen dungeon or raid setting. They return when reminders resume.",
  "New starter positions leave more room for consumables, including on shorter screens. Your existing positions stay put. Reset look & position restores one reminder without moving the others.",
  "Warriors and Rogues now see power in waiting messages. Settings also have clearer labels and roomier Nearby text choices."}},
 {version="1.26.5",title="A quicker welcome to BuffTap",items={
  "First-time setup is shorter: choose Get started, Customize first or Keep current settings. The recommended setup includes Nearby, without a required tour.",
  "Recommended setup includes sounds, the resting pause, stronger-buff protection and class-appropriate Cleanse and Resurrection. Solo Thanks is your choice; SmartShift and class helpers remain available in Settings.",
  "Nearby setup explains friendly nameplates and offers a separate names-only choice when supported. Game settings change only when you choose to change them.",
  "New characters get a tidier starting layout. Edit Mode lets you place Camping, Supplies and Nearby even while they are off; existing positions stay put.",
  "Higher-rank Nearby buffs now work through the main binding. Grey mana and power waits follow your label choices, including icon-only, and hide with the city/inn pause. Automatic sounds stay quiet if resting information is briefly unavailable."},thanks="Thanks to sevaniuz for the power-wait display feedback."},
 {version="1.26.4",title="Give nearby players a buff-grade",items={
  "Nearby > Offer higher rank buffs can suggest an upgrade when someone has a known weaker buff and can receive a stronger rank. It starts off. Mage, Priest, Druid and Paladin rank choices also work better for lower-level recipients.",
  "Shamans can get a shield reminder with one or two charges left. Choose My buffs > Refresh at charges for Lightning Shield or Water Shield; it starts off.",
  "Fresh setup recommends class-appropriate Cleanse, Resurrection, cleanse-first ordering and SmartShift. Supplies guidance helps you choose ammo, Soul Shards and reagents to track.",
  "Curious about a buff? Diagnostics > Inspect buffs shows which reminders recognize it. Full check-up includes the same details; select the text and press Ctrl+C to share it.",
  "Group buffs respect Also on me and use single buffs when a member's buff information is unclear. Nearby buttons also clear prepared casts when combat starts.",
  "Warlocks using Demonic Pact can be reminded to summon a chosen different demon while protecting the sacrificed family."}},
 {version="1.26.3",title="Better recovery, more food choices",items={
  "Druids can resurrect with every rank of Revive while leaving Also use Rebirth off. Resurrection reminders check again when a fallen group member comes back into range.",
  "Plan tracking ahead of time. Druids can choose Track Humanoids and Warlocks can choose Sense Demons before learning them. Using them still needs the spell, and Druid tracking needs Cat Form.",
  "SmartShift can offer your previous form after a successful cleanse.",
  "Nearby confirmations have a clearer left-to-right cooldown sweep. Repeated presses follow the real cooldown, and unrelated game errors no longer make a successful cast look failed. Every cast still needs your input.",
  "Fifteen more foods are on the menu, including Goblin Deviled Clams, Clamlette Surprise and seasonal treats. Find them under Consumables > Food > Choose."},thanks="Thanks to shaunpearsondev for reporting the missing Goblin Deviled Clams."},
 {version="1.26.2",title="Keep smooth buffing quiet",items={
  "Fixed a smooth-buffing edge case that let repeat reminder sounds slip through between buffs or while waiting for a buff to appear.",
  "Fresh reminders after a pause can still alert you. Cleansing and resurrection keep their usual sounds."}},
 {version="1.26.1",title="Faster, smoother buffing",items={
  "Keep the buffs flowing. Your next class buff stays ready during the global cooldown, so you can keep pressing your usual binding. A cooldown sweep shows the wait, without another alert when it ends.",
  "SmartShift offers your previous form after class buffs, ahead of optional reminders. It also handles rapid buffing and mana recovery more reliably.",
  "The main icon now stays dimmed with a waiting message when mana is low, even with Nearby closed. Reminders resume when you have enough.",
  "Rapid presses are less likely to repeat a successful self buff while the game catches up. Other buffs can follow normally, and every cast still needs your input."},thanks="Thanks to Mechrite for the responsiveness suggestion and jimbo1111 for the repeated Thorns report."},

}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
