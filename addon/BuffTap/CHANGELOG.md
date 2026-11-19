# BuffTap 1.26.8-beta3

### Solo Thanks delayed-caster recovery
- Investigation of waggz81's 1.26.6 diagnostic identifies a readable aura caster GUID with no live emote unit. It does not implicate Warrior resource state or fishing/crafting. The exact live report is not reproduced.
- Preserve an incoming aura's unresolved caster GUID and allow up to ten seconds for live-unit resolution. Existing unknown/secret-ID cases retain the short two-second window. Settling remains bounded: first retries at 0.2 s, then 0.5 s after ten attempts, at most thirty attempts for a known pending GUID, no idle timer. Pauses/combat/profile/group transitions continue to discard or prevent sends.
- At delayed dispatch a previously live unit token can be replaced only by a live token with the same GUID and original full name. Final player/existence/ignore/name/GUID checks remain; no name-only fallback, automatic targeting, crafting interruption or emote API retry is introduced. Per-provider cooldown and pacing remain.
- Explicit initial baselines discard pending candidates, preventing an already present unresolved buff from creating a retroactive thank when its caster becomes visible later. Regression covers late resolution, timeout, wrong identity, combat/disabled cancellation, initial baseline and token replacement.
- Report scope: a bounded recovery improvement, not a confirmed fix for the reporter. A caster never exposed as a live unit still cannot safely be thanked. Targeted mocked Lua 5.1 regression: **1,049 passed, 0 failed**, including existing thanks identity/robustness, helper, review-correction and profile scenarios plus seven new delayed-caster cases. FINAL_TOTAL/FINAL_FAILED and absence of FAIL records verified in tests/thanks-1268-beta3-regression.txt. Three affected Lua files compiled independently. Full beta1 suite is historical, not rerun for this scoped change.

# BuffTap 1.26.8-beta2

### Secondary icon consistency
- ManualConsumables, BuffQueue and the consumable preview now reuse ApplyIconStyle with the main reminder iconStyle. Runtime refresh updates existing buttons, including unavailable stock and overflow, without changing secure payloads, centering or counts. Classic restores full texture coordinates and hides modern borders; Modern applies the same crop and frame as the main icon. No glow or animated effects are added.
- Presentation-only change; beta1 behavior validation remains historical. Focused mocked regression: 143 passed, zero FAIL records, including six Classic/Modern live-update, preview and no-glow cases (tests/secondary-style-1268-beta2-focused.txt). Four affected Lua files compiled. Full beta1 suite is not rerun for this visual-only change.

# BuffTap 1.26.8-beta1

### Contribution and adaptation
- Adapts tinect's PR #6 at 815a94d750d441b0c523a7291c071b333a6b80bb without merging or publishing the PR. Latest revision excludes the earlier Nearby-on-reminder option. Contributor credit is retained in all three note audiences.
- BuffQueue is optional, off by default. It reuses bounded buff-only EngineSelect passes, excludes already represented recipient/family pairs, suppresses group casts/Greater Blessings and respects blessing exclusivity. Four centered secure up-click buttons retain fresh GUID/payload/need/eligibility checks and secure combat/death/mount drivers. Bindings remain on the main button. Manual consumables offset below the row; detached placement is unchanged.
- Adaptation starts BeginHelperAttempt only after successful queue PreClick validation, preserving SmartShift intent, self-buff confirmation settling, retry attribution and quiet sequence tracking. All casts require hardware input. Queue and estimate frames use MEDIUM strata alongside main/manual reminders. Bounded 12-pass counts explicitly use a trailing + and lower-bound tooltip when exhausted; counts exclude the main recipient and are not full-raid totals.
- CombatExpiry records enabled own buffs only out of combat, schedules nonsecure display timers about ten seconds before stored expiry and discards death/loading/identity-stale plans. Combat never queries auras or changes secure actions. Only true self-only cast confirmations can renew an estimate; targeted refreshes and dispels cannot be inferred. It is optional and off by default.
- PlayAlert accepts an explicit sound-action context for passive estimates without swapping B.action, preserving Personal mute/custom selection and category/rate/pause controls. Estimate visuals honor normal pauses; their combat-only update callback can quietly restore visibility when a pause ends. Cancellation removes timers/update callbacks. A separate footer row reserves space beside class-specific SmartShift controls.
- PR includes expanded German entries and release-click registration tests. Not every new English label or diagnostic has a German translation; no claim of complete localization or owner live verification is made.

### Compatibility and validation
- New combatExpiry and buffQueue booleans are profile-shared presentation preferences, both false by default. No existing values or positions are migrated and no WTF/SavedVariables files are edited. Existing per-buff sound schemas are unchanged. Three imported contributor test modules plus adaptation-specific behavior tests run in tests/run_release.py. Final integrated mocked Lua 5.1 release run: **2,923 passed, zero FAIL records**, with terminal FINAL_TOTAL verified (tests/release-1268-beta1-final.txt). Focused adaptation run: 97 passed, 0 failed; queue/imported baseline run: 381 passed, 0 failed. Eleven affected Lua files compiled independently; all loaded modules also compile in the full run. Initial mixed run exposed sound-context forwarding through Cleanse; the final complete rerun includes that fix. No live game testing claimed.

# BuffTap 1.26.7

### Scoped sound selection
- Adds versioned character/class buffAlerts preferences for personal, party and raid scopes, keyed by canonical buff family. Records hold enabled and optional validated sound keys. Missing values inherit enabled/default behavior; single/group spell versions share their family. Same-class copy and export/import preserve selections and sanitize invalid records. Unlearned class-applicable spells remain configurable.
- Personal controls affect ordinary personal/pet maintenance even while grouped. Party/Raid controls apply to external roster actions and group casts. QuickTarget, Nearby, Cleanse, readiness and consumables do not inherit personal mutes. Existing category, pause, rate and smooth-queue gates run before scoped playback; SmartShift remains explicitly silent. Selection, priorities, secure payloads and hardware-input requirements are unchanged.
- BuffSoundOptions provides an explicitly scoped searchable editor, default inheritance, separate Preview actions and immediate persistence. Left-click toggles without clearing overrides; right-click edits. Preview neither saves a selection nor arms an action. Unavailable SharedMedia choices remain saved/visible with existing fallback behavior. Tooltips explain scope, current sound and muting.

### Category permissions and presentation
- Existing sound, campSound and suppliesSound permissions retain state as independent category controls. New cleanseSoundEnabled inherits the old sound permission once; socialSoundEnabled defaults true to preserve separately opt-in social behavior. Fresh setup's sound choice sets all five permissions; returning setup review preserves individual choices. No direct WTF or SavedVariables file edits.
- State-aware accent speakers replace group switches at the selected card's top right. Paladin Buff sounds aligns with Casting. The default-sounds card places compact category controls beside Preview and explains inheritance in place of the former master switch.
- Selector lists reset stale searches, open around the current selection and use exact sound keys. OptionsStyle scrolling uses 20-unit eased steps, cancels on hide or scrollbar drag, and is immediate under Reduce animation. No idle polling is added.

### Audio assets
- Adds ten owner-created 44.1 kHz stereo Ogg alerts, each 0.98 seconds. Gain-only normalization preserves the recordings' content and stereo, followed by Vorbis encoding. Following owner feedback, target loudness is -20.82 LUFS, 1 dB above the initial matching target; decoded additions remain within 0.1 dB with peaks below -7.7 dBFS. The eight previously shipped assets and all owner originals are byte-identical.
- research/owner-sounds-1267.json records hashes, gains and measurements; tools/import_owner_sounds.py reproduces the conversion. Five rejected internal-beta keys map to corresponding new choices, including scoped overrides. Their unregistered prototype audio files are excluded from the release archive, retained on disk without deletion.

### Automatic Abolish selection
- CleanseSpellFor now chooses the first learned spell from the existing Abolish-first lists for Druid Poison and Priest Disease. Cure/Abolish Poison each cost 16% base mana; Disease counterparts each cost 15% in published client-derived 1.60.1.70888 spellbook extracts. Preserved Spell/SpellEffect records confirm immediate dispel plus periodic removal. Direct SpellPower CSV retrieval returned HTTP 403; it is not claimed as evidence. Sources and records: research/abolish-cost-1267.json.
- The conditional stacks/duration preference could choose Cure despite equal cost. Learned Abolish now applies to all otherwise eligible effects; Cure remains the pre-learning fallback. Active-Abolish suppression, Never cleanse, duration eligibility, identity, range, PvP and PreClick safeguards remain. Legacy cleansePreferAbolish is retained but ignored; class-specific guidance replaces the control. Thanks to jimbo1111 for identifying this unnecessary distinction.

### Validation and release scope
- Final committed beta5 integrated mocked Lua 5.1 suite: **2,881 checks passed, zero recorded failures**; FINAL_TOTAL and absence of FAIL records verified. Focused editor/scrolling/scoped-sound run: **98 passed, 0 failed**. Logs: tests/release-1267-beta5-full.txt and tests/sound-editor-1267-beta5-focused.txt. Nine focused modules and eight affected Lua files compiled independently. Asset hashes, stereo/rate/duration, loudness and headroom were checked.
- Owner authorized publication after beta iteration. Stable promotion changes version identity and these audience-specific notes only. Automated mock UI checks are not exhaustive live Forever rendering, listening or all-class verification. GitHub open/recent issue review found no new open reports; closed issues #4/#5 require no release action. Combat aura restrictions and protected-action rules remain unchanged.

# BuffTap 1.26.6

### Settings polish
- Presentation only: reduce Consumables toolbar spacing by 40 UI units; widen Nearby font and size selectors without changing class-dependent panels; distinguish stored custom hex from active accent; clarify manual selection, disabled weapons and Camping pause status; standardize movement labels. No saved-setting or secure-action changes. GitHub review: no open issues; closed #4/#5 remain outside this visual scope. Beta 2 passed 40 focused pause/layout cases and syntax checks; the owner authorized stable publication after local testing.

### Pause consistency
- Camping's normal eligibility now observes ReminderPauseReason, including temporary/resting/stealth/edit states. Entering editing hides the live reminder before showing the mover; temporary pause/cancel/expiry updates it independently. Its own event frame now observes resting and stealth updates, without relying on group/Target/Nearby toggles. Existing snooze, instance, mount, death and combat protections remain.
- Automatic camp alerts use the non-preview path. PlayAlert chooses campSound separately from main sound permission while retaining automatic pause checks and shared pacing. Explicit sound/visual previews retain deliberate exceptions; a visual preview does not emit an automatic alert. Resuming an already-alerted missing effect does not replay the same alert; a newly missing effect can alert normally.
- Manual consumable rendering now checks global and category/scope pauses before projection/inventory work. Buttons, caption and holder are hidden/disarmed, and visible entries cleared. Resume reconstructs fresh payloads. Click-boundary validation and secure combat drivers remain unchanged. Grey missing-stock information remains outside pauses.

### Placement, reset and wording
- Shared starter geometry reserves space for the attached caption and two Manual rows. Normal UIs keep the vertical column; short UI spaces put Supplies beneath Nearby instead. Saved/copied positions are never migrated. Explicit reset uses the same shared provider for main/Camping/Supplies, with module-local coordinates only and conservative geometry-unavailable fallbacks.
- Main and both Camping reset paths use the shared helper. Supplies normalization uses the shared default only when coordinates require repair. Enabled features and consumable modes are preserved. The hidden legacy Center action remains a center operation, separate from a default reset.
- Warrior/Rogue player-facing resource status now agrees with the power-wait icon instead of calling the shortage mana. Internal reason keys remain compatible.

### Evidence and scope
- Forty focused corrected-behavior scenarios passed, plus Lua 5.1 compilation of seven changed behavior modules. They include actual reset buttons and event handlers, pause/expiry/combat transitions, sound permission/rate/preview distinctions, stale-click disarming and UI-space layout checks. The integrated full mocked Lua 5.1 run completed with **2,791 passed, 0 recorded failures**; FINAL_TOTAL and the absence of FAIL records were checked. Focused and full logs accompany the committed scenarios. Historical 1.26.5 audit probes remain evidence of the old behavior and are not part of the release suite.
- Owner authorized stable publication on 2026-11-18 after reporting the beta stable and requesting the final visual polish. Stable promotion changes release identity and notes only; beta validation is retained. No catalog/rank, cast-selection, profile migration or SavedVariables/WTF file changes. Automated validation uses the mocked API; the owner reported the beta stable. No exhaustive all-class or all-resolution live verification is claimed.

# BuffTap 1.26.5

### Onboarding and preferences
- One welcome decision and one optional compact selection view replace the required recommendations/review/features sequence. Explicit staged application validates class-applicable booleans, preserves sound selections and unrelated settings, rolls back the character facade and shared-profile table on apply failure, and finishes only on success. Profile copy closes directly on success; errors leave it open. Back is nonmutating; explicit X/ESC finish without applying. Loading-screen hides do not finish.
- Fresh quick start enables Nearby, reminder sound only, the resting pause, stronger-effect protection and class-capable Cleanse/normal Resurrection. Cleanse-first is enabled with both fresh recommendations. Existing unconfigured Thorns/Paladin plan closures are reused, with extra protection for configured Paladin role plans. Fear Ward, guessed Shaman weapon choices, SmartShift, class readiness, consumables and social automation are not newly enabled. Existing enabled preferences survive. Manual review reflects current values and applies explicit selections; onboarding version remains 1, with completed/returning eligibility preventing replay.
- Friendly names-only is a separate out-of-combat action, requiring readable visibility and presentation CVars. It establishes presentation before visibility, verifies both by read-back and attempts restoration on failure. No login changes, enemy CVar writes or new scan loop. Unsupported/unknown support gets manual guidance. Public return values do not establish live rendering support on Forever.
- Fresh characters with no saved positions get a one-time upper-right icon column plus adjacent Nearby, calculated in scaled UIParent space with a bounded group layout. Saved/copied coordinates and later screen changes never trigger repositioning. Edit Mode exposes disabled Camping, Supplies and Nearby without changing feature permissions. Attached consumables retain their shared anchor.

### Click and display fixes
- Nearby rank-upgrade detection now recognizes an actual Nearby action at the main button's fresh Missing check after the scanning flag has cleared. Fresh identity, current coverage, toggle, eligibility, range and secure macro checks remain. Equal/higher/unknown effects still revoke obsolete payloads.
- Passive mana/power waiting labels honor showBuffName/showTargetName, preserving the grey display and tooltip without adding actions or sounds. Existing Helpers resting pause already suppresses these states; it is not silently enabled for returning users. Thanks to sevaniuz for reporting the cluttered power-wait text.
- Automatic non-social sounds now stay silent when an enabled resting pause cannot obtain an explicitly false resting state. Confirmed-city self-buff sound could not be reproduced against the mocked API; this is a bounded unreadable-state safeguard, not proof of the live report's cause. A session-only last-sound record and resting/pause diagnostics distinguish actual reminders, previews and social alerts without names or persistent logging.

### Validation and limits
- Initial focused onboarding/Nearby/profile/class/nameplate checks: 77 passed. Expanded focused click/resting/edit/placement checks: 134 passed, 0 failed, plus Lua 5.1 compilation of the five touched behavior modules. No live Forever UI, clipboard, friendly-names rendering or reported city sound reproduction is claimed. The integrated full mocked Lua 5.1 run subsequently completed with **2,751 passed, 0 recorded failures**; FINAL_TOTAL and the absence of FAIL records were checked. Both focused and full logs are committed. Initial test-only encoding/escaped-newline issues were corrected before these final runs.
- Owner authorized stable publication on 2026-11-18. Runtime behavior is unchanged from the tested beta; final edits are release identity and notes. Existing runtime defaults/coordinates are preserved except the explicitly described fresh setup and fresh unpositioned layout. No WTF/SavedVariables file operation, cast automation or combat-rule change.

# BuffTap 1.26.4

### Rank selection and optional maintenance
- Ordinary ranked Mark, Thorns, Intellect, Dampen/Amplify Magic, Fortitude, Divine Spirit, Shadow Protection, Might and Wisdom use `max(1, RankLevel[id]-10)` for external recipients, independently of learning API metadata. The 53 catalog ranks retain Forever-derived levels. Individual rank ownership, unknown-level rejection and exact-rank secure casting remain required. Group/Greater versions and unusual spells retain their prior policy.
- Opt-in Nearby **Offer higher rank buffs** compares complete, readable coverage with the selected known recipient-compatible rank. Only identified lower ranks in the same ordinary family can justify an upgrade; unknown, group-equivalent and equal/higher coverage cannot. Toggle state participates in need caching; fresh click validation revokes obsolete upgrades. Rank ordering does not establish relative strength after every talent bonus; existing stronger-effect refusals/backoff remain applicable.
- Optional Lightning Shield/Water Shield refresh thresholds use public positive integer applications at one/two remaining charges. Missing, zero or restricted counts retain timing behavior. Settings are class-specific and support Solo/Party/Raid inheritance, same-class transfer and reload persistence. No combat prediction or new polling.

### Safety and class behavior
- Nearby rows now inherit the native secure state-handler template as well as the action template; failed state registration cannot arm a row. Existing combat clearing, exact targeting and cooldown feedback remain.
- Group affected-recipient preflight honors explicit self exclusions and verifies usable effect information outside the missing bucket. Unknown affected coverage falls back to singles, while readable covered members, known-positive partial coverage and other raid subgroups retain their intended behavior.
- Verified Demonic Pact ownership allows the already-selected different demon while sacrifice is active. The sacrificed family remains suppressed, including shared Succubus/Incubus identity; unknown ownership keeps protection. Shards, cooldowns, resources and explicit-input checks remain intact.

### Diagnostics, setup and appearance
- Read-only self-buff inspection uses the actual class/consumable recognition sets and is included in Full check-up. It reports public IDs, ranks, source unit tokens, counts and timing without caster-name/GUID lookup, persistent history or casting permissions. Incomplete data is labeled; combat cannot create a current snapshot from cached data.
- Main and captured Diagnostics text remain native selectable/copyable editors without inset/focus-box styling. Select all replaces Print to chat on the page; native Ctrl+C copies selected text. Focused main text survives redraws, explicit Refresh recaptures, and name hiding applies without recursive action refresh.
- Fresh setup presents class-applicable Cleanse, normal Resurrection, cleanse-first ordering and Druid/Shaman SmartShift recommendations on its first review page, independently of learning/level. Each may be declined. Existing profiles require opt-in/review, and completed onboarding is not replayed. Class-specific Supplies guidance opens existing manual tracking without auto-selecting items or enabling warnings.
- Nearby switches use distinct compact positions, collapse the unavailable upgrade row for other classes, and keep Mana reserve at the bottom. Diagnostics actions no longer overlap. Existing settings, priorities, positions and secure-action rules are preserved; new optional controls default off outside accepted setup recommendations. No saved-variable migration or deletion.

### Verification and known limits
- Last strict full mocked Lua 5.1 run: **2,676 passed, 0 failed** on beta4, including 98 audit/fix cases, 134 rank-policy cases, 86 maintenance-feature cases and 37 layout/copy/setup cases added during this release cycle. Tests and run logs are committed. The final beta5/beta6 changes were visual-only; the owner explicitly requested no test rerun, and no fresh final-version test result is claimed.
- Owner reported rank-2 Mark landing on a level-1 recipient and reviewed the displayed beta UI. No agent-operated live WoW, shield-count API, complete class-boundary matrix, Pact lifecycle or system-clipboard validation is claimed. Unknown data remains conservative. Archive/source delivery hashes are checked independently of regression tests.
- Owner authorized publication of the final beta6 behavior as 1.26.4. GitHub issue review found no open issues; closed #4/#5 remain previously resolved, with no new issue changes or replies in this release.

# BuffTap 1.26.4-beta6

### Class-aware visual spacing
- Collapse the hidden Nearby upgrade row for classes outside Druid/Mage/Priest/Paladin by shifting the remaining four left-column controls up one row. Supported classes keep the existing positions; Mana reserve and right-column controls do not move. No setting or action logic changes.
- Visual-only follow-up. No tests rerun at owner request; beta4's 2,676-pass result remains historical. In-game visual beta notes are folded into the latest entry.

# BuffTap 1.26.4-beta5

### Visual-only follow-up
- Move Return the favor from row 224 to row 196, directly below the other right-column list switches. Mana reserve remains at its beta4 coordinates.
- Mark both Diagnostics edit boxes as plain report text. The shared styling pass preserves their font/text colour but skips the inset surface and focus-border decoration. Native selection, Ctrl+C, focus handling, report capture and all addon behavior are unchanged.
- In-game beta4 notes are folded into the beta5 entry, retaining exactly ten versions. No regression tests were run, at the owner's explicit request. The last full run was beta4's 2,676 passes; that is not a new beta5 validation claim. Packaging hashes verify delivery integrity only.

# BuffTap 1.26.4-beta4

### Options layout and copyable diagnostics
- Correct the screenshot-confirmed Nearby collision: the upgrade control no longer shares the social-marker coordinates. Use six compact rows in the existing Player list card, with Return the favor above the bottom Mana reserve control. Other preferences and visibility rules are retained.
- Replace the Diagnostics live FontString with a multiline native EditBox, preserving the bounded scroll viewport and using a hidden FontString for height measurement. Mouse selection and native Ctrl+C are available; Select all focuses/highlights whichever live/captured report is visible. Local typing restores the snapshot rather than editing diagnostics. Focused text is not overwritten by background option redraws; explicit Refresh clears focus and recaptures. The live report path applies existing name redaction without recursively refreshing action selection.
- Remove the Print to chat page button; existing status slash commands are unchanged. Pack Refresh, Select all, Reset metrics, Inspect buffs, Unknown items and Rescan bags into separate bounded action slots, fixing the Inspect/Unknown overlap. The inspector remains included in Full check-up. No clipboard API, game automation or insecure action path was added; copying uses the native editor's keyboard handling.

