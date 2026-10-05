# BuffTap 1.3.0 â€” Supply warnings and smarter group recasts

- Optional Supplies controls are integrated in Consumables. Track your selected Rogue poisons, food buffs, flasks and elixirs with per-supply warning minimums and desired quantities.
- Separate stock indicator plus optional private chat alerts, sound and ready-check supply summaries. Stock alerts can be snoozed for ten minutes. All new features start disabled.
- Usable poison ranks are combined and shared hand preferences counted once. Explicit consumable preferences remain unchanged when out of stock.
- Empty, low, unusable, loading and unreadable stock are distinguished. Unknown data never generates an empty-bag warning; mismatched item effects do not count as supported usable supplies.
- Reagent-consuming group buffs now recount eligible recipients at the click. An obsolete group cast cancels safely; a new suggestion requires the next click or binding input.
- Group ranks no longer combine incompatible recipients to meet group spell thresholds. Existing healthy group-buff coverage remains respected across all supported classes.
- Stock checks use coalesced inventory events and caches, with startup/combat safeguards. No new recurring polling, purchasing, bank/alt tracking, or cross-player coordination.

Group/recovery reagent stock warnings and Reagent Economy detection are deferred because the hidden active perk state is not yet verified in Forever. Existing reagent checks and Healthstone/pet behavior are unchanged. Oils, stones and Mage imbue scrolls remain outside automatic weapon application.

Validation: 342 mocked Lua 5.1 scenarios passed, including 108 new stock and group-recast cases. Ten runtime Lua files loaded successfully. Live UI rendering and actual native API/cast behavior require the checks in docs/RELEASE-REVIEW-1.3.0.md. Prepared locally; not published.

Review corrections: stock warnings follow consumable/poison preference and enable changes immediately. Punctuation bindings are preserved through settings normalization. Ten added regression cases pass; 342 total.
