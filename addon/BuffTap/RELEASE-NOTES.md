# BuffTap 1.30.3

### A group spell for one
You can now lower group-spell thresholds to one player for any class. This includes Greater Blessings, making it easier to use their longer duration when only one member of a class needs a buff. Thanks to Pepperybacon for suggesting this for Legacy builds. The choice is available to everyone.

Under Groups, adjust the shared threshold or the threshold for a particular buff. Party and Raid keep their own choices. Existing defaults stay as they were, and each cast still needs your click or binding. Choosing one does not bypass exclusions or the spell's normal requirements.

Existing spell requirements and group protections still apply. No Legacy talent setup is required to use this preference.

# BuffTap 1.30.2

### More useful group buffing
This update adjusts how BuffTap chooses group spells. Mage, Priest and Druid group buffs count missing buffs across the raid. A Warrior who does not need Intellect, or a pet that cannot benefit from it, no longer prevents a useful cast for everyone else.

Your explicit exclusions are still respected. Greater Blessings continue to follow class assignments and avoid replacing a different blessing you intended to keep. Known group ranks now use the same ten-level recipient allowance as ordinary ranked buffs. Broad raid spells are prepared on yourself, with their normal area effect deciding coverage.

### Recovering without repeated group attempts
If the game rejects a group cast, or repeated checks after a successful cast show the same players still missing it, BuffTap can temporarily offer single buffs instead. Every cast still needs your usual click or binding. Resource errors and incomplete information are kept separate from confirmed recipient problems.

PvP protection now applies outdoors, with no PvP gating inside dungeons or raids. Existing settings and reagent handling are kept.

### Helping us check the result
The Full check-up now explains more of the group-spell decision. The beta has been reviewed by the owner; we have not independently reproduced the reporting player's exact setup. If a group spell is still skipped unexpectedly, capture the full report while it is happening.

Thanks to the player who reported the Arcane Brilliance behavior and helped prompt these improvements.

# BuffTap 1.30.1

### Lighter combat-frame adjustments
Changing combat icon size, style or colors now updates the existing controls. Repeatedly trying different looks no longer keeps adding replacement controls for the rest of your session. The group grid also leaves its layout alone when nothing has changed. Click assignments, your chosen appearance and the usual combat restrictions stay the same.

### More accurate consumable status
Elixirs and Utility now describe their location choice correctly. A category restricted to dungeons and raids should say so outdoors, even if your older shared setting was different. This corrects the explanation; item-use eligibility was already following the right choice.

### Clearer controls and limits
Combat cleansing labels, previews and tooltips now include German, Spanish, French and Brazilian Portuguese translations. Old beta labels on the feature have been removed. The combat settings also explain that direct clicks use the player currently occupying each unit slot and do not apply BuffTap's normal blacklist or PvP protection. Never cleanse exclusions cannot be guaranteed in combat, so check the recipient and debuff before clicking.

Your existing choices are kept. No new setup is required, and combat cleansing still uses the same direct mouse clicks.

# BuffTap 1.30.0: a helping hand, mid-fight

### Combat cleansing, by popular request
You can now choose prepared click-to-cleanse controls during a fight. Open **Cleanse > Combat cleansing** and enable either option, or both:

- **Yourself (main icon)** gives you a personal warning at your existing buff-icon position, including while grouped. It follows that icon's size and appearance.
- **Party and raid** gives your current group a compact grid, including you. Only occupied positions appear, up to 40 raid members. Idle frames stay visible while grouped.

Both start off, so updating does not add anything to your screen unless you choose it. Follow the small **L/R** cue to left- or right-click a frame; hover it for the player name and full spell guide. Your ordinary buff binding still handles out-of-combat maintenance. Combat cleansing requires a direct mouse click and stays silent, with no stream of group alert sounds.

### A grid that fits your UI
Choose 18–64 px icons, spacing, growth direction and line length, or keep raid subgroups on five-frame lines. Adjust idle opacity, class or custom idle colors, debuff colors and modern/classic styling. Position the grid separately or have it follow the main icon.

**Move frames** shows the complete 40-slot footprint at actual size even while solo, with a non-casting preview and the usual Done/Cancel controls. Layout and subgroup sorting update after combat; newly arriving members may use reserved positions until then.

### A tidier Cleanse page
The **Cleansing** tab keeps removal choices, recipients, resurrection and Never cleanse together, with Alliance/Horde artwork and more list space. Classes without resurrection no longer have to stare at unused controls. Existing choices are kept.

### Before you enable it
The personal combat option has an invisible click area throughout combat, even when no warning is showing; clicking that spot can attempt a self-cleanse. The game controls the combat debuff display. **Never cleanse exclusions cannot be guaranteed in combat**, so decide whether removing a debuff is safe before clicking. Ordinary out-of-combat cleansing retains its existing safeguards. Resurrection remains an out-of-combat reminder feature.

### Also fixed
Nearby's low-mana notice remains visible alongside its player rows and clears as mana recovers. It does not light your main reminder when no main action is waiting.

Thanks to everyone who asked for combat cleansing and helped shape the controls.

