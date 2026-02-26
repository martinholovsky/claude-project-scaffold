---
description: Run the project test suite and analyze failures
allowed-tools: Bash(npm test:*), Bash(pytest:*), Bash(vitest:*), Bash(cargo test:*), Bash(go test:*), Read, Grep, Glob
---

Run the project's test suite. If any tests fail:
1. Read the failing test file to understand the assertion
2. Read the source code being tested
3. Identify the root cause
4. Suggest a fix (or fix it if the cause is clear)

If all tests pass, report the summary.

$ARGUMENTS
