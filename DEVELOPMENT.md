# BuffTap development

Current local version: **1.2.1**. Runtime: addon/BuffTap. Prepared for live testing, not published.

Install requirements-dev.txt and run `python tests/test_weapons.py` to include all 234 scenarios (Lua 5.1 via lupa 2.8). Weapon facts are generated from the same client DB2 exports as the class catalog; no reference addon code copied. See docs/RELEASE-REVIEW-1.2.1.md for required live checks.

Publish only runtime, public documentation, tests and development tools. Exclude research, reference copies, private handoffs, logs and historical archives. The installable ZIP contains one BuffTap folder. Earlier packages remain intact for rollback.
