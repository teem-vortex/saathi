---
name: saathi-maintainer
description: Apply Saathi's project decisions and UI conditions before any work in this Flutter Android repository. Keep its Obsidian wiki current as features, standing instructions, or verification results change.
---

# Maintain Saathi

Resolve all paths from the Saathi repository root. Read [the index](../../../AI-Wiki/Home.md), [project conditions](../../../AI-Wiki/Project-Conditions.md), and the recent [work log](../../../AI-Wiki/Work-Log.md) before working. Inspect the current branch and working tree to check which behavior is available there.

- For screen or interaction changes, read [UI Conditions](../../../AI-Wiki/UI-Conditions.md). Preserve direct access to the two preview modes until the team asks to implement onboarding.
- For feature, data, integration, or sequencing work, read [Project Design](../../../AI-Wiki/Project-Design.md) and [Decisions](../../../AI-Wiki/Decisions.md). Treat proposed integrations as future work and verify implementation claims against code.
- For Flutter changes, run the relevant analyzer and tests. For changes to the UI or Android behavior, verify the affected flow on an Android 13 emulator when available. Record which checks actually ran.
- Update the affected notes in the same task as each feature, durable fix, or changed decision. Update the status from planned to implemented only when supported by code. At handoff, append a dated entry with the change, evidence, and any remaining work. Mention local-only work explicitly.
- Capture an explicit standing instruction such as “always do this” or “do not do this again” as a rule with its scope and date. Put UI rules in UI Conditions, project-wide rules in Project Conditions, and architectural choices in Decisions. If a later authorized instruction changes a rule, revise the active rule and record what it superseded. Keep task-only requests and personal information out of standing rules.
- Keep the wiki usable in GitHub and Obsidian with relative Markdown links. Update the index when adding a note. Log durable work and findings, while leaving the log alone for a question that produces neither.
