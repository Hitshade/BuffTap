# BuffTap 1.7.0

- Added separate per-hand oil and stone preferences in Weapons for every class, alongside existing Rogue poisons and Shaman imbues.
- Supports Wizard/Mana Oils, leveling sharpening stones and weightstones, Elemental Sharpening Stone, Frost Oil and Shadow Oil.
- Reuses the normal scroll/click binding, missing/expiry reminders and safe replacement controls. New preferences default to None.
- Enforces client weapon restrictions and preserves separate enchant categories. Unknown effects are never overwritten automatically.
- Optional Supplies warnings track selected oils/stones; multi-use oils count remaining applications. Shared hand choices count once.
- Includes the previously prepared minimap button and opt-in broker display from 1.6.0.

444 mocked Lua 5.1 checks passed. Live weapon application/stacking and layout verification remain pending. This build is prepared locally and not published.
