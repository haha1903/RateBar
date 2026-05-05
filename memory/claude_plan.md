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
- Added the explicit `AppIntents` import to `RateBarApp.swift`, reran tests, and confirmed the metadata warning was removed.
- Committed the pre-existing issue fix as `a119179` (`Fix AppIntents metadata warning`).

## T05 Plan

1. Add `RateBar/UI/MenuBarLabel.swift` for the menu bar title text, including AUD-to-CNY formatting and stale indication.
2. Add `RateBar/UI/MenuContent.swift` for the menu dropdown: four rate rows, last updated text, stale/error status, Refresh, and Quit.
3. Wire `RateBarApp` to create a `RateService`, render the new label/content, invoke refresh from the button, and quit via `NSApplication`.
4. Add `RateBarTests/MenuContentTests.swift` covering four displayed rates, stale badge text, and refresh button action invocation.
5. Add README screenshot documentation for the new T05 UI.
6. Regenerate the Xcode project, run tests/build, fix any warnings or failures, update `TODO.md` and `PLAN.md`, commit, and stop.

## T05 Progress

- Added `MenuBarLabel` and `MenuContent` SwiftUI components with testable display models.
- Updated `RateBarApp` to hold a `RateService`, render AUD-to-CNY in the menu bar, show dropdown content, run refresh from the button, and terminate from Quit.
- Added `MenuContentTests` for the three T05 acceptance-test names.
- Regenerated `RateBar.xcodeproj` with XcodeGen so the new source and test files are included.
- Ran the test suite after T05 implementation: 14 tests passed, including the 3 new menu UI tests.
- Added README screenshot documentation via `docs/ratebar-menu-screenshot.svg`.
- Adjusted `MenuBarLabel` to include the dollar-circle system icon as well as the formatted rate text, matching the T05 plan.
- Captured final test verification in `/tmp/ratebar-t05-test.log` after the label correction: 14 tests passed and no `warning:` or `error:` lines were found.
- Captured final clean build verification in `/tmp/ratebar-t05-clean-build.log` after the label correction: build succeeded and no `warning:` or `error:` lines were found.
- Launched the rebuilt `RateBar.app`, confirmed a `RateBar` process started, and quit it via bundle identifier `com.peter.ratebar`.
- Marked T05 done in `TODO.md` and checked the T05 delivery criteria in `PLAN.md`.
