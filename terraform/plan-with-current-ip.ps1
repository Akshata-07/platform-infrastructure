$ErrorActionPreference = "Stop"

$PublicIP = (Invoke-RestMethod -Uri "https://checkip.amazonaws.com").Trim()
$CIDR = "$PublicIP/32"

Write-Host "Using current public IP: $CIDR" -ForegroundColor Green

terraform plan "-var=cluster_api_allowed_cidr=$CIDR"

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
