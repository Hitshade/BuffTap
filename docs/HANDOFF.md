# BuffTap handoff (shared by Claude and Codex)

Last updated: 2026-11-26. Stable 1.29.4 is published on GitHub, submitted to CurseForge (Processing), and installed locally. Source edf71a7. Update this file at the end of each session or release.

## Stable 1.29.4 publication (2026-11-26)
- Source edf71a7; GitHub release 459860267, tag v1.29.4, published 15:12 ET. CurseForge file 9833371 submitted as Release for 1.60.1, automatic publication once approved; last observed Processing at 15:13 ET. Previous 1.29.3 confirmed Approved.
- 146 packaged files, 2,819,824 bytes, SHA256 be03d7988861391a9e5a794d4a5eaaea38379e4b5a470f6f85da2a118cc82aed. Stable installed locally with backup, all 146 files verified. Publication/build/install receipts under releases/receipts/BuffTap-1.29.4-*.
- Final affected mocked checks: 562 PASS / 0 FAIL (mana display, Nearby, Warrior, SmartShift, queues), all 52 Lua modules compile. No redundant full suite or live-client verification. Three note audiences updated, exactly ten in-game versions retained. No open/recent GitHub issues on release review.

## Mana-display correction, stable 1.29.4 authorized (2026-11-26)
- Owner reported a grey main mana pause on a fully buffed Priest with Nearby open. Shared manaBlocked/manaFloorBlocked flags could be set by Nearby probes or the friendly-target reserve gate before establishing missing work.
- Implemented fix: mainManaBlocked is reset each Select and set only by non-Nearby, non-nameplate spell validation or SmartShift restoration. ShowManaWait uses that main-action flag; reserve-only state remains in Nearby/status. Queue passes preserve the new flag. Existing global power/mana flags and recovery events remain intact. No settings, casting eligibility or Nearby behavior changed.
- 250 affected mocked checks passed, zero failed (mana display, Nearby and Warrior suppression). Regression coverage includes no needed personal buff + reserve, Nearby-only spell shortage, and real personal shortage clearing after buffing. Log docs/reviews/mana-scope-1293.txt. Owner subsequently authorized 1.29.4 publication. Final affected validation: 562 PASS / 0 FAIL including SmartShift and buff queues; all 52 Lua modules compile. No full suite or live-client run. GitHub open/recent issue searches were empty on 2026-11-26.

## Stable 1.29.3 publication (2026-11-25)
- Owner approved publication after reviewing beta2 and visual follow-ups. Source commit cd05444; GitHub release 458403375, tag v1.29.3, published 12:09 ET. CurseForge file 9812855 submitted as Release for 1.60.1 with automatic publication; last observed Processing at 12:10 ET.
- ZIP contains all 146 verified files, 2,819,249 bytes, SHA256 cf51325f936c04133504cf38722f1e3f70a6330638932a9d8078560f1893907a. Includes the Rebuff at and footer alignment follow-ups. Stable installed locally, all 146 files hash-verified, prior installation backed up. Receipts: releases/receipts/BuffTap-1.29.3-*.
- Retained beta1 full 3,518 PASS / 0 FAIL and beta2 focused 350 PASS / 0 FAIL. Final affected layout run 144 PASS / 0 FAIL; all 52 Lua modules compile. No redundant full run or new live-client verification. GitHub review found no open or newly updated issues.

## Stable 1.29.3 preparation
- Owner authorized publication on 2026-11-25 after reviewing the installed beta and alignment fixes. GitHub review found no open or newly updated issues. Final affected layout checks: 144 PASS / 0 FAIL; no additional full suite run. Stable package must include both installed Options.lua alignment follow-ups.