# BuffTap 1.29.4

### A quieter main reminder
The main icon could turn grey for a mana pause even when your own buffs were already up, because Nearby was saving mana. That pause now stays with Nearby. The main reminder still shows Waiting for mana when a needed main action is short of mana.

This fixes a shared display issue across classes, rather than a Priest-only problem. Your mana reserve and other settings are preserved, and Nearby still resumes buffing normally as mana recovers. No setup changes are needed.

# BuffTap 1.29.3

### Choose where your consumables remind you
Each row on Consumables now has its own location choice: Everywhere or Dungeons and raids. You can keep food reminders while leveling and save flasks, elixirs and utility items for instances. The choices follow the Solo, Party, Raid and spec setup you are editing. Your old setting remains in effect until you change a category. Pause while resting still applies to them all.

### Ask your group for a missing buff
On Helpers, under Buff requests, enable Party and raid, then open the Nearby window. Party and raid members who are nearby show the same request icon as other players. Click their icon to send your request. It uses your existing buff choices and message, and checks again before sending so it does not ask for a buff you just received. Requests to the same player are spaced three minutes apart. Nothing is sent automatically. Groups includes a shortcut to these controls.

### Inventory and food updates
Camp item lookup, consumable discovery and class-item inventory checks now include an extra equipped bag slot when the game reports one. Two additional versions of Tender Wolf Steak and Grilled Squid are supported after checking their client data. The existing supported consumables were also checked against the newer Forever tables.

### Settings and compatibility
Your existing choices are preserved. Party and raid requests are optional and start switched off. Nearby requests still need a visible friendly nameplate, and the usual out-of-combat restrictions apply. Full check-up now includes more information about maintenance readiness and equipped bag slots.

# BuffTap 1.29.2

### More reliable reminders
Resurrection reminders now keep the prepared spell when you use your normal binding or click. Cleansing and resurrection wait when the game cannot confirm that the spell is usable or its cooldown is ready.

With greyed out-of-range reminders enabled, a needed cleanse for a party member or friendly target can now appear there too. It becomes a normal reminder when the player returns to range. Right-click dismisses only the notice. Nearby players remain in Nearby and no longer create an out-of-range notice on the main reminder.

### Thanks and tidying up
The optional setting to thank players outside your group now waits for complete group information before treating someone as a stranger. This also protects the manual thank-you backup. No new chat messages or settings are added.

Expired reminder timers and old Nearby social/request records are cleaned up. Several translated labels and Nearby tooltips are filled in, and existing in-game patch notes have a light wording polish. Your saved settings are preserved.

### Settings and compatibility
No setup changes are required. This update keeps your existing choices and adds no new settings. Combat casting remains unavailable. Translations have not had a native-speaker review.

# BuffTap 1.29.1

### Dismiss means dismissed
Right-clicking the greyed-out "out of range" reminder for a party or group member, such as a missing Blessing, now dismisses it. Before, the icon stayed on screen. It only hides the out-of-range notice: once that player is back in range and still missing the buff, the normal reminder comes back by itself. If someone else is also out of range, their notice shows next. **Restore reminders** on the Helpers page brings dismissed reminders back.

Thanks to the player who reported it.

# BuffTap 1.29.0

### Separate settings for each spec
If your character has dual spec, My buffs, Weapons and Consumables can now keep a different set of choices for each spec. Turn on **Different settings per spec** at the top of any of those pages, then pick **Spec 1** or **Spec 2** to set that one up. BuffTap follows the spec you are in, in Solo, Party and Raid, and a green dot shows which one that is. A tank, a healer and a damage dealer can now keep up different buffs, imbues, oils, stones and consumables. Works for every class.

You can set up Spec 2 before you learn dual spec. Buff timers and the rest of your settings stay shared between specs.

We could not test this on a character with two specs, so reports are very welcome.

### Thank players outside your group
Solo thanks has a new switch, **Thank players outside my group**, on the Helpers page. It thanks strangers who buff you while you are grouped outdoors. Your own party and raid members are never thanked, and nothing happens in instances or combat. It is off by default.

### Nearby and stronger buffs
When a Nearby cast fails because a stronger buff is already active, the person is now cleared right away instead of BuffTap trying several more times.

Your saved settings carry over untouched. The new translations were written without a native review, so corrections are welcome.

# BuffTap 1.28.1

### Rogues can reach Tracking again
In 1.28.0, Tracking moved to a tab on My buffs, but for a Rogue that page showed only a note that the class has no buffs to remind, so the Tracking settings could not be reached. My buffs now opens straight to Tracking for Rogues, and for any class with no personal buffs, without an empty buff list or Solo, Party and Raid buttons that do not apply. Classes with buffs look the same as before.

### For testers: Talents and spec
The Full check-up on the Diagnostics page has a new Talents and spec section. It only reads information and changes nothing. We are looking into settings that follow your talent spec (for example a different weapon imbue for each spec). If you have a character with two specs and are willing to paste a check-up report taken before and after switching spec, it would help a lot.

Nothing else changed, and your saved settings carry over untouched.

# BuffTap 1.28.0

