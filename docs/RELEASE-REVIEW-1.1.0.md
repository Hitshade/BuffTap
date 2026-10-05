# BuffTap 1.1.0 implementation and verification

## Baseline and changes

Canonical source: `addon/BuffTap`. Baseline matched GitHub commit
`f4dd126920f80008ad80a8fa86b64feccad5d28c` (1.0.0). The original release ZIP and
pre-1.1.0 source snapshot remain unchanged in releases / releases/archive.

Changed runtime files: Engine.lua (defaults, validation and selection),
BuffTap.lua (click validation, inert manual alerts, events, diagnostics),
Readiness.lua (new isolated providers), Options.lua (integrated class controls),
Catalog.lua (replacement generated data), ConsumableData.lua (previously
original maintenance data relocated from Catalog), and BuffTap.toc.
License scope, README, release notes, tests and handoff were updated.

## Verified data and behavior

Data build: Forever 1.60.1.70009. Client API documentation is pinned to
`Gethe/wow-ui-source` forever commit `bd2470aed543f72697a044e989285b6c83e63f73`.
The new module is independently written. Behavioral research is recorded
locally; no reference-addon source or assets are incorporated.

- Learned summon IDs: 688, 697, 712, 713, 691. Explicit selection only; no forced
  replacement of a living demon. Sacrifice effects 18789–18792 suppress summons.
- Hunter Revive 982 is armed only for an observable dead pet with matching GUID.
  C_StableInfo.GetStablePetInfo(1) proves assignment, not absent life state;
  therefore absent assigned pets receive an inert manual reminder. No guessed Call cast.
- Create Healthstone spells: 6201, 6202, 5699, 11729, 11730. All require one
  Soul Shard (6265). Any of the 15 supported base/improved Healthstones satisfies
  possession. Bank contents and item cooldowns do not count as missing/present
  decisions. No item-use action is created.
- General bag space, consistent occupied-slot data, output metadata, reagents,
  movement, spell usability/cooldown and current pet state are checked before
  preparing and again before accepting a click.
- No Soulstone support, consumable potion inventory tracking or camp interaction added.

## Performance and safety

Both helpers default off. Their extra events register only while relevant and
enabled. Disabled providers perform no pet/inventory scans. Healthstone
inventory is cached until a bag/relevant metadata event or an explicit click.
100 ordinary aura refreshes reuse that cache in the regression test.
No permanent update loop or new idle heartbeat was added. Two-second transition
allowances and bounded pending-cast timeouts are conservative implementation
choices, not a claim that every live Forever transition completes in two seconds.
Ordinary buffs, consumables and tracking remain ahead of readiness; an unavailable
provider cannot block another. The secure combat/mount suspension is unchanged.

## Validation

Run `python tests/test_readiness.py` after installing requirements-dev.txt.
181 mocked Lua 5.1 scenarios pass: the existing 129 plus 52 readiness/catalog cases.
Coverage includes dead/absent/living pets, sacrifice, preferred selection,
missing shards, invalid bags and metadata, all 15 Healthstone IDs, stale pre-click
state, failure/success/interruption attribution, mouse phases, combat, movement,
dismiss/restore, default-off cost, cache reuse and catalog corrections.
All loaded Lua files also compile in Lua 5.1. ZIP contents and TOC paths are
checked against the source; hashes are recorded in RELEASE-MANIFEST-1.1.0.json.
Mock tests cannot exercise Blizzard's secure executor or render the game UI.

## Required live smoke checks

1. Hunter: living/dead/absent pet, no assigned pet, death/revive, dismount and
   zone transitions. Verify only a visible dead pet offers Revive; manual missing
   alerts have no binding. Confirm readiness doesn't briefly request duplicate recovery.
2. Warlock: choose each learned demon, use a different living demon, test
   sacrifice, no shards, movement, insufficient mana, interrupted/failed casts.
3. Healthstone: each learned creation rank, base/improved carried stone, bank-only
   stone, consumed/traded-away stone, full and specialist bags, uncached item data.
   Confirm the icon creates a stone and never consumes one.
4. Combat: no taint/errors or stale actions across entering/leaving combat. Verify
   wheel/key and mouse inputs, mounted and vehicle transitions.
5. UI: Helpers text and dropdown fit at normal and smaller UI scales. Verify
   Hunter/Warlock-only controls and native icons, plus all prior helper toggles.
6. Catalog: Paladin seal ranks/Greater Blessings, Hunter Trueshot, Warlock armor,
   and Rogue/Shaman manual weapon alerts. Existing target/party ordering stays correct.

Nothing was installed into the live client, uploaded to CurseForge, or pushed to
GitHub by this task. The user explicitly requested version 1.1.0 without a beta tag.
