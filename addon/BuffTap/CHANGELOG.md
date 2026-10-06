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
