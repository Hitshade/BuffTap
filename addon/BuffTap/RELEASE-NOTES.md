# BuffTap 1.17.0

## Options and navigation

- Replaced the crowded horizontal tabs with an icon-led sidebar. All eleven pages remain directly accessible, with the same usable page area and no scrolling of the options window itself.
- Refined the dark surfaces, section cards, muted descriptions, selected navigation, selector arrow wells, menu selection highlights and text-field focus indicators. Native WoW action buttons and the existing banner remain in use.
- Grouped Profiles into clear active, create, copy and removal areas, preserving the existing create-from-current choice and confirmations.
- Removed the empty class-imbue area for classes that only use oils and stones, placing their hand checkboxes beside those choices. Class-specific imbue controls remain available where supported.
- Clarified Nearby instructions, including scrolling inside the window and using the buff binding after moving the pointer away. Configuration menus are opaque and clamped to the screen.
- Applied matching surfaces to onboarding, quick controls, item selection, assignment dialogs and camp setup. The Nearby player window keeps its established design.
- Added the current version to the options header, alongside the existing Diagnostics and debug version details.

## Camping and sleeping bag

- Added a separate Camping page and an optional, movable reminder for Camp Benefits and the sleeping bag's Well-Rested bonus. Track either benefit independently, including missing or expiring benefits away from a camp.
- Shows sleeping bag stacks and remaining duration alongside camp timing, with independent countdown and stack visibility. Live label timers reuse cached expiry information.
- Added warning thresholds, optional sound and snooze/resume controls. Camping stays separate from the regular buff queue and binding. Food reminders remain under Consumables.
- Added a compact setup tray for carried camping items and relevant profession recipes, using 39 verified recipe/item/use mappings across twelve professions. Carried items take precedence where appropriate.
- Item use rechecks the bag slot, spell, usability, cooldown and proximity before a click. Crafting opens the relevant profession first and requires another click to craft one item. Ground placement remains manual where required.

## Reminder customization

- Added soft glow, pulse, pixel border, sparkles and spell glow choices, with color and animation-speed options for both reminders. Corrected tinting so white and cyan retain their intended colors.
- Added font, pixel size, color, outline and text-spacing controls to regular Customization and Camping. Camp styling is independent of the regular reminder.
- Centered camp text beneath the icon and centered the Nearby invite plus independently of font bearings.
- Replaced ambiguous text defaults with the actual inherited game font/size where available. Outlines offer None, Thin and Thick; duplicate inherited choices are removed. Returning to the game font and size restores them correctly.
- General visual and camping preferences participate in named profiles. Temporary snoozes, inventory and profession knowledge are not copied.

## Catalog, helpers and Nearby

- Removed passive Omen of Clarity from selectable Druid buffs and corrected a Seal of Fury fallback rank level. Removed unused reagent entries for retired spells and verified catalog regeneration retains the supported spell and alternate-aura data.
- Added an opt-in Paladin Oath of Light helper for an explicitly assigned recipient, using the normal buff binding or click. Requires the talent. Its assignment remains character-specific and is available in explicit same-class profile copies.
- Added the opt-in Utility (selected) consumable family: Distilled Firewater, Winterfall Firewater, Dragonbreath Chili or Gift of Arthas. It maintains one selected preference and preserves a recognized existing utility effect until expiry.
- Fixed Nearby scrolling over player rows and invite controls, including when the configured buff binding uses the mouse wheel. The pointer must leave the Nearby window to use that wheel binding for buffing.

Existing preferences and profiles are preserved. Every cast, item use and craft still requires input. In-combat casting remains disabled. The prior Nearby allocation improvements and verified-recipient solo-thanks safeguards are retained.
