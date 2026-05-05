# Current Execution Plan

I will execute one task from `TODO.md` and stop after committing it. I will keep this file updated with progress and any plan changes.

## Constraints

- First address any pre-existing issue mentioned by the latest commit before starting the next TODO task.
- Complete exactly the first incomplete task from `TODO.md`, unless it must be decomposed first.
- If decomposition is needed, update `PLAN.md` and `TODO.md`, commit that planning change, complete only the first new subtask, then stop.
- Run relevant tests and fix any issues introduced or exposed by this task.
- Mark completed work in `TODO.md`, update `PLAN.md`, commit with a clear message, then stop.

## Steps

1. Inspect the latest commit for notes about pre-existing issues.
2. Check the working tree so existing user changes are not overwritten.
3. Read `TODO.md` and `PLAN.md`.
4. Identify the first incomplete task.
5. If the task is too broad, refine it into smaller subtasks in `TODO.md` and `PLAN.md`.
6. Implement the selected task or first subtask.
7. Run the relevant build and test commands.
8. Fix any build, test, or warning failures related to the task.
9. Update `TODO.md`, `PLAN.md`, and this progress file.
10. Commit all changes for this invocation.

## Progress

- Created this plan file before repository inspection.
- Inspected the latest commit (`[T03] Add ExchangeRateHost client`); it does not mention a known pre-existing issue.
- Checked `TODO.md`; the first incomplete task is `T04: RateService（缓存 + 状态）`.
- Read existing model, client, project, and test files to match current Swift/XCTest patterns.

## T04 Implementation Plan

1. Add `RateBar/Storage/SnapshotStore.swift` to encode and decode `RatesSnapshot` in `UserDefaults`.
2. Add `RateBar/Services/RateService.swift` as a `@MainActor @Observable` service wrapping `RateFetching`.
3. Ensure refresh success updates state and persists the latest snapshot.
4. Ensure refresh failure records a user-readable error while preserving the previous snapshot.
5. Add `RateBarTests/RateServiceTests.swift` covering refresh success, failure with cache preservation, persistence reload, and stale detection.
6. Regenerate the Xcode project if needed.
7. Run the test suite and fix any warnings or failures.
8. Mark T04 complete in `TODO.md`, update `PLAN.md`, commit, and stop.

## Progress Update

- Added `SnapshotStore` for UserDefaults JSON persistence.
- Added `RateService` with cached snapshot loading, refresh state, error retention, and stale-data detection.
- Added `RateServiceTests` for the four T04 acceptance tests.
- First test build failed on Swift 6 strict-concurrency checking because `RateFetching` was not `Sendable`.
- Updating the fetch protocol and model DTOs to make rate snapshots safe to cross actor boundaries.
- Second test build reached the test target but found `UserDefaults` crossing into the main-actor service from nonisolated tests.
- Moving `RateServiceTests` methods onto the main actor to match the service isolation.
- Regenerated the Xcode project with `xcodegen generate`.
- Verified with `xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" test`: 11 tests passed, including all 4 T04 tests.
- Marked T04 complete in `TODO.md` and `PLAN.md`.
- Reran verification with output captured at `/tmp/ratebar-t04-xcodebuild.log`.
- Scanned the captured log for `warning:` and `error:`; no matches were found.
- Final changes staged for a `[T04]` commit.
