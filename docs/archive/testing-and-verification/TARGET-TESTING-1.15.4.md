# Target troubleshooting test checklist

- Compare two unbuffed players of the same class and level in spell range.
- With custom priorities and first-choice selection, confirm missing Kings is offered.
- With fallback enabled, another identified Paladin's fresh Kings permits the next eligible blessing.
- With fallback disabled, another Paladin's Kings does not advance the list.
- Your own healthy Kings or Wisdom must never be replaced by a different priority in either mode.
- Unknown caster information must block replacement and explain why in /bt debug.
- If a player is skipped, collect /bt debug while that player remains targeted. Capture Target settings and whether the reminder was dismissed. Restore reminders in Helpers and compare.
- Switch targets rapidly, enter combat and leave combat. No stale action should remain and normal selection should resume.

This build adds diagnostic evidence; it does not establish the cause of the original live report. Mock tests cannot establish Forever's actual aura/caster returns.
