# Script to open SSIS package directly in Visual Studio
# Sometimes opening the package directly works when the project file has issues

$packagePath = "C:\RLCIntegration\RLCIntegration\RLCIntegration.dtsx"
$vsPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"

Write-Host "Opening SSIS package directly..." -ForegroundColor Cyan
Write-Host "Package: $packagePath" -ForegroundColor Gray
Write-Host ""

if (Test-Path $packagePath) {
    if (Test-Path $vsPath) {
        # Try opening the package file directly
        Start-Process -FilePath $vsPath -ArgumentList "`"$packagePath`""
        Write-Host "Package should open in Visual Studio" -ForegroundColor Green
    } else {
        # Try opening with default application
        Start-Process $packagePath
        Write-Host "Opening with default application..." -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: Package file not found at: $packagePath" -ForegroundColor Red
}

Write-Host ""
Write-Host "Alternative: In Visual Studio, go to:" -ForegroundColor Cyan
Write-Host "  File -> Open -> File" -ForegroundColor White
Write-Host "  Navigate to: $packagePath" -ForegroundColor White

