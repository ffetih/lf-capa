# Diagnoses Windows -> Podman WSL VM -> kind container networking.
# Usage: .\local\diag-network.ps1   (paste the whole output when asking for help)
. "$PSScriptRoot\env.ps1"
$ErrorActionPreference = "Continue"

function Section($t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function TcpOk($port, $hostName = "127.0.0.1") {
  $c = New-Object System.Net.Sockets.TcpClient
  try { return $c.ConnectAsync($hostName, [int]$port).Wait(2000) -and $c.Connected } catch { return $false } finally { $c.Dispose() }
}

Section "Podman connections / machine"
podman system connection list
podman machine inspect --format "name={{.Name}} rootful={{.Rootful}} userModeNetworking={{.UserModeNetworking}} state={{.State}}"

Section "kind port mappings"
podman port capa-control-plane
$api = (podman port capa-control-plane 6443/tcp) -replace '.*:', ''
Write-Host "API server host port: $api"

Section "Listening inside the VM (hop 2)"
podman machine ssh "ss -ltnp | grep -E ':($api|30443|30080) '"

Section "API from inside the VM (hop 3)"
podman machine ssh "curl -sk -m 5 https://127.0.0.1:$api/version || echo FAILED"

Section "API from Windows (hop 1)"
Write-Host "127.0.0.1:$api -> $(TcpOk $api)"

Section "WSL config"
Get-Content "$env:USERPROFILE\.wslconfig" -ErrorAction SilentlyContinue
wsl --version

Section "Experiment: which path reaches Windows?"
$vmIp = (podman machine ssh "ip -4 -o addr show eth0" | Select-String -Pattern 'inet (\d+\.\d+\.\d+\.\d+)').Matches[0].Groups[1].Value
Write-Host "VM eth0 IP: $vmIp"
podman rm -f probe-any probe-host 2>$null | Out-Null
podman run -d --name probe-any  -p 18081:80 docker.io/library/nginx:alpine | Out-Null
podman run -d --name probe-host --network host docker.io/library/busybox httpd -f -p 0.0.0.0:18082 | Out-Null
Start-Sleep -Seconds 5
podman machine ssh "ss -ltnp | grep -E ':1808[12] ' || echo '(no listening sockets for 18081/18082)'"
Write-Host "A) published port via 127.0.0.1:18081 -> $(TcpOk 18081)"
Write-Host "B) published port via $($vmIp):18081   -> $(TcpOk 18081 $vmIp)"
Write-Host "C) real listener  via 127.0.0.1:18082 -> $(TcpOk 18082)"
Write-Host "D) kind API       via $($vmIp):$api    -> $(TcpOk $api $vmIp)"
podman rm -f probe-any probe-host | Out-Null