### Class settings now live in My buffs
Pet, Healthstone, Soulstone, Oath and tracking settings used to sit at the bottom of the Helpers page, where they were easy to miss. They now have their own tab in My buffs, next to Solo, Party and Raid, set slightly apart so it does not look like another setup.

The tab is named for what is inside it. Warlocks and Paladins see **Class helpers** (pet, Healthstone and Soulstone for Warlocks, the assigned Oath for Paladins, plus tracking), Hunters see **Pet and tracking**, and every other class sees **Tracking**. These settings apply in every setup, so the Use Solo settings button is hidden while you are on the tab.

The Helpers page itself has more room now. Solo thanks has a full-width card with a new picture (it changes with your faction, and the Camping scene was redrawn too), Buff requests comes next, then the optional conveniences, and a short pointer to the new tab sits at the bottom.

Everything works the way it did, including the Soulstone target menu, the preferred demon choice and the tracking reminder. Your saved choices carry over untouched. Helpers keeps a small card where the settings used to be, with a button that opens the new tab.

### Known limits
The new tab and the redesigned Helpers page were looked over in the Forever client on Warlock, Hunter, Paladin and Druid characters. The Horde version of the Solo thanks picture and the new Camping picture have only been checked in a simulated game so far, so please tell us if anything overlaps or looks wrong.


# BuffTap 1.27.1

### Nearby: no more lingering rows
If you swept your mouse around a crowded area with the animated list on, the rows of players who had just left could hang around for a moment before disappearing. Nearby now lets go of those rows as soon as your mouse leaves them. Nothing else changes, and no settings are affected. This is a Lua-only update, so a `/reload` is enough.

# BuffTap 1.27.0

### A fresh look for the settings window
Every page now shares one darker background and opens with a larger title. Section headings gain a small icon and a fine line, and the boxes inside boxes are gone, so pages feel calmer and easier to scan. Controls are lined up with even spacing.

Weapons, Consumables, Supplies, Cleanse, My buffs, Target, Blacklist and Groups were all reworked. Supplies has roomier item rows, and Weapons shows the Off hand row only for classes that can dual wield. Camping shows its benefits with new icons. On Groups, Party and Raid get a small emblem and a short note under each setting. Scrollbars appear only when a list actually scrolls.

### Nearby stays open in combat
Inviting players and asking to join a group work during a fight, whatever your class, so Nearby now stays open in combat by default. Existing characters get this once; if you prefer the old behaviour, turn off **Keep open in combat** under Customization > Nearby window and it stays off. The **How Nearby works** guide now starts folded away, and **Show** opens it.

### Translations
New text appears in German, Spanish, French and Brazilian Portuguese, and the section icons now show in every language.

No gameplay or saved settings change apart from the Nearby default above. Some new window art needs a full game restart the first time.

# BuffTap 1.26.15

### Invite and ask to join, even mid-fight
Nearby can now stay open while you are in combat, so its invite and request-to-join buttons keep working during a fight. Turn on **Keep open in combat** under Customization > Nearby window. It starts off, and Restore window defaults turns it off again.

In combat the window looks the same and keeps showing players as they come into range and leave, under a yellow **Paused: in combat. Invites still work.** banner. Buffing waits until combat ends, so buff icons, buff requests and the right-click menu return afterwards, and you can still scroll the list. Each invite is one click and is rechecked against the player you see.

### More translated text
Settings, help and status text added in recent versions now appears in German, Spanish, French and Brazilian Portuguese, including the new combat option, class tips, shared blacklists, manual thanks and per-buff sounds. The in-game patch notes and a few older Nearby window messages remain in English. Corrections from native speakers are welcome.

### Smaller improvements
BuffTap does less background work during busy raids when the optional manual thank-you is off, and fewer key-binding updates while a THANK is on screen. Short buff lists on the Groups page no longer show an empty scrollbar.

Known limits: during combat the list cannot buff anyone, and empty rows are blank placeholders until combat ends.

# BuffTap 1.26.14

### Group buffs with Reagent Economy
Forever effects that waive a group buff's normal vendor reagent cost now work with BuffTap. If the game says your spell can be cast, an empty reagent stack no longer makes BuffTap switch to individual buffs.

No setup is needed. Spells the game refuses still fall back normally, and BuffTap checks again when you use your binding. Group preferences and other features are unchanged. No new settings or saved-data changes.

# BuffTap 1.26.13

### Catch the giver while the buff arrives
Solo Thanks now captures a readable buff giver from the incoming buff update, before checking your buff list again. This can help when the giver's details are available briefly and disappear from the later check.

Your existing emote, delay, mounted thanks and resting choices stay in place. BuffTap still verifies who it is thanking, and the optional manual whisper backup still requires your input. This adds no automatic chat messages.

This is a targeted improvement for missed thanks, not a guarantee when the game never exposes a usable giver. Thanks to waggz81 for continuing to help us investigate.

# BuffTap 1.26.12

### Say thanks without dismounting
Automatic thank-you emotes and the optional whisper backup now work while mounted. Riding no longer pauses Solo Thanks. Your ordinary buff actions still wait until you dismount, and **Keep thanking while resting** still controls thanks in towns and inns, mounted or on foot.

