# Script to download PSFTP (PuTTY SFTP client) and use it to list files
$psftpUrl = "https://the.earth.li/~sgtatham/putty/latest/w64/psftp.exe"
$psftpPath = "$env:TEMP\psftp.exe"

Write-Host "Downloading PSFTP (PuTTY SFTP client)..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $psftpUrl -OutFile $psftpPath -UseBasicParsing
    Write-Host "PSFTP downloaded successfully!" -ForegroundColor Green
    Write-Host "Location: $psftpPath" -ForegroundColor Green
    
    # Create a command file for PSFTP
    $cmdFile = "$env:TEMP\sftp_commands.txt"
    @"
open 20.86.180.225 -P 8922
9pq09noto4lkjl0jqhrr3cp417dmx3
xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj
ls
quit
"@ | Out-File -FilePath $cmdFile -Encoding ASCII
    
    Write-Host ""
    Write-Host "Connecting to SFTP server..." -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    
    & $psftpPath -b $cmdFile
    
    Remove-Item $cmdFile -ErrorAction SilentlyContinue
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: You can manually download PSFTP from:" -ForegroundColor Yellow
    Write-Host "https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html" -ForegroundColor Cyan
}