## Development history: 1.29.3-beta2
- Installed footer alignment follow-up: Consumables Retry reminders moved right to match card edge x704 and up 28 UI units, leaving 24 units below the final card. Pause status moved with it to the left, with no overlap. Options.lua syntax-checked; no full suite. Include this source hotfix in next package.
- Installed visual follow-up: Rebuff at label/slider moved down to share the category dropdown’s vertical center (label y-57, 16px slider y-54; 26px dropdown y-49). Options.lua syntax-checked only, no full suite. Original beta2 ZIP remains unchanged; include this source hotfix in next package.
- Visual follow-up: Party and raid request switch moved 6 UI units right to x256, aligning with the middle buff column. Options.lua syntax-checked only; full suite not rerun. Installed source hotfix differs from the original beta ZIP; include it in the next package.
- Owner authorized per-category consumable location controls, explicit-click group buff requests, preventive cooldown/bag checks and consumables data review. Shopping lists and custom any-of buff groups are explicitly excluded. Owner subsequently authorized installation: 1.29.3-beta1 is installed in the Forever AddOns folder, all 146 files hash-verified, prior addon backed up. No new publication or commit requested.
- Runtime changes: consumableLocations map follows Solo/Party/Raid/spec overlays, inheriting the old consumablesInstanceOnly flag when unset. Auto/Manual/click validation all use it. Per-row selectors, rest-pause shared; selected-item strip sits below the new control.
- Optional groupRequests is off by default, independent of Nearby and group buffing. Helpers > Buff requests exposes Party and raid + Open window; party/raid requests now appear on the existing Nearby rows (no separate name selector); Groups has a shortcut. Uses the existing request message/buff choices, fresh missing-buff checks and shared 180s per-GUID throttle. Only a chosen recipient gets one whisper. No queue action or binding added.
- A.CarriedBagIDs handles extra carried slot 5 through native enum/total. Discovery, Camping and class-item/capacity scans use it. Supply totals remain native item-count based. Full check-up adds read-only cooldown return-shape and bag-slot probes; actual WoW access was denied, so no native API result claimed and safe readiness gates remain unchanged.
- Data: all 207 existing consumable and 67 weapon/coating item-use mappings match official Blizzard 1.60.1.71091 client tables mirrored by wago.tools. Added item variants 287973 and 287974 using existing food effects; total visible consumables 209. No changed supported-item stats/durations found; seasonal aura 24870 has a separate attribute flag change recorded, not a remapping. Eight Endless elixirs remain excluded. Evidence/hashes: research/consumables-1.29.3.
- Validation: 189 focused mocked checks passed. Initial full run had 3516 passes and two obsolete layout-position assertions; row spacing and those assertions were updated, focused layout checks passed. Final frozen-source full run: 3,518 PASS / 0 FAIL in 316.0 seconds, no harness errors or source changes (docs/reviews/1.29.3-beta1-full-suite*). All 52 TOC modules compile.
- Working checkout remains review-1.29.2, base e83e77d; 1.29.3-beta2 is installed at the owner’s request; all 146 files hash-verified with prior addon backed up. Install receipt and backup are in releases/betas. Verified build artifacts are in releases/betas/BuffTap-1.29.3-beta1* (ZIP, source patch, hash, receipt, notes and data review). No live UI/translation verification or saved-settings access.

## Request-list correction (2026-11-25)
- Owner corrected the initial UI: party/raid requests belong on Nearby rows. Removed Ask someone selector, cached choice maps and send helper. Group membership is proven by matching the nameplate GUID against current party/raid units; class, identity and connection checks remain. Existing row request click/tooltip/cooldown paths are reused. Eligible group providers appear even in buffs-only view with provider sorting off. Normal buff/cleanse/social priorities are unchanged.
- Helpers keeps the independent Party and raid switch at x256, aligned to the middle column. Open window enables/shows Nearby explicitly; enabling group requests alone does not change Nearby settings. Both request switches refresh the list.
- 350 focused mocked checks passed, zero failed. Includes actual party/raid row visibility/clicks, coverage-before-click, group departure, recycled nameplates, provider sort, shared cooldowns and helper/consumable layout. Beta1 full 3,518 result retained as historical baseline; full suite not rerun. All 52 registered Lua modules syntax-checked for beta2. No publication/commit. Source, ZIP, source patch and install receipts are in releases/betas/BuffTap-1.29.3-beta2*.

