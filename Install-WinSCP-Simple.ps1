# WinSCP Installation Helper Script
# This script will help you install WinSCP

Write-Host "WinSCP Installation Helper" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
$winscpPath = "C:\Program Files\WinSCP\WinSCP.com"
if (Test-Path $winscpPath) {
    Write-Host "WinSCP is already installed at: $winscpPath" -ForegroundColor Green
    exit 0
}

Write-Host "WinSCP is not installed." -ForegroundColor Yellow
Write-Host ""

# Check for downloaded installer
$downloads = Get-ChildItem "$env:USERPROFILE\Downloads\WinSCP*.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if ($downloads) {
    $installer = $downloads | Select-Object -First 1
    Write-Host "Found installer: $($installer.FullName)" -ForegroundColor Green
    Write-Host "Installing WinSCP..." -ForegroundColor Cyan
    
    $installPath = "C:\Program Files\WinSCP"
    Start-Process -FilePath $installer.FullName -ArgumentList "/SILENT", "/DIR=`"$installPath`"" -Wait -NoNewWindow
    
    Start-Sleep -Seconds 3
    
    if (Test-Path "$installPath\WinSCP.com") {
        Write-Host "WinSCP installed successfully!" -ForegroundColor Green
        Write-Host "Location: $installPath\WinSCP.com" -ForegroundColor Cyan
    } else {
        Write-Host "Installation may require manual completion." -ForegroundColor Yellow
        Write-Host "Please run the installer manually and select: C:\Program Files\WinSCP" -ForegroundColor Yellow
    }
} else {
    Write-Host "No installer found in Downloads folder." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Cyan
    Write-Host "1. Download WinSCP from: https://winscp.net/eng/download.php" -ForegroundColor White
    Write-Host "2. Save it to your Downloads folder" -ForegroundColor White
    Write-Host "3. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening download page..." -ForegroundColor Cyan
    Start-Process "https://winscp.net/eng/download.php"
}

