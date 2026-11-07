# Study plan — build phases mapped to courses and CAPA competencies

Courses:
- **KC** = KodeKloud *Certified Argo Project Associate (CAPA)*, ~9h — strongest on Workflows
- **OR** = O'Reilly *GitOps in Practice with Argo CD and Argo Rollouts* (LM Academy), ~9h — Argo CD + Rollouts
- **Docs** = official docs (needed for Argo Events, which neither course covers in depth)

Order follows what each phase needs: Argo CD first because it deploys everything else.
Each phase ends with a "can I explain it?" checklist, since the exam is multiple choice.

---

## Phase 0 — Local cluster (½ day)
- kind on Podman (Podman Desktop has a Kind extension; rootless Podman needs cgroup v2 delegation — test first)
- Install Argo CD by hand once (`kubectl apply`), open the UI, log in with the CLI
- Courses: KC *installation and setup*, OR setup section

## Phase 1 — payment-api + first Argo CD Application (Domain: Argo CD 34%)
Build: payment-api, a container image, Helm chart (Deployment for now), one `Application`.
- Courses: OR GitOps principles and Argo CD sections; KC *argo cd basics*, *gitops with argo*
- Explain it: the 4 GitOps principles (declarative, versioned/immutable, pulled automatically,
  continuously reconciled) · Application spec (`source`, `destination`, `project`, `syncPolicy`)
  · sync status vs health status (Synced/OutOfSync; Healthy/Progressing/Degraded/Missing/Suspended)
  · auto-sync, prune, self-heal · refresh vs hard refresh · Argo CD components
  (api-server, repo-server, application-controller, redis, dex)

## Phase 2 — Platform as code (still Argo CD)
Build: root app-of-apps, `ApplicationSet` for dev/prod, sync waves, PostSync smoke-test hook, `AppProject`.
- Courses: OR multi-env / Helm syncing sections
- Explain it: app-of-apps vs ApplicationSet · generators (list, cluster, git, matrix)
  · sync waves and hooks (PreSync, Sync, PostSync, SyncFail) · AppProject restrictions
  · RBAC basics · how Argo CD handles Helm (renders templates, does not use `helm install`)

## Phase 3 — Progressive delivery (Domain: Argo Rollouts 18%)
Build: change the chart's Deployment into a `Rollout`, canary + `AnalysisTemplate` on Prometheus,
release a bad version with `FAULT_RATE=0.3`, watch it roll back; then try blue-green.
- Courses: OR Blue-Green and Canary sections
- Explain it: canary vs blue-green · steps (`setWeight`, `pause`, `analysis`) · AnalysisTemplate vs
  AnalysisRun vs Experiment · background vs inline analysis · traffic routing providers
  (NGINX, Istio, ALB, SMI) · `kubectl argo rollouts promote / abort / retry`

## Phase 4 — The nightly settlement workflow (Domain: Argo Workflows 36% — biggest)
Build in small steps, each one a commit:
1. one-step workflow running `settlement-job --step=fetch` → KC *argo workflows architecture*
2. move it into a `WorkflowTemplate` → KC *workflow templates*
3. pass parameters and MinIO artifacts between steps → KC *parameters and artifacts*
4. full DAG with fan-out (`withParam`) and `when` → KC *dags in workflows*
5. exit handler, watch phases in the UI/CLI → KC *workflow execution and lifecycle*
6. `retryStrategy` on the flaky ledger step → KC *error handling and retries*
7. `CronWorkflow` for the nightly run
- Explain it: template types (container, script, resource, suspend, steps, dag)
  · Workflow vs WorkflowTemplate vs ClusterWorkflowTemplate vs CronWorkflow · `templateRef`
  · artifact repository config · input/output parameters and artifacts · steps vs DAG
  · `retryStrategy` (`limit`, `retryPolicy`, `backoff`) · `onExit` · workflow controller and
  argo-server · service account / RBAC for workflow pods

## Phase 5 — Event-driven start (Domain: Argo Events 12%)
Build: `EventBus` (JetStream), MinIO `EventSource`, `Sensor` that submits the WorkflowTemplate
with `fileKey` from the event. Upload a bank file → workflow starts.
- Courses: Docs (argoproj.github.io/argo-events)
- Explain it: EventSource → EventBus → Sensor → Trigger · dependencies and filters
  · trigger types (Argo Workflow, Kubernetes resource, HTTP) · parameterising a trigger from event data

## Phase 6 — Exam mode
- Finish both courses' quizzes, then 2–3 timed practice exams (90 min, 60 questions, 75% to pass)
- Re-read the weakest domain's docs; Workflows and Argo CD together are 70% of the score
