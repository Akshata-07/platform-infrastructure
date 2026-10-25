$ErrorActionPreference = "Stop"

$ExpectedCluster = "devops-portfolio-eks"
$Context = kubectl config current-context

if ($LASTEXITCODE -ne 0 -or $Context -notmatch [regex]::Escape($ExpectedCluster)) {
    throw "Wrong Kubernetes context. Select the devops-portfolio-eks cluster first."
}

$Version = "v3.5.6"
$Manifest = "https://raw.githubusercontent.com/argoproj/argo-cd/$Version/manifests/install.yaml"

kubectl create namespace argocd --dry-run=client -o yaml |
    kubectl apply -f -

if ($LASTEXITCODE -ne 0) {
    throw "Namespace setup failed."
}

kubectl apply --server-side --force-conflicts -n argocd -f $Manifest

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD installation failed."
}

kubectl wait --for=condition=Available deployment --all `
    -n argocd --timeout=300s

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD deployments are not ready."
}

Write-Host "Argo CD bootstrap completed."