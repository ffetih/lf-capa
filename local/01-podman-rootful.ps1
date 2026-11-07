# kind on Podman/WSL needs a ROOTFUL machine.
# CPU/memory are NOT set here: on WSL, `podman machine set --cpus/--memory` is QEMU-only.
# WSL machines get their resources from WSL itself (%UserProfile%\.wslconfig).
podman machine stop
podman machine set --rootful
if ($LASTEXITCODE -ne 0) { throw "podman machine set --rootful failed" }
podman machine start

$rootless = podman info --format "{{.Host.Security.Rootless}}"
podman info --format "rootless={{.Host.Security.Rootless}}  cgroup={{.Host.CgroupsVersion}}  cpus={{.Host.CPUs}}  mem={{.Host.MemTotal}}"
if ($rootless -ne "false") { throw "machine is still rootless - kind will not work" }
Write-Host "OK: rootful machine. Next: 02-create-cluster.ps1"
