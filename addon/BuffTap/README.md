# BuffTap

### ⚡ Less buff management. More adventure.

**Smart buff reminders, one-tap rebuffing, and optional quality-of-life automation for WoW Forever.**

BuffTap watches your buffs, works out what needs attention, and prepares the next action for you. Click the icon or press your chosen key to keep moving through missing buffs—without hunting through spellbooks, action bars, or bags.

**Automate the reminders and preparation. Stay in control of every cast.** BuffTap automatically detects, prioritizes, and updates its suggestions; casting spells and using items still require your click or keypress.

**Version 1.3.0.** Optional conveniences are available in the main **Helpers** tab and start disabled, so you can choose exactly how much assistance you want.

## One tap, your priorities

- **Automatic buff reminders:** Catch missing and expiring supported buffs, then advance to the next action after applying them.
- **Your preferred binding:** Use a keyboard key, mouse wheel, middle/side mouse button, or the clickable icon. Mouse buttons support Shift/Ctrl/Alt; left/right click requires a modifier.
- **Class-aware buffing:** Maintain learned class buffs with configurable priorities and refresh timing.
- **Friendly-target buffing:** Quickly buff another player using settings independent of your party and raid assignments.
- **Smart group spells:** Prefer group versions when enough eligible players need the buff, with configurable thresholds.
- **Paladin priorities:** Choose your blessing order and recipient filters while preserving BuffTap's blessing-family selection rules.

## Party and raid buff management

Set recipients **per buff, raid group, and class**. Maintain broader coverage for Mark of the Wild while limiting group Thorns to the classes you choose. Class filters are choices, not automatic tank-role detection; open-world friendly-target buffing remains independent.

The optional **party coverage panel** highlights missing buffs another party member's class may provide. It is informational, does not send chat messages, and currently covers five-player parties. The suggested provider's actual spellbook is not assumed known.

## 🧪 Consumables without the bag search

Choose supported **food buffs, flasks, and an elixir** to maintain. Search by name, filter to items in your bags, and keep a preferred item selected even when it runs out. Consumable reminders are optional and start disabled.

- **Quick choices:** Hover a consumable reminder to select another supported item from your bags, then use the main icon to apply it.
- **Predictable preferences:** Keep explicit selections and see when they are out of stock.
- **Respect existing effects:** Food and elixir checks help prevent unnecessary replacement prompts.
- **Discovery report:** Optionally list unknown bag consumables for review. Discovery does not automatically enable or use unverified items.

## 🐾 Ready for the next pull

Enable **pet readiness** or **personal Healthstone preparation** in Helpers when you want them. Both start off, and ordinary buffing keeps its place ahead of these extras.

- **Warlocks:** Pick a learned preferred demon. BuffTap offers its summon when no living pet is present, respects Demonic Sacrifice, and never replaces a living demon just to match your preference.
- **Hunters:** One-tap Revive for a visible dead pet. An absent assigned pet gets a manual call/revive reminder when BuffTap cannot verify which recovery is needed.
- **Personal Healthstones:** Offers your highest learned Create Healthstone spell when you carry none. Any supported rank or improved version satisfies the check. Creation requires a Soul Shard and verified general bag space; the button never consumes a Healthstone.

These helpers wait through mount and pet transitions and offer casts only while stationary, out of combat, and otherwise ready to act. Missing or unreadable client data suppresses an action rather than guessing.

## Small conveniences that add up

- **Dismiss for now:** Right-click an unwanted reminder until your next zone change, or restore reminders immediately.
- **Fewer repeated errors:** Optionally suppress a recent BuffTap action when the game rejects it because a stronger effect is already active. Restore it manually or on zone change.
- **Gathering reminders:** Choose a learned Find Herbs, Find Minerals, or Find Fish tracker and get a one-tap reminder when it is off. BuffTap does not cycle between trackers.
- **Automatic solo thanks:** Opt in to a targeted `/thank` when another identifiable player gives you a supported buff while you are solo in the open world. Disabled in parties, raids, instances, and combat; limited to once per minute overall and once per ten minutes per player. If the caster cannot be verified, BuffTap stays quiet.
- **Scroll-to-apply weapon buffs:** Opt in to maintain your preferred learned Shaman imbue or carried Rogue poisons through the normal BuffTap binding. Choose each Rogue hand separately, set refresh timing, and decide whether a different existing buff may be replaced. Shamans maintain the main-hand weapon; shields and held off-hand items are excluded. Out-of-stock poisons retain their saved preference and show a manual reminder. Oils and sharpening stones are not automatically managed.

## Make it fit your UI

Move and resize the reminder, adjust opacity, show buff and target names, add remaining-time labels, or enable an optional glow, pulse, and sound. Native game icons, a searchable item picker, and compact assignment controls keep your choices readable.

BuffTap uses event-driven updates and cached information. Optional discovery runs on inventory changes rather than repeatedly scanning bags during ordinary aura updates.

## Get started

1. Install the **BuffTap** folder inside your Forever client's `Interface/AddOns` folder.
2. Type **`/bt`** to choose your buffs, binding, and appearance.
3. Enable party, friendly-target, or consumable features as needed.
4. Open the **Helpers tab** in the main options or type **`/bt helpers`** to choose the new conveniences. Use **`/bt restore`** to restore dismissed reminders.

BuffTap is built for **WoW Forever** and out-of-combat maintenance. It suspends its casting actions in combat. Supported abilities depend on your learned spells and the information the client exposes.

## Feedback and support

Include your class, addon version, game build, and steps to reproduce the issue. **`/bt debug`** provides diagnostics; optional profiling is available through **`/bt profile on`** and **`/bt profile off`**.

[Download on CurseForge](https://www.curseforge.com/wow/addons/bufftap) · [Source and issue reports](https://github.com/Hitshade/BuffTap)

---

**License:** BuffTap source is offered under **MPL 2.0**; see the bundled license notices. The class catalog is generated from WoW Forever client data. Game data and artwork remain their respective owners'. Developed with AI-assisted coding and review.

## 📦 Stay stocked for your next adventure

Enable **Consumables → Supplies** for optional **low-stock warnings** on your selected Rogue poisons, food buffs, flasks, and elixirs. Set a warning minimum and desired quantity for each supply, then see your usable stock and shortfall at a glance.

- **A small stock indicator:** Remains useful even when there is nothing to cast, without taking over the buff queue.
- **Your notification preferences:** Visual warnings, optional private chat alerts and sound, plus a ten-minute snooze.
- **Private ready-check summaries:** Opt in to a report of tracked supply shortages when a ready check begins. Nothing is sent to your group.
- **Predictable counts:** Explicit item choices count only that item; Auto combines usable supported items. Poison ranks are combined, and choosing the same poison for both hands counts it once.
- **Clear availability:** Distinguishes empty bags, low stock, carried but unusable items, and information that is still loading.

All supply features start disabled. Group-buff reagents and resurrection supplies are not included in stock warnings in this release.

**Smarter use of group reagents:** Before a reagent-consuming group buff fires, BuffTap checks that enough eligible recipients still need it. If another player has already supplied the buff, it cancels an unnecessary group cast and prepares the next suggestion for your next input. Mixed group spell ranks no longer combine to meet the threshold.

