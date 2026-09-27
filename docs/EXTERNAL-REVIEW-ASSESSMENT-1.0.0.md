# BuffTap 1.0.0 external-review assessment

## Applied corrections

- Fixed party coverage's Shadow Protection key from `shadow` to the actual catalog key `sp`; added a missing/present regression.
- Stronger-effect suppression requires both the localized bounce error and a matching player spell-failure event within the existing 0.5-second window, in either order. Consumables match their use spell, not their item ID. Success, interruption, unrelated failure, other errors and expiration close attribution. No polling or timers added.
- Gathering preference explicitly defaults to zero (unselected), validates saved IDs and prompts for a selection. It never automatically chooses a profession tracker; existing supported preferences persist.
- Removed all three obsolete `stockOnly` guards and cleaned historical changelog encoding/duplicate heading.

## Suggestions not applied

- **Change emote target to a unit token:** modern Blizzard-generated `C_ChatInfo.PerformEmote` documentation specifies `targetName`, not a unit token. Retained name resolution with realm and source GUID revalidation. The specific Forever client and legacy fallback still need live verification. No claim that emotes were executed in-game.
- **Remove ClearOverrideBindings:** retained. Commit must also release old overrides when the action disappears or settings change outside combat; a blocked-state transition is not guaranteed in those cases.
- **Replace the UI error event entirely:** `UNIT_SPELLCAST_FAILED` identifies a spell but does not provide the failure reason. Correlation uses both events. It reduces misattribution but cannot prove that a manually cast identical spell belongs to this click. If the client omits either event, suppression safely does nothing.
- **Add success-clearing test:** that test already existed and still passes. Expanded failure/interruption tests instead.
- **Default helperTracker to nil:** Lua does not retain nil table entries. Used an explicit zero sentinel and visible choice prompt.

## Deferred optional cleanup

Dormant legacy catalog tracker rows, the overwritten initial eating-ID table, a spare rank entry and sound-constant consolidation are nonblocking cleanup suggestions. They were not mixed into these behavior fixes.

## Validation and remaining live checks

129 mocked Lua 5.1 scenarios pass, including five new regressions. All eight Lua files load in the harness. The installable ZIP is byte-compared with source, archive integrity checked and TOC references verified. Mock tests cannot validate real-client secure execution, UI layout, transient caster tokens or event ordering. Continue live checks of stronger-effect suppression and tracker selection in Forever. Solo thanks was subsequently confirmed by the maintainer. The maintainer subsequently authorized publication and confirmed solo-thanks emotes work in game on 2026-09-27.

The external reviewers assessed the previous installable; missing test files in an installable are expected. The refreshed Review-Inputs ZIP includes source, tests and supporting release documents.

## API evidence

- [Blizzard-generated ChatInfo API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua): PerformEmote targetName.
- [Blizzard-generated Unit API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua): failed/succeeded event arguments.

Reviewed original ZIP SHA-256: 12608d09c3bdac97d1a8167c04ef7fcc8a6ec786c40a2bbb92ba7e6c8560bc21

Rebuilt ZIP SHA-256: 1e9b8ac357a5ee906206b6e3bed918c6373d9d0cac9b295c2d5f000c964ee069

