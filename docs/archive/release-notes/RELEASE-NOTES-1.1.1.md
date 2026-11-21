# BuffTap 1.1.1 — Runtime efficiency

- Reuses normalized aura and consumable names to reduce repeated work during refreshes.
- Disabled pet and Healthstone helpers now avoid unnecessary class checks.
- Uses player-filtered power, spellcast and readiness events when supported, with compatibility fallback to the prior event path.
- Skips inactive reminder-dismissal and diagnostic formatting work.
- Keeps existing target response timing, aura and roster recovery windows, weapon reminders and key bindings unchanged.

This maintenance build received Lua syntax/load and package-integrity checks. The Python regression suite was intentionally not run for this build.
