# BuffTap development

Current local version: **1.1.1**. Runtime source: addon/BuffTap.

Install `requirements-dev.txt`, then run `python tests/test_readiness.py`.
This includes all baseline/helper tests and uses Lua 5.1 through lupa 2.8.
The 1.1.0 suite passed 181 scenarios. It was intentionally not rerun for the
1.1.1 maintenance build. Live client checks remain necessary; see
docs/RELEASE-REVIEW-1.1.1.md. Catalog regeneration is documented in docs/CATALOG-DATA.md.

No automatic deployment is configured. This task prepared 1.1.1 locally;
publishing is a separate user-requested step. Preserve release archives and
their original notices. Research, references, private handoffs and logs are not
public repository content. The installable ZIP contains one BuffTap folder.
