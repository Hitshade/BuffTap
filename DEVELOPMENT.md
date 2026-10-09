# BuffTap development

Current local version: **1.14.0**. Runtime: `addon/BuffTap`. Latest publication is 1.13.2; 1.14.0 is packaged locally and has not been uploaded. 

Install `requirements-dev.txt`, then run `python tests/test_warlock_review.py` for all 825 isolated mocked Lua 5.1 scenarios. This entry point imports all earlier suites. Run `python tools/verify_mage_catalog.py` to cross-check Mage scroll evidence.

Options support arrow ordering for class buff lists and independent Paladin Target/Groups priority lists. Group custom priorities are opt-in; explicit player choices remain authoritative. Unknown ownership fails closed. Tactical blessing IDs from the reviewed Forever spell-name export are ownership-only guards, never castable maintenance entries. Two-Paladin cases still need live-client testing.

Selection uses event-driven aura/inventory caches and bounded timers. No permanent polling, cross-player assignment coordination, bank/alt tracking, or auto-purchasing. All casts and item use require player input out of combat.

Installable ZIPs contain only `addon/BuffTap`; development tests and research are not loaded by the client. Full client database exports and reference addons are not redistributed. Bundled libraries retain their licenses.

Class-aware Paladin target lists are their own spell permission: checking a learned blessing enables it there without changing personal buff toggles. All use the shared targetSeconds setting; hidden legacy targetBuffs and targetBuffSeconds values are ignored for class-aware blessings. Other classes and Paladin legacy mode keep the old explicit filters and optional per-spell timing. Group custom lists use shared raid exclusions and player overrides, not hidden legacy per-buff gates.

Class dropdowns open the priority editor directly. Preview state lives on the options control only; opening or closing never writes saved settings. A checkbox or arrow edit saves the ordered list. Player exception selectors remain single-choice.

Optional SharedMedia integration reads the sound registry when opening/searching a picker or playing an alert; no registry polling or new runtime timers. SoundKit research: research/sound-support-1.12.0.json. A missing media pack does not erase the selected name. Native sound listening remains unverified.

Convenience.lua owns session pause, first-use guidance, label styling and a guarded Edit Mode preview. No LibEditMode dependency or Blizzard-system registration; one shared per-character position. Native Edit Mode still needs live verification.

Banner artwork is embedded as a shared 512×256 RGB TGA. Source/prompt: research/mini-banner-asset-1.13.1.md. Banner texture coordinates preserve the source aspect ratio while removing dark padding. The native options page area remains 630 units high.
