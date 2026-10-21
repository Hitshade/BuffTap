# BuffTap 1.15.5

Buffing reliability and PvP protection.

- When a blessing lacks a resolvable caster token, use Forever's per-instance aura filter to establish ownership. The aura must first be confirmed present by its readable instance ID. A readable PLAYER filter result identifies player/pet/vehicle ownership; missing, restricted or failed results retain the existing block.
- Preserve readable aura identity and positive coverage when timing fields are restricted. Unknown timing never triggers a refresh. Unreadable aura identity marks the scan incomplete, so it cannot authorize a missing/expiring cast or blessing replacement. Other readiness/consumable consumers keep strict scans.
- Blessing priority selection now considers dismissed/stronger-effect-suppressed families before choosing the next allowed priority. Existing own blessings are still protected, fixed assignments remain fixed, and disabled fallback does not advance. Restore reminders restores dismissed choices.
- Click-time aura refresh and ownership validation use the same safety rules. Restricted/incomplete results are not cached as complete. No combat functionality or polling loops were added.

API evidence is documented in research/aura-evidence-1.15.5.md. Mocked tests do not replace a live Forever verification.

- Added default-on PvP protection under Helpers, shared through named profiles. Checks ordinary and free-for-all flags, retains protection while leaving PvP, and exempts battlegrounds/arenas. Unknown flags remain blocked. Area spells check actual affected class/subgroup membership, including excluded or already-covered players, before selection and at click time. Single-target alternatives remain available.
- Confirmed recent BuffTap spell failures caused by line of sight or range defer that recipient for 10 seconds. The queue continues, and a scheduled wake retries automatically. Both the matching spell failure and error reason are required. Deferrals are session-only and separate from dismissal/stronger-effect suppression.
- Added explicit unavailable-aura, unknown-blessing-owner, PvP-protection and temporary-retry status/diagnostic messages. Debug output includes safety state even when another action remains available.
- Kept global UNIT_FLAGS registration independent of pet-helper registration. Key release no longer starts another error-attribution attempt.

Validation: 1,061 mocked Lua 5.1 scenarios passed. Shipped Lua compiled and package contents verified. Live client testing remains outstanding.
