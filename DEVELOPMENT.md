# Development

Current prepared release: 1.0.0. Source: addon/BuffTap.

## Tests

Use Python 3.12: `python -m pip install -r requirements-dev.txt`, then `python tests/test_helpers.py`. This runs 129 baseline and helper scenarios with Lua 5.1 through lupa 2.8. These mocked tests do not replace live-client testing.

## Publishing

The 1.0.0 package is prepared locally. GitHub and CurseForge remain unchanged until the user requests the browser upload. See docs/RELEASE-REVIEW-1.0.0.md. Preserve existing licensing notices and exclude personal handoffs, archives, research downloads and game settings from GitHub. No automatic deployment is configured.
