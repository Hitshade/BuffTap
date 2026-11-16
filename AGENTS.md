# BuffTap contributor rules

## Release notes: mandatory two-audience rule

For every user-visible release, write TWO independently authored records:

1. `addon/BuffTap/PatchNotes.lua`: plain English for in-game players, explaining the visible effect and where to find it. Keep it short. No function names, variable names, API details, raw IDs or internal jargon. No em dashes. Keep exactly ten versions.
2. `addon/BuffTap/CHANGELOG.md`: technical release notes, also used for the GitHub release and the CurseForge changelog. State additions, fixes, root causes, affected modules, API limits, saved-variable migrations, backwards compatibility and the test results actually obtained.

Never copy the in-game `items` strings into `CHANGELOG.md` or into a GitHub or CurseForge release, and never generate the technical notes from `PatchNotes.lua`. Check every claim against the merged source and the tests. Separate "added", "fixed" and "known limits". Keep contributor thanks in both records. Never claim a test passed, or that something was verified in the Forever client, unless it was.

Before publishing: read both records, confirm the version in `BuffTap.toc`, `Engine.lua`, the top of `PatchNotes.lua` and the first heading of `CHANGELOG.md` agree, and make sure the GitHub and CurseForge text is the technical one.

## BuffTap is Forever only

Plan, code and test for WoW Forever. The second value of `UnitName` is a surname, not a realm. Buffs are hidden from addons in combat. Never touch WTF or SavedVariables.

## Tests and evidence
- Commit new regression tests with the fix and import new test modules in `tests/run_release.py`. A release note may only quote a test result that a committed run produced.
- Do not claim live WoW Forever testing unless it happened. Say what was only checked against the mocked game API.

## Maintenance features and events
- Independent helpers (cleanse, resurrection) observe their own events and must not rely on unrelated toggles such as Target buffs or group buffing. Test the real event dispatcher and PreClick, not only helper functions.
- An action on another player needs a readable, unchanged player ID and current eligibility (scope, PvP, block lists, Never cleanse) at selection AND at click time. Unknown identity fails closed; two missing IDs never prove two debuffs are the same.
