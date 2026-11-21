# BuffTap 1.15.2

Prepared for local in-game testing. Not published.

- Paladin Groups now opens with Party setup, or Raid when already in a raid. Both views can be configured before joining a group.
- Party class assignments and raid defaults are separate. Raid groups can inherit defaults or use their own class assignments or one blessing for everyone.
- Same blessing for everyone hides and overrides saved class and player choices. Returning to By class restores those choices.
- Raid group buttons show blessing icons, class-assignment icon clusters, inherited defaults and excluded groups. Use raid defaults removes only that group's override.
- Class and player selectors retain spell/class icons; inherited choices show the selected blessing instead of a generic settings icon. Player exceptions are highlighted when present.
- Greater Blessings still require agreement across the full affected class, including other raid groups. Conflicts or exclusions use individual blessings. Casting thresholds are under Casting.
- Removed the redundant Other group buffs route from Paladins. Blessings, Salvation recipients and casting thresholds remain on their current dedicated controls. Other classes retain their simpler existing per-buff group controls. No whole-window scrolling or live-roster redesign was added.
- Fixed open player lists not updating after roster changes. Inventory updates now refresh each visible options/picker window once; unrelated item completions are ignored.
- Removed hidden class-inappropriate assignment controls, unused widgets, obsolete exclusive-Salvation branches and stale/repeated comments. Plan lookups no longer repeatedly normalize settings.
- Added a compact Buffs recipient filters window for inherited blessing filters, without restoring the old page.
- Fixed malformed non-Paladin profile validation and removed profile snapshot copies from ordinary options refreshes. Profiles still save on entry, profile operations and logout.
- Existing class choices migrate into independent party/raid plans. Old effective party exclusions are retained until explicitly enabled from Party setup, independently of later raid G1 changes. A former G1 class override becomes the party choice while the original raid defaults remain intact. Plans are not reset on reload.
- Profiles keep these plans character-specific. Shared-profile switching/copy/reset leaves them intact. Optional same-class copying includes both plans, priorities and subgroup overrides, using independent copies. Cross-class imports are rejected. Session player exceptions are not imported and party/raid exception choices are separate.
- Salvation and Mass Salvation remain separate from blessings, using verified build 1.60.1.70425 IDs 1038 and 25895. Group, personal and friendly-target permissions are independent. Prior Salvation opt-ins pause on upgrade for review.
- Salvation recipients includes a dedicated player-exclusions entry, also accessible while uniform blessings are active. Never Salvation protection, class-wide safety, reagents and click-time checks remain enforced. Revoke remains manual.

Validation: 983 mocked Lua 5.1 scenarios passed, including roster UI updates, preserved exclusions, compact filter editing, single event ownership, malformed profile recovery, profile copy isolation, uniform-mode precedence, subgroup inheritance, combat guards and fixed-panel geometry. Shipped Lua and archive contents verified. Live casting and visual layout require in-game testing.
