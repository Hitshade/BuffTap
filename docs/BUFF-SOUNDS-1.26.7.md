# BuffTap 1.26.7 sound controls and Abolish review

Owner-authorized local beta; no publication authorized.

## Sound scope
- Personal: own ordinary buff and own pet maintenance, independent of the active Solo/Party/Raid personal setup.
- Party/Raid: external roster members and group casts, including group casts targeted on the player. Canonical buff-family key pairs single/group versions.
- Target/Nearby retain existing quieting behavior. SmartShift is explicitly silent, not dependent on queue timing. Cleanse, consumables and readiness do not inherit per-buff personal mutes.
- Category permissions: sound (Reminder), suppliesSound, campSound, cleanseSoundEnabled, socialSoundEnabled. New Cleanse permission inherits the former sound state once. Social sound defaults enabled but social detection/highlighting remains separately opt-in. No module is enabled by granting sound permission.
- Schema: buffAlerts = {version=1, personal={key={enabled=boolean, sound=optional_validated_key}}, party={}, raid={}}. Beta5 activates sound overrides in the scoped editor; absent sound inherits the Reminder category. Initial betas only used enabled.
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

Beta 2 visual follow-up: enabled speakers track the active accent, muted speakers use grey; the shared theme refresh repaints both states. Party/Raid selected-buff headers reserve space for a top-right 26-unit speaker. Paladin sound-list entries use matching speakers. 78 focused cases passed, including tint and bounds; beta1 full validation retained. Live appearance remains owner-verified.

## Beta 3 audio additions
Five original synthesized mono Ogg Vorbis clips, 44.1 kHz, are added without replacing any of the eight existing recordings: Soft pluck (0.76 s), Amber chime (0.90 s), Gentle ripple (0.84 s), Wooden bloom (0.78 s), Silver notes (0.88 s). tools/build_extra_sounds.py contains the original oscillator/envelope recipes. It reads the original clips only as references and measures K-weighted gated loudness on decoded output. All five are within 0.1 dB of the existing set's median -21.82 LUFS, with decoded sample peaks below -8.7 dBFS. Report, hashes and reference metrics: research/extra-sounds-1267.json. No subjective listening or live game sound validation is claimed. Python audio dependencies are build-only, not shipped in the addon.

The sound picker, normalization, optional SharedMedia registration and existing previews consume the new files through the same code as existing choices. No defaults or per-buff custom playback overrides are activated. Paladin Buff sounds now shares Casting's right edge. Standalone WAV previews and a combined audition are in the parent releases folder under BuffTap-1.26.7-new-sound-previews.

## Beta 4: owner-created recordings replace the prototypes
Ten owner-created Ogg files from Desktop/AI Projects are now registered: Crystal chime, Elven harp, Holy light, Fairy ping, Celestial lift, Soft glow, Moonlit bells, Gentle harp, Warm welcome, Lullaby ping. Originals are read-only and hash-verified unchanged. Addon copies preserve stereo, 44.1 kHz and 0.98-second length. tools/import_owner_sounds.py applies gain only and re-encodes Ogg Vorbis; no trimming, fades, synthesis, compression or limiting. Channel-aware K-weighted energy summation is used for stereo instead of mono downmix measurement. Source loudness requires attenuation of about 7.9-12.3 dB to match the eight legacy sounds' median -21.82 LUFS; decoded copies are within 0.1 dB with peaks below -8.9 dBFS. Raw/final metrics and hashes are in research/owner-sounds-1267.json.

The five rejected beta3 picker choices are no longer registered; saved references to those five keys migrate to corresponding new selections, including reserved future per-buff sound values. Eight shipped choices/defaults remain unchanged. No source files, old prototype files, installed files or user originals were deleted. Old prototype assets remain on disk unregistered because file deletion is not authorized. Prior preview artifacts and synthesis code remain historical development evidence, not current picker entries.

Final audio listening remains with the owner; automated measurements do not certify subjective quality or native WoW playback.

## Beta 5: per-buff editor and scrolling
Right-click any personal/group/Paladin buff speaker to open BuffSoundOptions. Left-click remains mute/unmute. The popup captures an explicit validated canonical buff key and Personal/Party/Raid context, shows it in its heading, and offers an enabled checkbox, search, Use default row, sound rows and independent Preview controls. Clicking a row persists only the sound choice and keeps its enabled state. Selecting Use default removes the override. Preview uses an explicit sound argument forwarded through the existing Cleanse wrapper and never saves a selection or changes an action. Unavailable SharedMedia preferences remain represented in the list and keep the existing fallback. Combat, invalid keys and cross-class writes fail without mutation. Escape, combat or hiding Options closes the editor.

Automatic ordinary-buff playback consults the scoped override after existing mute/category/pause/queue gates. It does not change casting, selection priorities, timers or SmartShift silence. Export/import and optional same-class profile copying use the already prepared schema. Speaker tooltips name the chosen/default sound and explain left/right click.

Selectors clear stale search and open at the selected entry. Category sound selectors identify it by key rather than display text. The new editor highlights and centres the selected entry. Scroll motion uses smaller 20-unit wheel steps with a short-lived animation frame, no idle polling, bounded endpoints, hide cleanup and immediate movement under Reduce animation. Native scrollbar drag is retained and cancels any pending smooth target.

Owner-created files are rebuilt from unchanged originals with a 1 dB louder target (-20.82 LUFS); stereo/duration remain unchanged and the eight old sounds are still byte-identical. Updated gain/source/output metrics remain in research/owner-sounds-1267.json.

Live checks: right-click Aquatic Form, preview and select a sound; mute/unmute retains it; Use default follows a later category change. Choose different Party/Raid sounds and verify group casts. Try a long SharedMedia list, search, current-selection reopening, Reduce animation and scrollbar dragging. Reload to confirm saved choices. Actual native rendering/audio remains owner testing.

Beta5 automated evidence: 2,881 integrated mocked Lua 5.1 passes with zero FAIL records; 98 focused passes; Lua syntax, ten-version notes, and all ten untouched owner source hashes checked. Updated audio copies meet the +1 dB target within 0.1 dB and retain headroom. Logs: tests/release-1267-beta5-full.txt and tests/sound-editor-1267-beta5-focused.txt.
