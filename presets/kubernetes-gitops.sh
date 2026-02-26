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
│   ├── hooks/
│   │   └── lint-on-edit.sh
│   ├── memory/
│   │   ├── MEMORY.md
│   │   ├── cluster-state.md
│   │   ├── cilium-bpf.md
│   │   ├── infrastructure.md
│   │   ├── deploy-history.md
│   │   └── debugging.md
│   └── commands/
│       ├── review.md
│       ├── plan.md
│       ├── deploy-check.md
│       ├── cluster-health.md
│       └── validate-policies.md
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

# Memory topics: "filename|description" pairs
MEMORY_TOPICS="cluster-state.md|Current cluster health, node status, version info
cilium-bpf.md|BPF policy map rules, port mapping reference, incident history
infrastructure.md|Service versions, config state, operational notes
deploy-history.md|Deployment versions, rollback history, image tags
debugging.md|Common errors encountered and their solutions"

# Slash commands to scaffold
COMMANDS="review.md
plan.md
deploy-check.md
cluster-health.md
validate-policies.md"

# --- Substantive Rules Content ---

# shellcheck disable=SC2034
RULES_CONTENT_ARCHITECTURE='# Cluster Architecture

> **When to use:** Understanding cluster layout, planning new services, reviewing security boundaries.
>
> **Read first for:** Any task spanning multiple namespaces, new service design.

## Cluster Layout

```
Nodes: N control-plane + worker nodes
CNI: Cilium / Calico
Ingress: Ingress controller → Services
GitOps: ArgoCD / Flux watches git → applies to cluster
```

## Namespace Organization

| Namespace | Purpose |
|-----------|---------|
| `kube-system` | Core Kubernetes components |
| `argocd` | GitOps controller |
| `monitoring` | Metrics, logging, alerting |
| `cert-manager` | TLS certificate management |
| *app namespaces* | One namespace per application |

## Ingress Architecture

```
Internet → Ingress Controller → Service → Pods
```

- Each externally-accessible service gets an Ingress/HTTPRoute resource
- Internal services use ClusterIP (no external access)
- TLS termination at ingress controller

## Security Boundaries

- **Network:** Default-deny, explicit allow per service (NetworkPolicy/CiliumNetworkPolicy)
- **Admission:** Pod Security Standards enforced via admission controller
- **Secrets:** External secrets manager, never in git
- **Images:** Signed and scanned before deployment'

# shellcheck disable=SC2034
RULES_CONTENT_DEPLOYMENT_FLOW='# Deployment Flow

> **When to use:** Building and deploying code changes, troubleshooting builds.
>
> **Read first for:** Any deployment, CI/CD work, image build issues.

## GitOps Pipeline

```
Developer → git push → CI builds image → Push to registry → GitOps detects → Apply to cluster
```

### Steps
1. **Code change** — commit to service repo
2. **CI/CD build** — compile, test, build container image
3. **Image scan** — vulnerability scanning (fail on critical)
4. **Image sign** — cosign / Notary signature
5. **Push to registry** — internal or external registry
6. **GitOps sync** — ArgoCD/Flux detects new tag, applies manifests
7. **Admission control** — verify signature, check policies
8. **Rollout** — rolling update, health checks

## Deployment Checklist (New Service)

1. [ ] Kustomize/Helm manifests
2. [ ] ArgoCD Application / Flux Kustomization
3. [ ] NetworkPolicy / CiliumNetworkPolicy
4. [ ] DNS entry (if externally accessible)
5. [ ] Secrets in vault + ExternalSecret
6. [ ] Monitoring (ServiceMonitor / PodMonitor)
7. [ ] Build pipeline (CI workflow)

## Rollback

```bash
# ArgoCD
argocd app history <app-name>
argocd app rollback <app-name> <revision>

# Manual
kubectl set image deployment/<name> -n <ns> <container>=<registry>/<image>:<previous-tag>
```

## Troubleshooting Builds

```bash
# Check recent CI runs
# Check image exists in registry
# Verify image signature
# Check ArgoCD sync status
argocd app get <app-name>
```'

# shellcheck disable=SC2034
RULES_CONTENT_NETWORK_POLICIES='# Network Policies

> **When to use:** Adding or modifying network policies, debugging traffic blocks.
>
> **Read first for:** Any CiliumNetworkPolicy/NetworkPolicy change, connectivity issues.

## Default Posture

**Default-deny** for all egress and ingress. Every service needs an explicit policy.

## Required Egress for Every Service

Every service policy must allow:
- DNS: UDP+TCP port 53 to kube-dns in kube-system
- Admission webhooks (if applicable): TCP 443/9443 to webhook namespace

