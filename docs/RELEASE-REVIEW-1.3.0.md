# BuffTap 1.3.0 release review

## Automated verification

342 scenarios passed under Lua 5.1: 234 existing, 98 stock and reagent-saving cases, and 10 correction regressions. The test runner loads all ten runtime Lua files in manifest order. Run `python tests/test_supplies.py` with lupa 2.8 installed; it includes the other suites.

Stock coverage: default-off idle cost, startup bag capacity and settling, explicit/Auto choices, poison rank pooling/hand deduplication, disabled families/supplies, empty/unusable/unknown/partial counts, metadata load recovery and effect mismatches, cache reuse, inventory coalescing, sound/chat episodes, snooze/restore, ready-check privacy/defer/expiry, saved settings and integrated UI routes. No protected mutations occur in combat mocks.

Group coverage: Gift of the Wild; Arcane Brilliance; Prayer of Fortitude, Spirit and Shadow Protection; Greater Blessings of Kings, Might, Wisdom, Salvation and Light. Healthy greater coverage suppresses expiring singles, isolated missing recipients use a single buff, expiring group coverage remains actionable, stale group clicks cancel, and unchanged valid group clicks remain available. Mixed-rank counts, changed range/assignments and unreadable recipient auras are checked.

## Live checks before publication

1. Reload with all new switches disabled; verify ordinary buffing and existing settings are unchanged.
2. Enable Consumables Ã¢â€ â€™ Supplies. Check native icons, readable rows and editable thresholds/targets at your UI scale. Press Enter to save numeric changes. All current applicable supplies fit in the integrated view.
3. With distinct Rogue poisons, check usable rank totals and separate families; selecting one poison for both hands produces one row. Test zero stock versus an unusable carried rank, and reloading with saved choices.
4. Test explicitly selected food/flask/elixir stock and Auto food. Run out of a selected item, restock, and confirm warnings reset without changing choices. Confirm unknown data does not claim zero stock.
5. Test optional chat/sound, ten-minute snooze, Restore alerts, and the indicator when the cast queue is empty. Check position after moving/resizing the BuffTap anchor.
6. Initiate a group ready check: the supply summary is private and describes stock only. Enter combat with a visible indicator; it hides, no casting state is modified, and stock refreshes after combat. A ready check during combat is reported only if combat ends within 30 seconds.
7. For each available reagent group buff, prepare a group reminder, have another player buff a recipient or move a recipient out of range before clicking, and confirm the obsolete group action cancels. The next input may apply a single buff. Test a valid group cast and healthy existing greater buffs.
8. Retain the Shaman main-hand/Rogue per-hand application checks in RELEASE-REVIEW-1.2.0.md; this task does not newly verify those native actions in-game.

## Scope and unresolved research

No reagent-exemption detector, manual reagent override, group/recovery stock tracker, resurrection action, purchasing, bank/alt tracking, assignment synchronization, or broad tooltip-based item scoring is installed. The hidden Reagent Economy state needs live validation before related features are built. Group click recount applies only to reagent-consuming group casts. Existing group reagent validation remains unchanged.

Prepared locally, not published. Automated verification is not a substitute for live client rendering/cast checks. Keep releases/BuffTap-1.2.1.zip for rollback.

Correction regressions: actual main/quick pickers, consumable family/master switches, slash toggles and weapon preferences update supply definitions. Punctuation capture/load/slash paths persist bindings. No additional inventory calls for a preference-only stock update. Total: 342 mocked scenarios. Verify punctuation binding acceptance in the client before publication.