### An extra thank-you backup for the especially polite
For the really, really polite players who never want to miss a chance to say thanks, Solo Thanks now has a **very optional manual backup**. It starts off; ordinary automatic thanks needs no extra setup.

Enable **Offer a manual thank-you** under Helpers > Solo Thanks. This is only a backup when automatic thanks has not fired and the buff giver's full name is known. BuffTap never sends these whispers automatically. A handshake marked THANK can appear at your reminder position. Use your regular BuffTap binding or click to whisper; right-click to dismiss this thank-you. The offer lasts 15 seconds and waits behind ready buff actions. Automatic and manual thanks avoid doubling up.

The message starts as **Thank you for %s!**. Edit it inside Solo Thanks and press Enter to save; %s inserts received buff names. Several buffs from one giver share a thank-you. Reset restores the original message.

**Keep thanking while resting** applies to this backup too. A reliable full name is required, and normal solo and chat restrictions still apply. This is an extra courtesy option, not a guarantee of delivery.

Thanks to waggz81 for helping us refine Solo Thanks.

# BuffTap 1.26.12-beta1

### Catch a brief chance to say thanks
If BuffTap knows who gave a buff but cannot yet reach them for a directed thank-you, a matching nameplate, target, mouseover or focus update now prompts another immediate lookup. It still stops after ten seconds and never substitutes an unverified player name.

Diagnostics also keeps the first and last lookup for the latest incoming buff, whether its giver was ever matched, and what happened afterward. This should help distinguish an inaccessible giver from one who became available and then disappeared.

Existing thanks preferences, pauses and cooldowns are unchanged. This cannot thank someone who remains inaccessible to the game API. Local beta for testing; not published.

# BuffTap 1.26.11

### Let game windows take priority
The buff reminder, Camping and Supplies now use a lower display layer by default, helping ordinary game windows appear above them. Each has a **Keep above other windows** switch under its Customization tab. The switches sit just above Move reminders and Reset look & position. Nearby keeps its existing switch under Position.

Your main reminder's choice also controls the smaller buff queue, consumable icons (including detached icons) and combat expiry warnings. Camping, Supplies and Nearby can each be raised separately. Existing Nearby choices are kept.

Settings, setup trays and popup menus retain their higher layers. These choices save with profiles; resetting a reminder's appearance returns it to the lower layer. Buffing and sound behavior are unchanged.

Thanks to WareWolf44 for the feedback. The lower layer is the default; turn on Keep above other windows if you prefer a reminder to stay above ordinary panels.

# BuffTap 1.26.10

Warriors no longer see the grey waiting-for-power icon when they lack rage for Battle Shout. When enough rage is available, its usual missing-buff reminder returns. Your existing settings, mana reminders and combat restrictions stay the same.

Thanks to ichkruchka for explaining why this reminder was distracting while travelling and gathering. This change is specific to the Warrior waiting icon; other classes keep their existing reminders.

# BuffTap 1.26.9

### Less clutter for your class
Groups now shows the pet, role and group-spell options your class and selected buff can actually use. Supported spells remain configurable before you learn them. Paladins keep their blessing plans; Warlocks and Shamans get simpler utility layouts.

Classes without personal or friendly-target buffs get a short explanation and useful shortcuts instead of empty controls. Nearby keeps browsing, invitations and buff requests together, with a tidier layout when your class has no buffs to offer. Battle Shout and Trueshot Aura stay under My buffs.

Thorns offers tank targeting, and Fear Ward offers tanks or healers. Pet upkeep is limited to appropriate buffs, with Intellect and Spirit reserved for mana-using pets. Existing preferences stay saved.

### Share your blacklist
Under Blacklist, turn on **Share across all characters** to use one player and guild list. It starts off. Enabling adds your current profile's entries; disabling restores each profile's original list and keeps the shared list saved.

For separate lists, choose **Copy from profile**, then **Add entries**. This adds names without replacing your list or copying other settings. Blacklist rules stay separate for each profile. Newly blocked friendly targets are checked again before a prepared buff can cast.

### Quieter reminders and easier settings
Weapon reminders stay quiet for items below your level, unusable carried items and items whose requirements have not loaded yet. Saved choices remain ready for later. Usable poisons, eligible lower ranks and deliberate out-of-stock reminders still work.

**Use Solo settings** remains available while editing Party or Raid outside combat. New Warlock and Shaman utility group setups start off; existing choices are kept. Information cards, headings and Blacklist controls have also been tidied up.

For WoW Forever. Your own party and raid retain their existing blacklist exemptions. Unknown item requirements stay quiet until the game provides them. Some new text uses English until translated.

# BuffTap 1.26.8

### See what is next
An optional row of up to four clickable buff icons sits below your main reminder. Turn on **Customization > Buff reminder > Show next buffs below** to try it. Your binding and group spells stay on the main icon, and every cast still needs your input. Attached consumables tuck beneath the queue. A count ending in **+** means at least that many additional recipients were found.

