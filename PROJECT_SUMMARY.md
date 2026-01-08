# RLC Integration SSIS Package - Project Summary

## Project Overview
SSIS package for downloading CSV files from SFTP server and loading them into SQL Server INT database.

## Package Configuration

### Connection Managers
1. **10.64.1.101.RMS** - Source database (for getting file names)
   - Server: 10.64.1.101
   - Database: RMS
   - Authentication: Windows Integrated

2. **10.184.0.52.INT** - Target database (for loading data)
   - Server: 10.184.0.52
   - Database: INT
   - Username: RLC_INT_App
   - Password: Exk15B97ky1zsvku

3. **Flat File Connection Manager** - For reading downloaded CSV files
   - Path: `C:\RLC\` (dynamic based on filename)

### FTP/SFTP Configuration
- **Host**: 20.86.180.225
- **Port**: 8922
- **Protocol**: SFTP
- **Username**: 9pq09noto4lkjl0jqhrr3cp417dmx3
- **Password**: xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj
- **Remote Path**: /
- **File Pattern**: *.CSV
- **Local Download Path**: C:\RLC\

### Package Workflow
1. **Update Filename** - Generates timestamped filename
2. **Get the file name** - Retrieves filename from database
3. **Extract data and load to csv** - (May need to be removed/updated for FTP workflow)
4. **Download Files from FTP** - Downloads files using WinSCP
5. **Create Processed Files Table** - Creates tracking table if not exists
6. **Check for Duplicate File** - Checks if file was already processed
7. **Create Table from Filename** - Creates RLC_Data table if not exists
8. **Load Data** - (Data Flow Task - needs configuration)
9. **Record Processed File** - Marks file as processed

## Database Tables

### RLC_Data Table
Single table to store all imported data with source filename tracking:
- StoreFormatCode (VARCHAR(50))
- StartDate (VARCHAR(10))
- EndDate (VARCHAR(10))
- RegionCode (VARCHAR(50))
- ProductCategoryCode (VARCHAR(50))
- RetailSalesExVAT (NUMERIC(38,2))
- RetailSalesUnits (NUMERIC(38,2))
- SourceFileName (VARCHAR(255)) - **Tracks timestamped filename**
- LoadDate (DATETIME) - Auto-populated

**Indexes:**
- IX_RLC_Data_SourceFileName
- IX_RLC_Data_LoadDate

### RLC_ProcessedFiles Table
Tracks which files have been processed to prevent duplicates:
- FileName (VARCHAR(255)) - PRIMARY KEY
- ProcessedDate (DATETIME) - Auto-populated
- TableName (VARCHAR(255))

## Files Created

### SSIS Package
- `RLCIntegration.dtsx` - Main SSIS package

### SQL Scripts
- `Create-Tables-INT.sql` - SQL script to create tables in INT database

### PowerShell Scripts
- `RLC_SFTP.ps1` - SFTP download script (with dependency resolution)
- `Test-TableCreation.ps1` - Test table creation
- `Verify-Tables.ps1` - Verify tables exist
- `Check-Permissions.ps1` - Check user permissions
- `Setup-Automation.ps1` - Setup script for dependencies
- `Get-Dependencies-Simple.ps1` - Download dependencies
- `ListFTPFiles.ps1` - List files on FTP server

### Configuration Files
- `winscp_download.txt` - WinSCP script for downloading files

### Documentation
- `WinSCP_SSIS_Setup.md` - WinSCP integration guide
- `SETUP_SUMMARY.md` - Setup summary
- `README_Dependencies.md` - Dependency management guide
- `README_FTP_Access.md` - FTP access solutions

## Installation Requirements

### On Client Machines:
1. **WinSCP** (Required)
   - Download: https://winscp.net/eng/download.php
   - Install with default settings
   - Location: `C:\Program Files\WinSCP\WinSCP.com`

2. **SQL Server** - SSIS Runtime
   - SQL Server Integration Services must be installed

3. **Directory Structure**
   - `C:\RLC\` - For downloaded files
   - `C:\RLC\winscp_download.txt` - WinSCP script

### Database Setup:
1. Run `Create-Tables-INT.sql` as DBA/sysadmin
2. Tables will be created in INT database
3. Permissions granted to RLC_INT_App user

## Package Variables

### File Management
- `OutputFileName` - Generated filename (e.g., SD_20250814_12_21_20.CSV)
- `OutputFilePath` - Full path to file (C:\RLC\ + filename)

### FTP Configuration
- `SFTPHostname` - 20.86.180.225
- `SFTPPort` - 8922
- `SFTPUsername` - 9pq09noto4lkjl0jqhrr3cp417dmx3
- `SFTPPassword` - xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj
- `SFTPRemotePath` - /
- `SFTPRemoteFileName` - *.CSV

### WinSCP Configuration
- `WinSCPPath` - C:\Program Files\WinSCP\WinSCP.com
- `WinSCPScriptPath` - C:\RLC\winscp_download.txt
- `WinSCP_Arguments` - /script="C:\RLC\winscp_download.txt"

### Database
- `TableName` - RLC_Data (fixed table name)
- `SQLCreateTable` - SQL to create RLC_Data table
- `SQLCreateProcessedFilesTable` - SQL to create tracking table
- `SQLCheckDuplicate` - SQL to check for duplicate files
- `SQLInsertProcessedFile` - SQL to record processed file

## Testing

### Test FTP Connection:
```powershell
& "C:\Program Files\WinSCP\WinSCP.com" /script="C:\RLC\winscp_download.txt"
```

### Test Database Tables:
```powershell
powershell -ExecutionPolicy Bypass -File "RLCIntegration\Verify-Tables.ps1"
```

### Test Table Creation:
```powershell
powershell -ExecutionPolicy Bypass -File "RLCIntegration\Test-TableCreation.ps1"
```

## Deployment Checklist

- [ ] Install WinSCP on all client machines
- [ ] Create `C:\RLC\` directory on client machines
- [ ] Copy `winscp_download.txt` to `C:\RLC\`
- [ ] Run `Create-Tables-INT.sql` on INT database
- [ ] Verify tables exist using `Verify-Tables.ps1`
- [ ] Test FTP connection manually
- [ ] Deploy SSIS package to client machines
- [ ] Configure SSIS package connection strings
- [ ] Test end-to-end workflow

## Notes

- All files are loaded into a single `RLC_Data` table
- Source filename is stored in `SourceFileName` column
- Duplicate files are prevented using `RLC_ProcessedFiles` table
- WinSCP is used instead of PowerShell/Renci.SshNet to avoid dependency issues
- Package uses INT database on server 10.184.0.52

## Support Files Location

All project files are in: `C:\RLCIntegration\RLCIntegration\`

