# BuffTap handoff (shared by Claude and Codex)

Last updated: 2026-11-24. Main now contains stable 1.29.2 (source b8c15e3). Owner authorized a local 1.29.2-beta2 implementing the review fixes and cleanup, plus light in-game note revisions. Owner authorized stable 1.29.2 publication on 2026-11-24, superseding the earlier local-only restriction. Owner subsequently requested installation; beta2 is installed in the Forever AddOns folder, all 145 packaged files hash-verified. Previous addon backed up under releases/betas; install receipt is BuffTap-1.29.2-beta2-install-receipt.json. Update this file at the end of each session or release.

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
