# BuffTap 1.4.0 implementation review

Prepared locally, not published. 383 mocked Lua 5.1 scenarios passed (342 previous plus 38 assignment cases and three header cases). Test entry point: tests/test_blessings.py. Source changes are Engine.lua, Options.lua and BuffTap.lua; Catalog data and all licenses are preserved. No copied implementation from reference addons.

Explicit assignment mode defaults off. Class choices persist per character. Player choices are session-only, keyed by GUID; leave-group events clear them even during combat. Reload also clears them. Per-class assignment mode uses the visible shared Greater threshold, overriding retained legacy per-buff thresholds only while that mode is active. An unavailable explicit spell never silently becomes a different blessing. The default coverage policy continues to accept matching normal/Greater auras from other casters.

One player class expands at a time, displaying two players per page. Layout bounds checked against the actual frame coordinates. All nine class rows and footer remain separate; height 766, scaled to UIParent. Other pages share card/button/row styling. Actual font rendering and native icon cropping must be checked in-client.

Live verification required: mixed-role Shaman/Druid choices; tank Salvation protection; two Paladins with matching coverage; same-class skipped/excluded members; Greater rank/reagent eligibility; click cancellation after a preference/roster change; popup closure, player pagination and screen scaling. Do not publish merely on mocked test results. No uncertain spec guesses, Sanctuary additions, automatic class presets, Greater-first exception repair, or addon synchronization implemented.

Future CurseForge file display name: BuffTap 1.4.0. Project title BuffTap – Smart Buffing; slug bufftap unchanged.

Header refinement: branding moved left, longer labels receive wider tabs, Close uses classic panel normal/pressed/disabled textures. Page area remains 624 logical pixels high. Header bounds, Close behavior, tab selection and small-screen scaling pass mocked checks; actual textures/fonts require client verification.
