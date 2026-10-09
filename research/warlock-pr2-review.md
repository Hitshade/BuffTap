# Warlock contribution review

Contribution: [PR #2](https://github.com/Hitshade/BuffTap/pull/2), by **kristofdenolf1985-arch**, reviewed at `dd52103c3eaee1de2eb4ea9353926c7af2c4e37d`.

Accepted Firestone/Spellstone preferences, resource-checked creation, independent oils, and opt-in Soulstone upkeep. Original commits are retained in the integration history; attribution is shipped in CREDITS.md and the unreleased changelog.

Integration corrections:

- A raid Soulstone with unavailable caster identity suppresses the helper rather than being counted as somebody else's.
- Unreadable group state/counts or incomplete rosters suppress Soulstone selection.
- Forever assignments combine first name and surname using the client separator. Traditional Name-Realm handling remains for clients without regional names. Duplicate partial names cannot select an arbitrary recipient.
- Weapon Remind only mode never creates or applies a stone. Creation is enabled by an explicit stone preference plus Remind and apply.
- Updated the stale comment claiming readiness never uses items.

Evidence: `warlock-pr2-evidence.json` records independent assertions against archived Blizzard 1.60.1.70009 DB2 tables. All 7 imbue mappings, weapon masks, 12 creation outputs/shard costs and 5 Soulstone mappings agree with the contribution's reported 1.60.1.70124 data. Forever name semantics come from [Blizzard Camelot NameUtil.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua).

Validation: 820 isolated mocked Lua 5.1 scenarios, including 79 contributor scenarios and 13 integration safeguards. Run `python tests/test_warlock_review.py`.

Live client checks remain: reported enchant category/IDs, item range and secure Soulstone targeting, creation hand-off, and actual Helpers layout. New option strings retain English fallback in other locales. Version remains 1.13.2 with an Unreleased changelog; no release upload is part of this integration.
