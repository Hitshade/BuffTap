# BuffTap 1.1.2 — Mouse-button bindings

- Bind middle-click and mouse side buttons directly from the options binding screen.
- Combine mouse buttons with Shift, Ctrl, or Alt. Left/right click requires a modifier to prevent accidental primary-click bindings.
- Clearer binding instructions explain the available inputs and Escape cancellation.
- Uses the existing secure, player-triggered casting path; adds no polling or background scanning.

Thanks to juan-medina for the mouse-button capture contribution in GitHub PR #1.

Validation: all 189 mocked Lua 5.1 scenarios passed, including eight new mouse-binding checks. Package-integrity checks completed. Physical mouse-button behavior still needs an in-game check.
