---
description: Review staged changes for bugs, security issues, and style
allowed-tools: Bash(git diff:*), Bash(git log:*), Read, Grep, Glob
---

Review the staged changes (`git diff --cached`) for this project.

Check for:
1. **Bugs** — logic errors, off-by-one, null/undefined access, race conditions
2. **Security** — injection, hardcoded secrets, unsafe input handling (OWASP Top 10)
3. **Style** — naming consistency, dead code, overly complex logic
4. **Tests** — are new code paths covered? Any test gaps?

For each issue found, specify the file, line, severity (critical/warning/nit), and a suggested fix.

If the changes look good, say so briefly.

$ARGUMENTS
