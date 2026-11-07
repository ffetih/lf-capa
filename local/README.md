# Phase 0 — local cluster

Run in PowerShell from the repo root (if scripts are blocked:
`powershell -ExecutionPolicy Bypass -File .\local\<script>.ps1`).

| Step | Script                    | What it does |
|------|---------------------------|--------------|
| 0    | `00-prereqs.ps1`          | check tools; `-Install` installs missing ones with winget |
| 1    | `01-podman-rootful.ps1`   | switch the Podman machine to rootful (CPU/RAM come from WSL) |
| 2    | `02-create-cluster.ps1`   | kind cluster `capa` + `bridge.ps1` (Windows access on 127.0.0.1) |
| 3    | `03-install-argocd.ps1`   | Argo CD v3.5.6, UI on https://localhost:30443, prints admin password |

Tools are checked by `00-prereqs.ps1` (winget ids: `Kubernetes.kind`, `Kubernetes.kubectl`, `argoproj.argocd`).

## Check it worked
```powershell
kubectl get pods -n argocd          # all Running
argocd login localhost:30443 --username admin --insecure
argocd version
```

## How Windows reaches the cluster (and after a reboot)
Rootful Podman on WSL publishes ports as kernel redirect rules with no listening process, and
WSL only relays ports where something is really listening. `bridge.ps1` runs a small socat
container (`capa-bridge`) on the VM's host network that listens on 6443 / 30443 / 30080 / 30088 / 30746
and forwards to the kind node.

```
Windows 127.0.0.1:6443 --(WSL relay)--> capa-bridge (socat) --> kind node :6443
```

After restarting the Podman machine or Windows: `.\local\bridge.ps1`.
If something still fails: `.\local\diag-network.ps1` and look at lines A-D.

## Why Argo CD is installed by hand here
This is the "bootstrap" problem: something has to install the GitOps tool before GitOps can
manage anything. In Phase 2 Argo CD will start managing the rest of the platform (and could
manage itself) through the root app-of-apps.
