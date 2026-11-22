# Decisions

| Date | Decision | Effect |
| --- | --- | --- |
| 2026-11-22 | Use one Flutter Android app with Android 13 (API 33) as the minimum. | Keep Elder and Guardian in one build and test the minimum on the API 33 emulator. |
| 2026-11-22 | Start with the two-mode UI preview. | Both modes open directly. Phone verification and service integration follow in later work. |
| 2026-11-22 | Build approved pairing and a two-device callback as the first AWS milestone. | This defines the implementation order. No AWS deployment is part of the preview. |
| 2026-11-22 | Keep the Obsidian AI wiki and Codex maintainer skill in Git. | Clones share project rules, design decisions, and verification history. |
| 2026-11-22 | Use Health Connect as Saathi’s primary wearable data integration. | Test with labeled synthetic data and Health Connect Toolbox before validating real watch sync. |

When a standing decision changes, date the new entry, identify what it supersedes, and update the active rules in the linked notes.

- 2026-11-22: The Elder home uses a horizontally scrolling two-row pad, with language settings in both modes. Guardian mode may use a richer dashboard. Care-home support is a product goal alongside family use.
