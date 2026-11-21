# BuffTap 1.2.0 — Scroll-to-apply weapon buffs

- New integrated Weapons options page with native icons, preferred buff selectors, and poison stock availability.
- Opt-in scroll/click application for learned Shaman main-hand imbues and supported carried Rogue poison items on either hand.
- Separate Rogue hand preferences; Shamans maintain their single main-hand weapon. Shields, held off-hand items, and fishing poles are excluded.
- Choose a refresh threshold from 0 to 300 seconds. A different existing buff is preserved unless replacement is explicitly enabled; unknown effects remain manual.
- Uses Forever's weapon-enchant categories so an oil cannot satisfy a missing Shaman imbue. Permanent enchants never satisfy weapon-buff reminders.
- Schedules threshold/expiry checks through the existing wake timer; no new polling loop. Bag restocks and metadata-load events restore ready poison actions.
- Revalidates preferences, weapon identity, stock, usability and cooldown before arming/clicking; clears weapon targeting on combat entry and when returning to ordinary buffs.
- Weapon application starts disabled, preserving existing manual-alert behavior. Open `/bt` → Weapons, choose preferences, and enable Apply through scroll / click.

Validation: 228 mocked Lua 5.1 scenarios passed (189 prior plus 39 weapon scenarios). Live-client application, especially Rogue off-hand targeting and the options layout, needs an in-game smoke test before publication.
