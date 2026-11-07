# Makes the kind cluster reachable from Windows on 127.0.0.1.
# Re-run after every Podman machine restart (the node IP can change).
#
#   Windows 127.0.0.1:PORT --(WSL relay)--> socat in VM (real listener) --> kind node IP:PORT
#
. "$PSScriptRoot\env.ps1"
$ports = 6443, 30443, 30080, 30088, 30746   # API, Argo CD UI, payment-api, dev-guide, Argo Workflows UI
$node  = "$env:CLUSTER_NAME-control-plane"

$nodeIp = podman inspect $node --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}"
if (-not $nodeIp) { throw "node container $node not found or not running" }
Write-Host "kind node IP: $nodeIp"

$cmd = ($ports | ForEach-Object { "socat TCP-LISTEN:$($_),fork,reuseaddr TCP:$($nodeIp):$($_) &" }) -join " "
podman rm -f capa-bridge 2>$null | Out-Null
podman run -d --name capa-bridge --network host --restart unless-stopped `
  --entrypoint sh docker.io/alpine/socat -c "$cmd wait" | Out-Null

# kind wrote a random API port into kubeconfig; point it at the bridge instead
kubectl config set-cluster "kind-$env:CLUSTER_NAME" --server="https://127.0.0.1:6443" | Out-Null

function TcpOk($port) {
  $c = New-Object System.Net.Sockets.TcpClient
  try { return $c.ConnectAsync("127.0.0.1", [int]$port).Wait(2000) -and $c.Connected } catch { return $false } finally { $c.Dispose() }
}
Start-Sleep -Seconds 3
if (-not (TcpOk 6443)) { throw "bridge started but 127.0.0.1:6443 is not reachable - run diag-network.ps1" }
kubectl cluster-info --context "kind-$env:CLUSTER_NAME"
