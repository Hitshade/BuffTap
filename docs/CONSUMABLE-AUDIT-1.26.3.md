# Consumable review, 1.26.3 beta

Reviewed 2026-11-17, including GitHub #5 from shaunpearsondev. Goblin Deviled Clams was genuinely absent from the whitelist. Its Forever tooltip confirms use spell 5006 and a 15-minute Well Fed effect granting 6 Stamina and Spirit. It does not show an experience bonus.

## Scope and confidence

`tools/audit_consumables.py` unions the preserved food, other-consumable and restoration-only research with the current visible whitelist. It records input hashes and each tooltip's source/hash/freshness. The final result has **605 unique candidate items**, **207 whitelisted items** after this change, and **378 freshly retrieved tooltip responses**. All **207** included use-spell mappings match fresh Forever tooltip links; none of their requests failed. The initial 23 saved-tooltip evidence gaps were resolved by the refresh.

The initial external refresh was blocked by automatic approval review on the session usage limit. After the stated reset time passed, the approved refresh completed: 378 successes, 22 failed candidate requests. The report's `freshThisAudit`, `fetchedThisRun`, hash and `evidenceFile` distinguish refreshed evidence from older research and reuse of identical refreshed responses. Failed candidates are not silently verified. Tooltips and database rows still do not establish current acquisition.

Reproduce with `python tools/audit_consumables.py --research <preserved-research> --output <report-folder>`, optionally adding `--refresh` for online retrieval. Raw reports stay in the research folder, outside the addon package. Sources are the public `https://nether.wowhead.com/forever/tooltip/item/<ID>` responses.

## Foods added

| Item | Use spell | Buff aura |
|---|---:|---:|
| Goblin Deviled Clams (5527) | 5006 | 19708 |
| Clamlette Surprise (16971) | 10256 | 19710 |
| Dirge's Kickin' Chimaerok Chops (21023) | 25660 | 25661 |
| Westfall Stew (733) | 1248687 | 1248688 |
| Goldthorn Tea (10841) | 1249906 | 1249907 |
| Sweetpaw Jam (267341) | 1294006 | 1294007 |
| Pine Nut Butter (206177) | 5004 | 19705 |
| Cactus Apple Surprise (11584) | 5004 | 19705 |
| Lollipop (7806) | 5004 | 19705 |
| Candy Bar (7807) | 5004 | 19705 |
| Chocolate Square (7808) | 5004 | 19705 |
| Gingerbread Cookie (17197) | 5004 | 19705 |
| Egg Nog (17198) | 21149 | 19705 |
| Bobbing Apple (20516) | 24869 | 24870 |
| Winter Veil Cookie (21254) | 24869 | 24870 |

The old Chimaerok research's textual aura reference was inconsistent. SpellEffect's trigger relationship establishes 25660 -> 25661 (25 Stamina), rather than importing the unrelated 24799 aura. Bobbing Apple/Winter Veil Cookie use the preserved tooltip's Well Fed 24870 and describe the level-dependent effect without inventing a fixed stat amount. Regional restrictions remain visible in the meal notes. Legacy eating spells suppress repeated use while eating, and the extra aura IDs are recognized across food choices.

All 15 foods append to the existing list, preserving Auto preference order and saved choices. Their use-spell links were freshly checked. Existing runtime item metadata, exact use-spell, stock, level, cooldown, aura, pending and quarantine checks still apply. Seasonal/legacy records may not be currently obtainable; no automatic acquisition or availability claim is made.

## Other candidates

- 34 candidates belong to separate features, including weapon coatings, Camping and Soulstone upkeep. They are not missing food/elixir reminders.
- 364 candidates remain outside the maintenance whitelist. This includes restoration-only food/drinks, healing/mana potions, short combat buffs, offensive consumables, quest interactions and uncertain legacy records. The audit list is not an instruction to add them all.
- Lightning in a Bottle (248613) was a stale positive in the preserved research. Its fresh tooltip links ordinary Food 435 and has no Well Fed benefit. It was excluded before packaging rather than shipping the old 5006/19708 mapping.
- Wastewanderer Rations (277950) is a trinket/equipment effect, not an ordinary food-use omission.
- Existing research has five unresolved food records: 12211, 17199, 246916, 252024, 277313. Do not invent names or effects.
- Oil of Olaf (1177), Rumsey drinks (17048/20709/21114/21151/227286), and old Lesser Arcane Elixir (217398) require current availability, mapping and overlap review before offering maintenance reminders. Their database presence is not proof of current acquisition or compatibility.
- Elixir of Coalesced Regret is a quest interaction; slaying/elemental potions are short conditional combat effects; Petrification, Noggenfogger and Videre have special consequences. They were not silently treated as routine stat elixirs.
- No additional elixir or utility item has enough newly established evidence in this pass to add safely. Current acquisition/overlap remains unresolved for the deferred candidates above. All shipped whitelist tooltip mappings were checked; failed non-whitelist candidate requests remain recorded.

## Regression coverage

Every added meal has a mocked runtime selection test proving exact item preparation and recognizing its buff without replacement. Legacy eating suppression, retained metadata validation and existing category/checklist/manual-food tests are included in the release suite. No live-client test is claimed. Credit shaunpearsondev in all three release-note audiences; #5 remains open until owner-authorized follow-up.

Final release suite: **2,312 passed, 0 failed** in mocked Lua 5.1. All 207 included use-spell mappings separately match refreshed Forever tooltips. The 22 failed non-whitelist requests are retained as failures, not reported as verified entries.
