# RLC SFTP Script for SSIS Package
# Handles downloading files from SFTP server

param(
    [Parameter(Mandatory=$true)]
    [string]$LocalPath,
    
    [Parameter(Mandatory=$true)]
    [string]$Hostname,
    
    [Parameter(Mandatory=$true)]
    [int]$Port,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [string]$RemotePath = "/",
    
    [string]$RemoteFileName = "*.CSV",
    
    [ValidateSet("Download", "List")]
    [string]$Action = "Download"
)

$ErrorActionPreference = "Stop"

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

Write-Log "Starting SFTP operation: $Action" "INFO"
Write-Log "Host: $Hostname`:$Port" "INFO"
Write-Log "Remote Path: $RemotePath" "INFO"
Write-Log "Remote File Pattern: $RemoteFileName" "INFO"

# Method 1: Try WinSCP (Recommended - most reliable)
$winscpPath = "C:\Program Files\WinSCP\WinSCP.com"
if (Test-Path $winscpPath) {
    Write-Log "Using WinSCP command line" "INFO"
    
    try {
        # Create WinSCP script
        $scriptFile = "$env:TEMP\winscp_rlc_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
        
        if ($Action -eq "Download") {
            # Ensure local directory exists
            $localDir = Split-Path $LocalPath -Parent
            if (-not (Test-Path $localDir)) {
                New-Item -ItemType Directory -Path $localDir -Force | Out-Null
                Write-Log "Created directory: $localDir" "INFO"
            }
            
            $scriptContent = @"
option batch abort
option confirm off
open sftp://${Username}:${Password}@${Hostname}:${Port}/
cd $RemotePath
get $RemoteFileName $LocalPath
exit
"@
        } else {
            # List files
            $scriptContent = @"
option batch abort
option confirm off
open sftp://${Username}:${Password}@${Hostname}:${Port}/
ls $RemotePath
exit
"@
        }
        
        $scriptContent | Out-File -FilePath $scriptFile -Encoding ASCII -NoNewline
        
        # Execute WinSCP
        $logFile = "$env:TEMP\winscp_rlc_log_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
        $process = Start-Process -FilePath $winscpPath -ArgumentList "/script=$scriptFile","/log=$logFile" -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "SFTP operation completed successfully" "SUCCESS"
            
            if ($Action -eq "List" -and (Test-Path $logFile)) {
                Write-Log "Files on server:" "INFO"
                Get-Content $logFile | Select-String -Pattern "\.csv|\.CSV" | ForEach-Object {
                    Write-Log "  $_" "INFO"
                }
            }
            
            Remove-Item $scriptFile -ErrorAction SilentlyContinue
            Remove-Item $logFile -ErrorAction SilentlyContinue
            exit 0
        } else {
            if (Test-Path $logFile) {
                $errorContent = Get-Content $logFile -Raw
                Write-Log "WinSCP Error: $errorContent" "ERROR"
                Remove-Item $logFile -ErrorAction SilentlyContinue
            }
            throw "WinSCP exited with code: $($process.ExitCode)"
        }
    } catch {
        Write-Log "WinSCP failed: $_" "ERROR"
        Remove-Item $scriptFile -ErrorAction SilentlyContinue
        # Fall through to next method
    }
}

# Method 2: Try Renci.SshNet.dll (if available and dependencies are resolved)
$dllPaths = @(
    "C:\RLCIntegration\RLCIntegration\bin\Renci.SshNet.dll",
    "C:\RLCIntegration\RLCIntegration\bin\Development\Renci.SshNet.dll",
    "Renci.SshNet.dll"
)

foreach ($dllPath in $dllPaths) {
    if (Test-Path $dllPath) {
        try {
            Write-Log "Attempting to use Renci.SshNet.dll from: $dllPath" "INFO"
            [System.Reflection.Assembly]::LoadFrom($dllPath) | Out-Null
            
            $connectionInfo = New-Object Renci.SshNet.ConnectionInfo($Hostname, $Port, $Username, 
                (New-Object Renci.SshNet.PasswordAuthenticationMethod($Username, $Password)))
            
            $sftp = New-Object Renci.SshNet.SftpClient($connectionInfo)
            
            $sftp.Connect()
            Write-Log "Connected via Renci.SshNet" "SUCCESS"
            
            if ($Action -eq "Download") {
                # Download files
                $files = $sftp.ListDirectory($RemotePath)
                $downloaded = 0
                
                foreach ($file in $files) {
                    if (-not $file.IsDirectory -and $file.Name -like $RemoteFileName) {
                        $localFilePath = Join-Path (Split-Path $LocalPath -Parent) $file.Name
                        $stream = [System.IO.File]::Create($localFilePath)
                        $sftp.DownloadFile($file.FullName, $stream)
                        $stream.Close()
                        Write-Log "Downloaded: $($file.Name)" "SUCCESS"
                        $downloaded++
                    }
                }
                
                if ($downloaded -eq 0) {
                    Write-Log "No files matching pattern '$RemoteFileName' found" "WARNING"
                }
            } else {
                # List files
                $files = $sftp.ListDirectory($RemotePath)
                Write-Log "Files on server:" "INFO"
                foreach ($file in $files) {
                    if (-not $file.IsDirectory) {
                        Write-Log "  $($file.Name) - $([math]::Round($file.Length/1KB, 2)) KB - $($file.LastWriteTime)" "INFO"
                    }
                }
            }
            
            $sftp.Disconnect()
            exit 0
        } catch {
            Write-Log "Renci.SshNet failed: $_" "ERROR"
            continue
        }
    }
}

# If we get here, no method worked
Write-Log "ERROR: Could not connect to SFTP server" "ERROR"
Write-Log "Please install WinSCP from: https://winscp.net/eng/download.php" "ERROR"
Write-Log "Or ensure Renci.SshNet.dll dependencies are available" "ERROR"
exit 1

