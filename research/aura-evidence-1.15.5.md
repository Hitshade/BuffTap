# Forever aura evidence and integration

Source inspected: Gethe/wow-ui-source forever branch, commit 172a387e3ab85b26e6640d3058d5ec1e6ccd4c63.

- Interface/AddOns/Blizzard_FrameXMLUtil/AuraUtil.lua, AuraFilters.Player: PLAYER includes auras cast by the player, pet or vehicle.
- Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua: IsAuraFilteredOutByInstanceID(unit, auraInstanceID, filter) returns bool and requires unit aura access. GetUnitAuras also requires that access.
- Source: https://github.com/Gethe/wow-ui-source/tree/172a387e3ab85b26e6640d3058d5ec1e6ccd4c63

Implementation queries HELPFUL first to establish that the exact aura instance exists, then HELPFUL|PLAYER. Only public booleans are used. Failure, missing identity or restricted results provide no permission to replace a blessing. Existing resolved caster tokens remain the first ownership source. Combat and global aura-secrecy gates remain unchanged. This is ordinary API filtering, not a restriction bypass.

Partial scans preserve identity and presence, not inferred absence. Unknown identities block missing/expiring actions. Restricted timing on a known aura means present with unknown expiry. Strict consumers outside the buff-selection path still receive failure for incomplete/restricted scans. Partial scans are not cached as complete. Own tactical blessings continue blocking ordinary blessing replacement.

Priority suppression is consulted after establishing ownership. Suppression cannot allow replacing an existing own blessing, changing a fixed assignment or bypassing disabled fallback. Suppression remains scoped to its existing family/target key and restoration behavior.

SnapBuff r6 and BuffRadar 1.1.1 were inspected for methodology only. No third-party source was copied into BuffTap. Their simpler blessing assignments are not evidence that unknown ownership is safe.

No live client/API execution has been performed. Verify filter availability and public results in the actual Forever client; unavailable results safely retain prior behavior.