### Class setup recommendations
- Offer Cleanse for the existing supported cleanse classes and normal Resurrection for Druid, Priest, Paladin and Shaman independently of learned spells or player level. Offer cleanse-first ordering when both are class-applicable, plus SmartShift for Druid/Shaman. These recommendations are checked when reviewed in fresh-character setup; each can be declined and applies only with the selected recommendations. Existing characters see opt-in choices, with review confirmation retained. The explicit recommended-class-setup shortcut includes them in its review.
- `CanConfigureRevive` shares the normal resurrection class catalog without treating an unlearned spell as an unsupported class. Runtime learned/resource/identity/combat gates, old baseline defaults, completed onboarding, all stored choices and secure casting rules are unchanged. No forced onboarding replay or migration.
- Class recommendations precede general appearance/convenience choices, so the fresh player's cleanse/resurrection/ordering/SmartShift choices are visible and applicable on the first review page.
- Validation: strict full mocked Lua 5.1 suite **2,676 passed, 0 failed**, including 37 new layout/copy/setup cases. The new cases verify Nearby coordinate separation and non-overlapping Diagnostics actions in five locales; native EditBox focus/highlight routing for visible main/captured text; selection preservation, editing rejection, refresh, privacy and no-refresh capture; inspector retention in Full check-up; all nine classes with unlearned abilities; first-page application, declining defaults and existing-character review confirmation. The existing long-diagnostics test now measures the hidden sizing FontString. Log: `tests/layout-setup-beta4-release.txt`. No actual WoW rendering or system-clipboard operation was performed by the agent.

# BuffTap 1.26.4-beta3

### Optional maintenance controls
- Add `buffCharges` for Lightning Shield and Water Shield, default off, with explicit 0/1/2 values and Solo/Party/Raid inheritance. Preserve only public nonnegative integer aura applications; zero, missing and restricted values cannot imply depleted charges. A verified positive low count can request a self refresh alongside normal timing. Only the active shield's own spell identity is eligible, so an alternative shield does not trigger replacement. Existing cooldown, resource, aura-confirmation, combat and click-time guards remain authoritative. Current Forever tooltips independently confirm three charges for both shields. No combat prediction, new polling or Inner Fire/poison charge engine.
- Add shared opt-in `nearbyRankUpgrades` and the Nearby control **Offer higher rank buffs**. Within the existing Nearby need scan only, compare a complete readable matching effect against the highest known recipient-compatible rank in the ordinary rank-policy allowlist. Every matching covered effect must be an identified lower rank in that exact family. Same/higher ranks, unknown identities, missing metadata, restricted timing, incomplete scans and group equivalents cannot justify an upgrade. Existing eligibility, policy, priorities, exact-rank macros and click-time reselection apply. Cache identity includes the toggle; temporary scan scope clears on errors. Rank comparison does not prove relative potency after talent bonuses; the game's stronger-effect refusal and existing backoff still apply.

### Diagnostics and onboarding
- Extract the existing class recognition sets into `BuffCoverage`, preserving the `Missing` path, and expose the existing consumable recognition sets for inspection. `BuffInspectorLines` performs one explicit fresh self-aura snapshot, reports readable spell identity/subtext, source unit token, count, remaining time and actual recognition matches. It never changes settings, casts or bindings, and does not refresh action selection. Unknown helpful effects remain informational. Combat returns an unavailable explanation without reusing a stale snapshot. No caster GUID/name lookup or persistent aura history. Partial data is labeled; ranks and counts are never invented.
- Add **Inspect buffs** to the existing Diagnostics capture pane and include the snapshot in Full check-up. Class-appropriate Supplies guidance and a **Set up supplies** shortcut appear on the final onboarding page. Hunters choose their actual ammo; Warlocks can add Soul Shards; reagent classes see group-buff supply guidance. The shortcut completes onboarding and opens existing Supplies controls without enabling warnings or choosing items. The final guide scrolls within its pane; existing returning users are not forced through setup again.
- Compatibility: old settings retain time-only shield refresh and no buff-grade behavior. New fields survive same-class profiles, settings transfer and context preferences; shield class settings are not imported across classes. No existing choices, reminder positions or secure-action rules are migrated.
- Validation: strict mocked Lua 5.1 full runner **2,634 passed, 0 failed**, including 81 new feature cases. After the final class-only visibility refinement, all **86 focused feature cases passed**, including five additional inapplicable-class controls. Final focused execution uses the same harness/fixtures with their unrelated top-level scenario runs omitted; the normal release runner imports the complete module. Logs: `tests/shield-inspector-beta3-release.txt` and `tests/shield-inspector-beta3-final-focused.txt`. Coverage includes indexed/batch count extraction, invalid/secret fields, real UNIT_AURA and PreClick paths, cooldown/combat restrictions, context inheritance, cross-class transfer, fresh-Lua reload, inspection privacy/read-only behavior, actual coverage sets, copyable/full reports, onboarding navigation, rank-upgrade boundaries/cache/revalidation and error-scope cleanup. No live shield/API or upgrade validation claimed. Owner reported Mark rank 2 on a level-1 recipient during beta2 testing; that is one case, not comprehensive rank verification.

# BuffTap 1.26.4-beta2

### Recipient rank eligibility
- `Engine.lua`: separate ordinary ranked recipient requirements from caster learning metadata. The explicit allowlist is Mark of the Wild, Thorns, Arcane Intellect, Dampen Magic, Amplify Magic, Power Word: Fortitude, Divine Spirit, Shadow Protection, Blessing of Might and Blessing of Wisdom. For a catalogued rank in its own family, apply `max(1, RankLevel[id] - 10)` using the existing Forever 70888 client-derived rank record. This replaces the learning-level comparison for those families and preserves Mark's established allowance.
- No new inference of learned ranks. Unrecognized/remapped IDs or missing catalog levels retain the learning-level fallback without an allowance. Self still uses its highest known rank. Restricted, absent and invalid external levels remain ineligible. Candidate ordering, localized exact-rank macros, identity checks and cache invalidation stay in place.
- Group/Greater versions, Kings, Fear Ward, utility spells, shouts and auras retain their existing recipient policy. No saved-variable migration, configuration gating, layout, priority, assignment, event or secure-action redesign. The four beta1 corrections are retained.
- The Classic formula and an independent Forever implementation justify a focused beta, not a claim of comprehensive Forever server verification. CheaperBuffs explicitly requests retesting on the current build; its historical spell table was compared, not copied into runtime. The linked Blizzard-hosted discussion is player discussion, not an official server specification. Representative live boundary casts remain a release gate.
- Validation: strict mocked Lua 5.1 release suite **2,553 passed, 0 failed**, including 134 new recipient-rank cases. All 53 affected fixture levels match the preserved Forever SpellLevels export. Tests cover every exact/below boundary, unknown/remapped/missing data, adjusted learning metadata, ownership, cache/event behavior, 14 excluded families, exact-rank Nearby macros and click-time rejection. An existing Priest ordering fixture now uses a genuinely eligible recipient and Divine Spirit's real learning level. Log: `tests/recipient-ranks-beta2-release.txt`. No live casts claimed.

# BuffTap 1.26.4-beta1

### Corrected audit findings
- `Nearby.lua`: row buttons now inherit `SecureHandlerStateTemplate` alongside `SecureActionButtonTemplate`, connecting the registered combat state to the existing clearing snippet. The earlier tests executed the snippet directly and missed its absent callback wiring. Rows whose state-driver registration errors or explicitly fails remain disarmed, including PreClick. Parent visibility, row layout, ordinary main-button safeguards, macros and GCD/error handling are preserved.
- `Engine.lua`: the affected-recipient group preflight now uses existing recipient policy, including `SelfRecipientAllowed`, so a broadcast cannot bypass `buffSelf=false`. Checks apply to the actual existing subgroup/class bucket; a cast in another raid subgroup remains permitted when the player is outside that affected set.
- Covered recipients outside the missing bucket must also have verifiable applicable buff information. Unavailable/incomplete absence evidence causes single-target fallback. Known-positive equivalent coverage survives an unrelated restricted aura. Known corpses do not require helpful-aura scans. Existing scans/errors are reused within selection, and click-time `RevalidateGroupAction` reuses this selection path. Rank counts, thresholds, assignments and reagent checks are retained; captured diagnostics explain the new blocker.
- `Readiness.lua`: verified Forever Demonic Pact 425464 permits the already-selected different demon while a sacrifice aura is present. Ownership requires a public positive from `C_SpellBook.IsSpellKnown` or `IsPlayerSpell`. Unknown/unlearned ownership retains the existing conservative guard. Sacrifice-to-summon family mappings preserve Imp, Voidwalker, Felhunter and the shared Succubus/Incubus family. Removing Pact or changing the selected family is rechecked at explicit input. Existing shard, movement, identity, cooldown and pet-lifecycle checks remain authoritative. No maintained sacrifice spell, automatic demon preference change or new control.
- Current primary evidence: Forever Pact tooltip and build 70938 Spell records; native state-handler wiring checked against Forever UI mirror commit 3d8abb1da73acd38e412e24fb3f99454a6392346. The separate 425473 wrapper is not used as a capability signal.

### Compatibility and validation
- UI layout, appearance, Solo/Party/Raid inheritance, existing preference order, Manual consumables and all saved-variable formats are preserved. No new event subscription or recurring polling, automatic cast, target or item use.
- Final mocked Lua 5.1 release suite: **2,419 passed, 0 failed**. All 65 audit probes pass, including the five failing acceptance cases from unchanged 1.26.3. Another 33 checks cover native state delivery and ready-state behavior, registration failure, Party/Raid self exclusion, another raid subgroup, healthy/partially readable coverage, corpses, click-time changes, Greater Blessings, all supported sacrifice/demon pairings, Pact ownership/removal and retained shard requirements. New module is imported by the release runner.
- No live Forever validation claimed. Native combat delivery and passive-talent ownership need owner testing; unknown Pact information continues to suppress potentially destructive resummons.

# BuffTap 1.26.3

### Nearby confirmations and timing

- Replace the rectangular native cooldown presentation with a horizontal, right-anchored StatusBar shade that reveals the successful Nearby confirmation left to right. Raise black shade opacity from 0.18 to 0.22. The visual uses the absolute cooldown deadline, so row redraws do not restart it. Its brief visual-only OnUpdate stops at expiry or hiding; no action selection or secure attributes are written by the animation.
- Remove the 0.6-second minimum confirmation tail, invented 1.5-second fallback, two-second pending-input lock and 20/30ms expiry padding. Unknown timing grants no fabricated cooldown; pending deduplication is limited to the same input frame. Each later physical press reads live cooldown state. Future public timing blocks Nearby target/restore macros even when `isActive=false`, avoiding accidental queuing across restored targets. Independent real spell cooldowns still apply. No settings migration.
- Nearby result errors now require the exact player spell failure and unchanged recipient identity; a global UI error alone cannot mark the row failed. Failure callbacks are bound to the original result, canceled on a new attempt or success, and a matching success can replace a provisional failure. Real failures retain their reasons and immediate explicit retry. This reproduces misleading error correlation and contradictory cooldown-flag paths, not the owner's exact live range incident.
- Validation: the final beta2 full suite passed **2,321 mocked Lua 5.1 scenarios, 0 failed**, including nine new sweep/timing/error-correlation cases. The mock supplies actual cooldown evidence on successful Nearby casts instead of relying on the removed production fallback. Coverage checks absolute progress, redraws, hide/expiry cleanup, a one-second GCD confirmed near its end, absent timing, ready input without a fixed lock, contradictory cooldown flags and both error-event orders. The owner confirmed the initial visible effect and authorized publication; the exact live range incident remains unconfirmed.

### Class spells and consumables
- `Cleanse.lua`: added all five normal Druid Revive ranks (437138, 1237948–1237951), independent of the optional Rebirth setting. Selection prefers the highest known normal rank. The omission was confirmed against preserved Forever class/rank/effect tables; other normal resurrection classes have complete ranks in those inputs.
- Out-of-range corpse candidates now survive ordinary selection and join the existing conditional range heartbeat. The heartbeat validates resurrection recipients with corpse eligibility rather than the living-buff filter, including while a self buff is displayed. No new permanent poll, weakened identity check or combat action.
- `SmartShift.lua`: validated cleanse input can capture the current form for self, group and Nearby recipients. Exact player spell success and confirmed form exit are still required; failure grants no return. Ordinary foreign-recipient buffs remain excluded. Every return requires another hardware action.
- `Nearby.lua` and main PreClick block repeat target/restore payloads during a real active cooldown or duplicate input in the same frame. Successful confirmations use the horizontal sweep above. A bounded expiry timer refreshes readiness; it never casts. Real failures remain visible and immediately retryable. The guard also works with result display disabled.
- `ConsumableData.lua`: append 15 foods to preserve existing Auto order. Add exact food-use and Well Fed mappings, including legacy Stamina/Spirit, seasonal, skill and regional food. Exclude stale Lightning in a Bottle data after a fresh Forever tooltip shows no Well Fed. Preserve region restrictions in descriptions and do not invent an XP bonus for legacy foods. Thanks to **shaunpearsondev**, GitHub #5, for reporting Goblin Deviled Clams.
- No saved-variable migration or preference reset. Class-applicable options remain configurable before learning. Existing secure-action and combat restrictions remain in force.
- `Catalog.lua` and generator specification: add Druid Track Humanoids and Warlock Sense Demons to ahead-of-learning tracking choices. Dynamic runtime discovery already supported the learned spells, but the fallback list omitted them. Preserve default-off behavior and the existing Druid Cat Form guard. Supplemental facts were rechecked against refreshed 70888 tables matching the generated manifest's source hashes.

### Audit and validation
- Repeatable tools review 3,037 class-mask spell records across nine classes in refreshed build 70888 tables, producing 268 maintenance/resurrection/dispel candidates, and 605 consumable candidates against the 207-item visible whitelist. All 207 use-spell mappings match fresh Forever tooltips. There were 378 successful tooltip fetches and 22 failed candidate requests; none of the shipped whitelist requests failed. Candidate records are not proof of current trainability or acquisition. Reports distinguish triggered effects, retired families, separate helpers, non-maintenance abilities and unresolved legacy records.
- The full final beta suite above includes all 62 class/consumable review scenarios. Final 1.26.3 identity passed **367 focused scenarios, 0 failed**. All 15 Mage item/use/enchant/weapon mappings also match reviewed evidence. Release runtime matches the tested beta2 except version identity. No comprehensive live-client validation is claimed. See the development audit reports for evidence limits and deferred candidates.

# BuffTap 1.26.2

### Fixed
- Fixed a sound-notification edge case introduced by 1.26.1's smooth-buffing changes. Reproduced extra sounds when ordinary class-buff selection changes and when the 0.75s self-buff aura grace temporarily clears the action before it returns. Existing sound eligibility treated these as new reminders whenever `soundInterval` allowed.
- Validated ordinary buff input starts/renews a four-second in-memory quiet window. `Commit` suppresses ordinary class-buff reminder sounds during that active sequence, including nil-action gaps. No input means original alert behavior; inactivity expiry and combat/zone boundaries restore normal alerts. SmartShift stays silent, and cleanse/revive/items/manual reminders retain their existing sound rules. No settings migration, timers, polling or secure-action eligibility changes.

### Validation
- Full mocked Lua 5.1 beta release run: **2,250 passed, 0 failed**, including seven new queue-sound cases. Final 1.26.2 identity passed **97 focused checks, 0 failed**; runtime behavior is unchanged from the tested beta. Two original sound regressions failed on 1.26.1 and pass with the fix; coverage also checks initial/new-need alerts, independent cleanse sounds, sequences lasting more than five seconds and combat reset. No new live-client verification claimed.

# BuffTap 1.26.1

### Added
- GCD-aware ordinary class-buff and SmartShift preparation keeps a verified secure action and override binding available during a confirmed global cooldown. `SPELL_UPDATE_COOLDOWN` captures per-spell public start/duration evidence because Forever limits trust in `isOnGCD` to that event. Every later validation, including PreClick, requires matching timing and a fresh public zero from `GetSpellCooldownDuration(id,true):GetRemainingDuration()`. Independent cooldowns, missing APIs and restricted data retain conservative waiting behavior. Item, tracking, weapon and readiness cooldown permissions are unchanged.
- A forward GCD sweep takes precedence over the optional reverse rebuff sweep and clears at expiry through the existing exact wake. No second completion alert, polling loop or preference migration.
- A passive main-reminder status explains mana shortages and configured reserve pauses while keeping `B.action=nil`, no secure payload, no override binding and no sound/effects. Existing power events restore selection. Visibility preferences, other pauses and secure combat hiding remain enforced; non-mana classes say power.

### Fixed
- SmartShift now observes its intent form's cooldown before success/form-exit events arrive, but still grants restoration only after both confirmations and all runtime guards pass. Confirmation observes the original exact player spell/GUID independently of the shared general attempt, with the existing four-second bound. Rapid pre-exit input preserves the first intent; a later repeated failure cannot revoke an already confirmed success.
- Restore usability failures set the existing power/mana flags so resource recovery triggers a refresh. Validated restoration precedes optional consumables, tracking, weapons, readiness and ordinary Nearby buffs, reserving the binding during a cooldown wait. Class/group/target spell maintenance and cleanse/revive precedence remain unchanged. Check-up reports pending SmartShift stages.
- A successful self-cast confirmation starts a 0.75-second same-spell aura-settling deferral, keyed by readable self GUID. Captured-attempt and confirmation maps are bounded to 16 entries, expire, and clear on combat. Confirmation refreshes the player's aura cache and existing three-second fresh-scan window. This does not mark an aura present: the spell becomes retryable after expiry if still missing. Other spell IDs, recipients and group casts are unaffected; failed/unconfirmed clicks grant no deferral.
- Preserved all settings, refresh thresholds and priorities. No SavedVariables migration, automatic casts or new permanent polling. Consolidated internal beta notes into one current release while retaining ten in-game versions.
- Thanks to **Mechrite** for the responsiveness suggestion and **jimbo1111** for reporting repeated Thorns.

### Validation and limits
- Final 1.26.1 mocked Lua 5.1 release suite: **2,243 passed, 0 failed**. All 15 Mage item/use/enchant/weapon mappings match reviewed catalog evidence. Runtime Lua was compared with the owner-tested beta6 archive and matches apart from release identity; in-game notes retain exactly ten entries and both contributor credits.
- Owner confirmed the beta6 live smoke test: rapid self-buffing, low mana/recovery, SmartShift return with Nearby enabled and settings surviving reload. This does not establish every class, latency or server-event combination.
- The delayed-aura duplicate path was reproduced in mocks; jimbo1111's exact live incident remains unconfirmed. The safeguard mitigates that window without claiming every possible repeat cast is eliminated. The timing probe measured earlier action preparation, not a reduction in the game's GCD or guaranteed casting throughput.

# BuffTap 1.26.0

### Added
- Registered the timing information heading with the existing theme label tracking, so its section highlight follows the selected accent like other headings. Cosmetic follow-up only; no regression-suite rerun.
- Replaced the visible shared rebuff slider with a Default refresh timings information panel. It explains one effective timer per buff and the actual duration rules (45 seconds, five minutes for durations of at least 45 minutes, missing-only below two minutes/untimed). Reset default timings restores the selected context's 45-second baseline and clears per-buff overrides without altering enables/priorities. Existing legacy baselines remain unchanged unless explicitly reset; per-row edits remain available. Removed the unused shared slider factory and updated its superseded UI regression.
- `ManualConsumables.lua`: independent secure click-only buttons for Manual Food, Flask, Elixirs and Utility. Auto remains the default; Manual families never enter `B.action` or override bindings. Exact item identity, current stock, metadata/use spell, level, cooldown, aura state, settings and pending/quarantined effects are revalidated before preparation and click.
- `consumableModes` persists per visible family in profiles and situation settings; checklist children inherit it. Missing values retain Auto. No destructive saved-variable migration, new catalog, polling loop or insecure item-use calls.
- Centered 22px rows support eight clickable effects plus an informational overflow list for bag use. Unknown stock/effects remain uncertain, active effects leave the strip, and the strip survives a hidden/idle main reminder. Secure drivers revoke unsafe payloads without restoring stale actions.
- Optional shared detached anchor and an unprotected edit-mode mover, available even without active items. One Move reminders action positions reminders; Done saves and Cancel rolls all coordinates back to the session baseline. Reset look & position replaces Center and preserves consumable selections/modes.
- Appearance pages order Layout, Visible labels, Text; label position lives under Visible labels. Taller Camping/Supplies panes, themed previews, centered timer, top-right group count and a labeled Manual sample strip improve consistency. Modern Soft/Pulse uses rounded inner artwork contours and a square feathered outside; Classic retains game art. Camping applies its icon style before its effect. Extra Camping/Supplies backdrops were removed.
- Thanks to **Xprit44** for suggesting manual reminders without accidental mouse-wheel consumption.

### Fixed in the pre-ship review
- **Consumables row overlap (`Options.lua`):** selected checklist thumbnails and overflow now occupy the bottom-left footer, separate from the Manual/ticked summary; timing label/slider move to the bottom-right. Native row heights and saved settings are unchanged. Added a geometry regression for the full twelve-icon strip.
- **Master-off click gap (`Engine.lua`):** `ActionPauseReason` now checks the master switch at the shared click boundary, preventing a prepared action from firing before a queued settings refresh revokes it.
- **SmartShift fallback (`SmartShift.lua`):** return actions now respect master disable, loading/session/resting/edit pauses, current situation and readable self identity. A raw form index must confirm caster form; unreadable metadata or another active form cannot authorize a return. Casting/channeling and unconfirmed/active cooldowns block it. A bounded wake schedules the cooldown end. Druid and Shaman cases are tested.
- **Manual threshold scheduling (`ManualConsumables.lua`):** the read-only projection returns the earliest future threshold even when all effects are active and no icon is shown. The update path retains that wake without adding polling or display-time use confirmation.
- **Incomplete appearance reset (`Options.lua`, `OptionsRefinement.lua`):** reset also restores Classic icon style, split placement, swipe/range and urgency/flash options; Camping resets its icon style too.

### Validation and limits
- Late Consumables footer correction: 171 focused scenarios passed, zero failed across review/appearance/Manual modules, after the full run below.
- Full mocked Lua 5.1 release suite: **2,162 passed, zero failed**, including 17 new pre-ship review scenarios. All 15 Mage item/use/enchant/weapon mappings match reviewed offline evidence. See `RELEASE-REVIEW-1.26.0-beta2.md`.
- The owner visually tested earlier beta layouts and glow revisions. Native secure execution across every class, raid and item combination has not been established by these mocked checks. Final SmartShift, timing and edit-mode smoke tests remain recommended.
- Eight Manual effects are clickable; overflow is a named informational list for bag use. Buffs unavailable under Forever combat restrictions are never inferred missing. Manual food does not add Auto food's global eating gate to class readiness. Supplies tracking/alert behavior is unchanged; appearance is updated.
- Final release identity is 1.26.0, so previously read beta notes become unread again. Publication approved by the owner on 2026-11-17; beta wording removed from current in-game notes and package metadata.

