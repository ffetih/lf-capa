. "$PSScriptRoot\env.ps1"
kind create cluster --config "$PSScriptRoot\kind-config.yaml"
if ($LASTEXITCODE -ne 0) { throw "kind create cluster failed" }
& "$PSScriptRoot\bridge.ps1"
kubectl get nodes -o wide
