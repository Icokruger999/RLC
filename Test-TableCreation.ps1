# Test script to verify table creation on INT database
param(
    [string]$Server = "10.184.0.52",
    [string]$Database = "INT",
    [string]$Username = "RLC_INT_App",
    [string]$Password = "Exk15B97ky1zsvku"
)

$ErrorActionPreference = "Stop"

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Testing Table Creation on INT Database" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""
Write-Host "Server: $Server" -ForegroundColor Cyan
Write-Host "Database: $Database" -ForegroundColor Cyan
Write-Host "Username: $Username" -ForegroundColor Cyan
Write-Host ""

$connectionString = "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;TrustServerCertificate=True;"

try {
    # Test connection
    Write-Host "[1/4] Testing database connection..." -ForegroundColor Cyan
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "  Connected successfully!" -ForegroundColor Green
    $connection.Close()
    
    # Create RLC_ProcessedFiles table
    Write-Host ""
    Write-Host "[2/4] Creating RLC_ProcessedFiles table..." -ForegroundColor Cyan
    $processedFilesSQL = "IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RLC_ProcessedFiles') " +
        "BEGIN " +
        "CREATE TABLE [dbo].[RLC_ProcessedFiles] ( " +
        "[FileName] VARCHAR(255) PRIMARY KEY, " +
        "[ProcessedDate] DATETIME DEFAULT GETDATE(), " +
        "[TableName] VARCHAR(255) " +
        ") " +
        "PRINT 'RLC_ProcessedFiles table created successfully' " +
        "END " +
        "ELSE " +
        "BEGIN " +
        "PRINT 'RLC_ProcessedFiles table already exists' " +
        "END"
    
    $connection.Open()
    $command = New-Object System.Data.SqlClient.SqlCommand($processedFilesSQL, $connection)
    $command.ExecuteNonQuery() | Out-Null
    $connection.Close()
    Write-Host "  RLC_ProcessedFiles table ready" -ForegroundColor Green
    
    # Create RLC_Data table
    Write-Host ""
    Write-Host "[3/4] Creating RLC_Data table..." -ForegroundColor Cyan
    $dataTableSQL = "IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RLC_Data') " +
        "BEGIN " +
        "CREATE TABLE [dbo].[RLC_Data] ( " +
        "[StoreFormatCode] VARCHAR(50), " +
        "[StartDate] VARCHAR(10), " +
        "[EndDate] VARCHAR(10), " +
        "[RegionCode] VARCHAR(50), " +
        "[ProductCategoryCode] VARCHAR(50), " +
        "[RetailSalesExVAT] NUMERIC(38,2), " +
        "[RetailSalesUnits] NUMERIC(38,2), " +
        "[SourceFileName] VARCHAR(255), " +
        "[LoadDate] DATETIME DEFAULT GETDATE() " +
        ") " +
        "CREATE INDEX IX_RLC_Data_SourceFileName ON [dbo].[RLC_Data] ([SourceFileName]) " +
        "CREATE INDEX IX_RLC_Data_LoadDate ON [dbo].[RLC_Data] ([LoadDate]) " +
        "PRINT 'RLC_Data table created successfully' " +
        "END " +
        "ELSE " +
        "BEGIN " +
        "PRINT 'RLC_Data table already exists' " +
        "END"
    
    $connection.Open()
    $command = New-Object System.Data.SqlClient.SqlCommand($dataTableSQL, $connection)
    $command.ExecuteNonQuery() | Out-Null
    $connection.Close()
    Write-Host "  RLC_Data table ready" -ForegroundColor Green
    
    # Verify tables exist
    Write-Host ""
    Write-Host "[4/4] Verifying tables..." -ForegroundColor Cyan
    $verifySQL = "SELECT t.name AS TableName, " +
        "(SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) AS ColumnCount, " +
        "t.create_date AS CreatedDate " +
        "FROM sys.tables t " +
        "WHERE t.name IN ('RLC_Data', 'RLC_ProcessedFiles') " +
        "ORDER BY t.name"
    
    $connection.Open()
    $command = New-Object System.Data.SqlClient.SqlCommand($verifySQL, $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null
    $connection.Close()
    
    Write-Host ""
    Write-Host "Tables in database:" -ForegroundColor Yellow
    $dataset.Tables[0] | Format-Table -AutoSize
    
    # Check columns
    Write-Host ""
    Write-Host "RLC_Data table columns:" -ForegroundColor Yellow
    $columnsSQL = "SELECT c.name AS ColumnName, " +
        "t.name AS DataType, " +
        "c.max_length AS MaxLength, " +
        "c.precision AS Precision, " +
        "c.scale AS Scale, " +
        "CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END AS Nullable " +
        "FROM sys.columns c " +
        "INNER JOIN sys.types t ON c.user_type_id = t.user_type_id " +
        "WHERE c.object_id = OBJECT_ID('dbo.RLC_Data') " +
        "ORDER BY c.column_id"
    
    $connection.Open()
    $command = New-Object System.Data.SqlClient.SqlCommand($columnsSQL, $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null
    $connection.Close()
    
    $dataset.Tables[0] | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "All tables created and verified successfully!" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Cyan
    
} catch {
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Red
    Write-Host "ERROR: $_" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    Write-Host ("=" * 80) -ForegroundColor Red
    exit 1
}