# BuffTap 1.25.0

### Added
- `SmartShift.lua`: opt-in Druid and Ghost Wolf restoration through the existing secure button. Captures the form on a BuffTap self-buff attempt, requires correlated success and form exit, defers restoration until ordinary work is complete, and revalidates before use. Restoration is silent; active forms, combat, mounting and stale state cannot trigger a toggle.
- Food and Elixir category dropdowns and secondary benefit text in the existing picker. Categories use curated static notes and do not alter inventory eligibility, item actions, Auto semantics or elixir stacking.
- Adaptive Paladin class/role blessing orders, stored with class-profile settings. Accepted orders evaluate learned spells at selection time; fixed manual choices remain authoritative. Shaman setup writes the actual main-hand preference without enabling application. Added optional Atrophic, Numbing, Sebacious and Occult I/II poison mappings.

### Fixed
- Cleanse/resurrection preferences can be configured before spells are learned. Unsupported classes retain explanatory status; Abolish is shown only for classes with an Abolish spell. Runtime learned-spell and secure-action eligibility remains unchanged.
- Setup pagination preserves selections across pages. Review requires confirmation, offers an ordinary profile backup and applies all selected pages. Existing recommendations can be reviewed without resetting setup history. Removed the unsupported assertion that custom settings already match recommendations.
- SmartShift settings occupy their own area. Corrected frame parenting to use the settings frame rather than a decorative texture. The UI mock now rejects texture parents.
- Corrected a Windows-only test source-path escape error.

### Compatibility and known limits
- Fresh resurrection defaults to off; saved true/false values are preserved. New class fields participate in profile copy/export/import. No game SavedVariables files are edited by installation.
- Installation and settings have been exercised by the owner. This is not a claim of full live-client class, raid or SmartShift validation. High-level behavior is covered through mocked APIs.
- Executed mocked regression suite: 2,092 passed, zero failed. The final focused run after setup preview/localization additions passed 107 scenarios, zero failed. See VERIFICATION-1.25.0.md for commands and live-test limits. Publication approved by the owner on 2026-11-16.

# BuffTap 1.24.8

### Fixed
- **Independent cleanse and resurrection events (`BuffTap.lua`):** `PLAYER_TARGET_CHANGED` returned early unless Target buffs (`friendlyTarget`) was on, and `IsWatchedUnit()` watched party and raid tokens only for group buffing or the Soulstone helper, so Cleanse and Resurrection (separate options) missed target changes and group aura updates. New `WatchesMaintenanceTarget()` and `WatchesMaintenanceGroup()` also count Cleanse (target, group) and Resurrection (target, group, gated on `CanRevive()` because `reviveEnabled` and `reviveTarget` default to on for every class). A class with nothing target-dependent still ignores target changes, so the idle-event and timer tests keep their meaning. `UNIT_AURA` still refreshes only for watched units.
- **Death state for standalone resurrection (`BuffTap.lua`):** `UNIT_HEALTH` is now registered through the existing protected loop (a rejected registration lands in `unsupportedEvents`; no polling fallback). The handler does cheap token checks first, then for a group member or the target compares `UnitGUID` plus `UnitIsDead` with a one-entry-per-token cache (`reviveDeathStates`) and calls `RequestRefresh` only when the GUID or dead state changed, so ordinary health changes cause no refreshes. The cache is cleared on `GROUP_ROSTER_UPDATE`, `PLAYER_ENTERING_WORLD` and `ZONE_CHANGED_NEW_AREA`; an unreadable GUID or death state does nothing. No secure writes occur in this path.
- **Cleanse identity and click-time checks (`Cleanse.lua`, `BuffTap.lua`):** `BuildCleanseAction()` needs one readable public GUID (also for the player) and stores it; `tryUnit()` records the scope (`self`, `group`, `target`, `nearby`). `ValidateCleanse()` now also requires a readable saved GUID (nil is never identity), the addon and cleanse enabled and no pause, `CleanseScopeAllowed()` (same scope rules as selection: group token shape, target is a non-grouped assistable player, PvP guard, block list, Nearby tracking and pause), the type still enabled and learned, and re-runs `CleanseNeed()` so the first eligible debuff must be the same one (spell ID when known; by name only when no ID was recorded) with the same spell, which also covers Never cleanse and the 3-second expiry cut-off. If the priority changed the click cancels and a refresh follows; it never casts a different cleanse. The Nearby click path validates before arming the macro, so no macro is set for an unverified recipient.
- **Resurrection identity and scope (`Cleanse.lua`):** `BuildReviveAction()` reads one GUID (nil means no action) and stores `scope` (`group` or `target`) and `key="revive:"..guid`. `ValidateRevive()` re-checks the addon and option, pause, saved GUID, the scope's own toggle and token or target shape, that the spell is still the normal resurrection or the enabled Druid Rebirth, then `reviveTargetOk()` (connection, dead not ghost, incoming resurrection, block list, PvP). The range policy is unchanged.

### Changed
- **Shared reports hide remembered players (`Extras.lua`):** the name hider for the Full check-up and other reports now also covers the saved Soulstone and Oath players (first name, surname and punctuation parts), even when they are not in the group. Settings exports are unchanged (they already leave these out, and player IDs).
- **Soulstone strings translated (`Readiness.lua`, `Locales/`):** the fixed notices and reasons ("not in your group", "dead, offline or out of range", ambiguous, no assigned player, the strict-assignment notice and the raid notice) now go through `B:Text()` with translations in deDE, esES, frFR and ptBR; placeholder counts are unchanged and a test renders each locale.

### Tests
- New `test_maintenance_1248.py` (27 scenarios) through the real event dispatcher and `PreClick`: target and group events for cleanse and resurrection alone, idle and gated cases, `UNIT_HEALTH` transitions with no refresh storm and ignored units, unreadable GUID at selection and at click, changed recipient, nil-ID debuffs, replaced debuff, Never cleanse after selection, type and scope off, PvP flip, resurrection scope, disconnect, incoming resurrection and Rebirth off, report redaction (name and ID), and locale rendering. Deliberately removing the event predicates or the `CleanseNeed` re-check made the matching tests fail.
- Full suite (`BT_KEEP_GOING=1 python tests/run_release.py`): 2079 scenarios passed, 0 failed, exit 0 (mocked game API).

### Known limits
- Range is unchanged: an unknown cleanse or resurrection range still counts as usable until Forever samples exist.
- A party Soulstone already on anyone still counts as coverage before an assigned player is chosen; this release does not change that.
- Nothing here has been checked in the Forever client beyond the mocked game API.

---

# BuffTap 1.24.7

### Fixed
- **Soulstone assignment is strict in a party (`Readiness.lua`, `SoulstoneTarget`, `SoulstoneCandidate`):** with `soulstoneParty="assigned"`, `SoulstoneAssignedUnit()` returning no unit used to fall through to the Healer pick and then to the player. It now returns no target together with the reason, and `SoulstoneCandidate()` produces the existing manual-notice action ("Soulstone not placed", `manual=true`, no `secureType`, no item, unit or binding installed). Healer mode still falls back to self, Me mode stays self, and raids were already strict. The saved mode and GUID are never rewritten; when the assigned GUID is eligible again the next action targets it. `SoulstoneCoverage()` and the click-time GUID check in `PreClick` are unchanged. The Soulstone target tooltip (and its four translations) no longer promises a fallback.
- **Resurrection needs a confirmed connection (`Cleanse.lua`, `reviveTargetOk`):** `UnitIsConnected(unit)==false` became `~=true`, so an unreadable or `nil` result no longer counts as connected. This matches `stoneEligible()` and `TargetEligible()`.
- **Competing manual notices (`Engine.lua`, `Select`):** a manual weapon-coating notice is now held like the manual class-readiness notice instead of being returned immediately. Order: castable actions first (buffs, cleanse and revive, castable readiness, consumables, tracking, castable weapon work, Nearby), then the manual pet or readiness notice, then the manual weapon notice. Dismissed and disabled reminders are filtered as before.

### Changed
- **Checklist status (`Consumables.lua`, `Options.lua`):** new read-only `ConsumableChecklistExplanation()` for the Elixirs and Utility rows, shown in the row tooltip when it opens (no timers, events or combat reads). It reports selected, active, expiring, missing, out of stock, paused and unknown counts and one line per selected effect (up to seven), using `ConsumableFamilyState()` and the cached item counts. Sources that share one effect count together, an unreadable bag count is reported as unknown rather than out of stock, and a failed effect is shown as paused with the Retry reminders hint. The tooltip for another setup being edited still says live status is not shown. Selection, thresholds, aura matching and item use are unchanged. New strings are in all four translated locales.

### Tests
- New and replaced coverage: `test_warlock_stones.py` and `test_warlock_review.py` (the three party fallback assertions were replaced by strict manual-notice assertions; GUID absent, GUID on another unit token, Healer and Me modes), `test_food_status.py` (checklist states, combat, unreadable auras, other-setup tooltip, no state change from opening it), `test_revive.py` (connection state `nil`, `false`, `true`; range characterization), `test_readiness.py` (manual pet over manual weapon, castable work over manual notices).
- The 1.24.6 test changes, including `test_food_status.py`, were not in the 1.24.6 commit; they are committed with this release. The 2035 figure quoted for 1.24.6 came from a local run of the uncommitted tree.
- Full suite (`BT_KEEP_GOING=1 python tests/run_release.py`): 2052 scenarios passed, 0 failed (mocked game API). `tools/verify_mage_catalog.py` was not run in this session.

### Known limits
- Range: `SpellRange()` can return `nil` (unknown) and cleanse and revive still treat that as usable. Changing it to require a confirmed `true` needs Forever client checks (Priest, Paladin, Shaman and Druid resurrection, each cleanse type, near and far) before it can ship; a test now documents the current behaviour.
- Nothing here has been checked in the Forever client beyond the mocked game API.

---

# BuffTap 1.24.6

### Fixed
- **Resurrection eligibility (`Cleanse.lua`, `reviveTargetOk`):** the incoming-resurrection probe was `A.Call(UnitHasIncomingResurrection,unit)~=false`. `A.Call` returns only the value, and the game answers `nil` (not `false`) when no resurrection is incoming, so `nil~=false` rejected every eligible dead player on those builds. A new local `incomingResurrection()` calls the API under `pcall`: `true` blocks, `false` or a successful `nil` allows, and a failed call, a secret value or an unexpected type stays unknown and still blocks. A client without the API keeps the old behaviour (allowed).
- **Soulstone recipient identity (`Readiness.lua`, `Engine.lua`, `Profiles.lua`, `Options.lua`):** an assignment was stored only as a name built from `UnitName` plus the client surname separator (`Constants.CharacterNameSeparatorConsts`), so it could not be saved when that constant was missing and could not tell two players with the same given name apart. New assignments also store the target's validated `Player-` GUID in `soulstoneAssignedGUID` (alongside the display text in `soulstoneAssigned`). `SoulstoneAssignedUnit()` resolves a stored GUID against the current roster first and never falls back to a same-named player: if that GUID is not in the group the result is "not in your group". Legacy name-only assignments keep their old matching and fail closed when ambiguous. Both fields are cleared by Clear, validated in `InitDB` (a GUID must start with `Player-`, contain no control characters or `|`, and needs a name beside it), are class-only on import (skipped on another class), and are left out of the privacy-filtered Full check-up like `soulstoneAssigned`. Importing an older export that has the name but no GUID clears the stored GUID so a stale ID never sits beside a new name. Saving from the current target is refused in combat or without a readable GUID.

### Changed
- **Battleground tracking (`Engine.lua`, `Select`):** the `BGSelfMode()` branch returned `SelectBGSelf()` directly, which also skipped `TrackingAction()`. It now falls through to `TrackingAction()` when no self buff is actionable and the player is out of combat. Tracking reads the minimap tracking list, not unit auras, so the aura-secrecy rules are unchanged: group, consumable, weapon and Nearby checks stay disabled in battlegrounds, and an unreadable tracking list still offers nothing.
- **Readiness before optional consumables (`Engine.lua`, `Select`):** `SelectReadiness()` is now called once, before consumables, instead of after tracking. A castable result (pet recovery, Healthstone, Soulstone) is returned immediately; a manual-only result is held and returned only after consumables, tracking, weapon reminders and the Nearby fallback found nothing. Previously a Warlock needing a Healthstone, or a pet to summon, waited behind optional food and flasks, and a manual pet notice sat ahead of castable weapon work. Ordinary class, group and friendly-target buffs still come first. No new setting; `Readiness.lua` is unchanged.
- **Cleanse and revive order (`Cleanse.lua`, `Engine.lua`, `Profiles.lua`):** the two stacked `B:Select()` wrappers became one wrapper with a shared `maintenancePick()` helper. New `cleanseFirst` (default `false`, so existing behaviour is the default) swaps the order; either action still falls through to the other, then to the normal selector. Added to the class-settings export and to the class-spell list (not imported onto another class). Cleanse page: new "Cleanse before resurrection" checkbox, shown only for a class that can both cleanse and resurrect. The Validate wrappers and secure payloads are untouched.
- **Informational status text (`Consumables.lua`, `Options.lua`, `Helpers.lua`, `BuffTap.lua`):** added `FoodPreferenceStatus()` (states: compatible, different, ambiguous, missing, auto, disabled, unknown), `ConsumableExplanation()` and `TrackingStatusText()`. They only produce text, shown in the food picker note, the Consumables row tooltip and the tracking dropdown tooltip, and are built when the tooltip opens (no timers, no events, no combat reads). `ConsumableFamilyState()` and `ValidateConsumable()` are unchanged: any recognised Well Fed effect still satisfies the food family, a mismatch never selects or replaces anything, and the text never claims the exact meal because several items share one effect ID. Live buff state is only shown for the current setup. Diagnostics gained two lines (tracking following the minimap, an effect that was not detected). New strings are in all four translated locales.

### Compatibility and migration
- New saved keys: `cleanseFirst` and `soulstoneAssignedGUID`. Existing saved data loads unchanged (revive first; Soulstone assignments made before this version stay name-based until chosen again from the target).
- No automatic casting or item use was added; every action still needs the player's click or binding.

### Tests
- `test_revive.py`: incoming resurrection `nil`, `true`, `false`, error, odd value and missing API; cleanse/revive order both ways and defaults; checkbox visibility, save and export/import.
- `test_bg_self.py`: tracking in a battleground when off, active and unreadable.
- `test_warlock_stones.py`, `test_warlock_review.py`: saving without the separator constant, same-named players, player leaving, roster token change, invalid and name-less GUIDs.
- `test_readiness.py`: castable readiness ahead of food, manual notice not blocking castable food, manual notice when nothing else remains.
- `test_food_status.py` (new): food status states and explanation texts.
- Full suite: 2035 scenarios passed, 0 failed (mocked game API). The test changes listed here were not committed with this release; they were added to the repository in 1.24.7.

### Known limits
- Cleanse and resurrection range checks still treat an unknown range result as usable. Whether Forever reports range for these spells has not been probed in game, so this is unchanged.
- None of the above has been checked in the Forever client yet beyond the mocked game API.

---

# BuffTap 1.24.5

### Fixed: tracking state and preference persistence
- Replaced the legacy gathering-only saved-ID validator in `Engine.lua` with bounded, integral spell-ID validation. Class tracking selections, including Hunter and Paladin tracking, now persist through database initialization, reload and profile operations; runtime spellbook/trackability checks remain separate from saved-setting normalization.
- Reworked minimap tracking reconciliation in `Helpers.lua` and `BuffTap.lua`: `MINIMAP_UPDATE_TRACKING` schedules a debounced update, prevents the previously preferred tracker from being re-armed while the client settles, and refreshes the secure action only after the selection is reconciled.
- Reconcile tracking again when the helper is enabled, after post-login/loading settling, and following `PLAYER_REGEN_ENABLED` when a switch occurred during combat. Maintain the last preference when no primary tracker is currently active; independent Find Treasure tracking remains separate.

### Fixed: inventory, privacy and defensive data handling
- Restricted `weaponSkipEmpty` suppression in `WeaponCoatings.lua` to ordinary coatings (oils/sharpening stones) and Rogue poisons. Mage scroll and Warlock stone readiness still produce their normal out-of-stock reminders.
- Extended privacy-filtered `ExportSettings(true)` in `Profiles.lua` to omit `blessingSaved`, `oathAssigned` and `soulstoneAssigned`, as well as the previously excluded blacklist identities. Explicit user-requested settings exports preserve class settings. This specifically affects shareable Full check-up reports, not normal gameplay preferences.
- Hardened `NormalizeBlessingAssignments()` for imported `blessingSaved` tables: validate Player GUIDs, recognized classes and blessing choices, remove unsafe name markup and invalid records, sort keys deterministically and cap accepted records at 200.
- Corrected the Full check-up's instance-type diagnostic by collecting both results of `IsInInstance()` through a protected multi-return call instead of the single-value `A.Call` helper.

### Compatibility and validation notes
- The release retains the existing secure-action architecture and does not introduce automatic spellcasting. Tracking still requires a user click/binding.
- Covered by regression tests in `test_helpers.py`, `test_player_exceptions.py` and `test_weapons.py`.

---

# BuffTap 1.24.4

### Changed: dedicated Supplies configuration page
- Promoted Supplies from the Consumables page's internal view switch to its own sidebar tab and settings panel. `Options.lua` defines the additional page at internal index 15 and inserts it immediately after Consumables in the visible navigation order; the global UI now contains 15 page definitions.
- Routed entry points such as `ShowSuppliesOptions()` to the new page; updated `OptionsRefinement.lua` page titles, descriptions, header controls, Customize look shortcut and Supply appearance navigation accordingly.
- Separated navigation-status lights: the Consumables indicator now reflects `consumablesEnabled` alone, while Supplies reflects `suppliesEnabled`, removing the previous combined active state.
- Removed the obsolete Consumables/Supplies subview switch; expanded available Consumables content space and adjusted controls and coordinates on Supplies. The consumable item picker now closes when navigating away from Consumables.
- Updated the bundled locale files and affected options, navigation, profile, camping and Supplies tests for the revised page structure.

### Compatibility
- Existing tracked supply IDs, thresholds, warning preferences, icon styling and positions remain in their saved-variable keys. This is a UI/navigation migration, not a reset of user preferences.
- The main consumable application queue is unchanged by the page separation.

---

# BuffTap 1.24.3

### Added: class-aware minimap tracking
- Expanded `Helpers.lua` tracking discovery from three gathering spell IDs to learned, spell-backed entries exposed by `C_Minimap.GetNumTrackingTypes()` / `GetTrackingInfo()`, including class-specific tracking such as Hunter tracking and Paladin Sense Undead.
- Added `TrackingChoices()` to combine the active/learned minimap list with eligible curated-but-unlearned spellbook catalog entries, allowing a preference to be selected before its ability is trained.
- Replaced the three hard-coded tracking buttons with an icon-bearing, scrollable selector in Helpers. Added `helperTrackingFollow` (default on): after a minimap-menu change, the selected primary tracking spell becomes BuffTap's preferred tracker instead of being immediately replaced. Dwarf Find Treasure stays on its own independent toggle.
- Added a Druid Track Humanoids guard: only offer that reminder while in Cat Form (`GetShapeshiftFormID()==1`). Tracking choice persistence and event-race issues in this first implementation were subsequently corrected in **1.24.5**.

### Changed: weapon stock and untimed buffs
- Added the `weaponSkipEmpty` preference and Weapons-page control to omit reminders for out-of-stock weapon consumables; persisted it in class-settings import/export. The initial condition was broader than intended; **1.24.5** narrowed it so class-created Mage/Warlock items remain eligible for their normal reminders.
- Marked until-cancelled auras and aspects as `noTimer` / `permanent` in `Catalog.lua`, including Trueshot Aura, Shadowform and Soul Link. The Buffs settings display now shows an untimed state rather than a nonfunctional rebuff slider.
- Resolved overlapping Resurrection controls for Druids without a learned resurrection spell. The UI conditionally shows Rebirth options or a single not-yet-learned note.

### Compatibility
- `helperTrackingFollow` and `weaponSkipEmpty` are incorporated into the saved class-specific settings schema. The implementation reads player-selected tracking but never performs timer-driven, automatic tracking casts.

- Thanks to waggz81 for the tracking idea and the Rebirth report, and a big shoutout to noci__, who has been with BuffTap since the beta, for the weapon idea.

---

# BuffTap 1.24.2

### Fixed: secure item use and blessing resolution
- For self-maintenance consumables, `BuffTap.lua` now writes `unit="player"` alongside secure item attributes and verifies that `type1`, `item` and `unit` match before the action is offered. This prevents a targetable Juju or Crystal from unintentionally using an arbitrary selected friendly target; weapon-item actions retain their distinct handling.
- Corrected context-specific Paladin blessing exceptions: `GetBlessingPlayer()` now returns no override if the requested Party/Raid choice does not exist, so a Raid-only saved choice cannot suppress Party healer/tank role preferences, or vice versa.
- Kept the per-class remembered-player editor accessible even when no player of that class currently appears in the group, allowing absent remembered records to be inspected and removed.
- Corrected retrieval of the second `UnitClass()` return when persisting remembered blessings, instead of relying on the first-value-only API wrapper.

### Fixed: settings export/import and layout
- Suppressed `blessingSaved` in privacy-filtered Full check-up settings exports while retaining it in explicit profile exports. **This version did not yet exclude Oath/Soulstone assignment identities; that was extended in 1.24.5.**
- Added `blessingSelf` and `blessingSaved` to the class-spell exclusion rules so Paladin-specific player exceptions cannot be imported unintentionally onto another class.
- Corrected the Supplies page's overlapping master warning/icon checkbox positions and synchronized the root and bundled READMEs.

### Tests
- Regression coverage for Party-only and Raid-only exceptions, remembered absent players and cross-class imports. Live Forever behaviour of the secure item target was not separately verified in game.

---

# BuffTap 1.24.1

### Added: persistent Paladin per-player blessing exceptions
- Added `blessingSelf`: the Paladin's personal blessing exception now persists across sessions, independently for the Party and Raid contexts.
- Added opt-in `blessingSaved`, keyed by recipient GUID, for retaining other players' blessing exceptions across sessions. Unremembered exceptions remain session-scoped. Saving and forgetting a player invalidates relevant aura checks and refreshes recommendations.
- Expanded the Groups player-exception editor with **Remember** controls for current members and a greyed-out display with **Remove** for absent remembered members. Display names preserve WoW Forever surname information when available.
- Added the new fields to the class-specific settings export/profile schema. Context precedence and absent-player management received follow-up corrections in **1.24.2**, and imported-data sanitization in **1.24.5**.

