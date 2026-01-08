# Simple dependency downloader - direct from NuGet packages
param(
    [string]$OutputPath = "C:\RLC\Dependencies"
)

$ErrorActionPreference = "Continue"

Write-Host "Downloading Renci.SshNet dependencies..." -ForegroundColor Cyan
Write-Host "Output: $OutputPath" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Download NuGet packages and extract DLLs
$packages = @{
    "System.ValueTuple" = "4.5.0"
    "System.Memory" = "4.5.5"
    "System.Buffers" = "4.5.1"
    "System.Threading.Tasks.Extensions" = "4.5.4"
    "Microsoft.Bcl.AsyncInterfaces" = "8.0.0"
    "Microsoft.Extensions.Logging.Abstractions" = "8.0.0"
    "System.Numerics.Vectors" = "4.1.4"
    "System.Formats.Asn1" = "8.0.0"
}

$baseUrl = "https://www.nuget.org/api/v2/package"

foreach ($packageName in $packages.Keys) {
    $version = $packages[$packageName]
    $dllName = "$packageName.dll"
    $targetPath = Join-Path $OutputPath $dllName
    
    if (Test-Path $targetPath) {
        Write-Host "[SKIP] $dllName" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "[DOWNLOAD] $packageName v$version..." -ForegroundColor Cyan
    
    try {
        $packageUrl = "$baseUrl/$packageName/$version"
        $zipPath = "$env:TEMP\$packageName.nupkg"
        
        Invoke-WebRequest -Uri $packageUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        
        # Try different framework folders
        $dllEntry = $null
        $folders = @("lib\net462", "lib\net461", "lib\netstandard2.0", "lib\net40")
        
        foreach ($folder in $folders) {
            $dllEntry = $zip.Entries | Where-Object { $_.FullName -eq "$folder\$dllName" } | Select-Object -First 1
            if ($dllEntry) { break }
        }
        
        if ($dllEntry) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($dllEntry, $targetPath, $true)
            Write-Host "  [OK] $dllName" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] DLL not found in package" -ForegroundColor Red
        }
        
        $zip.Dispose()
        Remove-Item $zipPath -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  [ERROR] $_" -ForegroundColor Red
    }
}

# BouncyCastle
Write-Host ""
Write-Host "[DOWNLOAD] BouncyCastle..." -ForegroundColor Cyan
try {
    $bcUrl = "$baseUrl/BouncyCastle/1.8.10"
    $bcZip = "$env:TEMP\BouncyCastle.nupkg"
    Invoke-WebRequest -Uri $bcUrl -OutFile $bcZip -UseBasicParsing
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($bcZip)
    $bcDll = $zip.Entries | Where-Object { $_.Name -eq "BouncyCastle.Crypto.dll" } | Select-Object -First 1
    
    if ($bcDll) {
        $bcPath = Join-Path $OutputPath "BouncyCastle.Cryptography.dll"
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($bcDll, $bcPath, $true)
        Write-Host "  [OK] BouncyCastle.Cryptography.dll" -ForegroundColor Green
    }
    
    $zip.Dispose()
    Remove-Item $bcZip -ErrorAction SilentlyContinue
} catch {
    Write-Host "  [ERROR] $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Complete! Check: $OutputPath" -ForegroundColor Green

