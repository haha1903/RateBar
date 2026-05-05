Visible execution plan for this invocation

Scope guard:
- Complete exactly the first undone task from TODO.md, then stop.
- Before starting that task, inspect the latest commit for any mentioned pre-existing issues and fix those first if present.
- Keep changes focused and do not revert unrelated work.
- I cannot record private chain-of-thought, but this file will contain the concrete plan, decisions, and progress updates needed to audit the work.

Initial plan:
1. Inspect the latest Git commit message and diff to identify any pre-existing issue called out there.
2. If the latest commit mentions or introduces an issue that is still present, fix that issue first, test it, document it, and include it in the final commit for this invocation.
3. Read TODO.md and locate the first incomplete task.
4. If the task is too large to complete safely in one invocation, update PLAN.md and TODO.md to split it into smaller ordered subtasks, commit that planning change, and execute only the first subtask if appropriate.
5. Inspect the relevant project files and existing tests to understand local structure and conventions.
6. Implement the first undone task completely with focused changes.
7. Add or update tests appropriate to the behavior changed.
8. Run the relevant build and test commands, fixing any warnings or failures encountered.
9. Mark the completed task in TODO.md and update PLAN.md with current status.
10. Commit all changes with a descriptive message.
11. Stop without starting the next TODO.md task.

Progress:
- Plan file created before repository inspection.
- TODO.md inspected. The first incomplete task is T03: ExchangeRateHost client.
- Latest commit inspected: `aa463b5411ff9221bc56416024aeba6ab15fa6d2` (`[T02] Add exchange rate data models`). Its message and changed-file list do not mention an unresolved pre-existing issue, so there is no separate pre-task fix identified.
- T03 is small enough to complete in one invocation without splitting. Next steps: inspect existing model/test/project structure, implement `RateFetching`, `ExchangeRateHostClient`, and `RateClientError`, add URLProtocol-backed client tests, run XCTest, update TODO.md and PLAN.md, then commit.
- Added `RateBar/Network/RateClient.swift` with the async exchangerate.host client and error mapping.
- Added `RateBarTests/RateClientTests.swift` with URLProtocol-backed success, HTTP 500, and bad JSON tests. Next step: regenerate the Xcode project and run the test suite.
- Regenerated the Xcode project with `xcodegen generate`.
- Ran `xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" test`; all 7 tests passed, including the 3 T03 tests.
- Updated TODO.md and PLAN.md to mark T03 complete. Next step: rerun verification, inspect the final diff/status, and commit.
- Reran `xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" test` with output captured to `/tmp/ratebar-t03-xcodebuild.log`; all 7 tests passed again.
- Scanned `/tmp/ratebar-t03-xcodebuild.log` for `warning:` and `error:`; no matches were found.
- Final diff/status inspected. Changes are scoped to T03 client code, URLProtocol-backed tests, generated Xcode project references, task docs, and this progress log.
- T03 changes staged for commit with a descriptive task-prefixed message.
