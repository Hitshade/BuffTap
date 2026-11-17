# BuffTap 1.26.0-beta1 verification

Caption follow-up: focused Manual consumable and appearance modules passed **142 scenarios, zero failures**, including caption visibility, secure combat hiding and the localized preview heading. The full-suite count below predates this cosmetic follow-up.

Executed 2026-11-17 using Python with lupa 2.8 (Lua 5.1).

Full release runner: `BT_KEEP_GOING=1`, import `tests/run_release.py`, inspect `test_bufftap.tests` and `test_bufftap.failures` after all imports: **2,118 passed, zero failed**.

Focused runner: import `tests/test_manual_consumables.py`: **125 passed, zero failed**, including the base scenarios. It covers default Auto behavior, independent Manual projection, normal binding isolation, hidden main reminder, stock uncertainty, exact-item revalidation, rapid family confirmations, secure driver revocation, pending/quarantine, mode changes, unsafe states, bounded overflow, noninteractive preview and centered partial rows for totals one through nine.

New tests are imported by the release runner. These checks use a mocked game API; they do not prove native secure execution in Forever. No live-client test is claimed.

## Owner smoke test after reload

1. On Consumables, enable a family and choose Manual. Confirm the normal binding never uses that family's items.
2. Show one, two, three and five missing selected effects. Each row should stay centered beneath the main reminder and its labels. Hide the main reminder and check the strip remains usable.
3. Click one item. Confirm only that exact item is used, its pending reminder cannot immediately consume again, and its active effect leaves the strip.
4. Remove the displayed item before clicking. Confirm the click cancels, then the strip refreshes.
5. Enter/leave combat and mount/dismount. Icons should hide and return only after fresh evaluation. Check for blocked-action or taint warnings.
6. Switch Solo/Party/Raid and profiles, then reload. Confirm each setup's modes and selections remain correct. Review Buff reminder preview and unchanged Supplies layout.

Eight effects are clickable at a time; +N lists overflow for bag use. No public upload is part of this beta preparation.
