# Execution Plan

Requested scope: complete the first undone task in `TODO.md`, fix any issue called out by the latest commit before starting that task, verify the work, update project tracking files, commit, and stop.

Note: this file records the operational plan and progress updates. It intentionally avoids private chain-of-thought and instead keeps concrete steps, decisions, and outcomes.

## Initial Plan

1. Inspect the latest Git commit message and diff for any mentioned pre-existing issue.
2. If the latest commit identifies an issue, investigate and fix all such issues before working on `TODO.md`.
3. Read `TODO.md` and identify the first incomplete task.
4. Read `PLAN.md` and nearby source/test files needed for that task.
5. If the task is too broad to complete safely in one pass, break it into smaller tasks in `TODO.md`, update `PLAN.md`, commit that planning change, and stop after completing only the first new subtask if feasible.
6. Implement the first incomplete task using existing project patterns.
7. Run the relevant build and test commands, fixing any compilation warnings, test failures, or regressions found.
8. Mark only the completed task in `TODO.md`, update `PLAN.md` with current progress, and keep this file updated with key status changes.
9. Review the working tree and commit all relevant changes with a descriptive message.
10. Stop without starting the next task.

## Progress

- Started plan log before repository inspection.
- Inspected latest commit `695dbc4` (`[T04] Add rate service caching`). The commit message and changed files did not mention a pre-existing issue to fix before the next task.
- Read `TODO.md` and identified `T05: MenuBarExtra UI` as the first incomplete task.
- Read the relevant `PLAN.md` section. Current task scope is menu bar label/content UI, tests for four rendered rates, stale badge, and refresh button invocation, plus README screenshot documentation.
- Ran the existing test suite before T05. All 11 tests passed, but Xcode emitted an AppIntents metadata warning from the app target.
- Treating the warning as a pre-existing issue under the quality requirements. Next step: make the app target explicitly import `AppIntents` so the metadata extractor sees the dependency already declared in `project.yml`.
