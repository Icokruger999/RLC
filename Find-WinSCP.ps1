# Script to find WinSCP and update SSIS package path
Write-Host "Searching for WinSCP..." -ForegroundColor Cyan

# Common installation paths
$searchPaths = @(
    "C:\Program Files\WinSCP\WinSCP.com",
    "C:\Program Files (x86)\WinSCP\WinSCP.com",
    "$env:ProgramFiles\WinSCP\WinSCP.com",
    "${env:ProgramFiles(x86)}\WinSCP\WinSCP.com"
)

$winscpPath = $null

# Check common paths
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $winscpPath = $path
        Write-Host "Found WinSCP at: $winscpPath" -ForegroundColor Green
        break
    }
}

# If not found, search recursively
if (-not $winscpPath) {
    Write-Host "Not found in common locations. Searching..." -ForegroundColor Yellow
    $found = Get-ChildItem -Path "C:\Program Files" -Filter "WinSCP.com" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $winscpPath = $found.FullName
        Write-Host "Found WinSCP at: $winscpPath" -ForegroundColor Green
    }
}

if ($winscpPath) {
    Write-Host "" -ForegroundColor Green
    Write-Host "WinSCP found! Update the SSIS package variable 'WinSCPPath' to:" -ForegroundColor Cyan
    Write-Host "  $winscpPath" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Green
    Write-Host "Or run this command to update it automatically:" -ForegroundColor Cyan
    Write-Host "  (Get-Content 'RLCIntegration.dtsx') -replace 'C:\\Program Files\\WinSCP\\WinSCP.com', '$($winscpPath -replace '\\', '\\')' | Set-Content 'RLCIntegration.dtsx'" -ForegroundColor Yellow
} else {
    Write-Host "" -ForegroundColor Red
    Write-Host "WinSCP not found!" -ForegroundColor Red
    Write-Host "" -ForegroundColor Yellow
    Write-Host "Please install WinSCP:" -ForegroundColor Yellow
    Write-Host "  1. Download from: https://winscp.net/eng/download.php" -ForegroundColor Cyan
    Write-Host "  2. Install it (default location: C:\Program Files\WinSCP\)" -ForegroundColor Cyan
    Write-Host "  3. The package will then work automatically" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Yellow
    Write-Host "Or if WinSCP is installed elsewhere, update the 'WinSCPPath' variable in the SSIS package." -ForegroundColor Yellow
}

