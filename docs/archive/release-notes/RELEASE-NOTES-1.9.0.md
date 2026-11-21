# BuffTap 1.9.0

- All Paladin seals now start off; explicitly saved seal choices are preserved. Tactical combat abilities remain excluded.
- Refined Paladin assignment controls with native dropdown arrows, icons, selection checks, clearer labels, and distinct player-exception expansion. Re-clicking an expanded class now closes it. Inactive group/target controls are dimmed and explained; paging appears only when needed. Buff timing and priority controls include clearer help.
- Friendly-target Paladin blessings now consider the recipient’s class before selecting from enabled buff priorities. Customize each class independently in Target, choose Skip, or disable class-aware selection to retain unrestricted priorities.
- Grouped targets still follow enabled party/raid blessing assignments and player exceptions. Automatic target choices avoid inappropriate Might/Wisdom suggestions; explicit class choices can override suitability. Unlearned or disabled target choices fall back to Automatic without deleting the saved preference.
- Added an optional Helpers → Reminder behavior setting to pause reminders in cities and inns using the client’s resting state. Disabled by default.
- Mounting now also quiets stock badges, automatic stock messages, ready-check summaries, and alert sounds. Settings access remains available; sound previews and explicitly requested stock reports remain usable.
- Pause/resume updates are event-driven. Prepared blessings are revalidated before use, and pet-return grace after dismounting is preserved.

Validation: 531 isolated mocked Lua 5.1 scenarios passed, including 53 new cases. Live-client confirmation of target preference layout, Paladin target choices, and city/inn/mount transitions remains required. No periodic location polling or new libraries.
