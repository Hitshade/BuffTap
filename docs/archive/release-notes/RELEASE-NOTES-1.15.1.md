# BuffTap 1.15.1 - Named profiles

Prepared locally for in-game testing. Published stable remains 1.14.2. This release contains named profiles, not the discarded live roster beta.

- Clarified creation with Create & switch, explicit starting settings, confirmation before default creation, and a dedicated Rename dialog beside Active profile.
- New Profiles tab with active-profile selection, create from defaults/current preferences, copy, rename, reset and unused-profile deletion.
- Profiles share bindings, reminder appearance/position, sounds, minimap/Broker preferences and general reminder behavior. Existing characters are migrated to independent named profiles, preserving their setup.
- Buff selections, priorities, timing, target/group assignments, weapon/consumable/supply settings and class readiness stay character-specific when switching or copying shared preferences.
- Copying optionally includes a saved buff/class setup from a matching-class character. The checkbox appears only when a compatible source exists; the copy function independently rejects other or unreadable classes. Copied values pass through normal validation.
- Shared profile edits affect characters linked to it. Copy into a separate profile to keep independent preferences. Class copies are one-time imports, never live links.
- Temporary player exceptions, pause/dismissal state, caches and onboarding state are not imported. Individual player exceptions retain their existing group-session/reload behavior.
- Profile operations are blocked in combat. Switching refreshes the reminder and secure bindings immediately. Copy/reset/delete require confirmation; deletion is limited to profiles unused by known characters. Reset all settings detaches the current character rather than resetting another character's shared profile.
- Embedded unmodified AceDB-3.0 minor 39, with its license; no AceGUI/AceConfig dependencies. Profile controls and confirmations are localized in German, French, Spanish and Brazilian Portuguese.

Validation: 882 mocked Lua 5.1 scenarios passed. Coverage includes real database serialization/reload across characters, opt-in same-class copies, cross-class/unknown-class rejection, immediate binding replacement, migration backup recovery, reset isolation, combat guards, localization and panel geometry. Shipped Lua syntax, TOC paths and archive contents verified. Live client interaction/appearance remains for testing.
