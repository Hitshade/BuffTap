# BuffTap 1.8.1

- Fix an options/diagnostics error when an oil or stone reminder lacked its weapon-hand label, including out-of-stock reminders.
- Ensure main-hand and off-hand coating reminders carry readable hand labels.
- Handle incomplete action display metadata safely in diagnostics.
- Include the shortened addon overview.

Validation: 478 mocked Lua 5.1 scenarios passed, including three new regression cases. Live-client verification of this hotfix remains pending.