- Thanks to Misketadam for the report.

---

# BuffTap 1.24.0

### Added: curated specialty utility consumables
- Extended `ConsumableData.lua`'s utility checklist with Magical Awareness source items (Elemental Attractor and Arcane Censer), Spirit/Sheen/Swiftness of Zanza, Juju Power/Might/Guile/Ember/Chill, Blasted Lands stat consumables, Crystal Force/Ward and Dire Maul drinks.
- Extended `MakeChecklist(parent,prefix,lines,sharedLines)` so distinct item IDs may be alternative sources of the same recognized effect. Magical Awareness can be refreshed from either carried source; Zanza choices are mutually exclusive as a replacement line. Existing same-effect Firewaters retain their shared-line behaviour.
- Retained conservative curated item mapping and effect-pause behaviour. New utility entries were registered with Forever on-use spell IDs as expected aura IDs; if the expected buff isn't observed after use, the reminder is paused rather than repeatedly consuming items. The aura IDs have not all been verified in game.
- Excluded intentionally short/combat-only Juju Flurry/Juju Escape, Flask of Petrification, Predatory Senses, targetable Crystal Spire and zone-specific Winterspring Shrouding from automatic maintenance. The comprehensive external consumables research catalog is broader than the application's active whitelist.

### Fixed: Supplies and configuration portability
- Kept Supplies inventory counts fresh when warning delivery is disabled by invalidating the stock cache on relevant bag/item events, while not producing alerts. The Supplies list remains readable in the options window.
- Added a repeating alpha-animation group for the live Supplies icon's Pulse effect, matching the functioning preview rather than leaving the live glow static.
- Extended the class-settings schema to include `supplyCustom`, `supplyReminder`, `supplyAnywhere` and picker preferences. Extended shared profile appearance serialization for the Supplies reminder's size, position, text formatting, icon style and effects.

- Thanks to Lufia_TM for the Elemental Attractor request.

---

# BuffTap 1.23.0

### Added: independently maintained elixirs and utility buffs
- Converted the previously single-choice elixir and utility families into checklists. `MakeChecklist()` creates hidden child families for individual items; each checked item has its own maintenance reminder, while its refresh threshold inherits the parent family via `thresholdKey`.
- Added explicit replacement-line definitions for elixir families. Selecting one item unticks other members of that *same line*, and their equivalent recognized auras can satisfy it; unrelated checked elixirs can be maintained simultaneously on WoW Forever. The two Firewater item IDs likewise share one utility effect.
- Extended the item chooser with multi-select checkmarks, same-line conflict feedback, item counts, search, a clear-all operation and remembered **In bags only** preference. Existing single-item elixir/utility choices are used as a migration fallback until an explicit checklist preference exists.
- Adjusted `Consumables.lua` selection and `Supplies.lua` tracking to skip the new parent multi-families and evaluate the selected hidden child families, preventing duplicate parent-and-child maintenance actions.

### Added: custom stock-only Supplies tracking and movable reminder
- Added arbitrary tracked inventory IDs (`supplyCustom`) and per-item `custom:<itemID>` stock entries. Item IDs can be resolved from supported item links/names or selected from bags; adding an item does not grant permission to use or cast it.
- Added custom tracked-item remove controls, a scrollable Supplies list, and display-only stock refresh even with the alerts master switch off. Custom entries count carried inventory, not spell usability; they never become secure consumable actions.
- Replaced the compact Supplies status badge with a dedicated movable, nonsecure reminder featuring per-category stock details, icon/text appearance controls, click-through to settings and 10-minute snooze. By default it appears while resting; an optional setting permits display outdoors. Added its own positioning support to Edit Mode and the Customization editor.
- **Historical UI placement:** At this release the Supplies controls lived under the Consumables page's internal Supplies view, not an independent sidebar page. The independent page arrived in **1.24.4**.

### Compatibility and testing
- Preserved previous elixir/utility selections during checklist migration and reused the existing consumable metadata checks and normal secure-action click/validation path.
- Added or expanded regression coverage in `tests/test_elixirs.py`, `tests/test_supplies.py` and the release test runner.

- Thanks to Drusangus for the suggestion.

---

# BuffTap 1.22.7

### Added: Return the Favor priority for Nearby recipients
- Added optional-on-by-default favor detection driven by newly observed or refreshed player helpful auras (`UNIT_AURA` for `player`), using identifiable player-source units and GUIDs. This is evidence-driven rather than automatic chat or combat-log guessing.
- A detected favor remains eligible for 300 seconds; a buff BuffTap itself gave is excluded from reciprocation for 300 seconds, and the same recipient cannot be bumped again for 1,800 seconds. Favor state is reflected in Nearby cache keys and invalidates cached recipients when necessary.
- Nearby sorts actionable cleanses first, followed by favorable recipients needing buffs, then other buff candidates with friend/guild priority. A small gold icon marks favor status while an action is available. Every spell still requires an explicit click or assigned binding.
- Improved default priority for friends and guild members within eligible Nearby buff recipients, with deterministic ordering within priority tiers.

### Fixed: readable Nearby errors
- Normalized Blizzard's long range-related `UI_ERROR_MESSAGE` strings to a short localized **Out of range** result, using known error constants and a narrow string fallback so the message fits the Nearby row.

---

# BuffTap 1.22.6

### Changes
- Nearby: the animated list is now on for everyone (turned on once; switch it off under Customization > Nearby window > Title bar and rows if you prefer, and it stays off).
- Nearby: when your mana reserve holds back Nearby buffs, the first row now says "Paused: saving mana" (with "Invites still work." in the all-players view), like the stealth and resting pauses. Before, buffs just stopped without saying why. It only shows when BuffTap can tell you are below your reserve, so in cat or bear form buffs stay available as before.
- Nearby window: new icons in the title bar. The resting button shows rising z's, and the lock is a padlock: closed and gold when the window is locked, open and grey when it is not. Both match the style of the all-players icon.

---

# BuffTap 1.22.5

### Changes
- Nearby: new optional "Animated list" (Customization > Nearby window > Title bar and rows, off by default). When someone new arrives, the rows below glide down to make room and the newcomer fades in. Gaps left by players who were buffed or walked away close instantly, so all visible motion flows the same way. Only the drawing moves: each clickable row stays in its slot, so a click always reaches the player shown there. No animation in combat, while scrolling, or with Reduce animation on.
- Nearby, all-players view: below the players who need a buff and your friends and guildmates, everyone else is now listed newest arrival first. Someone who just came into range always appears in the same place, near the top, instead of at the bottom or wherever they happened to sort.
- Nearby: "Buff while resting" now works on its own. Before, it only mattered when the Helpers "Pause reminders while resting" was on; otherwise Nearby always buffed in cities and inns. Characters that were buffing in towns keep doing so; new characters start with Nearby paused there. Your own reminders still follow the Helpers pause.
- Nearby window: new zZ button in the title bar to switch Nearby buffing in cities and inns on (gold) or off (grey) without opening the settings.
- Cleanse & revive: the Resurrection switches now line up with the Who switches above them.
- New `/bt combatprobe` (diagnostic): during your next fight it records whether WoW Forever lets addons read who cast your buffs and send emotes, and prints the results when combat ends. Nothing is cast or sent.

---

# BuffTap 1.22.4

### Fix
- Nearby: "Buff while resting" now works while "Pause reminders while resting" (Helpers) is on. The list filled up, but your binding, the click check and Nearby cleanses still obeyed the resting pause, so nothing was cast until that pause was turned off. Now, in cities and inns, Nearby players are offered while your own buffs stay paused.
- Nearby: new players now join the list at the bottom even while your mouse is over the window. Before, the list held still until you moved the mouse away.
- Friend and guildmate alert: the sound and glow now wait until the friend's row is actually on screen. Before, the sound could play while the list was held under the mouse, and the glow had already ended by the time the row appeared. The glow is also brighter, shown at full row brightness, gently pulses and fades out over four seconds.
- Friends who don't get a row still get the sound: while you are mounted, stealthed or resting with the all-players view off, or when they need no buff in the buff-only view.

---

# BuffTap 1.22.3

### New
- "Also on me" switch for each single-target buff on the Groups page, under the class choices. It is on by default. Turn it off and, while you are in a party or raid, BuffTap casts that buff on the people it picks but not on you, for example Thorns only on your tank. It is saved separately for your party and raid setups, like the other Groups settings. Solo, you always get it.
- Before, you were always included: turning Thorns off under My buffs turned it off for everyone, and leaving it on with "Tanks" still buffed you as well as the tank.
- The hint under the class choices is shorter and no longer says personal buffs ignore these settings.

Thanks to Lufia_TM for reporting this.

---

# BuffTap 1.22.2

### Fixes
- Nearby and PvP realms: PvP protection now skips flagged Nearby players only while you are unflagged (or your flag is running out), the same rule your group and target already used. Before, Nearby skipped every flagged player even when you were flagged yourself, so on PvP realms it did nothing in contested zones. Battlegrounds and arenas keep the stricter check.
- The "Prevent accidental PvP flagging" switch is now also on the Nearby page, under Player list. It is the same setting as the one on Helpers.
- Stealth: BuffTap offers nothing while you are in Stealth, Prowl, Shadowmeld or any other stealth, so a buff, cleanse or item can't break it. Reminders come back as soon as stealth ends. With "Show all nearby players" on, the Nearby window stays listed while you are stealthed, so invite buttons keep working; only buffing pauses, as it already did while mounted or resting.
- Nearby: while paused (stealthed, mounted or resting), the first row now says so, for example "Paused: stealthed. Invites still work.", in the same style as cast results. It shows whether or not the title bar is hidden, and the title bar keeps its usual count.

Thanks to bruinsfan825 (PvP realms) and user_vvl9721yymgwdslx85417 (stealth) for reporting these.

---

# BuffTap 1.22.1

### Fix
- Nearby: players with nothing to cast show the small grey dash on the right of their row again. 1.22.0 removed it by mistake.

---

# BuffTap 1.22.0

### Resurrection (new)
- Priests, Paladins and Shamans: when a group member is dead (not yet released) and you are out of combat, your binding offers your highest known Resurrection, Redemption or Ancestral Spirit on them. A dead player you target outside your group is offered too.
- Druids can turn on "Also use Rebirth" (off by default, since it has a long cooldown and a reagent).
- Players who have released their spirit, are offline, or are already being resurrected by someone else are skipped.
- Settings are on the Cleanse page, now called "Cleanse & revive": Offer resurrection, Your group, Your target and (Druids) Also use Rebirth.
- Nearby players can't be resurrected: the game removes nameplates from dead players, so they never appear in the Nearby list.

### Smaller changes
- The cleanse sound is now chosen with the other sounds under Customization > Binding & sound; the Cleanse & revive page has a "Sound settings" button that goes straight there. "Border colour by type" moved into What to remove, and the Never cleanse list shows more entries.
- The cleanse alert now uses Warm bell, which sounds more like a warning. This applies once to every character; you can pick another sound afterwards.
- New characters start with these sounds: Cleansing wash for buff reminders, Glass chime for supplies, Harp arpeggio for camping, Warm bell for cleansing and Happy hello for friends. Existing characters keep their other choices.
- Customization > Binding & sound: the buff reminder position now sits inside the Quick access card, so the page no longer overlaps.

### Friend and guildmate alert (new, off by default)
- Turn on "Alert me when a friend or guildmate appears in Nearby" under Customization > Binding & sound. The first time a friend or guild member shows up in your Nearby list, BuffTap plays the new "Happy hello" sound (a bouncy kalimba "hey there", level-matched to the other BuffTap sounds; any sound can be chosen as the Friend sound) and their row glows briefly in blue for a friend or green for a guild member.
- Two more new BuffTap sounds come with it, usable for any alert: "Twin bells" (a bright, cheerful ding-ding) and "Playful marimba".
- Separate Friends and Guild switches. It works whether or not the heart and shield name tags are shown.
- At most once per player per hour and one alert every 20 seconds; never in combat, in instances or for people in your group; quiet for the first seconds after a loading screen, so arriving in a busy guild hub doesn't set off a string of chimes.
- It uses the Nearby list, so it works wherever that list is active (with "Buff while resting" on, also in cities and inns). It has its own pacing, separate from the reminder sound's switch and minimum interval.

---

# BuffTap 1.21.2

### Mana reserve on WoW Forever
- The Nearby mana reserve never triggered on Forever: the game hides your current mana from addons (your maximum stays readable), so the reserve check could not compare anything and let every cast through, down to zero mana.
- When your exact mana is hidden, BuffTap now judges it from your own spells: it reads each rank's mana cost and asks the game which ones you can afford right now. A spell costing no more than the reserve that you can't afford means you are below it; one costing at least the reserve that you can afford means you are above it; in between, the middle of what is known decides. With many ranks (Healing Touch, Regrowth, heals, armors) it lands close to the reserve. When the exact value is readable it is still used.
- Once it is saving mana, Nearby waits until you are 5% above the reserve before offering again, so it doesn't flicker on and off.
- Nearby cleanses respect the reserve too.
- Full check-up: "Hide player names" now also hides players named in BuffTap's own status lines (last Nearby click, invitations, thanks) after they have walked away, and the Game line shows your class and interface number instead of "nil".
- The Full check-up's Nearby section shows the reserve, how your mana was read (exact or an estimated range) and whether it is saving mana.

### Tests
- 1888 Lua tests passed.

---

# BuffTap 1.21.1

### Who gets each buff (friendly targets and Nearby)
- Each single-target buff on the Target page has a Classes button that opens a class picker with class colours. The choice applies to friendly targets and Nearby players alike; party and raid keep their own class filters on the Groups page.
- Defaults are unchanged except one fix: Arcane Intellect and Divine Spirit are no longer offered to Warriors and Rogues you target yourself (Nearby already skipped them). Thorns now defaults to Warrior, Rogue, Paladin and Druid, in groups too. A target you click still gets other buffs whatever the class, until you choose classes.
- The first change in the picker saves every class, starting from what the picker shows, so targets and Nearby follow the same list from then on. "Use defaults" clears it. Choices save as you click, and the picker has a Done button.
- Blessings keep their own class choices.

### Nearby cleansing shows in the Nearby window
- With "Nearby players" on in Cleanse, a stranger with a debuff could put a cleanse on your binding while the main icon stayed hidden (Nearby casts never show it) and the Nearby window, which only listed buff needs, showed nothing. Nearby rows now include the cleanse as their first icon, and clicking the row casts it.
- Players who need a cleanse sort to the top of the window. Their row gets a faint tint and a left bar in the debuff's colour, and the cleanse icon has a border in that colour. The tooltip reads "Click: cleanse <debuff>".
- Nearby cleanses stay silent, like Nearby buffs.

### Nearby page
- New "Hold back short buffs, like Thorns" (off by default): in cities and inns, Nearby doesn't offer buffs of ten minutes or less (Thorns, Dampen and Amplify Magic, Fear Ward, Shadow Protection, single blessings, Water Breathing and Walking, Unending Breath, Detect Invisibility). Longer buffs are still offered.
- Player list rearranged: who and when you buff on the left (Offer nearby buffs, Buff while resting, Hold back short buffs, invite buttons), how the list looks on the right (Show all, Show full names, Show level, Mark friends and guild members, Mana reserve). "Open window" moved to the page header next to "Buff requests".

