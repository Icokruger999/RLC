# Script to download all required dependencies for Renci.SshNet.dll
# Run this once to set up dependencies for automation

$ErrorActionPreference = "Stop"

$dependenciesPath = "C:\RLC\Dependencies"
$nugetUrl = "https://www.nuget.org/api/v2/package"

# Create dependencies directory
if (-not (Test-Path $dependenciesPath)) {
    New-Item -ItemType Directory -Path $dependenciesPath -Force | Out-Null
    Write-Host "Created directory: $dependenciesPath" -ForegroundColor Green
}

# List of required dependencies based on assembly references
$dependencies = @(
    @{ Name = "System.ValueTuple"; Version = "4.5.0"; Framework = "net461" },
    @{ Name = "Microsoft.Extensions.Logging.Abstractions"; Version = "8.0.0"; Framework = "net462" },
    @{ Name = "Microsoft.Bcl.AsyncInterfaces"; Version = "8.0.0"; Framework = "net462" },
    @{ Name = "System.Memory"; Version = "4.5.5"; Framework = "net461" },
    @{ Name = "BouncyCastle"; Version = "1.8.10"; Framework = "net40"; PackageName = "BouncyCastle" },
    @{ Name = "System.Formats.Asn1"; Version = "8.0.0"; Framework = "net462" },
    @{ Name = "System.Threading.Tasks.Extensions"; Version = "4.5.4"; Framework = "net461" },
    @{ Name = "System.Numerics.Vectors"; Version = "4.5.0"; Framework = "net461" },
    @{ Name = "System.Buffers"; Version = "4.5.1"; Framework = "net461" }
)

Write-Host "Downloading dependencies for Renci.SshNet.dll..." -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

foreach ($dep in $dependencies) {
    $packageName = if ($dep.PackageName) { $dep.PackageName } else { $dep.Name }
    $dllName = "$($dep.Name).dll"
    $targetPath = Join-Path $dependenciesPath $dllName
    
    if (Test-Path $targetPath) {
        Write-Host "[SKIP] $dllName already exists" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "[DOWNLOAD] $packageName v$($dep.Version)..." -ForegroundColor Cyan
    
    try {
        # Download NuGet package
        $packageUrl = "$nugetUrl/$packageName/$($dep.Version)"
        $zipPath = "$env:TEMP\$packageName.$($dep.Version).nupkg"
        
        Invoke-WebRequest -Uri $packageUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        
        # Extract DLL from package
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        
        # Look for DLL in lib folder
        $dllEntry = $zip.Entries | Where-Object {
            $_.FullName -like "lib\$($dep.Framework)\$dllName" -or
            $_.FullName -like "lib\netstandard2.0\$dllName" -or
            $_.FullName -like "lib\net462\$dllName" -or
            $_.FullName -like "lib\net461\$dllName" -or
            $_.FullName -like "lib\net40\$dllName"
        } | Select-Object -First 1
        
        if ($dllEntry) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($dllEntry, $targetPath, $true)
            Write-Host "[SUCCESS] Extracted $dllName" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Could not find $dllName in package" -ForegroundColor Yellow
        }
        
        $zip.Dispose()
        Remove-Item $zipPath -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[ERROR] Failed to download $packageName : $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Dependency download complete!" -ForegroundColor Green
Write-Host "Dependencies location: $dependenciesPath" -ForegroundColor Cyan

