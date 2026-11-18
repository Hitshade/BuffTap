-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.26.7-beta3",title="Choose which reminders you hear",items={
  "Five new brief sounds: Soft pluck, Amber chime, Gentle ripple, Wooden bloom and Silver notes. Preview them under Customization > Binding & sound. Their volume is matched to BuffTap's existing sounds.",
  "My buffs now has a speaker button beside each buff. Mute Aquatic Form, for example, while keeping Mark and Thorns audible. Your reminder icon and binding keep working.",
  "Party and Raid have separate speaker buttons at the top right of each buff box. Enabled speakers use your accent colour. Paladins can open Buff sounds beside the Party and Raid tabs.",
  "Customization > Binding & sound now has a speaker button for each sound category. Reminder, Supply, Camp, Cleanse and Friend sounds can be enabled separately. Preview still plays when a category is muted.",
  "Hover a speaker or muted reminder to see what is silent. All enabled reminders use the existing default sound for their category. SmartShift and active buffing queues stay quiet.",
  "New players who choose alert sounds in setup enable all sound categories. This does not turn on optional reminder features.",
  "Druids and Priests now use Abolish Poison or Abolish Disease when learned, falling back to Cure beforehand. The unnecessary conditional Abolish switch has been removed."},thanks="Thanks to jimbo1111 for pointing out the equal-cost Cure and Abolish choice."},
 {version="1.26.6",title="Quieter pauses and tidier reminders",items={
  "Camping now respects temporary pause, the Helpers city/inn pause, stealth and Edit Mode. Its automatic sounds follow its own sound switch without bypassing pauses.",
  "Manual consumable icons and their heading hide during applicable pauses and outside your chosen dungeon/raid scope. They return when reminders resume, without changing your selections.",
  "New starter positions leave room for both rows of attached consumables. On short game UIs, Supplies sits below Nearby. Saved positions stay where you put them.",
  "Reset look & position now uses the same starting layout for each reminder. Resetting one reminder does not move the others.",
  "Resource-wait status text now says power rather than mana for Warriors and Rogues.",
  "Settings have tighter Consumables spacing, clearer selection and pause labels, wider Nearby text choices and separate labels for saved and active accent colours."}},
 {version="1.26.5",title="Quicker setup and clearer reminders",items={
  "New players can choose Get started once, Customize first, or Keep current settings. Nearby is included in the recommended setup without requiring a tour.",
  "Recommended setup enables reminder sounds, a resting pause, stronger-buff error protection and class-appropriate Cleanse and Resurrection. Solo thanks remains your choice; SmartShift and class helpers stay in Settings.",
  "Friendly names-only setup is a separate choice when supported. Otherwise, setup explains how to enable friendly nameplates. It never changes game settings automatically.",
  "New characters start with a tidy upper-right stack of reminders and Nearby beside it. Existing positions stay where you put them.",
  "Edit Mode now lets you place Camping, Supplies and Nearby while those features are off. Moving them does not turn them on.",
  "Fixed a higher-rank Nearby buff being offered but cancelled when using the main buff button or binding.",
  "Grey mana and power waits follow your visible-label choices. Hide both labels for just the icon. The Helpers resting pause hides these reminders in cities and inns. Automatic sounds stay quiet if resting information is briefly unavailable."},thanks="Thanks to sevaniuz for the power-wait display feedback."},
 {version="1.26.4",title="Buff-grades, shield charges and smarter setup",items={
  "Nearby > Offer higher rank buffs can offer a buff-grade when someone has a known lower rank and can receive your upgrade. This option starts off.",
  "Ordinary ranked Mage, Priest, Druid and Paladin buffs can offer a stronger appropriate rank to lower-level players.",
  "Shamans: My buffs > Refresh at charges can remind for Lightning Shield or Water Shield at one or two charges remaining. It starts off.",
  "Fresh setup recommends class-appropriate Cleanse, Resurrection, cleanse-first ordering and SmartShift. Supplies guidance helps you choose ammo, Soul Shards and reagents to track.",
  "Diagnostics > Inspect buffs explains which reminders recognize your active buffs. Full check-up includes it. Select text or use Select all, then Ctrl+C to copy.",
  "Group buffs respect Also on me and use single buffs when an affected member's buff information cannot be verified. Nearby buttons clear prepared casts when combat starts.",
  "Warlocks with Demonic Pact can be reminded to summon their chosen different demon while protecting the sacrificed family."}},
 {version="1.26.3",title="Resurrection, cleansing and food fixes",items={
  "Druids: Resurrection now includes Revive at every rank. You can leave Also use Rebirth off and still resurrect with Revive.",
  "Helpers > Tracking: Druids can choose Track Humanoids and Warlocks can choose Sense Demons before learning them. Actual use still needs the spell, and Druid tracking needs Cat Form.",
  "Resurrection reminders check again when a dead group member returns into range. SmartShift can now offer your previous form after a successful cleanse.",
  "Nearby: a slightly clearer cooldown sweep moves left to right over successful confirmations and follows the cooldown without extra waiting time. Repeated presses wait for the real cooldown; every cast still needs a new press.",
  "Nearby no longer labels a cast failed from an unrelated game error alone. Matching successful casts clear provisional failure messages.",
  "Added 15 missing foods, including Goblin Deviled Clams, Clamlette Surprise and seasonal treats. Find them under Consumables > Food > Choose."},thanks="Thanks to shaunpearsondev for reporting the missing Goblin Deviled Clams."},
 {version="1.26.2",title="Smooth buffing reminder fix",items={
  "Fixed an edge case introduced with smooth buffing that let repeated reminder sounds slip through while moving between class buffs or briefly waiting for buff updates.",
  "New reminders after a pause can still alert you. Cleansing and resurrection keep their normal sounds."}},
 {version="1.26.1",title="Faster, smoother buffing",items={
  "Buffing several spells in a row is faster and smoother. Your next class buff stays ready during the global cooldown, so keep pressing your usual binding.",
  "A cooldown sweep shows when your queued buff can cast. There is no second alert when the wait ends, and every cast still needs your input.",
  "SmartShift offers your previous form after class buffs, ahead of optional reminders. It also responds more reliably to rapid buffing and recovering mana.",
  "Low on mana? The main reminder stays dimmed with a waiting message, even with Nearby closed. Normal reminders resume when you have enough.",
  "A brief safeguard after a successful self buff reduces repeat casts while the game updates your buffs. Other buffs can still follow normally."},thanks="Thanks to Mechrite for the responsiveness suggestion and jimbo1111 for the repeated Thorns report."},
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

}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
