# One-screen health check of the lab. Run after a reboot or whenever something looks wrong.
# Usage: .\local\status.ps1
. "$PSScriptRoot\env.ps1" | Out-Null
$script:bad = 0
function Ok($msg)   { Write-Host "[ ok ] $msg" -ForegroundColor Green }
function Bad($msg, $fix) { Write-Host "[FAIL] $msg" -ForegroundColor Red; if ($fix) { Write-Host "       fix: $fix" -ForegroundColor Yellow }; $script:bad++ }
function TcpOk($port) {
  $c = New-Object System.Net.Sockets.TcpClient
  try { return $c.ConnectAsync("127.0.0.1", [int]$port).Wait(2000) -and $c.Connected } catch { return $false } finally { $c.Dispose() }
}

# 1. Podman machine
$state = podman machine inspect --format "{{.State}} {{.Rootful}}" 2>$null
if ($state -eq "running true") { Ok "Podman machine running, rootful" }
else { Bad "Podman machine: '$state'" "podman machine start  (rootful: .\local\01-podman-rootful.ps1)" }

# 2. kind node container
$node = "$env:CLUSTER_NAME-control-plane"
$nodeIp = podman inspect $node --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" 2>$null
if ($nodeIp) { Ok "kind node container $node ($nodeIp)" } else { Bad "kind node container $node not running" "podman start $node" }

# 3. Bridge
$cmd = podman inspect capa-bridge --format "{{.Config.Cmd}} {{.State.Status}}" 2>$null
if (-not $cmd) { Bad "capa-bridge missing" ".\local\bridge.ps1" }
elseif ($cmd -notmatch "running") { Bad "capa-bridge not running" ".\local\bridge.ps1" }
elseif ($nodeIp -and $cmd -notmatch [regex]::Escape($nodeIp)) { Bad "capa-bridge points to an old node IP" ".\local\bridge.ps1" }
else { Ok "capa-bridge running -> $nodeIp" }

# 4. Kubernetes API
if (TcpOk 6443) {
  $ready = kubectl get nodes --no-headers 2>$null
  if ($ready -match " Ready ") { Ok "API 127.0.0.1:6443, node Ready" } else { Bad "API reachable but node not Ready: $ready" "kubectl describe node $node" }
} else { Bad "API 127.0.0.1:6443 not reachable" ".\local\bridge.ps1" }

# 5. Argo CD pods
$pods = kubectl -n argocd get pods --no-headers 2>$null
if (-not $pods) { Bad "no Argo CD pods" ".\local\03-install-argocd.ps1" }
else {
  $notReady = $pods | Where-Object { $_ -notmatch "\s(\d+)/\1\s+Running\s" }
  if ($notReady) { Bad "Argo CD pods not ready:`n       $($notReady -join "`n       ")" "kubectl -n argocd get pods; wait or check logs" }
  else { Ok "Argo CD pods: $(@($pods).Count) Running/Ready" }
}

# 6. Argo CD UI end to end (HTTPS through the bridge)
$svc = kubectl -n argocd get svc argocd-server -o jsonpath="{.spec.type}" 2>$null
if ($svc -ne "NodePort") { Bad "argocd-server is $svc, not NodePort" "kubectl -n argocd patch svc argocd-server --patch-file local\argocd-server-nodeport.yaml" }
else {
  $code = curl.exe -sk -o NUL -w "%{http_code}" --max-time 5 https://127.0.0.1:30443/healthz
  if ($code -eq "200") { Ok "Argo CD UI https://localhost:30443 (healthz 200)" } else { Bad "Argo CD UI answered '$code'" ".\local\bridge.ps1, then reload the browser" }
}

# 7. Applications
$apps = kubectl -n argocd get applications --no-headers -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status 2>$null
if ($apps) {
  foreach ($a in $apps) {
    if ($a -match "Synced\s+Healthy") { Ok "app $a" }
    else { Write-Host "[info] app $a   (OutOfSync/Missing = not synced yet: press SYNC)" -ForegroundColor Cyan }
  }
} else { Write-Host "[info] no Argo CD Applications yet" -ForegroundColor Cyan }

if ($script:bad -eq 0) { Write-Host "`nAll good." -ForegroundColor Green } else { Write-Host "`n$($script:bad) problem(s) - follow the 'fix' lines top to bottom." -ForegroundColor Red }
