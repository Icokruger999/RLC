# Script to list files on FTP server
# This should be run in the SSIS execution environment where Renci.SshNet.dll is properly loaded

param(
    [string]$Hostname = "20.86.180.225",
    [int]$Port = 8922,
    [string]$Username = "9pq09noto4lkjl0jqhrr3cp417dmx3",
    [string]$Password = "xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj",
    [string]$RemotePath = "/"
)

# Try to load Renci.SshNet from common locations
$dllPaths = @(
    "C:\RLCIntegration\RLCIntegration\bin\Renci.SshNet.dll",
    "C:\RLCIntegration\RLCIntegration\bin\Development\Renci.SshNet.dll",
    "Renci.SshNet.dll",
    (Join-Path $PSScriptRoot "..\bin\Renci.SshNet.dll")
)

$dllLoaded = $false
foreach ($dllPath in $dllPaths) {
    if (Test-Path $dllPath) {
        try {
            [System.Reflection.Assembly]::LoadFrom($dllPath) | Out-Null
            $dllLoaded = $true
            Write-Host "Loaded DLL from: $dllPath" -ForegroundColor Green
            break
        } catch {
            continue
        }
    }
}

if (-not $dllLoaded) {
    Write-Host "ERROR: Could not load Renci.SshNet.dll" -ForegroundColor Red
    Write-Host "Please ensure Renci.SshNet.dll is available in one of these locations:" -ForegroundColor Yellow
    foreach ($path in $dllPaths) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
    exit 1
}

try {
    # Create connection
    $connectionInfo = New-Object Renci.SshNet.ConnectionInfo($Hostname, $Port, $Username, 
        (New-Object Renci.SshNet.PasswordAuthenticationMethod($Username, $Password)))
    
    $sftp = New-Object Renci.SshNet.SftpClient($connectionInfo)
    
    Write-Host "Connecting to $Hostname`:$Port..." -ForegroundColor Cyan
    $sftp.Connect()
    Write-Host "Connected successfully!" -ForegroundColor Green
    Write-Host ""
    
    # List files
    $files = $sftp.ListDirectory($RemotePath)
    
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "FILES ON FTP SERVER" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
    
    $csvFiles = @()
    $otherFiles = @()
    
    foreach ($file in $files) {
        if (-not $file.IsDirectory -and $file.Name -notmatch '^\.\.?$') {
            $fileInfo = [PSCustomObject]@{
                Name = $file.Name
                Size = $file.Length
                SizeKB = [math]::Round($file.Length / 1KB, 2)
                Modified = $file.LastWriteTime
            }
            
            if ($file.Name -match '\.(csv|CSV)$') {
                $csvFiles += $fileInfo
            } else {
                $otherFiles += $fileInfo
            }
        }
    }
    
    if ($csvFiles.Count -gt 0) {
        Write-Host "CSV FILES ($($csvFiles.Count)):" -ForegroundColor Green
        Write-Host ""
        foreach ($file in $csvFiles) {
            Write-Host "  File: $($file.Name)" -ForegroundColor Yellow
            Write-Host "    Size: $($file.SizeKB) KB ($($file.Size) bytes)"
            Write-Host "    Modified: $($file.Modified)"
            Write-Host ""
        }
    }
    
    if ($otherFiles.Count -gt 0) {
        Write-Host "OTHER FILES ($($otherFiles.Count)):" -ForegroundColor Cyan
        Write-Host ""
        foreach ($file in $otherFiles) {
            Write-Host "  File: $($file.Name)" -ForegroundColor Gray
            Write-Host "    Size: $($file.SizeKB) KB"
            Write-Host "    Modified: $($file.Modified)"
            Write-Host ""
        }
    }
    
    if ($csvFiles.Count -eq 0 -and $otherFiles.Count -eq 0) {
        Write-Host "No files found in directory." -ForegroundColor Yellow
    }
    
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "Total files: $($csvFiles.Count + $otherFiles.Count)" -ForegroundColor Green
    
    # Analyze filename patterns
    if ($csvFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "FILENAME PATTERN ANALYSIS:" -ForegroundColor Cyan
        Write-Host ""
        $patterns = @{}
        foreach ($file in $csvFiles) {
            # Check for timestamp patterns
            if ($file.Name -match '(\d{8})') {
                $datePattern = "YYYYMMDD"
                if (-not $patterns.ContainsKey($datePattern)) {
                    $patterns[$datePattern] = @()
                }
                $patterns[$datePattern] += $file.Name
            }
            if ($file.Name -match '(\d{4})[-_](\d{2})[-_](\d{2})') {
                $datePattern = "YYYY-MM-DD or YYYY_MM_DD"
                if (-not $patterns.ContainsKey($datePattern)) {
                    $patterns[$datePattern] = @()
                }
                $patterns[$datePattern] += $file.Name
            }
            if ($file.Name -match '(\d{2})[-_](\d{2})[-_](\d{2})') {
                $timePattern = "HH_MM_SS or HH-MM-SS"
                if (-not $patterns.ContainsKey($timePattern)) {
                    $patterns[$timePattern] = @()
                }
                $patterns[$timePattern] += $file.Name
            }
        }
        
        if ($patterns.Count -gt 0) {
            Write-Host "Detected patterns:" -ForegroundColor Yellow
            foreach ($pattern in $patterns.Keys) {
                Write-Host "  - $pattern : $($patterns[$pattern].Count) files" -ForegroundColor White
                Write-Host "    Example: $($patterns[$pattern][0])" -ForegroundColor Gray
            }
        }
    }
    
    $sftp.Disconnect()
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    exit 1
}

