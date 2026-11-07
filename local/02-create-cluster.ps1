. "$PSScriptRoot\env.ps1"
kind create cluster --config "$PSScriptRoot\kind-config.yaml"
kubectl cluster-info --context kind-capa
kubectl get nodes -o wide
