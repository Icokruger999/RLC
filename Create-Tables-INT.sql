-- SQL Script to create RLC tables in INT database
-- Run this script as a user with CREATE TABLE permissions (e.g., DBA or sysadmin)
-- Database: INT
-- Server: 10.184.0.52

USE [INT]
GO

-- Create RLC_ProcessedFiles table to track processed files
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RLC_ProcessedFiles' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE [dbo].[RLC_ProcessedFiles] (
        [FileName] VARCHAR(255) PRIMARY KEY,
        [ProcessedDate] DATETIME DEFAULT GETDATE(),
        [TableName] VARCHAR(255)
    )
    
    PRINT 'RLC_ProcessedFiles table created successfully'
END
ELSE
BEGIN
    PRINT 'RLC_ProcessedFiles table already exists'
END
GO

-- Create RLC_Data table to store all imported data
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RLC_Data' AND schema_id = SCHEMA_ID('dbo'))
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
    
    -- Create indexes for better query performance
    CREATE INDEX IX_RLC_Data_SourceFileName ON [dbo].[RLC_Data] ([SourceFileName])
    CREATE INDEX IX_RLC_Data_LoadDate ON [dbo].[RLC_Data] ([LoadDate])
    
    PRINT 'RLC_Data table created successfully'
END
ELSE
BEGIN
    PRINT 'RLC_Data table already exists'
END
GO

-- Grant permissions to RLC_INT_App user
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'RLC_INT_App')
BEGIN
    -- Grant SELECT, INSERT, UPDATE permissions
    GRANT SELECT, INSERT, UPDATE ON [dbo].[RLC_ProcessedFiles] TO [RLC_INT_App]
    GRANT SELECT, INSERT, UPDATE ON [dbo].[RLC_Data] TO [RLC_INT_App]
    
    PRINT 'Permissions granted to RLC_INT_App'
END
ELSE
BEGIN
    PRINT 'User RLC_INT_App not found - permissions not granted'
END
GO

-- Verify tables were created
SELECT 
    t.name AS TableName,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) AS ColumnCount,
    t.create_date AS CreatedDate
FROM sys.tables t
WHERE t.name IN ('RLC_Data', 'RLC_ProcessedFiles')
    AND t.schema_id = SCHEMA_ID('dbo')
ORDER BY t.name
GO

-- Show table structure
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLength,
    c.precision AS Precision,
    c.scale AS Scale,
    CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END AS Nullable
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name = 'RLC_Data'
    AND t.schema_id = SCHEMA_ID('dbo')
ORDER BY c.column_id
GO

