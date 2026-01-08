# WinSCP Download and Install Script
$downloadUrl = "https://winscp.net/eng/downloads/WinSCP-6.3.2-Setup.exe"
$installerPath = "$env:TEMP\WinSCP-Setup.exe"
$installPath = "C:\Program Files\WinSCP"

Write-Host "Downloading WinSCP..." -ForegroundColor Cyan
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "Downloaded successfully!" -ForegroundColor Green
    
    Write-Host "Installing WinSCP to: $installPath" -ForegroundColor Cyan
    Start-Process -FilePath $installerPath -ArgumentList "/SILENT /DIR=`"$installPath`"" -Wait -NoNewWindow
    
    if (Test-Path "$installPath\WinSCP.com") {
        Write-Host "WinSCP installed successfully!" -ForegroundColor Green
        Write-Host "Location: $installPath\WinSCP.com" -ForegroundColor Cyan
    } else {
        Write-Host "Installation may have completed. Please verify manually." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Please download manually from: https://winscp.net/eng/download.php" -ForegroundColor Yellow
}
