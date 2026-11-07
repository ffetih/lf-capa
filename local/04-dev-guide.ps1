# Build the developer guide image and run it locally on http://localhost:8088
# Usage: .\local\04-dev-guide.ps1 [-Version 0.1.0] [-LoadIntoKind]
param(
  [string]$Version = "0.1.0",
  [switch]$LoadIntoKind
)
. "$PSScriptRoot\env.ps1"
$image = "localhost/settlement/dev-guide:$Version"
$context = Join-Path $PSScriptRoot "..\docs\dev-guide"

podman build -t $image -f "$context\Containerfile" $context
if ($LASTEXITCODE -ne 0) { throw "build failed" }

# Host network, not -p: rootful Podman on WSL only reaches Windows when a process really
# listens in the VM (see the troubleshooting chapter). nginx listens on 8088 itself.
podman rm -f dev-guide 2>$null | Out-Null
podman run -d --name dev-guide --network host $image
Write-Host "Guide: http://localhost:8088   (stop: podman rm -f dev-guide)"

if ($LoadIntoKind) {
  $tar = Join-Path $env:TEMP "dev-guide-$Version.tar"
  podman save $image -o $tar
  kind load image-archive $tar --name $env:CLUSTER_NAME
  Remove-Item $tar
  Write-Host "Loaded $image into kind cluster '$env:CLUSTER_NAME'"
}
