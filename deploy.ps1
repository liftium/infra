[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env = if ($args.Length -gt 0) { $args[0] } else { "dev" }

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$chartPath = "$scriptPath\helm"
$releaseName = "liftium-$env"
$namespace = "liftium-$env"
$valuesFile = "$chartPath\values-$env.yaml"

if (-Not (Test-Path $valuesFile)) {
    Write-Host "Error: File $valuesFile not found." -ForegroundColor Red
    exit 1
}

Write-Host "Updating Helm dependencies..." -ForegroundColor Blue
helm dependency update $chartPath

Write-Host "Deploying environment '$env' in namespace '$namespace'..." -ForegroundColor Blue
helm upgrade --install $releaseName $chartPath --namespace $namespace --create-namespace -f $valuesFile

Write-Host "Deployment completed." -ForegroundColor Green
