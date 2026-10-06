# BuffTap 1.8.0

- Added 15 verified Mage imbue scroll choices in Weapons, with compatible staff, dagger or sword checks. Main-hand only; preferences start at None.
- Scrolls use your existing BuffTap click/scroll binding and stay separate from oils/stones. Optional Supplies warnings include the selected compatible Mage scroll.
- Added Crippling Poison II, including highest usable carried rank selection and enchant recognition.
- Fixed bag updates for selected oils/stones on every class and Mage scrolls, including restocking an idle reminder.
- Bounded item-data loading to three attempts with backoff. Retries suspend during combat; successful loads release cached metadata.
- Added Retry reminders in Consumables and Weapons. An unobserved flask/elixir effect gets a second check before its family pauses, preventing Auto from offering another item. Retry restores reminders without reloading; changed item mappings remain blocked.
- Bounded the class weapon picker, added translated retry controls, and removed an overwritten food-aura table.
- Added a draggable minimap settings button (on by default) and an optional LibDataBroker display (off by default).
- Added independent oil/stone choices for both compatible weapon hands on every class, with application counts for multi-use oils.
- Added Paladin blessings by recipient class, individual player exceptions and optional Salvation protection, with conservative Greater Blessing handling.
- Polished the options layout, clarified shared versus per-buff group settings, and added safe appearance preview and reset confirmation.
- Added client-language localization for Spanish, German, French and Brazilian Portuguese with English fallback.
- Added separate reminder/low-stock sound choices, previews, audio channel selection and minimum alert interval.

475 mocked Lua 5.1 scenarios passed. In-game Mage scroll application and visual checks remain pending. Spellbreak remains excluded because its name and live mapping disagree.
