# Use PSFTP to list files on SFTP server
$hostname = "20.86.180.225"
$port = 8922
$username = "9pq09noto4lkjl0jqhrr3cp417dmx3"
$password = "xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj"

$psftpPath = "$env:TEMP\psftp.exe"

if (-not (Test-Path $psftpPath)) {
    Write-Host "Downloading PSFTP..." -ForegroundColor Cyan
    try {
        $psftpUrl = "https://the.earth.li/~sgtatham/putty/latest/w64/psftp.exe"
        Invoke-WebRequest -Uri $psftpUrl -OutFile $psftpPath -UseBasicParsing
        Write-Host "PSFTP downloaded!" -ForegroundColor Green
    } catch {
        Write-Host "Error downloading PSFTP: $_" -ForegroundColor Red
        exit 1
    }
}

# Create command file for PSFTP
$cmdFile = "$env:TEMP\sftp_list.txt"
@"
open $hostname $port
$username
$password
ls
quit
"@ | Out-File -FilePath $cmdFile -Encoding ASCII -NoNewline

Write-Host ""
Write-Host "Connecting to SFTP server $hostname`:$port..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Run PSFTP with commands
$output = & $psftpPath -b $cmdFile 2>&1

# Display output
$output | ForEach-Object {
    if ($_ -match "\.(csv|CSV)") {
        Write-Host $_ -ForegroundColor Yellow
    } elseif ($_ -match "^-" -or $_ -match "total") {
        Write-Host $_ -ForegroundColor Gray
    } else {
        Write-Host $_
    }
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan

# Cleanup
Remove-Item $cmdFile -ErrorAction SilentlyContinue