### An early heads-up in combat
**My buffs > Combat expiry warning** is a separate optional warning for your own enabled buffs, about ten seconds before expected expiry. Personal sound choices and normal pauses apply.

This is an estimate: the game hides buffs from addons in combat, so dispels and another player's refresh can make it inaccurate. Death or loading clears it. Both new reminder features start off.

### Find a helping hand
Under **Helpers > Buff requests**, optional **Prioritize providers** surfaces potential providers of selected missing buffs in Nearby. Existing buff, cleanse, favor and friend/guild priorities come first. It cannot change your next cast or send a request automatically. Buffs you already have are not offered as requests. A potential provider is not a guarantee they have learned the spell.

### Better recovery, clearer settings
Solo Thanks gives a briefly unavailable buff giver more time to appear. **Diagnostics > Full check-up** now includes more useful settings, timing and lookup details. If a thank is missed, capture it soon afterward with **Hide player names** enabled. We have not reproduced waggz81's exact problem, so this is a recovery improvement rather than a confirmed fix.

Paladins can offer Kings, Might and Wisdom in town without those blessings being held back as short buffs. Smaller consumable and queue icons follow Classic/Modern styling, Helpers has cleaner spacing, and in-game notes are easier to read. German translations have also been expanded.

Thanks to **tinect** for the contribution and follow-up ideas in PR #6, and to **waggz81** for the diagnostic report.
# BuffTap 1.26.7

### Choose which buffs you hear
My buffs now has a speaker beside each buff. Left-click to mute or unmute that reminder while keeping its icon and binding available. Right-click to choose a custom sound in a searchable editor, with separate Preview buttons. **Use default** follows your Reminder sound choice.

Personal, Party and Raid preferences are independent. Under Groups, use the speaker at the top right of the selected buff. Paladins use **Buff sounds** beside the Party/Raid tabs. A buff's single and group versions share its group sound preference. Enabled speakers use your accent colour; tooltips explain their scope and controls.

### Independent default sounds
Under **Customization > Binding & sound**, Reminder, Supply, Camp, Cleanse and Friend sounds each have their own speaker switch. Previews remain available while muted. Existing choices are retained. New players choosing alert sounds enable all five sound permissions, without turning on optional features.

Ten new brief fantasy sounds include Crystal chime, Elven harp, Holy light, Fairy ping, Celestial lift, Soft glow, Moonlit bells, Gentle harp, Warm welcome and Lullaby ping. Sound lists open at the current choice and scroll more smoothly; Reduce animation keeps scrolling immediate.

### Simpler cleansing
Druids and Priests now prefer learned Abolish Poison or Abolish Disease automatically. Each costs the same base mana as its Cure counterpart and continues removing effects afterward. Cure remains the fallback before Abolish is learned. The unnecessary conditional preference has been replaced by an explanation.

Thanks to **jimbo1111** for pointing out the equal-cost Cure/Abolish choice.

SmartShift returns and active smooth-buffing queues stay quiet. Sound choices do not change casting, and every cast still requires your input.

# BuffTap 1.26.6

Settings also have a more compact Consumables layout, roomier Nearby text selectors and clearer Manual selection, pause and accent-colour labels. Class-specific settings and your saved choices are unchanged.

### Pauses now cover the companion reminders
Camping stays quiet during temporary pause, the Helpers city/inn pause, stealth and Edit Mode. Its sound still has its own switch; turning on ordinary reminder sounds does not turn on Camping sounds. Deliberate previews remain available from Settings.

Manual consumable icons, their heading and additional-items button hide during the relevant pause or when **Only in dungeons and raids** excludes your current area. They return with fresh item checks when that condition ends. Your saved selections are retained, and low-stock icons can still appear normally outside a pause.

### More consistent positions and status
The starter layout now leaves space below the main icon for attached consumables, including two rows. Short game UIs use the space under Nearby for Supplies. This affects new defaults and explicit resets; existing positions are not moved automatically.

**Reset look & position** returns the selected reminder to its place in that layout without moving the other reminders. Warrior and Rogue resource-wait status uses the same power wording as the icon.

Every cast and item use still requires your input. Existing settings and positions are retained; use Reset look & position only when you want the new starting placement.

# BuffTap 1.26.5

### A shorter first run
Choose **Get started** once to accept the recommended extras, **Customize first** to pick them, or **Keep current settings** to finish without changes. Copying another character's settings finishes immediately after a successful copy. There is no required tour or backup prompt.

Recommended setup includes Nearby, reminder sounds, the city/inn resting pause, stronger-buff error protection, and Cleanse/Resurrection for classes that support them. It uses the existing class setup when unconfigured. Solo thanks remains opt-in; SmartShift, pet/stone/Oath helpers and item use stay deliberate choices in Settings. Existing players are not taken through setup again or given a new preset automatically.

If friendly nameplates are off, setup explains why Nearby is waiting. **Enable friendly names only** is a separate action offered only when the game reports support; both settings are checked after changing. Otherwise, use the game's friendly-nameplate controls. This still needs a live Forever appearance check.

