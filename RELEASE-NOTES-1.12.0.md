# BuffTap 1.12.0

- Expanded game sound choices: Whisper ping, Alarm clock 1 and 3, and Quest complete, offered when the client exposes the corresponding sound constant.
- Optional LibSharedMedia-3.0 support for sounds registered by installed addons and media packs, including sound paths and FileDataIDs.
- Searchable sound pickers with a mouse-wheel scrollable list and native scrollbar; existing Preview controls and separate reminder/low-stock selections remain.
- Missing media selections remain saved and visibly unavailable; playback temporarily falls back to the default. Broken library calls and failed media playback are contained.
- No polling, bundled sound pack, forced dependency, or change to casting/buff selection.

Validation: 638 mocked Lua 5.1 scenarios passed. Added SoundKit IDs exist in the Forever 1.60.1.70009 database; named constants also gate availability at runtime. Native client listening and media-pack integration still need user verification.
