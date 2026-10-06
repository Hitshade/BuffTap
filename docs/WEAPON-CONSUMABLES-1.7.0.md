# Weapon consumables research and implementation — 1.7.0

## Verified evidence

Blizzard Forever API exports expose independent Permanent, Temporary and Imbue categories through C_Item.GetWeaponEnchantInfo. Inventory slots 16/17 are mapped to WeaponSlot enum values, as in the existing implementation.

- API source: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua
- Enum source: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemConstantsDocumentation.lua
- Archived API snapshots: research/weapon-consumables-1.7.0/.
- Catalog source: existing Blizzard Forever 1.60.1.70009 DB2 exports via wago.tools. ItemXItemEffect → ItemEffect gives the actual item-use spell; SpellEffect effect 54 gives the temporary enchant ID. SpellEquippedItems supplies weapon subclass/inventory-type masks.
- Poison uses effect 360 (imbue) in that export, whereas these oils/stones use effect 54 (temporary). We track and validate these independently. Permanent enchants never satisfy either.
- Reproducible generator: tools/build_coatings.py; selected records and source hashes: research/weapon-consumables-1.7.0/catalog-evidence.json.
- An attempted 1.60.1.70205 export refresh returned HTTP 403. We retained the verified existing dataset. Runtime item spell identity, usability, equipment masks and readable enchant category/timer checks are mandatory before preparing an item. This is not a claim of live-client validation.

## Included

12 choices covering 20 item IDs: Minor/Lesser/normal/Brilliant Wizard Oil; Minor/Lesser/Brilliant Mana Oil; Rough through Dense Sharpening Stones and Weightstones; Elemental Sharpening Stone; Shadow Oil and Frost Oil.

Wizard/Mana oil tiers remain explicit choices. Sharpening/weightstone ranks select the highest carried usable supported rank. Weapon masks come from the client data, not assumptions about names: notably Elemental Sharpening Stone has its own mask. Only equipped compatible melee weapons are used; no shields, held items, ranged weapons, fishing poles or trade targets.

Temporary coating preferences are independent per hand and default to None for all classes. The existing enable/hand/application/replacement/expiry settings also apply. Class-specific poison/imbue preferences remain separate. An existing different recognized temporary coating is preserved unless replacement is enabled; unknown effects never become automatic replacements. Missing APIs and secret values fail closed. No legacy aggregate-enchant fallback can authorize these new item actions.

Actions use the existing secure item button and target-slot handling, with click-time item, preference and weapon-identity revalidation. Application remains player initiated and out of combat. Existing event refreshes and bounded expiry timers are reused, with no new periodic polling.

Optional Supplies warnings include selected compatible oils/stones. Shared selections count once. Multi-use Wizard/Mana Oils count remaining applications through GetItemCount(includeUses=true); cache entries are separate from bottle counts. All bank flags remain false.

## Deliberate exclusions / remaining opportunity

Mage-specific Imbue scrolls are present in the client spell-name data (for example Imbue Lesser Flame 1295720 and Imbue Chillknife 1296225). They have distinct class/weapon targeting and have not been added speculatively. This is the next weapon-buff opportunity to audit separately.

Rare event-specific Blessed Wizard Oil / Consecrated Sharpening Stone and season-specific Blackfathom consumables are not offered solely because their records exist. Availability and intended Forever behavior have not been established. No auto-purchasing, bank/alt tracking, performance scoring or cross-player assignments.

## Verification

444 mocked Lua 5.1 scenarios passed, including every supported item/enchant pair, weapon restrictions, category coexistence, rank selection, expiry wakes without polling, inventory/weapon/preference changes at click, secret/missing APIs, replacement protection, per-hand targeting, oil charges and cache separation, independent supplies and combat safety. All 22 Lua load files compile/load under Lua 5.1. Library sources remain unchanged.

Live checks still needed: apply one oil/stone with scroll to each eligible hand; confirm coexistence with Rogue poison and a Shaman imbue; test partially used oil counts and bag notifications; inspect dropdowns and translated labels. Automated mocks cannot confirm actual in-game application.
