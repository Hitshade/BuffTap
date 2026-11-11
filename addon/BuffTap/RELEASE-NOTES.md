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
