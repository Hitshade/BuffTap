# BuffTap development record

## 1.30.1 release (2026-11-27)
Local fixes from the 1.30.0 review: reuse combat controls/native slots, skip unchanged grid layout, correct Elixirs/Utility location explanations, complete combat-control localization and explain bypassed combat click safeguards. Stable gameplay intent/settings unchanged. Owner accepted the local beta and approved publication.

Affected verification: 1,222 mocked scenarios passed, zero failed; final 158 allocation/palette checks passed, zero failed. All 54 Lua modules compile. Final release verification: 3,600 mocked checks passed, zero failed; all 54 modules compile. Owner accepted the beta. Promotion changes only five version/notes files. 150-file ZIP, SHA256 032c250746b16d82c5051da2104231e05cd961c107f57f0a6e1e11210e5e362c. Publication in progress; receipts follow.

Detailed current work, validation and installation state: [docs/HANDOFF.md](docs/HANDOFF.md).

## Latest published release: 1.30.0
- Source 6a1f3d3; receipt follow-up 071019e. GitHub release 460955231, tag v1.30.0, public.
- CurseForge file 9853287 submitted as Release for 1.60.1 with automatic publication; Approved, verified during 1.30.1 preparation.
- 150-file ZIP, 3,710,138 bytes, SHA256 945601e9ca9259ac9754b9a5e1ad6862a60922620a5c35c52b5d44d3c6f37035. Receipts under ../releases/receipts/BuffTap-1.30.0*.
- Full release run: 3,584 passed, zero failed; all 54 Lua modules compile. Evidence in docs/reviews/1.30.0-full-suite*. Owner confirmed self and group combat cleansing. Mocks do not establish native secure interoperability for later changes.
- Published description and requested user reply updated. Installed with backup and all 150 files verified; no saved-settings access.

## Historical records
The complete previous record is retained at [docs/archive/handoffs/DEVELOPMENT-through-1.30.0.md](docs/archive/handoffs/DEVELOPMENT-through-1.30.0.md). Earlier handoff details are archived alongside it. Use the current handoff for present status and working rules.
