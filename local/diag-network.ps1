# Diagnoses Windows -> Podman WSL VM -> kind container networking.
# Usage: .\local\diag-network.ps1   (paste the whole output when asking for help)
. "$PSScriptRoot\env.ps1"
$ErrorActionPreference = "Continue"

function Section($t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function TcpOk($port) { (Test-NetConnection 127.0.0.1 -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded }

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

Section "Experiment: which binding reaches Windows?"
podman rm -f probe-lo probe-any 2>$null | Out-Null
podman run -d --name probe-lo  -p 127.0.0.1:18080:80 docker.io/library/nginx:alpine | Out-Null
podman run -d --name probe-any -p 18081:80           docker.io/library/nginx:alpine | Out-Null
Start-Sleep -Seconds 5
Write-Host "published on 127.0.0.1 (18080) -> $(TcpOk 18080)"
Write-Host "published on 0.0.0.0   (18081) -> $(TcpOk 18081)"
podman rm -f probe-lo probe-any | Out-Null
