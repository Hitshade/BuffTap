# BuffTap 1.26.7 sound controls and Abolish review

Owner-authorized local beta; no publication authorized.

## Sound scope
- Personal: own ordinary buff and own pet maintenance, independent of the active Solo/Party/Raid personal setup.
- Party/Raid: external roster members and group casts, including group casts targeted on the player. Canonical buff-family key pairs single/group versions.
- Target/Nearby retain existing quieting behavior. SmartShift is explicitly silent, not dependent on queue timing. Cleanse, consumables and readiness do not inherit per-buff personal mutes.
- Category permissions: sound (Reminder), suppliesSound, campSound, cleanseSoundEnabled, socialSoundEnabled. New Cleanse permission inherits the former sound state once. Social sound defaults enabled but social detection/highlighting remains separately opt-in. No module is enabled by granting sound permission.
- Future schema: buffAlerts = {version=1, personal={key={enabled=boolean, sound=optional_validated_key}}, party={}, raid={}}. Only enabled affects runtime. No custom picker or custom playback path implemented.
- Preferences are class/character data with same-class snapshot/copy/export support. Category switches follow their existing shared/character ownership. No settings files are edited externally.

## Abolish evidence
Reviewed 2026-11-18 after jimbo1111's report. The directly published client-build spellbooks list both Druid spells at 16% base mana and both Priest spells at 15%. Sources: https://www.60.tools/spellbook/druid and https://www.60.tools/spellbook/priest, build 1.60.1.70888. Local preserved Spell.csv and SpellEffect.csv show immediate removal for each Abolish spell plus periodic trigger records. Wago SpellPower CSV access returned 403; no successful fresh raw cost-table download is claimed. Exact extracted effects and cost-source provenance are recorded in research/abolish-cost-1267.json. This establishes base records, not exhaustive live talent/server modifier testing.

The selection now prefers learned Abolish and falls back to Cure before learning it. Old conditional preference is ignored but retained in saved data for compatibility. Active Abolish suppression and all protected-action guards remain in place. No reply is authorized or posted by this implementation request.

## Live checks for owner
- Mute Aquatic Form in My buffs; verify silent visual reminder/click while Mark and Thorns remain audible.
- In Groups, set different Party/Raid sound choices and confirm group casts use those choices while personal reminders use their own.
- Check Default sounds card spacing, speaker states, tooltips, explicit muted Preview, independent Cleanse category and shared Camp/Supply controls.
- Reload to check persistence. Druid/ Priest Cleanse page explains automatic Abolish and no longer has a conditional switch.

Integrated mocked Lua 5.1 validation passed 2,838 cases with no recorded failures. The final focused run passed 76 cases, including three geometry/copy checks added after the full run began. Seven focused Lua modules and nine affected Lua files compiled; all five release identities and the ten-entry/24-KiB in-game notes limit were checked. Mock construction cannot verify in-game font metrics or sound audibility.
