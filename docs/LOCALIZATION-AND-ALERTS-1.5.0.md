Groups label refinement: shared controls and per-buff editor have distinct headings and scope descriptions; no behavioral change.

# Localization and alert implementation — 1.5.0

Localization.lua loads before catalogs; only the selected locale dictionary is allocated. Four separate UTF-8 Lua files hold 206 English-keyed messages each. esMX shares the Spanish esES dictionary; unsupported locales and absent entries use the English key. No selector, global GetLocale override, translation library or new polling loop.

B:Text(key, ...) performs lookup and guarded formatting. Translation failures retry the English format. Keep format placeholder types and order unchanged; the tests verify all dictionaries. Options label/button/check/tooltip helpers use lookup, with explicit lookups on translated dynamic labels. Some longer descriptions, item effect notes, technical reports and internal errors remain English. This is initial partial localization, not native-reviewed complete language support. New translations should be reviewed in the actual client for meaning and fit. Keep keys independent of engine states and never translate catalog IDs, setting keys, secure attributes, unit tokens, command tokens or matching logic.

Locale files: addon/BuffTap/Locales/esES.lua, deDE.lua, frFR.lua and ptBR.lua. English key text is the fallback. Italian is an uncomplicated possible next addition; Russian should receive fluent review. Neither is included in this release. GetLocale is used automatically; supported client language/font availability must be confirmed on Forever.

Alerts.lua whitelists the existing sound and sound constants actually exposed by SOUNDKIT. Choices may be fewer on a client with missing constants. Reference: https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Mainline/SoundKitConstants.lua

Sounds default to off, existing sound 12867, Master channel, five-second minimum. Independent selections share a bounded live audio cooldown; closely spaced reminders may deliberately be silent. Preview is explicit, bypasses enabled flags and never consumes notification timing. No custom file paths or SharedMedia integration in this build.

The appearance preview is a separate unprotected frame with no secure attributes or bindings. Its native animation uses no OnUpdate script. Reset confirmation is inline in Appearance and clears on close/tab change; the typed /bt reset remains explicit and immediate. The Diagnostics summary reports known states and refers users to the existing diagnostics for detailed exclusions.

Test entry point: tests/test_usability.py, 412 mocked Lua 5.1 scenarios. Native speakers should review translations. Live tests still needed for audio playback/channel/interval, preview appearance, long translated text and unchanged class/weapon/pet behavior.
