# BuffTap 1.26.4-beta1 verification

## Follow-up 1.26.4-beta2: ordinary recipient ranks

Owner supplied stronger Classic-rule evidence and a focused-beta recommendation. The beta changes recipient eligibility only for Mark, Thorns, Intellect, Dampen/Amplify Magic, Fortitude, Divine Spirit, Shadow Protection, Might and Wisdom. Known catalog ranks use the existing Forever-derived rank level minus ten, clamped to one. Learning API metadata remains separate, including when Level Link changes it. Unknown/remapped ranks do not inherit the allowance. Self behavior, individual ownership checks, unknown-level rejection, localized macros and cache invalidation remain intact.

Group/Greater spells, single-rank effects, shouts, auras and utility retain their prior rules. All beta1 fixes are retained. This is an internal test build, with no publication authorized and no unrelated competitor feature added.

`test_recipient_ranks.py` adds 134 cases: exact and below-boundary checks across all 53 affected ranks, invalid/restricted levels, individually unknown ranks, adjusted learning metadata, per-level caches, actual spellbook-event invalidation, missing/remapped records, 14 excluded-family controls, exact Nearby rank macros and a real Nearby PreClick rejection after eligibility changes. The two existing audit rank checks now use the new 3/4 Intellect boundary and correctly expect rank 2 while rank 3 metadata loads. An old Priest-ordering fixture falsely declared Divine Spirit learned at level 1 on a level-10 target; it now supplies the real learning level and an eligible level-60 recipient. That fixture change preserves its intended ordering assertion.

Live release gate: explicitly cast a representative known rank immediately below/at its expected boundary, recording actual aura/error and client build: Mage Intellect rank 3 (17/18), Priest Fortitude rank 2 (1/2), Druid Thorns rank 2 (3/4), Paladin Wisdom rank 1 (3/4). No stronger competing aura should obscure acceptance. These checks sample the four classes; any deviation requires narrowing the policy before publication. They have not been performed by the agent. Keep the prior beta1 live checks below where not already confirmed by the owner.

Final strict release run: **2,553 mocked Lua 5.1 cases passed, 0 failed**, including all 134 new recipient cases; `tests/recipient-ranks-beta2-release.txt`. All 53 fixture levels independently matched the preserved client export. In-game notes retain exactly ten versions. Against the beta1 package, only Engine.lua, BuffTap.toc and the three note files changed; all other addon files remain byte-identical.

Owner authorized a beta implementing the four findings from the isolated v1.26.3 audit. Publication is not authorized. The original audit checkout and its failing acceptance evidence are preserved.

## Changes and boundaries

| Audit finding | Correction | Preserved behavior |
|---|---|---|
| C-1: unconnected Nearby combat state | Row inherits both secure action and state templates. Failed state registration cannot arm the row. | Row layout, main binding, macro targeting, horizontal cooldown sweep and error correlation. |
| D-1: group cast bypasses Also on me | Affected-recipient preflight calls existing recipient policy, including self preference. | Casts to a different raid subgroup remain allowed when the player is outside its affected set. |
| D-2: unreadable member outside missing bucket | Group preflight verifies applicable coverage for affected covered members too, then falls back to singles when necessary. | Known-positive partial scans, healthy covered members, known corpses, exact rank counts, assignments, reagents and thresholds. |
| G-1: Pact different-demon suppression | Public verified Pact ownership permits the currently chosen different demon. Same sacrificed family remains suppressed. | Chosen demon, Soul Link upkeep, unknown-data safeguards, shards, movement, cooldowns and explicit input. |

No UI controls or appearance changed. No saved-variable migration, new event subscription, recurring poll, automatic target/cast/item use, rank resolver replacement or new maintained sacrifice buff.

## Evidence

- Full release runner, mocked Lua 5.1: **2,419 passed, 0 failed**; output `tests/regression-1264-beta1-release.txt`.
- `tests/test_regression_1264.py` contributes **98 cases**: all 65 original audit probes now pass, plus 33 focused boundary cases. Fixture imports are shared with the existing runner, not a parallel test framework.
- Native callback wiring is modeled from the Forever UI source mirror at commit `3d8abb1da73acd38e412e24fb3f99454a6392346`, specifically SecureHandlerTemplates.xml, SecureHandlers.lua and SecureStateDriver.lua. The positive control and actual row construction are exercised; the tests do not merely execute the row snippet directly.
- Demonic Pact ability **425464** was verified through the Forever tooltip and build **1.60.1.70938** Spell records during the audit. Both state that a different demon preserves sacrifice while the same demon cancels it. The separate wrapper **425473** is not used.
- Public positive ownership can come from the existing spell-known API or IsPlayerSpell. Unreadable/negative ownership keeps the legacy protective suppression. Succubus and Incubus share the protected sacrifice family.
- The new group checks reuse the selection scan cache/errors, run only for a bucket that could meet its threshold, and are re-evaluated through existing explicit group-click reselection.

## Live checks for this beta

These are still required; the mocked results are not live Forever confirmation:

1. Nearby: prepare a row, enter combat, then leave combat. Confirm prepared row casts clear and fresh out-of-combat reminders recover. Recheck the existing rapid-input/sweep behavior.
2. Druid group: turn Also on me off and confirm permitted members receive singles. In a raid, a different eligible subgroup should still receive its group buff.
3. Warlock: verify the client exposes learned Pact through one of the supported public APIs. With sacrifice active, the chosen different demon should be offered when absent; the sacrificed family should remain withheld. Check talent removal and pet death/dismissal, and confirm Soul Link remains independent.

Settings and the established consumable/manual-strip behavior are covered by the complete existing suite. No live-client result is claimed for these beta changes. Keep all three release-note audiences and existing contributor credits when eventually preparing an owner-approved public release.
