# Named profiles implementation

AceDB-3.0 minor 39, pinned upstream commit 40f4cc1356ae7fcc0cf71fc0a19dc7d50d6ae6c2, downloaded from WoWUIDev/Ace3. Library is unmodified; license included. Reuses existing LibStub and CallbackHandler. No AceConfig/AceGUI dependencies.

An explicit shared preference allowlist routes bindings, appearance, sounds and general helper behavior to account-wide BuffTapProfiles. Class/buff settings remain per-character in BuffTapDB. A shared-preference backup in BuffTapDB preserves upgrade data. Initial migration makes independent profiles. Character class snapshots become available after login and opening options or logging out; same-class copy is explicit and independently validated by the backend.

Source: https://github.com/WoWUIDev/Ace3/tree/40f4cc1356ae7fcc0cf71fc0a19dc7d50d6ae6c2
