# BuffTap handoff (shared by Claude and Codex)

Last updated: 2026-11-22, preparing 1.28.0. Update this file at the end of each session or release.

## RULE 1: BuffTap is a WoW Forever-only addon
- Client 1.60.1, interface 16001, Lua 5.1. The second value of `UnitName` is a surname (no realms). Buffs are hidden from addons in combat. No click-to-target on Nearby rows. Spell and item IDs follow Forever build 70888.
- Never touch WTF or SavedVariables. Never claim in-game testing that did not happen.
- Commit identity: author name `Hitshade`, email `283539417+Hitshade@users.noreply.github.com` (GitHub's private address for the owner). Never use the owner's personal email or a made-up `noreply@users.noreply.github.com` address, which belongs to an unrelated GitHub account.

## Current state
- 1.28.0 "Class helpers move into My buffs" (prepared 2026-11-22, publication in progress; see DEVELOPMENT.md for the receipt): class readiness and tracking live on a My buffs tab (`f.helpersPane`, `B.buffsHelpersView`); Helpers page is four full-width cards; Solo thanks picture is faction-aware (`ThanksSceneHorde.tga`); full suite 3,319 PASS, 0 FAIL; ZIP 149 files, 2,847,625 bytes, SHA256 925a4fb8b6495dc5ba9b7d88661dbbd6cf97dd10f939d8ce73f1296352e0dc79.
- Previous release: 1.27.1 "Ghosts of Nearby players past" (GitHub release 454103857, ZIP sha256 0cddef8f54cf8e77b8cb9197e322a25931e1c632839d06037cb1176e7ab5d0ca, 1,830,219 bytes, 142 files). CurseForge submitted as Release for 1.60.1 with automatic publication after approval; confirm it went live.
- 1.27.0 "A fresh coat of paint" (options window redesign, Nearby open in combat by default) shipped the same day.
- Final full mocked run: 3,319 PASS, 0 FAIL (1.28.0).
- Note: on 2026-11-21 the 8 commits after 1.26.15 were rewritten to fix a wrong author address, so tags `v1.27.0` and `v1.27.1` point at the pre-rewrite commits (same files, different IDs, not on `main`'s history). Leave them; do not rewrite history again.
- Known, unexplained: a one-off brief reminder flash plus sound while resting in an inn (diagnostics showed the game's resting read was false at that instant). Not reproduced; deliberately no workaround. If it recurs, ask for the Full check-up and add logging of reminder shows with the resting reading.

## Release procedure
1. Check open GitHub issues first (see AGENTS.md).
2. Bump `addon/BuffTap/BuffTap.toc` and `Engine.lua` (`B.version`); versions in the three notes must agree.
3. Write the three independent notes: `PatchNotes.lua` (players, exactly ten versions, no em dashes, light humour welcome), `CHANGELOG.md` (technical), `RELEASE-NOTES.md` (CurseForge, moderate).
4. Run the full suite: `BT_KEEP_GOING=1 python3 tests/run_release.py` (about 10 minutes; needs `lupa==2.8`, Lua 5.1 for `luac -p`). Count PASS and FAIL lines.
5. Build the ZIP: single top-level `BuffTap/` folder containing the files of `addon/BuffTap`, omitting the five unregistered sounds (BuffTapAmber, BuffTapRipple, BuffTapSilver, BuffTapSoftPluck, BuffTapWood .ogg). 149 files as of 1.28.0. Record size and SHA-256.
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
- In-game locale picker on the Diagnostics page (declined for memory cost; maybe 1.29).
- Remaining page audits: Nearby column balance, Diagnostics tidy, Profiles, other Customization tabs, legacy app page, Paladin Groups card emblem.
- Route remaining hard-coded Nearby strings through `B:Text` and translate them.
- Split `DEVELOPMENT.md` (about 55 KB); add a README screenshot of the new options window.

## Lessons from the 1.28.0 session
- Installing to the owner's game folder: a file copied to /mnt/user-data/outputs is not readable by device_commit_files for a few seconds; wait about 10 s after copying, commit, then re-stage the device file and `cmp` it against the source before telling the owner it is installed. Twice a stale copy was installed because this was skipped.
- New or replaced image files need a full game restart. Textures are 512x512 TGA with the picture in the top-left (SetTexCoord to the used part); Media files appear in the ZIP automatically.
- Section icons come from `SECTION_ICONS` in OptionsStyle.lua; `T.SectionTitle` moves the title 22 right and puts the icon at the old x, so code that later re-anchors a title must allow for that.
- Artwork: use art without faction emblems or crests; image tools' licence terms are the owner's responsibility.
