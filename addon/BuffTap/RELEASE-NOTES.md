# BuffTap 1.16.9

- Fixed a solo-thanks path that could produce a general thank-you emote when the game could not resolve a caster by name.
- Added native GUID-to-unit lookup to recover a live buff provider where available. Automatic thanks now always requires a live recipient whose identity is checked immediately before the emote.
- When a provider is identified only by GUID/name, BuffTap skips the emote and reports that no live unit is available. It never changes your selected target or falls back to a general thank-you.

Existing settings and profiles are preserved. Every buff cast still requires your click or binding. Combat casting remains disabled.
