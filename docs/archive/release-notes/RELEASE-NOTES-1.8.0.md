# BuffTap 1.8.0

- Added 15 verified Mage imbue scroll choices in Weapons, with compatible staff, dagger or sword checks. Main-hand only; preferences start at None.
- Scrolls use your existing BuffTap click/scroll binding and stay separate from oils/stones. Optional Supplies warnings include the selected compatible Mage scroll.
- Added Crippling Poison II, including highest usable carried rank selection and enchant recognition.
- Fixed bag updates for selected oils/stones on every class and Mage scrolls, including restocking an idle reminder.
- Bounded item-data loading to three attempts with backoff. Retries suspend during combat; successful loads release cached metadata.
- Added Retry reminders in Consumables and Weapons. An unobserved flask/elixir effect gets a second check before its family pauses, preventing Auto from offering another item. Retry restores reminders without reloading; changed item mappings remain blocked.
- Bounded the class weapon picker, added translated retry controls, and removed an overwritten food-aura table.
- Includes the prepared minimap button, opt-in broker display, and all-class oils/stones from 1.6.0–1.7.0.

475 mocked Lua 5.1 scenarios passed. Prepared locally; not published. In-game Mage scroll application and visual checks remain pending. Spellbreak remains excluded because its name and live mapping disagree.
