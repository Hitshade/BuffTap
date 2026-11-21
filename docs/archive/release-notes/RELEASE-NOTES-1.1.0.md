# BuffTap 1.1.0 — Class readiness

- New optional Hunter and Warlock pet readiness in the main Helpers tab; disabled by default.
- Warlocks choose a learned preferred demon. Any living pet satisfies the reminder; Demonic Sacrifice suppresses summons.
- Hunters can revive a visible dead pet with one tap. An absent assigned pet gets a manual call/revive reminder because its life state cannot be reliably verified.
- New optional personal Healthstone preparation for Warlocks. Offers the highest learned creation spell only when no supported Healthstone is carried, a Soul Shard is available, and general bag space is verified. Never consumes a Healthstone.
- Recovery actions respect combat, mount/vehicle state, casting, movement and existing queue priorities. Inventory results are cached; pet transitions and cast retries use bounded event-driven delays.
- Compact class-specific controls, explanations and native spell icons are integrated into Helpers. Existing saved preferences remain intact.
- Rebuilt the class catalog from Forever client spell, skill, level, effect and reagent tables. Corrected missing Seal of Righteousness, Seal of Fury and Trueshot ranks, Demon Armor rank membership/levels, and poison application/recipe records.
- Updated current documentation and MPL 2.0 license scope for the replacement catalog. Earlier releases remain unchanged.

181 mocked Lua 5.1 regression scenarios pass. Live-client pet transitions, Healthstone creation and the compact Helpers layout still need in-game verification.
