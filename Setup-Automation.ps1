# Complete setup script for RLC SFTP automation
# Run this once on the client machine to set up all dependencies

$ErrorActionPreference = "Stop"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "RLC SFTP Automation Setup" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Step 1: Create directories
Write-Host "[1/4] Creating directories..." -ForegroundColor Cyan
$directories = @("C:\RLC", "C:\RLC\Dependencies")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists: $dir" -ForegroundColor Gray
    }
}

# Step 2: Copy Renci.SshNet.dll if needed
Write-Host ""
Write-Host "[2/4] Checking Renci.SshNet.dll..." -ForegroundColor Cyan
$sourceDll = "RLCIntegration\bin\Renci.SshNet.dll"
$targetDll = "C:\RLC\Renci.SshNet.dll"

if (Test-Path $sourceDll) {
    Copy-Item $sourceDll -Destination $targetDll -Force
    Write-Host "  Copied Renci.SshNet.dll to C:\RLC\" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Renci.SshNet.dll not found at $sourceDll" -ForegroundColor Yellow
    Write-Host "  Please ensure it's available" -ForegroundColor Yellow
}

# Step 3: Download dependencies
Write-Host ""
Write-Host "[3/4] Downloading dependencies..." -ForegroundColor Cyan
Write-Host "  This may take a few minutes..." -ForegroundColor Gray

$downloadScript = "RLCIntegration\Download-Dependencies.ps1"
if (Test-Path $downloadScript) {
    & powershell -ExecutionPolicy Bypass -File $downloadScript
} else {
    Write-Host "  WARNING: Download-Dependencies.ps1 not found" -ForegroundColor Yellow
    Write-Host "  Dependencies will need to be downloaded manually" -ForegroundColor Yellow
}

# Step 4: Copy SFTP script
Write-Host ""
Write-Host "[4/4] Installing SFTP script..." -ForegroundColor Cyan
$sftpScript = "RLCIntegration\RLC_SFTP_WithDependencies.ps1"
if (Test-Path $sftpScript) {
    Copy-Item $sftpScript -Destination "C:\RLC\RLC_SFTP.ps1" -Force
    Write-Host "  Installed RLC_SFTP.ps1" -ForegroundColor Green
} else {
    Write-Host "  WARNING: RLC_SFTP_WithDependencies.ps1 not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Files installed:" -ForegroundColor Yellow
Write-Host "  - C:\RLC\RLC_SFTP.ps1" -ForegroundColor White
Write-Host "  - C:\RLC\Renci.SshNet.dll" -ForegroundColor White
Write-Host "  - C:\RLC\Dependencies\*.dll" -ForegroundColor White
Write-Host ""
Write-Host "Test the connection:" -ForegroundColor Yellow
Write-Host '  powershell -ExecutionPolicy Bypass -File "C:\RLC\RLC_SFTP.ps1" -Action List -LocalPath "C:\RLC\" -Hostname "20.86.180.225" -Port 8922 -Username "9pq09noto4lkjl0jqhrr3cp417dmx3" -Password "xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj"' -ForegroundColor Gray
Write-Host ""

