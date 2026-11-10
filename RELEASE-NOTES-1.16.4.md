# BuffTap 1.16.4

- Nearby now detects changes to PvP flags and recipient combat state without movement. Unsafe recipients are removed even while a row is hovered, and rejected binding attempts refresh the next selection.
- Confirmed range and line-of-sight cast failures temporarily skip that recipient and spell for ten seconds, then retry automatically. Mana, cooldown and unrelated errors do not delay recipients. Failed rows do not remain stuck under the cursor.
- Added Soul Link's pet-applied aura (25228) to detection, including BG self checks. The cast spell remains 19028; restricted aura data still counts as unknown.
- Uses existing settings and profiles. No new settings or migration.

Research references: Manners 1.11.13 highlighted range retry delays and pet-applied Soul Link detection; Serial Buffer also handles target range/line-of-sight errors. These fixes use BuffTap's own matching-failure safeguards and scheduler.
