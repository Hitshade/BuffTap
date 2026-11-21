# In-game verification for 1.15.5

1. Confirm /bt debug reports 1.15.5.
2. Target an ungrouped player with another Paladin's fresh Kings. With fallback enabled and Wisdom next, check selection and debug ownership evidence.
3. Repeat with your own Kings and your own Wisdom. Neither should be replaced by a different priority. Repeat after /reload and with Greater Kings.
4. If ownership remains unknown, confirm selection stays blocked with a readable reason rather than guessing. Capture /bt debug.
5. Test a stronger-buff rejection with the helper enabled. The rejected family should stay suppressed and a safe next choice may be offered. A manual dismissal suppresses that family too. Restore reminders should restore it.
6. Repeat in fixed-assignment mode and with fallback disabled: neither should silently advance to a different blessing.
7. Change targets rapidly and enter combat. No stale cast or binding should survive the safety gates.

Do not run raw aura dumps or try to access restricted values. Share ordinary /bt debug output with settings and whether the blessing was yours. Mock regression results cannot prove live caster-filter responses.


## Safety and recovery checks

1. Helpers: confirm Prevent accidental PvP flagging starts checked and follows profile switching/copying. Other helper choices should be unchanged.
2. While unflagged, target a flagged friendly player. No external buff should arm. Confirm the reason in /bt debug and Diagnostics. Your personal buffs should remain available.
3. Repeat with a flagged party member already buffed and excluded from assignments. Group spells must not hit them; safe individual buffs should still be offered to other members. Test Greater Blessings with a flagged member of the same class in another raid subgroup.
4. Flag yourself deliberately and confirm normal external buffing. Turn PvP off and confirm protection resumes during the countdown. Missing/unreadable countdown data deliberately keeps protection active.
5. Change a recipient's flag after a reminder appears, then click. The stale action must be cancelled. Repeat with a secondary recipient of a group cast.
6. Place an eligible party member behind an obstacle. After a confirmed line-of-sight failure, other recipients should be offered; after 10 seconds the failed member should be retried. Repeat for a confirmed range failure. No permanent dismissal should be created.
7. Check that mana errors, unrelated manual casts and interrupted/successful casts do not defer a recipient. Check that mouse/key release does not create another attempt.
8. Check Hunters/Warlocks still refresh pet readiness when pet flags change. Battleground/arena exemption removes only this PvP guard, not existing combat or restricted-aura protections.

Area protection conservatively checks the whole affected class/subgroup without assuming distant or excluded members cannot receive the spell. This guards casts prepared by BuffTap; it cannot remove existing auras or prevent manually cast spells from flagging you later.
