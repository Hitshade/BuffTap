# CurseForge changelog follow-up

Timing: after 1.25.0 has been published on CurseForge and GitHub with owner approval. Preparation is not publication authorization.

Before public publication, remove the Beta title prefix and test-build notice from PatchNotes.lua, remove beta wording from the current-version CurseForge and GitHub release notes, and use BuffTap-1.25.0.zip for the public archive. Keep historical beta verification records intact. Check all release-facing version labels together.

Use three independently written audiences:

- In game: short, plain-English features, visible fixes and where to find them. Omit routine development details.
- CurseForge: moderate detail explaining class impact, practical behavior, opt-in configuration, compatibility and meaningful limitations.
- GitHub: complete technical changes, root causes, modules, data mappings, migrations, test evidence and limits.

For each existing CurseForge release file, read its current changelog and the matching version's technical source history. Rewrite only the changelog text. Preserve version/date association, contributor acknowledgments and what was true at that release. Do not backport new feature claims or imply old releases included later fixes. Leave file binaries and GitHub release history unchanged.

The 1.25.0 CurseForge source is addon/BuffTap/RELEASE-NOTES.md. The technical source is addon/BuffTap/CHANGELOG.md. Existing changelogs must be inventoried from CurseForge when the follow-up starts; no existing remote changelog has been changed by this preparation.
