# Simplified script to get Renci.SshNet dependencies
# Uses NuGet CLI or direct download

param(
    [string]$OutputPath = "C:\RLC\Dependencies"
)

$ErrorActionPreference = "Stop"

Write-Host "Setting up Renci.SshNet dependencies..." -ForegroundColor Cyan
Write-Host "Output path: $OutputPath" -ForegroundColor Gray
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Check for NuGet CLI
$nugetCmd = Get-Command nuget -ErrorAction SilentlyContinue
$nugetPath = $null

if ($nugetCmd) {
    $nugetPath = $nugetCmd.Source
    Write-Host "Found NuGet CLI at: $nugetPath" -ForegroundColor Green
} else {
    Write-Host "NuGet CLI not found. Downloading it..." -ForegroundColor Yellow
    
    $nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $nugetExe = "$env:TEMP\nuget.exe"
    
    try {
        Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetExe -UseBasicParsing
        $nugetPath = $nugetExe
        Write-Host "Downloaded NuGet CLI" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download NuGet. Using alternative method..." -ForegroundColor Yellow
        $nugetPath = $null
    }
}

# List of critical dependencies
$packages = @(
    "System.ValueTuple/4.5.0",
    "System.Memory/4.5.5",
    "System.Buffers/4.5.1",
    "System.Threading.Tasks.Extensions/4.5.4",
    "Microsoft.Bcl.AsyncInterfaces/8.0.0",
    "Microsoft.Extensions.Logging.Abstractions/8.0.0",
    "System.Numerics.Vectors/4.1.4",
    "System.Formats.Asn1/8.0.0"
)

if ($nugetPath) {
    Write-Host "Using NuGet to download packages..." -ForegroundColor Cyan
    
    foreach ($package in $packages) {
        $parts = $package -split '/'
        $packageName = $parts[0]
        $version = $parts[1]
        
        Write-Host "  Downloading $packageName v$version..." -ForegroundColor Gray
        
        $tempDir = "$env:TEMP\NuGet_$packageName"
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
        
        try {
            # Download package
            & $nugetPath install $packageName -Version $version -OutputDirectory $tempDir -NoCache | Out-Null
            
            # Find and copy DLL
            $dll = Get-ChildItem -Path $tempDir -Recurse -Filter "$packageName.dll" | 
                Where-Object { $_.Directory.Name -match "net4[0-9]|netstandard" } | 
                Select-Object -First 1
            
            if ($dll) {
                Copy-Item $dll.FullName -Destination (Join-Path $OutputPath "$packageName.dll") -Force
                Write-Host "    ✓ $packageName.dll" -ForegroundColor Green
            } else {
                Write-Host "    ✗ DLL not found for $packageName" -ForegroundColor Yellow
            }
            
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "    ✗ Error: $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "NuGet not available. Please download dependencies manually:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Install .NET Framework 4.7.2 or later (includes most dependencies)" -ForegroundColor Cyan
    Write-Host "Option 2: Download from NuGet.org and extract DLLs to: $OutputPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Required packages:" -ForegroundColor Yellow
    foreach ($package in $packages) {
        Write-Host "  - $package" -ForegroundColor Gray
    }
}

# Special case: BouncyCastle (different package name)
Write-Host ""
Write-Host "Downloading BouncyCastle..." -ForegroundColor Cyan
try {
    $bcUrl = "https://www.nuget.org/api/v2/package/BouncyCastle/1.8.10"
    $bcZip = "$env:TEMP\BouncyCastle.zip"
    Invoke-WebRequest -Uri $bcUrl -OutFile $bcZip -UseBasicParsing
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($bcZip)
    $bcDll = $zip.Entries | Where-Object { $_.Name -eq "BouncyCastle.Crypto.dll" } | Select-Object -First 1
    
    if ($bcDll) {
        $bcPath = Join-Path $OutputPath "BouncyCastle.Cryptography.dll"
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($bcDll, $bcPath, $true)
        Write-Host "  ✓ BouncyCastle.Cryptography.dll" -ForegroundColor Green
    }
    
    $zip.Dispose()
    Remove-Item $bcZip -ErrorAction SilentlyContinue
} catch {
    Write-Host "  ✗ Failed to download BouncyCastle: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Dependency setup complete!" -ForegroundColor Green
Write-Host "Dependencies location: $OutputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Test the SFTP script to verify all dependencies load correctly" -ForegroundColor Yellow

