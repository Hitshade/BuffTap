# BuffTap 1.15.1 in-game profile checks

Before testing, back up your existing per-character BuffTap SavedVariables file while WoW is closed. The new account-wide BuffTapProfiles store is saved in the account-level BuffTap SavedVariables file. Keep both files together for future backups. The local 1.14.2 ZIP remains available if needed.

1. Install BuffTap-1.15.1.zip and log into your main character. Open /bt, then Profiles. Existing bindings, appearance and buff choices should be preserved in a profile named after the character.
2. Rename the active profile, for example Main setup. Adjust a harmless preference such as reminder size. Reload and confirm the profile name and setting remain.
3. Log into an alt, then select Main setup. Binding, size and sounds should transfer. The alt's own buffs, assignments and weapon settings must stay unchanged.
4. To keep separate preferences, enter a new name and Create with Start with current settings checked. Changes to this new profile must not change Main setup.
5. On a same-class alt, choose the source under Copy from profile. The optional buff/class checkbox should appear when a same-class setup was saved with that source profile. Check it, select the source character, then Copy into current and confirm. Verify buff priorities, assignments and weapon preferences. Source characters need to visit the profile in this version and open settings or log out before their setup is available.
6. A profile with only other-class sources must not offer the class-copy checkbox. Shared preferences should still copy normally.
7. Check profile Reset versus Reset all settings: profile Reset keeps buffs/class setup; Reset all creates a fresh independent setup for this character. Neither should erase other characters' setups. Unused profiles can be deleted after confirmation.
8. Enter combat with settings open. Profile operations must not change settings or secure bindings. After combat, switching should immediately replace the old binding with the selected profile's binding.

Profiles is a fixed-height page. Profile/character dropdowns scroll if needed; the options window itself does not require scrolling. Please check tab readability and confirmation spacing at your normal UI scale.
