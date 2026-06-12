# W9 Lab - GitOps, Observability, and Canary Release

This project demonstrates a GitOps-based delivery workflow on Kubernetes using ArgoCD, Prometheus, Alertmanager, and Argo Rollouts.

The main goal is to prove that application changes can be released safely:

```text
Git change
  -> ArgoCD sync
  -> Kubernetes rollout
  -> Prometheus observes metrics
  -> Argo Rollouts evaluates canary
  -> good version is promoted
  -> bad version is auto-aborted
  -> alert is sent to email when SLO is violated
```

## What This Project Covers

- GitOps deployment with ArgoCD.
- App-of-apps pattern with a root ArgoCD Application.
- Kubernetes manifests managed from Git.
- Prometheus/Grafana/Alertmanager installed through ArgoCD.
- Argo Rollouts canary deployment.
- Backend metrics exposed through `/metrics`.
- Prometheus `ServiceMonitor` for metric scraping.
- Prometheus `PrometheusRule` for SLO alerting.
- Alertmanager email notification.
- Canary auto-abort with `AnalysisTemplate`.
- Rollback through `git revert`.

## Architecture

```text
GitHub Repository
  -> ArgoCD root Application
  -> ArgoCD child Applications
      -> web app manifests
      -> kube-prometheus-stack
      -> argo-rollouts

User / Load
  -> frontend Service
  -> backend Service
  -> backend /metrics
  -> Prometheus scrape
  -> PrometheusRule alert
  -> Alertmanager email

Backend release
  -> Argo Rollouts canary
  -> AnalysisTemplate query Prometheus
  -> promote or abort
```

## Repository Structure

```text
cloud/w9/lab/
  README.md
  EVIDENCE.md
  PROJECT_VIVA_GUIDE.md
  gitops-lab-guide.md
  observability-canary-challenge-guide.md
  evidence/
    *.png
  gitops/
    app/
      backend/
      frontend/
    argocd/
      root.yaml
      apps/
        web.yaml
        kube-prometheus-stack.yaml
        argo-rollouts.yaml
    k8s/
      namespace.yaml
      web.yaml
      alertmanager-smtp-secret.example.yaml
```

## Main GitOps Applications

| Application | Purpose |
| --- | --- |
| `root` | App-of-apps root Application |
| `web` | Deploys workload and observability resources from `k8s/` |
| `api` | Deploys the Lab 3 API from `k8s-api/` |
| `kube-prometheus-stack` | Installs Prometheus, Grafana, Alertmanager, and operators |
| `argo-rollouts` | Installs Argo Rollouts controller and CRDs |

## Core Kubernetes Resources

The main workload and challenge resources are defined in:

```text
gitops/k8s/web.yaml
```

The Lab 3 API resources are defined in:

```text
gitops/k8s-api/api.yaml
gitops/k8s-api/servicemonitor.yaml
gitops/argocd/apps/api.yaml
```

Important resources:

- `Rollout/api`
- `Service/api`
- `ServiceMonitor/api`
- `Rollout/backend`
- `Rollout/frontend`
- `Service/backend`
- `Service/frontend`
- `ServiceMonitor/backend`
- `PrometheusRule/backend-slo-alerts`
- `AnalysisTemplate/backend-error-rate`

## SLO and Alert

The project uses a simple backend SLO:

```text
/api/order error rate must stay below 5%
```

The Prometheus query calculates:

```text
HTTP 5xx requests / total /api/order requests
```

If the error rate is greater than `0.05` for `1m`, Prometheus fires:

```text
BackendHighErrorRate
```

Alertmanager routes this alert to an email receiver.

## Canary Strategy

The backend uses Argo Rollouts canary steps:

```text
25% -> analysis -> 50% -> analysis -> 100%
```

The `AnalysisTemplate` queries Prometheus:

- If error rate is below 5%, the release continues.
- If error rate exceeds 5%, the release is aborted.

Good version:

```yaml
ERROR_RATE: "0"
```

Bad version:

```yaml
ERROR_RATE: "0.5"
```

## Verification Commands

Check ArgoCD Applications:

```powershell
kubectl -n argocd get applications
```

Check monitoring stack:

```powershell
kubectl -n monitoring get pods
```

Check Argo Rollouts:

```powershell
kubectl -n argo-rollouts get pods
```

Check demo resources:

```powershell
kubectl -n demo get rollouts.argoproj.io,svc,servicemonitor,prometheusrule,analysistemplate,pods
```

Check the Lab 3 API:

```powershell
kubectl -n argocd get app api
kubectl -n demo get rollout api,svc api,servicemonitor api
kubectl -n demo get pods -l app=api
```

Verify that Prometheus can see the API metric:

```promql
flask_http_request_total{namespace="demo"}
```

Check backend rollout:

```powershell
kubectl -n demo describe rollout backend
```

Check analysis results:

```powershell
kubectl -n demo get analysisrun
```

Open Prometheus:

```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Open Alertmanager:

```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093
```

## Evidence

Project screenshots and proof are documented in:

```text
EVIDENCE.md
```

Screenshots are stored in:

```text
evidence/
```

The evidence includes:

- ArgoCD Applications.
- Monitoring pods.
- Argo Rollouts controller.
- Demo namespace resources.
- Backend metrics.
- Prometheus query and alert rule.
- Good canary release.
- Bad canary auto-abort.
- Git revert rollback.
- Email alert received.

## Security Notes

Do not commit the real SMTP secret file:

```text
gitops/k8s/alertmanager-smtp-secret.yaml
```

Only commit the example file:

```text
gitops/k8s/alertmanager-smtp-secret.example.yaml
```

The real SMTP password should be stored as a Kubernetes Secret in the cluster.

## Final State

After demonstrating the bad canary and email alert, the backend was restored to a healthy release:

```yaml
VERSION: "v1.8.0"
ERROR_RATE: "0"
```

Expected final state:

```text
web Synced Healthy
backend Phase: Healthy
```
