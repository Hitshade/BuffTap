# BuffTap 1.16.10

- Reduced temporary memory allocations and processing overhead while Nearby buffing is enabled, especially around larger groups of players.
- Avoided repeatedly rebuilding and sorting the same class buff list during a single refresh.
- Added short-lived reuse of unchanged Nearby buff checks, with invalidation when auras, player identity, spellbook data, or settings change.
- Preserved fresh pre-cast checks for buffs, recipient identity, PvP status, range, mana, and cooldowns.

Existing settings and profiles are preserved. Every buff cast still requires your click or binding. Combat casting remains disabled.
