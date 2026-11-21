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
