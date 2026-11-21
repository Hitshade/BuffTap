# BuffTap 1.18.0

## A redesigned settings window

- Rebuilt the settings window from the ground up: a full-height sidebar with line icons, a header with the BuffTap banner, version, master on/off switch and active setup, and a consistent page layout with a title, short description and section cards on every page.
- New controls throughout: rounded buttons with hover and pressed states, on/off switches for labelled settings, compact checkboxes for lists and grids, rounded fields and dropdowns, thin scrollbars and pill-shaped sliders.
- New typeface: Inter (SIL Open Font License), with a standard game font fallback. One type scale is used everywhere, so titles, section headings, labels and descriptions are consistently sized.
- Choose BuffTap gold, your class colour or any custom colour as the interface accent. The settings window can be scaled.
- Content inside every section card has consistent padding, and list rows have soft outlines that highlight on hover.
- Every settings tooltip shares one layout: title, description and, where useful, a short note.
- Live previews of the buff reminder and camping reminder appear while you adjust their appearance. Previews never cast, target or play alerts.

## Sliders

- Every slider shows what it changes inside its value field: seconds, pixels, percent or players.
- Hover a slider to see its full range. Type a number and press Enter to save, or Escape to cancel.
- Removed the separate minimum and maximum labels under sliders.

## Buffs page

- Unchecked buffs are dimmed so the active ones stand out.
- The Default button appears only when a buff has its own rebuff timing.
- Priority is shown as a rank number; use the arrows to move a buff earlier or later.
- Rebuff and Priority column headings line up with the controls beneath them.

## Nearby

- New appearance settings for the Nearby window: scale, width, background opacity and visible rows.

## Patch notes in the addon

- A Patch notes page covers the ten most recent versions. The newest release opens first and older versions expand with a click. An optional dot on the sidebar marks unread notes.

## New option: pause while resting

- Consumables and Weapons each have a Pause while resting option. When enabled, food, flask, elixir, utility and weapon buff reminders are skipped in cities and inns so you do not use them while resting. Buff reminders continue as usual. Off by default and saved per character and in profiles. Thanks to waggz81 for the idea.

## Translations

- Translated the remaining settings text into German, French, Spanish and Brazilian Portuguese, and removed unused translation entries. Native-speaker corrections are welcome.
- Buttons whose translated label is too long step down a size instead of overflowing.

## Corrections

- Fixed three places where settings code could read an undefined value: loading party and raid group preferences, choosing which consumable to use, and the item picker.
- Item choices show the client's localized item names.
- `/bt reset` now asks for confirmation: type `/bt reset confirm`. The reset button in the window uses the same path.

## Compatibility

Every cast, item use and craft still requires your click or key binding, and nothing is cast in combat. Your existing settings, profiles and Solo, Party and Raid preferences are kept.
