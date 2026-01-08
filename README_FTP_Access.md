# FTP Server Access - Solutions

## Current Issue
The FTP server uses **SFTP (SSH File Transfer Protocol)** on port **8922**, which requires SSH/SFTP libraries. The Renci.SshNet.dll has dependency issues in the current environment.

## FTP Server Details
- **Host**: 20.86.180.225
- **Port**: 8922
- **Protocol**: SFTP (SSH File Transfer Protocol)
- **Username**: 9pq09noto4lkjl0jqhrr3cp417dmx3
- **Password**: xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj

## Recommended Solutions

### Option 1: WinSCP (Best for SSIS Integration)
**Free and works great with SSIS**

1. Download WinSCP: https://winscp.net/eng/download.php
2. Install it (includes command-line tool: `WinSCP.com`)
3. Use in SSIS Execute Process Task:
   ```
   Executable: C:\Program Files\WinSCP\WinSCP.com
   Arguments: /script=C:\RLC\winscp_download.txt
   ```

**WinSCP Script Example** (`winscp_download.txt`):
```
option batch abort
option confirm off
open sftp://9pq09noto4lkjl0jqhrr3cp417dmx3:xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj@20.86.180.225:8922/
get *.CSV C:\RLC\
exit
```

### Option 2: FileZilla (GUI Client - For Manual Checks)
**Free GUI client for testing**

1. Download: https://filezilla-project.org/
2. Connect using:
   - Host: `sftp://20.86.180.225`
   - Port: `8922`
   - Protocol: SFTP
   - Username: `9pq09noto4lkjl0jqhrr3cp417dmx3`
   - Password: `xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj`

### Option 3: Fix Renci.SshNet.dll Dependencies
**For PowerShell scripts**

The issue is missing dependencies. You need:
- Renci.SshNet.dll (already have)
- System.Security.Cryptography.Algorithms.dll
- System.Security.Cryptography.Primitives.dll
- System.IO.Compression.dll

**Solution**: Install .NET Framework 4.7.2 or later, or use the DLLs from a working environment.

### Option 4: Use Existing RLC_SFTP.ps1 Script
**If the script already exists**

The SSIS package references: `C:\RLC\RLC_SFTP.ps1`

1. Check if this script exists
2. If it does, it should already handle SFTP connections
3. You can modify it to add a "List" function to see files

**Example modification** to add listing:
```powershell
param(
    [string]$Action = "Download",  # Add "List" option
    [string]$Hostname,
    [int]$Port,
    [string]$Username,
    [string]$Password,
    [string]$RemotePath = "/",
    [string]$RemoteFileName = "*.CSV",
    [string]$LocalPath
)

# Add List action
if ($Action -eq "List") {
    # List files code here
}
```

## Quick Test Commands

### Using WinSCP (if installed):
```powershell
& "C:\Program Files\WinSCP\WinSCP.com" /script=C:\temp\list.txt
```

### Using FileZilla:
Just open FileZilla and connect with the credentials above.

## For SSIS Package

The package is already configured to use:
- PowerShell script: `C:\RLC\RLC_SFTP.ps1`
- Parameters: Hostname, Port, Username, Password, RemotePath, RemoteFileName, Action

**Next Steps**:
1. Ensure `C:\RLC\RLC_SFTP.ps1` exists and works
2. Or install WinSCP and update the package to use WinSCP.com instead
3. Test the connection manually first using one of the tools above

## Checking Files on Server

To see what files are on the server:
1. Use FileZilla to connect and browse
2. Or modify RLC_SFTP.ps1 to add a List function
3. Or use WinSCP command line with a list script

