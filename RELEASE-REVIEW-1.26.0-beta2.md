# BuffTap pre-ship review: 1.26.0-beta2

Reviewed 2026-11-17 against the local work branch, with 1.25.0 as the published baseline. This is a risk-based review across addon subsystems, not a claim that every client, class, encounter or third-party addon combination has been tested.

## Confirmed findings and fixes

| Priority | Finding | Player impact | Correction |
| --- | --- | --- | --- |
| High | A prepared ordinary action could pass PreClick after the master switch was disabled but before its queued refresh. | One more click could still cast after switching BuffTap off. | The shared action-pause guard checks the master switch immediately. Regression uses the actual main-button PreClick. |
| High | SmartShift's fallback ran after the main selector rejected a disabled/paused context. Its independent validator also conflated missing form data with caster form and accepted incomplete cooldown information. | Misleading or usable return-form actions during disabled/paused states; an unsafe return when form data was unavailable. | Selection and PreClick now enforce master/pause/situation/self identity, a confirmed zero form index, cast/channel state, learned spell and public enabled cooldown data. Tests cover both Druid and Shaman. |
| Medium | SmartShift rejected a live cooldown without scheduling its end. | A return could be delayed until an unrelated event. | A single bounded wake is scheduled for the readable cooldown end. |
| Medium | Manual projection discarded the next threshold when hiding an already-active effect. | A missing reminder could return late in a quiet game state. | Read-only projection returns the earliest future threshold; the update path schedules it even when the strip is empty. No polling added. |
| Low | Reset look did not restore icon style, label placement and several effect/overlay options. Camping also retained its selected icon style. | A reset did not fully match its promised defaults. | Main reset restores those visual defaults; Camping resets Classic style. Consumable modes/selections remain intact. |

All findings above are fixed locally. Their failure scenarios were reproduced before the corresponding corrections. The 17 new review scenarios are in `tests/test_pre_ship_review.py`, imported by the release runner.

## Scope and evidence

| Area | Review focus | Result or remaining limit |
| --- | --- | --- |
| Secure actions | Main/Manual button preparation, PreClick, state-driver revocation, identity and exact-item checks; no insecure casting/item-use API additions. | Shared master-off gap and SmartShift validator corrected. Existing combat state drivers retained. Mock execution cannot establish absence of native taint. |
| Class and level handling | Catalog/class lists, setup recommendations, Paladin blessing ownership/roles, cleanse/resurrection availability, tracking and weapon choices. | Class-applicable configuration remains available before learning; runtime eligibility remains required. Existing all-class and class-specific regressions pass. No speculative live spell-data changes were made. |
| Druid/Shaman | Opt-in previous-form capture, correlated success, return validation, silence, active-form protection and cooldown readiness. | New pause/identity/form/cooldown cases pass, including Ghost Wolf. Live form/GCD transitions still need owner testing. |
| Consumables | Auto/Manual separation, exact item, stock/aura uncertainty, cooldowns, pending/quarantine, shared effects, overflow, eating behavior, timing. | Manual threshold wake corrected; existing click/stock/effect/overflow cases pass. Eight-effect clickable cap remains documented. |
| Groups/Target/Nearby | Identity freshness, blessing ownership/exclusions, PvP guard, independent maintenance events and separate bindings. | Existing regression coverage passes; no confirmed additional defect found in the inspected paths. Two-Paladin/raid/server behavior remains a live-test limit. |
| Readiness and weapons | Pet/stone recovery, assigned Soulstone identity, movement/reagents, exact weapon/slot compatibility and level/runtime guards. | Existing regressions pass; offline validation confirms all 15 Mage mappings. No new item/spell mappings were inferred. |
| Profiles/settings | Explicit allowlists, safe parser rather than executable imports, normalization, situation revision and shared detached positions. | Existing profile/export/import/context tests pass. No WTF or SavedVariables files were read or edited directly. |
| Editing/appearance | Shared preview/live styling, first-display Camping order, detach/reattach, Cancel rollback and reset scope. | Earlier UI changes retained; incomplete reset corrected. Native Edit Mode interaction and final render still need owner smoke checks. |
| Performance | Event-driven aura/inventory caches, default-Auto idle work, bounded retries/wakes, optional animation/UI updates. | No new scanner or permanent polling loop. Manual wake uses existing scheduler. Mock performance regressions pass; actual raid CPU cost was not profiled. |
| Release preparation | Three independently written note audiences, exact ten in-game versions, Xprit44 credit, matching beta identity and archive contents. | Beta 2 prepared locally; no public publishing performed. Prior 1.25.0 history preserved. |

## Executed validation

- Baseline full suite before review fixes: **2,145 passed, zero failed**.
- Full release runner after fixes: **2,162 passed, zero failed**, using Python/lupa 2.8 with Lua 5.1, `BT_KEEP_GOING=1`, and final counts from `test_bufftap.tests`/`failures`.
- `tools/verify_mage_catalog.py`: all 15 Mage item/use/enchant/weapon mappings match reviewed offline evidence; Spellbreak excluded.
- New scenarios reproduce master-off PreClick, five SmartShift pause contexts, unavailable/active form state, missing identity, incomplete/active cooldown flags, casting, cooldown wake, Ghost Wolf parity, active Manual threshold wake and full appearance reset.

## Final owner smoke checks

1. Druid or Shaman: self-buff from a supported form, wait through the global cooldown, and confirm one silent return offer. Pause or disable BuffTap and confirm no return action is offered or cast. Choose a different form manually and confirm the old return is canceled.
2. Manual consumable: keep a selected buff active, let it cross the configured refresh threshold while otherwise idle, and confirm its icon returns. Confirm the main binding still skips Manual items.
3. Move multiple reminders and Cancel, then repeat and Done. Check detached consumables in native Edit Mode, including with no active reminder. Combat interruption must produce no blocked-action warning.
4. Reset appearance and verify Classic/Split/default effects and positions, while class preferences and item modes remain saved.

No other confirmed blocker was found in the inspected paths. These checks do not replace native Forever validation, particularly combat lockdown, forms, group ownership and optional-addon interactions. Do not publish until the owner approves the final build.
