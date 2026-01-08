# Check permissions and verify table creation SQL
param(
    [string]$Server = "10.184.0.52",
    [string]$Database = "INT",
    [string]$Username = "RLC_INT_App",
    [string]$Password = "Exk15B97ky1zsvku"
)

$connectionString = "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;TrustServerCertificate=True;"

Write-Host "Checking permissions for user: $Username" -ForegroundColor Cyan
Write-Host "Database: $Database" -ForegroundColor Cyan
Write-Host ""

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check if user has CREATE TABLE permission
    $permSQL = "SELECT HAS_PERMS_BY_NAME('$Database', 'DATABASE', 'CREATE TABLE') AS HasCreateTablePermission"
    $command = New-Object System.Data.SqlClient.SqlCommand($permSQL, $connection)
    $hasPermission = $command.ExecuteScalar()
    
    Write-Host "CREATE TABLE Permission: $hasPermission" -ForegroundColor $(if ($hasPermission -eq 1) { "Green" } else { "Red" })
    
    # Check if tables already exist
    $checkSQL = "SELECT name FROM sys.tables WHERE name IN ('RLC_Data', 'RLC_ProcessedFiles')"
    $command = New-Object System.Data.SqlClient.SqlCommand($checkSQL, $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null
    
    Write-Host ""
    Write-Host "Existing tables:" -ForegroundColor Cyan
    if ($dataset.Tables[0].Rows.Count -gt 0) {
        $dataset.Tables[0] | Format-Table -AutoSize
    } else {
        Write-Host "  No RLC tables found" -ForegroundColor Yellow
    }
    
    $connection.Close()
    
    Write-Host ""
    Write-Host "SQL to create tables (for manual execution):" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor Gray
    Write-Host @"

-- Create RLC_ProcessedFiles table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RLC_ProcessedFiles')
BEGIN
  CREATE TABLE [dbo].[RLC_ProcessedFiles] (
    [FileName] VARCHAR(255) PRIMARY KEY,
    [ProcessedDate] DATETIME DEFAULT GETDATE(),
    [TableName] VARCHAR(255)
  )
END

-- Create RLC_Data table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RLC_Data')
BEGIN
  CREATE TABLE [dbo].[RLC_Data] (
    [StoreFormatCode] VARCHAR(50),
    [StartDate] VARCHAR(10),
    [EndDate] VARCHAR(10),
    [RegionCode] VARCHAR(50),
    [ProductCategoryCode] VARCHAR(50),
    [RetailSalesExVAT] NUMERIC(38,2),
    [RetailSalesUnits] NUMERIC(38,2),
    [SourceFileName] VARCHAR(255),
    [LoadDate] DATETIME DEFAULT GETDATE()
  )
  
  CREATE INDEX IX_RLC_Data_SourceFileName ON [dbo].[RLC_Data] ([SourceFileName])
  CREATE INDEX IX_RLC_Data_LoadDate ON [dbo].[RLC_Data] ([LoadDate])
END
"@ -ForegroundColor White
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}

