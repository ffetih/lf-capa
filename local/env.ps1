# Dot-source in each new PowerShell session:  . .\local\env.ps1
$env:JAVA_HOME = "C:\Java\jdk-25.0.5.0.3"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:KIND_EXPERIMENTAL_PROVIDER = "podman"
$env:ARGOCD_VERSION = "v3.5.6"
$env:CLUSTER_NAME = "capa"
Write-Host "JAVA_HOME=$env:JAVA_HOME  kind provider=podman  Argo CD=$env:ARGOCD_VERSION"
java -version
