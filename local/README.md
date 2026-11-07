# Phase 0 — local cluster

Run in PowerShell from the repo root (if scripts are blocked:
`powershell -ExecutionPolicy Bypass -File .\local\<script>.ps1`).

| Step | Script                    | What it does |
|------|---------------------------|--------------|
| 0    | `00-prereqs.ps1`          | check tools; `-Install` installs missing ones with winget |
| 1    | `01-podman-rootful.ps1`   | switch the Podman machine to rootful (CPU/RAM come from WSL) |
| 2    | `02-create-cluster.ps1`   | kind cluster `capa` (one node, ports 30443/30080/30746) |
| 3    | `03-install-argocd.ps1`   | Argo CD v3.5.6, UI on https://localhost:30443, prints admin password |

Tools are checked by `00-prereqs.ps1` (winget ids: `Kubernetes.kind`, `Kubernetes.kubectl`, `argoproj.argocd`).

## Check it worked
```powershell
kubectl get pods -n argocd          # all Running
argocd login localhost:30443 --username admin --insecure
argocd version
```

## If ports are unreachable from Windows
Rootful Podman on WSL has broken port publishing on this machine before.
1. Try `kubectl -n argocd port-forward svc/argocd-server 8080:443` (uses the API server port only).
2. If `kubectl` itself cannot reach the API server, check `podman port capa-control-plane`
   and whether `127.0.0.1:<port>` answers; worst case run `kubectl`/`argocd` inside the
   machine: `wsl -d podman-machine-default`.

## Why Argo CD is installed by hand here
This is the "bootstrap" problem: something has to install the GitOps tool before GitOps can
manage anything. In Phase 2 Argo CD will start managing the rest of the platform (and could
manage itself) through the root app-of-apps.
