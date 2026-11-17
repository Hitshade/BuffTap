# BuffTap 1.26.0-beta1 verification

Latest Cancel/switch follow-up: importing `test_manual_consumables`, `test_options1170` and `test_convenience` passed **738 scenarios, zero failures**. New checks exercise the real switch, Move, Done and Cancel callbacks; restore all reminder coordinates including an unfinished drag; and verify fresh/repeated session baselines. The full-suite result below predates this follow-up. The refined controls still need owner visual review in Forever.

Current follow-up includes detached positioning, edit-mode integration, themed captions, centered overlay labels and whole-composition preview centering.

Executed 2026-11-17 using Python with lupa 2.8 (Lua 5.1).

Full release runner: `BT_KEEP_GOING=1`, import `tests/run_release.py`, inspect `test_bufftap.tests` and `test_bufftap.failures` after all imports: **2,139 passed, zero failed**.

Focused runner: import `tests/test_manual_consumables.py` and `tests/test_options1170.py`: **148 passed, zero failed**, including the base scenarios. It covers default Auto behavior, independent Manual projection, normal binding isolation, hidden main reminder, stock uncertainty, exact-item revalidation, rapid family confirmations, secure driver revocation, pending/quarantine, mode changes, unsafe states, bounded overflow, noninteractive preview and centered partial rows for totals one through nine. Detached-mode scenarios cover no-jump anchoring, reattaching, drag-save on edit-mode exit without active items, live-button disarming, combat interruption and settings export/import.

New tests are imported by the release runner. These checks use a mocked game API; they do not prove native secure execution in Forever. Owner screenshots confirm the earlier beta's visible strip and captions. Detached dragging and final preview centering still need live review.

## Owner smoke test after reload

1. On Consumables, enable a family and choose Manual. Confirm the normal binding never uses that family's items.
2. Show one, two, three and five missing selected effects. Each row should stay centered beneath the main reminder and its labels. Hide the main reminder and check the strip remains usable.
3. Click one item. Confirm only that exact item is used, its pending reminder cannot immediately consume again, and its active effect leaves the strip.
4. Remove the displayed item before clicking. Confirm the click cancels, then the strip refreshes.
5. Enter/leave combat and mount/dismount. Icons should hide and return only after fresh evaluation. Check for blocked-action or taint warnings.
6. Switch Solo/Party/Raid and profiles, then reload. Confirm each setup's modes and selections remain correct. Review Buff reminder preview and unchanged Supplies layout.
7. In Customization > Buff reminder, enable Detach consumables, then use Move. Drag the independent group, finish editing and reload. Confirm its position persists. Enter native Edit Mode with no active consumable reminders and confirm the detached handle still appears. Turn the switch off to follow the main icon again. In BuffTap's move screen, change several reminder positions and press Cancel; they should all return to the session's starting positions.

Eight effects are clickable at a time; +N lists overflow for bag use. No public upload is part of this beta preparation.
