# BuffTap 1.26.0-beta1

### Added
Appearance settings now put Visible labels before Text, so you choose what to display before styling it. This order is shared by Buff, Camping and Supplies.
Want the consumable icons closer to your action bars? In Customization > Buff reminder, turn on Detach consumables, then use the single Move reminders button. Detached consumables have their own drag handle in Edit Mode, even if no items currently need reminding. Every row stays centered around that position. Turn the switch off to restore the original arrangement. The preview balances the main reminder and consumable samples together within its box.

Appearance pages now have two aligned actions: Move reminders and Reset look & position. On Buff reminder, these sit level with the bottom of the Effect box, with the detachment switch above. Reset restores the selected reminder's default appearance and placement, so a separate Center button is unnecessary. Resetting the main reminder also reattaches its consumable icons; your Auto/Manual item choices remain unchanged.

BuffTap's move screen now offers Done and Cancel. Done keeps your changes; Cancel returns all reminder positions to where they were when you opened that move session, including any unfinished drag.
The main buff icon now places its group count in the top-right corner and centers the remaining time along the bottom. The appearance preview matches this layout.
Buff, Camping and Supplies previews now share the highlighted headings used by the other settings boxes, with the redundant sample caption removed.
The small icons have a muted Consumables heading in game and in the appearance preview, so their purpose is clear without labeling every item.
Food, Flask, Elixirs and Utility each have an Auto/Manual choice on the Consumables page. Everything starts in Auto, with the existing behavior. Choose Manual to keep reminders while using items only by clicking their small icons beneath the main buff reminder. The buff binding and mouse wheel skip Manual families. Your Solo, Party and Raid setups can use different modes.

Icons stay centered under the main reminder as their number changes, including shorter rows. They remain available when the main reminder is hidden or idle. Stock counts use white above three, amber for one to three, and red for zero; uncertain stock shows a question mark. Active effects leave the strip until they need refreshing. The Buff reminder appearance preview includes sample consumable icons.

### Safety and limits
Each click rechecks the exact displayed item. A changed or unavailable item cancels the click and refreshes the reminder. Icons hide in combat, while dead, mounted, in a vehicle, in a pet battle or stealthed. Up to eight effects are clickable; hover +N for the remaining effects and use those items from your bags. Manual food does not pause your normal class reminders while eating. Supplies is unchanged.

This internal beta has automated checks against a simulated game interface; live Forever testing is still required. Thanks to **Xprit44** for requesting food reminders without accidental mouse-wheel consumption.

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
