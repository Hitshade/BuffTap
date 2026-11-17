# BuffTap 1.25.0 beta verification

Baseline: v1.24.8, commit 1234233dfba7110df06855cd757941547f3e840d. Working branch: work/bufftap-1.25.0.

Executed on 2026-11-16 with the bundled Python runtime and lupa 2.8:

```
BT_KEEP_GOING=1 python -c "import sys; sys.path.insert(0,'tests'); import run_release; import test_bufftap as t; print('RELEASE_RESULT',len(t.tests),'passed',len(t.failures),'failed'); print(t.failures); sys.exit(bool(t.failures))"
```

Observed full-suite result: **2092 passed, 0 failed**. This run included regression changes for beta setup, class settings, SmartShift and picker controls. After the final setup preview/documentation additions, executed:

```
python -c "import sys; sys.path.insert(0,'tests'); import test_release_125; import test_bufftap as t; print('FOCUSED_RESULT',len(t.tests),'passed',len(t.failures),'failed')"
```

Observed focused result: **107 passed, 0 failed**, including all four locale controls, level-one/max-level class-list parity, backup preserving the active profile, cross-page selection, confirmation before changes, dropdown navigation and texture-parent rejection. Also executed tests/test_revive.py successfully after removing learned-spell restrictions from its preference controls.

These are simulated API tests. They are not a claim of a fresh successful live game smoke test. The owner supplied live screenshots and regression reports used to correct layout and class messaging.

## Owner smoke check

- Level 1: /reload, open every relevant settings page; check unlearned class choices remain configurable. Review recommendations, page forward/back, cancel, and verify unchanged settings. Apply one choice with backup and confirm persistence after reload.
- Level 34 Druid: enable SmartShift, Cat to buff(s) to silent Cat return, one click per action; repeat with Travel if convenient. Check disabled SmartShift, manual form interruption and combat interruption.
- Food and Elixirs: open Category dropdown, combine search and In bags only, change categories and verify selected items remain saved.

No publication, deletion or direct game saved-settings edits are part of this build.