### Easier positioning and cleaner waits
Fresh characters start with the reminders stacked toward the upper right and Nearby beside them. The layout uses the scaled game UI and keeps the group on screen; saved positions are preserved. Camping, Supplies and Nearby can now be placed in Edit Mode while disabled, without turning them on.

The grey mana/power wait uses your existing name and recipient label switches. Turn both off for an icon-only display. **Helpers > Pause reminders while resting** also hides it in cities and inns. Thanks to **sevaniuz** for the display feedback.

### Fixes
An offered higher-rank Nearby buff now survives the final check on the main buff button/binding. Fresh eligibility and stronger-effect protections remain in place. Automatic sounds stay quiet when resting status cannot be read and the resting pause is enabled. The reported sound during a confirmed city rest has not been reproduced; Diagnostics now includes the most recent sound type and resting state to help investigate.

Names-only appearance still needs live Forever verification. Every cast continues to require player input.

# BuffTap 1.26.4

### Optional buff-grades and shield reminders
- **Nearby > Offer higher rank buffs:** offer an upgrade when someone has a clearly identified lower rank and can receive a higher rank you know. It starts off. Unknown effects, group equivalents and equal or higher ranks do not trigger upgrades. Talent bonuses can affect actual strength; normal stronger-effect protections still apply.
- **Shamans > My buffs > Refresh at charges:** optionally refresh Lightning Shield or Water Shield at one or two charges remaining. Leave it Off for normal timing. Solo, Party and Raid can differ; unreadable counts keep the existing timing behavior.

### Better ranks, setup and troubleshooting
- Ordinary ranked Mage, Priest, Druid and Paladin buffs use the usual Classic recipient-level allowance, avoiding unnecessarily weak buffs for lower-level players. Group versions and unusual spells retain their existing rules.
- Fresh setup recommends class-appropriate Cleanse, Resurrection, cleanse-first ordering and SmartShift, even before learning the abilities. Review and decline any choice. Existing setups keep their preferences. Supplies guidance points out ammo, Soul Shards and reagents without automatically tracking items.
- **Diagnostics > Inspect buffs** shows readable active effects and which reminders recognize them. Full check-up includes it. Select text or use Select all, then **Ctrl+C** to copy. The report pane and Nearby controls have cleaner spacing.

### Maintenance fixes
Group buffs respect Also on me and fall back to singles when an affected member's buff information cannot be verified. Nearby buttons clear prepared casts on entering combat. Warlocks with Demonic Pact can recover their chosen different demon while protecting the sacrificed family.

BuffTap still requires readable information and your input for every cast. Existing settings and appearance choices are preserved.

# BuffTap 1.26.4-beta6

### Nearby spacing for every class
Classes without the higher-rank buff option no longer have an empty row in their Nearby settings. The remaining switches move up together; Mana reserve stays in place. This is a visual-only adjustment, with no tests rerun as requested.

# BuffTap 1.26.4-beta5

### Visual polish
Return the favor now sits directly beneath the other Nearby list switches. Mana reserve stays at the bottom in its existing position.

Diagnostics text appears directly in its report pane, without an extra inner box or coloured focus border. It remains selectable and copyable with **Ctrl+C**, including through **Select all**. This update changes appearance only; regression tests were not rerun at the owner's request.

# BuffTap 1.26.4-beta4

### Tidier Nearby and Diagnostics controls
The Nearby upgrade switch now has its own space. Return the favor sits above Mana reserve, keeping the mana control at the bottom. Diagnostics buttons also have separate spaces, including Inspect buffs and Unknown items.

You can select the text in the main Diagnostics display or a captured report and press **Ctrl+C** to copy. **Select all** replaces Print to chat. Text stays stable while selected; Refresh diagnostics captures current information again. Existing name-hiding applies to the main display too. **Full check-up already includes the active-buff inspection.**

### Helpful choices in fresh setup
New-character setup recommends Cleanse, normal Resurrection and cleanse-first ordering for classes that support them. Druids and Shamans are also offered SmartShift. These can be selected before the spells or forms are learned, while actual use still requires the relevant ability and normal out-of-combat checks. Each recommendation can be declined.

Existing players keep their choices and are not sent through setup again. They can opt into the recommendations by reviewing setup manually. The earlier beta's optional charge reminders, buff-grades and rank changes are retained, with their existing live-testing limits.

# BuffTap 1.26.4-beta3

### Shield charge reminders
Shamans can choose **Refresh at charges** beneath Lightning Shield or Water Shield in **My buffs**. Select one or two remaining charges, or leave it **Off** for the existing timing behavior. Solo, Party and Raid may use different choices. Charge reminders use readable information outside combat and retain normal casting requirements.

### Optional Nearby buff-grades
Enable **Offer higher rank buffs** on the Nearby page to offer a better rank when someone already has a clearly identified lower one and can receive your known upgrade. It starts off. Unknown ranks, group equivalents and equal or higher ranks are left alone by the upgrade check. Comparing ranks cannot account for every talent bonus; normal stronger-effect protections still apply. Each cast needs your input.

