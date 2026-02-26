---
description: Verify a deployment is healthy after rollout
allowed-tools: Bash(kubectl:*), Bash(argocd:*), Bash(./scripts/*:*), Read
---

Check the deployment health for the specified service.

1. Run `./scripts/verify-deploy.sh` if it exists
2. Check pod status: `kubectl get pods -n <namespace>`
3. Check recent events: `kubectl get events -n <namespace> --sort-by=.lastTimestamp`
4. Check ArgoCD sync status: `argocd app get <app-name>` (if available)
5. Report any issues found

Service to check:
$ARGUMENTS
