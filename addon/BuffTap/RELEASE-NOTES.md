# BuffTap 1.15.5

Prepared for local in-game testing. Not published.

- When a blessing lacks a resolvable caster token, use Forever's per-instance aura filter to establish ownership. The aura must first be confirmed present by its readable instance ID. A readable PLAYER filter result identifies player/pet/vehicle ownership; missing, restricted or failed results retain the existing block.
- Preserve readable aura identity and positive coverage when timing fields are restricted. Unknown timing never triggers a refresh. Unreadable aura identity marks the scan incomplete, so it cannot authorize a missing/expiring cast or blessing replacement. Other readiness/consumable consumers keep strict scans.
- Blessing priority selection now considers dismissed/stronger-effect-suppressed families before choosing the next allowed priority. Existing own blessings are still protected, fixed assignments remain fixed, and disabled fallback does not advance. Restore reminders restores dismissed choices.
- Click-time aura refresh and ownership validation use the same safety rules. Restricted/incomplete results are not cached as complete. No new options, combat functionality or polling loops were added.

API evidence is documented in research/aura-evidence-1.15.5.md. Mocked tests do not replace a live Forever verification.

Validation: 1,026 mocked Lua 5.1 scenarios passed. Shipped Lua compiled and package contents verified. Live client testing remains outstanding.
