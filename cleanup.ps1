[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env = if ($args.Length -gt 0) { $args[0] } else { "dev" }

$releaseName = "liftium-$env"
$namespace = "liftium-$env"

function Remove-HelmReleases {
    param (
        [string]$namespace
    )

    Write-Host "Fetching Helm releases in namespace '$namespace'..." -ForegroundColor Blue
    $releases = helm list -n $namespace --short

    if (-not $releases) {
        Write-Host "No Helm releases found in namespace '$namespace'." -ForegroundColor Yellow
    } else {
        foreach ($release in $releases) {
            Write-Host "Deleting Helm release '$release'..." -ForegroundColor Blue
            helm uninstall $release -n $namespace
        }
    }
}

function Remove-K8sNamespace {
    param (
        [string]$namespace
    )

    Write-Host "Deleting all Kubernetes resources in namespace '$namespace'..." -ForegroundColor Blue
    kubectl delete all --all -n $namespace
    kubectl delete pvc --all -n $namespace
    kubectl delete configmap --all -n $namespace
    kubectl delete secret --all -n $namespace
}

Remove-HelmReleases -namespace $namespace
Remove-K8sNamespace -namespace $namespace

Write-Host "Deleting namespace '$namespace'..." -ForegroundColor Blue
kubectl delete namespace $namespace

Write-Host "Cleaning Helm cache and configuration for '$env'..." -ForegroundColor Blue
$repos = helm repo list --output json | ConvertFrom-Json
foreach ($repo in $repos) {
    if ($repo.name -match $env) {
        Write-Host "Removing Helm repo '$($repo.name)'" -ForegroundColor Blue
        helm repo remove $repo.name
    }
}

helm repo update
Remove-Item -Recurse -Force "$HOME\AppData\Local\helm" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$HOME\AppData\Roaming\helm" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$HOME\.config\helm" -ErrorAction SilentlyContinue

Write-Host "Cleanup for environment '$env' completed successfully." -ForegroundColor Green