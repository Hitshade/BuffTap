# BuffTap 1.26.12-beta2

### A manual thank-you when automatic thanks cannot reach someone
Under Helpers > Solo Thanks, enable **Offer a manual thank-you** to try the fallback. It starts off. If the game provides a reliable full name for an otherwise unreachable buff giver, a handshake marked THANK appears at your reminder position when no buff is ready.

Click to whisper, or right-click to dismiss. The offer lasts 30 seconds. Your buff binding never sends it. Automatic thanks continues trying; either successful route removes the other offer.

The message starts as **Thank you for [buff]!**. Edit it inside Solo Thanks and press Enter to save; [buff] inserts received buff names. Several buffs from one giver share a thank-you. Reset restores the original message.

Keep thanking while resting applies to both the offer and click. Normal solo restrictions still apply. A trustworthy full name is required, and chat restrictions can prevent delivery. Local beta for owner testing, not published.

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
