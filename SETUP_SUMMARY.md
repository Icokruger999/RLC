# RLC SFTP Automation Setup - Summary

## Current Status

✅ **Completed:**
- Created `RLC_SFTP.ps1` script with dependency resolution
- Set up directory structure (`C:\RLC\` and `C:\RLC\Dependencies\`)
- Copied Renci.SshNet.dll to `C:\RLC\`
- Registered AssemblyResolve event handler

⚠️ **Issue:**
- Renci.SshNet.dll requires .NET Standard dependencies that aren't automatically resolved
- Missing dependencies: Microsoft.Extensions.Logging.Abstractions, Microsoft.Bcl.AsyncInterfaces, etc.

## Recommended Solution for Client Machines

### Option 1: Use WinSCP (RECOMMENDED - No Dependencies)

**Pros:**
- No dependency issues
- Reliable and well-tested
- Free for commercial use
- Works perfectly with SSIS

**Steps:**
1. Download WinSCP: https://winscp.net/eng/download.php
2. Install on client machine
3. Update SSIS package to use WinSCP.com instead of PowerShell script

**SSIS Configuration:**
```
Executable: C:\Program Files\WinSCP\WinSCP.com
Arguments: /script=C:\RLC\winscp_download.txt
```

**WinSCP Script (`C:\RLC\winscp_download.txt`):**
```
option batch abort
option confirm off
open sftp://9pq09noto4lkjl0jqhrr3cp417dmx3:xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj@20.86.180.225:8922/
get *.CSV C:\RLC\
exit
```

### Option 2: Fix Renci.SshNet Dependencies

**For .NET Framework 4.8 (Current System):**

The missing dependencies are .NET Standard packages. You need to:

1. **Install .NET Standard 2.0 Support:**
   - Download: https://dotnet.microsoft.com/download/dotnet-framework/net48
   - Install .NET Framework 4.8 Developer Pack

2. **Manually Download Dependencies:**
   - Go to https://www.nuget.org
   - Download these packages and extract DLLs:
     - Microsoft.Extensions.Logging.Abstractions (v8.0.0)
     - Microsoft.Bcl.AsyncInterfaces (v8.0.0)
     - System.Formats.Asn1 (v8.0.0)
   - Place DLLs in `C:\RLC\Dependencies\`

3. **Or Use NuGet Package Manager:**
   ```powershell
   # Install NuGet CLI
   # Then run:
   nuget install Microsoft.Extensions.Logging.Abstractions -Version 8.0.0 -OutputDirectory C:\RLC\Dependencies
   nuget install Microsoft.Bcl.AsyncInterfaces -Version 8.0.0 -OutputDirectory C:\RLC\Dependencies
   nuget install System.Formats.Asn1 -Version 8.0.0 -OutputDirectory C:\RLC\Dependencies
   ```

## Current File Structure

```
C:\RLC\
├── RLC_SFTP.ps1              ✅ Installed (with dependency resolution)
├── Renci.SshNet.dll          ✅ Installed
└── Dependencies\             ⚠️  Empty (needs DLLs)
```

## Testing

**Test WinSCP (if installed):**
```powershell
& "C:\Program Files\WinSCP\WinSCP.com" /script=C:\RLC\winscp_download.txt
```

**Test PowerShell Script:**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\RLC\RLC_SFTP.ps1" `
    -Action List `
    -LocalPath "C:\RLC\" `
    -Hostname "20.86.180.225" `
    -Port 8922 `
    -Username "9pq09noto4lkjl0jqhrr3cp417dmx3" `
    -Password "xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj"
```

## Recommendation

**For production automation on client machines, use WinSCP** because:
1. No dependency management needed
2. More reliable
3. Better error handling
4. Widely used in enterprise environments
5. Free and well-documented

The PowerShell/Renci.SshNet approach works but requires careful dependency management which can be problematic across different client environments.

## Next Steps

1. **If using WinSCP:** Update SSIS package to use WinSCP.com
2. **If using Renci.SshNet:** Download and place missing dependencies in `C:\RLC\Dependencies\`
3. Test the connection
4. Deploy to client machines

