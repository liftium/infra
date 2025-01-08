[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read environment argument or default to "dev"
$env = if ($args.Length -gt 0) { $args[0] } else { "dev" }

# Determine the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Move up one level to the project folder
$liftiumPath = Split-Path $scriptDir -Parent
Set-Location $liftiumPath

Write-Host "`n=== Building Docker images ===`n" -ForegroundColor Cyan

# Find all Dockerfiles in project folder (excluding infra)
$dockerfiles = Get-ChildItem -Path "." -Recurse -Filter "Dockerfile" -File |
    Where-Object { $_.FullName -notmatch '\\infra\\' }

if (-not $dockerfiles) {
    Write-Host "Error: No Dockerfiles found outside 'infra' folder." -ForegroundColor Red
    exit 1
}

# Build each Docker image
foreach ($df in $dockerfiles) {
    # Example: C:\...\Liftium\dispatcher\Liftium.Dispatcher\Dockerfile
    $fullDockerfilePath = $df.FullName
    # Dockerfile directory, e.g. C:\...\Liftium\dispatcher\Liftium.Dispatcher
    $dockerfileDir      = Split-Path $fullDockerfilePath -Parent
    # Context directory = one level above Dockerfile directory
    $contextDir         = Split-Path $dockerfileDir -Parent
    # Service name = the leaf folder (dispatcher, elevator, etc.)
    $svcName            = Split-Path $contextDir -Leaf
    # Docker image name and tag
    $imageName          = "liftium/$($svcName):$env"

    Write-Host "=============================================="
    Write-Host "  Dockerfile  : $fullDockerfilePath"
    Write-Host "  Context dir : $contextDir"
    Write-Host "  Service name: $svcName"
    Write-Host "  Image name  : $imageName"
    Write-Host "=============================================="

    docker build -t $imageName -f $fullDockerfilePath $contextDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to build Docker image for '$svcName'." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n=== Updating Helm dependencies ===`n" -ForegroundColor Blue

# 5. Define paths and variables for Helm
$chartPath   = Join-Path $liftiumPath 'infra\helm'
$releaseName = "liftium-$env"
$namespace   = "liftium-$env"
$valuesFile  = Join-Path $chartPath "values-$env.yaml"

# Verify chart and values file paths
if (-not (Test-Path $chartPath)) {
    Write-Host "Error: Helm chart path '$chartPath' not found." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $valuesFile)) {
    Write-Host "Error: Values file '$valuesFile' not found." -ForegroundColor Red
    exit 1
}

# Update Helm dependencies
helm dependency update $chartPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: 'helm dependency update' failed." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Deploying '$env' in namespace '$namespace' ===`n" -ForegroundColor Blue

# Perform helm upgrade/install
helm upgrade --install `
    $releaseName `
    $chartPath `
    --namespace $namespace `
    --create-namespace `
    -f $valuesFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: 'helm upgrade --install' failed." -ForegroundColor Red
    exit 1
}

# Success message
Write-Host "`n=== Deployment completed successfully. ===`n" -ForegroundColor Green
