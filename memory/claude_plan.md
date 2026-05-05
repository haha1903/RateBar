# Execution Plan

## Scope

Complete exactly the first undone task from `TODO.md`, after first checking the latest commit for any mentioned pre-existing issue that must be fixed before task work.

## Step-by-Step Plan

1. Inspect the latest Git commit message and diff summary.
   - If it mentions a pre-existing issue, investigate and fix that issue before continuing to `TODO.md`.
   - If no such issue is mentioned, record that result and continue.
2. Read `TODO.md` and identify the first incomplete task.
3. Read `PLAN.md` and relevant project files to understand expected implementation details.
4. If the first incomplete task is too large to complete safely in one invocation, decompose it into smaller subtasks by updating `PLAN.md` and `TODO.md`, commit that planning change, and stop.
5. Implement the first incomplete task completely.
6. Add or update tests appropriate to the change.
7. Run the relevant build and test commands, fixing any failures or warnings introduced by the work.
8. Update `TODO.md` to mark the completed task done.
9. Update `PLAN.md` with the current state and any implementation notes.
10. Commit all changes with a clear, descriptive commit message.
11. Stop without starting the next task.

## Progress Log

- Plan initialized before running repository inspection commands.
- Latest commit inspected: `f335e30 [T08] Add launch at login toggle`; no pre-existing issue was mentioned in the commit message.
- `TODO.md` inspected; the first incomplete task is `T09: 打包 + 验收`.
- T09 implementation approach: add final smoke coverage for release metadata, complete README installation and known-limitations sections, then run Release build and full XCTest validation.
- Implemented T09 documentation and smoke-test edits: README now includes release build, install, and known-limitations notes; `SmokeTests` now includes `testFinalSmoke`; generated build output is ignored.
- Full XCTest validation passed: 25 tests, 0 failures. Release build initially succeeded but used Xcode's default destination selection, so the documented command is being tightened to specify the current macOS architecture.
- Explicit-destination Release build passed and `build/Build/Products/Release/RateBar.app` exists.
- Marked T09 complete in `TODO.md` and `PLAN.md`.
- Final repository step: commit the T09 changes and create the `v0.1.0` tag on that commit.
