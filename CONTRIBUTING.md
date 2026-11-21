# Contributing to BuffTap

BuffTap is maintained by a solo developer, so small, focused changes are easiest to review.

## Reporting a problem
Open an issue and include your class, BuffTap version, game build and the steps to reproduce it. A screenshot of the settings page involved helps. Please check the latest release first, since many reports are fixed there.

## Suggesting a change
Describe what you want to happen and why. BuffTap only prepares actions; every cast or item use must stay a player input, so ideas that automate casting cannot be accepted.

## Pull requests
1. Keep one change per pull request and match the existing Lua 5.1 style.
2. New player-facing text goes through `B:Text` and needs German, Spanish, French and Brazilian Portuguese entries in `addon/BuffTap/Locales`.
3. Run the test suite before submitting: `python tests/run_release.py` (requires Python 3 and Lua 5.1; see `requirements-dev.txt`).
4. Do not edit release notes or version numbers. The maintainer handles those.

## License
Contributions are offered under the Mozilla Public License 2.0, the same as the project.
