# Script to check files on FTP server
# This can be used in your SSIS package or run manually

param(
    [string]$Hostname = "20.86.180.225",
    [int]$Port = 8922,
    [string]$Username = "9pq09noto4lkjl0jqhrr3cp417dmx3",
    [string]$Password = "xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj",
    [string]$RemotePath = "/"
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "FTP SERVER FILE LISTING" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Server: $Hostname`:$Port" -ForegroundColor Cyan
Write-Host "Remote Path: $RemotePath" -ForegroundColor Cyan
Write-Host ""

# Method 1: Try WinSCP command line (winscp.com)
$winscpPath = "C:\Program Files\WinSCP\WinSCP.com"
if (Test-Path $winscpPath) {
    Write-Host "Using WinSCP command line..." -ForegroundColor Green
    
    $scriptContent = @"
option batch abort
option confirm off
open sftp://${Username}:${Password}@${Hostname}:${Port}/
ls $RemotePath
exit
"@
    
    $scriptFile = "$env:TEMP\winscp_list.txt"
    $scriptContent | Out-File -FilePath $scriptFile -Encoding ASCII
    
    & $winscpPath /script=$scriptFile /log=$env:TEMP\winscp_log.txt
    
    if (Test-Path "$env:TEMP\winscp_log.txt") {
        Write-Host ""
        Write-Host "Files found:" -ForegroundColor Green
        Get-Content "$env:TEMP\winscp_log.txt" | Select-String -Pattern "\.csv|\.CSV" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Yellow
        }
        Remove-Item "$env:TEMP\winscp_log.txt" -ErrorAction SilentlyContinue
    }
    
    Remove-Item $scriptFile -ErrorAction SilentlyContinue
    exit
}

# Method 2: Try using the existing RLC_SFTP.ps1 script if it exists
$rlcScript = "C:\RLC\RLC_SFTP.ps1"
if (Test-Path $rlcScript) {
    Write-Host "Found existing RLC_SFTP.ps1 script" -ForegroundColor Green
    Write-Host "You can modify it to list files instead of download" -ForegroundColor Yellow
    Write-Host "Script location: $rlcScript" -ForegroundColor Cyan
}

# Method 3: Suggest alternatives
Write-Host ""
Write-Host "RECOMMENDED SOLUTIONS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Install WinSCP (Free):" -ForegroundColor Cyan
Write-Host "   Download from: https://winscp.net/eng/download.php" -ForegroundColor White
Write-Host "   Then use: WinSCP.com command line tool" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Use FileZilla (Free GUI client):" -ForegroundColor Cyan
Write-Host "   Download from: https://filezilla-project.org/" -ForegroundColor White
Write-Host "   Connect with:" -ForegroundColor Gray
Write-Host "     Host: $Hostname" -ForegroundColor Gray
Write-Host "     Port: $Port" -ForegroundColor Gray
Write-Host "     Protocol: SFTP" -ForegroundColor Gray
Write-Host "     Username: $Username" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Use the existing RLC_SFTP.ps1 script:" -ForegroundColor Cyan
Write-Host "   Modify it to add a 'List' action that shows files" -ForegroundColor Gray
Write-Host ""
Write-Host "4. For SSIS Package:" -ForegroundColor Cyan
Write-Host "   The package already references: C:\RLC\RLC_SFTP.ps1" -ForegroundColor Gray
Write-Host "   Ensure this script exists and can list/download files" -ForegroundColor Gray
Write-Host ""

# Method 4: Try to use .NET FtpWebRequest (won't work for SFTP, but worth trying)
Write-Host "Note: Port $Port suggests SFTP (SSH File Transfer Protocol)" -ForegroundColor Yellow
Write-Host "Regular FTP tools won't work - you need SFTP/SSH support" -ForegroundColor Yellow
Write-Host ""

