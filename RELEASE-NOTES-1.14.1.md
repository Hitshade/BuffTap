# BuffTap 1.14.1 - Find Treasure tracking

- Renamed the Helpers Gathering tracker section to Tracking.
- Added an independent, opt-in Keep Find Treasure active checkbox for characters who know the Dwarf racial ability. Gathering preferences remain unchanged; both reminders can be enabled together.
- Restores missing tracking through the normal player-triggered binding, with fresh tracking-state checks before use. Unknown tracking data does not arm an action.
- Localized the new controls in German, French, Spanish and Brazilian Portuguese.

Thanks to noci_ for the Find Treasure suggestion.

Validation: 834 mocked Lua 5.1 scenarios passed, including nine new tracking cases. All shipped Lua syntax and archive contents verified. Live Dwarf tracking verification remains pending.
