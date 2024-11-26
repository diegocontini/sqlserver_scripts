
--Cria uma func pra transformar os atributos em PascalCase ao inves de snake_case. 
--Ex: PRO_CODIGO vira ProCodigo
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

DECLARE @TABLE_NAME nvarchar(MAX) =  'EMPRESA';
DECLARE @CLASS_NAME  nvarchar(MAX) = 'Empresa';
DECLARE @PREFIX nvarchar(10) = 'EMP_';
-- SQLServer não deixa usar função custom diretamente em tabelas do sistema
--Criar uma tabela temporária e popular com as infos, e depois manipular com a 
--função criada acima
CREATE TABLE #TempColumns (
    COLUMN_NAME nvarchar(128),
    DATA_TYPE nvarchar(128),
    IS_NULLABLE nvarchar(3)
);

INSERT INTO #TempColumns (COLUMN_NAME, DATA_TYPE, IS_NULLABLE)
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TABLE_NAME;


SELECT '[Table("' + @TABLE_NAME + '")]' + CHAR(13) + 
       'public class ' + @CLASS_NAME + ' {' + CHAR(13)
UNION ALL
SELECT concat(
              '[Column("', COLUMN_NAME, '")] ' + CHAR(13),
              'public ', 
              CASE DATA_TYPE
                  WHEN 'nvarchar' THEN 'string' 
                  WHEN 'varchar' THEN 'string'
                  WHEN 'datetime' THEN 'DateTime'
                  WHEN 'money' THEN 'decimal' 
                  WHEN 'bit' THEN 'bool'
                  WHEN 'smallint' THEN 'short'
                  WHEN 'float' THEN 'double'
                  ELSE DATA_TYPE
              END,
              CASE IS_NULLABLE
                  WHEN 'YES' THEN '?'
                  ELSE ''
              END,
              ' ', 
              dbo.SnakeToPascal(REPLACE(COLUMN_NAME, @PREFIX, '')), 
              ' { get; set; }', CHAR(13)
             )
FROM #TempColumns
UNION ALL
SELECT '}';

-- Drop a tabela temporária e a func
DROP TABLE #TempColumns;
DROP FUNCTION SnakeToPascal;