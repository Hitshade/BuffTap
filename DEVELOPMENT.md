# BuffTap development

Current local version: **1.15.2**. Runtime: `addon/BuffTap`. Salvation compatibility prepared locally; published stable is 1.15.1.

Install `requirements-dev.txt`, then run `python tests/test_warlock_review.py` for all 825 isolated mocked Lua 5.1 scenarios. This entry point imports all earlier suites. Run `python tools/verify_mage_catalog.py` to cross-check Mage scroll evidence.

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
