# BuffTap development

Current local version: **1.3.0**. Runtime: addon/BuffTap. Prepared for live testing, not published. Previous published GitHub release: 1.2.1.

Install requirements-dev.txt and run `python tests/test_supplies.py` for all 342 scenarios (Lua 5.1 via lupa 2.8). Tests include the other suites. See docs/RELEASE-REVIEW-1.3.0.md for required live checks and explicitly deferred reagent-exemption work.

Supplies.lua is informational and default-off; it does not prepare actions or modify protected state. Counts use inventory events and caches. Reagent-consuming group casts alone get a fresh selection check at the explicit click; changed actions cancel instead of swapping the click payload.

Publish only runtime, public documentation, tests and development tools. Exclude research, reference copies, private handoffs, logs and historical archives. The installable ZIP contains one BuffTap folder. Earlier packages remain intact for rollback.
