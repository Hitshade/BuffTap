# BuffTap 1.1.2 local release review

Integrated the substance of https://github.com/Hitshade/BuffTap/pull/1
at head 12058c976dce137fe9ab56a2c5979bc627f0b040 into the canonical local
1.1.1 source. Contributor: juan-medina. The PR remains open and unmerged;
publishing and GitHub reconciliation are deferred to the next requested step.

Added the proposed mouse-button capture handler, clarified that primary clicks
require modifiers, and accept only recognized button labels. Binding persistence,
secure override installation and cleanup still use the existing paths.

Eight focused scenarios in tests/test_mouse_bindings.py cover middle/side
buttons, persistence, modifiers, ignored primary clicks, Escape, combat,
unknown inputs, and override installation/removal. This runner also imports
the existing baseline, helper and readiness suites.

All 189 mocked Lua 5.1 scenarios passed (181 existing plus eight mouse-binding
scenarios). The user clarified that the previous test-skip instruction applied
only to the earlier build and explicitly authorized these checks. All nine
runtime Lua files loaded in the harness. Static review and archive integrity
were checked. No live-client validation was performed.

Before publication, verify Button4/Button5 and middle-click, modified primary
clicks, Escape, entering combat during capture, and normal mouse behavior after
buffs are satisfied or combat starts. Physical mouse routing requires the game.

GitHub main contains the 1.1.1 source commit d2441349fdf56ada0d993069bfcf6f9c40fca591.
The GitHub release API returned 404 for v1.1.1 during this preparation. Do not
claim the earlier GitHub release was finalized. CurseForge 1.1.1 was previously
submitted as file 9003284; its current approval state was not checked here.

The installable 1.1.2 ZIP contains only addon/BuffTap, under one BuffTap folder.
Existing release ZIPs remain untouched. See RELEASE-MANIFEST-1.1.2.json.
