# BuffTap development record

## 1.30.2 release (2026-11-27)
Owner accepted the researched group-buff beta and authorized publication. Corrected default usefulness versus explicit exclusions, pets, paired raid-wide scope, minus-ten recipient ranks, PvE-instance PvP gating and bounded failed-group recovery. Reagent semantics unchanged; diagnostics expanded. The reporter's exact setup has not been reproduced.

Full mocked release suite: 3,632 PASS / 0 FAIL; all 55 Lua modules compile. Promotion changes only five version/notes files from accepted beta. Package: 151 files, 3,708,938 bytes; SHA256 f5a643727ab7c19bbf43da205d30937960986d69f6e5aa8819a0af6e4c2376ff. Receipts under ../releases/receipts/BuffTap-1.30.2*; source ffb1238 and GitHub release 461302615 / v1.30.2 public. CurseForge file 9862618 submitted, last observed Uploading. Stable installed with backup and 151-file verification; requested reporter reply posted. Final evidence in docs/HANDOFF.md.

## 1.30.1 release (2026-11-27)
Local fixes from the 1.30.0 review: reuse combat controls/native slots, skip unchanged grid layout, correct Elixirs/Utility location explanations, complete combat-control localization and explain bypassed combat click safeguards. Stable gameplay intent/settings unchanged. Owner accepted the local beta and approved publication.

Affected verification: 1,222 mocked scenarios passed, zero failed; final 158 allocation/palette checks passed, zero failed. All 54 Lua modules compile. Final release verification: 3,600 mocked checks passed, zero failed; all 54 modules compile. Owner accepted the beta. Promotion changes only five version/notes files. 150-file ZIP, SHA256 032c250746b16d82c5051da2104231e05cd961c107f57f0a6e1e11210e5e362c. Published source e7f8036; GitHub release 461000821 / tag v1.30.1. CurseForge file 9854529 submitted as Release for 1.60.1 with automatic publication; last observed Uploading, approval pending. Stable installed with backup, all 150 files verified. Receipts under ../releases/receipts/BuffTap-1.30.1*.

Detailed current work, validation and installation state: [docs/HANDOFF.md](docs/HANDOFF.md).

## Previous release: 1.30.0
- Source 6a1f3d3; receipt follow-up 071019e. GitHub release 460955231, tag v1.30.0, public.
- CurseForge file 9853287 submitted as Release for 1.60.1 with automatic publication; Approved, verified during 1.30.1 preparation.
- 150-file ZIP, 3,710,138 bytes, SHA256 945601e9ca9259ac9754b9a5e1ad6862a60922620a5c35c52b5d44d3c6f37035. Receipts under ../releases/receipts/BuffTap-1.30.0*.
- Full release run: 3,584 passed, zero failed; all 54 Lua modules compile. Evidence in docs/reviews/1.30.0-full-suite*. Owner confirmed self and group combat cleansing. Mocks do not establish native secure interoperability for later changes.
- Published description and requested user reply updated. Installed with backup and all 150 files verified; no saved-settings access.

## Historical records
The complete previous record is retained at [docs/archive/handoffs/DEVELOPMENT-through-1.30.0.md](docs/archive/handoffs/DEVELOPMENT-through-1.30.0.md). Earlier handoff details are archived alongside it. Use the current handoff for present status and working rules.
