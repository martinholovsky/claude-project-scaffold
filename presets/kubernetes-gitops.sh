#!/usr/bin/env bash
# Preset: Kubernetes / GitOps infrastructure

preset_name="kubernetes-gitops"
preset_description="Kubernetes infrastructure with GitOps, network policies, deployment verification, and cluster operations"

# Rules files: newline-delimited "filename|description" pairs
RULES_FILES="architecture.md|Cluster architecture, namespaces, service mesh, ingress
deployment-flow.md|Code to production: CI/CD pipeline, image build, GitOps sync
network-policies.md|NetworkPolicy / CiliumNetworkPolicy rules and constraints
security-controls.md|Admission policies, runtime security, image signing, secrets
observability.md|Logging, metrics, tracing, alerting configuration
cross-service.md|Naming conventions, label standards, resource limits"

# Technology stack entries
TECH_STACK="| Orchestration | Kubernetes |
| OS | *Talos Linux / Ubuntu / other* |
| CNI | *Cilium / Calico / other* |
| GitOps | *ArgoCD / Flux* |
| CI/CD | *Argo Workflows / GitHub Actions / GitLab CI* |
| Secrets | *OpenBao/Vault + ExternalSecrets / sealed-secrets* |
| Registry | *Zot / Harbor / GHCR* |
| Monitoring | *VictoriaMetrics / Prometheus + Grafana* |"

# Context loading table entries
CONTEXT_LOADING_TABLE="| **Deploy new service** | \`.claude/rules/deployment-flow.md\`, \`.claude/rules/network-policies.md\` |
| **Network policy change** | \`.claude/rules/network-policies.md\`, \`.claude/rules/security-controls.md\` |
| **Security hardening** | \`.claude/rules/security-controls.md\`, \`.claude/rules/architecture.md\` |
| **Observability/alerting** | \`.claude/rules/observability.md\` |
| **CI/CD pipeline** | \`.claude/rules/deployment-flow.md\` |
| **Debugging** | \`.claude/rules/troubleshooting.md\` |
| **Architecture decisions** | \`docs/decisions/index.md\` |"

# Context groups
CONTEXT_GROUPS='### `deploy`
Read: `.claude/rules/deployment-flow.md`, ArgoCD app definitions
After changes: Run `scripts/verify-deploy.sh <service>`

### `network`
Read: `.claude/rules/network-policies.md`, `.claude/rules/security-controls.md`
After changes: Run `scripts/validate-cnp.sh`

### `security`
Read: `.claude/rules/security-controls.md`, `.claude/rules/architecture.md`, `docs/decisions/`

### `observability`
Read: `.claude/rules/observability.md`

### `debug`
Read: `.claude/rules/troubleshooting.md`'

# Development workflow
WORKFLOW='### GitOps Workflow

All changes follow GitOps — commit to git, ArgoCD/Flux applies to cluster.

```bash
# Check cluster health
./scripts/smoke-cluster.sh

# Validate network policies before commit
./scripts/validate-cnp.sh

# After deploying
./scripts/verify-deploy.sh <service> <tag>

# ArgoCD sync status
argocd app list
argocd app sync <app-name>
```

### Deployment Checklist (New Service)

1. Kustomize manifests in `kustomize/apps/<service>/`
2. ArgoCD Application definition
3. CiliumNetworkPolicy / NetworkPolicy
4. DNS entry (CoreDNS or external)
5. Secrets in Vault/OpenBao + ExternalSecret
6. Monitoring (ServiceMonitor / VMServiceScrape)
7. Build pipeline (WorkflowTemplate / GitHub Actions)'

# Project overview
PROJECT_OVERVIEW="Kubernetes infrastructure managed via GitOps. All changes are applied through git commits."

# Workspace structure
WORKSPACE_STRUCTURE='{{PROJECT_NAME}}/
├── CLAUDE.md
├── .claude/
│   ├── rules/
│   │   ├── architecture.md
│   │   ├── deployment-flow.md
│   │   ├── network-policies.md
│   │   ├── security-controls.md
│   │   ├── observability.md
│   │   ├── cross-service.md
│   │   └── troubleshooting.md
│   └── hooks/
│       └── lint-on-edit.sh
├── kustomize/
│   ├── apps/           # Application manifests
│   ├── infra/          # Infrastructure components
│   └── base/           # Shared base resources
├── docs/
│   ├── plans/
│   │   └── .plan-template.md
│   └── decisions/
│       ├── index.md
│       └── adr-template.md
└── scripts/
    ├── smoke-cluster.sh
    ├── validate-cnp.sh
    └── verify-deploy.sh'

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
TROUBLESHOOTING_SECTIONS='## 1. Cluster Connectivity

### Symptom: `kubectl` commands fail with connection refused

**Diagnosis:** Kubeconfig not set, cluster API unreachable, or certificate expired.

**Fix:**
```bash
# Check kubeconfig
echo $KUBECONFIG
kubectl cluster-info

# Check API server health
curl -k https://<api-server>:6443/healthz
```

---

## 2. Deployments

### Symptom: Pod stuck in CrashLoopBackOff

**Diagnosis:** Application crashing on startup. Check logs for the root cause.

**Fix:**
```bash
# Check logs
kubectl logs -n <ns> <pod> --previous

# Check events
kubectl describe pod -n <ns> <pod>

# Check resource limits (OOMKilled)
kubectl get pod -n <ns> <pod> -o jsonpath="{.status.containerStatuses[*].lastState}"
```

---

### Symptom: Pod stuck in Pending — no nodes available

**Diagnosis:** Resource requests exceed available capacity, or node affinity/taints prevent scheduling.

**Fix:**
```bash
kubectl describe pod -n <ns> <pod>
# Look at Events section for scheduling failure reason

kubectl top nodes
kubectl describe nodes | grep -A5 "Allocated resources"
```

---

## 3. Network Policies

### Symptom: Traffic blocked despite correct-looking policy

**Diagnosis:** Network policies use container port (post-DNAT), not service port.
Also check for BPF map overflow if using Cilium.

**Fix:**
```bash
# Verify the actual container port
kubectl get pod -n <ns> <pod> -o jsonpath="{.spec.containers[*].ports}"

# If using Cilium, check Hubble for drops
hubble observe --verdict DROPPED --namespace <ns> -f
```

---

## 4. GitOps (ArgoCD/Flux)

### Symptom: Application shows OutOfSync but manifests look correct

**Diagnosis:** Resource managed by multiple sources (ArgoCD + operator/controller).

**Fix:** Ensure each resource has exactly one owner. Use `ignoreDifferences` in ArgoCD
for fields managed by controllers.

---

## 5. Secrets

### Symptom: ExternalSecret stuck in SecretSyncFailed

**Diagnosis:** Vault/OpenBao unreachable, token expired, or secret path incorrect.

**Fix:**
```bash
kubectl describe externalsecret -n <ns> <name>
# Check the Events and Conditions for the specific error
```

---

*Add entries as you encounter and solve issues. Use the Symptom -> Diagnosis -> Fix format.*'

LINT_LANGUAGES="YAML (syntax validation), JSON, Shell (shellcheck)"
