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
