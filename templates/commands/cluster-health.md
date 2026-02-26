---
description: Run cluster health checks and report status
allowed-tools: Bash(kubectl:*), Bash(./scripts/*:*), Read
---

Run a comprehensive cluster health check:

1. Run `./scripts/smoke-cluster.sh` if it exists
2. Check node status: `kubectl get nodes`
3. Check for unhealthy pods: `kubectl get pods -A | grep -v Running | grep -v Completed`
4. Check for pending PVCs: `kubectl get pvc -A | grep -v Bound`
5. Check recent warning events: `kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp | head -20`

Summarize the cluster health and flag any issues that need attention.

$ARGUMENTS
