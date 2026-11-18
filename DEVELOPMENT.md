# BuffTap development

## Issue review workflow

Check [GitHub issues](https://github.com/Hitshade/BuffTap/issues) at the start of development or review work and before each public release. Read relevant comments, assess reports against the current source and Forever client limits, and record what is reproduced, addressed or deferred. Carry applicable issue references and reporter credits into release preparation. Report any inability to complete the check; do not assume no issues exist. Posting replies and closing issues require owner authorization.

Latest review, 2026-11-17: connected GitHub review confirmed [#5: Goblin Deviled Clams not showing as food after latest update](https://github.com/Hitshade/BuffTap/issues/5), reported by shaunpearsondev, with no new comments before publication. The confirmed whitelist omission is addressed in 1.26.3 with 14 other foods. Following owner authorization and publication, #5 was closed as completed. No additional comment was posted. Closed #4 and its Druid resurrection-row overlap comment were reviewed.

**1.26.3** includes normal Druid Revive, corpse range recovery, SmartShift after cleansing, Nearby cooldown confirmation, food additions and pre-learning class tracking. The horizontal confirmation sweep is slightly stronger, fixed timing padding is removed, and error correlation and contradictory cooldown flags are corrected. Its final beta2 full suite passed 2,321 mocked scenarios; release identity passed 367 focused checks. See [class review](docs/CLASS-SPELL-AUDIT-1.26.3.md) and [consumable review](docs/CONSUMABLE-AUDIT-1.26.3.md). Fresh 70888 class tables and all included consumable tooltips were retrieved. Their current-availability limits still apply; records alone do not prove acquisition or trainability.

Current release: **1.26.3**, owner-authorized on 2026-11-17. [GitHub release](https://github.com/Hitshade/BuffTap/releases/tag/v1.26.3), tag v1.26.3, commit b399b24. [CurseForge file 9676481](https://www.curseforge.com/wow/addons/bufftap/files/9676481) was submitted as Release for Forever 1.60.1 with automatic publication after approval; last observed status Under Review. Both platforms use the same verified package. Stable release installed and all 117 files hash-verified. Preserve settings and all three note audiences; do not claim the exact live range incident was reproduced.

1.26.2 fixes repeated reminder sounds during active smooth-buffing sequences. No casting or saved-setting changes. Publication approved by the owner on 2026-11-17.

1.26.1 adds confirmed-GCD preparation and swipe, passive mana-wait status, SmartShift event/priority/resource recovery fixes and bounded successful self-buff aura settling. New regression modules cover the real dispatcher and PreClick. Publication approved by the owner on 2026-11-17, conditional on release checks; owner confirmed the beta6 live smoke test including settings after reload.

1.26.0 adds independent Manual consumables, detachable edit-mode positioning and appearance refinements. `tests/test_pre_ship_review.py` covers the release-review fixes: master-off click revocation, SmartShift pause/form/cooldown guards, Manual refresh-threshold wakes and complete appearance reset. Review evidence is in `RELEASE-REVIEW-1.26.0-beta2.md`. Final publication was approved by the owner on 2026-11-17.

Previous release: **1.25.0**. Runtime files: `addon/BuffTap/`; tests: `tests/`; release harness: `tests/run_release.py`.

Install `requirements-dev.txt`, then run `python tests/run_release.py` (set `BT_KEEP_GOING=1` to see every failure) and `python tools/verify_mage_catalog.py`. The mocked Lua 5.1 suite does not establish live WoW Forever compatibility. See `AGENTS.md` for the release-notes policy and the combat and secure-action safety rules. Test counts in older release notes are historical.

Options support arrow ordering for class buff lists and independent Paladin Target/Groups priority lists. Group custom priorities are opt-in; explicit player choices remain authoritative. Unknown ownership fails closed. Tactical blessing IDs from the reviewed Forever spell-name export are ownership-only guards, never castable maintenance entries. Two-Paladin cases still need live-client testing.

Selection uses event-driven aura/inventory caches and bounded timers. No permanent polling, cross-player assignment coordination, bank/alt tracking, or auto-purchasing. All casts and item use require player input out of combat.

Installable ZIPs contain only `addon/BuffTap`; development tests and research are not loaded by the client. Full client database exports and reference addons are not redistributed. Bundled libraries retain their licenses.

Class-aware Paladin target lists are their own spell permission: checking a learned blessing enables it there without changing personal buff toggles. All use the shared targetSeconds setting; hidden legacy targetBuffs and targetBuffSeconds values are ignored for class-aware blessings. Other classes and Paladin legacy mode keep the old explicit filters and optional per-spell timing. Group custom lists use shared raid exclusions and player overrides, not hidden legacy per-buff gates.

Class dropdowns open the priority editor directly. Preview state lives on the options control only; opening or closing never writes saved settings. A checkbox or arrow edit saves the ordered list. Player exception selectors remain single-choice.

Optional SharedMedia integration reads the sound registry when opening/searching a picker or playing an alert; no registry polling or new runtime timers. SoundKit research: research/sound-support-1.12.0.json. A missing media pack does not erase the selected name. Native sound listening remains unverified.

Convenience.lua owns session pause, first-use guidance, label styling and a guarded Edit Mode preview. No LibEditMode dependency or Blizzard-system registration; one shared per-character position. Native Edit Mode still needs live verification.

Banner artwork is embedded as a shared 512×256 RGB TGA. Source/prompt: research/mini-banner-asset-1.13.1.md. Banner texture coordinates preserve the source aspect ratio while removing dark padding. The native options page area remains 630 units high.

1.14.1 adds independent Dwarf Find Treasure tracking. Test entry: tests/test_tracking.py; 834 scenarios passed. Prepared locally, not published.

1.14.2 validation: tests/test_player_exceptions.py; 840 mocked Lua 5.1 scenarios passed. Individual exceptions remain session-only. Live editor verification remains pending.

1.15.0: embedded AceDB-3.0 minor 39 with an explicit shared-key facade over the character settings. Profiles/ProfileOptions own profile operations and UI. Test entry: tests/test_profile_persistence.py; 876 scenarios. Source class snapshots are profile-specific, keyed by character and never applied on profile switch. Optional copy validates class identity before any mutation.

1.15.1: embedded AceDB-3.0 minor 39 with an explicit shared-key facade over the character settings. Profiles/ProfileOptions own profile operations and UI. Test entry: tests/test_profile_persistence.py; 882 scenarios. Source class snapshots are profile-specific, keyed by character and never applied on profile switch. Optional copy validates class identity before any mutation.

1.15.2: Salvation and Mass Salvation are independent of blessing ownership. Current DB2 evidence: research/salvation-1.15.2.json, build 1.60.1.70425. Test entry: tests/test_salvation.py, 902 mocked Lua 5.1 scenarios. Old opt-ins pause for explicit review, with backups retained; old fixed Salvation assignments become Skip. Class-wide casts revalidate affected exclusions and roster completeness. Revoke remains manual.

1.15.2 clarity revision: Groups owns independent salvationGroup permission; Target owns explicit targetBuffs.bos permission; Buffs retains personal permission. blessingGroupOverrides stores scoped class choices and priorities, resolved before player exceptions, with shared exclusions authoritative. tests/test_group_scopes.py: 922 scenarios. Research-only comparison: research/buff-manager-usability-1.15.2.md.

1.15.2 party-first revision: Party retains blessingClasses/groupBlessingPriorities and adds blessingPartyMode/blessingPartyUniform. blessingRaidDefaults owns separate class/order/mode data; blessingGroupOverrides stores G1-G8 overrides. All four plan fields are classKeys for same-class optional profile copying, never shared profile preferences. Session exceptions use choice for Party and raidChoice for Raid; Never Salvation is independent. Uniform mode returns before class/player resolution. tests/test_party_plans.py: 957 scenarios. No publication performed.

1.15.2 party-first revision: Party retains blessingClasses/groupBlessingPriorities and adds blessingPartyMode/blessingPartyUniform. blessingRaidDefaults owns separate class/order/mode data; blessingGroupOverrides stores G1-G8 overrides. All four plan fields are classKeys for same-class optional profile copying, never shared profile preferences. Session exceptions use choice for Party and raidChoice for Raid; Never Salvation is independent. Uniform mode returns before class/player resolution. tests/test_party_plans.py: 959 scenarios. No publication performed.

1.15.2 party-first revision: Party retains blessingClasses/groupBlessingPriorities and adds blessingPartyMode/blessingPartyUniform/blessingPartyExcluded. blessingRaidDefaults owns separate class/order/mode data; blessingGroupOverrides stores G1-G8 overrides. All plan fields are classKeys for same-class optional profile copying, never shared profile preferences. Session exceptions use choice for Party and raidChoice for Raid; Never Salvation is independent. Uniform mode returns before class/player resolution. tests/test_mechanical_cleanup.py: 983 scenarios. Roster UI/event ownership, plan initialization, inherited filter access, profile normalization and unused class UI corrected. No publication performed.

## 1.15.5 aura evidence pass

Exact-instance PLAYER ownership queries, conservative partial buff scans and suppression-aware priorities. See research/aura-evidence-1.15.5.md and AURA-TESTING-1.15.5.md. 1026 mocked Lua 5.1 scenarios passed; shipped Lua and archive verified. Not published; no live-client verification.

1.15.5 safety pass: Safety.lua owns PvP recipient/area checks and confirmed 10-second recipient deferrals. pvpProtection is a default-on shared profile preference. UNIT_FLAGS remains globally registered independently of readiness helpers. No polling was added. tests/test_safety.py adds 35 scenarios; total 1061 mocked Lua 5.1 scenarios. Live tests: AURA-TESTING-1.15.5.md. Not published.

## 1.16.0 Nearby release

Nearby.lua owns the fixed compact list, bounded nameplate tracking, exact-name secure cast/restore payloads, per-spell range heartbeat and nearby-only stronger-effect handling. Helpers.lua and Engine.lua share bounded post-cast aura freshness with normal buffing. No new artwork or dependencies. Run `python tests/run_release.py` for the full suite (1,183 scenarios). Scanning remains optional, out of combat and limited to friendly player nameplates.
