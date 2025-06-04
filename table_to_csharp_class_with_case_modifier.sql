DECLARE @TABLE_NAME nvarchar(MAX) =  'venda';
DECLARE @CLASS_NAME  nvarchar(MAX) = 'venda';

-- Create a function to transform the attributes to PascalCase instead of snake_case.
-- Example: PRO_DESCRICAO_COMPLEMENTAR becomes DescricaoComplementar
IF OBJECT_ID(N'dbo.SnakeToPascal', N'FN') IS NULL
BEGIN
    EXEC('
        CREATE FUNCTION dbo.SnakeToPascal(@snakeCase nvarchar(MAX))
        RETURNS nvarchar(MAX)
        AS
        BEGIN
            DECLARE @result nvarchar(MAX) = '''';
            DECLARE @i int = 1;
            DECLARE @char nvarchar(1);
            DECLARE @nextUpper bit = 1;
            
            -- Remove everything before the first underscore, including the underscore itself
            SET @snakeCase = SUBSTRING(@snakeCase, CHARINDEX(''_'', @snakeCase) + 1, LEN(@snakeCase));
            
            WHILE @i <= LEN(@snakeCase)
            BEGIN
                SET @char = SUBSTRING(@snakeCase, @i, 1);
                IF @char = ''_''
                BEGIN
                    SET @nextUpper = 1;
                END
                ELSE
                BEGIN
                    IF @nextUpper = 1
                    BEGIN
                        SET @result = @result + UPPER(@char);
                        SET @nextUpper = 0;
                    END
                    ELSE
                    BEGIN
                        SET @result = @result + LOWER(@char);
                    END
                END
                SET @i = @i + 1;
            END

            RETURN @result;
        END
    ');
END;


-- SQLServer doesn't allow using custom functions directly in system tables
-- Create a temporary table and populate it with the information, then manipulate it 
-- with the function created above
CREATE TABLE #TempColumns (
    COLUMN_NAME nvarchar(128),
    DATA_TYPE nvarchar(128),
    IS_NULLABLE nvarchar(3),
    NUMERIC_PRECISION int,
    NUMERIC_SCALE int
);

INSERT INTO #TempColumns (COLUMN_NAME, DATA_TYPE, IS_NULLABLE, NUMERIC_PRECISION, NUMERIC_SCALE)
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TABLE_NAME;

SELECT '[Table("' + @TABLE_NAME + '")]' + CHAR(13) + 
       'public class ' + @CLASS_NAME + ' {' + CHAR(13)
UNION ALL

SELECT CONCAT(
              '[Column(',
              CASE DATA_TYPE
                  WHEN 'decimal' THEN 'TypeName = "decimal(' + CAST(NUMERIC_PRECISION AS nvarchar) + ', ' + CAST(NUMERIC_SCALE AS nvarchar) + ')"'
                  ELSE '"' + COLUMN_NAME + '"'
              END,
              ')]' + CHAR(13),
              'public ', 
              CASE DATA_TYPE
                  WHEN 'nvarchar' THEN 'string' 
                  WHEN 'varchar' THEN 'string'
                  WHEN 'datetime' THEN 'DateTime'
                  WHEN 'money' THEN 'decimal' 
                  WHEN 'bit' THEN 'bool'
                  WHEN 'smallint' THEN 'short'
                  WHEN 'bigint' THEN 'long'
                  WHEN 'float' THEN 'double'
                  WHEN 'date' THEN 'DateTime'
                  WHEN 'tinyint' THEN 'byte'
                  WHEN 'uniqueidentifier' THEN 'Guid'
                  ELSE DATA_TYPE
              END,
              CASE IS_NULLABLE
                  WHEN 'YES' THEN '?'
                  ELSE ''
              END,
              ' ', 
              dbo.SnakeToPascal(COLUMN_NAME), 
              ' { get; set; }', CHAR(13)
             )
FROM #TempColumns
UNION ALL
SELECT '}';

-- Cleanup
DROP TABLE #TempColumns;
DROP FUNCTION SnakeToPascal;
