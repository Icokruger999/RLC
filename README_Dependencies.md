# Renci.SshNet.dll Dependency Setup Guide

## Problem
Renci.SshNet.dll requires several .NET dependencies that may not be available in the SSIS runtime environment, causing "Could not load file or assembly" errors.

## Solution
We've created scripts to automatically download and resolve all required dependencies.

## Quick Setup (Recommended)

### Option 1: Automated Setup (Easiest)
Run the complete setup script:
```powershell
powershell -ExecutionPolicy Bypass -File "RLCIntegration\Setup-Automation.ps1"
```

This will:
1. Create required directories
2. Copy Renci.SshNet.dll
3. Download all dependencies
4. Install the SFTP script

### Option 2: Manual Dependency Download
If automated setup fails, download dependencies manually:

```powershell
powershell -ExecutionPolicy Bypass -File "RLCIntegration\Get-RenciDependencies.ps1"
```

## Required Dependencies

The following DLLs must be in `C:\RLC\Dependencies\`:

1. **System.ValueTuple.dll** (v4.5.0)
2. **System.Memory.dll** (v4.5.5)
3. **System.Buffers.dll** (v4.5.1)
4. **System.Threading.Tasks.Extensions.dll** (v4.5.4)
5. **Microsoft.Bcl.AsyncInterfaces.dll** (v8.0.0)
6. **Microsoft.Extensions.Logging.Abstractions.dll** (v8.0.0)
7. **System.Numerics.Vectors.dll** (v4.1.4)
8. **System.Formats.Asn1.dll** (v8.0.0)
9. **BouncyCastle.Cryptography.dll** (v2.0.0)

## Alternative: Install .NET Framework 4.7.2+

Many dependencies are included with .NET Framework 4.7.2 or later:
- Download: https://dotnet.microsoft.com/download/dotnet-framework
- Install .NET Framework 4.7.2 or later
- This includes most System.* dependencies

## How It Works

The updated `RLC_SFTP.ps1` script:
1. Registers an `AssemblyResolve` event handler
2. Automatically loads dependencies from `C:\RLC\Dependencies\`
3. Falls back gracefully if dependencies are missing

## File Structure After Setup

```
C:\RLC\
├── RLC_SFTP.ps1                    # Main SFTP script
├── Renci.SshNet.dll                # SFTP library
└── Dependencies\
    ├── System.ValueTuple.dll
    ├── System.Memory.dll
    ├── System.Buffers.dll
    ├── System.Threading.Tasks.Extensions.dll
    ├── Microsoft.Bcl.AsyncInterfaces.dll
    ├── Microsoft.Extensions.Logging.Abstractions.dll
    ├── System.Numerics.Vectors.dll
    ├── System.Formats.Asn1.dll
    └── BouncyCastle.Cryptography.dll
```

## Testing

After setup, test the connection:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\RLC\RLC_SFTP.ps1" `
    -Action List `
    -LocalPath "C:\RLC\" `
    -Hostname "20.86.180.225" `
    -Port 8922 `
    -Username "9pq09noto4lkjl0jqhrr3cp417dmx3" `
    -Password "xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj"
```

## Troubleshooting

### Error: "Could not load file or assembly"
- Ensure all dependencies are in `C:\RLC\Dependencies\`
- Check that DLL versions match requirements
- Verify .NET Framework 4.7.2+ is installed

### Error: "The type or namespace name 'Renci' could not be found"
- Verify Renci.SshNet.dll is in `C:\RLC\`
- Check that the script can find the DLL path

### Dependencies won't download
- Install NuGet CLI manually: https://www.nuget.org/downloads
- Or download packages manually from https://www.nuget.org
- Extract DLLs from .nupkg files (they're ZIP files)

## For SSIS Deployment

When deploying to client machines:
1. Copy entire `C:\RLC\` folder structure
2. Ensure .NET Framework 4.7.2+ is installed
3. Test the script manually before running SSIS package
4. Verify all DLLs are in the Dependencies folder

## Manual Download Links

If automated download fails, get packages from NuGet:
- https://www.nuget.org/packages/System.ValueTuple/
- https://www.nuget.org/packages/System.Memory/
- https://www.nuget.org/packages/System.Buffers/
- https://www.nuget.org/packages/System.Threading.Tasks.Extensions/
- https://www.nuget.org/packages/Microsoft.Bcl.AsyncInterfaces/
- https://www.nuget.org/packages/Microsoft.Extensions.Logging.Abstractions/
- https://www.nuget.org/packages/System.Numerics.Vectors/
- https://www.nuget.org/packages/System.Formats.Asn1/
- https://www.nuget.org/packages/BouncyCastle/

Download the .nupkg file, rename to .zip, extract, and find DLLs in `lib\net461\` or `lib\net462\` folder.

