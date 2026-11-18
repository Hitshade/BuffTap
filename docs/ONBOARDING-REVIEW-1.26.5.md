# BuffTap 1.26.5-beta1 implementation record

Status: local beta; no release archive or public publication. Baseline verified as 1.26.4 on the working branch before implementation. The owner subsequently added resting sound, Edit Mode, placement and Nearby click investigation, and removed the original usage-budget constraint.

Changed behavior files: `addon/BuffTap/Onboarding.lua`, `Convenience.lua`, `Engine.lua`, `Alerts.lua` and `BuffTap.lua`. Release identity and the three note audiences are updated in BuffTap.toc, PatchNotes.lua, CHANGELOG.md and RELEASE-NOTES.md. Focused runner/new regression modules, affected older onboarding/power-display assertions, logs and DEVELOPMENT.md accompany the changes. New strings use the existing localization lookup and its safe English fallback; no locale or artwork overhaul was made.

## First run

One welcome decision offers Get started, Customize first, Keep current settings and, only with another valid source profile, Copy settings from another character. Get started applies once and closes. Customize has a single selection view; Back changes no settings. Copy closes on success and leaves the chooser open on failure, without falling back to recommendations. Explicit X/ESC finish without applying; loading-screen hides do not finish.

| Quick-start choice | Fresh character |
| --- | --- |
| Nearby | On; existing invites, requests, resting and safety suboptions preserved; no required guide |
| Reminder sound | On; individual sounds and camp alerts unchanged |
| Pause reminders while resting | On; separate Nearby, consumables, weapon and supply policies unchanged |
| Stronger-effect protection | On |
| Cleanse / normal Resurrection | On for applicable classes, configurable before learning |
| Cleanse before resurrection | On when both fresh choices are selected |
| Solo thanks | Off; explicit customization opt-in only |
| SmartShift and class readiness helpers | Not newly enabled; existing choices retained |
| Consumables / supplies / weapon use | Existing choices retained, no automatic activation |
| Class/group catalog settings | Existing defaults retained; unconfigured Thorns role / adaptive Paladin plan use existing closures |

Priest Fear Ward and Shaman weapon/spec choices are not guessed. Paladin class, role and override preferences prevent replacing a configured plan. Manual review reflects saved switches and applies explicit choices. No onboarding version bump: returning and completed legacy characters are not replayed. Existing optional Nearby guide remains available.

## Friendly names

The separate Enable friendly names only action requires readable 0/1 returns for the existing friendly visibility CVar and `nameplateShowOnlyNameForFriendlyPlayerUnits`. It changes presentation first, verifies it, changes friendly visibility, verifies both, and attempts to restore original values on failure. It never writes enemy settings. No automatic login/quick-start CVar changes, persistence/restore policy or new scan loop is introduced.

This is a capability probe, not a claim that Forever supports or honors the presentation CVar. Unsupported/unreadable settings receive Shift+V/game-settings guidance. Actual Forever names-only rendering remains pending. Solo Thanks has no hard nameplate prerequisite.

## Follow-up review fixes

- The main buff button's final fresh Missing check previously lost the Nearby scanning flag. A healthy lower-rank effect therefore passed listing/selection but cancelled the upgrade at PreClick. Real Nearby actions now use the same upgrade policy during that check. Current coverage, rank, toggle, identity, range, combat and exact macro protections remain.
- Camping, Supplies and Nearby have unprotected Edit Mode placeholders even while disabled. Position saving and Cancel work without changing module permissions. Detached consumables retain their independent mover; attached ones share the main anchor.
- Fresh, unpositioned characters receive an upper-right column with Nearby beside it, using scaled UIParent geometry and a bounded group layout. It is computed only before initial position defaults are filled. Saved/copied coordinates and subsequent resolution changes do not trigger movement. The owner's 2026-11-18 07:54 screenshot supplies visual direction, not literal physical-pixel coordinates.
- Passive resource-wait labels follow the normal name/recipient visibility switches. Both off gives a grey icon with tooltip information. Existing Helpers city/inn pause hides the whole display; returning characters are not silently opted into it. Credit: sevaniuz's CurseForge report.
- A confirmed-city self Thorns sound was not reproduced against the mocked API. An enabled resting pause now also mutes automatic non-social sounds while the resting API is unavailable/unreadable. Explicit previews and opt-in social alerts retain separate semantics. Diagnostics includes the latest actual sound kind, preview flag, resting read, pause preference and age, in memory only and without player identities. This does not establish the live report's root cause.

## Verification

Focused command: `python tests/run_onboarding_focus.py` using the bundled Python runtime and Lua 5.1 through lupa. Final focused result before integration: **134 passed, 0 failed**. It selects relevant existing scenarios without importing their unrelated test chains, runs the new first-run/review cases, and compiles Onboarding.lua, Convenience.lua, Engine.lua, Alerts.lua and BuffTap.lua.

Cases cover actual buttons/PreClick, copied-profile success/failure, fresh versus returning setup, no automatic CVar writes, both read-back failures, class spot checks, known/unknown coverage, city transitions and Nearby exception, disabled movers/Cancel/combat, icon-only waits, and scaled UI dimensions from 450x320 through 5120x1440 and 3840x2160. These are UI-space tests, not live monitor/rendering tests.

Integrated command: `BT_KEEP_GOING=1 python tests/run_release.py`. The run completed with **2,751 passed, 0 recorded failures** (FINAL_TOTAL 2751; the output was separately checked for FAIL records). Logs: `tests/onboarding-review-1265-focused.txt` and `tests/release-1265-beta1-full.txt`. All scenario sources and run logs are committed with this change. No agent-operated WoW, native clipboard test, actual names-only rendering, server-side buff upgrade cast, or live city-sound reproduction is claimed.

GitHub was checked again on 2026-11-18: no open/new issues. Closed #5 remains the prior Goblin Deviled Clams fix by shaunpearsondev; #4's existing resurrection-row comment was reviewed. This beta does not reopen, close or post replies to either report. The external sevaniuz screenshot is feedback, not authorization to send a reply.
