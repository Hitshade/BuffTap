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
