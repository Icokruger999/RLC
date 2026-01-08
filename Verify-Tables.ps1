# Verify tables exist and show structure
param(
    [string]$Server = "10.184.0.52",
    [string]$Database = "INT",
    [string]$Username = "RLC_INT_App",
    [string]$Password = "Exk15B97ky1zsvku"
)

$connectionString = "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;TrustServerCertificate=True;"

Write-Host "Verifying tables in INT database..." -ForegroundColor Cyan
Write-Host ""

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check if tables exist
    $checkSQL = "SELECT t.name AS TableName, " +
        "(SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) AS ColumnCount, " +
        "t.create_date AS CreatedDate " +
        "FROM sys.tables t " +
        "WHERE t.name IN ('RLC_Data', 'RLC_ProcessedFiles') " +
        "AND t.schema_id = SCHEMA_ID('dbo') " +
        "ORDER BY t.name"
    
    $command = New-Object System.Data.SqlClient.SqlCommand($checkSQL, $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null
    
    if ($dataset.Tables[0].Rows.Count -eq 0) {
        Write-Host "WARNING: Tables not found!" -ForegroundColor Red
        Write-Host "Please run Create-Tables-INT.sql as a DBA/sysadmin user" -ForegroundColor Yellow
    } else {
        Write-Host "Tables found:" -ForegroundColor Green
        $dataset.Tables[0] | Format-Table -AutoSize
        
        # Show RLC_Data columns
        Write-Host ""
        Write-Host "RLC_Data table structure:" -ForegroundColor Cyan
        $columnsSQL = "SELECT c.name AS ColumnName, " +
            "ty.name AS DataType, " +
            "c.max_length AS MaxLength, " +
            "c.precision AS Precision, " +
            "c.scale AS Scale, " +
            "CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END AS Nullable " +
            "FROM sys.columns c " +
            "INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id " +
            "WHERE c.object_id = OBJECT_ID('dbo.RLC_Data') " +
            "ORDER BY c.column_id"
        
        $command = New-Object System.Data.SqlClient.SqlCommand($columnsSQL, $connection)
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        $dataset.Tables[0] | Format-Table -AutoSize
    }
    
    $connection.Close()
    Write-Host ""
    Write-Host "Verification complete!" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}

