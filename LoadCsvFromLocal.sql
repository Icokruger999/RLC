DECLARE @FileName VARCHAR(255);
DECLARE @FilePath VARCHAR(4000);

SET @FileName = ?;   -- Parameter 0 (User::OutputFileName)
SET @FilePath = ?;  

IF NOT EXISTS (SELECT 1 FROM dbo.RLC_ProcessedFiles WHERE FileName = @FileName)
BEGIN
    IF OBJECT_ID('tempdb..#RLC_CsvStage') IS NOT NULL
        DROP TABLE #RLC_CsvStage;

    CREATE TABLE #RLC_CsvStage
    (
        TradingYear             VARCHAR(50)  NULL,
        TradingMonth            VARCHAR(50)  NULL,
        TradingWeek             VARCHAR(50)  NULL,
        TradingMonthDescription VARCHAR(200) NULL,
        StoreFormatCodeCsv      VARCHAR(50)  NULL,
        RegionCodeCsv           VARCHAR(50)  NULL,
        ProductCategoryCodeCsv  VARCHAR(50)  NULL,
        RetailSalesExVATCsv     VARCHAR(50)  NULL,
        RetailSalesUnitsCsv     VARCHAR(50)  NULL,
        MarketSalesCsv          VARCHAR(50)  NULL,
        MarketSalesUnitsCsv     VARCHAR(50)  NULL
    );

    DECLARE @Sql NVARCHAR(MAX) =
    N'BULK INSERT #RLC_CsvStage
      FROM ''' + REPLACE(@FilePath, '''', '''''') + N'''
      WITH
      (
          FIRSTROW = 2,
          FIELDTERMINATOR = '','',
          ROWTERMINATOR   = ''\n'',
          TABLOCK,
          CODEPAGE = ''ACP''
      );';

    EXEC (@Sql);

    DECLARE @FileDate CHAR(8) = SUBSTRING(@FileName, 4, 8);
    DECLARE @StartEndDate VARCHAR(10) =
        STUFF(STUFF(@FileDate,5,0,'-'),8,0,'-');

    INSERT INTO dbo.RLC_Data
    (
        StoreFormatCode,
        StartDate,
        EndDate,
        RegionCode,
        ProductCategoryCode,
        RetailSalesExVAT,
        RetailSalesUnits,
        SourceFileName
    )
    SELECT
        StoreFormatCodeCsv,
        @StartEndDate,
        @StartEndDate,
        RegionCodeCsv,
        ProductCategoryCodeCsv,
        TRY_CONVERT(NUMERIC(38,2), RetailSalesExVATCsv),
        TRY_CONVERT(NUMERIC(38,2), RetailSalesUnitsCsv),
        @FileName
    FROM #RLC_CsvStage;

    INSERT INTO dbo.RLC_ProcessedFiles (FileName, TableName)
    VALUES (@FileName, 'RLC_Data');
END;

