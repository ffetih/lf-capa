# Settlement Lab — CAPA (Certified Argo Project Associate) study project

A small payment-settlement system used as a vehicle to learn all four Argo projects.
The Java code is intentionally small; the learning lives in `gitops/`.

| Exam domain        | Weight | Where it shows up in this repo                         |
|--------------------|--------|--------------------------------------------------------|
| Argo Workflows     | 36%    | `gitops/workflows/` — nightly reconciliation DAG       |
| Argo CD            | 34%    | `gitops/bootstrap/`, `gitops/apps/` — app-of-apps, dev/prod |
| Argo Rollouts      | 18%    | `gitops/charts/payment-api/` — canary + analysis       |
| Argo Events        | 12%    | `gitops/events/` — file drop in MinIO triggers workflow |

## Stack
- Java 25 (LTS), Spring Boot 4.1.x (move to 4.2 at GA — use that upgrade as a canary exercise)
- Local Kubernetes: kind on Podman (Windows, WSL-backed)
- MinIO (artifacts + acquirer files), Prometheus (Rollouts analysis), PostgreSQL

## Layout
```
services/
  payment-api/       REST service: authorize / capture / refund, exposes metrics
  settlement-job/    one image, several steps (--step=fetch|ledger|match|report)
gitops/
  bootstrap/         root Application (app-of-apps) — the only thing applied by hand
  apps/              child Applications + ApplicationSet (dev, prod)
  platform/          Argo Workflows, Events, Rollouts, MinIO, Prometheus, Postgres
  charts/payment-api Helm chart whose workload is a Rollout, not a Deployment
  workflows/         WorkflowTemplates, CronWorkflow
  events/            EventBus, EventSource, Sensor
local/               kind cluster config, helper scripts
docs/
  DOMAIN.md          what the system does
  STUDY-PLAN.md      build phases mapped to courses and exam competencies
```

> Study shortcut: one repo holds both code and manifests. In real GitOps you would
> usually split the *app repo* (code, CI builds images) from the *config repo* (what
> Argo CD watches). Know that distinction for the exam.
