-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
 {version="1.26.4-beta6",title="Clearer controls and setup choices",items={
  "Nearby controls close the gap when your class has no higher-rank buffs to offer. Return the favor sits directly below the other list switches. Mana reserve stays at the bottom.",
  "Diagnostics text blends into the report pane without an extra box or focus border. Select text or use Select all, then press Ctrl+C to copy. Full check-up includes Inspect buffs.",
  "Fresh setup recommends Cleanse, Resurrection, Cleanse before resurrection and SmartShift where they fit your class, even before learning the spells. You can decline each choice. Existing setups stay unchanged unless you select a recommendation."}},
 {version="1.26.4-beta3",title="Shield charges and buff-grades",items={
  "Shamans: My buffs now lets Lightning Shield and Water Shield refresh at one or two charges remaining. This is optional and uses readable information outside combat.",
  "Nearby: turn on Offer higher rank buffs to give a buff-grade when someone has a clearly identified lower rank and can receive your upgrade. It starts off.",
  "Diagnostics > Inspect buffs shows your readable active buffs and which reminders recognize them. You can copy the results into a report.",
  "Setup now points out Supplies tracking for ammunition, Soul Shards and group-buff reagents, with a shortcut to choose what to track."}},
 {version="1.26.4-beta2",title="Better buff ranks for lower-level players",items={
  "Mages, Priests, Druids and Paladins: ordinary ranked buffs can now offer a stronger rank to lower-level players, instead of treating the level where you learn it as their requirement.",
  "This beta tests the usual Classic buff-level allowance. Group versions and unusual spells keep their existing rules; every cast still needs your click or binding."}},
 {version="1.26.4-beta1",title="Safer group buffs and pet reminders",items={
  "Nearby buttons now clear their prepared casts reliably when combat starts.",
  "Group buffs respect Also on me being turned off. If an affected member's buff information cannot be verified, BuffTap offers single buffs where possible.",
  "Warlocks with Demonic Pact: pet reminders can offer your chosen different demon while a sacrifice effect is active. Summoning the sacrificed demon stays withheld to protect that effect."}},
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
