#!/usr/bin/env bash
# Preset: Kubernetes / GitOps infrastructure

preset_name="kubernetes-gitops"
preset_description="Kubernetes infrastructure with GitOps, network policies, deployment verification, and cluster operations"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="architecture.md|Cluster architecture, namespaces
deployment-flow.md|Deployment checklist, rollback commands
network-policies.md|CiliumNetworkPolicy critical rules and constraints
cross-service.md|Naming conventions, required labels"

# Technology stack entries
TECH_STACK="| Orchestration | Kubernetes |
| OS | *Talos Linux / Ubuntu / other* |
| CNI | *Cilium / Calico / other* |
| GitOps | *ArgoCD / Flux* |
| CI/CD | *Argo Workflows / GitHub Actions / GitLab CI* |
| Secrets | *OpenBao/Vault + ExternalSecrets / sealed-secrets* |
| Registry | *Zot / Harbor / GHCR* |
| Monitoring | *VictoriaMetrics / Prometheus + Grafana* |"

# Development workflow
WORKFLOW='```bash
# Check cluster health
./scripts/smoke-cluster.sh

# Validate network policies before commit
./scripts/validate-cnp.sh

# After deploying
./scripts/verify-deploy.sh <service> <tag>

# ArgoCD sync status
argocd app list
argocd app sync <app-name>
```'

# Project conventions
PROJECT_CONVENTIONS='- All changes via GitOps — commit to git, ArgoCD/Flux applies to cluster.
- Every service needs: Kustomize manifests, ArgoCD App, NetworkPolicy, ExternalSecret, ServiceMonitor.
- Validate network policies with `./scripts/validate-cnp.sh` before committing.'

# Smoke test scripts: "filename|title|checks_variable_name"
SMOKE_SCRIPTS="smoke-cluster.sh|Cluster Health Checks|SMOKE_CLUSTER_CHECKS
validate-cnp.sh|Network Policy Validation|SMOKE_VALIDATE_CNP_CHECKS
verify-deploy.sh|Deployment Verification|SMOKE_VERIFY_DEPLOY_CHECKS"

# shellcheck disable=SC2034
SMOKE_CLUSTER_CHECKS='section "Nodes"

NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d " ")
if [[ "$NODE_COUNT" -gt 0 ]]; then
  pass "Cluster reachable — $NODE_COUNT node(s)"
else
  fail "Cannot reach cluster (kubectl get nodes failed)"
fi

READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || true)
if [[ "$READY_NODES" -eq "$NODE_COUNT" ]]; then
  pass "All $NODE_COUNT nodes Ready"
else
  fail "$READY_NODES/$NODE_COUNT nodes Ready"
fi

section "Core Components"

for NS in kube-system; do
  NOT_RUNNING=$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l | tr -d " ")
  if [[ "$NOT_RUNNING" -eq 0 ]]; then
    pass "$NS: all pods healthy"
  else
    warn "$NS: $NOT_RUNNING pod(s) not Running"
  fi
done

section "Deployments"

TOTAL_DEPLOY=$(kubectl get deployments -A --no-headers 2>/dev/null | wc -l | tr -d " ")
READY_DEPLOY=$(kubectl get deployments -A --no-headers 2>/dev/null | awk '"'"'{split($3,a,"/"); if(a[1]==a[2]) print}'"'"' | wc -l | tr -d " ")
if [[ "$READY_DEPLOY" -eq "$TOTAL_DEPLOY" ]]; then
  pass "All $TOTAL_DEPLOY deployments ready"
else
  warn "$READY_DEPLOY/$TOTAL_DEPLOY deployments ready"
fi'

# shellcheck disable=SC2034
SMOKE_VALIDATE_CNP_CHECKS='section "Network Policies"

if ! command -v kubectl >/dev/null 2>&1; then
  fail "kubectl not found"
else

# Check for CiliumNetworkPolicy or NetworkPolicy
CNP_COUNT=$(kubectl get cnp -A --no-headers 2>/dev/null | wc -l | tr -d " ")
NP_COUNT=$(kubectl get networkpolicy -A --no-headers 2>/dev/null | wc -l | tr -d " ")

if [[ "$CNP_COUNT" -gt 0 ]]; then
  pass "Found $CNP_COUNT CiliumNetworkPolicy resources"
elif [[ "$NP_COUNT" -gt 0 ]]; then
  pass "Found $NP_COUNT NetworkPolicy resources"
else
  warn "No network policies found"
fi

section "Policy Syntax"

info "Checking for dangerous patterns..."

# Check for toEntities:cluster with toPorts (BPF overflow risk)
DANGEROUS=$(kubectl get cnp -A -o yaml 2>/dev/null | grep -c "toEntities" || true)
if [[ "$DANGEROUS" -gt 0 ]]; then
  warn "Found $DANGEROUS toEntities rules — verify no toEntities:cluster + toPorts combos"
else
  pass "No toEntities rules found (or no CNPs)"
fi

fi'

# shellcheck disable=SC2034
SMOKE_VERIFY_DEPLOY_CHECKS='section "Deployment Verification"

SERVICE="${1:-}"
TAG="${2:-}"

if [[ -z "$SERVICE" ]]; then
  info "Usage: verify-deploy.sh <service> [tag]"
  warn "No service specified"
else
  # Check deployment exists and is ready
  if kubectl get deployment "$SERVICE" -n "$SERVICE" --no-headers 2>/dev/null | grep -q .; then
    READY=$(kubectl get deployment "$SERVICE" -n "$SERVICE" -o jsonpath="{.status.readyReplicas}" 2>/dev/null || echo "0")
    DESIRED=$(kubectl get deployment "$SERVICE" -n "$SERVICE" -o jsonpath="{.spec.replicas}" 2>/dev/null || echo "0")
    if [[ "$READY" -eq "$DESIRED" ]] && [[ "$READY" -gt 0 ]]; then
      pass "$SERVICE: $READY/$DESIRED replicas ready"
    else
      fail "$SERVICE: $READY/$DESIRED replicas ready"
    fi
  else
    fail "$SERVICE deployment not found in namespace $SERVICE"
  fi

  if [[ -n "$TAG" ]]; then
    CURRENT_IMAGE=$(kubectl get deployment "$SERVICE" -n "$SERVICE" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null || echo "unknown")
    if echo "$CURRENT_IMAGE" | grep -q "$TAG"; then
      pass "Image tag matches: $TAG"
    else
      warn "Expected tag $TAG but found: $CURRENT_IMAGE"
    fi
  fi
fi'

# Troubleshooting sections
TROUBLESHOOTING_SECTIONS='### Symptom: Pod stuck in CrashLoopBackOff

**Diagnosis:** Application crashing on startup. Check logs for root cause.

**Fix:**
```bash
kubectl logs -n <ns> <pod> --previous
kubectl describe pod -n <ns> <pod>
```

---

### Symptom: Traffic blocked despite correct-looking network policy

**Diagnosis:** Network policies use container port (post-DNAT), not service port.
Also check for BPF map overflow if using Cilium.

**Fix:**
```bash
kubectl get pod -n <ns> <pod> -o jsonpath="{.spec.containers[*].ports}"
hubble observe --verdict DROPPED --namespace <ns> -f
```

---

### Symptom: ExternalSecret stuck in SecretSyncFailed

**Diagnosis:** Vault/OpenBao unreachable, token expired, or secret path incorrect.

**Fix:**
```bash
kubectl describe externalsecret -n <ns> <name>
```'

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="cluster-state.md|Current cluster health, node status, version info
cilium-bpf.md|BPF policy map rules, port mapping reference, incident history
infrastructure.md|Service versions, config state, operational notes
deploy-history.md|Deployment versions, rollback history, image tags
debugging.md|Common errors encountered and their solutions"

# Slash commands to scaffold
COMMANDS="review.md
deploy-check.md
cluster-health.md
validate-policies.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_ARCHITECTURE='# Cluster Architecture

## Namespace Organization

| Namespace | Purpose |
|-----------|---------|
| `kube-system` | Core Kubernetes components |
| `argocd` | GitOps controller |
| `monitoring` | Metrics, logging, alerting |
| `cert-manager` | TLS certificate management |
| *app namespaces* | One namespace per application |

*Add your actual namespaces above as you deploy services.*'

# shellcheck disable=SC2034
RULES_CONTENT_DEPLOYMENT_FLOW='# Deployment Flow

## Deployment Checklist (New Service)

- [ ] Kustomize/Helm manifests
- [ ] ArgoCD Application / Flux Kustomization
- [ ] NetworkPolicy / CiliumNetworkPolicy
- [ ] DNS entry (if externally accessible)
- [ ] Secrets in vault + ExternalSecret
- [ ] Monitoring (ServiceMonitor / PodMonitor)
- [ ] Build pipeline (CI workflow)

## Rollback

```bash
# ArgoCD
argocd app history <app-name>
argocd app rollback <app-name> <revision>

