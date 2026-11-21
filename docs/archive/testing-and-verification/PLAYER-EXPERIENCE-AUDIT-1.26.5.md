# BuffTap 1.26.5 player-experience audit

Follow-up: the owner authorized fixes to all findings. See PLAYER-EXPERIENCE-FIXES-1.26.6.md for the corrected local beta. The observations below remain historical 1.26.5 evidence; their standalone reproduction script is not intended to pass against the corrected branch.

Reviewed 2026-11-18 against the shipped 1.26.5 behavior. No runtime changes, installation, publication or user replies were made for this review.

## Confirmed findings

### 1. Camping bypasses the main pause system

Camping.lua:80-86 checks master enable, combat, death, mount, instances and its own snooze, but not the temporary reminder pause, stealth or Edit Mode. Its automatic alert at line 506 calls PlayAlert with the preview bypass, skipping ordinary pause checks and sound pacing.

Reproduced: the normal Camping reminder displays and sounds during Pause reminders for five minutes, while stealthed, and during Edit Mode. It also sounds with the Helpers city/inn pause enabled. The Edit Mode case shows a live reminder alongside its mover.

Recommendation: respect temporary pause, editing and stealth for normal Camping notifications. Decide explicitly whether the general city/inn pause covers Camping or whether Camping needs a clearly presented independent policy. Keep deliberate sound/UI previews separate from automatic alerts. This could explain a sound heard in town; it does not establish that Camping caused the owner's earlier Thorns report.

### 2. Manual consumable notifications remain visible when their use is paused

ManualConsumables.lua:163 projects missing effects before testing per-action/category pauses. At line 207, pauses remove the item action but still show the grey icon and caption. The category checkbox help says to skip food/flask/elixir/utility reminders in cities and inns.

Reproduced: a Manual food icon remains visible during its city/inn pause, the global temporary pause, and the Only in dungeons and raids exclusion. All tested buttons were disarmed; a fresh stale-click check also refused item use. This is notification/UI inconsistency, not unauthorized consumption.

Recommendation: hide the strip for explicit global/category/scope pauses. Reserve grey informational states for conditions where the user still wants the reminder, such as missing stock or unreadable coverage. Apply the same policy to the Consumables caption and overflow tile.

### 3. Fresh starter positions overlap attached Manual consumables and Camping

Convenience.lua:288 places Camping 76 UI units below the main buff icon, at the same horizontal coordinate. ManualConsumables.lua:8 places the attached first consumable row approximately 82 UI units below the main icon with default labels. The 22-unit consumable icons and 40-unit Camping icon therefore intersect.

Reproduced from a fresh mocked profile: identical horizontal centers and only six UI units between the first Manual row and Camping centers. This requires the user to subsequently enable Camping and choose Manual consumables; it is not visible with both optional modules off.

Recommendation: reserve space for the attached caption and two Manual rows when choosing starter positions, or place Camping outside that attached region. Keep the bounded scaled-UI layout and never migrate saved positions automatically. Existing dragged positions can always overlap by choice; the issue is the supplied starting layout.

### 4. Reset look & position does not use the new starter layout

The main reset in Options.lua:2358 still writes x=0,y=-180. Camping's visible reset in OptionsRefinement.lua:236 writes x=100,y=0, while its older underlying reset uses y=-180. Supplies generates another position relative to the main icon. These differ from the newly supplied starter group.

Reproduced by clicking the actual confirmed main and Camping reset buttons. Both return to different locations than ReminderDefaultPositions().

Recommendation: use one shared placement provider for initial defaults and each explicit position reset. Preserve the behavior that resetting one module does not move the others, and preserve all unrelated selections/settings. Audit the separately labeled Center behavior when wiring the reset to avoid reintroducing duplicate visible controls.

### 5. Warrior resource waiting still says mana in the status/footer

The new grey display correctly calls a Warrior's shortage power, but Engine.lua returns the generic internal reason not enough mana. Alerts.lua:159 translates that into Not enough mana to buff.

Reproduced with known Battle Shout and insufficient power: a passive waiting indicator and the literal mana status text. This affects status/footer/broker descriptions, not spell eligibility.

Recommendation: derive player-facing resource wording consistently across the icon, tooltip, status and diagnostics. Keep internal error keys backward-compatible if useful.

## Checked controls and boundaries

- The current city/inn pause suppresses the grey power-wait notification; this existing behavior was reproduced again.
- A paused Manual food icon cannot consume its item at PreClick; the tested behavior fails closed.
- Camping already checks its own snooze and major combat/death/mount/instance exclusions. Its gap is other pause states, not the absence of all safety checks.
- Supplies remaining visible in town is intentional: towns are where players restock. It should not be changed simply to make all helpers identical.
- Class-applicable cleanse and resurrection configuration remains available before learning; irrelevant Abolish/Rebirth controls are class-specific. Sleeping-bag presentation already distinguishes a max-level character from an unfinished stack. No additional defect was established in those inspected paths.
- No new GitHub reports were found. Closed #4 and #5 remain previous resolutions; no state changes or replies were requested by this audit.

## Evidence and limits

Command: `python tests/audit_player_experience_1265.py`, executed with the bundled Python runtime and existing Lua 5.1 mocked-game harness. Result: **13 observations/control checks reproduced as asserted**. Log: `tests/player-experience-audit-1265.txt`.

This standalone audit deliberately asserts the current problematic behavior to prove the observations; its PASS output is not evidence that the issues are fixed. It is not imported into the normal release suite. The existing harness is loaded without running unrelated scenario chains. No full-suite rerun, live WoW automation or client rendering test was performed. The overlap is established from actual layout coordinates and sizes, not a captured live screenshot.

Suggested fix order: Camping pause/alert separation and Manual pause visibility, starter-layout spacing, then shared resets and resource wording. All five should have regression cases that assert the corrected behavior before another release.
