# WinSCP Integration with SSIS Package

## ✅ Package Updated

The SSIS package has been updated to use **WinSCP** instead of PowerShell/Renci.SshNet.dll.

## Changes Made

1. **Execute Process Task** renamed to **"Download Files from FTP"**
2. **Executable**: Now uses `C:\Program Files\WinSCP\WinSCP.com`
3. **Arguments**: Uses `/script="C:\RLC\winscp_download.txt"`
4. **Variables Added**:
   - `WinSCPPath` - Path to WinSCP.com
   - `WinSCPScriptPath` - Path to WinSCP script file
   - `WinSCP_Arguments` - Arguments for WinSCP command

## WinSCP Script

The WinSCP script is located at: `C:\RLC\winscp_download.txt`

**Current Content:**
```
option batch abort
option confirm off
open sftp://9pq09noto4lkjl0jqhrr3cp417dmx3:xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj@20.86.180.225:8922/
cd /
get *.CSV C:\RLC\
exit
```

## Installation Requirements

### On Each Client Machine:

1. **Install WinSCP:**
   - Download: https://winscp.net/eng/download.php
   - Install with default settings
   - WinSCP.com will be at: `C:\Program Files\WinSCP\WinSCP.com`

2. **Verify Script File:**
   - Ensure `C:\RLC\winscp_download.txt` exists
   - Or the package will use the static script

## Package Workflow

1. **Update Filename** → Generate filename
2. **Get the file name** → Get filename from database
3. **Extract data and load to csv** → (This step may need to be removed/changed for FTP download workflow)
4. **Download Files from FTP** → Downloads files using WinSCP
5. **Create Processed Files Table** → Creates tracking table
6. **Check for Duplicate File** → Checks if file already processed
7. **Create Table from Filename** → Creates RLC_Data table
8. **Load Data** → (Data Flow Task - needs to be configured)
9. **Record Processed File** → Marks file as processed

## Testing

**Test WinSCP manually:**
```powershell
& "C:\Program Files\WinSCP\WinSCP.com" /script="C:\RLC\winscp_download.txt"
```

**Test in SSIS:**
- Open package in Visual Studio
- Run the "Download Files from FTP" task
- Check `C:\RLC\` for downloaded files

## Advantages of WinSCP

✅ **No dependency issues** - Self-contained executable  
✅ **Reliable** - Widely used in enterprise  
✅ **Free** - No licensing costs  
✅ **Well-documented** - Extensive documentation available  
✅ **Error handling** - Better error messages than PowerShell  

## Notes

- The WinSCP script uses a static configuration
- For dynamic script generation, you can add a Script Task before the Execute Process Task
- WinSCP will download all files matching `*.CSV` pattern
- Files are downloaded to `C:\RLC\` directory

## Next Steps

1. Install WinSCP on client machines
2. Test the package
3. Configure the Data Flow Task to load downloaded CSV files into SQL Server
4. Deploy to production

