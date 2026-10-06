# BuffTap 1.4.0 — Blessings made clearer

## New
- Paladin class blessing assignments inside Groups: choose a blessing for each recipient class, inherit existing settings, or skip a class.
- Expand a class for individual player choices and a Never Salvation safeguard. Exceptions use player identity and last until you leave the group or reload.
- Clear casting status explains when Greater Blessings are allowed, assignments conflict, or the chosen spell is unavailable. Learned game spells and native class/spell icons are used.
- Explicit class assignments start disabled, preserving existing settings. Solo personal settings and ungrouped target preferences remain independent; grouped targets follow enabled assignments.

## Safety and efficiency
- Greater Blessings require matching choices across affected same-class group members. Mixed choices, skipped/excluded members, and protected Salvation recipients use individual blessings.
- Group need thresholds still count verified recipients of the same spell rank; click validation cancels an outdated suggestion instead of substituting a spell on that input.
- Healthy matching blessings from other Paladins count as coverage. No automatic spec guessing, inspection, shared assignments or chat coordination.
- Uses existing event-driven roster and aura caches; no new recurring polling.

## Interface
- Refined header: left-aligned logo/title, aligned controls, native red Close artwork, roomier tabs sized for their labels; preserves the page area and screen scaling.
- Consistent dark cards, subdued gold borders, clearer buttons and compact rows throughout the options pages and item picker.
- Shared group settings remain visible above the buff editor. Paladins can still access existing buff filters.
- Weapons remains before Appearance; Helpers precedes Diagnostics.
- Class rows stay visible with one inline exception section open. Large class rosters page two players at a time within that section.
- Window scales to smaller screens.

Validation: 383 mocked Lua 5.1 scenarios passed, including 38 assignment/UI cases and three header regressions and layout-bound checks. Actual client visuals, blessing overwrite behavior, and secure casting still require in-game verification. Prepared locally; not published.
