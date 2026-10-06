# BuffTap development

Current version: **1.8.0**. Runtime: `addon/BuffTap`.

Install `requirements-dev.txt`, then run `python tests/test_mage_release.py` for all 475 isolated Lua 5.1 scenarios. The entry point imports all previous suites. Run `python tools/verify_mage_catalog.py` to cross-check the 15 supported Mage scrolls against reviewed evidence. See `docs/MAGE-AND-CORRECTIONS-1.8.0.md` for validation limits and remaining live checks.

Source includes event-driven cached buff selection, safe player-triggered out-of-combat actions, configurable Paladin recipients, optional stock alerts, localized options, minimap access and opt-in broker display. No bank/alt tracking, auto-purchasing or cross-player assignment coordination.

Installable ZIPs are release assets; only `addon/BuffTap` belongs in the client AddOns folder. Developer tests, logs and research are not loaded by the addon. New Mage item application is data-verified and mock-tested, not live-client validated. Spellbreak is deliberately excluded due to ambiguous name/effect mapping.

The catalog generators require the corresponding client DB2 CSV export supplied as their input directory. Those full data exports and reference addons are not redistributed. Bundled libraries retain their licenses.