### Easier troubleshooting and Supplies setup
**Diagnostics > Inspect buffs** captures your readable active buffs and explains which reminders recognize them. Copy the result from the existing report box; Full check-up includes it too. Information hidden by the game is marked unavailable, and combat does not show an old snapshot as current.

The final setup page now explains Supplies for your class, including Hunter ammo, Warlock Soul Shards and group-buff reagents. **Set up supplies** opens the existing tracking page so you can choose items and warning minimums. Nothing is automatically tracked or enabled, and existing users are not sent through setup again.

Earlier beta fixes and ordinary recipient-rank changes are included. These additions still need in-game checks, including whether Forever exposes shield charge counts as expected. The four-class recipient-boundary check remains a public-release gate.

# BuffTap 1.26.4-beta2

### More appropriate buffs for lower-level players
BuffTap previously used the level where most buff ranks are learned as the requirement for receiving them. This beta applies Classic's usual ten-level allowance to ordinary ranked Mage, Priest, Druid and Paladin buffs. For example, it can offer Arcane Intellect rank 3 from recipient level 18 when you know that rank.

This covers Mark of the Wild, Thorns, Arcane Intellect, Dampen and Amplify Magic, Fortitude, Divine Spirit, Shadow Protection, Might and Wisdom. Group versions and unusual spells keep their existing behavior while their rules are evaluated separately. Your priorities, settings and appearance stay the same, with no extra setup.

The earlier beta's Nearby, group-choice and Demonic Pact corrections are included. The ordinary-buff allowance still needs representative in-game boundary testing on Forever before public release. BuffTap continues to require known spells, readable recipient information and your input for every cast.

# BuffTap 1.26.4-beta1

### Nearby combat safety
Corrected the combat safeguard on Nearby row buttons so their prepared casts are cleared when combat begins. Their layout and the recent cooldown feedback stay the same.

### Group buffs follow your choices
Turning **Also on me** off now prevents a group cast that would include you. BuffTap can still use a group buff for another raid subgroup. When an affected member's buff information cannot be verified, it falls back to eligible single-target buffs. Readable, already-covered members do not unnecessarily block a group cast.

### Demonic Pact pet recovery
Warlocks with **Demonic Pact** can receive a reminder to summon their chosen different demon while a sacrifice effect is active. Summoning the sacrificed demon, including its equivalent form, remains withheld to protect that effect. Existing pet choices, Soul Link upkeep and normal casting requirements are retained. No new setup is needed.

Your settings and appearance are preserved. This beta needs in-game checking of combat transitions and Warlock talent detection. If Pact ownership cannot be verified, the reminder keeps the protective sacrifice behavior.

# BuffTap 1.26.3

### Smoother Nearby feedback
Successful Nearby confirmations now show a subtle sweep from left to right. Repeated presses wait for the real cooldown without an extra fixed pause. Corrected cases where conflicting cooldown information or an unrelated game error could produce misleading failure messages. Matching successes clear provisional failures; genuine failures still show their reason. Every cast still needs your input.

### Resurrection and SmartShift
Druids can use normal **Revive** through the Resurrection helper at every rank. **Also use Rebirth** remains optional and can stay off. A dead group member returning into range is checked again. SmartShift now also offers your previous form after a confirmed successful cleanse, using another click as usual.

### Configure class tracking early
Under **Helpers > Tracking**, Druids can choose Track Humanoids and Warlocks can choose Sense Demons before learning them. The reminder becomes usable once the spell is learned. Druid Track Humanoids still requires Cat Form.

### Missing foods restored
Added 15 foods, including Goblin Deviled Clams, Clamlette Surprise, Dirge's Kickin' Chimaerok Chops, regional meals and seasonal treats. Choose them under **Consumables > Food > Choose**. Existing choices and Auto preference order are preserved. Some older foods grant Stamina and Spirit without the experience bonus shown on newer meals; descriptions reflect current tooltips.

Thanks to **shaunpearsondev** for reporting the missing Goblin Deviled Clams.

Your settings are preserved. Combat restrictions remain unchanged. The reported range-error incident has not been reproduced exactly; the related failure-handling cases above are corrected.

# BuffTap 1.26.2

### Fixed
Corrected an edge case introduced by 1.26.1's smooth buffing update: repeated reminder sounds could slip through when the next class buff changed or briefly disappeared while the game updated its buffs. Active buffing sequences now remain quiet through those transitions. The initial reminder and new needs after a pause can still alert normally; cleansing, resurrection and other independent reminders retain their sound behavior.

No settings change is needed. This update changes reminder sound eligibility only; spell priorities, cooldowns and the repeat-cast safeguard are retained.

# BuffTap 1.26.1

### Faster, smoother buffing
Working through several class buffs is more responsive. The next eligible spell stays on your usual binding during the global cooldown, letting repeated presses use the game's spell queue. A cooldown sweep shows the wait, without another alert when it finishes. No setup change is needed; every cast still requires your input.

### Clearer mana pauses
When mana runs low, the main reminder stays dimmed with **Waiting for mana** and **Resumes when ready**, even with Nearby closed. A configured reserve says **Saving mana**. The status is silent and cannot cast or use an item; normal reminders return when enough mana is available.

