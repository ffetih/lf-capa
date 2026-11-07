# kind on Podman/WSL needs a ROOTFUL machine. Also give it enough memory for Argo + Prometheus.
podman machine stop
podman machine set --rootful --cpus 4 --memory 8192
podman machine start
podman info --format "rootless={{.Host.Security.Rootless}}  cgroup={{.Host.CgroupVersion}}"