### Nearby cast results
- After you buff or cleanse a Nearby player (row click or binding), their row shows the result until the global cooldown from that cast ends (1.5 seconds when the game doesn't say): green with a tick and "<buff>: done" (or "Cleansed: <debuff>"), or red with a cross and the game's reason, such as out of range. Then the row clears, shows their next buff, or comes back so you can try again.
- The result covers the whole row: the player's name, class icon, buff icons and tags hide while it shows and come back afterwards.
- While a cast is pending or its result shows, the list holds still, so the row doesn't move away in busy places.
- A failed row stays clickable: clicking it retries at once, even after an out of range or line of sight error that would otherwise skip that player for a few seconds.
- A Nearby cleanse cast with your binding no longer plays the cleanse sound for that player while the cast briefly targets them.
- Only a cast of that spell in the next 2 seconds counts. The text shortens and then shrinks to fit narrow windows and long names like Greater Blessing of Wisdom.
- On by default; Customization > Nearby window > "Show whether each cast worked" turns it off.

### Status lights
- The Nearby light turns red when Nearby is on but friendly nameplates are off, with a tooltip pointing to Shift+V.

### Diagnostics
- "Copy for a report" is now "Full check-up": game and character, Diagnostics, Debug, Nearby, Supplies and your settings import string in one box to copy. Also /bt checkup. The names on your blacklist are left out of it (only how many there are), since bug reports are often posted publicly; Export settings still includes them.

### Customization page
- The right column (Icon, Preview, Effect) no longer runs past the bottom of the page onto the status bar. The Icon and Preview cards are a little more compact, and the preview icon tops out at 72 pixels.

### Tests
- 1878 Lua tests passed.

---

# BuffTap 1.21.0

1.21.0 also includes everything from the unreleased 1.20.1 build, listed below the new features.

### Cleansing (new)
- New Cleanse page, right after My buffs in the menu. Off by default. Classes with nothing to remove (Warriors, Rogues, Hunters, Warlocks) don't see it.
- BuffTap reads debuffs with their type (Magic, Curse, Poison, Disease), stacks and time left, and puts the right removal spell on the reminder, out of combat only. You still click or press your binding. A due cleanse comes before buffs.
- Spells: Druid Remove Curse, Cure Poison, Abolish Poison; Mage Remove Lesser Curse; Priest Dispel Magic, Cure Disease, Abolish Disease; Paladin Purify and Cleanse; Shaman Cure Poison and Cure Disease.
- Abolish Poison and Abolish Disease are chosen when the debuff has 2 or more stacks, when several of that type are on the same player, or when it will last more than about 8 seconds. A single short one gets the plain cure. If Abolish is already ticking on that player, BuffTap waits for it. "Prefer Abolish" can be turned off.
- Who: you, then your group, your friendly target, then Nearby players (option, off by default; uses the same safety rules as Nearby buffing, including PvP protection and the blacklist).
- Debuffs with under 3 seconds left are skipped.
- Never cleanse list, shared by all your characters: type a name on the Cleanse page, or right-click a cleanse reminder to add its debuff. A built-in list (starting with Naxxramas' Mutating Injection) is included.
- Cleanse reminders read "Cleanse: <debuff>" with the stack count, play their own sound (new "Cleansing wash", a rising airy shimmer with a bright two-note sparkle; any sound can be chosen on the Cleanse page) and get a border in the debuff colour (blue Magic, purple Curse, green Poison, brown Disease; can be turned off).
- The click checks again that the debuff is still there, the spell is usable and the player is in range.
- The Never cleanse list shows each debuff's icon and name with a Remove button. Built-in entries can be removed too if you really want to cleanse them, and "Restore built-in entries" brings them back.

### Settings window
- Status lights in the sidebar: a green light when a page's feature is on, a hollow ring when it is off (My buffs, Cleanse, Groups, Target, Nearby, Consumables, Camping, Weapons). Hover for "Turned on" or "Turned off".
- Blacklist moved down with the settings-only pages (Customization, Helpers, Profiles, Diagnostics, Patch notes).

### Weapons and consumables
- Weapon menus show the oil, stone or poison's own icon even when none are in your bags, instead of a question mark.
- Consumables show the item's own icon when none are in your bags, instead of a question mark.
- Weapons page: the status line no longer runs under the Retry reminders button.

### Nearby
- Hide the title bar until the mouse is over the window (Customization > Nearby window > Title bar), with an option to keep the hairline. Off by default.
- New "Buff while resting" option on the Nearby page: Nearby keeps working in cities and inns while your own reminders still pause. In the all players view while resting or mounted the list is kept and the count shows why buffing is paused.
- Fix: the mana reserve didn't notice when your mana crossed it, so buffs kept being offered below the reserve.
- All players view: once nobody needs a buff, friends and guild members are listed first, so they stay in the visible rows. Players who need a buff still come first.
- First-time setup turns on every Nearby option except buff requests. Existing settings are not changed.

### Camping
- Camp text wraps instead of being cut off, and the bag line shows whenever you have sleeping bag stacks.

### Nearby guide and fonts
- The Nearby guide (Nearby page and first-time introduction) is redrawn to look like the real Nearby window: header with count, people icon, lock and close, gold-edged class and buff icons, levels before names, and the gold row your binding buffs next. Numbered markers point at each part, with a numbered key in two groups: Buttons (invite, ask to join, ask for a buff, all players view) and On each row (needs your buff, nothing needed), plus name tags in a two-by-two grid. It says "press your BuffTap binding" instead of naming a key.
- The first-time introduction is wider to fit the new guide. The Nearby page note about nameplates and window options moved into the guide.
- Font menus (Nearby window font, buff and camp reminder fonts) show each font name in its own font, and the box shows your current choice in its font, also while hovering.

### Fixes from a full code review
- Combat safety: Nearby rows clear their cast the moment combat starts, so the separate Nearby key can never cast a stale buff in combat.
- Nearby right-click menu and blacklist use the full name (first name and surname), so blacklisting one "Bob" no longer blocks every Bob. Entries typed with a first name only still match by first name.
- "Hide player names" in Diagnostics reports also hides surnames, and only replaces whole words.
- The Nearby list is found again after combat on clients where nameplates expose their unit only as a field.
- Nearby works out group members once per update instead of once per player, which is much lighter in raids.
- Underwater buffs: after a /reload while underwater, BuffTap reads the running breath timer instead of waiting for it to restart.
- Pets: Arcane Intellect and Divine Spirit are only offered to pets that use mana (Thorns still is). Pet buff changes are noticed straight away when pet buffing is on.
- Party and Raid per-buff timing kept values only from 15 s to 3 minutes; it now keeps When gone up to 10 minutes like Solo. /bt rebuff uses the same range.
- /bt group, /bt smartgroup, /bt groupneed and /bt groups now change the active Party or Raid setup instead of settings that setup ignores.
- Consumables: an item cooldown reported as 1/0 instead of true/false is accepted, and items whose spell data loads late are requested again instead of staying unusable until /reload.
- Cross-class import keeps your class's own supplies (poisons, stones) and only brings over food, drink and coatings.
- Deleting a profile other characters use: the warning now says they go back to their own character settings at their next login, which is what happens.
- Settings window: the window scale applies when you let go of the slider instead of rescaling under the mouse; colour and scale changes, and bag or item-data bursts, no longer rebuild the window on every tick; an open dropdown is no longer closed by a bag change.
- The camp reminder updates again when the settings window closes, and it no longer schedules work during combat.
- A second "Click again to confirm" within four seconds of leaving a page now works.
- Changing the main key to one used by the Nearby key rebinds Nearby straight away.
- The urgency colour no longer restarts its timer on every refresh.
- Searchable lists (sounds) highlight the current choice.
- Em dashes removed from interface text in all languages.

### Tests
- 1838 Lua tests passed (full release suite, 0 failures).

---

# BuffTap 1.20.0

- Fix: the reminder could pop up (and play its sound) right after login or a loading screen, before the game had reported your buffs. BuffTap now waits 4 seconds after loading, then checks once.
- Smarter default timing: buffs under 2 minutes (such as Nature's Grasp) remind when they wear off, and buffs of 45 minutes or more refresh 5 minutes early. Food now reminds 1 minute before it ends (was 5), flasks 5 minutes (was 10) and Elixir of Ferocity 1 minute (was 3). The same rules apply in party and raid, and short buffs also wait until they wear off on friendly targets and Nearby players. Timing you set yourself is kept.
- Party and raid buffing is on by default. This update turns it on once for every character; turning it off on the Groups page afterwards sticks.
- Right-click dismiss is on by default for new characters and lasts 10 minutes (new 10 minute choice). Existing characters keep their setting.
- Import from another class keeps everything except settings tied to that class's spells (buff choices, blessings, class tools) and says what was skipped.
- Four new icon effects for the buff and camp reminders: Shine (a light sweep), Ripple (an expanding ring), Bounce (a small hop) and Orbit (a small comet circling the icon). They run on their own, without the soft glow underneath. Two new options for the buff reminder: Urgency colour (amber in the last half of the refresh window, red once the buff is gone) and Flash once, then settle.
- Clearer status when nothing needs doing: "All your buffs are up", with a note when no players are nearby or nearby players already have your buffs, and a separate message when a buff is due but the player is out of range.
- The live status line moved from the header to the bottom bar of the settings window, so it is no longer cut off. The old "save immediately" note there is gone.
- The Buffs page is now called My buffs, with a shorter description.
- Profile lists show each profile in its class colour with the class in brackets when all of its characters share a class.
- "Move buff reminder" and "Move camping reminder" now open the same Move BuffTap frames mode and return to the tab you came from. The export and import window, the Done bar and the Nearby right-click menu use the settings window's styling.
- Customization > Binding & sound: "Move BuffTap frames" shows the buff reminder, Nearby and camp movers with a Done button, without opening Blizzard's Edit Mode.
- Setup: new recommendations (party and raid buffing, right-click dismiss) and an updated "Worth knowing" page covering the blacklist, the Nearby key, Mana reserve, ready check top-ups, export and import, and the smart underwater buffs. The Buffs page labels breathing buffs and Aquatic Form "Reminds when underwater".
- Page headers: the page switch sits at the top right with its label first and the switch at the right edge, and shortcuts such as Customize look sit right below it with the same right edge, on every page. More space between the header text and the line under it. Dropdown lists match their box width and show five rows.
- Groups page: "Use group spells automatically", "Buff pets" and "Top up at ready checks" sit inside the Shared group settings box.
- Customization > Buff reminder: "Show icon" is the first row of the Icon box, and the preview note is centred.
- Diagnostics: the report box is taller, so most reports fit without scrolling.
- Profiles: any profile except the active one can be deleted. If other characters (including deleted ones) still use it, the confirmation says how many, and they start a fresh profile at their next login.
- Timing sliders on My buffs and Target show the timing a buff really gets when you have not set your own, for example 5 minutes for hour-long buffs and "When gone" for short ones. Your own timing can now range from "When gone" up to 10 minutes. BuffTap learns each buff's length the first time it sees it.

- Blacklist page (in the menu under Nearby): never offer buffs or invites to players you name, whole guilds, or anyone on your ignore list (on by default). Add by typing a name, from your target, or by right-clicking a name in the Nearby window. Guild names must match exactly, including accents and special characters. Rules: apply to players you target yourself (on by default) and optionally ignore the blacklist in dungeons and raids. Your own group is never affected.
- Nearby window name tags, at the right end of the name next to the buffs: a blue heart for friends (character or Battle.net), a green shield for your guild, a red flag for PvP-flagged players (shown even with PvP protection off, since buffing them flags you; faded when their status can't be read) and a red crossed circle for blacklisted players. The buff icon or dash keeps its own place, and the dash is now centred like the icons. In the buff-only view, the counter notes how many were left out for PvP or the blacklist. Hover a row for details. Turn off friend and guild tags on the Nearby page.
- The Nearby window's people toggle has a new round-headed icon (same size).
- Right-click a blacklisted name in the Nearby window to remove the player or their guild from the blacklist.
- Fix: the Nearby buff request button could show for a player with nothing to request (for example a blacklisted player, or one whose information was not ready yet).
- Nearby window: right-click a name to whisper, invite, add to your ignore list, or blacklist the player or their guild.
- Optional Nearby key (Customization > Binding & sound): a second key that buffs the top player in the Nearby window. With it set, your main key covers only you and your group.
- Mana reserve (Nearby page, a slider from 0 to 50%; 0 is off): pause buffs for players outside your group while your mana is below that level. Your own and your group's buffs are unaffected. The status shows why it is waiting.
- Ready check top-up (Groups page, on by default): during a ready check, buffs with less than half their time left count as missing.
- Long buffs (20 minutes or more) top up a little earlier inside dungeons and raids: at 10% of their duration, up to 5 minutes.
- Consumables: new "Only in dungeons and raids" option next to "Pause while resting".
- Dismiss a reminder for now: choose until zone change (as before), 5, 15 or 30 minutes.
- Buff pets (Groups page, off by default): single-target buffs such as Mark of the Wild for your pet and your group's pets. Blessings and group spells stay with players.
- Solo thanks: optional short random delay before the emote.
- Unending Breath and Water Breathing only remind for you, your group and Nearby while the breath timer is running. A friendly player you target yourself can get them any time. Druids can turn on an Aquatic Form reminder for the same moment (Buffs page, off by default).
- Profiles page: export your settings as a text string and import them on another character or account. Buff settings only import onto the same class.
- Diagnostics: capture the Debug, Status, Nearby and Supplies reports on the page instead of in chat, and "Copy for a report" selects everything for Ctrl+C. Player names are hidden by default.
- When reminders stop because the game is not sharing buff information (some battlegrounds), BuffTap says so once per zone. Turn it off on the Diagnostics page.
- Settings window: "Customize look" sits in the header on Buffs, Consumables, Weapons and Camping; retry and reset buttons sit at the bottom right; the Helpers page has more room; Export and Import sit in a Share settings box on Profiles; the Supplies view no longer leaves an empty gap; the header status uses smaller text so it is not cut off; patch notes scroll in smaller steps; Mana reserve replaces "Buff others at".

- New smooth icons for the Nearby invite (+) and request to join (arrow) buttons, also used in the Nearby guide.
- Nearby window options (size, rows, width, background, button side, text and position) moved to a new Customization > Nearby window tab. The Nearby page now shows the Nearby guide in its place, updated with the name tags and with more space between its paragraphs; the separate "How Nearby works" button is gone.
- Nearby text options: font, size and outline, under Customization > Nearby window. The font list now has all four game fonts (Friz Quadrata, Arial Narrow, Morpheus, Skurri) plus any font registered through SharedMedia. A SharedMedia font that is later uninstalled falls back to the game font. The BuffTap title and the counter use the same font and outline, capped at 13 px so they fit the header. Rows grow to fit larger text. Restore window defaults resets them.
- New "Show level" option on the Nearby page shows each player's level before their name, for example (28) Bob Loblaw. Off by default; players too high to read show (??).
- Forever is now recognised by its game type instead of its version number, so solo thanks keeps writing names correctly after future Forever patches.

---

# BuffTap 1.19.3

- The Nearby window now sits under interface windows such as professions and bags instead of covering them. A new "Keep above other windows" option on the Nearby page restores the old behaviour.
- Fix: the Nearby window jumped away from where you dropped it when its scale was not 100%. Its position is now saved in screen units, so it also stays centred when you change the scale. Edit Mode uses the same fix.

---

# BuffTap 1.19.2

Release summary. Internal builds 1.19.2-beta1 to beta8 are listed below.

- One-time setup for each character, shown after any login cinematic and reopened with /bufftap setup: "Set me up" or "Leave me alone", recommended settings that only change what you haven't touched, and copying settings from another character.
- Class presets: Paladin blessing plan (Kings first once learned, Wisdom for Priests, Druids, Shamans and healers), Druid Thorns on tanks, optional Fear Ward on tanks, Shaman caster or healer imbue, and class readiness for Hunters, Warlocks and Paladins.
- Smarter built-in defaults for every class: situational buffs such as Dampen Magic, Amplify Magic and Shadow Protection stay off, Arcane Intellect and Divine Spirit go to mana users, and buff requests fit your class.
- Nearby guide on first use: a preview of the window with the invite, join and request buttons explained, quick choices, and a button to turn on friendly nameplates. The setup explains why Nearby helps your class.
- Nearby shows full player names by default, with a "Show full names" option.
- BuffTap's own sounds for supplies (Glass chime) and camp (Warm bell), with a separate camp sound setting.
- Edit Mode now also moves the Nearby window and the camp reminder.
- Reset and clear buttons ask for a second click.
- Fixes: the camp reminder preview offset, see-through dropdowns, and the old welcome card appearing after setup.

---

# BuffTap 1.19.2-beta8

Internal build. Not published.

- Paladin setup plan puts Kings first once it is learned: Kings for Warriors, Rogues, Hunters, Mages, Warlocks, Paladins and tanks; Wisdom for Priests, Druids, Shamans and healers. Before Kings, Might for physical classes and Wisdom for mana users.

---

# BuffTap 1.19.2-beta7

Internal build. Not published.

- Edit Mode now also moves the Nearby window (when Nearby is on) and the camp reminder icon (when the camp reminder is on), using placeholders so you can place them anytime outside combat.
- Setup: the Nearby offer now explains the benefit for your class (non-buffers get invites and buff requests) and opens the guide first; Nearby turns on from there.

---

# BuffTap 1.19.2-beta6

Internal build. Not published.

One-time setup additions:
- Copy settings from another character (alts), including buff and class settings when the source is the same class.
- Change binding and Customize reminders buttons on the last page; an optional Modern square icon choice.
- Shaman: choose caster (Flametongue) or healer (Flametongue and Water Shield); melee keeps Windfury.
- Tips for roles (Mark target role, Guess tanks from stance) and the minimap icon's quick controls.
- The Nearby guide offers to turn on friendly nameplates when they are off.

---

# BuffTap 1.19.2-beta5

Internal build. Not published.

- Nearby introduction: the first time you turn Nearby on (from the setup, the settings or the minimap), a short guide shows a drawn example of the window and explains the + invite, the blue arrow (ask to join) and the buff request tile. Quick choices turn on party invites, buff requests and the all-players view. Reopen it with "How Nearby works" on the Nearby page. Players who already use Nearby are not interrupted.

---

# BuffTap 1.19.2-beta4

Internal build. Not published.

Buffing defaults reviewed class by class, so new characters work well without setup:
- Situational buffs are no longer offered to friendly targets unless you allow them: Dampen and Amplify Magic, Shadow Protection, Fear Ward, Water Breathing and Walking, Unending Breath, Detect Invisibility.
- Arcane Intellect and Divine Spirit go to mana users by default (not Warriors or Rogues), in groups and to nearby players. Your own class choices still win.
- Paladins without Blessing of Kings maintain Blessing of Might by default; with Kings, Kings only.
- Low-level fallbacks are on: Rockbiter Weapon until Windfury, Aspect of the Monkey until Hawk.
- The one-time setup no longer needs Mage, Priest or Shaman presets for these; it keeps Thorns on tanks, the Paladin blessing plan, optional Fear Ward on tanks and class readiness.

---

# BuffTap 1.19.2-beta3

Internal build. Not published.

- Fix: the one-time setup now appears on its own for new characters. A new character's intro cinematic hid it and that counted as "Leave me alone"; only an explicit choice (or the X button) finishes it now, and it waits while the UI is hidden.
- The setup replaces the old first-use card; its "how to buff" tip with your binding is on the last page.
- Supply alerts now default to Glass chime and camp alerts to Warm bell. Alerts still on the old default (Ding) switch once.
- Buff requests default to what helps your class: no Blessing of Might for casters, no Arcane Intellect or Divine Spirit for Warriors and Rogues. Your own ticks still win.
- Situational buffs stay opt-in: Shadow Protection is no longer requested by default, and the Priest Fear Ward setup is listed as optional rather than preselected.
- The one-time setup points out Class readiness for Hunters, Warlocks and Paladins and offers to turn on the pet, Healthstone, Soulstone or Oath reminders.

---

# BuffTap 1.19.2-beta2

Internal build. Not published.

- One-time setup: class presets for every class, each offered only when you have not set it up yourself:
  - Paladin: a full blessing plan for party and raid (Might for Warriors, Rogues and Hunters; Wisdom for casters; Kings for Druids, Shamans and Paladins when known), plus Kings (or Might) for tanks and Wisdom for healers.
  - Druid: Thorns on tanks. Mage: Arcane Intellect for mana users only. Priest: Divine Spirit for mana users only, and Fear Ward on tanks when known.
  - Shaman: Rockbiter Weapon until Windfury is learned.
  - Warrior, Hunter, Warlock and Rogue defaults already match the recommendation; the setup says so.

---

# BuffTap 1.19.2-beta1

Internal build. Not published.

- One-time setup: new players get a short guided setup; existing players see it once after updating. "Leave me alone" changes nothing. "Set me up" lists recommended settings (alert sounds, BuffTap chime, solo thanks, pause while resting, PvP protection, stop repeated stronger-buff errors, class-colour highlight) and only preselects ones you never changed. Class setups: Thorns on tanks (Druid), Arcane Intellect and Divine Spirit for mana users only (Mage, Priest). Points out Nearby and offers to turn it on. Reopen any time with /bufftap setup.
- Camp reminder has its own sound (default: Warm bell).
- Nearby shows full names (first name and surname) by default, with an option for first names only. The default width grows from 210 to 240 px once.
- New installs use the class colour as the highlight colour.
- Fix: the camp preview card is no longer offset from the cards above and below it.

---

# BuffTap 1.19.1


- BuffTap's own alert sounds: Marimba rise (the new reminder default), Glass chime, Warm bell and Harp arpeggio. Original recordings, about 9 KB each.
- Existing reminders using the old default switch to Marimba rise once; Ding stays available as "Ding (game)". The supply alert keeps Ding so the two alerts stay distinct.
- The sounds are registered with SharedMedia whenever another addon provides it, so other addons can use them too.
- Fix: dropdown menus on some settings pages were see-through and could sit under nearby controls.

---

# BuffTap 1.19.0

Release summary. Internal builds 1.19.0-beta1 to beta3 are listed below.

- Roles: each party/raid buff can go By class, to Tanks or to Healers. Roles come from your mark, the group role, the raid Main Tank, or optionally a tanking stance or form.
- Paladin blessings: separate Tank and Healer choices per class.
- Nearby: request a missing class buff from a passing player (one whisper per click, three-minute cooldown); request to join a player's group when the client offers it; invite and request buttons on the left or right.
- Reminder icon: Classic or Modern square style, label placement, rebuff countdown sweep, greyed out-of-range reminder.
- Helpers fits on one page with Solo thanks at the top; thanks can continue while resting.
- Camp setup tray uses the settings theme; Customize look shortcuts; accent colour swatch; Nearby hairline follows the accent colour.
- Destructive buttons need a second click to confirm.
- Fixes: camp effect dropdowns, target refresh field showing "00", settings window shadow gap, group-count badge character, header seams, font fallback.

---

# BuffTap 1.19.0-beta3

Internal build. Not published. No test suites run.

- Helpers page no longer scrolls. Solo thanks and Conveniences share the top row, Buff requests and Tracking follow, and Class readiness fills the space below for Warlocks, Hunters and Paladins. Restore reminders and View discovery report moved to the page header. Longer explanations moved into tooltips.
- Header banner: the artwork's dark backdrop is now transparent, so it blends into the window instead of looking pasted in.
- Groups: the selected buff's settings no longer draw a second panel inside the card (fixes the offset double border).
- Nearby: new Invite and request buttons setting (Left side or Right side), under Nearby > Window appearance.
- Nearby: Request to join now shows a bold blue arrow on the same tile as the invite plus (replaces the hard-to-see teal glyph).
- Customization: the reminder editor's right column is now Icon, a more compact Preview, then Effect, so both columns end level.
- Fixes: camp reminder Effect, colour and speed dropdowns now open in Customization (their menus stayed on the hidden Camping page); an unavailable unit-name font is no longer mistaken for the combat-number font.
- Destructive buttons need a second click within four seconds ("Click again to confirm"): Clear binding, Reset look, Reset camp look, Reset buffs, Reset target settings, Restore window defaults.
- Nearby: the header hairline follows your accent colour.
- Customization: the camp preview card lines up with the Icon and Effect cards; the settings header no longer shows faint seams at its sides.
- Visual pass:
  - Customize look buttons sit on the header line, left of the switch on Consumables and Weapons, so they no longer collide with the switch or with "Use Solo settings".
  - Target: sections start directly under the header, matching other pages.
  - Nearby: appearance slider tracks line up; the card fits its two-line note.
  - Camping: Setup & appearance card fits its content.
  - Profiles: the copy card shrinks when same-class copy options are hidden, removing the empty gap.
  - Helpers: buff request choices use three even columns (long names no longer collide); the message field uses the standard text size.

---

# BuffTap 1.19.0-beta2

Internal build. Not published. No test suites run.

- Roles simplified: each buff has "Who gets this buff": By class, Tanks or Healers. Tanks/Healers give the buff to every player with that role whatever the class; the class checkboxes are dimmed and unused. "Everyone except tanks" removed.
- Modern icon: crisp dark edge only (accent hairline removed).
- Helpers page rebuilt as a scrolling stack of evenly spaced sections (Solo thanks, buff requests, conveniences, class readiness, tracking, actions). Fixes overlapping sections.
- Request to join: availability now follows the client's invite logic (GetDisplayedInviteType), with a fallback for grouped players.

---

# BuffTap 1.19.0-beta1

Internal build. Not published. No test suites run.

- Roles: party/raid buffs can target Everyone, Tanks only, Healers only or Everyone except tanks. Roles come from a BuffTap mark, the group role, the raid Main Tank, then optionally a tanking stance or form (off by default).
- Paladin blessings: per-class Tank and Healer choices between player exceptions and class choices; mixed choices use single blessings for that class.
- Nearby: Request to join for grouped players when the client offers it; optional buff requests (whisper on click, three-minute cooldown per player) configured in Helpers.
- Reminder icon: Classic or Modern square style (buff and camp reminders), label placement, rebuff countdown sweep, greyed out-of-range reminder (display only).
- Helpers: Solo thanks moved to the top with a larger card; Keep thanking while resting.
- Camp setup tray uses the settings theme. Customize look shortcuts on Buffs, Consumables and Weapons. Accent colour swatch.
- Fixes: target refresh value field showed "00" for four-digit values; light gap under the settings window shadow; group-count badge showed a garbled character; gold button text is now bold without a shadow.

---

# BuffTap 1.18.0

Release summary. Internal builds 1.18.0-beta1 to beta9 are listed below.

- Redesigned settings window: sidebar with icons, page headers, rounded controls, switches, Inter typeface, accent colour and window scale.
- Sliders show their units (sec, px, %, players) inside the value field; the range is in the tooltip.
- New: pause consumable and weapon reminders while resting (Consumables and Weapons pages).
- Reminder previews, Nearby appearance settings and in-game patch notes for the ten most recent versions.
- Fixed: undefined-global reads in group preference loading, consumable resolution and the item picker.
- `/bt reset` requires `/bt reset confirm`; the window and slash command share one reset path.
- Translated the missing settings text in deDE, frFR, esES and ptBR and removed unused translation keys.

---

# BuffTap 1.18.0-beta9

Internal build. Not published.

- Design pass: one type scale, 16 px card padding, collapsible patch notes, slider ranges moved to tooltips.
- Buffs rows: faint outline with hover highlight, unchecked rows dimmed, Default shown only for customized timing, read-only priority rank.
- Group thresholds are labelled in players. Long translated button labels step down a size instead of overflowing.
- No test suites run.

---

# BuffTap 1.18.0-beta8

Internal build. Not published.

- Implemented review items 1 to 10, the resting pause for consumables and weapons, slider units, and borderless list rows.
- No test suites run.

---

# BuffTap 1.18.0-beta7

Internal visual redesign build. Not published.

- Redesigned the settings window: rounded surfaces with a soft shadow, a header holding the banner, status and master switch, a full-height sidebar and a taller page area.
- New typeface for the settings window: Inter (SIL Open Font License), with Arial Narrow as a fallback.
- Rebuilt controls: rounded buttons with hover and pressed states, accent primary actions and red-outlined reset actions, on/off switches for settings, compact checkboxes for lists and grids, rounded fields and dropdowns, pill-shaped sliders and thin scrollbars.
- Page headers now show the page icon; section titles use consistent small capitals inside their boxes.
- Fixed stray value labels (for example "40 px", "100%", "5 sec" and duplicated slider values) and the overlapping "45 sec" text in buff rows.
- Fixed left-aligned button text, weapon checkboxes touching their section border, and profile buttons touching their box edges.
- Replaced the old yellow arrow buttons with matching chevrons.
- No settings, callbacks or saved data changed. No test suites run.

---

# BuffTap 1.18.0-beta6

Internal visual redesign build. Not published.

- Modernized the options window: flat dark surfaces, hairline borders and a single clean typeface throughout.
- New sidebar with matching line icons, an accent bar on the selected page and dimmed icons for the others.
- Open page headers with a large title and a divider, replacing the boxed title band.
- Redrawn controls: flat checkboxes with an accent fill, round slider thumbs, dropdown chevrons, flat text fields with an accent focus outline, and thin scrollbars.
- Customization sub-tabs use an underline style; Solo/Party/Raid switches use a segmented style.
- Added small generated interface textures (checkmark, chevron, slider thumb and twelve sidebar icons).
- No settings, callbacks or saved data changed. No test suites run.

---

# BuffTap 1.18.0-beta5

Internal visual correction build. Not published.

- Added separation between weapon application controls and the oils/stones section.
- Added bottom padding beneath label-visibility checkboxes in both reminder editors.
- Matched helper-card heights and checkbox insets; aligned solo-thanks and tracking captions.
- Inset the default rebuff controls and Reset buffs button from their section border.
- Retained ten versions of patch notes. No test suites run and no gameplay changes.

---

# BuffTap 1.18.0-beta4

Internal visual correction build. Not published.

- Matched gold borders across page frames, title bands, preview panels and section boxes.
- Preserved native page borders while replacing Nearby, Camping and Customization content.
- Aligned full-width section boxes and title insets, added missing section outlines, and matched slider fills to thumb centers.
- Removed the duplicate weapon description and improved the patch-history link's font and padding.
- Kept the ten-version patch history. No test suites run and no gameplay changes.

---

# BuffTap 1.18.0-beta3

Internal visual correction build. Not published.

- Applied the same four-sided border to shared title and section boxes.
- Kept each page border in place when positioning its content, so title areas stay inside the page frame.
- Used explicit Buffs/Weapons content references instead of relying on native child order.
- Expanded the in-game patch history from five to ten versions, using the existing release notes.
- No test suites run, as requested. No changes to buffing behavior or profile preferences.

---

# BuffTap 1.18.0-beta2

Internal visual correction build. Not published.

- Corrected the Patch notes panel background template so options initialization can finish and apply the shared headers and layouts.
- Kept pages and customization subpanels hidden until selected, preventing initial overlap.
- Kept native checkbox artwork at 24 x 24 instead of stretching it to label width.
- Removed the old slider track and thumb behind the new slider controls.
- Added a matching title-area background on every options page.
- Buffing logic, scanning, profiles and gameplay behavior are unchanged.

No test suites were run for this correction, as requested. Native in-game visual confirmation is still needed.

---

# BuffTap 1.18.0-beta1

Internal testing build. Not published.

## Consistent options

- Retained the BuffTap banner and vertical navigation, with matching page headings, section cards, spacing and action controls.
- Aligned Solo / Party / Raid editing controls across Buffs, Weapons and Consumables, and Party / Raid controls in Groups. Descriptions explain automatic application and inheritance in plain language.
- Standardized sliders with a numeric field on the left, immediate saving, keyboard entry, cancellation and focused-input protection.
- Kept precise buff-icon coordinates in Binding & sound.

## Appearance and previews

- Added separate Buff reminder and Camping reminder editors with live sample displays. Samples use the real icon effects and text styling without casting, changing targets or playing notification sounds.
- Grouped binding, sound and quick-access settings together.
- Added gold, class-colour and custom-hex interface accents, a colour picker where supported, window scale and a reduced-animation preference.
- Preserved warning colours and player-class colours. Dark custom accents are brightened for readable contrast.
- Moved Camping appearance into Customization with a direct shortcut from Camping.

## Nearby and patch notes

- Added Nearby scale, width, background-opacity, position-lock and visible-row controls. Choose 2–40 rows, limited by screen space; extra players remain available by scrolling.
- Kept a stable footprint when switching player-list views. Layout changes defer until out of combat and secure row payloads are cleared when hidden.
- Added Patch notes with five recent updates, short nontechnical explanations, contribution thanks and a copyable link to older history. An optional unread dot uses one shared seen-version marker.

## Compatibility

- New shared appearance preferences participate in named-profile copying. Class-specific buff, weapon, consumable and group preferences retain their existing behavior.
- Retained existing spell selection, PvP checks, aura protection, click validation and scanning logic.
- Uses the existing banner, icon assets and libraries; no new artwork pack or UI dependency.

---

# BuffTap 1.17.1

## Preferences for Solo, Party and Raid

- Added Solo, Party and Raid selectors directly to Buffs, Weapons and Consumables. You can prepare any setup while ungrouped; selecting a setup edits it without activating it.
- Solo is the baseline. Party and Raid independently inherit unchanged preferences. Changing one setting leaves the rest following Solo, and Use Solo settings restores inheritance for that section.
- Added separate five-player Party and Raid preferences to Groups for every class. Existing group settings are preserved in both before customization, with independent enablement, recipient filters and group-spell thresholds.
- Party shows simple party inclusion controls. Raid retains G1–G8 responsibility controls and per-buff group filters.
- Paladins retain separate blessing plans, class choices and player exceptions, with independent Party/Raid assignment enablement, Greater Blessing settings and thresholds. Explicit assignments remain authoritative.
- Context changes apply automatically out of combat. Changes during combat wait until combat ends, and a stale prepared action is cancelled before casting.
- Context preferences remain character-specific. Explicit same-class profile copying includes them; shared-only and cross-class copies do not import them.

## Corrections

- Corrected the weapon refresh slider's numeric value handling.
- Kept item labels, stock previews and timing controls matched to the setup being edited.
- Invalidated roster and Nearby selection caches when the active setup changes.

Weapon application and replacement permissions remain common explicit choices. Target preferences remain separate. Battlegrounds, arenas and unavailable group state use Solo buff/weapon/consumable preferences with the existing client restrictions intact.

---

# BuffTap 1.17.0

## Options and navigation

- Replaced the crowded horizontal tabs with an icon-led sidebar. All eleven pages remain directly accessible, with the same usable page area and no scrolling of the options window itself.
- Refined the dark surfaces, section cards, muted descriptions, selected navigation, selector arrow wells, menu selection highlights and text-field focus indicators. Native WoW action buttons and the existing banner remain in use.
- Grouped Profiles into clear active, create, copy and removal areas, preserving the existing create-from-current choice and confirmations.
- Removed the empty class-imbue area for classes that only use oils and stones, placing their hand checkboxes beside those choices. Class-specific imbue controls remain available where supported.
- Clarified Nearby instructions, including scrolling inside the window and using the buff binding after moving the pointer away. Configuration menus are opaque and clamped to the screen.
- Applied matching surfaces to onboarding, quick controls, item selection, assignment dialogs and camp setup. The Nearby player window keeps its established design.
- Added the current version to the options header, alongside the existing Diagnostics and debug version details.

## Camping and sleeping bag

- Added a separate Camping page and an optional, movable reminder for Camp Benefits and the sleeping bag's Well-Rested bonus. Track either benefit independently, including missing or expiring benefits away from a camp.
- Shows sleeping bag stacks and remaining duration alongside camp timing, with independent countdown and stack visibility. Live label timers reuse cached expiry information.
- Added warning thresholds, optional sound and snooze/resume controls. Camping stays separate from the regular buff queue and binding. Food reminders remain under Consumables.
- Added a compact setup tray for carried camping items and relevant profession recipes, using 39 verified recipe/item/use mappings across twelve professions. Carried items take precedence where appropriate.
- Item use rechecks the bag slot, spell, usability, cooldown and proximity before a click. Crafting opens the relevant profession first and requires another click to craft one item. Ground placement remains manual where required.

## Reminder customization

- Added soft glow, pulse, pixel border, sparkles and spell glow choices, with color and animation-speed options for both reminders. Corrected tinting so white and cyan retain their intended colors.
- Added font, pixel size, color, outline and text-spacing controls to regular Customization and Camping. Camp styling is independent of the regular reminder.
- Centered camp text beneath the icon and centered the Nearby invite plus independently of font bearings.
- Replaced ambiguous text defaults with the actual inherited game font/size where available. Outlines offer None, Thin and Thick; duplicate inherited choices are removed. Returning to the game font and size restores them correctly.
- General visual and camping preferences participate in named profiles. Temporary snoozes, inventory and profession knowledge are not copied.

## Catalog, helpers and Nearby

- Removed passive Omen of Clarity from selectable Druid buffs and corrected a Seal of Fury fallback rank level. Removed unused reagent entries for retired spells and verified catalog regeneration retains the supported spell and alternate-aura data.
- Added an opt-in Paladin Oath of Light helper for an explicitly assigned recipient, using the normal buff binding or click. Requires the talent. Its assignment remains character-specific and is available in explicit same-class profile copies.
- Added the opt-in Utility (selected) consumable family: Distilled Firewater, Winterfall Firewater, Dragonbreath Chili or Gift of Arthas. It maintains one selected preference and preserves a recognized existing utility effect until expiry.
- Fixed Nearby scrolling over player rows and invite controls, including when the configured buff binding uses the mouse wheel. The pointer must leave the Nearby window to use that wheel binding for buffing.

Existing preferences and profiles are preserved. Every cast, item use and craft still requires input. In-combat casting remains disabled. The prior Nearby allocation improvements and verified-recipient solo-thanks safeguards are retained.

# BuffTap 1.16.10

- Reduced temporary memory allocations and processing overhead while Nearby buffing is enabled, especially around larger groups of players.
- Avoided repeatedly rebuilding and sorting the same class buff list during a single refresh.
- Added short-lived reuse of unchanged Nearby buff checks, with invalidation when auras, player identity, spellbook data, or settings change.
- Preserved fresh pre-cast checks for buffs, recipient identity, PvP status, range, mana, and cooldowns.

Existing settings and profiles are preserved. Every buff cast still requires your click or binding. Combat casting remains disabled.

# BuffTap 1.16.9

- Fixed a solo-thanks path that could produce a general thank-you emote when the game could not resolve a caster by name.
- Added native GUID-to-unit lookup to recover a live buff provider where available. Automatic thanks now always requires a live recipient whose identity is checked immediately before the emote.
- When a provider is identified only by GUID/name, BuffTap skips the emote and reports that no live unit is available. It never changes your selected target or falls back to a general thank-you.

Existing settings and profiles are preserved. Every buff cast still requires your click or binding. Combat casting remains disabled.

# BuffTap 1.16.8

- Improved solo thanks with a verified aura-caster GUID fallback when the game does not provide a source unit. The provider can be resolved to a live player or a game-reported name without changing your target.
- Added safeguards against automatic thanks while stealthed, feigning death or chat-restricted, and excluded ignored players. Existing one-second spacing and the one-minute per-player cooldown are preserved.
- Added exact caster-GUID evidence to blessing ownership checks while retaining protection when ownership remains unknown.
- Improved cooldown validation to use public readiness information when timing values are hidden, and recover correctly when cooldowns change.
- Extended out-of-combat battleground self-buff checks to enabled Paladin seals and self-only Hunter aspects. Group-affecting aspects remain excluded, and hidden buff information is never treated as missing.
- Consolidated temporary failed-cast handling so Restore reminders clears the delay completely.
- Preserved unfinished numeric settings during refreshes and avoided unrelated options updates after bag changes.
- Reduced unnecessary aura scanning, clarified mana/cooldown status, improved debug information, and removed obsolete active settings and redundant lookups.

Existing settings and profiles are preserved. Every buff cast still requires your click or binding. Combat casting remains disabled. The client must provide readable identity and buff information; these changes do not bypass API restrictions.

# BuffTap 1.16.7

- Improved solo thanks by capturing the buff provider immediately when your helpful auras change, independently of the buff-selection cache.
- Solo thanks now accepts any helpful effect from another identifiable player, including short-duration effects, rather than a fixed spell list.
- Removed unnecessary eligibility checks that could prevent thanking a valid player. Improved full-name handling and rechecks the provider before directing an emote.
- Corrected reporting of the client emote result and added more specific debug reasons when the provider cannot be identified.
- Preserved one-second spacing between different players, the one-minute cooldown per player, and protections against duplicate or misdirected emotes.

Existing settings and profiles are preserved. Solo thanks remains limited to solo outdoor play outside combat. The game must expose the provider's identity; restricted or missing caster information cannot be recovered reliably.

# BuffTap 1.16.6

- Added a dedicated Nearby tab with independent controls for buffing, an optional all-players view, and party invitation shortcuts.
- Nearby players can remain listed after buffing. Buff candidates appear first, with stable arrival order, missing-buff icons and subdued inactive rows. Hovering keeps rows steady while you interact.
- Added compact party invite buttons beside players, or invite suggestions to the group leader when offered by the game. Available in either view; every invitation requires your click.
- Added a small grey/gold people icon to switch views and a queued-buff / nearby-player counter with tooltips.
- Kept a fixed-size five-row window with a scrollbar for up to 40 detected players. Invite buttons sit on the left and remain within screen limits.
- Current group members appear only while an eligible group-configured buff is queued. Strangers use Target preferences. New Nearby preferences participate in shared profiles.
- Improved Diagnostics with a contained scrolling report, clearer spacing and controls, and complete Nearby debug output. Fixed stale Nearby counts and removed redundant event handling.

Existing settings and profiles are preserved. Friendly player nameplates are required for Nearby. Every cast requires your click or binding, and combat casting remains disabled.

# BuffTap 1.16.5

- Improved solo-thanks detection and recovery from incomplete aura data. Tracks identifiable buff applications, replacements and refreshes, with brief retries for delayed caster information.
- Thanks different providers one second apart, with a one-minute cooldown per player. Short bursts are queued and duplicate providers are coalesced.
- Discards queued thanks when conditions change and verifies the caster before sending. Debug and Diagnostics include thanks status.
- Corrected Mark of the Wild rank selection for lower-level recipients using the ten-level allowance. Other spell families retain their existing rank rules.
- Clarified the unlearned group-spell label to explicitly name Gift of the Wild.

Existing settings and profiles are preserved. Combat casting remains disabled.

# BuffTap 1.16.4

- Nearby now detects changes to PvP flags and recipient combat state without movement. Unsafe recipients are removed even while a row is hovered, and rejected binding attempts refresh the next selection.
- Confirmed range and line-of-sight cast failures temporarily skip that recipient and spell for ten seconds, then retry automatically. Mana, cooldown and unrelated errors do not delay recipients. Failed rows do not remain stuck under the cursor.
- Added Soul Link's pet-applied aura (25228) to detection, including BG self checks. The cast spell remains 19028; restricted aura data still counts as unknown.
- Uses existing settings and profiles. No new settings or migration.


# BuffTap 1.16.3

- Added a battleground self-buff fallback while out of combat. Enabled self-castable class buffs are checked individually when normal aura scanning is restricted.
- Only verified missing self buffs are offered. Hidden or unreadable data is never treated as a missing buff. Existing blessings and related group-buff coverage are preserved.
- Rechecks buff state before casting and uses existing buff preferences and profiles. No profile migration is required.
- Debug output identifies BG self-only mode and unavailable self-buff information.
- Buffing other players remains unavailable while BG aura restrictions prevent verification. In-combat casting remains disabled.

BG self-buff support still needs live testing. Some spells may remain restricted. If a missing self buff is not offered while out of combat, please provide /bt debug output from inside the battleground.

# BuffTap 1.16.2

- Fixed corrupted punctuation in group spell labels and other options text.
- Fixed the Nearby window reopening after clicking its close button. Nearby still hides automatically during combat.

# BuffTap 1.16.1

- Retired Salvation, Mass Salvation and the Blessing of Light family from BuffTap. Removed Salvation options.
- Saved fixed assignments for retired blessings become Skip. Priority lists retain their remaining spells in order.
- Corrected the Righteous Fury fallback training level to 10 and Elixir of Wisdom's picker text to 3 Intellect for 30 minutes.
- WoW Forever interface remains 16001.

# BuffTap 1.16.0

## Nearby player buffing

- Optional compact Nearby window lists eligible nearby players with class-coloured names and missing-buff icons. Click a name or use your existing buff binding to apply the next buff.
- Friendly player nameplates must be enabled, normally with Shift+V. Enable it in the Target tab, or Shift-left-click the minimap icon to toggle Nearby. The feature starts disabled and follows your Target preferences.
- Movable, lockable window with stable rows and a scrollbar. Nearby casts restore your previous target and keep reminder sounds and the normal reminder icon quiet.
- Nearby skips players in combat. PvP protection also skips flagged or unreadable recipients. Every cast requires player input and remains out of combat.

## Reliability and clarity

- Keeps verified missing buffs visible but disarmed during cooldown, preventing the Nearby list from emptying after each cast.
- Refreshes the cast recipient's aura data after normal and nearby buffs, improving follow-up detection for spells such as Thorns.
- Watches each missing spell's range separately, so secondary buffs can become available without manually selecting the player.
- Distinguishes insufficient mana from no missing nearby buffs.
- Automatically skips confirmed stronger-effect rejections for nearby buffing, allowing another missing buff or another recipient. Restore reminders clears these skips. The normal stronger-effect helper remains optional.

General Nearby preferences follow named profiles. Class and Target buff preferences retain their existing character-specific behaviour.

Validation: 1,184 automated mocked Lua 5.1 scenarios passed, plus Lua syntax and package integrity checks. Nearby has been tested in game during the private beta. Automated tests do not establish behaviour under every client restriction.

# 1.15.5

Added exact-instance filtered blessing ownership evidence, conservative partial-aura coverage, and suppression-aware blessing priorities. Unknown ownership, unreadable identities, explicit assignments and own blessings remain protected.

Added default-on profile-aware PvP protection, 10-second failed-recipient retries, and explicit restricted-data/safety diagnostics. Group casts check affected members and retain safe single-target alternatives.

# 1.15.4

Improved friendly-target diagnostic reasons and bounded late-data recovery. Fixed disabled-fallback target selection bypassing own-blessing protection. Unknown ownership remains fail-closed.

# 1.15.3

Added a profile-aware Show reminder button toggle. Hidden mode preserves the buffing binding and optional audio without an invisible mouse-interactive area.

# BuffTap 1.15.2

Prepared for local in-game testing. Not published.

- Paladin Groups now opens with Party setup, or Raid when already in a raid. Both views can be configured before joining a group.
- Party class assignments and raid defaults are separate. Raid groups can inherit defaults or use their own class assignments or one blessing for everyone.
- Same blessing for everyone hides and overrides saved class and player choices. Returning to By class restores those choices.
- Raid group buttons show blessing icons, class-assignment icon clusters, inherited defaults and excluded groups. Use raid defaults removes only that group's override.
- Class and player selectors retain spell/class icons; inherited choices show the selected blessing instead of a generic settings icon. Player exceptions are highlighted when present.
- Greater Blessings still require agreement across the full affected class, including other raid groups. Conflicts or exclusions use individual blessings. Casting thresholds are under Casting.
- Removed the redundant Other group buffs route from Paladins. Blessings, Salvation recipients and casting thresholds remain on their current dedicated controls. Other classes retain their simpler existing per-buff group controls. No whole-window scrolling or live-roster redesign was added.
- Fixed open player lists not updating after roster changes. Inventory updates now refresh each visible options/picker window once; unrelated item completions are ignored.
- Removed hidden class-inappropriate assignment controls, unused widgets, obsolete exclusive-Salvation branches and stale/repeated comments. Plan lookups no longer repeatedly normalize settings.
- Added a compact Buffs recipient filters window for inherited blessing filters, without restoring the old page.
- Fixed malformed non-Paladin profile validation and removed profile snapshot copies from ordinary options refreshes. Profiles still save on entry, profile operations and logout.
- Existing class choices migrate into independent party/raid plans. Old effective party exclusions are retained until explicitly enabled from Party setup, independently of later raid G1 changes. A former G1 class override becomes the party choice while the original raid defaults remain intact. Plans are not reset on reload.
- Profiles keep these plans character-specific. Shared-profile switching/copy/reset leaves them intact. Optional same-class copying includes both plans, priorities and subgroup overrides, using independent copies. Cross-class imports are rejected. Session player exceptions are not imported and party/raid exception choices are separate.
- Salvation and Mass Salvation remain separate from blessings, using verified build 1.60.1.70425 IDs 1038 and 25895. Group, personal and friendly-target permissions are independent. Prior Salvation opt-ins pause on upgrade for review.
- Salvation recipients includes a dedicated player-exclusions entry, also accessible while uniform blessings are active. Never Salvation protection, class-wide safety, reagents and click-time checks remain enforced. Revoke remains manual.

Validation: 983 mocked Lua 5.1 scenarios passed, including roster UI updates, preserved exclusions, compact filter editing, single event ownership, malformed profile recovery, profile copy isolation, uniform-mode precedence, subgroup inheritance, combat guards and fixed-panel geometry. Shipped Lua and archive contents verified. Live casting and visual layout require in-game testing.

# BuffTap 1.15.1 - Named profiles

Prepared locally for in-game testing. Published stable remains 1.14.2. This release contains named profiles, not the discarded live roster beta.

- Clarified creation with Create & switch, explicit starting settings, confirmation before default creation, and a dedicated Rename dialog beside Active profile.
- New Profiles tab with active-profile selection, create from defaults/current preferences, copy, rename, reset and unused-profile deletion.
- Profiles share bindings, reminder appearance/position, sounds, minimap/Broker preferences and general reminder behavior. Existing characters are migrated to independent named profiles, preserving their setup.
- Buff selections, priorities, timing, target/group assignments, weapon/consumable/supply settings and class readiness stay character-specific when switching or copying shared preferences.
- Copying optionally includes a saved buff/class setup from a matching-class character. The checkbox appears only when a compatible source exists; the copy function independently rejects other or unreadable classes. Copied values pass through normal validation.
- Shared profile edits affect characters linked to it. Copy into a separate profile to keep independent preferences. Class copies are one-time imports, never live links.
- Temporary player exceptions, pause/dismissal state, caches and onboarding state are not imported. Individual player exceptions retain their existing group-session/reload behavior.
- Profile operations are blocked in combat. Switching refreshes the reminder and secure bindings immediately. Copy/reset/delete require confirmation; deletion is limited to profiles unused by known characters. Reset all settings detaches the current character rather than resetting another character's shared profile.
- Embedded unmodified AceDB-3.0 minor 39, with its license; no AceGUI/AceConfig dependencies. Profile controls and confirmations are localized in German, French, Spanish and Brazilian Portuguese.

Validation: 882 mocked Lua 5.1 scenarios passed. Coverage includes real database serialization/reload across characters, opt-in same-class copies, cross-class/unknown-class rejection, immediate binding replacement, migration backup recovery, reset isolation, combat guards, localization and panel geometry. Shipped Lua syntax, TOC paths and archive contents verified. Live client interaction/appearance remains for testing.

# BuffTap 1.15.0 - Named profiles

Prepared locally for in-game testing. Published stable remains 1.14.2. This release contains named profiles, not the discarded live roster beta.

- New Profiles tab with active-profile selection, create from defaults/current preferences, copy, rename, reset and unused-profile deletion.
- Profiles share bindings, reminder appearance/position, sounds, minimap/Broker preferences and general reminder behavior. Existing characters are migrated to independent named profiles, preserving their setup.
- Buff selections, priorities, timing, target/group assignments, weapon/consumable/supply settings and class readiness stay character-specific when switching or copying shared preferences.
- Copying optionally includes a saved buff/class setup from a matching-class character. The checkbox appears only when a compatible source exists; the copy function independently rejects other or unreadable classes. Copied values pass through normal validation.
- Shared profile edits affect characters linked to it. Copy into a separate profile to keep independent preferences. Class copies are one-time imports, never live links.
- Temporary player exceptions, pause/dismissal state, caches and onboarding state are not imported. Individual player exceptions retain their existing group-session/reload behavior.
- Profile operations are blocked in combat. Switching refreshes the reminder and secure bindings immediately. Copy/reset/delete require confirmation; deletion is limited to profiles unused by known characters. Reset all settings detaches the current character rather than resetting another character's shared profile.
- Embedded unmodified AceDB-3.0 minor 39, with its license; no AceGUI/AceConfig dependencies. Profile controls and confirmations are localized in German, French, Spanish and Brazilian Portuguese.

Validation: 876 mocked Lua 5.1 scenarios passed. Coverage includes real database serialization/reload across characters, opt-in same-class copies, cross-class/unknown-class rejection, immediate binding replacement, migration backup recovery, reset isolation, combat guards, localization and panel geometry. Shipped Lua syntax, TOC paths and archive contents verified. Live client interaction/appearance remains for testing.

# BuffTap 1.14.2 - Player exception usability

- Retains your own planned Paladin group exception during solo refreshes and after leaving a group. Solo maintenance still follows personal Buffs settings. Other players' exceptions remain group-session choices; all individual exceptions reset on reload.
- Replaces two-player Previous/Next paging with a five-player exception editor, mouse-wheel scrolling and a scrollbar. Supports all 40 recipients of the same class. Done, Escape and the class button close the editor.
- Keeps the established 1.14.1 options design. No beta roster redesign included.

Validation: 840 mocked Lua 5.1 scenarios passed, including solo retention, rejoining, all-40 scrolling, selection identity and closing. Syntax and archive contents verified. Live client interaction and visual verification remain pending.

Prepared locally; not published.

# BuffTap 1.14.1 - Find Treasure tracking

- Renamed the Helpers Gathering tracker section to Tracking.
- Added an independent, opt-in Keep Find Treasure active checkbox for characters who know the Dwarf racial ability. Gathering preferences remain unchanged; both reminders can be enabled together.
- Restores missing tracking through the normal player-triggered binding, with fresh tracking-state checks before use. Unknown tracking data does not arm an action.
- Localized the new controls in German, French, Spanish and Brazilian Portuguese.

Thanks to noci_ for the Find Treasure suggestion.

Validation: 834 mocked Lua 5.1 scenarios passed, including nine new tracking cases. All shipped Lua syntax and archive contents verified. Live Dwarf tracking verification remains pending.

# BuffTap 1.14.0 - Warlock stones and Soulstone

- Diagnostics displays the installed BuffTap version. Status and debug chat output already include it.
- Helpers places the emote picker beside Solo thanks and shows Class readiness with your Hunter or Warlock icon. Gathering tracker appears last, below readiness, with inset footer actions and comfortable bottom spacing. All settings stay visible without scrolling; full details remain in tooltips.
- Choose Firestone or Spellstone for your main hand in Weapons. Oils and other temporary coatings remain independent.
- In Remind and apply mode, BuffTap can offer creation when your chosen stone is missing, then application on a separate click. Creation requires a learned spell, Soul Shard and free bag space. Remind only stays informational.
- Soulstone target settings use an opaque, clearly separated popup and explicitly show that solo upkeep targets yourself. Use current target saves a friendly player and enables Assigned player for the current party/raid context; Clear restores the default modes. The popup stays open while making changes; press Escape or use Done to close it. It uses an interactive foreground layer without a full-screen click overlay.
- Enable Keep a Soulstone up in Helpers for optional creation and upkeep. Party targets can use a healer role, yourself or an assigned player; an unavailable party assignment falls back to a healer, then yourself. Raids default to a manual reminder, with explicit assigned targeting available.
- Soulstone placement rechecks inventory, cooldown, coverage, range and recipient identity. Unreadable ownership or group data suppresses the action. Forever assignments distinguish first names and surnames.

Thanks to **kristofdenolf1985-arch** for the Warlock contribution in [PR #2](https://github.com/Hitshade/BuffTap/pull/2). Original contributor commits are preserved. See CREDITS.md for attribution.

All casts and item uses require player input and remain out of combat. Soulstone upkeep is off by default; weapon stone creation/application requires Remind and apply.

Validation: 825 mocked Lua 5.1 scenarios passed, with independent client-data checks and package integrity verification. Live Warlock verification remains pending for enchant reporting, Soulstone item range/secure targeting and the creation hand-off. New Soulstone option strings use English fallback in other locales.

# BuffTap 1.13.2 — Solo response emotes

- Choose from 30 built-in directed emotes, including Thank, Bow, Salute, Fart, Burp and Mock. Thank remains the default.
- Solo thanks now has its own Helpers section, with compact gathering controls below.
- Choose an emote even while Solo thanks is off. The dropdown scrolls without a search box and closes when clicked again.
- Existing solo-only restrictions, provider checks and cooldowns remain. Posture-changing commands and custom chat are excluded.

Validation: 728 mocked Lua 5.1 scenarios passed; Lua syntax and package integrity verified. Live client verification remains pending.

# BuffTap 1.13.1 — Visual polish and cleanup

Consolidates the latest local 1.13.0 refinements into one versioned build.

- Compact image banner in options and onboarding; fixed foreground layering and unsupported Ready-status character.
- Native action buttons, explicit Close artwork, cleaner priority arrows, and aligned Weapons/Customization controls.
- Balanced Groups layout and Paladin-only Greater Blessings threshold controls.
- Removed unused PNG and three uncalled helpers; active compatibility paths retained.
- Includes the 1.13.0 convenience features: minimap quick controls, timed pause, onboarding, reminder fonts/colors and safe Edit Mode movement preview.

Validation: 719 mocked Lua 5.1 scenarios, Lua syntax and ZIP integrity checks. Live visual confirmation remains necessary. Not published.

# BuffTap 1.13.0 — Convenience and customization

- Right-click the minimap icon or broker display for Settings, Enable/Disable, temporary pause, Resume, and a safe reminder preview.
- Pause reminders for 5, 15, or 30 minutes without changing buff selections or bindings. The pause also quiets automatic stock alerts and solo thanks; it ends automatically and resets on reload.
- Move a harmless BuffTap preview while Blizzard Edit Mode is open. Its position is shared with Customization → Move icon. The protected casting button never participates in dragging.
- Actual compact banner artwork in options and onboarding, sharing one 512×256 RGB TGA. The visible banner is about 600×123 in options and 528×109 in onboarding; the existing options page area is preserved.
- Brief first-use guidance explains the current binding and minimap controls. Reopen it with Customization → How to buff.
- Built-in game-font choices and white/default, gold, cyan, and green label colors; defaults preserve the existing appearance.
- New menu and onboarding text localized in Spanish, German, French, and Brazilian Portuguese, with English fallback.

No group-composition tracker, additional buff display, new casting permissions, permanent polling, or additional library dependencies.

Validation: 669 isolated mocked Lua 5.1 scenarios passed. Live Forever Edit Mode positioning, translated layout fit, and font appearance require in-game verification. Edit Mode integration uses guarded OnShow/OnHide hooks and our own unprotected preview; it does not register a Blizzard system or save separate positions per Blizzard layout. If Edit Mode is unavailable, Move icon remains usable.

Local build prepared; not published. Latest published release remains 1.12.0.

# BuffTap 1.12.0

- Expanded game sound choices: Whisper ping, Alarm clock 1 and 3, and Quest complete, offered when the client exposes the corresponding sound constant.
- Optional LibSharedMedia-3.0 support for sounds registered by installed addons and media packs, including sound paths and FileDataIDs.
- Searchable sound pickers with a mouse-wheel scrollable list and native scrollbar; existing Preview controls and separate reminder/low-stock selections remain.
- Missing media selections remain saved and visibly unavailable; playback temporarily falls back to the default. Broken library calls and failed media playback are contained.
- No polling, bundled sound pack, forced dependency, or change to casting/buff selection.

Validation: 638 mocked Lua 5.1 scenarios passed. Added SoundKit IDs exist in the Forever 1.60.1.70009 database; named constants also gate availability at runtime. Native client listening and media-pack integration still need user verification.

# BuffTap 1.11.0

- Display actual icons for unlearned spells and group versions using verified Forever SpellMisc metadata; casting eligibility is unchanged.
- Mark unlearned spells in red and display opacity as a 0–100% field, retaining fractional saved values.
- Rename Appearance to Customization and clearly separate Binding, Reminder appearance, Sounds and Quick access.
- Replace ambiguous weapon application toggles with explicit Remind only / Remind and apply choices. Existing preferences and opt-in defaults are preserved.
- Sound and audio-channel selectors now show explicit lists instead of cycling. Weapon, oil/stone and demon selectors have visible dropdown arrows; reclicking closes menus.
- Add an event-updated status line to settings, including accurate manual-application status. Move header troubleshooting access to the existing Diagnostics page.
- Add saving guidance: immediate checkbox/list/slider changes, Enter or Escape for numeric fields, and clear Apply guidance for appearance fields.
- Correct consumable and target help; explain Automatic versus checked custom blessing priorities. Give the priority editor more space for its instructions.
- Preserve content space beneath the header and add localized primary labels for Spanish, German, French and Brazilian Portuguese.

Validation: 630 mocked Lua 5.1 scenarios pass, including explicit selection, close/reopen, combat protection and status updates. In-game visual confirmation remains pending. No buff selection, ownership, reagent or secure casting logic changes.

# BuffTap 1.11.0

- Display actual icons for unlearned spells and group versions using verified Forever SpellMisc metadata; casting eligibility is unchanged.
- Mark unlearned spells in red and display opacity as a 0–100% field, retaining fractional saved values.
- Rename Appearance to Customization and clearly separate Binding, Reminder appearance, Sounds and Quick access.
- Replace ambiguous weapon application toggles with explicit Remind only / Remind and apply choices. Existing preferences and opt-in defaults are preserved.
- Sound and audio-channel selectors now show explicit lists instead of cycling. Weapon, oil/stone and demon selectors have visible dropdown arrows; reclicking closes menus.
- Add an event-updated status line to settings, including accurate manual-application status. Move header troubleshooting access to the existing Diagnostics page.
- Add saving guidance: immediate checkbox/list/slider changes, Enter or Escape for numeric fields, and clear Apply guidance for appearance fields.
- Correct consumable and target help; explain Automatic versus checked custom blessing priorities. Give the priority editor more space for its instructions.
- Preserve content space beneath the header and add localized primary labels for Spanish, German, French and Brazilian Portuguese.

Validation: 630 mocked Lua 5.1 scenarios pass, including explicit selection, close/reopen, combat protection and status updates. In-game visual confirmation remains pending. No buff selection, ownership, reagent or secure casting logic changes.

# BuffTap 1.10.2

- Target and Groups class dropdowns now open the numbered blessing editor directly. Include blessings and use arrows to reorder in one panel; Automatic/Buff settings, Skip and Done remain in that panel.
- Opening and closing the editor does not change settings. Automatic, fixed and skipped choices are previewed; the first checkbox or arrow edit saves a custom list. Existing settings and player exceptions are preserved.
- Remove the intermediate selection menu and Custom priorities submenu for class controls. Individual player exceptions retain their appropriate single-choice selector.
- Preserve arrow-only ordering, simplified Paladin target controls, ownership checks and Greater Blessing safeguards.

Validation: 608 mocked Lua 5.1 scenarios pass. Live-client layout and two-Paladin confirmation remain pending. Not published.

# BuffTap 1.10.1

- Remove priority icon dragging and related controls/help. Use up/down arrows to arrange buffs and Paladin blessing lists.
- Simplify class-aware Paladin Target options: remove the redundant lower spell section. Checking a blessing in a custom list enables that blessing for target use independently of personal buff toggles. All class choices use the visible default target refresh setting.
- Automatic follows enabled Buffs settings; custom lists use exactly their checked learned blessings. Unlearned entries remain saved and are skipped. Existing personal buff settings are preserved.
- Group custom lists likewise enable their selected blessings without a second personal-buff gate. Shared raid-group exclusions, explicit player exceptions, ownership checks and Greater Blessing safeguards remain authoritative.
- Other classes retain their necessary target spell controls, clearly labeled Spell availability & refresh timing. Legacy Paladin controls remain accessible when class-aware mode is disabled.

Validation: 602 mocked Lua 5.1 scenarios pass. Live two-Paladin testing and native layout confirmation remain pending. Not published.

# BuffTap 1.10.0

- Arrange your main Buffs list by using up/down arrows. Applies to every class with maintainable spell entries; priorities update automatically and group/single ranks remain paired.
- Add independent per-class Paladin priority lists to Target and Groups. Choose Custom priorities in a class dropdown, check which blessings to include, and use arrows to order them. All five supported maintenance blessings may be included once. A compact summary shows the first choices; hover reveals the complete sequence.
- Fixed group class assignments and individual player exceptions retain precedence. Custom group priorities are opt-in. Existing settings are preserved; selecting Custom priorities seeds the existing preference first.
- Maintain your own blessing, skip healthy blessings supplied by other Paladins, and stop fallback when ownership is unknown or the caster cannot be verified. Tactical blessings are recognized for ownership safety only and never offered for maintenance.
- Use individual blessings when same-class fallback choices differ. Greater Blessings require agreement across the affected class, eligible recipients, and the configured reagent threshold. Fresh click-time checks cancel stale casts rather than substitute another spell.
- Target fallback can be disabled. Unlearned or disabled custom entries are skipped; empty lists offer no blessing. Automatic mode remains available.
- Use existing aura caches, bounded threshold wake-ups and a static blessing-ID lookup. No new polling, communication protocol, or libraries.

Validation: 600 isolated mocked Lua 5.1 scenarios pass. Live two-Paladin testing and options layout confirmation remain pending. No publication performed.

## 1.9.1

- Add ownership-aware Paladin friendly-target blessing fallback, with a Target toggle. Class preference is first; remaining enabled, suitable blessings follow Buffs priorities.
- Preserve own blessings and stop fallback when caster identity cannot be verified. Fresh click-time scans cancel stale recommendations. Group assignments remain authoritative.

# BuffTap 1.9.0

- All Paladin seals now start off; explicitly saved seal choices are preserved. Tactical combat abilities remain excluded.
- Refined Paladin assignment controls with native dropdown arrows, icons, selection checks, clearer labels, and distinct player-exception expansion. Re-clicking an expanded class now closes it. Inactive group/target controls are dimmed and explained; paging appears only when needed. Buff timing and priority controls include clearer help.
- Friendly-target Paladin blessings now consider the recipient’s class before selecting from enabled buff priorities. Customize each class independently in Target, choose Skip, or disable class-aware selection to retain unrestricted priorities.
- Grouped targets still follow enabled party/raid blessing assignments and player exceptions. Automatic target choices avoid inappropriate Might/Wisdom suggestions; explicit class choices can override suitability. Unlearned or disabled target choices fall back to Automatic without deleting the saved preference.
- Added an optional Helpers → Reminder behavior setting to pause reminders in cities and inns using the client’s resting state. Disabled by default.
- Mounting now also quiets stock badges, automatic stock messages, ready-check summaries, and alert sounds. Settings access remains available; sound previews and explicitly requested stock reports remain usable.
- Pause/resume updates are event-driven. Prepared blessings are revalidated before use, and pet-return grace after dismounting is preserved.

Validation: 531 isolated mocked Lua 5.1 scenarios passed, including 53 new cases. Live-client confirmation of target preference layout, Paladin target choices, and city/inn/mount transitions remains required. No periodic location polling or new libraries.

# BuffTap 1.8.1

- Fix an options/diagnostics error when an oil or stone reminder lacked its weapon-hand label, including out-of-stock reminders.
- Ensure main-hand and off-hand coating reminders carry readable hand labels.
- Handle incomplete action display metadata safely in diagnostics.
- Include the shortened addon overview.

Validation: 478 mocked Lua 5.1 scenarios passed, including three new regression cases. Live-client verification of this hotfix remains pending.

# BuffTap 1.8.0

- Added 15 verified Mage imbue scroll choices in Weapons, with compatible staff, dagger or sword checks. Main-hand only; preferences start at None.
- Scrolls use your existing BuffTap click/scroll binding and stay separate from oils/stones. Optional Supplies warnings include the selected compatible Mage scroll.
- Added Crippling Poison II, including highest usable carried rank selection and enchant recognition.
- Fixed bag updates for selected oils/stones on every class and Mage scrolls, including restocking an idle reminder.
- Bounded item-data loading to three attempts with backoff. Retries suspend during combat; successful loads release cached metadata.
- Added Retry reminders in Consumables and Weapons. An unobserved flask/elixir effect gets a second check before its family pauses, preventing Auto from offering another item. Retry restores reminders without reloading; changed item mappings remain blocked.
- Bounded the class weapon picker, added translated retry controls, and removed an overwritten food-aura table.
- Includes the prepared minimap button, opt-in broker display, and all-class oils/stones from 1.6.0–1.7.0.

475 mocked Lua 5.1 scenarios passed. Prepared locally; not published. In-game Mage scroll application and visual checks remain pending. Spellbreak remains excluded because its name and live mapping disagree.

# BuffTap 1.7.0

- Added separate per-hand oil and stone preferences in Weapons for every class, alongside existing Rogue poisons and Shaman imbues.
- Supports Wizard/Mana Oils, leveling sharpening stones and weightstones, Elemental Sharpening Stone, Frost Oil and Shadow Oil.
- Reuses the normal scroll/click binding, missing/expiry reminders and safe replacement controls. New preferences default to None.
- Enforces client weapon restrictions and preserves separate enchant categories. Unknown effects are never overwritten automatically.
- Optional Supplies warnings track selected oils/stones; multi-use oils count remaining applications. Shared hand choices count once.
- Includes the previously prepared minimap button and opt-in broker display from 1.6.0.

444 mocked Lua 5.1 checks passed. Live weapon application/stacking and layout verification remain pending. This build is prepared locally and not published.

# BuffTap 1.6.0

- Added a draggable minimap settings button, enabled by default, with saved positioning and standard LibDBIcon support.
- Added an optional LibDataBroker display, disabled by default. Shows the next queued reminder and its recipient using existing cached status, without additional buff scans.
- Independent controls in Appearance → Quick access allow either display, both or neither. Broker bars require a separate display addon; disabling an already registered broker requires a UI reload.
- Clicking either display opens settings; neither casts spells. Settings remain unavailable during combat.
- Bundled upstream LibStub, CallbackHandler, LibDataBroker and LibDBIcon with their original notices.
- BuffTap remains uncategorized in the addon menu.

Validation: 420 mocked Lua 5.1 scenarios passed. Live placement, translated layout and compatibility with minimap managers and broker bars still require in-game verification. Not published.

# BuffTap 1.5.0 — Alerts and localization

- Groups clearly separates Shared group settings from Per-buff customization, with recipient-scope guidance and a labeled buff selector. Casting and assignment behavior are unchanged.
- Automatic client-language detection and first-pass Spanish (Spain/Latin America), German, French and Brazilian Portuguese translations. 212 messages per language; missing translations and technical diagnostics retain English. No language selector or added library dependency.
- Client-provided spell and item names in options when available; item picker searches localized names as well as catalog names and IDs. Catalog IDs, saved keys, aura matching and casting decisions remain unchanged.
- Independent buff-reminder and low-stock sound choices, using supported client sound constants. Click the sound name to cycle choices, then Preview to listen. Defaults preserve the existing sound and disabled sound toggles.
- Master / sound-effects channel selection and a 5–60-second shared minimum audio interval. Previews ignore alert toggles and do not consume live alert cooldowns. Supply warnings still notify on shortage episodes rather than recurring polling.
- Safe appearance preview for size, opacity, labels, timers, group count, glow and pulse. Click it to close; changing tabs, closing options or entering combat also closes it. It cannot cast or install bindings.
- Confirmation before resetting all settings through the options interface. Cancel, closing options or changing tabs preserves preferences. The explicitly typed /bt reset command remains direct.
- Plain-language status summary and Check now action on Diagnostics; no speculative explanation of why an individual recipient was excluded.
- Includes the prepared 1.4.0 Paladin assignments and shared UI refinements.

Validation: 412 mocked Lua 5.1 scenarios passed. This includes format checks across all four dictionaries, Spanish locale aliases, unknown-locale fallback, localized names/search, audio throttling, preview isolation, reset protection and layout bounds. Client sound availability/playback, translated text rendering and native-speaker review remain pending. Prepared locally; not published.

---

# BuffTap 1.4.0 — Blessings made clearer

## New
- Paladin class blessing assignments inside Groups: choose a blessing for each recipient class, inherit existing settings, or skip a class.
- Expand a class for individual player choices and a Never Salvation safeguard. Exceptions use player identity and last until you leave the group or reload.
- Clear casting status explains when Greater Blessings are allowed, assignments conflict, or the chosen spell is unavailable. Learned game spells and native class/spell icons are used.
- Explicit class assignments start disabled, preserving existing settings. Solo personal settings and ungrouped target preferences remain independent; grouped targets follow enabled assignments.

## Safety and efficiency
- Greater Blessings require matching choices across affected same-class group members. Mixed choices, skipped/excluded members, and protected Salvation recipients use individual blessings.
- Group need thresholds still count verified recipients of the same spell rank; click validation cancels an outdated suggestion instead of substituting a spell on that input.
- Healthy matching blessings from other Paladins count as coverage. No automatic spec guessing, inspection, shared assignments or chat coordination.
- Uses existing event-driven roster and aura caches; no new recurring polling.

## Interface
- Refined header: left-aligned logo/title, aligned controls, native red Close artwork, roomier tabs sized for their labels; preserves the page area and screen scaling.
- Consistent dark cards, subdued gold borders, clearer buttons and compact rows throughout the options pages and item picker.
- Shared group settings remain visible above the buff editor. Paladins can still access existing buff filters.
- Weapons remains before Appearance; Helpers precedes Diagnostics.
- Class rows stay visible with one inline exception section open. Large class rosters page two players at a time within that section.
- Window scales to smaller screens.

Validation: 383 mocked Lua 5.1 scenarios passed, including 38 assignment/UI cases and three header regressions and layout-bound checks. Actual client visuals, blessing overwrite behavior, and secure casting still require in-game verification. Prepared locally; not published.

---

# BuffTap changelog

## 1.3.0 â€” Supply warnings and smarter group recasts

- Optional Supplies controls are integrated in Consumables. Track your selected Rogue poisons, food buffs, flasks and elixirs with per-supply warning minimums and desired quantities.
- Separate stock indicator plus optional private chat alerts, sound and ready-check supply summaries. Stock alerts can be snoozed for ten minutes. All new features start disabled.
- Usable poison ranks are combined and shared hand preferences counted once. Explicit consumable preferences remain unchanged when out of stock.
- Empty, low, unusable, loading and unreadable stock are distinguished. Unknown data never generates an empty-bag warning; mismatched item effects do not count as supported usable supplies.
- Reagent-consuming group buffs now recount eligible recipients at the click. An obsolete group cast cancels safely; a new suggestion requires the next click or binding input.
- Group ranks no longer combine incompatible recipients to meet group spell thresholds. Existing healthy group-buff coverage remains respected across all supported classes.
- Stock checks use coalesced inventory events and caches, with startup/combat safeguards. No new recurring polling, purchasing, bank/alt tracking, or cross-player coordination.

Group/recovery reagent stock warnings and Reagent Economy detection are deferred because the hidden active perk state is not yet verified in Forever. Existing reagent checks and Healthstone/pet behavior are unchanged. Oils, stones and Mage imbue scrolls remain outside automatic weapon application.

Validation: 342 mocked Lua 5.1 scenarios passed, including 108 new stock and group-recast cases. Ten runtime Lua files loaded successfully. Live UI rendering and actual native API/cast behavior require the checks in docs/RELEASE-REVIEW-1.3.0.md. Prepared locally; not published.

## 1.2.1 â€” Weapon options and reliability cleanup

- Moved Weapons immediately before Appearance in the main options window.
- Hid weapon-specific controls and explanatory labels for unsupported classes; kept the class availability message.
- Uncached Rogue poison spell data now requests loading and recovers through the existing item-data event.
- Unified item-loading request timestamps across weapons, consumables, and optional discovery; failed requests can retry without adding polling.
- Preserved valid saved weapon preferences when player-class information is temporarily unavailable during initialization.
- Consolidated manual weapon-selection helpers and centralized tab indices so Helpers and Diagnostics shortcuts continue opening the correct pages.

Validation: all 234 mocked Lua 5.1 scenarios passed, including six new regression scenarios. All nine runtime Lua files load during these checks. The release ZIP is verified against the source and manifest. Live weapon application and Rogue off-hand targeting remain unverified in this review; use the existing in-game checks before publication.


## 1.2.0 â€” Scroll-to-apply weapon buffs

- New integrated Weapons options page with native icons, preferred buff selectors, and poison stock availability.
- Opt-in scroll/click application for learned Shaman main-hand imbues and supported carried Rogue poison items on either hand.
- Separate Rogue hand preferences; Shamans maintain their single main-hand weapon. Shields, held off-hand items, and fishing poles are excluded.
- Choose a refresh threshold from 0 to 300 seconds. A different existing buff is preserved unless replacement is explicitly enabled; unknown effects remain manual.
- Uses Forever's weapon-enchant categories so an oil cannot satisfy a missing Shaman imbue. Permanent enchants never satisfy weapon-buff reminders.
- Schedules threshold/expiry checks through the existing wake timer; no new polling loop. Bag restocks and metadata-load events restore ready poison actions.
- Revalidates preferences, weapon identity, stock, usability and cooldown before arming/clicking; clears weapon targeting on combat entry and when returning to ordinary buffs.
- Weapon application starts disabled, preserving existing manual-alert behavior. Open `/bt` â†’ Weapons, choose preferences, and enable Apply through scroll / click.

Validation: 228 mocked Lua 5.1 scenarios passed (189 prior plus 39 weapon scenarios). Live-client application, especially Rogue off-hand targeting and the options layout, needs an in-game smoke test before publication.

## 1.1.2 â€” Mouse-button bindings

- Added middle-click and side-button binding capture in options, including Shift/Ctrl/Alt combinations.
- Left/right click requires a modifier; clearer instructions explain the available inputs.
- Existing secure casting and combat restrictions remain in place. No polling or background scanning added.
- Based on juan-medina's GitHub PR #1, with input validation and expanded regression scenarios.

All 189 mocked Lua 5.1 scenarios passed, including eight new mouse-binding checks. Package integrity verified; live-client verification remains outstanding.

## 1.1.1 â€” Runtime efficiency

- Reused normalized aura and consumable names to avoid repeated string work during refreshes.
- Disabled pet and Healthstone helpers now bypass class queries; successful class detection is cached for the character.
- Player-only power and spellcast events use filtered registration when supported, with full-event fallback for compatibility.
- Optional readiness events use the same safe filtered registration and fallback behavior.
- Avoided reminder-key and diagnostic-string work when those features are inactive.
- Preserved existing aura and roster cache lifetimes, friendly-target response timing, weapon-reminder behavior and bindings.

This maintenance build received Lua syntax/load and package-integrity checks. The Python regression suite was intentionally not run for this build.

## 1.1.0 â€” Class readiness

- New optional Hunter and Warlock pet readiness in the main Helpers tab; disabled by default.
- Warlocks choose a learned preferred demon. Any living pet satisfies the reminder; Demonic Sacrifice suppresses summons.
- Hunters can revive a visible dead pet with one tap. An absent assigned pet gets a manual call/revive reminder because its life state cannot be reliably verified.
- New optional personal Healthstone preparation for Warlocks. Offers the highest learned creation spell only when no supported Healthstone is carried, a Soul Shard is available, and general bag space is verified. Never consumes a Healthstone.
- Recovery actions respect combat, mount/vehicle state, casting, movement and existing queue priorities. Inventory results are cached; pet transitions and cast retries use bounded event-driven delays.
- Compact class-specific controls, explanations and native spell icons are integrated into Helpers. Existing saved preferences remain intact.
- Rebuilt the class catalog from Forever client spell, skill, level, effect and reagent tables. Corrected missing Seal of Righteousness, Seal of Fury and Trueshot ranks, Demon Armor rank membership/levels, and poison application/recipe records.
- Updated current documentation and MPL 2.0 license scope for the replacement catalog. Earlier releases remain unchanged.

181 mocked Lua 5.1 regression scenarios pass. Live-client pet transitions, Healthstone creation and the compact Helpers layout still need in-game verification.


## 1.0.0 â€” Smart buffing, fewer chores (2026-09-27)

- Automatic missing/expiring buff checks and one-tap spell/item preparation, with player input required for each use.
- Configurable personal, friendly-target, party and raid buffing; per-buff class/group filters, priorities and smart group-spell thresholds.
- Food, flask and elixir preferences with a searchable picker, quick bag choices and saved out-of-stock selections.
- Integrated Helpers tab with visible explanations for dismissal, stronger-effect error suppression, gathering tracking, party coverage, unknown-consumable discovery and optional solo thanks.
- Solo thanks is opt-in, requires an identifiable friendly player caster, and stays off in parties, raids, instances and combat. Global and per-player cooldowns prevent repeated thanks.
- Removed potion inventory tracking and its 85-item inventory-only catalog. Existing potion settings are cleared on upgrade; food, flask and elixir choices remain intact.
- Rogue/Shaman missing-coating reminders remain manual-only. No automatic poison application or camp interaction.
- Fixed Shadow Protection party coverage and clarified unselected gathering tracking.
- Stronger-effect suppression now requires a matching spell-failure event as well as the error message.
- Removed obsolete potion-only guards and corrected historical changelog formatting.
- Updated README and CurseForge description for the 1.0.0 feature set.


## 0.10.0-beta2 â€” Integrated helper options (2026-09-27)

- Replaced the separate helper window with a Helpers tab in the main options. `/bt helpers` selects that tab.
- Added visible plain-language descriptions beneath every helper toggle, explaining actions, limits and how to undo dismissals.
- All helper settings fit on one page. Discovery report and rescan controls now live in Diagnostics, with a shortcut from Helpers.
- Gathering choices display native icons and are disabled until the tracking reminder is enabled.
- Existing saved preferences and buffing behavior are unchanged.
- 122 mocked Lua 5.1 regression scenarios pass. In-game visual verification remains pending.


## 0.10.0-beta1 â€” Optional helpers (2026-09-27)

- New Helpers window; all new features are independently opt-in and default off.
- Temporary reminder dismissal with manual restore and zone-change reset; group and single versions share a family. Group casts respect dismissed recipients.
- Recent stronger-effect errors can suppress the responsible BuffTap action until restored.
- Quick consumable preference panel with native icons, bag counts and six choices per page. Selection prepares a preference; the main icon remains the only item-use action.
- Explicit gathering-tracker preference, checked again before its secure cast.
- Separate five-player party coverage information; unknown auras are not reported as missing and no chat is sent.
- Event-driven unknown-consumable report with bounded metadata requests. Does not create unverified item actions.
- Optional automatic targeted thanks for recognized buffs received solo in the open world. Requires a verified other player caster; no party, raid, instance or combat messages. 60-second global and 10-minute per-player limits.
- Updated README and CurseForge description emphasizing automatic checks, one-tap convenience and customization without claiming unattended casting.
- Existing consumable defaults, Paladin priorities and manual weapon application are preserved.

Beta: mocked tests pass; real-client UI, caster attribution and emote availability still require validation. No live release was published.


## 0.9.5 â€” 2026-09-25

- Redesigned options with charcoal panels, restrained gold accents, readable secondary text, and neutral action buttons.
- Consumable rows keep the chosen item, native icon, bag count, timing, and Choose action aligned. Auto counts describe the currently preferred item.
- Replaced paginated item buttons with a searchable eight-row scrolling catalog, in-bags filter enabled on opening, native icons, stock counts, effect tooltips, and persistent selected-item summary. Turn off In bags only to choose absent items.
- Auto and specific items are mutually exclusive; selection applies immediately and Done closes the chooser. Absent choices stay saved.
- Party/raid assignments use a buff list and detail pane with native spell icons, full class names, All classes and Reset. Shared group defaults and thresholds expand below the pane.
- Existing buff logic, Paladin sorting, food database, opt-in defaults, manual weapon coatings, and camping behavior are unchanged.
- 88 mocked Lua 5.1 scenarios pass. Real-client rendering and interaction testing remain required.

## 0.9.4 â€” 2026-09-25

- Expanded verified food choices from 2 to 102, including Herb Baked Egg and leveling foods. Added exact resulting buff IDs and 67 eating-state IDs.
- While food reminders are enabled, recognized eating pauses the reminder queue so class buffs do not interrupt a meal. Existing food buffs remain protected under the configured refresh timing.
- Added 59 elixir choices with one explicit selected-item reminder. Any recognized active elixir is preserved until it expires; no stacking rules are assumed. Existing Ferocity preferences are retained.
- Added 85 potion inventory choices. Potions are tracked in options and always used manually; no potion secure action is generated.
- Added a searchable dropdown with selection checkmarks, pagination, an In bags only filter, effect tooltips, and Out of stock status. Selected unavailable items remain selected and do not substitute another item.
- Bag changes refresh visible counts; inventory and coverage caches avoid periodic scans. Food and flask Auto selection remains available. Consumables remain opt-in.
- Camping and weapon application are unchanged. 82 mocked Lua 5.1 scenarios pass; in-game eating, items and dropdown layout require validation.

## 0.9.3 â€” 2026-09-25

- Compacted the options header and Party & Raid controls without reducing the main window size or font sizes.
- Removed the Party & Raid assignment scrollbar. All current class assignment lists fit at once, including five Paladin blessing families.
- Compact class labels have full-name hover help; each buff retains group checkboxes, threshold, class toggles, and Reset.
- Buff selection and filtering behavior are unchanged. All 70 mocked Lua 5.1 scenarios pass; in-client visual confirmation remains pending.

## 0.9.2 â€” 2026-09-25

- Fixed friendly-target Thorns being skipped on classes such as Shaman and Warlock. Explicit friendly targets now ignore party/raid class and group filters for all supported target buffs.
- Added per-buff recipient-class checkboxes and Reset classes to Party & Raid options. Recipients must match both group and class; parties use G1. Defaults preserve previous class preferences.
- Personal buff maintenance stays independent of group class assignments.
- Paladin blessings retain configured priority and one-family selection. Greater Blessings share their single-target class settings; group casts fall back to single-target casts when filters would be bypassed.
- 70 mocked Lua 5.1 scenarios pass. In-game casting and options layout still require testing.

## 0.9.1 â€” 2026-09-25

- Fixed an unreadable main-hand enchant state suppressing a definite missing off-hand coating warning.
- Treats an inventory item ID of zero as an empty hand.
- Reuses an unchanged manual-alert display without clearing and rebuilding the empty secure payload.
- Keeps all ready spell and consumable actions ahead of a manual coating warning.
- Corrected three catalog IDs: Nature's Grasp rank 6, Lightning Shield rank 4, and removal of Hunter's Mark from Aspect of the Hawk.
- Added verified fallback levels for current Water Shield, Aspect of the Beast, and Seal of Fury records.
- Updated the mixed-license scope for 0.9.1 and included `WeaponCoatings.lua` explicitly.
- 60 mocked Lua 5.1 scenarios pass. Live Rogue/Shaman weapon-event testing remains necessary.

## 0.9.0 â€” 2026-09-25

- Added event-driven, manual-only missing weapon-coating alerts for Rogues and Shamans.
- Tracks equipped main-hand and off-hand weapons separately, ignores shields and nonweapon off hands, and lets each hand be enabled independently.
- Coating alerts never receive a secure action or temporary BuffTap binding; poison and imbue application remains manual.
- Uses Forever's structured temporary-enchantment API plus weapon/enchant events without tooltip parsing or permanent polling.
- Added exact recognition of the ten hidden Camp Benefits addition auras and displays their names in options and diagnostics.
- Kept class buffs ahead of manual coating alerts and retained conservative fail-closed behavior when equipment or enchant state is unreadable.
- 55 mocked Lua 5.1 scenarios pass. Real-client weapon event behavior and visual layout still require smoke testing.

## 0.8.1 â€” 2026-09-25

- Fixed consumable mouse clicks being blocked between input phases; settling now follows observed use.
- Preserved friendly-target refresh timing when validating clicks.
- Corrected group-vs-single priority, range-aware group counts, Greater Blessing conflicts, and group reagent checks.
- Pinned food/flask/elixir use and aura IDs to Forever 1.60.1.70009; reject incomplete metadata and quarantine changed or unobserved non-food effects locally. Auto can try another supported item.
- Added optional Water Shield support and current Aspect of the Beast / Seal of Fury ranks; retained known-spell checks.
- Cancelled obsolete timers, ignored unrelated target/aura/data events, and bounded spellbook retries.
- Hardened saved settings and restricted aura reads. Added a main enable control, compact bag counts, small-screen scaling, and clearer options spacing.
- Adopted MPL 2.0 for original code; preserved the original catalog permission and notice for that release.
- 48 mocked Lua 5.1 scenarios passed. In-game smoke testing remains necessary.


## 0.8.0 - Consumables foundation

- Added an opt-in Consumables tab with curated food, flask, and Elixir of Ferocity reminders.
- Consumables use the same secure BuffTap button and binding, but only for explicitly whitelisted item IDs.
- Added event-driven bag count caching; no bag polling or nearby-player scanning.
- Added conservative effect-family tracking: any recognized Well Fed satisfies Food, and any current known flask satisfies Flask.
- Added separate consumable rebuff thresholds and preferred-item selection.
- Added bounded post-use settling windows so food cannot be repeatedly offered while Well Fed is being acquired.
- Added passive Camp Benefits detection (spell 1229741) as recognition-only status. BuffTap does not infer individual camp benefits or interact with camp objects yet.
- Added secure item pre-click revalidation, cooldown/usability checks, and fail-closed handling for missing or unreadable item APIs/data.
- Expanded diagnostics and profiler counters for consumable work.
- Curated Forever data is tagged to client database build 1.60.1.69913.

## 0.7.0 - Dedicated friendly-target buffing

- Moved friendly-player target buffing out of the Groups page into its own **Target** tab.
- Added per-buff target-mode enable/disable controls.
- Added a separate target-mode refresh threshold from 30 seconds to 30 minutes, with optional per-buff overrides.
- Target-mode timing remains independent from normal solo/party/raid rebuff timing and is still capped at half of the aura's full duration.
- Added two one-shot settling retries after `PLAYER_TARGET_CHANGED` to handle brief target metadata/aura propagation delays seen in beta/service conditions.
- Target changes now clear the previous secure action before rebuilding the new target action.
- Reduced the current-target aura cache lifetime and force-invalidates it during settling retries so stale target snapshots do not linger.
- Added target-settling work to diagnostics/performance counters.
- Split long rebuff/cooldown wake timers from short event-debounce timers so routine aura events no longer churn long-lived callbacks.
- Runtime work counters remain disabled unless the optional profiler is enabled.
- Restored a hard 48-entry cap on pathological out-of-range watch lists.
- Kept friendly-target scanning event-driven: no nearby-player scans, nameplate sweeps, or permanent polling loop were added.
- Added `/bt targetrebuff <seconds>` and `/bt targetrebuff <buff> <seconds>` for testing.

## 0.6.1 - Friendly target quick buffing

- Added optional **Buff friendly player target** mode for quickly buffing friendly players you click in the world.
- Friendly-target mode uses only single-target spells and takes priority while a valid friendly player is targeted.
- Added immediate `PLAYER_TARGET_CHANGED` revalidation so the secure button cannot carry a stale spell onto a newly selected target.
- Reuses the existing aura cache, exact spell-range checks, and event-driven refresh path; no new polling loop was added.
- `UNIT_AURA` watches the current target only while friendly-target mode is enabled and the target is friendly.
- Fixed the recipient label so **Show buff recipient** also displays self actions instead of appearing to do nothing when BuffTap selected the player.
- Added `/bt target on|off`.

## 0.6.0 - Hardening, range awareness, and efficiency pass

- Removed redundant per-buff raid-assignment reset buttons and added checked/unchecked/mixed master group states.
- Added clearer group-spell icon/name information and per-buff smart-group `Need` thresholds.
- Added exact spell-specific range filtering with a spellbook fallback; unreachable members are skipped without estimated-distance heuristics.
- Completely missing buffs now outrank merely expiring buffs; expiring targets are ordered by shortest remaining duration.
- Added optional remaining-time and group-count overlays to the reminder.
- Added a Diagnostics & Performance tab with runtime work counters and an opt-in session profiler.
- Reworked refresh scheduling around coalesced timers/events instead of a permanent high-frequency polling loop.
- Added batch/cached aura reads, roster caching, and rank-resolution caching to reduce repeated API work.
- Limited exact range checks to missing/expiring candidates and uses a lightweight active-target range heartbeat only when needed.
- Hardened timer/event/refresh paths with protected error handling, cache invalidation, secret-value checks, and combat-safe deferred refreshes.
- Migrated the older reminder overlay settings to the 0.6 names automatically.

## 0.5.1 - Raid assignment behavior cleanup

- Renamed the per-buff `Global` action to the clearer `Default`.
- Per-buff overrides now disappear automatically when their selections match the raid-group defaults.
- The `Default` button only lights when that row actually differs from the defaults.
- If every per-buff row is manually changed to the same value for a raid group, that common value is promoted back to the master default automatically.
- Changing a raid-group default now clears stale overrides that have become identical to the defaults.
- Updated the Groups-tab help text to better explain inherited versus customized assignments.

## 0.5.0 - Per-buff raid assignments and reminder polish

- Fixed per-buff **Default** buttons so they enable immediately after a custom rebuff threshold is set.
- Added per-buff raid group assignments. Each buff inherits the global group selection until individually customized.
- Added a one-click **Global** reset for each buff assignment row.
- Group scanning now evaluates all roster members and applies the assignment for the specific buff being considered.
- Added optional buff-name and target-name labels around the reminder icon.
- Kept self-buffing independent from raid assignments so BuffTap can still maintain the player's own buffs.

## 0.4.0 - Smarter timing controls

- Added per-buff rebuff thresholds from 15 seconds to 3 minutes.
- Kept a global default threshold for buffs without a custom value.
- Added spell icons and reorganized the Buffs page into clearer Buff, Rebuff, and Priority columns.
- Added configurable smart group thresholds for party/raid group spells and Greater Blessings.
- Added `/bt rebuff <buff> <seconds>`, `/bt groupneed`, and `/bt blessingneed` commands.
- Preserved the half-duration safety cap for short-duration buffs.

## 0.3.3 - Forever event and debug cleanup

- Removed redundant events that WoW Forever reports as unsupported: `PLAYER_UNGHOSTED` and `LEARNED_SPELL_IN_TAB`.
- Clarified binding diagnostics so the normal WoW binding and BuffTap's secure override are reported separately.
- Debug output now reports whether each BuffTap secure override is active, inactive, or failed.

## 0.3.2 - Priority numbering fix

- Buff priorities now start at 1 for each class.
- Group and single-target versions of the same logical buff share one priority.
- Priority values entered through the UI or slash command are clamped to 1 or higher.

## 0.3.1 - UI and rebuff timing test build

- Added a 15-second to 3-minute rebuff threshold slider with a 45-second default.
- Added BuffTap to the in-game Settings > AddOns menu, with a legacy Interface Options fallback.
- Kept `/bt` as a quick way to open the full BuffTap window.
- Fixed tab/header spacing and the Buffs-page footer alignment.
- Added a visible Priority label for the buff order fields.
- Preserved the 0.3.0 party/raid assignment and smart group-buff behavior.

## 0.3.0 - Group buffing test build

- Added party and raid buff scanning.
- Added selectable raid group assignments (1-8).
- Added smart group-buff selection with single-target fallback.
- Added class-wide handling for Greater Blessings.
- Redesigned the settings window into Buffs, Groups, and Appearance tabs.
- Added group assignment and smart-group slash commands.
- Preserved the existing secure one-tap casting path and BuffTap branding.

## 0.2.0

- Added BuffTap artwork and addon icon support.
- Redesigned the initial settings interface.
