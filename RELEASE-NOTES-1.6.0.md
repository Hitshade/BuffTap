# BuffTap 1.6.0

- Added a draggable minimap settings button, enabled by default, with saved positioning and standard LibDBIcon support.
- Added an optional LibDataBroker display, disabled by default. Shows the next queued reminder and its recipient using existing cached status, without additional buff scans.
- Independent controls in Appearance → Quick access allow either display, both or neither. Broker bars require a separate display addon; disabling an already registered broker requires a UI reload.
- Clicking either display opens settings; neither casts spells. Settings remain unavailable during combat.
- Bundled upstream LibStub, CallbackHandler, LibDataBroker and LibDBIcon with their original notices.
- BuffTap remains uncategorized in the addon menu.

Validation: 420 mocked Lua 5.1 scenarios passed. Live placement, translated layout and compatibility with minimap managers and broker bars still require in-game verification. Not published.
