# BuffTap 1.16.7

- Improved solo thanks by capturing the buff provider immediately when your helpful auras change, independently of the buff-selection cache.
- Solo thanks now accepts any helpful effect from another identifiable player, including short-duration effects, rather than a fixed spell list.
- Removed unnecessary eligibility checks that could prevent thanking a valid player. Improved full-name handling and rechecks the provider before directing an emote.
- Corrected reporting of the client emote result and added more specific debug reasons when the provider cannot be identified.
- Preserved one-second spacing between different players, the one-minute cooldown per player, and protections against duplicate or misdirected emotes.

Existing settings and profiles are preserved. Solo thanks remains limited to solo outdoor play outside combat. The game must expose the provider's identity; restricted or missing caster information cannot be recovered reliably.
