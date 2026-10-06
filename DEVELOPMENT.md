# BuffTap development

Current version: **1.9.0**. Runtime: `addon/BuffTap`.

Install `requirements-dev.txt`, then run `python tests/test_blessing_ui.py` for all 531 isolated mocked Lua 5.1 scenarios. The entry point imports all previous suites. Run `python tools/verify_mage_catalog.py` to cross-check supported Mage scrolls against reviewed evidence.

Source includes event-driven cached buff selection, safe player-triggered out-of-combat actions, class-aware Paladin targets and group assignments, optional resting-area pause, stock alerts, localized options, minimap access and opt-in broker display. No bank/alt tracking, auto-purchasing or cross-player assignment coordination.

Installable ZIPs are release assets; only `addon/BuffTap` belongs in the client AddOns folder. Tests, logs and research are not loaded by the addon. New layout and resting transitions have automated coverage and still need live-client feedback. Mage item application remains data-verified and mock-tested; Spellbreak remains excluded due to ambiguous effect mapping.

Catalog generators require the corresponding client DB2 CSV export as their input directory. Full data exports and reference addons are not redistributed. Bundled libraries retain their licenses.
