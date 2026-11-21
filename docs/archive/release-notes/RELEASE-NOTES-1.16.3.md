# BuffTap 1.16.3

- Added a battleground self-buff fallback while out of combat. Enabled self-castable class buffs are checked individually when normal aura scanning is restricted.
- Only verified missing self buffs are offered. Hidden or unreadable data is never treated as a missing buff. Existing blessings and related group-buff coverage are preserved.
- Rechecks buff state before casting and uses existing buff preferences and profiles. No profile migration is required.
- Debug output identifies BG self-only mode and unavailable self-buff information.
- Buffing other players remains unavailable while BG aura restrictions prevent verification. In-combat casting remains disabled.

BG self-buff support still needs live testing. Some spells may remain restricted. If a missing self buff is not offered while out of combat, please provide /bt debug output from inside the battleground.
