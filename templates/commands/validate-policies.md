---
description: Validate network policies and check for dangerous patterns
allowed-tools: Bash(kubectl:*), Bash(./scripts/*:*), Read, Grep, Glob
---

Validate network policies in the cluster:

1. Run `./scripts/validate-cnp.sh` if it exists
2. Check for dangerous patterns:
   - `toEntities: cluster` with `toPorts` (BPF map overflow risk)
   - `fromEntities: cluster` in namespace CNPs (duplicate entries)
   - Service ports used instead of container ports in `toPorts`
3. Check for namespaces missing network policies
4. Report BPF map pressure if Cilium is installed

$ARGUMENTS
