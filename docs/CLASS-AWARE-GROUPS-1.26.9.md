# Class-aware Groups, 1.26.9-beta1

This is a capability cleanup within the existing interface, not a visual redesign. The owner's screenshot is a layout reference, not a source of spell semantics.

## Policy

| Class | Targeted assignments | True group pairs | Generic pets | Role modes |
|---|---|---|---|---|
| Druid | Mark, Thorns | Mark/Gift | Mark, Thorns | Thorns: tank |
| Mage | Intellect, Dampen/Amplify | Intellect/Brilliance | Intellect, mana pets only | None |
| Priest | Fortitude, Spirit, Shadow Protection, Fear Ward | Three prayer pairs | Fortitude, Shadow; Spirit for mana pets | Fear Ward: tank/healer |
| Paladin | Dedicated blessing workflow | Dedicated Greater logic | None | Existing specialized plans |
| Shaman | Water utilities, deliberately enabled | None | None | None |
| Warlock | Breath/Invisibility, deliberately enabled | None | None | None |
| Warrior | None; Battle Shout is self/broadcast | None | None | None |
| Hunter | None; Trueshot is self/broadcast | None | None | None |
| Rogue | None; Groups links to Weapons | None | None | None |

The semantic policy is hand-authored in BuffCapabilities.lua, outside generated Catalog spell/rank evidence. Existing catalog targeting and player-only broadcast selection are retained; no new range, radius, duration or server behavior is inferred. Pet/role policy is a conservative product whitelist, not a claim of exhaustive live server validation. Unknown pet families fail closed.

Fresh maintenance defaults stay on for Druid/Mage/Priest/Paladin. Other fresh targeted-group switches start off. Explicit existing booleans win, including pre-migration profiles. Hidden group filters, roles and pet preferences remain stored. Unsupported roles evaluate as class mode. Party/Raid contexts, profile copying and exports retain their existing schema. No onboarding replay or direct settings-file access.

## Related context-control correction

Use Solo settings remains available in Party/Raid outside combat, even when already inheriting. SituationChanged refreshes context labels immediately without rebuilding the page or stealing input focus. This applies to buffs, weapons and consumables. Paladin target plans remain configurable while Target/Nearby are off; their class-aware mode and combat restrictions remain. Profile copy/delete selectors already refresh their dependent buttons after selection; regression tests exercise that flow without deleting a profile.

## Evidence and remaining live review

New tests cover all nine class pages in Party/Raid with learned/unlearned relevant spells, fresh/legacy defaults, explicit pet policy, stale roles, broadcast self actions, intentional utility assignment, context preservation, same-class profile copying and immediate reset controls. Existing full-suite tests cover export/import and secure action validation.

This beta still needs owner visual review in Forever. Check a utility class, the Druid full page, Paladin's dedicated page and broadcast/info pages as available. Confirm My buffs Party/Raid checkbox edits can immediately be undone with Use Solo settings. No public upload is authorized by this implementation handoff.

## Beta2 follow-up

Owner's level-one Rogue screenshots exposed remaining generic My buffs/Target/Nearby surfaces and an impossible saved coating reminder. My buffs now has an explanatory state for Rogues; Target uses it for Hunter, Warrior and Rogue. Supported unlearned families keep their normal editors. The sidebar stays in place, with no active-mode light for an inapplicable personal/target mode.

Nearby retains browsing, invitations, requests and presentation choices. Casting-only controls are hidden by capabilities, with actual row/card/guide reflow rather than empty slots. Saved options remain stored. Classes without external actions do not get casting-specific mana/rest pauses or the unused rest shortcut; they do not scan favor auras. View/provider ordering preferences and request validation remain unchanged.

Weapon defaults still choose no coating. Explicit saved oils/stones/poisons use public client item-level and usability evidence before reminders; unknown/below-level requirements are silent. Existing bounded metadata requests and completion events restore valid notices. Lower eligible carried ranks, real Forever item poisons, explicit eligible empty-stock notices and Skip when I have none remain covered. No guessed Rogue unlock level or settings-file edits.

Final beta2 integrated mocked Lua 5.1 result: 3,116 passed, zero failed. Includes all-nine-class/two-locale learned/unlearned page cases, level-one saved-stone reproduction, click-time revalidation and metadata recovery. No live visual verification is claimed; install beta2 for owner review.
