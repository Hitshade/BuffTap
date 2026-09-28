# BuffTap 1.1.1 implementation and verification

## Scope

This maintenance release adopts only low-risk runtime optimizations reviewed
from the 1.1.0-eff1 proposal. It does not use the proposal's longer aura or
roster cache lifetimes, slower friendly-target batching, negative weapon-spell
cache, combat-wide event suppression, or binding changes.

Implemented changes:

- bounded normalized-name caches for aura and consumable matching;
- fast disabled paths and successful player-class caching for readiness helpers;
- player-filtered power, spellcast and readiness events, each with global-event
  fallback if filtered registration is unavailable, throws or returns false;
- inactive dismissal and diagnostic formatting fast paths.

## Verification

- All nine runtime Lua files received Lua 5.1 syntax/load checks.
- The installable ZIP was inspected for one top-level BuffTap folder, expected
  runtime files, internal version 1.1.1 and absence of development artifacts.
- SHA-256 hashes are recorded in RELEASE-MANIFEST-1.1.1.json.
- At the user's request, the Python regression suite was not run for this build.

## Live checks

- Confirm personal and friendly-target buffs update with their previous timing.
- Enable each class readiness helper and verify pet/Healthstone transitions.
- Verify a spellcast, consumable use and power-starved action refresh normally.
- Test solo, party and raid transitions, including combat entry and exit.
- Confirm `/bt debug` reports no unsupported event that worked in 1.1.0.

No live-client test or external publication was performed while preparing this build.
