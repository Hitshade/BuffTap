# BuffTap 1.15.2 visual and behavior checks

1. Open Groups as a Paladin. Party should open first outside a raid, with nine class rows and class/spell icons. Raid should open first if already in a raid. Verify all rows and footer fit without page scrolling.
2. Set Party class choices and a player exception. Switch to Same blessing for everyone, choose Kings, and confirm class/player controls disappear. Everyone uses Kings, including a class/player previously assigned Wisdom. Switch back to By class and confirm the saved choices return.
3. Switch to Raid. Inspect Defaults and G1-G8: individual-blessing icons, mixed class icon clusters, default labels and dim excluded groups. Select G1 and G3, assign Kings, leave other groups on default class choices. Use raid defaults on G1 and confirm only its override disappears.
4. Exclude a raid group with Buff this group. Verify its button says Not buffing and it is skipped. Greater Blessings must not bypass excluded same-class players. Conflicting same-class assignments across raid subgroups must use individual blessings.
5. Return to Party and verify raid changes have not changed its choices. Prepare either setup while solo and with group maintenance off. Existing preferences remain on Buffs until an assignment mode is chosen; Use Buffs settings restores that behavior without deleting plans.
6. In class mode, open player exceptions and test scrolling with a large class roster. Done and Escape should close the editor. Party and raid player exception choices remain independent for the current session.
7. Open Salvation recipients, then Player exclusions, while uniform blessing mode is active. Verify the independent protection can be checked without changing the blessing mode. Check class/group Salvation filters, Done/Escape, and tab changes close popups correctly.
8. Test Casting and its Greater threshold. Check native buttons, icon alignment, opacity of menus, dropdown behavior, labels and the conditional individual-blessing explanation.
9. Reload with party, raid and subgroup choices saved. Switch or copy a shared profile: both plans should stay unchanged. Use the explicit matching-class copy option to import both plans. Verify source settings stay unchanged and incompatible classes cannot be selected.
10. As another class, verify Groups retains its original simpler per-buff controls. Personal and friendly-target settings stay separate.
11. With By class or Use Buffs settings, open Buffs recipient filters. Select a blessing, edit its group/class filters, and confirm that other blessings are unaffected. Check that the spell selector leaves the parent window open, and Done/Escape/tab changes close it cleanly.
12. Keep a player-exception list open while members join, leave or change raid subgroup. Names and choices should update automatically, without changing selection to a replacement player.
13. If your old setup excluded G1, Party should remain excluded on upgrade. Enable party / raid from Party setup to opt in. Raid G1 edits must not silently clear that retained party exclusion.

983 mocked Lua 5.1 scenarios passed. No live-client visual or casting verification has been performed for this build.