## RULE 1: BuffTap is a WoW Forever-only addon
- Client 1.60.1, interface 16001, Lua 5.1. The second value of `UnitName` is a surname (no realms). Buffs are hidden from addons in combat. No click-to-target on Nearby rows. Spell and item IDs follow Forever build 70888.
- Never touch WTF or SavedVariables. Never claim in-game testing that did not happen.
- Commit identity: author name `Hitshade`, email `283539417+Hitshade@users.noreply.github.com` (GitHub's private address for the owner). Never use the owner's personal email or a made-up `noreply@users.noreply.github.com` address, which belongs to an unrelated GitHub account.

## Current state
- Review checkout: `C:/Users/hitsh/Desktop/AI Projects/BuffTap/review-1.29.2`, a clean clone of main at c73e959. The archived 1.26.14 checkout and its existing changes were left alone. The former Nearby task was cancelled; do not resume it.
- 1.29.2-beta1 is LOCAL ONLY. Applied `releases/betas/BuffTap-1.29.2-beta1-source.patch` using `git apply` after a successful check. It changes only Engine.lua `AddRangeBlocked` and adds one regression in test_review_1263.py. At review time source identified as 1.29.1; the supplied beta ZIP identifies as 1.29.2-beta1. The owner subsequently authorized the local beta2 described below.
- Beta intent: Nearby probes must not feed the main greyed out-of-range reminder, alert or heartbeat. The patch excludes every `nameplateN` target. Review also needs to check nameplate cleanse/revive actions, rather than assuming every nameplate action belongs to Nearby.
- 1.29.1 "Dismiss means dismissed": commits 482d6a0/c73e959. OutOfRangeDisplay checks dismissal of the notice's range key without dismissing the underlying cast. GitHub release 457363398; CurseForge receipt says Processing at 16:40 ET, auto-publish; approval has not been independently checked in this review. Reporter: user_uctfgdsc7zs7pzju (Blessings).
- 1.29.0 "Two specs, two setups": commits 1fdadbc/6b3d7d2. GitHub release 456213197; 1.29.1 receipt says its CurseForge file is Approved. Spec choices are implemented for all nine classes, not pinned: per-character `situationSettings.spec={enabled,[1],[2]}` overlays Solo/Party/Raid. Reads GetNumSpecGroups and C_SpecializationInfo.GetActiveSpecGroup. My buffs routes enabled buffs and shield charges per spec; buff timing/priorities stay shared. Weapons and Consumables route their category choices per spec. Spec 2 can be configured before learning dual spec; unreadable spec does not apply a spec layer.
- 1.29.0 also adds helperThanksOutsiders (default off). ThanksInGroup returns true/member, false/outsider, nil/unknown; unknown blocks. Capture, delayed dispatch, manual offer and manual send check membership. Existing solo/outdoor/combat/identity restrictions remain. Nearby stronger-effect correlation window is 1.5 seconds; unrelated errors no longer cancel the pending attempt.
- Verified registration: test_dualspec, test_thanks_outsiders and test_reachability are imported by tests/run_release.py. Historical full run for 1.29.0: 3,277 PASS / 0 FAIL. Supplied beta focused receipt: 283 PASS / 0 FAIL. Review run: 3,381 passing scenarios before a hard-coded /home/claude path aborted the harness; 50 remaining scenarios passed with a path-only in-memory continuation. Combined 3,431 PASS / 0 scenario FAIL, not a clean unmodified portable suite run. Source unchanged during the run. See docs/reviews/REVIEW-1.29.2-beta1.md and its logs.
- Not verified on a real two-spec character: spec-switch events/transitions. Also unverified live: grouped outsider thanks, stronger-buff handling, range dismissal and beta nameplate exclusion. Locale additions in deDE/esES/frFR/ptBR are author-written, not native-reviewed.
- 1.28.1 (ed0b742/100f812/cd7dc62): compact My buffs restores Rogue Tracking; Nearby guide card is 424 high with footer clearance; read-only SpecProbe added. Historical full run: 3,339 PASS. 1.28.0 moved class readiness/tracking to My buffs and redesigned Helpers. 1.27.0 made Nearby stay open in combat by default; it retains a switch.
- GitHub review 2026-11-24: connector reports no open issues. Recently listed issues #5 (food), #4 (Cleanse layout), #3 (Warlock stones) are historical; relevant comments and source scope reviewed separately in the report. No replies or issue changes authorized.
- Known unexplained: one-off reminder flash/sound in an inn with resting=false in diagnostics. Not reproduced; no workaround. Ask for Full check-up if it recurs.
- Tags v1.27.0/v1.27.1 predate an author-address history correction; leave them alone.

## Review fixes implemented locally (2026-11-24)
- Historical report: `docs/reviews/REVIEW-1.29.2-beta1.md`. Its resurrection proposal is now applied. Owner authorization supersedes the review-only restriction above; historical beta1 evidence remains unchanged.
- Local beta2 fixes resurrection PreClick disarming, unknown maintenance usability/cooldown readiness, incomplete-roster outsider classification, and missing non-Nearby cleanse range notices. Active cooldowns, including GCD, now defer cleanse/revive maintenance. Existing unknown-range compatibility is unchanged.
- Cleanup cancels expired helper dismissal timers on restore/reset, prunes old Nearby social/request histories on existing activity, corrects stale comments/catalog guidance, and repairs nonportable/vacuous tests. No new settings or catalog regeneration.
- Missing translations and raw Nearby tooltips are covered. Existing in-game notes received a light wording polish, preserving credits; ten versions retained. All three note audiences now identify stable 1.29.2.
- Focused mocked checks: 531 PASS / 0 FAIL. Final full portable run: 3,481 PASS / 0 FAIL in 332.5 seconds, no harness errors, source unchanged. Log/summary: docs/reviews/1.29.2-beta2-full-suite*. Build receipt and local ZIP: releases/betas/BuffTap-1.29.2-beta2*. No native client, taint, layout or translation verification claimed. Spec-event/unknown-spec UX questions remain deferred.
- Build artifacts belong in `releases/betas`; QA and review evidence are under `docs/reviews` (ignored on disk). Stable 1.29.2 publication is now authorized; no external replies or saved-settings access. Owner-authorized beta2 installation completed after packaging; all 145 files verified and prior addon backed up.

## Stable 1.29.2 publication
- Promotes installed beta2 without behavior changes; version and release wording only. Retains 3,481 full mocked passes and 531 focused passes. Final 51 Lua modules compile; all 145 ZIP files hash-verified, and comparison with beta2 confirms only the five version/notes files differ.
- Publication complete on GitHub; CurseForge upload submitted and awaiting approval. Receipts recorded under releases/receipts. GitHub final review: no open or newly updated reports on 2026-11-24. Previous CurseForge 1.29.1 is Approved.

### Final publication receipt
- Published 1.29.2 on 2026-11-24 at 22:53 ET: source b8c15e3, GitHub release 457631110 (tag v1.29.2, not draft), verified asset 2,813,146 bytes, SHA256 07463c331f043185498241174e8baa78c507e9011300ae80a5922e7f2b93f6df. CurseForge file 9804838 submitted as Release for 1.60.1 with automatic publication after approval; last observed Uploading, approval not yet verified. Stable installed locally, all 145 files hash-verified. Receipts are in releases/receipts/BuffTap-1.29.2-*. Retained 3,481 full mocked passes and 531 focused passes; promotion changed only identity and notes.

## Release procedure
1. Check open GitHub issues first (see AGENTS.md).
2. Bump `addon/BuffTap/BuffTap.toc` and `Engine.lua` (`B.version`); versions in the three notes must agree.
3. Write the three independent notes: `PatchNotes.lua` (players, exactly ten versions, no em dashes, light humour welcome), `CHANGELOG.md` (technical), `RELEASE-NOTES.md` (CurseForge, moderate).
4. Run the full suite: `BT_KEEP_GOING=1 python3 tests/run_release.py` (about 10 minutes; needs `lupa==2.8`, Lua 5.1 for `luac -p`). Count PASS and FAIL lines.
5. Build the ZIP: single top-level `BuffTap/` folder containing the files of `addon/BuffTap`, omitting the five unregistered sounds (BuffTapAmber, BuffTapRipple, BuffTapSilver, BuffTapSoftPluck, BuffTapWood .ogg). 145 files as of 1.28.1. Record size and SHA-256.
6. Commit, push to `main`, publish the GitHub release (tag `vX.Y.Z`, CHANGELOG text), upload to CurseForge (project 1710644, RELEASE-NOTES text), then record a publication receipt in `DEVELOPMENT.md`.
7. Publish only when the owner says so.

## Publishing mechanics by environment
- Claude (claude.ai Project): `git push` to `main` works; tag pushes and the GitHub release API are refused (403, token invalid). The release form is filled in Chrome (`github.com/Hitshade/BuffTap/releases/new?tag=vX&target=main`), the owner attaches the ZIP and clicks Publish, then verify via `api.github.com/repos/Hitshade/BuffTap/releases/tags/vX` (draft false, asset digest). CurseForge form: `authors.curseforge.com/#/projects/1710644/files/create`; the assistant types the changelog, the owner attaches the ZIP and clicks Add File. Browser tools cannot upload files. Claude can write files to the owner's PC but cannot move or delete them there.
- Codex: use whatever authenticated GitHub and CurseForge access it has; the same procedure applies. Put the ZIP and notes in `releases/` on the owner's machine.

## Working rules
- Keep replies short. Mock up layout changes for approval before coding. Reuse existing UI; propose the smallest change that fits. Be conservative.
- Nothing is committed or published unless the owner says so.
- No em dashes in user-facing prose. Refer to the owner as the solo developer.
- New player-facing strings go through `B:Text` with deDE, esES, frFR and ptBR entries in `addon/BuffTap/Locales`.
- Keep each file's own line endings (most files are CRLF). Commit tests with fixes and register them in `tests/run_release.py`.
- Tests: in the mock environment missing fields return noop functions, so guard with `type(x)=="function"` or `rawget`. Run a focused module first, then the full suite before release.
- Install for the owner's testing by copying changed files to `C:\World of Warcraft\_forever_\Interface\AddOns\BuffTap\`. Lua-only changes need `/reload`; new image files need a full game restart.

## Owner's local folder
`Desktop\AI Projects\BuffTap` was reorganised: `addon/`, `releases/` (recent ZIPs, `archive/`, `betas/`, `receipts/`), `archive/` (old notes and handoffs), `assets/`, `publishing/`, plus `tests/`, `tools/`, `docs/`, `research/`. The undo script is `_organize-undo.ps1`.

## Architecture notes
- One shared table `B` across about 50 modules; TOC order matters. event -> RequestRefresh -> Refresh -> Select -> Commit arms `BuffTapActionButton` and override bindings; PreClick revalidates and clears.
- Nearby rows are secure buttons: never show, hide, move or SetAttribute in combat; only regions, plain child buttons and alpha.
- Options UI: `OptionsStyle.lua` (theme `T`), `OptionsRefinement.lua` (page layouts), `Options.lua` (construction and update code).

## Competitor research (2026-11-24)
- Read-only review saved in research/competitor-review-2026-11-24.json. Shortlist: per-family consumable location rules, explicit-click party requests, custom any-of informational reminders and a simple supply shopping list. Same-class coordination is a larger deferred feature.
- Preventive live checks worth prioritizing: cooldown return shape on learned ready maintenance spells (competitor Forever logs show nil for their probe), extra carried bag-slot coverage, delayed thanks identity and frame-position validation. These are audit leads, not confirmed BuffTap defects. Existing tank filters, underwater context, rank logic and per-buff controls already cover several competitor ideas. No runtime changes or tests run; no commits/publication.

## Deferred ideas
- No Reset Spec N button, legacy GetActiveTalentGroup fallback, or 40-player roster GUID cache unless a confirmed issue warrants one. An unset-spec Differs tag is cosmetic.
- In-game locale picker on Diagnostics (declined for memory cost).
- Remaining page audits: Nearby column balance, Diagnostics tidy, Profiles, other Customization tabs, legacy app page, Paladin Groups card emblem.
- Route remaining hard-coded Nearby strings through `B:Text` and translate them.
- Split `DEVELOPMENT.md` (about 55 KB); add a README screenshot of the new options window.

## Lessons from the 1.28.0 session
- Installing to the owner's game folder: a file copied to /mnt/user-data/outputs is not readable by device_commit_files for a few seconds; wait about 10 s after copying, commit, then re-stage the device file and `cmp` it against the source before telling the owner it is installed. Twice a stale copy was installed because this was skipped.
- New or replaced image files need a full game restart. Textures are 512x512 TGA with the picture in the top-left (SetTexCoord to the used part); Media files appear in the ZIP automatically.
- Section icons come from `SECTION_ICONS` in OptionsStyle.lua; `T.SectionTitle` moves the title 22 right and puts the icon at the old x, so code that later re-anchors a title must allow for that.
- Artwork: use art without faction emblems or crests; image tools' licence terms are the owner's responsibility.

### Publication receipts (1.28.0, 2026-11-22)
- GitHub: release BuffTap 1.28.0, id 454625427, tag v1.28.0 on main, published (not draft). Asset BuffTap-1.28.0.zip, 2,847,625 bytes, sha256 925a4fb8b6495dc5ba9b7d88661dbbd6cf97dd10f939d8ce73f1296352e0dc79 (matches the built ZIP). Release commit c71e3f8, changelog and hash follow-up bfa0fd5.
- CurseForge: BuffTap-1.28.0.zip uploaded as Release for Forever 1.60.1, auto-publish, LibDBIcon dependency; status "Uploading" at upload time, awaiting approval.
- CurseForge replies posted (no links): Lufia_TM (Healthstone setting, now on My buffs > Class helpers) and user_e83iy6nbhigk93ij (tracking reminder exists, now the Tracking tab). Verified on the comments page. No reply posted to laysson (an author reply already existed) or Xprit44 (spec detection, unanswered).
