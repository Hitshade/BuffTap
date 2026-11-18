# Forever class-spell review, 1.26.3 beta

Reviewed 2026-11-17 after the owner's report that Druid Revive was missing. This corrects an incorrect Vanilla-based assumption: Forever Druids have a normal out-of-combat resurrection as well as optional Rebirth.

## Evidence and scope

`tools/audit_class_spells.py` reads Forever DB2 exports: SpellName, Spell, SpellLevels, SpellEffect, SpellDuration, SpellMisc and SkillLineAbility. After the initial preserved 70009 review, all seven tables were freshly retrieved from wago.tools for **1.60.1.70888**, the build used by BuffTap's catalog. The six tables already recorded in `tools/catalog-evidence.json` match its SHA-256 hashes exactly; SpellDuration's newly recorded hash is `4787f303fe8487cd67e5f9e8574fdc6fa2a03516dcfaabba23d9944f937223f5`. The report records hashes and compares maintained families, defensive dispels and actual resurrection selection. It retains every candidate's IDs, levels, effects, targets and description. Reproduce with `python tools/audit_class_spells.py --data <exports> --build 1.60.1.70888 --output <report-folder>`.

| Class | Distinct class-mask spell records | Review result |
|---|---:|---|
| Warrior | 233 | Battle Shout ranks covered. Stances and Shield Slam are not maintenance buffs or friendly cleanses. Unverified newer shouts remain deferred. |
| Paladin | 347 | All five Redemption ranks and defensive Cleanse/Purify spells covered. Current maintained blessings, seals and auras reviewed. Retired Salvation/Light families stay retired. |
| Hunter | 467 | Existing aspects, Trueshot, tracking, Revive Pet and feeding helpers reviewed. Tranquilizing Shot is offensive dispel, not cleanse. Unverified aspect alternatives remain deferred. |
| Rogue | 233 | Poison creation/application choices reviewed separately from triggered poison effects. Stealth is not an automatic maintenance target. |
| Priest | 415 | All five Resurrection ranks and defensive dispels covered. Apparent Shadowguard/Touch of Weakness omissions are triggered damage/debuff records, not castable ranks. Levitate is a contextual movement utility and remains outside maintained buffs. |
| Shaman | 327 | All five Ancestral Spirit ranks, friendly Poison/Disease cleanses, shield and weapon choices covered. Purge is offensive. Ghost Wolf return remains opt-in SmartShift. |
| Mage | 372 | Maintained buffs, Remove Lesser Curse, pet/readiness and scroll mappings reviewed. Combustion is a combat cooldown, not a maintenance reminder. |
| Warlock | 305 | Armor, breathing, detection, Soul Link, demon/stone helpers and weapon stones reviewed. Added Sense Demons to pre-learning tracking choices. Legacy Fel Armor/Metamorphosis records need current availability evidence. |
| Druid | 338 | Fixed all five normal Revive ranks. Rebirth remains independent. Friendly poison/curse removal covered. Added Track Humanoids to pre-learning tracking choices; runtime Cat Form requirement remains. |

Total: **3,037 records**, **268 discovered maintenance/resurrection/dispel candidates**. This is a systematic candidate review, not proof that every database row is currently trainable or that every spell was exercised in the client. The preserved 70009 baseline had 3,025 records and 275 candidates; it is retained separately rather than overwritten.

## Confirmed changes

| Feature | Spell records | Evidence and behavior |
|---|---|---|
| Druid Revive | 437138, 1237948, 1237949, 1237950, 1237951 | Druid class mask, resurrection effect and levels 12/24/36/48/60. Highest known normal rank selected before optional Rebirth. |
| Druid Track Humanoids | 5225 | Druid class mask, level 32, icon 132328. Already handled dynamically after learning; now available in the fallback chooser beforehand. |
| Warlock Sense Demons | 5500 | Warlock class mask, level 24, icon 136172. Same fallback-choice correction, default off. |

The two tracking additions and all five Revive ranks were rechecked against the refreshed 70888 records, including their icons and levels. No wholesale catalog rebuild was performed. The generator specification includes both tracking additions so a future rebuild retains them.

## Candidate dispositions

- Triggered effects: Druid Abolish Poison Effect 3137; Priest Shadowguard 28377–28382 and Touch of Weakness 2943/19249/19251–19254. Keep actual cast spells, not these triggered records.
- Offensive spells: Shield Slam, Tranquilizing Shot, Purge, Hunter's Mark, Hex of Weakness and Warlock curses/Bane of Havoc. Not friendly buff/cleanse maintenance.
- Player-controlled states: Druid combat/travel forms and Prowl, Warrior stances, Rogue Stealth, Hunter Feign Death/Eyes of the Beast, Paladin mounts, Shaman Sentry Totem, Warlock Subjugate Demon. Do not continually override intentional state choices.
- Paladin Salvation/Light families were explicitly retired by earlier Forever review. This audit does not reintroduce them merely because old rows remain.
- Tracking is also discovered from the game's minimap menu. Absence from a maintained-buff list is not a runtime omission, but missing pre-learning choices were real configuration gaps and are fixed above.
- Current trainability/availability unresolved: Warrior Commanding Shout 403215 and Valor of Azeroth 461475; Hunter Heart of the Lion 409580 and Aspects Viper 415423/Falcon 469145; Paladin Righteous Fury variant 407627, Horn of Lordaeron 425600, Inspiration Exemplar 407880 and Swift Judgement 1310994; Shaman Earth Shield 408514/Spirit of the Alpha 408696; Warlock Fel Armor 403619/Metamorphosis 403789. Old/rune/trigger records cannot establish current supported abilities. Obtain current client/spellbook evidence before adding them; none is claimed unavailable solely from ID or origin.

## Behavioral review and verification

Added regression coverage for each normal resurrection rank across all four resurrection classes, normal Revive with Rebirth off, highest known rank, unlearned choices, corpse range re-entry without an aura event, ghost rejection, and avoiding unnecessary full refreshes for a valid corpse. Added actual PreClick/dispatcher coverage for SmartShift after self/group/Nearby cleanse, failure, changed recipient and ordinary other-player buffs. Tracking tests cover pre-learning choices, unrelated classes and Cat Form eligibility.

Settings are preserved. No level/learned restriction was added to configuration, no combat aura inspection was added, and every protected action remains tied to hardware input. The owner has not yet live-tested this beta. A class-mask row alone does not establish current trainability, so the review does not claim exhaustive current-server spell availability.

Final beta release suite: **2,312 passed, 0 failed** in mocked Lua 5.1, including 62 new review scenarios. The separate Mage evidence check passes all 15 item/use/enchant/weapon mappings. Recorded output: `tests/review-1263-final.txt`.

GitHub review: #5 is open, reported by shaunpearsondev, zero comments; included in the consumable work. #4 is closed, with the previous Druid resurrection-row overlap fix documented in its comment. Preserve that layout fix. No issue replies or state changes were made during this review.
