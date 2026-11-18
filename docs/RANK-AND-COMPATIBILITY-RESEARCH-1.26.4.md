# Forever recipient ranks and consumable compatibility

## Follow-up: focused Classic-policy beta

After this research, the owner supplied further Classic-rule and CheaperBuffs evidence and endorsed a focused test branch with representative live verification. **1.26.4-beta2 now tests the Classic allowance for ten ordinary ranked families only.** This supersedes the earlier research-only implementation decision below; it does not convert the historical evidence into comprehensive Forever server verification. Group versions, unusual effects and consumable compatibility remain unchanged.

Read the [independent CheaperBuffs data](https://github.com/mendeleevforever/CheaperBuffs/blob/main/Data.lua) and [logic](https://github.com/mendeleevforever/CheaperBuffs/blob/main/Logic.lua): its author explicitly calls the table historical 1.12 data and requests current Forever retesting. Compare against our preserved Forever 70888 records; do not transplant its rank ownership assumptions, hidden-level fallback or historical table. BuffTap still requires every offered rank to be individually known and rejects unreadable recipient levels. Its own existing catalog supplies the levels.

The supplied Classic [Blizzard-hosted thread](https://us.forums.blizzard.com/en/wow/t/buff-auto-down-ranking/465042) contains player discussion, not an official Blizzard server specification. The linked spell 1245 is Fortitude rank **3**, learned at 24; rank **2** is 1244, learned at 12. The latter is the Classic level-2 recipient example. Existing BuffTap data has the correct identities.

The supplied expanded competitor review was read as a backlog of candidate investigations, not authorization to add preference learning, stack controls, a buff inspector, supply features or other unrelated changes. No competitor code is copied. See the beta verification record for implementation boundaries and the remaining four-class live check.

Research date: 2026-11-17 local. Installed beta: 1.26.4-beta1. Research only; no runtime change, new package or publication.

## Scope and evidence

Owner requested due diligence before changing recipient rank limits, and research into consumable compatibility. Resurrection recovery is deferred. Owner reports the previous range errors have disappeared and the current beta appears fine; do not describe that incident as an outstanding reproduced failure.

Connected GitHub review: no open BuffTap issues returned; recently relevant #4 and #5 remain closed. No issue state or comments changed.

`tools/research_rank_compatibility.py` independently reads our current catalog and collects primary tooltip data. The completed collection contains **85 unique external/group buff spell tooltips, 207 supported item tooltips, and two native UI/API source files**, all successfully retrieved. Earlier progress estimates of 82/210 were incorrect; 85/207 are the final counts. Raw responses, retrieval time and SHA-256 hashes are preserved in `../research/rank-compatibility-1.26.4/sources.json`. `ranks.json` joins every reviewed rank to preserved client levels and attributes.

Five attempts to refresh build 70938 DB2 exports returned HTTP 403. Those failures are recorded, not treated as fresh data. Preserved build 70888 tables match the catalog's recorded hashes:

- SpellLevels: `c9ef7708478aaff1b5e488c58356df443ee7d6c08a53017819f9af37cd5bef5a`
- SpellMisc: `4b3d573dae575c2051e71d524dc73ac3590c56aa102b69770675c0eb10508f85`

Current tooltips establish current descriptions and displayed requirements, not a current server eligibility implementation. Native source is pinned to Forever mirror commit `3d8abb1da73acd38e412e24fb3f99454a6392346`.

## Rank finding: learning level is not a recipient requirement

The native [C_Spell API documentation](https://github.com/Gethe/wow-ui-source/blob/3d8abb1da73acd38e412e24fb3f99454a6392346/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) defines GetSpellLevelLearned as the learning level, with possible Level Link adjustment. It does not promise a minimum recipient level. Our Candidates uses that API/book value with RankLevel fallback. Resolve currently compares external target level directly with it, except for Mark of the Wild's ten-level allowance. Self casts bypass that comparison.

Thus the existing generic comparison is a conservative policy, not a verified general recipient rule. Copying learning levels into a new recipient table would preserve the same uncertainty.

The firsthand [Manners #9 report](https://github.com/fpsacha/Manners/issues/9), from Forever build 70862, describes Arcane Intellect rank 3 as applicable from level 18 although it is learned at 28. Its diagnostic identifies Forever despite the prose calling it Classic. The follow-up's suggested implementation incorrectly treats training level as applicability; that suggestion is not evidence of the threshold. The native action bar versus macro distinction is separately reported in this [Forever beta thread](https://us.forums.blizzard.com/en/wow/t/target-is-too-low-level/2380625).

The [Forever rank-3 page](https://www.wowhead.com/forever/spell=1461/arcane-intellect) displays learning level 28 and a comment reporting recipient level 18. However, [rank 5](https://www.wowhead.com/forever/spell=10157/arcane-intellect) and [Wisdom rank 1](https://www.wowhead.com/forever/spell=19742/blessing-of-wisdom) visibly include old Thottbot/patch-era comments. A comment's presence on a Forever page does not establish that it was tested on Forever. In particular, do not promote the historical Wisdom level-4 comment to a current verified rule.

### Coverage reviewed

These are **learning levels**, highest rank first, from the preserved client export. They are not approved recipient minima.

| Buff family | Learning levels |
|---|---|
| Mark / Gift of the Wild | 60,50,40,30,20,10,1 / 60,50 |
| Thorns | 54,44,34,24,14,6 |
| Arcane Intellect / Brilliance | 56,42,28,14,1 / 56 |
| Dampen / Amplify Magic | 60,48,36,24,12 / 54,42,30,18 |
| Fortitude / Prayer | 60,48,36,24,12,1 / 60,48 |
| Divine Spirit / Prayer | 60,50,40,30 / 60 |
| Shadow Protection / Prayer | 56,42,30 / 56 |
| Fear Ward | 20 |
| Kings / Greater Kings | 20 / 60 |
| Might / Greater Might | 60,52,42,32,22,12,4 / 60,52 |
| Wisdom / Greater Wisdom | 60,54,44,34,24,14 / 60,54 |
| Battle Shout | 60,52,42,32,22,12,1 |
| Trueshot Aura | 60,50,40,32,25 |
| Water Breathing / Walking | 22 / 28 |
| Unending Breath / Detect Invisibility | 16 / 50,38,26 |

Some utility records have BaseLevel=0 despite nonzero SpellLevel. That difference alone does not establish recipient exemption. Area buffs, percentage effects and Greater Blessings also need their own evidence; a universal minus-ten transformation is not justified by the retrieved primary records. Public emulator implementations were excluded as proof of Blizzard Forever server behavior.

### Implementation decision and remaining gate

**Do not change runtime thresholds from this research alone.** There is meaningful evidence of under-ranking, especially Arcane Intellect rank 3, but not a source-backed complete Forever eligibility matrix. Neither retrieved API documentation nor tooltip tables expose a definitive per-recipient rule. No live rank-boundary test occurred.

The defensible implementation shape, once verified, is an explicit per-spell recipient policy separate from learning level, retaining existing candidate discovery, localized exact-rank casts, unknown-level safeguards and click-time identity checks. Keep settings configurable regardless of player learning/level. Do not add permanent error-driven learning or assume native action-bar downranking applies to secure macros.

Smallest high-value live confirmation: explicitly cast known Arcane Intellect rank 3 on levels 17/18, rank 2 on 3/4, rank 4 on 31/32, and rank 5 on 45/46, with no stronger competing effect. These pairs test the proposed ten-level rule, rather than declaring it true. For each family later changed, verify its own adjacent boundary and exemptions. For group forms, verify affected low-level members and exact-rank threshold counts separately. Record client build, spell ID/rank, recipient level, success/error and actual resulting aura.

## Consumables: confirmed restrictions versus unresolved combinations

Current direct item tooltips explicitly restrict flasks to one active flask and Zanza to one active Zanza. Current code already implements one flask selection and a mutually exclusive Zanza checklist line. No change is needed for those documented restrictions. [Titans](https://www.wowhead.com/forever/item=13510/flask-of-the-titans), [Spirit of Zanza](https://www.wowhead.com/forever/item=20079/spirit-of-zanza).

Shared spell identity is also direct evidence: Distilled/Winterfall Firewater share their effect, and Elemental Attractor/Arcane Censer both use Magical Awareness. Existing Utility lines cover these. This establishes identity, not compatibility with every other attack-power or caster buff.

The current tooltips do not supply a complete pairwise stacking table. A three-second item cooldown describes a use lockout, not whether two effects coexist. Absence of Battle/Guardian wording is not sufficient proof that all elixirs stack. Identical stat names are likewise insufficient to declare either exclusion or compatibility.

Priority unresolved combinations from our supported catalog:

| Combination | Why it merits verification |
|---|---|
| Intellect elixir / Owl / Cunning / Sages with Arcane Intellect or camp Intellect | Possible overlapping stat effects; class buff may block item use or only one component. |
| Ferocity / Brute Force / Grizzly with Strength or Agility elixirs | Multi-stat effects cannot safely be reduced to one exclusive line by tooltip similarity. |
| Mongoose with Greater Agility; Owl with Greater Intellect | Same stat amount plus a critical bonus does not establish whole-aura replacement behavior. |
| Phalanx with Defense or Fortitude; Wicked Regeneration with Mageblood or Troll's Blood | Need to distinguish partial stat non-stacking from complete aura rejection/replacement. |
| Juju Power / Might / Guile with elixirs, Firewater or class buffs | Crosses visible Utility/Elixir families; current line checks do not model every cross-family conflict. |
| Different Well Fed foods and buff-bearing drinks | Eating/drinking channels may coexist while their resulting bonuses do not; channel compatibility and aura compatibility are separate questions. |

Current runtime safeguards remain valuable: item mapping and stock revalidation, actual item cooldowns, pending-use settling, an existing-food guard and pausing after a confirmed non-food use whose effect fails to appear. **That pause is not complete conflict protection:** if A appears, is observed, then B replaces it, the confirmation record for A can already be cleared; A may be offered again. This is a conditional code-path risk, not a reproduced Forever loop. Do not claim the current guard proves all selected elixirs can coexist.

No speculative conflict graph, automatic unticking, same-stat merge or Battle/Guardian limit was added. To promote a combination to a runtime exclusion rule, obtain a current explicit rule or observe both cast orders, both aura identities, resulting stat changes and whether the item was consumed. One direction or one aura screenshot can miss partial suppression. Keep food/camp/class effects distinct unless their actual coverage is established.

## Outcome

Research evidence and a reproducible collection tool are retained. All confirmed explicit restrictions examined are already represented. The remaining rank and hybrid compatibility questions lack enough current primary evidence for a universal runtime change. Installed beta, settings, UI and all three release-note records are unchanged. No new runtime tests are claimed or needed for this research-only change.