### More reliable SmartShift
Druid and Shaman return forms can queue too. After class buff maintenance, the return takes priority over optional consumable, tracking, weapon, readiness and Nearby reminders. Rapid presses and recovering mana no longer cause the reproduced delays. Cleansing and resurrection keep their priority.

### Repeat-cast safeguard
A brief wait after a confirmed successful self buff reduces repeat offers while the game updates its aura. Other spells remain eligible, and missing effects become retryable afterward. Refresh settings and priorities are unchanged. This addresses a reproduced timing gap; jimbo1111's exact live Thorns incident remains unconfirmed.

Existing settings are preserved. Owner testing covered rapid buffing, mana recovery, SmartShift with Nearby enabled and settings after reload. Thanks to **Mechrite** for suggesting more responsive buffing and **jimbo1111** for the Thorns report.

# BuffTap 1.26.0

### Added
Food, Flask, Elixirs and Utility each have an optional **Manual** mode on Consumables. Auto keeps the existing behavior. Manual items appear as small, centered icons with stock counts; click an icon directly to use that item. The buff binding and mouse wheel skip Manual families. Solo, Party and Raid can use different modes.

The strip stays visible when the main reminder is hidden or idle. Under Customization > Buff reminder, enable **Detach consumables** to position it separately with **Move reminders** or Edit Mode. Done saves; Cancel restores the move session's starting positions. Reset look & position restores defaults without changing item choices.

Appearance settings put Visible labels before Text, including label position. Camping and Supplies have larger previews and fuller layouts. Timers are centered, group counts sit at the top right, and Modern Soft glow/Pulse has a rounded inside and square outer halo.

My buffs now explains default refresh timings in an information panel instead of showing a second slider. Adjust each buff's row, or use Reset default timings for the selected Solo, Party or Raid setup. Resetting timings leaves buff choices and priorities alone.

### Fixed
The release review corrected prepared clicks after disabling BuffTap, SmartShift ignoring pauses or waiting too long after cooldowns, Manual icons returning late at refresh thresholds, and appearance reset leaving some choices unchanged.

Selected elixir and utility thumbnails now have their own space along the bottom-left of each row, with refresh timing on the right, so they no longer overlap the selection text.

### Limits
Up to eight Manual effects are clickable. Hover +N for remaining effects to use from your bags. Unknown stock shows a question mark. Unsafe player states hide the icons; changed items cancel the click. Manual food leaves class reminders available while eating.

Automated regression checks passed; final Forever testing is still recommended. Thanks to **Xprit44** for the suggestion.

# BuffTap 1.25.0

Class settings can be prepared ahead of learning spells, including cleansing types, resurrection, Druid Rebirth and cleansing order. BuffTap still requires a learned, usable spell before offering a cast. Prefer Abolish appears only for Druids and Priests.

Open My buffs > Review class setup to choose recommendations. Review starts unchecked and asks for confirmation. You can create a profile backup first. Paladin recommendations use blessing priorities that adapt as spells are learned. Shaman recommendations set the main-hand preference, while weapon application remains a separate choice. Manual fixed preferences stay fixed.

Druids and Shamans can enable SmartShift to offer their previous form after BuffTap self-buffing. Each buff and the return require your input. Return reminders are silent. Food and Elixirs have category dropdowns and benefit descriptions; filtering never changes saved selections or automatic item choice. Rogue choices now include Atrophic, Numbing, Sebacious and Occult Poison.

Your existing settings are preserved. Cleansing and resurrection start off for fresh profiles, and can be enabled whenever you choose. SmartShift is optional and never changes form without your click or binding. Existing contributor acknowledgments remain in the release history below.

# BuffTap 1.18.0

## A redesigned settings window

- Rebuilt the settings window with a new sidebar, page icons, rounded controls, on/off switches and the Inter typeface. The BuffTap banner stays at the top.
- Sliders now show what they measure (seconds, pixels, percent or players) inside their value fields. Hover a slider to see its range. Type a number and press Enter to save, or Escape to cancel.
- Preview your buff and camping reminders while adjusting their appearance. Previews never cast, target or play alerts.
- Choose gold, your class colour or a custom colour for the interface accent. The window size can be scaled.
- Nearby has its own appearance settings: scale, width, background and visible rows.
- Patch notes now live inside the addon, covering the ten most recent versions. The newest release opens first; click any other version to expand it.
- Buffs list: unchecked buffs are dimmed, Default appears only when a buff has its own timing, and the arrows reorder priority.

## New option

- Pause consumable and weapon reminders while resting in cities and inns, separately from buff reminders. Find it on the Consumables and Weapons pages. Thanks to waggz81 for the idea.

## Corrections

- Item choices now show the client's localized item names.
- Party and raid group preferences are no longer exposed to a name clash with other addons when loading.
- `/bt reset` now asks for confirmation: type `/bt reset confirm`.
- Many settings texts are now translated in German, French, Spanish and Brazilian Portuguese.

Every cast still requires your click or key binding. Your existing settings, profiles and Solo, Party and Raid preferences are kept.
