# Verify WinSCP Installation
Write-Host "Checking WinSCP installation..." -ForegroundColor Cyan

$winscpPath = "C:\Program Files\WinSCP\WinSCP.com"

if (Test-Path $winscpPath) {
    Write-Host "SUCCESS! WinSCP is installed!" -ForegroundColor Green
    Write-Host "Location: $winscpPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The SSIS package should now work correctly." -ForegroundColor Green
} else {
    Write-Host "WinSCP not found at: $winscpPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "1. WinSCP is installed" -ForegroundColor White
    Write-Host "2. Installation path is: C:\Program Files\WinSCP\" -ForegroundColor White
    Write-Host "3. WinSCP.com file exists in that folder" -ForegroundColor White
}

