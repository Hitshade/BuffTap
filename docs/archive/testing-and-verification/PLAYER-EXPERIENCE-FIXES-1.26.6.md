# Player-experience fixes: 1.26.6-beta1

The owner authorized all five findings from PLAYER-EXPERIENCE-AUDIT-1.26.5.md on 2026-11-18. This is a local beta, not a public publication or a new feature expansion.

| Finding | Corrected behavior |
| --- | --- |
| Camping bypassed pauses | Normal Camping reminders obey temporary pause, the Helpers city/inn pause, stealth and editing. Its own frame watches resting/stealth events. Temporary pause, cancel, expiry and Edit Mode update an existing icon promptly. |
| Camping sound used preview bypass | Automatic sound uses campSound independently of main sounds and observes pause/rate checks. Explicit previews remain deliberate. Resuming the same missing effect does not replay its old alert. |
| Paused Manual icons stayed visible | Buttons, heading and holder hide and disarm before inventory/projection work during global/category/scope pauses. Resume rebuilds current item payloads. Grey stock information still works normally outside pauses. |
| Attached items intersected Camping | Starter positions reserve room for the heading and two attached rows. Short UI spaces use the area below Nearby for Supplies. Existing saved or copied positions are not migrated. |
| Reset positions disagreed | Main and both Camping reset paths use the common position provider. Supplies position repair/defaults also use that provider. Each reset changes its own module's position only and preserves other module enable flags. |
| Warrior footer said mana | Warrior/Rogue status uses power, matching the icon. Internal reason keys remain compatible. |

The two Camping rows describe one audit finding and its sound-path cause. No casting, catalog/rank, class configuration or profile migration changes were introduced. Town Supplies visibility remains intentional; restocking information is not hidden merely to match buff reminders. Deliberate Camp tray operations and previews remain available.

## Verification

Focused command: `python tests/run_pause_layout_focus.py` using the bundled runtime and mocked Lua 5.1 API. Result: **40 passed, 0 failed**, plus compile checks for Alerts.lua, ManualConsumables.lua, Camping.lua, Convenience.lua, Supplies.lua, Options.lua and OptionsRefinement.lua.

Coverage includes actual reset buttons, Camping's own event handler, timer expiry and combat interruption, existing-alert versus new-alert behavior, sound permission/preview/rate distinctions, hidden Manual holder/caption/buttons, stale PreClick rejection, detached item coordinates, two-row separation at eight UI sizes, independent reset positions and class-appropriate status terminology. Existing tests were adjusted only for the intentionally changed default/reset expectations. The historical audit script remains a reproduction of the old release, not a fix regression module.

Integrated command: `BT_KEEP_GOING=1 python tests/run_release.py`. Result: **2,791 passed, 0 recorded failures**, with the final count and absence of FAIL records verified. The installation receipt is recorded in DEVELOPMENT.md after copying and hash verification. New test module: tests/test_pause_layout_1266.py, imported by tests/run_release.py. Logs: tests/pause-layout-1266-focused.txt and tests/release-1266-beta1-full.txt.

## Remaining useful live check

After reloading the local beta, enable Camping and Manual consumables together. Check temporary pause/resume, a city/inn and stealth where applicable, then Edit Mode and Cancel. Reset each of the three reminder types individually and confirm the others stay put. The new automatic placement is for fresh/unpositioned characters or explicit resets; existing saved positions intentionally do not move on upgrade.

No agent-operated WoW, actual client rendering, or explanation of the earlier live Thorns sound is claimed. This corrects demonstrated pause inconsistencies without assuming that they caused that specific report. Public release still requires owner authorization.
