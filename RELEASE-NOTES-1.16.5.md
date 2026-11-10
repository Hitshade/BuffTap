# BuffTap 1.16.5

- Improved solo-thanks detection and recovery from incomplete aura data. Tracks identifiable buff applications, replacements and refreshes, with brief retries for delayed caster information.
- Thanks different providers one second apart, with a one-minute cooldown per player. Short bursts are queued and duplicate providers are coalesced.
- Discards queued thanks when conditions change and verifies the caster before sending. Debug and Diagnostics include thanks status.
- Corrected Mark of the Wild rank selection for lower-level recipients using the ten-level allowance. Other spell families retain their existing rank rules.
- Clarified the unlearned group-spell label to explicitly name Gift of the Wild.

Existing settings and profiles are preserved. Combat casting remains disabled.
