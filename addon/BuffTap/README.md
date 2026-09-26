# BuffTap

### Your buffs, one tap away.

Stay ready for the next pullâ€”or lend a passing adventurer a helping hand. **BuffTap** brings personal buffs, group assignments, and optional consumables together in one customizable reminder for **WoW Forever**.

When a supported buff is missing or needs refreshing, BuffTap shows you what to apply and who needs it. **Click the icon, press your chosen key, or tap the mouse wheel** to apply the displayed action and move on to the next.

---

## âœ¨ Stay buffed, your way

**A simple, one-tap workflow**  
One reminder shows the next action in your queue. Choose your own binding, or use mouse wheel down by default. BuffTap releases its temporary binding when there is no action ready.

**Personal buff priorities**  
Choose which supported class buffs to maintain, set their priority, and decide how early to refresh them. Use a shared timing preference or customize individual buffs.

**Party and raid support**  
Assign recipient classes and raid groups per buff. Both filters apply together; parties use group 1. BuffTap chooses group versions when enough eligible players need the same buff and falls back to individual casts when class exclusions would be bypassed. Class filters select classes, not tank roles.

**A little kindness on the road**  
Enable friendly-target buffing to offer selected buffs to the player you target. Separate refresh settings let you help passersby without changing your normal party or raid timing. Explicit friendly targets ignore party/raid class and group filters, so any class can receive selected buffs such as Thorns. Paladin blessings follow your priority order and maintain one blessing family per recipient.

**Optional consumable reminders**  
Track a curated selection of food, flasks, and Elixir of Ferocity. BuffTap offers supported items from your bags and recognizes existing food and flask effects. **All consumable reminders start disabled.**

**Manual weapon-coating alerts**  
Rogues and Shamans can receive a simple warning when an equipped main-hand or off-hand weapon has no temporary coating. Main and off hand can be selected separately. These alerts are intentionally manual: BuffTap never applies or replaces a poison or weapon imbue, and ready spell or item actions remain ahead of the warning.

**Detailed Camp Benefits status**  
When Camp Benefits is active, BuffTap can identify the exact granted additions exposed by Forever, such as First Aid Kit or Incense Candle. Camp additions remain informational and never suppress class buffs based only on similar stat text.

## ðŸŽ¨ Make it fit your UI

Keep the reminder subtle or make it easier to spot:

- Drag the icon into place, or set its position precisely.
- Adjust icon size and opacity.
- Choose buff names, recipient labels, remaining time, and group counts.
- Add an optional glow, pulse, or reminder sound.
- Set a keyboard or mouse-wheel binding that feels natural.

Everything is available in one options window, with separate pages for buffs, groups, friendly targets, consumables, appearance, and diagnostics.

## Getting started

1. Install BuffTap in your Forever client's `Interface/AddOns` folder, then restart the game or `/reload`.
2. Type **`/bt`**, or open **Settings â†’ AddOns â†’ BuffTap**.
3. Choose your buffs and binding. Under **Appearance**, select **Move icon** to position the reminder.
4. Enable group, friendly-target, or consumable features whenever you need them.

**See the buff. Tap to apply it. Keep adventuring.**

## Good to know

BuffTap is designed for **out-of-combat buff maintenance**. Each cast or item use requires your input, and casting through BuffTap is suspended during combat.

This is an early release for WoW Forever. Supported abilities depend on your class and learned spells. Rogue poisons and Shaman weapon imbues have **missing-coating alerts only**; application remains manual. BuffTap does not currently track oils, sharpening stones, or weightstones. Camp Benefits and their recognized additions are informational; campsite interactions are not automated.

## Feedback & support

Found a missing buff or unexpected behavior? Include your **class**, **BuffTap version**, **game build**, and a short description of how to reproduce it. Output from **`/bt debug`** helps narrow things down.

For optional performance diagnostics, use `/bt profile on` and `/bt profile off`.

---

**Credits & license:** BuffTap's original code is available under **MPL 2.0**. Its buff catalog was derived from **Keepward** and retains the original personal-WoW-use license. See the included license files for details.

**AI use:** BuffTap was developed with AI-assisted coding and review, with automated tests and Forever-specific API/data checks.

### Choose your consumables

Food and flask reminders offer Auto or a specific item. The selected-elixir reminder maintains one item of your choice and preserves any recognized elixir already active; it does not manage elixir stacking. Existing Ferocity settings carry over.

Use **Choose** to search supported items, filter to **In bags only**, and see selection checkmarks and bag counts. Items you do not carry show **Out of stock**, and remain selected until you change them. Hover for effect details. Potion selection tracks stock in options only; use potions manually.

The catalog contains 102 foods, 59 elixirs and 85 potion inventory choices. All consumable reminders remain optional. Unknown item mappings are skipped, and camping behavior is unchanged.
