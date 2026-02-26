---
description: Create a session-resilient plan file for a multi-step task
allowed-tools: Bash(cp:*), Read, Write, Glob
---

Create a plan file for the following task. Follow the Plan Execution Protocol:

1. Copy `docs/plans/.plan-template.md` to `docs/plans/plan-{topic}.md`
2. Fill in the objective, context, and implementation steps
3. Each step should be a checkbox item with clear acceptance criteria
4. Include a "Verification" section describing how to confirm success

The plan should be detailed enough that a new Claude session can pick it up and continue without additional context.

Task to plan:
$ARGUMENTS
