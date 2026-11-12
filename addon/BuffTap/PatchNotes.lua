-- This Source Code Form is subject to the Mozilla Public License, v. 2.0.
local _,B=...
-- Keep the ten most recent releases within a 24 KiB content ceiling.
B.PatchNotes={
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
 {version="1.16.10",title="Smoother Nearby sessions",items={
  "Reduced the temporary memory created while checking nearby players.",
  "Nearby continues updating normally while players enter and leave view."}},
 {version="1.16.9",title="Directed solo thanks",items={
  "Solo thanks avoids sending a general emote when the recipient cannot be verified.",
  "Debug information makes missed thank-you emotes easier to investigate."},thanks="Thank you for the reports and continued testing."},
 {version="1.16.8",title="Safer detection and clearer status",items={
  "Improved solo-thanks identification and protection against misdirected emotes.",
  "Improved cooldown recovery and clarified why a buff may be unavailable.",
  "Expanded supported battleground self buffs while respecting restricted buff information."}},
 {version="1.16.7",title="More reliable solo thanks",items={
  "Solo thanks recognizes helpful effects from identifiable players beyond a fixed spell list.",
  "Improved provider checks and explanations when a thank-you cannot be sent."}},
 {version="1.16.6",title="Nearby players and party invitations",items={
  "Added a dedicated Nearby page and an optional view that keeps nearby players listed after buffing.",
  "Added party invite and suggest-invite buttons, with buff candidates shown first.",
  "Improved Nearby counters, list stability and Diagnostics."}},
 {version="1.16.5",title="Buff ranks and thank-you reliability",items={
  "Corrected Mark of the Wild rank choices for lower-level recipients.",
  "Improved solo-thanks handling of delayed buff information and quick successive providers.",
  "Clarified the unlearned Gift of the Wild label."},thanks="Thank you for the reports and continued testing."}
}
function B:PatchNotesUnread()
  return self.profileDB and self.db.optionsPatchDot~=false and self.profileDB.global.patchNotesSeen~=self.version
end
function B:MarkPatchNotesRead()
  if self.profileDB then self.profileDB.global.patchNotesSeen=self.version end
end
