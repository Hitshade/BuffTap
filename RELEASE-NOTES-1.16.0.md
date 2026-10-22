# BuffTap 1.16.0

## Nearby player buffing

- Optional compact Nearby window lists eligible nearby players with class-coloured names and missing-buff icons. Click a name or use your existing buff binding to apply the next buff.
- Friendly player nameplates must be enabled, normally with Shift+V. Enable it in the Target tab, or Shift-left-click the minimap icon to toggle Nearby. The feature starts disabled and follows your Target preferences.
- Movable, lockable window with stable rows and a scrollbar. Nearby casts restore your previous target and keep reminder sounds and the normal reminder icon quiet.
- Nearby skips players in combat. PvP protection also skips flagged or unreadable recipients. Every cast requires player input and remains out of combat.

## Reliability and clarity

- Keeps verified missing buffs visible but disarmed during cooldown, preventing the Nearby list from emptying after each cast.
- Refreshes the cast recipient's aura data after normal and nearby buffs, improving follow-up detection for spells such as Thorns.
- Watches each missing spell's range separately, so secondary buffs can become available without manually selecting the player.
- Distinguishes insufficient mana from no missing nearby buffs.
- Automatically skips confirmed stronger-effect rejections for nearby buffing, allowing another missing buff or another recipient. Restore reminders clears these skips. The normal stronger-effect helper remains optional.

General Nearby preferences follow named profiles. Class and Target buff preferences retain their existing character-specific behaviour.

Validation: 1,184 automated mocked Lua 5.1 scenarios passed, plus Lua syntax and package integrity checks. Nearby has been tested in game during the private beta. Automated tests do not establish behaviour under every client restriction.