## Policy Template

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: <service>-policy
  namespace: <namespace>
spec:
  endpointSelector:
    matchLabels:
      app: <service>
  ingress:
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: <source-namespace>
      toPorts:
        - ports:
            - port: "<container-port>"  # Always container port, not service port
              protocol: TCP
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

## Critical Rules

| Rule | Reason |
|------|--------|
| **ALWAYS** use container port in `toPorts` | Cilium evaluates post-DNAT (pod port, not service port) |
| **AVOID** `toEntities: cluster` with `toPorts` | Creates ~19K BPF entries per port — causes map overflow |
| **USE** `toEndpoints` with namespace labels | Targeted entries, scales with KEDA/HPA |
| **AVOID** L7 DNS rules / `toFQDNs` | ~25K proxy redirect entries per endpoint |

## Verifying Policies

```bash
# Check for dropped traffic (Cilium)
hubble observe --verdict DROPPED -f

# Check BPF map pressure
cilium-dbg bpf policy get --all -o json | jq "to_entries | map({id: .key, count: (.value | length)}) | sort_by(-.count) | .[:5]"
```'

# shellcheck disable=SC2034
RULES_CONTENT_SECURITY_CONTROLS='# Security Controls

> **When to use:** Reviewing security posture, adding services, investigating security events.
>
> **Read first for:** Any security hardening, policy changes, admission control, runtime security.

## Active Controls

| Area | Tool | Mode |
|------|------|------|
| Pod Security | Kyverno / PSS | Enforce |
| Network | CiliumNetworkPolicy | Enforce |
| Image Scanning | Trivy | Continuous |
| Image Signing | cosign | Audit or Enforce |
| Secrets | External secrets manager | Enforce |
| TLS | cert-manager + internal CA | Enforce |

## Pod Security Standards

All workloads must:
- Run as non-root (`runAsNonRoot: true`)
- Drop ALL capabilities (`drop: ["ALL"]`)
- Use read-only root filesystem where possible
- Set `allowPrivilegeEscalation: false`
- Use `seccomp: RuntimeDefault`

## Image Policy

- Internal images: must be signed (cosign)
- Base images: use distroless or Chainguard
- No `:latest` tag — always pin to specific version or digest

## Secrets Management

- **NEVER** store secrets in git
- Use ExternalSecrets or sealed-secrets to sync from vault
- Rotate secrets on a schedule
- Mount secrets as volumes, not environment variables (when possible)

## Certificate Management

- Internal CA for service-to-service TLS
- cert-manager for automatic renewal
- Short-lived certificates (7 days recommended)
- Distribute CA trust bundle to all pods'

# shellcheck disable=SC2034
RULES_CONTENT_OBSERVABILITY='# Observability

> **When to use:** Debugging issues, adding instrumentation, querying logs/metrics/traces.
>
> **Read first for:** Any logging, monitoring, tracing, or alerting work.

## Three Pillars

| Pillar | Tool | Query |
|--------|------|-------|
| Metrics | Prometheus / VictoriaMetrics | PromQL |
| Logs | Loki / VictoriaLogs | LogQL / LogsQL |
| Traces | Tempo / Jaeger | TraceQL |

## Structured Logging

All services should emit JSON logs:
```json
{
  "timestamp": "2026-01-01T12:00:00Z",
  "level": "INFO",
  "message": "request completed",
  "service": "my-service",
  "trace_id": "abc123",
  "duration_ms": 45
}
```

**Never log:** passwords, tokens, PII, or sensitive data.

## Instrumenting a New Service

Add these environment variables to any deployment:
```yaml
env:
  - name: NODE_IP
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://$(NODE_IP):4317"
  - name: OTEL_SERVICE_NAME
    value: "<service-name>"
```

## Alerting

| Alert | Severity | Trigger |
|-------|----------|---------|
| PodCrashLooping | Critical | Pod restarted >3 times in 10min |
| HighErrorRate | Warning | >5% 5xx responses in 5min |
| CertExpiringSoon | Warning | TLS cert expires in <48h |
| NodeNotReady | Critical | Node not Ready for >5min |'

# shellcheck disable=SC2034
RULES_CONTENT_CROSS_SERVICE='# Cross-Service Conventions

> **When to use:** Ensuring consistency across services and manifests.
>
> **Read first for:** Naming standards, labels, resource limits, tagging.

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
```

## Resource Limits

Every container must have resource requests and limits:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Health Probes

Every deployment must define:
- `livenessProbe` — restart if unhealthy
- `readinessProbe` — remove from service if not ready
- `startupProbe` — for slow-starting applications

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 5
```'

LINT_LANGUAGES="YAML (syntax validation), JSON, Shell (shellcheck)"
