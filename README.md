# Settlement Lab — CAPA study project

A small payment-settlement system used to learn all four Argo projects for the
Certified Argo Project Associate (CAPA) exam. The Java stays small; the learning lives in `gitops/`.

**Start here: the developer guide** — [`docs/dev-guide/index.adoc`](docs/dev-guide/index.adoc)
(renders on GitHub and in IntelliJ with the AsciiDoc plugin), or as a website:

```powershell
. .\local\env.ps1
.\local\04-dev-guide.ps1        # http://localhost:8088
```

| Exam domain    | Weight | Where in this repo |
|----------------|--------|--------------------|
| Argo Workflows | 36%    | `gitops/workflows/` |
| Argo CD        | 34%    | `gitops/bootstrap/`, `gitops/apps/` |
| Argo Rollouts  | 18%    | `gitops/charts/payment-api/` |
| Argo Events    | 12%    | `gitops/events/` |

Stack: Java 25, Spring Boot 4.1.x, kind on Podman, Argo CD v3.5.6.
