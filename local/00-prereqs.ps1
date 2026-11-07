# Checks every tool the lab needs and prints how to install what is missing.
# Usage: .\local\00-prereqs.ps1            (check only)
#        .\local\00-prereqs.ps1 -Install   (install missing ones with winget)
param([switch]$Install)
. "$PSScriptRoot\env.ps1"

$tools = @(
  @{ Name = "podman";  Winget = "RedHat.Podman";     Phase = 0 },
  @{ Name = "kind";    Winget = "Kubernetes.kind";   Phase = 0 },
  @{ Name = "kubectl"; Winget = "Kubernetes.kubectl";Phase = 0 },
  @{ Name = "argocd";  Winget = "argoproj.argocd";   Phase = 0 },
  @{ Name = "java";    Winget = $null;               Phase = 1 }
)

$missing = @()
foreach ($t in $tools) {
  $cmd = Get-Command $t.Name -ErrorAction SilentlyContinue
  if ($cmd) { Write-Host ("[ok]      {0,-8} {1}" -f $t.Name, $cmd.Source) -ForegroundColor Green }
  else {
    $hint = if ($t.Winget) { "winget install -e --id $($t.Winget)" } else { "install JDK 25 and fix JAVA_HOME in local/env.ps1" }
    Write-Host ("[missing] {0,-8} {1}" -f $t.Name, $hint) -ForegroundColor Red
    $missing += $t
  }
}

if ($missing.Count -gt 0 -and $Install) {
  foreach ($t in $missing | Where-Object { $_.Winget }) {
    winget install -e --id $t.Winget --accept-source-agreements --accept-package-agreements
  }
  . "$PSScriptRoot\env.ps1"   # reload PATH
  Write-Host "Installed. Re-run this script to verify."
  exit 0
}
if ($missing.Count -gt 0) { throw "Missing tools: $(($missing | ForEach-Object { $_.Name }) -join ', ') (re-run with -Install)" }

$rootless = podman info --format "{{.Host.Security.Rootless}}" 2>$null
if ($rootless -ne "false") { Write-Host "[todo]    Podman machine is rootless -> run 01-podman-rootful.ps1" -ForegroundColor Yellow }
else { Write-Host "[ok]      Podman machine is rootful" -ForegroundColor Green }
Write-Host "All tools present."
