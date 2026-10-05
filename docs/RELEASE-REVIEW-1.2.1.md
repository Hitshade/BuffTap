# BuffTap 1.2.1 release review

All 234 mocked Lua 5.1 scenarios passed (228 existing and six new). New coverage checks unloaded poison spell metadata and event recovery, shared timestamp requests, request failure retry, unavailable class preference preservation, tab order/Helpers routing, and unsupported-class label visibility. UI mocks now record font-string visibility.

Review fixes implemented: missing poison metadata load request, incompatible shared request types, and premature saved-preference deletion. Manual weapon selection uses private helpers; option page assignments and shortcut routes use named indices. No new polling loop added.

Live client execution is not proven by mocks. Retain the Shaman main-hand and Rogue per-hand application, combat, stock, threshold, and replacement checks in RELEASE-REVIEW-1.2.0.md. Inspect Weapons → Appearance order and unsupported-class layout after reload.

Prepared locally; not published. Previous release packages remain available for rollback.
