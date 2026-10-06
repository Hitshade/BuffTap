# BuffTap 1.8.0 implementation and release review

## Implemented

The four confirmed 1.7.0 review findings are corrected: inventory events now refresh selected weapon consumables on all classes; metadata requests have finite backoff; Crippling Poison II is included; and an unobserved consumed flask/elixir effect gets a second readable observation then a recoverable pause. The whole consumable family pauses, including Auto alternatives, to prevent another flask from being offered accidentally. Retry reminders clears effect pauses and failed metadata state/cache, but does not clear item-use-spell mapping quarantine or pending-use settling.

Metadata loads are limited to three requests separated by 10 and 30 seconds, with a final bounded timeout. Failures do not clear backoff or force bag recounts. Combat entry cancels retry timers; combat exit resumes eligible outstanding attempts. Successful completion cancels the retry slot and invalidates cached Healthstone metadata as well as ordinary item metadata. No repeating polling or new OnUpdate handler was added.

## Mage scrolls

15 verified items from research/mage-and-coating-review-1.7.0/mage-scroll-candidates.json are implemented as explicit Mage-only main-hand preferences. Source: client 1.60.1.70009 DB2 export, cross-checked against Forever item tooltips during the preceding research pass. Staff: Lesser Flame, Frost, Striking, Baleflame, Accuracy, Quickening, Balefrost, Flame, Greater Flame, Greater Frost and Precision. Dagger: Chillknife, Iceknife and Manablade. Sword: Spark.

Class/weapon restrictions, item-use spell identity, stock, usability, cooldown and readable modern Imbue category are required. Click-time revalidation checks current preference, exact item, equipped weapon and effect state. Different recognized imbues are preserved unless replacement is enabled; unidentified imbues can only produce a manual reminder. The application still requires player input and remains blocked in combat. Oils/stones retain their separate Temporary category and optional per-hand choices.

Spellbreak (277503) is not included: its name conflicts with the currently returned Lesser Flame use/enchant mapping. Unconfirmed shield/event/season items remain excluded. The attempted newer client export was denied, so no unsupported availability claims were made.

## Cleanup and scope

Removed the overwritten small EatingSpellIDs table; retained the complete data. New retry controls are translated for esES/deDE/frFR/ptBR with English fallback. The class-imbue selector uses a bounded scroll list. Existing secure safety snippets, punctuation bindings, tested thank emote, sounds and guarded settings fallbacks remain intact. Optional slider InitDB refinement, unused helper removal and addon-compartment integration were not mixed into this correction release.

## Validation

475 isolated mocked Lua 5.1 scenarios pass (444 existing + 31 release cases). Every one of the 15 Mage scroll mappings prepares its verified item and recognizes its exact imbue. Checks cover incompatible equipment, main-hand-only selection, unknown effects, category coexistence, stock/preference changes at click, restock events, Crippling II, bounded failure storms, native request exceptions, combat suspension/resume, metadata success/retry, family-wide pause and late aura recovery, translated controls and bounded picker geometry. All 22 TOC Lua files compile/load in those scenarios.

## Live checks before broad distribution

- Mage: equip a compatible weapon; select one carried scroll; apply using the binding and verify the reminder clears. Test staff/dagger/sword choices as available.
- Check the scroll Imbue coexists with a supported oil Temporary effect. Swap to an incompatible weapon and confirm no scroll is offered.
- Rogue: carry Crippling II and confirm its use/recognition; check oils/stone restock notifications on another class.
- Inspect the Mage dropdown, retry tooltips and low-stock entries. Confirm combat blocks action and resumes safely afterward.

Mocks cannot validate the actual Forever client’s protected item application or visual rendering. Release ZIP is prepared locally, not uploaded. Use CurseForge file display name BuffTap 1.8.0, preserving project title BuffTap – Smart Buffing and slug bufftap.
