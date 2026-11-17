# BuffTap 1.26.1-beta3

### Fixed
SmartShift could miss the cooldown information it needed when the game reported the global cooldown before confirming the buff and form exit. The return form now uses that earlier information as soon as both confirmations arrive, rather than waiting for another cooldown update.

The ordinary buff queue and GCD sweep are retained. Returning still requires your input, and an unconfirmed or failed buff never permits a return. This timing correction has automated event-order coverage and needs a fresh in-game check.

# BuffTap 1.26.1-beta2

### Added
A standard cooldown sweep now shows the wait on a queued class-buff icon. It appears automatically, with no settings change, and disappears when the global cooldown finishes. If you use the optional rebuff countdown sweep, that display resumes afterward. Finishing the wait does not create an extra reminder sound.

### Changed
Druid and Shaman SmartShift return forms can now stay available during a confirmed global cooldown too. Ordinary class self buffs already share this queue behavior, including armors, shields, aspects and blessings. Spells with their own cooldown still wait; item-use cooldown behavior is unchanged.

### Limits
The owner confirmed smoother ordinary buffing in beta1. The new sweep and form extension need in-game testing. Existing safety checks and settings are retained, and every cast still requires your input. Thanks to **Mechrite** for the original suggestion.

# BuffTap 1.26.1-beta1

### Changed
This test build prepares an eligible next class buff during the global cooldown, instead of temporarily removing the buff binding. Repeated clicks or key presses can then reach the game's normal spell queue. No setup changes are needed, and your existing choices are preserved.

### Limits
Each cast still needs your input. The improvement depends on clear cooldown information from the Forever client; spells with a separate cooldown and uncertain information retain the previous waiting behavior. Consumable and helper cooldown rules are unchanged. This has automated coverage but still needs in-game testing for how smooth it feels.

Thanks to **Mechrite** for raising the delay between buffs.

# BuffTap 1.26.0

### Added
Food, Flask, Elixirs and Utility each have an optional **Manual** mode on Consumables. Auto keeps the existing behavior. Manual items appear as small, centered icons with stock counts; click an icon directly to use that item. The buff binding and mouse wheel skip Manual families. Solo, Party and Raid can use different modes.

The strip stays visible when the main reminder is hidden or idle. Under Customization > Buff reminder, enable **Detach consumables** to position it separately with **Move reminders** or Edit Mode. Done saves; Cancel restores the move session's starting positions. Reset look & position restores defaults without changing item choices.

Appearance settings put Visible labels before Text, including label position. Camping and Supplies have larger previews and fuller layouts. Timers are centered, group counts sit at the top right, and Modern Soft glow/Pulse has a rounded inside and square outer halo.

My buffs now explains default refresh timings in an information panel instead of showing a second slider. Adjust each buff's row, or use Reset default timings for the selected Solo, Party or Raid setup. Resetting timings leaves buff choices and priorities alone.

### Fixed
The release review corrected prepared clicks after disabling BuffTap, SmartShift ignoring pauses or waiting too long after cooldowns, Manual icons returning late at refresh thresholds, and appearance reset leaving some choices unchanged.

Selected elixir and utility thumbnails now have their own space along the bottom-left of each row, with refresh timing on the right, so they no longer overlap the selection text.

### Limits
Up to eight Manual effects are clickable. Hover +N for remaining effects to use from your bags. Unknown stock shows a question mark. Unsafe player states hide the icons; changed items cancel the click. Manual food leaves class reminders available while eating.

Automated regression checks passed; final Forever testing is still recommended. Thanks to **Xprit44** for the suggestion.

# BuffTap 1.25.0

Class settings can be prepared ahead of learning spells, including cleansing types, resurrection, Druid Rebirth and cleansing order. BuffTap still requires a learned, usable spell before offering a cast. Prefer Abolish appears only for Druids and Priests.

Open My buffs > Review class setup to choose recommendations. Review starts unchecked and asks for confirmation. You can create a profile backup first. Paladin recommendations use blessing priorities that adapt as spells are learned. Shaman recommendations set the main-hand preference, while weapon application remains a separate choice. Manual fixed preferences stay fixed.

Druids and Shamans can enable SmartShift to offer their previous form after BuffTap self-buffing. Each buff and the return require your input. Return reminders are silent. Food and Elixirs have category dropdowns and benefit descriptions; filtering never changes saved selections or automatic item choice. Rogue choices now include Atrophic, Numbing, Sebacious and Occult Poison.

Your existing settings are preserved. Cleansing and resurrection start off for fresh profiles, and can be enabled whenever you choose. SmartShift is optional and never changes form without your click or binding. Existing contributor acknowledgments remain in the release history below.

# BuffTap 1.18.0

## A redesigned settings window

- Rebuilt the settings window with a new sidebar, page icons, rounded controls, on/off switches and the Inter typeface. The BuffTap banner stays at the top.
- Sliders now show what they measure (seconds, pixels, percent or players) inside their value fields. Hover a slider to see its range. Type a number and press Enter to save, or Escape to cancel.
- Preview your buff and camping reminders while adjusting their appearance. Previews never cast, target or play alerts.
- Choose gold, your class colour or a custom colour for the interface accent. The window size can be scaled.
- Nearby has its own appearance settings: scale, width, background and visible rows.
- Patch notes now live inside the addon, covering the ten most recent versions. The newest release opens first; click any other version to expand it.
- Buffs list: unchecked buffs are dimmed, Default appears only when a buff has its own timing, and the arrows reorder priority.

## New option

- Pause consumable and weapon reminders while resting in cities and inns, separately from buff reminders. Find it on the Consumables and Weapons pages. Thanks to waggz81 for the idea.

## Corrections

- Item choices now show the client's localized item names.
- Party and raid group preferences are no longer exposed to a name clash with other addons when loading.
- `/bt reset` now asks for confirmation: type `/bt reset confirm`.
- Many settings texts are now translated in German, French, Spanish and Brazilian Portuguese.

Every cast still requires your click or key binding. Your existing settings, profiles and Solo, Party and Raid preferences are kept.
