. "$PSScriptRoot\env.ps1"
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts `
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/$env:ARGOCD_VERSION/manifests/install.yaml"
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

# Expose the UI on https://localhost:30443 through the kind port mapping
kubectl -n argocd patch svc argocd-server --type merge `
  -p '{"spec":{"type":"NodePort","ports":[{"name":"https","port":443,"targetPort":8080,"nodePort":30443}]}}'

$b64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
$adminPass = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
Write-Host "Argo CD UI : https://localhost:30443   user: admin   password: $adminPass"
Write-Host "Fallback   : kubectl -n argocd port-forward svc/argocd-server 8080:443  ->  https://localhost:8080"
