# BuffTap 1.11.0

- Display actual icons for unlearned spells and group versions using verified Forever SpellMisc metadata; casting eligibility is unchanged.
- Mark unlearned spells in red and display opacity as a 0–100% field, retaining fractional saved values.
- Rename Appearance to Customization and clearly separate Binding, Reminder appearance, Sounds and Quick access.
- Replace ambiguous weapon application toggles with explicit Remind only / Remind and apply choices. Existing preferences and opt-in defaults are preserved.
- Sound and audio-channel selectors now show explicit lists instead of cycling. Weapon, oil/stone and demon selectors have visible dropdown arrows; reclicking closes menus.
- Add an event-updated status line to settings, including accurate manual-application status. Move header troubleshooting access to the existing Diagnostics page.
- Add saving guidance: immediate checkbox/list/slider changes, Enter or Escape for numeric fields, and clear Apply guidance for appearance fields.
- Correct consumable and target help; explain Automatic versus checked custom blessing priorities. Give the priority editor more space for its instructions.
- Preserve content space beneath the header and add localized primary labels for Spanish, German, French and Brazilian Portuguese.

Validation: 630 mocked Lua 5.1 scenarios pass, including explicit selection, close/reopen, combat protection and status updates. In-game visual confirmation remains pending. No buff selection, ownership, reagent or secure casting logic changes.
