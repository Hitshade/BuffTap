# BuffTap 1.15.4

Prepared for local in-game testing. Not published.

- Friendly-target diagnostics now explain rejected target metadata, unreadable aura scans, unknown blessing ownership, retained own blessings, group-assignment precedence and dismissed reminders.
- Incomplete target class, level, aura or caster data receives up to two additional one-shot retries after the existing settling checks. Retries stop when data recovers, the target changes, combat starts or the addon/mode is disabled. There is no continuous target polling.
- Fixed first-choice target mode with fallback disabled bypassing blessing ownership checks. An existing own blessing remains protected in both selection modes.
- Unknown ownership and restricted aura data still fail closed. No new combat buffing or ownership assumptions are introduced.

For testing, target a player who is unexpectedly skipped and run /bt debug. Include the complete output, addon/client version, Target priorities and whether Kings was yours or another Paladin's. Restricted aura values are not dumped.
