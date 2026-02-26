---
description: Run TypeScript type checking and fix type errors
allowed-tools: Bash(npx tsc:*), Bash(npx:*), Read, Edit, Grep, Glob
---

Run `npx tsc --noEmit` to check for TypeScript type errors.

If errors are found:
1. Group them by file
2. For each error, read the relevant code
3. Suggest or apply fixes
4. Re-run type checking to verify

$ARGUMENTS
