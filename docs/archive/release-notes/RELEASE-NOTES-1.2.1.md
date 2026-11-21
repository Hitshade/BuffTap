# BuffTap 1.2.1 — Weapon options and reliability cleanup

- Moved Weapons immediately before Appearance in the main options window.
- Hid weapon-specific controls and explanatory labels for unsupported classes; kept the class availability message.
- Uncached Rogue poison spell data now requests loading and recovers through the existing item-data event.
- Unified item-loading request timestamps across weapons, consumables, and optional discovery; failed requests can retry without adding polling.
- Preserved valid saved weapon preferences when player-class information is temporarily unavailable during initialization.
- Consolidated manual weapon-selection helpers and centralized tab indices so Helpers and Diagnostics shortcuts continue opening the correct pages.

Validation: all 234 mocked Lua 5.1 scenarios passed, including six new regression scenarios. All nine runtime Lua files load during these checks. The release ZIP is verified against the source and manifest. Live weapon application and Rogue off-hand targeting remain unverified in this review; use the existing in-game checks before publication.
