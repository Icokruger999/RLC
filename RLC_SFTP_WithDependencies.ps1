# RLC SFTP Script with Automatic Dependency Resolution
# This version automatically loads all required dependencies for Renci.SshNet.dll

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

# Function to resolve assembly dependencies
function Register-AssemblyResolver {
    param([string]$DependenciesPath)
    
    if (-not (Test-Path $DependenciesPath)) {
        Write-Log "Dependencies path not found: $DependenciesPath" "WARNING"
        return
    }
    
    # Register assembly resolver
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Reflection;

public class AssemblyResolver {
    private static string dependenciesPath;
    
    public static void Register(string path) {
        dependenciesPath = path;
        AppDomain.CurrentDomain.AssemblyResolve += CurrentDomain_AssemblyResolve;
    }
    
    private static Assembly CurrentDomain_AssemblyResolve(object sender, ResolveEventArgs args) {
        string assemblyName = new AssemblyName(args.Name).Name;
        string dllPath = Path.Combine(dependenciesPath, assemblyName + ".dll");
        
        if (File.Exists(dllPath)) {
            return Assembly.LoadFrom(dllPath);
        }
        
        return null;
    }
}
"@ -ReferencedAssemblies @("System.dll")
    
    [AssemblyResolver]::Register($DependenciesPath)
    Write-Log "Assembly resolver registered for: $DependenciesPath" "INFO"
}

# Set up dependency resolution
$dependenciesPath = "C:\RLC\Dependencies"
if (Test-Path $dependenciesPath) {
    Register-AssemblyResolver -DependenciesPath $dependenciesPath
} else {
    Write-Log "Dependencies directory not found. Creating it..." "WARNING"
    New-Item -ItemType Directory -Path $dependenciesPath -Force | Out-Null
    Write-Log "Please run Download-Dependencies.ps1 to download required DLLs" "WARNING"
}

# Find Renci.SshNet.dll
$dllPaths = @(
    "C:\RLCIntegration\RLCIntegration\bin\Renci.SshNet.dll",
    "C:\RLCIntegration\RLCIntegration\bin\Development\Renci.SshNet.dll",
    "RLCIntegration\bin\Renci.SshNet.dll",
    "Renci.SshNet.dll"
)

$dllPath = $null
foreach ($path in $dllPaths) {
    if (Test-Path $path) {
        $dllPath = (Resolve-Path $path).Path
        break
    }
}

if (-not $dllPath) {
    Write-Log "ERROR: Renci.SshNet.dll not found" "ERROR"
    Write-Log "Searched in: $($dllPaths -join ', ')" "ERROR"
    exit 1
}

Write-Log "Found Renci.SshNet.dll at: $dllPath" "INFO"
Write-Log "Starting SFTP operation: $Action" "INFO"
Write-Log "Host: $Hostname`:$Port" "INFO"
Write-Log "Remote Path: $RemotePath" "INFO"
Write-Log "Remote File Pattern: $RemoteFileName" "INFO"

try {
    # Load Renci.SshNet.dll
    Write-Log "Loading Renci.SshNet.dll..." "INFO"
    $assembly = [System.Reflection.Assembly]::LoadFrom($dllPath)
    Write-Log "Successfully loaded Renci.SshNet.dll" "SUCCESS"
    
    # Create connection
    $connectionInfo = New-Object Renci.SshNet.ConnectionInfo($Hostname, $Port, $Username, 
        (New-Object Renci.SshNet.PasswordAuthenticationMethod($Username, $Password)))
    
    $sftp = New-Object Renci.SshNet.SftpClient($connectionInfo)
    
    Write-Log "Connecting to SFTP server..." "INFO"
    $sftp.Connect()
    Write-Log "Connected successfully!" "SUCCESS"
    
    if ($Action -eq "Download") {
        # Ensure local directory exists
        $localDir = Split-Path $LocalPath -Parent
        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
            Write-Log "Created directory: $localDir" "INFO"
        }
        
        # Download files
        $files = $sftp.ListDirectory($RemotePath)
        $downloaded = 0
        
        foreach ($file in $files) {
            if (-not $file.IsDirectory -and $file.Name -like $RemoteFileName) {
                $localFilePath = if ($LocalPath -like "*.csv" -or $LocalPath -like "*.CSV") {
                    # If LocalPath is a specific file, use it
                    $LocalPath
                } else {
                    # If LocalPath is a directory, append filename
                    Join-Path $LocalPath $file.Name
                }
                
                $stream = [System.IO.File]::Create($localFilePath)
                $sftp.DownloadFile($file.FullName, $stream)
                $stream.Close()
                Write-Log "Downloaded: $($file.Name) -> $localFilePath" "SUCCESS"
                $downloaded++
            }
        }
        
        if ($downloaded -eq 0) {
            Write-Log "No files matching pattern '$RemoteFileName' found" "WARNING"
            exit 1
        } else {
            Write-Log "Successfully downloaded $downloaded file(s)" "SUCCESS"
        }
    } else {
        # List files
        $files = $sftp.ListDirectory($RemotePath)
        Write-Log "Files on server:" "INFO"
        Write-Log ("=" * 70) "INFO"
        
        $csvFiles = @()
        foreach ($file in $files) {
            if (-not $file.IsDirectory -and $file.Name -notmatch '^\.\.?$') {
                $fileInfo = [PSCustomObject]@{
                    Name = $file.Name
                    Size = [math]::Round($file.Length / 1KB, 2)
                    Modified = $file.LastWriteTime
                }
                
                if ($file.Name -like "*.csv" -or $file.Name -like "*.CSV") {
                    $csvFiles += $fileInfo
                }
                
                Write-Log "  $($file.Name) - $($fileInfo.Size) KB - $($fileInfo.Modified)" "INFO"
            }
        }
        
        Write-Log ("=" * 70) "INFO"
        if ($csvFiles.Count -gt 0) {
            Write-Log "Found $($csvFiles.Count) CSV file(s)" "SUCCESS"
        } else {
            Write-Log "No CSV files found" "WARNING"
        }
    }
    
    $sftp.Disconnect()
    Write-Log "Disconnected from server" "INFO"
    exit 0
    
} catch {
    Write-Log "ERROR: $_" "ERROR"
    if ($_.Exception.InnerException) {
        Write-Log "Inner Exception: $($_.Exception.InnerException.Message)" "ERROR"
    }
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}

