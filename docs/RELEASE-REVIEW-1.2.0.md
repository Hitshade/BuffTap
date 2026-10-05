# BuffTap 1.2.0 release review

Prepared locally, not published. New weapon source is independently written using Forever API documentation and client DB2 exports. Prior runtime is preserved in research/pre-1.2.0; earlier release ZIPs unchanged.

Runtime: WeaponCoatings.lua, BuffTap.lua, Engine.lua, Options.lua, version metadata. Nine Lua files remain; no new polling/ticker. Selection priority remains aura buffs, consumables, optional readiness, then weapon application; manual weapon fallback cannot block another ready hand.

Known boundaries: supported poison items only, highest carried usable rank within the chosen family; no automatic crafting, oils, stones, weapon swaps, or in-combat application. Shaman off-hand preferences are hidden and ignored. Different effects are preserved by default. A five-second application settling window limits repeat clicks. Client replacement confirmations are left to the player.

Checks: 228 mocked Lua 5.1 scenarios, including 39 new weapon tests. All runtime Lua files load in each test. Mocking proves selection, secure attributes and event/timer behavior; it does not prove live protected execution or render fidelity.

Required in-game checks before publishing:
1. Shaman: a one-handed weapon plus shield, then a two-handed weapon; choose each learned imbue and scroll with the enchant missing. Verify the weapon buff appears and the reminder clears.
2. Shaman: an oil present without an imbue must not hide the missing-imbue action; shield must never be offered.
3. Rogue: Instant on main hand and Deadly on off hand; scroll each action and verify it lands on exactly the displayed hand. Confirm both hands independently with the same poison family too.
4. Let a coating reach the configured threshold and expire without unrelated actions; check refresh and replacement-confirmation behavior.
5. Remove poison stock, then restock; check the manual out-of-stock status and restored scroll action. Confirm higher carried ranks are chosen only when usable.
6. Enter combat while a weapon action is visible, then leave; no cast in combat, no stale binding or weapon targeting afterwards.
7. Inspect all eight options tabs; verify compact menus, icons, visibility, and readable layout. Set preferences, reload, and confirm persistence.

Do not publish until live hand-targeting checks pass. If a poison selects the wrong weapon on Forever, disable application and retain manual alerts while its client routing is investigated.