# Manual
kubectl set image deployment/<name> -n <ns> <container>=<registry>/<image>:<previous-tag>
```'

# shellcheck disable=SC2034
RULES_CONTENT_NETWORK_POLICIES='# Network Policies

## Critical Rules

| Rule | Reason |
|------|--------|
| **ALWAYS** use container port in `toPorts` | Cilium evaluates post-DNAT (pod port, not service port) |
| **AVOID** `toEntities: cluster` with `toPorts` | Creates ~19K BPF entries per port — causes map overflow |
| **USE** `toEndpoints` with namespace labels | Targeted entries, scales with KEDA/HPA |
| **AVOID** L7 DNS rules / `toFQDNs` | ~25K proxy redirect entries per endpoint |

## Required Egress for Every Service

Every service policy must allow DNS:

```yaml
egress:
  - toEndpoints:
      - matchLabels:
          k8s:io.kubernetes.pod.namespace: kube-system
          k8s-app: kube-dns
    toPorts:
      - ports:
          - port: "53"
            protocol: UDP
          - port: "53"
            protocol: TCP
```

## Default Posture

**Default-deny** for all egress and ingress. Every service needs an explicit policy.'

# shellcheck disable=SC2034
RULES_CONTENT_CROSS_SERVICE='# Cross-Service Conventions

## Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| Namespace | `<service-name>` | `dn-api` |
| Deployment | `<service-name>` | `dn-api` |
| Service | `<service-name>` | `dn-api` |
| ConfigMap | `<service>-config` | `dn-api-config` |
| Secret | `<service>-<purpose>` | `dn-api-db-credentials` |

## Required Labels

```yaml
metadata:
  labels:
    app.kubernetes.io/name: <service>
    app.kubernetes.io/part-of: <project>
    app.kubernetes.io/managed-by: argocd
```'

LINT_LANGUAGES="YAML (syntax validation), JSON, Shell (shellcheck)"