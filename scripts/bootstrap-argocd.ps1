
param(
    [string]$GitOpsRepoPath
)

$ErrorActionPreference = "Stop"

# Default: assumes platform-infrastructure and platform-gitops
# are sibling folders under the same workspace directory.
if ([string]::IsNullOrWhiteSpace($GitOpsRepoPath)) {
    $WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $GitOpsRepoPath = Join-Path $WorkspaceRoot "platform-gitops"
}

$ApplicationsPath = Join-Path $GitOpsRepoPath "argocd"

# Confirm the correct EKS cluster context
$ExpectedCluster = "devops-portfolio-eks"
$Context = kubectl config current-context

if ($LASTEXITCODE -ne 0 -or $Context -notmatch [regex]::Escape($ExpectedCluster)) {
    throw "Wrong Kubernetes context. Select the devops-portfolio-eks cluster first."
}

# Validate GitOps Application manifests before installation
if (-not (Test-Path $ApplicationsPath -PathType Container)) {
    throw "GitOps Application directory not found: $ApplicationsPath"
}

$ApplicationFiles = @(
    Get-ChildItem $ApplicationsPath -Filter "*.yaml" -File |
    Sort-Object Name
)

if ($ApplicationFiles.Count -ne 6) {
    throw "Expected 6 Argo CD Application manifests, found $($ApplicationFiles.Count). Check: $ApplicationsPath"
}

Write-Host "Found $($ApplicationFiles.Count) Argo CD Application manifests."

# Retrieve the VPC ID from Terraform state
$TerraformPath = Join-Path (Split-Path -Parent $PSScriptRoot) "terraform"

Write-Host "Retrieving VPC ID from Terraform..."

$VpcId = terraform "-chdir=$TerraformPath" output -raw vpc_id

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($VpcId)) {
    throw "Could not retrieve VPC ID from Terraform state."
}

Write-Host "Using VPC ID: $VpcId"

# Install Argo CD
$Version = "v3.5.6"
$Manifest = "https://raw.githubusercontent.com/argoproj/argo-cd/$Version/manifests/install.yaml"

Write-Host "Creating Argo CD namespace..."

kubectl create namespace argocd --dry-run=client -o yaml |
    kubectl apply -f -

if ($LASTEXITCODE -ne 0) {
    throw "Namespace setup failed."
}

Write-Host "Installing Argo CD version $Version..."

kubectl apply --server-side --force-conflicts -n argocd -f $Manifest

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD installation failed."
}

# Wait for Argo CD deployments
Write-Host "Waiting for Argo CD deployments to become available..."

kubectl wait --for=condition=Available deployment --all `
    -n argocd --timeout=300s

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD deployments are not ready."
}

# Register all Argo CD Applications
Write-Host "Registering Argo CD Applications..."

foreach ($File in $ApplicationFiles) {
    Write-Host "Applying Application: $($File.Name)"

    kubectl apply -f $File.FullName

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to register Application: $($File.Name)"
    }

    if ($File.Name -eq "aws-load-balancer-controller.yaml") {
        Write-Host "Setting dynamic VPC ID in Helm parameters..."

        $Patch = @{
            spec = @{
                source = @{
                    helm = @{
                        parameters = @(
                            @{
                                name  = "aws-load-balancer-controller.vpcId"
                                value = $VpcId
                            }
                        )
                    }
                }
            }
        }

        $PatchJson = $Patch | ConvertTo-Json -Depth 10 -Compress

        kubectl patch application aws-load-balancer-controller `
            -n argocd `
            --type merge `
            --patch $PatchJson

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to configure VPC ID for AWS Load Balancer Controller."
        }

        Write-Host "AWS Load Balancer Controller configured with VPC ID: $VpcId"
    }
}

Write-Host ""
Write-Host "Argo CD bootstrap completed successfully."
Write-Host "All $($ApplicationFiles.Count) Applications have been registered."
